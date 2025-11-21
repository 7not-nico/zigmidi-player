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

    pub fn init(allocator: std.mem.Allocator) MidiTrack {
        _ = allocator;
        return MidiTrack{
            .events = std.ArrayList(MidiEvent).empty,
        };
    }
};

// Complete MIDI file
pub const MidiFile = struct {
    header: MidiHeader,
    tracks: []MidiTrack,
    arena: std.heap.ArenaAllocator,

    pub fn deinit(self: *MidiFile) void {
        self.arena.deinit();
    }
};

// Read variable length quantity from byte stream
inline fn readVLQ(reader: anytype) !u32 {
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

pub const MidiParser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) MidiParser {
        return MidiParser{ .allocator = allocator };
    }

    pub fn parseFile(self: MidiParser, file_path: []const u8) !MidiFile {
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const contents = try file.readToEndAlloc(self.allocator, 10 * 1024 * 1024); // 10MB max
        defer self.allocator.free(contents);

        var stream = std.io.fixedBufferStream(contents);
        var reader = stream.reader();

        // Parse header
        const header = try parseHeader(&reader);

        // Initialize Arena for this MIDI file
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        errdefer arena.deinit();
        const arena_allocator = arena.allocator();

        // Parse tracks
        const tracks = try arena_allocator.alloc(MidiTrack, header.num_tracks);

        for (0..header.num_tracks) |i| {
            tracks[i] = try parseTrack(&reader, arena_allocator);
        }

        return MidiFile{
            .header = header,
            .tracks = tracks,
            .arena = arena,
        };
    }

    fn parseHeader(reader: anytype) !MidiHeader {
        const chunk_id = try reader.readBytesNoEof(4);
        if (!std.mem.eql(u8, &chunk_id, "MThd")) {
            return error.InvalidHeader;
        }

        const chunk_length = try reader.readInt(u32, .big);
        if (chunk_length != 6) return error.InvalidHeaderLength;

        const format = try reader.readInt(u16, .big);
        const num_tracks = try reader.readInt(u16, .big);
        const division = try reader.readInt(u16, .big);

        return MidiHeader{
            .format = format,
            .num_tracks = num_tracks,
            .division = division,
        };
    }

    fn parseTrack(reader: anytype, allocator: std.mem.Allocator) !MidiTrack {
        var track = MidiTrack.init(allocator);
        // No errdefer track.deinit() needed because arena handles it

        const chunk_id = try reader.readBytesNoEof(4);
        if (!std.mem.eql(u8, &chunk_id, "MTrk")) {
            return error.InvalidTrackChunk;
        }

        const chunk_length = try reader.readInt(u32, .big);
        const start_pos = reader.context.pos;
        const end_pos = start_pos + chunk_length;

        var running_status: ?u8 = null;

        // Optimization: Disable runtime safety for hot loop in Release builds
        @setRuntimeSafety(false);
        while (reader.context.pos < end_pos) {
            _ = try readVLQ(reader); // Delta time (ignored for now)

            // Peek at status byte
            const status_byte = try reader.readByte();

            const event = if (status_byte < 0x80) blk: {
                // Running status
                const rs = running_status orelse return error.InvalidRunningStatus;
                // Push back the data byte we just read
                reader.context.pos -= 1;
                break :blk try parseEvent(rs, null, reader, allocator);
            } else blk: {
                running_status = status_byte;
                break :blk try parseEvent(status_byte, null, reader, allocator);
            };

            try track.events.append(allocator, event);
        }

        return track;
    }

    fn parseEvent(status: u8, first_data: ?u8, reader: anytype, allocator: std.mem.Allocator) !MidiEvent {
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
                } };
            },

            0x90 => { // Note On
                const note = first_data orelse try reader.readByte();
                const velocity = try reader.readByte();
                return MidiEvent{ .note_on = NoteEvent{
                    .channel = channel,
                    .note = note,
                    .velocity = velocity,
                } };
            },

            0xB0 => { // Control Change
                const controller = first_data orelse try reader.readByte();
                const value = try reader.readByte();
                return MidiEvent{ .control_change = ControlEvent{
                    .channel = channel,
                    .controller = controller,
                    .value = value,
                } };
            },

            0xC0 => { // Program Change
                const program = first_data orelse try reader.readByte();
                return MidiEvent{ .program_change = ProgramEvent{
                    .channel = channel,
                    .program = program,
                } };
            },

            0xF0 => { // System Common / Realtime
                if (status == 0xFF) { // Meta Event
                    const meta_type = try reader.readByte();
                    const length = try readVLQ(reader);
                    const data = try allocator.alloc(u8, length);
                    _ = try reader.readAll(data);
                    return MidiEvent{ .meta = MetaEvent{
                        .type = meta_type,
                        .data = data,
                    } };
                } else {
                    // Skip other system messages for now
                    return error.UnsupportedEvent;
                }
            },

            else => return error.UnsupportedEvent,
        }
    }
};

test "parse simple midi file" {
    const midi_data = [_]u8{
        // Header Chunk
        'M', 'T', 'h', 'd',
        0, 0, 0, 6, // Length
        0, 1, // Format 1
        0, 1, // 1 Track
        0,   60, // Division 60

        // Track Chunk
        'M', 'T',
        'r', 'k',
        0, 0, 0, 4, // Length
        0, 0xFF, 0x2F, 0x00, // End of Track
    };

    // Create a temporary file
    const tmp_path = "test_midi.mid";
    var file = try std.fs.cwd().createFile(tmp_path, .{});
    try file.writeAll(&midi_data);
    file.close();
    defer std.fs.cwd().deleteFile(tmp_path) catch {};

    var parser = MidiParser.init(std.testing.allocator);
    var midi = try parser.parseFile(tmp_path);
    defer midi.deinit();

    try std.testing.expectEqual(@as(u16, 1), midi.header.format);
    try std.testing.expectEqual(@as(u16, 1), midi.header.num_tracks);
    try std.testing.expectEqual(@as(u16, 60), midi.header.division);
    try std.testing.expectEqual(@as(usize, 1), midi.tracks.len);
    try std.testing.expectEqual(@as(usize, 1), midi.tracks[0].events.items.len);
}
