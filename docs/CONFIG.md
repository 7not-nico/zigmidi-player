# Configuration System

## Overview

The MIDI Player uses a JSON-based configuration system for persistent user settings. Configuration is automatically saved and loaded, allowing users to customize their experience and resume playback sessions.

## Configuration File Location

**Primary Location**: `~/.config/midi_player/config.json`

The configuration directory is created automatically on first save. The file uses standard JSON format for human readability and editing.

## Configuration Schema

### Config Structure

```zig
pub const Config = struct {
    volume: f32 = 0.2,                          // Playback volume (0.0-10.0)
    last_played_index: usize = 0,               // Last played track index
    loop_mode: bool = false,                    // Loop current track
    soundfont_path: []const u8 = "soundfonts/standard-midisf.sf2", // SoundFont path
};
```

### JSON Format

```json
{
  "volume": 0.5,
  "last_played_index": 5,
  "loop_mode": true,
  "soundfont_path": "soundfonts/custom.sf2"
}
```

## Configuration Fields

### volume

**Type**: `f32` (floating point)  
**Range**: 0.0 - 10.0  
**Default**: 0.2  
**Description**: Audio playback volume level

- 0.0 = muted
- 0.2 = default (recommended)
- 1.0 = 100% volume
- 10.0 = maximum amplification

**Note**: Values are clamped to the valid range internally.

### last_played_index

**Type**: `usize` (unsigned integer)  
**Range**: 0 - (playlist length - 1)  
**Default**: 0  
**Description**: Index of the last played track in the playlist

Used to resume playback from the same position in subsequent sessions. Automatically updated when tracks change during playback.

### loop_mode

**Type**: `bool` (boolean)  
**Range**: true/false  
**Default**: false  
**Description**: Whether to loop the current track

- `false`: Play track once, then advance to next
- `true`: Loop current track indefinitely

Can be toggled during playback with the `l` key.

### soundfont_path

**Type**: `string`  
**Default**: "soundfonts/standard-midisf.sf2"  
**Description**: Path to the SoundFont file for MIDI synthesis

Can be:
- Relative path (searched relative to executable)
- Absolute path
- Custom SoundFont for different instrument sounds

## Configuration Lifecycle

### Loading Configuration

Configuration is loaded automatically on application startup:

1. **File Location**: Resolve `~/.config/midi_player/config.json`
2. **File Existence**: Check if configuration file exists
3. **Parse JSON**: Parse JSON content into Config struct
4. **Validation**: Apply defaults for missing fields
5. **String Handling**: Duplicate strings for persistence

```zig
var config = config_mod.Config.load(allocator) catch config_mod.Config{};
```

### Saving Configuration

Configuration is saved automatically during playback:

1. **Update Values**: Copy current state to config
2. **Directory Creation**: Ensure config directory exists
3. **JSON Serialization**: Convert Config struct to JSON
4. **File Writing**: Write to configuration file
5. **Error Handling**: Ignore save errors (non-critical)

```zig
config.volume = midi_player.state.volume;
config.loop_mode = midi_player.state.is_looping;
config.last_played_index = midi_player.state.current_index;
config.save(allocator) catch {}; // Ignore save errors
```

### Error Handling

- **File Not Found**: Uses default configuration (graceful degradation)
- **Invalid JSON**: Falls back to defaults (corruption recovery)
- **Permission Errors**: Continues execution (save errors ignored)
- **Directory Creation**: Handles existing directories gracefully

## Configuration Precedence

1. **User Config File**: `~/.config/midi_player/config.json` (highest priority)
2. **Application Defaults**: Compiled-in default values (fallback)

## Runtime Configuration

Some settings can be overridden at runtime:

### SoundFont Override

Command-line argument takes precedence over config file:

```bash
# Uses config soundfont
./midi_player song.mid

# Overrides config soundfont
./midi_player song.mid custom.sf2
```

### Volume Control

Runtime volume changes are persisted to configuration:

- `+` / `=` keys increase volume
- `-` / `_` keys decrease volume
- Changes saved automatically on track change

## File Format Details

### JSON Structure

- **Encoding**: UTF-8
- **Formatting**: Pretty-printed with 2-space indentation
- **Unknown Fields**: Ignored (forward compatibility)
- **Comments**: Not supported (standard JSON limitation)

### String Handling

- **Null Termination**: Strings are duplicated with null termination for C API compatibility
- **Memory Ownership**: Configuration owns string memory
- **Allocation Strategy**: Uses provided allocator for persistence

### Numeric Precision

- **Volume**: `f32` provides sufficient precision (6-7 decimal digits)
- **Indices**: `usize` ensures compatibility with array indexing

## Migration and Compatibility

### Version Compatibility

The configuration system is designed for forward compatibility:

- **Missing Fields**: Automatically use defaults
- **Extra Fields**: Ignored without errors
- **Type Changes**: JSON parsing handles type mismatches gracefully

### Upgrading

When new configuration fields are added:

1. Add field to `Config` struct with default value
2. Existing config files continue to work
3. New field uses default until explicitly set

### Downgrading

- Removing fields doesn't break existing configs
- Old applications ignore unknown fields
- Graceful degradation to defaults

## Configuration Examples

### Minimal Configuration

```json
{}
```

All fields use defaults. Useful for reset or initial state.

### Full Configuration

```json
{
  "volume": 0.8,
  "last_played_index": 12,
  "loop_mode": true,
  "soundfont_path": "/usr/share/soundfonts/FluidR3_GM.sf2"
}
```

Complete customization with all features enabled.

### Development Configuration

```json
{
  "volume": 0.1,
  "last_played_index": 0,
  "loop_mode": false,
  "soundfont_path": "soundfonts/standard-midisf.sf2"
}
```

Quiet playback for development testing.

## Configuration Management

### Manual Editing

Users can edit the configuration file directly:

```bash
# Edit with preferred editor
$EDITOR ~/.config/midi_player/config.json
```

### Reset Configuration

Delete the configuration file to reset to defaults:

```bash
rm ~/.config/midi_player/config.json
```

### Backup Configuration

```bash
# Backup
cp ~/.config/midi_player/config.json ~/.config/midi_player/config.json.backup

# Restore
cp ~/.config/midi_player/config.json.backup ~/.config/midi_player/config.json
```

## Troubleshooting

### Common Issues

**Configuration not saved**:
- Check write permissions on `~/.config/midi_player/`
- Verify disk space availability
- Check for filesystem errors

**Invalid configuration**:
- Validate JSON syntax: `jq . config.json`
- Check for special characters in paths
- Ensure numeric values are in valid ranges

**Configuration ignored**:
- Verify file location and permissions
- Check for JSON parsing errors in logs
- Ensure application has read access

### Debug Information

Enable debug output to troubleshoot configuration issues:

```zig
// In config.zig load() function
std.debug.print("Loading config from: {s}\n", .{path});
std.debug.print("Config content: {s}\n", .{content});
```

### Validation

Manual validation of configuration files:

```bash
# Check JSON syntax
python3 -m json.tool ~/.config/midi_player/config.json

# Check file permissions
ls -la ~/.config/midi_player/config.json
```

## Future Extensions

### Planned Features

- **Multiple Profiles**: Named configuration profiles
- **Per-Song Settings**: Track-specific configuration
- **Import/Export**: Configuration backup and sharing
- **GUI Editor**: In-application configuration management

### Extension Points

The configuration system is designed for easy extension:

```zig
pub const Config = struct {
    // ... existing fields ...

    // New features
    audio_device: []const u8 = "default",
    visualizer_enabled: bool = true,
    custom_keybindings: std.json.Value = undefined,
};
```

### Schema Validation

Future versions may include JSON schema validation for:
- Type checking
- Range validation
- Required field enforcement
- Deprecation warnings

## Security Considerations

### File Permissions

Configuration files may contain sensitive paths:
- SoundFont file locations
- Custom audio device names
- User-specific settings

**Recommendations**:
- Restrict file permissions: `chmod 600 config.json`
- Avoid storing credentials in configuration
- Validate paths before use

### Path Validation

All paths in configuration should be validated:
- Check file existence
- Verify read permissions
- Sanitize path components
- Prevent directory traversal attacks

## Performance Impact

### Loading

- **File I/O**: Minimal (small JSON file)
- **Parsing**: Fast (Zig's JSON parser)
- **Memory**: Small allocation for strings
- **Startup Time**: Negligible impact

### Saving

- **Frequency**: Only on track changes
- **I/O Pattern**: Infrequent small writes
- **Blocking**: Non-blocking (errors ignored)
- **Performance**: No measurable impact

## Testing

### Configuration Tests

- **Load/Save Cycle**: Verify round-trip integrity
- **Default Values**: Test missing field handling
- **Invalid Data**: Test corruption recovery
- **Permissions**: Test read/write restrictions

### Integration Tests

- **Runtime Updates**: Verify live configuration changes
- **Persistence**: Test across application restarts
- **Migration**: Test configuration upgrades

---

The configuration system provides a robust, user-friendly way to customize the MIDI Player experience while maintaining backward compatibility and performance.