# Hono.js Best Practices

## Official Documentation
- **Hono Documentation**: https://hono.dev
- **GitHub Repository**: https://github.com/honojs/hono
- **API Reference**: https://hono.dev/api
- **Examples**: https://github.com/honojs/examples

## Project Structure

```
project-root/
├── src/
│   ├── middleware/
│   │   ├── auth.ts
│   │   ├── cors.ts
│   │   ├── logger.ts
│   │   └── validation.ts
│   ├── routes/
│   │   ├── auth/
│   │   │   ├── index.ts
│   │   │   ├── login.ts
│   │   │   └── register.ts
│   │   ├── users/
│   │   │   ├── index.ts
│   │   │   ├── profile.ts
│   │   │   └── [id].ts
│   │   └── posts/
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── user.service.ts
│   │   └── post.service.ts
│   ├── types/
│   │   ├── auth.ts
│   │   ├── user.ts
│   │   └── common.ts
│   ├── utils/
│   │   ├── db.ts
│   │   ├── validation.ts
│   │   └── crypto.ts
│   ├── app.ts
│   └── index.ts
├── tests/
├── package.json
└── tsconfig.json
```

## Basic Application Setup

### Main Application File
```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';
import { secureHeaders } from 'hono/secure-headers';
import { timing } from 'hono/timing';
import { compress } from 'hono/compress';

import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import postRoutes from './routes/posts';
import { errorHandler } from './middleware/error';
import { requestId } from './middleware/request-id';

type Bindings = {
  DATABASE_URL: string;
  JWT_SECRET: string;
  REDIS_URL: string;
};

type Variables = {
  user?: {
    id: string;
    email: string;
    role: string;
  };
  requestId: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// Global middleware
app.use('*', logger());
app.use('*', requestId());
app.use('*', timing());
app.use('*', secureHeaders());
app.use('*', compress());
app.use('*', prettyJSON());

// CORS configuration
app.use('/api/*', cors({
  origin: (origin) => {
    const allowedOrigins = ['http://localhost:3000', 'https://myapp.com'];
    return allowedOrigins.includes(origin) ? origin : null;
  },
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowHeaders: ['Content-Type', 'Authorization'],
  exposeHeaders: ['X-Request-ID'],
  credentials: true,
  maxAge: 86400
}));

// Health check
app.get('/health', (c) => {
  return c.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version 
  });
});

// API routes
app.route('/api/auth', authRoutes);
app.route('/api/users', userRoutes);
app.route('/api/posts', postRoutes);

// 404 handler
app.notFound((c) => {
  return c.json({ 
    error: 'Not Found', 
    message: `Route ${c.req.method} ${c.req.path} not found`,
    requestId: c.get('requestId')
  }, 404);
});

// Error handler
app.onError(errorHandler);

export default app;
```

### Environment Configuration
```typescript
// src/config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform(Number).default('3000'),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  REDIS_URL: z.string().url().optional(),
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  RATE_LIMIT_REQUESTS: z.string().transform(Number).default('100'),
  RATE_LIMIT_WINDOW: z.string().transform(Number).default('900000'), // 15 minutes
});

export const env = envSchema.parse(process.env);

export type Env = z.infer<typeof envSchema>;
```

## Middleware Implementation

### Authentication Middleware
```typescript
// src/middleware/auth.ts
import { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { verify } from 'hono/jwt';

interface JWTPayload {
  sub: string;
  email: string;
  role: string;
  exp: number;
}

export const authMiddleware = () => {
  return async (c: Context, next: Next) => {
    const authHeader = c.req.header('authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new HTTPException(401, { message: 'Authorization header required' });
    }
    
    const token = authHeader.substring(7);
    
    try {
      const payload = await verify(token, c.env.JWT_SECRET) as JWTPayload;
      
      if (payload.exp < Date.now() / 1000) {
        throw new HTTPException(401, { message: 'Token expired' });
      }
      
      c.set('user', {
        id: payload.sub,
        email: payload.email,
        role: payload.role
      });
      
      await next();
    } catch (error) {
      if (error instanceof HTTPException) {
        throw error;
      }
      throw new HTTPException(401, { message: 'Invalid token' });
    }
  };
};

export const requireRole = (requiredRole: string) => {
  return async (c: Context, next: Next) => {
    const user = c.get('user');
    
    if (!user) {
      throw new HTTPException(401, { message: 'Authentication required' });
    }
    
    if (user.role !== requiredRole && user.role !== 'admin') {
      throw new HTTPException(403, { message: 'Insufficient permissions' });
    }
    
    await next();
  };
};
```

### Validation Middleware
```typescript
// src/middleware/validation.ts
import { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { z, ZodError } from 'zod';

export const validate = (schema: z.ZodSchema) => {
  return async (c: Context, next: Next) => {
    try {
      const contentType = c.req.header('content-type');
      
      if (contentType?.includes('application/json')) {
        const body = await c.req.json();
        const validatedData = schema.parse(body);
        c.set('validatedData', validatedData);
      } else if (contentType?.includes('application/x-www-form-urlencoded')) {
        const formData = await c.req.parseBody();
        const validatedData = schema.parse(formData);
        c.set('validatedData', validatedData);
      }
      
      await next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message,
          code: err.code
        }));
        
        throw new HTTPException(400, { 
          message: 'Validation failed',
          cause: { errors }
        });
      }
      throw error;
    }
  };
};

export const validateQuery = (schema: z.ZodSchema) => {
  return async (c: Context, next: Next) => {
    try {
      const query = c.req.query();
      const validatedQuery = schema.parse(query);
      c.set('validatedQuery', validatedQuery);
      await next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message
        }));
        
        throw new HTTPException(400, { 
          message: 'Query validation failed',
          cause: { errors }
        });
      }
      throw error;
    }
  };
};
```

### Rate Limiting Middleware
```typescript
// src/middleware/rate-limit.ts
import { Context, Next } from 'hono';
import { HTTPException } from 'hono/http-exception';

interface RateLimitOptions {
  windowMs: number;
  maxRequests: number;
  message?: string;
  keyGenerator?: (c: Context) => string;
}

// Simple in-memory rate limiter (use Redis in production)
const requests = new Map<string, { count: number; resetTime: number }>();

export const rateLimit = (options: RateLimitOptions) => {
  const {
    windowMs,
    maxRequests,
    message = 'Too many requests',
    keyGenerator = (c) => c.req.header('x-forwarded-for') || 'anonymous'
  } = options;

  return async (c: Context, next: Next) => {
    const key = keyGenerator(c);
    const now = Date.now();
    const windowStart = now - windowMs;

    // Clean up old entries
    for (const [k, v] of requests.entries()) {
      if (v.resetTime < windowStart) {
        requests.delete(k);
      }
    }

    const current = requests.get(key);

    if (!current) {
      requests.set(key, { count: 1, resetTime: now + windowMs });
    } else if (current.resetTime < now) {
      requests.set(key, { count: 1, resetTime: now + windowMs });
    } else if (current.count >= maxRequests) {
      const resetIn = Math.ceil((current.resetTime - now) / 1000);
      
      c.header('X-RateLimit-Limit', maxRequests.toString());
      c.header('X-RateLimit-Remaining', '0');
      c.header('X-RateLimit-Reset', resetIn.toString());
      
      throw new HTTPException(429, { message });
    } else {
      current.count++;
      requests.set(key, current);
    }

    const remaining = Math.max(0, maxRequests - (requests.get(key)?.count || 0));
    c.header('X-RateLimit-Limit', maxRequests.toString());
    c.header('X-RateLimit-Remaining', remaining.toString());

    await next();
  };
};
```

### Error Handling Middleware
```typescript
// src/middleware/error.ts
import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { ZodError } from 'zod';

export const errorHandler = (err: Error, c: Context) => {
  console.error('Error:', {
    message: err.message,
    stack: err.stack,
    requestId: c.get('requestId'),
    path: c.req.path,
    method: c.req.method,
  });

  // HTTP exceptions
  if (err instanceof HTTPException) {
    return c.json({
      error: err.message,
      status: err.status,
      requestId: c.get('requestId'),
      ...(err.cause && { details: err.cause })
    }, err.status);
  }

  // Zod validation errors
  if (err instanceof ZodError) {
    const errors = err.errors.map(e => ({
      field: e.path.join('.'),
      message: e.message,
      code: e.code
    }));

    return c.json({
      error: 'Validation failed',
      status: 400,
      requestId: c.get('requestId'),
      errors
    }, 400);
  }

  // Database errors
  if (err.name === 'DatabaseError') {
    return c.json({
      error: 'Database operation failed',
      status: 500,
      requestId: c.get('requestId')
    }, 500);
  }

  // Default error
  return c.json({
    error: process.env.NODE_ENV === 'production' 
      ? 'Internal Server Error' 
      : err.message,
    status: 500,
    requestId: c.get('requestId')
  }, 500);
};
```

## Route Implementation

### RESTful API Routes
```typescript
// src/routes/users/index.ts
import { Hono } from 'hono';
import { z } from 'zod';
import { authMiddleware, requireRole } from '../../middleware/auth';
import { validate, validateQuery } from '../../middleware/validation';
import { userService } from '../../services/user.service';

const userRoutes = new Hono();

// Validation schemas
const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  role: z.enum(['user', 'admin']).default('user')
});

const updateUserSchema = z.object({
  firstName: z.string().min(1).optional(),
  lastName: z.string().min(1).optional(),
  email: z.string().email().optional()
});

const querySchema = z.object({
  page: z.string().transform(Number).default('1'),
  limit: z.string().transform(Number).default('10'),
  search: z.string().optional(),
  role: z.enum(['user', 'admin']).optional()
});

// Get all users (admin only)
userRoutes.get(
  '/',
  authMiddleware(),
  requireRole('admin'),
  validateQuery(querySchema),
  async (c) => {
    const query = c.get('validatedQuery');
    const users = await userService.findMany({
      page: query.page,
      limit: query.limit,
      search: query.search,
      role: query.role
    });

    return c.json({
      data: users.data,
      pagination: {
        page: query.page,
        limit: query.limit,
        total: users.total,
        totalPages: Math.ceil(users.total / query.limit)
      }
    });
  }
);

// Get current user
userRoutes.get('/me', authMiddleware(), async (c) => {
  const currentUser = c.get('user');
  const user = await userService.findById(currentUser!.id);
  
  if (!user) {
    return c.json({ error: 'User not found' }, 404);
  }

  return c.json({ data: user });
});

// Get user by ID
userRoutes.get('/:id', authMiddleware(), async (c) => {
  const { id } = c.req.param();
  const currentUser = c.get('user');

  // Users can only view their own profile unless they're admin
  if (currentUser!.id !== id && currentUser!.role !== 'admin') {
    return c.json({ error: 'Forbidden' }, 403);
  }

  const user = await userService.findById(id);
  
  if (!user) {
    return c.json({ error: 'User not found' }, 404);
  }

  return c.json({ data: user });
});

// Create user (admin only)
userRoutes.post(
  '/',
  authMiddleware(),
  requireRole('admin'),
  validate(createUserSchema),
  async (c) => {
    const userData = c.get('validatedData');
    
    try {
      const user = await userService.create(userData);
      return c.json({ data: user }, 201);
    } catch (error) {
      if (error.code === 'DUPLICATE_EMAIL') {
        return c.json({ error: 'Email already exists' }, 409);
      }
      throw error;
    }
  }
);

// Update user
userRoutes.put(
  '/:id',
  authMiddleware(),
  validate(updateUserSchema),
  async (c) => {
    const { id } = c.req.param();
    const userData = c.get('validatedData');
    const currentUser = c.get('user');

    // Users can only update their own profile unless they're admin
    if (currentUser!.id !== id && currentUser!.role !== 'admin') {
      return c.json({ error: 'Forbidden' }, 403);
    }

    const user = await userService.update(id, userData);
    
    if (!user) {
      return c.json({ error: 'User not found' }, 404);
    }

    return c.json({ data: user });
  }
);

// Delete user (admin only)
userRoutes.delete(
  '/:id',
  authMiddleware(),
  requireRole('admin'),
  async (c) => {
    const { id } = c.req.param();
    const deleted = await userService.delete(id);
    
    if (!deleted) {
      return c.json({ error: 'User not found' }, 404);
    }

    return c.json({ message: 'User deleted successfully' });
  }
);

export default userRoutes;
```

### Authentication Routes
```typescript
// src/routes/auth/index.ts
import { Hono } from 'hono';
import { z } from 'zod';
import { sign } from 'hono/jwt';
import { validate } from '../../middleware/validation';
import { authService } from '../../services/auth.service';
import { rateLimit } from '../../middleware/rate-limit';

const authRoutes = new Hono();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  firstName: z.string().min(1),
  lastName: z.string().min(1)
});

const refreshTokenSchema = z.object({
  refreshToken: z.string()
});

// Rate limiting for auth endpoints
const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 5,
  message: 'Too many authentication attempts'
});

// Login
authRoutes.post(
  '/login',
  authRateLimit,
  validate(loginSchema),
  async (c) => {
    const { email, password } = c.get('validatedData');

    try {
      const result = await authService.login(email, password);
      
      if (!result.success) {
        return c.json({ error: result.error }, 401);
      }

      const { user, accessToken, refreshToken } = result;

      // Set HTTP-only cookie for refresh token
      c.header('Set-Cookie', 
        `refreshToken=${refreshToken}; HttpOnly; Secure; SameSite=Strict; Max-Age=${7 * 24 * 60 * 60}; Path=/api/auth`
      );

      return c.json({
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          role: user.role
        },
        accessToken
      });
    } catch (error) {
      console.error('Login error:', error);
      return c.json({ error: 'Login failed' }, 500);
    }
  }
);

// Register
authRoutes.post(
  '/register',
  authRateLimit,
  validate(registerSchema),
  async (c) => {
    const userData = c.get('validatedData');

    try {
      const result = await authService.register(userData);
      
      if (!result.success) {
        return c.json({ error: result.error }, 400);
      }

      const { user, accessToken, refreshToken } = result;

      c.header('Set-Cookie', 
        `refreshToken=${refreshToken}; HttpOnly; Secure; SameSite=Strict; Max-Age=${7 * 24 * 60 * 60}; Path=/api/auth`
      );

      return c.json({
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          role: user.role
        },
        accessToken
      }, 201);
    } catch (error) {
      console.error('Registration error:', error);
      return c.json({ error: 'Registration failed' }, 500);
    }
  }
);

// Refresh token
authRoutes.post(
  '/refresh',
  validate(refreshTokenSchema),
  async (c) => {
    const { refreshToken } = c.get('validatedData');

    try {
      const result = await authService.refreshToken(refreshToken);
      
      if (!result.success) {
        return c.json({ error: result.error }, 401);
      }

      return c.json({
        accessToken: result.accessToken
      });
    } catch (error) {
      console.error('Token refresh error:', error);
      return c.json({ error: 'Token refresh failed' }, 500);
    }
  }
);

// Logout
authRoutes.post('/logout', async (c) => {
  c.header('Set-Cookie', 
    'refreshToken=; HttpOnly; Secure; SameSite=Strict; Max-Age=0; Path=/api/auth'
  );
  
  return c.json({ message: 'Logged out successfully' });
});

export default authRoutes;
```

## Database Integration

### Database Connection
```typescript
// src/utils/db.ts
import { PrismaClient } from '@prisma/client';

let prisma: PrismaClient;

declare global {
  var __prisma: PrismaClient | undefined;
}

if (process.env.NODE_ENV === 'production') {
  prisma = new PrismaClient();
} else {
  if (!global.__prisma) {
    global.__prisma = new PrismaClient();
  }
  prisma = global.__prisma;
}

export { prisma };

// Connection health check
export async function checkDatabaseConnection() {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return true;
  } catch (error) {
    console.error('Database connection failed:', error);
    return false;
  }
}

// Graceful shutdown
export async function closeDatabaseConnection() {
  await prisma.$disconnect();
}

// Handle process termination
process.on('beforeExit', async () => {
  await closeDatabaseConnection();
});
```

### Service Layer
```typescript
// src/services/user.service.ts
import { prisma } from '../utils/db';
import { hashPassword } from '../utils/crypto';
import type { User, CreateUserInput, UpdateUserInput } from '../types/user';

export class UserService {
  async findMany(options: {
    page: number;
    limit: number;
    search?: string;
    role?: string;
  }) {
    const { page, limit, search, role } = options;
    const offset = (page - 1) * limit;

    const where = {
      ...(search && {
        OR: [
          { firstName: { contains: search, mode: 'insensitive' } },
          { lastName: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } }
        ]
      }),
      ...(role && { role })
    };

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          role: true,
          createdAt: true,
          updatedAt: true
        },
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.user.count({ where })
    ]);

    return { data: users, total };
  }

  async findById(id: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }

  async findByEmail(email: string) {
    return prisma.user.findUnique({
      where: { email }
    });
  }

  async create(data: CreateUserInput): Promise<User> {
    const existingUser = await this.findByEmail(data.email);
    
    if (existingUser) {
      throw new Error('DUPLICATE_EMAIL');
    }

    const hashedPassword = await hashPassword(data.password);

    return prisma.user.create({
      data: {
        ...data,
        password: hashedPassword
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        createdAt: true,
        updatedAt: true
      }
    });
  }

  async update(id: string, data: UpdateUserInput): Promise<User | null> {
    try {
      return await prisma.user.update({
        where: { id },
        data,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          role: true,
          createdAt: true,
          updatedAt: true
        }
      });
    } catch (error) {
      if (error.code === 'P2025') {
        return null; // Record not found
      }
      throw error;
    }
  }

  async delete(id: string): Promise<boolean> {
    try {
      await prisma.user.delete({
        where: { id }
      });
      return true;
    } catch (error) {
      if (error.code === 'P2025') {
        return false; // Record not found
      }
      throw error;
    }
  }
}

export const userService = new UserService();
```

## Testing

### Unit Tests
```typescript
// tests/routes/users.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { testClient } from 'hono/testing';
import app from '../../src/app';
import { userService } from '../../src/services/user.service';

vi.mock('../../src/services/user.service');

describe('Users API', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('GET /api/users', () => {
    it('should return users for admin', async () => {
      const mockUsers = {
        data: [
          {
            id: '1',
            email: 'john@example.com',
            firstName: 'John',
            lastName: 'Doe',
            role: 'user'
          }
        ],
        total: 1
      };

      vi.mocked(userService.findMany).mockResolvedValue(mockUsers);

      const client = testClient(app);
      const res = await client.api.users.$get(
        {},
        {
          headers: {
            authorization: 'Bearer valid-admin-token'
          }
        }
      );

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.data).toHaveLength(1);
      expect(data.data[0].email).toBe('john@example.com');
    });

    it('should return 401 for unauthenticated requests', async () => {
      const client = testClient(app);
      const res = await client.api.users.$get();

      expect(res.status).toBe(401);
    });

    it('should return 403 for non-admin users', async () => {
      const client = testClient(app);
      const res = await client.api.users.$get(
        {},
        {
          headers: {
            authorization: 'Bearer valid-user-token'
          }
        }
      );

      expect(res.status).toBe(403);
    });
  });

  describe('POST /api/users', () => {
    it('should create user for admin', async () => {
      const newUser = {
        id: '2',
        email: 'jane@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        role: 'user'
      };

      vi.mocked(userService.create).mockResolvedValue(newUser);

      const client = testClient(app);
      const res = await client.api.users.$post(
        {
          json: {
            email: 'jane@example.com',
            password: 'SecurePass123!',
            firstName: 'Jane',
            lastName: 'Smith'
          }
        },
        {
          headers: {
            authorization: 'Bearer valid-admin-token',
            'content-type': 'application/json'
          }
        }
      );

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.data.email).toBe('jane@example.com');
    });

    it('should return validation errors for invalid input', async () => {
      const client = testClient(app);
      const res = await client.api.users.$post(
        {
          json: {
            email: 'invalid-email',
            password: '123', // Too short
            firstName: '',
            lastName: 'Smith'
          }
        },
        {
          headers: {
            authorization: 'Bearer valid-admin-token',
            'content-type': 'application/json'
          }
        }
      );

      expect(res.status).toBe(400);
      const data = await res.json();
      expect(data.errors).toBeDefined();
    });
  });
});
```

### Integration Tests
```typescript
// tests/integration/auth.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { testClient } from 'hono/testing';
import app from '../../src/app';
import { prisma } from '../../src/utils/db';

describe('Authentication Integration', () => {
  beforeAll(async () => {
    // Setup test database
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    // Cleanup test database
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const client = testClient(app);
      const res = await client.api.auth.register.$post({
        json: {
          email: 'test@example.com',
          password: 'SecurePass123!',
          firstName: 'Test',
          lastName: 'User'
        }
      });

      expect(res.status).toBe(201);
      const data = await res.json();
      expect(data.user.email).toBe('test@example.com');
      expect(data.accessToken).toBeDefined();

      // Verify user was created in database
      const user = await prisma.user.findUnique({
        where: { email: 'test@example.com' }
      });
      expect(user).toBeTruthy();
    });

    it('should not allow duplicate email registration', async () => {
      const client = testClient(app);
      const res = await client.api.auth.register.$post({
        json: {
          email: 'test@example.com', // Same email as above
          password: 'AnotherPass123!',
          firstName: 'Another',
          lastName: 'User'
        }
      });

      expect(res.status).toBe(400);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with valid credentials', async () => {
      const client = testClient(app);
      const res = await client.api.auth.login.$post({
        json: {
          email: 'test@example.com',
          password: 'SecurePass123!'
        }
      });

      expect(res.status).toBe(200);
      const data = await res.json();
      expect(data.user.email).toBe('test@example.com');
      expect(data.accessToken).toBeDefined();
    });

    it('should reject invalid credentials', async () => {
      const client = testClient(app);
      const res = await client.api.auth.login.$post({
        json: {
          email: 'test@example.com',
          password: 'WrongPassword'
        }
      });

      expect(res.status).toBe(401);
    });
  });
});
```

## Performance Optimization

### Caching with Redis
```typescript
// src/utils/cache.ts
import Redis from 'ioredis';

let redis: Redis | null = null;

if (process.env.REDIS_URL) {
  redis = new Redis(process.env.REDIS_URL);
}

export class CacheService {
  async get<T>(key: string): Promise<T | null> {
    if (!redis) return null;
    
    const value = await redis.get(key);
    return value ? JSON.parse(value) : null;
  }

  async set(key: string, value: any, ttl: number = 300): Promise<void> {
    if (!redis) return;
    
    await redis.setex(key, ttl, JSON.stringify(value));
  }

  async del(key: string): Promise<void> {
    if (!redis) return;
    
    await redis.del(key);
  }

  async invalidatePattern(pattern: string): Promise<void> {
    if (!redis) return;
    
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
  }
}

export const cacheService = new CacheService();
```

### Database Query Optimization
```typescript
// src/services/post.service.ts
import { prisma } from '../utils/db';
import { cacheService } from '../utils/cache';

export class PostService {
  async findMany(options: {
    page: number;
    limit: number;
    authorId?: string;
    published?: boolean;
  }) {
    const cacheKey = `posts:${JSON.stringify(options)}`;
    
    // Try to get from cache first
    const cached = await cacheService.get(cacheKey);
    if (cached) {
      return cached;
    }

    const { page, limit, authorId, published } = options;
    const offset = (page - 1) * limit;

    const where = {
      ...(authorId && { authorId }),
      ...(published !== undefined && { published })
    };

    const [posts, total] = await Promise.all([
      prisma.post.findMany({
        where,
        include: {
          author: {
            select: {
              id: true,
              firstName: true,
              lastName: true
            }
          },
          _count: {
            select: {
              comments: true,
              likes: true
            }
          }
        },
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' }
      }),
      prisma.post.count({ where })
    ]);

    const result = { data: posts, total };
    
    // Cache for 5 minutes
    await cacheService.set(cacheKey, result, 300);
    
    return result;
  }

  async invalidateCache(postId?: string) {
    // Invalidate related cache entries
    await cacheService.invalidatePattern('posts:*');
    
    if (postId) {
      await cacheService.del(`post:${postId}`);
    }
  }
}
```

## Security Best Practices

### Input Sanitization
```typescript
// src/utils/sanitize.ts
import DOMPurify from 'isomorphic-dompurify';

export function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'u', 'ol', 'ul', 'li'],
    ALLOWED_ATTR: []
  });
}

export function sanitizeString(str: string): string {
  return str.trim().replace(/[<>\"']/g, '');
}
```

### CORS and Security Headers
```typescript
// src/middleware/security.ts
import { Context, Next } from 'hono';

export const securityHeaders = () => {
  return async (c: Context, next: Next) => {
    // Content Security Policy
    c.header('Content-Security-Policy', 
      "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    );
    
    // Other security headers
    c.header('X-Content-Type-Options', 'nosniff');
    c.header('X-Frame-Options', 'DENY');
    c.header('X-XSS-Protection', '1; mode=block');
    c.header('Referrer-Policy', 'strict-origin-when-cross-origin');
    c.header('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
    
    await next();
  };
};
```

## Deployment

### Dockerfile
```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM node:18-alpine AS runner

WORKDIR /app

RUN addgroup --system --gid 1001 hono
RUN adduser --system --uid 1001 hono

COPY --from=builder --chown=hono:hono /app/dist ./dist
COPY --from=builder --chown=hono:hono /app/node_modules ./node_modules
COPY --from=builder --chown=hono:hono /app/package.json ./package.json

USER hono

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### Production Configuration
```typescript
// src/config/production.ts
export const productionConfig = {
  server: {
    port: process.env.PORT || 3000,
    host: '0.0.0.0'
  },
  
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://myapp.com'],
    credentials: true
  },
  
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    maxRequests: parseInt(process.env.RATE_LIMIT_REQUESTS || '100')
  },
  
  jwt: {
    secret: process.env.JWT_SECRET!,
    expiresIn: '15m',
    refreshExpiresIn: '7d'
  },
  
  database: {
    url: process.env.DATABASE_URL!,
    ssl: process.env.NODE_ENV === 'production'
  },
  
  redis: {
    url: process.env.REDIS_URL
  }
};
```

## Common Pitfalls

1. **No input validation**: Always validate and sanitize inputs
2. **Missing error handling**: Implement comprehensive error handling
3. **No rate limiting**: Protect endpoints from abuse
4. **Weak authentication**: Use proper JWT handling and refresh tokens
5. **No logging**: Implement structured logging for debugging
6. **Database N+1 queries**: Use proper database query optimization
7. **No caching**: Implement appropriate caching strategies
8. **Missing security headers**: Use security middleware
9. **No API versioning**: Plan for API evolution
10. **Poor test coverage**: Write comprehensive tests for critical paths