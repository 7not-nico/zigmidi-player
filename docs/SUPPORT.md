# Support Guide

## Configuration

### Location

Configuration is stored at: `~/.config/midi_player/config.json`

### Format

```json
{
  "volume": 0.5,
  "last_played_index": 5,
  "loop_mode": true,
  "soundfont_path": "soundfonts/custom.sf2"
}
```

### Fields

| Field | Type | Range | Default | Description |
|-------|------|-------|---------|-------------|
| `volume` | float | 0.0-10.0 | 0.2 | Playback volume |
| `last_played_index` | integer | 0+ | 0 | Resume track index |
| `loop_mode` | boolean | true/false | false | Loop current track |
| `soundfont_path` | string | path | "soundfonts/standard-midisf.sf2" | SoundFont file |

### Configuration Lifecycle

**Loading:**
1. Check `~/.config/midi_player/config.json`
2. If missing, use defaults
3. Apply to player state

**Saving:**
- Automatic on track change
- Automatic on volume adjustment
- Automatic on loop toggle
- Saves current state for next session

### Manual Management

```bash
# Edit configuration
$EDITOR ~/.config/midi_player/config.json

# Reset to defaults
rm ~/.config/midi_player/config.json

# Backup
cp ~/.config/midi_player/config.json ~/backup.json

# Restore
cp ~/backup.json ~/.config/midi_player/config.json

# Validate JSON
jq . ~/.config/midi_player/config.json
```

##Troubleshooting

### No Sound

**Problem**: Player starts but no audio output

**Solutions:**

1. **Check SoundFont exists:**
   ```bash
   ls -la soundfonts/
   # Should contain .sf2 files
   ```

2. **Verify ALSA is working:**
   ```bash
   speaker-test -c 2 -t wav
   alsamixer  # Check volume levels
   aplay -l   # List audio devices
   ```

3. **Try different SoundFont:**
   ```bash
   ./midi_player song.mid soundfonts/standard-midisf.sf2
   ```

4. **Check FluidSynth installation:**
   ```bash
   pkg-config --modversion fluidsynth
   # Should show version number
   ```

### Controls Not Working

**Problem**: Keyboard shortcuts don't respond

**Solutions:**

1. **Ensure terminal has focus**
   - Click on terminal window
   - Check window manager settings

2. **Terminal compatibility:**
   - Some terminal emulators may not support raw mode
   - Try different terminal (gnome-terminal, alacritty, urxvt)

3. **Input mode issues:**
   - Terminal might be in wrong mode
   - Restart player
   - Check for error messages

### Configuration Not Saved

**Problem**: Settings don't persist between sessions

**Solutions:**

1. **Check permissions:**
   ```bash
   ls -la ~/.config/midi_player/
   # Should be writable by user
   chmod 755 ~/.config/midi_player/
   chmod 644 ~/.config/midi_player/config.json
   ```

2. **Verify disk space:**
   ```bash
   df -h ~
   # Check available space
   ```

3. **Check file system errors:**
   ```bash
   dmesg | grep -i error
   ```

### Configuration Corruption

**Problem**: Invalid configuration file

**Solutions:**

1. **Validate JSON syntax:**
   ```bash
   python3 -m json.tool ~/.config/midi_player/config.json
   ```

2. **View file contents:**
   ```bash
   cat ~/.config/midi_player/config.json
   ```

3. **Reset configuration:**
   ```bash
   rm ~/.config/midi_player/config.json
   # Restart player to regenerate
   ```

### Player Crashes on Startup

**Problem**: Application exits immediately

**Solutions:**

1. **Check dependencies:**
   ```bash
   # Ubuntu/Debian
   sudo apt install libfluidsynth-dev libasound2-dev
   
   # Arch Linux
   sudo pacman -S fluidsynth alsa-lib
   ```

2. **Verify MIDI files exist:**
   ```bash
   ls midis/*.mid
   # Should list MIDI files
   ```

3. **Check for error messages:**
   ```bash
   ./midi_player 2>&1 | tee error.log
   ```

4. **Run with verbose output:**
   ```bash
   # Rebuild with debug info
   zig build -Doptimize=Debug
   ./zig-out/bin/midi_player
   ```

### File Not Found

**Problem**: "MidiFileNotFound" error

**Solutions:**

1. **Check file path:**
   ```bash
   ls -la midis/song.mid
   ```

2. **Use absolute path:**
   ```bash
   ./midi_player "/absolute/path/to/song.mid"
   ```

3. **Check filename:**
   - Case-sensitive on Linux
   - Include .mid extension
   - Check for special characters

4. **Verify midis/ directory:**
   ```bash
   # Create if missing
   mkdir -p midis
   # Add MIDI files
   cp /path/to/files/*.mid midis/
   ```

### ALSA Errors

**Problem**: ALSA warnings or errors in output

**Common ALSA Warnings:**
```
ALSA lib pcm.c:2722:(snd_pcm_open_noupdate) Unknown PCM cards.pcm.rear
```

These warnings are usually harmless - ALSA is checking for audio devices that don't exist on your system.

**Solutions if audio doesn't work:**

1. **Check default audio device:**
   ```bash
   aplay -L | grep default
   ```

2. **Test audio system:**
   ```bash
   aplay /usr/share/sounds/alsa/Front_Center.wav
   ```

3. **Check PulseAudio:**
   ```bash
   pactl info
   pulseaudio --check
   ```

### Build Errors

**Problem**: Compilation fails

**Solutions:**

1. **Check Zig version:**
   ```bash
   zig version
   # Requires 0.13.0+
   ```

2. **Verify library headers:**
   ```bash
   # Ubuntu/Debian
   dpkg -L libfluidsynth-dev | grep fluid
   
   # Arch Linux
   pacman -Ql fluidsynth | grep include
   ```

3. **Clean build cache:**
   ```bash
   rm -rf .zig-cache zig-out
   zig build
   ```

### Search Not Working

**Problem**: Search mode doesn't filter correctly

**Solutions:**

1. **Case sensitivity:**
   - Search is case-insensitive
   - Try alternative spellings

2. **Partial matching:**
   - Search matches substrings
   - "mario" matches "Super Mario Bros"

3. **Clear search:**
   - Press ESC to exit without filtering
   - Press backspace to delete characters

## FAQ

**Q: How do I change the default SoundFont?**

A: Edit `~/.config/midi_player/config.json` and set `soundfont_path` to your preferred .sf2 file.

**Q: Can I use absolute paths for MIDI files?**

A: Yes! `./midi_player /home/user/music/song.mid` works.

**Q: How do I add more MIDI files?**

A: Copy .mid files to the `midis/` directory. They'll appear automatically.

**Q: Does it support other audio backends besides ALSA?**

A: Currently ALSA only, but FluidSynth supports PulseAudio, JACK, and others. Future versions may add this.

**Q: Can I run it without a terminal?**

A: Not currently - it's a terminal-based application requiring interactive input.

**Q: Where are the logs?**

A: Output goes to stderr. Redirect with: `./midi_player 2> error.log`

**Q: How do I update to a newer version?**

A: Pull latest code and rebuild: `git pull && zig build`

## Getting Help

**Check documentation:**
- [USAGE.md](USAGE.md) - User guide and examples
- [TECHNICAL.md](TECHNICAL.md) - API and architecture
- [README.md](../README.md) - Project overview

**Debug information to collect:**
- Zig version: `zig version`
- FluidSynth version: `pkg-config --modversion fluidsynth`
- OS/distribution: `uname -a`
- Error messages: Full terminal output
- Configuration: Contents of config.json

**Common log analysis:**
```bash
# Capture full output
./midi_player 2>&1 | tee full.log

# Filter warnings
grep -i warning full.log

# Filter errors
grep -i error full.log
```
