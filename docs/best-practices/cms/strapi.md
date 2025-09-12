# Strapi Best Practices

## Overview

Strapi is an open-source headless CMS that gives developers the freedom to choose their favorite tools and frameworks while allowing content editors to manage and distribute content using a customizable admin panel.

### Use Cases
- Content management for websites and applications
- E-commerce product catalogs
- Multi-channel content distribution
- API-first content delivery
- Digital asset management
- Multi-language content management

## Setup and Configuration

### Initial Setup

```bash
# Create a new Strapi project
npx create-strapi-app@latest my-project

# Choose installation type:
# - Quickstart (SQLite)
# - Custom (manual settings)

cd my-project
npm run develop
```

### Project Structure

```
my-project/
├── config/
│   ├── database.js       # Database configuration
│   ├── server.js         # Server configuration
│   ├── admin.js          # Admin panel configuration
│   └── plugins.js        # Plugin configuration
├── src/
│   ├── api/              # API endpoints
│   │   └── [model]/
│   │       ├── content-types/
│   │       ├── controllers/
│   │       ├── routes/
│   │       └── services/
│   ├── extensions/       # Plugin extensions
│   ├── plugins/          # Custom plugins
│   └── admin/           # Admin customizations
├── public/              # Public assets
└── database/
    └── migrations/      # Database migrations
```

### Environment Configuration

```javascript
// config/server.js
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    keys: env.array('APP_KEYS'),
  },
  webhooks: {
    populateRelations: env.bool('WEBHOOKS_POPULATE_RELATIONS', false),
  },
});

// config/database.js
module.exports = ({ env }) => ({
  connection: {
    client: 'postgres',
    connection: {
      host: env('DATABASE_HOST', 'localhost'),
      port: env.int('DATABASE_PORT', 5432),
      database: env('DATABASE_NAME', 'strapi'),
      user: env('DATABASE_USERNAME', 'strapi'),
      password: env('DATABASE_PASSWORD', 'strapi'),
      ssl: env.bool('DATABASE_SSL', false) && {
        rejectUnauthorized: env.bool('DATABASE_SSL_REJECT_UNAUTHORIZED', true),
      },
    },
    pool: {
      min: env.int('DATABASE_POOL_MIN', 2),
      max: env.int('DATABASE_POOL_MAX', 10),
    },
    acquireConnectionTimeout: env.int('DATABASE_CONNECTION_TIMEOUT', 60000),
  },
});
```

## Security Considerations

### API Token Management

```javascript
// config/admin.js
module.exports = ({ env }) => ({
  auth: {
    secret: env('ADMIN_JWT_SECRET'),
  },
  apiToken: {
    salt: env('API_TOKEN_SALT'),
  },
  transfer: {
    token: {
      salt: env('TRANSFER_TOKEN_SALT'),
    },
  },
});

// Custom middleware for API key validation
module.exports = (config, { strapi }) => {
  return async (ctx, next) => {
    const token = ctx.request.header['x-api-key'];
    
    if (!token) {
      return ctx.unauthorized('API key required');
    }
    
    try {
      const apiToken = await strapi
        .query('admin::api-token')
        .findOne({ where: { accessKey: token } });
      
      if (!apiToken || apiToken.type !== 'full-access') {
        return ctx.unauthorized('Invalid API key');
      }
      
      ctx.state.apiToken = apiToken;
      await next();
    } catch (error) {
      return ctx.unauthorized('Authentication failed');
    }
  };
};
```

### Role-Based Access Control (RBAC)

```javascript
// src/api/article/policies/is-owner.js
module.exports = async (ctx, config, { strapi }) => {
  const { user } = ctx.state;
  const { id } = ctx.params;
  
  if (!user) {
    return false;
  }
  
  const article = await strapi.entityService.findOne(
    'api::article.article',
    id,
    { populate: ['author'] }
  );
  
  if (!article) {
    return false;
  }
  
  return article.author.id === user.id;
};

// src/api/article/routes/article.js
module.exports = {
  routes: [
    {
      method: 'PUT',
      path: '/articles/:id',
      handler: 'article.update',
      config: {
        policies: ['is-owner'],
        middlewares: [],
      },
    },
  ],
};
```

### Input Sanitization

```javascript
// src/api/article/controllers/article.js
const { sanitize } = require('@strapi/utils');

module.exports = {
  async create(ctx) {
    const { user } = ctx.state;
    const { body } = ctx.request;
    
    // Sanitize input
    const sanitizedInput = await sanitize.contentAPI.input(
      body,
      strapi.getModel('api::article.article'),
      { user }
    );
    
    // Additional validation
    if (!sanitizedInput.title || sanitizedInput.title.length < 5) {
      return ctx.badRequest('Title must be at least 5 characters');
    }
    
    // Create with sanitized data
    const article = await strapi.entityService.create(
      'api::article.article',
      {
        data: {
          ...sanitizedInput,
          author: user.id,
        },
      }
    );
    
    // Sanitize output
    const sanitizedOutput = await sanitize.contentAPI.output(
      article,
      strapi.getModel('api::article.article'),
      { user }
    );
    
    return ctx.send(sanitizedOutput);
  },
};
```

## Performance Optimization

### Database Query Optimization

```javascript
// src/api/product/services/product.js
module.exports = ({ strapi }) => ({
  async findWithOptimization(params) {
    const knex = strapi.db.connection;
    
    // Use raw query for complex operations
    const products = await knex('products')
      .select('products.*')
      .leftJoin('categories', 'products.category_id', 'categories.id')
      .where('products.published', true)
      .andWhere('categories.active', true)
      .orderBy('products.created_at', 'desc')
      .limit(params.limit || 25)
      .offset(params.start || 0);
    
    // Get total count separately
    const [{ count }] = await knex('products')
      .leftJoin('categories', 'products.category_id', 'categories.id')
      .where('products.published', true)
      .andWhere('categories.active', true)
      .count('* as count');
    
    return {
      data: products,
      meta: {
        pagination: {
          total: parseInt(count),
          pageSize: params.limit || 25,
          page: Math.floor((params.start || 0) / (params.limit || 25)) + 1,
        },
      },
    };
  },
  
  async findWithPopulate(id) {
    // Use populate for relations
    return await strapi.entityService.findOne(
      'api::product.product',
      id,
      {
        populate: {
          category: true,
          tags: {
            fields: ['name', 'slug'],
          },
          reviews: {
            populate: {
              user: {
                fields: ['username', 'email'],
              },
            },
            sort: 'createdAt:desc',
            limit: 10,
          },
        },
      }
    );
  },
});
```

### Caching Strategy

```javascript
// src/extensions/cache-middleware.js
const redis = require('redis');
const client = redis.createClient({
  url: process.env.REDIS_URL,
});

module.exports = (config = {}) => {
  const { ttl = 300, exclude = [] } = config;
  
  return async (ctx, next) => {
    // Skip caching for excluded routes
    if (exclude.includes(ctx.path)) {
      return await next();
    }
    
    // Only cache GET requests
    if (ctx.method !== 'GET') {
      return await next();
    }
    
    const key = `cache:${ctx.url}`;
    
    try {
      // Check cache
      const cached = await client.get(key);
      
      if (cached) {
        ctx.body = JSON.parse(cached);
        ctx.set('X-Cache-Hit', 'true');
        return;
      }
      
      // Process request
      await next();
      
      // Cache successful responses
      if (ctx.status === 200 && ctx.body) {
        await client.setex(key, ttl, JSON.stringify(ctx.body));
        ctx.set('X-Cache-Hit', 'false');
      }
    } catch (error) {
      console.error('Cache error:', error);
      await next();
    }
  };
};

// Register middleware
module.exports = {
  settings: {
    cache: {
      enabled: true,
      ttl: 300,
      exclude: ['/admin', '/api/auth'],
    },
  },
  middlewares: [
    {
      name: 'cache',
      resolve: './src/extensions/cache-middleware',
      config: {
        ttl: 300,
        exclude: ['/admin', '/api/auth'],
      },
    },
  ],
};
```

### Image Optimization

```javascript
// config/plugins.js
module.exports = ({ env }) => ({
  upload: {
    config: {
      provider: 'local',
      providerOptions: {
        sizeLimit: 100000000, // 100MB
      },
      breakpoints: {
        xlarge: 1920,
        large: 1280,
        medium: 750,
        small: 500,
        xsmall: 320,
      },
    },
  },
  'image-optimizer': {
    enabled: true,
    config: {
      include: ['jpeg', 'jpg', 'png', 'webp'],
      exclude: ['gif'],
      formats: ['webp', 'avif'],
      sizes: [
        {
          name: 'thumbnail',
          width: 150,
          height: 150,
          fit: 'cover',
        },
        {
          name: 'small',
          width: 500,
        },
        {
          name: 'medium',
          width: 750,
        },
        {
          name: 'large',
          width: 1280,
        },
      ],
      quality: 80,
      progressive: true,
    },
  },
});
```

## Common Patterns

### Custom Controllers

```javascript
// src/api/article/controllers/article.js
const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::article.article', ({ strapi }) => ({
  async find(ctx) {
    const { query } = ctx;
    
    // Add custom filters
    const filters = {
      ...query.filters,
      publishedAt: { $notNull: true },
    };
    
    // Custom population
    const populate = {
      author: {
        fields: ['name', 'email'],
      },
      category: true,
      tags: true,
      featuredImage: true,
    };
    
    const entities = await strapi.entityService.findMany(
      'api::article.article',
      {
        ...query,
        filters,
        populate,
      }
    );
    
    return this.transformResponse(entities);
  },
  
  async findOne(ctx) {
    const { id } = ctx.params;
    
    const entity = await strapi.entityService.findOne(
      'api::article.article',
      id,
      {
        populate: {
          author: true,
          category: true,
          tags: true,
          comments: {
            populate: {
              user: {
                fields: ['username'],
              },
            },
            sort: 'createdAt:desc',
          },
        },
      }
    );
    
    if (!entity) {
      return ctx.notFound('Article not found');
    }
    
    // Increment view count
    await strapi.entityService.update(
      'api::article.article',
      id,
      {
        data: {
          viewCount: (entity.viewCount || 0) + 1,
        },
      }
    );
    
    return this.transformResponse(entity);
  },
}));
```

### Lifecycle Hooks

```javascript
// src/api/article/content-types/article/lifecycles.js
module.exports = {
  async beforeCreate(event) {
    const { data } = event.params;
    
    // Generate slug from title
    if (data.title && !data.slug) {
      data.slug = await generateUniqueSlug(data.title);
    }
    
    // Set default values
    data.viewCount = 0;
    data.publishedAt = data.publishedAt || null;
  },
  
  async afterCreate(event) {
    const { result } = event;
    
    // Send notification
    await strapi.plugins['email'].services.email.send({
      to: 'admin@example.com',
      subject: 'New Article Created',
      text: `A new article "${result.title}" has been created.`,
    });
    
    // Clear cache
    await clearCache('articles');
  },
  
  async beforeUpdate(event) {
    const { data, where } = event.params;
    
    // Track changes
    const previousArticle = await strapi.entityService.findOne(
      'api::article.article',
      where.id
    );
    
    if (previousArticle.title !== data.title) {
      // Log title change
      await strapi.entityService.create('api::audit-log.audit-log', {
        data: {
          entity: 'article',
          entityId: where.id,
          action: 'update',
          changes: {
            title: {
              from: previousArticle.title,
              to: data.title,
            },
          },
        },
      });
    }
  },
  
  async afterDelete(event) {
    const { result } = event;
    
    // Clean up related data
    await strapi.db.query('api::comment.comment').deleteMany({
      where: { article: result.id },
    });
    
    // Clear cache
    await clearCache(`article:${result.id}`);
  },
};

async function generateUniqueSlug(title) {
  const baseSlug = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  
  let slug = baseSlug;
  let counter = 1;
  
  while (await checkSlugExists(slug)) {
    slug = `${baseSlug}-${counter}`;
    counter++;
  }
  
  return slug;
}

async function checkSlugExists(slug) {
  const existing = await strapi.db.query('api::article.article').findOne({
    where: { slug },
  });
  return !!existing;
}
```

### GraphQL Customization

```javascript
// src/extensions/graphql/resolvers.js
module.exports = {
  Query: {
    articleBySlug: {
      resolve: async (parent, args, context) => {
        const { slug } = args;
        
        const article = await strapi.entityService.findMany(
          'api::article.article',
          {
            filters: { slug },
            populate: ['author', 'category', 'tags'],
          }
        );
        
        return article[0] || null;
      },
    },
    
    searchArticles: {
      resolve: async (parent, args, context) => {
        const { query, limit = 10 } = args;
        
        const articles = await strapi.db.query('api::article.article').findMany({
          where: {
            $or: [
              { title: { $containsi: query } },
              { content: { $containsi: query } },
            ],
          },
          limit,
          populate: ['author', 'category'],
        });
        
        return articles;
      },
    },
  },
  
  Mutation: {
    incrementArticleViews: {
      resolve: async (parent, args, context) => {
        const { id } = args;
        
        const article = await strapi.entityService.findOne(
          'api::article.article',
          id
        );
        
        if (!article) {
          throw new Error('Article not found');
        }
        
        return await strapi.entityService.update(
          'api::article.article',
          id,
          {
            data: {
              viewCount: (article.viewCount || 0) + 1,
            },
          }
        );
      },
    },
  },
};
```

## Anti-patterns to Avoid

### Direct Database Manipulation
```javascript
// ❌ Avoid direct database queries without proper sanitization
module.exports = {
  async findByTitle(ctx) {
    const { title } = ctx.query;
    // SQL injection vulnerability
    const result = await strapi.db.connection.raw(
      `SELECT * FROM articles WHERE title = '${title}'`
    );
    return result;
  },
};

// ✅ Use query builder or entity service
module.exports = {
  async findByTitle(ctx) {
    const { title } = ctx.query;
    return await strapi.entityService.findMany(
      'api::article.article',
      {
        filters: { title: { $containsi: title } },
      }
    );
  },
};
```

### Unbounded Queries
```javascript
// ❌ Fetching all records without pagination
module.exports = {
  async find(ctx) {
    return await strapi.entityService.findMany('api::article.article');
  },
};

// ✅ Always implement pagination
module.exports = {
  async find(ctx) {
    const { page = 1, pageSize = 25 } = ctx.query;
    
    return await strapi.entityService.findPage(
      'api::article.article',
      {
        page,
        pageSize: Math.min(pageSize, 100), // Cap maximum page size
      }
    );
  },
};
```

## Testing Strategies

### Unit Testing

```javascript
// tests/article/controller.test.js
const request = require('supertest');

describe('Article Controller', () => {
  let strapi;
  let authToken;
  
  beforeAll(async () => {
    strapi = require('../../src');
    await strapi.load();
    await strapi.server.mount();
    
    // Create test user and get token
    const user = await strapi.plugins['users-permissions'].services.user.add({
      username: 'testuser',
      email: 'test@example.com',
      password: 'Test1234',
      provider: 'local',
      confirmed: true,
    });
    
    const jwt = strapi.plugins['users-permissions'].services.jwt.issue({
      id: user.id,
    });
    
    authToken = `Bearer ${jwt}`;
  });
  
  afterAll(async () => {
    await strapi.destroy();
  });
  
  describe('GET /api/articles', () => {
    it('should return published articles', async () => {
      const response = await request(strapi.server.httpServer)
        .get('/api/articles')
        .expect(200);
      
      expect(response.body.data).toBeInstanceOf(Array);
      expect(response.body.meta.pagination).toBeDefined();
    });
    
    it('should filter articles by category', async () => {
      const response = await request(strapi.server.httpServer)
        .get('/api/articles?filters[category][name][$eq]=Technology')
        .expect(200);
      
      response.body.data.forEach(article => {
        expect(article.attributes.category.data.attributes.name).toBe('Technology');
      });
    });
  });
  
  describe('POST /api/articles', () => {
    it('should create article with authentication', async () => {
      const articleData = {
        data: {
          title: 'Test Article',
          content: 'This is test content',
          slug: 'test-article',
        },
      };
      
      const response = await request(strapi.server.httpServer)
        .post('/api/articles')
        .set('Authorization', authToken)
        .send(articleData)
        .expect(200);
      
      expect(response.body.data.attributes.title).toBe('Test Article');
      expect(response.body.data.id).toBeDefined();
    });
    
    it('should reject creation without authentication', async () => {
      const articleData = {
        data: {
          title: 'Test Article',
          content: 'This is test content',
        },
      };
      
      await request(strapi.server.httpServer)
        .post('/api/articles')
        .send(articleData)
        .expect(403);
    });
  });
});
```

### Integration Testing

```javascript
// tests/integration/article-workflow.test.js
describe('Article Workflow Integration', () => {
  let strapi;
  let testArticle;
  
  beforeAll(async () => {
    strapi = require('../../src');
    await strapi.load();
  });
  
  afterAll(async () => {
    // Clean up test data
    if (testArticle) {
      await strapi.entityService.delete('api::article.article', testArticle.id);
    }
    await strapi.destroy();
  });
  
  test('complete article lifecycle', async () => {
    // Create draft article
    testArticle = await strapi.entityService.create('api::article.article', {
      data: {
        title: 'Integration Test Article',
        content: 'Test content',
        status: 'draft',
      },
    });
    
    expect(testArticle.status).toBe('draft');
    expect(testArticle.publishedAt).toBeNull();
    
    // Update to published
    const published = await strapi.entityService.update(
      'api::article.article',
      testArticle.id,
      {
        data: {
          status: 'published',
          publishedAt: new Date(),
        },
      }
    );
    
    expect(published.status).toBe('published');
    expect(published.publishedAt).toBeDefined();
    
    // Test slug generation
    expect(published.slug).toBe('integration-test-article');
    
    // Test view count increment
    const viewed = await strapi.entityService.findOne(
      'api::article.article',
      testArticle.id
    );
    
    expect(viewed.viewCount).toBeGreaterThan(0);
  });
});
```

## Error Handling

### Global Error Handler

```javascript
// src/middlewares/error-handler.js
module.exports = (config, { strapi }) => {
  return async (ctx, next) => {
    try {
      await next();
    } catch (error) {
      // Log error details
      strapi.log.error({
        message: error.message,
        stack: error.stack,
        statusCode: error.statusCode || 500,
        path: ctx.path,
        method: ctx.method,
        query: ctx.query,
        body: ctx.request.body,
        user: ctx.state.user?.id,
      });
      
      // Determine response status
      const status = error.statusCode || error.status || 500;
      
      // Format error response
      const response = {
        error: {
          status,
          name: error.name || 'InternalServerError',
          message: status === 500 
            ? 'An internal server error occurred' 
            : error.message,
        },
      };
      
      // Add details in development
      if (strapi.config.environment === 'development') {
        response.error.details = error.details || {};
        response.error.stack = error.stack;
      }
      
      // Add validation errors
      if (error.name === 'ValidationError' && error.details) {
        response.error.details = error.details;
      }
      
      ctx.status = status;
      ctx.body = response;
    }
  };
};
```

### Custom Error Classes

```javascript
// src/utils/errors.js
class AppError extends Error {
  constructor(message, statusCode = 500, details = null) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.details = details;
  }
}

class ValidationError extends AppError {
  constructor(message, details) {
    super(message, 400, details);
    this.name = 'ValidationError';
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Authentication required') {
    super(message, 401);
    this.name = 'AuthenticationError';
  }
}

class AuthorizationError extends AppError {
  constructor(message = 'Insufficient permissions') {
    super(message, 403);
    this.name = 'AuthorizationError';
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404);
    this.name = 'NotFoundError';
  }
}

module.exports = {
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
};
```

## Resources

- [Official Documentation](https://docs.strapi.io)
- [API Reference](https://docs.strapi.io/dev-docs/api/rest)
- [Strapi Community Forum](https://forum.strapi.io)
- [GitHub Repository](https://github.com/strapi/strapi)
- [Strapi Discord](https://discord.strapi.io)