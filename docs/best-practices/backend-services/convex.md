# Convex Best Practices

## Overview

Convex is a real-time backend platform that combines a database, serverless functions, and real-time subscriptions into a cohesive development experience. It provides automatic scalability, ACID transactions, and reactive queries that update in real-time.

### Use Cases
- Real-time collaborative applications
- Chat and messaging platforms
- Live dashboards and analytics
- Multiplayer games and interactive experiences
- Applications requiring strong consistency guarantees
- Projects needing automatic TypeScript type safety

## Setup and Configuration

### Initial Setup

```bash
# Install Convex
npm install convex

# Initialize a new Convex project
npx convex dev

# Deploy to production
npx convex deploy
```

### Project Structure

```
convex/
├── schema.ts          # Database schema definition
├── functions/         # Server functions
├── mutations.ts       # Write operations
├── queries.ts         # Read operations
├── actions.ts         # External API calls
└── _generated/        # Auto-generated types
```

### Schema Definition

```typescript
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    name: v.string(),
    email: v.string(),
    role: v.union(v.literal("admin"), v.literal("user")),
    createdAt: v.number(),
    metadata: v.optional(v.object({
      lastLogin: v.number(),
      preferences: v.any()
    }))
  })
    .index("by_email", ["email"])
    .index("by_role", ["role", "createdAt"]),
  
  messages: defineTable({
    userId: v.id("users"),
    content: v.string(),
    timestamp: v.number(),
    edited: v.optional(v.boolean())
  })
    .index("by_user", ["userId", "timestamp"])
});
```

## Security Considerations

### Authentication Integration

```typescript
// convex/auth.ts
import { Auth } from "convex/server";
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

export const getUserIdentity = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Unauthenticated");
    }
    return identity;
  },
});

// Protect mutations with authentication
export const createSecureDocument = mutation({
  args: {
    content: v.string(),
  },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Authentication required");
    }
    
    // Verify user permissions
    const user = await ctx.db
      .query("users")
      .withIndex("by_email", q => q.eq("email", identity.email))
      .unique();
    
    if (!user || user.role !== "admin") {
      throw new Error("Insufficient permissions");
    }
    
    return await ctx.db.insert("documents", {
      content: args.content,
      userId: user._id,
      createdAt: Date.now()
    });
  },
});
```

### Input Validation

```typescript
// convex/validators.ts
import { v } from "convex/values";
import { mutation } from "./_generated/server";

// Define reusable validators
const emailValidator = v.string();
const phoneValidator = v.string();

export const validateUserInput = mutation({
  args: {
    email: emailValidator,
    phone: phoneValidator,
    age: v.number(),
  },
  handler: async (ctx, args) => {
    // Custom validation logic
    if (!args.email.includes("@")) {
      throw new Error("Invalid email format");
    }
    
    if (args.age < 18 || args.age > 120) {
      throw new Error("Age must be between 18 and 120");
    }
    
    // Phone format validation
    const phoneRegex = /^\+?[1-9]\d{1,14}$/;
    if (!phoneRegex.test(args.phone)) {
      throw new Error("Invalid phone number format");
    }
    
    // Process validated input
    return await ctx.db.insert("validatedUsers", args);
  },
});
```

### Rate Limiting

```typescript
// convex/rateLimit.ts
import { mutation } from "./_generated/server";
import { v } from "convex/values";

const rateLimitMap = new Map();

export const rateLimitedMutation = mutation({
  args: { data: v.string() },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Authentication required");
    
    const key = `${identity.subject}`;
    const now = Date.now();
    const windowMs = 60000; // 1 minute window
    const maxRequests = 10;
    
    const userRequests = rateLimitMap.get(key) || [];
    const recentRequests = userRequests.filter(
      (timestamp: number) => now - timestamp < windowMs
    );
    
    if (recentRequests.length >= maxRequests) {
      throw new Error("Rate limit exceeded. Try again later.");
    }
    
    recentRequests.push(now);
    rateLimitMap.set(key, recentRequests);
    
    // Process the mutation
    return await ctx.db.insert("data", {
      content: args.data,
      userId: identity.subject,
      timestamp: now
    });
  },
});
```

## Performance Optimization

### Query Optimization

```typescript
// convex/queries.ts
import { query } from "./_generated/server";
import { v } from "convex/values";

// Use indexes for efficient queries
export const getMessagesByUser = query({
  args: {
    userId: v.id("users"),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const limit = args.limit || 50;
    
    // Use index for efficient lookup
    const messages = await ctx.db
      .query("messages")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .order("desc")
      .take(limit);
    
    return messages;
  },
});

// Paginated queries for large datasets
export const paginatedQuery = query({
  args: {
    cursor: v.optional(v.string()),
    pageSize: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const pageSize = args.pageSize || 20;
    
    let q = ctx.db.query("items").order("desc");
    
    if (args.cursor) {
      q = q.filter(q => q.lt(q.field("_creationTime"), args.cursor));
    }
    
    const items = await q.take(pageSize + 1);
    
    const hasMore = items.length > pageSize;
    const nextCursor = hasMore ? items[pageSize - 1]._creationTime : null;
    
    return {
      items: items.slice(0, pageSize),
      nextCursor,
      hasMore
    };
  },
});
```

### Caching Strategies

```typescript
// convex/cache.ts
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

// Implement computed fields for expensive calculations
export const getUserStats = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    // Check if cached stats exist and are fresh
    const cached = await ctx.db
      .query("userStatsCache")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .first();
    
    const cacheExpiry = 5 * 60 * 1000; // 5 minutes
    const now = Date.now();
    
    if (cached && (now - cached.updatedAt) < cacheExpiry) {
      return cached.stats;
    }
    
    // Calculate fresh stats
    const posts = await ctx.db
      .query("posts")
      .withIndex("by_author", q => q.eq("authorId", args.userId))
      .collect();
    
    const stats = {
      postCount: posts.length,
      totalLikes: posts.reduce((sum, post) => sum + post.likes, 0),
      avgLikes: posts.length > 0 ? 
        posts.reduce((sum, post) => sum + post.likes, 0) / posts.length : 0
    };
    
    // Update cache
    if (cached) {
      await ctx.db.patch(cached._id, {
        stats,
        updatedAt: now
      });
    } else {
      await ctx.db.insert("userStatsCache", {
        userId: args.userId,
        stats,
        updatedAt: now
      });
    }
    
    return stats;
  },
});
```

### Batch Operations

```typescript
// convex/batch.ts
import { mutation } from "./_generated/server";
import { v } from "convex/values";

export const batchInsert = mutation({
  args: {
    items: v.array(v.object({
      name: v.string(),
      value: v.number()
    }))
  },
  handler: async (ctx, args) => {
    const results = [];
    
    // Use transaction for atomic batch operations
    for (const item of args.items) {
      const id = await ctx.db.insert("items", {
        ...item,
        createdAt: Date.now()
      });
      results.push(id);
    }
    
    return results;
  },
});

// Efficient bulk updates
export const bulkUpdate = mutation({
  args: {
    updates: v.array(v.object({
      id: v.id("items"),
      changes: v.object({
        name: v.optional(v.string()),
        value: v.optional(v.number())
      })
    }))
  },
  handler: async (ctx, args) => {
    const results = await Promise.all(
      args.updates.map(async ({ id, changes }) => {
        const item = await ctx.db.get(id);
        if (!item) return null;
        
        await ctx.db.patch(id, changes);
        return id;
      })
    );
    
    return results.filter(Boolean);
  },
});
```

## Common Patterns

### Real-time Subscriptions

```typescript
// React component with real-time data
import { useQuery } from "convex/react";
import { api } from "../convex/_generated/api";

function MessageList({ channelId }) {
  // Automatically updates when data changes
  const messages = useQuery(api.messages.getByChannel, { 
    channelId 
  });
  
  if (messages === undefined) {
    return <div>Loading...</div>;
  }
  
  return (
    <div>
      {messages.map(message => (
        <div key={message._id}>
          {message.content}
        </div>
      ))}
    </div>
  );
}
```

### Optimistic Updates

```typescript
// convex/optimistic.ts
import { useMutation } from "convex/react";
import { api } from "../convex/_generated/api";
import { useState, useOptimistic } from "react";

function TodoList({ todos }) {
  const addTodo = useMutation(api.todos.add);
  const [optimisticTodos, addOptimistic] = useOptimistic(
    todos,
    (state, newTodo) => [...state, newTodo]
  );
  
  const handleAdd = async (text) => {
    const tempTodo = {
      _id: `temp-${Date.now()}`,
      text,
      completed: false,
      createdAt: Date.now()
    };
    
    // Optimistically add to UI
    addOptimistic(tempTodo);
    
    try {
      // Actual mutation
      await addTodo({ text });
    } catch (error) {
      console.error("Failed to add todo:", error);
      // Handle rollback
    }
  };
  
  return (
    <div>
      {optimisticTodos.map(todo => (
        <div key={todo._id}>{todo.text}</div>
      ))}
    </div>
  );
}
```

### File Storage

```typescript
// convex/storage.ts
import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const generateUploadUrl = mutation(async (ctx) => {
  // Generate a short-lived upload URL
  return await ctx.storage.generateUploadUrl();
});

export const saveFile = mutation({
  args: {
    storageId: v.string(),
    metadata: v.object({
      name: v.string(),
      type: v.string(),
      size: v.number()
    })
  },
  handler: async (ctx, args) => {
    // Save file reference with metadata
    const fileId = await ctx.db.insert("files", {
      storageId: args.storageId,
      ...args.metadata,
      uploadedAt: Date.now(),
      userId: (await ctx.auth.getUserIdentity())?.subject
    });
    
    return fileId;
  },
});

export const getFileUrl = query({
  args: { fileId: v.id("files") },
  handler: async (ctx, args) => {
    const file = await ctx.db.get(args.fileId);
    if (!file) return null;
    
    // Generate URL for file access
    return await ctx.storage.getUrl(file.storageId);
  },
});
```

## Anti-patterns to Avoid

### N+1 Queries
```typescript
// ❌ Avoid multiple queries in loops
export const badPattern = query({
  handler: async (ctx) => {
    const users = await ctx.db.query("users").collect();
    const results = [];
    
    for (const user of users) {
      // This creates N additional queries
      const posts = await ctx.db
        .query("posts")
        .filter(q => q.eq(q.field("userId"), user._id))
        .collect();
      results.push({ user, posts });
    }
    
    return results;
  },
});

// ✅ Use proper joins or batch fetching
export const goodPattern = query({
  handler: async (ctx) => {
    const users = await ctx.db.query("users").collect();
    const userIds = users.map(u => u._id);
    
    // Single query for all posts
    const posts = await ctx.db
      .query("posts")
      .filter(q => q.or(...userIds.map(id => q.eq(q.field("userId"), id))))
      .collect();
    
    // Group posts by user
    const postsByUser = posts.reduce((acc, post) => {
      if (!acc[post.userId]) acc[post.userId] = [];
      acc[post.userId].push(post);
      return acc;
    }, {});
    
    return users.map(user => ({
      user,
      posts: postsByUser[user._id] || []
    }));
  },
});
```

### Unbounded Data Fetching
```typescript
// ❌ Never fetch unlimited data
export const unboundedQuery = query({
  handler: async (ctx) => {
    // This could return millions of records
    return await ctx.db.query("logs").collect();
  },
});

// ✅ Always limit query results
export const boundedQuery = query({
  args: {
    limit: v.optional(v.number())
  },
  handler: async (ctx, args) => {
    const limit = Math.min(args.limit || 100, 1000);
    return await ctx.db
      .query("logs")
      .order("desc")
      .take(limit);
  },
});
```

## Testing Strategies

### Unit Testing Functions

```typescript
// __tests__/functions.test.ts
import { convexTest } from "convex-test";
import { expect, test, describe } from "vitest";
import { api } from "../convex/_generated/api";
import schema from "../convex/schema";

describe("User Functions", () => {
  test("should create user with valid data", async () => {
    const t = convexTest(schema);
    
    const userId = await t.mutation(api.users.create, {
      name: "Test User",
      email: "test@example.com",
      role: "user"
    });
    
    expect(userId).toBeDefined();
    
    const user = await t.query(api.users.getById, { id: userId });
    expect(user.name).toBe("Test User");
    expect(user.email).toBe("test@example.com");
  });
  
  test("should validate email format", async () => {
    const t = convexTest(schema);
    
    await expect(
      t.mutation(api.users.create, {
        name: "Test",
        email: "invalid-email",
        role: "user"
      })
    ).rejects.toThrow("Invalid email format");
  });
});
```

### Integration Testing

```typescript
// __tests__/integration.test.ts
import { ConvexTestClient } from "convex-test";
import { api } from "../convex/_generated/api";

describe("Message System Integration", () => {
  let client: ConvexTestClient;
  let userId: string;
  let channelId: string;
  
  beforeEach(async () => {
    client = new ConvexTestClient();
    
    // Setup test data
    userId = await client.mutation(api.users.create, {
      name: "Test User",
      email: "test@example.com"
    });
    
    channelId = await client.mutation(api.channels.create, {
      name: "Test Channel",
      ownerId: userId
    });
  });
  
  test("complete message flow", async () => {
    // Send message
    const messageId = await client.mutation(api.messages.send, {
      channelId,
      content: "Hello, World!",
      userId
    });
    
    // Retrieve messages
    const messages = await client.query(api.messages.getByChannel, {
      channelId
    });
    
    expect(messages).toHaveLength(1);
    expect(messages[0].content).toBe("Hello, World!");
    
    // Update message
    await client.mutation(api.messages.edit, {
      messageId,
      content: "Updated message"
    });
    
    const updated = await client.query(api.messages.getById, {
      id: messageId
    });
    
    expect(updated.content).toBe("Updated message");
    expect(updated.edited).toBe(true);
  });
});
```

## Error Handling

### Comprehensive Error Management

```typescript
// convex/errors.ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 400,
    public details?: any
  ) {
    super(message);
    this.name = "AppError";
  }
}

export const errorHandler = (handler: any) => {
  return async (ctx: any, args: any) => {
    try {
      return await handler(ctx, args);
    } catch (error) {
      if (error instanceof AppError) {
        // Log structured error
        console.error({
          code: error.code,
          message: error.message,
          details: error.details,
          timestamp: new Date().toISOString()
        });
        
        throw error;
      }
      
      // Handle unexpected errors
      console.error("Unexpected error:", error);
      throw new AppError(
        "An unexpected error occurred",
        "INTERNAL_ERROR",
        500
      );
    }
  };
};

// Usage
export const protectedMutation = mutation({
  args: { data: v.string() },
  handler: errorHandler(async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    
    if (!identity) {
      throw new AppError(
        "Authentication required",
        "UNAUTHENTICATED",
        401
      );
    }
    
    if (args.data.length > 1000) {
      throw new AppError(
        "Data exceeds maximum length",
        "VALIDATION_ERROR",
        400,
        { maxLength: 1000, provided: args.data.length }
      );
    }
    
    return await ctx.db.insert("data", {
      content: args.data,
      userId: identity.subject
    });
  })
});
```

### Retry Logic

```typescript
// convex/retry.ts
import { action } from "./_generated/server";
import { v } from "convex/values";

export const retryableAction = action({
  args: {
    url: v.string(),
    maxRetries: v.optional(v.number())
  },
  handler: async (ctx, args) => {
    const maxRetries = args.maxRetries || 3;
    let lastError;
    
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const response = await fetch(args.url);
        
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        
        return await response.json();
      } catch (error) {
        lastError = error;
        
        // Exponential backoff
        const delay = Math.pow(2, attempt) * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        
        console.log(`Retry attempt ${attempt + 1} after ${delay}ms`);
      }
    }
    
    throw new Error(`Failed after ${maxRetries} attempts: ${lastError}`);
  }
});
```

## Resources

- [Official Documentation](https://docs.convex.dev)
- [API Reference](https://docs.convex.dev/api)
- [Discord Community](https://convex.dev/community)
- [GitHub Repository](https://github.com/get-convex/convex-js)
- [Stack Templates](https://github.com/get-convex/templates)