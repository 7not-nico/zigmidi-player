//! MIDI Player - A simple CLI MIDI player using FluidSynth and ALSA
//! Built with Zig following KISS principles: Keep It Simple, Stupid

const std = @import("std");
const app_mod = @import("app.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var app = try app_mod.App.init(allocator, args);
    defer app.deinit();

    try app.run();
}
