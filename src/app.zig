//! Application Module - Orchestrates the MIDI player application
//! Manages initialization, configuration, and routing between UI modes

const std = @import("std");
const player_mod = @import("player.zig");
const config_mod = @import("config.zig");
const ui_mod = @import("ui.zig");

pub const App = struct {
    allocator: std.mem.Allocator,
    midi_player: player_mod.MidiPlayer,
    config: config_mod.Config,
    ui: ui_mod.UI,
    args: []const [:0]const u8,

    pub fn init(allocator: std.mem.Allocator, args: []const [:0]const u8) !App {
        // Load config or use defaults
        const config = config_mod.Config.load(allocator) catch config_mod.Config{};

        // Initialize MIDI player
        var midi_player = try player_mod.MidiPlayer.init(allocator);

        // Apply configuration
        midi_player.setVolume(config.volume);
        midi_player.state.is_looping = config.loop_mode;
        midi_player.state.current_index = config.last_played_index;

        // Load playlist
        try loadPlaylist(&midi_player.state.playlist, allocator);

        // Load soundfont
        const soundfont_path_slice = if (args.len > 2) args[2] else config.soundfont_path;
        const soundfont_path = try allocator.dupeZ(u8, soundfont_path_slice);
        try midi_player.loadSoundFont(soundfont_path);

        return App{
            .allocator = allocator,
            .midi_player = midi_player,
            .config = config,
            .ui = ui_mod.UI.init(allocator),
            .args = args,
        };
    }

    pub fn deinit(self: *App) void {
        self.midi_player.deinit();
        self.ui.deinit();
    }

    pub fn run(self: *App) !void {
        // Set up terminal
        try ui_mod.setupRawMode();
        defer ui_mod.restoreMode();

        if (self.args.len < 2) {
            // Interactive Search Mode
            try self.ui.searchMode(&self.midi_player, self.allocator);
            try self.ui.playbackMode(&self.midi_player, &self.config, self.allocator);
        } else {
            // Handle list command
            const command = self.args[1];
            if (std.mem.eql(u8, command, "--")) {
                try listMidis(self.midi_player.state.playlist.items);
                return;
            }

            // Resolve MIDI file path and set initial index
            const initial_midi_path = try resolveMidiPath(command, self.allocator);
            defer self.allocator.free(initial_midi_path);

            // Find index in playlist
            for (self.midi_player.state.playlist.items, 0..) |item, i| {
                if (std.mem.endsWith(u8, initial_midi_path, item) or std.mem.eql(u8, initial_midi_path, item)) {
                    self.midi_player.state.current_index = i;
                    break;
                }
            }

            // Start playback
            try self.ui.playbackMode(&self.midi_player, &self.config, self.allocator);
        }
    }
};

// Utility functions

/// Load all MIDI files from the midis/ directory
fn loadPlaylist(playlist: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    var dir = std.fs.cwd().openDir("midis", .{ .iterate = true }) catch return;
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".mid")) {
            const name = try allocator.dupe(u8, entry.name);
            try playlist.append(allocator, name);
        }
    }
    // Sort playlist for consistent order
    std.sort.block([]const u8, playlist.items, {}, struct {
        fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThan);
}

/// List available MIDI files
fn listMidis(midis: [][]const u8) !void {
    std.debug.print("Available MIDI files:\n", .{});
    for (midis, 0..) |midi, i| {
        std.debug.print("  {}: {s}\n", .{ i + 1, midi });
    }
}

/// Resolve MIDI file path with smart lookup
fn resolveMidiPath(command: []const u8, allocator: std.mem.Allocator) ![:0]const u8 {
    // Check if it's an absolute path
    if (std.fs.path.isAbsolute(command)) {
        return allocator.dupeZ(u8, command);
    }

    // Try candidates: command as-is, command with .mid extension
    const candidates = [_][]const u8{ command, try std.mem.concat(allocator, u8, &[_][]const u8{ command, ".mid" }) };
    defer if (candidates.len > 1) allocator.free(candidates[1]);

    for (candidates) |candidate| {
        const midi_path = try std.fs.path.join(allocator, &[_][]const u8{ "midis", candidate });
        defer allocator.free(midi_path);

        if (std.fs.cwd().access(midi_path, .{})) |_| {
            return allocator.dupeZ(u8, midi_path);
        } else |_| {}
    }

    return error.MidiFileNotFound;
}
