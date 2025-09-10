# Express.js Best Practices

## Overview
Express.js is a minimal and flexible Node.js web application framework. These best practices ensure scalable, secure, and maintainable Express applications.

## Project Structure

### Modular Architecture
```
project/
├── src/
│   ├── app.js
│   ├── server.js
│   ├── config/
│   │   ├── database.js
│   │   ├── redis.js
│   │   └── constants.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   └── product.controller.js
│   ├── middlewares/
│   │   ├── auth.middleware.js
│   │   ├── error.middleware.js
│   │   ├── validation.middleware.js
│   │   └── rate-limit.middleware.js
│   ├── models/
│   │   ├── user.model.js
│   │   └── product.model.js
│   ├── routes/
│   │   ├── index.js
│   │   ├── auth.routes.js
│   │   └── api/
│   │       └── v1/
│   ├── services/
│   │   ├── auth.service.js
│   │   ├── email.service.js
│   │   └── cache.service.js
│   ├── utils/
│   │   ├── logger.js
│   │   ├── validator.js
│   │   └── helpers.js
│   └── validators/
│       └── schemas/
├── tests/
├── public/
└── .env.example
```

### Application Setup
```javascript
// app.js
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import mongoSanitize from 'express-mongo-sanitize';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import { errorHandler, notFound } from './middlewares/error.middleware.js';
import routes from './routes/index.js';
import logger from './utils/logger.js';

class App {
  constructor() {
    this.app = express();
    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  initializeMiddlewares() {
    // Security middlewares
    this.app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", "data:", "https:"],
        },
      },
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
      }
    }));

    // CORS configuration
    this.app.use(cors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      credentials: true,
      optionsSuccessStatus: 200,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
    }));

    // Body parsing
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Sanitization
    this.app.use(mongoSanitize());

    // Compression
    this.app.use(compression({
      level: 6,
      threshold: 100 * 1024, // 100kb
      filter: (req, res) => {
        if (req.headers['x-no-compression']) {
          return false;
        }
        return compression.filter(req, res);
      }
    }));

    // Rate limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP',
      standardHeaders: true,
      legacyHeaders: false,
    });
    this.app.use('/api', limiter);

    // Logging
    if (process.env.NODE_ENV === 'development') {
      this.app.use(morgan('dev'));
    } else {
      this.app.use(morgan('combined', {
        stream: { write: message => logger.info(message.trim()) }
      }));
    }

    // Trust proxy
    this.app.set('trust proxy', 1);
  }

  initializeRoutes() {
    this.app.use('/api', routes);
    this.app.use('/health', (req, res) => {
      res.status(200).json({ status: 'OK', timestamp: new Date() });
    });
  }

  initializeErrorHandling() {
    this.app.use(notFound);
    this.app.use(errorHandler);
  }

  listen(port) {
    return this.app.listen(port, () => {
      logger.info(`Server running on port ${port}`);
    });
  }
}

export default App;
```

## Middleware Patterns

### Authentication Middleware
```javascript
// middlewares/auth.middleware.js
import jwt from 'jsonwebtoken';
import { promisify } from 'util';
import User from '../models/user.model.js';
import AppError from '../utils/appError.js';
import catchAsync from '../utils/catchAsync.js';

export const protect = catchAsync(async (req, res, next) => {
  // 1) Get token and check if it exists
  let token;
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  } else if (req.cookies?.jwt) {
    token = req.cookies.jwt;
  }

  if (!token) {
    return next(new AppError('You are not logged in', 401));
  }

  // 2) Verify token
  const decoded = await promisify(jwt.verify)(token, process.env.JWT_SECRET);

  // 3) Check if user still exists
  const user = await User.findById(decoded.id).select('+active');
  if (!user) {
    return next(new AppError('User no longer exists', 401));
  }

  // 4) Check if user changed password after token was issued
  if (user.changedPasswordAfter(decoded.iat)) {
    return next(new AppError('User recently changed password', 401));
  }

  // 5) Grant access to protected route
  req.user = user;
  res.locals.user = user;
  next();
});

export const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission', 403));
    }
    next();
  };
};

export const checkOwnership = (model) => {
  return catchAsync(async (req, res, next) => {
    const doc = await model.findById(req.params.id);
    
    if (!doc) {
      return next(new AppError('Document not found', 404));
    }
    
    if (doc.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return next(new AppError('You do not own this resource', 403));
    }
    
    req.doc = doc;
    next();
  });
};
```

### Validation Middleware
```javascript
// middlewares/validation.middleware.js
import Joi from 'joi';

export const validate = (schema) => {
  return (req, res, next) => {
    const validationOptions = {
      abortEarly: false,
      allowUnknown: true,
      stripUnknown: true
    };

    const { error, value } = schema.validate(
      {
        body: req.body,
        query: req.query,
        params: req.params
      },
      validationOptions
    );

    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      return res.status(400).json({
        status: 'error',
        message: 'Validation error',
        errors
      });
    }

    // Replace request data with validated data
    req.body = value.body;
    req.query = value.query;
    req.params = value.params;

    next();
  };
};

// Validation schemas
export const userSchemas = {
  create: Joi.object({
    body: Joi.object({
      name: Joi.string().min(2).max(50).required(),
      email: Joi.string().email().required(),
      password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).required(),
      role: Joi.string().valid('user', 'admin').default('user')
    })
  }),
  
  update: Joi.object({
    params: Joi.object({
      id: Joi.string().hex().length(24).required()
    }),
    body: Joi.object({
      name: Joi.string().min(2).max(50),
      email: Joi.string().email(),
      active: Joi.boolean()
    }).min(1)
  })
};
```

### Error Handling Middleware
```javascript
// middlewares/error.middleware.js
import logger from '../utils/logger.js';

export const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  logger.error({
    error: err,
    request: req.url,
    method: req.method,
    ip: req.ip,
    user: req.user?.id
  });

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    error.message = 'Invalid ID format';
    error.statusCode = 400;
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    error.message = `${field} already exists`;
    error.statusCode = 400;
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map(e => e.message);
    error.message = errors.join(', ');
    error.statusCode = 400;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error.message = 'Invalid token';
    error.statusCode = 401;
  }

  if (err.name === 'TokenExpiredError') {
    error.message = 'Token expired';
    error.statusCode = 401;
  }

  res.status(error.statusCode || 500).json({
    success: false,
    error: {
      message: error.message || 'Server Error',
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    }
  });
};

export const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
```

## Routing Best Practices

### Route Organization
```javascript
// routes/index.js
import { Router } from 'express';
import authRoutes from './auth.routes.js';
import userRoutes from './user.routes.js';
import productRoutes from './product.routes.js';
import { protect } from '../middlewares/auth.middleware.js';

const router = Router();

// Public routes
router.use('/auth', authRoutes);

// Protected routes
router.use('/users', protect, userRoutes);
router.use('/products', protect, productRoutes);

// API versioning
router.use('/v1', router);

export default router;
```

### RESTful Route Design
```javascript
// routes/product.routes.js
import { Router } from 'express';
import * as productController from '../controllers/product.controller.js';
import { validate } from '../middlewares/validation.middleware.js';
import { productSchemas } from '../validators/product.validator.js';
import { restrictTo, checkOwnership } from '../middlewares/auth.middleware.js';
import Product from '../models/product.model.js';

const router = Router();

// Advanced query features
router.get(
  '/',
  validate(productSchemas.list),
  productController.getAllProducts
);

// CRUD operations
router.post(
  '/',
  restrictTo('admin', 'vendor'),
  validate(productSchemas.create),
  productController.createProduct
);

router
  .route('/:id')
  .get(validate(productSchemas.get), productController.getProduct)
  .patch(
    checkOwnership(Product),
    validate(productSchemas.update),
    productController.updateProduct
  )
  .delete(
    checkOwnership(Product),
    productController.deleteProduct
  );

// Nested routes
router.use('/:productId/reviews', reviewRoutes);

// Custom endpoints
router.post('/:id/upload-image', 
  checkOwnership(Product),
  productController.uploadImage
);

router.get('/stats', 
  restrictTo('admin'),
  productController.getProductStats
);

export default router;
```

## Controller Patterns

### Controller Implementation
```javascript
// controllers/product.controller.js
import Product from '../models/product.model.js';
import catchAsync from '../utils/catchAsync.js';
import AppError from '../utils/appError.js';
import APIFeatures from '../utils/apiFeatures.js';
import CacheService from '../services/cache.service.js';

const cache = new CacheService();

export const getAllProducts = catchAsync(async (req, res, next) => {
  // Check cache
  const cacheKey = `products:${JSON.stringify(req.query)}`;
  const cached = await cache.get(cacheKey);
  
  if (cached) {
    return res.status(200).json({
      status: 'success',
      cached: true,
      results: cached.length,
      data: { products: cached }
    });
  }

  // Build query with features
  const features = new APIFeatures(Product.find(), req.query)
    .filter()
    .sort()
    .limitFields()
    .paginate();

  const products = await features.query;

  // Cache results
  await cache.set(cacheKey, products, 300); // 5 minutes

  res.status(200).json({
    status: 'success',
    results: products.length,
    data: { products }
  });
});

export const createProduct = catchAsync(async (req, res, next) => {
  // Add user reference
  req.body.user = req.user.id;
  
  const product = await Product.create(req.body);

  // Clear cache
  await cache.clear('products:*');

  res.status(201).json({
    status: 'success',
    data: { product }
  });
});

export const updateProduct = catchAsync(async (req, res, next) => {
  // Prevent updating certain fields
  const filteredBody = filterObj(req.body, 'name', 'description', 'price', 'stock');
  
  const product = await Product.findByIdAndUpdate(
    req.params.id,
    filteredBody,
    {
      new: true,
      runValidators: true
    }
  );

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  // Clear cache
  await cache.clear('products:*');

  res.status(200).json({
    status: 'success',
    data: { product }
  });
});

export const deleteProduct = catchAsync(async (req, res, next) => {
  const product = await Product.findByIdAndDelete(req.params.id);

  if (!product) {
    return next(new AppError('No product found with that ID', 404));
  }

  // Clear cache
  await cache.clear('products:*');

  res.status(204).json({
    status: 'success',
    data: null
  });
});

// Aggregation pipeline
export const getProductStats = catchAsync(async (req, res, next) => {
  const stats = await Product.aggregate([
    {
      $match: { price: { $gte: 0 } }
    },
    {
      $group: {
        _id: '$category',
        numProducts: { $sum: 1 },
        avgPrice: { $avg: '$price' },
        minPrice: { $min: '$price' },
        maxPrice: { $max: '$price' },
        totalStock: { $sum: '$stock' }
      }
    },
    {
      $sort: { avgPrice: -1 }
    }
  ]);

  res.status(200).json({
    status: 'success',
    data: { stats }
  });
});
```

## Database Integration

### MongoDB with Mongoose
```javascript
// models/product.model.js
import mongoose from 'mongoose';
import slugify from 'slugify';

const productSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Product name is required'],
    trim: true,
    maxlength: [100, 'Product name cannot exceed 100 characters'],
    index: true
  },
  slug: String,
  description: {
    type: String,
    required: [true, 'Product description is required'],
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  price: {
    type: Number,
    required: [true, 'Product price is required'],
    min: [0, 'Price cannot be negative']
  },
  category: {
    type: String,
    required: [true, 'Product category is required'],
    enum: {
      values: ['electronics', 'clothing', 'books', 'food', 'other'],
      message: 'Invalid category'
    }
  },
  stock: {
    type: Number,
    default: 0,
    min: [0, 'Stock cannot be negative']
  },
  images: [{
    url: String,
    caption: String
  }],
  user: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: [true, 'Product must belong to a user']
  },
  ratings: {
    average: {
      type: Number,
      default: 0,
      min: [0, 'Rating must be above 0'],
      max: [5, 'Rating must be below 5.0'],
      set: val => Math.round(val * 10) / 10
    },
    quantity: {
      type: Number,
      default: 0
    }
  },
  active: {
    type: Boolean,
    default: true,
    select: false
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
productSchema.index({ price: 1, ratings: -1 });
productSchema.index({ slug: 1 });
productSchema.index({ category: 1, active: 1 });

// Virtual properties
productSchema.virtual('reviews', {
  ref: 'Review',
  foreignField: 'product',
  localField: '_id'
});

// Document middleware
productSchema.pre('save', function(next) {
  this.slug = slugify(this.name, { lower: true });
  next();
});

// Query middleware
productSchema.pre(/^find/, function(next) {
  this.find({ active: { $ne: false } });
  this.populate({
    path: 'user',
    select: 'name email'
  });
  next();
});

// Aggregation middleware
productSchema.pre('aggregate', function(next) {
  this.pipeline().unshift({ $match: { active: { $ne: false } } });
  next();
});

// Instance methods
productSchema.methods.checkStock = function(quantity) {
  return this.stock >= quantity;
};

// Static methods
productSchema.statics.getCategoryStats = async function(category) {
  return this.aggregate([
    {
      $match: { category }
    },
    {
      $group: {
        _id: null,
        avgPrice: { $avg: '$price' },
        totalProducts: { $sum: 1 },
        totalStock: { $sum: '$stock' }
      }
    }
  ]);
};

const Product = mongoose.model('Product', productSchema);

export default Product;
```

## Security Best Practices

### Security Configuration
```javascript
// config/security.js
import helmet from 'helmet';
import mongoSanitize from 'express-mongo-sanitize';
import xss from 'xss-clean';
import hpp from 'hpp';
import cors from 'cors';
import cookieParser from 'cookie-parser';

export const configureSecurity = (app) => {
  // Helmet for security headers
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
    crossOriginEmbedderPolicy: false,
  }));

  // Data sanitization against NoSQL query injection
  app.use(mongoSanitize({
    replaceWith: '_',
    onSanitize: ({ req, key }) => {
      console.warn(`Sanitized ${key} in ${req.url}`);
    }
  }));

  // Data sanitization against XSS
  app.use(xss());

  // Prevent parameter pollution
  app.use(hpp({
    whitelist: ['sort', 'fields', 'page', 'limit']
  }));

  // CORS
  const corsOptions = {
    origin: function (origin, callback) {
      const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];
      if (!origin || allowedOrigins.indexOf(origin) !== -1) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['X-Total-Count', 'X-Page-Count'],
    maxAge: 86400 // 24 hours
  };
  
  app.use(cors(corsOptions));

  // Cookie parser
  app.use(cookieParser(process.env.COOKIE_SECRET));

  // Prevent clickjacking
  app.use((req, res, next) => {
    res.setHeader('X-Frame-Options', 'DENY');
    next();
  });
};
```

## Performance Optimization

### Caching Strategy
```javascript
// services/cache.service.js
import Redis from 'ioredis';
import { promisify } from 'util';

class CacheService {
  constructor() {
    this.client = new Redis({
      host: process.env.REDIS_HOST,
      port: process.env.REDIS_PORT,
      password: process.env.REDIS_PASSWORD,
      retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
      }
    });

    this.getAsync = promisify(this.client.get).bind(this.client);
    this.setAsync = promisify(this.client.setex).bind(this.client);
    this.delAsync = promisify(this.client.del).bind(this.client);
    this.existsAsync = promisify(this.client.exists).bind(this.client);
  }

  async get(key) {
    try {
      const data = await this.getAsync(key);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.error('Cache get error:', error);
      return null;
    }
  }

  async set(key, value, ttl = 3600) {
    try {
      await this.setAsync(key, ttl, JSON.stringify(value));
      return true;
    } catch (error) {
      console.error('Cache set error:', error);
      return false;
    }
  }

  async del(pattern) {
    try {
      const keys = await this.client.keys(pattern);
      if (keys.length) {
        await this.client.del(...keys);
      }
      return true;
    } catch (error) {
      console.error('Cache delete error:', error);
      return false;
    }
  }

  async clear(pattern = '*') {
    return this.del(pattern);
  }

  // Cache middleware
  middleware(ttl = 300) {
    return async (req, res, next) => {
      if (req.method !== 'GET') {
        return next();
      }

      const key = `cache:${req.originalUrl}`;
      const cached = await this.get(key);

      if (cached) {
        return res.status(200).json({
          ...cached,
          cached: true
        });
      }

      // Store original send
      const originalSend = res.json;

      // Override send
      res.json = async (body) => {
        res.json = originalSend;
        
        if (res.statusCode === 200) {
          await this.set(key, body, ttl);
        }
        
        return res.json(body);
      };

      next();
    };
  }
}

export default CacheService;
```

## Testing

### Integration Testing
```javascript
// tests/product.test.js
import request from 'supertest';
import app from '../src/app.js';
import Product from '../src/models/product.model.js';

describe('Product API', () => {
  let authToken;
  let productId;

  beforeAll(async () => {
    // Login to get token
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'Test123!'
      });
    
    authToken = res.body.token;
  });

  describe('POST /api/products', () => {
    it('should create a new product', async () => {
      const res = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test Product',
          description: 'Test Description',
          price: 99.99,
          category: 'electronics',
          stock: 10
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.data.product).toHaveProperty('_id');
      expect(res.body.data.product.name).toBe('Test Product');
      
      productId = res.body.data.product._id;
    });

    it('should validate required fields', async () => {
      const res = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Incomplete Product'
        });

      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('errors');
    });
  });

  describe('GET /api/products', () => {
    it('should get all products with pagination', async () => {
      const res = await request(app)
        .get('/api/products?page=1&limit=10')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.products).toBeInstanceOf(Array);
      expect(res.body.data.products.length).toBeLessThanOrEqual(10);
    });

    it('should filter products by category', async () => {
      const res = await request(app)
        .get('/api/products?category=electronics')
        .set('Authorization', `Bearer ${authToken}`);

      expect(res.statusCode).toBe(200);
      res.body.data.products.forEach(product => {
        expect(product.category).toBe('electronics');
      });
    });
  });

  afterAll(async () => {
    // Cleanup
    if (productId) {
      await Product.findByIdAndDelete(productId);
    }
  });
});
```

## Best Practices Summary

1. **Modular Architecture**: Organize code in logical modules
2. **Security First**: Implement comprehensive security measures
3. **Error Handling**: Use centralized error handling
4. **Validation**: Validate all inputs thoroughly
5. **Authentication**: Implement robust JWT-based auth
6. **Rate Limiting**: Protect against abuse
7. **Caching**: Implement Redis caching for performance
8. **Logging**: Use structured logging
9. **Testing**: Write comprehensive tests
10. **Documentation**: Document APIs with Swagger/OpenAPI

## Conclusion

Express.js provides flexibility and simplicity for building Node.js applications. Following these best practices ensures your Express applications are secure, performant, and maintainable.