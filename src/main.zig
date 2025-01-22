const httpz = @import("httpz");
const serve = @import("./server.zig");
const std = @import("std");
const builtin = @import("builtin");
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;
    std.debug.print("Serving....", .{});
    _ = try serve.startServer(alloc);
}
