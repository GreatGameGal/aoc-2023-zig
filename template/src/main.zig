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
    var allocator = arena_allocator.allocator();
    const args = try std.process.argsAlloc(allocator);

    const input_path = try std.fs.realpathAlloc(allocator, args[1]);
    const file = try std.fs.openFileAbsolute(input_path, .{});
    const lines = try getLines(allocator, file);

}
