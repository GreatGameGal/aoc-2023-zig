const std = @import("std");

fn getLines(allocator: std.mem.Allocator, file: std.fs.File) ![][]u8 {
    const reader = file.reader();
    var lines_list = std.ArrayList([]u8).init(allocator);
    // The maxInt here is a *bad* idea, but I trust I'm not going to make the input that large.
    // usize is u64 on most targets so this is possibly *very* big.
    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize))) |last_line| {
        try lines_list.append(last_line);
    }
    return lines_list.toOwnedSlice();
}

fn parseNumbers(allocator: std.mem.Allocator, list: []const u8) ![][]const u8 {
    const list_cleaned = try std.mem.replaceOwned(u8, allocator, std.mem.trim(u8, list, " "), "  ", " ");
    var numbers = try allocator.alloc([]const u8, std.mem.count(u8, list_cleaned, " ") + 1);
    var number_iterator = std.mem.splitSequence(u8, list_cleaned, " ");

    var i: usize = 0;
    while (number_iterator.next()) |number| : (i += 1) {
        numbers[i] = number;
    }

    return numbers;
}

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit(); // Might never *really* run?
    var allocator = arena_allocator.allocator();
    const args = try std.process.argsAlloc(allocator);

    const input_path = try std.fs.realpathAlloc(allocator, args[1]);
    const file = try std.fs.openFileAbsolute(input_path, .{});
    const lines = try getLines(allocator, file);

    var pt1_sum: u32 = 0;
    var pt2_sum: u32 = 0;
    var card_counts = try allocator.alloc(u32, lines.len);
    for (card_counts, 0..) |_, i| card_counts[i] = 1;
    for (lines, 0..) |line, i| {
        const lists_start = std.mem.indexOfPos(u8, line, 0, ":").? + 1;
        var lists_iterator = std.mem.splitSequence(u8, line[lists_start..], "|");
        const winning_nums = try parseNumbers(allocator, lists_iterator.first());
        const card = try parseNumbers(allocator, lists_iterator.next().?);
        defer allocator.free(winning_nums);
        defer allocator.free(card);

        var win_count: u8 = 0;
        for (card) |card_num| {
            win_count += for (winning_nums) |winning_num| {
                if (std.mem.eql(u8, winning_num, card_num)) break 1;
            } else 0;
        }
        if (win_count > 0) pt1_sum += std.math.pow(u32, 2, win_count - 1);
        for (i + 1..i + 1 + win_count) |j| {
            card_counts[j] += card_counts[i];
        }
    }
    for (card_counts) |card_count| {
        pt2_sum += card_count;
    }
    std.debug.print("Pt1: {d}\n", .{pt1_sum});
    std.debug.print("Pt2: {d}\n", .{pt2_sum});
}
