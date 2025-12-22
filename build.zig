const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zipchip",
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // set test module path
    const tests = b.addTest(.{
        .name = "tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linkage = .dynamic,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.root_module.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    // Make sure tests always build newest so they are not cached
    const run_tests = b.addRunArtifact(tests);
    run_tests.has_side_effects = false;

    b.installArtifact(exe);
    b.installArtifact(raylib_artifact);

    const exe_check = b.addExecutable(.{
        .name = "ZipChipCheck",
        .root_module = exe.root_module,
    });

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const check = b.step("check", "Check the app");
    check.dependOn(&exe_check.step);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}
