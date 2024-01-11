const std = @import("std");

const RangeError = error{OutOfRange};

const Range = struct {
    const Self = @This();

    start: usize,
    end: usize,

    fn contains(self: *const Self, num: usize) bool {
        return num >= self.start and num < self.end;
    }

    fn overlap(self: *const Self, other: *const Self) ?Range {
        if (!self.contains(other.start) and !other.contains(self.start)) return null;
        return Range{
            .start = @max(self.start, other.start),
            .end = @min(self.end, other.end),
        };
    }

    // Maps a value to a new range without checking it's within the range.
    fn mapToUnsafe(self: *const Self, new_range: *const Self, num: usize) usize {
        return num - self.start + new_range.start;
    }

    fn mapTo(self: *const Self, new_range: *const Self, num: usize) RangeError!usize {
        if (!self.contains(num)) return RangeError.OutOfRange;
        var result = num - self.start + new_range.start;
        if (!new_range.contains(result)) return RangeError.OutOfRange;
        return result;
    }
};

fn parseNumbers(allocator: std.mem.Allocator, list: []const u8) ![]usize {
    var list_cleaned = try std.mem.replaceOwned(u8, allocator, std.mem.trim(u8, list, " "), "  ", " ");
    var numbers = try allocator.alloc(usize, std.mem.count(u8, list_cleaned, " ") + 1);
    var number_iterator = std.mem.splitSequence(u8, list_cleaned, " ");

    var i: usize = 0;
    while (number_iterator.next()) |number| : (i += 1) {
        numbers[i] = try std.fmt.parseUnsigned(usize, number, 10);
    }

    return numbers;
}

fn splitLines(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    var text_trimmed = std.mem.trim(u8, text, "\n");
    var lines = try allocator.alloc([]const u8, std.mem.count(u8, text_trimmed, "\n") + 1);
    var lines_iterator = std.mem.splitSequence(u8, text_trimmed, "\n");

    var i: usize = 0;
    while (lines_iterator.next()) |line| : (i += 1) {
        lines[i] = line;
    }

    return lines;
}

fn splitSections(allocator: std.mem.Allocator, text: []const u8) ![][][]const u8 {
    var sections = try allocator.alloc([][]const u8, std.mem.count(u8, text, "\n\n") + 1);
    var sections_iterator = std.mem.splitSequence(u8, text, "\n\n");

    var i: usize = 0;
    while (sections_iterator.next()) |section| : (i += 1) {
        sections[i] = try splitLines(allocator, section);
    }

    return sections;
}

fn parseMaps(allocator: std.mem.Allocator, sections: [][][]const u8) ![][][]Range {
    var maps = try allocator.alloc([][]Range, sections.len);

    for (sections, 0..) |section, i| {
        maps[i] = try allocator.alloc([]Range, section.len - 1);
        for (section[1..], 0..) |line, j| {
            maps[i][j] = try allocator.alloc(Range, 2);
            var range_from = &maps[i][j][0];
            var range_to = &maps[i][j][1];
            var numbers = try parseNumbers(allocator, line);
            defer allocator.free(numbers);

            range_from.start = numbers[1];
            range_from.end = numbers[1] + numbers[2];

            range_to.start = numbers[0];
            range_to.end = numbers[0] + numbers[2];
        }
    }
    return maps;
}

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit(); // Might never *really* run?
    var allocator = arena_allocator.allocator();
    const args = try std.process.argsAlloc(allocator);

    const input_path = try std.fs.realpathAlloc(allocator, args[1]);
    const file = try std.fs.openFileAbsolute(input_path, .{});
    // The maxInt here is a *bad* idea, but I trust I'm not going to make the input that large.
    // usize is u64 on most targets so this is possibly *very* big.
    const file_text = try file.readToEndAlloc(allocator, std.math.maxInt(usize));

    var sections = try splitSections(allocator, file_text);

    var seeds = try parseNumbers(allocator, sections[0][0][std.mem.indexOf(u8, sections[0][0], ":").? + 1 ..]);
    var maps = try parseMaps(allocator, sections[1..]);

    // -- START PART 1 --

    // This is initalized as a max bceause it is intended to be the lowest found of a list of values.
    var lowest_result: usize = std.math.maxInt(usize);
    for (seeds) |seed| {
        var current_mapping: usize = seed;

        for (maps) |map| {
            current_mapping = for (map) |ranges| {
                var range_from = &ranges[0];
                var range_to = &ranges[1];
                // mapTo returns an error if the value is out of range.
                var mapped = range_from.mapTo(range_to, current_mapping) catch continue;
                break mapped;
            } else current_mapping;
        }
        lowest_result = @min(current_mapping, lowest_result);
    }

    std.debug.print("Pt1: {d}\n", .{lowest_result});

    // -- END PART 1 --

    // -- START PART 2 --

    var i: usize = 0;
    var current_mappings = try std.ArrayList(Range).initCapacity(allocator, seeds.len / 2);
    while (i < seeds.len) : (i += 2) {
        var seed_range = Range{
            .start = seeds[i],
            .end = seeds[i] + seeds[i + 1],
        };
        try current_mappings.append(seed_range);
    }

    var lowest_of_map: usize = undefined;
    for (maps) |map| {
        var new_mappings = std.ArrayList(Range).init(allocator);
        lowest_of_map = std.math.maxInt(@TypeOf(lowest_of_map));
        while (current_mappings.popOrNull()) |old_range| {
            for (map) |ranges| {
                const range_from = &ranges[0];
                const range_to = &ranges[1];
                if (range_from.overlap(&old_range)) |overlap| {
                    var new_range = Range{
                        .start = range_from.mapToUnsafe(range_to, overlap.start),
                        .end = range_from.mapToUnsafe(range_to, overlap.end),
                    };
                    lowest_of_map = @min(new_range.start, lowest_of_map);
                    try new_mappings.append(new_range);
                    if (old_range.start < overlap.start) try current_mappings.append(Range{
                        .start = old_range.start,
                        .end = overlap.start,
                    });
                    if (old_range.end > overlap.end) try current_mappings.append(Range{
                        .start = overlap.end,
                        .end = old_range.end,
                    });
                    break;
                }
            } else {
                lowest_of_map = @min(old_range.start, lowest_of_map);
                try new_mappings.append(old_range);
            }
        }
        current_mappings.clearAndFree();
        current_mappings = new_mappings;
    }

    std.debug.print("Pt2: {d}\n", .{lowest_of_map});

    // -- END PART 2 --

    // -- START PART 2 Brute Force --

    var start = std.time.nanoTimestamp();

    // This is initalized as a max bceause it is intended to be the lowest found of a list of values.
    lowest_result = std.math.maxInt(usize);
    i = 0;
    while (i < seeds.len) : (i += 2) {
        for (seeds[i]..seeds[i] + seeds[i + 1]) |seed| {
            var current_mapping: usize = seed;

            for (maps) |map| {
                current_mapping = for (map) |ranges| {
                    var range_from = &ranges[0];
                    var range_to = &ranges[1];
                    // mapTo returns an error if the value is out of range.
                    var mapped = range_from.mapTo(range_to, current_mapping) catch continue;
                    break mapped;
                } else current_mapping;
            }
            lowest_result = @min(current_mapping, lowest_result);
        }
    }

    std.debug.print("Pt2 Brute Force: {d} ({d}ms)\n", .{ lowest_result, @as(f64, @floatFromInt(std.time.nanoTimestamp() - start)) / 1e6 });

    // -- END PART 2 Brute Force --
}
