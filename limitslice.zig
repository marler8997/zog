const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;

const zog = @import("./zog.zig");

pub fn LimitSlice(comptime T : type) type {
    comptime {
        if (zog.meta.ManyPointer(T) != T)
            @compileError("LimitSlice requires a many-pointer type (i.e. [*]T) but got " ++ @typeName(T));
    }
    return struct {
        ptr : T,
        limit : T,

        pub fn ManyPointer() type { return T; }

        pub fn asSlice(self: *const @This()) zog.meta.Slice(T) {
            return self.ptr[0 .. self.rangeLength()];
        }

        pub fn rangeClone(self: *@This()) @This() {
            return @This() { .ptr = self.ptr, .limit = self.limit };
        }

        pub fn rangeLength(self: *const @This()) usize {
            return (@ptrToInt(self.limit) - @ptrToInt(self.ptr)) / @sizeOf(@typeInfo(T).Pointer.child);
        }
        // Implementing indexInRange since length requires a divide
        pub fn rangeIndexInRange(self: *const @This(), index: usize) bool {
            return @ptrToInt(self.ptr + index) < @ptrToInt(self.limit);
        }

        pub fn rangeElementRefAt(self: *@This(), index: usize) zog.meta.SinglePointer(T) {
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

        pub fn asArrayPointer(self: *@This()) T { return self.ptr; }

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
    };
}

pub fn isLimitSlice(comptime T: type) bool {
    switch (@typeInfo(T)) {
        .Struct => |info| {
            if (info.fields.len != 2)
                return false;
            if (info.fields[0].name == "ptr") {
                if (info.fields[1].name != "limit")
                    return false;
            } else if (info.fields[0].name == "limit") {
                if (info.fields[1].name != "ptr")
                    return false;
            }
            if (info.fields[0].field_type != info.fields[1].field_type)
                return false;
            if (info.fields[0].field_type != zog.meta.ManyPointer(info.fields[0].field_type))
                return false;
            return true;
        },
        else => return false,
    }
}

pub inline fn limitSlice(x: var) LimitSlice(zog.meta.ManyPointer(@TypeOf(x))) {
    if (zog.meta.Slice(@TypeOf(x)) != @TypeOf(x))
        @compileError("pointerRange requires a slice but got " ++ @typeName(@TypeOf(x)));
    return LimitSlice(zog.meta.ManyPointer(@TypeOf(x))) {
        .ptr = x.ptr,
        .limit = x.ptr + x.len,
    };
}

test "limitSlice" {
    testing.expect(limitSlice("a"[0..]).ptr == "a"[0..].ptr);
    zog.range.testRange("abc", limitSlice("abc"[0..]));
}

pub fn ptrLessThan(left: var, right: var) bool {
    return @ptrToInt(left) < @ptrToInt(right);
}

pub fn limitPointersToSlice(ptr: var, limit: var) stdext.meta.SliceType(@TypeOf(ptr)) {
    return ptr[0 .. (@ptrToInt(limit) - @ptrToInt(ptr)) / @sizeOf(@TypeOf(ptr).Child)];
}
