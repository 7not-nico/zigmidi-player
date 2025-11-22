//! MIDI Player - A simple CLI MIDI player using FluidSynth and ALSA
//! Built with Zig following KISS principles: Keep It Simple, Stupid

const std = @import("std");
const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("termios.h");
});
const player_mod = @import("player.zig");
const config_mod = @import("config.zig");

// Main entry point - handles CLI args, FluidSynth setup, and playback loop
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check for profiling flag
    var profiling = false;
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--profile")) {
            profiling = true;
            break;
        }
    }

    // Load Config
    var config = config_mod.Config.load(allocator) catch config_mod.Config{};
    // We don't defer config deinit because it might have allocated strings we want to keep for now,
    // but actually we are using an arena so it's fine.
    // Wait, Config.load duplicates strings into the allocator passed.

    // Initialize Player
    var midi_player = try player_mod.MidiPlayer.init(allocator);
    defer midi_player.deinit();

    // Apply Config
    midi_player.setVolume(config.volume);
    midi_player.state.is_looping = config.loop_mode;
    midi_player.state.current_index = config.last_played_index;

    // Load available MIDI files from midis/ directory
    if (profiling) std.debug.print("Loading playlist...\n", .{});
    const playlist_start = std.time.milliTimestamp();
    try loadPlaylist(&midi_player.state.playlist, allocator);
    const playlist_end = std.time.milliTimestamp();
    if (profiling) std.debug.print("Playlist load time: {} ms ({} files)\n", .{ playlist_end - playlist_start, midi_player.state.playlist.items.len });

    // Load preferred soundfont
    // Use config soundfont if available, otherwise default
    // We need to cast config.soundfont_path to [:0]const u8
    const soundfont_path_slice = if (args.len > 2) args[2] else config.soundfont_path;
    const soundfont_path = try allocator.dupeZ(u8, soundfont_path_slice);

    if (profiling) std.debug.print("Loading soundfont: {s}\n", .{soundfont_path});
    const soundfont_start = std.time.milliTimestamp();
    try midi_player.loadSoundFont(soundfont_path);
    const soundfont_end = std.time.milliTimestamp();
    if (profiling) std.debug.print("Soundfont load time: {} ms\n", .{soundfont_end - soundfont_start});

    // Set up raw terminal mode
    try setupRawMode();
    defer restoreMode();

    if (args.len < 2) {
        // Interactive Search Mode
        try searchAndFilter(&midi_player, allocator);
    } else {
        // Handle list command
        const command = args[1];
        if (std.mem.eql(u8, command, "--")) {
            try listMidis(midi_player.state.playlist.items);
            return;
        }

        // Resolve MIDI file path (searches midis/ directory first)
        // If command is NOT a file path (e.g. just starting the player), we might want to use the last played index.
        // But currently the CLI requires an argument.
        // Let's support `midi_player resume` or just `midi_player` (if we change args check).
        // For now, let's keep existing behavior: if arg is provided, it overrides config.
        // But if the arg matches a file in the playlist, we set the index.

        const initial_midi_path = try resolveMidiPath(command, allocator);
        defer allocator.free(initial_midi_path);

        // Find index of initial midi in playlist
        var found_arg_in_playlist = false;
        for (midi_player.state.playlist.items, 0..) |item, i| {
            if (std.mem.endsWith(u8, initial_midi_path, item) or std.mem.eql(u8, initial_midi_path, item)) {
                midi_player.state.current_index = i;
                found_arg_in_playlist = true;
                break;
            }
        }

        // If the argument wasn't found in playlist (e.g. absolute path outside), we play it but index might be wrong.
        // If it WAS found, we updated index.
    }

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
        config.save(allocator) catch {}; // Ignore save errors for now

        const current_midi_name = midi_player.state.playlist.items[midi_player.state.current_index];
        const current_midi_path_slice = try std.fs.path.join(allocator, &[_][]const u8{ "midis", current_midi_name });
        defer allocator.free(current_midi_path_slice);
        const current_midi_path = try allocator.dupeZ(u8, current_midi_path_slice);
        defer allocator.free(current_midi_path);

        // Play File
        midi_player.playFile(current_midi_path) catch |err| {
            std.debug.print("Failed to load MIDI file: {s} ({})\n", .{ current_midi_path, err });
            midi_player.state.current_index += 1;
            continue;
        };

        // Initial Draw
        try drawUI(&midi_player, current_midi_name);

        var track_finished = false;
        var next_track = false;
        var prev_track = false;

        // Track Playback Loop
        while (!track_finished and midi_player.state.is_playing) {
            // Poll for keyboard input
            if (try checkInput()) |key| {
                switch (key) {
                    'q', 27 => { // ESC
                        midi_player.state.is_playing = false;
                    },
                    ' ' => {
                        midi_player.togglePause();
                        try drawUI(&midi_player, current_midi_name);
                    },
                    'l' => {
                        midi_player.state.is_looping = !midi_player.state.is_looping;
                        try drawUI(&midi_player, current_midi_name);
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
                        try drawUI(&midi_player, current_midi_name);
                    },
                    '-', '_' => {
                        midi_player.adjustVolume(-0.1);
                        try drawUI(&midi_player, current_midi_name);
                    },
                    '/' => {
                        try handleSearch(&midi_player, allocator);
                        // Break inner loop to reload current track/playlist
                        track_finished = true;
                        // If handleSearch sets current_index = 0, and we want to play that,
                        // we should ensure next_track and prev_track are false so the outer loop
                        // doesn't modify current_index further.
                        next_track = false;
                        prev_track = false;
                    },
                    else => {},
                }
            }

            // Update Progress UI periodically
            try drawProgress(&midi_player);

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

fn handleSearch(midi_player: *player_mod.MidiPlayer, allocator: std.mem.Allocator) !void {
    // We assume we are already in Raw Mode from main loop
    try searchAndFilter(midi_player, allocator);
}

fn searchAndFilter(midi_player: *player_mod.MidiPlayer, allocator: std.mem.Allocator) !void {
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
            var match = true;
            if (query.items.len > 0) {
                match = false;
                // Case-insensitive substring search
                // Simple brute force
                if (midi.len >= query.items.len) {
                    for (0..(midi.len - query.items.len + 1)) |i| {
                        if (std.ascii.eqlIgnoreCase(midi[i .. i + query.items.len], query.items)) {
                            match = true;
                            break;
                        }
                    }
                }
            }

            if (match) {
                if (matches_count < 15) {
                    std.debug.print("  {s}\n", .{midi});
                }
                matches_count += 1;
            }
        }
        if (matches_count > 15) {
            std.debug.print("  ... and {d} more\n", .{matches_count - 15});
        }

        // Blocking read for responsiveness (or tight loop with sleep)
        // Since we are in raw mode with VMIN=0, checkInput is non-blocking.
        // We can loop until input.
        var key: ?u8 = null;
        while (key == null) {
            key = try checkInput();
            if (key == null) _ = c.usleep(10000); // 10ms wait
        }

        if (key) |k| {
            switch (k) {
                13, 10 => { // Enter
                    // Apply filter
                    // Clear current playlist
                    for (midi_player.state.playlist.items) |item| allocator.free(item);
                    midi_player.state.playlist.clearRetainingCapacity();

                    // Add matches
                    for (all_midis.items) |midi| {
                        var match = true;
                        if (query.items.len > 0) {
                            match = false;
                            if (midi.len >= query.items.len) {
                                for (0..(midi.len - query.items.len + 1)) |i| {
                                    if (std.ascii.eqlIgnoreCase(midi[i .. i + query.items.len], query.items)) {
                                        match = true;
                                        break;
                                    }
                                }
                            }
                        }

                        if (match) {
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

fn drawUI(player: *player_mod.MidiPlayer, current_name: []const u8) !void {
    std.debug.print("\x1b[2J\x1b[H", .{}); // Clear screen
    std.debug.print("\x1b[1;36mMIDI Player\x1b[0m\n\n", .{}); // Cyan Header

    std.debug.print("Now Playing: \x1b[1m{s}\x1b[0m ({d}/{d})\n", .{ current_name, player.state.current_index + 1, player.state.playlist.items.len });

    const status_color = if (player.state.is_paused) "\x1b[33mPAUSED\x1b[0m" else "\x1b[32mPLAYING\x1b[0m";
    const loop_status = if (player.state.is_looping) "\x1b[35mON\x1b[0m" else "OFF";

    std.debug.print("Status: {s}   Loop: {s}   Volume: {d:.1}\n\n", .{ status_color, loop_status, player.state.volume });

    std.debug.print("Controls:\n", .{});
    std.debug.print("  [Space] Pause/Resume   [n] Next   [p] Prev\n", .{});
    std.debug.print("  [l] Loop               [+/-] Volume\n", .{});
    std.debug.print("  [/] Search             [q] Quit\n\n", .{});
}

fn drawProgress(player: *player_mod.MidiPlayer) !void {
    const progress = player.getProgress();
    const voices = player.getActiveVoiceCount();

    // Simple visualizer: bar graph of active voices (scaled, e.g. 1 char per 2 voices)
    // Max voices usually 256, but practical max is lower. Let's cap bar at 20 chars.
    const bar_len = @min(@as(usize, @intCast(@divTrunc(voices, 2))), 20);
    var bar_buf: [21]u8 = undefined;
    for (0..bar_len) |i| bar_buf[i] = '|';
    bar_buf[bar_len] = 0;
    const bar = bar_buf[0..bar_len];

    if (progress.total > 0) {
        const percent = @as(f64, @floatFromInt(progress.current)) / @as(f64, @floatFromInt(progress.total)) * 100.0;
        // Use \r to overwrite line, \x1b[K to clear rest of line
        std.debug.print("\rProgress: {d}/{d} ticks ({d:.1}%)  Activity: \x1b[1;32m{s}\x1b[0m\x1b[K", .{ progress.current, progress.total, percent, bar });
    }
}

// Display usage information and controls
fn printUsage() !void {
    std.debug.print(
        \\MIDI Player - FluidSynth + ALSA
        \\
        \\Usage:
        \\  midi_player --                    # List available MIDIs
        \\  midi_player <midi_file>          # Play MIDI file
        \\  midi_player <midi_file> <sf2>    # Play with custom SoundFont
        \\
    , .{});
}

// Load all MIDI files from the midis/ directory recursively
fn loadPlaylist(playlist: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    var dir = std.fs.cwd().openDir("midis", .{ .iterate = true }) catch return;
    defer dir.close();

    // Recursively load MIDI files from this directory and subdirectories
    try loadPlaylistRecursive(dir, "", playlist, allocator);

    // Sort playlist for consistent order
    std.sort.block([]const u8, playlist.items, {}, struct {
        fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
            return std.mem.lessThan(u8, lhs, rhs);
        }
    }.lessThan);
}

// Helper function to recursively load MIDI files
fn loadPlaylistRecursive(dir: std.fs.Dir, relative_path: []const u8, playlist: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        // Build the relative path for this entry
        const entry_path = if (relative_path.len > 0)
            try std.fs.path.join(allocator, &[_][]const u8{ relative_path, entry.name })
        else
            try allocator.dupe(u8, entry.name);
        defer allocator.free(entry_path);

        switch (entry.kind) {
            .file => {
                // Check if it's a MIDI file
                if (std.mem.endsWith(u8, entry.name, ".mid")) {
                    const name = try allocator.dupe(u8, entry_path);
                    try playlist.append(allocator, name);
                }
            },
            .directory => {
                // Recursively process subdirectory
                var subdir = try dir.openDir(entry.name, .{ .iterate = true });
                defer subdir.close();
                try loadPlaylistRecursive(subdir, entry_path, playlist, allocator);
            },
            else => {},
        }
    }
}

fn listMidis(midis: [][]const u8) !void {
    std.debug.print("Available MIDI files:\n", .{});
    for (midis, 0..) |midi, i| {
        std.debug.print("  {}: {s}\n", .{ i + 1, midi });
    }
}

// Resolve MIDI file path with smart lookup:
// 1. Absolute paths used as-is
// 2. Relative paths checked in midis/ directory
// 3. Auto-append .mid extension if needed
fn resolveMidiPath(command: []const u8, allocator: std.mem.Allocator) ![:0]const u8 {
    // Check if it's an absolute path
    if (std.fs.path.isAbsolute(command)) {
        return allocator.dupeZ(u8, command);
    }

    // Check if it's a file in midis/ directory
    const midi_path = try std.fs.path.join(allocator, &[_][]const u8{ "midis", command });
    if (std.fs.cwd().access(midi_path, .{})) |_| {
        defer allocator.free(midi_path);
        return allocator.dupeZ(u8, midi_path);
    } else |_| {
        // Assume it's a filename without .mid extension
        const with_ext = try std.mem.concat(allocator, u8, &[_][]const u8{ command, ".mid" });
        defer allocator.free(with_ext);
        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ "midis", with_ext });
        if (std.fs.cwd().access(full_path, .{})) |_| {
            defer allocator.free(full_path);
            return allocator.dupeZ(u8, full_path);
        } else |_| {
            return error.MidiFileNotFound;
        }
    }
}

// Load preferred soundfont from config file
fn loadPreferredSoundfont(allocator: std.mem.Allocator) ![:0]const u8 {
    const config_path = "preferred_soundfont.txt";
    const file = std.fs.cwd().openFile(config_path, .{}) catch return "soundfonts/standard-midisf.sf2";
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(content);

    // Trim whitespace
    const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
    return allocator.dupeZ(u8, trimmed);
}

// Terminal handling for interactive controls
var original_termios: c.termios = undefined;

// Set terminal to raw mode for immediate key detection
fn setupRawMode() !void {
    const stdin_fd = std.posix.STDIN_FILENO;
    _ = c.tcgetattr(stdin_fd, &original_termios);

    var raw = original_termios;
    raw.c_lflag &= ~@as(c_uint, c.ICANON | c.ECHO);
    raw.c_cc[c.VMIN] = 0;
    raw.c_cc[c.VTIME] = 0;

    _ = c.tcsetattr(stdin_fd, c.TCSAFLUSH, &raw);
}

// Restore original terminal settings
fn restoreMode() void {
    _ = c.tcsetattr(std.posix.STDIN_FILENO, c.TCSAFLUSH, &original_termios);
}

// Check for keyboard input (non-blocking)
fn checkInput() !?u8 {
    const stdin = std.fs.File.stdin();
    var buf: [1]u8 = undefined;
    const bytes_read = try stdin.read(&buf);
    return if (bytes_read > 0) buf[0] else null;
}

// Removed handleKey as it is now inlined in main loop for better state control
