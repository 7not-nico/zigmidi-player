# Examples & Advanced Usage

## Basic Usage Examples

### Playing MIDI Files

```bash
# List all available MIDI files
./midi_player --

# Play the first MIDI file in the playlist
./midi_player

# Play a specific file
./midi_player "demo.mid"

# Play with custom SoundFont
./midi_player "demo.mid" "soundfonts/piano.sf2"

# Play external file
./midi_player "/home/user/music/song.mid"
```

### Interactive Controls

During playback, use these controls:

```bash
Space    # Toggle play/pause
n        # Next track
p        # Previous track
l        # Toggle loop mode
+ / =    # Increase volume
- / _    # Decrease volume
/        # Search playlist
q / ESC  # Quit
```

## Advanced Features

### Search Functionality

Press `/` during playback to enter interactive search mode:

```
Search: mario_
  Mario Bros. - Super Mario Bros. Theme.mid
  New Super Mario Bros - Athletic Overworld.mid
  ... and 2 more
```

The search provides real-time filtering as you type:
- Shows matching files instantly
- Displays up to 15 matches
- Indicates additional matches with "... and X more"
- Press Enter to select and play the first match
- Press any other key to continue typing

### Volume Control

```bash
# Increase volume by 10%
+

# Decrease volume by 10%
-

# Volume is saved automatically
```

### Configuration

Edit `~/.config/midi_player/config.json`:

```json
{
  "volume": 0.8,
  "last_played_index": 5,
  "loop_mode": true,
  "soundfont_path": "soundfonts/custom.sf2"
}
```

### Custom SoundFonts

```bash
# Use different SoundFont for different instruments
./midi_player "piano.mid" "soundfonts/grand-piano.sf2"
./midi_player "orchestra.mid" "soundfonts/strings.sf2"
```

## Scripting Examples

### Batch Processing

```bash
#!/bin/bash
# Play all MIDI files in sequence
for file in midis/*.mid; do
    echo "Playing: $file"
    ./midi_player "$file"
    sleep 2
done
```

### Automated Testing

```bash
#!/bin/bash
# Test all MIDI files for 5 seconds each
for file in midis/*.mid; do
    echo "Testing: $file"
    timeout 5 ./midi_player "$file" &
    sleep 6
    kill %1 2>/dev/null
done
```

### Configuration Backup

```bash
#!/bin/bash
# Backup configuration
cp ~/.config/midi_player/config.json ~/midi_player_config_backup.json

# Restore configuration
cp ~/midi_player_config_backup.json ~/.config/midi_player/config.json
```

## Development Examples

### Adding New Controls

```zig
// In main.zig event loop
case 'x' => {
    // Handle custom key
    try handleCustomFeature(&midi_player);
}
```

### Custom SoundFont Loading

```zig
// Load multiple SoundFonts
try player.loadSoundFont("soundfonts/drums.sf2");
try player.loadSoundFont("soundfonts/bass.sf2");
// FluidSynth will combine them
```

### Progress Monitoring

```zig
// Get detailed progress info
const progress = player.getProgress();
const voices = player.getActiveVoiceCount();

std.debug.print("Progress: {d}/{d}, Voices: {d}\n",
               .{progress.current, progress.total, voices});
```

## Troubleshooting Examples

### Debug Output

Enable verbose logging:

```bash
# In player.zig, modify settings
_ = c.fluid_settings_setint(settings, "synth.verbose", 1);
```

### ALSA Debugging

Check audio system:

```bash
# List audio devices
aplay -l

# Test audio
speaker-test -c 2 -t wav

# Check mixer
alsamixer
```

### MIDI File Analysis

```bash
# Check file format
file midis/song.mid

# Get basic info
wc -c midis/song.mid  # File size
```

## Performance Tuning

### Memory Usage

```zig
// Monitor memory usage
const mem_usage = std.heap.page_allocator.allocated_bytes;
std.debug.print("Memory used: {d} bytes\n", .{mem_usage});
```

### CPU Optimization

```zig
// Adjust polling frequency
_ = c.usleep(50000); // 50ms instead of 100ms
```

### Audio Settings

```zig
// Configure FluidSynth for performance
_ = c.fluid_settings_setnum(settings, "synth.gain", 0.8);
_ = c.fluid_settings_setint(settings, "synth.polyphony", 128);
```

## Integration Examples

### System Integration

```bash
# Desktop file for application menu
cat > ~/.local/share/applications/midi-player.desktop << EOF
[Desktop Entry]
Name=MIDI Player
Exec=/path/to/midi_player
Icon=audio-x-midi
Type=Application
Categories=Audio;Music;
EOF
```

### Keyboard Shortcuts

```bash
# Global hotkey (requires window manager config)
# Example for i3wm
bindsym $mod+m exec /path/to/midi_player
```

### Cron Job

```bash
# Add to crontab for scheduled playback
crontab -e
# Play music at 9 AM weekdays
0 9 * * 1-5 /path/to/midi_player "wake_up.mid"
```

## Custom Build Examples

### Cross-Compilation

```bash
# Build for different architectures
zig build -Dtarget=x86_64-linux
zig build -Dtarget=aarch64-linux
```

### Custom Optimization

```bash
# Maximum optimization
zig build -Doptimize=ReleaseFast

# Debug with symbols
zig build -Doptimize=Debug
```

### Static Linking

```bash
# Link libraries statically (if available)
# Modify build.zig to use static linking
exe.linkLibC();
exe.linkSystemLibrary("fluidsynth");
exe.linkSystemLibrary("asound");
```

## File Organization Examples

### Project Structure

```
midi_player/
├── midis/
│   ├── classical/       # Classical music
│   ├── electronic/      # Electronic music
│   └── games/          # Game soundtracks
├── soundfonts/
│   ├── piano.sf2       # Piano sounds
│   ├── orchestra.sf2   # Orchestral sounds
│   └── drums.sf2       # Percussion
└── playlists/          # Custom playlists (future)
```

### SoundFont Management

```bash
# Organize SoundFonts by type
mkdir soundfonts/{piano,orchestra,drums,electronic}

# Create aliases
ln -s soundfonts/piano/grand.sf2 soundfonts/default.sf2
```

## Error Handling Examples

### Graceful Degradation

```zig
// Handle missing SoundFont
player.loadSoundFont(preferred_path) catch |err| {
    std.debug.print("Warning: {s}, using default\n", .{@errorName(err)});
    try player.loadSoundFont("soundfonts/standard-midisf.sf2");
};
```

### User-Friendly Messages

```zig
// Convert technical errors to user messages
catch error.SoundFontLoadFailed {
    std.debug.print("Error: Could not load SoundFont file. Check the file exists and is valid.\n", .{});
}
```

### Recovery Strategies

```zig
// Try multiple SoundFont locations
const soundfont_paths = [_][]const u8{
    config.soundfont_path,
    "soundfonts/default.sf2",
    "soundfonts/standard-midisf.sf2",
};

for (soundfont_paths) |path| {
    if (player.loadSoundFont(path)) |_| {
        break;
    } else |_| {
        // Try next path
    }
}
```

These examples demonstrate the flexibility and extensibility of the MIDI Player architecture.