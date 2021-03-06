const builtin = @import("builtin");

const zog = @import("./zog.zig");
usingnamespace zog.limitslice;
usingnamespace zog.sentinel;

pub fn Strtok(comptime Sliceable: type, comptime DelimRange: type) type {
    return struct {
        s: Sliceable,
        delims: DelimRange,

        pub fn init(s: Sliceable, delims: DelimRange) @This() {
            return @This() {
                .s = s,
                .delims = delims,
            };
        }

        pub fn rangeEmpty(self: *@This()) bool { return zog.range.empty(&self.s); }

        //pub fn rangeNext(self: *@This()) ?zog.range.SliceableSlice(Sliceable) {
        pub fn rangeNext(self: *@This()) ?Sliceable {
            //@compileLog("Strtok ", @typeName(Sliceable), " rangeNext returns ", @typeName(?zog.range.SliceableSlice(Sliceable)));
            if (self.rangeEmpty())
                return null;
            const optionalDelimIndex = zog.range.indexOfAny(&self.s, &self.delims);
            if (optionalDelimIndex) |delimIndex| {
                var result = zog.range.sliceableOffsetLimit(&self.s, 0, delimIndex);
                self.s = zog.range.sliceableOffsetOnly(&self.s, delimIndex + 1);
                return result;
            } else {
                var result = self.s;
                self.s = zog.range.sliceableOffsetOnly(&self.s, zog.range.length(&self.s));
                return result;
            }
        }
    };
}



pub fn StrtokResult(comptime S: type, comptime DelimRange: type) type {
    return Strtok(S, DelimRange);
    //switch (@typeInfo(S)) {
    //    .Pointer => |info| {
    //        switch (info.Size) {
    //            .One => @compileError("not impl"),
    //            .Many => @compileError("not impl"),
    //            .Slice => @compileError("not impl"),
    //            .C => @compileError("not impl"),
    //        }
    //    },
    //    else => @compileError("Expected slice/pointer but got '" ++ @typeName(S) ++ "'"),
    //}
}
pub fn strtok(s: anytype, delims: anytype) StrtokResult(@TypeOf(s), @TypeOf(delims)) {
    return Strtok(@TypeOf(s), @TypeOf(delims)).init(s, delims);
    //switch (@typeInfo(@TypeOf(s))) {
    //    .Pointer => |info| {
    //        switch (info.Size) {
    //            .One => @compileError("not impl"),
    //            .Many => @compileError("not impl"),
    //            .Slice => @compileError("not impl"),
    //            .C => @compileError("not impl"),
    //            //return Strtok(@TypeOf(s), null, @TypeOf(delims)) {
    //            //    .s = s,
    //            //    .delims = delims,
    //            //};
    //        }
    //    },
    //    else => @compileError("Expected slice/pointer but got '" ++ @typeName(@TypeOf(s)) ++ "'"),
    //}
}

test "strtok" {
    zog.range.testRange(
        ([_][]const u8 {"a"[0..], "b"[0..], "c"[0..]})[0..],
        strtok("a b c"[0..], " "[0..]));
    //zog.range.testRange([_]LimitSlice([*]const u8){
    //    zog.range.sliceRange("a"[0..]),
    //    zog.range.sliceRange("b"[0..]),
    //    zog.range.sliceRange("c"[0..])
    //}, strtok(zog.range.sliceRange("a b c"[0..]), " "[0..]));
}
