const std = @import("std");
const oauth = @import("./oauth.zig");
test "oauth" {
    const url = try oauth.OAuth().authorize("nandi.dads.lol", std.testing.allocator);
    std.debug.print("{s}\n\n", .{url});
}
