# AGENTS.md

## Project Scope
KISS-compliant, easy to use, performant MIDI player. Document work, avoid redundancies.

## Build/Lint/Test Commands
- Build: `zig build`
- Build & Copy to Root: `zig build && zig build copy-exe`
- Test: `zig build test` (no unit tests currently)
- Run: `./midi_player [midi_file] [soundfont]`
- Lint: `zig fmt --check` (formatting check)

## Code Style Guidelines
- **Formatting**: Zig fmt compliant. Run `zig fmt` before commits.
- **Naming**: Functions camelCase (e.g., `printUsage`), structs PascalCase (e.g., `PlayerState`), variables/consts snake_case (e.g., `midi_path`).
- **Imports**: `@import("std")` for Zig std, `@cImport` for C bindings.
- **Error Handling**: Explicit with `try`, `catch`, return custom errors (e.g., `error.SoundFontLoadFailed`).
- **State**: No global state; use structs for encapsulation.
- **Resources**: RAII with defer for cleanup (e.g., `defer arena.deinit()`).
- **Comments**: Brief, explanatory; avoid redundancy.
- **Performance**: Minimize allocations, direct C API calls, stack-based where possible.