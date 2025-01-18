const std = @import("std");
test "comptime alloc" {
    comptime {
        var comp_buffer: [10000]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&comp_buffer);
        const fba_alloc = fba.allocator();

        const content =
            \\{"hello": "world"}
        ;
        var fbs = std.io.fixedBufferStream(content);
        var reader = std.json.reader(fba_alloc, fbs.reader());
        defer reader.deinit();

        const foo = struct { hello: []const u8 };
        // const foo = std.json.Value;
        _ = try std.json.parseFromTokenSourceLeaky(foo, fba.allocator(), &reader, .{});
    }
}
