# Fastify Best Practices

## Overview
Fastify is a high-performance web framework for Node.js focused on providing excellent developer experience with minimal overhead. These best practices ensure optimal performance, security, and maintainability.

## Project Structure

### Modular Plugin Architecture
```
project/
├── src/
│   ├── app.js
│   ├── server.js
│   ├── config/
│   │   ├── swagger.js
│   │   ├── cors.js
│   │   └── env.js
│   ├── plugins/
│   │   ├── database.js
│   │   ├── redis.js
│   │   ├── authentication.js
│   │   └── sensible.js
│   ├── routes/
│   │   ├── root.js
│   │   ├── auth/
│   │   ├── users/
│   │   └── api/
│   │       └── v1/
│   ├── schemas/
│   │   ├── user.schema.js
│   │   └── product.schema.js
│   ├── services/
│   │   ├── user.service.js
│   │   └── auth.service.js
│   ├── hooks/
│   │   ├── auth.hooks.js
│   │   └── validation.hooks.js
│   └── decorators/
│       └── index.js
├── test/
├── .env.example
└── package.json
```

### Application Setup
```javascript
// app.js
import Fastify from 'fastify';
import autoLoad from '@fastify/autoload';
import { join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = join(__filename, '..');

export async function build(opts = {}) {
  const fastify = Fastify({
    logger: {
      level: process.env.LOG_LEVEL || 'info',
      transport: process.env.NODE_ENV === 'development' 
        ? {
            target: 'pino-pretty',
            options: {
              translateTime: 'HH:MM:ss Z',
              ignore: 'pid,hostname'
            }
          }
        : undefined
    },
    requestIdLogLabel: 'reqId',
    disableRequestLogging: false,
    trustProxy: true,
    bodyLimit: 10485760, // 10MB
    caseSensitive: false,
    ignoreTrailingSlash: true,
    connectionTimeout: 30000,
    keepAliveTimeout: 5000,
    maxParamLength: 500,
    ...opts
  });

  // Register plugins
  await fastify.register(autoLoad, {
    dir: join(__dirname, 'plugins'),
    options: { ...opts }
  });

  // Register routes
  await fastify.register(autoLoad, {
    dir: join(__dirname, 'routes'),
    options: { ...opts },
    routeParams: true,
    autoHooks: true,
    cascadeHooks: true
  });

  // Custom error handler
  fastify.setErrorHandler((error, request, reply) => {
    const { validation, statusCode } = error;
    
    // Log error
    request.log.error({ err: error, request: request.raw });
    
    // Validation error
    if (validation) {
      return reply.status(400).send({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Validation error',
        validation: validation
      });
    }
    
    // Handle known errors
    const errorResponse = {
      statusCode: statusCode || 500,
      error: error.name || 'Internal Server Error',
      message: error.message || 'An error occurred'
    };
    
    // Add stack trace in development
    if (process.env.NODE_ENV === 'development') {
      errorResponse.stack = error.stack;
    }
    
    reply.status(errorResponse.statusCode).send(errorResponse);
  });

  // Not found handler
  fastify.setNotFoundHandler((request, reply) => {
    reply.status(404).send({
      statusCode: 404,
      error: 'Not Found',
      message: `Route ${request.method}:${request.url} not found`
    });
  });

  // Graceful shutdown
  const closeListeners = ['SIGINT', 'SIGTERM'];
  closeListeners.forEach((signal) => {
    process.on(signal, async () => {
      fastify.log.info(`Received ${signal}, closing server...`);
      await fastify.close();
      process.exit(0);
    });
  });

  return fastify;
}
```

## Plugin System

### Database Plugin
```javascript
// plugins/database.js
import fp from 'fastify-plugin';
import mongoose from 'mongoose';

async function dbConnector(fastify, options) {
  try {
    const url = options.url || process.env.MONGODB_URI;
    
    const connection = await mongoose.connect(url, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
    });

    fastify.decorate('mongo', connection);
    fastify.log.info('MongoDB connected successfully');

    // Handle connection events
    connection.connection.on('disconnected', () => {
      fastify.log.warn('MongoDB disconnected');
    });

    connection.connection.on('error', (err) => {
      fastify.log.error({ err }, 'MongoDB connection error');
    });

    // Graceful shutdown
    fastify.addHook('onClose', async () => {
      await connection.disconnect();
      fastify.log.info('MongoDB connection closed');
    });
  } catch (error) {
    fastify.log.error({ err: error }, 'MongoDB connection failed');
    throw error;
  }
}

export default fp(dbConnector, {
  name: 'mongodb',
  dependencies: []
});
```

### Authentication Plugin
```javascript
// plugins/authentication.js
import fp from 'fastify-plugin';
import jwt from '@fastify/jwt';
import cookie from '@fastify/cookie';

async function authentication(fastify, opts) {
  // Register JWT
  await fastify.register(jwt, {
    secret: process.env.JWT_SECRET || 'supersecret',
    sign: {
      expiresIn: '7d',
      algorithm: 'HS256'
    },
    verify: {
      algorithms: ['HS256']
    },
    cookie: {
      cookieName: 'token',
      signed: false
    }
  });

  // Register cookies
  await fastify.register(cookie, {
    secret: process.env.COOKIE_SECRET,
    parseOptions: {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 1000 * 60 * 60 * 24 * 7 // 7 days
    }
  });

  // Decorate request with authenticate method
  fastify.decorate('authenticate', async function(request, reply) {
    try {
      const token = request.cookies.token || 
                   request.headers.authorization?.replace('Bearer ', '');
      
      if (!token) {
        throw new Error('No token provided');
      }

      const decoded = await request.jwtVerify();
      request.user = decoded;
    } catch (err) {
      reply.status(401).send({
        statusCode: 401,
        error: 'Unauthorized',
        message: err.message
      });
    }
  });

  // Optional authentication
  fastify.decorate('authenticateOptional', async function(request, reply) {
    try {
      const token = request.cookies.token || 
                   request.headers.authorization?.replace('Bearer ', '');
      
      if (token) {
        const decoded = await request.jwtVerify();
        request.user = decoded;
      }
    } catch (err) {
      // Silent fail for optional auth
      request.log.debug({ err }, 'Optional authentication failed');
    }
  });

  // Role-based access control
  fastify.decorate('authorize', (...roles) => {
    return async function(request, reply) {
      if (!request.user) {
        return reply.status(401).send({
          statusCode: 401,
          error: 'Unauthorized',
          message: 'Authentication required'
        });
      }

      if (roles.length && !roles.includes(request.user.role)) {
        return reply.status(403).send({
          statusCode: 403,
          error: 'Forbidden',
          message: 'Insufficient permissions'
        });
      }
    };
  });
}

export default fp(authentication, {
  name: 'authentication',
  dependencies: []
});
```

## Schema Validation

### JSON Schema Definitions
```javascript
// schemas/user.schema.js
export const userSchemas = {
  // Shared schema definitions
  $id: 'user',
  type: 'object',
  definitions: {
    userId: {
      type: 'string',
      pattern: '^[0-9a-fA-F]{24}$'
    },
    email: {
      type: 'string',
      format: 'email',
      maxLength: 255
    },
    password: {
      type: 'string',
      minLength: 8,
      maxLength: 100,
      pattern: '^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).*$'
    },
    name: {
      type: 'string',
      minLength: 2,
      maxLength: 100
    },
    role: {
      type: 'string',
      enum: ['user', 'admin', 'moderator']
    }
  }
};

export const createUserSchema = {
  body: {
    type: 'object',
    required: ['email', 'password', 'name'],
    properties: {
      email: { $ref: 'user#/definitions/email' },
      password: { $ref: 'user#/definitions/password' },
      name: { $ref: 'user#/definitions/name' },
      role: { $ref: 'user#/definitions/role' }
    },
    additionalProperties: false
  },
  response: {
    201: {
      type: 'object',
      properties: {
        id: { type: 'string' },
        email: { type: 'string' },
        name: { type: 'string' },
        role: { type: 'string' },
        createdAt: { type: 'string', format: 'date-time' }
      }
    }
  }
};

export const updateUserSchema = {
  params: {
    type: 'object',
    required: ['id'],
    properties: {
      id: { $ref: 'user#/definitions/userId' }
    }
  },
  body: {
    type: 'object',
    minProperties: 1,
    properties: {
      email: { $ref: 'user#/definitions/email' },
      name: { $ref: 'user#/definitions/name' },
      role: { $ref: 'user#/definitions/role' }
    },
    additionalProperties: false
  }
};

export const getUserSchema = {
  params: {
    type: 'object',
    required: ['id'],
    properties: {
      id: { $ref: 'user#/definitions/userId' }
    }
  },
  response: {
    200: {
      type: 'object',
      properties: {
        id: { type: 'string' },
        email: { type: 'string' },
        name: { type: 'string' },
        role: { type: 'string' },
        createdAt: { type: 'string', format: 'date-time' },
        updatedAt: { type: 'string', format: 'date-time' }
      }
    }
  }
};

export const listUsersSchema = {
  querystring: {
    type: 'object',
    properties: {
      page: { type: 'integer', minimum: 1, default: 1 },
      limit: { type: 'integer', minimum: 1, maximum: 100, default: 20 },
      sort: { type: 'string', enum: ['name', 'email', 'createdAt'], default: 'createdAt' },
      order: { type: 'string', enum: ['asc', 'desc'], default: 'desc' },
      search: { type: 'string', minLength: 1, maxLength: 100 }
    }
  },
  response: {
    200: {
      type: 'object',
      properties: {
        users: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              email: { type: 'string' },
              name: { type: 'string' },
              role: { type: 'string' }
            }
          }
        },
        pagination: {
          type: 'object',
          properties: {
            page: { type: 'integer' },
            limit: { type: 'integer' },
            total: { type: 'integer' },
            pages: { type: 'integer' }
          }
        }
      }
    }
  }
};
```

## Route Handlers

### RESTful Routes
```javascript
// routes/users/index.js
import { 
  createUserSchema, 
  updateUserSchema, 
  getUserSchema, 
  listUsersSchema 
} from '../../schemas/user.schema.js';
import UserService from '../../services/user.service.js';

export default async function userRoutes(fastify, opts) {
  const userService = new UserService(fastify);

  // Add schema to fastify instance
  fastify.addSchema({
    $id: 'user',
    ...userSchemas
  });

  // Hooks for this context
  fastify.addHook('preHandler', fastify.authenticate);

  // List users
  fastify.get('/', {
    schema: listUsersSchema,
    preHandler: fastify.authorize('admin')
  }, async (request, reply) => {
    const { page, limit, sort, order, search } = request.query;
    
    const result = await userService.listUsers({
      page,
      limit,
      sort,
      order,
      search
    });

    return reply.send(result);
  });

  // Create user
  fastify.post('/', {
    schema: createUserSchema,
    preHandler: fastify.authorize('admin')
  }, async (request, reply) => {
    const user = await userService.createUser(request.body);
    return reply.status(201).send(user);
  });

  // Get user
  fastify.get('/:id', {
    schema: getUserSchema
  }, async (request, reply) => {
    const { id } = request.params;
    
    // Check ownership or admin
    if (request.user.id !== id && request.user.role !== 'admin') {
      return reply.status(403).send({
        statusCode: 403,
        error: 'Forbidden',
        message: 'Access denied'
      });
    }

    const user = await userService.getUserById(id);
    
    if (!user) {
      return reply.status(404).send({
        statusCode: 404,
        error: 'Not Found',
        message: 'User not found'
      });
    }

    return reply.send(user);
  });

  // Update user
  fastify.patch('/:id', {
    schema: updateUserSchema,
    preHandler: async (request, reply) => {
      const { id } = request.params;
      
      // Check ownership or admin
      if (request.user.id !== id && request.user.role !== 'admin') {
        return reply.status(403).send({
          statusCode: 403,
          error: 'Forbidden',
          message: 'Access denied'
        });
      }
    }
  }, async (request, reply) => {
    const { id } = request.params;
    const user = await userService.updateUser(id, request.body);
    
    if (!user) {
      return reply.status(404).send({
        statusCode: 404,
        error: 'Not Found',
        message: 'User not found'
      });
    }

    return reply.send(user);
  });

  // Delete user
  fastify.delete('/:id', {
    preHandler: fastify.authorize('admin')
  }, async (request, reply) => {
    const { id } = request.params;
    await userService.deleteUser(id);
    return reply.status(204).send();
  });

  // Bulk operations
  fastify.post('/bulk', {
    preHandler: fastify.authorize('admin'),
    schema: {
      body: {
        type: 'object',
        required: ['operation', 'ids'],
        properties: {
          operation: { type: 'string', enum: ['delete', 'activate', 'deactivate'] },
          ids: {
            type: 'array',
            items: { type: 'string' },
            minItems: 1,
            maxItems: 100
          }
        }
      }
    }
  }, async (request, reply) => {
    const { operation, ids } = request.body;
    const result = await userService.bulkOperation(operation, ids);
    return reply.send(result);
  });
}
```

## Hooks and Decorators

### Lifecycle Hooks
```javascript
// hooks/request.hooks.js
export function setupHooks(fastify) {
  // Request ID generation
  fastify.addHook('onRequest', async (request, reply) => {
    request.id = request.headers['x-request-id'] || 
                 `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    reply.header('X-Request-ID', request.id);
  });

  // Request timing
  fastify.addHook('onRequest', async (request, reply) => {
    request.startTime = Date.now();
  });

  // Response timing
  fastify.addHook('onSend', async (request, reply, payload) => {
    const responseTime = Date.now() - request.startTime;
    reply.header('X-Response-Time', `${responseTime}ms`);
    
    // Log slow requests
    if (responseTime > 1000) {
      request.log.warn({
        responseTime,
        url: request.url,
        method: request.method
      }, 'Slow request detected');
    }
    
    return payload;
  });

  // Request logging
  fastify.addHook('preHandler', async (request, reply) => {
    request.log.info({
      url: request.url,
      method: request.method,
      query: request.query,
      params: request.params,
      headers: request.headers,
      user: request.user?.id
    }, 'Incoming request');
  });

  // Response logging
  fastify.addHook('onResponse', async (request, reply) => {
    request.log.info({
      url: request.url,
      method: request.method,
      statusCode: reply.statusCode,
      responseTime: reply.getResponseTime()
    }, 'Request completed');
  });

  // Error recovery
  fastify.addHook('onError', async (request, reply, error) => {
    request.log.error({
      err: error,
      url: request.url,
      method: request.method
    }, 'Request error');
  });
}
```

### Custom Decorators
```javascript
// decorators/index.js
export function setupDecorators(fastify) {
  // Pagination decorator
  fastify.decorateRequest('paginate', function(options = {}) {
    const { page = 1, limit = 20 } = this.query;
    const skip = (page - 1) * limit;
    
    return {
      page: parseInt(page),
      limit: parseInt(limit),
      skip,
      ...options
    };
  });

  // Cache decorator
  fastify.decorate('cache', {
    get: async (key) => {
      return await fastify.redis.get(key);
    },
    set: async (key, value, ttl = 3600) => {
      return await fastify.redis.setex(key, ttl, JSON.stringify(value));
    },
    del: async (key) => {
      return await fastify.redis.del(key);
    }
  });

  // Response helpers
  fastify.decorateReply('success', function(data, message = 'Success') {
    this.send({
      success: true,
      message,
      data
    });
  });

  fastify.decorateReply('error', function(message, statusCode = 400) {
    this.status(statusCode).send({
      success: false,
      error: message,
      statusCode
    });
  });

  // Utility decorators
  fastify.decorate('utils', {
    generateId: () => {
      return `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    },
    slugify: (text) => {
      return text.toLowerCase()
        .replace(/[^\w ]+/g, '')
        .replace(/ +/g, '-');
    },
    sanitizeHtml: (html) => {
      // Implementation of HTML sanitization
      return html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    }
  });
}
```

## Performance Optimization

### Caching Strategy
```javascript
// plugins/redis.js
import fp from 'fastify-plugin';
import fastifyRedis from '@fastify/redis';

async function redisPlugin(fastify, opts) {
  await fastify.register(fastifyRedis, {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,
    db: process.env.REDIS_DB || 0,
    enableOfflineQueue: true,
    connectTimeout: 10000,
    maxRetriesPerRequest: 3,
    retryStrategy: (times) => {
      const delay = Math.min(times * 50, 2000);
      return delay;
    }
  });

  // Cache middleware
  fastify.decorate('cacheMiddleware', (ttl = 300) => {
    return async (request, reply) => {
      // Only cache GET requests
      if (request.method !== 'GET') {
        return;
      }

      const key = `cache:${request.url}`;
      const cached = await fastify.redis.get(key);

      if (cached) {
        reply.header('X-Cache', 'HIT');
        return reply.send(JSON.parse(cached));
      }

      // Store original send method
      const originalSend = reply.send.bind(reply);

      // Override send to cache response
      reply.send = function(payload) {
        if (reply.statusCode === 200) {
          fastify.redis.setex(key, ttl, JSON.stringify(payload));
        }
        reply.header('X-Cache', 'MISS');
        return originalSend(payload);
      };
    };
  });

  // Cache invalidation
  fastify.decorate('invalidateCache', async (pattern) => {
    const keys = await fastify.redis.keys(pattern);
    if (keys.length) {
      await fastify.redis.del(...keys);
    }
    return keys.length;
  });
}

export default fp(redisPlugin, {
  name: 'redis',
  dependencies: []
});
```

### Response Compression
```javascript
// plugins/compression.js
import fp from 'fastify-plugin';
import compress from '@fastify/compress';

async function compressionPlugin(fastify, opts) {
  await fastify.register(compress, {
    global: true,
    threshold: 1024, // Only compress responses larger than 1KB
    encodings: ['gzip', 'deflate', 'br'],
    brotliOptions: {
      params: {
        [zlib.constants.BROTLI_PARAM_MODE]: zlib.constants.BROTLI_MODE_TEXT,
        [zlib.constants.BROTLI_PARAM_QUALITY]: 4
      }
    },
    zlibOptions: {
      level: 6
    },
    customTypes: /^text\/|^application\/json|^application\/xml/,
    onUnsupportedEncoding: (encoding, request, reply) => {
      reply.header('X-No-Compression', encoding);
    }
  });
}

export default fp(compressionPlugin);
```

## Security

### Security Configuration
```javascript
// plugins/security.js
import fp from 'fastify-plugin';
import helmet from '@fastify/helmet';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';

async function securityPlugin(fastify, opts) {
  // Helmet for security headers
  await fastify.register(helmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"]
      }
    },
    crossOriginEmbedderPolicy: false
  });

  // CORS
  await fastify.register(cors, {
    origin: (origin, cb) => {
      const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];
      if (!origin || allowedOrigins.includes(origin)) {
        cb(null, true);
      } else {
        cb(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS']
  });

  // Rate limiting
  await fastify.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
    cache: 10000,
    redis: fastify.redis,
    skipOnError: true,
    keyGenerator: (request) => {
      return request.headers['x-forwarded-for'] || 
             request.headers['x-real-ip'] || 
             request.ip;
    },
    errorResponseBuilder: (request, context) => {
      return {
        statusCode: 429,
        error: 'Too Many Requests',
        message: `Rate limit exceeded, retry in ${context.after}`,
        retryAfter: context.after
      };
    }
  });

  // SQL injection prevention (for SQL databases)
  fastify.addHook('preValidation', async (request, reply) => {
    const sqlInjectionPattern = /(\b(ALTER|CREATE|DELETE|DROP|EXEC(UTE)?|INSERT|SELECT|UNION|UPDATE)\b)/gi;
    
    const checkForSQLInjection = (obj) => {
      for (const key in obj) {
        if (typeof obj[key] === 'string' && sqlInjectionPattern.test(obj[key])) {
          throw new Error('Potential SQL injection detected');
        } else if (typeof obj[key] === 'object' && obj[key] !== null) {
          checkForSQLInjection(obj[key]);
        }
      }
    };

    try {
      if (request.body) checkForSQLInjection(request.body);
      if (request.query) checkForSQLInjection(request.query);
      if (request.params) checkForSQLInjection(request.params);
    } catch (error) {
      return reply.status(400).send({
        statusCode: 400,
        error: 'Bad Request',
        message: error.message
      });
    }
  });
}

export default fp(securityPlugin, {
  name: 'security'
});
```

## Testing

### Unit and Integration Tests
```javascript
// test/user.test.js
import tap from 'tap';
import { build } from '../src/app.js';

tap.test('User endpoints', async (t) => {
  const app = await build({ logger: false });
  
  t.teardown(() => app.close());
  
  let authToken;
  let userId;

  // Login to get token
  t.test('POST /auth/login', async (t) => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'admin@example.com',
        password: 'Admin123!'
      }
    });

    t.equal(response.statusCode, 200);
    const body = JSON.parse(response.payload);
    t.ok(body.token);
    authToken = body.token;
  });

  // Create user
  t.test('POST /users', async (t) => {
    const response = await app.inject({
      method: 'POST',
      url: '/users',
      headers: {
        authorization: `Bearer ${authToken}`
      },
      payload: {
        email: 'test@example.com',
        password: 'Test123!',
        name: 'Test User',
        role: 'user'
      }
    });

    t.equal(response.statusCode, 201);
    const body = JSON.parse(response.payload);
    t.ok(body.id);
    t.equal(body.email, 'test@example.com');
    userId = body.id;
  });

  // Get user
  t.test('GET /users/:id', async (t) => {
    const response = await app.inject({
      method: 'GET',
      url: `/users/${userId}`,
      headers: {
        authorization: `Bearer ${authToken}`
      }
    });

    t.equal(response.statusCode, 200);
    const body = JSON.parse(response.payload);
    t.equal(body.id, userId);
  });

  // Update user
  t.test('PATCH /users/:id', async (t) => {
    const response = await app.inject({
      method: 'PATCH',
      url: `/users/${userId}`,
      headers: {
        authorization: `Bearer ${authToken}`
      },
      payload: {
        name: 'Updated Name'
      }
    });

    t.equal(response.statusCode, 200);
    const body = JSON.parse(response.payload);
    t.equal(body.name, 'Updated Name');
  });

  // List users with pagination
  t.test('GET /users', async (t) => {
    const response = await app.inject({
      method: 'GET',
      url: '/users?page=1&limit=10',
      headers: {
        authorization: `Bearer ${authToken}`
      }
    });

    t.equal(response.statusCode, 200);
    const body = JSON.parse(response.payload);
    t.ok(Array.isArray(body.users));
    t.ok(body.pagination);
  });

  // Delete user
  t.test('DELETE /users/:id', async (t) => {
    const response = await app.inject({
      method: 'DELETE',
      url: `/users/${userId}`,
      headers: {
        authorization: `Bearer ${authToken}`
      }
    });

    t.equal(response.statusCode, 204);
  });

  // Test validation
  t.test('POST /users - validation error', async (t) => {
    const response = await app.inject({
      method: 'POST',
      url: '/users',
      headers: {
        authorization: `Bearer ${authToken}`
      },
      payload: {
        email: 'invalid-email',
        password: '123'
      }
    });

    t.equal(response.statusCode, 400);
    const body = JSON.parse(response.payload);
    t.ok(body.validation);
  });

  // Test authentication
  t.test('GET /users - unauthorized', async (t) => {
    const response = await app.inject({
      method: 'GET',
      url: '/users'
    });

    t.equal(response.statusCode, 401);
  });
});
```

## Deployment

### Production Configuration
```javascript
// server.js
import { build } from './app.js';
import closeWithGrace from 'close-with-grace';

const start = async () => {
  const app = await build({
    logger: {
      level: process.env.LOG_LEVEL || 'info',
      serializers: {
        req: (request) => ({
          method: request.method,
          url: request.url,
          headers: request.headers,
          hostname: request.hostname,
          remoteAddress: request.ip,
          remotePort: request.socket?.remotePort
        }),
        res: (reply) => ({
          statusCode: reply.statusCode,
          headers: reply.getHeaders()
        })
      }
    }
  });

  try {
    const port = process.env.PORT || 3000;
    const host = process.env.HOST || '0.0.0.0';
    
    await app.listen({ port, host });
    
    app.log.info(`Server listening on http://${host}:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }

  // Graceful shutdown
  closeWithGrace({ delay: 500 }, async ({ signal, err, manual }) => {
    if (err) {
      app.log.error(err);
    }
    app.log.info(`Shutting down gracefully... Signal: ${signal}`);
    await app.close();
  });
};

start();
```

## Best Practices Summary

1. **Plugin Architecture**: Use plugins for modular code organization
2. **Schema Validation**: Define and reuse JSON schemas
3. **Error Handling**: Implement comprehensive error handling
4. **Security First**: Apply security best practices from the start
5. **Performance**: Use caching, compression, and optimization techniques
6. **Logging**: Implement structured logging with Pino
7. **Testing**: Write comprehensive tests with tap
8. **Type Safety**: Use TypeScript for better type safety
9. **Documentation**: Auto-generate API documentation with Swagger
10. **Monitoring**: Implement health checks and metrics

## Conclusion

Fastify provides exceptional performance and developer experience for building Node.js applications. Following these best practices ensures your Fastify applications are fast, secure, and maintainable.