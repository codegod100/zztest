const std = @import("std");
const httpz = @import("httpz");
const oauth = @import("./oauth.zig");
pub fn startServer(alloc: std.mem.Allocator) !void {
    var server = try httpz.Server(void).init(alloc, .{ .port = 8080 }, {});
    defer {
        // clean shutdown, finishes serving any live request
        server.stop();
        server.deinit();
    }
    var router = server.router(.{});
    router.get("/callback", callback, .{});
    try server.listen();
}

fn callback(req: *httpz.Request, res: *httpz.Response) !void {
    const query = try req.query();
    const code = query.get("code").?;
    try oauth.callback(code, res.arena);
    try res.json(.{ .ok = code }, .{});
}

test "smokescreen" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    const alloc = arena.allocator();
    defer arena.deinit();

    _ = try startServer(alloc);
}
