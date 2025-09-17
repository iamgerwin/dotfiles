# FeathersJS Best Practices

## Overview

FeathersJS is a lightweight web framework for creating real-time applications and REST APIs using JavaScript or TypeScript. Built around the concept of services, Feathers provides a highly flexible, framework-agnostic way to build modern web applications with real-time capabilities through WebSockets. It offers a service-oriented architecture that works seamlessly with any frontend technology and supports multiple databases and authentication strategies.

Feathers emphasizes simplicity and developer productivity while providing powerful features like real-time events, universal usage (works with React Native, client-side, and server-side), and a plugin ecosystem that allows easy integration with various tools and services.

## Pros & Cons

### Pros
- **Real-time by Default**: Built-in WebSocket support for real-time applications
- **Service-Oriented Architecture**: Clean, modular approach to API design
- **Database Agnostic**: Works with SQL, NoSQL, and in-memory databases
- **Frontend Agnostic**: Compatible with any frontend framework
- **TypeScript Support**: Full TypeScript support with excellent type safety
- **Authentication Built-in**: Comprehensive authentication and authorization
- **Lightweight**: Minimal overhead and fast performance
- **Plugin Ecosystem**: Rich ecosystem of community and official plugins
- **Flexible Hooks**: Powerful middleware system for customization
- **Universal JavaScript**: Same codebase for client and server

### Cons
- **Learning Curve**: Service-oriented concepts may be unfamiliar
- **Smaller Community**: Less popular than Express.js or other frameworks
- **Documentation Gaps**: Some advanced topics lack comprehensive documentation
- **Opinionated Structure**: May not fit all architectural preferences
- **Real-time Complexity**: WebSocket debugging can be challenging
- **Limited Resources**: Fewer tutorials and learning materials available

## When to Use

FeathersJS is ideal for:
- Real-time applications (chat, collaboration tools, live dashboards)
- APIs requiring instant data synchronization across clients
- Applications with complex authentication and authorization needs
- Microservices architectures requiring consistent API patterns
- Full-stack JavaScript applications
- Mobile applications needing real-time backend services
- Projects requiring rapid API development with standardized patterns
- Applications that need to work across multiple platforms

Avoid FeathersJS for:
- Simple static websites or basic CRUD applications
- Applications where real-time features are unnecessary
- Teams unfamiliar with service-oriented architecture
- Projects with strict performance requirements (consider lower-level alternatives)
- Applications requiring extensive customization beyond Feathers patterns

## Core Concepts

### Services Architecture

```javascript
// Basic service structure
const { Service } = require('feathers-mongoose');

class MessageService extends Service {
  constructor(options, app) {
    super(options);
    this.app = app;
  }

  // Standard CRUD methods are automatically provided
  // find, get, create, update, patch, remove

  // Custom methods can be added
  async markAsRead(id, params) {
    return this.patch(id, { read: true }, params);
  }

  // Override standard methods for custom logic
  async create(data, params) {
    // Add timestamp and user info
    const messageData = {
      ...data,
      createdAt: new Date(),
      userId: params.user.id
    };

    return super.create(messageData, params);
  }

  async find(params) {
    // Add default sorting
    params.query = {
      ...params.query,
      $sort: { createdAt: -1 }
    };

    return super.find(params);
  }
}

module.exports = function (app) {
  const options = {
    Model: app.get('mongooseClient').model('Message'),
    paginate: app.get('paginate')
  };

  app.use('/messages', new MessageService(options, app));

  const service = app.service('messages');

  // Add hooks for validation, authentication, etc.
  service.hooks({
    before: {
      all: [authenticate('jwt')],
      find: [],
      get: [],
      create: [validateMessage()],
      update: [disallow()],
      patch: [checkOwnership()],
      remove: [checkOwnership()]
    },
    after: {
      all: [
        // Populate user information
        populate({
          schema: {
            include: [{
              service: 'users',
              nameAs: 'user',
              parentField: 'userId',
              childField: 'id'
            }]
          }
        })
      ],
      find: [],
      get: [],
      create: [notifyUsers()],
      update: [],
      patch: [],
      remove: []
    }
  });
};

// Custom hooks for business logic
function validateMessage() {
  return async context => {
    const { data } = context;

    if (!data.text || data.text.trim().length === 0) {
      throw new BadRequest('Message text is required');
    }

    if (data.text.length > 1000) {
      throw new BadRequest('Message text cannot exceed 1000 characters');
    }

    // Sanitize message content
    data.text = data.text.trim();

    return context;
  };
}

function checkOwnership() {
  return async context => {
    const { params, id } = context;
    const message = await context.app.service('messages').get(id);

    if (message.userId !== params.user.id) {
      throw new Forbidden('You can only modify your own messages');
    }

    return context;
  };
}

function notifyUsers() {
  return async context => {
    const { result } = context;

    // Emit real-time event to all connected clients
    context.app.service('messages').emit('created', result);

    return context;
  };
}
```

### Authentication and Authorization

```javascript
// Authentication configuration
const { AuthenticationService, JWTStrategy } = require('@feathersjs/authentication');
const { LocalStrategy } = require('@feathersjs/authentication-local');
const { OAuth2Strategy } = require('@feathersjs/authentication-oauth');

class CustomAuthenticationService extends AuthenticationService {
  async getPayload(authResult, params) {
    const payload = await super.getPayload(authResult, params);

    // Add custom claims to JWT
    payload.role = authResult.user.role;
    payload.permissions = authResult.user.permissions;

    return payload;
  }
}

module.exports = app => {
  const authentication = new CustomAuthenticationService(app);

  authentication.register('jwt', new JWTStrategy());
  authentication.register('local', new LocalStrategy());
  authentication.register('google', new OAuth2Strategy());
  authentication.register('github', new OAuth2Strategy());

  app.use('/authentication', authentication);

  // Authentication hooks
  app.service('authentication').hooks({
    before: {
      create: [
        // Rate limiting
        rateLimit({
          max: 5,
          window: 60000, // 1 minute
          message: 'Too many login attempts'
        }),
        // Additional validation
        validateLoginAttempt()
      ],
      remove: []
    },
    after: {
      create: [
        // Log successful logins
        logSuccessfulLogin(),
        // Update last login timestamp
        updateLastLogin()
      ]
    }
  });
};

// Custom authentication hooks
function validateLoginAttempt() {
  return async context => {
    const { data } = context;

    // Check if user account is active
    if (data.strategy === 'local') {
      const user = await context.app.service('users').find({
        query: { email: data.email }
      });

      if (user.total === 0) {
        throw new NotAuthenticated('Invalid credentials');
      }

      if (!user.data[0].isActive) {
        throw new NotAuthenticated('Account is deactivated');
      }
    }

    return context;
  };
}

// Role-based authorization hook
function authorize(...roles) {
  return async context => {
    const { params } = context;

    if (!params.user) {
      throw new NotAuthenticated('Not authenticated');
    }

    if (roles.length > 0 && !roles.includes(params.user.role)) {
      throw new Forbidden(`Requires one of: ${roles.join(', ')}`);
    }

    return context;
  };
}

// Permission-based authorization
function can(permission) {
  return async context => {
    const { params } = context;

    if (!params.user) {
      throw new NotAuthenticated('Not authenticated');
    }

    if (!params.user.permissions.includes(permission)) {
      throw new Forbidden(`Requires permission: ${permission}`);
    }

    return context;
  };
}

// Usage in service hooks
app.service('admin-users').hooks({
  before: {
    all: [authenticate('jwt'), authorize('admin', 'moderator')],
    create: [can('create_user')],
    update: [can('update_user')],
    remove: [can('delete_user')]
  }
});
```

### Real-time Events and Channels

```javascript
// Channel configuration for real-time events
module.exports = function(app) {
  if (typeof app.channel !== 'function') {
    return;
  }

  app.on('connection', connection => {
    // Join anonymous channel
    app.channel('anonymous').join(connection);
  });

  app.on('login', (authResult, { connection }) => {
    const { user } = authResult;

    if (connection) {
      // Remove from anonymous channel
      app.channel('anonymous').leave(connection);

      // Join authenticated user channel
      app.channel('authenticated').join(connection);

      // Join user-specific channel
      app.channel(`user:${user.id}`).join(connection);

      // Join role-based channels
      app.channel(`role:${user.role}`).join(connection);

      // Join organization/team channels
      if (user.organizationId) {
        app.channel(`org:${user.organizationId}`).join(connection);
      }
    }
  });

  app.on('disconnect', connection => {
    // Clean up all channels for this connection
  });

  // Configure which events are sent to which channels
  app.publish((data, hook) => {
    const { service, method, result, params } = hook;

    // Messages service real-time events
    if (service === 'messages') {
      switch (method) {
        case 'created':
          // Send to all authenticated users
          return app.channel('authenticated');

        case 'patched':
        case 'updated':
          // Send only to message owner and admins
          return [
            app.channel(`user:${result.userId}`),
            app.channel('role:admin')
          ];

        case 'removed':
          // Send to all users in the same channel/room
          return app.channel(`room:${result.roomId}`);

        default:
          return [];
      }
    }

    // Notification service
    if (service === 'notifications') {
      if (method === 'created') {
        // Send notification to specific user
        return app.channel(`user:${result.userId}`);
      }
    }

    // User service
    if (service === 'users') {
      if (method === 'patched' || method === 'updated') {
        // Send user updates only to the user themselves
        return app.channel(`user:${result.id}`);
      }
    }

    // Default: don't send any real-time events
    return [];
  });

  // Custom channel management
  app.service('rooms').on('created', room => {
    // Create new room channel
    app.channel(`room:${room.id}`);
  });

  app.service('room-members').on('created', membership => {
    // Add user to room channel
    const connection = app.channel(`user:${membership.userId}`).connections[0];
    if (connection) {
      app.channel(`room:${membership.roomId}`).join(connection);
    }
  });

  app.service('room-members').on('removed', membership => {
    // Remove user from room channel
    const connection = app.channel(`user:${membership.userId}`).connections[0];
    if (connection) {
      app.channel(`room:${membership.roomId}`).leave(connection);
    }
  });
};

// Custom real-time service for complex scenarios
class NotificationService {
  constructor(options, app) {
    this.app = app;
    this.options = options;
  }

  async create(data, params) {
    const notification = await this.app.service('notifications').create(data, params);

    // Send real-time notification with custom logic
    const user = await this.app.service('users').get(notification.userId);

    // Check user's notification preferences
    if (user.preferences.realTimeNotifications) {
      this.app.channel(`user:${user.id}`).send({
        type: 'notification',
        data: notification
      });
    }

    // Send push notification if user is offline
    const userConnections = this.app.channel(`user:${user.id}`).connections;
    if (userConnections.length === 0) {
      await this.sendPushNotification(user, notification);
    }

    return notification;
  }

  async sendPushNotification(user, notification) {
    // Integrate with push notification service
    const pushService = this.app.service('push-notifications');
    await pushService.send({
      userId: user.id,
      title: notification.title,
      body: notification.message,
      data: notification
    });
  }
}
```

## Installation & Setup

### Project Initialization

```bash
# Install Feathers CLI globally
npm install -g @feathersjs/cli

# Create new Feathers application
feathers generate app

# Follow the prompts:
# ? Project name: my-feathers-app
# ? Description: My awesome Feathers application
# ? What folder should the source files live in? src
# ? Which package manager are you using? npm
# ? What type of API are you making? REST, Realtime via Socket.io
# ? Which testing framework do you prefer? Jest
# ? This app uses authentication: Yes
# ? What authentication methods do you want? Username/Password, Google, GitHub

cd my-feathers-app
npm install

# Generate a service
feathers generate service

# Follow the prompts:
# ? What kind of service is it? Mongoose
# ? What is the name of the service? messages
# ? Which path should the service be registered on? /messages
# ? What is the database connection string? mongodb://localhost:27017/feathers
```

### Manual Setup

```bash
# Create new project
mkdir my-feathers-app
cd my-feathers-app
npm init -y

# Install core dependencies
npm install @feathersjs/feathers @feathersjs/express @feathersjs/socketio
npm install @feathersjs/authentication @feathersjs/authentication-local
npm install @feathersjs/authentication-oauth @feathersjs/authentication-jwt
npm install @feathersjs/configuration @feathersjs/errors

# Install database adapter (choose one)
npm install feathers-mongoose mongoose  # MongoDB
npm install feathers-sequelize sequelize sqlite3  # SQL with SQLite
npm install feathers-knex knex sqlite3  # SQL with Knex

# Install development dependencies
npm install --save-dev nodemon jest @types/node typescript ts-node
```

### Basic App Structure

```javascript
// src/app.js
const feathers = require('@feathersjs/feathers');
const express = require('@feathersjs/express');
const socketio = require('@feathersjs/socketio');
const configuration = require('@feathersjs/configuration');

const middleware = require('./middleware');
const services = require('./services');
const appHooks = require('./app.hooks');
const channels = require('./channels');
const authentication = require('./authentication');
const mongoose = require('./mongoose');

const app = express(feathers());

// Load app configuration
app.configure(configuration());

// Enable security, CORS, compression, favicon and body parsing
app.use(express.helmet({
  contentSecurityPolicy: false
}));
app.use(express.cors());
app.use(express.compress());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.favicon());

// Host the public folder
app.use('/', express.static(app.get('public')));

// Set up Plugins and providers
app.configure(express.rest());
app.configure(socketio());

app.configure(mongoose);

// Configure other middleware (see `middleware/index.js`)
app.configure(middleware);
app.configure(authentication);

// Set up our services (see `services/index.js`)
app.configure(services);

// Set up event channels (see channels.js)
app.configure(channels);

// Configure a middleware for 404s and the error handler
app.use(express.notFound());
app.use(express.errorHandler({ logger: console.log }));

app.hooks(appHooks);

module.exports = app;

// src/index.js
const logger = require('./logger');
const app = require('./app');
const port = app.get('port');
const server = app.listen(port);

process.on('unhandledRejection', (reason, p) =>
  logger.error('Unhandled Rejection at: Promise ', p, reason)
);

server.on('listening', () =>
  logger.info('Feathers application started on http://%s:%d', app.get('host'), port)
);
```

### Configuration

```javascript
// config/default.json
{
  "host": "localhost",
  "port": 3030,
  "public": "../public/",
  "paginate": {
    "default": 10,
    "max": 50
  },
  "mongodb": "mongodb://localhost:27017/feathersjs",
  "authentication": {
    "entity": "user",
    "service": "users",
    "secret": "your-secret-key",
    "authStrategies": ["jwt", "local"],
    "jwtOptions": {
      "header": {
        "typ": "access"
      },
      "audience": "https://yourdomain.com",
      "issuer": "feathers",
      "algorithm": "HS256",
      "expiresIn": "1d"
    },
    "local": {
      "usernameField": "email",
      "passwordField": "password"
    },
    "oauth": {
      "google": {
        "key": "your-google-client-id",
        "secret": "your-google-client-secret",
        "scope": ["profile", "email"]
      }
    }
  }
}

// config/production.json
{
  "host": "0.0.0.0",
  "port": "PORT",
  "mongodb": "MONGODB_CONNECTION_STRING",
  "authentication": {
    "secret": "JWT_SECRET"
  }
}
```

## Project Structure

### Recommended Directory Structure

```
my-feathers-app/
├── config/
│   ├── default.json
│   ├── production.json
│   └── test.json
├── public/
│   └── index.html
├── src/
│   ├── authentication.js
│   ├── channels.js
│   ├── app.hooks.js
│   ├── app.js
│   ├── index.js
│   ├── logger.js
│   ├── mongoose.js
│   ├── hooks/
│   │   ├── authenticate.js
│   │   ├── authorize.js
│   │   ├── populate.js
│   │   ├── validate.js
│   │   └── index.js
│   ├── middleware/
│   │   ├── index.js
│   │   ├── cors.js
│   │   ├── rate-limit.js
│   │   └── error-handler.js
│   ├── models/
│   │   ├── users.model.js
│   │   ├── messages.model.js
│   │   └── index.js
│   ├── services/
│   │   ├── index.js
│   │   ├── users/
│   │   │   ├── users.service.js
│   │   │   ├── users.class.js
│   │   │   ├── users.hooks.js
│   │   │   └── users.test.js
│   │   └── messages/
│   │       ├── messages.service.js
│   │       ├── messages.class.js
│   │       ├── messages.hooks.js
│   │       └── messages.test.js
│   └── utils/
│       ├── email.js
│       ├── upload.js
│       └── helpers.js
├── test/
│   ├── app.test.js
│   ├── authentication.test.js
│   └── services/
├── package.json
└── README.md
```

### Service Implementation

```javascript
// src/services/messages/messages.class.js
const { Service } = require('feathers-mongoose');

exports.Messages = class Messages extends Service {
  constructor(options, app) {
    super(options);
    this.app = app;
  }

  async find(params) {
    // Add user-specific filtering
    if (params.user && params.user.role !== 'admin') {
      params.query = {
        ...params.query,
        $or: [
          { userId: params.user.id },
          { recipients: params.user.id },
          { public: true }
        ]
      };
    }

    return super.find(params);
  }

  async create(data, params) {
    // Process message data
    const messageData = {
      ...data,
      userId: params.user.id,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    // Validate recipients
    if (data.recipients && data.recipients.length > 0) {
      const users = await this.app.service('users').find({
        query: {
          id: { $in: data.recipients },
          isActive: true
        }
      });

      if (users.total !== data.recipients.length) {
        throw new BadRequest('One or more recipients not found');
      }
    }

    const result = await super.create(messageData, params);

    // Send notifications
    if (result.recipients && result.recipients.length > 0) {
      await this.sendNotifications(result);
    }

    return result;
  }

  async patch(id, data, params) {
    // Only allow owner or admin to modify
    const message = await this.get(id, params);

    if (message.userId !== params.user.id && params.user.role !== 'admin') {
      throw new Forbidden('Not authorized to modify this message');
    }

    data.updatedAt = new Date();
    return super.patch(id, data, params);
  }

  async remove(id, params) {
    const message = await this.get(id, params);

    if (message.userId !== params.user.id && params.user.role !== 'admin') {
      throw new Forbidden('Not authorized to delete this message');
    }

    return super.remove(id, params);
  }

  async sendNotifications(message) {
    const notifications = message.recipients.map(recipientId => ({
      userId: recipientId,
      type: 'message',
      title: 'New Message',
      message: `You have a new message from ${message.user.name}`,
      data: { messageId: message.id },
      createdAt: new Date()
    }));

    await this.app.service('notifications').create(notifications);
  }

  // Custom methods
  async markAsRead(id, params) {
    return this.patch(id, {
      readBy: [...(params.message.readBy || []), params.user.id],
      readAt: new Date()
    }, params);
  }

  async getUnreadCount(params) {
    const count = await super.find({
      ...params,
      query: {
        recipients: params.user.id,
        readBy: { $ne: params.user.id }
      },
      paginate: false
    });

    return { count: count.length };
  }
};

// src/services/messages/messages.hooks.js
const { authenticate } = require('@feathersjs/authentication').hooks;
const { populate, discard, iff, isProvider } = require('feathers-hooks-common');

const validateMessage = require('../../hooks/validate-message');
const addAssociations = require('../../hooks/add-associations');

module.exports = {
  before: {
    all: [authenticate('jwt')],
    find: [],
    get: [],
    create: [
      validateMessage(),
      discard('id', 'createdAt', 'updatedAt')
    ],
    update: [discard('external')],
    patch: [discard('external')],
    remove: []
  },

  after: {
    all: [
      // Populate user information
      iff(isProvider('external'),
        populate({
          schema: {
            include: [{
              service: 'users',
              nameAs: 'user',
              parentField: 'userId',
              childField: 'id',
              select: ['id', 'name', 'email', 'avatar']
            }]
          }
        })
      )
    ],
    find: [],
    get: [],
    create: [
      addAssociations()
    ],
    update: [],
    patch: [],
    remove: []
  },

  error: {
    all: [],
    find: [],
    get: [],
    create: [],
    update: [],
    patch: [],
    remove: []
  }
};

// src/services/messages/messages.service.js
const { Messages } = require('./messages.class');
const createModel = require('../../models/messages.model');
const hooks = require('./messages.hooks');

module.exports = function (app) {
  const options = {
    Model: createModel(app),
    paginate: app.get('paginate'),
    multi: ['create', 'patch', 'remove']
  };

  // Initialize our service with any options it requires
  app.use('/messages', new Messages(options, app));

  // Get our initialized service so that we can register hooks
  const service = app.service('messages');

  // Register custom methods
  service.methods = {
    markAsRead: ['id'],
    getUnreadCount: []
  };

  service.hooks(hooks);
};
```

## Development Patterns

### Custom Hooks Development

```javascript
// src/hooks/validate.js
const { BadRequest } = require('@feathersjs/errors');

// Generic validation hook factory
function validate(schema) {
  return async context => {
    const { data } = context;

    try {
      // Use your preferred validation library (Joi, Yup, etc.)
      const validatedData = await schema.validate(data, { abortEarly: false });
      context.data = validatedData;
    } catch (error) {
      throw new BadRequest('Validation failed', {
        errors: error.details || error.errors
      });
    }

    return context;
  };
}

// Specific validation hooks
function validateUser() {
  return async context => {
    const { data, method } = context;

    if (method === 'create') {
      if (!data.email || !data.password) {
        throw new BadRequest('Email and password are required');
      }

      // Check email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(data.email)) {
        throw new BadRequest('Invalid email format');
      }

      // Check password strength
      if (data.password.length < 8) {
        throw new BadRequest('Password must be at least 8 characters long');
      }

      // Check if email already exists
      const existingUser = await context.app.service('users').find({
        query: { email: data.email }
      });

      if (existingUser.total > 0) {
        throw new BadRequest('Email already exists');
      }
    }

    return context;
  };
}

// Async validation with external services
function validateUniqueUsername() {
  return async context => {
    const { data, id, method } = context;

    if ((method === 'create' || method === 'patch') && data.username) {
      const query = { username: data.username };

      // Exclude current user for updates
      if (id) {
        query.id = { $ne: id };
      }

      const existing = await context.app.service('users').find({ query });

      if (existing.total > 0) {
        throw new BadRequest('Username already taken');
      }
    }

    return context;
  };
}

module.exports = { validate, validateUser, validateUniqueUsername };

// src/hooks/sanitize.js
function sanitizeInput() {
  return async context => {
    const { data } = context;

    if (data && typeof data === 'object') {
      // Remove potential XSS attacks
      Object.keys(data).forEach(key => {
        if (typeof data[key] === 'string') {
          // Remove script tags and javascript: protocols
          data[key] = data[key]
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
            .replace(/javascript:/gi, '')
            .trim();
        }
      });
    }

    return context;
  };
}

function sanitizeHtml(fields) {
  return async context => {
    const { data } = context;

    if (data) {
      fields.forEach(field => {
        if (data[field]) {
          // Use a library like DOMPurify or similar
          data[field] = purifyHtml(data[field]);
        }
      });
    }

    return context;
  };
}

// src/hooks/rate-limit.js
const rateLimitStore = new Map();

function rateLimit(options = {}) {
  const { max = 100, window = 60000, message = 'Rate limit exceeded' } = options;

  return async context => {
    const { params } = context;
    const identifier = params.user?.id || params.ip || 'anonymous';
    const key = `${context.service.path}:${identifier}`;
    const now = Date.now();

    if (!rateLimitStore.has(key)) {
      rateLimitStore.set(key, { count: 1, resetTime: now + window });
    } else {
      const limit = rateLimitStore.get(key);

      if (now > limit.resetTime) {
        // Reset the limit
        limit.count = 1;
        limit.resetTime = now + window;
      } else {
        limit.count++;

        if (limit.count > max) {
          throw new TooManyRequests(message);
        }
      }
    }

    return context;
  };
}

// src/hooks/cache.js
const cache = new Map();

function cacheResult(options = {}) {
  const { ttl = 300000, keyGenerator } = options; // 5 minutes default

  return async context => {
    if (context.type !== 'after' || context.method !== 'find') {
      return context;
    }

    const key = keyGenerator ?
      keyGenerator(context) :
      `${context.service.path}:${JSON.stringify(context.params.query)}`;

    // Store result in cache
    cache.set(key, {
      data: context.result,
      timestamp: Date.now()
    });

    // Clean up expired entries
    setTimeout(() => {
      if (cache.has(key)) {
        const entry = cache.get(key);
        if (Date.now() - entry.timestamp > ttl) {
          cache.delete(key);
        }
      }
    }, ttl);

    return context;
  };
}

function getCachedResult(options = {}) {
  const { ttl = 300000, keyGenerator } = options;

  return async context => {
    if (context.type !== 'before' || context.method !== 'find') {
      return context;
    }

    const key = keyGenerator ?
      keyGenerator(context) :
      `${context.service.path}:${JSON.stringify(context.params.query)}`;

    if (cache.has(key)) {
      const entry = cache.get(key);
      const age = Date.now() - entry.timestamp;

      if (age < ttl) {
        // Return cached result
        context.result = entry.data;
        return context;
      } else {
        // Remove expired entry
        cache.delete(key);
      }
    }

    return context;
  };
}
```

### Database Patterns

```javascript
// src/models/users.model.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 8
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'moderator'],
    default: 'user'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  profile: {
    avatar: String,
    bio: String,
    website: String,
    location: String
  },
  preferences: {
    notifications: {
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: true },
      realTime: { type: Boolean, default: true }
    },
    privacy: {
      showEmail: { type: Boolean, default: false },
      showProfile: { type: Boolean, default: true }
    }
  },
  lastLoginAt: Date,
  verificationToken: String,
  resetPasswordToken: String,
  resetPasswordExpires: Date
}, {
  timestamps: true
});

// Indexes for performance
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });
userSchema.index({ isActive: 1 });
userSchema.index({ createdAt: -1 });

// Virtual fields
userSchema.virtual('fullName').get(function() {
  return this.name;
});

// Instance methods
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  delete user.verificationToken;
  delete user.resetPasswordToken;
  delete user.resetPasswordExpires;
  return user;
};

userSchema.methods.generateResetToken = function() {
  const crypto = require('crypto');
  this.resetPasswordToken = crypto.randomBytes(20).toString('hex');
  this.resetPasswordExpires = Date.now() + 3600000; // 1 hour
  return this.resetPasswordToken;
};

// Static methods
userSchema.statics.findActiveUsers = function() {
  return this.find({ isActive: true });
};

userSchema.statics.findByRole = function(role) {
  return this.find({ role, isActive: true });
};

// Middleware
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();

  const bcrypt = require('bcryptjs');
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.pre('find', function() {
  // Default to active users only
  if (!this.getQuery().isActive) {
    this.where({ isActive: { $ne: false } });
  }
});

module.exports = function (app) {
  const mongooseClient = app.get('mongooseClient');
  const users = mongooseClient.model('User', userSchema);

  return users;
};

// Advanced model with relationships
// src/models/posts.model.js
const postSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  content: {
    type: String,
    required: true
  },
  excerpt: {
    type: String,
    maxlength: 500
  },
  slug: {
    type: String,
    unique: true,
    lowercase: true
  },
  status: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'draft'
  },
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  category: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category'
  },
  tags: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tag'
  }],
  metadata: {
    readTime: Number,
    wordCount: Number,
    featuredImage: String
  },
  publishedAt: Date,
  viewCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Compound indexes
postSchema.index({ status: 1, publishedAt: -1 });
postSchema.index({ author: 1, status: 1 });
postSchema.index({ slug: 1 }, { unique: true });

// Text search index
postSchema.index({
  title: 'text',
  content: 'text',
  excerpt: 'text'
});

// Pre-save middleware
postSchema.pre('save', function(next) {
  if (this.isModified('title') && !this.slug) {
    this.slug = this.title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
  }

  if (this.isModified('content')) {
    // Calculate read time and word count
    const words = this.content.split(/\s+/).length;
    this.metadata.wordCount = words;
    this.metadata.readTime = Math.ceil(words / 200); // 200 words per minute
  }

  if (this.isModified('status') && this.status === 'published' && !this.publishedAt) {
    this.publishedAt = new Date();
  }

  next();
});

// Virtual populate
postSchema.virtual('comments', {
  ref: 'Comment',
  localField: '_id',
  foreignField: 'post'
});

postSchema.set('toJSON', { virtuals: true });
```

### Error Handling Patterns

```javascript
// src/hooks/error-handler.js
const { GeneralError } = require('@feathersjs/errors');

function handleErrors() {
  return async context => {
    if (context.error) {
      const error = context.error;

      // Log the error
      console.error('Service Error:', {
        service: context.service.path,
        method: context.method,
        error: error.message,
        stack: error.stack,
        user: context.params.user?.id,
        data: context.data
      });

      // Handle specific error types
      if (error.name === 'ValidationError') {
        context.error = new BadRequest('Validation failed', {
          errors: Object.values(error.errors).map(e => ({
            field: e.path,
            message: e.message
          }))
        });
      } else if (error.name === 'CastError') {
        context.error = new BadRequest('Invalid ID format');
      } else if (error.code === 11000) {
        // MongoDB duplicate key error
        const field = Object.keys(error.keyPattern)[0];
        context.error = new BadRequest(`${field} already exists`);
      } else if (!error.code) {
        // Wrap unknown errors
        context.error = new GeneralError('An error occurred');
      }
    }

    return context;
  };
}

// Global error handler
function setupErrorHandling(app) {
  app.use((error, req, res, next) => {
    if (error.code === 404) {
      res.status(404).json({
        name: 'NotFound',
        message: 'Page not found',
        code: 404
      });
    } else {
      // Let Feathers handle other errors
      next(error);
    }
  });
}

// Custom error classes
class BusinessLogicError extends GeneralError {
  constructor(message, data) {
    super(message);
    this.name = 'BusinessLogicError';
    this.code = 422;
    this.data = data;
  }
}

class ExternalServiceError extends GeneralError {
  constructor(service, message) {
    super(`External service error: ${message}`);
    this.name = 'ExternalServiceError';
    this.code = 502;
    this.service = service;
  }
}

module.exports = {
  handleErrors,
  setupErrorHandling,
  BusinessLogicError,
  ExternalServiceError
};
```

## Security Best Practices

### Authentication Security

```javascript
// src/hooks/security.js
const crypto = require('crypto');
const { RateLimiterMemory } = require('rate-limiter-flexible');

// Rate limiting for authentication
const authLimiter = new RateLimiterMemory({
  points: 5, // Number of attempts
  duration: 900, // Per 15 minutes
  blockDuration: 900, // Block for 15 minutes
});

function rateLimitAuth() {
  return async context => {
    const { data, params } = context;
    const key = data.email || params.ip;

    try {
      await authLimiter.consume(key);
    } catch (rejRes) {
      const secs = Math.round(rejRes.msBeforeNext / 1000) || 1;
      throw new TooManyRequests(`Too many failed attempts. Try again in ${secs} seconds.`);
    }

    return context;
  };
}

// Password security
function validatePassword() {
  return async context => {
    const { data } = context;

    if (data.password) {
      // Check password strength
      const password = data.password;
      const minLength = 8;
      const hasUpperCase = /[A-Z]/.test(password);
      const hasLowerCase = /[a-z]/.test(password);
      const hasNumbers = /\d/.test(password);
      const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

      if (password.length < minLength) {
        throw new BadRequest('Password must be at least 8 characters long');
      }

      if (!hasUpperCase || !hasLowerCase || !hasNumbers || !hasSpecialChar) {
        throw new BadRequest('Password must contain uppercase, lowercase, number, and special character');
      }

      // Check against common passwords
      const commonPasswords = ['password', '123456', 'qwerty', 'admin'];
      if (commonPasswords.includes(password.toLowerCase())) {
        throw new BadRequest('Password is too common');
      }
    }

    return context;
  };
}

// CSRF protection
function csrfProtection() {
  return async context => {
    const { params } = context;

    if (params.provider === 'rest' &&
        ['create', 'update', 'patch', 'remove'].includes(context.method)) {

      const token = params.headers['x-csrf-token'];
      const sessionToken = params.session?.csrfToken;

      if (!token || !sessionToken || token !== sessionToken) {
        throw new BadRequest('Invalid CSRF token');
      }
    }

    return context;
  };
}

// Input sanitization
function sanitizeInput() {
  return async context => {
    const { data } = context;

    if (data && typeof data === 'object') {
      sanitizeObject(data);
    }

    return context;
  };
}

function sanitizeObject(obj) {
  Object.keys(obj).forEach(key => {
    if (typeof obj[key] === 'string') {
      // Remove potentially dangerous characters
      obj[key] = obj[key]
        .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
        .replace(/javascript:/gi, '')
        .replace(/on\w+="[^"]*"/g, '')
        .trim();
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      sanitizeObject(obj[key]);
    }
  });
}

// Encryption utilities
function encrypt(text, key) {
  const cipher = crypto.createCipher('aes-256-cbc', key);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}

function decrypt(encryptedText, key) {
  const decipher = crypto.createDecipher('aes-256-cbc', key);
  let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

// Secure session management
function setupSecureSessions(app) {
  const session = require('express-session');
  const MongoStore = require('connect-mongo');

  app.use(session({
    secret: app.get('sessionSecret'),
    resave: false,
    saveUninitialized: false,
    store: MongoStore.create({
      mongoUrl: app.get('mongodb'),
      ttl: 24 * 60 * 60 // 24 hours
    }),
    cookie: {
      secure: app.get('env') === 'production',
      httpOnly: true,
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    },
    name: 'sessionId'
  }));
}

module.exports = {
  rateLimitAuth,
  validatePassword,
  csrfProtection,
  sanitizeInput,
  encrypt,
  decrypt,
  setupSecureSessions
};
```

### Authorization Patterns

```javascript
// src/hooks/authorization.js
const { Forbidden, NotAuthenticated } = require('@feathersjs/errors');

// Role-based access control
function requireRole(...roles) {
  return async context => {
    const { params } = context;

    if (!params.user) {
      throw new NotAuthenticated('Authentication required');
    }

    if (roles.length > 0 && !roles.includes(params.user.role)) {
      throw new Forbidden(`Access denied. Required roles: ${roles.join(', ')}`);
    }

    return context;
  };
}

// Permission-based access control
function requirePermission(permission) {
  return async context => {
    const { params } = context;

    if (!params.user) {
      throw new NotAuthenticated('Authentication required');
    }

    const userPermissions = await getUserPermissions(context.app, params.user);

    if (!userPermissions.includes(permission)) {
      throw new Forbidden(`Access denied. Required permission: ${permission}`);
    }

    return context;
  };
}

// Resource ownership
function requireOwnership(userField = 'userId') {
  return async context => {
    const { params, id, method } = context;

    if (!params.user) {
      throw new NotAuthenticated('Authentication required');
    }

    // Skip ownership check for admins
    if (params.user.role === 'admin') {
      return context;
    }

    if (method === 'create') {
      // Set ownership on creation
      context.data[userField] = params.user.id;
    } else {
      // Check ownership for other operations
      const resource = await context.service.get(id, {
        ...params,
        provider: undefined // Bypass other hooks
      });

      if (resource[userField] !== params.user.id) {
        throw new Forbidden('You can only access your own resources');
      }
    }

    return context;
  };
}

// Dynamic authorization based on resource state
function requireResourceAccess() {
  return async context => {
    const { params, id, method } = context;

    if (!params.user) {
      throw new NotAuthenticated('Authentication required');
    }

    if (method !== 'create' && id) {
      const resource = await context.service.get(id, {
        ...params,
        provider: undefined
      });

      // Check if resource is public
      if (resource.isPublic) {
        return context;
      }

      // Check if user has direct access
      if (resource.userId === params.user.id) {
        return context;
      }

      // Check if user is in allowed users list
      if (resource.allowedUsers && resource.allowedUsers.includes(params.user.id)) {
        return context;
      }

      // Check if user's role has access
      if (resource.allowedRoles && resource.allowedRoles.includes(params.user.role)) {
        return context;
      }

      throw new Forbidden('Access denied to this resource');
    }

    return context;
  };
}

// Time-based access control
function requireTimeAccess(startTime, endTime) {
  return async context => {
    const now = new Date().getHours();

    if (now < startTime || now > endTime) {
      throw new Forbidden(`Access only allowed between ${startTime}:00 and ${endTime}:00`);
    }

    return context;
  };
}

// Rate limiting by user
function rateLimitByUser(options = {}) {
  const { maxRequests = 100, windowMs = 60000 } = options;
  const userRequests = new Map();

  return async context => {
    const { params } = context;
    const userId = params.user?.id || params.ip;
    const now = Date.now();

    if (!userRequests.has(userId)) {
      userRequests.set(userId, { count: 1, resetTime: now + windowMs });
    } else {
      const userLimit = userRequests.get(userId);

      if (now > userLimit.resetTime) {
        userLimit.count = 1;
        userLimit.resetTime = now + windowMs;
      } else {
        userLimit.count++;

        if (userLimit.count > maxRequests) {
          throw new TooManyRequests('Rate limit exceeded');
        }
      }
    }

    return context;
  };
}

async function getUserPermissions(app, user) {
  // Implement your permission logic here
  // This could involve checking a permissions table,
  // role-based permissions, or other authorization schemes

  const rolePermissions = {
    admin: ['*'], // All permissions
    moderator: ['read', 'update', 'moderate'],
    user: ['read', 'create', 'update_own']
  };

  return rolePermissions[user.role] || [];
}

module.exports = {
  requireRole,
  requirePermission,
  requireOwnership,
  requireResourceAccess,
  requireTimeAccess,
  rateLimitByUser
};
```

## Performance Optimization

### Database Optimization

```javascript
// src/hooks/optimize.js
const { cache } = require('../utils/cache');

// Query optimization
function optimizeQuery() {
  return async context => {
    const { params } = context;

    // Add default sorting for better performance
    if (!params.query.$sort) {
      params.query.$sort = { createdAt: -1 };
    }

    // Limit maximum page size
    if (params.query.$limit && params.query.$limit > 100) {
      params.query.$limit = 100;
    }

    // Add indexes hint for MongoDB
    if (params.query.userId) {
      params.mongooseOptions = {
        ...params.mongooseOptions,
        hint: { userId: 1, createdAt: -1 }
      };
    }

    return context;
  };
}

// Selective field loading
function selectFields(fields) {
  return async context => {
    const { params } = context;

    if (!params.query.$select) {
      params.query.$select = fields;
    }

    return context;
  };
}

// Population optimization
function optimizePopulate() {
  return async context => {
    const { params } = context;

    // Only populate necessary fields
    if (params.populateOptions) {
      params.populateOptions = params.populateOptions.map(option => ({
        ...option,
        select: option.select || 'id name email' // Default minimal fields
      }));
    }

    return context;
  };
}

// Caching hook
function cacheResponse(options = {}) {
  const { ttl = 300, keyGenerator } = options;

  return async context => {
    if (context.type === 'before' && context.method === 'find') {
      const cacheKey = keyGenerator ?
        keyGenerator(context) :
        generateCacheKey(context);

      const cached = await cache.get(cacheKey);
      if (cached) {
        context.result = cached;
        return context;
      }

      // Store the cache key for after hook
      context.cacheKey = cacheKey;
    }

    if (context.type === 'after' && context.cacheKey) {
      await cache.set(context.cacheKey, context.result, ttl);
    }

    return context;
  };
}

function generateCacheKey(context) {
  const { service, params } = context;
  const queryStr = JSON.stringify(params.query);
  const hash = require('crypto').createHash('md5').update(queryStr).digest('hex');
  return `${service.path}:${hash}`;
}

// Pagination optimization
function optimizePagination() {
  return async context => {
    const { params } = context;

    // Use cursor-based pagination for large datasets
    if (params.query.$skip && params.query.$skip > 1000) {
      // Convert to cursor-based pagination
      const lastId = params.query.lastId;
      if (lastId) {
        delete params.query.$skip;
        params.query.id = { $gt: lastId };
      }
    }

    return context;
  };
}

// Batch operations
function batchOperations() {
  return async context => {
    const { data, method } = context;

    if (method === 'create' && Array.isArray(data) && data.length > 10) {
      // Process in batches to avoid overwhelming the database
      const batchSize = 10;
      const results = [];

      for (let i = 0; i < data.length; i += batchSize) {
        const batch = data.slice(i, i + batchSize);
        const batchResults = await context.service.create(batch, {
          ...context.params,
          provider: undefined // Bypass hooks for internal calls
        });
        results.push(...batchResults);
      }

      context.result = results;
    }

    return context;
  };
}

module.exports = {
  optimizeQuery,
  selectFields,
  optimizePopulate,
  cacheResponse,
  optimizePagination,
  batchOperations
};

// src/utils/cache.js
const Redis = require('redis');

class CacheManager {
  constructor() {
    this.client = Redis.createClient({
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379
    });
  }

  async get(key) {
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error('Cache get error:', error);
      return null;
    }
  }

  async set(key, value, ttl = 300) {
    try {
      await this.client.setex(key, ttl, JSON.stringify(value));
    } catch (error) {
      console.error('Cache set error:', error);
    }
  }

  async del(pattern) {
    try {
      const keys = await this.client.keys(pattern);
      if (keys.length > 0) {
        await this.client.del(keys);
      }
    } catch (error) {
      console.error('Cache delete error:', error);
    }
  }

  async flush() {
    try {
      await this.client.flushall();
    } catch (error) {
      console.error('Cache flush error:', error);
    }
  }
}

module.exports = { cache: new CacheManager() };
```

### Real-time Optimization

```javascript
// src/channels/optimized.js
module.exports = function(app) {
  if (typeof app.channel !== 'function') {
    return;
  }

  // Connection management
  const connections = new Map();

  app.on('connection', connection => {
    connections.set(connection.id, {
      connection,
      user: null,
      channels: new Set(['anonymous']),
      lastActivity: Date.now()
    });

    app.channel('anonymous').join(connection);

    // Set up heartbeat
    const heartbeat = setInterval(() => {
      if (connection.readyState === 1) { // WebSocket.OPEN
        connection.ping();
      } else {
        clearInterval(heartbeat);
        connections.delete(connection.id);
      }
    }, 30000);

    connection.on('pong', () => {
      const connInfo = connections.get(connection.id);
      if (connInfo) {
        connInfo.lastActivity = Date.now();
      }
    });
  });

  app.on('login', (authResult, { connection }) => {
    const { user } = authResult;

    if (connection && connections.has(connection.id)) {
      const connInfo = connections.get(connection.id);
      connInfo.user = user;

      // Leave anonymous channel
      app.channel('anonymous').leave(connection);
      connInfo.channels.delete('anonymous');

      // Join user-specific channels
      const userChannel = `user:${user.id}`;
      app.channel(userChannel).join(connection);
      connInfo.channels.add(userChannel);

      const roleChannel = `role:${user.role}`;
      app.channel(roleChannel).join(connection);
      connInfo.channels.add(roleChannel);

      // Join organization channels
      if (user.organizationId) {
        const orgChannel = `org:${user.organizationId}`;
        app.channel(orgChannel).join(connection);
        connInfo.channels.add(orgChannel);
      }
    }
  });

  app.on('disconnect', connection => {
    connections.delete(connection.id);
  });

  // Optimized event publishing
  app.publish((data, hook) => {
    const { service, method, result } = hook;

    // Use specific channel targeting to reduce overhead
    switch (service) {
      case 'messages':
        return publishMessageEvents(data, hook, app);
      case 'notifications':
        return publishNotificationEvents(data, hook, app);
      case 'users':
        return publishUserEvents(data, hook, app);
      default:
        return []; // No real-time events by default
    }
  });

  // Clean up inactive connections
  setInterval(() => {
    const now = Date.now();
    const timeout = 5 * 60 * 1000; // 5 minutes

    for (const [id, connInfo] of connections) {
      if (now - connInfo.lastActivity > timeout) {
        connInfo.connection.terminate();
        connections.delete(id);
      }
    }
  }, 60000); // Check every minute
};

function publishMessageEvents(data, hook, app) {
  const { method, result } = hook;

  switch (method) {
    case 'created':
      // Only send to relevant users
      const recipients = result.recipients || [];
      const channels = recipients.map(id => app.channel(`user:${id}`));

      // Also send to the sender
      channels.push(app.channel(`user:${result.userId}`));

      return channels;

    case 'patched':
    case 'updated':
      // Only send to message participants
      return [
        app.channel(`user:${result.userId}`),
        ...result.recipients.map(id => app.channel(`user:${id}`))
      ];

    default:
      return [];
  }
}

function publishNotificationEvents(data, hook, app) {
  const { method, result } = hook;

  if (method === 'created') {
    // Send notification only to the target user
    return app.channel(`user:${result.userId}`);
  }

  return [];
}

function publishUserEvents(data, hook, app) {
  const { method, result } = hook;

  if (method === 'patched' || method === 'updated') {
    // Send user updates only to the user themselves
    return app.channel(`user:${result.id}`);
  }

  return [];
}
```

## Testing Strategies

### Unit Testing

```javascript
// test/services/messages.test.js
const assert = require('assert');
const app = require('../../src/app');

describe('\'messages\' service', () => {
  let user, authResult;

  beforeEach(async () => {
    // Create test user
    user = await app.service('users').create({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    });

    // Authenticate user
    authResult = await app.service('authentication').create({
      strategy: 'local',
      email: 'test@example.com',
      password: 'password123'
    });
  });

  afterEach(async () => {
    // Clean up test data
    await app.service('messages').remove(null);
    await app.service('users').remove(user.id);
  });

  it('registered the service', () => {
    const service = app.service('messages');
    assert.ok(service, 'Registered the service');
  });

  it('creates a message', async () => {
    const message = await app.service('messages').create({
      text: 'Test message',
      recipients: []
    }, {
      user,
      authenticated: true
    });

    assert.ok(message.id);
    assert.strictEqual(message.text, 'Test message');
    assert.strictEqual(message.userId, user.id);
    assert.ok(message.createdAt);
  });

  it('prevents creating empty messages', async () => {
    try {
      await app.service('messages').create({
        text: '',
        recipients: []
      }, {
        user,
        authenticated: true
      });
      assert.fail('Should have thrown an error');
    } catch (error) {
      assert.strictEqual(error.name, 'BadRequest');
    }
  });

  it('filters messages by user', async () => {
    // Create messages for different users
    const otherUser = await app.service('users').create({
      email: 'other@example.com',
      password: 'password123',
      name: 'Other User'
    });

    await app.service('messages').create({
      text: 'User message',
      recipients: []
    }, { user, authenticated: true });

    await app.service('messages').create({
      text: 'Other user message',
      recipients: []
    }, { user: otherUser, authenticated: true });

    const userMessages = await app.service('messages').find({
      user,
      authenticated: true
    });

    assert.strictEqual(userMessages.total, 1);
    assert.strictEqual(userMessages.data[0].text, 'User message');

    // Clean up
    await app.service('users').remove(otherUser.id);
  });

  it('marks message as read', async () => {
    const message = await app.service('messages').create({
      text: 'Test message',
      recipients: []
    }, { user, authenticated: true });

    const updatedMessage = await app.service('messages').markAsRead(message.id, {
      user,
      message
    });

    assert.ok(updatedMessage.readBy.includes(user.id));
    assert.ok(updatedMessage.readAt);
  });

  it('prevents unauthorized access', async () => {
    try {
      await app.service('messages').find();
      assert.fail('Should require authentication');
    } catch (error) {
      assert.strictEqual(error.name, 'NotAuthenticated');
    }
  });
});

// test/hooks/validate.test.js
const assert = require('assert');
const { validateUser } = require('../../src/hooks/validate');

describe('validate hooks', () => {
  let mockContext;

  beforeEach(() => {
    mockContext = {
      type: 'before',
      method: 'create',
      data: {},
      app: {
        service: jest.fn().mockReturnValue({
          find: jest.fn().mockResolvedValue({ total: 0 })
        })
      }
    };
  });

  it('validates required fields', async () => {
    try {
      await validateUser()(mockContext);
      assert.fail('Should have thrown validation error');
    } catch (error) {
      assert.strictEqual(error.name, 'BadRequest');
      assert.ok(error.message.includes('Email and password are required'));
    }
  });

  it('validates email format', async () => {
    mockContext.data = {
      email: 'invalid-email',
      password: 'password123'
    };

    try {
      await validateUser()(mockContext);
      assert.fail('Should have thrown validation error');
    } catch (error) {
      assert.strictEqual(error.name, 'BadRequest');
      assert.ok(error.message.includes('Invalid email format'));
    }
  });

  it('validates password strength', async () => {
    mockContext.data = {
      email: 'test@example.com',
      password: '123'
    };

    try {
      await validateUser()(mockContext);
      assert.fail('Should have thrown validation error');
    } catch (error) {
      assert.strictEqual(error.name, 'BadRequest');
      assert.ok(error.message.includes('Password must be at least 8 characters'));
    }
  });

  it('checks for duplicate emails', async () => {
    mockContext.data = {
      email: 'test@example.com',
      password: 'password123'
    };

    // Mock existing user
    mockContext.app.service().find.mockResolvedValue({ total: 1 });

    try {
      await validateUser()(mockContext);
      assert.fail('Should have thrown validation error');
    } catch (error) {
      assert.strictEqual(error.name, 'BadRequest');
      assert.ok(error.message.includes('Email already exists'));
    }
  });

  it('passes validation with valid data', async () => {
    mockContext.data = {
      email: 'test@example.com',
      password: 'password123'
    };

    const result = await validateUser()(mockContext);
    assert.strictEqual(result, mockContext);
  });
});
```

### Integration Testing

```javascript
// test/integration/authentication.test.js
const assert = require('assert');
const request = require('supertest');
const app = require('../../src/app');

describe('Authentication Integration', () => {
  let server;

  before(async () => {
    server = app.listen(0);
  });

  after(async () => {
    await server.close();
  });

  describe('POST /authentication', () => {
    let testUser;

    beforeEach(async () => {
      testUser = await app.service('users').create({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User'
      });
    });

    afterEach(async () => {
      await app.service('users').remove(testUser.id);
    });

    it('authenticates with valid credentials', async () => {
      const response = await request(server)
        .post('/authentication')
        .send({
          strategy: 'local',
          email: 'test@example.com',
          password: 'password123'
        })
        .expect(201);

      assert.ok(response.body.accessToken);
      assert.ok(response.body.user);
      assert.strictEqual(response.body.user.email, 'test@example.com');
    });

    it('rejects invalid credentials', async () => {
      await request(server)
        .post('/authentication')
        .send({
          strategy: 'local',
          email: 'test@example.com',
          password: 'wrong-password'
        })
        .expect(401);
    });

    it('requires email and password', async () => {
      await request(server)
        .post('/authentication')
        .send({
          strategy: 'local'
        })
        .expect(400);
    });
  });

  describe('Protected Routes', () => {
    let authToken;

    beforeEach(async () => {
      const user = await app.service('users').create({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User'
      });

      const authResult = await app.service('authentication').create({
        strategy: 'local',
        email: 'test@example.com',
        password: 'password123'
      });

      authToken = authResult.accessToken;
    });

    afterEach(async () => {
      await app.service('users').remove(null);
    });

    it('allows access with valid token', async () => {
      await request(server)
        .get('/messages')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
    });

    it('denies access without token', async () => {
      await request(server)
        .get('/messages')
        .expect(401);
    });

    it('denies access with invalid token', async () => {
      await request(server)
        .get('/messages')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});

// test/integration/messages.test.js
describe('Messages API Integration', () => {
  let server, authToken, testUser;

  before(async () => {
    server = app.listen(0);
  });

  after(async () => {
    await server.close();
  });

  beforeEach(async () => {
    testUser = await app.service('users').create({
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    });

    const authResult = await app.service('authentication').create({
      strategy: 'local',
      email: 'test@example.com',
      password: 'password123'
    });

    authToken = authResult.accessToken;
  });

  afterEach(async () => {
    await app.service('messages').remove(null);
    await app.service('users').remove(null);
  });

  it('creates a message', async () => {
    const response = await request(server)
      .post('/messages')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        text: 'Test message',
        recipients: []
      })
      .expect(201);

    assert.ok(response.body.id);
    assert.strictEqual(response.body.text, 'Test message');
    assert.strictEqual(response.body.userId, testUser.id);
  });

  it('lists user messages', async () => {
    // Create test messages
    await app.service('messages').create({
      text: 'Message 1',
      recipients: []
    }, { user: testUser });

    await app.service('messages').create({
      text: 'Message 2',
      recipients: []
    }, { user: testUser });

    const response = await request(server)
      .get('/messages')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    assert.strictEqual(response.body.total, 2);
    assert.strictEqual(response.body.data.length, 2);
  });

  it('updates message', async () => {
    const message = await app.service('messages').create({
      text: 'Original message',
      recipients: []
    }, { user: testUser });

    const response = await request(server)
      .patch(`/messages/${message.id}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        text: 'Updated message'
      })
      .expect(200);

    assert.strictEqual(response.body.text, 'Updated message');
  });

  it('prevents unauthorized updates', async () => {
    const otherUser = await app.service('users').create({
      email: 'other@example.com',
      password: 'password123',
      name: 'Other User'
    });

    const message = await app.service('messages').create({
      text: 'Other user message',
      recipients: []
    }, { user: otherUser });

    await request(server)
      .patch(`/messages/${message.id}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        text: 'Hacked message'
      })
      .expect(403);
  });
});
```

### End-to-End Testing

```javascript
// test/e2e/real-time.test.js
const assert = require('assert');
const io = require('socket.io-client');
const app = require('../../src/app');

describe('Real-time Communication E2E', () => {
  let server, client1, client2, authToken1, authToken2;

  before(async () => {
    server = app.listen(0);
    const port = server.address().port;

    // Create test users
    const user1 = await app.service('users').create({
      email: 'user1@example.com',
      password: 'password123',
      name: 'User 1'
    });

    const user2 = await app.service('users').create({
      email: 'user2@example.com',
      password: 'password123',
      name: 'User 2'
    });

    // Get authentication tokens
    const auth1 = await app.service('authentication').create({
      strategy: 'local',
      email: 'user1@example.com',
      password: 'password123'
    });

    const auth2 = await app.service('authentication').create({
      strategy: 'local',
      email: 'user2@example.com',
      password: 'password123'
    });

    authToken1 = auth1.accessToken;
    authToken2 = auth2.accessToken;

    // Create socket connections
    client1 = io(`http://localhost:${port}`, {
      extraHeaders: {
        Authorization: `Bearer ${authToken1}`
      }
    });

    client2 = io(`http://localhost:${port}`, {
      extraHeaders: {
        Authorization: `Bearer ${authToken2}`
      }
    });
  });

  after(async () => {
    client1?.disconnect();
    client2?.disconnect();
    await server.close();
    await app.service('users').remove(null);
    await app.service('messages').remove(null);
  });

  it('sends real-time message between users', (done) => {
    let messagesReceived = 0;

    // User 2 listens for new messages
    client2.on('messages created', (message) => {
      assert.strictEqual(message.text, 'Hello from User 1');
      messagesReceived++;

      if (messagesReceived === 1) {
        done();
      }
    });

    // Wait for connections to be established
    setTimeout(() => {
      // User 1 creates a message
      client1.emit('create', 'messages', {
        text: 'Hello from User 1',
        recipients: []
      });
    }, 100);
  });

  it('handles private messages', (done) => {
    let privateMessageReceived = false;

    client2.on('messages created', (message) => {
      if (message.text === 'Private message') {
        privateMessageReceived = true;
        assert.ok(message.recipients.includes(client2.userId));
        done();
      }
    });

    setTimeout(() => {
      client1.emit('create', 'messages', {
        text: 'Private message',
        recipients: [client2.userId]
      });
    }, 100);
  });

  it('handles user authentication events', (done) => {
    const client3 = io(`http://localhost:${server.address().port}`);

    client3.on('connect', () => {
      client3.emit('create', 'authentication', {
        strategy: 'local',
        email: 'user1@example.com',
        password: 'password123'
      }, (error, result) => {
        if (error) return done(error);

        assert.ok(result.accessToken);
        client3.disconnect();
        done();
      });
    });
  });

  it('maintains connection state', (done) => {
    let heartbeats = 0;

    client1.on('ping', () => {
      heartbeats++;

      if (heartbeats >= 2) {
        assert.ok(client1.connected);
        done();
      }
    });

    // Trigger heartbeat
    client1.emit('ping');

    setTimeout(() => {
      client1.emit('ping');
    }, 100);
  });
});

// test/e2e/user-workflow.test.js
describe('Complete User Workflow E2E', () => {
  let server;

  before(async () => {
    server = app.listen(0);
  });

  after(async () => {
    await server.close();
    await app.service('users').remove(null);
    await app.service('messages').remove(null);
  });

  it('completes user registration and messaging flow', async () => {
    const client = io(`http://localhost:${server.address().port}`);

    // Step 1: Register user
    const user = await new Promise((resolve, reject) => {
      client.emit('create', 'users', {
        email: 'workflow@example.com',
        password: 'password123',
        name: 'Workflow User'
      }, (error, result) => {
        if (error) reject(error);
        else resolve(result);
      });
    });

    assert.ok(user.id);
    assert.strictEqual(user.email, 'workflow@example.com');

    // Step 2: Authenticate
    const authResult = await new Promise((resolve, reject) => {
      client.emit('create', 'authentication', {
        strategy: 'local',
        email: 'workflow@example.com',
        password: 'password123'
      }, (error, result) => {
        if (error) reject(error);
        else resolve(result);
      });
    });

    assert.ok(authResult.accessToken);

    // Step 3: Create message
    const message = await new Promise((resolve, reject) => {
      client.emit('create', 'messages', {
        text: 'My first message',
        recipients: []
      }, (error, result) => {
        if (error) reject(error);
        else resolve(result);
      });
    });

    assert.ok(message.id);
    assert.strictEqual(message.text, 'My first message');
    assert.strictEqual(message.userId, user.id);

    // Step 4: List messages
    const messages = await new Promise((resolve, reject) => {
      client.emit('find', 'messages', {}, (error, result) => {
        if (error) reject(error);
        else resolve(result);
      });
    });

    assert.strictEqual(messages.total, 1);
    assert.strictEqual(messages.data[0].id, message.id);

    // Step 5: Update message
    const updatedMessage = await new Promise((resolve, reject) => {
      client.emit('patch', 'messages', message.id, {
        text: 'Updated message'
      }, (error, result) => {
        if (error) reject(error);
        else resolve(result);
      });
    });

    assert.strictEqual(updatedMessage.text, 'Updated message');

    client.disconnect();
  });
});
```

## Deployment Guide

### Production Configuration

```javascript
// config/production.json
{
  "host": "0.0.0.0",
  "port": "PORT",
  "public": "../public/",
  "mongodb": "MONGODB_CONNECTION_STRING",
  "redis": {
    "host": "REDIS_HOST",
    "port": "REDIS_PORT",
    "password": "REDIS_PASSWORD"
  },
  "authentication": {
    "secret": "JWT_SECRET",
    "jwtOptions": {
      "expiresIn": "24h"
    }
  },
  "paginate": {
    "default": 10,
    "max": 50
  }
}

// src/app.js - Production optimizations
if (app.get('env') === 'production') {
  // Enable trust proxy for correct IP addresses
  app.set('trust proxy', 1);

  // Add security headers
  app.use(express.helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "https:"]
      }
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true
    }
  }));

  // Enable compression
  app.use(express.compress());

  // Rate limiting
  const rateLimit = require('express-rate-limit');
  app.use('/authentication', rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5 // limit each IP to 5 requests per windowMs
  }));
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Build stage
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build 2>/dev/null || echo "No build script found"

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 feathers
RUN adduser --system --uid 1001 feathers

COPY --from=deps --chown=feathers:feathers /app/node_modules ./node_modules
COPY --from=builder --chown=feathers:feathers /app/lib ./lib
COPY --from=builder --chown=feathers:feathers /app/public ./public
COPY --from=builder --chown=feathers:feathers /app/config ./config
COPY --from=builder --chown=feathers:feathers /app/package.json ./package.json

USER feathers

EXPOSE 3030

CMD ["node", "lib/index.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3030:3030"
    environment:
      - NODE_ENV=production
      - MONGODB_CONNECTION_STRING=mongodb://mongo:27017/feathers
      - REDIS_HOST=redis
      - JWT_SECRET=your-secure-jwt-secret
    depends_on:
      - mongo
      - redis
    restart: unless-stopped

  mongo:
    image: mongo:5.0
    volumes:
      - mongo_data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=root
      - MONGO_INITDB_ROOT_PASSWORD=password
      - MONGO_INITDB_DATABASE=feathers
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
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
  mongo_data:
  redis_data:
```

### Nginx Configuration

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream feathers_app {
        server app:3030;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

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
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;

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
        location /public/ {
            alias /app/public/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # WebSocket support
        location /socket.io/ {
            proxy_pass http://feathers_app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Authentication rate limiting
        location /authentication {
            limit_req zone=auth burst=10 nodelay;
            proxy_pass http://feathers_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # API rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://feathers_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Default proxy
        location / {
            proxy_pass http://feathers_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
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
      mongodb:
        image: mongo:5.0
        ports:
          - 27017:27017

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test
        env:
          NODE_ENV: test
          MONGODB_CONNECTION_STRING: mongodb://localhost:27017/feathers_test

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
        run: npm run compile

      - name: Build Docker image
        run: |
          docker build -t feathers-app:${{ github.sha }} .
          docker tag feathers-app:${{ github.sha }} feathers-app:latest

      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push feathers-app:${{ github.sha }}
          docker push feathers-app:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest

    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.KEY }}
          script: |
            cd /app
            docker-compose pull
            docker-compose up -d
            docker system prune -f
```

## Common Pitfalls

### Service Design Anti-patterns

```javascript
// BAD: Mixing business logic in hooks
app.service('orders').hooks({
  before: {
    create: [
      async context => {
        // Too much business logic in hook
        const { data } = context;

        // Calculate totals
        let total = 0;
        for (const item of data.items) {
          const product = await context.app.service('products').get(item.productId);
          total += product.price * item.quantity;
        }
        data.total = total;

        // Check inventory
        for (const item of data.items) {
          const product = await context.app.service('products').get(item.productId);
          if (product.stock < item.quantity) {
            throw new BadRequest(`Insufficient stock for ${product.name}`);
          }
        }

        // Update inventory
        for (const item of data.items) {
          await context.app.service('products').patch(item.productId, {
            stock: product.stock - item.quantity
          });
        }

        return context;
      }
    ]
  }
});

// GOOD: Business logic in service class
class OrderService extends Service {
  async create(data, params) {
    const orderData = await this.processOrder(data);
    return super.create(orderData, params);
  }

  async processOrder(data) {
    const orderItems = await this.validateAndPriceItems(data.items);
    const total = this.calculateTotal(orderItems);

    await this.checkInventory(orderItems);
    await this.reserveInventory(orderItems);

    return {
      ...data,
      items: orderItems,
      total,
      status: 'pending'
    };
  }

  async validateAndPriceItems(items) {
    const processedItems = [];

    for (const item of items) {
      const product = await this.app.service('products').get(item.productId);
      processedItems.push({
        ...item,
        price: product.price,
        name: product.name
      });
    }

    return processedItems;
  }

  calculateTotal(items) {
    return items.reduce((total, item) => total + (item.price * item.quantity), 0);
  }

  async checkInventory(items) {
    for (const item of items) {
      const product = await this.app.service('products').get(item.productId);
      if (product.stock < item.quantity) {
        throw new BadRequest(`Insufficient stock for ${product.name}`);
      }
    }
  }

  async reserveInventory(items) {
    for (const item of items) {
      await this.app.service('products').patch(item.productId, {
        $inc: { stock: -item.quantity }
      });
    }
  }
}
```

### Authentication Issues

```javascript
// BAD: Inconsistent authentication handling
app.service('messages').hooks({
  before: {
    all: [authenticate('jwt')],
    find: [], // Missing user filtering
    create: [
      context => {
        // Manual user assignment
        context.data.userId = context.params.user.id;
        return context;
      }
    ]
  }
});

// GOOD: Consistent authentication and authorization
app.service('messages').hooks({
  before: {
    all: [authenticate('jwt')],
    find: [addUserFilter()],
    get: [checkOwnership()],
    create: [setOwnership()],
    update: [checkOwnership()],
    patch: [checkOwnership()],
    remove: [checkOwnership()]
  }
});

function addUserFilter() {
  return context => {
    if (context.params.user && context.params.user.role !== 'admin') {
      context.params.query = {
        ...context.params.query,
        $or: [
          { userId: context.params.user.id },
          { sharedWith: context.params.user.id }
        ]
      };
    }
    return context;
  };
}

function setOwnership() {
  return context => {
    context.data.userId = context.params.user.id;
    return context;
  };
}

function checkOwnership() {
  return async context => {
    if (context.params.user.role === 'admin') {
      return context;
    }

    const resource = await context.service.get(context.id, {
      ...context.params,
      provider: undefined
    });

    if (resource.userId !== context.params.user.id) {
      throw new Forbidden('Access denied');
    }

    return context;
  };
}
```

### Real-time Event Issues

```javascript
// BAD: Broadcasting to all clients
app.publish(() => {
  return app.channel('authenticated'); // Sends everything to everyone
});

// GOOD: Targeted event publishing
app.publish((data, hook) => {
  const { service, method, result } = hook;

  // Only send relevant events to relevant users
  switch (service) {
    case 'messages':
      if (method === 'created') {
        const channels = [];

        // Send to sender
        channels.push(app.channel(`user:${result.userId}`));

        // Send to recipients
        if (result.recipients) {
          result.recipients.forEach(userId => {
            channels.push(app.channel(`user:${userId}`));
          });
        }

        return channels;
      }
      break;

    case 'notifications':
      if (method === 'created') {
        // Send only to the target user
        return app.channel(`user:${result.userId}`);
      }
      break;

    default:
      return []; // No real-time events by default
  }

  return [];
});
```

## Troubleshooting

### Common Issues and Solutions

```javascript
// Database connection issues
// src/utils/debug.js
async function checkDatabaseConnection(app) {
  try {
    const mongooseClient = app.get('mongooseClient');
    await mongooseClient.connection.db.admin().ping();
    console.log('✅ Database connection successful');
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

// WebSocket connection debugging
function debugWebSocket(app) {
  app.on('connection', connection => {
    console.log('WebSocket connected:', {
      id: connection.id,
      address: connection.handshake.address,
      headers: connection.handshake.headers
    });
  });

  app.on('disconnect', connection => {
    console.log('WebSocket disconnected:', connection.id);
  });

  app.on('login', (authResult, { connection }) => {
    console.log('User authenticated via WebSocket:', {
      userId: authResult.user.id,
      connectionId: connection.id
    });
  });
}

// Service debugging
function debugService(serviceName) {
  return async context => {
    console.log(`${serviceName} ${context.method}:`, {
      id: context.id,
      data: context.data,
      query: context.params.query,
      user: context.params.user?.id
    });

    return context;
  };
}

// Error logging
function logErrors() {
  return async context => {
    if (context.error) {
      console.error('Service Error:', {
        service: context.service.path,
        method: context.method,
        error: context.error.message,
        stack: context.error.stack,
        user: context.params.user?.id,
        data: context.data
      });
    }

    return context;
  };
}

// Performance monitoring
function monitorPerformance() {
  return async context => {
    const start = Date.now();

    context.performanceStart = start;

    return context;
  };
}

function logPerformance() {
  return async context => {
    if (context.performanceStart) {
      const duration = Date.now() - context.performanceStart;

      if (duration > 1000) { // Log slow operations
        console.warn('Slow Operation:', {
          service: context.service.path,
          method: context.method,
          duration: `${duration}ms`,
          user: context.params.user?.id
        });
      }
    }

    return context;
  };
}

// Health check endpoint
function setupHealthCheck(app) {
  app.use('/health', async (req, res) => {
    try {
      // Check database
      const mongooseClient = app.get('mongooseClient');
      await mongooseClient.connection.db.admin().ping();

      // Check services
      const services = Object.keys(app.services);

      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        database: 'connected',
        services: services.length,
        uptime: process.uptime()
      });
    } catch (error) {
      res.status(500).json({
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  });
}

module.exports = {
  checkDatabaseConnection,
  debugWebSocket,
  debugService,
  logErrors,
  monitorPerformance,
  logPerformance,
  setupHealthCheck
};
```

## Best Practices Summary

### Development Guidelines

1. **Service Design**
   - Keep services focused on a single resource
   - Use service classes for business logic
   - Implement proper error handling
   - Use hooks for cross-cutting concerns

2. **Authentication & Authorization**
   - Use JWT tokens for stateless authentication
   - Implement role-based access control
   - Validate all inputs and sanitize data
   - Use HTTPS in production

3. **Real-time Features**
   - Design efficient channel strategies
   - Implement targeted event publishing
   - Handle connection cleanup properly
   - Monitor WebSocket performance

4. **Database Optimization**
   - Use proper indexing strategies
   - Implement query optimization
   - Use caching for frequently accessed data
   - Monitor database performance

5. **Testing**
   - Write comprehensive unit tests
   - Implement integration testing
   - Test real-time functionality
   - Use proper test data management

## Conclusion

FeathersJS provides a powerful platform for building real-time applications with a service-oriented architecture. Its strength lies in its real-time capabilities, flexible design patterns, and comprehensive feature set that includes authentication, database integration, and WebSocket support out of the box.

The framework's service-oriented approach promotes clean, maintainable code while its hook system provides powerful middleware capabilities. The built-in real-time features make it particularly suitable for applications requiring instant data synchronization across multiple clients.

However, FeathersJS requires understanding of its architectural patterns and may not be suitable for simple applications that don't need real-time features. The framework works best when its conventions are embraced rather than fought against.

Success with FeathersJS comes from properly designing services, implementing effective authentication and authorization strategies, and leveraging its real-time capabilities appropriately. The framework's plugin ecosystem and TypeScript support make it a solid choice for modern web application development.

## Resources

### Official Documentation
- [FeathersJS Official Website](https://feathersjs.com/)
- [FeathersJS Documentation](https://docs.feathersjs.com/)
- [FeathersJS GitHub Repository](https://github.com/feathersjs/feathers)
- [FeathersJS CLI](https://github.com/feathersjs/cli)

### Learning Resources
- [FeathersJS Guide](https://docs.feathersjs.com/guides/)
- [FeathersJS Tutorial](https://docs.feathersjs.com/tutorial/)
- [FeathersJS Blog](https://blog.feathersjs.com/)
- [FeathersJS Examples](https://github.com/feathersjs/feathers/tree/dove/examples)

### Tools and Plugins
- [Feathers Authentication](https://github.com/feathersjs/authentication)
- [Feathers Mongoose](https://github.com/feathersjs-ecosystem/feathers-mongoose)
- [Feathers Sequelize](https://github.com/feathersjs-ecosystem/feathers-sequelize)
- [Feathers Swagger](https://github.com/feathersjs-ecosystem/feathers-swagger)

### Community
- [FeathersJS Slack](https://slack.feathersjs.com/)
- [FeathersJS Discord](https://discord.gg/qa8kez8QBx)
- [FeathersJS Stack Overflow](https://stackoverflow.com/questions/tagged/feathersjs)
- [FeathersJS Reddit](https://www.reddit.com/r/feathersjs/)

### Testing Tools
- [Jest](https://jestjs.io/)
- [Mocha](https://mochajs.org/)
- [Supertest](https://github.com/visionmedia/supertest)
- [Socket.IO Client](https://socket.io/docs/v4/client-api/)

### Deployment and Monitoring
- [PM2](https://pm2.keymetrics.io/)
- [Docker](https://www.docker.com/)
- [Nginx](https://nginx.org/)
- [New Relic](https://newrelic.com/)
- [Sentry](https://sentry.io/)