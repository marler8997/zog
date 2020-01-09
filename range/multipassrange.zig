const std = @import("std");
const zog = @import("../zog.zig");

// TODO: this should be somewhere else
fn max(a: var, b: @TypeOf(a)) @TypeOf(a) {
    return if (a >= b) a else b;
}

/// A Range that iterates through an underlying range N times returning a different set
/// of elements each time.  It takes a function that determins which 'pass' each item belongs
/// to (i.e. 0 - (N-1)).  This function does not cache the result of this function, so it gets
/// called for every element on every pass.
///
/// This mechanism is differs from sort as it does not require extra memory but does require
/// iterating over the range multiple times.
pub fn MultiPassRange(comptime Range: type) type {
    return struct {
        const Element = zog.range.RangeElement(Range);
        const Func = fn(*const Element) u8;

        rangeRef: *Range,
        func: Func,
        currentRange: Range,
        currentOrder: u8,
        maxOrder: u8,
        
        pub fn init(rangeRef: *Range, func: Func) @This() {
            return @This() {
                .rangeRef = rangeRef,
                .func = func,
                .currentRange = zog.range.clone(rangeRef),
                .currentOrder = 0,
                .maxOrder = 0,
            };
        }

        pub fn rangeNext(self: *@This()) ?Element {
            while (true) {
                var optionalElement = zog.range.next(&self.currentRange);
                if (optionalElement) |element| {
                    const order = self.func(&element);
                    if (self.currentOrder == 0)
                        self.maxOrder = max(order, self.maxOrder);
                    if (order == self.currentOrder)
                        return element;
                } else {
                    if (self.currentOrder == self.maxOrder) {
                        return null;
                    }
                    self.currentOrder += 1;
                    self.currentRange = zog.range.clone(self.rangeRef);
                }
            }
        }
        
    };
}

pub fn multiPassRange(rref: var, func: var) MultiPassRange(@TypeOf(rref.*)) {
    const T = @TypeOf(rref.*);
    return MultiPassRange(T).init(rref, func);
}

fn asciiDigitToBinary(val: *const u8) u8 { return val.* - '0'; }

test "MultiPassRange" {
    zog.range.testRange("000111", multiPassRange(&"010101"[0..], asciiDigitToBinary));
    zog.range.testRange("000111", multiPassRange(&"110010"[0..], asciiDigitToBinary));
    zog.range.testRange("000111222", multiPassRange(&"121022010"[0..], asciiDigitToBinary));
}
