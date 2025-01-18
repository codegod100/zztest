const std = @import("std");
const xrpc = @import("./xrpc.zig");

const Identity = struct { did: []const u8, pds: []const u8 };
const Resolve = struct { identity: Identity = undefined, meta: []const u8 = undefined };
const Did = struct { did: []const u8 = undefined };
const DidEndPoint = struct { service: []struct { serviceEndpoint: []const u8 } };
pub fn OAuth() type {
    //identity is did & pds
    // meta is in metadata
    // https://plc.directory
    // PDS:/.well-known/oauth-protected-resource
    // ISSUER:/.well-known/oauth-authorization-server

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

fn getMeta(pds_url: []const u8, alloc: std.mem.Allocator) !void {
    const resource = ".well-known/oauth-protected-resource";
    // const url = pds_url + "/.well-known/oauth-protected-resource";
    const url = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ pds_url, resource });
    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();
    var list = std.ArrayList(u8).init(alloc);
    const status = try client.fetch(.{ .location = .{ .url = url }, .response_storage = .{ .dynamic = &list } });
    const response = try list.toOwnedSlice();
    std.debug.print("{} - {s}\n\n", .{ status, response });
}

pub fn resolve(handle: []const u8, alloc: std.mem.Allocator) !Resolve {
    //home/v/sand/atproto/packages/internal/identity-resolver/src/identity-resolver.ts - resolve
    //resolve identity
    // const subdomain = "_atproto";

    // get did and pds url
    const did_json = try xrpc.MakeRequest("com.atproto.identity.resolveHandle").call(.{ .handle = handle }, alloc);
    std.debug.print("{s}\n\n", .{did_json});
    // defer alloc.free(did_json);
    var fbs = std.io.fixedBufferStream(did_json);
    var reader = std.json.reader(alloc, fbs.reader());
    defer reader.deinit();
    const did = try std.json.parseFromSlice(Did, alloc, did_json, .{});
    defer did.deinit();
    const did_str = did.value.did;
    const endpoint = try getPds(did_str, alloc);
    const meta = try getMeta(endpoint.service[0].serviceEndpoint, alloc);
    _ = meta;
    std.debug.print("{s}\n\n", .{did_str});
    const identity = Identity{ .did = did_str, .pds = "" };
    return Resolve{ .identity = identity, .meta = "" };
}

fn getPds(did: []const u8, alloc: std.mem.Allocator) !DidEndPoint {
    const base = "https://plc.directory";
    // const url = base + did;
    const url = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ base, did });
    std.debug.print("url: {s}\n\n", .{url});
    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();
    var list = std.ArrayList(u8).init(alloc);
    const status = try client.fetch(.{ .location = .{ .url = url }, .response_storage = .{ .dynamic = &list } });
    defer list.deinit();
    std.debug.print("status: {}\n\n", .{status.status});
    const pds_json = try list.toOwnedSlice();
    std.debug.print("pds_json: {s}\n\n", .{pds_json});
    const pds = try std.json.parseFromSlice(DidEndPoint, alloc, pds_json, .{ .ignore_unknown_fields = true });
    return pds.value;
}
