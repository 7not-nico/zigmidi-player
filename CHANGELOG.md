# Changelog

All notable changes to the MIDI Player project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation suite
  - Quick start guide (`docs/QUICKSTART.md`)
  - Examples and recipes (`docs/EXAMPLES.md`)
  - Glossary and terminology (`docs/GLOSSARY.md`)
  - Contributing guide (`docs/CONTRIBUTING.md`)
  - API reference (`docs/API.md`)
  - Architecture guide (`docs/ARCHITECTURE.md`)
  - Developer guide (`docs/DEVELOPER.md`)
  - Configuration guide (`docs/CONFIG.md`)
  - Troubleshooting FAQ (`docs/TROUBLESHOOTING.md`)
  - Documentation index (`docs/README.md`)
- Project infrastructure
  - MIT License (`LICENSE`)
  - Security policy (`SECURITY.md`)
  - Git ignore rules (`.gitignore`)

### Changed
- Updated README.md to reflect modular architecture
- Improved project structure documentation
- Enhanced user guide with new features

## [0.1.0] - 2024-01-XX

### Added
- **Modular Architecture**: Refactored from single-file to modular design
  - `main.zig`: Application logic, CLI, UI, event loop
  - `player.zig`: FluidSynth abstraction and MIDI playback
  - `config.zig`: JSON-based configuration management
- **Interactive Search**: Real-time playlist filtering with `/` key
- **Voice Activity Visualization**: Live display of active synthesizer voices
- **Volume Control**: Runtime volume adjustment with `+`/`-` keys
- **Persistent Configuration**: JSON-based settings with automatic save/load
- **Smart Path Resolution**: Intelligent MIDI file location with fallbacks
- **Progress Display**: Real-time playback progress with tick counts

### Changed
- **Architecture**: Moved from single-file to clean modular design
- **Configuration**: Replaced simple text file with structured JSON config
- **UI**: Enhanced terminal interface with progress bars and activity indicators
- **Error Handling**: Improved error propagation and user feedback
- **Build System**: Updated for Zig 0.15+ compatibility

### Technical Improvements
- **RAII Resource Management**: Proper cleanup with defer statements
- **Memory Management**: Arena allocators for temporary allocations
- **State Encapsulation**: Clean separation of runtime state
- **Direct C API**: Maximum performance with FluidSynth integration
- **Cross-Platform Ready**: Extensible audio backend architecture

## [0.0.1] - Initial Release

### Added
- Basic MIDI file playback using FluidSynth
- Command-line interface with file arguments
- Simple keyboard controls (space, q, n, p)
- ALSA audio backend integration
- Playlist management from midis/ directory
- Basic error handling and user feedback

### Technical Foundation
- Zig language implementation
- FluidSynth C API integration
- Terminal-based user interface
- Project directory structure
- Build system with zig build

---

## Development Notes

### Architecture Evolution

The project evolved from a single-file implementation following KISS principles to a modular architecture while maintaining simplicity and performance:

- **Phase 1**: Single-file implementation (`main.zig` ~240 lines)
- **Phase 2**: Basic modularity with separate player abstraction
- **Phase 3**: Feature additions (search, volume, progress display)
- **Phase 4**: Comprehensive documentation and refinement

### Key Design Decisions

- **KISS Principle**: Keep implementation simple while adding necessary features
- **Performance First**: Direct C API calls, minimal abstractions
- **User Experience**: Intuitive controls, helpful error messages
- **Maintainability**: Clean modular design, comprehensive documentation
- **Extensibility**: Plugin-ready architecture for future enhancements

### Future Roadmap

- **GUI Interface**: Optional graphical user interface
- **Network Features**: Remote control and streaming
- **Advanced Audio**: Multiple backends (PulseAudio, JACK, PipeWire)
- **Plugin System**: Extensible effects and processing
- **Cross-Platform**: Windows/macOS support

---

*For the latest changes, see the commit history or GitHub releases.*