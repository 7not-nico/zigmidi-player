#!/bin/bash
# MIDI Player - macOS Installation Script

set -e

echo "======================================"
echo "  MIDI Player - macOS Installer"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Warning: Homebrew not found${NC}"
    echo "You may need to install FluidSynth manually"
else
    echo -e "${GREEN}✓ Homebrew detected${NC}"
fi

# Check for FluidSynth
echo ""
echo "Checking dependencies..."
if ! command -v fluidsynth &> /dev/null; then
    if command -v brew &> /dev/null; then
        echo -e "${YELLOW}FluidSynth not found. Installing via Homebrew...${NC}"
        brew install fluid-synth
        echo -e "${GREEN}✓ FluidSynth installed${NC}"
    else
        echo -e "${YELLOW}FluidSynth not found. Please install it manually:${NC}"
        echo "brew install fluid-synth"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo -e "${GREEN}✓ FluidSynth already installed${NC}"
fi

# Check if binary exists
if [ ! -f "midi_player" ]; then
    echo ""
    echo "Error: midi_player binary not found!"
    echo "Please run 'zig build' first to compile the application."
    exit 1
fi

# Install binary to /usr/local/bin
echo ""
echo "Installing MIDI Player..."
sudo cp midi_player /usr/local/bin/
sudo chmod +x /usr/local/bin/midi_player
echo -e "${GREEN}✓ Binary installed to /usr/local/bin/midi_player${NC}"

# Create user directories
echo ""
echo "Creating user directories..."
mkdir -p ~/Library/Application\ Support/midi-player/soundfonts
mkdir -p ~/Library/Application\ Support/midi-player/midis
mkdir -p ~/.config/midi-player
echo -e "${GREEN}✓ User directories created${NC}"

# Copy sample files if they exist
if [ -d "midis" ] && [ "$(ls -A midis)" ]; then
    echo ""
    read -p "Copy sample MIDI files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp -r midis/* ~/Library/Application\ Support/midi-player/midis/
        echo -e "${GREEN}✓ Sample MIDI files copied${NC}"
    fi
fi

if [ -d "soundfonts" ] && [ "$(ls -A soundfonts)" ]; then
    echo ""
    read -p "Copy SoundFonts? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp -r soundfonts/* ~/Library/Application\ Support/midi-player/soundfonts/
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
echo "  Files:  ~/Library/Application Support/midi-player/"
echo ""
