# Developer Guide

## Overview

This guide provides comprehensive information for developers working on the MIDI Player project. The codebase follows Zig best practices with a focus on performance, maintainability, and clean architecture.

## Getting Started

### Prerequisites

- **Zig**: Version 0.15+ (download from [ziglang.org](https://ziglang.org))
- **FluidSynth**: Development libraries
- **ALSA**: Audio development libraries

#### Ubuntu/Debian Installation
```bash
sudo apt update
sudo apt install libfluidsynth-dev libasound2-dev
```

#### Arch Linux Installation
```bash
sudo pacman -S fluidsynth alsa-lib
```

### Building

```bash
# Standard build
zig build

# Build with copy to root directory
zig build && zig build copy-exe

# Debug build (default)
zig build -Doptimize=Debug

# Release build
zig build -Doptimize=ReleaseFast

# Run directly
zig build run -- <midi_file>
```

### Development Workflow

1. **Clone and setup**:
   ```bash
   git clone <repository>
   cd midi_player
   zig build
   ```

2. **Make changes**:
   - Follow code style guidelines (see AGENTS.md)
   - Run `zig fmt` before committing
   - Test changes manually

3. **Test changes**:
   ```bash
   ./midi_player --                    # List MIDIs
   ./midi_player demo.mid             # Test playback
   ./midi_player demo.mid soundfonts/standard-midisf.sf2  # Test SoundFont
   ```

## Project Structure

```
midi_player/
├── src/
│   ├── main.zig          # Application entry point, CLI, UI
│   ├── player.zig        # FluidSynth abstraction layer
│   ├── config.zig        # Configuration management
│   └── test_*.zig        # Development utilities
├── docs/
│   ├── API.md            # API reference
│   └── ARCHITECTURE.md   # Architecture documentation
├── midis/                # MIDI test files
├── soundfonts/           # SoundFont test files
├── build.zig             # Build configuration
├── AGENTS.md             # Development standards
└── README.md             # User documentation
```

## Architecture Overview

### Layered Architecture

The codebase follows a clean architecture with three layers:

1. **Application Layer** (`main.zig`)
   - User interface and interaction
   - Command-line argument processing
   - Event loop and state management

2. **Domain Layer** (`player.zig`)
   - Business logic for MIDI playback
   - FluidSynth integration
   - Audio state management

3. **Infrastructure Layer** (`config.zig`)
   - Configuration persistence
   - External system integration

### Key Design Patterns

#### RAII (Resource Acquisition Is Initialization)

All resources are managed with automatic cleanup:

```zig
var player = try MidiPlayer.init(allocator);
defer player.deinit(); // Automatic cleanup
```

#### Error Propagation

Explicit error handling with custom error types:

```zig
pub fn playFile(self: *MidiPlayer, path: [:0]const u8) !void {
    // Errors propagate up the call stack
    if (c.fluid_player_add(self.player, path) != 0) {
        return error.MidiLoadFailed;
    }
}
```

#### State Encapsulation

Runtime state is contained in structs:

```zig
pub const PlayerState = struct {
    current_index: usize,
    playlist: std.ArrayList([]const u8),
    is_playing: bool,
    // ... other fields
};
```

## Code Style Guidelines

### Naming Conventions

- **Functions**: camelCase (`printUsage`, `loadPlaylist`)
- **Structs/Enums**: PascalCase (`MidiPlayer`, `PlayerState`)
- **Variables/Fields**: snake_case (`midi_path`, `current_index`)
- **Constants**: SCREAMING_SNAKE_CASE (`DEFAULT_VOLUME`)
- **Files**: snake_case (`main.zig`, `player.zig`)

### Formatting

- Use `zig fmt` for consistent formatting
- Maximum line length: 100 characters
- 4-space indentation (Zig standard)

### Error Handling

- Use explicit error returns (`!T`) instead of panics
- Define custom error types for different failure modes
- Provide meaningful error messages

```zig
pub const PlayerError = error{
    FluidSynthInitFailed,
    SoundFontLoadFailed,
    MidiLoadFailed,
};
```

### Memory Management

- Prefer stack allocation for small, temporary data
- Use arena allocators for scoped allocations
- Explicit allocation/deallocation for persistent data
- RAII pattern with defer statements

### Documentation

- Document all public functions with parameter/return descriptions
- Use `//!` for module-level documentation
- Include usage examples where helpful

```zig
//! MIDI Player - A simple CLI MIDI player using FluidSynth and ALSA
//! Built with Zig following KISS principles: Keep It Simple, Stupid

/// Initializes a new MIDI player with FluidSynth components.
/// Returns a MidiPlayer instance or an error if initialization fails.
pub fn init(allocator: std.mem.Allocator) !MidiPlayer
```

## Development Utilities

### Test Files

The project includes development utilities in `src/test_*.zig`:

- **test_json.zig**: Explore Zig's JSON API at compile time
- **test_io.zig**: Explore Zig's I/O API at compile time

Usage:
```bash
zig run src/test_json.zig  # Compile-time API exploration
```

### Build System

Custom build steps in `build.zig`:

- **install**: Standard Zig install
- **copy-exe**: Copy executable to project root
- **run**: Run the application

### Debugging

- Use `std.debug.print` for debug output
- Check FluidSynth logs for audio issues
- Use `zig build -Doptimize=Debug` for debug builds

## Adding New Features

### 1. Planning

- Consider architectural impact
- Follow existing patterns
- Update documentation

### 2. Implementation

- Add feature to appropriate module
- Follow code style guidelines
- Include error handling
- Update public API documentation

### 3. Testing

- Manual testing with various scenarios
- Edge case validation
- Performance impact assessment

### 4. Documentation

- Update API documentation
- Update user-facing documentation
- Add examples if needed

## Common Development Tasks

### Adding a New Control

1. Add key handling in `main.zig` event loop:
```zig
case 'x' => {
    // Handle new key press
    try handleNewFeature(&midi_player);
}
```

2. Implement the handler function:
```zig
fn handleNewFeature(player: *MidiPlayer) !void {
    // Feature implementation
}
```

3. Update UI help text in `drawUI()`.

### Adding Configuration

1. Add field to `Config` struct in `config.zig`:
```zig
pub const Config = struct {
    // ... existing fields ...
    new_feature_enabled: bool = false,
};
```

2. Use in application code:
```zig
if (config.new_feature_enabled) {
    // Enable feature
}
```

3. Configuration persists automatically.

### Adding Audio Features

1. Extend `MidiPlayer` in `player.zig`:
```zig
pub fn newFeature(self: *MidiPlayer) void {
    // FluidSynth API calls
    _ = c.fluid_synth_some_function(self.synth);
}
```

2. Add public method to header.

### Error Handling

1. Define new error in appropriate error set:
```zig
pub const PlayerError = error{
    // ... existing errors ...
    NewFeatureFailed,
};
```

2. Return error from functions:
```zig
if (!success) return error.NewFeatureFailed;
```

## Testing Strategy

### Manual Testing Checklist

- [ ] Build succeeds without warnings
- [ ] `--` lists all MIDI files
- [ ] Playback starts without errors
- [ ] All keyboard controls work
- [ ] Volume control functions
- [ ] Search functionality works
- [ ] Configuration persists between runs
- [ ] Error cases handled gracefully

### Edge Cases to Test

- Empty MIDI directory
- Missing SoundFont file
- Corrupted MIDI files
- Terminal resize during playback
- Rapid key presses
- Very long playlists
- Special characters in filenames

### Performance Testing

- Memory usage with large playlists
- CPU usage during playback
- Startup time
- Response time to controls

## Troubleshooting

### Build Issues

**Missing dependencies**:
```bash
# Ubuntu/Debian
sudo apt install libfluidsynth-dev libasound2-dev

# Check versions
pkg-config --modversion fluidsynth
pkg-config --modversion alsa
```

**Zig version issues**:
```bash
zig version  # Should be 0.15+
```

### Runtime Issues

**No audio output**:
- Check ALSA configuration: `aplay -l`
- Verify SoundFont exists and is valid
- Check FluidSynth logs for errors

**Terminal issues**:
- Raw mode not restored: Reset terminal with `reset` command
- Input not responsive: Check for background processes

**Configuration issues**:
- Config file location: `~/.config/midi_player/config.json`
- Reset config by deleting the file

### Debug Output

Enable debug logging:
```zig
std.debug.print("Debug: value = {}\n", .{value});
```

Check FluidSynth debug output by modifying settings:
```zig
_ = c.fluid_settings_setint(settings, "synth.verbose", 1);
```

## Contributing

### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/new-feature`
3. **Implement** changes following guidelines
4. **Test** thoroughly
5. **Update** documentation
6. **Commit** with clear messages: `git commit -m "Add new feature"`
7. **Push** to branch: `git push origin feature/new-feature`
8. **Create** pull request

### Commit Guidelines

- Use clear, descriptive commit messages
- Reference issue numbers when applicable
- Keep commits focused on single changes
- Run `zig fmt` before committing

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Error handling is appropriate
- [ ] Memory management is correct
- [ ] Documentation is updated
- [ ] Tests pass
- [ ] No breaking changes without discussion

## Performance Optimization

### Profiling

Use Zig's time report:
```bash
zig build -ftime-report
```

### Memory Optimization

- Minimize allocations in hot paths
- Use stack allocation for small buffers
- Consider arena allocators for scoped work
- Profile with `valgrind` if available

### CPU Optimization

- Direct C API calls (no wrappers)
- Efficient polling loops
- Minimize string operations
- Consider SIMD for audio processing (future)

## Future Development

### Planned Features

- **GUI Interface**: Replace terminal UI with graphical interface
- **Network Support**: Stream MIDI over network
- **Plugin System**: Loadable audio effects
- **Multiple Formats**: Support for additional audio formats

### Architecture Improvements

- **Async/Await**: Modern concurrency model
- **Error Tracing**: Better error context and debugging
- **Configuration UI**: In-app settings management
- **Logging Framework**: Structured logging system

### Testing Infrastructure

- **Unit Tests**: Comprehensive test coverage
- **Integration Tests**: End-to-end testing
- **Performance Benchmarks**: Automated performance testing
- **CI/CD Pipeline**: Automated testing and deployment

## Resources

### Documentation

- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [FluidSynth API](https://www.fluidsynth.org/api/)
- [ALSA Documentation](https://www.alsa-project.org/alsa-doc/alsa-lib/)

### Community

- [Zig Discord](https://discord.gg/zig)
- [FluidSynth Mailing List](https://lists.nongnu.org/mailman/listinfo/fluid-dev)
- [ALSA Development](https://www.alsa-project.org/)

### Tools

- **Zig LSP**: Language server for editors
- **ZLS**: Zig language server implementation
- **FluidSynth CLI**: Command-line testing tool

---

This guide is maintained alongside the codebase. Please update it when making significant changes to development processes or architecture.