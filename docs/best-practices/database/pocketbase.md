# PocketBase Best Practices

## Official Documentation
- **PocketBase Documentation**: https://pocketbase.io/docs/
- **PocketBase GitHub**: https://github.com/pocketbase/pocketbase
- **JavaScript SDK**: https://github.com/pocketbase/js-sdk
- **Dart SDK**: https://github.com/pocketbase/dart-sdk

## Overview
PocketBase is an open-source backend consisting of embedded SQLite database with realtime subscriptions, built-in auth management, convenient dashboard UI, and simple REST-ish API.

## Core Best Practices

### 1. Installation and Setup

#### Self-Hosted Deployment
```bash
# Download latest release
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip
unzip pocketbase_0.20.0_linux_amd64.zip

# Run PocketBase
./pocketbase serve --http="0.0.0.0:8090"

# With custom data directory
./pocketbase serve --dir="./pb_data" --http="0.0.0.0:8090"
```

#### Docker Deployment
```dockerfile
FROM alpine:latest

RUN apk add --no-cache ca-certificates

ADD https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb && rm /tmp/pb.zip

EXPOSE 8090

CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8090"]
```

#### Programmatic Usage (Go)
```go
package main

import (
    "log"
    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
)

func main() {
    app := pocketbase.New()

    // Custom routes
    app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
        e.Router.GET("/custom/hello", func(c echo.Context) error {
            return c.String(200, "Hello World!")
        })
        return nil
    })

    // Event hooks
    app.OnRecordAfterCreateRequest().Add(func(e *core.RecordCreateEvent) error {
        log.Println("Record created:", e.Record.Id)
        return nil
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

### 2. JavaScript SDK Setup

#### Installation and Configuration
```javascript
// npm install pocketbase
import PocketBase from 'pocketbase';

// Initialize client
const pb = new PocketBase('http://localhost:8090');

// Auto-cancel pending requests on page navigation
pb.autoCancellation(false);

// Custom fetch implementation
const pb = new PocketBase('http://localhost:8090', {
    // Custom fetch for Node.js
    fetch: (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args)),
});

// TypeScript types generation
// npx pocketbase-typegen --db ./pb_data/data.db --out ./src/types/pocketbase.ts
```

### 3. Authentication

#### Email/Password Authentication
```javascript
// Register new user
const userData = {
    email: 'user@example.com',
    password: 'securePassword123',
    passwordConfirm: 'securePassword123',
    name: 'John Doe',
    // Custom fields
    avatar: null,
    preferences: { theme: 'dark' }
};

const record = await pb.collection('users').create(userData);

// Send verification email
await pb.collection('users').requestVerification('user@example.com');

// Login
const authData = await pb.collection('users').authWithPassword(
    'user@example.com',
    'securePassword123'
);

// The auth token is automatically saved
console.log(pb.authStore.isValid);
console.log(pb.authStore.token);
console.log(pb.authStore.model);

// Refresh auth
const refreshed = await pb.collection('users').authRefresh();

// Logout
pb.authStore.clear();
```

#### OAuth2 Authentication
```javascript
// List OAuth2 providers
const authMethods = await pb.collection('users').listAuthMethods();
console.log(authMethods.authProviders);

// Authenticate with OAuth2
const authData = await pb.collection('users').authWithOAuth2({
    provider: 'google',
    code: 'CODE_FROM_OAUTH_REDIRECT',
    codeVerifier: 'PKCE_CODE_VERIFIER',
    redirectUrl: 'http://localhost:3000/redirect',
});

// Or use the built-in popup flow
const authData = await pb.collection('users').authWithOAuth2({
    provider: 'github'
});
```

#### Admin Authentication
```javascript
// Admin login
const admin = await pb.admins.authWithPassword('admin@example.com', 'adminPassword');

// Admin operations
const collections = await pb.collections.getList();
const logs = await pb.logs.getList();
```

### 4. CRUD Operations

#### Basic CRUD
```javascript
// Create
const record = await pb.collection('posts').create({
    title: 'My First Post',
    content: 'This is the content',
    author: pb.authStore.model.id,
    published: true,
    tags: ['javascript', 'pocketbase']
});

// Read single record
const post = await pb.collection('posts').getOne('RECORD_ID');

// Read with expand (join related records)
const postWithAuthor = await pb.collection('posts').getOne('RECORD_ID', {
    expand: 'author,comments.user'
});

// Update
const updated = await pb.collection('posts').update('RECORD_ID', {
    title: 'Updated Title',
    content: 'Updated content'
});

// Delete
await pb.collection('posts').delete('RECORD_ID');
```

#### List and Filter
```javascript
// List with pagination
const resultList = await pb.collection('posts').getList(1, 20, {
    filter: 'published = true',
    sort: '-created',
    expand: 'author'
});

console.log(resultList.items);
console.log(resultList.totalItems);
console.log(resultList.totalPages);

// Complex filtering
const posts = await pb.collection('posts').getList(1, 50, {
    filter: 'author.name ~ "John" && created >= "2024-01-01" && (tags ~ "javascript" || tags ~ "typescript")',
    sort: '+title,-created',
});

// Full list (be careful with large datasets)
const records = await pb.collection('posts').getFullList({
    sort: '-created',
    batch: 200
});
```

### 5. File Upload
```javascript
// Single file upload
const formData = new FormData();
formData.append('title', 'Post with image');
formData.append('thumbnail', fileInput.files[0]);

const record = await pb.collection('posts').create(formData);

// Multiple files
const formData = new FormData();
formData.append('name', 'Gallery');
formData.append('images', file1);
formData.append('images', file2);
formData.append('images', file3);

const gallery = await pb.collection('galleries').create(formData);

// Get file URL
const post = await pb.collection('posts').getOne('RECORD_ID');
const thumbnailUrl = pb.files.getUrl(post, post.thumbnail);

// With thumb transformation
const thumbUrl = pb.files.getUrl(post, post.thumbnail, {
    thumb: '100x100'
});

// Delete file from record
await pb.collection('posts').update('RECORD_ID', {
    'thumbnail-': null  // Note the minus suffix
});
```

### 6. Realtime Subscriptions
```javascript
// Subscribe to changes in a collection
const unsubscribe = await pb.collection('messages').subscribe('*', (e) => {
    console.log(e.action); // create, update, delete
    console.log(e.record);
    
    switch(e.action) {
        case 'create':
            handleNewMessage(e.record);
            break;
        case 'update':
            updateMessage(e.record);
            break;
        case 'delete':
            removeMessage(e.record);
            break;
    }
});

// Subscribe to specific record
await pb.collection('posts').subscribe('RECORD_ID', (e) => {
    console.log('Post updated:', e.record);
});

// Subscribe with filter
await pb.collection('comments').subscribe('*', (e) => {
    console.log('New comment on post:', e.record);
}, {
    filter: `post = "POST_ID"`
});

// Unsubscribe
unsubscribe();

// Unsubscribe from all
pb.collection('messages').unsubscribe();
```

### 7. Collection Rules and Schemas

#### API Rules (via Admin UI or migrations)
```javascript
// Example collection schema with rules
{
    "name": "posts",
    "type": "base",
    "schema": [
        {
            "name": "title",
            "type": "text",
            "required": true,
            "options": {
                "min": 3,
                "max": 255
            }
        },
        {
            "name": "content",
            "type": "editor",
            "required": true
        },
        {
            "name": "author",
            "type": "relation",
            "required": true,
            "options": {
                "collectionId": "users",
                "cascadeDelete": false
            }
        },
        {
            "name": "tags",
            "type": "select",
            "options": {
                "maxSelect": 5,
                "values": ["javascript", "typescript", "go", "python"]
            }
        },
        {
            "name": "published",
            "type": "bool",
            "options": {
                "default": false
            }
        }
    ],
    "listRule": "published = true || author = @request.auth.id",
    "viewRule": "published = true || author = @request.auth.id",
    "createRule": "@request.auth.id != ''",
    "updateRule": "author = @request.auth.id",
    "deleteRule": "author = @request.auth.id"
}
```

### 8. Migrations
```go
// migrations/1234567890_create_posts.go
package migrations

import (
    "github.com/pocketbase/dbx"
    "github.com/pocketbase/pocketbase/daos"
    m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
    m.Register(func(db dbx.Builder) error {
        // Create custom table
        _, err := db.NewQuery(`
            CREATE TABLE custom_stats (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                views INTEGER DEFAULT 0,
                likes INTEGER DEFAULT 0,
                created DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `).Execute()
        
        return err
    }, func(db dbx.Builder) error {
        // Rollback
        _, err := db.NewQuery("DROP TABLE custom_stats").Execute()
        return err
    })
}
```

### 9. Custom Endpoints and Hooks
```go
// main.go
package main

import (
    "net/http"
    "github.com/labstack/echo/v5"
    "github.com/pocketbase/pocketbase"
    "github.com/pocketbase/pocketbase/apis"
    "github.com/pocketbase/pocketbase/core"
    "github.com/pocketbase/pocketbase/forms"
    "github.com/pocketbase/pocketbase/models"
)

func main() {
    app := pocketbase.New()

    // Custom API endpoint
    app.OnBeforeServe().Add(func(e *core.ServeEvent) error {
        e.Router.GET("/api/stats/:userId", func(c echo.Context) error {
            userId := c.PathParam("userId")
            
            // Check authentication
            info := apis.RequestInfo(c)
            if info.AuthRecord == nil {
                return apis.NewForbiddenError("Authentication required", nil)
            }
            
            // Fetch stats
            var result struct {
                TotalPosts int `db:"total_posts" json:"totalPosts"`
                TotalViews int `db:"total_views" json:"totalViews"`
            }
            
            app.Dao().DB().
                NewQuery(`
                    SELECT 
                        COUNT(id) as total_posts,
                        SUM(views) as total_views
                    FROM posts
                    WHERE author = {:userId}
                `).
                Bind(dbx.Params{"userId": userId}).
                One(&result)
            
            return c.JSON(http.StatusOK, result)
        })
        
        return nil
    })

    // Record hooks
    app.OnRecordBeforeCreateRequest("posts").Add(func(e *core.RecordCreateEvent) error {
        // Set author to current user
        e.Record.Set("author", e.HttpContext.Get("authRecord").(*models.Record).Id)
        return nil
    })

    app.OnRecordAfterCreateRequest("posts").Add(func(e *core.RecordCreateEvent) error {
        // Send notification
        go sendNotification(e.Record)
        return nil
    })

    // Validation hook
    app.OnRecordBeforeUpdateRequest("users").Add(func(e *core.RecordUpdateEvent) error {
        // Custom validation
        if e.Record.GetString("username") == "admin" {
            return apis.NewBadRequestError("Username 'admin' is reserved", nil)
        }
        return nil
    })

    if err := app.Start(); err != nil {
        log.Fatal(err)
    }
}
```

## Advanced Patterns

### 1. Batch Operations
```javascript
// Batch create with transaction
async function batchCreate(items) {
    const promises = items.map(item => 
        pb.collection('items').create(item)
    );
    
    try {
        const results = await Promise.all(promises);
        return results;
    } catch (error) {
        console.error('Batch create failed:', error);
        // Implement rollback logic if needed
        throw error;
    }
}

// Batch update
async function batchUpdate(updates) {
    const promises = updates.map(({id, data}) =>
        pb.collection('items').update(id, data)
    );
    
    return await Promise.allSettled(promises);
}
```

### 2. Caching Strategy
```javascript
class PocketBaseCache {
    constructor(pb, ttl = 60000) {
        this.pb = pb;
        this.cache = new Map();
        this.ttl = ttl;
    }
    
    async get(collection, id, options = {}) {
        const key = `${collection}:${id}`;
        const cached = this.cache.get(key);
        
        if (cached && Date.now() - cached.timestamp < this.ttl) {
            return cached.data;
        }
        
        const data = await this.pb.collection(collection).getOne(id, options);
        this.cache.set(key, {
            data,
            timestamp: Date.now()
        });
        
        return data;
    }
    
    invalidate(collection, id) {
        const key = `${collection}:${id}`;
        this.cache.delete(key);
    }
    
    clear() {
        this.cache.clear();
    }
}

const cachedPB = new PocketBaseCache(pb);
const user = await cachedPB.get('users', 'USER_ID');
```

### 3. Offline Support
```javascript
class OfflineQueue {
    constructor(pb) {
        this.pb = pb;
        this.queue = [];
        this.processing = false;
        
        // Load queue from localStorage
        const saved = localStorage.getItem('pb_offline_queue');
        if (saved) {
            this.queue = JSON.parse(saved);
        }
        
        // Process queue when online
        window.addEventListener('online', () => this.processQueue());
    }
    
    async execute(operation) {
        if (!navigator.onLine) {
            this.queue.push({
                ...operation,
                timestamp: Date.now()
            });
            this.saveQueue();
            return { offline: true, queued: true };
        }
        
        return await this.performOperation(operation);
    }
    
    async performOperation(op) {
        switch(op.type) {
            case 'create':
                return await this.pb.collection(op.collection).create(op.data);
            case 'update':
                return await this.pb.collection(op.collection).update(op.id, op.data);
            case 'delete':
                return await this.pb.collection(op.collection).delete(op.id);
        }
    }
    
    async processQueue() {
        if (this.processing || !this.queue.length) return;
        
        this.processing = true;
        
        while (this.queue.length > 0) {
            const op = this.queue.shift();
            
            try {
                await this.performOperation(op);
            } catch (error) {
                console.error('Failed to sync operation:', error);
                // Re-add to queue or handle error
                this.queue.unshift(op);
                break;
            }
        }
        
        this.saveQueue();
        this.processing = false;
    }
    
    saveQueue() {
        localStorage.setItem('pb_offline_queue', JSON.stringify(this.queue));
    }
}
```

### 4. Search Implementation
```javascript
// Full-text search
async function search(query, options = {}) {
    const {
        collections = ['posts', 'pages', 'products'],
        fields = ['title', 'content', 'description'],
        limit = 20
    } = options;
    
    const searchPromises = collections.map(collection => {
        const filters = fields.map(field => 
            `${field} ~ "${query}"`
        ).join(' || ');
        
        return pb.collection(collection).getList(1, limit, {
            filter: filters,
            sort: '-created'
        });
    });
    
    const results = await Promise.all(searchPromises);
    
    // Combine and sort results
    const combined = results.flatMap((result, index) => 
        result.items.map(item => ({
            ...item,
            collection: collections[index],
            score: calculateRelevance(item, query, fields)
        }))
    );
    
    return combined.sort((a, b) => b.score - a.score);
}

function calculateRelevance(item, query, fields) {
    let score = 0;
    const queryLower = query.toLowerCase();
    
    fields.forEach(field => {
        const value = (item[field] || '').toLowerCase();
        if (value.includes(queryLower)) {
            score += value.startsWith(queryLower) ? 3 : 1;
        }
    });
    
    return score;
}
```

## Performance Optimization

### 1. Query Optimization
```javascript
// Use field selection to reduce payload
const posts = await pb.collection('posts').getList(1, 20, {
    fields: 'id,title,created,author',
    expand: 'author',
    filter: 'published = true'
});

// Batch requests with Promise.all
const [posts, comments, users] = await Promise.all([
    pb.collection('posts').getList(),
    pb.collection('comments').getList(),
    pb.collection('users').getList()
]);

// Implement pagination
async function* paginate(collection, filter = '') {
    let page = 1;
    let hasMore = true;
    
    while (hasMore) {
        const result = await pb.collection(collection).getList(page, 100, {
            filter
        });
        
        yield result.items;
        
        hasMore = page < result.totalPages;
        page++;
    }
}

// Usage
for await (const batch of paginate('posts', 'published = true')) {
    processBatch(batch);
}
```

### 2. Connection Management
```javascript
// Singleton pattern for PocketBase client
class PocketBaseClient {
    constructor() {
        if (PocketBaseClient.instance) {
            return PocketBaseClient.instance;
        }
        
        this.pb = new PocketBase(process.env.POCKETBASE_URL);
        PocketBaseClient.instance = this;
    }
    
    getInstance() {
        return this.pb;
    }
}

const pb = new PocketBaseClient().getInstance();
```

## Security Best Practices

### 1. API Rules
```javascript
// Secure collection rules examples
const rules = {
    // Only authenticated users can list
    listRule: "@request.auth.id != ''",
    
    // Only see own records or published
    viewRule: "author = @request.auth.id || published = true",
    
    // Only verified users can create
    createRule: "@request.auth.verified = true",
    
    // Only author can update within 24 hours
    updateRule: "author = @request.auth.id && created > @now - 86400",
    
    // Only author or admin can delete
    deleteRule: "author = @request.auth.id || @request.auth.role = 'admin'"
};
```

### 2. Input Validation
```javascript
// Client-side validation
function validatePost(data) {
    const errors = {};
    
    if (!data.title || data.title.length < 3) {
        errors.title = 'Title must be at least 3 characters';
    }
    
    if (!data.content || data.content.length < 10) {
        errors.content = 'Content must be at least 10 characters';
    }
    
    if (data.tags && data.tags.length > 5) {
        errors.tags = 'Maximum 5 tags allowed';
    }
    
    return {
        valid: Object.keys(errors).length === 0,
        errors
    };
}

// Use before submission
const validation = validatePost(formData);
if (!validation.valid) {
    showErrors(validation.errors);
    return;
}
```

## Deployment

### 1. Production Configuration
```bash
# systemd service file
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=pocketbase
Group=pocketbase
WorkingDirectory=/opt/pocketbase
ExecStart=/opt/pocketbase/pocketbase serve --http="127.0.0.1:8090"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 2. Nginx Reverse Proxy
```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for realtime
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 3. Backup Strategy
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups/pocketbase"
PB_DATA="/opt/pocketbase/pb_data"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Stop PocketBase
systemctl stop pocketbase

# Backup data
tar -czf "$BACKUP_DIR/pb_backup_$DATE.tar.gz" -C $PB_DATA .

# Start PocketBase
systemctl start pocketbase

# Remove old backups (keep last 7 days)
find $BACKUP_DIR -name "pb_backup_*.tar.gz" -mtime +7 -delete
```

## Common Pitfalls to Avoid

1. **Not Setting API Rules**: Always configure proper access rules
2. **Ignoring Rate Limiting**: Implement rate limiting for public APIs
3. **Large File Uploads**: Use appropriate limits and validation
4. **Not Handling Offline**: Implement offline queue for better UX
5. **Missing Indexes**: Add indexes for frequently queried fields
6. **Not Backing Up**: Regular backups of pb_data directory
7. **Exposing Admin UI**: Secure or disable admin UI in production
8. **Not Validating Input**: Always validate on both client and server
9. **Ignoring Migrations**: Use migrations for schema changes
10. **Not Monitoring**: Track errors and performance metrics

## Useful Resources

- **PocketBase Examples**: https://github.com/pocketbase/pocketbase/tree/master/examples
- **Community Extensions**: https://github.com/topics/pocketbase
- **Docker Images**: https://hub.docker.com/r/spectado/pocketbase
- **Deployment Guides**: https://pocketbase.io/docs/deployment
- **SDK Examples**: https://github.com/pocketbase/js-sdk#examples