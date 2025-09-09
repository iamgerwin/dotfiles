# Neon Database Best Practices

## Official Documentation
- **Neon Documentation**: https://neon.tech/docs
- **Neon API Reference**: https://neon.tech/docs/reference/api-reference
- **Neon CLI Reference**: https://neon.tech/docs/reference/neon-cli
- **Neon GitHub**: https://github.com/neondatabase

## Overview

Neon is a fully managed serverless PostgreSQL platform that separates compute from storage, offering features like instant branching, autoscaling, and scale-to-zero capabilities perfect for modern applications.

## Getting Started

### 1. Installation & Setup

```bash
# Install Neon CLI
npm install -g @neondatabase/cli

# Login to Neon
neon auth

# Create a new project
neon projects create --name "my-project" --region us-east-1

# Create a database
neon databases create --name "production" --project-id <project-id>

# Create a branch
neon branches create --name "development" --project-id <project-id>
```

### 2. Environment Configuration

```bash
# .env.local
# Main database (production)
DATABASE_URL="postgresql://username:password@ep-xxx.us-east-1.aws.neon.tech/dbname?sslmode=require"

# Development branch
DATABASE_URL_DEV="postgresql://username:password@ep-xxx.us-east-1.aws.neon.tech/dbname?sslmode=require"

# Connection pooling (recommended for serverless)
DATABASE_URL_POOLED="postgresql://username:password@ep-xxx-pooler.us-east-1.aws.neon.tech/dbname?sslmode=require"

# Neon API key for management operations
NEON_API_KEY="your-api-key"
NEON_PROJECT_ID="your-project-id"
```

## Connection Patterns

### 1. Direct Connection with Prisma

```typescript
// lib/neon-prisma.ts
import { PrismaClient } from '@prisma/client'

// Development vs Production connection
const getDatabaseUrl = () => {
  if (process.env.NODE_ENV === 'production') {
    return process.env.DATABASE_URL_POOLED || process.env.DATABASE_URL
  }
  return process.env.DATABASE_URL_DEV || process.env.DATABASE_URL
}

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    datasources: {
      db: {
        url: getDatabaseUrl(),
      },
    },
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

// Graceful shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect()
})
```

### 2. Connection Pooling for Serverless

```typescript
// lib/neon-pool.ts
import { Pool, neonConfig } from '@neondatabase/serverless'
import { PrismaNeon } from '@prisma/adapter-neon'
import { PrismaClient } from '@prisma/client'
import ws from 'ws'

// Enable WebSocket support for local development
neonConfig.webSocketConstructor = ws

const connectionString = process.env.DATABASE_URL_POOLED

const pool = new Pool({ connectionString })
const adapter = new PrismaNeon(pool)
export const prisma = new PrismaClient({ adapter })

// Connection health check
export async function checkDatabaseHealth() {
  try {
    await prisma.$queryRaw`SELECT 1`
    return { status: 'healthy', timestamp: new Date().toISOString() }
  } catch (error) {
    console.error('Database health check failed:', error)
    return { status: 'unhealthy', error: error.message, timestamp: new Date().toISOString() }
  }
}
```

### 3. Edge Runtime Support

```typescript
// lib/neon-edge.ts
import { neon } from '@neondatabase/serverless'

const sql = neon(process.env.DATABASE_URL!)

// Edge-compatible query function
export async function queryDatabase<T = any>(
  query: string,
  params: any[] = []
): Promise<T[]> {
  try {
    const result = await sql(query, params)
    return result as T[]
  } catch (error) {
    console.error('Database query failed:', error)
    throw new Error(`Database query failed: ${error.message}`)
  }
}

// Example usage in Edge Runtime
export async function getUsers() {
  return queryDatabase<{
    id: string
    name: string
    email: string
    created_at: string
  }>('SELECT id, name, email, created_at FROM users WHERE status = $1', ['active'])
}

export async function getUserById(id: string) {
  const users = await queryDatabase(
    'SELECT * FROM users WHERE id = $1 LIMIT 1',
    [id]
  )
  return users[0] || null
}
```

## Branching Strategies

### 1. Development Workflow

```typescript
// scripts/neon-branch.ts
import { neon } from '@neondatabase/serverless'

interface NeonBranch {
  id: string
  name: string
  parent_id: string
  created_at: string
  updated_at: string
  primary: boolean
  current_state: 'init' | 'ready'
  endpoint: {
    host: string
    id: string
    proxy_host: string
  }
}

class NeonBranchManager {
  private apiKey: string
  private projectId: string
  private baseUrl = 'https://console.neon.tech/api/v2'

  constructor(apiKey: string, projectId: string) {
    this.apiKey = apiKey
    this.projectId = projectId
  }

  async createBranch(name: string, parentBranchId?: string): Promise<NeonBranch> {
    const response = await fetch(
      `${this.baseUrl}/projects/${this.projectId}/branches`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          branch: {
            name,
            parent_id: parentBranchId,
          },
        }),
      }
    )

    if (!response.ok) {
      throw new Error(`Failed to create branch: ${response.statusText}`)
    }

    const data = await response.json()
    return data.branch
  }

  async deleteBranch(branchId: string): Promise<void> {
    const response = await fetch(
      `${this.baseUrl}/projects/${this.projectId}/branches/${branchId}`,
      {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      }
    )

    if (!response.ok) {
      throw new Error(`Failed to delete branch: ${response.statusText}`)
    }
  }

  async listBranches(): Promise<NeonBranch[]> {
    const response = await fetch(
      `${this.baseUrl}/projects/${this.projectId}/branches`,
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      }
    )

    if (!response.ok) {
      throw new Error(`Failed to list branches: ${response.statusText}`)
    }

    const data = await response.json()
    return data.branches
  }

  async createFeatureBranch(featureName: string): Promise<{
    branch: NeonBranch
    connectionString: string
  }> {
    const branch = await this.createBranch(`feature/${featureName}`)
    
    // Wait for branch to be ready
    await this.waitForBranch(branch.id)
    
    const connectionString = this.buildConnectionString(branch)
    
    return { branch, connectionString }
  }

  private async waitForBranch(branchId: string, timeout = 60000): Promise<void> {
    const startTime = Date.now()
    
    while (Date.now() - startTime < timeout) {
      const branches = await this.listBranches()
      const branch = branches.find(b => b.id === branchId)
      
      if (branch?.current_state === 'ready') {
        return
      }
      
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
    
    throw new Error(`Branch ${branchId} did not become ready within ${timeout}ms`)
  }

  private buildConnectionString(branch: NeonBranch): string {
    const { host } = branch.endpoint
    const dbname = process.env.NEON_DATABASE || 'neondb'
    const username = process.env.NEON_USERNAME || 'neondb_owner'
    const password = process.env.NEON_PASSWORD || ''
    
    return `postgresql://${username}:${password}@${host}/${dbname}?sslmode=require`
  }
}

// Usage example
export async function createDevelopmentBranch(featureName: string) {
  const branchManager = new NeonBranchManager(
    process.env.NEON_API_KEY!,
    process.env.NEON_PROJECT_ID!
  )
  
  try {
    const { branch, connectionString } = await branchManager.createFeatureBranch(featureName)
    
    console.log(`✅ Created branch: ${branch.name}`)
    console.log(`📝 Connection string: ${connectionString}`)
    
    return { branch, connectionString }
  } catch (error) {
    console.error('❌ Failed to create development branch:', error)
    throw error
  }
}
```

### 2. GitHub Actions Integration

```yaml
# .github/workflows/pr-database.yml
name: PR Database Branch

on:
  pull_request:
    types: [opened, synchronize]
  pull_request:
    types: [closed]

jobs:
  create-branch:
    if: github.event.action == 'opened' || github.event.action == 'synchronize'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Neon CLI
        run: npm install -g @neondatabase/cli
      
      - name: Create database branch
        env:
          NEON_API_KEY: ${{ secrets.NEON_API_KEY }}
          NEON_PROJECT_ID: ${{ secrets.NEON_PROJECT_ID }}
        run: |
          BRANCH_NAME="pr-${{ github.event.number }}"
          
          # Create branch
          neon branches create \
            --name "$BRANCH_NAME" \
            --project-id "$NEON_PROJECT_ID"
          
          # Get connection string
          CONNECTION_STRING=$(neon connection-string \
            --branch "$BRANCH_NAME" \
            --project-id "$NEON_PROJECT_ID" \
            --pooled)
          
          # Set as environment variable for next steps
          echo "DATABASE_URL=$CONNECTION_STRING" >> $GITHUB_ENV
      
      - name: Run migrations
        env:
          DATABASE_URL: ${{ env.DATABASE_URL }}
        run: |
          npm install
          npx prisma migrate deploy
          npx prisma db seed
      
      - name: Run tests
        env:
          DATABASE_URL: ${{ env.DATABASE_URL }}
        run: npm test

  cleanup-branch:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - name: Delete database branch
        env:
          NEON_API_KEY: ${{ secrets.NEON_API_KEY }}
          NEON_PROJECT_ID: ${{ secrets.NEON_PROJECT_ID }}
        run: |
          BRANCH_NAME="pr-${{ github.event.number }}"
          
          # Delete branch
          neon branches delete \
            --name "$BRANCH_NAME" \
            --project-id "$NEON_PROJECT_ID" \
            --force
```

## Performance Optimization

### 1. Connection Management

```typescript
// lib/neon-connection-manager.ts
import { Pool } from '@neondatabase/serverless'

class ConnectionManager {
  private static instance: ConnectionManager
  private pools: Map<string, Pool> = new Map()

  static getInstance(): ConnectionManager {
    if (!ConnectionManager.instance) {
      ConnectionManager.instance = new ConnectionManager()
    }
    return ConnectionManager.instance
  }

  getPool(connectionString: string, config?: any): Pool {
    if (!this.pools.has(connectionString)) {
      const pool = new Pool({
        connectionString,
        max: config?.maxConnections || 10,
        idleTimeoutMillis: config?.idleTimeout || 30000,
        connectionTimeoutMillis: config?.connectionTimeout || 10000,
      })
      
      this.pools.set(connectionString, pool)
    }
    
    return this.pools.get(connectionString)!
  }

  async closeAll(): Promise<void> {
    const closePromises = Array.from(this.pools.values()).map(pool => pool.end())
    await Promise.all(closePromises)
    this.pools.clear()
  }
}

export const connectionManager = ConnectionManager.getInstance()

// Usage in serverless functions
export async function withDatabase<T>(
  operation: (client: any) => Promise<T>,
  connectionString?: string
): Promise<T> {
  const pool = connectionManager.getPool(
    connectionString || process.env.DATABASE_URL_POOLED!
  )
  
  const client = await pool.connect()
  
  try {
    return await operation(client)
  } finally {
    client.release()
  }
}
```

### 2. Query Optimization for Serverless

```typescript
// lib/neon-queries.ts
import { neon } from '@neondatabase/serverless'

const sql = neon(process.env.DATABASE_URL!)

// Optimized queries with proper indexing
export class NeonQueries {
  // Batch operations for better performance
  static async batchInsert<T>(
    table: string,
    records: T[],
    batchSize = 1000
  ): Promise<void> {
    for (let i = 0; i < records.length; i += batchSize) {
      const batch = records.slice(i, i + batchSize)
      
      if (batch.length === 0) continue
      
      // Build dynamic insert query
      const columns = Object.keys(batch[0] as any)
      const values = batch.map((record, index) =>
        `(${columns.map((_, colIndex) => `$${index * columns.length + colIndex + 1}`).join(', ')})`
      ).join(', ')
      
      const flatValues = batch.flatMap(record => 
        columns.map(col => (record as any)[col])
      )
      
      await sql(`
        INSERT INTO ${table} (${columns.join(', ')})
        VALUES ${values}
        ON CONFLICT DO NOTHING
      `, flatValues)
    }
  }

  // Pagination with cursor-based approach
  static async getPaginatedResults<T = any>({
    table,
    columns = '*',
    where = '',
    orderBy = 'created_at DESC',
    limit = 20,
    cursor,
    cursorColumn = 'created_at',
  }: {
    table: string
    columns?: string
    where?: string
    orderBy?: string
    limit?: number
    cursor?: string
    cursorColumn?: string
  }): Promise<{
    data: T[]
    nextCursor?: string
    hasMore: boolean
  }> {
    let query = `SELECT ${columns} FROM ${table}`
    const params: any[] = []
    
    // Build WHERE clause
    const conditions: string[] = []
    if (where) conditions.push(where)
    if (cursor) {
      conditions.push(`${cursorColumn} < $${params.length + 1}`)
      params.push(cursor)
    }
    
    if (conditions.length > 0) {
      query += ` WHERE ${conditions.join(' AND ')}`
    }
    
    query += ` ORDER BY ${orderBy} LIMIT $${params.length + 1}`
    params.push(limit + 1) // Get one extra to check if there are more
    
    const results = await sql(query, params) as T[]
    
    const hasMore = results.length > limit
    if (hasMore) results.pop() // Remove the extra record
    
    const nextCursor = results.length > 0 
      ? (results[results.length - 1] as any)[cursorColumn]
      : undefined
    
    return {
      data: results,
      nextCursor,
      hasMore,
    }
  }

  // Full-text search optimized for PostgreSQL
  static async searchContent(
    query: string,
    tables: string[] = ['posts'],
    limit = 10
  ): Promise<any[]> {
    const searchQuery = `
      SELECT 
        id,
        title,
        excerpt,
        ts_rank(search_vector, plainto_tsquery('english', $1)) as rank,
        ts_headline('english', content, plainto_tsquery('english', $1)) as highlight
      FROM posts
      WHERE search_vector @@ plainto_tsquery('english', $1)
      ORDER BY rank DESC
      LIMIT $2
    `
    
    return sql(searchQuery, [query, limit])
  }

  // Aggregation queries with proper grouping
  static async getAnalytics(
    dateRange: { start: Date; end: Date },
    groupBy: 'day' | 'week' | 'month' = 'day'
  ) {
    const dateFormat = {
      day: 'YYYY-MM-DD',
      week: 'YYYY-"W"WW',
      month: 'YYYY-MM',
    }[groupBy]
    
    return sql(`
      WITH date_series AS (
        SELECT generate_series(
          $1::date,
          $2::date,
          '1 ${groupBy}'::interval
        )::date as date
      ),
      analytics AS (
        SELECT
          date_trunc('${groupBy}', created_at)::date as period,
          COUNT(*) as total_posts,
          COUNT(DISTINCT author_id) as unique_authors,
          AVG(view_count) as avg_views
        FROM posts
        WHERE created_at BETWEEN $1 AND $2
          AND status = 'published'
        GROUP BY date_trunc('${groupBy}', created_at)
      )
      SELECT
        ds.date,
        COALESCE(a.total_posts, 0) as total_posts,
        COALESCE(a.unique_authors, 0) as unique_authors,
        COALESCE(a.avg_views, 0) as avg_views
      FROM date_series ds
      LEFT JOIN analytics a ON ds.date = a.period
      ORDER BY ds.date
    `, [dateRange.start, dateRange.end])
  }
}
```

### 3. Caching Strategies

```typescript
// lib/neon-cache.ts
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})

export class NeonCache {
  static async withCache<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl: number = 300,
    options?: {
      staleWhileRevalidate?: number
      tags?: string[]
    }
  ): Promise<T> {
    try {
      // Try to get from cache
      const cached = await redis.get(key)
      
      if (cached !== null) {
        // If we have stale-while-revalidate, refresh in background
        if (options?.staleWhileRevalidate) {
          const cacheAge = await redis.ttl(key)
          if (cacheAge > 0 && cacheAge < options.staleWhileRevalidate) {
            // Refresh in background
            setImmediate(async () => {
              try {
                const fresh = await fetcher()
                await redis.setex(key, ttl, JSON.stringify(fresh))
              } catch (error) {
                console.error('Background refresh failed:', error)
              }
            })
          }
        }
        
        return JSON.parse(cached as string)
      }
    } catch (error) {
      console.error('Cache read error:', error)
    }
    
    // Fetch from database
    const result = await fetcher()
    
    // Cache the result
    try {
      await redis.setex(key, ttl, JSON.stringify(result))
      
      // Add to tag sets for invalidation
      if (options?.tags) {
        await Promise.all(
          options.tags.map(tag =>
            redis.sadd(`tag:${tag}`, key)
          )
        )
      }
    } catch (error) {
      console.error('Cache write error:', error)
    }
    
    return result
  }

  static async invalidateByTag(tag: string): Promise<void> {
    try {
      const keys = await redis.smembers(`tag:${tag}`)
      if (keys.length > 0) {
        await Promise.all([
          redis.del(...keys),
          redis.del(`tag:${tag}`),
        ])
      }
    } catch (error) {
      console.error('Cache invalidation error:', error)
    }
  }

  static async invalidate(pattern: string): Promise<void> {
    try {
      // Note: This is inefficient for large key sets
      // Consider using Redis modules or other approaches in production
      const keys = await redis.keys(pattern)
      if (keys.length > 0) {
        await redis.del(...keys)
      }
    } catch (error) {
      console.error('Cache pattern invalidation error:', error)
    }
  }
}

// Usage in API routes
export async function getCachedPosts(page = 1, limit = 10) {
  return NeonCache.withCache(
    `posts:page:${page}:limit:${limit}`,
    () => NeonQueries.getPaginatedResults({
      table: 'posts',
      where: "status = 'published'",
      limit,
      cursor: page > 1 ? String((page - 1) * limit) : undefined,
    }),
    300, // 5 minutes
    {
      staleWhileRevalidate: 60, // Refresh if cache is older than 1 minute
      tags: ['posts'],
    }
  )
}
```

## Monitoring and Observability

### 1. Performance Monitoring

```typescript
// lib/neon-monitoring.ts
interface QueryMetrics {
  query: string
  duration: number
  timestamp: Date
  success: boolean
  error?: string
}

class NeonMonitoring {
  private static metrics: QueryMetrics[] = []
  private static maxMetrics = 1000

  static async trackQuery<T>(
    query: string,
    operation: () => Promise<T>
  ): Promise<T> {
    const start = Date.now()
    const timestamp = new Date()
    let success = true
    let error: string | undefined

    try {
      const result = await operation()
      return result
    } catch (err) {
      success = false
      error = err instanceof Error ? err.message : 'Unknown error'
      throw err
    } finally {
      const duration = Date.now() - start
      
      this.addMetric({
        query: query.substring(0, 100), // Truncate long queries
        duration,
        timestamp,
        success,
        error,
      })
      
      // Log slow queries
      if (duration > 1000) {
        console.warn(`Slow query detected (${duration}ms):`, query.substring(0, 200))
      }
    }
  }

  private static addMetric(metric: QueryMetrics) {
    this.metrics.push(metric)
    
    // Keep only recent metrics
    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics)
    }
  }

  static getMetrics(): QueryMetrics[] {
    return [...this.metrics]
  }

  static getSlowQueries(threshold = 1000): QueryMetrics[] {
    return this.metrics.filter(m => m.duration > threshold)
  }

  static getFailedQueries(): QueryMetrics[] {
    return this.metrics.filter(m => !m.success)
  }

  static getAverageQueryTime(): number {
    if (this.metrics.length === 0) return 0
    const total = this.metrics.reduce((sum, m) => sum + m.duration, 0)
    return total / this.metrics.length
  }
}

// Enhanced query wrapper with monitoring
export async function monitoredQuery<T>(
  query: string,
  params: any[] = []
): Promise<T> {
  const sql = neon(process.env.DATABASE_URL!)
  
  return NeonMonitoring.trackQuery(query, async () => {
    return sql(query, params) as Promise<T>
  })
}

// Health check endpoint
export async function getDatabaseHealth() {
  try {
    const start = Date.now()
    await monitoredQuery('SELECT 1')
    const responseTime = Date.now() - start
    
    const metrics = NeonMonitoring.getMetrics()
    const recentMetrics = metrics.filter(
      m => Date.now() - m.timestamp.getTime() < 60000 // Last minute
    )
    
    const failureRate = recentMetrics.length > 0
      ? recentMetrics.filter(m => !m.success).length / recentMetrics.length
      : 0
    
    return {
      status: 'healthy',
      responseTime,
      averageQueryTime: NeonMonitoring.getAverageQueryTime(),
      slowQueries: NeonMonitoring.getSlowQueries().length,
      failedQueries: NeonMonitoring.getFailedQueries().length,
      failureRate: Math.round(failureRate * 100),
      timestamp: new Date().toISOString(),
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

## Best Practices Summary

### 1. Connection Management
- Use connection pooling for serverless environments
- Implement proper connection lifecycle management
- Monitor connection usage and performance

### 2. Branching Strategy
- Create feature branches for development
- Use ephemeral branches for testing
- Implement automated cleanup for unused branches

### 3. Performance Optimization
- Implement proper indexing strategies
- Use cursor-based pagination for large datasets
- Cache frequently accessed data
- Monitor and optimize slow queries

### 4. Cost Management
- Use autoscaling and scale-to-zero features
- Monitor compute usage and optimize accordingly
- Implement proper caching to reduce database load
- Clean up unused branches and endpoints

### 5. Security
- Use connection pooling endpoints for better security
- Implement proper SSL configuration
- Use environment variables for credentials
- Audit database access and operations

### 6. Monitoring
- Track query performance and failures
- Set up alerts for critical metrics
- Monitor branch and compute usage
- Implement health checks

This comprehensive guide covers all aspects of using Neon effectively for modern serverless applications with proper performance, cost optimization, and reliability practices.