/// # Ranges
///
/// A range is a sequence of values.  This sequence of values could be bounded, infinite, lazy, generated on the fly or stored somewhere in memory. This module provides functions to use ranges and defines a standard interface for implementing them.
///
/// ## How to use Ranges
///
/// ### Rule 1: Never use a range directly
///
/// This means never calling methods or accessing fields directly on the range.  Instead, interact with the range through the functions defined in this module.  For example, if you want to check if a range is empty, you shouldn't call `r.empty()` or `r.rangeEmpty()`, instead you would call `zog.range.empty(&r)`.  The API to use a range is quite different from the API to implement a range.  This is because the implementation to use a range dynamically adapts to the range's implementation.  This module provides a generic API that works with any range implementation.
///
/// IDEA: instead of calling a different free function for each operation on a range, I could implement a range type where you pass in the range data, and then that range type implements all the operations.
/// while(zog.range.Range("hello").next()) |c| { ... }
///
/// ### Rule 2: Always pass ranges by reference
///
/// See the section "Why pass ranges by reference?" for details.
///
/// ### Rule 3: Use the minimal range interface you need
///
/// There is a pecking order in which you should use ranges.  Prefer the method that works for you that
/// comes earlier.  The earlier methods will be compatible with more range implementations and be more efficient.
///
/// 1. Use next()
///
///     while (zog.range.next(&r)) |element| { ... }
///
///     If the next function is all you need, use it.  It's more efficient to support than an interface like empty/peek/pop because the range doesn't need to worry about when and how many times each operation will be called.  It has one entry point to perform all 3 operations so it doesn't need to store state between each one to allow calling any operation at any time.  Only use the empty/peek/pop interface if you need to peek at values before deciding whether or not to pop.
///
/// 2. Use makePeekable()
///
///     Use this if there is a time where you want to get the next value but don't necessarily
///     want to pop it off the range yet.
///
///     var rPeekable = makePeekable(&r);
///     for (zog.range.peek(&rPeekable)) |element| {
///         ...
///         zog.range.pop(&rPeekable);
///         ...
///     }
///
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// TODO: talk about using the slicing and cloning operations
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// ### How do you create a range from another range?
///
///   Some ranges may support 'cloning' which means that you can create a copy of the range and iterate over both ranges independently and they will both yield the same values.  Some range may not support this.  A struct/union can indicate support by implementing the 'rangeClone' function.
///
///
/// ## How to implement a Range
///
/// There is a different pecking order when implementing a range than using one.  You want to implement the smallest set of functions that provide the most functionality and also accurately represent the best way to use your range.  For example, if you are a range for a null-terminated string, you wouldn't implement a `length` method, because that would require iterating the entire string to implement.  However, if you were implementing a slice range, then implementing the `length` field would be appropriate.
///
/// ### Element Access
///
///     1. rangeElementRefAt(index: usize) *T
///        Implement if elements can be accessed out of order and the range has storage for its values rather than being generated on the fly.
///
///     2. rangeElementAt(index: usize) T
///        Implement if you can't implement rangeElementRefAt but you can still access elements out of order.
///
///     3. rangePeek() T
///        Implement if you can't implement rangeElementRefAt or rangeElementAt (because elements can't be accessed out of order) or implement alongside rangeElementRefAt and rangeElementAt if it's more efficient.
///
///     4. rangeNext() ?T
///        Implement this if you can't implement the previous functions and peeking requires extra storage.  The user can still peek using makePeekable but will only use the extra storage needed to support peek if it's required.
///
/// ### Bounds
///
///     1. rangeLength() usize
///        Implement if remaining number of elements is known without needing to traverse the range.
///
///     2. rangeIndexInRange(index: usize) bool
///        Implement if you can't implement rangeLength (could be infinite or too big for usize, etc) but you can still check whether arbitrary indices are within the range without needing to traverse the range, or, implement alongside length if it's more efficient to check an index than to calculate the length and compare an index to it.
///
///     3. rangeEmpty() bool
///        Implement if you can't implement rangeLength/rangeIndexInRange or implement it alonside them if it's more efficient.
///
///     4. rangeNext (see rangeNext in the Element Access section above)
///
/// ### Iteration
///
///     1. rangePopMany(count: usize) void
///        Implement if elements can be popped more efficiently in groups than one at a time.
///
///     2. rangePopOne() void
///        Implement if the range only supports popping one element at a time. You could also choose to implement this alongside rangePopMany if the singe value case is more efficient.
///
/// ### Slicing
///
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// TODO
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
///
/// ### Cloning
///
///     1. rangeClone() T
///        Implement if you can create a copy of the range and iterate over both the original and the copy independently yielding the same values.  This is an important function to enable many operations on ranges, implement it if you can.
///
///
/// Thoughts and Notes
/// --------------------------------------------------------------------------------
/// * when designing the range implementation interface, I try to break up every operation as much as I can.  This helps simplify what the range has to implement in order to support all the operations it needs.  For example, a range could implement a function that returns the element at a given index.  This function could return an optional value in case the index is out of range.  However, this proposed operation can be split into 2 smaller operations, an operation that checks if the index is in range and then an operation to retrieve the element.   So in this case, the range implements both operations separately and then they can be re-used in higher-level operations.
///
///
// The sliceable functions like sliceableOffsetLimit, sliceableOffsetOnly and sliceableLimitLength
// actually implement 2 functions.  One is it copies a new "view" into the range and then it
// limits it somehow.  For example, if you had another function called "cloneView" that just created
// a copy of the range, then you could call "popMany" on that to emulate the same thing as
// sliceableOffsetOnly, i.e.
//
//    sliceableOffsetOnly(X) == cloneView().popMany(X)
//
// Because of this, I think that instead of the sliceable functions, I should probably create a cloneView
// function and a popMany function.  I may still want the sliceableFunctions in zog.range, however, they
// probably won't need to be implemented in the ranges themselves.
///
/// ## Why pass ranges by reference?
///
/// A range type should represent the data that needs to be stored to manage the range.  Note that the range type is not a pointer to the data, but the data itself. For example, a slice is a pointer and a length, and a slice is also a range type, however, a pointer to a slice is not a range type.  A pointer to a slice is a reference to a range.
///
/// Why is it always passed by reference?  Consistency.  Since a range type represents the data to manage the range, if you pass the range to a function that modifies the range, then it will need to change the data that manages the range, so it must have a reference to it rather than a copy of the range.  It would be possible to pass the range by value to an operation that does not modify the range, however, this would make the interface inconsistent and could cause a large amounts of data to be copied on the stack if the range data structure is large.

const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;

const zog = @import("./zog.zig");


const multipassrange = @import("./range/multipassrange.zig");
pub const MultiPassRange = multipassrange.MultiPassRange;
pub const multiPassRange = multipassrange.multiPassRange;

// ------
// empty/front/pop vs next
//
//   * there may be times where you want to check if a range is empty but not get the value yet

//   * there may be time where you want to get the value, but not pop yet (peek)
//   * if you have next(), it may allow some structures to need less "state"
//
// I need to come up with examples for these situations.
//
// I think this means that next() should be the default recommended interface because it allows
// the range to depend on the return value for storage, and empty would be an optional extension.
//
// We could say that ranges should only support the "empty/front" functions if it is 'free' to support them.
// Not supporting them indicates that the range would need to add extra storage to support it.
//
//
//
//

// TODO: Explore these range examples/test
// Add a limitLength operation that removes values from the end of the range.
// A sentinel pointer range (length is unknown)
// A limit array range (length is known)
// A file reader range
//    - could return single characters, strings, or lines
//

/// The element type of the given range type T.
pub fn RangeElement(comptime T: type) type {
    const errorMsg = "don't know range element type for: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| return info.child,
        .Struct, .Union => {
            // Check next first, as this is the lowest-common-denominator of a range
            if (@hasDecl(T, "rangeNext")) {
                if (@typeInfo(@TypeOf(T.rangeNext)).Fn.return_type) |t| {
                    return @typeInfo(t).Optional.child;
                } else @compileError("rangeNext must return a type");
            } else if (@hasDecl(T, "peek")) {
                @compileError("not implemented");
            } else if (@hasDecl(T, "rangeElementAt")) {
                if (@typeInfo(@TypeOf(T.rangeElementAt)).Fn.return_type) |t| {
                    return t;
                } else @compileError("rangeElementAt must return a type");
            } else if (@hasDecl(T, "rangeElementRefAt")) {
                if (@typeInfo(@TypeOf(T.rangeElementRefAt)).Fn.return_type) |t| {
                    return @typeInfo(t).Pointer.child;
                } else @compileError("rangeElementRefAt must return a type");
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

pub fn CounterRange(comptime T: type) type {
    return struct {
        next: T,
        limit: T,
        pub fn init(start: T, limit: T) @This() {
            std.debug.assert(limit >= start);
            return @This() {
                .next = start,
                .limit = limit,
            };
        }
        // do not implement rangeElementRefAt because we generate these values as we go
        pub fn rangeElementAt(self: *@This(), index: usize) T
        {
            const result = self.next + index;
            std.debug.assert(result < self.limit);
            return @intCast(T, result);
        }
        pub fn rangeLength(self: *@This()) usize { return self.limit - self.next; }

        // we implement rangeEmpty even though we don't need to because it's a bit
        // more efficient than the rangeLength implementation
        pub fn rangeEmpty(self: *@This()) bool { return self.next == self.limit; }

        pub fn rangePopMany(self: *@This(), count: usize) void
        {
            const newNext = self.next + count;
            std.debug.assert(newNext <= self.limit);
            self.next = @intCast(T, newNext);
        }
        pub fn rangeClone(self: *@This()) @This() {
            return @This() { .next = self.next, .limit = self.limit };
        }
    };
}

pub fn counterRange(start: anytype, limit: anytype) CounterRange(@TypeOf(start)) {
    return CounterRange(@TypeOf(start)).init(start, limit);
}

test "CounterRange" {
    try testRange([_]u8 {83}, CounterRange(u8).init(83, 84));
    try testRange([_]u8 {10, 11, 12}, CounterRange(u8).init(10, 13));
    {
        const u8Buffer : [0]u8 = undefined;
        try testRange(u8Buffer[0..], CounterRange(u8).init(32, 32));
    }
}

// TODO: create a range that reads a file line-by-line
// TODO: the default file range should accept a buffer and return slices to that buffer
pub const FileRange = struct {
    file: std.fs.File,
    pub fn rangeNext(self: *@This()) ?u8 { return self.file.read(); }
};

// `expected` is an array of the expected items that will be enumerated by `r`
pub fn testRange(expected: anytype, r: anytype) !void {
    var expectedIndex : usize = 0;
    var mutableRange = r;
    //@compileLog("@typeName(@TypeOf(mutableRange)) = ", @typeName(@TypeOf(mutableRange)));
    while (next(&mutableRange)) |actual| {
        //try testing.expect(expectedIndex < expected.len);
        if (expectedIndex >= expected.len) {
            std.debug.print("\nrange has more than the expected {} element(s)\n", expected.len);
            @panic("range has too many elements");
        }
        //std.debug.print("\nexpected: '{}' (type={})", expected[expectedIndex], @typeName(@TypeOf(expected[expectedIndex])));
        //std.debug.print("\nactual  : '{}' (type={})\n", actual, @typeName(@TypeOf(actual)));
        try testing.expect(zog.compare.deepEquals(expected[expectedIndex], actual));
        expectedIndex += 1;
    }
    try testing.expect(expectedIndex == expected.len);
}

/// Creates an efficient range from a slice.  It uses a limitSlice under-the-hood since
/// a limit-slice only needs to perform one operation to pop a value whereas a slice
/// needs to perform 2.
pub const sliceRange = zog.limitslice.limitSlice;

test "sliceRange" {
    try testRange(""[0..], sliceRange(""[0..]));
    try testRange("a"[0..], sliceRange("a"[0..]));
    try testRange("abcd"[0..], sliceRange("abcd"[0..]));
}

// TODO: move this, or delete it
pub fn dumpType(comptime T: type) void {
    @compileLog("dumpType '{}'", @typeName(T));
    switch (@typeInfo(T)) {
        .Struct => |info| {
            for (info.decls) |decl| {
                @compileLog("  decl '{}'", decl.name);
            }
        },
        else => {},
    }
}

pub fn empty(rref: anytype) bool {
    const T = @TypeOf(rref.*);
    const errorMsg = "don't know how to implement 'empty' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        // Array doesn't make sense because you can't modify a pointer to a constant array
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.len == 0; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "rangeEmpty")) {
                return rref.rangeEmpty();
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "empty" {
    //try testing.expect(empty(&""[0..]));
    //try testing.expect(!empty(&"a"[0..]));
    try testing.expect(empty(&sliceRange(""[0..])));
    try testing.expect(!empty(&sliceRange("b"[0..])));
    try testing.expect(empty(&CounterRange(u8).init(0, 0)));
    try testing.expect(!empty(&CounterRange(u8).init(0, 1)));
    // TODO: add some sentinel pointer/slice tests
    //try testing.expect(empty(&zog.sentinel.sentinelPtrRange(("".*)[0..].ptr)));
    //{
    //    var ptr : [*:0]const u8 = "";
    //    try testing.expect(empty(&ptr));
    //}

}

comptime {
    //@compileLog("hello");
    //@compileLog(@typeName(@TypeOf("abc")));
    std.debug.assert(*const [3:0]u8 == @TypeOf("abc"));
    std.debug.assert([3:0]u8 == @TypeOf("abc".*));
    //@compileLog("TYPE:");
    //@compileLog(@typeName(@TypeOf("abc".*)));
    //@compileLog(@typeName(@TypeOf("abc".*[0..])));
    /////!!!@compileLog(@typeName(SentinelArraySlice(@TypeOf("abc"))));
    //@compileLog(@typeName(@TypeOf(sentinelArraySlice("abc"))));
}

pub fn SentinelArraySlice(comptime T: type) type {
    const errorMsg = "expected pointer to sentinel array but got: " ++ @typeName(T);
    switch (@typeInfo(T))
    {
        .Pointer => |ptrInfo| {
            if (ptrInfo.size != .One)
                @compileError(errorMsg);
            switch (@typeInfo(ptrInfo.child))
            {
                .Array => |info| {
                    return @Type(builtin.Type { .Pointer = builtin.Type.Pointer {
                        .size = builtin.Type.Pointer.Size.Slice,
                        .is_const = true,
                        .is_volatile = false,
                        // Assertion failed at /deps/zig/src/ir.cpp:22457 in get_const_field. This is a bug in the Zig compiler.
                        //.alignment = @alignOf(info.child),
                        .alignment = 0,
                        .child = info.child,
                        //.is_allowzero = info.is_allowzero,
                        .is_allowzero = false,
                        .sentinel = info.sentinel,
                    }});
                },
                else => @compileError(errorMsg),
            }

        },
        else => @compileError(errorMsg),
    }
}
pub fn sentinelArraySlice(x: anytype) SentinelArraySlice(@TypeOf(x)) {
    return @as(SentinelArraySlice(@TypeOf(x)), x.*[0..]);
}

/// Clone a range.  After calling this, both ranges can be iterated independently and should have the same values.
pub fn clone(rref: anytype) @TypeOf(rref.*) {
    const T = @TypeOf(rref.*);
    const errorMsg = "don't know how to implement 'clone' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.*; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "rangeClone")) {
                return rref.rangeClone();
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "clone" {
    try testing.expect(zog.mem.sliceEqual(""[0..], clone(&""[0..])));
    try testing.expect(zog.mem.sliceEqual("a"[0..], clone(&"a"[0..])));
    try testRange(""[0..], clone(&sliceRange(""[0..])));
    try testRange("b"[0..], clone(&sliceRange("b"[0..])));
    try testRange(""[0..], clone(&CounterRange(u8).init(0, 0)));
    try testRange("\x00\x01"[0..], clone(&CounterRange(u8).init(0, 2)));
}

pub fn pop(rref: anytype) void {
    const T = @TypeOf(rref.*);
    const errorMsg = "don't know how to pop on type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { rref.* = rref.*[1..]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "rangePopOne")) {
                rref.rangePopOne();
            } else if (@hasDecl(T, "rangePopMany")) {
                rref.rangePopMany(1);
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "pop" {
    // Modifying an rvalue reference of a string literal causes segfault
    // see https://github.com/ziglang/zig/issues/3444
    //pop(&"a"[0..]);
    {
        var r = "a"[0..];
        pop(&r);
    }
    pop(&sliceRange("a"[0..]));
    pop(&CounterRange(u8).init(0, 1));
}

pub fn popMany(rref: anytype, count: usize) void {
    const T = @TypeOf(rref.*);
    const errorMsg = "don't know how to implement 'popMany' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { rref.* = rref.*[count..]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "rangePopMany")) {
                rref.rangePopMany(count);
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

pub fn peek(rref: anytype) RangeElement(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    const errorMsg = "don't know how to peek on type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.*[0]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "rangePeek")) {
                return rref.rangePeek();
            } else if (@hasDecl(T, "rangeElementAt")) {
                return rref.rangeElementAt(0);
            } else if (@hasDecl(T, "rangeElementRefAt")) {
                return rref.rangeElementRefAt(0).*;
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

/// A convenience function.
pub fn optionalPeek(rref: anytype) ?RangeElement(@TypeOf(rref.*)) {
    return if (empty(rref)) null else peek(rref);
}

test "optionalPeek" {
    try testing.expect(null == optionalPeek(&""[0..]));
    //try testing.expect('a'  == optionalPeek(&"a"[0..]).?);
    try testing.expect(null == optionalPeek(&sliceRange(""[0..])));
    try testing.expect('b'  == optionalPeek(&sliceRange("b"[0..])).?);
    try testing.expect(null == optionalPeek(&CounterRange(u8).init(0, 0)));
    try testing.expect(0    == optionalPeek(&CounterRange(u8).init(0, 1)).?);
}

pub fn Peekable(comptime T: type) type {
    if (@hasDecl(T, "rangePeek") ||
        @hasDecl(T, "rangeElementAt") ||
        @hasDecl(T, "rangeElementRefAt")) {
        return T;
    } else { // assume there is a 'rangeNext' method
        const NextReturnType = @typeInfo(T.rangeNext).Fn.return_type;
        return struct {
            rref: T,
            peeked: bool,
            peekValue: NextReturnType,
            pub fn init(rref: T) @This() {
                return @This() {
                    .rref = rref,
                    .peeked = false,
                    .peekValue = undefined,
                };
            }
            pub fn rangePeek(self: *@This()) NextReturnType {
                if (!self.peeked) {
                    self.peekValue = next(self.rref);
                    self.peeked = true;
                }
                return self.peekValue;
            }
            // TODO: define other methods
        };
    }

}
pub fn makePeekable(rref: anytype) Peekable(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    if (@hasDecl(T, "rangePeek") ||
        @hasDecl(T, "rangeElementAt") ||
        @hasDecl(T, "rangeElementRefAt")) {
        return rref;
    } else {
        return Peekable(@TypeOf(rref)).init(rref);
    }
}

pub fn next(rref: anytype) ?RangeElement(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    switch (@typeInfo(T)) {
        .Struct, .Union => {
            if (@hasDecl(T, "rangeNext")) {
                return rref.rangeNext();
            } else {
                if (empty(rref)) return null;
                var value = peek(rref);
                pop(rref);
                return value;
            }
        },
        else => {
            if (empty(rref)) return null;
            var value = peek(rref);
            pop(rref);
            return value;
        },
    }
}

pub fn length(rref: anytype) usize {
    const T = @TypeOf(rref.*);
    if (@hasField(T, "len")) {
        return rref.len;
    } else if (@hasDecl(T, "rangeLength")) {
        return rref.rangeLength();
    } else @compileError("don't know how to get length of " ++ @typeName(@TypeOf(rref)));
}

//fn RangeType(comptime T: type) type {
//    switch (@typeInfo(T)) {
//        .Array => |info| return PointerRange(zog.meta.ManyPointer(T)),
//        .Pointer => |info| return PointerRange(zog.meta.ManyPointer(T)),
//        else => @compileError("not implemented"),
//    }
//}
//pub fn range(x: anytype) callconv(.Inline) RangeType(@TypeOf(x)) {
//    switch (@typeInfo(@TypeOf(x))) {
//        .Array => |info| @compileError("cannot create a range from a static array passed-by-value: " ++ @typeName(@TypeOf(x))),
//        .Pointer => |info| switch (info.size) {
//            .One => return @compileError("OnePointer not implemented"),
//            .Many => @compileError("Many pointer not implemented"),
//            .Slice => return PointerRange(zog.meta.ManyPointer(@TypeOf(x))) {
//                .next = x.ptr,
//                .limit = x.ptr + x.len,
//            },
//            .C => @compileError("C pointer not implemented"),
//        },
//        //return PointerRange(zog.meta.ManyPointer(T)),
//        else => @compileError("not implemented"),
//    }
//}



/// pop elements until the given element is found
/// returns true if found, false otherwise
pub fn popFind(rref: anytype, element: anytype) bool {
    while (next(rref)) |e| {
        if (zog.compare.deepEquals(e, element))
            return true;
    }
    return false;
}

/// A convenience function around popFind.  It makes a clone of the range
/// when calling popFind so the original range position is maintained.
pub fn contains(rref: anytype, value: anytype) bool {
    var rangeClone = clone(rref);
    return popFind(&rangeClone, value);
}

test "contains" {
    try testing.expect(!contains(&""[0..], 'a'));
    // Modifying an rvalue reference of a string literal causes segfault
    // see https://github.com/ziglang/zig/issues/3444
    //try testing.expect( contains(&"a"[0..], 'a'));
    {
        var r = "a"[0..];
        try testing.expect( contains(&r, 'a'));
    }
    try testing.expect(!contains(&sliceRange(""[0..] ), 'b'));
    try testing.expect( contains(&sliceRange("b"[0..]), 'b'));
    try testing.expect(!contains(&CounterRange(u8).init(0, 0), 0));
    try testing.expect( contains(&CounterRange(u8).init(0, 1), 0));
}


/// pop elements out of range until any of the given elements is found
/// returns true if found, false otherwise
pub fn popFindAny(rref: anytype, any: anytype) bool {
    while (next(rref)) |e| {
        // need to clone so that we can start from the beginning
        // of any on the next iteration
        var anyClone = clone(any);
        for (next(&anyClone)) |e2| {
            if (zog.compare.deepEquals(e, e2))
                return true;
        }
    }
    return false;
}

pub fn indexOfAny(rref: anytype, any: anytype) ?usize {
    var i: usize = 0;
    while (indexInRange(rref, i)) : (i += 1) {
        if (contains(any, elementAt(rref, i)))
            return i;
    }
    return null;
}

test "indexOfAny" {
    try testing.expect(null == indexOfAny(&""[0..], &"abc"[0..]));
    try testing.expect(null == indexOfAny(&"jjklm"[0..], &"abc"[0..]));
    try testing.expect(4 == indexOfAny(&"jjklbm"[0..], &"abc"[0..]).?);
    //try testing.expect(empty(&sliceRange(""[0..])));
    //try testing.expect(!empty(&sliceRange("b"[0..])));
    //try testing.expect(empty(&CounterRange(u8).init(0, 0)));
    //try testing.expect(!empty(&CounterRange(u8).init(0, 1)));
}

// TODO: sliceableOffsetLength?

// TODO: if the type does not support sliceableOffsetLimit but does support
//       rangePopMany and shrinkMany then we can use those
pub fn sliceableOffsetLimit(rref: anytype, offset: usize, limit: usize) @TypeOf(rref.*) {
    const T = @TypeOf(rref.*);
    //const errorMsg = "don't know how to implement sliceableOffsetLimit for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => return rref.*[offset .. limit],
        .Struct, .Union => {
            return rref.sliceableOffsetLimit(offset, limit);
        },
        else => return offset < length(rref),
    }
}

test "sliceableOffsetLimit" {
    try testing.expect(zog.mem.sliceEqual(""[0..], sliceableOffsetLimit(&""[0..], 0, 0)));
    try testing.expect(zog.mem.sliceEqual(""[0..], sliceableOffsetLimit(&"a"[0..], 0, 0)));
    try testing.expect(zog.mem.sliceEqual(""[0..], sliceableOffsetLimit(&"a"[0..], 1, 1)));
    try testing.expect(zog.mem.sliceEqual("a"[0..], sliceableOffsetLimit(&"a"[0..], 0, 1)));
    try testing.expect(zog.mem.sliceEqual("34"[0..], sliceableOffsetLimit(&"123456"[0..], 2, 4)));

    //try testing.expect(zog.compare.deepEquals(&sliceRange("bc"[0..]), sliceableOffsetLimit(&sliceRange("abcd"[0..]), 1, 3)));
    _ = sliceableOffsetLimit(&sliceRange("abcd"[0..]), 1, 3);

    // TODO: CounterRange not supported yet, need to allow sliceableOffsetLimit to fallback
    //       to calling popMany and something else
    //try testing.expect(!indexInRange(&CounterRange(u8).init(0, 0), 0));
    //try testing.expect( indexInRange(&CounterRange(u8).init(0, 1), 0));
    //_ = sliceableOffsetLimit(&CounterRange(u8).init(0, 100), 10, 20);
}

// Just a convenience function
pub fn sliceableOffsetOnly(rref: anytype, offset: usize) @TypeOf(rref.*) {
    var rangeCopy = clone(rref);
    popMany(&rangeCopy, offset);
    return rangeCopy;
}
pub fn sliceableLimitLength(rref: anytype, limitLength: usize) @TypeOf(rref.*) {
    const T = @TypeOf(rref.*);
    if (@hasDecl(T, "sliceableLimitLength")) {
        return rref.sliceableLimitLength(limitLength);
    } else return sliceableOffsetLimit(rref, 0, limitLength);
}

pub fn asSlice(rref: anytype) []RangeElement(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    if (@hasDecl(T, "asSlice")) {
        return rref.asSlice();
    } else @compileError("don't know how to make " ++ @typeName(T) ++ " into a slice");
}


pub fn AsArrayPointerResult(comptime T: type) type {
    if (@hasDecl(T, "asArrayPointer")) {
        return @typeInfo(@TypeOf(T.asArrayPointer)).Fn.return_type orelse {
            @compileError("asArrayPointer must return a type");
        };
    } else @compileError("don't know how to make " ++ @typeName(T) ++ " into an array pointer");
}
// Return a pointer to an array of elements for the range
pub fn asArrayPointer(rref: anytype) AsArrayPointerResult(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    if (@hasDecl(T, "asArrayPointer")) {
        return rref.asArrayPointer();
    } else @compileError("don't know how to make " ++ @typeName(T) ++ " into an array pointer");
}

/// Return the slice type for a Sliceable
pub fn SliceableSlice(comptime Sliceable: type) type {
    if (@typeInfo(@TypeOf(Sliceable.sliceOffsetLimit)).Fn.return_type) |t| {
        return t;
    } else @compileError(".sliceOffsetLimit must return a type");
}


pub fn indexInRange(rref: anytype, index: usize) bool {
    const T = @TypeOf(rref.*);
    //const errorMsg = "don't know how to implement indexInRange for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Struct, .Union => {
            if (@hasDecl(T, "rangeIndexInRange")) {
                return rref.rangeIndexInRange(index);
            } else {
                return index < length(rref);
            }
        },
        else => return index < length(rref),
    }
}

test "indexInRange" {
    try testing.expect(!indexInRange(&""[0..], 0));
    try testing.expect( indexInRange(&"a"[0..], 0));
    try testing.expect(!indexInRange(&sliceRange(""[0..]), 0));
    try testing.expect( indexInRange(&sliceRange("b"[0..]), 0));
    try testing.expect(!indexInRange(&CounterRange(u8).init(0, 0), 0));
    try testing.expect( indexInRange(&CounterRange(u8).init(0, 1), 0));
}

/// Indexable
//
/// Can assert if index is out-of-range, but does not return an error.
/// If the caller wants to check whether the index is out of range then they
/// can call another function to check this.
pub fn elementAt(rref: anytype, index: usize) RangeElement(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    const errorMsg = "don't know how to implement 'elementAt' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.*[index]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "rangeElementAt")) {
                return rref.rangeElementAt(index);
            } else if (@hasDecl(T, "rangeElementRefAt")) {
                return rref.rangeElementRefAt(index).*;
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "elementAt" {
    //try testing.expect('a' == elementAt(&"a"[0..], 0));
    //try testing.expect('2' == elementAt(&"abc1234"[0..], 4));
    try testing.expect('b' == elementAt(&sliceRange("b"[0..]), 0));
    try testing.expect('j' == elementAt(&sliceRange("fdkazjlad"[0..]), 5));
    try testing.expect(8 == elementAt(&CounterRange(u8).init(0, 9), 8));
}

// Takes a slice as the 2nd parameter because we're definitely going to need the length
pub fn startsWith(rref: anytype, slice: []const RangeElement(@TypeOf(rref.*))) bool {
    return indexInRange(rref, slice.len) and
        zog.mem.ptrEqual(asArrayPointer(rref), slice.ptr, slice.len);
}

test "startsWith" {
    {
        var r = sliceRange("abcd"[0..]);
        try testing.expect(startsWith(&r, "a"[0..]));
    }
}

pub fn popIfMatch(rref: anytype, slice: anytype) bool {
    if (startsWith(rref, slice)) {
        popMany(rref, slice.len);
        return true;
    }
    return false;
}
