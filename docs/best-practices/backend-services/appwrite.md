# Appwrite Best Practices

## Overview

Appwrite is an open-source Backend-as-a-Service (BaaS) platform that provides developers with core APIs to build web, mobile, and native applications. It abstracts complex backend operations while maintaining flexibility and control over your application architecture.

### Use Cases
- Rapid prototyping and MVP development
- Real-time collaborative applications
- Mobile and web applications requiring authentication
- Applications needing file storage and management
- Projects requiring database operations without backend setup

## Setup and Configuration

### Initial Setup

```bash
# Docker installation (recommended)
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="install" \
    appwrite/appwrite:latest
```

### Environment Configuration

```env
# .env configuration
_APP_ENV=production
_APP_LOCALE=en
_APP_CONSOLE_WHITELIST_EMAILS=admin@example.com
_APP_CONSOLE_WHITELIST_IPS=
_APP_SYSTEM_EMAIL_NAME=Appwrite
_APP_SYSTEM_EMAIL_ADDRESS=team@appwrite.io
_APP_SYSTEM_SECURITY_EMAIL_ADDRESS=security@appwrite.io
_APP_USAGE_STATS=enabled
_APP_LOGGING_PROVIDER=
_APP_LOGGING_CONFIG=
```

### SDK Initialization

```javascript
// Web SDK initialization
import { Client, Account, Databases } from 'appwrite';

const client = new Client()
    .setEndpoint('https://cloud.appwrite.io/v1')
    .setProject('YOUR_PROJECT_ID');

// Initialize services
const account = new Account(client);
const databases = new Databases(client);
```

## Security Considerations

### API Key Management

```javascript
// Server-side only - never expose in client code
const client = new Client()
    .setEndpoint('https://cloud.appwrite.io/v1')
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
```

### Permission Models

```javascript
// Document-level permissions
import { Permission, Role } from 'appwrite';

const permissions = [
    Permission.read(Role.any()),
    Permission.update(Role.user('USER_ID')),
    Permission.delete(Role.user('USER_ID'))
];

// Create document with permissions
await databases.createDocument(
    'DATABASE_ID',
    'COLLECTION_ID',
    ID.unique(),
    data,
    permissions
);
```

### Authentication Best Practices

```javascript
// Implement session management
class AuthService {
    async login(email, password) {
        try {
            const session = await account.createEmailSession(email, password);
            // Store session securely
            return session;
        } catch (error) {
            // Handle authentication errors
            console.error('Authentication failed:', error);
            throw error;
        }
    }

    async logout() {
        try {
            await account.deleteSession('current');
        } catch (error) {
            console.error('Logout failed:', error);
        }
    }

    async validateSession() {
        try {
            const user = await account.get();
            return user;
        } catch {
            return null;
        }
    }
}
```

## Performance Optimization

### Query Optimization

```javascript
// Use indexes for frequently queried fields
const response = await databases.listDocuments(
    'DATABASE_ID',
    'COLLECTION_ID',
    [
        Query.equal('status', 'active'),
        Query.orderDesc('$createdAt'),
        Query.limit(25),
        Query.offset(0)
    ]
);

// Implement pagination
class PaginationService {
    async fetchPage(page = 1, limit = 25) {
        const offset = (page - 1) * limit;
        return await databases.listDocuments(
            'DATABASE_ID',
            'COLLECTION_ID',
            [
                Query.limit(limit),
                Query.offset(offset)
            ]
        );
    }
}
```

### Caching Strategies

```javascript
// Implement client-side caching
class CacheService {
    constructor(ttl = 300000) { // 5 minutes default
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
        const item = this.cache.get(key);
        if (!item) return null;
        
        if (Date.now() - item.timestamp > this.ttl) {
            this.cache.delete(key);
            return null;
        }
        
        return item.value;
    }
}
```

### File Upload Optimization

```javascript
// Chunked file uploads for large files
async function uploadLargeFile(file, onProgress) {
    const chunkSize = 5 * 1024 * 1024; // 5MB chunks
    const chunks = Math.ceil(file.size / chunkSize);
    
    for (let i = 0; i < chunks; i++) {
        const start = i * chunkSize;
        const end = Math.min(start + chunkSize, file.size);
        const chunk = file.slice(start, end);
        
        // Upload chunk
        await storage.createFile(
            'BUCKET_ID',
            ID.unique(),
            chunk
        );
        
        // Report progress
        if (onProgress) {
            onProgress((i + 1) / chunks * 100);
        }
    }
}
```

## Common Patterns

### Real-time Subscriptions

```javascript
// Subscribe to document changes
const unsubscribe = client.subscribe(
    `databases.${DATABASE_ID}.collections.${COLLECTION_ID}.documents`,
    (response) => {
        // Handle real-time updates
        if (response.events.includes('databases.*.collections.*.documents.*.create')) {
            console.log('Document created:', response.payload);
        }
        if (response.events.includes('databases.*.collections.*.documents.*.update')) {
            console.log('Document updated:', response.payload);
        }
    }
);

// Clean up subscription
// unsubscribe();
```

### Error Handling Pattern

```javascript
class AppwriteErrorHandler {
    static handle(error) {
        const errorMap = {
            401: 'Authentication required',
            403: 'Access denied',
            404: 'Resource not found',
            409: 'Resource already exists',
            429: 'Too many requests',
            500: 'Server error'
        };

        const message = errorMap[error.code] || 'An unexpected error occurred';
        
        // Log error for debugging
        console.error(`Appwrite Error [${error.code}]:`, error.message);
        
        return {
            success: false,
            message,
            code: error.code
        };
    }
}

// Usage
try {
    const result = await databases.createDocument(...);
    return { success: true, data: result };
} catch (error) {
    return AppwriteErrorHandler.handle(error);
}
```

### Data Validation

```javascript
// Schema validation before database operations
class ValidationService {
    static validateEmail(email) {
        const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return regex.test(email);
    }

    static validateDocument(data, schema) {
        const errors = [];
        
        for (const [field, rules] of Object.entries(schema)) {
            if (rules.required && !data[field]) {
                errors.push(`${field} is required`);
            }
            
            if (rules.type && typeof data[field] !== rules.type) {
                errors.push(`${field} must be of type ${rules.type}`);
            }
            
            if (rules.minLength && data[field].length < rules.minLength) {
                errors.push(`${field} must be at least ${rules.minLength} characters`);
            }
        }
        
        return errors.length > 0 ? { valid: false, errors } : { valid: true };
    }
}
```

## Anti-patterns to Avoid

### Client-Side API Keys
```javascript
// ❌ Never do this
const client = new Client()
    .setKey('sk_live_abc123...'); // API key exposed in client

// ✅ Use proper authentication
const client = new Client();
// Let users authenticate themselves
await account.createEmailSession(email, password);
```

### Unbounded Queries
```javascript
// ❌ Avoid fetching all documents
const allDocs = await databases.listDocuments(
    'DATABASE_ID',
    'COLLECTION_ID'
    // No limit specified
);

// ✅ Always paginate
const docs = await databases.listDocuments(
    'DATABASE_ID',
    'COLLECTION_ID',
    [Query.limit(100)]
);
```

### Synchronous Operations in Loops
```javascript
// ❌ Avoid sequential operations
for (const item of items) {
    await databases.createDocument(...);
}

// ✅ Use batch operations
const promises = items.map(item => 
    databases.createDocument(...)
);
await Promise.all(promises);
```

## Testing Strategies

### Unit Testing

```javascript
// Mock Appwrite client for testing
class MockAppwriteClient {
    constructor() {
        this.databases = {
            createDocument: jest.fn().mockResolvedValue({ $id: 'test-id' }),
            listDocuments: jest.fn().mockResolvedValue({ documents: [] }),
            updateDocument: jest.fn().mockResolvedValue({ $id: 'test-id' }),
            deleteDocument: jest.fn().mockResolvedValue({})
        };
    }
}

// Test example
describe('DocumentService', () => {
    let service;
    let mockClient;

    beforeEach(() => {
        mockClient = new MockAppwriteClient();
        service = new DocumentService(mockClient);
    });

    test('should create document', async () => {
        const data = { title: 'Test' };
        const result = await service.create(data);
        
        expect(mockClient.databases.createDocument).toHaveBeenCalledWith(
            expect.any(String),
            expect.any(String),
            expect.any(String),
            data,
            expect.any(Array)
        );
        expect(result.$id).toBe('test-id');
    });
});
```

### Integration Testing

```javascript
// Test against Appwrite test instance
describe('Appwrite Integration', () => {
    let client;
    let testUserId;

    beforeAll(() => {
        client = new Client()
            .setEndpoint(process.env.TEST_ENDPOINT)
            .setProject(process.env.TEST_PROJECT);
    });

    afterEach(async () => {
        // Clean up test data
        if (testUserId) {
            await databases.deleteDocument(
                'test-db',
                'test-collection',
                testUserId
            );
        }
    });

    test('full CRUD cycle', async () => {
        // Create
        const created = await databases.createDocument(...);
        testUserId = created.$id;
        
        // Read
        const read = await databases.getDocument(...);
        expect(read.$id).toBe(testUserId);
        
        // Update
        const updated = await databases.updateDocument(...);
        expect(updated.status).toBe('updated');
        
        // Delete
        await databases.deleteDocument(...);
        testUserId = null;
    });
});
```

## Error Handling

### Comprehensive Error Management

```javascript
class AppwriteService {
    async executeWithRetry(operation, maxRetries = 3) {
        let lastError;
        
        for (let i = 0; i < maxRetries; i++) {
            try {
                return await operation();
            } catch (error) {
                lastError = error;
                
                // Don't retry on client errors
                if (error.code >= 400 && error.code < 500) {
                    throw error;
                }
                
                // Exponential backoff for server errors
                if (error.code >= 500) {
                    const delay = Math.pow(2, i) * 1000;
                    await new Promise(resolve => setTimeout(resolve, delay));
                }
            }
        }
        
        throw lastError;
    }

    async handleDatabaseOperation(operation) {
        try {
            const result = await this.executeWithRetry(operation);
            return { success: true, data: result };
        } catch (error) {
            // Log to monitoring service
            console.error('Database operation failed:', {
                code: error.code,
                message: error.message,
                type: error.type,
                timestamp: new Date().toISOString()
            });
            
            // Return user-friendly error
            return {
                success: false,
                error: this.getUserFriendlyError(error)
            };
        }
    }

    getUserFriendlyError(error) {
        const errorMessages = {
            'user_unauthorized': 'Please log in to continue',
            'document_not_found': 'The requested item was not found',
            'storage_file_not_found': 'File not found',
            'general_rate_limit_exceeded': 'Too many requests. Please try again later',
            'project_unknown': 'Configuration error. Please contact support'
        };
        
        return errorMessages[error.type] || 'An error occurred. Please try again';
    }
}
```

### Monitoring and Logging

```javascript
// Implement logging middleware
class AppwriteLogger {
    static logRequest(service, method, params) {
        console.log({
            timestamp: new Date().toISOString(),
            service,
            method,
            params: this.sanitizeParams(params)
        });
    }

    static logResponse(service, method, response, duration) {
        console.log({
            timestamp: new Date().toISOString(),
            service,
            method,
            success: !!response,
            duration: `${duration}ms`
        });
    }

    static sanitizeParams(params) {
        // Remove sensitive data from logs
        const sanitized = { ...params };
        delete sanitized.password;
        delete sanitized.secret;
        delete sanitized.apiKey;
        return sanitized;
    }
}
```

## Resources

- [Official Documentation](https://appwrite.io/docs)
- [API Reference](https://appwrite.io/docs/references)
- [Discord Community](https://appwrite.io/discord)
- [GitHub Repository](https://github.com/appwrite/appwrite)
- [SDK Libraries](https://github.com/appwrite/sdk-generator)