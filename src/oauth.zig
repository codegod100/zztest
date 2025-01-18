const std = @import("std");
const xrpc = @import("./xrpc.zig");

const Identity = struct { did: []const u8, pds: []const u8 };
const Resolve = struct { identity: Identity, meta: []const u8 };
pub fn OAuth() type {
    //identity is did & pds
    // meta is in metadata
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
    _ = did_json;
    const identity = Identity{ .did = "did:yolo", .pds = "" };
    return Resolve{ .identity = identity, .meta = "" };
}
