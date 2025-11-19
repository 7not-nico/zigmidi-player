# MIDI Player API Documentation

## Overview

The MIDI Player is a modular Zig application that provides high-quality MIDI playback using FluidSynth and ALSA. This documentation covers the public API for all modules.

## Module: player.zig

Core MIDI player abstraction providing FluidSynth integration and playback controls.

### PlayerState

Runtime state structure for the MIDI player.

```zig
pub const PlayerState = struct {
    current_index: usize = 0,           // Current track index in playlist
    playlist: std.ArrayList([]const u8), // List of MIDI filenames
    is_playing: bool = false,           // Global playing state
    is_looping: bool = false,           // Loop current track
    is_paused: bool = false,            // Pause state
    volume: f32 = 0.2,                  // Volume level (0.0-10.0)
};
```

### MidiPlayer

Main player struct encapsulating FluidSynth components and state.

```zig
pub const MidiPlayer = struct {
    settings: ?*c.fluid_settings_t,      // FluidSynth settings
    synth: ?*c.fluid_synth_t,           // FluidSynth synthesizer
    adriver: ?*c.fluid_audio_driver_t,   // Audio driver
    player: ?*c.fluid_player_t,         // MIDI player instance
    allocator: std.mem.Allocator,       // Memory allocator
    state: PlayerState,                 // Runtime state
};
```

#### Methods

##### init(allocator: std.mem.Allocator) !MidiPlayer

Initializes a new MIDI player with FluidSynth components.

**Parameters:**
- `allocator`: Memory allocator for internal allocations

**Returns:** New MidiPlayer instance or error

**Errors:**
- `FluidSynthInitFailed`: Failed to create FluidSynth settings
- `FluidSynthSynthFailed`: Failed to create synthesizer
- `FluidSynthAudioFailed`: Failed to create audio driver

**Example:**
```zig
var player = try MidiPlayer.init(allocator);
defer player.deinit();
```

##### deinit()

Cleans up all FluidSynth resources and deallocates playlist memory.

**Note:** Must be called to prevent resource leaks.

##### loadSoundFont(path: [:0]const u8) !void

Loads a SoundFont file for MIDI synthesis.

**Parameters:**
- `path`: Null-terminated path to SoundFont file (.sf2)

**Errors:**
- `SoundFontLoadFailed`: SoundFont file could not be loaded

**Example:**
```zig
try player.loadSoundFont("soundfonts/default.sf2");
```

##### playFile(path: [:0]const u8) !void

Loads and starts playing a MIDI file.

**Parameters:**
- `path`: Null-terminated path to MIDI file (.mid)

**Errors:**
- `FluidSynthPlayerFailed`: Failed to create MIDI player
- `MidiLoadFailed`: Failed to load MIDI file
- `PlaybackFailed`: Failed to start playback

**Example:**
```zig
try player.playFile("midis/song.mid");
```

##### togglePause()

Toggles between play and pause states.

**Note:** Safe to call when no file is loaded.

##### stop()

Stops playback and sets global playing state to false.

**Note:** Safe to call when not playing.

##### setVolume(gain: f32)

Sets the synthesizer volume level.

**Parameters:**
- `gain`: Volume level (clamped to 0.0-10.0 range)

**Note:** Updates both internal state and FluidSynth synthesizer.

##### adjustVolume(delta: f32)

Adjusts volume by a relative amount.

**Parameters:**
- `delta`: Volume change amount (can be negative)

**Example:**
```zig
player.adjustVolume(0.1);  // Increase volume by 0.1
player.adjustVolume(-0.1); // Decrease volume by 0.1
```

##### isPlaying() bool

Returns whether the player is currently playing audio.

**Returns:** `true` if actively playing, `false` otherwise

##### restart()

Restarts the current track from the beginning.

**Note:** Only works if a file is currently loaded.

##### getProgress() struct { current: i32, total: i32 }

Returns playback progress information.

**Returns:** Struct with current and total MIDI ticks

**Example:**
```zig
const progress = player.getProgress();
std.debug.print("Progress: {d}/{d}\n", .{progress.current, progress.total});
```

##### getActiveVoiceCount() i32

Returns the number of currently active synthesizer voices.

**Returns:** Number of active voices (0-256 typically)

**Note:** Useful for visualizing playback activity.

## Module: config.zig

Configuration management with JSON persistence.

### Config

User configuration structure with persistence.

```zig
pub const Config = struct {
    volume: f32 = 0.2,                          // Default volume
    last_played_index: usize = 0,               // Last played track index
    loop_mode: bool = false,                    // Loop mode enabled
    soundfont_path: []const u8 = "soundfonts/standard-midisf.sf2", // SoundFont path
};
```

#### Methods

##### load(allocator: std.mem.Allocator) !Config

Loads configuration from user config file.

**Parameters:**
- `allocator`: Memory allocator for string duplication

**Returns:** Loaded Config or default Config if file doesn't exist

**Errors:** File system errors (except FileNotFound which returns defaults)

**Config File Location:** `~/.config/midi_player/config.json`

**Example JSON:**
```json
{
  "volume": 0.5,
  "last_played_index": 5,
  "loop_mode": true,
  "soundfont_path": "soundfonts/custom.sf2"
}
```

##### save(self: Config, allocator: std.mem.Allocator) !void

Saves configuration to user config file.

**Parameters:**
- `self`: Config instance to save
- `allocator`: Memory allocator for temporary strings

**Errors:** File system errors

**Note:** Creates config directory if it doesn't exist.

## Module: main.zig

Main application logic and CLI interface.

### Functions

#### main() !void

Application entry point handling CLI arguments and main event loop.

**CLI Usage:**
```bash
midi_player                    # Show help
midi_player --                 # List available MIDIs
midi_player <midi_file>        # Play MIDI file
midi_player <midi_file> <sf2>  # Play with custom SoundFont
```

#### printUsage() !void

Prints command-line usage information to stderr.

#### loadPlaylist(playlist: *std.ArrayList([]const u8), allocator: std.mem.Allocator) !void

Loads all MIDI files from the `midis/` directory.

**Parameters:**
- `playlist`: ArrayList to populate with MIDI filenames
- `allocator`: Memory allocator for string duplication

**Note:** Automatically sorts playlist alphabetically.

#### listMidis(midis: [][]const u8) !void

Prints numbered list of available MIDI files.

**Parameters:**
- `midis`: Array of MIDI filenames to display

#### resolveMidiPath(command: []const u8, allocator: std.mem.Allocator) ![:0]const u8

Resolves MIDI file path with smart lookup strategy.

**Parameters:**
- `command`: Filename or path from command line
- `allocator`: Memory allocator for path construction

**Resolution Strategy:**
1. Absolute paths used as-is
2. Check if file exists in `midis/` directory
3. Auto-append `.mid` extension if needed

**Returns:** Null-terminated absolute path

**Errors:**
- `MidiFileNotFound`: File not found in any location

#### drawUI(player: *MidiPlayer, current_name: []const u8) !void

Draws the main user interface with current status.

**Parameters:**
- `player`: Player instance for status information
- `current_name`: Current track filename

#### drawProgress(player: *MidiPlayer) !void

Updates progress display with ticks and voice activity.

**Parameters:**
- `player`: Player instance for progress information

**Features:**
- Progress percentage and tick count
- Voice activity bar graph
- Overwrites current line for smooth updates

### Terminal Control Functions

#### setupRawMode() !void

Configures terminal for raw input mode (immediate key detection).

**Note:** Disables echo and canonical mode.

#### restoreMode()

Restores original terminal settings.

**Note:** Automatically called via defer in main().

#### checkInput() !?u8

Non-blocking keyboard input check.

**Returns:** ASCII character if key pressed, null otherwise

#### handleSearch(midi_player: *MidiPlayer, allocator: std.mem.Allocator) !void

Interactive search functionality for filtering the playlist.

**Parameters:**
- `midi_player`: Player instance to modify
- `allocator`: Memory allocator for string operations

**Behavior:**
- Temporarily restores terminal for input
- Calls searchAndFilter to perform the actual filtering
- Resets to first matching track
- Called when user presses '/' during playback

#### searchAndFilter(midi_player: *MidiPlayer, allocator: std.mem.Allocator) !void

Performs the actual playlist filtering based on user search query.

**Parameters:**
- `midi_player`: Player instance to modify
- `allocator`: Memory allocator for string operations

**Behavior:**
- Reads search query from stdin
- Reloads full playlist
- Filters playlist to items containing the query
- Updates player state with filtered results

### Keyboard Controls

During playback, the following keys are recognized:

- `q`, `ESC`: Quit application
- `Space`: Toggle pause/resume
- `l`: Toggle loop mode
- `n`: Next track
- `p`: Previous track
- `+`, `=`: Increase volume
- `-`, `_`: Decrease volume
- `/`: Enter search mode

## Error Types

### Player Errors
- `FluidSynthInitFailed`: FluidSynth initialization failed
- `FluidSynthSynthFailed`: Synthesizer creation failed
- `FluidSynthAudioFailed`: Audio driver creation failed
- `FluidSynthPlayerFailed`: MIDI player creation failed
- `SoundFontLoadFailed`: SoundFont loading failed
- `MidiLoadFailed`: MIDI file loading failed
- `PlaybackFailed`: Playback start failed

### Application Errors
- `MidiFileNotFound`: MIDI file not found
- `HomeNotFound`: HOME environment variable not set

## Constants

### Default Values
- `DEFAULT_VOLUME`: 0.2
- `VOLUME_MIN`: 0.0
- `VOLUME_MAX`: 10.0
- `POLL_INTERVAL_MS`: 100

### Directory Names
- `MIDIS_DIR`: "midis"
- `SOUNDFONTS_DIR`: "soundfonts"
- `CONFIG_DIR`: ".config/midi_player"
- `CONFIG_FILE`: "config.json"

## Dependencies

### External Libraries
- **FluidSynth**: MIDI synthesis engine
- **ALSA**: Audio output backend
- **Zig Standard Library**: Core functionality

### System Requirements
- Linux with ALSA support
- FluidSynth development libraries
- Zig 0.15+

## Threading

The application is single-threaded. FluidSynth handles internal audio processing threads, but all application logic runs on the main thread.

## Memory Management

- **Arena Allocation**: Main function uses arena allocator for temporary allocations
- **Explicit Allocation**: Playlist strings and config data use explicit allocation
- **RAII Pattern**: All resources cleaned up via defer statements
- **No GC**: Manual memory management throughout