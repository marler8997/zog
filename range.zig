// NOTES:
// I think elementAt and peekTo are duplicating the same functionality.  Not sure which
// one is better. The only difference was that peekTo returned an optional value.  Instead,
// I think just having elementAt is good, it should assert on indexOfOfRange.  If a program
// wants to check an index, they can can call indexInRange beforehand.
//

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
// A sentinel pointer range (length is unknown)
// A limit array range (length is known)
// A file reader range
//    - could return single characters, strings, or lines
//


//
// This function returns the element type of a range
//
pub fn RangeElement(comptime T: type) type {
    //comptime var t : T = undefined;
    //return @typeInfo(@typeOf(next(&t))).child;

    return @typeInfo(NextResult(T)).Optional.child;

    //switch (@typeInfo(T)) {
    //    .Array => |info| return info.child,
    //    .Pointer => |info| return info.child,
    //    //.Struct => |info| {
    //    //    if (zog.limitslice.isLimitSlice(T)) {
    //    //        return T.ManyPointer();
    //    //    }
    //    //},
    //    else => {},
    //}
    //@compileError("Expected pointer/array type, " ++ "found '" ++ @typeName(T) ++ "'");
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
        fn elementAt(self: *@This(), index: usize) T
        {
            const result = self.next + index;
            std.debug.assert(result < self.limit);
            return @intCast(T, result);
        }
    };
}

test "CounterRange" {
    testRange([_]u8 {83}, CounterRange(u8).init(83, 84));
    testRange([_]u8 {10, 11, 12}, CounterRange(u8).init(10, 13));

    {
        const u8Buffer : [0]u8 = undefined;
        testRange(u8Buffer[0..], CounterRange(u8).init(32, 32));
    }
}

// TODO: create a file line range
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

pub const sliceRange = zog.limitslice.limitSlice;

test "sliceRange" {
    testRange(""[0..], sliceRange(""[0..]));
    testRange("a"[0..], sliceRange("a"[0..]));
    testRange("abcd"[0..], sliceRange("abcd"[0..]));
}


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
    if (@hasDecl(@typeOf(rref.*), "empty")) {
        return rref.empty();
    } else @compileError("zog.range.empty not implemented for " ++ @typeName(@typeOf(rref.*)));
}

pub fn pop(rref: var) void {
    if (@hasDecl(@typeOf(rref.*), "pop")) {
        rref.pop();
    } else if (@hasDecl(@typeOf(rref.*), "popMany")) {
        rref.popMany(1);
    } else @compileError("don't know how to pop type: " ++ @typeName(@typeOf(rref)));
}

pub fn popMany(rref: var, count: usize) void {
    if (@hasDecl(@typeOf(rref.*), "popMany")) {
        rref.popMany(count);
    } else @compileError("don't know how to popMany on type: " ++ @typeName(@typeOf(rref)));
}


pub fn PeekResult(comptime T : type) type {
    if (@hasDecl(T, "peek")) {
        return @typeOf(T.peek).Function.return_type;
    } else if (@hasDecl(T, "elementAt")) {
        if (@typeInfo(@typeOf(T.elementAt)).Fn.return_type) |t| {
            return t;
        } else @compileError("elementAt must return a type");
    } else if (@hasDecl(T, "elementAtRef")) {
        if (@typeInfo(@typeOf(T.elementAtRef)).Fn.return_type) |t| {
            return @typeInfo(t).Pointer.child;
        } else @compileError("elementAtRef must return a type");
    } else {
        //dumpType(T);
        @compileError("PeekResult not implemented here");
    }
}
pub fn peek(rref: var) PeekResult(@typeOf(rref.*)) {
    if (@hasDecl(@typeOf(rref.*), "peek")) {
        return rref.peek();
    } else if (@hasDecl(@typeOf(rref.*), "elementAt")) {
        return rref.elementAt(0);
    } else if (@hasDecl(@typeOf(rref.*), "elementAtRef")) {
        return rref.elementAtRef(0).*;
    } else @compileError("peek does not seem to support this type");
}
pub fn optionalPeek(rref: var) ?PeekResult(@typeOf(rref.*)) {
    return if (empty(rref)) null else peek(rref);
}


pub fn Peekable(comptime T: type) type {
    const Range = @typeOf(T).Pointer.child;
    if (@hasDecl(Range, "peek") || @hasDecl(Range, "elementAt")) {
        return T;
    } else { // assume there is a 'next' method
        const NextReturnType = @typeInfo(T.next).Function.return_type;
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

pub fn NextResult(comptime T : type) type {
    if (@hasDecl(T, "next")) {
        if (@typeInfo(@typeOf(T.next)).Fn.return_type) |t| {
            return t;
        } else @compileError("next must return a type");
    } else {
        return ?PeekResult(T);
    }
}
pub fn next(rref: var) NextResult(@typeOf(rref.*)) {
    if (@hasDecl(@typeOf(rref.*), "next")) {
        return rref.next();
    // TODO: support optionalPeek?
    } else {
        if (empty(rref)) return null;
        var value = peek(rref);
        pop(rref);
        return value;
    }
}

pub fn length(rref: var) usize {
    if (@hasField(@typeOf(rref.*), "len")) {
        return rref.len;
    } else if (@hasDecl(@typeOf(rref.*), "length")) {
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



/// pop elements out of range until the given element is found
/// returns true if found, false otherwise
pub fn popFind(rref: var, element: var) bool {
    while (next(rref)) |e| {
        if (std.meta.eql(e, element))
            return true;
    }
    return false;
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
    while (i < length(rref)) : (i += 1) {
        if (contains(any, elementAt(rref, i)))
            return i;
    }
    return null;
}

// TODO: sliceableOffsetLength?

pub fn sliceableOffsetLimit(rref: var, offset: usize, limit: usize) @typeOf(rref.*) {
    // TODO: probably support more
    return rref.sliceableOffsetLimit(offset, limit);
}
pub fn sliceableOffsetOnly(rref: var, offset: usize) @typeOf(rref.*) {
    // TODO: probably support more
    return rref.sliceableOffsetOnly(offset);
}
pub fn sliceableLimitLength(rref: var, limitLength: usize) @typeOf(rref.*) {
    if (@hasDecl(@typeOf(rref.*), "sliceableLimitLength")) {
        return rref.sliceableLimitLength(limitLength);
    } else return sliceableOffsetLimit(rref, 0, limitLength);
}

pub fn asSlice(rref: var) []RangeElement(@typeOf(rref.*)) {
    if (@hasDecl(@typeOf(rref.*), "asSlice")) {
        return rref.asSlice();
    } else @compileError("don't know how to make " ++ @typeName(@typeOf(rref.*)) ++ " into a slice");
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
    if (@hasDecl(@typeOf(rref.*), "asArrayPointer")) {
        return rref.asArrayPointer();
    } else @compileError("don't know how to make " ++ @typeName(@typeOf(rref.*)) ++ " into an array pointer");
}

/// Return the slice type for a Sliceable
pub fn SliceableSlice(comptime Sliceable: type) type {
    if (@typeInfo(@typeOf(Sliceable.sliceOffsetLimit)).Fn.return_type) |t| {
        return t;
    } else @compileError(".sliceOffsetLimit must return a type");
}


pub fn indexInRange(rref: var, index: usize) bool {
    if (@hasDecl(@typeOf(rref.*), "indexInRange")) {
        return rref.indexInRange(index);
    } else {
        return index < length(rref);
    }
}

/// Indexable
pub fn ElementAt(comptime Indexable: type) type {
    if (@typeInfo(@typeOf(Indexable.elementAt)).Fn.return_type) |t| {
        return t;
    } else @compileError(".elementAt must return a type");
}
/// Can assert if index is out-of-range, but does not return an error.
/// If the caller wants to check whether the index is out of range then
/// can call another function to check this.
pub fn elementAt(rref: var, index: usize) ElementAt(@typeOf(rref.*)) {
    return rref.elementAt(index);
}

pub fn contains(rref: var, value: var) bool {
    @compileError("contains not implemented");
    //while (zog.range.next(&r)) |element| { ... }
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
