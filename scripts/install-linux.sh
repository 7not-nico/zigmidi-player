#!/bin/bash
# MIDI Player - Linux Installation Script

set -e

echo "======================================"
echo "  MIDI Player - Linux Installer"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for dependencies
echo "Checking dependencies..."

# Check for FluidSynth
if ! command -v fluidsynth &> /dev/null; then
    echo -e "${YELLOW}FluidSynth not found. Installing...${NC}"
    
    # Detect package manager
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y libfluidsynth-dev libasound2-dev
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y fluidsynth-devel alsa-lib-devel
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm fluidsynth alsa-lib
    else
        echo "Could not detect package manager. Please install FluidSynth and ALSA manually."
        exit 1
    fi
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${GREEN}✓ FluidSynth already installed${NC}"
fi

# Check if binary exists
if [ ! -f "midi_player" ]; then
    echo "Error: midi_player binary not found!"
    echo "Please run 'zig build' first to compile the application."
    exit 1
fi

# Install binary
echo ""
echo "Installing MIDI Player..."
sudo cp midi_player /usr/local/bin/
sudo chmod +x /usr/local/bin/midi_player
echo -e "${GREEN}✓ Binary installed to /usr/local/bin/midi_player${NC}"

# Create user directories
echo ""
echo "Creating user directories..."
mkdir -p ~/.config/midi-player
mkdir -p ~/.local/share/midi-player/soundfonts
mkdir -p ~/.local/share/midi-player/midis
echo -e "${GREEN}✓ User directories created${NC}"

# Copy sample files if they exist
if [ -d "midis" ] && [ "$(ls -A midis)" ]; then
    echo ""
    read -p "Copy sample MIDI files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp -r midis/* ~/.local/share/midi-player/midis/
        echo -e "${GREEN}✓ Sample MIDI files copied${NC}"
    fi
fi

if [ -d "soundfonts" ] && [ "$(ls -A soundfonts)" ]; then
    echo ""
    read -p "Copy SoundFonts? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp -r soundfonts/* ~/.local/share/midi-player/soundfonts/
        echo -e "${GREEN}✓ SoundFonts copied${NC}"
    fi
fi

# Installation complete
echo ""
echo "======================================"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo "======================================"
echo ""
echo "Run with: midi_player <file.mid>"
echo "Help: midi_player --help"
echo ""
echo "User data location:"
echo "  Config: ~/.config/midi-player/"
echo "  Files:  ~/.local/share/midi-player/"
echo ""
