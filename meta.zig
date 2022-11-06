const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const testing = std.testing;

/// Given an array/pointer type, return the slice type `[]Child`.
/// Preserves all pointer attributes such as `const`/`volatile` etc.
pub fn Slice(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Array => @compileError("Slice not implemented for arrays"),
        .Pointer => |info| @Type(std.builtin.Type { .Pointer = std.builtin.Type.Pointer {
            .size = std.builtin.Type.Pointer.Size.Slice,
            .is_const = info.is_const,
            .is_volatile = info.is_volatile,
            .alignment = info.alignment,
            .address_space = info.address_space,
            .child = info.child,
            .is_allowzero = info.is_allowzero,
            .sentinel = info.sentinel,
        }}),
        else => @compileError("Expected pointer or array type, " ++ "found '" ++ @typeName(T) ++ "'"),
    };
}

test "std.meta.Slice" {
    try testing.expect(Slice([]u8) == []u8);
    try testing.expect(Slice([]const u8) == []const u8);
    try testing.expect(Slice(*u8) == []u8);
    try testing.expect(Slice(*const u8) == []const u8);
    try testing.expect(Slice([*]u8) == []u8);
    try testing.expect(Slice([*]const u8) == []const u8);
    //try testing.expect(Slice([10]u8) == []const u8);

    try testing.expect(Slice([]volatile u8) == []volatile u8);
    try testing.expect(Slice([]const volatile u8) == []const volatile u8);
    try testing.expect(Slice(*volatile u8) == []volatile u8);
    try testing.expect(Slice(*const volatile u8) == []const volatile u8);
    try testing.expect(Slice([*]volatile u8) == []volatile u8);
}

/// Converts slices or pointers to arrays to the [*]T "ManyPointer" equivalent.
/// For example: []u8 becomes [*]u8 and *[N]u8 becomes [*]u8
/// Preserves all pointer attributes such as `const`/`volatile` etc.
pub fn ManyPointer(comptime T: type) type {
    const errorMsg = "ManyPointer does not support type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| switch (info.size) {
            .One => switch (@typeInfo(info.child)) {
                .Array => |array_info| return @Type(std.builtin.Type { .Pointer = std.builtin.Type.Pointer {
                    .size = std.builtin.Type.Pointer.Size.Many,
                    .is_const = true,
                    .is_volatile = false,
                    .alignment = @alignOf(array_info.child),
                    .address_space = info.address_space,
                    .child = array_info.child,
                    .is_allowzero = false,
                    .sentinel = array_info.sentinel,
                }}),
                else => @compileError(errorMsg),
            },
            .Many => return T,
            .Slice, .C => return @Type(std.builtin.Type { .Pointer = std.builtin.Type.Pointer {
                .size = std.builtin.Type.Pointer.Size.Many,
                .is_const = info.is_const,
                .is_volatile = info.is_volatile,
                .alignment = info.alignment,
                .address_space = info.address_space,
                .child = info.child,
                .is_allowzero = info.is_allowzero,
                .sentinel = info.sentinel,
            }}),
        },
//        .Struct => |info| {
//            // TODO: support a @hasDecl(T, "ManyPointer") interface?
//            if (zog.limitslice.isLimitSlice(T)) {
//                return T.ManyPointer();
//            }
//        },
        else => @compileError(errorMsg),
    }
}

test "std.meta.ManyPointer" {
    try testing.expect(ManyPointer([]u8) == [*]u8);
    try testing.expect(ManyPointer([]const u8) == [*]const u8);
    try testing.expect(ManyPointer([*]u8) == [*]u8);
    try testing.expect(ManyPointer([*]const u8) == [*]const u8);
    try testing.expect(ManyPointer(*[10]u8) == [*]const u8);
    try testing.expect(ManyPointer(*const [10]u8) == [*]const u8);
}

/// Given an array/pointer type, return the "single pointer" type `*Child`.
/// Preserves all pointer attributes such as `const`/`volatile` etc.
pub fn SinglePointer(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Array => |info| return *const info.child,
        .Pointer => |info| return @Type(std.builtin.Type { .Pointer = std.builtin.Type.Pointer {
            .size = std.builtin.Type.Pointer.Size.One,
            .is_const = info.is_const,
            .is_volatile = info.is_volatile,
            .alignment = info.alignment,
            .child = info.child,
            .is_allowzero = info.is_allowzero,
            .sentinel = null,
        }}),
        //.Struct => |info| {
        //    if (zog.limitslice.isLimitSlice(T)) {
        //        return T.ManyPointer();
        //    }
        //},
        else => {},
    }
    @compileError("Expected pointer/array type, " ++ "found '" ++ @typeName(T) ++ "'");
}
