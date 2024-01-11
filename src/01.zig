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

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit(); // Might never *really* run?
    const allocator = arena_allocator.allocator();
    const args = try std.process.argsAlloc(allocator);

    const input_path = try std.fs.realpathAlloc(allocator, args[1]);
    const file = try std.fs.openFileAbsolute(input_path, .{});
    const lines = try getLines(allocator, file);

    const digit_strings = [_](struct { string: []const u8, digit: u8 }){
        .{ .string = "one", .digit = '1' },
        .{ .string = "two", .digit = '2' },
        .{ .string = "three", .digit = '3' },
        .{ .string = "four", .digit = '4' },
        .{ .string = "five", .digit = '5' },
        .{ .string = "six", .digit = '6' },
        .{ .string = "seven", .digit = '7' },
        .{ .string = "eight", .digit = '8' },
        .{ .string = "nine", .digit = '9' },
        .{ .string = "zero", .digit = '0' },
    };
    comptime var longest_digit = 0;
    comptime {
        for (digit_strings) |digit| {
            if (digit.string.len > longest_digit) longest_digit = digit.string.len;
        }
    }
    var sum: u16 = 0;

    // Start of actually solving the problem.
    for (lines) |line| {
        var number = [_]u8{ 0, 0 };
        // This is considered bad practice. Zig wants you to explicitly initialize all fields.
        // https://ziglang.org/documentation/master/std/#A;std:mem.zeroes
        var last_chars = std.mem.zeroes([longest_digit]u8);
        for (last_chars, 0..) |_, i| {
            last_chars[i] = ' ';
        }
        number[0] = outer: for (line) |char| {
            for (1..last_chars.len) |j| {
                last_chars[j - 1] = last_chars[j];
            }
            last_chars[last_chars.len - 1] = char;
            for (digit_strings) |digit| {
                if (std.ascii.endsWithIgnoreCase(&last_chars, digit.string)) {
                    break :outer digit.digit;
                }
            }
            switch (char) {
                '0'...'9' => break char,
                else => continue,
            }
        };

        for (last_chars, 0..) |_, i| {
            last_chars[i] = ' ';
        }
        var i: usize = line.len;
        number[1] = outer: while (i > 0) : (i -= 1) {
            const char = line[i - 1];
            var j: u16 = last_chars.len - 1;
            while (j > 0) : (j -= 1) {
                last_chars[j] = last_chars[j - 1];
            }
            last_chars[0] = char;
            std.debug.print("{s}\n", .{last_chars});
            for (digit_strings) |digit| {
                if (std.ascii.startsWithIgnoreCase(&last_chars, digit.string)) {
                    break :outer digit.digit;
                }
            }
            switch (line[i - 1]) {
                '0'...'9' => break char,
                else => continue,
            }
        };
        sum += try std.fmt.parseUnsigned(u16, &number, 10);
    }

    std.debug.print("{d}\n", .{sum});
}
