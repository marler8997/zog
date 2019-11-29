const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const testing = std.testing;

/// Given an array/pointer type, return the slice type `[]Child`.
/// Preserves all pointer attributes such as `const`/`volatile` etc.
pub fn Slice(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Array => |info| @compileError("Slice not implemented for arrays"),
        .Pointer => |info| @Type(builtin.TypeInfo { .Pointer = builtin.TypeInfo.Pointer {
            .size = builtin.TypeInfo.Pointer.Size.Slice,
            .is_const = info.is_const,
            .is_volatile = info.is_volatile,
            .alignment = info.alignment,
            .child = info.child,
            .is_allowzero = info.is_allowzero,
            .sentinel = info.sentinel,
        }}),
        else => @compileError("Expected pointer or array type, " ++ "found '" ++ @typeName(T) ++ "'"),
    };
}

test "std.meta.Slice" {
    testing.expect(Slice([]u8) == []u8);
    testing.expect(Slice([]const u8) == []const u8);
    testing.expect(Slice(*u8) == []u8);
    testing.expect(Slice(*const u8) == []const u8);
    testing.expect(Slice([*]u8) == []u8);
    testing.expect(Slice([*]const u8) == []const u8);
    //testing.expect(Slice([10]u8) == []const u8);

    testing.expect(Slice([]volatile u8) == []volatile u8);
    testing.expect(Slice([]const volatile u8) == []const volatile u8);
    testing.expect(Slice(*volatile u8) == []volatile u8);
    testing.expect(Slice(*const volatile u8) == []const volatile u8);
    testing.expect(Slice([*]volatile u8) == []volatile u8);
}

/// Given an array/pointer type, return the "many pointer" type `[*]Child`.
/// Preserves all pointer attributes such as `const`/`volatile` etc.
pub fn ManyPointer(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Array => |info| return [*]const info.child,
        .Pointer => |info| return @Type(builtin.TypeInfo { .Pointer = builtin.TypeInfo.Pointer {
            .size = builtin.TypeInfo.Pointer.Size.Many,
            .is_const = info.is_const,
            .is_volatile = info.is_volatile,
            .alignment = info.alignment,
            .child = info.child,
            .is_allowzero = info.is_allowzero,
            .sentinel = info.sentinel,
        }}),
        .Struct => |info| {
            if (zog.limitslice.isLimitSlice(T)) {
                return T.ManyPointer();
            }
        },
        else => {},
    }
    @compileError("Expected pointer/array type, " ++ "found '" ++ @typeName(T) ++ "'");
}

test "std.meta.ManyPointer" {
    testing.expect(ManyPointer([]u8) == [*]u8);
    testing.expect(ManyPointer([]const u8) == [*]const u8);
    testing.expect(ManyPointer(*u8) == [*]u8);
    testing.expect(ManyPointer(*const u8) == [*]const u8);
    testing.expect(ManyPointer([*]u8) == [*]u8);
    testing.expect(ManyPointer([*]const u8) == [*]const u8);
    //testing.expect(ManyPointer([10]u8) == [*]const u8);
}

/// Given an array/pointer type, return the "single pointer" type `*Child`.
/// Preserves all pointer attributes such as `const`/`volatile` etc.
pub fn SinglePointer(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Array => |info| return *const info.child,
        .Pointer => |info| return @Type(builtin.TypeInfo { .Pointer = builtin.TypeInfo.Pointer {
            .size = builtin.TypeInfo.Pointer.Size.One,
            .is_const = info.is_const,
            .is_volatile = info.is_volatile,
            .alignment = info.alignment,
            .child = info.child,
            .is_allowzero = info.is_allowzero,
            .sentinel = info.sentinel,
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
