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

const red_cubes = 12;
const green_cubes = 13;
const blue_cubes = 14;

const ColorType = enum {
    Unknown,
    Red,
    Green,
    Blue,
};

fn getRounds(allocator: std.mem.Allocator, line: []u8) ![][]const u8 {
    const game_start = (std.mem.indexOf(u8, line, ":") orelse 0) + 1;
    var rounds = try std.ArrayList([]const u8).initCapacity(allocator, std.mem.count(u8, line, ";") + 1);
    var round_iterator = std.mem.splitSequence(u8, line[game_start..], ";");

    while (round_iterator.next()) |round| {
        try rounds.append(std.mem.trim(u8, round, " "));
    }

    return rounds.toOwnedSlice();
}

const Color = struct { color: ColorType, count: u32 };

fn getColors(allocator: std.mem.Allocator, round: []const u8) ![]Color {
    var colors = try std.ArrayList(Color).initCapacity(allocator, std.mem.count(u8, round, ",") + 1);
    var color_iterator = std.mem.splitSequence(u8, round, ",");

    while (color_iterator.next()) |text| {
        var color_text = std.mem.trim(u8, text, " ");
        var color_split = std.mem.splitSequence(u8, color_text, " ");
        var number_slice = color_split.first();
        var color_slice: []const u8 = color_split.next() orelse &[_]u8{0};
        var number: u32 = try std.fmt.parseUnsigned(u32, number_slice, 10);
        try colors.append(.{
            .color = switch (color_slice[0]) {
                'r' => ColorType.Red,
                'b' => ColorType.Blue,
                'g' => ColorType.Green,
                else => ColorType.Unknown,
            },
            .count = number,
        });
    }

    return try colors.toOwnedSlice();
}

pub fn main() !void {
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit(); // Might never *really* run?
    var allocator = arena_allocator.allocator();
    const args = try std.process.argsAlloc(allocator);

    const input_path = try std.fs.realpathAlloc(allocator, args[1]);
    const file = try std.fs.openFileAbsolute(input_path, .{});
    const lines = try getLines(allocator, file);

    var possible_sum: usize = 0;
    var game_power_sum: usize = 0;

    var game_number: usize = 1;
    for (lines) |line| {
        defer game_number += 1;

        var highest_red: u32 = 0;
        var highest_green: u32 = 0;
        var highest_blue: u32 = 0;

        const rounds = try getRounds(allocator, line);
        var is_valid_game = true;
        for (rounds) |round| {
            var red: u32 = 0;
            var green: u32 = 0;
            var blue: u32 = 0;

            var colors = try getColors(allocator, round);
            for (colors) |color| {
                switch (color.color) {
                    ColorType.Red => red += color.count,
                    ColorType.Green => green += color.count,
                    ColorType.Blue => blue += color.count,
                    ColorType.Unknown => std.debug.print("Unknown Color {?}\n", .{color}),
                }
            }
            highest_red = @max(highest_red, red);
            highest_green = @max(highest_green, green);
            highest_blue = @max(highest_blue, blue);
            var is_not_valid = red > red_cubes or green > green_cubes or blue > blue_cubes;
            //std.debug.print("{s} (r: {d}, g: {d}, b: {d}) (Possible: {?})\n", .{ round, red, green, blue, !is_not_valid });
            if (is_not_valid) is_valid_game = false;
        }
        game_power_sum += highest_red * highest_green * highest_blue;
        if (is_valid_game) {
            possible_sum += game_number;
        }
    }
    std.debug.print("Possible Sum: {d}\nPower Sum: {d}\n", .{ possible_sum, game_power_sum });
}
