# RESTful API Best Practices

## Official Documentation & Resources
- **REST API Tutorial**: https://restfulapi.net
- **HTTP Status Codes**: https://httpstatuses.com
- **OpenAPI Specification**: https://swagger.io/specification
- **JSON:API Specification**: https://jsonapi.org
- **RFC 7231 (HTTP/1.1)**: https://tools.ietf.org/html/rfc7231

## API Structure

```
api/
├── v1/
│   ├── controllers/
│   ├── middleware/
│   ├── routes/
│   ├── validators/
│   └── schemas/
├── v2/
├── docs/
│   ├── openapi.yaml
│   └── postman-collection.json
├── tests/
└── config/
```

## Core REST Principles

### 1. Resource-Based URLs

```
# Good - Nouns, not verbs
GET    /api/v1/users           # Get all users
GET    /api/v1/users/123       # Get specific user
POST   /api/v1/users           # Create user
PUT    /api/v1/users/123       # Update entire user
PATCH  /api/v1/users/123       # Partial update
DELETE /api/v1/users/123       # Delete user

# Bad - Avoid verbs in URLs
GET    /api/v1/getUsers
POST   /api/v1/createUser
POST   /api/v1/deleteUser/123

# Nested resources
GET    /api/v1/users/123/posts
POST   /api/v1/users/123/posts
GET    /api/v1/users/123/posts/456
```

### 2. HTTP Methods & Status Codes

```javascript
// Express.js example
const express = require('express');
const router = express.Router();

// GET - Retrieve resources
router.get('/users', async (req, res) => {
    const users = await User.findAll();
    res.status(200).json({
        success: true,
        data: users,
        meta: {
            total: users.length,
            page: 1,
            per_page: 20
        }
    });
});

// POST - Create resource
router.post('/users', async (req, res) => {
    try {
        const user = await User.create(req.body);
        res.status(201)
           .location(`/api/v1/users/${user.id}`)
           .json({
               success: true,
               data: user
           });
    } catch (error) {
        res.status(400).json({
            success: false,
            error: {
                code: 'VALIDATION_ERROR',
                message: error.message,
                details: error.details
            }
        });
    }
});

// PUT - Full update
router.put('/users/:id', async (req, res) => {
    const user = await User.findByPk(req.params.id);
    if (!user) {
        return res.status(404).json({
            success: false,
            error: {
                code: 'RESOURCE_NOT_FOUND',
                message: 'User not found'
            }
        });
    }
    
    await user.update(req.body);
    res.status(200).json({
        success: true,
        data: user
    });
});

// PATCH - Partial update
router.patch('/users/:id', async (req, res) => {
    const user = await User.findByPk(req.params.id);
    if (!user) {
        return res.status(404).json({
            success: false,
            error: {
                code: 'RESOURCE_NOT_FOUND',
                message: 'User not found'
            }
        });
    }
    
    // Only update provided fields
    Object.keys(req.body).forEach(key => {
        if (req.body[key] !== undefined) {
            user[key] = req.body[key];
        }
    });
    
    await user.save();
    res.status(200).json({
        success: true,
        data: user
    });
});

// DELETE - Remove resource
router.delete('/users/:id', async (req, res) => {
    const deleted = await User.destroy({
        where: { id: req.params.id }
    });
    
    if (!deleted) {
        return res.status(404).json({
            success: false,
            error: {
                code: 'RESOURCE_NOT_FOUND',
                message: 'User not found'
            }
        });
    }
    
    res.status(204).send(); // No content
});
```

### 3. Status Code Guidelines

```javascript
// Success responses
200 OK              // Successful GET, PUT, PATCH
201 Created         // Successful POST
202 Accepted        // Request accepted for processing
204 No Content      // Successful DELETE

// Client errors
400 Bad Request     // Invalid request data
401 Unauthorized    // Authentication required
403 Forbidden       // Authenticated but not authorized
404 Not Found       // Resource doesn't exist
405 Method Not Allowed
409 Conflict        // Resource conflict (duplicate)
422 Unprocessable Entity // Validation errors
429 Too Many Requests // Rate limiting

// Server errors
500 Internal Server Error
502 Bad Gateway
503 Service Unavailable
504 Gateway Timeout
```

### 4. Request/Response Format

```javascript
// Consistent response structure
const apiResponse = {
    success: true,
    data: null,
    error: null,
    meta: {},
    links: {}
};

// Success response
{
    "success": true,
    "data": {
        "id": 123,
        "name": "John Doe",
        "email": "john@example.com",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
    },
    "meta": {
        "version": "1.0",
        "timestamp": "2024-01-15T10:30:00Z"
    }
}

// Error response
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Validation failed",
        "details": [
            {
                "field": "email",
                "message": "Email is required"
            },
            {
                "field": "age",
                "message": "Age must be a positive number"
            }
        ]
    },
    "meta": {
        "request_id": "550e8400-e29b-41d4-a716-446655440000"
    }
}

// Collection response with pagination
{
    "success": true,
    "data": [...],
    "meta": {
        "pagination": {
            "total": 100,
            "count": 20,
            "per_page": 20,
            "current_page": 1,
            "total_pages": 5
        }
    },
    "links": {
        "self": "/api/v1/users?page=1",
        "first": "/api/v1/users?page=1",
        "last": "/api/v1/users?page=5",
        "prev": null,
        "next": "/api/v1/users?page=2"
    }
}
```

### 5. Filtering, Sorting, and Pagination

```javascript
// Query parameters for filtering
GET /api/v1/users?status=active&role=admin&created_after=2024-01-01

// Sorting
GET /api/v1/users?sort=-created_at,name  // DESC by created_at, ASC by name

// Pagination
GET /api/v1/users?page=2&per_page=20

// Field selection (sparse fieldsets)
GET /api/v1/users?fields=id,name,email

// Search
GET /api/v1/users?q=john&search_fields=name,email

// Implementation example
router.get('/users', async (req, res) => {
    const {
        page = 1,
        per_page = 20,
        sort = '-created_at',
        fields,
        ...filters
    } = req.query;
    
    const offset = (page - 1) * per_page;
    const order = parseSort(sort); // Convert "-created_at" to [['created_at', 'DESC']]
    const attributes = fields ? fields.split(',') : undefined;
    
    const { count, rows } = await User.findAndCountAll({
        where: filters,
        order,
        attributes,
        limit: per_page,
        offset
    });
    
    res.json({
        success: true,
        data: rows,
        meta: {
            pagination: {
                total: count,
                count: rows.length,
                per_page: parseInt(per_page),
                current_page: parseInt(page),
                total_pages: Math.ceil(count / per_page)
            }
        }
    });
});
```

### 6. API Versioning

```javascript
// URL versioning (recommended)
/api/v1/users
/api/v2/users

// Header versioning
Accept: application/vnd.api+json; version=1

// Query parameter versioning
/api/users?version=1

// Express implementation
const v1Routes = require('./routes/v1');
const v2Routes = require('./routes/v2');

app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);

// Deprecation headers
res.set({
    'Sunset': 'Sat, 31 Dec 2024 23:59:59 GMT',
    'Deprecation': 'true',
    'Link': '</api/v2/users>; rel="successor-version"'
});
```

### 7. Authentication & Authorization

```javascript
// JWT Bearer token
const jwt = require('jsonwebtoken');

// Authentication middleware
const authenticate = async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({
            success: false,
            error: {
                code: 'UNAUTHORIZED',
                message: 'Authentication required'
            }
        });
    }
    
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = await User.findByPk(decoded.userId);
        next();
    } catch (error) {
        res.status(401).json({
            success: false,
            error: {
                code: 'INVALID_TOKEN',
                message: 'Invalid or expired token'
            }
        });
    }
};

// Authorization middleware
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                error: {
                    code: 'FORBIDDEN',
                    message: 'Insufficient permissions'
                }
            });
        }
        next();
    };
};

// Usage
router.get('/admin/users', 
    authenticate, 
    authorize('admin'), 
    getUsersController
);

// API Key authentication
const apiKeyAuth = (req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    
    if (!apiKey || !isValidApiKey(apiKey)) {
        return res.status(401).json({
            success: false,
            error: {
                code: 'INVALID_API_KEY',
                message: 'Valid API key required'
            }
        });
    }
    next();
};
```

### 8. Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

// Create limiter
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
        success: false,
        error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many requests, please try again later'
        }
    },
    standardHeaders: true, // Return rate limit info in headers
    legacyHeaders: false,
});

// Apply to routes
app.use('/api/', limiter);

// Different limits for different endpoints
const strictLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    skipSuccessfulRequests: true
});

app.post('/api/v1/auth/login', strictLimiter, loginController);

// Custom rate limit headers
res.set({
    'X-RateLimit-Limit': 100,
    'X-RateLimit-Remaining': 95,
    'X-RateLimit-Reset': new Date(Date.now() + 60000).toISOString()
});
```

### 9. HATEOAS (Hypermedia as the Engine of Application State)

```javascript
// Include links in responses
{
    "success": true,
    "data": {
        "id": 123,
        "name": "John Doe",
        "email": "john@example.com"
    },
    "links": {
        "self": "/api/v1/users/123",
        "posts": "/api/v1/users/123/posts",
        "followers": "/api/v1/users/123/followers",
        "avatar": "/api/v1/users/123/avatar"
    },
    "actions": {
        "update": {
            "href": "/api/v1/users/123",
            "method": "PUT"
        },
        "delete": {
            "href": "/api/v1/users/123",
            "method": "DELETE"
        }
    }
}
```

### 10. Error Handling

```javascript
// Centralized error handler
class ApiError extends Error {
    constructor(statusCode, code, message, details = null) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
    }
}

// Error handler middleware
const errorHandler = (err, req, res, next) => {
    let error = { ...err };
    error.message = err.message;
    
    // Log error
    console.error(err);
    
    // Mongoose validation error
    if (err.name === 'ValidationError') {
        const details = Object.values(err.errors).map(e => ({
            field: e.path,
            message: e.message
        }));
        error = new ApiError(400, 'VALIDATION_ERROR', 'Validation failed', details);
    }
    
    // Mongoose duplicate key
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue)[0];
        error = new ApiError(409, 'DUPLICATE_ERROR', `${field} already exists`);
    }
    
    res.status(error.statusCode || 500).json({
        success: false,
        error: {
            code: error.code || 'INTERNAL_ERROR',
            message: error.message || 'Server Error',
            details: error.details,
            ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
        },
        meta: {
            request_id: req.id,
            timestamp: new Date().toISOString()
        }
    });
};

app.use(errorHandler);
```

### 11. Caching

```javascript
// Cache headers
const cacheMiddleware = (duration = 3600) => {
    return (req, res, next) => {
        res.set({
            'Cache-Control': `public, max-age=${duration}`,
            'ETag': generateETag(res.body),
            'Last-Modified': new Date().toUTCString()
        });
        next();
    };
};

// Conditional requests
router.get('/users/:id', async (req, res) => {
    const user = await User.findByPk(req.params.id);
    const etag = generateETag(user);
    
    res.set('ETag', etag);
    
    if (req.headers['if-none-match'] === etag) {
        return res.status(304).send(); // Not Modified
    }
    
    res.json({
        success: true,
        data: user
    });
});

// Redis caching
const redis = require('redis');
const client = redis.createClient();

const cacheMiddleware = (duration = 3600) => {
    return async (req, res, next) => {
        const key = `cache:${req.originalUrl}`;
        
        try {
            const cached = await client.get(key);
            if (cached) {
                return res.json(JSON.parse(cached));
            }
        } catch (err) {
            console.error('Cache error:', err);
        }
        
        // Store original json method
        const originalJson = res.json;
        
        // Override json method to cache response
        res.json = function(data) {
            client.setex(key, duration, JSON.stringify(data));
            originalJson.call(this, data);
        };
        
        next();
    };
};
```

### 12. API Documentation (OpenAPI/Swagger)

```yaml
# openapi.yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
  description: RESTful API for user management

servers:
  - url: https://api.example.com/v1
    description: Production server
  - url: http://localhost:3000/api/v1
    description: Development server

paths:
  /users:
    get:
      summary: List all users
      operationId: listUsers
      tags:
        - Users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: per_page
          in: query
          schema:
            type: integer
            default: 20
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UsersResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
    
    post:
      summary: Create a new user
      operationId: createUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserInput'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserResponse'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        email:
          type: string
          format: email
      required:
        - id
        - name
        - email
        
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### 13. Testing

```javascript
// Jest/Supertest example
const request = require('supertest');
const app = require('../app');

describe('User API', () => {
    describe('GET /api/v1/users', () => {
        it('should return list of users', async () => {
            const response = await request(app)
                .get('/api/v1/users')
                .set('Authorization', 'Bearer ' + token)
                .expect(200);
                
            expect(response.body).toHaveProperty('success', true);
            expect(response.body).toHaveProperty('data');
            expect(Array.isArray(response.body.data)).toBe(true);
        });
        
        it('should handle pagination', async () => {
            const response = await request(app)
                .get('/api/v1/users?page=2&per_page=10')
                .set('Authorization', 'Bearer ' + token)
                .expect(200);
                
            expect(response.body.meta.pagination.current_page).toBe(2);
            expect(response.body.meta.pagination.per_page).toBe(10);
        });
    });
    
    describe('POST /api/v1/users', () => {
        it('should create a new user', async () => {
            const newUser = {
                name: 'John Doe',
                email: 'john@example.com'
            };
            
            const response = await request(app)
                .post('/api/v1/users')
                .set('Authorization', 'Bearer ' + token)
                .send(newUser)
                .expect(201);
                
            expect(response.body.data).toMatchObject(newUser);
            expect(response.headers.location).toBe(`/api/v1/users/${response.body.data.id}`);
        });
        
        it('should return validation errors', async () => {
            const invalidUser = {
                name: 'John'
                // Missing email
            };
            
            const response = await request(app)
                .post('/api/v1/users')
                .set('Authorization', 'Bearer ' + token)
                .send(invalidUser)
                .expect(400);
                
            expect(response.body.success).toBe(false);
            expect(response.body.error.code).toBe('VALIDATION_ERROR');
        });
    });
});
```

### Common Pitfalls to Avoid

1. **Using verbs in URLs instead of nouns**
2. **Returning incorrect status codes**
3. **Inconsistent response formats**
4. **Not implementing pagination for lists**
5. **Missing proper error handling**
6. **No API versioning strategy**
7. **Exposing internal implementation details**
8. **Not implementing rate limiting**
9. **Missing authentication/authorization**
10. **Poor or no documentation**
11. **Not following HTTP method semantics**
12. **Ignoring caching opportunities**

### Useful Tools & Libraries

- **Express.js**: Node.js web framework
- **Fastify**: Fast Node.js web framework
- **Swagger/OpenAPI**: API documentation
- **Postman**: API testing
- **Insomnia**: API design and testing
- **JSON Schema**: Request/response validation
- **express-validator**: Request validation
- **helmet**: Security headers
- **cors**: CORS handling
- **compression**: Response compression
- **morgan**: HTTP request logger