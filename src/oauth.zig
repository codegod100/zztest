const std = @import("std");
const xrpc = @import("./xrpc.zig");

const Identity = struct { did: []const u8, pds: []const u8 };
const Resolve = struct { identity: Identity, meta: Meta };
const Did = struct { did: []const u8 };
const DidEndPoint = struct { service: []struct { serviceEndpoint: []const u8 } };
const Authorization = struct { authorization_servers: [][]const u8 };
const Meta = struct { pushed_authorization_request_endpoint: []const u8 };
const ParParams = struct { client_id: []const u8, redirect_uri: []const u8, code_challenge: []const u8, code_challenge_method: []const u8 = "S256", state: []const u8, login_hint: []const u8, response_mode: []const u8, response_type: []const u8 = "code", scope: []const u8 };
const PKCE = struct { verifier: []const u8, challenge: []const u8 };
const url_safe = std.base64.url_safe;

//identity is did & pds
// meta is in metadata
// https://plc.directory
// PDS:/.well-known/oauth-protected-resource
// ISSUER:/.well-known/oauth-authorization-server
fn nonce(alloc: std.mem.Allocator) []const u8 {
    var buffer = std.ArrayList(u8).init(alloc);
    const random_bytes: [16]u8 = undefined;
    std.crypto.random.bytes(&random_bytes);
    try url_safe.Encoder.encodeWriter(&buffer, random_bytes);
    return buffer.items;
}
fn isValidChar(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '0'...'9', '-', '.', '_', '~' => true, // RFC 3986 unreserved characters
        else => false,
    };
}
fn pkce(alloc: std.mem.Allocator) type {
    var buffer = std.ArrayList(u8).init(alloc);
    const random_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&random_bytes);

    try url_safe.Encoder.encodeWriter(&buffer, random_bytes);
    const verifier = buffer.items;

    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(verifier, &hash, .{});
    var encoded = std.ArrayList(u8).init(alloc);
    try url_safe.Encoder.encodeWriter(encoded.writer(), &hash);
    const challenge = encoded.items;
    return PKCE{ .verifier = verifier, .challenge = challenge };
}
pub fn authorize(handle: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    //https://bsky.social/oauth/authorize?client_id=http%3A%2F%2Flocalhost%3Fredirect_uri%3Dhttp%253A%252F%252F127.0.0.1%253A4321%252Fcallback%26scope%3Datproto%2520transition%253Ageneric&request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Areq-9ab4f41233320fbceff60dc9c429dbb9
    const redirect_url = "http://127.0.0.1:8080/callback";
    const scope = "atproto transition:generic";
    // var redirect_buffer = std.ArrayList(u8).init(alloc);
    // try std.Uri.Component.percentEncode(redirect_buffer.writer(), redirect_url, isValidChar);
    // //http://localhost?redirect_uri=${enc(`${url}/callback`)}&scope=${enc("atproto transition:generic",)}`
    // var scopes_buffer = std.ArrayList(u8).init(alloc);
    // try std.Uri.Component.percentEncode(scopes_buffer.writer(), scope, isValidChar);
    const client_id = try std.fmt.allocPrint(alloc, "http://localhost?redirect_uri={s}&scope={s}", .{ redirect_url, scope });
    var client_id_buffer = std.ArrayList(u8).init(alloc);
    try std.Uri.Component.percentEncode(client_id_buffer.writer(), client_id, isValidChar);
    // const request_uri = redirect_url;
    const res = try resolve(handle, alloc);
    std.debug.print("{}", .{res.identity});
    var fbs = std.io.fixedBufferStream(res.meta);
    var reader = std.json.reader(alloc, fbs.reader());
    defer reader.deinit();
    const meta_val = try std.json.parseFromTokenSource(std.json.Value, alloc, &reader, .{});
    const request_uri = "urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3Areq-9ab4f41233320fbceff60dc9c429dbb9";
    const base_auth_url = meta_val.value.object.get("authorization_endpoint").?.string;
    const auth_url = try std.fmt.allocPrint(alloc, "{s}?client_id={s}&request_uri={s}", .{ base_auth_url, client_id_buffer.items, request_uri });
    return auth_url;
}

fn getAuth(pds_url: []const u8, alloc: std.mem.Allocator) !Meta {
    const resource = ".well-known/oauth-protected-resource";
    // const url = pds_url + "/.well-known/oauth-protected-resource";
    const url = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ pds_url, resource });
    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();
    var list = std.ArrayList(u8).init(alloc);
    const status = try client.fetch(.{ .location = .{ .url = url }, .response_storage = .{ .dynamic = &list } });
    const response = try list.toOwnedSlice();
    std.debug.print("{} - {s}\n\n", .{ status, response });
    const authorization = try std.json.parseFromSlice(Authorization, alloc, response, .{ .ignore_unknown_fields = true });
    const auth_server = authorization.value.authorization_servers[0];
    const meta = try getMeta(auth_server, alloc);
    return meta;
}

fn getMeta(auth_url: []const u8, alloc: std.mem.Allocator) !Meta {
    const resource = ".well-known/oauth-authorization-server";
    const url = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ auth_url, resource });
    var client = std.http.Client{ .allocator = alloc };
    defer client.deinit();
    var list = std.ArrayList(u8).init(alloc);
    const status = try client.fetch(.{ .location = .{ .url = url }, .response_storage = .{ .dynamic = &list } });
    const response = try list.toOwnedSlice();

    std.debug.print("{} - {s}\n\n", .{ status, response });

    const meta = try std.json.parseFromSlice(Meta, alloc, response, .{ .ignore_unknown_fields = true });

    return meta.value;
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
    const pds_url = endpoint.service[0].serviceEndpoint;
    const meta = try getAuth(pds_url, alloc);
    std.debug.print("{s}\n\n", .{did_str});
    const identity = Identity{ .did = did_str, .pds = pds_url };
    return Resolve{ .identity = identity, .meta = meta };
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
