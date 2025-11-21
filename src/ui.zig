//! UI Module - Handles all user interface and terminal interactions
//! Provides search mode, playback mode, and terminal control functions

const std = @import("std");
const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("termios.h");
});
const player_mod = @import("player.zig");
const config_mod = @import("config.zig");

// Terminal handling
var original_termios: c.termios = undefined;

pub const UI = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) UI {
        return UI{ .allocator = allocator };
    }

    pub fn deinit(self: *UI) void {
        _ = self;
    }

    /// Interactive search mode - allows filtering MIDI files in real-time
    pub fn searchMode(self: *UI, midi_player: *player_mod.MidiPlayer, allocator: std.mem.Allocator) !void {
        _ = self;

        // Load all midis for filtering
        var all_midis = std.ArrayList([]const u8).empty;
        defer {
            for (all_midis.items) |item| allocator.free(item);
            all_midis.deinit(allocator);
        }
        try loadPlaylist(&all_midis, allocator);

        var query = std.ArrayList(u8).empty;
        defer query.deinit(allocator);

        while (true) {
            std.debug.print("\x1b[2J\x1b[H", .{}); // Clear screen
            std.debug.print("Search: {s}_\n\n", .{query.items});

            // Filter and print matches
            var matches_count: usize = 0;
            for (all_midis.items) |midi| {
                if (matchesQuery(midi, query.items)) {
                    if (matches_count < 15) {
                        std.debug.print("  {s}\n", .{midi});
                    }
                    matches_count += 1;
                }
            }
            if (matches_count > 15) {
                std.debug.print("  ... and {d} more\n", .{matches_count - 15});
            }

            // Blocking read for responsiveness
            var key: ?u8 = null;
            while (key == null) {
                key = try checkInput();
                if (key == null) _ = c.usleep(10000); // 10ms wait
            }

            if (key) |k| {
                switch (k) {
                    13, 10 => { // Enter
                        // Apply filter
                        for (midi_player.state.playlist.items) |item| allocator.free(item);
                        midi_player.state.playlist.clearRetainingCapacity();

                        // Add matches
                        for (all_midis.items) |midi| {
                            if (matchesQuery(midi, query.items)) {
                                try midi_player.state.playlist.append(allocator, try allocator.dupe(u8, midi));
                            }
                        }
                        midi_player.state.current_index = 0;
                        return;
                    },
                    127, 8 => { // Backspace
                        if (query.items.len > 0) {
                            _ = query.pop();
                        }
                    },
                    27 => { // Esc
                        return;
                    },
                    else => {
                        if (std.ascii.isPrint(k)) {
                            try query.append(allocator, k);
                        }
                    },
                }
            }
        }
    }

    /// Main playback mode - handles track playback and user controls
    pub fn playbackMode(
        self: *UI,
        midi_player: *player_mod.MidiPlayer,
        config: *config_mod.Config,
        allocator: std.mem.Allocator,
    ) !void {
        midi_player.state.is_playing = true;

        // Playlist Loop
        while (midi_player.state.is_playing) {
            if (midi_player.state.playlist.items.len == 0) {
                std.debug.print("No MIDI files found in playlist.\n", .{});
                break;
            }

            if (midi_player.state.current_index >= midi_player.state.playlist.items.len) {
                midi_player.state.current_index = 0;
            }

            // Save Config on track change
            config.volume = midi_player.state.volume;
            config.loop_mode = midi_player.state.is_looping;
            config.last_played_index = midi_player.state.current_index;
            config.save(allocator) catch {};

            const current_midi_name = midi_player.state.playlist.items[midi_player.state.current_index];
            const current_midi_path_slice = try std.fs.path.join(allocator, &[_][]const u8{ "midis", current_midi_name });
            defer allocator.free(current_midi_path_slice);
            const current_midi_path = try allocator.dupeZ(u8, current_midi_path_slice);
            defer allocator.free(current_midi_path);

            // Play File with Analysis
            midi_player.loadAndAnalyzeMidi(current_midi_path) catch |err| {
                std.debug.print("Failed to load MIDI file: {s} ({})\n", .{ current_midi_path, err });
                midi_player.state.current_index += 1;
                continue;
            };

            // Initial Draw
            try drawUI(midi_player, current_midi_name);

            var track_finished = false;
            var next_track = false;
            var prev_track = false;

            // Track Playback Loop
            while (!track_finished and midi_player.state.is_playing) {
                // Poll for keyboard input
                if (try checkInput()) |k| {
                    switch (k) {
                        'q', 27 => { // ESC
                            midi_player.state.is_playing = false;
                        },
                        ' ' => {
                            midi_player.togglePause();
                            try drawUI(midi_player, current_midi_name);
                        },
                        'l' => {
                            midi_player.state.is_looping = !midi_player.state.is_looping;
                            try drawUI(midi_player, current_midi_name);
                        },
                        'n' => {
                            next_track = true;
                            track_finished = true;
                        },
                        'p' => {
                            prev_track = true;
                            track_finished = true;
                        },
                        '+', '=' => {
                            midi_player.adjustVolume(0.1);
                            try drawUI(midi_player, current_midi_name);
                        },
                        '-', '_' => {
                            midi_player.adjustVolume(-0.1);
                            try drawUI(midi_player, current_midi_name);
                        },
                        '/' => {
                            try self.searchMode(midi_player, allocator);
                            track_finished = true;
                            next_track = false;
                            prev_track = false;
                        },
                        else => {},
                    }
                }

                // Update Progress UI periodically
                try drawProgress(midi_player);

                // Check status
                if (!midi_player.isPlaying() and !midi_player.state.is_paused) {
                    if (midi_player.state.is_looping) {
                        midi_player.restart();
                    } else {
                        track_finished = true;
                        next_track = true;
                    }
                }

                _ = c.usleep(100000); // 100ms
            }

            midi_player.stop();

            if (next_track) {
                midi_player.state.current_index += 1;
            } else if (prev_track) {
                if (midi_player.state.current_index > 0) {
                    midi_player.state.current_index -= 1;
                } else {
                    midi_player.state.current_index = midi_player.state.playlist.items.len - 1;
                }
            }
        }

        // Final Save
        config.volume = midi_player.state.volume;
        config.loop_mode = midi_player.state.is_looping;
        config.last_played_index = midi_player.state.current_index;
        config.save(allocator) catch {};
    }
};

// Helper functions

/// Case-insensitive substring matching for search
fn matchesQuery(midi: []const u8, query: []const u8) bool {
    if (query.len == 0) return true;
    if (midi.len < query.len) return false;

    for (0..(midi.len - query.len + 1)) |i| {
        if (std.ascii.eqlIgnoreCase(midi[i .. i + query.len], query)) {
            return true;
        }
    }
    return false;
}

/// Draw MIDI file information
fn drawMidiInfo(player: *player_mod.MidiPlayer) !void {
    if (player.getMidiInfo()) |info| {
        std.debug.print("\x1b[1;36mMIDI File Info:\x1b[0m\n", .{});
        std.debug.print("  Format: Type {}\n", .{info.format});
        std.debug.print("  Tracks: {}\n", .{info.num_tracks});
        std.debug.print("  Division: {} ticks/quarter\n", .{info.division});
        std.debug.print("  Events: {}\n\n", .{info.total_events});
    }
}

/// Draw the main UI with player status
fn drawUI(player: *player_mod.MidiPlayer, current_name: []const u8) !void {
    std.debug.print("\x1b[2J\x1b[H", .{}); // Clear screen
    std.debug.print("\x1b[1;36mMIDI Player\x1b[0m\n\n", .{}); // Cyan Header

    // Add MIDI file info
    try drawMidiInfo(player);

    std.debug.print("Now Playing: \x1b[1m{s}\x1b[0m ({d}/{d})\n", .{ current_name, player.state.current_index + 1, player.state.playlist.items.len });

    const status_color = if (player.state.is_paused) "\x1b[33mPAUSED\x1b[0m" else "\x1b[32mPLAYING\x1b[0m";
    const loop_status = if (player.state.is_looping) "\x1b[35mON\x1b[0m" else "OFF";

    std.debug.print("Status: {s}   Loop: {s}   Volume: {d:.1}\n\n", .{ status_color, loop_status, player.state.volume });

    std.debug.print("Controls:\n", .{});
    std.debug.print("  [Space] Pause/Resume   [n] Next   [p] Prev\n", .{});
    std.debug.print("  [l] Loop               [+/-] Volume\n", .{});
    std.debug.print("  [/] Search             [q] Quit\n\n", .{});
}

/// Draw progress bar with active voice visualizer
fn drawProgress(player: *player_mod.MidiPlayer) !void {
    const progress = player.getProgress();
    const voices = player.getActiveVoiceCount();

    // Simple visualizer: bar graph of active voices
    const bar_len = @min(@as(usize, @intCast(@divTrunc(voices, 2))), 20);
    var bar_buf: [21]u8 = undefined;
    for (0..bar_len) |i| bar_buf[i] = '|';
    bar_buf[bar_len] = 0;
    const bar = bar_buf[0..bar_len];

    if (progress.total > 0) {
        const percent = @as(f64, @floatFromInt(progress.current)) / @as(f64, @floatFromInt(progress.total)) * 100.0;
        std.debug.print("\rProgress: {d}/{d} ticks ({d:.1}%)  Activity: \x1b[1;32m{s}\x1b[0m\x1b[K", .{ progress.current, progress.total, percent, bar });
    }
}

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

// Terminal handling functions

/// Set terminal to raw mode for immediate key detection
pub fn setupRawMode() !void {
    const stdin_fd = std.posix.STDIN_FILENO;
    _ = c.tcgetattr(stdin_fd, &original_termios);

    var raw = original_termios;
    raw.c_lflag &= ~@as(c_uint, c.ICANON | c.ECHO);
    raw.c_cc[c.VMIN] = 0;
    raw.c_cc[c.VTIME] = 0;

    _ = c.tcsetattr(stdin_fd, c.TCSAFLUSH, &raw);
}

/// Restore original terminal settings
pub fn restoreMode() void {
    _ = c.tcsetattr(std.posix.STDIN_FILENO, c.TCSAFLUSH, &original_termios);
}

/// Check for keyboard input (non-blocking)
fn checkInput() !?u8 {
    const stdin = std.fs.File.stdin();
    var buf: [1]u8 = undefined;
    const bytes_read = try stdin.read(&buf);
    return if (bytes_read > 0) buf[0] else null;
}
