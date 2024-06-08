const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;

const AdjMatErrors = error{
    // Passed slice has an invalid length
    InvalidSliceLength,
};

// basic 1D adjacency matrix representation
pub const Graph = struct {
    vcount: usize,
    data: []u8,
    allocator: Allocator,

    // alloc and free
    pub fn init(allocator: Allocator, vertex_count: usize) Allocator.Error!Graph {
        const g = Graph{
            .vcount = vertex_count,
            .allocator = allocator,
            .data = try allocator.alloc(u8, vertex_count * vertex_count),
        };

        @memset(g.data, 0);
        return g;
    }

    pub fn deinit(self: *Graph) void {
        self.allocator.free(self.data);
    }

    // Allocate and Populate a graph based on the edge list
    pub fn fromEdgeListAlloc(allocator: Allocator, edges: []const struct { u8, u8 }) Allocator.Error!Graph {
        var graph = try Graph.init(allocator, edges.len);
        try graph.fromEdgeList(edges);
        return graph;
    }

    // Populate a pre-allocated graph based on the edge list provided
    pub fn fromEdgeList(self: *Graph, edges: []const struct { u8, u8 }) !void {
        for (edges) |e| try self.add_edge(e.@"0", e.@"1");
    }

    fn add_edge(self: *Graph, v1: u8, v2: u8) !void {
        self.data[self.vcount * v1 + v2] = 1;
        self.data[self.vcount * v2 + v1] = 1;
    }

    pub fn getEdges(self: *Graph, vertex: u8) []u8 {
        std.debug.assert(vertex < self.vcount);
        return self.data[self.vcount * vertex .. self.vcount * vertex + self.vcount];
    }

    pub fn bfs(self: *Graph, parents: []i16) !void {
        std.debug.assert(self.vcount <= parents.len);

        var q = util.Queue(u8).init(self.allocator);
        try q.push(0);

        // lookup table for visited
        var visited = try std.DynamicBitSet.initEmpty(self.allocator, self.vcount);
        defer visited.deinit();

        while (q.count > 0) {
            const parent = q.pop().?;
            const children = self.getEdges(parent);

            for (children, 0..) |child_exits, i| {
                const child: u8 = @intCast(i);
                if (child_exits == 1 and !visited.isSet(child)) {
                    try q.push(child);
                    visited.set(child);
                    parents[child] = parent;
                }
            }
        }
    }
};

const testing = std.testing;

test "init and deinit" {
    var graph = try Graph.init(testing.allocator, 5);
    defer graph.deinit();

    try testing.expect(graph.data.len == graph.vcount * graph.vcount);
}

test "from edge list" {
    const edges = [_]struct { u8, u8 }{ .{ 0, 1 }, .{ 0, 2 }, .{ 1, 2 }, .{ 1, 3 }, .{ 2, 4 } };

    // runtime length to coerce array into slice
    var start: u8 = 0;
    _ = &start;

    var graph = try Graph.fromEdgeListAlloc(testing.allocator, edges[start..]);
    defer graph.deinit();

    const expected = [_]u8{
        0, 1, 1, 0, 0,
        1, 0, 1, 1, 0,
        1, 1, 0, 0, 1,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
    };

    try testing.expectEqualSlices(u8, &expected, graph.data);
}
