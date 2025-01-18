const std = @import("std");
const oauth = @import("./oauth.zig");
test "oauth" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    const url = try oauth.authorize("nandi.dads.lol", alloc);
    std.debug.print("{s}\n\n", .{url});
}
