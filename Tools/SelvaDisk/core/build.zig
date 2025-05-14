const std = @import("std");

pub fn build(build_process: *std.Build) void {
    const target = build_process.standardTargetOptions(.{});
    const optimize = build_process.standardOptimizeOption(.{});

    const executable = build_process.addExecutable(.{
        .name = "SelvaDisk",
        .root_source_file = build_process.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const selvafat = build_process.dependency("SelvaFat", .{});

    executable.root_module.addImport("selvafat.zig", selvafat.module("selvafat"));

    build_process.installArtifact(executable);
    const run_command = build_process.addRunArtifact(executable);
    run_command.step.dependOn(build_process.getInstallStep());

    if (build_process.args) |args| {
        run_command.addArgs(args);
    }

    const run_step = build_process.step("run", "Execute the SelvaDisk Disk Image Creator");
    run_step.dependOn(&run_command.step);

    const executable_unit_tests = build_process.addTest(.{
        .root_source_file = build_process.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_executable_unit_tests = build_process.addRunArtifact(executable_unit_tests);

    const test_step = build_process.step("test", "Run all unit tests");
    test_step.dependOn(&run_executable_unit_tests.step);
}
