const std = @import("std");
const zog = @import("./zog.zig");

// TODO: this should be somewhere else
fn max(a: var, b: @typeOf(a)) @typeOf(a) {
    return if (a >= b) a else b;
}

pub fn Reorder(comptime Range: type) type {
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

pub fn reorder(rref: var, func: var) Reorder(@typeOf(rref.*)) {
    const T = @typeOf(rref.*);
    return Reorder(T).init(rref, func);
}

fn asciiDigitToBinary(val: *const u8) u8 { return val.* - '0'; }

test "reorder" {
    zog.range.testRange("000111", reorder(&"010101"[0..], asciiDigitToBinary));
    zog.range.testRange("000111", reorder(&"110010"[0..], asciiDigitToBinary));
    zog.range.testRange("000111222", reorder(&"121022010"[0..], asciiDigitToBinary));
}
