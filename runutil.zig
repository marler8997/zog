const std = @import("std");
const zog = @import("./zog.zig");
const appendlib = zog.appendlib;

// todo: use quotes if arg contains spaces
pub fn getCommandStringLength(argv: []const []const u8) usize {
    var len : usize = 0;
    var prefixLength : u8 = 0;
    for (argv) |arg| {
        len += prefixLength + arg.len;
        prefixLength = 1;
    }
    return len;
}

pub fn writeCommandString(buf: [*]u8, argv: []const []const u8) void {
    var next = buf;
    var prefix : []const u8 = "";
    for (argv) |arg| {
        if (prefix.len > 0) {
            @memcpy(next, prefix.ptr, prefix.len);
            next += prefix.len;
        }
        @memcpy(next, arg.ptr, arg.len);
        next += arg.len;
        prefix = " ";
    }
}

pub fn runPassed(result: *const std.ChildProcess.ExecResult) bool {
    switch (result.term) {
        .Exited => {
            return result.term.Exited == 0;
        },
        else => {
            return false;
        }
    }
}
pub fn runFailed(result: *const std.ChildProcess.ExecResult) bool {
    return !runPassed(result);
}

pub fn runCombineOutput(allocator: std.mem.Allocator, result: *const std.ChildProcess.ExecResult) ![]u8 {
    if (result.stderr.len == 0) {
        return result.stdout;
    }
    if (result.stdout.len == 0) {
        return result.stderr;
    }
    var combined = try allocator.alloc(u8, result.stdout.len + result.stderr.len);
    std.mem.copy(u8, combined                     , result.stdout);
    std.mem.copy(u8, combined[result.stdout.len..], result.stderr);
    return combined;
}
