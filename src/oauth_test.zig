const std = @import("std");
const oauth = @import("./oauth.zig");
test "oauth" {
    const url = oauth.OAuth().authorize("nandi.dads.lol");
    std.debug.print("{s}\n\n", .{url});
}
