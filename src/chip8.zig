const std = @import("std");

pub const Chip8 = struct {
    const instruction_size: u16 = 2;
    const fontset_address: usize = 0x50;
    const start_address: usize = 0x200;

    const fontset_size: u8 = 80;

    const fontset = [fontset_size]u8{
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80, // F
    };

    const rand = std.crypto.random;

    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,
    registers: [16]u8,
    memory: [4096]u8,
    index: u16,
    pc: u16,
    stack: [16]u16,
    sp: u8,
    delay_timer: u8,
    sound_timer: u8,
    keypad: [16]u8,
    video: [64 * 32]u32,
    opcode: u16,

    pub fn init(allocator: std.mem.Allocator) !Chip8 {
        var arena = std.heap.ArenaAllocator.init(allocator);
        errdefer arena.deinit();

        var c8 = Chip8{
            .arena = arena,
            .allocator = arena.allocator(),
            .registers = [_]u8{0} ** 16,
            .memory = [_]u8{0} ** 4096,
            .index = 0,
            .pc = start_address,
            .stack = [_]u16{0} ** 16,
            .sp = 0,
            .delay_timer = 0,
            .sound_timer = 0,
            .keypad = [_]u8{0} ** 16,
            .video = [_]u32{0} ** (64 * 32),
            .opcode = 0,
        };

        // Load the fontset into memory.
        for (fontset, 0..) |b, i| {
            c8.memory[fontset_address + i] = b;
        }

        return c8;
    }

    pub fn deinit(self: *Chip8) void {
        self.arena.deinit();
    }

    fn getRandInt() u8 {
        return rand.intRangeAtMost(u8, 0, 255);
    }

    // Load ROM into memory
    pub fn loadROM(self: *Chip8, file_path: []const u8) !void {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
        defer file.close();

        const rom_size = try file.getEndPos();

        if (rom_size > self.memory.len - start_address) {
            return error.RomTooLarge;
        }

        const rom = try self.allocator.alloc(u8, rom_size);
        defer self.allocator.free(rom);

        var reader = file.reader(rom);

        try reader.interface.readSliceAll(rom);

        for (rom, 0..) |b, i| {
            self.memory[start_address + i] = b;
        }
    }

    pub fn emulateCycle(self: *Chip8) !void {
        const current_pc = self.pc;

        // get opcode
        const hi_byte = self.memory[current_pc];
        const lo_byte = self.memory[current_pc + 1];

        self.opcode = (@as(u16, hi_byte) << 8) | @as(u16, lo_byte);

        // advance pc by default
        self.pc += instruction_size;

        // execute opcode
    }

    // Instructions
    // 00E0 - CLS: Clear the display by pushing zeroes to display.
    fn op00E0(self: *Chip8) void {
        @memset(self.video, 0);
    }

    // 00EE - RET: Return from a subroutine.
    fn op00EE(self: *Chip8) !void {
        self.sp = try std.math.sub(u8, self.sp, 1);
        self.pc = self.stack[self.sp];
    }

    // 1NNN - JP to addr: Jump to NNN
    fn op1NNN(self: *Chip8) void {
        const address: u16 = self.opcode & 0x0FFF;
        self.pc = address;
    }

    // 2NNN - CALL addr: Call subroutine at NNN
    fn op2NNN(self: *Chip8) !void {
        const address: u16 = self.opcode & 0x0FFF;
        self.stack[self.sp] = self.pc;
        self.sp = try std.math.add(u8, self.sp, 1);
        self.pc = address;
    }

    // 3XKK - SE Vx, byte: Skip next instruction if Vx == kk
    fn op3XKK(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const kk: u8 = @as(u8, self.opcode & 0x00FF);

        if (self.registers[x] == kk) {
            self.pc += instruction_size;
        }
    }

    // 4XKK - SNE Vx, byte: Skip next instruction if Vx != kk
    fn op4XKK(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const kk: u8 = @as(u8, self.opcode & 0x00FF);

        if (self.registers[x] != kk) {
            self.pc += instruction_size;
        }
    }

    // 5XY0 - SE Vx, Vy: Skip next instruction if Vx == Vy
    fn op5XY0(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        if (self.registers[x] == self.registers[y]) {
            self.pc += instruction_size;
        }
    }

    // 6XKK - LD Vx, byte: Set Vx = kk
    fn op6XKK(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const kk: u8 = @as(u8, self.opcode & 0x00FF);

        self.registers[x] = kk;
    }

    // 7XKK - LD Vx, byte: Set Vx += kk
    fn op7XKK(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const kk: u8 = @as(u8, self.opcode & 0x00FF);

        self.registers[x] += kk;
    }

    // 8XY0 - SE Vx, Vy: Set Vx = Vy
    fn op8XY0(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        self.registers[x] = self.registers[y];
    }

    // 8XY1 - SE Vx, Vy: Set Vx = Vx OR Vy
    fn op8XY1(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        self.registers[x] |= self.registers[y];
    }

    // 8XY2 - SE Vx, Vy: Set Vx = Vx AND Vy
    fn op8XY2(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        self.registers[x] &= self.registers[y];
    }

    // 8XY3 - SE Vx, Vy: Set Vx = Vx OR Vy
    fn op8XY3(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        self.registers[x] ^= self.registers[y];
    }

    // 8XY4 - SE Vx, Vy: Set Vx = Vx + Vy
    fn op8XY4(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        const ov = @addWithOverflow(self.registers[x], self.registers[y]);
        if (ov[1] != 0) {
            self.registers[0xF] = 1;
        } else {
            self.registers[0xF] = 0;
        }

        self.registers[x] = ov[0] & 0xFF;
    }

    // 8XY5 - SE Vx, Vy: Set Vx = Vx - Vy
    fn op8XY5(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        if (self.registers[x] > self.registers[y]) {
            self.registers[0xF] = 1;
        } else {
            self.registers[0xF] = 0;
        }

        self.registers[x] -= self.registers[y];
    }

    // 8XY6 - SE Vx, Vy: Set Vx = Vx SHR 1
    fn op8XY6(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);

        self.registers[0xF] = self.registers[x] & 0x1;
        self.registers[x] >>= 1;
    }

    // 8XY7 - SE Vx, Vy: Set Vx = Vx - Vy
    fn op8XY7(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        if (self.registers[y] > self.registers[x]) {
            self.registers[0xF] = 1;
        } else {
            self.registers[0xF] = 0;
        }

        self.registers[y] -= self.registers[x];
    }

    // 8XYE - SE Vx, Vy: Set Vx = Vx SHL 1
    fn op8XYE(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);

        self.registers[0xF] = (self.registers[x] & 0x80) >> 7;
        self.registers[x] <<= 1;
    }

    // 9XY0 - SNE Vx, Vy: Skip next instruction if Vx != Vy
    fn op9XY0(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const y: u8 = @as(u8, (self.opcode & 0x00F0) >> 4);

        if (self.registers[x] != self.registers[y]) {
            self.pc += instruction_size;
        }
    }

    // ANNN - LD I, addr: Set index = NNN
    fn opANNN(self: *Chip8) void {
        const address: u16 = self.opcode & 0x0FFF;
        self.index = address;
    }

    // BNNN - JP V0, addr: Jump to location NNN + V0
    fn opBNNN(self: *Chip8) void {
        const address: u16 = self.opcode & 0x0FFF;
        self.pc = @as(u16, self.registers[0]) + address;
    }

    fn opCXKK(self: *Chip8) void {
        const x: u8 = @as(u8, (self.opcode & 0x0F00) >> 8);
        const kk: u8 = @as(u8, self.opcode & 0x00FF);

        self.registers[x] = getRandInt() & kk;
    }
};
