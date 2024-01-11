const std = @import("std");

const Day = struct {
    name: []const u8,
    path: []const u8,
};

const days = [_]Day{
    .{ .name = "01", .path = "./src/01.zig" },
    .{ .name = "02", .path = "./src/02.zig" },
    .{ .name = "03", .path = "./src/03.zig" },
    .{ .name = "04", .path = "./src/04.zig" },
    .{ .name = "05", .path = "./src/05.zig" },
    .{ .name = "06", .path = "./src/06.zig" },
    .{ .name = "07", .path = "./src/07.zig" },
    .{ .name = "08", .path = "./src/08.zig" },
    .{ .name = "09", .path = "./src/09.zig" },
    .{ .name = "10", .path = "./src/10.zig" },
    .{ .name = "11", .path = "./src/11.zig" },
    .{ .name = "12", .path = "./src/12.zig" },
    .{ .name = "13", .path = "./src/13.zig" },
    .{ .name = "14", .path = "./src/14.zig" },
    .{ .name = "15", .path = "./src/15.zig" },
    .{ .name = "16", .path = "./src/16.zig" },
    .{ .name = "17", .path = "./src/17.zig" },
    .{ .name = "18", .path = "./src/18.zig" },
    .{ .name = "19", .path = "./src/19.zig" },
    .{ .name = "20", .path = "./src/20.zig" },
    .{ .name = "21", .path = "./src/21.zig" },
    .{ .name = "22", .path = "./src/22.zig" },
    .{ .name = "23", .path = "./src/23.zig" },
    .{ .name = "24", .path = "./src/24.zig" },
    .{ .name = "25", .path = "./src/25.zig" },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();

    const dayno: ?usize = b.option(usize, "n", "Select day.");

    if (dayno) |dayn| {
        if (dayn == 0 or dayn >= days.len) {
            std.debug.print("Invalid day: {d}", .{dayn});
            std.os.exit(2);
        }

        const day = days[dayn - 1];

        const exe = b.addExecutable(.{
            .name = day.name,
            .root_source_file = .{ .path = day.path },
            .target = target,
            .optimize = optimize,
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    } else {
        for (days) |day| {
            var exists = true;
            _ = std.fs.realpathAlloc(allocator, day.path) catch {
                exists = false;
            };
            if (exists) {
                const exe = b.addExecutable(.{
                    .name = day.name,
                    .root_source_file = .{ .path = day.path },
                    .target = target,
                    .optimize = optimize,
                });
                b.installArtifact(exe);
            }
        }
    }
}
