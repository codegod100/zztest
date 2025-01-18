const std = @import("std");
const xrpc = @import("./xrpc.zig");

const Identity = struct { did: []const u8, pds: []const u8 };
const Resolve = struct { identity: Identity = undefined, meta: []const u8 = undefined };
const Did = struct { did: []const u8 = undefined };
pub fn OAuth() type {
    //identity is did & pds
    // meta is in metadata
    // https://plc.directory
    return struct {
        pub fn authorize(handle: []const u8, alloc: std.mem.Allocator) ![]const u8 {
            const redirect_url = "http://127.0.0.1:8080/callback";
            const res = try resolve(handle, alloc);
            std.debug.print("{}", .{res.identity});
            _ = redirect_url;
            return "https://fixme.com";
        }
    };
}

pub fn resolve(handle: []const u8, alloc: std.mem.Allocator) !Resolve {
    //home/v/sand/atproto/packages/internal/identity-resolver/src/identity-resolver.ts - resolve
    //resolve identity
    // const subdomain = "_atproto";

    // get did and pds url
    const did_json = try xrpc.MakeRequest("com.atproto.identity.resolveHandle").call(.{ .handle = handle }, alloc);
    std.debug.print("{s}\n\n", .{did_json});
    defer alloc.free(did_json);
    // var fbs = std.io.fixedBufferStream(did_json);
    // var reader = std.json.reader(alloc, fbs.reader());
    // defer reader.deinit();
    // const did = try std.json.parseFromSlice(Did, alloc, did_json, .{});
    // const identity = Identity{ .did = did.value.did, .pds = "" };
    // return Resolve{ .identity = identity, .meta = "" };
    return Resolve{};
}

fn getPds(did: []const u8, alloc: std.mem.Allocator) []const u8 {
    const base = "https://web.plc.directory/did/";
    const url = base + did;
    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();
    var list = std.ArrayList(u8).init(alloc);
    const status = try client.fetch(.{ .location = .{ .url = url }, .response_storage = .{ .dynamic = &list } });
    defer list.deinit();
    std.debug.print("status: {}\n\n", .{status.status});
    return list.items;
}
