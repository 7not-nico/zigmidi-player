const std = @import("std");

pub const Config = struct {
    volume: f32 = 0.2,
    last_played_index: usize = 0,
    loop_mode: bool = false,
    soundfont_path: []const u8 = "soundfonts/standard-midisf.sf2",

    pub fn load(allocator: std.mem.Allocator) !Config {
        const path = try getConfigPath(allocator);
        defer allocator.free(path);

        const file = std.fs.openFileAbsolute(path, .{}) catch |err| {
            if (err == error.FileNotFound) return Config{};
            return err;
        };
        defer file.close();

        const content = try file.readToEndAlloc(allocator, 4096);
        defer allocator.free(content);

        // Parse JSON
        const parsed = try std.json.parseFromSlice(Config, allocator, content, .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        // We need to duplicate the strings because parsed.value references content which is freed
        var config = parsed.value;
        if (config.soundfont_path.len > 0) {
            config.soundfont_path = try allocator.dupe(u8, config.soundfont_path);
        } else {
            config.soundfont_path = try allocator.dupe(u8, "soundfonts/standard-midisf.sf2");
        }

        return config;
    }

    pub fn save(self: Config, allocator: std.mem.Allocator) !void {
        const path = try getConfigPath(allocator);
        defer allocator.free(path);

        // Ensure directory exists
        if (std.fs.path.dirname(path)) |dir| {
            std.fs.makeDirAbsolute(dir) catch |err| {
                if (err != error.PathAlreadyExists) return err;
            };
        }

        const file = try std.fs.createFileAbsolute(path, .{});
        defer file.close();

        const json_string = try std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(self, .{ .whitespace = .indent_2 })});
        defer allocator.free(json_string);
        try file.writeAll(json_string);
    }
};

fn getConfigPath(allocator: std.mem.Allocator) ![]const u8 {
    const home = std.posix.getenv("HOME") orelse return error.HomeNotFound;
    return std.fs.path.join(allocator, &[_][]const u8{ home, ".config", "midi_player", "config.json" });
}
