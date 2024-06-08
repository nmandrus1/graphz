const std = @import("std");

const Graph = @import("graphz.zig").AdjacencyMatrix;

pub fn main() !void {
    std.debug.print("Hello Graph Lib!\n", .{});

    var alloc = std.heap.GeneralPurposeAllocator(.{}){};

    const edges = [_]struct { u8, u8 }{ .{ 0, 1 }, .{ 0, 2 }, .{ 1, 2 }, .{ 1, 3 }, .{ 2, 4 } };
    const vcount = edges.len;

    var g = try Graph.fromEdgeListAlloc(alloc.allocator(), &edges);
    defer g.deinit();

    // parents array of vcount i16s
    var parents: [vcount]i16 = [_]i16{-1} ** vcount;

    // calculate BFS and write to parents array
    try g.bfs(&parents);
    std.debug.print("{any}\n", .{&parents});
}
