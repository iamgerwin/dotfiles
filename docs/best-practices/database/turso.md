# Turso Database Best Practices

## Official Documentation
- **Turso Documentation**: https://docs.turso.tech
- **Turso CLI Reference**: https://docs.turso.tech/reference/turso-cli
- **libSQL Documentation**: https://docs.turso.tech/libsql
- **Turso GitHub**: https://github.com/tursodatabase

## Overview

Turso is an edge-hosted, distributed database based on libSQL (SQLite fork) that brings data close to your users with global replication, branching capabilities, and SQLite compatibility.

## Getting Started

### 1. Installation & Setup

```bash
# Install Turso CLI
curl -sSfL https://get.tur.so/install.sh | bash

# Login to Turso
turso auth login

# Create a new database
turso db create my-app --location lax

# Get connection URLs
turso db show my-app

# Create a database token
turso db tokens create my-app --expiration none
```

### 2. Environment Configuration

```bash
# .env.local
# Primary database URL
TURSO_DATABASE_URL="libsql://my-app-username.turso.io"

# Database auth token
TURSO_AUTH_TOKEN="your-auth-token"

# For local development with remote sync
TURSO_DATABASE_URL_LOCAL="file:local.db"
TURSO_SYNC_URL="libsql://my-app-username.turso.io"

# Multiple regions (if using)
TURSO_DATABASE_URL_LAX="libsql://my-app-lax-username.turso.io"
TURSO_DATABASE_URL_FRA="libsql://my-app-fra-username.turso.io"
```

## Connection Patterns

### 1. Basic libSQL Client

```typescript
// lib/turso.ts
import { createClient } from "@libsql/client"

// Create client based on environment
export const turso = createClient({
  url: process.env.TURSO_DATABASE_URL!,
  authToken: process.env.TURSO_AUTH_TOKEN!,
})

// Local development with sync
export const tursoLocal = createClient({
  url: process.env.TURSO_DATABASE_URL_LOCAL!,
  syncUrl: process.env.TURSO_SYNC_URL!,
  authToken: process.env.TURSO_AUTH_TOKEN!,
  syncInterval: 60, // Sync every 60 seconds
})

// Connection with retry logic
export async function executeWithRetry<T>(
  operation: () => Promise<T>,
  maxRetries = 3,
  delay = 1000
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation()
    } catch (error) {
      if (attempt === maxRetries) {
        throw error
      }
      
      console.warn(`Database operation failed (attempt ${attempt}/${maxRetries}):`, error)
      await new Promise(resolve => setTimeout(resolve, delay * attempt))
    }
  }
  
  throw new Error('Max retries exceeded')
}

// Health check function
export async function checkDatabaseHealth() {
  try {
    const result = await turso.execute("SELECT 1 as health")
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      rows: result.rows.length,
    }
  } catch (error) {
    return {
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString(),
    }
  }
}
```

### 2. Drizzle ORM Integration

```typescript
// lib/drizzle-turso.ts
import { drizzle } from 'drizzle-orm/libsql'
import { createClient } from '@libsql/client'
import * as schema from './schema'

const client = createClient({
  url: process.env.TURSO_DATABASE_URL!,
  authToken: process.env.TURSO_AUTH_TOKEN!,
})

export const db = drizzle(client, { schema })

// Schema definition
// lib/schema.ts
import { sqliteTable, text, integer, real, blob } from 'drizzle-orm/sqlite-core'
import { relations } from 'drizzle-orm'
import { createInsertSchema, createSelectSchema } from 'drizzle-zod'
import { z } from 'zod'

export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  email: text('email').unique().notNull(),
  name: text('name'),
  avatar: text('avatar'),
  role: text('role', { enum: ['user', 'admin', 'moderator'] }).default('user'),
  status: text('status', { enum: ['active', 'inactive', 'suspended'] }).default('active'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
})

export const posts = sqliteTable('posts', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  slug: text('slug').unique().notNull(),
  content: text('content'),
  excerpt: text('excerpt'),
  status: text('status', { enum: ['draft', 'published', 'archived'] }).default('draft'),
  publishedAt: integer('published_at', { mode: 'timestamp' }),
  authorId: text('author_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  viewCount: integer('view_count').default(0),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
})

export const comments = sqliteTable('comments', {
  id: text('id').primaryKey(),
  content: text('content').notNull(),
  authorId: text('author_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  postId: text('post_id').notNull().references(() => posts.id, { onDelete: 'cascade' }),
  parentId: text('parent_id').references(() => comments.id, { onDelete: 'cascade' }),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
})

export const tags = sqliteTable('tags', {
  id: text('id').primaryKey(),
  name: text('name').unique().notNull(),
  slug: text('slug').unique().notNull(),
  description: text('description'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
})

export const postTags = sqliteTable('post_tags', {
  postId: text('post_id').notNull().references(() => posts.id, { onDelete: 'cascade' }),
  tagId: text('tag_id').notNull().references(() => tags.id, { onDelete: 'cascade' }),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull().$defaultFn(() => new Date()),
}, (table) => ({
  pk: { columns: [table.postId, table.tagId] },
}))

// Relations
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
  comments: many(comments),
}))

export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id] }),
  comments: many(comments),
  postTags: many(postTags),
}))

export const commentsRelations = relations(comments, ({ one, many }) => ({
  author: one(users, { fields: [comments.authorId], references: [users.id] }),
  post: one(posts, { fields: [comments.postId], references: [posts.id] }),
  parent: one(comments, { fields: [comments.parentId], references: [comments.id] }),
  replies: many(comments),
}))

export const tagsRelations = relations(tags, ({ many }) => ({
  postTags: many(postTags),
}))

export const postTagsRelations = relations(postTags, ({ one }) => ({
  post: one(posts, { fields: [postTags.postId], references: [posts.id] }),
  tag: one(tags, { fields: [postTags.tagId], references: [tags.id] }),
}))

// Zod schemas for validation
export const insertUserSchema = createInsertSchema(users)
export const selectUserSchema = createSelectSchema(users)
export const insertPostSchema = createInsertSchema(posts)
export const selectPostSchema = createSelectSchema(posts)

export type User = typeof users.$inferSelect
export type NewUser = typeof users.$inferInsert
export type Post = typeof posts.$inferSelect
export type NewPost = typeof posts.$inferInsert
```

### 3. Repository Pattern with Turso

```typescript
// repositories/post-repository.ts
import { db } from '@/lib/drizzle-turso'
import { posts, users, comments, tags, postTags } from '@/lib/schema'
import { eq, desc, and, like, sql, count } from 'drizzle-orm'
import { generateId } from '@/lib/utils'

export class PostRepository {
  // Get paginated posts with relations
  static async getPaginatedPosts({
    page = 1,
    limit = 10,
    status = 'published',
    search,
    authorId,
  }: {
    page?: number
    limit?: number
    status?: string
    search?: string
    authorId?: string
  }) {
    const offset = (page - 1) * limit

    // Build where conditions
    const conditions = [
      eq(posts.status, status as any),
      ...(authorId ? [eq(posts.authorId, authorId)] : []),
      ...(search ? [
        sql`(${posts.title} LIKE ${`%${search}%`} OR ${posts.content} LIKE ${`%${search}%`})`
      ] : []),
    ]

    // Get posts with author info
    const result = await db
      .select({
        id: posts.id,
        title: posts.title,
        slug: posts.slug,
        excerpt: posts.excerpt,
        publishedAt: posts.publishedAt,
        viewCount: posts.viewCount,
        author: {
          id: users.id,
          name: users.name,
          avatar: users.avatar,
        },
        commentsCount: sql<number>`(
          SELECT COUNT(*) FROM ${comments} 
          WHERE ${comments.postId} = ${posts.id}
        )`,
      })
      .from(posts)
      .leftJoin(users, eq(posts.authorId, users.id))
      .where(and(...conditions))
      .orderBy(desc(posts.publishedAt))
      .limit(limit)
      .offset(offset)

    // Get total count
    const totalResult = await db
      .select({ count: sql<number>`COUNT(*)` })
      .from(posts)
      .where(and(...conditions))

    const total = totalResult[0]?.count || 0

    return {
      posts: result,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: offset + limit < total,
        hasPrev: page > 1,
      },
    }
  }

  // Get single post with all relations
  static async getPostBySlug(slug: string) {
    const result = await db
      .select({
        id: posts.id,
        title: posts.title,
        slug: posts.slug,
        content: posts.content,
        excerpt: posts.excerpt,
        status: posts.status,
        publishedAt: posts.publishedAt,
        viewCount: posts.viewCount,
        createdAt: posts.createdAt,
        author: {
          id: users.id,
          name: users.name,
          avatar: users.avatar,
        },
      })
      .from(posts)
      .leftJoin(users, eq(posts.authorId, users.id))
      .where(eq(posts.slug, slug))
      .limit(1)

    const post = result[0]
    if (!post) return null

    // Get comments with replies
    const commentsResult = await db
      .select({
        id: comments.id,
        content: comments.content,
        createdAt: comments.createdAt,
        parentId: comments.parentId,
        author: {
          id: users.id,
          name: users.name,
          avatar: users.avatar,
        },
      })
      .from(comments)
      .leftJoin(users, eq(comments.authorId, users.id))
      .where(eq(comments.postId, post.id))
      .orderBy(desc(comments.createdAt))

    // Get tags
    const tagsResult = await db
      .select({
        id: tags.id,
        name: tags.name,
        slug: tags.slug,
      })
      .from(postTags)
      .leftJoin(tags, eq(postTags.tagId, tags.id))
      .where(eq(postTags.postId, post.id))

    return {
      ...post,
      comments: commentsResult,
      tags: tagsResult,
    }
  }

  // Create post with tags (transaction)
  static async createPost({
    title,
    content,
    excerpt,
    authorId,
    tagNames = [],
    status = 'draft',
  }: {
    title: string
    content: string
    excerpt?: string
    authorId: string
    tagNames?: string[]
    status?: string
  }) {
    return db.transaction(async (tx) => {
      const postId = generateId()
      const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-')

      // Create the post
      await tx.insert(posts).values({
        id: postId,
        title,
        slug,
        content,
        excerpt,
        authorId,
        status: status as any,
        publishedAt: status === 'published' ? new Date() : null,
      })

      // Handle tags
      if (tagNames.length > 0) {
        for (const tagName of tagNames) {
          const tagSlug = tagName.toLowerCase().replace(/[^a-z0-9]+/g, '-')
          
          // Insert or ignore tag
          await tx
            .insert(tags)
            .values({
              id: generateId(),
              name: tagName,
              slug: tagSlug,
            })
            .onConflictDoNothing({ target: tags.slug })

          // Get the tag ID
          const tagResult = await tx
            .select({ id: tags.id })
            .from(tags)
            .where(eq(tags.slug, tagSlug))
            .limit(1)

          if (tagResult[0]) {
            // Create post-tag relation
            await tx
              .insert(postTags)
              .values({
                postId,
                tagId: tagResult[0].id,
              })
              .onConflictDoNothing()
          }
        }
      }

      return postId
    })
  }

  // Update post view count
  static async incrementViewCount(postId: string) {
    await db
      .update(posts)
      .set({
        viewCount: sql`${posts.viewCount} + 1`,
        updatedAt: new Date(),
      })
      .where(eq(posts.id, postId))
  }

  // Full-text search using SQLite FTS5
  static async searchPosts(query: string, limit = 10) {
    // Note: This requires FTS5 virtual table setup
    const result = await db.execute(sql`
      SELECT 
        p.id, p.title, p.slug, p.excerpt, p.published_at, p.view_count,
        u.name as author_name, u.avatar as author_avatar,
        rank
      FROM posts_fts pf
      JOIN posts p ON pf.rowid = p.rowid
      LEFT JOIN users u ON p.author_id = u.id
      WHERE posts_fts MATCH ${query}
        AND p.status = 'published'
        AND p.published_at <= datetime('now')
      ORDER BY rank
      LIMIT ${limit}
    `)

    return result.rows
  }

  // Batch operations for performance
  static async batchInsertPosts(postsData: NewPost[]) {
    const batchSize = 100
    const results: string[] = []

    for (let i = 0; i < postsData.length; i += batchSize) {
      const batch = postsData.slice(i, i + batchSize)
      
      await db.transaction(async (tx) => {
        for (const postData of batch) {
          const postId = generateId()
          await tx.insert(posts).values({
            ...postData,
            id: postId,
          })
          results.push(postId)
        }
      })
    }

    return results
  }
}

// User repository
export class UserRepository {
  static async createUser(userData: {
    email: string
    name: string
    avatar?: string
  }) {
    const userId = generateId()
    
    await db.insert(users).values({
      id: userId,
      email: userData.email,
      name: userData.name,
      avatar: userData.avatar,
    })

    return userId
  }

  static async getUserWithStats(id: string) {
    const result = await db
      .select({
        id: users.id,
        name: users.name,
        email: users.email,
        avatar: users.avatar,
        role: users.role,
        status: users.status,
        createdAt: users.createdAt,
        postsCount: sql<number>`(
          SELECT COUNT(*) FROM ${posts} 
          WHERE ${posts.authorId} = ${users.id} 
            AND ${posts.status} = 'published'
        )`,
        commentsCount: sql<number>`(
          SELECT COUNT(*) FROM ${comments} 
          WHERE ${comments.authorId} = ${users.id}
        )`,
        totalViews: sql<number>`(
          SELECT COALESCE(SUM(${posts.viewCount}), 0) FROM ${posts} 
          WHERE ${posts.authorId} = ${users.id}
        )`,
      })
      .from(users)
      .where(eq(users.id, id))
      .limit(1)

    return result[0] || null
  }

  static async getUserPosts(
    userId: string,
    options: { limit?: number; offset?: number; status?: string } = {}
  ) {
    const { limit = 10, offset = 0, status } = options

    const conditions = [
      eq(posts.authorId, userId),
      ...(status ? [eq(posts.status, status as any)] : []),
    ]

    return db
      .select({
        id: posts.id,
        title: posts.title,
        slug: posts.slug,
        excerpt: posts.excerpt,
        status: posts.status,
        publishedAt: posts.publishedAt,
        viewCount: posts.viewCount,
        createdAt: posts.createdAt,
        commentsCount: sql<number>`(
          SELECT COUNT(*) FROM ${comments} 
          WHERE ${comments.postId} = ${posts.id}
        )`,
      })
      .from(posts)
      .where(and(...conditions))
      .orderBy(desc(posts.createdAt))
      .limit(limit)
      .offset(offset)
  }
}
```

## Performance Optimization

### 1. Local Development with Sync

```typescript
// lib/turso-local.ts
import { createClient } from '@libsql/client'

// Local development setup with remote sync
export const tursoLocal = createClient({
  url: "file:local.db",
  syncUrl: process.env.TURSO_DATABASE_URL!,
  authToken: process.env.TURSO_AUTH_TOKEN!,
  syncInterval: 60000, // Sync every minute
})

// Manual sync control
export async function syncDatabase() {
  try {
    await tursoLocal.sync()
    console.log('✅ Database synced successfully')
  } catch (error) {
    console.error('❌ Database sync failed:', error)
  }
}

// Auto-sync on application start
export async function initializeLocalDatabase() {
  try {
    // Initial sync
    await tursoLocal.sync()
    
    // Set up periodic sync
    setInterval(async () => {
      try {
        await tursoLocal.sync()
      } catch (error) {
        console.error('Background sync failed:', error)
      }
    }, 60000) // Every minute
    
    console.log('📊 Local database initialized with sync')
  } catch (error) {
    console.error('Failed to initialize local database:', error)
  }
}
```

### 2. Edge-First Architecture

```typescript
// lib/turso-edge.ts
import { createClient } from '@libsql/client'

// Regional database setup
const REGIONS = {
  'us-east-1': process.env.TURSO_DATABASE_URL_IAD,
  'us-west-1': process.env.TURSO_DATABASE_URL_SJC,
  'eu-west-1': process.env.TURSO_DATABASE_URL_FRA,
  'ap-south-1': process.env.TURSO_DATABASE_URL_SIN,
} as const

type Region = keyof typeof REGIONS

export function getTursoClient(region?: Region) {
  // Auto-detect region or use default
  const detectedRegion = region || detectRegion()
  const url = REGIONS[detectedRegion] || process.env.TURSO_DATABASE_URL!
  
  return createClient({
    url,
    authToken: process.env.TURSO_AUTH_TOKEN!,
  })
}

function detectRegion(): Region {
  // Detect region from Vercel headers, Cloudflare, etc.
  const cfRegion = process.env.CF_RAY?.split('-')[1]
  const vercelRegion = process.env.VERCEL_REGION
  
  // Map to our regions
  if (vercelRegion?.startsWith('iad')) return 'us-east-1'
  if (vercelRegion?.startsWith('sfo')) return 'us-west-1'
  if (vercelRegion?.startsWith('fra')) return 'eu-west-1'
  if (cfRegion === 'SIN') return 'ap-south-1'
  
  return 'us-east-1' // Default
}

// Edge-optimized query wrapper
export async function edgeQuery<T = any>(
  query: string,
  params: any[] = [],
  region?: Region
): Promise<T[]> {
  const client = getTursoClient(region)
  
  try {
    const result = await client.execute({
      sql: query,
      args: params,
    })
    
    return result.rows.map(row => 
      Object.fromEntries(
        result.columns.map((col, i) => [col, row[i]])
      )
    ) as T[]
  } catch (error) {
    console.error('Edge query failed:', error)
    throw error
  }
}

// Read/write splitting for better performance
export class EdgeDatabase {
  private readClient: ReturnType<typeof createClient>
  private writeClient: ReturnType<typeof createClient>

  constructor(region?: Region) {
    // Use regional endpoint for reads
    this.readClient = getTursoClient(region)
    
    // Use primary region for writes
    this.writeClient = createClient({
      url: process.env.TURSO_DATABASE_URL!,
      authToken: process.env.TURSO_AUTH_TOKEN!,
    })
  }

  async read<T = any>(query: string, params: any[] = []): Promise<T[]> {
    const result = await this.readClient.execute({ sql: query, args: params })
    return result.rows.map(row => 
      Object.fromEntries(
        result.columns.map((col, i) => [col, row[i]])
      )
    ) as T[]
  }

  async write<T = any>(query: string, params: any[] = []): Promise<T[]> {
    const result = await this.writeClient.execute({ sql: query, args: params })
    return result.rows.map(row => 
      Object.fromEntries(
        result.columns.map((col, i) => [col, row[i]])
      )
    ) as T[]
  }

  async transaction<T>(
    fn: (tx: ReturnType<typeof createClient>) => Promise<T>
  ): Promise<T> {
    return fn(this.writeClient)
  }
}
```

### 3. Full-Text Search Setup

```sql
-- migrations/001_create_fts.sql
-- Create FTS5 virtual table for full-text search
CREATE VIRTUAL TABLE IF NOT EXISTS posts_fts USING fts5(
  title,
  content,
  excerpt,
  content=posts,
  content_rowid=rowid
);

-- Populate FTS index
INSERT INTO posts_fts(rowid, title, content, excerpt)
SELECT rowid, title, content, excerpt FROM posts
WHERE status = 'published';

-- Create triggers to maintain FTS index
CREATE TRIGGER posts_ai AFTER INSERT ON posts BEGIN
  INSERT INTO posts_fts(rowid, title, content, excerpt)
  VALUES (new.rowid, new.title, new.content, new.excerpt);
END;

CREATE TRIGGER posts_ad AFTER DELETE ON posts BEGIN
  INSERT INTO posts_fts(posts_fts, rowid, title, content, excerpt)
  VALUES('delete', old.rowid, old.title, old.content, old.excerpt);
END;

CREATE TRIGGER posts_au AFTER UPDATE ON posts BEGIN
  INSERT INTO posts_fts(posts_fts, rowid, title, content, excerpt)
  VALUES('delete', old.rowid, old.title, old.content, old.excerpt);
  INSERT INTO posts_fts(rowid, title, content, excerpt)
  VALUES (new.rowid, new.title, new.content, new.excerpt);
END;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_posts_status_published 
ON posts(status, published_at DESC) WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_posts_author_status 
ON posts(author_id, status, published_at DESC);

CREATE INDEX IF NOT EXISTS idx_comments_post_created 
ON comments(post_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_post_tags_post 
ON post_tags(post_id);

CREATE INDEX IF NOT EXISTS idx_post_tags_tag 
ON post_tags(tag_id);
```

## Database Branching

### 1. Development Workflow

```typescript
// scripts/turso-branch.ts
import { execSync } from 'child_process'

interface TursoBranch {
  name: string
  type: 'schema' | 'data'
  parent?: string
  url: string
}

class TursoBranchManager {
  private dbName: string

  constructor(dbName: string) {
    this.dbName = dbName
  }

  createBranch(branchName: string, fromBranch = 'main'): string {
    try {
      const command = `turso db create ${this.dbName}-${branchName} --from-db ${this.dbName}${fromBranch !== 'main' ? `-${fromBranch}` : ''}`
      execSync(command, { stdio: 'inherit' })
      
      const url = this.getDatabaseUrl(`${this.dbName}-${branchName}`)
      console.log(`✅ Created branch: ${branchName}`)
      console.log(`📝 URL: ${url}`)
      
      return url
    } catch (error) {
      console.error('❌ Failed to create branch:', error)
      throw error
    }
  }

  deleteBranch(branchName: string): void {
    try {
      const command = `turso db destroy ${this.dbName}-${branchName} --yes`
      execSync(command, { stdio: 'inherit' })
      console.log(`✅ Deleted branch: ${branchName}`)
    } catch (error) {
      console.error('❌ Failed to delete branch:', error)
      throw error
    }
  }

  listBranches(): string[] {
    try {
      const output = execSync('turso db list --json', { encoding: 'utf-8' })
      const databases = JSON.parse(output)
      
      return databases
        .filter((db: any) => db.Name.startsWith(`${this.dbName}-`))
        .map((db: any) => db.Name.replace(`${this.dbName}-`, ''))
    } catch (error) {
      console.error('❌ Failed to list branches:', error)
      return []
    }
  }

  private getDatabaseUrl(dbName: string): string {
    try {
      const output = execSync(`turso db show ${dbName} --json`, { encoding: 'utf-8' })
      const dbInfo = JSON.parse(output)
      return dbInfo.Hostname
    } catch (error) {
      console.error('❌ Failed to get database URL:', error)
      throw error
    }
  }

  createToken(dbName: string, expiration = 'none'): string {
    try {
      const output = execSync(
        `turso db tokens create ${dbName} --expiration ${expiration}`,
        { encoding: 'utf-8' }
      )
      return output.trim()
    } catch (error) {
      console.error('❌ Failed to create token:', error)
      throw error
    }
  }
}

// Usage functions
export async function createFeatureBranch(featureName: string) {
  const branchManager = new TursoBranchManager('my-app')
  
  try {
    const branchUrl = branchManager.createBranch(`feature-${featureName}`)
    const token = branchManager.createToken(`my-app-feature-${featureName}`)
    
    return {
      name: `feature-${featureName}`,
      url: `libsql://${branchUrl}`,
      token,
    }
  } catch (error) {
    console.error('Failed to create feature branch:', error)
    throw error
  }
}

export async function cleanupFeatureBranch(featureName: string) {
  const branchManager = new TursoBranchManager('my-app')
  branchManager.deleteBranch(`feature-${featureName}`)
}
```

### 2. CI/CD Integration

```yaml
# .github/workflows/turso-branch.yml
name: Turso Database Branch

on:
  pull_request:
    types: [opened, synchronize, closed]

jobs:
  create-branch:
    if: github.event.action == 'opened' || github.event.action == 'synchronize'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Turso CLI
        run: |
          curl -sSfL https://get.tur.so/install.sh | bash
          echo "$HOME/.turso/bin" >> $GITHUB_PATH
      
      - name: Create database branch
        env:
          TURSO_TOKEN: ${{ secrets.TURSO_TOKEN }}
        run: |
          turso auth token $TURSO_TOKEN
          
          BRANCH_NAME="pr-${{ github.event.number }}"
          DB_NAME="my-app-$BRANCH_NAME"
          
          # Create branch database
          turso db create $DB_NAME --from-db my-app
          
          # Create token
          TOKEN=$(turso db tokens create $DB_NAME --expiration 7d)
          
          # Get URL
          URL=$(turso db show $DB_NAME --url)
          
          # Set environment variables for next steps
          echo "TURSO_DATABASE_URL=$URL" >> $GITHUB_ENV
          echo "TURSO_AUTH_TOKEN=$TOKEN" >> $GITHUB_ENV
      
      - name: Run migrations
        run: |
          npm ci
          npm run db:migrate
      
      - name: Run tests
        run: npm test

  cleanup-branch:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - name: Delete database branch
        env:
          TURSO_TOKEN: ${{ secrets.TURSO_TOKEN }}
        run: |
          curl -sSfL https://get.tur.so/install.sh | bash
          echo "$HOME/.turso/bin" >> $GITHUB_PATH
          
          turso auth token $TURSO_TOKEN
          
          BRANCH_NAME="pr-${{ github.event.number }}"
          DB_NAME="my-app-$BRANCH_NAME"
          
          turso db destroy $DB_NAME --yes || echo "Branch database may not exist"
```

## Monitoring and Analytics

### 1. Performance Monitoring

```typescript
// lib/turso-monitoring.ts
interface QueryMetrics {
  query: string
  duration: number
  rowsAffected: number
  timestamp: Date
  success: boolean
  error?: string
}

class TursoMonitoring {
  private static metrics: QueryMetrics[] = []
  private static maxMetrics = 1000

  static async trackQuery<T>(
    client: any,
    query: string,
    params: any[] = []
  ): Promise<T> {
    const start = performance.now()
    const timestamp = new Date()
    let success = true
    let error: string | undefined
    let rowsAffected = 0

    try {
      const result = await client.execute({ sql: query, args: params })
      rowsAffected = result.rowsAffected || result.rows.length
      return result
    } catch (err) {
      success = false
      error = err instanceof Error ? err.message : 'Unknown error'
      throw err
    } finally {
      const duration = performance.now() - start
      
      this.addMetric({
        query: query.substring(0, 100),
        duration: Math.round(duration),
        rowsAffected,
        timestamp,
        success,
        error,
      })
    }
  }

  private static addMetric(metric: QueryMetrics) {
    this.metrics.push(metric)
    
    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics)
    }

    // Log slow queries
    if (metric.duration > 1000) {
      console.warn(`🐌 Slow query (${metric.duration}ms):`, metric.query)
    }
  }

  static getMetrics(since?: Date): QueryMetrics[] {
    const filtered = since 
      ? this.metrics.filter(m => m.timestamp >= since)
      : this.metrics

    return [...filtered]
  }

  static getSlowQueries(threshold = 100): QueryMetrics[] {
    return this.metrics.filter(m => m.duration > threshold)
  }

  static getQueryStats() {
    if (this.metrics.length === 0) {
      return {
        totalQueries: 0,
        averageDuration: 0,
        slowQueries: 0,
        failedQueries: 0,
        successRate: 0,
      }
    }

    const total = this.metrics.length
    const avgDuration = this.metrics.reduce((sum, m) => sum + m.duration, 0) / total
    const slowQueries = this.getSlowQueries().length
    const failedQueries = this.metrics.filter(m => !m.success).length
    const successRate = ((total - failedQueries) / total) * 100

    return {
      totalQueries: total,
      averageDuration: Math.round(avgDuration),
      slowQueries,
      failedQueries,
      successRate: Math.round(successRate),
    }
  }
}

// Enhanced client with monitoring
export function createMonitoredClient(config: any) {
  const client = createClient(config)
  
  return {
    ...client,
    execute: async (query: any) => {
      if (typeof query === 'string') {
        return TursoMonitoring.trackQuery(client, query)
      }
      return TursoMonitoring.trackQuery(client, query.sql, query.args)
    },
    getStats: () => TursoMonitoring.getQueryStats(),
    getMetrics: (since?: Date) => TursoMonitoring.getMetrics(since),
  }
}
```

## Best Practices Summary

### 1. Connection Management
- Use appropriate client configuration for your deployment model
- Implement connection retry logic for reliability
- Monitor connection health and performance

### 2. Performance Optimization
- Leverage edge deployment for global applications
- Use local databases with sync for development
- Implement proper indexing strategies
- Use FTS5 for full-text search capabilities

### 3. Development Workflow
- Use database branching for feature development
- Implement automated testing with ephemeral databases
- Set up proper CI/CD integration
- Clean up unused branches regularly

### 4. Data Management
- Use transactions for data consistency
- Implement proper schema migrations
- Use appropriate SQLite-specific features
- Consider read/write splitting for performance

### 5. Monitoring
- Track query performance and failures
- Monitor database health across regions
- Set up alerting for critical metrics
- Analyze slow queries and optimize

This comprehensive guide covers all aspects of using Turso effectively for edge-first, globally distributed applications with SQLite compatibility and modern development workflows.