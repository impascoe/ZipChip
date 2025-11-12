const std = @import("std");

const ProcessingError = error{
    StackUnderflow,
    StackOverflow,
};

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
    fn op00EE(self: *Chip8) ProcessingError!void {
        if (self.sp == 0) {
            return ProcessingError.StackUnderflow;
        } else {
            self.sp -= 1;
            self.pc = self.stack[self.sp];
        }
    }

    // 1NNN - JP to addr: Jump to NNN
    fn op1NNN(self: *Chip8) void {
        const address: u16 = self.opcode & 0x0FFF;
        self.pc = address;
    }

    // 2NNN - CALL addr: Call subroutine at NNN
    fn op2NNN(self: *Chip8) ProcessingError!void {
        if (self.sp == self.stack.len) {
            return ProcessingError.StackOverflow;
        } else {
            const address: u16 = self.opcode & 0x0FFF;
            self.stack[self.sp] = self.pc;
            self.sp += 1;
            self.pc = address;
        }
    }
};
