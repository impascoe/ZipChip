const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

const tones = @import("tonegen.zig");
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
    const target_instructions_per_second: usize = 500;
    const target_timer_hz: usize = 60;

    const pixel_size: usize = scale;

    const ns_per_s = std.time.ns_per_s;
    const instr_interval_ns: usize = @intCast(ns_per_s / target_instructions_per_second);
    const timer_interval_ns: usize = @intCast(ns_per_s / target_timer_hz);

    rl.initWindow(@intCast(VIDEO_WIDTH * pixel_size), @intCast(VIDEO_HEIGHT * pixel_size), "ZipChip Emulator");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    const samples = tones.generateSineWave(std.heap.page_allocator, 0.5, 44100, 0.3) catch {
        std.debug.print("Failed to generate sine wave samples.\n", .{});
        return;
    };

    defer tones.deinit(std.heap.page_allocator, samples);
    std.debug.print("\n{any}\n", .{samples.len});

    const stream = rl.loadAudioStream(44100, 16, 2) catch |err| {
        std.debug.print("Failed to load audio stream. Error: {}\n", .{err});
        return;
    };

    var prev_sound_timer: usize = chip.sound_timer;

    defer rl.unloadAudioStream(stream);

    rl.playAudioStream(stream);

    rl.updateAudioStream(stream, samples.ptr, @intCast(samples.len));

    std.debug.print("Audio Stream: {any}\n", .{stream});

    rl.setTargetFPS(60);

    var last_instr_ns = std.time.nanoTimestamp();
    var last_timer_ns = last_instr_ns;

    while (!rl.windowShouldClose()) {
        const now = std.time.nanoTimestamp();

        while (now - last_timer_ns >= timer_interval_ns) : (last_timer_ns += timer_interval_ns) {
            if (chip.delay_timer > 0) chip.delay_timer -= 1;
            if (chip.sound_timer > 0) {
                chip.sound_timer -= 1;
            }
        }

        while (now - last_instr_ns >= instr_interval_ns) : (last_instr_ns += instr_interval_ns) {
            chip.emulateCycle() catch |err| {
                std.debug.print("Emulation cycle failed. Error: {}\n", .{err});
                return;
            };
        }

        const current_sound_timer = chip.sound_timer;

        if (current_sound_timer > 0) {
            // Start stream when going from 0 -> non-zero
            if (prev_sound_timer == 0) {
                rl.playAudioStream(stream);
            }

            // Feed stream as needed
            if (rl.isAudioStreamProcessed(stream)) {
                // frame_count is "number of samples per channel"
                const frame_count: i32 = @intCast(samples.len);
                rl.updateAudioStream(stream, samples.ptr, frame_count);
            }
        } else {
            // Optional: stop/pause when it reaches 0
            if (prev_sound_timer > 0) {
                rl.stopAudioStream(stream);
            }
        }

        prev_sound_timer = current_sound_timer;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        for (chip.video, 0..) |pixel, idx| {
            if (pixel == 0) continue;

            const x: i32 = @intCast((idx % VIDEO_WIDTH) * pixel_size);
            const y: i32 = @intCast((idx / VIDEO_WIDTH) * pixel_size);

            rl.drawRectangle(x, y, @intCast(pixel_size), @intCast(pixel_size), rl.Color.black);
        }

        handleInput(chip);
    }
}

fn initBeep() void {}

fn handleInput(chip: *chip8) void {
    if (rl.isKeyDown(rl.KeyboardKey.one)) chip.keypad[0x1] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.two)) chip.keypad[0x2] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.three)) chip.keypad[0x3] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.four)) chip.keypad[0xC] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.q)) chip.keypad[0x4] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.w)) chip.keypad[0x5] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.e)) chip.keypad[0x6] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.r)) chip.keypad[0xD] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.a)) chip.keypad[0x7] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.s)) chip.keypad[0x8] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.d)) chip.keypad[0x9] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.f)) chip.keypad[0xE] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.z)) chip.keypad[0xA] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.x)) chip.keypad[0x0] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.c)) chip.keypad[0xB] = 1;
    if (rl.isKeyDown(rl.KeyboardKey.v)) chip.keypad[0xF] = 1;

    if (rl.isKeyUp(rl.KeyboardKey.one)) chip.keypad[0x1] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.two)) chip.keypad[0x2] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.three)) chip.keypad[0x3] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.four)) chip.keypad[0xC] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.q)) chip.keypad[0x4] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.w)) chip.keypad[0x5] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.e)) chip.keypad[0x6] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.r)) chip.keypad[0xD] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.a)) chip.keypad[0x7] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.s)) chip.keypad[0x8] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.d)) chip.keypad[0x9] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.f)) chip.keypad[0xE] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.z)) chip.keypad[0xA] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.x)) chip.keypad[0x0] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.c)) chip.keypad[0xB] = 0;
    if (rl.isKeyUp(rl.KeyboardKey.v)) chip.keypad[0xF] = 0;
}
