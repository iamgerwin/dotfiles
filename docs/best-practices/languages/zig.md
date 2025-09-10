# Zig Programming Language Best Practices

## Overview

Zig is a general-purpose programming language designed for robustness, optimality, and clarity. It provides manual memory management with safety features and compile-time code execution.

## Core Principles

### Explicit Over Implicit
```zig
// ❌ Bad - Hidden allocations
const list = ArrayList(u32).init();  // Where's the allocator?

// ✅ Good - Explicit allocator
const list = ArrayList(u32).init(allocator);
```

### No Hidden Control Flow
```zig
// Zig has no exceptions, hidden function calls, or operator overloading
// All control flow is visible in the code

// ✅ Errors are values
fn divide(a: f32, b: f32) !f32 {
    if (b == 0) return error.DivisionByZero;
    return a / b;
}
```

## Memory Management

### Allocator Pattern
```zig
const std = @import("std");

pub fn main() !void {
    // General purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Arena allocator for temporary allocations
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    
    // Use arena for all allocations in scope
    const temp_allocator = arena.allocator();
    const data = try temp_allocator.alloc(u8, 1024);
    // No need to free individual allocations
}
```

### Memory Safety
```zig
// ✅ Bounds checking at compile time when possible
const array = [_]u8{1, 2, 3};
const value = array[comptime_known_index];

// ✅ Runtime safety in debug/ReleaseSafe modes
fn getElement(slice: []const u8, index: usize) u8 {
    return slice[index]; // Bounds checked in safe modes
}

// ✅ Optional types for nullable values
var maybe_value: ?u32 = null;
if (maybe_value) |value| {
    // value is guaranteed non-null here
}
```

## Error Handling

### Error Sets and Unions
```zig
const FileError = error{
    NotFound,
    PermissionDenied,
    SystemResources,
};

fn openFile(path: []const u8) FileError!File {
    // Return error or file
    return error.NotFound;
}

// Error handling patterns
fn processFile(path: []const u8) !void {
    // Try - propagate error up
    const file = try openFile(path);
    defer file.close();
    
    // Catch with default value
    const size = file.getSize() catch 0;
    
    // Catch and handle specific errors
    file.read() catch |err| switch (err) {
        error.EndOfFile => return,
        error.SystemResources => {
            // Handle system resource error
            return err;
        },
        else => return err,
    };
}
```

## Compile-Time Programming

### Comptime Parameters
```zig
fn Matrix(comptime T: type, comptime rows: usize, comptime cols: usize) type {
    return struct {
        data: [rows][cols]T,
        
        pub fn init() @This() {
            return .{ .data = std.mem.zeroes([rows][cols]T) };
        }
    };
}

// Usage
const Mat3x3 = Matrix(f32, 3, 3);
var matrix = Mat3x3.init();
```

### Comptime Reflection
```zig
fn debugPrint(value: anytype) void {
    const T = @TypeOf(value);
    const type_info = @typeInfo(T);
    
    switch (type_info) {
        .Struct => |info| {
            inline for (info.fields) |field| {
                std.debug.print("{s}: {}\n", .{
                    field.name,
                    @field(value, field.name),
                });
            }
        },
        else => std.debug.print("{}\n", .{value}),
    }
}
```

## Project Structure

### Standard Layout
```
my-project/
├── build.zig           # Build configuration
├── build.zig.zon       # Package dependencies
├── src/
│   ├── main.zig       # Application entry point
│   ├── lib.zig        # Library entry point
│   └── modules/       # Internal modules
├── test/
│   └── main_test.zig  # Test files
├── docs/              # Documentation
└── examples/          # Example code
```

### Build Configuration
```zig
// build.zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Executable
    const exe = b.addExecutable(.{
        .name = "my-app",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    
    // Library
    const lib = b.addStaticLibrary(.{
        .name = "my-lib",
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);
    
    // Tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&tests.step);
}
```

## Testing

### Unit Tests
```zig
const std = @import("std");
const testing = std.testing;

fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "addition" {
    try testing.expectEqual(@as(i32, 42), add(40, 2));
    try testing.expect(add(1, 1) == 2);
}

test "string operations" {
    const allocator = testing.allocator;
    
    const str = try std.fmt.allocPrint(allocator, "Hello, {s}!", .{"World"});
    defer allocator.free(str);
    
    try testing.expectEqualStrings("Hello, World!", str);
}
```

### Test Organization
```zig
// Group related tests
test "math operations" {
    try testing.expectEqual(@as(i32, 4), 2 + 2);
    try testing.expectEqual(@as(i32, 0), 2 - 2);
}

// Reference all module tests
test {
    _ = @import("math.zig");
    _ = @import("string.zig");
    _ = @import("network.zig");
}
```

## Async/Await

### Async Functions
```zig
const std = @import("std");

fn fetchData() ![]u8 {
    // Simulate async operation
    std.time.sleep(1 * std.time.ns_per_ms);
    return "data";
}

pub fn main() !void {
    // Note: Async is being redesigned in Zig
    // Current implementation may change
    const result = try fetchData();
    std.debug.print("Result: {s}\n", .{result});
}
```

## C Interoperability

### Importing C Libraries
```zig
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});

pub fn main() void {
    _ = c.printf("Hello from C!\n");
}
```

### Exporting to C
```zig
// Export function for C usage
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

// Export with C calling convention
export fn process(data: [*c]u8, len: usize) void {
    const slice = data[0..len];
    // Process data
}
```

## Performance Optimization

### SIMD Operations
```zig
const std = @import("std");

fn vectorAdd(a: []f32, b: []f32, result: []f32) void {
    const vec_size = 4;
    var i: usize = 0;
    
    // Process in SIMD chunks
    while (i + vec_size <= a.len) : (i += vec_size) {
        const va = @Vector(vec_size, f32){ a[i], a[i+1], a[i+2], a[i+3] };
        const vb = @Vector(vec_size, f32){ b[i], b[i+1], b[i+2], b[i+3] };
        const vr = va + vb;
        
        result[i..i+vec_size].* = @as([vec_size]f32, vr);
    }
    
    // Process remaining elements
    while (i < a.len) : (i += 1) {
        result[i] = a[i] + b[i];
    }
}
```

### Custom Allocators
```zig
const FixedBufferAllocator = struct {
    buffer: []u8,
    pos: usize = 0,
    
    pub fn allocator(self: *@This()) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .resize = resize,
                .free = free,
            },
        };
    }
    
    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        const self = @ptrCast(*FixedBufferAllocator, @alignCast(@alignOf(FixedBufferAllocator), ctx));
        _ = ret_addr;
        
        const aligned_pos = std.mem.alignForward(self.pos, ptr_align);
        if (aligned_pos + len > self.buffer.len) return null;
        
        const result = self.buffer.ptr + aligned_pos;
        self.pos = aligned_pos + len;
        return result;
    }
    
    fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
        _ = ctx; _ = buf; _ = buf_align; _ = new_len; _ = ret_addr;
        return false; // Fixed buffer cannot resize
    }
    
    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        _ = ctx; _ = buf; _ = buf_align; _ = ret_addr;
        // No-op for fixed buffer
    }
};
```

## Best Practices Summary

### Do's ✅
- Always use explicit allocators
- Handle all errors explicitly
- Use defer for cleanup
- Leverage compile-time features
- Write comprehensive tests
- Use const by default, var when needed
- Document public APIs
- Use meaningful error names
- Profile before optimizing
- Keep functions small and focused

### Don'ts ❌
- Don't ignore error returns
- Don't use undefined behavior in safe builds
- Don't leak memory
- Don't use @intToPtr without good reason
- Don't rely on implicit behavior
- Don't use global allocators in libraries
- Don't mix allocators
- Don't assume platform-specific behavior
- Don't use unsafe features without documentation
- Don't ignore compiler warnings

## Common Patterns

### Builder Pattern
```zig
const Builder = struct {
    allocator: std.mem.Allocator,
    name: ?[]const u8 = null,
    value: u32 = 0,
    
    pub fn setName(self: *@This(), name: []const u8) *@This() {
        self.name = name;
        return self;
    }
    
    pub fn setValue(self: *@This(), value: u32) *@This() {
        self.value = value;
        return self;
    }
    
    pub fn build(self: @This()) !Product {
        return Product{
            .name = self.name orelse return error.MissingName,
            .value = self.value,
        };
    }
};
```

### Resource Management
```zig
const Resource = struct {
    handle: *c_void,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) !@This() {
        const handle = c.createResource() orelse return error.ResourceCreationFailed;
        return .{
            .handle = handle,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: @This()) void {
        c.destroyResource(self.handle);
    }
};

// Usage with defer
const resource = try Resource.init(allocator);
defer resource.deinit();
```

## References

- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig Learn](https://ziglearn.org/)
- [Zig by Example](https://zigbyexample.github.io/)
- [Zig Standard Library](https://ziglang.org/documentation/master/std/)
- [Awesome Zig](https://github.com/C-BJ/awesome-zig)