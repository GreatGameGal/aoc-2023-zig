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

fn getFullNumber(line: []u8, x: usize) u32 {
    var other_x: usize = x - 1;
    var val: u32 = line[x] - '0';

    var found: u8 = 0;
    while (other_x >= 0 and std.ascii.isDigit(line[other_x])) : (other_x -= 1) {
        found += 1;
        val += (line[other_x] - '0') * std.math.pow(u32, 10, found);
        if (other_x == 0) break;
    }

    other_x = x + 1;
    while (other_x < line.len and std.ascii.isDigit(line[other_x])) : (other_x += 1) {
        val *= 10;
        val += line[other_x] - '0';
    }
    return val;
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

    var y: usize = 0;
    var x: usize = undefined;

    while (y < lines.len) : (y += 1) {
        x = 0;
        while (x < lines[y].len) : (x += 1) {
            switch (lines[y][x]) {
                '0'...'9', '.' => {},
                else => {
                    var other_y: usize = @max(y - 1, 0);
                    var other_x: usize = undefined;
                    var found_numbers: u4 = 0;
                    var found_numbers_mult: u32 = 1;
                    while (other_y < y + 2) : (other_y += 1) {
                        other_x = @max(x - 1, 0);
                        while (other_x < x + 2) : (other_x += 1) {
                            switch (lines[other_y][other_x]) {
                                '0'...'9' => {
                                    found_numbers += 1;
                                    var num = getFullNumber(lines[other_y], other_x);
                                    pt1_sum += num;
                                    found_numbers_mult *= num;
                                    while (other_x < x + 2 and std.ascii.isDigit(lines[other_y][other_x])) other_x += 1;
                                },
                                else => {},
                            }
                        }
                    }
                    if (found_numbers == 2) pt2_sum += found_numbers_mult;
                },
            }
        }
    }
    std.debug.print("Pt1: {d}\n", .{pt1_sum});
    std.debug.print("Pt2: {d}\n", .{pt2_sum});
}
