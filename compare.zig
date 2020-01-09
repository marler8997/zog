const builtin = @import("builtin");
const std = @import("std");
const zog = @import("./zog.zig");

///Compares two of any type for equality. Containers are compared on a field-by-field basis,
/// where possible. Pointers are also followed.
pub fn deepEquals(a: var, b: @TypeOf(a)) bool {
    switch (@typeInfo(@TypeOf(a))) {
        builtin.TypeId.Pointer => |info| {
            switch (info.size) {
                builtin.TypeInfo.Pointer.Size.One,
                builtin.TypeInfo.Pointer.Size.Many,
                builtin.TypeInfo.Pointer.Size.C,
                    => @compileError("not implemented"),
                builtin.TypeInfo.Pointer.Size.Slice => return zog.mem.sliceEqual(a, b),
            }
        },
        else => return std.meta.eql(a, b),
    }
}