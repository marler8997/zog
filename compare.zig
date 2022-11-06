const builtin = @import("builtin");
const std = @import("std");
const zog = @import("./zog.zig");

///Compares two of any type for equality. Containers are compared on a field-by-field basis,
/// where possible. Pointers are also followed.
pub fn deepEquals(a: anytype, b: @TypeOf(a)) bool {
    switch (@typeInfo(@TypeOf(a))) {
        .Pointer => |info| {
            switch (info.size) {
                builtin.Type.Pointer.Size.One,
                builtin.Type.Pointer.Size.Many,
                builtin.Type.Pointer.Size.C,
                    => @compileError("not implemented"),
                builtin.Type.Pointer.Size.Slice => return zog.mem.sliceEqual(a, b),
            }
        },
        else => return std.meta.eql(a, b),
    }
}
