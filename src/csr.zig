const std = @import("std");

/// Compressed Sparse Row Representation
const CSR = struct {
    // values of nonzero elements
    a: []u8,

    // stores the cumulative number of nonzero
    // elements upto (not including) the i-th row
    ia: []u8,

    // stores the column index of each element in the A vector
    ja: []u8,

    allocator: std.mem.Allocator,
};
