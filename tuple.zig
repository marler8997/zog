const std = @import("std");

pub fn enforceIsTuple(comptime T: type) void {
    if (@typeInfo(T) != .Struct) {
        @compileError("Expected tuple or struct argument, found " ++ @typeName(T));
    }
}

pub fn copy(array: anytype, tuple: anytype) void {
    enforceIsTuple(@TypeOf(tuple));
    comptime var i = 0;
    inline while (i < tuple.len) : (i += 1) array[i] = tuple[i];
}

pub fn alloc(comptime T: type, allocator: *std.mem.Allocator, tuple: anytype) ![]T {
    enforceIsTuple(@TypeOf(tuple));
    var array = try allocator.alloc(T, tuple.len);
    copy(array, tuple);
    return array;
}
