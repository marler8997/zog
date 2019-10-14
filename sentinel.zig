const builtin = @import("builtin");
const std = @import("std");

const zog = @import("./zog.zig");

pub fn SentinelPtr(comptime T: type, comptime sentinelValue: @typeInfo(T).Pointer.child) type {
    comptime {
        std.debug.assert(T == zog.meta.ManyPointer(T));
        //switch (T) {
        //    builtin.TypeInfo.Pointer => {
        //    },
        //    else => @compileError("SentinelPtr requires a [*]ptr type but got '" ++ @typeName(T) ++ "'"),
        //}
    }
    return struct {
        ptr: T,
        pub fn init(ptr: T) @This() { return @This() { .ptr = ptr }; }
        pub fn empty(self: *@This()) bool {
            return self.ptr[0] == sentinelValue;
        }
        pub fn clone(self: *@This()) @This() {
            return @This() { .ptr = self.ptr };
        }
        pub fn elementAtRef(self: *@This(), index: usize) zog.meta.SinglePointer(T) {
            return &self.ptr[index];
        }
        pub fn popMany(self: *@This(), count: usize) void {
            self.ptr += count;
        }
        // TODO: asArrayPointer?
        // TODO: sliceableOffsetLimit?
    };
}

pub fn SentinelSlice(comptime T: type, comptime sentinelValue: @typeInfo(T).Pointer.child) type {
    const ElementType = @typeInfo(T).Pointer.child;
    comptime {
        std.debug.assert(T == zog.meta.ManyPointer(T));
        //switch (T) {
        //    builtin.TypeInfo.Pointer => {
        //    },
        //    else => @compileError("SentinelPtr requires a [*]ptr type but got '" ++ @typeName(T) ++ "'"),
        //}
    }
    return struct {
        ptr: T,
        len: usize,
        pub fn empty(self: *@This()) bool {
            return self.len == 0;
        }
        pub fn length(self: *@This()) usize { return self.len; }
        pub fn popMany(self: *@This(), count: usize) void {
            std.debug.assert(count <= self.len);
            self.ptr += count;
            self.len -= count;
        }
        pub fn elementAtRef(self: *@This(), index: usize) zog.meta.SinglePointer(T) {
            std.debug.assert(index < self.len);
            return &self.ptr[index];
        }
    };
}

// TODO: should there be a SentinelLimitSlice?

pub fn defaultSentinelValue(comptime T: type) T {
    if (T == u8) {
        return @intCast(T, 0);
    } else @compileError("defaultSentinelValue not implemented for type: " ++ @typeName(T));
}

//
// TODO: probably accept slices, array pointers and limit arrays?
//       for now I'll just support slices
//
// TODO: create reduceSentinelCustom, with accepts a custom sentinel value
//
pub fn reduceSentinel(x: var) SentinelSlice(zog.meta.ManyPointer(@typeOf(x)), defaultSentinelValue(@typeInfo(@typeOf(x)).Pointer.child)) {
    // TODO: print nice error message if it is not a valid type
    const ElementType = @typeInfo(@typeOf(x)).Pointer.child;
    std.debug.assert(x.len >= 1);
    comptime const sentinelValue = defaultSentinelValue(ElementType);
    std.debug.assert(x[x.len - 1] == sentinelValue);
    return SentinelSlice(zog.meta.ManyPointer(@typeOf(x)), sentinelValue) {
        .ptr = x.ptr,
        .len = x.len - 1,
    };
}


pub fn AssumeSentinel(comptime T: type) type {
    const errorMsg = "assumeSentinel does not support type: " ++ @typeName(T);
    // TODO:Return Either SentinelPtr or SentinelSlice
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Many => return SentinelPtr(T, defaultSentinelValue(info.child)),
                .C => return SentinelPtr(zog.meta.ManyPointer(T), defaultSentinelValue(info.child)),
                else => @compileError(errorMsg),
            }
        },
        else => @compileError(errorMsg),
    }
}
// For now, only accept many pointers and slices
pub fn assumeSentinel(x: var) AssumeSentinel(@typeOf(x)) {
    const T = @typeOf(x);
    const errorMsg = "assumeSentinel does not support type: " ++ @typeName(T);
    // TODO:Return Either SentinelPtr or SentinelSlice
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                // TODO: can't call defaultSentinelValue for some reason?
                //.Many => return SentinelPtr(T, defaultSentinelValue(info.child)).init(x),
                .Many => return SentinelPtr(T, 0).init(x),
                .C => return SentinelPtr(zog.meta.ManyPointer(T), defaultSentinelValue(info.child)).init(x),
                else => @compileError(errorMsg),
            }
        },
        else => @compileError(errorMsg),
    }
}

test "SentinelSlice" {
    // TODO: verify this is a compile error
    //_ = SentinelPtr(u8);

    zog.range.testRange("abc", reduceSentinel("abc\x00"[0..]));

    // TODO: make this work
    zog.range.testRange("", assumeSentinel(c""));
    zog.range.testRange("abc", assumeSentinel(c"abc"));
}
