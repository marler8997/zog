const builtin = @import("builtin");

pub fn Strtok(comptime Pointer: type) type {
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // TODO: add support for pointers with sentinel values
    //       also allow delims to be a pointer/sentinel
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    return struct {
         next: Pointer,
         limit: Pointer,
         delims: []const u8,
         //pub fn init(start: Pointer, limit: Pointer, delims: []const u8) @This() {
         //}
         pub fn init(start: Pointer, limit: Pointer, delims: []const u8) @This() {
             return @This() {
                 .start = start,
                 .limit = limit,
                 .delims = delims,
             };
         }
         pub fn next(self: *@This()) ?T {
             //while (self.
             //const start = str.ptr;
             
         }
    };
}

pub fn strtok(str: var, delims: []const u8) Strtok(ArrayPointerType(@TypeOf(str))) {
    switch (@typeInfo(@TypeOf(str))) {
        .Pointer => |info| {

        },
        else => @compileError("Expected slice/pointer but got '" ++ @typeName(@TypeOf(str)) ++ "'"),
    }

     
}

test "strtok" {
    {
        var s = strtok("a b c"[0..], " "[0..]);
        
    }
}


//
// TODO: these should be in the standard library and should be more complete
//

/// Given an array/pointer type, return the slice type `[]Child`. Preserves `const`.
pub fn SliceType(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Array => |info| []const info.child,
        .Pointer => |info| if (info.is_const) {
            return if (info.is_volatile) []const volatile info.child else []const info.child;
        } else {
            return if (info.is_volatile) []volatile info.child else []info.child;
        },
        else => @compileError("Expected pointer or array type, " ++ "found '" ++ @typeName(T) ++ "'"),
    };
}
/// Given an array/pointer type, return the "array pointer" type `[*]Child`. Preserves `const`.
pub fn ArrayPointerType(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Array => |info| [*]const info.child,
        .Pointer => |info| if (info.is_const) [*]const info.child else [*]info.child,
        else => @compileError("Expected pointer or array type, " ++ "found '" ++ @typeName(T) ++ "'"),
    };
}

