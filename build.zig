const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const exe = b.addExecutable(.{
        .name = "midi_player",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Link FluidSynth
    exe.linkLibC();
    exe.linkSystemLibrary("fluidsynth");

    // Link ALSA
    exe.linkSystemLibrary("asound");

    b.installArtifact(exe);

    // Copy executable to project root for easier access
    const copy_exe = b.addSystemCommand(&[_][]const u8{ "cp", "zig-out/bin/midi_player", "midi_player" });
    copy_exe.step.dependOn(b.getInstallStep());

    const copy_step = b.step("copy-exe", "Copy executable to project root");
    copy_step.dependOn(&copy_exe.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
