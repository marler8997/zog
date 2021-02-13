//
// Keeping this file around.
//
// This file allows you to use slices and arrays directly as ranges, however,
// I'm currently going to require wrapping these values in a struct to use them
// as ranges.
//

const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;

/// The purpose for this function is to be able to support both primitive types
/// and user-defined types in the same way.  Because you can't add member functions
/// to primitive types, this function will either detect and support the primitive type
/// or it will check if the given range has the `empty` member function.
pub fn empty(r: anytype) callconv(.Inline) bool {
    switch (@typeInfo(@TypeOf(r))) {
        .Array => |info| return r.len == 0,
        .Pointer => |info| {
            switch (info.size) {
                .One, .Many, .C => @compileError("empty cannot be called on unknown-length pointer " ++ @typeName(@TypeOf(r))),
                .Slice => return r.len == 0,
            }
           
        },
        else => return r.empty(),
    }
}

test "empty" {
    testing.expect(empty(""));
    testing.expect(!empty("a"));
    testing.expect(empty(""[0..]));
    testing.expect(!empty("a"[0..]));


    // TODO: test these compiler errors
    if (false) {
        {
            var x : u8 = 0;
            testing.expect(!empty(&x));
        }
        testing.expect(!empty("a"[0..].ptr));
        // TODO: make sure it doesn't support C pointers
    }
}

