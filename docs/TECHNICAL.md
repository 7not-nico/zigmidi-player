# Technical Documentation

## Architecture Overview

The MIDI Player follows a modular, KISS-compliant architecture with clear separation of concerns:

```
src/
├── main.zig      # Application entry point (~19 lines)
├── app.zig       # Application orchestration (~136 lines)
├── ui.zig        # UI and terminal handling (~322 lines)
├── player.zig    # FluidSynth integration (~135 lines)
└── config.zig    # Configuration management (~60 lines)
```

### Module Responsibilities

- **main.zig**: Minimal entry point, delegates to App
- **app.zig**: Initialization, configuration, mode routing
- **ui.zig**: Search mode, playback mode, terminal control, UI rendering
- **player.zig**: FluidSynth abstraction, MIDI playback, audio state
- **config.zig**: JSON persistence, user settings

## API Reference

### Module: player.zig

#### PlayerState

```zig
pub const PlayerState = struct {
    current_index: usize = 0,
    playlist: std.ArrayList([]const u8),
    is_playing: bool = false,
    is_looping: bool = false,
    is_paused: bool = false,
    volume: f32 = 0.2,
};
```

#### MidiPlayer

```zig
pub const MidiPlayer = struct {
    settings: ?*c.fluid_settings_t,
    synth: ?*c.fluid_synth_t,
    adriver: ?*c.fluid_audio_driver_t,
    player: ?*c.fluid_player_t,
    allocator: std.mem.Allocator,
    state: PlayerState,
};
```

**Methods:**

```zig
// Initialize player with FluidSynth components
pub fn init(allocator: std.mem.Allocator) !MidiPlayer

// Clean up all resources
pub fn deinit()

// Load SoundFont file (.sf2)
pub fn loadSoundFont(path: [:0]const u8) !void

// Load and play MIDI file
pub fn playFile(path: [:0]const u8) !void

// Toggle pause/resume
pub fn togglePause()

// Stop playback
pub fn stop()

// Set volume (0.0-10.0, clamped)
pub fn setVolume(gain: f32)

// Adjust volume by delta
pub fn adjustVolume(delta: f32)

// Check if currently playing
pub fn isPlaying() bool

// Restart current track
pub fn restart()

// Get playback progress (current/total ticks)
pub fn getProgress() struct { current: i32, total: i32 }

// Get active voice count for visualization
pub fn getActiveVoiceCount() i32
```

### Module: config.zig

#### Config

```zig
pub const Config = struct {
    volume: f32 = 0.2,
    last_played_index: usize = 0,
    loop_mode: bool = false,
    soundfont_path: []const u8 = "soundfonts/standard-midisf.sf2",
};
```

**Methods:**

```zig
// Load from ~/.config/midi_player/config.json
pub fn load(allocator: std.mem.Allocator) !Config

// Save to config file
pub fn save(self: Config, allocator: std.mem.Allocator) !void
```

### Module: ui.zig

#### UI

```zig
pub const UI = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) UI
    pub fn deinit(self: *UI) void
    
    // Interactive search/filter mode
    pub fn searchMode(self: *UI, midi_player: *player_mod.MidiPlayer, allocator: std.mem.Allocator) !void
    
    // Main playback loop with controls
    pub fn playbackMode(self: *UI, midi_player: *player_mod.MidiPlayer, config: *config_mod.Config, allocator: std.mem.Allocator) !void
};

// Terminal control
pub fn setupRawMode() !void
pub fn restoreMode() void
```

### Module: app.zig

#### App

```zig
pub const App = struct {
    allocator: std.mem.Allocator,
    midi_player: player_mod.MidiPlayer,
    config: config_mod.Config,
    ui: ui_mod.UI,
    args: []const [:0]const u8,
    
    // Initialize all components
    pub fn init(allocator: std.mem.Allocator, args: []const [:0]const u8) !App
    
    // Clean up resources
    pub fn deinit(self: *App) void
    
    // Run application (search or playback mode)
    pub fn run(self: *App) !void
};
```

## Data Flow

### Application Startup

```
main() → App.init() → Config.load()
                   → MidiPlayer.init()
                   → loadPlaylist()
                   → loadSoundFont()
```

### Playback Loop

```
App.run() → UI.searchMode() [if no args]
        → UI.playbackMode()
            ↓
        Event Loop:
            checkInput() → Handle Key → Update State
            drawProgress() → Check Status
            Config.save() → Continue
```

## Memory Management

### Allocation Strategies

- **Arena Allocator**: main() uses arena for automatic cleanup
- **Explicit Allocation**: Playlist strings, config data
- **RAII Pattern**: All resources cleaned up via defer

### Example

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit(); // Automatic cleanup

var player = try MidiPlayer.init(allocator);
defer player.deinit(); // FluidSynth cleanup
```

## Error Handling

### Error Types

- `FluidSynthInitFailed`: FluidSynth initialization failed
- `SoundFontLoadFailed`: SoundFont loading failed  
- `MidiLoadFailed`: MIDI file loading failed
- `MidiFileNotFound`: File not found
- `HomeNotFound`: HOME environment variable missing

### Error Strategy

```zig
// Critical errors propagate
try midi_player.playFile(path);

// Non-critical errors ignored
config.save(allocator) catch {};
```

## FluidSynth Integration

### Component Hierarchy

```
fluid_settings_t → fluid_synth_t → fluid_audio_driver_t
                                 → fluid_player_t
```

### Direct C API Usage

```zig
const c = @cImport({
    @cInclude("fluidsynth.h");
});

// Direct C function calls - no wrapper overhead
const voices = c.fluid_synth_get_active_voice_count(synth);
```

## Performance

### Optimizations

- **Direct C Calls**: No abstraction layers
- **Stack Allocations**: Where possible
- **Efficient Polling**: 100ms intervals balance responsiveness and CPU usage
- **Arena Allocation**: Batch cleanup for temporary objects

## Build System

```zig
// build.zig
const exe = b.addExecutable(.{
    .name = "midi_player",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
    }),
});

exe.linkLibC();
exe.linkSystemLibrary("fluidsynth");
exe.linkSystemLibrary("asound");
```

### Build Commands

```bash
# Debug build
zig build

# Release build (optimized)
zig build -Doptimize=ReleaseFast

# Copy executable to project root
zig build copy-exe

# Run directly
zig build run -- [args]
```

## Development

### Code Style

- **Functions**: camelCase (`loadPlaylist`, `setupRawMode`)
- **Structs**: PascalCase (`MidiPlayer`, `PlayerState`)
- **Variables**: snake_case (`midi_path`, `current_index`)
- **Files**: snake_case (`main.zig`, `player.zig`)

### Adding Features

**New Control:**

```zig
// In ui.zig playbackMode()
'x' => {
    // Handle custom key
    try handleCustomFeature(midi_player);
},
```

**New Config Field:**

```zig
// In config.zig
pub const Config = struct {
    // ... existing fields ...
    new_feature: bool = false,
};
```

## Dependencies

- **Zig**: 0.13.0+
- **FluidSynth**: Development libraries
- **ALSA**: Linux audio system
- **System**: Linux with ALSA support

## Testing

Build and manual testing:

```bash
# Verify build
zig build

# Test list command
zig build run -- --

# Test playback
zig build run -- demo.mid

# Test search mode
zig build run
# (then type query, press Enter)
```

## Extensibility Points

### Audio Backend

```zig
// Change from ALSA to PulseAudio
_ = c.fluid_settings_setstr(settings, "audio.driver", "pulseaudio");
```

### Custom UI

Replace ui.zig functions with GUI framework while keeping same interface.

### Additional Formats

Extend `loadPlaylist()` to support other file formats beyond `.mid`.
