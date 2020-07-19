const std = @import("std");

pub fn sliceEqual(a: anytype, b: anytype) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    for (a) |item, index| {
        if (b[index] != item) return false;
    }
    return true;
}
pub fn ptrEqual(a: anytype, b: anytype, len: usize) bool {
    if (a == b) return true;
    var index : usize = 0;
    while (index < len) : (index += 1) {
        if (a[index] != b[index]) return false;
    }
    return true;
}



pub fn indexOf(haystack: anytype, needle: anytype) anytype {
    return indexOfPos(T, haystack, 0, needle);
}

pub fn indexOfAny(comptime T: type, slice: []const T, values: []const T) ?usize {
    return indexOfAnyPos(T, slice, 0, values);
}

pub fn copy(dest: anytype, source: anytype) void {
    std.mem.copy(@TypeOf(dest[0]), dest, source);
}
