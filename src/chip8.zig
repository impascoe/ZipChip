const std = @import("std");

pub const Chip8 = struct {
    const start_address: u8 = 0x200;

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

    pub fn init(self: @This()) void {
        self.pc = start_address;
    }

    pub fn loadROM(self: @This(), file_path: []const u8) !void {
        const file = try std.fs.cwd().openFile(file_path, .{});

        const size: usize = try file.getEndPos();
        const buffer: []const u8 = try std.heap.page_allocator.alloc(u8, size);
        defer std.heap.page_allocator.free(buffer);

        file.reader(buffer);

        for (size) |i| {
            self.memory[start_address + i] = buffer[i];
        }
    }
};
