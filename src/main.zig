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

    chip.loadROM("dummy.c8") catch {
        std.debug.print("Could not load chip 8 file. Make sure it is a valid .c8 file.\n", .{});
    };

    while (true) {
        chip.emulateCycle() catch |err| switch (err) {
            error.Overflow => {
                std.debug.print("Stack overflow occurred during emulation.\n", .{});
                return;
            },
            error.RomTooLarge => {
                std.debug.print("The ROM file is too large to fit in memory.\n", .{});
                return;
            },
            error.InvalidOpcode => {
                std.debug.print("Encountered invalid opcode during emulation.\n", .{});
                return;
            },
            else => {
                std.debug.print("An unexpected error occurred: {s}\n", .{err});
                return;
            },
        };
        // add timing control here.
    }
}
