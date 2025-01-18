const std = @import("std");
const xrpc = @import("./xrpc.zig");

const Identity = struct { did: []const u8, pds: []const u8 };
pub fn OAuth() type {
    //identity is did & pds
    // meta is in metadata
    return struct {
        fn authorize(handle: []const u8) []const u8 {
            const redirect_url = "http://127.0.0.1:8080/callback";
            const identity, const meta = resolve(handle);
            std.debug.print("{}", .{identity});
            _ = meta;
            _ = redirect_url;
        }
    };
}

fn resolve(handle: []const u8) type {
    //home/v/sand/atproto/packages/internal/identity-resolver/src/identity-resolver.ts - resolve
    //resolve identity
    // const subdomain = "_atproto";

    // get did and pds url
    const did_json = try xrpc.MakeRequest("com.atproto.identity.resolveHandle").call(.{ .handle = handle }, alloc);
    const identity = Identity{ .did = "did:yolo", .pds = "" };
    return struct { .identity = identity, .meta = "" };
}
