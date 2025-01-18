const std = @import("std");
const lexicon = @import("./lexicon.zig");

test "smoketest" {
    const query = try lexicon.Query("app.bsky.actor.getProfile").run();
    _ = query;
}
