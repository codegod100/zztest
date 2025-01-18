const std = @import("std");
const xrpc = @import("./xrpc.zig");
test "resolve handle" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const alloc = arena.allocator();
    defer arena.deinit();
    const handle = "nandi.dads.lol";
    const profile = try xrpc.MakeRequest("com.atproto.identity.resolveHandle").call(.{ .handle = handle }, alloc);
    std.debug.print("{s}\n\n", .{profile});
}
