const std = @import("std");
pub const Self = @This();
const NSID = enum {
    getProfile,
};
fn enumTable(alloc: std.mem.Allocator) !std.StringHashMap(NSID) {
    var map = std.StringHashMap(NSID).init(
        alloc,
    );
    // defer map.deinit();
    try map.put("app.bsky.actor.getProfile", NSID.getProfile);
    return map;
}
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

const Entry = struct { key: []const u8, val: []const u8 };
pub fn Query(comptime nsid: []const u8) type {
    return struct {
        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) Query(nsid) {
            return .{ .alloc = alloc };
        }
        pub fn run(self: Query(nsid)) !std.json.ObjectMap {
            var map = try enumTable(self.alloc);
            defer map.deinit();
            // const nsid = NSID.toString(nsid);
            const nsid_enum = map.get(nsid);
            var profile: std.json.Parsed(std.json.Value) = undefined;
            std.debug.print("enum val: {any} - {s}\n\n", .{ nsid_enum, nsid });
            if (nsid_enum) |e| {
                switch (e) {
                    NSID.getProfile => {
                        profile = try parseJson("./src/getProfile.json", self.alloc);
                    },
                }
            }
            var buffer = std.ArrayList(u8).init(self.alloc);
            try std.json.stringify(profile.value, .{}, buffer.writer());
            // try profile.value.jsonStringify(buffer.writer());
            std.debug.print("profile string: {s}\n\n", .{buffer.items});
            const ref = profile.value.object.get("defs").?.object.get("main").?.object.get("output").?.object.get("schema").?.object.get("ref").?.string;
            std.debug.print("ref: {s}\n\n", .{ref});
            const parts = try splitAtHash(ref);

            comptime {
                var comp_buffer: [10000]u8 = undefined;
                var fba = std.heap.FixedBufferAllocator.init(&comp_buffer);
                const fba_alloc = fba.allocator();

                const defs = try parseJson("./src/defs.json", fba_alloc);
                defer defs.deinit();
                const view = defs.value.object.get("defs").?.object.get(parts.suffix).?;
                var view_buffer = std.ArrayList(u8).init(fba_alloc);
                try std.json.stringify(view, .{}, view_buffer.writer());
                std.debug.print("view string: {s}\n\n", .{view_buffer.items});
                // const view_string = try parseValue
                defer profile.deinit();
                defer buffer.deinit();
                defer view_buffer.deinit();
                const properties = view.object.get("properties").?.object;
                var iterator = properties.iterator();

                var entryList = std.ArrayList(Entry).init(fba_alloc);

                while (iterator.next()) |entry| {
                    const key = entry.key_ptr.*;
                    std.debug.print("key: {s}\n", .{key});
                    const v = entry.value_ptr.*;
                    const val = v.object.get("type").?.string;
                    std.debug.print("value: {s}\n", .{val});
                    if (std.mem.eql(u8, val, "string")) {
                        try entryList.append(Entry{ .key = key, .val = val });
                    }
                }
                const entries = entryList.items;
                const property_struct = createStruct(entries.len, entries);

                std.debug.print("properties: {any}\n", .{property_struct});
                return properties;
            }
        }
    };
}

allocator: std.mem.Allocator,
ref: []const u8,
pub fn init(alloc: std.mem.Allocator) !Self {
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

fn parseValue(value: std.json.ObjectMap, alloc: std.mem.Allocator) ![]const u8 {
    var buffer = std.ArrayList(u8).init(alloc);
    defer buffer.deinit();
    try std.json.stringify(value, .{}, buffer.writer());
    return buffer.items;
}
fn parseJson(path: []const u8, a: std.mem.Allocator) !std.json.Parsed(std.json.Value) {
    const content = try std.fs.cwd().readFileAlloc(a, path, 1024 * 1024);
    defer a.free(content);
    // std.debug.print("content: {s}\n\n", .{content});
    var fbs = std.io.fixedBufferStream(content);
    var reader = std.json.reader(a, fbs.reader());
    defer reader.deinit();
    const json_struct = try std.json.parseFromTokenSource(std.json.Value, a, &reader, .{});
    // defer json_struct
    return json_struct;
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

fn createStruct(field_num: usize, entries: []Entry) type {
    var struct_fields: [field_num]std.builtin.Type.StructField = undefined;
    for (&struct_fields, entries) |*struct_field, entry| {
        struct_field.* = .{ .name = entry.key, .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = null };
    }

    return @Type(.{ .@"struct" = .{
        .layout = .auto,
        .fields = &struct_fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}
