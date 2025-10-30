const std = @import("std");

pub const Chip8 = struct {
    const fontset_address: u8 = 0x50;
    const start_address: u8 = 0x200;

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

    pub fn init(self: @This(), allocator: std.mem.Allocator) !void {
        self.arena = std.heap.ArenaAllocator.init(allocator);
        errdefer self.allocator.deinit();

        self.allocator = self.arena.allocator();

        self.pc = start_address;

        for (fontset_size) |i| {
            self.memory[fontset_address + i] = fontset[i];
        }
    }

    pub fn deinit(self: @This()) void {
        self.arena.deinit();
    }

    fn getRandInt() u8 {
        return rand.intRangeAtMost(u8, 0, 255);
    }

    pub fn loadROM(self: @This(), file_path: []const u8) !void {
        const file = try std.fs.cwd().openFile(file_path, .{});

        const size: usize = try file.getEndPos();
        const buffer: []const u8 = try self.allocator.alloc(u8, size);

        file.reader(buffer);

        for (size) |i| {
            self.memory[start_address + i] = buffer[i];
        }
    }

    // Instructions
    // 00E0 - CLS: Clear the display.
    fn op00E0(self: @This()) void {
        @memset(self.video, 0);
    }
};
