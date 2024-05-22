const std = @import("std");
const Allocator = std.mem.Allocator;

const testing = std.testing;

const Edge = struct { u8, u8 };

// basic 1D adjacency matrix representation
const Graph = struct {
    vcount: usize,
    data: []u8,
    allocator: Allocator,

    // alloc and free
    pub fn init(allocator: Allocator, vertex_count: usize) Allocator.Error!Graph {
        return Graph{
            .vcount = vertex_count,
            .allocator = allocator,
            .data = try allocator.alloc(u8, vertex_count * vertex_count),
        };
    }

    pub fn deinit(self: Graph) void {
        self.allocator.free(self.data);
    }

    // Allocate and Populate a graph based on the edge list
    pub fn fromEdgeList(allocator: Allocator, edges: []const struct { u8, u8 }) Allocator.Error!Graph {
        var graph = try Graph.init(allocator, edges.len);

        for (edges) |e| {
            const e1 = e.@"0";
            const e2 = e.@"1";
            graph.data[e1] = e2;
            graph.data[e2] = e1;
        }

        return graph;
    }
};

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

    var graph = try Graph.fromEdgeList(testing.allocator, edges[start..]);
    defer graph.deinit();
}
