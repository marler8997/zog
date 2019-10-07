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
        pub fn empty(self: *@This()) bool {
            return self.ptr.* == sentinelValue;
        }
    };
}

pub fn SentinelArray(comptime T: type, comptime sentinelValue: @typeInfo(T).Pointer.child) type {
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

// TODO: should there be a SentinelLimitArray?

pub fn defaultSentinelValue(comptime T: type) T {
    if (T == u8) {
        return 0;
    } else @compileError("defaultSentinelValue not implemented for type: " ++ @typeName(T));
}

//
// TODO: probably accept slices, array pointers and limit arrays?
//       for now I'll just support slices
//
// TODO: create reduceSentinelCustom, with accepts a custom sentinel value
//
pub fn reduceSentinel(x: var) SentinelArray(zog.meta.ManyPointer(@typeOf(x)), defaultSentinelValue(@typeInfo(@typeOf(x)).Pointer.child)) {
    // TODO: print nice error message if it is not a valid type
    const ElementType = @typeInfo(@typeOf(x)).Pointer.child;
    std.debug.assert(x.len >= 1);
    comptime const sentinelValue = defaultSentinelValue(ElementType);
    std.debug.assert(x[x.len - 1] == sentinelValue);
    return SentinelArray(zog.meta.ManyPointer(@typeOf(x)), sentinelValue) {
        .ptr = x.ptr,
        .len = x.len - 1,
    };
}


pub fn AssumeSentinel(comptime T: type) type {
    // Return Either SentinelPtr or SentinelArray
    @compileError("not implemented");
}
// For now, only accept many pointers and slices
pub fn assumeSentinel(x: var) AssumeSentinel(@typeOf(x)) {
    // Return Either SentinelPtr or SentinelArray
    @compileError("not implemented");
}

test "SentinelArray" {
    // TODO: verify this is a compile error
    //_ = SentinelPtr(u8);

    zog.range.testRange("abc", reduceSentinel("abc\x00"[0..]));

    // TODO: make this work
    //zog.range.testRange("abc", assumeSentinel(c"abc"));
}
