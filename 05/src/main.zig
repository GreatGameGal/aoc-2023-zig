const std = @import("std");

fn parseNumbers(allocator: std.mem.Allocator, list: []const u8) ![]usize {
    var list_trimmed = std.mem.trim(u8, list, " ");
    var numbers = try std.ArrayList(usize).initCapacity(allocator, std.mem.count(u8, list_trimmed, " ") + 1);
    var number_iterator = std.mem.splitSequence(u8, list_trimmed, " ");

    while (number_iterator.next()) |number| {
        if (number.len == 0) continue;
        try numbers.append(try std.fmt.parseUnsigned(usize, number, 10));
    }

    return numbers.toOwnedSlice();
}

fn splitLines(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    var lines = try std.ArrayList([]const u8).initCapacity(allocator, std.mem.count(u8, text, "\n") + 1);
    var lines_iterator = std.mem.splitSequence(u8, text, "\n");

    while (lines_iterator.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

fn splitSections(allocator: std.mem.Allocator, text: []const u8) ![][][]const u8 {
    var sections = try std.ArrayList([][]const u8).initCapacity(allocator, std.mem.count(u8, text, "\n\n") + 1);
    var sections_iterator = std.mem.splitSequence(u8, text, "\n\n");

    while (sections_iterator.next()) |section| {
        try sections.append(try splitLines(allocator, section));
    }

    return try sections.toOwnedSlice();
}

fn parseMaps(allocator: std.mem.Allocator, sections: [][][]const u8) ![][][]usize {
    var maps = try std.ArrayList([][]usize).initCapacity(allocator, sections.len);

    for (sections) |section| {
        var map = try std.ArrayList([]usize).initCapacity(allocator, section.len);
        for (section[1..]) |line| {
            try map.append(try parseNumbers(allocator, line));
        }
        try maps.append(try map.toOwnedSlice());
    }

    return maps.toOwnedSlice();
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

    // This is initalized as a max bceause it is intended to be the lowest found of a list of values.
    var pt1_answer: usize = std.math.maxInt(usize);
    //std.debug.print("{any}\n", .{sections});
    for (seeds) |seed| {
        var last_map_mapping: usize = seed;

        for (maps) |map| {
            last_map_mapping = for (map) |range| {
                // range[1] = Destination
                // range[1] = Source
                // range[2] = Range length
                // If the value is within the range, subtract the difference betwene destination and source range from mapping
                if (last_map_mapping >= range[1] and last_map_mapping < range[1] + range[2]) break last_map_mapping + range[0] - range[1];
            } else last_map_mapping;
        }
        pt1_answer = @min(last_map_mapping, pt1_answer);
    }

    std.debug.print("Pt1: {d}\n", .{pt1_answer});
}
