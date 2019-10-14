const std = @import("std");
const StringHashMap = std.hash_map.StringHashMap;

/// Takes an allocator and manages a set of strings.
/// Every string in the pool is owned by the pool.
pub const StringPool = struct {
    allocator: *std.mem.Allocator,
    map: StringHashMap([]const u8),
    pub fn init(allocator: *std.mem.Allocator) @This() {
        return @This() {
            .allocator = allocator,
            .map = StringHashMap([]const u8).init(allocator),
        };
    }
    /// If the pool already contains this a string that matches the contents
    /// of the given string, return the existing string from this pool.
    /// Otherwise, create a copy of this string, add it to the pool and return
    /// the new copy.
    pub fn add(self: *@This(), s: []const u8) ![]const u8 {
        if (self.map.get(s)) |entry| {
            return entry.value;
        }
        var newString = try self.allocator.alloc(u8, s.len);
        std.mem.copy(u8, newString, s);
        _ = try self.map.put(newString, newString);
        return newString;
    }
};

test "stringpool"
{
    var pool = StringPool.init(std.heap.direct_allocator);
    const s = try pool.add("hello");
    {
        var buf : [5]u8 = "hello";
        const s2 = try pool.add(buf);
        std.testing.expect(s.ptr == s2.ptr);
    }
}