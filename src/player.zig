const std = @import("std");
const c = @cImport({
    @cInclude("fluidsynth.h");
    @cInclude("unistd.h"); // For usleep if needed inside, though main loop handles sleep usually.
});

pub const PlayerState = struct {
    current_index: usize = 0,
    playlist: std.ArrayList([]const u8),
    is_playing: bool = false,
    is_looping: bool = false,
    is_paused: bool = false,
    volume: f32 = 0.2, // Default volume
};

pub const MidiPlayer = struct {
    settings: ?*c.fluid_settings_t,
    synth: ?*c.fluid_synth_t,
    adriver: ?*c.fluid_audio_driver_t,
    player: ?*c.fluid_player_t,
    allocator: std.mem.Allocator,
    state: PlayerState,

    pub fn init(allocator: std.mem.Allocator) !MidiPlayer {
        const settings = c.new_fluid_settings();
        if (settings == null) return error.FluidSynthInitFailed;

        _ = c.fluid_settings_setstr(settings, "audio.driver", "alsa");

        const synth = c.new_fluid_synth(settings);
        if (synth == null) return error.FluidSynthSynthFailed;

        const adriver = c.new_fluid_audio_driver(settings, synth);
        if (adriver == null) return error.FluidSynthAudioFailed;

        // Set initial volume
        _ = c.fluid_synth_set_gain(synth, 0.2);

        return MidiPlayer{
            .settings = settings,
            .synth = synth,
            .adriver = adriver,
            .player = null,
            .allocator = allocator,
            .state = PlayerState{
                .playlist = std.ArrayList([]const u8).empty,
            },
        };
    }

    pub fn deinit(self: *MidiPlayer) void {
        if (self.player) |p| _ = c.delete_fluid_player(p);
        if (self.adriver) |a| _ = c.delete_fluid_audio_driver(a);
        if (self.synth) |s| _ = c.delete_fluid_synth(s);
        if (self.settings) |s| _ = c.delete_fluid_settings(s);
        self.state.playlist.deinit(self.allocator);
    }

    pub fn loadSoundFont(self: *MidiPlayer, path: [:0]const u8) !void {
        const sf_id = c.fluid_synth_sfload(self.synth, path, 1);
        if (sf_id == -1) return error.SoundFontLoadFailed;
    }

    pub fn playFile(self: *MidiPlayer, path: [:0]const u8) !void {
        if (self.player) |p| _ = c.delete_fluid_player(p);

        self.player = c.new_fluid_player(self.synth);
        if (self.player == null) return error.FluidSynthPlayerFailed;

        if (c.fluid_player_add(self.player, path) != 0) return error.MidiLoadFailed;
        if (c.fluid_player_play(self.player) != 0) return error.PlaybackFailed;

        self.state.is_paused = false;
    }

    pub fn togglePause(self: *MidiPlayer) void {
        if (self.player) |p| {
            if (self.state.is_paused) {
                _ = c.fluid_player_play(p);
                self.state.is_paused = false;
            } else {
                _ = c.fluid_player_stop(p);
                self.state.is_paused = true;
            }
        }
    }

    pub fn stop(self: *MidiPlayer) void {
        if (self.player) |p| _ = c.fluid_player_stop(p);
        self.state.is_playing = false;
    }

    pub fn setVolume(self: *MidiPlayer, gain: f32) void {
        var new_gain = gain;
        if (new_gain < 0.0) new_gain = 0.0;
        if (new_gain > 10.0) new_gain = 10.0;
        self.state.volume = new_gain;
        _ = c.fluid_synth_set_gain(self.synth, new_gain);
    }

    pub fn adjustVolume(self: *MidiPlayer, delta: f32) void {
        self.setVolume(self.state.volume + delta);
    }

    pub fn isPlaying(self: *MidiPlayer) bool {
        if (self.player) |p| {
            return c.fluid_player_get_status(p) == c.FLUID_PLAYER_PLAYING;
        }
        return false;
    }

    pub fn restart(self: *MidiPlayer) void {
        if (self.player) |p| {
            _ = c.fluid_player_seek(p, 0);
            _ = c.fluid_player_play(p);
            self.state.is_paused = false;
        }
    }

    pub fn getProgress(self: *MidiPlayer) struct { current: i32, total: i32 } {
        if (self.player) |p| {
            const current = c.fluid_player_get_current_tick(p);
            const total = c.fluid_player_get_total_ticks(p);
            return .{ .current = current, .total = total };
        }
        return .{ .current = 0, .total = 0 };
    }

    pub fn getActiveVoiceCount(self: *MidiPlayer) i32 {
        if (self.synth) |s| {
            return c.fluid_synth_get_active_voice_count(s);
        }
        return 0;
    }
};
