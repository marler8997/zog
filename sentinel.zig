const builtin = @import("builtin");
const std = @import("std");

const zog = @import("./zog.zig");

pub fn SentinelPtrRange(comptime T: type) type {
    const Info = @typeInfo(T).Pointer;
    //comptime {
        //std.debug.assert(T == zog.meta.ManyPointer(T));
        //switch (T) {
        //    builtin.Type.Pointer => {
        //    },
        //    else => @compileError("SentinelPtr requires a [*]ptr type but got '" ++ @typeName(T) ++ "'"),
        //}
    //}
    return struct {
        ptr: T,
        pub fn rangeElementRefAt(self: *@This(), index: usize) *Info.child {
            return &self.ptr[index];
        }
        pub fn rangeEmpty(self: *@This()) bool {
            return self.ptr[0] == Info.sentinel;
        }
        pub fn rangeClone(self: *@This()) @This() {
            return @This() { .ptr = self.ptr };
        }
        pub fn rangePopMany(self: *@This(), count: usize) void {
            self.ptr += count;
        }
        // TODO: asArrayPointer?
        // TODO: sliceableOffsetLimit?
    };
}

// A range that uses a single pointer and a sentinel value
pub fn sentinelPtrRange(ptr: anytype) SentinelPtrRange(@TypeOf(ptr)) {
    //@compileLog(@typeName(@TypeOf(ptr)));
    return SentinelPtrRange(@TypeOf(ptr)) { .ptr = ptr };
}

//
//pub fn SentinelSlice(comptime T: type, comptime sentinelValue: @typeInfo(T).Pointer.child) type {
//    const ElementType = @typeInfo(T).Pointer.child;
//    comptime {
//        std.debug.assert(T == zog.meta.ManyPointer(T));
//        //switch (T) {
//        //    builtin.Type.Pointer => {
//        //    },
//        //    else => @compileError("SentinelPtr requires a [*]ptr type but got '" ++ @typeName(T) ++ "'"),
//        //}
//    }
//    return struct {
//        ptr: T,
//        len: usize,
//        pub fn rangeEmpty(self: *@This()) bool {
//            return self.len == 0;
//        }
//        pub fn rangeLength(self: *@This()) usize { return self.len; }
//        pub fn rangePopMany(self: *@This(), count: usize) void {
//            std.debug.assert(count <= self.len);
//            self.ptr += count;
//            self.len -= count;
//        }
//        pub fn rangeElementRefAt(self: *@This(), index: usize) zog.meta.SinglePointer(T) {
//            std.debug.assert(index < self.len);
//            return &self.ptr[index];
//        }
//    };
//}
//
// TODO: should there be a SentinelLimitSlice?

pub fn defaultSentinelElement(comptime T: type) T {
    if (T == u8) {
        return @intCast(T, 0);
    } else @compileError("defaultSentinel not implemented for type: " ++ @typeName(T));
}
pub fn defaultSentinel(comptime T: type) std.meta.Child(GetSliceType(T)) {
    return defaultSentinelElement(std.meta.Child(GetSliceType(T)));
}

fn GetSliceType(comptime T: type) type {
    const errorMsg = "GetSliceType requires some kind of pointer type but got: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => return type,
                .One => switch (@typeInfo(info.child)) {
                    .Array => return @Type(builtin.Type { .Pointer = .{
                        .size = .Slice,
                        .is_const = true,
                        .is_volatile = false,
                        .alignment = @alignOf(info.child), // is this right?
                        .child = info.child,
                        .is_allowzero = false,
                        .sentinel = info.sentinel,
                    }}),
                    else => @compileError(errorMsg),
                },
                else => @compileError(errorMsg),
            }
        },
        else => @compileError(errorMsg),
    }
}


/// Takes a pointer and returns the same type but with a sentinel value
/// TODO: support more than just slices
pub fn PointerWithSentinel(comptime T: type, comptime sentinelValue: anytype) type {
    const errorMsg = "expected some kind of slice type but got: " ++ @typeName(T);
    switch (@typeInfo(GetSliceType(T)))
    {
        .Pointer => |info| { switch (info.siz) {
            .Slice => {
                if (info.sentinel) |_| {
                    @compileError("slice already has a sentinel" ++ @typeName(T));
                }
                return @Type(builtin.Type { .Pointer = builtin.Type.Pointer {
                    .size = .Slice,
                    .is_const = info.is_const,
                    .is_volatile = info.is_volatile,
                    .alignment = info.alignment,
                    .child = info.child,
                    .is_allowzero = info.is_allowzero,
                    .sentinel = sentinelValue
                }});
            },
            else => @compileError(errorMsg),
        }},
        else => @compileError(errorMsg),
    }
}

// TODO: probably accept slices, array pointers and limit arrays?
//       for now I'll just support slices
pub fn reduceSentinel(x: anytype) PointerWithSentinel(@TypeOf(x), defaultSentinel(@TypeOf(x))) {
    return reduceSentinelCustom(x, 0);//defaultSentinel(@TypeOf(x)));
}
pub fn reduceSentinelCustom(x: anytype, comptime sentinelValue: anytype) PointerWithSentinel(@TypeOf(x), sentinelValue) {
    const T = @TypeOf(x);
    const errorMsg = "expected a slice type but got: " ++ @typeName(T);
    switch (@typeInfo(T))
    {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => {
                    if (info.sentinel) |_| {
                        @compileError("slice already has a sentinel" ++ @typeName(T));
                    }
                    std.debug.assert(x.len >= 1);
                    std.debug.assert(x[x.len - 1] == sentinelValue);
                    return @as(PointerWithSentinel(T, sentinelValue), x[0 .. x.len - 1]);
                },
                else => @compileError(errorMsg),
            }
        },
        else => @compileError(errorMsg),
    }
}


//pub fn AssumeSentinel(comptime T: type) type {
//    const errorMsg = "assumeSentinel does not support type: " ++ @typeName(T);
//     TODO:Return Either SentinelPtr or SentinelSlice
//    switch (@typeInfo(T)) {
//        .Pointer => |info| {
//            switch (info.size) {
//                .Many => return SentinelPtr(T, defaultSentinel(info.child)),
//                .C => return SentinelPtr(zog.meta.ManyPointer(T), defaultSentinel(info.child)),
//                else => @compileError(errorMsg),
//            }
//        },
//        else => @compileError(errorMsg),
//    }
//}
// For now, only accept many pointers and slices
//pub fn assumeSentinel(x: anytype) AssumeSentinel(@TypeOf(x)) {
//    const T = @TypeOf(x);
//    const errorMsg = "assumeSentinel does not support type: " ++ @typeName(T);
//    // TODO:Return Either SentinelPtr or SentinelSlice
//    switch (@typeInfo(T)) {
//        .Pointer => |info| {
//            switch (info.size) {
//                // TODO: can't call defaultSentinel for some reason?
//                //.Many => return SentinelPtr(T, defaultSentinel(info.child)).init(x),
//                .Many => return SentinelPtr(T, 0).init(x),
//                .C => return SentinelPtr(zog.meta.ManyPointer(T), defaultSentinel(info.child)).init(x),
//                else => @compileError(errorMsg),
//            }
//        },
//        else => @compileError(errorMsg),
//    }
//}

test "SentinelSlice" {
    // TODO: verify this is a compile error
    //_ = SentinelPtr(u8);

    //zog.range.testRange("abc", reduceSentinel("abc\x00"));

    // TODO: make this work
    //zog.range.testRange("", assumeSentinel(""));
    //zog.range.testRange("abc", assumeSentinel("abc"));
}
