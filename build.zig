const std = @import("std");
// const jetzig = @import("jetzig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zztest",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("httpz", httpz.module("httpz"));

    // exe.addCSourceFile(.{ .file = b.path("./src/resolve.c") });
    // exe.linkLibC();

    // Example Dependency
    // -------------------
    // const iguanas_dep = b.dependency("iguanas", .{ .optimize = optimize, .target = target });
    // exe.root_module.addImport("iguanas", iguanas_dep.module("iguanas"));
    //
    // ^ Add all dependencies before `jetzig.jetzigInit()` ^

    // try jetzig.jetzigInit(b, exe, .{});

    b.installArtifact(exe);
    // const zigJsonDependency = b.dependency("zig-json", .{ .target = target, .optimize = optimize });

    // exe.root_module.addImport("json", zigJsonDependency.module("zig-json"));
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
