# Prisma Best Practices

## Official Documentation
- **Prisma Documentation**: https://www.prisma.io/docs
- **Prisma Examples**: https://github.com/prisma/prisma-examples
- **Prisma Schema Reference**: https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference
- **Prisma Client Reference**: https://www.prisma.io/docs/reference/api-reference/prisma-client-reference

## Overview

Prisma is a modern database toolkit that provides a type-safe database client, migrations, and introspection for Node.js and TypeScript applications.

## Installation & Setup

```bash
# Install Prisma CLI and Client
npm install prisma @prisma/client

# Initialize Prisma
npx prisma init

# For Edge Runtime support
npm install @prisma/client-edge
npm install @prisma/extension-accelerate
```

## Schema Design Best Practices

### 1. Database Schema Structure

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
  // Enable preview features
  previewFeatures = ["relationJoins", "omitApi", "typedSql"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // Connection pooling for serverless
  relationMode = "prisma" // Use for MySQL with PlanetScale
}

// User model with proper indexing
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  username  String?  @unique
  name      String?
  avatar    String?
  role      Role     @default(USER)
  status    UserStatus @default(ACTIVE)
  
  // Audit fields
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  lastLoginAt DateTime?
  
  // Relations
  posts     Post[]
  comments  Comment[]
  likes     Like[]
  sessions  Session[]
  accounts  Account[]
  
  // Indexes for performance
  @@index([email])
  @@index([username])
  @@index([role])
  @@index([status])
  @@index([createdAt])
  @@map("users")
}

model Post {
  id          String   @id @default(cuid())
  title       String
  slug        String   @unique
  content     String?  @db.Text
  excerpt     String?
  publishedAt DateTime?
  status      PostStatus @default(DRAFT)
  
  // SEO fields
  metaTitle       String?
  metaDescription String?
  
  // Author relation
  authorId String
  author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade)
  
  // Category relation
  categoryId String?
  category   Category? @relation(fields: [categoryId], references: [id], onDelete: SetNull)
  
  // Tags many-to-many
  tags     PostTag[]
  comments Comment[]
  likes    Like[]
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  // Compound indexes
  @@index([authorId, status])
  @@index([categoryId, publishedAt])
  @@index([slug])
  @@index([status, publishedAt])
  @@map("posts")
}

model Category {
  id          String @id @default(cuid())
  name        String @unique
  slug        String @unique
  description String?
  color       String?
  
  posts Post[]
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@index([slug])
  @@map("categories")
}

model Tag {
  id          String @id @default(cuid())
  name        String @unique
  slug        String @unique
  description String?
  
  posts PostTag[]
  
  createdAt DateTime @default(now())
  
  @@index([slug])
  @@map("tags")
}

// Junction table for many-to-many
model PostTag {
  id String @id @default(cuid())
  
  postId String
  post   Post   @relation(fields: [postId], references: [id], onDelete: Cascade)
  
  tagId String
  tag   Tag    @relation(fields: [tagId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  
  @@unique([postId, tagId])
  @@index([postId])
  @@index([tagId])
  @@map("post_tags")
}

model Comment {
  id      String @id @default(cuid())
  content String @db.Text
  
  // Author relation
  authorId String
  author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade)
  
  // Post relation
  postId String
  post   Post   @relation(fields: [postId], references: [id], onDelete: Cascade)
  
  // Self-referencing for replies
  parentId String?
  parent   Comment?  @relation("CommentReplies", fields: [parentId], references: [id], onDelete: Cascade)
  replies  Comment[] @relation("CommentReplies")
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@index([postId, createdAt])
  @@index([authorId])
  @@index([parentId])
  @@map("comments")
}

model Like {
  id String @id @default(cuid())
  
  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  postId String
  post   Post   @relation(fields: [postId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  
  @@unique([userId, postId]) // Prevent duplicate likes
  @@index([postId])
  @@index([userId])
  @@map("likes")
}

// Session management for authentication
model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@index([userId])
  @@index([expires])
  @@map("sessions")
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String? @db.Text
  access_token      String? @db.Text
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String? @db.Text
  session_state     String?
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([provider, providerAccountId])
  @@index([userId])
  @@map("accounts")
}

// Enums
enum Role {
  USER
  MODERATOR
  ADMIN
}

enum UserStatus {
  ACTIVE
  INACTIVE
  SUSPENDED
  DELETED
}

enum PostStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}
```

### 2. Client Configuration

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    errorFormat: 'pretty',
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

// Middleware for logging
prisma.$use(async (params, next) => {
  const before = Date.now()
  const result = await next(params)
  const after = Date.now()
  
  if (process.env.NODE_ENV === 'development') {
    console.log(`Query ${params.model}.${params.action} took ${after - before}ms`)
  }
  
  return result
})

// Extension for soft delete
export const db = prisma.$extends({
  name: 'soft-delete',
  model: {
    user: {
      async findManyActive<T>(this: T, args?: Parameters<T['findMany']>[0]) {
        return (this as any).findMany({
          ...args,
          where: { ...args?.where, status: { not: 'DELETED' } },
        })
      },
      async softDelete<T>(this: T, where: Parameters<T['delete']>[0]['where']) {
        return (this as any).update({
          where,
          data: { status: 'DELETED' },
        })
      },
    },
  },
})

// Edge runtime client
// lib/prisma-edge.ts
import { PrismaClient } from '@prisma/client/edge'
import { withAccelerate } from '@prisma/extension-accelerate'

export const prismaEdge = new PrismaClient().$extends(withAccelerate())
```

## Query Optimization Patterns

### 1. Efficient Data Fetching

```typescript
// services/post-service.ts
import { db } from '@/lib/prisma'
import { Prisma } from '@prisma/client'

// Define reusable select objects
const POST_SELECT = {
  id: true,
  title: true,
  slug: true,
  excerpt: true,
  publishedAt: true,
  author: {
    select: {
      id: true,
      name: true,
      username: true,
      avatar: true,
    },
  },
  category: {
    select: {
      id: true,
      name: true,
      slug: true,
      color: true,
    },
  },
  _count: {
    select: {
      comments: true,
      likes: true,
    },
  },
} satisfies Prisma.PostSelect

const POST_WITH_CONTENT_SELECT = {
  ...POST_SELECT,
  content: true,
  metaTitle: true,
  metaDescription: true,
  tags: {
    select: {
      tag: {
        select: {
          id: true,
          name: true,
          slug: true,
        },
      },
    },
  },
} satisfies Prisma.PostSelect

export class PostService {
  // Paginated posts with proper indexing
  static async getPaginatedPosts({
    page = 1,
    limit = 10,
    categoryId,
    authorId,
    search,
    status = 'PUBLISHED',
  }: {
    page?: number
    limit?: number
    categoryId?: string
    authorId?: string
    search?: string
    status?: string
  }) {
    const skip = (page - 1) * limit
    
    // Build where clause
    const where: Prisma.PostWhereInput = {
      status: status as any,
      publishedAt: { lte: new Date() },
      ...(categoryId && { categoryId }),
      ...(authorId && { authorId }),
      ...(search && {
        OR: [
          { title: { contains: search, mode: 'insensitive' } },
          { excerpt: { contains: search, mode: 'insensitive' } },
          { content: { contains: search, mode: 'insensitive' } },
        ],
      }),
    }

    // Execute queries in parallel
    const [posts, total] = await Promise.all([
      db.post.findMany({
        where,
        select: POST_SELECT,
        orderBy: { publishedAt: 'desc' },
        skip,
        take: limit,
      }),
      db.post.count({ where }),
    ])

    return {
      posts,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: skip + limit < total,
        hasPrev: page > 1,
      },
    }
  }

  // Get single post with relations
  static async getPostBySlug(slug: string, userId?: string) {
    const post = await db.post.findUnique({
      where: { 
        slug,
        status: 'PUBLISHED',
        publishedAt: { lte: new Date() },
      },
      select: {
        ...POST_WITH_CONTENT_SELECT,
        comments: {
          select: {
            id: true,
            content: true,
            createdAt: true,
            author: {
              select: {
                id: true,
                name: true,
                username: true,
                avatar: true,
              },
            },
            replies: {
              select: {
                id: true,
                content: true,
                createdAt: true,
                author: {
                  select: {
                    id: true,
                    name: true,
                    username: true,
                    avatar: true,
                  },
                },
              },
              orderBy: { createdAt: 'asc' },
            },
            _count: {
              select: { replies: true },
            },
          },
          where: { parentId: null }, // Only top-level comments
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        ...(userId && {
          likes: {
            where: { userId },
            select: { id: true },
          },
        }),
      },
    })

    if (!post) return null

    // Get related posts
    const relatedPosts = await db.post.findMany({
      where: {
        id: { not: post.id },
        categoryId: post.category?.id,
        status: 'PUBLISHED',
        publishedAt: { lte: new Date() },
      },
      select: POST_SELECT,
      orderBy: { publishedAt: 'desc' },
      take: 3,
    })

    return {
      ...post,
      isLiked: userId ? post.likes?.length > 0 : false,
      relatedPosts,
    }
  }

  // Batch operations for performance
  static async createPostWithTags({
    title,
    content,
    excerpt,
    authorId,
    categoryId,
    tagNames,
    status = 'DRAFT',
  }: {
    title: string
    content: string
    excerpt?: string
    authorId: string
    categoryId?: string
    tagNames?: string[]
    status?: string
  }) {
    return db.$transaction(async (tx) => {
      // Create or find tags
      const tags = tagNames ? await Promise.all(
        tagNames.map(name =>
          tx.tag.upsert({
            where: { name },
            create: { 
              name, 
              slug: name.toLowerCase().replace(/\s+/g, '-') 
            },
            update: {},
          })
        )
      ) : []

      // Create post
      const post = await tx.post.create({
        data: {
          title,
          content,
          excerpt,
          slug: title.toLowerCase().replace(/\s+/g, '-'),
          status: status as any,
          authorId,
          categoryId,
          ...(status === 'PUBLISHED' && { publishedAt: new Date() }),
        },
      })

      // Connect tags
      if (tags.length > 0) {
        await tx.postTag.createMany({
          data: tags.map(tag => ({
            postId: post.id,
            tagId: tag.id,
          })),
        })
      }

      return post
    })
  }

  // Optimized search with full-text search
  static async searchPosts(query: string, limit = 10) {
    // Use database-specific full-text search
    return db.$queryRaw<any[]>`
      SELECT 
        p.id, p.title, p.slug, p.excerpt, p."publishedAt",
        u.name as "authorName", u.username as "authorUsername",
        c.name as "categoryName", c.slug as "categorySlug",
        ts_rank(
          setweight(to_tsvector('english', p.title), 'A') ||
          setweight(to_tsvector('english', coalesce(p.excerpt, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(p.content, '')), 'C'),
          plainto_tsquery('english', ${query})
        ) as rank
      FROM posts p
      LEFT JOIN users u ON p."authorId" = u.id
      LEFT JOIN categories c ON p."categoryId" = c.id
      WHERE 
        p.status = 'PUBLISHED' 
        AND p."publishedAt" <= NOW()
        AND (
          to_tsvector('english', p.title) @@ plainto_tsquery('english', ${query}) OR
          to_tsvector('english', coalesce(p.excerpt, '')) @@ plainto_tsquery('english', ${query}) OR
          to_tsvector('english', coalesce(p.content, '')) @@ plainto_tsquery('english', ${query})
        )
      ORDER BY rank DESC
      LIMIT ${limit}
    `
  }
}
```

### 2. Advanced Query Patterns

```typescript
// services/analytics-service.ts
export class AnalyticsService {
  // Aggregations and grouping
  static async getPostAnalytics(authorId?: string) {
    const where: Prisma.PostWhereInput = {
      ...(authorId && { authorId }),
      status: 'PUBLISHED',
    }

    const [
      totalPosts,
      totalViews,
      totalLikes,
      totalComments,
      monthlyStats,
      categoryStats,
    ] = await Promise.all([
      // Total posts
      db.post.count({ where }),
      
      // Total views (if you have a views table)
      db.postView.count({
        where: { post: where },
      }),
      
      // Total likes
      db.like.count({
        where: { post: where },
      }),
      
      // Total comments
      db.comment.count({
        where: { post: where },
      }),
      
      // Monthly stats for the last 12 months
      db.$queryRaw<any[]>`
        SELECT 
          DATE_TRUNC('month', p."publishedAt") as month,
          COUNT(p.id)::int as posts,
          COUNT(l.id)::int as likes,
          COUNT(c.id)::int as comments
        FROM posts p
        LEFT JOIN likes l ON p.id = l."postId"
        LEFT JOIN comments c ON p.id = c."postId"
        WHERE 
          p.status = 'PUBLISHED'
          ${authorId ? Prisma.sql`AND p."authorId" = ${authorId}` : Prisma.empty}
          AND p."publishedAt" >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '11 months')
        GROUP BY DATE_TRUNC('month', p."publishedAt")
        ORDER BY month DESC
      `,
      
      // Posts by category
      db.post.groupBy({
        by: ['categoryId'],
        where,
        _count: {
          id: true,
        },
        _avg: {
          _count: {
            likes: true,
            comments: true,
          },
        },
      }),
    ])

    return {
      totals: {
        posts: totalPosts,
        views: totalViews,
        likes: totalLikes,
        comments: totalComments,
      },
      monthlyStats,
      categoryStats,
    }
  }

  // Complex joins and subqueries
  static async getTopAuthors(limit = 10) {
    return db.user.findMany({
      select: {
        id: true,
        name: true,
        username: true,
        avatar: true,
        _count: {
          select: {
            posts: {
              where: {
                status: 'PUBLISHED',
                publishedAt: { lte: new Date() },
              },
            },
          },
        },
        posts: {
          select: {
            _count: {
              select: {
                likes: true,
                comments: true,
              },
            },
          },
          where: {
            status: 'PUBLISHED',
            publishedAt: { lte: new Date() },
          },
        },
      },
      orderBy: {
        posts: {
          _count: 'desc',
        },
      },
      take: limit,
    })
  }
}

// Repository pattern for complex business logic
export class UserRepository {
  static async createUserWithProfile(userData: {
    email: string
    name: string
    password: string
    profileData?: any
  }) {
    return db.$transaction(async (tx) => {
      // Create user
      const user = await tx.user.create({
        data: {
          email: userData.email,
          name: userData.name,
          // Don't store password directly - use a proper auth system
        },
      })

      // Create user profile
      await tx.userProfile.create({
        data: {
          userId: user.id,
          bio: userData.profileData?.bio,
          website: userData.profileData?.website,
          location: userData.profileData?.location,
        },
      })

      // Create default settings
      await tx.userSettings.create({
        data: {
          userId: user.id,
          emailNotifications: true,
          darkMode: false,
          language: 'en',
        },
      })

      return user
    })
  }

  static async getUserWithStats(id: string) {
    return db.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        username: true,
        email: true,
        avatar: true,
        createdAt: true,
        _count: {
          select: {
            posts: {
              where: { status: 'PUBLISHED' },
            },
            comments: true,
            likes: true,
          },
        },
        posts: {
          select: {
            id: true,
            title: true,
            slug: true,
            publishedAt: true,
            _count: {
              select: {
                likes: true,
                comments: true,
              },
            },
          },
          where: { status: 'PUBLISHED' },
          orderBy: { publishedAt: 'desc' },
          take: 5,
        },
      },
    })
  }
}
```

### 3. Performance Optimization

```typescript
// lib/prisma-cache.ts
import { db } from '@/lib/prisma'

// Redis caching layer
class PrismaCache {
  private static redis = new Redis(process.env.REDIS_URL!)
  
  static async withCache<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl: number = 300 // 5 minutes default
  ): Promise<T> {
    // Try to get from cache
    const cached = await this.redis.get(key)
    if (cached) {
      return JSON.parse(cached)
    }
    
    // Fetch from database
    const result = await fetcher()
    
    // Cache the result
    await this.redis.setex(key, ttl, JSON.stringify(result))
    
    return result
  }
  
  static async invalidate(pattern: string) {
    const keys = await this.redis.keys(pattern)
    if (keys.length > 0) {
      await this.redis.del(...keys)
    }
  }
}

// Usage in services
export class PostService {
  static async getCachedPopularPosts() {
    return PrismaCache.withCache(
      'popular-posts',
      async () => {
        return db.post.findMany({
          where: { status: 'PUBLISHED' },
          select: POST_SELECT,
          orderBy: {
            likes: { _count: 'desc' },
          },
          take: 10,
        })
      },
      600 // 10 minutes
    )
  }
  
  static async invalidatePostCache(postId: string) {
    await Promise.all([
      PrismaCache.invalidate('popular-posts'),
      PrismaCache.invalidate(`post:${postId}:*`),
      PrismaCache.invalidate('recent-posts'),
    ])
  }
}

// Connection pooling for serverless
// lib/prisma-pool.ts
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'
import { PrismaClient } from '@prisma/client'

const connectionString = process.env.DATABASE_URL

const pool = new Pool({ connectionString })
const adapter = new PrismaPg(pool)
export const prismaPooled = new PrismaClient({ adapter })

// Middleware for request timing
prismaPooled.$use(async (params, next) => {
  const start = Date.now()
  const result = await next(params)
  const end = Date.now()
  
  // Log slow queries
  if (end - start > 1000) {
    console.warn(`Slow query detected: ${params.model}.${params.action} took ${end - start}ms`)
  }
  
  return result
})
```

### 4. Migration Best Practices

```sql
-- migrations/001_initial_schema.sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create indexes for full-text search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_search 
ON posts USING gin(to_tsvector('english', title || ' ' || coalesce(excerpt, '') || ' ' || coalesce(content, '')));

-- Create partial indexes for better performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_published 
ON posts (published_at DESC) WHERE status = 'PUBLISHED';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_author_published 
ON posts (author_id, published_at DESC) WHERE status = 'PUBLISHED';

-- Create composite indexes for common queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_category_status_date 
ON posts (category_id, status, published_at DESC);
```

```typescript
// scripts/seed.ts
import { db } from '../lib/prisma'
import { faker } from '@faker-js/faker'

async function seedDatabase() {
  console.log('🌱 Starting database seed...')
  
  // Create categories
  const categories = await Promise.all(
    Array.from({ length: 5 }, () => 
      db.category.create({
        data: {
          name: faker.lorem.words(2),
          slug: faker.lorem.slug(),
          description: faker.lorem.paragraph(),
          color: faker.color.hex(),
        },
      })
    )
  )
  
  // Create users
  const users = await Promise.all(
    Array.from({ length: 10 }, () => 
      db.user.create({
        data: {
          email: faker.internet.email(),
          name: faker.person.fullName(),
          username: faker.internet.userName(),
          avatar: faker.image.avatar(),
        },
      })
    )
  )
  
  // Create posts with batch inserts for better performance
  const postData = Array.from({ length: 100 }, () => ({
    title: faker.lorem.sentence(),
    slug: faker.lorem.slug(),
    content: faker.lorem.paragraphs(5),
    excerpt: faker.lorem.paragraph(),
    status: faker.helpers.arrayElement(['DRAFT', 'PUBLISHED', 'ARCHIVED']),
    publishedAt: faker.date.past(),
    authorId: faker.helpers.arrayElement(users).id,
    categoryId: faker.helpers.arrayElement(categories).id,
  }))
  
  // Use createMany for better performance
  await db.post.createMany({
    data: postData,
    skipDuplicates: true,
  })
  
  console.log('✅ Database seeded successfully!')
}

seedDatabase()
  .catch(console.error)
  .finally(() => db.$disconnect())
```

## Testing Strategies

```typescript
// tests/setup.ts
import { PrismaClient } from '@prisma/client'
import { execSync } from 'child_process'
import { randomBytes } from 'crypto'

const generateDatabaseURL = () => {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL environment variable is not set')
  }
  
  const url = new URL(process.env.DATABASE_URL)
  const schema = `test_${randomBytes(8).toString('hex')}`
  url.searchParams.set('schema', schema)
  
  return { url: url.toString(), schema }
}

export const setupTestDatabase = async () => {
  const { url, schema } = generateDatabaseURL()
  process.env.DATABASE_URL = url
  
  execSync('npx prisma migrate deploy', { stdio: 'inherit' })
  
  const prisma = new PrismaClient()
  await prisma.$connect()
  
  return { prisma, schema }
}

export const cleanupTestDatabase = async (prisma: PrismaClient, schema: string) => {
  await prisma.$executeRaw`DROP SCHEMA IF EXISTS ${Prisma.raw(schema)} CASCADE`
  await prisma.$disconnect()
}

// tests/post.test.ts
import { describe, it, expect, beforeEach, afterAll } from 'vitest'
import { setupTestDatabase, cleanupTestDatabase } from './setup'
import { PostService } from '../services/post-service'

describe('PostService', () => {
  let prisma: PrismaClient
  let schema: string
  let testUser: any
  let testCategory: any
  
  beforeEach(async () => {
    ({ prisma, schema } = await setupTestDatabase())
    
    // Create test data
    testUser = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User',
        username: 'testuser',
      },
    })
    
    testCategory = await prisma.category.create({
      data: {
        name: 'Test Category',
        slug: 'test-category',
      },
    })
  })
  
  afterAll(async () => {
    await cleanupTestDatabase(prisma, schema)
  })
  
  it('should create post with tags', async () => {
    const post = await PostService.createPostWithTags({
      title: 'Test Post',
      content: 'Test content',
      excerpt: 'Test excerpt',
      authorId: testUser.id,
      categoryId: testCategory.id,
      tagNames: ['react', 'typescript'],
      status: 'PUBLISHED',
    })
    
    expect(post).toBeDefined()
    expect(post.title).toBe('Test Post')
    expect(post.slug).toBe('test-post')
    
    // Verify tags were created and connected
    const postWithTags = await prisma.post.findUnique({
      where: { id: post.id },
      include: {
        tags: {
          include: { tag: true },
        },
      },
    })
    
    expect(postWithTags?.tags).toHaveLength(2)
    expect(postWithTags?.tags.map(pt => pt.tag.name)).toEqual(
      expect.arrayContaining(['react', 'typescript'])
    )
  })
  
  it('should get paginated posts', async () => {
    // Create test posts
    await prisma.post.createMany({
      data: Array.from({ length: 15 }, (_, i) => ({
        title: `Test Post ${i + 1}`,
        slug: `test-post-${i + 1}`,
        content: `Content for post ${i + 1}`,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        authorId: testUser.id,
        categoryId: testCategory.id,
      })),
    })
    
    const result = await PostService.getPaginatedPosts({
      page: 1,
      limit: 10,
    })
    
    expect(result.posts).toHaveLength(10)
    expect(result.pagination.total).toBe(15)
    expect(result.pagination.totalPages).toBe(2)
    expect(result.pagination.hasNext).toBe(true)
    expect(result.pagination.hasPrev).toBe(false)
  })
})
```

## Production Best Practices

### 1. Security
- Use environment variables for database connections
- Implement row-level security where applicable
- Audit sensitive operations with middleware
- Use prepared statements (Prisma handles this automatically)

### 2. Performance
- Index frequently queried columns
- Use connection pooling for serverless environments
- Implement caching for read-heavy workloads
- Monitor query performance and optimize slow queries

### 3. Monitoring
- Log slow queries and errors
- Monitor database connections and performance
- Set up alerts for critical database metrics
- Use Prisma's built-in metrics

### 4. Maintenance
- Regular database backups
- Monitor migration health
- Keep Prisma and dependencies updated
- Use proper error handling and recovery

This comprehensive guide covers all aspects of using Prisma effectively in production applications with proper performance, security, and maintainability practices.