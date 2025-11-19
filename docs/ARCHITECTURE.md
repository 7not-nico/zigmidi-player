# Architecture Documentation

## Overview

The MIDI Player follows a modular, KISS-compliant architecture built with Zig. This document explains the design patterns, data flow, and architectural decisions that shape the codebase.

## Core Architecture

### Modular Design

The application evolved from a single-file implementation to a clean modular architecture:

```
src/
├── main.zig      # CLI, UI, event loop (397 lines)
├── player.zig    # FluidSynth abstraction (136 lines)
├── config.zig    # Configuration management (61 lines)
├── test_*.zig    # Development utilities
└── build.zig     # Build configuration
```

### Separation of Concerns

**main.zig** - Application Layer
- Command-line interface
- User interaction (keyboard input, UI rendering)
- Event loop and state management
- File system operations (playlist loading, path resolution)

**player.zig** - Domain Layer
- FluidSynth integration
- MIDI playback abstraction
- Audio state management
- Progress tracking

**config.zig** - Infrastructure Layer
- Configuration persistence
- User settings management
- JSON serialization/deserialization

## Design Patterns

### RAII (Resource Acquisition Is Initialization)

All resources follow RAII with defer-based cleanup:

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit(); // Automatic cleanup

var player = try MidiPlayer.init(allocator);
defer player.deinit(); // FluidSynth cleanup
```

### State Encapsulation

Runtime state is encapsulated in structs, avoiding global variables:

```zig
pub const PlayerState = struct {
    current_index: usize,
    playlist: std.ArrayList([]const u8),
    is_playing: bool,
    is_looping: bool,
    is_paused: bool,
    volume: f32,
};
```

### Error Propagation

Explicit error handling with custom error types:

```zig
pub const MidiPlayer = struct {
    // ... fields ...

    pub fn init(allocator: std.mem.Allocator) !MidiPlayer {
        // Return custom errors for different failure modes
        const settings = c.new_fluid_settings() orelse return error.FluidSynthInitFailed;
        // ...
    }
};
```

### Builder Pattern (FluidSynth Integration)

FluidSynth components are built step-by-step:

```zig
pub fn init(allocator: std.mem.Allocator) !MidiPlayer {
    const settings = c.new_fluid_settings();
    const synth = c.new_fluid_synth(settings);
    const adriver = c.new_fluid_audio_driver(settings, synth);
    // Components depend on each other in order
}
```

## Data Flow

### Application Startup

```
CLI Args → main() → Config.load() → MidiPlayer.init()
    ↓              ↓              ↓
resolveMidiPath() → loadPlaylist() → loadSoundFont()
    ↓              ↓              ↓
playFile() → Event Loop → UI Updates
```

### Playback Loop

```
Event Loop
    ↓
checkInput() → Handle Key → Update State
    ↓              ↓              ↓
drawProgress() → Check Status → Next Track
    ↓              ↓              ↓
Config.save() → Continue Loop
```

### Search Functionality

```
User presses '/' → handleSearch()
    ↓
restoreMode() → Read Input → Filter Playlist
    ↓              ↓              ↓
setupRawMode() → Update Index → Continue Playback
```

## FluidSynth Integration

### Component Hierarchy

```
fluid_settings_t (configuration)
    ↓
fluid_synth_t (synthesis engine)
    ↓
fluid_audio_driver_t (ALSA output)
fluid_player_t (MIDI sequencer)
```

### Direct C API Usage

No wrapper libraries - direct C function calls for maximum performance:

```zig
// Direct mapping to FluidSynth C API
const sf_id = c.fluid_synth_sfload(self.synth, path, 1);
const status = c.fluid_player_get_status(self.player);
```

### Audio Backend Configuration

ALSA backend selected explicitly:

```zig
_ = c.fluid_settings_setstr(settings, "audio.driver", "alsa");
```

## Memory Management

### Allocation Strategies

**Arena Allocator**: Used for temporary allocations in main function
- Automatic cleanup on function exit
- Efficient for short-lived objects
- Used for CLI args, path construction, temporary strings

**Explicit Allocation**: Used for persistent data
- Playlist filenames
- Configuration strings
- Manual deallocation required

### Ownership Model

**Single Ownership**: Each allocation has one clear owner
**Defer Cleanup**: Resources cleaned up in reverse order of acquisition
**No Reference Counting**: Manual memory management throughout

## State Management

### Runtime State

All application state centralized in `PlayerState`:

```zig
pub const PlayerState = struct {
    // Playlist state
    current_index: usize,
    playlist: std.ArrayList([]const u8),

    // Playback state
    is_playing: bool,
    is_looping: bool,
    is_paused: bool,

    // Audio state
    volume: f32,
};
```

### Configuration State

Persistent settings in `Config`:

```zig
pub const Config = struct {
    volume: f32,              // Session persistence
    last_played_index: usize, // Resume playback
    loop_mode: bool,          // User preference
    soundfont_path: []const u8, // User choice
};
```

### State Synchronization

Configuration updated during playback:

```zig
// Save state on track changes
config.volume = midi_player.state.volume;
config.loop_mode = midi_player.state.is_looping;
config.last_played_index = midi_player.state.current_index;
config.save(allocator) catch {}; // Ignore save errors
```

## Event Handling

### Polling-Based Input

Non-blocking keyboard input with 100ms polling:

```zig
while (condition) {
    if (try checkInput()) |key| {
        // Handle key press
    }
    // Update UI
    _ = c.usleep(100000); // 100ms delay
}
```

### Terminal Mode Management

Raw mode for immediate input, restored on exit:

```zig
try setupRawMode();
defer restoreMode(); // Always restore terminal
```

## File System Integration

### Path Resolution Strategy

Smart MIDI file location with fallbacks:

```zig
fn resolveMidiPath(command: []const u8, allocator: std.mem.Allocator) ![:0]const u8 {
    // 1. Absolute paths
    if (std.fs.path.isAbsolute(command)) return allocator.dupeZ(u8, command);

    // 2. Check midis/ directory
    const midi_path = try std.fs.path.join(allocator, &[_][]const u8{ "midis", command });
    if (std.fs.cwd().access(midi_path, .{})) |_| {
        return allocator.dupeZ(u8, midi_path);
    } else |_| {
        // 3. Auto-append .mid extension
        const with_ext = try std.mem.concat(allocator, &[_][]const u8{ command, ".mid" });
        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ "midis", with_ext });
        // ...
    }
}
```

### Directory Structure

Organized project layout:

```
midi_player/
├── midis/           # MIDI files (.mid)
├── soundfonts/      # SoundFont files (.sf2)
├── src/            # Source code
└── docs/           # Documentation
```

## Error Handling Strategy

### Error Types

Custom error set for different failure modes:

```zig
// Player errors
FluidSynthInitFailed
SoundFontLoadFailed
MidiLoadFailed

// Application errors
MidiFileNotFound
HomeNotFound
```

### Error Propagation

Errors bubble up through the call stack:

```zig
pub fn main() !void {
    // Errors from init propagate to main
    var midi_player = try player_mod.MidiPlayer.init(allocator);
    // Errors from playFile propagate to main
    try midi_player.playFile(current_midi_path);
}
```

### Graceful Degradation

Non-critical errors don't crash the application:

```zig
// Config save errors ignored
config.save(allocator) catch {};
// Continue execution
```

## Performance Considerations

### Direct C Calls

No abstraction layers between Zig and FluidSynth:

```zig
// Direct C function call - no overhead
const voices = c.fluid_synth_get_active_voice_count(synth);
```

### Minimal Allocations

Stack-based operations where possible:

```zig
var buf: [256]u8 = undefined; // Stack allocation
if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    // Process input
}
```

### Efficient Polling

Balanced polling frequency for responsiveness vs. CPU usage:

```zig
_ = c.usleep(100000); // 100ms - responsive but not wasteful
```

## Testing Strategy

### Development Utilities

Compile-time reflection for API exploration:

```zig
// test_json.zig - Explore JSON API
pub fn main() void {
    @compileLog(@typeInfo(std.json).@"struct".decls);
}
```

### Manual Testing

Comprehensive manual test procedures in README.md covering:
- Build verification
- MIDI listing
- Playback testing
- Control validation

## Extensibility Points

### Audio Backend

Easy to extend to other backends:

```zig
// Change audio driver
_ = c.fluid_settings_setstr(settings, "audio.driver", "pulseaudio");
// or "jack", "oss", etc.
```

### Configuration

JSON-based config easily extensible:

```zig
pub const Config = struct {
    // Add new fields
    new_feature: bool = false,
    custom_setting: []const u8 = "default",
};
```

### UI Framework

Terminal UI abstracted into functions:

```zig
fn drawUI(player: *MidiPlayer, current_name: []const u8) !void {
    // Easily replaceable with GUI framework
}
```

## Development Workflow

### Build System

Standard Zig build with custom steps:

```zig
// build.zig
const exe = b.addExecutable(.{
    .name = "midi_player",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }),
});

// Link external libraries
exe.linkLibC();
exe.linkSystemLibrary("fluidsynth");
exe.linkSystemLibrary("asound");
```

### Code Organization

Consistent naming and structure:

- **Functions**: camelCase (`printUsage`, `loadPlaylist`)
- **Structs**: PascalCase (`MidiPlayer`, `PlayerState`)
- **Variables**: snake_case (`midi_path`, `current_index`)
- **Files**: snake_case (`main.zig`, `player.zig`)

### Documentation

Comprehensive documentation maintained alongside code:
- API documentation in `docs/API.md`
- Architecture guide in `docs/ARCHITECTURE.md`
- User guide in `README.md`
- Development notes in `AGENTS.md`

This architecture provides a solid foundation for a maintainable, extensible MIDI player while adhering to KISS principles and Zig best practices.