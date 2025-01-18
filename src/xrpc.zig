const std = @import("std");
fn createStruct(nsid: []const u8) type {
    var host: []const u8 = undefined;
    comptime host = "https://public.api.bsky.app";
    var nsid_found: bool = false;
    if (std.mem.eql(u8, nsid, "app.bsky.actor.getProfile")) {
        var struct_fields: [4]std.builtin.Type.StructField = undefined;
        var fields: [1][]const u8 = undefined;
        comptime fields = .{"actor"};

        struct_fields[0] = std.builtin.Type.StructField{ .name = "fields", .type = [1][]const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&fields)) };
        // struct_fields: [6]std.builtin.Type.StructField = undefined;
        struct_fields[1] = std.builtin.Type.StructField{ .name = "host", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&host)) };
        struct_fields[2] = std.builtin.Type.StructField{ .name = "nsid", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&nsid)) };
        struct_fields[3] = std.builtin.Type.StructField{ .name = "actor", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = null };

        nsid_found = true;
        return @Type(.{ .@"struct" = .{
            .layout = .auto,
            .fields = &struct_fields,
            .decls = &.{},
            .is_tuple = false,
        } });
    }
    if (std.mem.eql(u8, nsid, "app.bsky.feed.getLikes")) {
        var struct_fields: [4]std.builtin.Type.StructField = undefined;
        var fields: [1][]const u8 = undefined;
        comptime fields = .{"uri"};

        struct_fields[0] = std.builtin.Type.StructField{ .name = "host", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&host)) };
        struct_fields[1] = std.builtin.Type.StructField{ .name = "nsid", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&nsid)) };
        struct_fields[2] = std.builtin.Type.StructField{ .name = "fields", .type = [1][]const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&fields)) };
        struct_fields[3] = std.builtin.Type.StructField{ .name = "uri", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = null };
        nsid_found = true;
        return @Type(.{ .@"struct" = .{
            .layout = .auto,
            .fields = &struct_fields,
            .decls = &.{},
            .is_tuple = false,
        } });
    }
    if (std.mem.eql(u8, nsid, "com.atproto.repo.getRecord")) {
        var struct_fields: [6]std.builtin.Type.StructField = undefined;
        var fields: [3][]const u8 = undefined;
        comptime fields = .{ "repo", "collection", "rkey" };

        struct_fields[0] = std.builtin.Type.StructField{ .name = "repo", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = null };
        struct_fields[1] = std.builtin.Type.StructField{ .name = "collection", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = null };
        struct_fields[2] = std.builtin.Type.StructField{ .name = "rkey", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = null };
        struct_fields[3] = std.builtin.Type.StructField{ .name = "host", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&host)) };
        struct_fields[4] = std.builtin.Type.StructField{ .name = "nsid", .type = []const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&nsid)) };
        struct_fields[5] = std.builtin.Type.StructField{ .name = "fields", .type = [3][]const u8, .is_comptime = false, .alignment = 0, .default_value = @as(?*const anyopaque, @ptrCast(&fields)) };
        nsid_found = true;
        return @Type(.{ .@"struct" = .{
            .layout = .auto,
            .fields = &struct_fields,
            .decls = &.{},
            .is_tuple = false,
        } });
    }
    if (!nsid_found) @panic("Invalid NSID");
}

pub fn MakeRequest(nsid: []const u8) type {
    // https://docs.bsky.app/docs/category/http-reference
    const client = createStruct(nsid);
    return struct {
        client: type = client,

        pub fn call(c: client, alloc: std.mem.Allocator) ![]const u8 {
            // _ = alloc;
            // std.debug.print("calling {}\n", .{c});
            // const x = xrpc.init(c.host, alloc);

            var buffer = std.ArrayList(u8).init(alloc);
            // std.debug.print("{}\n", .{moo});
            // try buffer.appendSlice("?");
            inline for (@typeInfo(@TypeOf(c)).@"struct".fields) |field| {
                // std.debug.print("{s}\n", .{field.value});
                const val = @field(c, field.name);
                std.debug.print("{s}: {s}\n", .{ field.name, val });
                // std.debug.print("{s}: {s}\n\n", .{ field.name, val });
                // const val = comptime @field(c, field);
                // comptime val = @field(c, field);
                for (c.fields, 0..) |c_field, i| {
                    if (std.mem.eql(u8, c_field, field.name)) {
                        const str = try std.fmt.allocPrint(alloc, "{s}={s}", .{ field.name, val });
                        try buffer.appendSlice(str);
                        if (i < c.fields.len) {
                            try buffer.appendSlice("&");
                        }
                    }
                }
            }
            std.debug.print("buffer items: {s}\n", .{buffer.items});

            var buffer2 = std.ArrayList(u8).init(alloc);
            const writer = buffer2.writer();
            try std.Uri.Component.percentEncode(writer, nsid, isAllowed);
            const url = std.fmt.allocPrint(alloc, "{s}/xrpc/{s}?{s}", .{ c.host, buffer2.items, buffer.items }) catch return error.FormattingError;
            return getData(url, alloc);
        }
    };
}

pub fn getData(url: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var client = std.http.Client{ .allocator = alloc };
    const uri = try std.Uri.parse(url);
    var server_header_buffer: [10240]u8 = undefined;
    var req = try client.open(.GET, uri, .{ .server_header_buffer = &server_header_buffer });
    try req.send();
    try req.wait();
    const json_string = try req.reader().readAllAlloc(alloc, 81920);
    var fbs = std.io.fixedBufferStream(json_string);
    var reader = std.json.reader(alloc, fbs.reader());
    const json_struct = try std.json.parseFromTokenSource(std.json.Value, alloc, &reader, .{});

    const err = json_struct.value.object.get("error");
    const message = json_struct.value.object.get("message");
    if (err != null) {
        const msg = message.?.string;
        std.debug.print("Error: {s}\n\n", .{msg});
        if (std.mem.eql(u8, msg, "Profile not found")) {
            return error.ProfileNotFound;
        }
        return error.XRPCResponseError;
    }

    // std.debug.Trace.dump(json_struct);
    // return "hello";
    return json_string;
}

fn isAllowed(c: u8) bool {
    // Example logic: allow only ASCII alphanumeric characters
    return (c >= 'a' and c <= 'z') or
        (c >= 'A' and c <= 'Z') or
        (c >= '0' and c <= '9');
}
