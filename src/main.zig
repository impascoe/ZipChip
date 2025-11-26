const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

const chip8 = @import("chip8.zig").Chip8;

const VIDEO_WIDTH: usize = 64;
const VIDEO_HEIGHT: usize = 32;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len != 3) {
        std.debug.print("Usage: zch8 <scale> <rom>\n", .{});
        return;
    }

    const scale: usize = std.fmt.parseInt(usize, args[1], 10) catch {
        std.debug.print("Invalid scale factor. Please provide a valid integer.\n", .{});
        return;
    };
    const chip_rom: []const u8 = args[2];

    var chip = chip8.init(std.heap.page_allocator) catch {
        std.debug.print("Failed to initialize Chip8 emulator.\n", .{});
        return;
    };

    defer chip.deinit();

    chip.loadROM(chip_rom) catch {
        std.debug.print("Could not load chip 8 file. Make sure it is a valid .c8 file.\n", .{});
        return;
    };

    // var i: u32 = 0;
    // while (i < 40) : (i += 1) {
    //     chip.emulateCycle() catch |err| {
    //         std.debug.print("Emulation cycle failed. Error: {}\n", .{err});
    //         return;
    //     };
    // }

    render(&chip, scale);
}

fn render(chip: *chip8, scale: usize) void {
    const pixel_size: usize = scale;

    rl.initWindow(@intCast(VIDEO_WIDTH * pixel_size), @intCast(VIDEO_HEIGHT * pixel_size), "ZipChip Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        chip.emulateCycle() catch |err| {
            std.debug.print("Emulation cycle failed. Error: {}\n", .{err});
            return;
        };

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        for (chip.video, 0..) |pixel, idx| {
            if (pixel == 0) continue;

            const x: i32 = @intCast((idx % VIDEO_WIDTH) * pixel_size);
            const y: i32 = @intCast((idx / VIDEO_WIDTH) * pixel_size);

            rl.drawRectangle(x, y, @intCast(pixel_size), @intCast(pixel_size), rl.Color.black);
        }
    }
}
