# Usage Guide

## Quick Start

### Installation

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install libfluidsynth-dev libasound2-dev
```

**Arch Linux:**
```bash
sudo pacman -S fluidsynth alsa-lib
```

### Build and Test

```bash
git clone <repository>
cd zigmidi-player
zig build

# List available MIDI files
./zig-out/bin/midi_player --

# Play a MIDI file
./zig-out/bin/midi_player "demo.mid"
```

## Basic Usage

### Playing MIDI Files

```bash
# Interactive mode (no arguments)
./midi_player

# List all MIDI files
./midi_player --

# Play specific file
./midi_player"demo.mid"

# Play with custom SoundFont
./midi_player "demo.mid" "soundfonts/piano.sf2"

# Play external file (absolute path)
./midi_player "/path/to/song.mid"
```

### Keyboard Controls

| Key | Action |
|-----|--------|
| `Space` | Toggle play/pause |
| `n` | Next track |
| `p` | Previous track |
| `l` | Toggle loop mode |
| `+` / `=` | Increase volume |
| `-` / `_` | Decrease volume |
| `/` | Search/filter playlist |
| `q` / `ESC` | Quit |

## Interactive Search

Press `/` during playback to filter your playlist:

```
Search: mario_

  Mario Bros. - Super Mario Bros. Theme.mid
  New Super Mario Bros - Athletic Overworld.mid
  ... and 2 more
```

- Type to filter in real-time
- Shows up to 15 matches
- Press `Enter` to play filtered results
- Press `ESC` to cancel

## Configuration

Configuration is stored in `~/.config/midi_player/config.json` and automatically saved.

### Example Configuration

```json
{
  "volume": 0.5,
  "last_played_index": 5,
  "loop_mode": true,
  "soundfont_path": "soundfonts/custom.sf2"
}
```

### Configuration Fields

- **volume** (0.0-10.0): Playback volume, default 0.2
- **last_played_index**: Resume from this track
- **loop_mode**: Loop current track
- **soundfont_path**: Path to SoundFont file

### Manual Editing

```bash
# Edit configuration
$EDITOR ~/.config/midi_player/config.json

# Reset to defaults
rm ~/.config/midi_player/config.json

# Backup configuration
cp ~/.config/midi_player/config.json ~/midi_config_backup.json
```

## Advanced Examples

### Batch Processing

```bash
#!/bin/bash
# Play all MIDI files in sequence
for file in midis/*.mid; do
    echo "Playing: $file"
    ./midi_player "$file"
done
```

### Custom Soundfonts

```bash
# Use different SoundFonts for different styles
./midi_player "piano.mid" "soundfonts/grand-piano.sf2"
./midi_player "orchestra.mid" "soundfonts/strings.sf2"
```

### Desktop Integration

```bash
# Create desktop application entry
cat > ~/.local/share/applications/midi-player.desktop <<EOF
[Desktop Entry]
Name=MIDI Player
Exec=/path/to/midi_player
Icon=audio-x-midi
Type=Application
Categories=Audio;Music;
EOF
```

## Project Organization

```
midi_player/
├── midis/           # MIDI files (.mid)
│   ├── classical/
│   ├── games/
│   └── electronic/
├── soundfonts/      # SoundFont files (.sf2)
│   ├── piano.sf2
│   └── orchestra.sf2
└── ~/.config/midi_player/
    └── config.json  # User configuration
```

## Troubleshooting

**No sound?**
- Check if SoundFont exists: `ls soundfonts/`
- Verify ALSA is working: `speaker-test -c 2 -t wav`
- Try different SoundFont: `./midi_player song.mid soundfonts/standard-midisf.sf2`

**Controls not working?**
- Ensure terminal window has focus
- Check terminal supports raw mode
- Try pressing keys individually

**Configuration not saved?**
- Check write permissions: `ls -la ~/.config/midi_player/`
- Verify disk space: `df -h`
- Validate JSON syntax: `jq . ~/.config/midi_player/config.json`

**Need help?**
- Check [TECHNICAL.md](TECHNICAL.md) for API details
- See [SUPPORT.md](SUPPORT.md) for detailed troubleshooting
