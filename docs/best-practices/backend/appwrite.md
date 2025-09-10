# Appwrite Best Practices

## Official Documentation
- **Appwrite Documentation**: https://appwrite.io/docs
- **Appwrite GitHub**: https://github.com/appwrite/appwrite
- **Appwrite SDK References**: https://appwrite.io/docs/sdks
- **Appwrite Cloud**: https://cloud.appwrite.io/

## Overview
Appwrite is an open-source backend-as-a-service platform that provides developers with all the core APIs required to build modern applications including authentication, databases, storage, functions, and realtime capabilities.

## Core Best Practices

### 1. Installation and Setup

#### Self-Hosted with Docker
```bash
# Install with Docker
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="install" \
    appwrite/appwrite:latest

# Docker Compose setup
version: '3'
services:
  appwrite:
    image: appwrite/appwrite:latest
    container_name: appwrite
    restart: unless-stopped
    networks:
      - appwrite
    volumes:
      - appwrite-uploads:/storage/uploads:rw
      - appwrite-cache:/storage/cache:rw
      - appwrite-config:/storage/config:rw
      - appwrite-certificates:/storage/certificates:rw
      - appwrite-functions:/storage/functions:rw
    ports:
      - 80:80
      - 443:443
    environment:
      - _APP_ENV=production
      - _APP_OPENSSL_KEY_V1=your-secret-key
      - _APP_DOMAIN=localhost
      - _APP_DOMAIN_TARGET=localhost
```

#### Client SDK Setup

**Web/JavaScript**
```javascript
// npm install appwrite
import { Client, Account, Databases, Storage, Functions } from 'appwrite';

const client = new Client()
    .setEndpoint('https://[HOSTNAME_OR_IP]/v1') // Your API Endpoint
    .setProject('[PROJECT_ID]'); // Your project ID

// Services
const account = new Account(client);
const databases = new Databases(client);
const storage = new Storage(client);
const functions = new Functions(client);

// With custom configuration
const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setSelfSigned(true); // For self-signed certificates in development
```

**Flutter/Dart**
```dart
import 'package:appwrite/appwrite.dart';

void main() {
  Client client = Client()
    .setEndpoint('https://[HOSTNAME_OR_IP]/v1')
    .setProject('[PROJECT_ID]')
    .setSelfSigned(status: true);
    
  Account account = Account(client);
  Databases databases = Databases(client);
  Storage storage = Storage(client);
}
```

### 2. Authentication

#### Email/Password Authentication
```javascript
// Register user
const user = await account.create(
    ID.unique(),
    'email@example.com',
    'password123',
    'John Doe'
);

// Email verification
await account.createVerification('https://example.com/verify');

// Login
const session = await account.createEmailSession(
    'email@example.com',
    'password123'
);

// Get current user
const currentUser = await account.get();

// Update user preferences
await account.updatePrefs({
    theme: 'dark',
    language: 'en',
    notifications: true
});

// Logout
await account.deleteSession('current');

// Logout from all devices
await account.deleteSessions();
```

#### OAuth2 Authentication
```javascript
// List OAuth2 providers
const providers = [
    'google', 'facebook', 'github', 'gitlab', 'discord',
    'microsoft', 'apple', 'spotify', 'twitch', 'linkedin'
];

// Initiate OAuth2 login
account.createOAuth2Session(
    'google',
    'https://example.com/success',
    'https://example.com/failure',
    ['profile', 'email'] // Scopes
);

// Handle OAuth2 callback
const urlParams = new URLSearchParams(window.location.search);
const userId = urlParams.get('userId');
const secret = urlParams.get('secret');

if (userId && secret) {
    const session = await account.updateSession(userId, secret);
    console.log('Logged in successfully');
}
```

#### JWT Authentication
```javascript
// Create JWT
const jwt = await account.createJWT();

// Use JWT in requests
const clientWithJWT = new Client()
    .setEndpoint('https://[HOSTNAME_OR_IP]/v1')
    .setProject('[PROJECT_ID]')
    .setJWT(jwt.jwt);
```

#### Team Management
```javascript
// Create team
const team = await teams.create(ID.unique(), 'Development Team');

// Invite members
await teams.createMembership(
    team.$id,
    'member@example.com',
    ['developer'],
    'https://example.com/join'
);

// List team members
const memberships = await teams.listMemberships(team.$id);

// Update member roles
await teams.updateMembershipRoles(
    team.$id,
    membershipId,
    ['developer', 'admin']
);
```

### 3. Database Operations

#### Collection Schema
```javascript
// Create database
const database = await databases.create(
    ID.unique(),
    'blog_database'
);

// Create collection with attributes
const collection = await databases.createCollection(
    database.$id,
    ID.unique(),
    'posts',
    [
        Permission.read(Role.any()),
        Permission.create(Role.users()),
        Permission.update(Role.user(ID.custom('user-id'))),
        Permission.delete(Role.user(ID.custom('user-id')))
    ]
);

// Create attributes
await databases.createStringAttribute(
    database.$id,
    collection.$id,
    'title',
    255,
    true
);

await databases.createStringAttribute(
    database.$id,
    collection.$id,
    'content',
    5000,
    true,
    'Default content'
);

await databases.createEnumAttribute(
    database.$id,
    collection.$id,
    'status',
    ['draft', 'published', 'archived'],
    true,
    'draft'
);

await databases.createDatetimeAttribute(
    database.$id,
    collection.$id,
    'publishedAt',
    false
);

await databases.createRelationship(
    database.$id,
    collection.$id,
    'users',
    'oneToMany',
    false,
    'author',
    'posts'
);

// Create indexes
await databases.createIndex(
    database.$id,
    collection.$id,
    'title_index',
    'key',
    ['title'],
    ['asc']
);
```

#### CRUD Operations
```javascript
// Create document
const post = await databases.createDocument(
    database.$id,
    collection.$id,
    ID.unique(),
    {
        title: 'My First Post',
        content: 'This is the content of my post',
        status: 'draft',
        author: currentUser.$id,
        tags: ['javascript', 'appwrite'],
        publishedAt: new Date().toISOString()
    },
    [
        Permission.read(Role.any()),
        Permission.update(Role.user(currentUser.$id)),
        Permission.delete(Role.user(currentUser.$id))
    ]
);

// Read document
const document = await databases.getDocument(
    database.$id,
    collection.$id,
    documentId
);

// Update document
const updated = await databases.updateDocument(
    database.$id,
    collection.$id,
    documentId,
    {
        title: 'Updated Title',
        status: 'published'
    }
);

// Delete document
await databases.deleteDocument(
    database.$id,
    collection.$id,
    documentId
);

// List documents with queries
const posts = await databases.listDocuments(
    database.$id,
    collection.$id,
    [
        Query.equal('status', 'published'),
        Query.greaterThan('publishedAt', '2024-01-01'),
        Query.orderDesc('publishedAt'),
        Query.limit(10),
        Query.offset(0)
    ]
);
```

#### Advanced Queries
```javascript
// Complex queries
const results = await databases.listDocuments(
    database.$id,
    collection.$id,
    [
        // Comparison queries
        Query.equal('status', ['published', 'draft']),
        Query.notEqual('author', 'anonymous'),
        Query.lessThan('price', 100),
        Query.lessThanEqual('stock', 10),
        Query.greaterThan('rating', 4.0),
        Query.greaterThanEqual('views', 1000),
        
        // String queries
        Query.search('title', 'javascript'),
        Query.startsWith('category', 'tech'),
        Query.endsWith('filename', '.pdf'),
        
        // Array queries
        Query.contains('tags', ['javascript', 'nodejs']),
        
        // Null checks
        Query.isNull('deletedAt'),
        Query.isNotNull('publishedAt'),
        
        // Logical operators
        Query.or([
            Query.equal('priority', 'high'),
            Query.greaterThan('votes', 100)
        ]),
        
        // Pagination and sorting
        Query.orderAsc('title'),
        Query.orderDesc('createdAt'),
        Query.limit(25),
        Query.offset(0),
        Query.cursorAfter(lastDocument.$id),
        
        // Select specific fields
        Query.select(['title', 'author', 'publishedAt'])
    ]
);
```

### 4. File Storage
```javascript
// Create bucket
const bucket = await storage.createBucket(
    ID.unique(),
    'avatars',
    [
        Permission.read(Role.any()),
        Permission.create(Role.users()),
        Permission.update(Role.user(ID.custom('user-id'))),
        Permission.delete(Role.user(ID.custom('user-id')))
    ],
    false, // encryption
    true, // antivirus
    1048576, // 1MB max file size
    ['image/png', 'image/jpeg'] // allowed file types
);

// Upload file
const file = await storage.createFile(
    bucket.$id,
    ID.unique(),
    document.getElementById('uploader').files[0],
    [
        Permission.read(Role.any()),
        Permission.delete(Role.user(currentUser.$id))
    ]
);

// Get file preview
const preview = storage.getFilePreview(
    bucket.$id,
    file.$id,
    300, // width
    300, // height
    'center', // gravity
    100, // quality
    1, // borderWidth
    '000000', // borderColor
    10, // borderRadius
    1, // opacity
    0, // rotation
    'FFFFFF', // background
    'webp' // output format
);

// Download file
const download = storage.getFileDownload(bucket.$id, file.$id);

// View file
const view = storage.getFileView(bucket.$id, file.$id);

// Delete file
await storage.deleteFile(bucket.$id, file.$id);

// List files
const files = await storage.listFiles(
    bucket.$id,
    [
        Query.equal('mimeType', 'image/png'),
        Query.greaterThan('sizeOriginal', 1000),
        Query.orderDesc('$createdAt')
    ]
);
```

### 5. Cloud Functions
```javascript
// Create function
const func = await functions.create(
    ID.unique(),
    'sendEmail',
    ['node-18.0'],
    [
        Permission.execute(Role.users())
    ],
    'index.js',
    'send',
    {
        'SMTP_HOST': 'smtp.gmail.com',
        'SMTP_PORT': '587'
    },
    ['*/5 * * * *'], // Cron schedule
    30, // timeout in seconds
    true // enabled
);

// Execute function
const execution = await functions.createExecution(
    func.$id,
    JSON.stringify({
        to: 'user@example.com',
        subject: 'Hello from Appwrite',
        body: 'This is a test email'
    }),
    false // async
);

// Get execution logs
const logs = await functions.getExecution(func.$id, execution.$id);
console.log(logs.response);
console.log(logs.stderr);
console.log(logs.stdout);

// Function code example (index.js)
module.exports = async function(req, res) {
    const payload = JSON.parse(req.payload || '{}');
    
    // Your function logic
    const result = await sendEmail(
        payload.to,
        payload.subject,
        payload.body
    );
    
    res.json({
        success: true,
        message: 'Email sent successfully',
        data: result
    });
};
```

### 6. Realtime Subscriptions
```javascript
// Subscribe to account events
const unsubscribeAccount = client.subscribe('account', (response) => {
    console.log('Account event:', response);
    
    if (response.events.includes('users.*.sessions.*.create')) {
        console.log('New session created');
    }
    
    if (response.events.includes('users.*.sessions.*.delete')) {
        console.log('Session deleted');
    }
});

// Subscribe to database events
const unsubscribeDB = client.subscribe(
    `databases.${database.$id}.collections.${collection.$id}.documents`,
    (response) => {
        console.log('Document event:', response);
        
        if (response.events.includes(`databases.${database.$id}.collections.${collection.$id}.documents.*.create`)) {
            console.log('New document created:', response.payload);
        }
        
        if (response.events.includes(`databases.${database.$id}.collections.${collection.$id}.documents.*.update`)) {
            console.log('Document updated:', response.payload);
        }
    }
);

// Subscribe to specific document
const unsubscribeDoc = client.subscribe(
    `databases.${database.$id}.collections.${collection.$id}.documents.${documentId}`,
    (response) => {
        console.log('Document changed:', response.payload);
    }
);

// Subscribe to storage events
const unsubscribeStorage = client.subscribe(
    `buckets.${bucket.$id}.files`,
    (response) => {
        console.log('File event:', response);
    }
);

// Unsubscribe
unsubscribeAccount();
unsubscribeDB();
```

## Advanced Patterns

### 1. Custom Authentication Flow
```javascript
class AuthManager {
    constructor(client) {
        this.client = client;
        this.account = new Account(client);
        this.user = null;
    }
    
    async init() {
        try {
            this.user = await this.account.get();
            return this.user;
        } catch (error) {
            this.user = null;
            return null;
        }
    }
    
    async register(email, password, name) {
        try {
            const user = await this.account.create(
                ID.unique(),
                email,
                password,
                name
            );
            
            // Auto-login after registration
            await this.login(email, password);
            
            // Send verification email
            await this.account.createVerification(
                `${window.location.origin}/verify`
            );
            
            return user;
        } catch (error) {
            throw this.handleAuthError(error);
        }
    }
    
    async login(email, password) {
        try {
            const session = await this.account.createEmailSession(email, password);
            this.user = await this.account.get();
            this.onAuthStateChange(this.user);
            return session;
        } catch (error) {
            throw this.handleAuthError(error);
        }
    }
    
    async logout() {
        try {
            await this.account.deleteSession('current');
            this.user = null;
            this.onAuthStateChange(null);
        } catch (error) {
            console.error('Logout error:', error);
        }
    }
    
    async refreshSession() {
        try {
            const session = await this.account.getSession('current');
            if (new Date(session.expire) < new Date()) {
                await this.logout();
                throw new Error('Session expired');
            }
            return session;
        } catch (error) {
            await this.logout();
            throw error;
        }
    }
    
    onAuthStateChange(user) {
        // Emit event or update state management
        window.dispatchEvent(new CustomEvent('authStateChange', {
            detail: { user }
        }));
    }
    
    handleAuthError(error) {
        const errorMessages = {
            401: 'Invalid credentials',
            409: 'User already exists',
            429: 'Too many attempts. Please try again later',
            500: 'Server error. Please try again'
        };
        
        return new Error(errorMessages[error.code] || error.message);
    }
}
```

### 2. Database Repository Pattern
```javascript
class Repository {
    constructor(databases, databaseId, collectionId) {
        this.databases = databases;
        this.databaseId = databaseId;
        this.collectionId = collectionId;
    }
    
    async create(data, permissions = []) {
        return await this.databases.createDocument(
            this.databaseId,
            this.collectionId,
            ID.unique(),
            data,
            permissions
        );
    }
    
    async findById(id) {
        try {
            return await this.databases.getDocument(
                this.databaseId,
                this.collectionId,
                id
            );
        } catch (error) {
            if (error.code === 404) return null;
            throw error;
        }
    }
    
    async find(queries = []) {
        const response = await this.databases.listDocuments(
            this.databaseId,
            this.collectionId,
            queries
        );
        return response.documents;
    }
    
    async findOne(queries = []) {
        const documents = await this.find([...queries, Query.limit(1)]);
        return documents[0] || null;
    }
    
    async update(id, data) {
        return await this.databases.updateDocument(
            this.databaseId,
            this.collectionId,
            id,
            data
        );
    }
    
    async delete(id) {
        return await this.databases.deleteDocument(
            this.databaseId,
            this.collectionId,
            id
        );
    }
    
    async paginate(page = 1, limit = 10, queries = []) {
        const offset = (page - 1) * limit;
        
        const response = await this.databases.listDocuments(
            this.databaseId,
            this.collectionId,
            [
                ...queries,
                Query.limit(limit),
                Query.offset(offset)
            ]
        );
        
        return {
            documents: response.documents,
            total: response.total,
            page,
            pages: Math.ceil(response.total / limit)
        };
    }
}

// Usage
const postsRepo = new Repository(databases, 'blog', 'posts');
const posts = await postsRepo.paginate(1, 20, [
    Query.equal('status', 'published'),
    Query.orderDesc('publishedAt')
]);
```

### 3. File Upload Manager
```javascript
class FileUploadManager {
    constructor(storage, bucketId) {
        this.storage = storage;
        this.bucketId = bucketId;
        this.uploadQueue = [];
        this.uploading = false;
    }
    
    async upload(file, options = {}) {
        const {
            onProgress,
            permissions = [],
            metadata = {}
        } = options;
        
        // Validate file
        if (!this.validateFile(file)) {
            throw new Error('Invalid file');
        }
        
        // Create upload promise
        const uploadPromise = this.storage.createFile(
            this.bucketId,
            ID.unique(),
            file,
            permissions,
            (progress) => {
                if (onProgress) {
                    onProgress({
                        loaded: progress.loaded,
                        total: progress.total,
                        percentage: Math.round((progress.loaded / progress.total) * 100)
                    });
                }
            }
        );
        
        try {
            const uploaded = await uploadPromise;
            
            // Store metadata if needed
            if (Object.keys(metadata).length > 0) {
                await this.storeMetadata(uploaded.$id, metadata);
            }
            
            return uploaded;
        } catch (error) {
            console.error('Upload failed:', error);
            throw error;
        }
    }
    
    async uploadMultiple(files, options = {}) {
        const results = [];
        
        for (const file of files) {
            try {
                const uploaded = await this.upload(file, options);
                results.push({ success: true, file: uploaded });
            } catch (error) {
                results.push({ success: false, error: error.message });
            }
        }
        
        return results;
    }
    
    validateFile(file) {
        const maxSize = 10 * 1024 * 1024; // 10MB
        const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
        
        if (file.size > maxSize) {
            throw new Error('File too large');
        }
        
        if (!allowedTypes.includes(file.type)) {
            throw new Error('File type not allowed');
        }
        
        return true;
    }
    
    async storeMetadata(fileId, metadata) {
        // Store in a separate collection
        // Implementation depends on your schema
    }
    
    getFileUrl(fileId, preview = false) {
        if (preview) {
            return this.storage.getFilePreview(
                this.bucketId,
                fileId,
                200,
                200
            );
        }
        return this.storage.getFileView(this.bucketId, fileId);
    }
}
```

### 4. Caching Layer
```javascript
class AppwriteCache {
    constructor(ttl = 300000) { // 5 minutes
        this.cache = new Map();
        this.ttl = ttl;
    }
    
    set(key, value) {
        this.cache.set(key, {
            value,
            timestamp: Date.now()
        });
    }
    
    get(key) {
        const cached = this.cache.get(key);
        
        if (!cached) return null;
        
        if (Date.now() - cached.timestamp > this.ttl) {
            this.cache.delete(key);
            return null;
        }
        
        return cached.value;
    }
    
    async fetch(key, fetchFn) {
        const cached = this.get(key);
        if (cached) return cached;
        
        const value = await fetchFn();
        this.set(key, value);
        return value;
    }
    
    invalidate(pattern) {
        for (const key of this.cache.keys()) {
            if (key.includes(pattern)) {
                this.cache.delete(key);
            }
        }
    }
    
    clear() {
        this.cache.clear();
    }
}

// Usage with repository
class CachedRepository extends Repository {
    constructor(databases, databaseId, collectionId) {
        super(databases, databaseId, collectionId);
        this.cache = new AppwriteCache();
    }
    
    async findById(id) {
        return await this.cache.fetch(
            `doc:${id}`,
            () => super.findById(id)
        );
    }
    
    async update(id, data) {
        const result = await super.update(id, data);
        this.cache.invalidate(`doc:${id}`);
        return result;
    }
}
```

## Performance Optimization

### 1. Batch Operations
```javascript
async function batchCreate(databases, databaseId, collectionId, documents) {
    const promises = documents.map(doc =>
        databases.createDocument(
            databaseId,
            collectionId,
            ID.unique(),
            doc
        )
    );
    
    const results = await Promise.allSettled(promises);
    
    return {
        successful: results.filter(r => r.status === 'fulfilled').map(r => r.value),
        failed: results.filter(r => r.status === 'rejected').map(r => r.reason)
    };
}
```

### 2. Lazy Loading
```javascript
class LazyLoader {
    constructor(databases) {
        this.databases = databases;
        this.loaded = new Map();
    }
    
    async load(databaseId, collectionId, documentId) {
        const key = `${databaseId}:${collectionId}:${documentId}`;
        
        if (this.loaded.has(key)) {
            return this.loaded.get(key);
        }
        
        const document = await this.databases.getDocument(
            databaseId,
            collectionId,
            documentId
        );
        
        this.loaded.set(key, document);
        return document;
    }
    
    async loadRelated(document, relations) {
        for (const relation of relations) {
            if (document[relation] && typeof document[relation] === 'string') {
                document[relation] = await this.load(
                    document.$databaseId,
                    relation,
                    document[relation]
                );
            }
        }
        return document;
    }
}
```

## Security Best Practices

### 1. Permission Management
```javascript
class PermissionBuilder {
    static publicRead() {
        return Permission.read(Role.any());
    }
    
    static userWrite(userId) {
        return Permission.write(Role.user(userId));
    }
    
    static teamAccess(teamId, role = 'member') {
        return [
            Permission.read(Role.team(teamId, role)),
            Permission.write(Role.team(teamId, role))
        ];
    }
    
    static ownerOnly(userId) {
        return [
            Permission.read(Role.user(userId)),
            Permission.write(Role.user(userId)),
            Permission.delete(Role.user(userId))
        ];
    }
    
    static adminOnly() {
        return [
            Permission.read(Role.team('admin')),
            Permission.write(Role.team('admin')),
            Permission.delete(Role.team('admin'))
        ];
    }
}
```

### 2. Input Validation
```javascript
class Validator {
    static email(value) {
        const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!regex.test(value)) {
            throw new Error('Invalid email format');
        }
        return value;
    }
    
    static password(value) {
        if (value.length < 8) {
            throw new Error('Password must be at least 8 characters');
        }
        if (!/[A-Z]/.test(value)) {
            throw new Error('Password must contain uppercase letter');
        }
        if (!/[0-9]/.test(value)) {
            throw new Error('Password must contain number');
        }
        return value;
    }
    
    static sanitizeHtml(value) {
        // Remove script tags and dangerous attributes
        return value
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
            .replace(/on\w+="[^"]*"/g, '');
    }
}
```

## Deployment

### 1. Docker Production Setup
```yaml
version: '3'

services:
  traefik:
    image: traefik:2.9
    container_name: traefik
    command:
      - --providers.docker=true
      - --providers.docker.exposedByDefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.email=admin@example.com
      - --certificatesresolvers.letsencrypt.acme.storage=/certificates/acme.json
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./certificates:/certificates

  appwrite:
    image: appwrite/appwrite:latest
    container_name: appwrite
    restart: unless-stopped
    networks:
      - appwrite
    labels:
      - traefik.enable=true
      - traefik.http.routers.appwrite.rule=Host(`api.example.com`)
      - traefik.http.routers.appwrite.tls=true
      - traefik.http.routers.appwrite.tls.certresolver=letsencrypt
    volumes:
      - appwrite-uploads:/storage/uploads:rw
      - appwrite-cache:/storage/cache:rw
      - appwrite-config:/storage/config:rw
      - appwrite-certificates:/storage/certificates:rw
      - appwrite-functions:/storage/functions:rw
    environment:
      - _APP_ENV=production
      - _APP_DOMAIN=api.example.com
      - _APP_DOMAIN_TARGET=api.example.com
      - _APP_REDIS_HOST=redis
      - _APP_REDIS_PORT=6379
      - _APP_DB_HOST=mariadb
      - _APP_DB_PORT=3306
      - _APP_DB_SCHEMA=appwrite
      - _APP_DB_USER=appwrite
      - _APP_DB_PASS=${DB_PASSWORD}
```

### 2. Backup Strategy
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backups/appwrite"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker exec appwrite-mariadb mysqldump \
    -u root -p${MYSQL_ROOT_PASSWORD} \
    appwrite > $BACKUP_DIR/database_$DATE.sql

# Backup storage
tar -czf $BACKUP_DIR/storage_$DATE.tar.gz \
    /var/lib/docker/volumes/appwrite_appwrite-uploads/_data

# Backup config
tar -czf $BACKUP_DIR/config_$DATE.tar.gz \
    /var/lib/docker/volumes/appwrite_appwrite-config/_data

# Remove old backups (keep last 7 days)
find $BACKUP_DIR -type f -mtime +7 -delete
```

## Common Pitfalls to Avoid

1. **Not Setting Permissions**: Always configure appropriate permissions
2. **Ignoring Rate Limits**: Implement rate limiting for API calls
3. **Large File Uploads**: Set appropriate file size limits
4. **Missing Indexes**: Add indexes for frequently queried fields
5. **Not Handling Errors**: Implement comprehensive error handling
6. **Hardcoding Configuration**: Use environment variables
7. **Not Validating Input**: Always validate and sanitize user input
8. **Ignoring Realtime Events**: Utilize realtime for better UX
9. **Not Backing Up**: Regular backups of database and storage
10. **Missing SSL**: Always use HTTPS in production

## Useful Resources

- **Appwrite Discord**: https://appwrite.io/discord
- **Appwrite Blog**: https://appwrite.io/blog
- **Appwrite Awesome List**: https://github.com/appwrite/awesome-appwrite
- **Appwrite Functions Examples**: https://github.com/appwrite/functions-examples
- **Appwrite Playground**: https://playground.appwrite.io/