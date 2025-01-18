const std = @import("std");
pub const Self = @This();
const NSID = enum {
    getProfile,
    pub fn toString(self: NSID) []const u8 {
        return switch (self) {
            .getProfile => "app.bsky.actor.getProfile",
        };
    }
};
pub fn splitAtHash(ref: []const u8) !struct {
    prefix: []const u8,
    suffix: []const u8,
} {
    var parts = std.mem.splitAny(u8, ref, "#");
    const prefix = parts.next() orelse return error.MissingPrefix;
    const suffix = parts.next() orelse return error.MissingSuffix;

    if (parts.next() != null) return error.TooManyParts;

    return .{ .prefix = prefix, .suffix = suffix };
}
pub fn Query(comptime nsid: []const u8) type {
    return struct {
        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) Query(nsid) {
            return .{ .alloc = alloc };
        }
        pub fn run(self: Query(nsid)) !std.json.ObjectMap {
            const nsid_enum = std.meta.stringToEnum(NSID, nsid);
            var profile: std.json.Value = undefined;
            if (nsid_enum) |e| {
                switch (e) {
                    NSID.getProfile => {
                        profile = try parseJson("./src/getProfile.json", self.alloc);
                    },
                }
            }
            const ref = profile.object.get("defs").?.object.get("main").?.object.get("output").?.object.get("schema").?.object.get("ref").?.string;
            const parts = try splitAtHash(ref);
            const defs = try parseJson("./src/defs.json", self.alloc);
            const view = defs.object.get("defs").?.object.get(parts.suffix).?;
            return view.object.get("properties").?.object;
        }
    };
}

allocator: std.mem.Allocator,
ref: []const u8,
pub fn init(alloc: std.mem.Allocator) anyerror!Self {
    const profile = try parseJson("./src/getProfile.json", alloc);
    const ref = profile.object.get("defs").?.object.get("main").?.object.get("output").?.object.get("schema").?.object.get("ref").?.string;
    return Self{ .allocator = alloc, .ref = ref };
}

// pub fn splitAtHash(str: []const u8) struct { prefix: []const u8, suffix: []const u8 } {
//     if (std.mem.indexOf(u8, str, "#")) |hash_index| {
//         return .{
//             .prefix = str[0..hash_index],
//             .suffix = str[hash_index + 1 ..],
//         };
//     }
//     // Return the whole string as prefix if no hash found
//     return .{
//         .prefix = str,
//         .suffix = "",
//     };
// }

fn parseJson(path: []const u8, a: std.mem.Allocator) anyerror!std.json.Value {
    const content = try std.fs.cwd().readFileAlloc(a, path, 1024 * 1024);

    var fbs = std.io.fixedBufferStream(content);
    var reader = std.json.reader(a, fbs.reader());
    const json_struct = try std.json.parseFromTokenSource(std.json.Value, a, &reader, .{});
    return json_struct.value;
}
pub fn parse(self: Self) !void {
    const profile = try parseJson("./src/getProfile.json", self.allocator);
    const defs = try parseJson("./src/defs.json", self.allocator);
    const id = profile.object.get("id").?.string;
    std.debug.print("ID: {?s}\n\n", .{id});

    const ref = profile.object.get("defs").?.object.get("main").?.object.get("output").?.object.get("schema").?.object.get("ref").?.string;
    std.debug.print("REF: {?s}\n\n", .{ref});

    const parts = splitAtHash(ref);
    const view = defs.object.get("defs").?.object.get(parts.suffix).?;
    var view_buffer = std.ArrayList(u8).init(self.allocator);
    try std.json.stringify(view, .{}, view_buffer.writer());
    std.debug.print("View: {s}\n\n", .{view_buffer.items});

    const properties = view.object.get("properties").?.object;
    const profileIter = properties.iterator();
    _ = profileIter;
    // while (profileIter.next()) |*field| {
    //     // const val = field.value_ptr.*;
    //     // var buffer = std.ArrayList(u8).init(self.allocator);
    //     // try val.jsonStringify(buffer.writer());
    //     // try std.json.stringify(val, .{}, buffer.writer());
    //     const key = field.key_ptr.*;

    //     }
    //     std.debug.print("{s}: {s}\n", .{ , buffer.items });
    // }
}
