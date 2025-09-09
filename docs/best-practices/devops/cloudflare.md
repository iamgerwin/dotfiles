# Cloudflare Platform Best Practices

Comprehensive guide for building scalable, performant applications using Cloudflare's edge computing platform: Workers, Pages, D1, R2, and the full developer ecosystem.

## 📚 Official Documentation
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Cloudflare Pages](https://developers.cloudflare.com/pages/)
- [Cloudflare D1](https://developers.cloudflare.com/d1/)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)

## 🏗️ Project Setup

### Initial Setup & Configuration
```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Create new Workers project
npm create cloudflare@latest my-app
cd my-app

# Initialize existing project
wrangler init my-worker
```

### Project Structure
```
my-cloudflare-app/
├── src/
│   ├── index.ts              # Main Worker entry point
│   ├── handlers/             # Route handlers
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   └── uploads.ts
│   ├── middleware/           # Custom middleware
│   │   ├── auth.ts
│   │   ├── cors.ts
│   │   └── rate-limit.ts
│   ├── utils/                # Utility functions
│   │   ├── database.ts       # D1 utilities
│   │   ├── storage.ts        # R2 utilities
│   │   └── validation.ts     # Input validation
│   └── types/                # TypeScript definitions
├── migrations/               # D1 database migrations
│   ├── 0001_initial.sql
│   └── 0002_add_users.sql
├── public/                   # Static assets (Pages)
├── functions/               # Pages Functions
│   └── api/
├── schema.sql              # Database schema
├── wrangler.toml           # Wrangler configuration
└── package.json
```

## 🎯 Cloudflare Workers Best Practices

### 1. Worker Architecture & Entry Point

```typescript
// src/index.ts
import { Router } from 'itty-router'
import { corsMiddleware } from './middleware/cors'
import { authMiddleware } from './middleware/auth'
import { rateLimitMiddleware } from './middleware/rate-limit'
import { handleAPI } from './handlers/api'
import { handleAuth } from './handlers/auth'
import { handleUploads } from './handlers/uploads'

export interface Env {
  // Bindings
  DB: D1Database
  STORAGE: R2Bucket
  KV: KVNamespace
  
  // Environment variables
  JWT_SECRET: string
  API_KEY: string
  ENVIRONMENT: 'development' | 'staging' | 'production'
  
  // Rate limiting
  RATE_LIMITER: DurableObjectNamespace
}

const router = Router()

// Global middleware
router.all('*', corsMiddleware)

// Public routes
router.post('/auth/login', handleAuth)
router.post('/auth/register', handleAuth)

// Protected routes
router.all('/api/*', authMiddleware)
router.get('/api/users', handleAPI)
router.post('/api/users', handleAPI)
router.get('/api/users/:id', handleAPI)

// File upload routes
router.all('/uploads/*', authMiddleware, rateLimitMiddleware)
router.post('/uploads', handleUploads)
router.get('/uploads/:key', handleUploads)

// Health check
router.get('/health', () => {
  return new Response(JSON.stringify({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  }), {
    headers: { 'Content-Type': 'application/json' }
  })
})

// 404 handler
router.all('*', () => new Response('Not Found', { status: 404 }))

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    try {
      return await router.handle(request, env, ctx)
    } catch (error) {
      console.error('Worker error:', error)
      
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: env.ENVIRONMENT === 'development' ? error.message : 'Something went wrong'
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      })
    }
  }
}
```

### 2. Middleware Patterns

```typescript
// middleware/cors.ts
export const corsMiddleware = async (request: Request) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  }

  // Handle preflight
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  // Add CORS headers to response
  return (response: Response) => {
    const newResponse = new Response(response.body, response)
    Object.entries(corsHeaders).forEach(([key, value]) => {
      newResponse.headers.set(key, value)
    })
    return newResponse
  }
}

// middleware/auth.ts
import { verify } from '@tsndr/cloudflare-worker-jwt'

export const authMiddleware = async (request: Request, env: Env) => {
  const authorization = request.headers.get('Authorization')
  
  if (!authorization || !authorization.startsWith('Bearer ')) {
    return new Response(JSON.stringify({ error: 'Missing or invalid authorization header' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  const token = authorization.substring(7)
  
  try {
    const isValid = await verify(token, env.JWT_SECRET)
    
    if (!isValid) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      })
    }
    
    // Decode token and attach user info to request
    const payload = JSON.parse(atob(token.split('.')[1]))
    request.user = payload
    
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Token verification failed' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    })
  }
}

// middleware/rate-limit.ts
export const rateLimitMiddleware = async (request: Request, env: Env) => {
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown'
  const key = `rate_limit:${clientIP}`
  
  try {
    const current = await env.KV.get(key)
    const requests = current ? parseInt(current) : 0
    const limit = 100 // requests per minute
    
    if (requests >= limit) {
      return new Response(JSON.stringify({
        error: 'Rate limit exceeded',
        limit,
        reset: 60
      }), {
        status: 429,
        headers: {
          'Content-Type': 'application/json',
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': (Date.now() + 60000).toString()
        }
      })
    }
    
    // Increment counter
    await env.KV.put(key, (requests + 1).toString(), { expirationTtl: 60 })
    
    // Add rate limit headers to response
    return (response: Response) => {
      const newResponse = new Response(response.body, response)
      newResponse.headers.set('X-RateLimit-Limit', limit.toString())
      newResponse.headers.set('X-RateLimit-Remaining', (limit - requests - 1).toString())
      return newResponse
    }
    
  } catch (error) {
    console.error('Rate limiting error:', error)
    // Continue on error (fail open)
  }
}
```

### 3. D1 Database Integration

```typescript
// utils/database.ts
export class DatabaseService {
  constructor(private db: D1Database) {}

  async getUsers(limit = 50, offset = 0) {
    try {
      const { results } = await this.db.prepare(`
        SELECT id, email, name, created_at, updated_at 
        FROM users 
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
      `).bind(limit, offset).all()
      
      return results
    } catch (error) {
      console.error('Database error:', error)
      throw new Error('Failed to fetch users')
    }
  }

  async getUserById(id: string) {
    try {
      const user = await this.db.prepare(`
        SELECT id, email, name, created_at, updated_at 
        FROM users 
        WHERE id = ?
      `).bind(id).first()
      
      if (!user) {
        throw new Error('User not found')
      }
      
      return user
    } catch (error) {
      console.error('Database error:', error)
      throw new Error('Failed to fetch user')
    }
  }

  async createUser(userData: { email: string; name: string; passwordHash: string }) {
    try {
      const { success, meta } = await this.db.prepare(`
        INSERT INTO users (id, email, name, password_hash, created_at, updated_at)
        VALUES (?, ?, ?, ?, datetime('now'), datetime('now'))
      `).bind(
        crypto.randomUUID(),
        userData.email,
        userData.name,
        userData.passwordHash
      ).run()

      if (!success) {
        throw new Error('Failed to create user')
      }

      return { id: meta.last_row_id, ...userData }
    } catch (error) {
      console.error('Database error:', error)
      if (error.message.includes('UNIQUE constraint failed')) {
        throw new Error('Email already exists')
      }
      throw new Error('Failed to create user')
    }
  }

  async updateUser(id: string, updates: Partial<{ email: string; name: string }>) {
    try {
      const setClause = Object.keys(updates)
        .map(key => `${key} = ?`)
        .join(', ')
      
      const values = [...Object.values(updates), id]

      const { success } = await this.db.prepare(`
        UPDATE users 
        SET ${setClause}, updated_at = datetime('now')
        WHERE id = ?
      `).bind(...values).run()

      if (!success) {
        throw new Error('Failed to update user')
      }

      return await this.getUserById(id)
    } catch (error) {
      console.error('Database error:', error)
      throw new Error('Failed to update user')
    }
  }

  async deleteUser(id: string) {
    try {
      const { success } = await this.db.prepare(`
        DELETE FROM users WHERE id = ?
      `).bind(id).run()

      if (!success) {
        throw new Error('Failed to delete user')
      }

      return { success: true }
    } catch (error) {
      console.error('Database error:', error)
      throw new Error('Failed to delete user')
    }
  }

  // Transaction example
  async transferUserData(fromUserId: string, toUserId: string) {
    try {
      const stmt = this.db.batch([
        this.db.prepare(`
          UPDATE posts SET user_id = ? WHERE user_id = ?
        `).bind(toUserId, fromUserId),
        
        this.db.prepare(`
          UPDATE comments SET user_id = ? WHERE user_id = ?
        `).bind(toUserId, fromUserId),
        
        this.db.prepare(`
          DELETE FROM users WHERE id = ?
        `).bind(fromUserId)
      ])

      const results = await stmt
      
      return results.every(result => result.success)
    } catch (error) {
      console.error('Transaction error:', error)
      throw new Error('Failed to transfer user data')
    }
  }
}
```

### 4. R2 Storage Integration

```typescript
// utils/storage.ts
export class StorageService {
  constructor(private bucket: R2Bucket) {}

  async uploadFile(key: string, file: File | ArrayBuffer, metadata?: Record<string, string>) {
    try {
      const object = await this.bucket.put(key, file, {
        httpMetadata: {
          contentType: file instanceof File ? file.type : 'application/octet-stream',
          cacheControl: 'public, max-age=31536000', // 1 year
        },
        customMetadata: {
          uploadedAt: new Date().toISOString(),
          ...metadata,
        },
      })

      if (!object) {
        throw new Error('Failed to upload file')
      }

      return {
        key: object.key,
        size: object.size,
        etag: object.etag,
        uploaded: object.uploaded,
      }
    } catch (error) {
      console.error('Storage error:', error)
      throw new Error('Failed to upload file')
    }
  }

  async getFile(key: string) {
    try {
      const object = await this.bucket.get(key)
      
      if (!object) {
        return null
      }

      return {
        body: object.body,
        size: object.size,
        etag: object.etag,
        httpMetadata: object.httpMetadata,
        customMetadata: object.customMetadata,
      }
    } catch (error) {
      console.error('Storage error:', error)
      throw new Error('Failed to get file')
    }
  }

  async deleteFile(key: string) {
    try {
      await this.bucket.delete(key)
      return { success: true }
    } catch (error) {
      console.error('Storage error:', error)
      throw new Error('Failed to delete file')
    }
  }

  async listFiles(prefix?: string, limit = 1000) {
    try {
      const objects = await this.bucket.list({
        prefix,
        limit,
      })

      return {
        objects: objects.objects.map(obj => ({
          key: obj.key,
          size: obj.size,
          etag: obj.etag,
          uploaded: obj.uploaded,
        })),
        truncated: objects.truncated,
        cursor: objects.cursor,
      }
    } catch (error) {
      console.error('Storage error:', error)
      throw new Error('Failed to list files')
    }
  }

  // Generate presigned URL for direct uploads
  async getUploadUrl(key: string, expirationMinutes = 60) {
    try {
      // Note: Presigned URLs for R2 require additional setup
      // This is a simplified example
      const url = new URL(`https://your-bucket.r2.cloudflarestorage.com/${key}`)
      url.searchParams.set('X-Amz-Expires', (expirationMinutes * 60).toString())
      
      return url.toString()
    } catch (error) {
      console.error('Presigned URL error:', error)
      throw new Error('Failed to generate upload URL')
    }
  }
}
```

## 🎯 Cloudflare Pages Best Practices

### 1. Pages Functions Integration

```typescript
// functions/api/users/[id].ts
interface Env {
  DB: D1Database
  STORAGE: R2Bucket
}

export const onRequestGet: PagesFunction<Env> = async (context) => {
  const { params, env } = context
  const userId = params.id as string

  try {
    const db = new DatabaseService(env.DB)
    const user = await db.getUserById(userId)
    
    return Response.json(user)
  } catch (error) {
    return Response.json(
      { error: error.message },
      { status: error.message === 'User not found' ? 404 : 500 }
    )
  }
}

export const onRequestPut: PagesFunction<Env> = async (context) => {
  const { request, params, env } = context
  const userId = params.id as string

  try {
    const updates = await request.json()
    const db = new DatabaseService(env.DB)
    const user = await db.updateUser(userId, updates)
    
    return Response.json(user)
  } catch (error) {
    return Response.json(
      { error: error.message },
      { status: 500 }
    )
  }
}

// functions/_middleware.ts
export const onRequest: PagesFunction = async (context) => {
  // Global middleware for all Pages Functions
  const response = await context.next()
  
  // Add security headers
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  
  return response
}
```

### 2. Static Site Generation with Dynamic Content

```typescript
// functions/blog/[slug].ts
export const onRequestGet: PagesFunction<Env> = async (context) => {
  const { params, env, request } = context
  const slug = params.slug as string

  try {
    // Check if static version exists first
    const staticResponse = await env.ASSETS.fetch(request)
    if (staticResponse.status === 200) {
      return staticResponse
    }

    // Generate dynamic content
    const db = new DatabaseService(env.DB)
    const post = await db.getPostBySlug(slug)
    
    if (!post) {
      return new Response('Post not found', { status: 404 })
    }

    // Generate HTML
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>${post.title}</title>
          <meta name="description" content="${post.excerpt}">
          <meta property="og:title" content="${post.title}">
          <meta property="og:description" content="${post.excerpt}">
        </head>
        <body>
          <article>
            <h1>${post.title}</h1>
            <div>${post.content}</div>
          </article>
        </body>
      </html>
    `

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html',
        'Cache-Control': 'public, max-age=3600', // 1 hour
      },
    })
  } catch (error) {
    return new Response('Internal Server Error', { status: 500 })
  }
}
```

## 🛠️ Configuration & Environment Management

### 1. Wrangler Configuration

```toml
# wrangler.toml
name = "my-cloudflare-app"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[env.development]
vars = { ENVIRONMENT = "development" }
kv_namespaces = [
  { binding = "KV", id = "your-dev-kv-namespace-id" }
]
d1_databases = [
  { binding = "DB", database_name = "my-app-dev", database_id = "your-dev-db-id" }
]
r2_buckets = [
  { binding = "STORAGE", bucket_name = "my-app-dev-storage" }
]

[env.staging]
vars = { ENVIRONMENT = "staging" }
kv_namespaces = [
  { binding = "KV", id = "your-staging-kv-namespace-id" }
]
d1_databases = [
  { binding = "DB", database_name = "my-app-staging", database_id = "your-staging-db-id" }
]
r2_buckets = [
  { binding = "STORAGE", bucket_name = "my-app-staging-storage" }
]

[env.production]
vars = { ENVIRONMENT = "production" }
kv_namespaces = [
  { binding = "KV", id = "your-prod-kv-namespace-id" }
]
d1_databases = [
  { binding = "DB", database_name = "my-app-prod", database_id = "your-prod-db-id" }
]
r2_buckets = [
  { binding = "STORAGE", bucket_name = "my-app-prod-storage" }
]

# Pages configuration
[env.production.pages_build_output_dir]
pages_build_output_dir = "dist"
```

### 2. Database Migrations

```sql
-- migrations/0001_initial.sql
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- migrations/0002_add_posts.sql
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  excerpt TEXT,
  slug TEXT UNIQUE NOT NULL,
  user_id TEXT NOT NULL,
  published BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX IF NOT EXISTS idx_posts_slug ON posts(slug);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_published ON posts(published);
```

```bash
# Run migrations
wrangler d1 migrations apply my-app-dev --env development
wrangler d1 migrations apply my-app-staging --env staging
wrangler d1 migrations apply my-app-prod --env production
```

## ⚠️ Common Pitfalls to Avoid

### 1. CPU Time Limits
```typescript
// ❌ Bad - Synchronous, blocking operations
function processLargeArray(data: any[]) {
  return data.map(item => {
    // Expensive synchronous operation
    for (let i = 0; i < 1000000; i++) {
      // Heavy computation
    }
    return processItem(item)
  })
}

// ✅ Good - Async processing with yielding
async function processLargeArray(data: any[]) {
  const results = []
  for (const item of data) {
    results.push(await processItemAsync(item))
    
    // Yield control periodically
    if (results.length % 100 === 0) {
      await new Promise(resolve => setTimeout(resolve, 0))
    }
  }
  return results
}
```

### 2. Memory Usage
```typescript
// ❌ Bad - Loading large files into memory
async function handleFileUpload(request: Request, env: Env) {
  const arrayBuffer = await request.arrayBuffer() // Loads entire file
  await env.STORAGE.put('file.pdf', arrayBuffer)
}

// ✅ Good - Streaming uploads
async function handleFileUpload(request: Request, env: Env) {
  await env.STORAGE.put('file.pdf', request.body) // Streams directly
}
```

### 3. Cold Start Performance
```typescript
// ❌ Bad - Heavy initialization in global scope
const heavyLibrary = require('heavy-library')
const expensiveConnection = createDatabaseConnection()

// ✅ Good - Lazy initialization
let heavyLibrary: any = null
let databaseConnection: any = null

async function getHeavyLibrary() {
  if (!heavyLibrary) {
    heavyLibrary = await import('heavy-library')
  }
  return heavyLibrary
}
```

## 📊 Performance Optimization

### 1. Caching Strategies
```typescript
// Edge caching with custom cache keys
export async function handleCachedRequest(request: Request, env: Env) {
  const cacheUrl = new URL(request.url)
  const cacheKey = new Request(cacheUrl.toString(), request)
  const cache = caches.default

  // Try to find the request in cache
  let response = await cache.match(cacheKey)

  if (!response) {
    // Generate response
    const data = await fetchDataFromD1(env.DB)
    response = Response.json(data)
    
    // Cache for 1 hour
    response.headers.set('Cache-Control', 'public, max-age=3600')
    response.headers.set('CDN-Cache-Control', 'public, max-age=3600')
    
    // Store in edge cache
    await cache.put(cacheKey, response.clone())
  }

  return response
}
```

### 2. Database Query Optimization
```typescript
// Optimize D1 queries
export class OptimizedDatabaseService {
  constructor(private db: D1Database) {}

  // Use prepared statements for repeated queries
  private preparedStatements = new Map<string, D1PreparedStatement>()

  private getStatement(key: string, sql: string) {
    if (!this.preparedStatements.has(key)) {
      this.preparedStatements.set(key, this.db.prepare(sql))
    }
    return this.preparedStatements.get(key)!
  }

  async getUsersOptimized(limit = 50, offset = 0) {
    const stmt = this.getStatement('getUsers', `
      SELECT id, email, name, created_at 
      FROM users 
      ORDER BY created_at DESC 
      LIMIT ? OFFSET ?
    `)
    
    return (await stmt.bind(limit, offset).all()).results
  }
}
```

## 🧪 Testing Strategies

### 1. Local Testing with Miniflare
```typescript
// test/worker.test.ts
import { unstable_dev } from 'wrangler'

describe('Worker Tests', () => {
  let worker: any

  beforeAll(async () => {
    worker = await unstable_dev('src/index.ts', {
      experimental: { disableExperimentalWarning: true },
    })
  })

  afterAll(async () => {
    await worker.stop()
  })

  it('should return health check', async () => {
    const resp = await worker.fetch('/health')
    expect(resp.status).toBe(200)
    
    const data = await resp.json()
    expect(data.status).toBe('healthy')
  })

  it('should handle authentication', async () => {
    const resp = await worker.fetch('/api/users', {
      headers: { 'Authorization': 'Bearer invalid-token' }
    })
    expect(resp.status).toBe(401)
  })
})
```

### 2. Integration Testing
```bash
# package.json
{
  "scripts": {
    "test": "vitest",
    "test:integration": "wrangler dev --port 8787 & sleep 2 && npm run test:integration:run && kill %1",
    "test:integration:run": "vitest run --config vitest.integration.config.ts"
  }
}
```

## 🚀 Deployment & CI/CD

### 1. GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloudflare

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run test
      - run: npm run build

  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run build
      
      - name: Deploy to Cloudflare Workers
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          environment: 'staging'

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run build
      
      - name: Run DB migrations
        run: wrangler d1 migrations apply my-app-prod --env production
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      
      - name: Deploy to Cloudflare Workers
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          environment: 'production'
```

## 📈 Monitoring & Observability

### 1. Analytics & Logging
```typescript
// Enhanced logging and metrics
export async function handleRequestWithAnalytics(request: Request, env: Env) {
  const startTime = Date.now()
  const requestId = crypto.randomUUID()
  
  try {
    // Log request start
    console.log(JSON.stringify({
      type: 'request_start',
      requestId,
      method: request.method,
      url: request.url,
      userAgent: request.headers.get('User-Agent'),
      country: request.cf?.country,
      timestamp: new Date().toISOString()
    }))

    const response = await handleRequest(request, env)
    const duration = Date.now() - startTime

    // Log successful response
    console.log(JSON.stringify({
      type: 'request_complete',
      requestId,
      status: response.status,
      duration,
      timestamp: new Date().toISOString()
    }))

    // Store analytics in KV
    await env.KV.put(`analytics:${requestId}`, JSON.stringify({
      method: request.method,
      url: request.url,
      status: response.status,
      duration,
      country: request.cf?.country,
      timestamp: Date.now()
    }), { expirationTtl: 86400 * 30 }) // 30 days

    return response
  } catch (error) {
    const duration = Date.now() - startTime

    // Log error
    console.error(JSON.stringify({
      type: 'request_error',
      requestId,
      error: error.message,
      stack: error.stack,
      duration,
      timestamp: new Date().toISOString()
    }))

    throw error
  }
}
```

## 🔒 Security Best Practices

### 1. Input Validation & Sanitization
```typescript
// utils/validation.ts
import { z } from 'zod'

export const userCreateSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  password: z.string().min(8).max(100)
})

export const postCreateSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(50000),
  slug: z.string().regex(/^[a-z0-9-]+$/),
})

export function validateInput<T>(schema: z.ZodSchema<T>, data: unknown): T {
  try {
    return schema.parse(data)
  } catch (error) {
    if (error instanceof z.ZodError) {
      throw new Error(`Validation failed: ${error.errors.map(e => e.message).join(', ')}`)
    }
    throw error
  }
}
```

### 2. Content Security Policy
```typescript
// Security headers middleware
export function addSecurityHeaders(response: Response): Response {
  const securityHeaders = {
    'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';",
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()'
  }

  Object.entries(securityHeaders).forEach(([key, value]) => {
    response.headers.set(key, value)
  })

  return response
}
```

## 📋 Code Review Checklist

- [ ] Environment-specific configurations properly set
- [ ] Database queries optimized and use prepared statements
- [ ] Error handling implemented throughout
- [ ] Input validation and sanitization applied
- [ ] Caching strategies implemented where appropriate
- [ ] Security headers and CSP configured
- [ ] Rate limiting implemented for sensitive endpoints
- [ ] Logging and monitoring in place
- [ ] Tests cover critical functionality
- [ ] Deployment pipeline configured

Remember: Cloudflare's edge computing platform excels at global scale and performance. Focus on leveraging edge caching, optimizing for cold starts, and designing for the unique constraints and capabilities of the Workers runtime environment.