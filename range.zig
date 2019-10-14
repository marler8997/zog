/// ### What is a range?
///     A range is a sequence of values.
/// ### What operations are supported by ranges?
///     This module implements a set of functions that you can call with a range.
/// ### Do you pass ranges by value or by reference?
///     Ranges are almost always passed by reference.  A range type should represent the data that needs to be stored to manage the range.  Note that the range type is not a pointer to the data, but the data itself. For example, a slice is a pointer and a length, and a slice is also a range type, however, a pointer to a slice is not a range type.  A pointer to a slice is a reference to a range.
///
///     Why is it always passed by reference?  Consistency.  Since a range type represents the data to manage the range, if you pass the range to a function that modifies the range, then it will need to change the data that manages the range, so it must have a reference to it rather than a copy of the range.  It would be possible to pass the range by value to an operation that does not modify the range, however, this would make the interface inconsistent and could cause a large amounts of data to be copied on the stack if the range data structure is large.
///
/// ### How do you create a range from another range?
///
///   Some ranges may support 'cloning' which means that you can create a copy of the range and iterate over both ranges independently and they will both yield the same values.  Some range may not support this.  A struct/union can indicate support by implementing the 'clone' function.
///
///
///
/// Thoughts and Notes
/// --------------------------------------------------------------------------------
/// * when designing the functions that a range can implement, I try to break up every operation as much as I can.  This helps simplify what the range has to implement in order to support all the operations it needs.  For example, a range could implement a function that returns the element at a given index.  This function could return an optional value in case the index is out of range.  However, this proposed operation can be split into 2 smaller operations, an operation that checks if the index is in range and then an operation to retrieve the element.   So in this case, the range implements both operations separately and then they can be re-used in higher-level operations.


// NOTES:
// I think elementAt and peekTo are duplicating the same functionality.  Not sure which
// one is better. The only difference was that peekTo returned an optional value.  Instead,
// I think just having elementAt is good, it should assert on indexOfOfRange.  If a program
// wants to check an index, they can can call indexInRange beforehand.
//

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


/// How to use ranges:
///
/// Ranges have a wide variety of ways to be defined.  As such, range methods should never be
/// called directly.  Instead, methods that use ranges should use the free functions found in this module
/// to interact with ranges. For example, if you want to check if a range is empty, you shouldn't call
/// `r.empty()`, instead you would call `zog.range.empty(&r)`.
///
/// There is a pecking order in which you should use ranges.  Prefer the method that works for you that
/// comes earlier.  The earlier methods will be compatible with more ranges and be more efficient.
///
/// 1. Use next()
///     while (zog.range.next(&r)) |element| { ... }
/// 2. Use makePeekable()
///     Use this if there is a time where you want to get the next value but don't necessarily
///     want to pop it off the range yet.
///
///     var rPeek = makePeekable(&r);
///     for (zog.range.peek(&rPeek)) |element| {
///         ...
///         zog.range.pop(&rPeek);
///         ...
///     }
///
/// There is a different pecking order if you are implementing a range.  You want to implement the smallest
/// set of functions that provide the most functionality and also accurately represent the best way to
/// use your range.  For example, if you are a range for a null-terminated string, you wouldn't implement
/// a `length` method, because that would require iterating the entire string to implement.  However, if
/// you were implementing a slice range, then implementing the `length` field would be appropriate.
///
/// 1. elementAtRef or elementAt
///    elementAtRef should be preferred as it is more powerful.  It should be implemented if it makes sense.
///    If you implement this, you should probably also implement:
///        * length or indexInRange
///        * popMany or pop
///    If elementAt can't be implemented, should front be implemented instead?
/// 2. length (prefer over indexInRange)
/// 3. indexInRange: implement if either not implementing length, or if it is more efficient than length
/// 4. empty
///    If your range implements length or indexInRange should it implement empty?
///    I think if the empty function is smaller/quicker than a length or indexInRange check
///    then the range should probably still implement empty.
///
///


///
/// Range Use Case: Indexable
/// ---------------------------------
/// pub fn elementRefAt(rref: var, index: usize) *T; // defined by range
/// pub fn elementAt(rref: var, index: usize) T;     // defined by zog.range, calls elementRefAt
///
///

const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;

const zog = @import("./zog.zig");


// When should a range be used?  If you require the ability to slice then data then you probably
// should just accept a slice.  Otherwise, slicing would require allocation each time.
//
// I could see a reason for having an 'indexable' interface, but not a 'sliceable' one.  If you need
// the ability to slice, then you would either need it as a slice already, or you would have to allocate
// memory every time you make a new slice.
//
// ------
// empty/front/popFront vs next
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
            if (@hasDecl(T, "next")) {
                const U = @typeOf(T.peek).Fn.return_type;
                return U.Optional.child;
            } else if (@hasDecl(T, "peek")) {
            } else if (@hasDecl(T, "elementAt")) {
                if (@typeInfo(@typeOf(T.elementAt)).Fn.return_type) |t| {
                    return t;
                } else @compileError("elementAt must return a type");
            } else if (@hasDecl(T, "elementAtRef")) {
                if (@typeInfo(@typeOf(T.elementAtRef)).Fn.return_type) |t| {
                    return @typeInfo(t).Pointer.child;
                } else @compileError("elementAtRef must return a type");
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
        // Cloneable
        pub fn clone(self: *@This()) @This() {
            return @This() { .next = self.next, .limit = self.limit };
        }
        // SkipIterable
        pub fn popMany(self: *@This(), count: usize) void
        {
            const newNext = self.next + count;
            std.debug.assert(newNext <= self.limit);
            self.next = @intCast(T, newNext);
        }
        // EmptyPeekable
        pub fn empty(self: *@This()) bool { return self.next == self.limit; }
        // LengthPeekable
        pub fn length(self: *@This()) usize { return self.limit - self.next; }
        // Indexable
        pub fn elementAt(self: *@This(), index: usize) T
        {
            const result = self.next + index;
            std.debug.assert(result < self.limit);
            return @intCast(T, result);
        }
    };
}

pub fn counterRange(start: var, limit: var) CounterRange(@typeOf(start)) {
    return CounterRange(@typeOf(start)).init(start, limit);
}

test "CounterRange" {
    testRange([_]u8 {83}, CounterRange(u8).init(83, 84));
    testRange([_]u8 {10, 11, 12}, CounterRange(u8).init(10, 13));
    {
        const u8Buffer : [0]u8 = undefined;
        testRange(u8Buffer[0..], CounterRange(u8).init(32, 32));
    }
}

// TODO: create a range that reads a file line-by-line
// TODO: the default file range should accept a buffer and return slices to that buffer
pub const FileRange = struct {
    file: File,
    pub fn next(self: *@This()) ?u8 { return file.read(); }
};


// Cloneable: clone the iterator so you can iterate multiple times
//   fn clone() T;
// LengthPeekable:
//   fn length() usize;
// NextIterable: Use if implementing peek/pop requires extra storage
//   fn next() T?;
// OneIterable:
//   fn pop() void; // pop the next value without returning it
// SkipIterable:
//   fn popMany(count: usize) void; // pop `count` values
// CanQueryIndexInBound:
//   fn indexInRange(index: usize) bool
// RefIndexable:
//   fn elementAtRef(index: usize) *T (preferred over Indexable)
// ValueIndexable:
//   fn elementAt(index: usize) T (prefer RefIndexable if possible)
// EmptyPeekable: Defined if you can check if the range is empty.  This should ONLY be supported if it can be supported without storing extra state.
//   fn empty() bool;
// IndexEmptyPeekable?  fn empty(usize) bool;
// OnePeekRange:
//   fn peek() T;
//   fn optionalPeek() ?T; // not sure if this is necessary
//   NOTE: multiple peek should implement elementAt
// Sliceable: also implies it is indexable
//   fn slice(offset: usize, limit: usize) T;
//

// Helper methods
// next()
// Iterable/ValueIndexable  :  fn next() T { var n = self.elementAt(0); if (n) self.pop(); return n; }
// Iterable/OnePeekRange:  fn next() T { var n = self.peek(); if (n) self.pop(); return n; }

// `expected` is an array of the expected items that will be enumerated by `r`
pub fn testRange(expected: var, r: var) void {
    var expectedIndex : usize = 0;
    var mutableRange = r;
    //@compileLog("@typeName(@typeOf(mutableRange)) = ", @typeName(@typeOf(mutableRange)));
    while (next(&mutableRange)) |actual| {
        //testing.expect(expectedIndex < expected.len);
        if (expectedIndex >= expected.len) {
            std.debug.warn("range has more than the expected {} element(s)\n", expected.len);
            @panic("range has too many elements");
        }
        //std.debug.warn("\nexpected: {}", expected[expectedIndex]);
        //std.debug.warn("\nactual  : {}\n", actual);
        testing.expect(std.meta.eql(expected[expectedIndex], actual));
        expectedIndex += 1;
    }
    testing.expect(expectedIndex == expected.len);
}

/// Creates an efficient range from a slice.  It uses a limitSlice under-the-hood since
/// a limit-slice only needs to perform one operation to pop a value whereas a slice
/// needs to perform 2.
pub const sliceRange = zog.limitslice.limitSlice;

test "sliceRange" {
    testRange(""[0..], sliceRange(""[0..]));
    testRange("a"[0..], sliceRange("a"[0..]));
    testRange("abcd"[0..], sliceRange("abcd"[0..]));
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

pub fn empty(rref: var) bool {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to implement 'empty' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.len == 0; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "empty")) {
                return rref.empty();
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "empty" {
    testing.expect(empty(&""[0..]));
    testing.expect(!empty(&"a"[0..]));
    testing.expect(empty(&sliceRange(""[0..])));
    testing.expect(!empty(&sliceRange("b"[0..])));
    testing.expect(empty(&zog.sentinel.assumeSentinel(c"")));
    testing.expect(!empty(&zog.sentinel.assumeSentinel(c"abc")));
    testing.expect(empty(&CounterRange(u8).init(0, 0)));
    testing.expect(!empty(&CounterRange(u8).init(0, 1)));
}

/// Clone a range.  After calling this, both ranges can be iterated independently and should have the same values.
pub fn clone(rref: var) @typeOf(rref.*) {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to implement 'clone' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.*; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "clone")) {
                return rref.clone();
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "clone" {
    testing.expect(zog.mem.sliceEqual(""[0..], clone(&""[0..])));
    testing.expect(zog.mem.sliceEqual("a"[0..], clone(&"a"[0..])));
    testRange(""[0..], clone(&sliceRange(""[0..])));
    testRange("b"[0..], clone(&sliceRange("b"[0..])));
    testRange(""[0..], clone(&CounterRange(u8).init(0, 0)));
    testRange("\x00\x01"[0..], clone(&CounterRange(u8).init(0, 2)));
}

pub fn pop(rref: var) void {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to pop on type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { rref.* = rref.*[1..]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "pop")) {
                rref.pop();
            } else if (@hasDecl(T, "popMany")) {
                rref.popMany(1);
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

pub fn popMany(rref: var, count: usize) void {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to implement 'popMany' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { rref.* = rref.*[count..]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "popMany")) {
                rref.popMany(count);
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

pub fn peek(rref: var) RangeElement(@typeOf(rref.*)) {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to peek on type: " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.*[0]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "peek")) {
                return rref.peek();
            } else if (@hasDecl(T, "elementAt")) {
                return rref.elementAt(0);
            } else if (@hasDecl(T, "elementAtRef")) {
                return rref.elementAtRef(0).*;
            } else @compileError("peek does not seem to support this type");
        },
        else => @compileError(errorMsg),
    }
}

/// A convenience function.
pub fn optionalPeek(rref: var) ?RangeElement(@typeOf(rref.*)) {
    return if (empty(rref)) null else peek(rref);
}

test "optionalPeek" {
    testing.expect(null == optionalPeek(&""[0..]));
    testing.expect('a'  == optionalPeek(&"a"[0..]).?);
    testing.expect(null == optionalPeek(&sliceRange(""[0..])));
    testing.expect('b'  == optionalPeek(&sliceRange("b"[0..])).?);
    testing.expect(null == optionalPeek(&CounterRange(u8).init(0, 0)));
    testing.expect(0    == optionalPeek(&CounterRange(u8).init(0, 1)).?);
}

pub fn Peekable(comptime T: type) type {
    const Range = @typeOf(T).Pointer.child;
    if (@hasDecl(Range, "peek") || @hasDecl(Range, "elementAt")) {
        return T;
    } else { // assume there is a 'next' method
        const NextReturnType = @typeInfo(T.next).Fn.return_type;
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
            pub fn peek(self: *@This()) NextReturnType {
                if (!self.peeked) {
                    //self.peekValue = next(self.rref);
                    self.peekValue = self.rref.next();
                    self.peeked = true;
                }
                return self.peekValue;
            }
            // TODO: define other methods
        };
    }

}
pub fn makePeekable(rref: var) Peekable(@typeOf(rref)) {
    if (@hasDecl(@typeOf(r.*), "peek")
        || @hasDecl(@typeOf(r.*), "elementAt")
        || @hasDecl(@typeOf(r.*), "elementAtRef")) {
        return rref;
    } else {
        return Peekable(@typeOf(rref)).init(rref);
    }
}

pub fn next(rref: var) ?RangeElement(@typeOf(rref.*)) {
    const T = @typeOf(rref.*);
    switch (@typeInfo(T)) {
        .Struct, .Union => {
            if (@hasDecl(T, "next")) {
                return rref.next();
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

pub fn length(rref: var) usize {
    const T = @typeOf(rref.*);
    if (@hasField(T, "len")) {
        return rref.len;
    } else if (@hasDecl(T, "length")) {
        return rref.length();
    } else @compileError("don't know how to get length of " ++ @typeName(@typeOf(rref)));
}


//fn RangeType(comptime T: type) type {
//    switch (@typeInfo(T)) {
//        .Array => |info| return PointerRange(zog.meta.ManyPointer(T)),
//        .Pointer => |info| return PointerRange(zog.meta.ManyPointer(T)),
//        else => @compileError("not implemented"),
//    }
//}
//pub inline fn range(x: var) RangeType(@typeOf(x)) {
//    switch (@typeInfo(@typeOf(x))) {
//        .Array => |info| @compileError("cannot create a range from a static array passed-by-value: " ++ @typeName(@typeOf(x))),
//        .Pointer => |info| switch (info.size) {
//            .One => return @compileError("OnePointer not implemented"),
//            .Many => @compileError("Many pointer not implemented"),
//            .Slice => return PointerRange(zog.meta.ManyPointer(@typeOf(x))) {
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
pub fn popFind(rref: var, element: var) bool {
    while (next(rref)) |e| {
        if (std.meta.eql(e, element))
            return true;
    }
    return false;
}

/// A convenience function around popFind.  It makes a clone of the range
/// when calling popFind so the original range position is maintained.
pub fn contains(rref: var, value: var) bool {
    var rangeClone = clone(rref);
    return popFind(&rangeClone, value);
}

test "contains" {
    testing.expect(!contains(&""[0..], 'a'));
    // Modifying an rvalue reference of a string literal causes segfault
    // see https://github.com/ziglang/zig/issues/3444
    //testing.expect( contains(&"a"[0..], 'a'));
    {
        var r = "a"[0..];
        testing.expect( contains(&r, 'a'));
    }
    testing.expect(!contains(&sliceRange(""[0..] ), 'b'));
    testing.expect( contains(&sliceRange("b"[0..]), 'b'));
    testing.expect(!contains(&CounterRange(u8).init(0, 0), 0));
    testing.expect( contains(&CounterRange(u8).init(0, 1), 0));
}


/// pop elements out of range until any of the given elements is found
/// returns true if found, false otherwise
pub fn popFindAny(rref: var, any: var) bool {
    while (next(rref)) |e| {
        // need to clone so that we can start from the beginning
        // of any on the next iteration
        var anyClone = any.clone();
        for (next(&anyClone)) |e2| {
            if (std.meta.eql(e, e2))
                return true;
        }
    }
    return false;
}

pub fn indexOfAny(rref: var, any: var) ?usize {
    var i: usize = 0;
    while (indexInRange(rref, i)) : (i += 1) {
        if (contains(any, elementAt(rref, i)))
            return i;
    }
    return null;
}

test "indexOfAny" {
    testing.expect(null == indexOfAny(&""[0..], &"abc"[0..]));
    testing.expect(null == indexOfAny(&"jjklm"[0..], &"abc"[0..]));
    testing.expect(4 == indexOfAny(&"jjklbm"[0..], &"abc"[0..]).?);
    //testing.expect(empty(&sliceRange(""[0..])));
    //testing.expect(!empty(&sliceRange("b"[0..])));
    //testing.expect(empty(&CounterRange(u8).init(0, 0)));
    //testing.expect(!empty(&CounterRange(u8).init(0, 1)));
}

// TODO: sliceableOffsetLength?

// TODO: if the type does not support sliceableOffsetLimit but does support
//       popMany and shrinkMany then we can use those
pub fn sliceableOffsetLimit(rref: var, offset: usize, limit: usize) @typeOf(rref.*) {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to implement sliceableOffsetLimit for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => return rref.*[offset .. limit],
        .Struct, .Union => {
            return rref.sliceableOffsetLimit(offset, limit);
        },
        else => return index < length(rref),
    }
}

test "sliceableOffsetLimit" {
    testing.expect(zog.mem.sliceEqual(""[0..], sliceableOffsetLimit(&""[0..], 0, 0)));
    testing.expect(zog.mem.sliceEqual(""[0..], sliceableOffsetLimit(&"a"[0..], 0, 0)));
    testing.expect(zog.mem.sliceEqual(""[0..], sliceableOffsetLimit(&"a"[0..], 1, 1)));
    testing.expect(zog.mem.sliceEqual("a"[0..], sliceableOffsetLimit(&"a"[0..], 0, 1)));
    testing.expect(zog.mem.sliceEqual("34"[0..], sliceableOffsetLimit(&"123456"[0..], 2, 4)));

    //testing.expect(std.meta.eql(&sliceRange("bc"[0..]), sliceableOffsetLimit(&sliceRange("abcd"[0..]), 1, 3)));
    _ = sliceableOffsetLimit(&sliceRange("abcd"[0..]), 1, 3);

    // TODO: CounterRange not supported yet, need to allow sliceableOffsetLimit to fallback
    //       to calling popMany and something else
    //testing.expect(!indexInRange(&CounterRange(u8).init(0, 0), 0));
    //testing.expect( indexInRange(&CounterRange(u8).init(0, 1), 0));
    //_ = sliceableOffsetLimit(&CounterRange(u8).init(0, 100), 10, 20);
}

// Just a convenience function
pub fn sliceableOffsetOnly(rref: var, offset: usize) @typeOf(rref.*) {
    var rangeCopy = clone(rref);
    popMany(&rangeCopy, offset);
    return rangeCopy;
}
pub fn sliceableLimitLength(rref: var, limitLength: usize) @typeOf(rref.*) {
    const T = @typeOf(rref.*);
    if (@hasDecl(T, "sliceableLimitLength")) {
        return rref.sliceableLimitLength(limitLength);
    } else return sliceableOffsetLimit(rref, 0, limitLength);
}

pub fn asSlice(rref: var) []RangeElement(@typeOf(rref.*)) {
    const T = @typeOf(rref.*);
    if (@hasDecl(T, "asSlice")) {
        return rref.asSlice();
    } else @compileError("don't know how to make " ++ @typeName(T) ++ " into a slice");
}


pub fn AsArrayPointerResult(comptime T: type) type {
    if (@hasDecl(T, "asArrayPointer")) {
        return @typeInfo(@typeOf(T.asArrayPointer)).Fn.return_type orelse {
            @compileError("asArrayPointer must return a type");
        };
    } else @compileError("don't know how to make " ++ @typeName(T) ++ " into an array pointer");
}
// Return a pointer to an array of elements for the range
pub fn asArrayPointer(rref: var) AsArrayPointerResult(@typeOf(rref.*)) {
    const T = @typeOf(rref.*);
    if (@hasDecl(T, "asArrayPointer")) {
        return rref.asArrayPointer();
    } else @compileError("don't know how to make " ++ @typeName(T) ++ " into an array pointer");
}

/// Return the slice type for a Sliceable
pub fn SliceableSlice(comptime Sliceable: type) type {
    if (@typeInfo(@typeOf(Sliceable.sliceOffsetLimit)).Fn.return_type) |t| {
        return t;
    } else @compileError(".sliceOffsetLimit must return a type");
}


pub fn indexInRange(rref: var, index: usize) bool {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to implement indexInRange for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Struct, .Union => {
            if (@hasDecl(T, "indexInRange")) {
                return rref.indexInRange(index);
            } else {
                return index < length(rref);
            }
        },
        else => return index < length(rref),
    }
}

test "indexInRange" {
    testing.expect(!indexInRange(&""[0..], 0));
    testing.expect( indexInRange(&"a"[0..], 0));
    testing.expect(!indexInRange(&sliceRange(""[0..]), 0));
    testing.expect( indexInRange(&sliceRange("b"[0..]), 0));
    testing.expect(!indexInRange(&CounterRange(u8).init(0, 0), 0));
    testing.expect( indexInRange(&CounterRange(u8).init(0, 1), 0));
}

/// Indexable
//
/// Can assert if index is out-of-range, but does not return an error.
/// If the caller wants to check whether the index is out of range then they
/// can call another function to check this.
pub fn elementAt(rref: var, index: usize) RangeElement(@typeOf(rref.*)) {
    const T = @typeOf(rref.*);
    const errorMsg = "don't know how to implement 'elementAt' for type " ++ @typeName(T);
    switch (@typeInfo(T)) {
        .Pointer => |info| {
            switch (info.size) {
                .Slice => { return rref.*[index]; },
                else => @compileError(errorMsg),
            }
        },
        .Struct, .Union => {
            if (@hasDecl(T, "elementAt")) {
                return rref.elementAt(index);
            } else if (@hasDecl(T, "elementAtRef")) {
                return rref.elementAtRef(index).*;
            } else @compileError(errorMsg);
        },
        else => @compileError(errorMsg),
    }
}

test "elementAt" {
    testing.expect('a' == elementAt(&"a"[0..], 0));
    testing.expect('2' == elementAt(&"abc1234"[0..], 4));
    testing.expect('b' == elementAt(&sliceRange("b"[0..]), 0));
    testing.expect('j' == elementAt(&sliceRange("fdkazjlad"[0..]), 5));
    testing.expect(8 == elementAt(&CounterRange(u8).init(0, 9), 8));
}

// Takes a slice as the 2nd parameter because we're definitely going to need the length
pub fn startsWith(rref: var, slice: []const RangeElement(@typeOf(rref.*))) bool {
    return indexInRange(rref, slice.len) and
        zog.mem.ptrEqual(asArrayPointer(rref), slice.ptr, slice.len);
}

test "startsWith" {
    {
        var r = sliceRange("abcd"[0..]);
        testing.expect(startsWith(&r, "a"[0..]));
    }
}

pub fn popIfMatch(rref: var, slice: var) bool {
    if (startsWith(rref, slice)) {
        popMany(rref, slice.len);
        return true;
    }
    return false;
}
