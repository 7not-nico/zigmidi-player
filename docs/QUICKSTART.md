# Quick Start Guide

## Getting Started in 5 Minutes

This guide will get you up and running with the MIDI Player quickly.

### 1. Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install libfluidsynth-dev libasound2-dev
```

**Arch Linux:**
```bash
sudo pacman -S fluidsynth alsa-lib
```

### 2. Build the Player

```bash
git clone <repository>
cd midi_player
zig build
```

### 3. Test the Player

List available MIDI files:
```bash
./midi_player --
```

Play a MIDI file:
```bash
./midi_player "demo.mid"
```

### 4. Basic Controls

- `Space` - Play/Pause
- `n` - Next track
- `p` - Previous track
- `q` - Quit

### 5. Advanced Features

Try the search feature:
- Press `/` during playback
- Type a song name
- Press Enter

Adjust volume:
- `+` / `=` - Increase volume
- `-` / `_` - Decrease volume

## Troubleshooting

**No sound?**
- Check if SoundFont exists: `ls soundfonts/`
- Try different SoundFont: `./midi_player song.mid soundfonts/standard-midisf.sf2`

**Controls not working?**
- Make sure you're in the terminal window
- Try pressing keys one at a time

**Need help?**
- Check the full documentation: `docs/README.md`
- See troubleshooting guide: `docs/TROUBLESHOOTING.md`