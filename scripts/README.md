# Installation Scripts

This directory contains installation and uninstallation scripts for all supported platforms.

## Usage

### Linux

**Install:**
```bash
./scripts/install-linux.sh
```

**Uninstall:**
```bash
./scripts/uninstall-linux.sh
```

### Windows

**Install (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-windows.ps1
```

**Uninstall:**
```
scripts\uninstall-windows.bat
```

### macOS

**Install:**
```bash
./scripts/install-macos.sh
```

**Uninstall:**
```bash
./scripts/uninstall-macos.sh
```

## What the Scripts Do

### Installation Scripts
- Check for and install dependencies (FluidSynth, ALSA)
- Copy binary to appropriate system location
- Create user data directories
- Add to PATH (where applicable)
- Create shortcuts (Windows)
- Copy sample files (optional)

### Uninstallation Scripts
- Stop running instances
- Remove binary and application files
- Remove shortcuts and PATH entries
- Optionally remove user data and configuration
- Verify complete removal

## User Data Locations

**Linux:**
- Config: `~/.config/midi-player/`
- Data: `~/.local/share/midi-player/`
- Cache: `~/.cache/midi-player/`

**Windows:**
- Install: `%LOCALAPPDATA%\MIDIPlayer`
- Config: `%APPDATA%\midi-player`
- Cache: `%LOCALAPPDATA%\midi-player`

**macOS:**
- Config: `~/.config/midi-player/`
- Data: `~/Library/Application Support/midi-player/`
- Prefs: `~/Library/Preferences/com.midi-player.plist`
- Cache: `~/Library/Caches/com.midi-player/`

## Notes

- Linux and macOS scripts require `sudo` for system-wide installation
- Windows installation adds to user PATH (requires terminal restart)
- Uninstallation always prompts before removing user data
- FluidSynth is a required dependency on all platforms
