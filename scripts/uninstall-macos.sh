#!/bin/bash
# MIDI Player - macOS Uninstallation Script

set -e

echo "======================================"
echo "  MIDI Player - macOS Uninstaller"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Stop any running instances
echo "Checking for running instances..."
if pgrep -x "midi_player" > /dev/null; then
    echo -e "${RED}Stopping MIDI Player...${NC}"
    pkill -x midi_player || true
    sleep 1
    echo -e "${GREEN}✓ Stopped${NC}"
else
    echo -e "${GREEN}✓ No running instances${NC}"
fi

# Remove binary
echo ""
echo "Removing application..."
if [ -f "/usr/local/bin/midi_player" ]; then
    sudo rm /usr/local/bin/midi_player
    echo -e "${GREEN}✓ Binary removed${NC}"
else
    echo "Binary not found (already removed?)"
fi

# Ask about user data
echo ""
echo "User data locations:"
echo "  Config: ~/.config/midi-player/"
echo "  Files:  ~/Library/Application Support/midi-player/"
echo "  Prefs:  ~/Library/Preferences/com.midi-player.plist"
echo ""

# Calculate total size
total_size=0
if [ -d ~/.config/midi-player ]; then
    size=$(du -sh ~/.config/midi-player 2>/dev/null | cut -f1)
    echo "  Config size: $size"
fi
if [ -d ~/Library/Application\ Support/midi-player ]; then
    size=$(du -sh ~/Library/Application\ Support/midi-player 2>/dev/null | cut -f1)
    echo "  Files size: $size"
fi

echo ""
read -p "Remove user configuration and data? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Are you sure? This cannot be undone. (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove all user data
        rm -rf ~/.config/midi-player/
        rm -rf ~/Library/Application\ Support/midi-player/
        rm -rf ~/Library/Preferences/com.midi-player.plist
        rm -rf ~/Library/Caches/com.midi-player/
        echo -e "${GREEN}✓ User data removed${NC}"
    else
        echo "User data kept"
    fi
else
    echo "User data kept"
fi

# Verify removal
echo ""
echo "Verifying uninstallation..."
if ! command -v midi_player &> /dev/null; then
    echo -e "${GREEN}✓ Verified: midi_player command not found${NC}"
else
    echo -e "${RED}Warning: midi_player still found in PATH${NC}"
fi

# Uninstall complete
echo ""
echo "======================================"
echo -e "${GREEN}✓ Uninstallation Complete!${NC}"
echo "======================================"
echo ""
echo "Note: FluidSynth was NOT removed."
echo "To remove FluidSynth: brew uninstall fluid-synth"
echo ""
