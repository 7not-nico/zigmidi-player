# Glossary & Terminology

## MIDI Terms

### MIDI (Musical Instrument Digital Interface)
A technical standard that describes a communications protocol, digital interface, and electrical connectors that connect a wide variety of electronic musical instruments, computers, and related audio devices for playing, editing and recording music.

### MIDI File (.mid)
A file format that stores MIDI data, containing instructions for musical notes, timing, and control changes rather than actual audio waveforms.

### SoundFont (.sf2)
A file format that contains samples of musical instruments along with additional information to define how they should be played. Used by FluidSynth to generate audio from MIDI data.

### FluidSynth
A real-time software synthesizer based on the SoundFont 2 specifications. It receives MIDI events and generates audio using SoundFont instruments.

### ALSA (Advanced Linux Sound Architecture)
The Linux kernel component providing audio functionality. Used by FluidSynth to output audio to the system's sound hardware.

## Technical Terms

### RAII (Resource Acquisition Is Initialization)
A programming idiom used in several object-oriented languages where resource allocation and deallocation are tied to object lifetime. In Zig, this is implemented using `defer` statements.

### Arena Allocator
A memory allocator that allocates memory from a contiguous block (arena) and deallocates all at once when the arena is destroyed. Efficient for temporary allocations.

### Raw Terminal Mode
A terminal input mode that allows immediate character reading without line buffering. Used for responsive keyboard controls.

### Non-blocking I/O
Input/output operations that return immediately if no data is available, rather than waiting. Used for keyboard polling.

### JSON (JavaScript Object Notation)
A lightweight data interchange format that's easy for humans to read and write, and easy for machines to parse and generate.

### UTF-8
A variable-width character encoding for Unicode that can represent every character in the Unicode character set. Used for text encoding in the application.

## Application-Specific Terms

### Playlist
An ordered collection of MIDI files discovered in the `midis/` directory, sorted alphabetically for consistent playback order.

### Track Index
The position of a MIDI file in the playlist (0-based). Used for navigation and resuming playback.

### Voice Activity
The number of active synthesizer voices currently producing sound. Indicates playback intensity and can be visualized as a bar graph.

### Progress Ticks
MIDI timing units that represent the current playback position within a file. Total ticks indicate the file's duration.

### Loop Mode
A playback setting that causes the current track to restart automatically when it finishes, rather than advancing to the next track.

### Volume Gain
A multiplier applied to the audio output level, ranging from 0.0 (muted) to 10.0 (maximum amplification).

### Search Filter
An interactive feature that filters the playlist to show only files containing a user-specified search term.

## Architecture Terms

### Modular Architecture
A software design approach where functionality is divided into independent, interchangeable modules. The MIDI Player uses separate modules for player logic, configuration, and UI.

### Domain Layer
The part of the application that contains the business logic and domain entities. In the MIDI Player, this includes the MIDI playback functionality.

### Infrastructure Layer
The part of the application that provides technical capabilities like persistence, external system integration, and configuration management.

### Application Layer
The part of the application that handles user interaction, input/output, and coordinates between domain and infrastructure layers.

### State Encapsulation
The practice of keeping an object's state private and providing controlled access through methods. The `PlayerState` struct encapsulates all playback-related state.

## Development Terms

### Zig
A general-purpose programming language and toolchain for maintaining robust, optimal, and reusable software. Used for implementing the MIDI Player.

### Build System
The process and tools used to compile source code into executable programs. The MIDI Player uses Zig's build system with custom steps.

### Cross-Compilation
The process of compiling code for a different platform than the one currently running. Supported by Zig's build system.

### Linting
The process of checking code for potential errors, style violations, and other issues. The MIDI Player uses `zig fmt` for code formatting.

### Unit Testing
A software testing method where individual units of code are tested in isolation. Currently not implemented in the MIDI Player.

### Integration Testing
Testing that verifies the interaction between different components of the system. Manual testing is used for the MIDI Player.

## File System Terms

### Working Directory
The current directory from which the application is executed. Used as the base for relative file paths.

### Absolute Path
A complete file path that starts from the root directory of the file system.

### Relative Path
A file path that is relative to the current working directory or another specified directory.

### Home Directory
The user's home directory, typically `/home/username` on Linux systems. Used for storing user-specific configuration.

### Configuration Directory
A standard location for storing application configuration files, typically `~/.config/application_name/`.

## Audio Terms

### Sample Rate
The number of audio samples per second. FluidSynth typically uses 44100 Hz (CD quality).

### Bit Depth
The number of bits used to represent each audio sample. FluidSynth typically uses 16-bit samples.

### Polyphony
The number of simultaneous notes that can be played. FluidSynth supports up to 4096 voices by default.

### Synthesis
The process of generating audio from MIDI data using mathematical algorithms and recorded samples.

### Real-time Audio
Audio processing that happens with minimal latency, suitable for interactive applications like music playback.

## Error Terms

### Error Propagation
The process of passing errors up the call stack until they are handled. Zig uses explicit error returns (`!T`).

### Error Handling
The process of responding to and recovering from error conditions. The MIDI Player uses try/catch and graceful degradation.

### Graceful Degradation
The ability of a system to continue operating with reduced functionality when errors occur, rather than failing completely.

### Defensive Programming
Writing code that anticipates and handles potential error conditions. Used throughout the MIDI Player codebase.

## Performance Terms

### Latency
The delay between an input event and the corresponding output. Important for real-time audio applications.

### Throughput
The amount of work that can be performed in a given time period. Related to CPU usage during audio synthesis.

### Memory Footprint
The amount of memory used by an application. The MIDI Player keeps this low through efficient allocation strategies.

### CPU Usage
The percentage of CPU time consumed by the application. The MIDI Player uses minimal CPU for audio synthesis.

This glossary provides definitions for terms used throughout the MIDI Player documentation and codebase.