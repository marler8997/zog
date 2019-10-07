const std = @import("std");

pub fn Appender(comptime T : type) type {
    return struct {
        appendSliceFunc : fn(self: *@This(), slice: []const T) void,
        pub inline fn appendSlice(self: *@This(), slice: []const T) void {
            self.appendSliceFunc(self, slice);
        }
    };
}

pub fn FixedAppender(comptime T : type) type {
    return struct {
        array: []T,
        len: usize,
        appender: Appender(T),
        pub fn init(array : []T) @This() {
            return @This() {
                .array = array,
                .len = 0,
                .appender = Appender(T) {
                    .appendSliceFunc = appendSlice
                },
            };
        }
        pub fn appendSlice(base: *Appender(T), slice: []const T) void {
            var self = @fieldParentPtr(@This(), "appender", base);
            std.mem.copy(T, self.array[self.len..], slice);
            self.len += slice.len;
        }
        pub fn full(self: *@This()) bool { return self.len == self.array.len; }
    };
}
