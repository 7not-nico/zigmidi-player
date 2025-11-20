#!/bin/bash
# MIDI Player - Linux Uninstallation Script

set -e

echo "======================================"
echo "  MIDI Player - Linux Uninstaller"
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
echo "  Files:  ~/.local/share/midi-player/"
echo ""
read -p "Remove user configuration and data? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Show what will be deleted
    echo ""
    echo "The following will be removed:"
    [ -d ~/.config/midi-player ] && du -sh ~/.config/midi-player 2>/dev/null
    [ -d ~/.local/share/midi-player ] && du -sh ~/.local/share/midi-player 2>/dev/null
    [ -d ~/.cache/midi-player ] && du -sh ~/.cache/midi-player 2>/dev/null
    
    echo ""
    read -p "Are you sure? This cannot be undone. (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.config/midi-player/
        rm -rf ~/.local/share/midi-player/
        rm -rf ~/.cache/midi-player/
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
