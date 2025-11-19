# Troubleshooting & FAQ

## Frequently Asked Questions

### General Questions

#### What is the MIDI Player?

The MIDI Player is a command-line application built with Zig that plays MIDI files using FluidSynth for high-quality audio synthesis. It provides an interactive terminal interface for playback control.

#### What are the system requirements?

- **Operating System**: Linux (ALSA support required)
- **Zig**: Version 0.15 or later
- **Libraries**: FluidSynth and ALSA development libraries
- **Audio**: ALSA-compatible sound system

#### How do I install the dependencies?

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install libfluidsynth-dev libasound2-dev
```

**Arch Linux:**
```bash
sudo pacman -S fluidsynth alsa-lib
```

**Fedora:**
```bash
sudo dnf install fluidsynth-devel alsa-lib-devel
```

#### How do I build the application?

```bash
# Clone repository
git clone <repository>
cd midi_player

# Build
zig build

# Optional: Copy to root directory
zig build copy-exe
```

#### How do I run the application?

```bash
# List available MIDI files
./midi_player --

# Play a MIDI file
./midi_player song.mid

# Play with custom SoundFont
./midi_player song.mid soundfonts/custom.sf2
```

### Audio Issues

#### No sound is playing

**Possible causes:**
- Missing or invalid SoundFont file
- ALSA audio system not configured
- Audio device permissions
- FluidSynth initialization failure

**Solutions:**
1. Check SoundFont exists: `ls soundfonts/`
2. Test ALSA: `aplay -l`
3. Check permissions: `groups | grep audio`
4. Try different SoundFont: `./midi_player song.mid soundfonts/standard-midisf.sf2`

#### Sound is distorted or low quality

**Possible causes:**
- Low-quality SoundFont
- Incorrect volume settings
- Audio device configuration

**Solutions:**
1. Try different SoundFont (FluidR3_GM.sf2 recommended)
2. Adjust volume: Use `+`/`-` keys during playback
3. Check audio device settings

#### ALSA warnings appear

ALSA warnings like "Unknown PCM cards.pcm.rear" are usually harmless and don't affect playback. They occur when ALSA probes for audio devices that don't exist on your system.

#### How do I change the audio device?

The application uses ALSA's default device. To use a different device:

1. List available devices: `aplay -l`
2. Set ALSA default device in `~/.asoundrc`:
```
defaults.pcm.card 1
defaults.ctl.card 1
```

### MIDI File Issues

#### "MidiFileNotFound" error

**Possible causes:**
- File doesn't exist in expected location
- Incorrect filename or path
- File is not a valid MIDI file

**Solutions:**
1. Check file exists: `ls midis/`
2. Use correct filename: `./midi_player "exact name.mid"`
3. Use absolute path: `./midi_player /path/to/file.mid`
4. Verify MIDI format: `file midis/filename.mid`

#### "Failed to load MIDI file" error

**Possible causes:**
- Corrupted or invalid MIDI file
- Unsupported MIDI format or features
- FluidSynth compatibility issues
- File permissions or access issues

**Solutions:**
1. Test with a different MIDI file
2. Check file integrity: `file midis/filename.mid`
3. Ensure file is not corrupted: Try playing in another MIDI player
4. Check file permissions: `ls -la midis/filename.mid`

#### "No MIDI files found in playlist" message

**Possible causes:**
- Empty `midis/` directory
- No files with `.mid` extension
- Permission issues accessing the directory

**Solutions:**
1. Check directory contents: `ls -la midis/`
2. Add MIDI files to the directory
3. Ensure files have `.mid` extension
4. Check directory permissions: `ls -ld midis/`

#### Playback stops immediately

**Possible causes:**
- Corrupted MIDI file
- Unsupported MIDI format
- FluidSynth compatibility issues

**Solutions:**
1. Test with different MIDI file
2. Check file integrity: `file midis/filename.mid`
3. Try different SoundFont

#### Some instruments sound wrong

**Possible causes:**
- SoundFont doesn't contain required instruments
- MIDI file uses custom instrument mappings
- Bank/program change commands not supported

**Solutions:**
1. Try different SoundFont with more instruments
2. Check MIDI file metadata for instrument requirements
3. Use General MIDI compatible SoundFonts

### Configuration Issues

#### Settings not saved

**Possible causes:**
- No write permission to config directory
- Disk space full
- Filesystem errors

**Solutions:**
1. Check permissions: `ls -la ~/.config/midi_player/`
2. Create directory: `mkdir -p ~/.config/midi_player`
3. Check disk space: `df -h`

#### Configuration file ignored

**Possible causes:**
- Invalid JSON syntax
- File permission issues
- Application using wrong path

**Solutions:**
1. Validate JSON: `python3 -c "import json; json.load(open('~/.config/midi_player/config.json'))"`
2. Check file location: `ls ~/.config/midi_player/config.json`
3. Reset config: `rm ~/.config/midi_player/config.json`

#### How do I reset configuration?

Delete the configuration file:
```bash
rm ~/.config/midi_player/config.json
```

The application will use default settings on next startup.

### Terminal Interface Issues

#### Keyboard input not responsive

**Possible causes:**
- Terminal not in raw mode
- Background processes interfering
- Terminal emulator issues

**Solutions:**
1. Reset terminal: Type `reset` and press Enter
2. Kill background processes: `pkill -f midi_player`
3. Try different terminal emulator

#### Display looks wrong

**Possible causes:**
- Terminal doesn't support ANSI escape codes
- Color scheme issues
- Font rendering problems

**Solutions:**
1. Use a modern terminal (GNOME Terminal, Konsole, etc.)
2. Check TERM variable: `echo $TERM`
3. Disable colors if needed (not currently supported)

#### Search function not working

**Possible causes:**
- Terminal mode switching issues
- Input buffering problems

**Solutions:**
1. Ensure terminal supports raw mode
2. Try pressing Enter after search query
3. Check for special characters in search term

### Build Issues

#### Compilation fails

**Common errors:**
- Missing Zig installation
- Wrong Zig version
- Missing system libraries

**Solutions:**
1. Install Zig 0.15+: `zig version`
2. Install dependencies: See installation section
3. Clean build: `rm -rf zig-cache && zig build`

#### Linker errors

**Possible causes:**
- Missing development libraries
- Incorrect library versions
- Architecture mismatches

**Solutions:**
1. Check library installation: `pkg-config --libs fluidsynth alsa`
2. Reinstall dependencies
3. Check architecture: `uname -m`

### Performance Issues

#### High CPU usage

**Possible causes:**
- Inefficient polling loop
- FluidSynth configuration
- Large SoundFont files

**Solutions:**
1. This is normal for real-time audio synthesis
2. Try smaller SoundFont
3. Close other CPU-intensive applications

#### High memory usage

**Possible causes:**
- Large SoundFont loaded
- Memory leaks (unlikely)
- Many MIDI files in playlist

**Solutions:**
1. Use smaller SoundFont file
2. Restart application periodically
3. This is normal for audio applications

#### Slow startup

**Possible causes:**
- Large SoundFont loading
- Slow disk I/O
- FluidSynth initialization

**Solutions:**
1. Use faster storage for SoundFont
2. Try different SoundFont
3. This is normal for first run

### Development Issues

#### How do I debug the application?

1. **Enable debug output:**
   Add `std.debug.print` statements in the code

2. **Check FluidSynth logs:**
   Modify settings for verbose output

3. **Use Zig's debugger:**
   ```bash
   zig build -Doptimize=Debug
   gdb ./midi_player
   ```

#### How do I add new features?

1. Follow the modular architecture
2. Add to appropriate module (main.zig, player.zig, or config.zig)
3. Update documentation
4. Test thoroughly

#### How do I contribute?

1. Fork the repository
2. Create a feature branch
3. Make changes following guidelines
4. Update documentation
5. Submit pull request

### Advanced Troubleshooting

#### FluidSynth Debug Output

Enable verbose FluidSynth logging:

```zig
// In player.zig init()
_ = c.fluid_settings_setint(settings, "synth.verbose", 1);
_ = c.fluid_settings_setint(settings, "synth.dump", 1);
```

#### ALSA Debug Output

Enable ALSA debugging:

```bash
export ALSA_DEBUG=1
./midi_player song.mid
```

#### System Audio Investigation

Check audio system status:

```bash
# List audio devices
aplay -l
arecord -l

# Check mixer settings
alsamixer

# Test audio playback
speaker-test -c 2 -t wav

# Check processes using audio
fuser -v /dev/snd/*
```

#### MIDI File Analysis

Analyze MIDI files:

```bash
# Check file format
file midis/filename.mid

# Use midicsv for detailed analysis
# (if installed)
midicsv midis/filename.mid | head -20
```

### Known Issues & Limitations

#### Current Limitations

- **Single track playback**: Plays one MIDI file at a time
- **ALSA only**: No support for PulseAudio, JACK, etc.
- **Terminal only**: No graphical user interface
- **No playlist persistence**: Playlists not saved between sessions
- **Limited MIDI support**: Basic MIDI file playback only

#### Known Issues

- **ALSA warnings**: Harmless but verbose output
- **Terminal restoration**: May need manual `reset` in some cases
- **Large playlists**: May be slow with thousands of files
- **Special characters**: Some filenames may cause issues

### Getting Help

#### Where to report issues

- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For questions and general discussion

#### What information to include

When reporting issues, please include:

1. **System information:**
   - OS version: `uname -a`
   - Zig version: `zig version`
   - Library versions: `pkg-config --modversion fluidsynth alsa`

2. **Steps to reproduce:**
   - Exact commands used
   - Expected vs actual behavior

3. **Error messages:**
   - Full error output
   - Debug logs if available

4. **Configuration:**
   - Contents of `~/.config/midi_player/config.json`
   - SoundFont being used

#### Debug build for reporting

For bug reports, provide output from debug build:

```bash
zig build -Doptimize=Debug
./midi_player [args] 2>&1 | tee debug.log
```

### Performance Tuning

#### Optimizing for low-latency

1. **Use real-time kernel** (if available)
2. **Adjust FluidSynth settings:**
   ```zig
   _ = c.fluid_settings_setnum(settings, "synth.gain", 0.5);
   _ = c.fluid_settings_setint(settings, "synth.polyphony", 256);
   ```

3. **Use smaller SoundFont**

#### Memory optimization

1. **Limit playlist size**
2. **Use efficient SoundFont**
3. **Close application when not in use**

### Compatibility

#### Supported formats

- **MIDI**: Standard MIDI Files (.mid) format 0 and 1
- **SoundFonts**: SF2 format
- **Audio**: ALSA-compatible systems

#### Tested systems

- Ubuntu 20.04+
- Debian 11+
- Arch Linux
- Fedora 35+

#### Known incompatible systems

- Systems without ALSA (use OSS emulation if available)
- WSL (Windows Subsystem for Linux) - limited audio support
- Container environments without audio access

---

This troubleshooting guide is continuously updated. If you encounter an issue not covered here, please check the GitHub issues or create a new one with detailed information.