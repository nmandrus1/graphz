const std = @import("std");
const debug = std.debug;
const assert = debug.assert;

const Allocator = std.mem.Allocator;

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []T,

        // index of first and last elements in the queue
        front: usize,
        rear: usize,

        // num of elements
        count: usize,

        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .items = &[_]T{},
                .front = 0,
                .rear = 0,
                .count = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.items);
        }

        pub fn growCapacity(self: *Self) Allocator.Error!void {
            const old_memory = self.items.ptr[0..self.items.len];
            const new = if (self.items.len == 0) 4 else self.items.len * 2;

            // Check if the allocator has enough memory to avoid a move
            if (self.allocator.resize(old_memory, new)) return else {
                // allocate new memory and copy everything over
                const new_memory = try self.allocator.alloc(T, new);
                // copy over the queue's memory to new slice being sure to write the current front of the queue
                // to index 0 regardless of the index of the front

                if (self.rear >= self.front) std.mem.copyForwards(T, new_memory, self.items[self.front..self.rear]) else {
                    const front_to_end = old_memory[self.front..];
                    std.mem.copyForwards(T, new_memory, front_to_end);
                    std.mem.copyForwards(T, new_memory[front_to_end.len..], old_memory[0..self.rear]);
                }

                self.allocator.free(old_memory);
                self.items = new_memory;
                self.front = 0;
                self.rear = old_memory.len -| 1;
            }
        }

        // returns the front of queue or null if empty
        pub fn pop(self: *Self) ?T {
            //empty queue
            if (self.front == self.rear) return null;

            const data = self.items[self.front];

            self.front += 1;
            self.count -= 1;

            if (self.front == self.rear) {
                self.front = 0;
                self.rear = 0;
                self.count = 0;
            } else self.front %= self.items.len;

            return data;
        }

        pub fn push(self: *Self, elem: T) Allocator.Error!void {
            // reallocating when there is an open slot
            if ((self.items.len == 0) or ((self.rear + 1) % self.items.len == self.front))
                try self.growCapacity(); // expand buffer

            self.items[self.rear] = elem;
            self.rear = ((self.rear + 1) % self.items.len);
            self.count += 1;
        }
    };
}

const testing = std.testing;

test "queue_initialization" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    try testing.expectEqual(0, queue.items.len);
}

test "queue_push_and_pop" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    try queue.push(1);
    try queue.push(2);
    try queue.push(3);

    try testing.expectEqual(3, queue.count);
    try testing.expectEqual(1, queue.pop());
    try testing.expectEqual(2, queue.pop());
    try testing.expectEqual(3, queue.pop());
    try testing.expectEqual(null, queue.pop());
    try testing.expectEqual(0, queue.count);
}

test "queue_resizing" {
    const allocator = std.testing.allocator;
    var queue = Queue(usize).init(allocator);
    defer queue.deinit();

    for (0..10) |i| {
        try queue.push(i);
    }

    for (0..10) |i| {
        try testing.expectEqual(i, queue.pop());
    }

    try testing.expect(queue.pop() == null);
}

test "queue_wrap-around" {
    const allocator = std.testing.allocator;
    var queue = Queue(usize).init(allocator);
    defer queue.deinit();

    for (0..5) |i| {
        try queue.push(i);
    }
    for (0..3) |i| {
        try testing.expect(queue.pop() == i);
    }

    for (5..8) |i| {
        try queue.push(i);
    }

    try testing.expectEqual(3, queue.pop());
    try testing.expectEqual(4, queue.pop());
    try testing.expectEqual(5, queue.pop());
    try testing.expectEqual(6, queue.pop());
    try testing.expectEqual(7, queue.pop());
    try testing.expectEqual(null, queue.pop());
}

test "queue_empty_after_pop" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    try queue.push(42);
    try testing.expectEqual(42, queue.pop());
    try testing.expectEqual(null, queue.pop());

    try queue.push(24);
    try testing.expectEqual(24, queue.pop());
    try testing.expectEqual(null, queue.pop());
}

test "queue_handles_large_number_of_elements" {
    const allocator = std.testing.allocator;
    var queue = Queue(usize).init(allocator);
    defer queue.deinit();

    for (0..10000) |i| {
        try queue.push(i);
    }

    for (0..10000) |i| {
        try testing.expect(queue.pop() == i);
    }
    try testing.expect(queue.pop() == null);
}

test "queue_multiple_resizing" {
    const allocator = std.testing.allocator;
    var queue = Queue(usize).init(allocator);
    defer queue.deinit();

    for (0..1000) |i| {
        try queue.push(i);
    }
    for (0..500) |i| {
        try testing.expectEqual(i, queue.pop());
    }
    for (1000..1500) |i| {
        try queue.push(i);
    }
    for (500..1500) |i| {
        try testing.expectEqual(i, queue.pop());
    }
    try testing.expectEqual(null, queue.pop());
}

test "queue_resizing_with_wrap-around" {
    const allocator = std.testing.allocator;
    var queue = Queue(usize).init(allocator);
    defer queue.deinit();

    for (0..5) |i| {
        try queue.push(i);
    }
    for (0..3) |i| {
        try testing.expectEqual(i, queue.pop());
    }
    for (5..15) |i| {
        try queue.push(i);
    }
    for (3..15) |i| {
        try testing.expectEqual(i, queue.pop());
    }
    try testing.expectEqual(null, queue.pop());
}

test "queue_front_after_wrap-around" {
    const allocator = std.testing.allocator;
    var queue = Queue(usize).init(allocator);
    defer queue.deinit();

    for (0..5) |i| {
        try queue.push(i);
    }
    for (0..3) |i| {
        try testing.expectEqual(i, queue.pop());
    }

    try queue.push(5);
    try queue.push(6);

    try testing.expectEqual(3, queue.pop());
    try testing.expectEqual(4, queue.pop());
    try testing.expectEqual(5, queue.pop());
    try testing.expectEqual(6, queue.pop());
    try testing.expectEqual(null, queue.pop());
}

test "queue_push_and_pop_in_reverse_order" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init(allocator);
    defer queue.deinit();

    try queue.push(1);
    try testing.expectEqual(1, queue.pop());
    try queue.push(2);
    try queue.push(3);
    try testing.expectEqual(2, queue.pop());
    try testing.expectEqual(3, queue.pop());
    try testing.expectEqual(null, queue.pop());
}

test "queue_memory_cleanup" {
    const allocator = std.testing.allocator;
    var queue = Queue([3]u8).init(allocator);
    defer queue.deinit();

    try queue.push([_]u8{ 1, 2, 3 });
    try queue.push([_]u8{ 4, 5, 6 });

    const first = queue.pop().?;
    try testing.expectEqual(1, first[0]);
    try testing.expectEqual(2, first[1]);
    try testing.expectEqual(3, first[2]);

    const second = queue.pop().?;
    try testing.expectEqual(4, second[0]);
    try testing.expectEqual(5, second[1]);
    try testing.expectEqual(6, second[2]);

    try testing.expectEqual(null, queue.pop());
}
