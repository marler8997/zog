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
            return self.ptr[0 .. self.length()];
        }

        pub fn length(self: *const @This()) usize {
            return (@ptrToInt(self.limit) - @ptrToInt(self.ptr)) / @sizeOf(@typeInfo(T).Pointer.child);
        }
        // Implementing indexInRange since length requires a divide
        pub fn indexInRange(self: *const @This(), index: usize) bool {
            return @ptrToInt(self.ptr + index) < @ptrToInt(self.limit);
        }

        pub fn elementAt(self: *@This(), index: usize) @typeInfo(T).Pointer.child {
            const ptr = self.ptr + index;
            std.debug.assert(@ptrToInt(ptr) < @ptrToInt(self.limit));
            return ptr[0];
        }

        pub fn popMany(self: *@This(), count: usize) void {
            const newPtr = self.ptr + count;
            std.debug.assert(@ptrToInt(newPtr) <= @ptrToInt(self.limit));
            self.ptr = newPtr;
        }

        // empty function defined because the empty check is more efficient than checking an index
        pub fn empty(self: *const @This()) bool {
            return self.ptr == self.limit;
        }

        pub fn asArrayPointer(self: *@This()) T { return self.ptr; }

        pub fn sliceableOffsetOnly(self: *@This(), offset: usize) @This() {
            if (@ptrToInt(self.ptr + offset) > @ptrToInt(self.limit))
                unreachable;
            return @This() { .ptr = self.ptr + offset, .limit = self.limit, };
        }
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

pub inline fn limitSlice(x: var) LimitSlice(zog.meta.ManyPointer(@typeOf(x))) {
    if (zog.meta.Slice(@typeOf(x)) != @typeOf(x))
        @compileError("pointerRange requires a slice but got " ++ @typeName(@typeOf(x)));
    return LimitSlice(zog.meta.ManyPointer(@typeOf(x))) {
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

pub fn limitPointersToSlice(ptr: var, limit: var) stdext.meta.SliceType(@typeOf(ptr)) {
    return ptr[0 .. (@ptrToInt(limit) - @ptrToInt(ptr)) / @sizeOf(@typeOf(ptr).Child)];
}
