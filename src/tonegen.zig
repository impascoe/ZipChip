const std = @import("std");

// sine wave formula: y(time) = A*sin(tau * frequency * time)

pub fn generateSineWave(allocator: std.mem.Allocator, duration: f32, sample_rate: u32, volume: f32) ![]i16 {
    const total_samples: usize = @as(u32, @intFromFloat(duration * @as(f32, @floatFromInt(sample_rate))));
    const sine_wave = try allocator.alloc(i16, total_samples);

    const frequency = 440.0;
    const tau = std.math.tau;

    std.debug.print("Generating sine wave: duration={}s, sample_rate={}Hz, total_samples={}, frequency={}Hz, volume={}\n", .{ duration, sample_rate, total_samples, frequency, volume });

    std.debug.print("Sine wave size {}\n", .{sine_wave.len});

    for (sine_wave, 0..) |*sine_pos, i| {
        // std.debug.print("Generating sample {}/{}\n", .{ i + 1, total_samples });
        const time = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(sample_rate));
        const sin_val = std.math.sin(tau * frequency * time) * volume;
        const scaled_val = sin_val * 32767.0;
        sine_pos.* = @intFromFloat(std.math.clamp(scaled_val, -32767.0, 32767.0));
    }

    // std.debug.print("\nSine Wave: {any}\n", .{sine_wave});

    return sine_wave;
}

pub fn deinit(allocator: std.mem.Allocator, wave: []i16) void {
    allocator.free(wave);
}
