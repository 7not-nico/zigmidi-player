# MIDI Processing Implementation Guide

## Overview

This document provides a comprehensive guide for implementing MIDI file processing capabilities in the Zig MIDI Player codebase. It covers the MIDI file format specification, parsing strategies, and implementation approaches specific to Zig.

## MIDI File Format Specification

### File Structure

A Standard MIDI File (SMF) consists of chunks:

```
MIDI File = Header Chunk + Track Chunk(s)
```

#### Header Chunk (MThd)

```
Offset | Length | Value       | Description
-------|---------|-------------|-------------------
0      | 4       | "MThd"      | Chunk identifier
4      | 4       | 6           | Header length (always 6)
8      | 2       | format       | File format (0, 1, or 2)
10     | 2       | num_tracks   | Number of tracks
12     | 2       | division     | Ticks per quarter note
```

**File Formats:**
- **Format 0**: Single track containing all MIDI channels
- **Format 1**: Multiple tracks played simultaneously  
- **Format 2**: Multiple independent tracks (songs)

#### Track Chunk (MTrk)

```
Offset | Length | Value       | Description
-------|---------|-------------|-------------------
0      | 4       | "MTrk"      | Chunk identifier
4      | 4       | length       | Track data length
8      | variable | events       | MIDI events with delta times
```

### Variable Length Quantity (VLQ)

Delta times use VLQ encoding:
- Each byte uses 7 bits for data, MSB indicates continuation
- Format: `0xxxxxxx` (last byte) or `1xxxxxxx` (continuation)

**Example:**
```
0x00       = 0
0x7F       = 127
0x81 0x00  = 128
0xC0 0x00  = 8192
```

### MIDI Event Types

#### Channel Voice Messages

| Status (hex) | Message          | Data Bytes | Description |
|--------------|------------------|-------------|-------------|
| 8n           | Note Off         | note, vel   | Note released |
| 9n           | Note On          | note, vel   | Note struck |
| An           | Poly Pressure    | note, press | Key pressure |
| Bn           | Control Change   | ctrl, val   | Controller |
| Cn           | Program Change  | program     | Patch change |
| Dn           | Channel Pressure | pressure    | Channel pressure |
| En           | Pitch Bend       | lsb, msb    | Pitch bend |

*(n = channel number 0-15)*

#### Meta Events

| Status | Type | Description |
|---------|-------|-------------|
| FF 00   | Sequence Number | Track sequence |
| FF 01   | Text Event     | Text annotation |
| FF 02   | Copyright      | Copyright notice |
| FF 03   | Track Name     | Track name |
| FF 2F   | End of Track  | Track terminator |
| FF 51   | Set Tempo     | Microseconds/quarter |
| FF 58   | Time Signature | Numerator, denominator |

## Implementation Strategy for Zig

### 1. Core Data Structures

```zig
const std = @import("std");

// MIDI file header structure
pub const MidiHeader = struct {
    format: u16,
    num_tracks: u16,
    division: u16,
};

// MIDI event types
pub const MidiEvent = union(enum) {
    note_off: NoteEvent,
    note_on: NoteEvent,
    control_change: ControlEvent,
    program_change: ProgramEvent,
    meta: MetaEvent,
};

pub const NoteEvent = struct {
    channel: u8,
    note: u8,
    velocity: u8,
};

pub const ControlEvent = struct {
    channel: u8,
    controller: u8,
    value: u8,
};

pub const ProgramEvent = struct {
    channel: u8,
    program: u8,
};

pub const MetaEvent = struct {
    type: u8,
    data: []const u8,
};

// Track structure
pub const MidiTrack = struct {
    events: std.ArrayList(MidiEvent),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) MidiTrack {
        return MidiTrack{
            .events = std.ArrayList(MidiEvent).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *MidiTrack) void {
        self.events.deinit();
    }
};

// Complete MIDI file
pub const MidiFile = struct {
    header: MidiHeader,
    tracks: []MidiTrack,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) MidiFile {
        return MidiFile{
            .header = undefined,
            .tracks = undefined,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *MidiFile) void {
        for (self.tracks) |*track| {
            track.deinit();
        }
        self.allocator.free(self.tracks);
    }
};
```

### 2. Variable Length Quantity Parser

```zig
// Read variable length quantity from byte stream
fn readVLQ(reader: anytype) !u32 {
    var result: u32 = 0;
    var shift: u5 = 0;
    
    while (true) {
        const byte = try reader.readByte();
        result |= @as(u32, byte & 0x7F) << shift;
        
        if (byte & 0x80 == 0) break;
        
        shift += 7;
        if (shift >= 32) return error.InvalidVLQ;
    }
    
    return result;
}

// Write variable length quantity
fn writeVLQ(writer: anytype, value: u32) !void {
    var remaining = value;
    
    while (remaining >= 0x80) {
        const byte = @as(u8, @intCast(remaining & 0x7F)) | 0x80;
        try writer.writeByte(byte);
        remaining >>= 7;
    }
    
    try writer.writeByte(@as(u8, @intCast(remaining)));
}
```

### 3. MIDI File Parser

```zig
pub const MidiParser = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) MidiParser {
        return MidiParser{ .allocator = allocator };
    }
    
    pub fn parseFile(self: MidiParser, file_path: []const u8) !MidiFile {
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();
        
        const contents = try file.readToEndAlloc(self.allocator, 1024 * 1024); // 1MB max
        defer self.allocator.free(contents);
        
        var stream = std.io.fixedBufferStream(contents);
        var reader = stream.reader();
        
        // Parse header
        const header = try self.parseHeader(&reader);
        
        // Parse tracks
        const tracks = try self.allocator.alloc(MidiTrack, header.num_tracks);
        for (0..header.num_tracks) |i| {
            tracks[i] = try self.parseTrack(&reader);
        }
        
        return MidiFile{
            .header = header,
            .tracks = tracks,
            .allocator = self.allocator,
        };
    }
    
    fn parseHeader(self: MidiParser, reader: anytype) !MidiHeader {
        const chunk_id = try reader.readBytesNoEof(4);
        if (!std.mem.eql(u8, &chunk_id, "MThd")) {
            return error.InvalidHeader;
        }
        
        const chunk_length = try reader.readIntBig(u32);
        if (chunk_length != 6) return error.InvalidHeaderLength;
        
        const format = try reader.readIntBig(u16);
        const num_tracks = try reader.readIntBig(u16);
        const division = try reader.readIntBig(u16);
        
        return MidiHeader{
            .format = format,
            .num_tracks = num_tracks,
            .division = division,
        };
    }
    
    fn parseTrack(self: MidiParser, reader: anytype) !MidiTrack {
        var track = MidiTrack.init(self.allocator);
        errdefer track.deinit();
        
        const chunk_id = try reader.readBytesNoEof(4);
        if (!std.mem.eql(u8, &chunk_id, "MTrk")) {
            return error.InvalidTrackChunk;
        }
        
        const chunk_length = try reader.readIntBig(u32);
        const end_pos = reader.context.pos + chunk_length;
        
        var running_status: ?u8 = null;
        
        while (reader.context.pos < end_pos) {
            const delta_time = try readVLQ(reader);
            const status_byte = try reader.readByte();
            
            const event = if (status_byte < 0x80) blk: {
                // Running status
                const rs = running_status orelse return error.InvalidRunningStatus;
                break :blk try self.parseEvent(rs, status_byte, reader);
            } else blk: {
                running_status = status_byte;
                break :blk try self.parseEvent(status_byte, null, reader);
            };
            
            try track.events.append(event);
        }
        
        return track;
    }
    
    fn parseEvent(self: MidiParser, status: u8, first_data: ?u8, reader: anytype) !MidiEvent {
        const status_nibble = status & 0xF0;
        const channel = status & 0x0F;
        
        switch (status_nibble) {
            0x80 => { // Note Off
                const note = first_data orelse try reader.readByte();
                const velocity = try reader.readByte();
                return MidiEvent{ .note_off = NoteEvent{
                    .channel = channel,
                    .note = note,
                    .velocity = velocity,
                }};
            },
            
            0x90 => { // Note On
                const note = first_data orelse try reader.readByte();
                const velocity = try reader.readByte();
                return MidiEvent{ .note_on = NoteEvent{
                    .channel = channel,
                    .note = note,
                    .velocity = velocity,
                }};
            },
            
            0xB0 => { // Control Change
                const controller = first_data orelse try reader.readByte();
                const value = try reader.readByte();
                return MidiEvent{ .control_change = ControlEvent{
                    .channel = channel,
                    .controller = controller,
                    .value = value,
                }};
            },
            
            0xC0 => { // Program Change
                const program = first_data orelse try reader.readByte();
                return MidiEvent{ .program_change = ProgramEvent{
                    .channel = channel,
                    .program = program,
                }};
            },
            
            0xFF => { // Meta Event
                const meta_type = first_data orelse try reader.readByte();
                const length = try readVLQ(reader);
                const data = try self.allocator.alloc(u8, length);
                _ = try reader.readAll(data);
                return MidiEvent{ .meta = MetaEvent{
                    .type = meta_type,
                    .data = data,
                }};
            },
            
            else => return error.UnsupportedEvent,
        }
    }
};
```

### 4. Integration with Existing Codebase

#### Modify `player.zig`

```zig
// Add to existing MidiPlayer struct
pub const MidiPlayer = struct {
    // ... existing fields ...
    
    // Add MIDI file analysis
    current_midi_file: ?MidiFile = null,
    
    // Add new methods
    pub fn loadAndAnalyzeMidi(self: *MidiPlayer, path: [:0]const u8) !void {
        var parser = MidiParser.init(self.allocator);
        const midi_file = try parser.parseFile(path);
        
        // Free previous file if exists
        if (self.current_midi_file) |*prev_file| {
            prev_file.deinit();
        }
        
        self.current_midi_file = midi_file;
        
        // Load into FluidSynth as before
        try self.playFile(path);
    }
    
    pub fn getMidiInfo(self: *MidiPlayer) ?MidiInfo {
        if (self.current_midi_file) |file| {
            return MidiInfo{
                .format = file.header.format,
                .num_tracks = file.header.num_tracks,
                .division = file.header.division,
                .total_events = blk: {
                    var total: usize = 0;
                    for (file.tracks) |track| {
                        total += track.events.items.len;
                    }
                    break :blk total;
                },
            };
        }
        return null;
    }
};

pub const MidiInfo = struct {
    format: u16,
    num_tracks: u16,
    division: u16,
    total_events: usize,
};
```

#### Enhance `ui.zig`

```zig
// Add MIDI information display
fn drawMidiInfo(player: *player_mod.MidiPlayer) !void {
    if (player.getMidiInfo()) |info| {
        std.debug.print("\x1b[1;36mMIDI File Info:\x1b[0m\n", .{});
        std.debug.print("  Format: Type {}\n", .{info.format});
        std.debug.print("  Tracks: {}\n", .{info.num_tracks});
        std.debug.print("  Division: {} ticks/quarter\n", .{info.division});
        std.debug.print("  Events: {}\n\n", .{info.total_events});
    }
}

// Update drawUI function
fn drawUI(player: *player_mod.MidiPlayer, current_name: []const u8) !void {
    std.debug.print("\x1b[2J\x1b[H", .{});
    std.debug.print("\x1b[1;36mMIDI Player\x1b[0m\n\n", .{});
    
    // Add MIDI file info
    try drawMidiInfo(player);
    
    // ... existing UI code ...
}
```

### 5. Performance Optimizations

#### Memory Pool for Event Allocation

```zig
pub const MidiEventPool = struct {
    pool: std.heap.MemoryPool([]MidiEvent),
    
    pub fn init(allocator: std.mem.Allocator) MidiEventPool {
        return MidiEventPool{
            .pool = std.heap.MemoryPool([]MidiEvent).init(allocator),
        };
    }
    
    pub fn allocEvents(self: *MidiEventPool, count: usize) ![]MidiEvent {
        return self.pool.allocator().alloc(MidiEvent, count);
    }
};
```

#### Streaming Parser for Large Files

```zig
pub const StreamingMidiParser = struct {
    // Parse events on-demand without loading entire file
    pub fn parseEventAt(self: StreamingMidiParser, track_index: usize, event_index: usize) ?MidiEvent {
        // Seek to position and parse single event
        // Useful for large MIDI files
    }
};
```

### 6. Error Handling

```zig
pub const MidiError = error{
    InvalidHeader,
    InvalidTrackChunk,
    InvalidVLQ,
    InvalidRunningStatus,
    UnsupportedEvent,
    EndOfFile,
    IoError,
};
```

### 7. Testing Strategy

```zig
// test_midi_parsing.zig
const std = @import("std");
const testing = std.testing;
const midi = @import("midi.zig");

test "parse header chunk" {
    const header_data = [_]u8{
        'M', 'T', 'h', 'd', // MThd
        0x00, 0x00, 0x00, 0x06, // Length = 6
        0x00, 0x00, // Format 0
        0x00, 0x01, // 1 track
        0x00, 0x60, // 96 ticks per quarter
    };
    
    var stream = std.io.fixedBufferStream(&header_data);
    var parser = midi.MidiParser.init(testing.allocator);
    const header = try parser.parseHeader(stream.reader());
    
    try testing.expect(header.format == 0);
    try testing.expect(header.num_tracks == 1);
    try testing.expect(header.division == 96);
}
```

## Implementation Roadmap

### Phase 1: Core Parser (Week 1)
1. Implement basic data structures
2. Create VLQ encoder/decoder
3. Build header and track parsers
4. Add basic event parsing

### Phase 2: Integration (Week 2)
1. Integrate with existing player.zig
2. Add MIDI information display
3. Enhance UI with file details
4. Add error handling

### Phase 3: Advanced Features (Week 3)
1. Add event filtering/searching
2. Implement tempo calculations
3. Add track visualization
4. Performance optimizations

### Phase 4: Testing & Polish (Week 4)
1. Comprehensive test suite
2. Memory usage optimization
3. Edge case handling
4. Documentation updates

## Best Practices

1. **Memory Management**: Use arena allocators for temporary parsing data
2. **Error Handling**: Provide detailed error messages for debugging
3. **Performance**: Stream large files instead of loading entirely
4. **Validation**: Verify file format before processing
5. **Testing**: Test with various MIDI file formats and edge cases

## References

- [MIDI.org Specifications](https://midi.org/specifications)
- [Standard MIDI File Format](https://www.midi.org/specifications/item/the-standard-midi-file-format-specification)
- [MIDI Message Reference](https://midi.org/summary-of-midi-1-0-messages)
- [Rust MIDI Libraries](https://github.com/Boddlnagg/midir) for implementation reference

This implementation guide provides a solid foundation for adding comprehensive MIDI file processing capabilities to the Zig MIDI Player while maintaining the project's KISS principles and performance requirements.