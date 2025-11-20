const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

const chip8 = @import("chip8.zig").Chip8;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    var chip = chip8.init(std.heap.page_allocator) catch {
        std.debug.print("Failed to initialize Chip8 emulator.\n", .{});
        return;
    };

    defer chip.deinit();

    chip.loadROM("1-chip8-logo.ch8") catch {
        std.debug.print("Could not load chip 8 file. Make sure it is a valid .c8 file.\n", .{});
        return;
    };

    var i: u32 = 0;
    while (i < 40) : (i += 1) {
        chip.emulateCycle() catch |err| {
            std.debug.print("Emulation cycle failed. Error: {}\n", .{err});
            return;
        };
    }

    // while (true) {
    //     chip.emulateCycle() catch |err| {
    //         std.debug.print("Emulation cycle failed. Error: {}\n", .{err});
    //         return;
    //     };
    //     // add timing control here.
    // }
}
