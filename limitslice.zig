const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;

const zog = @import("./zog.zig");

const LimitSliceTypeInfo = struct {
    is_const: bool,
    is_volatile: bool,
    alignment: comptime_int,
    child: type,
    is_allowzero: bool,
    sentinel: anytype,
};

pub fn limitSliceTypeInfo(comptime T: type) LimitSliceTypeInfo {
    const errorMsg = "limitSliceTypeInfo does not support type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| switch (info.size) {
            .One => switch (@typeInfo(info.child)) {
                .Array => |array_info| return LimitSliceTypeInfo {
                    .is_const = true,
                    .is_volatile = false,
                    .alignment = @alignOf(array_info.child),
                    .child = array_info.child,
                    .is_allowzero = false,
                    .sentinel = array_info.sentinel,
                },
                else => @compileError(errorMsg),
            },
            .Many, .Slice, .C => return LimitSliceTypeInfo {
                .is_const = info.is_const,
                .is_volatile = info.is_volatile,
                .alignment = info.alignment,
                .child = info.child,
                .is_allowzero = info.is_allowzero,
                .sentinel = info.sentinel,
            },
        },
        else => @compileError(errorMsg),
    }
}

pub fn LimitSlice(comptime info: LimitSliceTypeInfo) type { return struct {
    pub const ManyPtr = @Type(.{.Pointer = .{
        .size = .Many,
        .is_const = info.is_const,
        .is_volatile = info.is_volatile,
        .alignment = info.alignment,
        .child = info.child,
        .is_allowzero = info.is_allowzero,
        .sentinel = info.sentinel,
    }});
    pub const Slice = @Type(.{.Pointer = .{
        .size = .Slice,
        .is_const = info.is_const,
        .is_volatile = info.is_volatile,
        .alignment = info.alignment,
        .child = info.child,
        .is_allowzero = info.is_allowzero,
        .sentinel = info.sentinel,
    }});
    pub const OnePtr = @Type(.{.Pointer = .{
        .size = .One,
        .is_const = info.is_const,
        .is_volatile = info.is_volatile,
        .alignment = info.alignment,
        .child = info.child,
        .is_allowzero = info.is_allowzero,
        .sentinel = null,
    }});

    ptr : ManyPtr,
    limit : ManyPtr,

    pub fn asSlice(self: *const @This()) Slice {
        return self.ptr[0 .. self.rangeLength()];
    }

    pub fn rangeClone(self: *@This()) @This() {
        return @This() { .ptr = self.ptr, .limit = self.limit };
    }

    pub fn rangeLength(self: *const @This()) usize {
        return (@ptrToInt(self.limit) - @ptrToInt(self.ptr)) / @sizeOf(info.child);
    }
    // Implementing indexInRange since length requires a divide
    pub fn rangeIndexInRange(self: *const @This(), index: usize) bool {
        return @ptrToInt(self.ptr + index) < @ptrToInt(self.limit);
    }

    pub fn rangeElementRefAt(self: *@This(), index: usize) OnePtr {
        const ptr = self.ptr + index;
        std.debug.assert(@ptrToInt(ptr) < @ptrToInt(self.limit));
        return &ptr[0];
    }

    pub fn rangePopMany(self: *@This(), count: usize) void {
        const newPtr = self.ptr + count;
        std.debug.assert(@ptrToInt(newPtr) <= @ptrToInt(self.limit));
        self.ptr = newPtr;
    }

    // rangeEmpty function defined because the empty check is more efficient than checking an index
    pub fn rangeEmpty(self: *const @This()) bool {
        return self.ptr == self.limit;
    }

    pub fn asArrayPointer(self: *@This()) ManyPtr { return self.ptr; }

    // Don't think I need this function anymore, it is replaced with
    // with rangeClone() and rangePopMany()
    //
    //pub fn sliceableOffsetOnly(self: *@This(), offset: usize) @This() {
    //    if (@ptrToInt(self.ptr + offset) > @ptrToInt(self.limit))
    //        unreachable;
    //    return @This() { .ptr = self.ptr + offset, .limit = self.limit, };
    //}
    pub fn sliceableOffsetLimit(self: *@This(), offset: usize, limit: usize) @This() {
        std.debug.assert(offset <= limit);
        std.debug.assert(@ptrToInt(self.ptr + limit) <= @ptrToInt(self.limit));
        return @This() { .ptr = self.ptr + offset, .limit = self.ptr + limit, };
    }

};}

//pub fn isLimitSlice(comptime T: type) bool {
//    switch (@typeInfo(T)) {
//        .Struct => |info| {
//            if (info.fields.len != 2)
//                return false;
//            if (info.fields[0].name == "ptr") {
//                if (info.fields[1].name != "limit")
//                    return false;
//            } else if (info.fields[0].name == "limit") {
//                if (info.fields[1].name != "ptr")
//                    return false;
//            }
//            if (info.fields[0].field_type != info.fields[1].field_type)
//                return false;
//            if (info.fields[0].field_type != zog.meta.ManyPointer(info.fields[0].field_type))
//                return false;
//            return true;
//        },
//        else => return false,
//    }
//}


pub fn limitSlice(x: anytype) callconv(.Inline) LimitSlice(limitSliceTypeInfo(@TypeOf(x))) {
    const T = @TypeOf(x);
    const errorMsg = "limitSlice does not support type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| switch (info.size) {
            .One => switch (@typeInfo(info.child)) {
                .Array => |array_info| return .{ .ptr = x, .limit = x + x.len },
                else => @compileError(errorMsg),
            },
            .Slice => return .{ .ptr = x.ptr, .limit = x.ptr + x.len },
            // Note: do not support Many/C pointers since it requires traversing
            //       the array, use another function for that
            else => @compileError(errorMsg),
        },
        else => @compileError(errorMsg),
    }
}

test "limitSlice" {
    testing.expect(limitSlice("a").ptr == "a"[0..]);
    //zog.range.testRange(&"abc", limitSlice("abc"));
}

pub fn ptrLessThan(left: anytype, right: anytype) bool {
    return @ptrToInt(left) < @ptrToInt(right);
}

pub fn limitPointersToSlice(ptr: anytype, limit: anytype) stdext.meta.SliceType(@TypeOf(ptr)) {
    return ptr[0 .. (@ptrToInt(limit) - @ptrToInt(ptr)) / @sizeOf(@TypeOf(ptr).Child)];
}
