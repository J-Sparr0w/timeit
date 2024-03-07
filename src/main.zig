const std = @import("std");

pub fn usage() void {
    var writer = std.io.getStdOut();
    var bw = std.io.bufferedWriter(writer);
    var stdout = bw.writer();
    stdout.print("\nUsage: timeit [PROCESS NAME]\n", .{});
}

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();
    var args = std.ArrayList([:0]const u8).init(allocator);
    defer args.deinit();
    var procName: []const u8 = undefined;

    if (!args_iter.skip()) {
        return 0x7f;
    }
    
    var i: usize = 0;
    while (args_iter.next()) |arg| : (i += 1) {
        if (i == 0) {
            procName = arg;
        }
        if (!std.mem.startsWith(u8, arg, "-")) {
            try args.append(arg);
        } else {
            std.log.err("unknown cmdline options '{s}'", .{arg});
            return 0x7f;
        }
    }

    const start = try std.time.Instant.now();
    var proc = std.ChildProcess.init(try args.toOwnedSlice(), allocator);
    const result = proc.spawnAndWait() catch |err| {
        std.log.err("process '{s}' could not be spawned due to [{s}]", .{ procName, @errorName(err) });
        return 0x7f;
    };
    switch (result) {
        .Exited => |code| if (code != 0) {
            std.log.err("Program '{s}' exited with non-zero status {}", .{ procName, code });
        },
        .Signal => |signo| {
            std.log.err("Program '{s}' exited with signal {}", .{ procName, signo });
        },
        .Stopped => |signo| {
            std.log.err("Program '{s}' stopped with signal {}", .{ procName, signo });
        },
        .Unknown => |status| {
            std.log.err("Program terminated unexpectedly, status = {}", .{status});
        },
    }

    const elapsed = (try std.time.Instant.now()).since(start);
    const stderr = std.io.getStdErr().writer();
    try stderr.print("\nTime: {any}", .{std.fmt.fmtDuration(elapsed)});
    return 0;
}

test "simple test" {}
