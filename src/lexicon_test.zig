const std = @import("std");
const lexicon = @import("./lexicon.zig");

test "smoketest" {
    const query = lexicon.Query("app.bsky.actor.getProfile").init(std.testing.allocator).run();
    _ = try query;
}
