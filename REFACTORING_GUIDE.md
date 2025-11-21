# Refactoring Guide: Zig MIDI Player

## Overview

This document provides a structured approach to refactor the Zig MIDI player codebase to eliminate redundancies while maintaining KISS principles. The refactoring focuses on reducing complexity, eliminating duplication, and improving maintainability.

## Current State Analysis

- **Code**: 668 lines across 3 source files
- **Documentation**: 3,249 lines across 11 files (4.9x documentation ratio)
- **Main Issues**:
  - Duplicated search logic in `main.zig` (lines 231-253 & 276-293)
  - State duplication between `PlayerState` and `Config`
  - Monolithic 463-line `main()` function
  - Excessive documentation with redundancy

## Refactoring Goals

1. **Eliminate Code Duplication**: Remove redundant search logic and state fields
2. **Reduce Documentation Bloat**: Consolidate from 11 to 4 files
3. **Improve Modularity**: Break down monolithic functions
4. **Maintain KISS Principles**: Keep solutions simple and focused
5. **Preserve Functionality**: Zero breaking changes to user experience

## Phase 1: Immediate Code Cleanup (Priority: High)

### 1.1 Extract Duplicated Search Logic

**Files**: `src/main.zig`
**Impact**: -20 lines, improved maintainability

**Steps**:
1. Add new function after imports:
```zig
fn matchesQuery(midi: []const u8, query: []const u8) bool {
    if (query.len == 0) return true;
    if (midi.len < query.len) return false;
    
    for (0..(midi.len - query.len + 1)) |i| {
        if (std.ascii.eqlIgnoreCase(midi[i..i + query.len], query)) {
            return true;
        }
    }
    return false;
}
```

2. Replace first occurrence (lines 231-253):
```zig
for (all_midis.items) |midi| {
    if (matchesQuery(midi, query.items)) {
        if (matches_count < 15) {
            std.debug.print("  {s}\n", .{midi});
        }
        matches_count += 1;
    }
}
```

3. Replace second occurrence (lines 276-293):
```zig
for (all_midis.items) |midi| {
    if (matchesQuery(midi, query.items)) {
        try midi_player.state.playlist.append(allocator, try allocator.dupe(u8, midi));
    }
}
```

### 1.2 Eliminate State Duplication

**Files**: `src/player.zig`, `src/main.zig`
**Impact**: Cleaner state management, fewer sync bugs

**Steps**:
1. Update `PlayerState` in `src/player.zig`:
```zig
pub const PlayerState = struct {
    current_index: usize = 0,
    playlist: std.ArrayList([]const u8),
    is_playing: bool = false,
    is_paused: bool = false,
    // Remove: volume, is_looping - managed by Config
};
```

2. Add sync method to `MidiPlayer`:
```zig
pub fn syncFromConfig(self: *MidiPlayer, config: config_mod.Config) void {
    self.setVolume(config.volume);
    self.state.is_looping = config.loop_mode;
}

pub fn syncToConfig(self: *MidiPlayer, config: *config_mod.Config) void {
    config.volume = self.state.volume;
    config.loop_mode = self.state.is_looping;
    config.last_played_index = self.state.current_index;
}
```

3. Update `main.zig` sync points:
```zig
// After config load
midi_player.syncFromConfig(config);

// Before config save
midi_player.syncToConfig(&config);
```

### 1.3 Remove Unused Functions

**Files**: `src/main.zig`
**Impact**: -15 lines, cleaner codebase

**Steps**:
1. Delete `loadPreferredSoundfont()` (lines 421-432)
2. Delete `printUsage()` (lines 352-362)
3. Update any references if they exist

## Phase 2: Modular Architecture (Priority: Medium)

### 2.1 Create Application Module

**New File**: `src/app.zig`
**Impact**: Separation of concerns, improved testability

**Steps**:
1. Create `src/app.zig`:
```zig
const std = @import("std");
const player_mod = @import("player.zig");
const config_mod = @import("config.zig");
const ui_mod = @import("ui.zig");

pub const App = struct {
    allocator: std.mem.Allocator,
    midi_player: player_mod.MidiPlayer,
    config: config_mod.Config,
    ui: ui_mod.UI,
    args: [][]const u8,

    pub fn init(allocator: std.mem.Allocator, args: [][]const u8) !App {
        var config = config_mod.Config.load(allocator) catch config_mod.Config{};
        var midi_player = try player_mod.MidiPlayer.init(allocator);
        midi_player.syncFromConfig(config);
        
        try loadPlaylist(&midi_player.state.playlist, allocator);
        
        return App{
            .allocator = allocator,
            .midi_player = midi_player,
            .config = config,
            .ui = ui_mod.UI.init(allocator),
            .args = args,
        };
    }

    pub fn deinit(self: *App) void {
        self.midi_player.deinit();
        self.ui.deinit();
    }

    pub fn run(self: *App) !void {
        if (self.args.len < 2) {
            try self.ui.searchMode(&self.midi_player, &self.config);
        } else {
            try self.ui.playbackMode(&self.midi_player, &self.config, self.args);
        }
    }
};
```

### 2.2 Create UI Module

**New File**: `src/ui.zig`
**Impact**: Isolated UI logic, reusable components

**Steps**:
1. Extract UI functions from `main.zig` into `src/ui.zig`:
```zig
const std = @import("std");
const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("termios.h");
});
const player_mod = @import("player.zig");
const config_mod = @import("config.zig");

pub const UI = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) UI {
        return UI{ .allocator = allocator };
    }

    pub fn deinit(self: *UI) void {
        _ = self;
    }

    pub fn searchMode(self: *UI, midi_player: *player_mod.MidiPlayer, config: *config_mod.Config) !void {
        // Move searchAndFilter logic here
    }

    pub fn playbackMode(self: *UI, midi_player: *player_mod.MidiPlayer, config: *config_mod.Config, args: [][]const u8) !void {
        // Move main playback loop here
    }

    // Move all UI functions: drawUI, drawProgress, setupRawMode, etc.
};
```

### 2.3 Simplify Main Function

**File**: `src/main.zig`
**Impact**: Reduce from 463 to ~50 lines

**Steps**:
1. Replace entire `main()` function:
```zig
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var app = try app_mod.App.init(allocator, args);
    defer app.deinit();
    
    try app.run();
}
```

## Phase 3: Documentation Consolidation (Priority: Medium)

### 3.1 Consolidate Documentation Files

**Current**: 11 files (3,249 lines)
**Target**: 4 files (~1,000 lines)
**Impact**: 69% reduction in documentation maintenance

**Mapping**:
```
QUICKSTART.md + EXAMPLES.md → USAGE.md
API.md + ARCHITECTURE.md → TECHNICAL.md  
CONFIG.md + TROUBLESHOOTING.md → SUPPORT.md
KEEP: CONTRIBUTING.md, GLOSSARY.md
DELETE: docs/README.md (redundant index)
```

**Steps**:
1. Create `docs/USAGE.md`:
   - Quick start guide (from QUICKSTART.md)
   - Usage examples (from EXAMPLES.md)
   - Common workflows

2. Create `docs/TECHNICAL.md`:
   - API reference (from API.md)
   - Architecture guide (from ARCHITECTURE.md)
   - Implementation details

3. Create `docs/SUPPORT.md`:
   - Configuration guide (from CONFIG.md)
   - Troubleshooting (from TROUBLESHOOTING.md)
   - FAQ and common issues

4. Update main README.md to reference new structure

### 3.2 Update Documentation References

**Files**: `README.md`, build files, code comments
**Impact**: Consistent references across project

**Steps**:
1. Update all `[Quick Start](docs/QUICKSTART.md)` → `[Usage Guide](docs/USAGE.md)`
2. Update `[API Reference](docs/API.md)` → `[Technical Docs](docs/TECHNICAL.md)`
3. Update `[Configuration](docs/CONFIG.md)` → `[Support](docs/SUPPORT.md)`

## Phase 4: Final Optimizations (Priority: Low)

### 4.1 Simplify File Resolution

**File**: `src/main.zig` (or move to `src/utils.zig`)
**Impact**: Cleaner path resolution logic

**Steps**:
1. Refactor `resolveMidiPath()`:
```zig
fn resolveMidiPath(command: []const u8, allocator: std.mem.Allocator) ![:0]const u8 {
    if (std.fs.path.isAbsolute(command)) 
        return allocator.dupeZ(u8, command);
    
    const candidates = [_][]const u8{ command, command ++ ".mid" };
    for (candidates) |candidate| {
        const path = try std.fs.path.join(allocator, &.{ "midis", candidate });
        if (std.fs.cwd().access(path, .{})) |_| {
            return allocator.dupeZ(u8, path);
        } else |_| {
            allocator.free(path);
        }
    }
    return error.MidiFileNotFound;
}
```

### 4.2 Add Error Types

**New File**: `src/errors.zig` (optional)
**Impact**: Better error handling and debugging

**Steps**:
1. Define custom error types:
```zig
pub const MidiPlayerError = error{
    SoundFontLoadFailed,
    MidiFileNotFound,
    FluidSynthInitFailed,
    // ... other errors
};
```

## Implementation Timeline

### Week 1: Phase 1 (4-6 hours)
- **Day 1**: Extract search logic, remove unused functions
- **Day 2**: Eliminate state duplication, test thoroughly
- **Day 3**: Code review, fix any regressions

### Week 2: Phase 2 (8-10 hours)  
- **Day 1-2**: Create `app.zig` module
- **Day 3-4**: Create `ui.zig` module, extract UI logic
- **Day 5**: Simplify main function, integration testing

### Week 3: Phase 3 (4-6 hours)
- **Day 1-2**: Consolidate documentation files
- **Day 3**: Update references, validate links

### Week 4: Phase 4 (2-4 hours)
- **Day 1**: Final optimizations, error handling
- **Day 2**: Final testing, documentation updates

## Validation Checklist

### Code Quality
- [ ] All tests pass: `zig build test`
- [ ] Code formatting: `zig fmt --check` 
- [ ] Build succeeds: `zig build`
- [ ] No functionality regressions

### Documentation
- [ ] All links resolve correctly
- [ ] Examples work as documented
- [ ] Installation instructions valid

### Performance
- [ ] Startup time unchanged (<100ms)
- [ ] Memory usage similar (~50MB)
- [ ] UI responsiveness maintained

## Rollback Plan

If issues arise during refactoring:

1. **Git Branch**: Work on dedicated branch `refactor/cleanup`
2. **Commits**: Small, atomic commits with clear messages
3. **Testing**: Test each phase before proceeding
4. **Rollback**: `git revert` to previous stable state if needed

## Expected Outcomes

### Quantitative
- **Code reduction**: ~100 lines (15% decrease)
- **Documentation reduction**: ~2,250 lines (69% decrease)
- **Files**: 3 → 5 source files, 11 → 4 documentation files

### Qualitative
- **Maintainability**: Clear module boundaries
- **Testability**: Isolated components
- **Readability**: Focused, single-purpose functions
- **Complexity**: Reduced cognitive load

### KISS Compliance
- **Simplicity**: Each function has single responsibility
- **Clarity**: Direct code paths, minimal abstraction
- **Efficiency**: No performance degradation
- **Reliability**: Fewer places for bugs to hide

## Success Metrics

1. **Zero Breaking Changes**: All existing functionality preserved
2. **Improved Test Coverage**: Modular design enables better testing
3. **Faster Onboarding**: New developers can understand code faster
4. **Reduced Maintenance**: Less code and documentation to maintain
5. **Enhanced Extensibility**: Easier to add new features

---

This refactoring maintains the project's KISS principles while significantly improving code organization and reducing maintenance burden. Each phase can be implemented independently, allowing for incremental progress with minimal risk.