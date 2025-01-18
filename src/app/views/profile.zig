const std = @import("std");
const jetzig = @import("jetzig");
const xrpc = @import("../../xrpc.zig");
// const json = @import("json");
pub fn index(request: *jetzig.Request) !jetzig.View {
    const alloc = request.allocator;
    const Params = struct {
        actor: []const u8,
    };

    const Profile = struct { did: []const u8 };

    const params = try request.expectParams(Params) orelse {
        return request.fail(.unprocessable_entity);
    };
    const actor = params.actor;
    const profile = try xrpc.MakeRequest("app.bsky.actor.getProfile").call(.{ .actor = actor }, request.allocator);
    var root = try request.data(.object);
    var fbs = std.io.fixedBufferStream(profile);
    var reader = std.json.reader(request.allocator, fbs.reader());
    const profile_struct = try std.json.parseFromTokenSource(std.json.Value, alloc, &reader, .{});
    const parsed = try std.json.parseFromSlice(Profile, alloc, profile, .{});
    _ = parsed;
    // const val = try json.parse(profile);
    try root.put("actor", actor);
    try root.put("profile", profile);
    try root.put("profile_struct", profile_struct.value);
    return request.render(.ok);
}

pub fn get(id: []const u8, request: *jetzig.Request) !jetzig.View {
    var root = try request.data(.object);
    try root.put("actor", id);
    return request.render(.ok);
}

pub fn new(request: *jetzig.Request) !jetzig.View {
    return request.render(.ok);
}

pub fn edit(id: []const u8, request: *jetzig.Request) !jetzig.View {
    _ = id;
    return request.render(.ok);
}

pub fn post(request: *jetzig.Request) !jetzig.View {
    return request.render(.created);
}

pub fn put(id: []const u8, request: *jetzig.Request) !jetzig.View {
    _ = id;
    return request.render(.ok);
}

pub fn patch(id: []const u8, request: *jetzig.Request) !jetzig.View {
    _ = id;
    return request.render(.ok);
}

pub fn delete(id: []const u8, request: *jetzig.Request) !jetzig.View {
    _ = id;
    return request.render(.ok);
}

test "index" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/profile", .{});
    try response.expectStatus(.ok);
}

test "get" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/profile/example-id", .{});
    try response.expectStatus(.ok);
}

test "new" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/profile/new", .{});
    try response.expectStatus(.ok);
}

test "edit" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.GET, "/profile/example-id/edit", .{});
    try response.expectStatus(.ok);
}

test "post" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.POST, "/profile", .{});
    try response.expectStatus(.created);
}

test "put" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.PUT, "/profile/example-id", .{});
    try response.expectStatus(.ok);
}

test "patch" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.PATCH, "/profile/example-id", .{});
    try response.expectStatus(.ok);
}

test "delete" {
    var app = try jetzig.testing.app(std.testing.allocator, @import("routes"));
    defer app.deinit();

    const response = try app.request(.DELETE, "/profile/example-id", .{});
    try response.expectStatus(.ok);
}
