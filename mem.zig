const std = @import("std");

pub fn sliceEqual(a: var, b: var) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    for (a) |item, index| {
        if (b[index] != item) return false;
    }
    return true;
}
pub fn ptrEqual(a: var, b: var, len: usize) bool {
    if (a == b) return true;
    var index : usize = 0;
    while (index < len) : (index += 1) {
        if (a[index] != b[index]) return false;
    }
    return true;
}



pub fn indexOf(haystack: var, needle: var) var {
    
    return indexOfPos(T, haystack, 0, needle);
}

pub fn indexOfAny(comptime T: type, slice: []const T, values: []const T) ?usize {
    return indexOfAnyPos(T, slice, 0, values);
}

pub fn copy(dest: var, source: var) void {
    std.mem.copy(@typeOf(dest[0]), dest, source);
}
