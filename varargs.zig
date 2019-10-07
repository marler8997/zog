/// Note: varargs are going away, when they do this module will also go away
const std = @import("std");

pub fn copyVarargs(array: var, args: ...) void {
    comptime var i = 0;
    inline while (i < args.len) : (i += 1) array[i] = args[i];
}

pub fn allocVarargs(comptime T: type, allocator: *std.mem.Allocator, args: ...) ![]T {
    var array = try allocator.alloc(T, args.len);
    copyVarargs(array, args);
    return array;
}
