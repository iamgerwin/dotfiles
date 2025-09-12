# AdonisJS Best Practices

## Overview

AdonisJS is a fully-featured Node.js web framework with a focus on developer ergonomics, stability, and confidence. It follows the MVC pattern and provides everything needed to create full-stack web applications or API servers.

### Use Cases
- Enterprise web applications
- RESTful APIs and GraphQL servers  
- Real-time applications with WebSockets
- Multi-tenant SaaS applications
- Server-side rendered applications
- Microservices architecture

## Setup and Configuration

### Initial Setup

```bash
# Create a new AdonisJS application
npm init adonisjs@latest my-app

# Choose application structure
# - web (Full-stack app with views)
# - api (API server)
# - slim (Minimal structure)

cd my-app
node ace serve --watch
```

### Project Structure

```
my-app/
├── app/
│   ├── Controllers/     # HTTP controllers
│   ├── Models/          # Database models
│   ├── Middleware/      # HTTP middleware
│   ├── Validators/      # Request validators
│   ├── Services/        # Business logic
│   └── Exceptions/      # Custom exceptions
├── config/              # Configuration files
├── database/
│   ├── migrations/      # Database migrations
│   ├── seeders/        # Database seeders
│   └── factories/      # Model factories
├── resources/
│   └── views/          # Edge templates
├── start/
│   ├── routes.ts       # Application routes
│   └── kernel.ts       # HTTP kernel
└── tests/              # Test files
```

### Environment Configuration

```typescript
// config/app.ts
import proxyAddr from 'proxy-addr'
import Env from '@ioc:Adonis/Core/Env'
import { ServerConfig } from '@ioc:Adonis/Core/Server'
import { LoggerConfig } from '@ioc:Adonis/Core/Logger'

export const appKey: string = Env.get('APP_KEY')

export const http: ServerConfig = {
  allowMethodSpoofing: false,
  subdomainOffset: 2,
  generateRequestId: true,
  trustProxy: proxyAddr.compile('loopback'),
  cookie: {
    domain: '',
    path: '/',
    maxAge: '2h',
    httpOnly: true,
    secure: Env.get('NODE_ENV') === 'production',
    sameSite: 'lax',
  },
  forceContentNegotiationTo: 'application/json',
}

export const logger: LoggerConfig = {
  name: Env.get('APP_NAME'),
  enabled: true,
  level: Env.get('LOG_LEVEL', 'info'),
  prettyPrint: Env.get('NODE_ENV') === 'development',
}
```

## Security Considerations

### Authentication Implementation

```typescript
// app/Controllers/Http/AuthController.ts
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import User from 'App/Models/User'
import LoginValidator from 'App/Validators/LoginValidator'
import Hash from '@ioc:Adonis/Core/Hash'

export default class AuthController {
  public async login({ request, auth, response }: HttpContextContract) {
    const { email, password } = await request.validate(LoginValidator)
    
    try {
      // Verify credentials
      const user = await User.query()
        .where('email', email)
        .firstOrFail()
      
      if (!(await Hash.verify(user.password, password))) {
        return response.unauthorized('Invalid credentials')
      }
      
      // Generate token
      const token = await auth.use('api').generate(user, {
        expiresIn: '7days'
      })
      
      // Log authentication event
      await user.related('loginHistory').create({
        ipAddress: request.ip(),
        userAgent: request.header('user-agent'),
        loginAt: DateTime.now()
      })
      
      return response.ok({
        user: user.serialize(),
        token
      })
    } catch {
      return response.unauthorized('Invalid credentials')
    }
  }
  
  public async logout({ auth, response }: HttpContextContract) {
    await auth.use('api').revoke()
    return response.ok({ message: 'Logged out successfully' })
  }
}
```

### Middleware for Authorization

```typescript
// app/Middleware/Authorize.ts
import { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import { AuthenticationException } from '@adonisjs/auth/build/standalone'

export default class Authorize {
  public async handle(
    { auth, response }: HttpContextContract,
    next: () => Promise<void>,
    guards: string[]
  ) {
    const user = auth.user
    
    if (!user) {
      throw new AuthenticationException(
        'Unauthorized access',
        'E_UNAUTHORIZED_ACCESS'
      )
    }
    
    // Check user roles/permissions
    const hasPermission = guards.some(guard => {
      if (guard === 'admin') return user.role === 'admin'
      if (guard === 'verified') return user.emailVerified
      return false
    })
    
    if (!hasPermission) {
      return response.forbidden('Insufficient permissions')
    }
    
    await next()
  }
}
```

### CORS Configuration

```typescript
// config/cors.ts
import { CorsConfig } from '@ioc:Adonis/Core/Cors'

const corsConfig: CorsConfig = {
  enabled: true,
  origin: (origin, callback) => {
    const allowedOrigins = [
      'http://localhost:3000',
      'https://yourdomain.com'
    ]
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  },
  credentials: true,
  maxAge: 90,
  methods: ['GET', 'HEAD', 'POST', 'PUT', 'DELETE'],
  headers: true,
  exposeHeaders: [
    'cache-control',
    'content-language',
    'content-type',
    'expires',
    'last-modified',
    'pragma',
  ],
}

export default corsConfig
```

## Performance Optimization

### Database Query Optimization

```typescript
// app/Models/User.ts
import { DateTime } from 'luxon'
import Hash from '@ioc:Adonis/Core/Hash'
import {
  column,
  beforeSave,
  BaseModel,
  hasMany,
  HasMany,
  scope
} from '@ioc:Adonis/Lucid/Orm'
import Post from 'App/Models/Post'

export default class User extends BaseModel {
  @column({ isPrimary: true })
  public id: number

  @column()
  public email: string

  @column({ serializeAs: null })
  public password: string

  @column.dateTime({ autoCreate: true })
  public createdAt: DateTime

  @hasMany(() => Post)
  public posts: HasMany<typeof Post>

  @beforeSave()
  public static async hashPassword(user: User) {
    if (user.$dirty.password) {
      user.password = await Hash.make(user.password)
    }
  }

  // Query scopes for reusable queries
  public static active = scope((query) => {
    query.where('status', 'active')
  })

  public static withPosts = scope((query) => {
    query.preload('posts', (postsQuery) => {
      postsQuery.orderBy('created_at', 'desc')
    })
  })
}

// Usage with eager loading
const users = await User
  .query()
  .apply((scopes) => scopes.active())
  .apply((scopes) => scopes.withPosts())
  .paginate(page, 20)
```

### Caching Strategy

```typescript
// app/Services/CacheService.ts
import Redis from '@ioc:Adonis/Addons/Redis'
import { DateTime } from 'luxon'

export default class CacheService {
  private readonly prefix = 'cache:'
  private readonly defaultTTL = 3600 // 1 hour

  public async get<T>(key: string): Promise<T | null> {
    const data = await Redis.get(`${this.prefix}${key}`)
    return data ? JSON.parse(data) : null
  }

  public async set(
    key: string, 
    value: any, 
    ttl: number = this.defaultTTL
  ): Promise<void> {
    await Redis.setex(
      `${this.prefix}${key}`,
      ttl,
      JSON.stringify(value)
    )
  }

  public async remember<T>(
    key: string,
    ttl: number,
    callback: () => Promise<T>
  ): Promise<T> {
    let data = await this.get<T>(key)
    
    if (!data) {
      data = await callback()
      await this.set(key, data, ttl)
    }
    
    return data
  }

  public async forget(key: string): Promise<void> {
    await Redis.del(`${this.prefix}${key}`)
  }

  public async flush(pattern: string = '*'): Promise<void> {
    const keys = await Redis.keys(`${this.prefix}${pattern}`)
    if (keys.length) {
      await Redis.del(keys)
    }
  }
}

// Usage in controller
import CacheService from 'App/Services/CacheService'

export default class PostsController {
  private cache = new CacheService()

  public async index({ request }: HttpContextContract) {
    const page = request.input('page', 1)
    const cacheKey = `posts:page:${page}`
    
    const posts = await this.cache.remember(cacheKey, 600, async () => {
      return await Post
        .query()
        .preload('author')
        .preload('tags')
        .orderBy('created_at', 'desc')
        .paginate(page, 20)
    })
    
    return posts
  }
}
```

### Request Rate Limiting

```typescript
// app/Middleware/Throttle.ts
import { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import Redis from '@ioc:Adonis/Addons/Redis'

export default class Throttle {
  public async handle(
    { request, response, auth }: HttpContextContract,
    next: () => Promise<void>,
    options: { limit: number; duration: number }
  ) {
    const identifier = auth.user?.id || request.ip()
    const key = `throttle:${request.url()}:${identifier}`
    
    const current = await Redis.incr(key)
    
    if (current === 1) {
      await Redis.expire(key, options.duration)
    }
    
    const ttl = await Redis.ttl(key)
    
    response.header('X-RateLimit-Limit', options.limit.toString())
    response.header('X-RateLimit-Remaining', 
      Math.max(0, options.limit - current).toString()
    )
    response.header('X-RateLimit-Reset', 
      new Date(Date.now() + ttl * 1000).toISOString()
    )
    
    if (current > options.limit) {
      return response.tooManyRequests({
        error: 'Too many requests',
        retryAfter: ttl
      })
    }
    
    await next()
  }
}

// Register in kernel
Server.middleware.registerNamed({
  throttle: () => import('App/Middleware/Throttle')
})

// Usage in routes
Route.post('/api/posts', 'PostsController.store')
  .middleware(['auth', 'throttle:10,60'])
```

## Common Patterns

### Service Layer Pattern

```typescript
// app/Services/UserService.ts
import User from 'App/Models/User'
import Mail from '@ioc:Adonis/Addons/Mail'
import Event from '@ioc:Adonis/Core/Event'
import { DateTime } from 'luxon'

export default class UserService {
  public async createUser(data: {
    email: string
    password: string
    name: string
  }) {
    const user = await User.create(data)
    
    // Send welcome email
    await Mail.send((message) => {
      message
        .to(user.email)
        .subject('Welcome to our platform')
        .htmlView('emails/welcome', { user })
    })
    
    // Emit event
    Event.emit('user:registered', user)
    
    return user
  }
  
  public async updateProfile(
    userId: number,
    data: Partial<User>
  ) {
    const user = await User.findOrFail(userId)
    
    user.merge(data)
    await user.save()
    
    // Clear cache
    await this.clearUserCache(userId)
    
    return user
  }
  
  private async clearUserCache(userId: number) {
    const patterns = [
      `user:${userId}`,
      `user:${userId}:*`
    ]
    
    for (const pattern of patterns) {
      await Redis.del(pattern)
    }
  }
}
```

### Repository Pattern

```typescript
// app/Repositories/PostRepository.ts
import Post from 'App/Models/Post'
import { ModelPaginatorContract } from '@ioc:Adonis/Lucid/Orm'

interface PostFilters {
  status?: string
  authorId?: number
  categoryId?: number
  search?: string
}

export default class PostRepository {
  public async paginate(
    page: number = 1,
    limit: number = 20,
    filters: PostFilters = {}
  ): Promise<ModelPaginatorContract<Post>> {
    const query = Post.query()
    
    if (filters.status) {
      query.where('status', filters.status)
    }
    
    if (filters.authorId) {
      query.where('author_id', filters.authorId)
    }
    
    if (filters.categoryId) {
      query.where('category_id', filters.categoryId)
    }
    
    if (filters.search) {
      query.where((q) => {
        q.where('title', 'like', `%${filters.search}%`)
          .orWhere('content', 'like', `%${filters.search}%`)
      })
    }
    
    return await query
      .preload('author')
      .preload('category')
      .preload('tags')
      .orderBy('created_at', 'desc')
      .paginate(page, limit)
  }
  
  public async findBySlug(slug: string): Promise<Post> {
    return await Post
      .query()
      .where('slug', slug)
      .preload('author')
      .preload('category')
      .preload('tags')
      .firstOrFail()
  }
  
  public async incrementViews(postId: number): Promise<void> {
    await Post
      .query()
      .where('id', postId)
      .increment('views_count', 1)
  }
}
```

### Event-Driven Architecture

```typescript
// app/Listeners/UserEventListener.ts
import Event from '@ioc:Adonis/Core/Event'
import Mail from '@ioc:Adonis/Addons/Mail'
import User from 'App/Models/User'

Event.on('user:registered', async (user: User) => {
  // Send notification to admin
  await Mail.send((message) => {
    message
      .to('admin@example.com')
      .subject('New user registration')
      .htmlView('emails/admin/new-user', { user })
  })
  
  // Create default settings
  await user.related('settings').create({
    notifications: true,
    newsletter: false,
    theme: 'light'
  })
  
  // Log activity
  await user.related('activities').create({
    type: 'registration',
    description: 'User account created'
  })
})

Event.on('user:login', async ({ user, ip, userAgent }) => {
  await user.related('loginHistory').create({
    ipAddress: ip,
    userAgent,
    loginAt: DateTime.now()
  })
})
```

## Anti-patterns to Avoid

### Business Logic in Controllers
```typescript
// ❌ Avoid putting business logic in controllers
export default class UsersController {
  public async store({ request, response }: HttpContextContract) {
    const data = request.all()
    
    // Business logic should not be here
    const user = await User.create(data)
    await Mail.send(...)
    await Redis.set(...)
    
    return response.created(user)
  }
}

// ✅ Use service layer
export default class UsersController {
  constructor(private userService: UserService) {}
  
  public async store({ request, response }: HttpContextContract) {
    const data = await request.validate(CreateUserValidator)
    const user = await this.userService.createUser(data)
    return response.created(user)
  }
}
```

### N+1 Query Problem
```typescript
// ❌ N+1 queries
const posts = await Post.all()
for (const post of posts) {
  // This creates N additional queries
  const author = await post.related('author').query().first()
  console.log(author.name)
}

// ✅ Eager loading
const posts = await Post
  .query()
  .preload('author')
  
posts.forEach(post => {
  console.log(post.author.name)
})
```

## Testing Strategies

### Unit Testing

```typescript
// tests/unit/user-service.spec.ts
import { test } from '@japa/runner'
import UserService from 'App/Services/UserService'
import { UserFactory } from 'Database/factories'

test.group('UserService', (group) => {
  group.each.setup(async () => {
    await Database.beginGlobalTransaction()
    return () => Database.rollbackGlobalTransaction()
  })
  
  test('creates user with hashed password', async ({ assert }) => {
    const service = new UserService()
    const userData = {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    }
    
    const user = await service.createUser(userData)
    
    assert.exists(user.id)
    assert.equal(user.email, userData.email)
    assert.notEqual(user.password, userData.password)
  })
  
  test('prevents duplicate emails', async ({ assert }) => {
    const service = new UserService()
    await UserFactory.merge({ email: 'test@example.com' }).create()
    
    const userData = {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    }
    
    await assert.rejects(
      () => service.createUser(userData),
      'E_UNIQUE_CONSTRAINT'
    )
  })
})
```

### Integration Testing

```typescript
// tests/functional/auth.spec.ts
import { test } from '@japa/runner'
import { UserFactory } from 'Database/factories'

test.group('Authentication', (group) => {
  group.each.setup(async () => {
    await Database.beginGlobalTransaction()
    return () => Database.rollbackGlobalTransaction()
  })
  
  test('user can login with valid credentials', async ({ client, assert }) => {
    const user = await UserFactory.merge({
      email: 'test@example.com',
      password: 'password123'
    }).create()
    
    const response = await client
      .post('/api/auth/login')
      .json({
        email: 'test@example.com',
        password: 'password123'
      })
    
    response.assertStatus(200)
    response.assertBodyContains({
      user: { email: 'test@example.com' }
    })
    assert.exists(response.body().token)
  })
  
  test('returns 401 for invalid credentials', async ({ client }) => {
    const response = await client
      .post('/api/auth/login')
      .json({
        email: 'wrong@example.com',
        password: 'wrongpassword'
      })
    
    response.assertStatus(401)
    response.assertBodyContains({
      message: 'Invalid credentials'
    })
  })
})
```

## Error Handling

### Custom Exception Handler

```typescript
// app/Exceptions/Handler.ts
import Logger from '@ioc:Adonis/Core/Logger'
import HttpExceptionHandler from '@ioc:Adonis/Core/HttpExceptionHandler'
import { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'

export default class ExceptionHandler extends HttpExceptionHandler {
  protected statusPages = {
    '403': 'errors/unauthorized',
    '404': 'errors/not-found',
    '500..599': 'errors/server-error',
  }

  protected ignoreCodes = ['E_ROUTE_NOT_FOUND']

  public async handle(error: any, ctx: HttpContextContract) {
    // Custom error handling
    if (error.code === 'E_VALIDATION_FAILURE') {
      return ctx.response.status(422).send({
        errors: error.messages
      })
    }

    if (error.code === 'E_ROW_NOT_FOUND') {
      return ctx.response.status(404).send({
        error: 'Resource not found'
      })
    }

    // Log critical errors
    if (error.status >= 500) {
      Logger.error({ err: error }, error.message)
    }

    return super.handle(error, ctx)
  }

  public async report(error: any, ctx: HttpContextContract) {
    // Send to error tracking service
    if (!this.ignoreCodes.includes(error.code)) {
      // Sentry, Bugsnag, etc.
      await this.sendToErrorTracking(error, ctx)
    }

    return super.report(error, ctx)
  }

  private async sendToErrorTracking(error: any, ctx: HttpContextContract) {
    // Implementation for error tracking service
    const errorData = {
      message: error.message,
      stack: error.stack,
      url: ctx.request.url(),
      method: ctx.request.method(),
      ip: ctx.request.ip(),
      userId: ctx.auth.user?.id
    }
    
    // Send to tracking service
    console.error('Error tracked:', errorData)
  }
}
```

### Validation Error Handling

```typescript
// app/Validators/CreatePostValidator.ts
import { schema, rules, CustomMessages } from '@ioc:Adonis/Core/Validator'
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'

export default class CreatePostValidator {
  constructor(protected ctx: HttpContextContract) {}

  public schema = schema.create({
    title: schema.string({ trim: true }, [
      rules.minLength(5),
      rules.maxLength(255)
    ]),
    content: schema.string({}, [
      rules.minLength(20)
    ]),
    categoryId: schema.number([
      rules.exists({ table: 'categories', column: 'id' })
    ]),
    tags: schema.array.optional().members(
      schema.number([
        rules.exists({ table: 'tags', column: 'id' })
      ])
    ),
    publishedAt: schema.date.optional({}, [
      rules.after('today')
    ])
  })

  public messages: CustomMessages = {
    'title.required': 'Post title is required',
    'title.minLength': 'Title must be at least 5 characters',
    'content.required': 'Post content is required',
    'content.minLength': 'Content must be at least 20 characters',
    'categoryId.exists': 'Selected category does not exist',
    'tags.*.exists': 'One or more selected tags do not exist',
    'publishedAt.after': 'Publish date must be in the future'
  }
}
```

## Resources

- [Official Documentation](https://docs.adonisjs.com)
- [API Reference](https://docs.adonisjs.com/reference)
- [AdonisJS Discord](https://discord.gg/vDcEjq6)
- [GitHub Repository](https://github.com/adonisjs)
- [Adocasts Video Tutorials](https://adocasts.com)