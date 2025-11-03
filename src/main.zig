const std = @import("std");
const chip8 = @import("chip8.zig").Chip8;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    var chip = chip8.init(std.heap.page_allocator) catch {
        std.debug.print("Failed to initialize Chip8 emulator.\n", .{});
        return;
    };

    defer chip.deinit();

    chip.loadROM("dummy.txt") catch {
        std.debug.print("Could not load chip 8 file. Make sure it is a valid .c8 file.\n", .{});
    };
}
