# AdonisJS Best Practices

## Overview

AdonisJS is a fully-featured Node.js web framework built on TypeScript that provides everything needed to create full-stack web applications and APIs. It follows the MVC (Model-View-Controller) pattern and emphasizes developer ergonomics, stability, and confidence. AdonisJS comes with an extensive ecosystem of official packages covering authentication, validation, database ORM, mail, WebSockets, and more.

The framework is heavily inspired by Laravel (PHP) and brings similar conventions and developer experience to the Node.js ecosystem. It provides a robust foundation for building scalable applications with built-in support for modern development practices.

## Pros & Cons

### Pros
- **TypeScript First**: Built with TypeScript from the ground up, providing excellent type safety
- **Batteries Included**: Comprehensive ecosystem with official packages for common features
- **Developer Experience**: Excellent CLI tools, scaffolding, and development workflow
- **Laravel-like Conventions**: Familiar patterns for developers coming from Laravel
- **Strong ORM**: Lucid ORM provides powerful database operations with elegant syntax
- **Built-in Authentication**: Multiple authentication guards and providers out of the box
- **Validation System**: Comprehensive validation with custom rules and error handling
- **Real-time Support**: Built-in WebSocket support for real-time applications
- **Testing Framework**: Integrated testing framework with excellent tooling
- **Performance**: Fast execution with optimized build process

### Cons
- **Learning Curve**: Comprehensive framework requires time to master all features
- **Opinionated Structure**: Enforces specific architectural patterns and conventions
- **Community Size**: Smaller community compared to Express.js or Fastify
- **Memory Usage**: Higher memory footprint compared to minimal frameworks
- **Bundle Size**: Larger application size due to comprehensive feature set
- **Vendor Lock-in**: Framework-specific patterns make migration challenging

## When to Use

AdonisJS is ideal for:
- Enterprise web applications requiring robust architecture
- Full-stack applications with complex business logic
- API development with comprehensive feature requirements
- Applications requiring built-in authentication and authorization
- Teams familiar with MVC patterns and convention-over-configuration
- Projects needing real-time features (WebSockets)
- Applications with complex data relationships and validation
- Long-term projects requiring maintainable codebases

Avoid AdonisJS for:
- Simple static websites or basic APIs
- Microservices requiring minimal overhead
- Applications with extreme performance requirements
- Teams preferring minimal, unopinionated frameworks
- Serverless applications with strict cold start requirements
- Projects requiring maximum flexibility in architecture choices

## Core Concepts

### Application Structure

```typescript
// Basic application structure
my-app/
├── app/
│   ├── Controllers/Http/    # HTTP controllers
│   ├── Models/             # Database models
│   ├── Middleware/         # HTTP middleware
│   ├── Validators/         # Request validators
│   ├── Services/           # Business logic services
│   ├── Exceptions/         # Custom exceptions
│   └── Listeners/          # Event listeners
├── config/                 # Configuration files
├── database/
│   ├── migrations/         # Database migrations
│   ├── seeders/           # Database seeders
│   └── factories/         # Model factories
├── resources/
│   ├── views/             # Edge templates
│   └── css/               # Stylesheets
├── start/
│   ├── routes.ts          # Route definitions
│   ├── kernel.ts          # HTTP kernel
│   └── events.ts          # Event listeners
└── tests/                 # Test files
```

### Models and Database

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
  belongsTo,
  BelongsTo,
  manyToMany,
  ManyToMany,
  computed,
  scope
} from '@ioc:Adonis/Lucid/Orm'
import Post from './Post'
import Profile from './Profile'
import Role from './Role'

export default class User extends BaseModel {
  @column({ isPrimary: true })
  public id: number

  @column()
  public email: string

  @column()
  public username: string

  @column({ serializeAs: null })
  public password: string

  @column()
  public isActive: boolean

  @column.dateTime()
  public emailVerifiedAt: DateTime | null

  @column.dateTime({ autoCreate: true })
  public createdAt: DateTime

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  public updatedAt: DateTime

  // Relationships
  @hasMany(() => Post)
  public posts: HasMany<typeof Post>

  @belongsTo(() => Profile)
  public profile: BelongsTo<typeof Profile>

  @manyToMany(() => Role)
  public roles: ManyToMany<typeof Role>

  // Computed properties
  @computed()
  public get fullName() {
    return `${this.firstName} ${this.lastName}`
  }

  @computed()
  public get isVerified() {
    return this.emailVerifiedAt !== null
  }

  // Hooks
  @beforeSave()
  public static async hashPassword(user: User) {
    if (user.$dirty.password) {
      user.password = await Hash.make(user.password)
    }
  }

  // Query scopes
  public static active = scope((query) => {
    query.where('is_active', true)
  })

  public static verified = scope((query) => {
    query.whereNotNull('email_verified_at')
  })

  public static withPosts = scope((query) => {
    query.preload('posts', (postsQuery) => {
      postsQuery.orderBy('created_at', 'desc').limit(5)
    })
  })

  public static withRoles = scope((query) => {
    query.preload('roles')
  })

  // Custom methods
  public async hasRole(roleName: string): Promise<boolean> {
    await this.load('roles')
    return this.roles.some(role => role.name === roleName)
  }

  public async assignRole(roleName: string): Promise<void> {
    const role = await Role.findByOrFail('name', roleName)
    await this.related('roles').attach([role.id])
  }

  public async revokeRole(roleName: string): Promise<void> {
    const role = await Role.findByOrFail('name', roleName)
    await this.related('roles').detach([role.id])
  }
}

// app/Models/Post.ts
export default class Post extends BaseModel {
  @column({ isPrimary: true })
  public id: number

  @column()
  public title: string

  @column()
  public slug: string

  @column()
  public content: string

  @column()
  public excerpt: string

  @column()
  public status: 'draft' | 'published' | 'archived'

  @column()
  public userId: number

  @column()
  public categoryId: number

  @column()
  public viewsCount: number

  @column.dateTime()
  public publishedAt: DateTime | null

  @column.dateTime({ autoCreate: true })
  public createdAt: DateTime

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  public updatedAt: DateTime

  @belongsTo(() => User)
  public author: BelongsTo<typeof User>

  @belongsTo(() => Category)
  public category: BelongsTo<typeof Category>

  @manyToMany(() => Tag)
  public tags: ManyToMany<typeof Tag>

  @hasMany(() => Comment)
  public comments: HasMany<typeof Comment>

  // Scopes
  public static published = scope((query) => {
    query.where('status', 'published')
      .whereNotNull('published_at')
      .where('published_at', '<=', DateTime.now())
  })

  public static recent = scope((query) => {
    query.orderBy('published_at', 'desc')
  })

  // Computed properties
  @computed()
  public get isPublished() {
    return this.status === 'published' &&
           this.publishedAt &&
           this.publishedAt <= DateTime.now()
  }

  @computed()
  public get readingTime() {
    const wordsPerMinute = 200
    const wordCount = this.content.split(/\s+/).length
    return Math.ceil(wordCount / wordsPerMinute)
  }
}
```

### Controllers and Routing

```typescript
// app/Controllers/Http/PostsController.ts
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import Post from 'App/Models/Post'
import CreatePostValidator from 'App/Validators/CreatePostValidator'
import UpdatePostValidator from 'App/Validators/UpdatePostValidator'
import PostService from 'App/Services/PostService'
import CacheService from 'App/Services/CacheService'

export default class PostsController {
  constructor(
    private postService: PostService,
    private cacheService: CacheService
  ) {}

  public async index({ request, response }: HttpContextContract) {
    const page = request.input('page', 1)
    const limit = request.input('limit', 20)
    const status = request.input('status')
    const search = request.input('search')
    const category = request.input('category')

    const cacheKey = `posts:${page}:${limit}:${status}:${search}:${category}`

    const posts = await this.cacheService.remember(cacheKey, 300, async () => {
      const query = Post.query()

      if (status) {
        query.where('status', status)
      } else {
        query.apply((scopes) => scopes.published())
      }

      if (search) {
        query.where((searchQuery) => {
          searchQuery
            .where('title', 'like', `%${search}%`)
            .orWhere('content', 'like', `%${search}%`)
            .orWhere('excerpt', 'like', `%${search}%`)
        })
      }

      if (category) {
        query.whereHas('category', (categoryQuery) => {
          categoryQuery.where('slug', category)
        })
      }

      return await query
        .preload('author', (authorQuery) => {
          authorQuery.select('id', 'username', 'email')
        })
        .preload('category')
        .preload('tags')
        .apply((scopes) => scopes.recent())
        .paginate(page, limit)
    })

    return response.ok({
      data: posts.serialize(),
      meta: posts.getMeta()
    })
  }

  public async show({ params, response }: HttpContextContract) {
    const { slug } = params

    const cacheKey = `post:${slug}`

    const post = await this.cacheService.remember(cacheKey, 3600, async () => {
      return await Post.query()
        .where('slug', slug)
        .apply((scopes) => scopes.published())
        .preload('author', (authorQuery) => {
          authorQuery.select('id', 'username', 'email').preload('profile')
        })
        .preload('category')
        .preload('tags')
        .preload('comments', (commentsQuery) => {
          commentsQuery
            .where('status', 'approved')
            .preload('author')
            .orderBy('created_at', 'desc')
            .limit(10)
        })
        .firstOrFail()
    })

    // Increment view count asynchronously
    this.postService.incrementViews(post.id)

    return response.ok({
      data: post.serialize({
        relations: {
          author: {
            fields: {
              pick: ['id', 'username', 'email']
            }
          }
        }
      })
    })
  }

  public async store({ request, response, auth }: HttpContextContract) {
    const payload = await request.validate(CreatePostValidator)

    const post = await this.postService.createPost({
      ...payload,
      userId: auth.user!.id
    })

    // Clear related caches
    await this.cacheService.flush('posts:*')

    return response.created({
      data: post.serialize(),
      message: 'Post created successfully'
    })
  }

  public async update({ params, request, response, auth }: HttpContextContract) {
    const { id } = params
    const payload = await request.validate(UpdatePostValidator)

    const post = await Post.findOrFail(id)

    // Authorization check
    if (post.userId !== auth.user!.id && !await auth.user!.hasRole('admin')) {
      return response.forbidden({
        error: 'You are not authorized to update this post'
      })
    }

    const updatedPost = await this.postService.updatePost(post, payload)

    // Clear related caches
    await this.cacheService.forget(`post:${post.slug}`)
    await this.cacheService.flush('posts:*')

    return response.ok({
      data: updatedPost.serialize(),
      message: 'Post updated successfully'
    })
  }

  public async destroy({ params, response, auth }: HttpContextContract) {
    const { id } = params
    const post = await Post.findOrFail(id)

    // Authorization check
    if (post.userId !== auth.user!.id && !await auth.user!.hasRole('admin')) {
      return response.forbidden({
        error: 'You are not authorized to delete this post'
      })
    }

    await this.postService.deletePost(post)

    // Clear related caches
    await this.cacheService.forget(`post:${post.slug}`)
    await this.cacheService.flush('posts:*')

    return response.ok({
      message: 'Post deleted successfully'
    })
  }

  public async publish({ params, response, auth }: HttpContextContract) {
    const { id } = params
    const post = await Post.findOrFail(id)

    if (post.userId !== auth.user!.id && !await auth.user!.hasRole('admin')) {
      return response.forbidden()
    }

    const publishedPost = await this.postService.publishPost(post)

    return response.ok({
      data: publishedPost.serialize(),
      message: 'Post published successfully'
    })
  }
}

// start/routes.ts
import Route from '@ioc:Adonis/Core/Route'

// API Routes
Route.group(() => {
  // Authentication routes
  Route.group(() => {
    Route.post('/register', 'AuthController.register')
    Route.post('/login', 'AuthController.login')
    Route.post('/logout', 'AuthController.logout').middleware('auth')
    Route.get('/me', 'AuthController.me').middleware('auth')
    Route.post('/forgot-password', 'AuthController.forgotPassword')
    Route.post('/reset-password', 'AuthController.resetPassword')
  }).prefix('/auth')

  // Posts routes
  Route.resource('posts', 'PostsController')
    .apiOnly()
    .middleware({
      store: ['auth', 'throttle:10,60'],
      update: ['auth'],
      destroy: ['auth']
    })

  Route.post('/posts/:id/publish', 'PostsController.publish').middleware('auth')
  Route.get('/posts/:slug/related', 'PostsController.related')

  // Users routes
  Route.resource('users', 'UsersController')
    .apiOnly()
    .middleware({
      '*': ['auth', 'admin']
    })

  // Comments routes
  Route.resource('posts.comments', 'CommentsController')
    .apiOnly()
    .middleware({
      store: ['auth', 'throttle:5,60'],
      update: ['auth'],
      destroy: ['auth']
    })

}).prefix('/api/v1')

// Web routes for full-stack applications
Route.group(() => {
  Route.get('/', 'HomeController.index')
  Route.get('/posts', 'PostsController.index')
  Route.get('/posts/:slug', 'PostsController.show')
  Route.get('/categories/:slug', 'CategoriesController.show')
}).as('web')
```

### Services and Business Logic

```typescript
// app/Services/PostService.ts
import Post from 'App/Models/Post'
import Tag from 'App/Models/Tag'
import Event from '@ioc:Adonis/Core/Event'
import { DateTime } from 'luxon'
import slugify from 'slugify'

interface CreatePostData {
  title: string
  content: string
  excerpt?: string
  categoryId: number
  tags?: number[]
  publishedAt?: DateTime
  userId: number
}

interface UpdatePostData {
  title?: string
  content?: string
  excerpt?: string
  categoryId?: number
  tags?: number[]
  publishedAt?: DateTime
  status?: 'draft' | 'published' | 'archived'
}

export default class PostService {
  public async createPost(data: CreatePostData): Promise<Post> {
    const slug = await this.generateUniqueSlug(data.title)

    const post = await Post.create({
      ...data,
      slug,
      status: data.publishedAt ? 'published' : 'draft',
      excerpt: data.excerpt || this.generateExcerpt(data.content),
      viewsCount: 0
    })

    // Attach tags if provided
    if (data.tags && data.tags.length > 0) {
      await post.related('tags').attach(data.tags)
    }

    // Emit event
    Event.emit('post:created', { post })

    return post
  }

  public async updatePost(post: Post, data: UpdatePostData): Promise<Post> {
    // Update slug if title changed
    if (data.title && data.title !== post.title) {
      data.slug = await this.generateUniqueSlug(data.title, post.id)
    }

    // Generate excerpt if content changed
    if (data.content && data.content !== post.content) {
      data.excerpt = data.excerpt || this.generateExcerpt(data.content)
    }

    post.merge(data)
    await post.save()

    // Update tags if provided
    if (data.tags !== undefined) {
      await post.related('tags').sync(data.tags)
    }

    // Emit event
    Event.emit('post:updated', { post })

    return post
  }

  public async deletePost(post: Post): Promise<void> {
    // Soft delete related data
    await post.related('comments').query().update({ deletedAt: DateTime.now() })

    // Remove tag associations
    await post.related('tags').detach()

    // Delete the post
    await post.delete()

    // Emit event
    Event.emit('post:deleted', { postId: post.id, slug: post.slug })
  }

  public async publishPost(post: Post): Promise<Post> {
    post.merge({
      status: 'published',
      publishedAt: DateTime.now()
    })
    await post.save()

    // Emit event
    Event.emit('post:published', { post })

    return post
  }

  public async incrementViews(postId: number): Promise<void> {
    await Post.query().where('id', postId).increment('views_count', 1)
  }

  public async getRelatedPosts(post: Post, limit: number = 5): Promise<Post[]> {
    await post.load('tags')
    const tagIds = post.tags.map(tag => tag.id)

    if (tagIds.length === 0) {
      return []
    }

    return await Post.query()
      .apply((scopes) => scopes.published())
      .whereHas('tags', (tagQuery) => {
        tagQuery.whereIn('tag_id', tagIds)
      })
      .where('id', '!=', post.id)
      .preload('author')
      .preload('category')
      .orderBy('published_at', 'desc')
      .limit(limit)
  }

  public async searchPosts(
    query: string,
    filters: {
      categoryId?: number
      tagIds?: number[]
      authorId?: number
      status?: string
    } = {},
    page: number = 1,
    limit: number = 20
  ) {
    const searchQuery = Post.query()

    // Full-text search
    searchQuery.where((searchSubQuery) => {
      searchSubQuery
        .where('title', 'like', `%${query}%`)
        .orWhere('content', 'like', `%${query}%`)
        .orWhere('excerpt', 'like', `%${query}%`)
    })

    // Apply filters
    if (filters.categoryId) {
      searchQuery.where('category_id', filters.categoryId)
    }

    if (filters.authorId) {
      searchQuery.where('user_id', filters.authorId)
    }

    if (filters.status) {
      searchQuery.where('status', filters.status)
    } else {
      searchQuery.apply((scopes) => scopes.published())
    }

    if (filters.tagIds && filters.tagIds.length > 0) {
      searchQuery.whereHas('tags', (tagQuery) => {
        tagQuery.whereIn('tag_id', filters.tagIds!)
      })
    }

    return await searchQuery
      .preload('author')
      .preload('category')
      .preload('tags')
      .orderBy('published_at', 'desc')
      .paginate(page, limit)
  }

  private async generateUniqueSlug(title: string, excludeId?: number): Promise<string> {
    const baseSlug = slugify(title, { lower: true, strict: true })
    let slug = baseSlug
    let counter = 1

    while (true) {
      const query = Post.query().where('slug', slug)

      if (excludeId) {
        query.where('id', '!=', excludeId)
      }

      const existingPost = await query.first()

      if (!existingPost) {
        break
      }

      slug = `${baseSlug}-${counter}`
      counter++
    }

    return slug
  }

  private generateExcerpt(content: string, length: number = 160): string {
    // Strip HTML tags and get first N characters
    const plainText = content.replace(/<[^>]*>/g, '')
    return plainText.length > length
      ? plainText.substring(0, length).trim() + '...'
      : plainText
  }
}
```

## Installation & Setup

### Prerequisites

```bash
# Ensure Node.js and npm are installed
node --version  # Should be >= 16.x
npm --version

# Install AdonisJS CLI globally
npm install -g @adonisjs/cli
```

### Project Initialization

```bash
# Create new project
npm init adonisjs@latest my-blog

# Navigate to project
cd my-blog

# Choose project structure:
# - web (full-stack with views)
# - api (API only)
# - slim (minimal setup)

# Install dependencies
npm install

# Generate application key
node ace generate:key

# Start development server
node ace serve --watch
```

### Environment Configuration

```bash
# .env
NODE_ENV=development
PORT=3333
HOST=localhost
LOG_LEVEL=info
APP_KEY=your-secret-app-key

# Database
DB_CONNECTION=mysql
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=your_username
MYSQL_PASSWORD=your_password
MYSQL_DB_NAME=my_blog

# Redis (for sessions and cache)
REDIS_CONNECTION=local
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=

# Mail
MAIL_MAILER=smtp
SMTP_HOST=smtp.mailtrap.io
SMTP_PORT=2525
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password

# Session
SESSION_DRIVER=redis
SESSION_COOKIE_NAME=adonis-session

# Security
HASH_DRIVER=bcrypt
```

### Database Setup

```typescript
// config/database.ts
import Env from '@ioc:Adonis/Core/Env'
import { DatabaseConfig } from '@ioc:Adonis/Lucid/Database'

const databaseConfig: DatabaseConfig = {
  connection: Env.get('DB_CONNECTION'),

  connections: {
    mysql: {
      client: 'mysql2',
      connection: {
        host: Env.get('MYSQL_HOST'),
        port: Env.get('MYSQL_PORT'),
        user: Env.get('MYSQL_USER'),
        password: Env.get('MYSQL_PASSWORD', ''),
        database: Env.get('MYSQL_DB_NAME'),
      },
      migrations: {
        naturalSort: true,
        disableRollbacksInProduction: true,
      },
      healthCheck: false,
      debug: Env.get('DB_DEBUG', false),
      pool: {
        min: 2,
        max: 20,
      },
    },

    pg: {
      client: 'pg',
      connection: {
        host: Env.get('PG_HOST'),
        port: Env.get('PG_PORT'),
        user: Env.get('PG_USER'),
        password: Env.get('PG_PASSWORD', ''),
        database: Env.get('PG_DB_NAME'),
      },
      migrations: {
        naturalSort: true,
        disableRollbacksInProduction: true,
      },
      healthCheck: false,
      debug: Env.get('DB_DEBUG', false),
    },

    sqlite: {
      client: 'sqlite3',
      connection: {
        filename: Application.tmpPath('db.sqlite3'),
      },
      pool: {
        afterCreate: (conn, cb) => {
          conn.run('PRAGMA foreign_keys=true', cb)
        }
      },
      migrations: {
        naturalSort: true,
        disableRollbacksInProduction: true,
      },
      useNullAsDefault: true,
      healthCheck: false,
      debug: Env.get('DB_DEBUG', false),
    },
  }
}

export default databaseConfig
```

### Migrations

```bash
# Create migration
node ace make:migration create_users_table

# Create model with migration
node ace make:model User --migration

# Run migrations
node ace migration:run

# Rollback migrations
node ace migration:rollback

# Reset database
node ace migration:reset

# Check migration status
node ace migration:status
```

```typescript
// database/migrations/001_create_users_table.ts
import BaseSchema from '@ioc:Adonis/Lucid/Schema'

export default class extends BaseSchema {
  protected tableName = 'users'

  public async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').primary()
      table.string('email', 255).notNullable().unique()
      table.string('username', 255).notNullable().unique()
      table.string('password', 180).notNullable()
      table.string('first_name', 255).nullable()
      table.string('last_name', 255).nullable()
      table.boolean('is_active').defaultTo(true)
      table.timestamp('email_verified_at').nullable()
      table.string('remember_me_token').nullable()
      table.timestamps(true, true)
    })
  }

  public async down() {
    this.schema.dropTable(this.tableName)
  }
}
```

## Project Structure

### Recommended Directory Organization

```
my-blog/
├── app/
│   ├── Controllers/
│   │   └── Http/
│   │       ├── AuthController.ts
│   │       ├── PostsController.ts
│   │       ├── UsersController.ts
│   │       └── Admin/
│   │           ├── DashboardController.ts
│   │           └── PostsController.ts
│   ├── Models/
│   │   ├── User.ts
│   │   ├── Post.ts
│   │   ├── Category.ts
│   │   └── Comment.ts
│   ├── Middleware/
│   │   ├── Auth.ts
│   │   ├── AdminAuth.ts
│   │   ├── Throttle.ts
│   │   └── Cors.ts
│   ├── Services/
│   │   ├── AuthService.ts
│   │   ├── PostService.ts
│   │   ├── EmailService.ts
│   │   └── CacheService.ts
│   ├── Validators/
│   │   ├── Auth/
│   │   │   ├── LoginValidator.ts
│   │   │   └── RegisterValidator.ts
│   │   ├── Posts/
│   │   │   ├── CreatePostValidator.ts
│   │   │   └── UpdatePostValidator.ts
│   │   └── Users/
│   │       ├── CreateUserValidator.ts
│   │       └── UpdateUserValidator.ts
│   ├── Repositories/
│   │   ├── UserRepository.ts
│   │   ├── PostRepository.ts
│   │   └── BaseRepository.ts
│   ├── Listeners/
│   │   ├── UserListener.ts
│   │   ├── PostListener.ts
│   │   └── EmailListener.ts
│   ├── Exceptions/
│   │   ├── Handler.ts
│   │   ├── ValidationException.ts
│   │   └── AuthorizationException.ts
│   └── Utils/
│       ├── Helpers.ts
│       ├── Constants.ts
│       └── Types.ts
├── config/
│   ├── app.ts
│   ├── auth.ts
│   ├── database.ts
│   ├── mail.ts
│   ├── redis.ts
│   └── cors.ts
├── database/
│   ├── migrations/
│   ├── seeders/
│   └── factories/
├── resources/
│   ├── views/
│   │   ├── layouts/
│   │   ├── components/
│   │   ├── emails/
│   │   └── errors/
│   ├── css/
│   └── js/
├── start/
│   ├── routes.ts
│   ├── kernel.ts
│   ├── events.ts
│   └── socket.ts
├── tests/
│   ├── functional/
│   ├── unit/
│   └── bootstrap.ts
└── contracts/
    ├── events.ts
    └── services.ts
```

### Service Layer Implementation

```typescript
// app/Services/BaseService.ts
export default abstract class BaseService {
  protected logActivity(action: string, data: any = {}) {
    console.log(`Service Activity: ${action}`, data)
  }

  protected handleError(error: Error, context: string) {
    console.error(`Service Error in ${context}:`, error)
    throw error
  }
}

// app/Repositories/BaseRepository.ts
import { BaseModel, LucidModel } from '@ioc:Adonis/Lucid/Orm'

export default abstract class BaseRepository<T extends BaseModel> {
  constructor(protected model: LucidModel) {}

  public async findById(id: number): Promise<T | null> {
    return await this.model.find(id) as T
  }

  public async findByIdOrFail(id: number): Promise<T> {
    return await this.model.findOrFail(id) as T
  }

  public async create(data: Partial<T>): Promise<T> {
    return await this.model.create(data) as T
  }

  public async update(id: number, data: Partial<T>): Promise<T> {
    const record = await this.findByIdOrFail(id)
    record.merge(data)
    await record.save()
    return record
  }

  public async delete(id: number): Promise<void> {
    const record = await this.findByIdOrFail(id)
    await record.delete()
  }

  public async paginate(page: number = 1, limit: number = 20) {
    return await this.model.query().paginate(page, limit)
  }
}

// app/Repositories/UserRepository.ts
import User from 'App/Models/User'
import BaseRepository from './BaseRepository'

export default class UserRepository extends BaseRepository<User> {
  constructor() {
    super(User)
  }

  public async findByEmail(email: string): Promise<User | null> {
    return await User.findBy('email', email)
  }

  public async findByUsername(username: string): Promise<User | null> {
    return await User.findBy('username', username)
  }

  public async getActiveUsers(page: number = 1, limit: number = 20) {
    return await User.query()
      .apply((scopes) => scopes.active())
      .preload('profile')
      .paginate(page, limit)
  }

  public async searchUsers(query: string, page: number = 1, limit: number = 20) {
    return await User.query()
      .where((searchQuery) => {
        searchQuery
          .where('username', 'like', `%${query}%`)
          .orWhere('email', 'like', `%${query}%`)
          .orWhere('first_name', 'like', `%${query}%`)
          .orWhere('last_name', 'like', `%${query}%`)
      })
      .preload('profile')
      .paginate(page, limit)
  }
}
```

## Development Patterns

### Validation Patterns

```typescript
// app/Validators/Posts/CreatePostValidator.ts
import { schema, rules, CustomMessages } from '@ioc:Adonis/Core/Validator'
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'

export default class CreatePostValidator {
  constructor(protected ctx: HttpContextContract) {}

  public schema = schema.create({
    title: schema.string({ trim: true }, [
      rules.minLength(5),
      rules.maxLength(255),
      rules.unique({ table: 'posts', column: 'title' })
    ]),

    content: schema.string({}, [
      rules.minLength(100),
      rules.maxLength(50000)
    ]),

    excerpt: schema.string.optional({ trim: true }, [
      rules.maxLength(500)
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
    ]),

    featuredImage: schema.file.optional({
      size: '2mb',
      extnames: ['jpg', 'jpeg', 'png', 'webp']
    }),

    seoMetaTitle: schema.string.optional({ trim: true }, [
      rules.maxLength(60)
    ]),

    seoMetaDescription: schema.string.optional({ trim: true }, [
      rules.maxLength(160)
    ]),

    allowComments: schema.boolean.optional()
  })

  public messages: CustomMessages = {
    'title.required': 'Post title is required',
    'title.minLength': 'Title must be at least 5 characters long',
    'title.maxLength': 'Title cannot exceed 255 characters',
    'title.unique': 'A post with this title already exists',
    'content.required': 'Post content is required',
    'content.minLength': 'Content must be at least 100 characters long',
    'categoryId.required': 'Please select a category',
    'categoryId.exists': 'Selected category does not exist',
    'tags.*.exists': 'One or more selected tags do not exist',
    'publishedAt.after': 'Publish date must be in the future',
    'featuredImage.size': 'Featured image must be under 2MB',
    'featuredImage.extnames': 'Featured image must be a valid image file'
  }
}

// Custom validation rule
import { validator } from '@ioc:Adonis/Core/Validator'

validator.rule('uniqueSlug', (value, [table, column, ignoreId], { pointer, arrayExpressionPointer, errorReporter }) => {
  return new Promise(async (resolve) => {
    const query = Database.from(table).where(column, value)

    if (ignoreId) {
      query.whereNot('id', ignoreId)
    }

    const row = await query.first()

    if (row) {
      errorReporter.report(pointer, 'uniqueSlug', 'Slug must be unique', arrayExpressionPointer)
    }

    resolve()
  })
})

// Usage
export default class UpdatePostValidator {
  public schema = schema.create({
    slug: schema.string.optional({ trim: true }, [
      rules.uniqueSlug('posts', 'slug', this.ctx.params.id)
    ])
  })
}
```

### Middleware Patterns

```typescript
// app/Middleware/AdminAuth.ts
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import type { GuardsList } from '@ioc:Adonis/Addons/Auth'

export default class AdminAuth {
  protected redirectTo = '/login'

  public async handle(
    { auth, response }: HttpContextContract,
    next: () => Promise<void>,
    customGuards: (keyof GuardsList)[]
  ) {
    const guards = customGuards.length ? customGuards : [auth.name]

    await auth.authenticate()

    const user = auth.user!

    // Check if user is admin
    if (!await user.hasRole('admin')) {
      return response.forbidden({
        error: 'Access denied. Admin privileges required.'
      })
    }

    // Check if user account is active
    if (!user.isActive) {
      return response.forbidden({
        error: 'Account is deactivated'
      })
    }

    await next()
  }
}

// app/Middleware/RoleMiddleware.ts
export default class RoleMiddleware {
  public async handle(
    { auth, response }: HttpContextContract,
    next: () => Promise<void>,
    requiredRoles: string[]
  ) {
    await auth.authenticate()

    const user = auth.user!
    const userRoles = await user.related('roles').query()

    const hasRole = userRoles.some(role =>
      requiredRoles.includes(role.name)
    )

    if (!hasRole) {
      return response.forbidden({
        error: 'Insufficient permissions',
        required_roles: requiredRoles
      })
    }

    await next()
  }
}

// app/Middleware/Throttle.ts
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import Redis from '@ioc:Adonis/Addons/Redis'

export default class Throttle {
  public async handle(
    { request, response, auth }: HttpContextContract,
    next: () => Promise<void>,
    options: string[]
  ) {
    const [limitStr, windowStr] = options
    const limit = parseInt(limitStr, 10)
    const window = parseInt(windowStr, 10)

    const identifier = auth.user?.id || request.ip()
    const key = `throttle:${request.url()}:${identifier}`

    const current = await Redis.incr(key)

    if (current === 1) {
      await Redis.expire(key, window)
    }

    const ttl = await Redis.ttl(key)

    // Set rate limit headers
    response.header('X-RateLimit-Limit', limit.toString())
    response.header('X-RateLimit-Remaining', Math.max(0, limit - current).toString())
    response.header('X-RateLimit-Reset', (Date.now() + ttl * 1000).toString())

    if (current > limit) {
      return response.tooManyRequests({
        error: 'Too many requests',
        retry_after: ttl
      })
    }

    await next()
  }
}
```

### Event-Driven Architecture

```typescript
// contracts/events.ts
declare module '@ioc:Adonis/Core/Event' {
  interface EventsList {
    'user:registered': { user: User }
    'user:login': { user: User; ip: string; userAgent: string }
    'user:logout': { user: User }
    'post:created': { post: Post }
    'post:published': { post: Post }
    'post:updated': { post: Post }
    'post:deleted': { postId: number; slug: string }
    'comment:created': { comment: Comment }
    'email:sent': { to: string; subject: string; template: string }
  }
}

// app/Listeners/UserListener.ts
import Event from '@ioc:Adonis/Core/Event'
import Mail from '@ioc:Adonis/Addons/Mail'
import User from 'App/Models/User'
import Logger from '@ioc:Adonis/Core/Logger'

Event.on('user:registered', async ({ user }: { user: User }) => {
  try {
    // Send welcome email
    await Mail.send((message) => {
      message
        .to(user.email)
        .subject('Welcome to our platform!')
        .htmlView('emails/welcome', { user })
    })

    // Create user profile
    await user.related('profile').create({
      bio: '',
      website: '',
      location: '',
      avatarUrl: '/images/default-avatar.png'
    })

    // Assign default role
    await user.assignRole('user')

    // Log registration
    Logger.info(`New user registered: ${user.email}`)

    // Emit email sent event
    Event.emit('email:sent', {
      to: user.email,
      subject: 'Welcome to our platform!',
      template: 'emails/welcome'
    })

  } catch (error) {
    Logger.error('Error processing user registration', error)
  }
})

Event.on('user:login', async ({ user, ip, userAgent }) => {
  try {
    // Log login activity
    await user.related('loginHistory').create({
      ipAddress: ip,
      userAgent,
      loginAt: DateTime.now()
    })

    // Update last login
    user.lastLoginAt = DateTime.now()
    await user.save()

    Logger.info(`User login: ${user.email} from ${ip}`)

  } catch (error) {
    Logger.error('Error processing user login', error)
  }
})

// app/Listeners/PostListener.ts
Event.on('post:published', async ({ post }) => {
  try {
    // Send notifications to subscribers
    const subscribers = await User.query()
      .whereHas('subscriptions', (subscriptionQuery) => {
        subscriptionQuery.where('type', 'new_posts')
      })

    for (const subscriber of subscribers) {
      await Mail.send((message) => {
        message
          .to(subscriber.email)
          .subject(`New post: ${post.title}`)
          .htmlView('emails/new-post', { post, subscriber })
      })
    }

    // Clear cache
    await Redis.del('posts:*')

    Logger.info(`Post published: ${post.title}`)

  } catch (error) {
    Logger.error('Error processing post publication', error)
  }
})
```

## Security Best Practices

### Authentication and Authorization

```typescript
// config/auth.ts
import { AuthConfig } from '@ioc:Adonis/Addons/Auth'

const authConfig: AuthConfig = {
  guard: 'api',
  guards: {
    api: {
      driver: 'oat',
      tokenProvider: {
        type: 'api',
        driver: 'database',
        table: 'api_tokens',
        foreignKey: 'user_id',
      },
      provider: {
        driver: 'lucid',
        identifierKey: 'id',
        uids: ['email', 'username'],
        model: () => import('App/Models/User'),
      },
    },

    web: {
      driver: 'session',
      provider: {
        driver: 'lucid',
        identifierKey: 'id',
        uids: ['email', 'username'],
        model: () => import('App/Models/User'),
      },
    },
  },
}

export default authConfig

// app/Controllers/Http/AuthController.ts
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import User from 'App/Models/User'
import Hash from '@ioc:Adonis/Core/Hash'
import Event from '@ioc:Adonis/Core/Event'
import LoginValidator from 'App/Validators/Auth/LoginValidator'
import RegisterValidator from 'App/Validators/Auth/RegisterValidator'
import AuthService from 'App/Services/AuthService'

export default class AuthController {
  constructor(private authService: AuthService) {}

  public async register({ request, response }: HttpContextContract) {
    const payload = await request.validate(RegisterValidator)

    // Check if registration is allowed
    if (!await this.authService.isRegistrationAllowed()) {
      return response.forbidden({
        error: 'Registration is currently disabled'
      })
    }

    try {
      const user = await this.authService.register(payload)

      Event.emit('user:registered', { user })

      return response.created({
        message: 'Registration successful. Please check your email to verify your account.',
        user: user.serialize()
      })

    } catch (error) {
      return response.badRequest({
        error: 'Registration failed',
        details: error.message
      })
    }
  }

  public async login({ request, response, auth }: HttpContextContract) {
    const { email, password, remember } = await request.validate(LoginValidator)

    try {
      // Rate limiting check
      const canAttemptLogin = await this.authService.canAttemptLogin(email, request.ip())

      if (!canAttemptLogin) {
        return response.tooManyRequests({
          error: 'Too many login attempts. Please try again later.'
        })
      }

      // Find user
      const user = await User.query()
        .where('email', email)
        .orWhere('username', email)
        .preload('roles')
        .firstOrFail()

      // Verify password
      if (!(await Hash.verify(user.password, password))) {
        await this.authService.recordFailedLogin(email, request.ip())

        return response.unauthorized({
          error: 'Invalid credentials'
        })
      }

      // Check if account is active
      if (!user.isActive) {
        return response.forbidden({
          error: 'Account is deactivated'
        })
      }

      // Generate token
      const token = await auth.use('api').generate(user, {
        expiresIn: remember ? '30days' : '24hours'
      })

      // Clear failed login attempts
      await this.authService.clearFailedLogins(email)

      // Emit login event
      Event.emit('user:login', {
        user,
        ip: request.ip(),
        userAgent: request.header('user-agent') || ''
      })

      return response.ok({
        message: 'Login successful',
        user: user.serialize({
          fields: {
            omit: ['password']
          },
          relations: {
            roles: {
              fields: ['id', 'name']
            }
          }
        }),
        token: token.toJSON()
      })

    } catch (error) {
      await this.authService.recordFailedLogin(email, request.ip())

      return response.unauthorized({
        error: 'Invalid credentials'
      })
    }
  }

  public async logout({ auth, response }: HttpContextContract) {
    const user = auth.user!

    await auth.use('api').revoke()

    Event.emit('user:logout', { user })

    return response.ok({
      message: 'Logged out successfully'
    })
  }

  public async me({ auth, response }: HttpContextContract) {
    const user = auth.user!

    await user.load('profile')
    await user.load('roles')

    return response.ok({
      user: user.serialize({
        fields: {
          omit: ['password']
        }
      })
    })
  }

  public async refreshToken({ auth, response }: HttpContextContract) {
    const user = auth.user!

    const newToken = await auth.use('api').generate(user, {
      expiresIn: '24hours'
    })

    return response.ok({
      token: newToken.toJSON()
    })
  }
}
```

### Input Sanitization and XSS Prevention

```typescript
// app/Middleware/SanitizeInput.ts
import type { HttpContextContract } from '@ioc:Adonis/Core/HttpContext'
import DOMPurify from 'isomorphic-dompurify'

export default class SanitizeInput {
  public async handle({ request }: HttpContextContract, next: () => Promise<void>) {
    const body = request.body()

    if (body && typeof body === 'object') {
      this.sanitizeObject(body)
    }

    await next()
  }

  private sanitizeObject(obj: any): void {
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        if (typeof obj[key] === 'string') {
          // Basic XSS prevention
          obj[key] = this.sanitizeString(obj[key])
        } else if (typeof obj[key] === 'object' && obj[key] !== null) {
          this.sanitizeObject(obj[key])
        }
      }
    }
  }

  private sanitizeString(str: string): string {
    // Remove script tags and javascript: protocols
    str = str.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    str = str.replace(/javascript:/gi, '')
    str = str.replace(/on\w+="[^"]*"/g, '')
    str = str.replace(/on\w+='[^']*'/g, '')

    return str.trim()
  }

  public static sanitizeHtml(html: string): string {
    return DOMPurify.sanitize(html, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
      ALLOWED_ATTR: ['href', 'title'],
      ALLOWED_URI_REGEXP: /^https?:\/\//,
    })
  }
}
```

### CSRF Protection

```typescript
// config/shield.ts
import { ShieldConfig } from '@ioc:Adonis/Addons/Shield'

const shieldConfig: ShieldConfig = {
  csp: {
    enabled: true,
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
      fontSrc: ["'self'", 'https://fonts.gstatic.com'],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
    },
    reportOnly: false,
  },

  csrf: {
    enabled: true,
    exceptRoutes: ['/api/webhooks/*'],
    enableXsrfCookie: true,
    methods: ['POST', 'PUT', 'PATCH', 'DELETE'],
  },

  dnsPrefetchControl: {
    enabled: true,
    allow: false,
  },

  frameguard: {
    enabled: true,
    action: 'deny',
  },

  hidePoweredBy: {
    enabled: true,
  },

  hsts: {
    enabled: true,
    maxAge: '180 days',
    includeSubDomains: true,
    preload: false,
  },

  ieNoOpen: {
    enabled: true,
  },

  noSniff: {
    enabled: true,
  },

  referrerPolicy: {
    enabled: true,
    policy: 'same-origin',
  },

  xss: {
    enabled: true,
    enableOnOldIE: false,
  },
}

export default shieldConfig
```

### SQL Injection Prevention

```typescript
// Always use parameterized queries through Lucid ORM
// GOOD:
const users = await User.query()
  .where('email', email)
  .where('status', 'active')

// BAD: Raw queries without parameters
// const users = await Database.rawQuery(`SELECT * FROM users WHERE email = '${email}'`)

// Safe raw queries with bindings
const users = await Database.rawQuery(
  'SELECT * FROM users WHERE email = ? AND status = ?',
  [email, 'active']
)

// Advanced query building with security
class UserRepository {
  public async searchUsers(filters: {
    email?: string
    status?: string
    role?: string
    createdAfter?: DateTime
  }) {
    const query = User.query()

    // Safe parameter binding
    if (filters.email) {
      query.where('email', 'like', `%${filters.email}%`)
    }

    if (filters.status) {
      query.where('status', filters.status)
    }

    if (filters.role) {
      query.whereHas('roles', (roleQuery) => {
        roleQuery.where('name', filters.role)
      })
    }

    if (filters.createdAfter) {
      query.where('created_at', '>', filters.createdAfter)
    }

    return await query.paginate(1, 20)
  }
}
```

## Performance Optimization

### Database Query Optimization

```typescript
// app/Services/CacheService.ts
import Redis from '@ioc:Adonis/Addons/Redis'
import { DateTime } from 'luxon'

export default class CacheService {
  private readonly prefix = 'cache:'
  private readonly defaultTTL = 3600 // 1 hour

  public async get<T>(key: string): Promise<T | null> {
    try {
      const data = await Redis.get(`${this.prefix}${key}`)
      return data ? JSON.parse(data) : null
    } catch (error) {
      console.error('Cache get error:', error)
      return null
    }
  }

  public async set(key: string, value: any, ttl: number = this.defaultTTL): Promise<void> {
    try {
      await Redis.setex(
        `${this.prefix}${key}`,
        ttl,
        JSON.stringify(value)
      )
    } catch (error) {
      console.error('Cache set error:', error)
    }
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

  public async tags(tags: string[]): Promise<CacheTag> {
    return new CacheTag(this, tags)
  }
}

class CacheTag {
  constructor(
    private cacheService: CacheService,
    private tags: string[]
  ) {}

  public async remember<T>(
    key: string,
    ttl: number,
    callback: () => Promise<T>
  ): Promise<T> {
    const taggedKey = `${this.tags.join(':')}:${key}`

    // Store tag references
    for (const tag of this.tags) {
      await Redis.sadd(`tag:${tag}`, taggedKey)
    }

    return await this.cacheService.remember(taggedKey, ttl, callback)
  }

  public async flush(): Promise<void> {
    for (const tag of this.tags) {
      const keys = await Redis.smembers(`tag:${tag}`)
      if (keys.length) {
        await this.cacheService.flush(keys.join('|'))
        await Redis.del(`tag:${tag}`)
      }
    }
  }
}

// Usage in controllers
export default class PostsController {
  constructor(private cacheService: CacheService) {}

  public async index({ request, response }: HttpContextContract) {
    const page = request.input('page', 1)
    const category = request.input('category')

    const cacheKey = `posts:page:${page}:category:${category || 'all'}`

    const posts = await this.cacheService
      .tags(['posts', 'categories'])
      .remember(cacheKey, 600, async () => {
        const query = Post.query()
          .apply((scopes) => scopes.published())
          .preload('author', (authorQuery) => {
            authorQuery.select('id', 'username', 'email')
          })
          .preload('category')

        if (category) {
          query.whereHas('category', (categoryQuery) => {
            categoryQuery.where('slug', category)
          })
        }

        return await query
          .orderBy('published_at', 'desc')
          .paginate(page, 20)
      })

    return response.ok({ data: posts })
  }
}
```

### Query Optimization Patterns

```typescript
// Efficient relationship loading
class PostService {
  // BAD: N+1 Query Problem
  public async getPostsWithAuthors() {
    const posts = await Post.all()

    for (const post of posts) {
      // This creates N additional queries
      post.author = await post.related('author').query().first()
    }

    return posts
  }

  // GOOD: Eager Loading
  public async getPostsWithAuthorsOptimized() {
    return await Post.query()
      .preload('author', (authorQuery) => {
        authorQuery.select('id', 'username', 'email') // Only select needed fields
      })
      .preload('category')
      .preload('tags')
  }

  // Advanced optimization with conditional loading
  public async getPostsAdvanced(options: {
    includeAuthor?: boolean
    includeComments?: boolean
    includeRelated?: boolean
  } = {}) {
    const query = Post.query()

    if (options.includeAuthor) {
      query.preload('author', (authorQuery) => {
        authorQuery.select('id', 'username', 'email', 'avatar_url')
      })
    }

    if (options.includeComments) {
      query.preload('comments', (commentsQuery) => {
        commentsQuery
          .where('status', 'approved')
          .preload('author')
          .orderBy('created_at', 'desc')
          .limit(5)
      })
    }

    return await query
  }

  // Optimized pagination with counting
  public async getPaginatedPosts(page: number, limit: number) {
    const query = Post.query()
      .apply((scopes) => scopes.published())
      .preload('author')
      .preload('category')

    // Use paginate for automatic counting
    return await query.paginate(page, limit)
  }

  // Custom pagination for better performance
  public async getCustomPaginatedPosts(page: number, limit: number) {
    const offset = (page - 1) * limit

    // Get total count (cached)
    const totalKey = 'posts:total:published'
    const total = await this.cacheService.remember(totalKey, 300, async () => {
      return await Post.query()
        .apply((scopes) => scopes.published())
        .count('* as total')
        .then(result => result[0].$extras.total)
    })

    // Get posts
    const posts = await Post.query()
      .apply((scopes) => scopes.published())
      .preload('author')
      .preload('category')
      .orderBy('published_at', 'desc')
      .offset(offset)
      .limit(limit)

    return {
      data: posts,
      meta: {
        total,
        perPage: limit,
        currentPage: page,
        lastPage: Math.ceil(total / limit),
        firstPage: 1,
        firstPageUrl: `/posts?page=1`,
        lastPageUrl: `/posts?page=${Math.ceil(total / limit)}`,
        nextPageUrl: page < Math.ceil(total / limit) ? `/posts?page=${page + 1}` : null,
        previousPageUrl: page > 1 ? `/posts?page=${page - 1}` : null,
      }
    }
  }
}

// Database indexing in migrations
export default class extends BaseSchema {
  public async up() {
    this.schema.createTable('posts', (table) => {
      table.increments('id')
      table.string('title').notNullable()
      table.string('slug').unique().notNullable()
      table.text('content').notNullable()
      table.enum('status', ['draft', 'published', 'archived']).defaultTo('draft')
      table.integer('user_id').unsigned().references('id').inTable('users')
      table.integer('category_id').unsigned().references('id').inTable('categories')
      table.integer('views_count').defaultTo(0)
      table.timestamp('published_at').nullable()
      table.timestamps(true, true)

      // Important indexes for performance
      table.index(['status', 'published_at']) // For published posts queries
      table.index(['user_id']) // For author-based queries
      table.index(['category_id']) // For category-based queries
      table.index(['slug']) // For single post lookups
      table.index(['created_at']) // For sorting
    })
  }
}
```

### Background Job Processing

```typescript
// app/Jobs/SendEmailJob.ts
import Bull from '@ioc:Rocketseat/Bull'
import Mail from '@ioc:Adonis/Addons/Mail'

interface EmailJobData {
  to: string
  subject: string
  template: string
  data: any
}

export default class SendEmailJob implements Bull.JobContract {
  public key = 'SendEmail'

  public async handle(job: Bull.JobContract<EmailJobData>) {
    const { to, subject, template, data } = job.data

    try {
      await Mail.send((message) => {
        message
          .to(to)
          .subject(subject)
          .htmlView(template, data)
      })

      console.log(`Email sent successfully to ${to}`)
    } catch (error) {
      console.error('Failed to send email:', error)
      throw error // This will retry the job
    }
  }

  public async failed(job: Bull.JobContract<EmailJobData>, error: Error) {
    console.error('Email job failed:', error)

    // Log to monitoring service
    // Sentry.captureException(error)
  }
}

// app/Services/EmailService.ts
import Bull from '@ioc:Rocketseat/Bull'
import SendEmailJob from 'App/Jobs/SendEmailJob'

export default class EmailService {
  public async sendWelcomeEmail(user: User) {
    await Bull.add(new SendEmailJob().key, {
      to: user.email,
      subject: 'Welcome to our platform!',
      template: 'emails/welcome',
      data: { user }
    })
  }

  public async sendPasswordResetEmail(user: User, token: string) {
    await Bull.add(new SendEmailJob().key, {
      to: user.email,
      subject: 'Password Reset Request',
      template: 'emails/password-reset',
      data: { user, token, resetUrl: `${Env.get('APP_URL')}/reset-password?token=${token}` }
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000,
      }
    })
  }

  public async sendBulkNewsletter(subscribers: User[], newsletter: Newsletter) {
    const jobs = subscribers.map(subscriber => ({
      name: new SendEmailJob().key,
      data: {
        to: subscriber.email,
        subject: newsletter.subject,
        template: 'emails/newsletter',
        data: { subscriber, newsletter }
      }
    }))

    await Bull.addBulk(jobs)
  }
}
```

## Testing Strategies

### Unit Testing

```typescript
// tests/unit/services/post-service.spec.ts
import { test } from '@japa/runner'
import PostService from 'App/Services/PostService'
import { PostFactory, UserFactory, CategoryFactory } from 'Database/factories'
import Database from '@ioc:Adonis/Lucid/Database'

test.group('PostService', (group) => {
  group.each.setup(async () => {
    await Database.beginGlobalTransaction()
    return () => Database.rollbackGlobalTransaction()
  })

  test('creates post with valid data', async ({ assert }) => {
    const user = await UserFactory.create()
    const category = await CategoryFactory.create()
    const service = new PostService()

    const postData = {
      title: 'Test Post Title',
      content: 'This is a test post content that is long enough to pass validation.',
      categoryId: category.id,
      userId: user.id
    }

    const post = await service.createPost(postData)

    assert.exists(post.id)
    assert.equal(post.title, postData.title)
    assert.equal(post.slug, 'test-post-title')
    assert.equal(post.status, 'draft')
    assert.equal(post.userId, user.id)
  })

  test('generates unique slug for duplicate titles', async ({ assert }) => {
    const user = await UserFactory.create()
    const category = await CategoryFactory.create()
    const service = new PostService()

    // Create first post
    await service.createPost({
      title: 'Duplicate Title',
      content: 'First post content that is long enough.',
      categoryId: category.id,
      userId: user.id
    })

    // Create second post with same title
    const secondPost = await service.createPost({
      title: 'Duplicate Title',
      content: 'Second post content that is long enough.',
      categoryId: category.id,
      userId: user.id
    })

    assert.equal(secondPost.slug, 'duplicate-title-1')
  })

  test('publishes post successfully', async ({ assert }) => {
    const post = await PostFactory.merge({ status: 'draft' }).create()
    const service = new PostService()

    const publishedPost = await service.publishPost(post)

    assert.equal(publishedPost.status, 'published')
    assert.exists(publishedPost.publishedAt)
  })

  test('throws error when updating non-existent post', async ({ assert }) => {
    const service = new PostService()
    const nonExistentPost = { id: 999 }

    await assert.rejects(
      () => service.updatePost(nonExistentPost as any, { title: 'New Title' }),
      'E_ROW_NOT_FOUND'
    )
  })

  test('searches posts by query', async ({ assert }) => {
    const user = await UserFactory.create()
    const category = await CategoryFactory.create()

    await PostFactory.merge({
      title: 'JavaScript Fundamentals',
      content: 'Learn JavaScript basics',
      status: 'published',
      userId: user.id,
      categoryId: category.id
    }).create()

    await PostFactory.merge({
      title: 'Python Tutorial',
      content: 'Learn Python programming',
      status: 'published',
      userId: user.id,
      categoryId: category.id
    }).create()

    const service = new PostService()
    const results = await service.searchPosts('JavaScript')

    assert.equal(results.length, 1)
    assert.equal(results[0].title, 'JavaScript Fundamentals')
  })
})

// tests/unit/models/user.spec.ts
test.group('User Model', (group) => {
  group.each.setup(async () => {
    await Database.beginGlobalTransaction()
    return () => Database.rollbackGlobalTransaction()
  })

  test('hashes password before saving', async ({ assert }) => {
    const user = await UserFactory.merge({
      password: 'plain-password'
    }).create()

    assert.notEqual(user.password, 'plain-password')
    assert.isTrue(await Hash.verify(user.password, 'plain-password'))
  })

  test('generates full name correctly', async ({ assert }) => {
    const user = await UserFactory.merge({
      firstName: 'John',
      lastName: 'Doe'
    }).create()

    assert.equal(user.fullName, 'John Doe')
  })

  test('checks role membership', async ({ assert }) => {
    const user = await UserFactory.create()
    const role = await RoleFactory.merge({ name: 'admin' }).create()

    await user.related('roles').attach([role.id])

    const hasRole = await user.hasRole('admin')
    assert.isTrue(hasRole)

    const hasOtherRole = await user.hasRole('moderator')
    assert.isFalse(hasOtherRole)
  })
})
```

### Integration Testing

```typescript
// tests/functional/auth.spec.ts
import { test } from '@japa/runner'
import { UserFactory } from 'Database/factories'
import Database from '@ioc:Adonis/Lucid/Database'

test.group('Authentication', (group) => {
  group.each.setup(async () => {
    await Database.beginGlobalTransaction()
    return () => Database.rollbackGlobalTransaction()
  })

  test('user can register with valid data', async ({ client, assert }) => {
    const userData = {
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      firstName: 'Test',
      lastName: 'User'
    }

    const response = await client
      .post('/api/v1/auth/register')
      .json(userData)

    response.assertStatus(201)
    response.assertBodyContains({
      message: 'Registration successful'
    })

    // Verify user was created in database
    const user = await User.findBy('email', userData.email)
    assert.exists(user)
    assert.equal(user!.username, userData.username)
  })

  test('registration fails with invalid email', async ({ client }) => {
    const userData = {
      username: 'testuser',
      email: 'invalid-email',
      password: 'password123',
      password_confirmation: 'password123'
    }

    const response = await client
      .post('/api/v1/auth/register')
      .json(userData)

    response.assertStatus(422)
    response.assertBodyContains({
      errors: {
        email: ['Please enter a valid email address']
      }
    })
  })

  test('user can login with valid credentials', async ({ client, assert }) => {
    const user = await UserFactory.merge({
      email: 'test@example.com',
      password: 'password123'
    }).create()

    const response = await client
      .post('/api/v1/auth/login')
      .json({
        email: 'test@example.com',
        password: 'password123'
      })

    response.assertStatus(200)
    response.assertBodyContains({
      message: 'Login successful'
    })

    const body = response.body()
    assert.exists(body.token)
    assert.equal(body.user.email, user.email)
  })

  test('login fails with invalid credentials', async ({ client }) => {
    await UserFactory.merge({
      email: 'test@example.com',
      password: 'password123'
    }).create()

    const response = await client
      .post('/api/v1/auth/login')
      .json({
        email: 'test@example.com',
        password: 'wrong-password'
      })

    response.assertStatus(401)
    response.assertBodyContains({
      error: 'Invalid credentials'
    })
  })

  test('user can access protected routes with token', async ({ client }) => {
    const user = await UserFactory.create()

    const loginResponse = await client
      .post('/api/v1/auth/login')
      .json({
        email: user.email,
        password: 'password123'
      })

    const { token } = loginResponse.body()

    const protectedResponse = await client
      .get('/api/v1/auth/me')
      .header('Authorization', `Bearer ${token.token}`)

    protectedResponse.assertStatus(200)
    protectedResponse.assertBodyContains({
      user: {
        id: user.id,
        email: user.email
      }
    })
  })

  test('protected route returns 401 without token', async ({ client }) => {
    const response = await client.get('/api/v1/auth/me')

    response.assertStatus(401)
  })
})

// tests/functional/posts.spec.ts
test.group('Posts API', (group) => {
  group.each.setup(async () => {
    await Database.beginGlobalTransaction()
    return () => Database.rollbackGlobalTransaction()
  })

  test('can fetch published posts', async ({ client, assert }) => {
    await PostFactory.merge({ status: 'published' }).createMany(5)
    await PostFactory.merge({ status: 'draft' }).createMany(3)

    const response = await client.get('/api/v1/posts')

    response.assertStatus(200)

    const body = response.body()
    assert.equal(body.data.length, 5) // Only published posts
    assert.exists(body.meta)
  })

  test('can create post when authenticated', async ({ client }) => {
    const user = await UserFactory.create()
    const category = await CategoryFactory.create()
    const token = await auth.use('api').generate(user)

    const postData = {
      title: 'New Test Post',
      content: 'This is a test post content that is long enough to pass validation.',
      categoryId: category.id
    }

    const response = await client
      .post('/api/v1/posts')
      .header('Authorization', `Bearer ${token.token}`)
      .json(postData)

    response.assertStatus(201)
    response.assertBodyContains({
      message: 'Post created successfully'
    })

    const post = await Post.findBy('title', postData.title)
    assert.exists(post)
    assert.equal(post!.userId, user.id)
  })

  test('cannot create post without authentication', async ({ client }) => {
    const postData = {
      title: 'New Test Post',
      content: 'This is a test post content.'
    }

    const response = await client
      .post('/api/v1/posts')
      .json(postData)

    response.assertStatus(401)
  })
})
```

### End-to-End Testing

```typescript
// tests/e2e/user-journey.spec.ts
import { test } from '@japa/runner'
import { chromium, Browser, Page } from 'playwright'

test.group('User Journey E2E', (group) => {
  let browser: Browser
  let page: Page

  group.setup(async () => {
    browser = await chromium.launch()
  })

  group.teardown(async () => {
    await browser?.close()
  })

  group.each.setup(async () => {
    page = await browser.newPage()
    await Database.beginGlobalTransaction()
    return async () => {
      await page?.close()
      await Database.rollbackGlobalTransaction()
    }
  })

  test('complete user registration and login flow', async ({ assert }) => {
    // Navigate to registration page
    await page.goto('http://localhost:3333/register')

    // Fill registration form
    await page.fill('[name="username"]', 'testuser')
    await page.fill('[name="email"]', 'test@example.com')
    await page.fill('[name="password"]', 'password123')
    await page.fill('[name="password_confirmation"]', 'password123')
    await page.fill('[name="firstName"]', 'Test')
    await page.fill('[name="lastName"]', 'User')

    // Submit form
    await page.click('button[type="submit"]')

    // Wait for success message
    const successMessage = await page.waitForSelector('.success-message')
    const messageText = await successMessage.textContent()
    assert.include(messageText, 'Registration successful')

    // Navigate to login page
    await page.goto('http://localhost:3333/login')

    // Fill login form
    await page.fill('[name="email"]', 'test@example.com')
    await page.fill('[name="password"]', 'password123')

    // Submit login
    await page.click('button[type="submit"]')

    // Wait for redirect to dashboard
    await page.waitForURL('**/dashboard')

    // Verify user is logged in
    const userMenu = await page.waitForSelector('[data-test="user-menu"]')
    assert.exists(userMenu)

    // Verify user name is displayed
    const userName = await page.textContent('[data-test="user-name"]')
    assert.equal(userName, 'Test User')
  })

  test('create and publish blog post', async ({ assert }) => {
    // Login first
    const user = await UserFactory.create()
    await loginAsUser(page, user)

    // Navigate to create post page
    await page.goto('http://localhost:3333/posts/create')

    // Fill post form
    await page.fill('[name="title"]', 'My First Blog Post')
    await page.fill('[name="content"]', 'This is the content of my first blog post. It contains enough text to pass validation requirements.')
    await page.selectOption('[name="categoryId"]', '1')

    // Upload featured image
    await page.setInputFiles('[name="featuredImage"]', 'tests/fixtures/test-image.jpg')

    // Add tags
    await page.click('[data-test="add-tag"]')
    await page.selectOption('[name="tags[]"]', '1')

    // Save as draft
    await page.click('button[data-action="save-draft"]')

    // Wait for success message
    const draftMessage = await page.waitForSelector('.success-message')
    assert.include(await draftMessage.textContent(), 'Post saved as draft')

    // Publish the post
    await page.click('button[data-action="publish"]')

    // Confirm publication
    await page.click('button[data-action="confirm-publish"]')

    // Verify post is published
    const publishMessage = await page.waitForSelector('.success-message')
    assert.include(await publishMessage.textContent(), 'Post published successfully')

    // Navigate to public blog to verify post is visible
    await page.goto('http://localhost:3333/blog')

    // Find the published post
    const postLink = await page.waitForSelector(`a:has-text("My First Blog Post")`)
    assert.exists(postLink)

    // Click on post to view details
    await postLink.click()

    // Verify post content is displayed
    const postContent = await page.waitForSelector('[data-test="post-content"]')
    const content = await postContent.textContent()
    assert.include(content, 'This is the content of my first blog post')
  })

  async function loginAsUser(page: Page, user: User) {
    await page.goto('http://localhost:3333/login')
    await page.fill('[name="email"]', user.email)
    await page.fill('[name="password"]', 'password123')
    await page.click('button[type="submit"]')
    await page.waitForURL('**/dashboard')
  }
})
```

## Deployment Guide

### Production Environment Setup

```bash
# Production environment variables
# .env.production
NODE_ENV=production
PORT=3333
HOST=0.0.0.0
LOG_LEVEL=info
APP_KEY=your-secure-production-key

# Database
DB_CONNECTION=mysql
MYSQL_HOST=your-db-host
MYSQL_PORT=3306
MYSQL_USER=your-production-user
MYSQL_PASSWORD=your-secure-password
MYSQL_DB_NAME=your_production_db

# Redis
REDIS_CONNECTION=local
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# Mail
MAIL_MAILER=ses
SES_ACCESS_KEY=your-access-key
SES_ACCESS_SECRET=your-secret-key
SES_REGION=us-east-1

# Session
SESSION_DRIVER=redis
SESSION_COOKIE_NAME=adonis-session

# Performance
CACHE_VIEWS=true
ASSETS_DRIVER=s3
S3_KEY=your-s3-key
S3_SECRET=your-s3-secret
S3_BUCKET=your-bucket-name
S3_REGION=us-east-1

# Monitoring
SENTRY_DSN=your-sentry-dsn
NEW_RELIC_LICENSE_KEY=your-new-relic-key
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Build the app
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate Prisma client and build
RUN npm run build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 adonisjs

# Copy built application
COPY --from=builder --chown=adonisjs:nodejs /app/build ./
COPY --from=builder --chown=adonisjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=adonisjs:nodejs /app/package.json ./package.json

USER adonisjs

EXPOSE 3333

ENV PORT 3333

CMD ["node", "server.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3333:3333"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis
    volumes:
      - ./uploads:/app/uploads
    restart: unless-stopped

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=adonis_app
      - MYSQL_USER=adonis
      - MYSQL_PASSWORD=password
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped

volumes:
  mysql_data:
  redis_data:
```

### Nginx Configuration

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream app {
        server app:3333;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

    server {
        listen 80;
        server_name yourdomain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name yourdomain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

        # Gzip compression
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types
            text/css
            text/javascript
            text/xml
            text/plain
            application/javascript
            application/xml+rss
            application/json;

        # Static files
        location /static/ {
            alias /app/public/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # API rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # Login rate limiting
        location /api/auth/login {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Default proxy
        location / {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: test_db
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

      redis:
        image: redis:alpine
        options: >-
          --health-cmd="redis-cli ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test
        env:
          DB_CONNECTION: mysql
          MYSQL_HOST: 127.0.0.1
          MYSQL_PORT: 3306
          MYSQL_USER: root
          MYSQL_PASSWORD: root
          MYSQL_DB_NAME: test_db
          REDIS_HOST: 127.0.0.1
          REDIS_PORT: 6379

  build:
    needs: test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.sha }} .
          docker tag myapp:${{ github.sha }} myapp:latest

      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push myapp:${{ github.sha }}
          docker push myapp:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.KEY }}
          script: |
            cd /app
            docker-compose pull
            docker-compose up -d
            docker image prune -f
```

## Common Pitfalls

### Memory Leaks and Performance Issues

```typescript
// BAD: Memory leaks from not cleaning up event listeners
class BadWebSocketService {
  private connections: Set<WebSocket> = new Set()

  public addConnection(ws: WebSocket) {
    this.connections.add(ws)

    // Memory leak: no cleanup on disconnect
    ws.on('message', this.handleMessage.bind(this))
  }

  private handleMessage(data: string) {
    // Process message
  }
}

// GOOD: Proper cleanup and memory management
class GoodWebSocketService {
  private connections: Map<string, WebSocket> = new Map()

  public addConnection(connectionId: string, ws: WebSocket) {
    this.connections.set(connectionId, ws)

    ws.on('message', this.handleMessage.bind(this))
    ws.on('close', () => this.removeConnection(connectionId))
    ws.on('error', () => this.removeConnection(connectionId))
  }

  public removeConnection(connectionId: string) {
    const ws = this.connections.get(connectionId)
    if (ws) {
      ws.removeAllListeners()
      this.connections.delete(connectionId)
    }
  }

  private handleMessage(data: string) {
    // Process message
  }

  public shutdown() {
    for (const [id, ws] of this.connections) {
      ws.close()
      this.removeConnection(id)
    }
  }
}
```

### N+1 Query Problems

```typescript
// BAD: N+1 queries
class BadPostService {
  async getPostsWithAuthors() {
    const posts = await Post.all()

    // This creates N additional queries!
    for (const post of posts) {
      post.author = await post.related('author').query().first()
    }

    return posts
  }
}

// GOOD: Proper eager loading
class GoodPostService {
  async getPostsWithAuthors() {
    return await Post.query()
      .preload('author')
      .preload('category')
      .preload('tags')
  }

  // Even better: Selective field loading
  async getPostsOptimized() {
    return await Post.query()
      .preload('author', (authorQuery) => {
        authorQuery.select('id', 'username', 'email')
      })
      .preload('category', (categoryQuery) => {
        categoryQuery.select('id', 'name', 'slug')
      })
      .select('id', 'title', 'slug', 'excerpt', 'created_at')
  }
}
```

### Security Vulnerabilities

```typescript
// BAD: SQL injection vulnerability
class VulnerableUserService {
  async searchUsers(query: string) {
    // NEVER DO THIS!
    return await Database.rawQuery(`
      SELECT * FROM users WHERE name LIKE '%${query}%'
    `)
  }
}

// GOOD: Parameterized queries
class SecureUserService {
  async searchUsers(query: string) {
    return await Database.rawQuery(
      'SELECT * FROM users WHERE name LIKE ?',
      [`%${query}%`]
    )
  }

  // Even better: Use ORM methods
  async searchUsersWithORM(query: string) {
    return await User.query()
      .where('name', 'like', `%${query}%`)
      .orWhere('email', 'like', `%${query}%`)
  }
}

// BAD: Exposing sensitive data
class BadAuthController {
  async getUsers({ response }: HttpContextContract) {
    const users = await User.all()

    // Exposes password hashes!
    return response.ok(users)
  }
}

// GOOD: Selective serialization
class GoodAuthController {
  async getUsers({ response }: HttpContextContract) {
    const users = await User.all()

    return response.ok(users.map(user => user.serialize({
      fields: {
        omit: ['password', 'rememberMeToken']
      }
    })))
  }
}
```

## Troubleshooting

### Common Development Issues

```typescript
// Database connection issues
// Check database configuration
export default class DatabaseTroubleshooter {
  static async checkConnection() {
    try {
      await Database.rawQuery('SELECT 1')
      console.log('✅ Database connection successful')
    } catch (error) {
      console.error('❌ Database connection failed:', error.message)

      // Common fixes:
      console.log('Try these solutions:')
      console.log('1. Check database credentials in .env')
      console.log('2. Ensure database server is running')
      console.log('3. Check firewall/network connectivity')
      console.log('4. Verify database exists')
    }
  }

  static async checkMigrations() {
    try {
      const pendingMigrations = await Database.rawQuery(`
        SELECT name FROM adonis_schema
        WHERE batch IS NULL
      `)

      if (pendingMigrations.length > 0) {
        console.log('⚠️  Pending migrations found:')
        pendingMigrations.forEach(m => console.log(`  - ${m.name}`))
        console.log('Run: node ace migration:run')
      } else {
        console.log('✅ All migrations are up to date')
      }
    } catch (error) {
      console.error('❌ Migration check failed:', error.message)
    }
  }
}

// Performance debugging
export default class PerformanceDebugger {
  static enableQueryLogging() {
    Database.on('query', (query) => {
      console.log('📊 SQL Query:', query.sql)
      console.log('📊 Bindings:', query.bindings)
      console.log('📊 Duration:', query.duration, 'ms')
      console.log('---')
    })
  }

  static async analyzeSlowQueries() {
    // Enable slow query logging
    await Database.rawQuery('SET GLOBAL slow_query_log = 1')
    await Database.rawQuery('SET GLOBAL long_query_time = 1')

    console.log('✅ Slow query logging enabled (queries > 1s)')
  }

  static memoryUsage() {
    const usage = process.memoryUsage()
    console.log('🔍 Memory Usage:')
    console.log(`  RSS: ${Math.round(usage.rss / 1024 / 1024)} MB`)
    console.log(`  Heap Used: ${Math.round(usage.heapUsed / 1024 / 1024)} MB`)
    console.log(`  Heap Total: ${Math.round(usage.heapTotal / 1024 / 1024)} MB`)
    console.log(`  External: ${Math.round(usage.external / 1024 / 1024)} MB`)
  }
}
```

### Error Debugging

```typescript
// Enhanced error handling
export default class ErrorDebugger {
  static setupGlobalErrorHandling() {
    process.on('uncaughtException', (error) => {
      console.error('🚨 Uncaught Exception:', error)
      // Log to monitoring service
      this.logToMonitoring(error)
      process.exit(1)
    })

    process.on('unhandledRejection', (reason, promise) => {
      console.error('🚨 Unhandled Rejection at:', promise, 'reason:', reason)
      // Log to monitoring service
      this.logToMonitoring(reason)
    })
  }

  static logToMonitoring(error: any) {
    // Integration with monitoring services
    // Sentry.captureException(error)
    // Winston logger, etc.
    console.error('Error logged to monitoring service:', error.message)
  }

  static debugValidationErrors(errors: any) {
    console.log('🔍 Validation Errors:')
    Object.entries(errors).forEach(([field, messages]) => {
      console.log(`  ${field}: ${Array.isArray(messages) ? messages.join(', ') : messages}`)
    })
  }

  static debugAuthenticationIssues(context: HttpContextContract) {
    console.log('🔍 Authentication Debug:')
    console.log('  Headers:', context.request.headers())
    console.log('  Auth Guard:', context.auth.defaultGuard)
    console.log('  Is Authenticated:', context.auth.isAuthenticated)
    console.log('  User:', context.auth.user)
  }
}
```

## Best Practices Summary

### Code Organization
1. **Follow MVC Pattern**: Keep controllers thin, models focused, and business logic in services
2. **Use Dependency Injection**: Leverage AdonisJS IoC container for better testability
3. **Implement Repository Pattern**: Abstract database operations for better maintainability
4. **Event-Driven Architecture**: Use events for decoupled, scalable applications

### Performance
1. **Database Optimization**: Use eager loading, proper indexing, and query optimization
2. **Caching Strategy**: Implement Redis caching for frequently accessed data
3. **Background Jobs**: Use queues for time-consuming operations
4. **Asset Optimization**: Minify and compress static assets

### Security
1. **Input Validation**: Always validate and sanitize user input
2. **Authentication**: Use strong authentication mechanisms and JWT tokens
3. **Authorization**: Implement role-based access control
4. **HTTPS**: Always use HTTPS in production environments

### Testing
1. **Comprehensive Coverage**: Write unit, integration, and E2E tests
2. **Test Database**: Use separate test database with proper cleanup
3. **Mock External Services**: Mock third-party APIs and services
4. **Continuous Integration**: Automate testing in CI/CD pipeline

### Deployment
1. **Environment Configuration**: Use environment variables for configuration
2. **Docker Containers**: Containerize applications for consistent deployment
3. **Load Balancing**: Use reverse proxy for production traffic
4. **Monitoring**: Implement comprehensive logging and monitoring

## Conclusion

AdonisJS provides a comprehensive, TypeScript-first framework that brings the best of modern web development to the Node.js ecosystem. Its strong conventions, extensive feature set, and developer-friendly approach make it an excellent choice for building scalable, maintainable applications.

The framework's strength lies in its "batteries included" philosophy, providing everything needed to build production-ready applications without the complexity of assembling multiple packages. The strong TypeScript integration ensures type safety throughout the application, while the extensive ecosystem of official packages reduces development time.

However, AdonisJS may not be suitable for all projects. Its opinionated nature and comprehensive feature set make it ideal for medium to large applications but potentially overkill for simple APIs or microservices. The learning curve can be steep for developers new to TypeScript or MVC patterns.

Success with AdonisJS comes from embracing its conventions and leveraging its powerful features like the Lucid ORM, built-in validation, authentication system, and event-driven architecture. The framework's focus on developer ergonomics and productivity makes it an excellent choice for teams building complex web applications.

The framework continues to evolve with regular updates, strong community support, and comprehensive documentation. Its commitment to TypeScript and modern development practices positions it well for future growth in the Node.js ecosystem.

## Resources

### Official Documentation
- [AdonisJS Official Website](https://adonisjs.com/)
- [AdonisJS Documentation](https://docs.adonisjs.com/)
- [AdonisJS GitHub Repository](https://github.com/adonisjs)
- [AdonisJS CLI Documentation](https://docs.adonisjs.com/guides/ace-commandline)

### Learning Resources
- [Adocasts - AdonisJS Video Tutorials](https://adocasts.com/)
- [AdonisJS Mastery Course](https://adonismastery.com/)
- [AdonisJS Blog](https://blog.adonisjs.com/)
- [Community Tutorials](https://github.com/adonisjs/awesome-adonisjs)

### Tools and Packages
- [Lucid ORM Documentation](https://docs.adonisjs.com/guides/database/introduction)
- [Auth Package](https://docs.adonisjs.com/guides/auth/introduction)
- [Validator Package](https://docs.adonisjs.com/guides/validator/introduction)
- [Mail Package](https://docs.adonisjs.com/guides/mail)
- [WebSocket Package](https://docs.adonisjs.com/guides/websocket)

### Community
- [AdonisJS Discord](https://discord.gg/vDcEjq6)
- [AdonisJS Forum](https://github.com/adonisjs/core/discussions)
- [AdonisJS Twitter](https://twitter.com/adonisframework)
- [Reddit Community](https://www.reddit.com/r/adonisjs/)

### Testing Tools
- [Japa Testing Framework](https://japa.dev/)
- [Playwright](https://playwright.dev/)
- [Supertest](https://github.com/visionmedia/supertest)

### Deployment and DevOps
- [PM2 Process Manager](https://pm2.keymetrics.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [GitHub Actions](https://docs.github.com/en/actions)

### Monitoring and Analytics
- [Sentry Error Tracking](https://sentry.io/)
- [New Relic APM](https://newrelic.com/)
- [DataDog Monitoring](https://www.datadoghq.com/)
- [Winston Logging](https://github.com/winstonjs/winston)