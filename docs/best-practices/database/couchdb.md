# CouchDB Best Practices

## Official Documentation
- **CouchDB Documentation**: https://docs.couchdb.org/
- **CouchDB Guide**: https://guide.couchdb.org/
- **CouchDB Wiki**: https://cwiki.apache.org/confluence/display/COUCHDB/
- **Fauxton UI**: https://couchdb.apache.org/fauxton-visual-guide/

## Architecture Overview
```
Application Layer
    ↓
HTTP/REST API
    ↓
CouchDB Cluster
├── Node 1
│   ├── Shards
│   └── Replicas
├── Node 2
│   ├── Shards
│   └── Replicas
└── Node 3
    ├── Shards
    └── Replicas
```

## Core Best Practices

### 1. Database Design
```javascript
// Document structure - denormalized approach
{
  "_id": "user:john@example.com",
  "_rev": "1-25ef4c2f7e3d8f3a1e6b4d9c2a1b3c4d",
  "type": "user",
  "name": "John Doe",
  "email": "john@example.com",
  "profile": {
    "age": 30,
    "location": "New York"
  },
  "addresses": [
    {
      "type": "home",
      "street": "123 Main St",
      "city": "New York",
      "zip": "10001"
    }
  ],
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}

// Use type field for document classification
{
  "_id": "order:2024:001234",
  "type": "order",
  "customer_id": "user:john@example.com",
  "items": [
    {
      "product_id": "product:ABC123",
      "name": "Widget",
      "quantity": 2,
      "price": 29.99
    }
  ],
  "total": 59.98,
  "status": "pending"
}
```

### 2. Connection Management

#### Node.js with nano
```javascript
const nano = require('nano');

// Basic connection
const couch = nano('http://admin:password@localhost:5984');

// With configuration
const couch = nano({
  url: 'http://localhost:5984',
  requestDefaults: {
    auth: {
      username: 'admin',
      password: 'password'
    },
    timeout: 30000,
    pool: {
      maxSockets: 50
    }
  }
});

// Database instance
const db = couch.db.use('myapp');

// With promises
async function getDocument(id) {
  try {
    const doc = await db.get(id);
    return doc;
  } catch (err) {
    console.error('Error fetching document:', err);
    throw err;
  }
}
```

#### Python with couchdb
```python
import couchdb
from couchdb import Server

# Connect to server
couch = Server('http://admin:password@localhost:5984/')

# Create or get database
try:
    db = couch.create('myapp')
except couchdb.http.PreconditionFailed:
    db = couch['myapp']

# Document operations
doc = {
    '_id': 'user:123',
    'type': 'user',
    'name': 'John Doe',
    'email': 'john@example.com'
}

# Save document
db.save(doc)

# Get document
user = db['user:123']
```

### 3. Document ID Strategies
```javascript
// Hierarchical IDs for sorting
const userId = 'user:2024:01:15:john@example.com';
const orderId = 'order:2024:01:15:0001234';
const productId = 'product:electronics:laptop:dell-xps-13';

// UUID for random distribution
const uuid = require('uuid');
const docId = uuid.v4();

// Composite keys for relationships
const reviewId = `review:${productId}:${userId}`;
const voteId = `vote:${postId}:${userId}`;

// Time-based IDs for chronological ordering
const eventId = `event:${Date.now()}:${eventType}`;
```

### 4. Views and Indexes

#### Map/Reduce Views
```javascript
// Design document with views
{
  "_id": "_design/users",
  "views": {
    "by_email": {
      "map": "function(doc) { if(doc.type === 'user' && doc.email) { emit(doc.email, null); } }"
    },
    "by_age": {
      "map": "function(doc) { if(doc.type === 'user' && doc.profile && doc.profile.age) { emit(doc.profile.age, 1); } }",
      "reduce": "_sum"
    },
    "active_users": {
      "map": "function(doc) { if(doc.type === 'user' && doc.status === 'active') { emit(doc.created_at, doc); } }"
    }
  }
}

// Query views
async function getUserByEmail(email) {
  const result = await db.view('users', 'by_email', {
    key: email,
    include_docs: true
  });
  return result.rows[0]?.doc;
}

// Query with options
const users = await db.view('users', 'by_age', {
  startkey: 25,
  endkey: 35,
  inclusive_end: true,
  include_docs: true,
  limit: 10,
  skip: 0
});
```

#### Mango Queries (CouchDB 2.0+)
```javascript
// Create index
await db.createIndex({
  index: {
    fields: ['type', 'status', 'created_at']
  },
  name: 'type-status-date-index'
});

// Query with Mango
const result = await db.find({
  selector: {
    type: 'order',
    status: 'pending',
    created_at: {
      $gte: '2024-01-01'
    }
  },
  fields: ['_id', 'customer_id', 'total'],
  sort: [{ created_at: 'desc' }],
  limit: 20
});

// Complex queries
const orders = await db.find({
  selector: {
    $and: [
      { type: 'order' },
      { status: { $in: ['pending', 'processing'] } },
      { total: { $gte: 100 } },
      {
        $or: [
          { priority: 'high' },
          { customer_type: 'premium' }
        ]
      }
    ]
  }
});
```

### 5. Bulk Operations
```javascript
// Bulk insert
async function bulkInsert(documents) {
  const docs = documents.map(doc => ({
    ...doc,
    _id: doc._id || uuid.v4(),
    created_at: new Date().toISOString()
  }));

  const result = await db.bulk({ docs });
  
  // Handle conflicts
  const conflicts = result.filter(r => r.error);
  if (conflicts.length > 0) {
    console.error('Conflicts:', conflicts);
  }
  
  return result;
}

// Bulk update
async function bulkUpdate(updates) {
  // Fetch current documents
  const keys = updates.map(u => u._id);
  const { rows } = await db.fetch({ keys });
  
  // Merge updates
  const docs = rows.map((row, index) => ({
    ...row.doc,
    ...updates[index],
    _rev: row.doc._rev,
    updated_at: new Date().toISOString()
  }));
  
  return await db.bulk({ docs });
}
```

### 6. Attachments
```javascript
// Add attachment
async function addAttachment(docId, attachmentName, data, contentType) {
  const doc = await db.get(docId);
  
  return await db.attachment.insert(
    docId,
    attachmentName,
    data,
    contentType,
    { rev: doc._rev }
  );
}

// Get attachment
async function getAttachment(docId, attachmentName) {
  return await db.attachment.get(docId, attachmentName);
}

// Inline attachments
const docWithAttachment = {
  _id: 'product:123',
  type: 'product',
  name: 'Widget',
  _attachments: {
    'thumbnail.jpg': {
      content_type: 'image/jpeg',
      data: Buffer.from(imageData).toString('base64')
    }
  }
};
```

### 7. Replication and Sync
```javascript
// One-time replication
async function replicate(source, target, options = {}) {
  return await nano.db.replicate(source, target, {
    create_target: true,
    continuous: false,
    ...options
  });
}

// Continuous replication
async function setupContinuousReplication() {
  const replication = await nano.db.replicate('myapp', 'myapp_backup', {
    continuous: true,
    create_target: true,
    filter: 'app/important_docs',
    query_params: { type: 'user' }
  });
  
  return replication.id;
}

// Filtered replication
{
  "_id": "_design/app",
  "filters": {
    "important_docs": "function(doc, req) { return doc.type === 'user' || doc.type === 'order'; }",
    "by_user": "function(doc, req) { return doc.user_id === req.query.user_id; }"
  }
}

// PouchDB sync (client-side)
const PouchDB = require('pouchdb');
const localDB = new PouchDB('myapp');
const remoteDB = new PouchDB('http://localhost:5984/myapp');

// Bidirectional sync
localDB.sync(remoteDB, {
  live: true,
  retry: true
}).on('change', (info) => {
  console.log('Sync change:', info);
}).on('error', (err) => {
  console.error('Sync error:', err);
});
```

## Advanced Patterns

### 1. Change Feeds
```javascript
// Listen to changes
async function watchChanges() {
  const feed = db.follow({
    since: 'now',
    include_docs: true,
    filter: (doc) => doc.type === 'order'
  });

  feed.on('change', (change) => {
    console.log('Document changed:', change.doc);
    processChange(change.doc);
  });

  feed.on('error', (err) => {
    console.error('Change feed error:', err);
    feed.stop();
  });

  feed.follow();
}

// Changes with last sequence
async function getChangesSince(since = '0') {
  const changes = await db.changes({
    since,
    include_docs: true,
    limit: 100
  });
  
  // Process changes
  for (const change of changes.results) {
    await processChange(change.doc);
  }
  
  // Save last sequence for next poll
  return changes.last_seq;
}
```

### 2. Conflict Resolution
```javascript
// Get document with conflicts
async function getWithConflicts(docId) {
  return await db.get(docId, {
    conflicts: true,
    revs_info: true
  });
}

// Resolve conflicts
async function resolveConflicts(docId) {
  const doc = await getWithConflicts(docId);
  
  if (!doc._conflicts || doc._conflicts.length === 0) {
    return doc;
  }
  
  // Get all conflicting versions
  const conflicts = await Promise.all(
    doc._conflicts.map(rev => 
      db.get(docId, { rev })
    )
  );
  
  // Merge strategy (latest wins, merge fields, etc.)
  const merged = mergeDocuments(doc, conflicts);
  
  // Delete conflicting revisions
  const bulkDocs = doc._conflicts.map(rev => ({
    _id: docId,
    _rev: rev,
    _deleted: true
  }));
  
  // Save merged version and delete conflicts
  bulkDocs.push(merged);
  await db.bulk({ docs: bulkDocs });
  
  return merged;
}

function mergeDocuments(winner, conflicts) {
  // Custom merge logic
  const merged = { ...winner };
  
  conflicts.forEach(conflict => {
    // Example: Keep the latest updated_at
    if (conflict.updated_at > merged.updated_at) {
      merged.updated_at = conflict.updated_at;
      // Merge other fields as needed
    }
  });
  
  delete merged._conflicts;
  return merged;
}
```

### 3. Pagination
```javascript
// Efficient pagination with bookmarks
async function paginate(options = {}) {
  const {
    limit = 10,
    bookmark = null,
    selector = { type: 'product' }
  } = options;
  
  const query = {
    selector,
    limit,
    sort: [{ created_at: 'desc' }]
  };
  
  if (bookmark) {
    query.bookmark = bookmark;
  }
  
  const result = await db.find(query);
  
  return {
    docs: result.docs,
    bookmark: result.bookmark,
    hasMore: result.docs.length === limit
  };
}

// View-based pagination
async function paginateView(viewName, options = {}) {
  const {
    limit = 10,
    skip = 0,
    startkey = null,
    startkey_docid = null
  } = options;
  
  const params = {
    limit: limit + 1,  // Fetch one extra to check if more exist
    include_docs: true
  };
  
  if (startkey !== null) {
    params.startkey = startkey;
    if (startkey_docid) {
      params.startkey_docid = startkey_docid;
    }
  } else if (skip > 0) {
    params.skip = skip;
  }
  
  const result = await db.view('design', viewName, params);
  
  const hasMore = result.rows.length > limit;
  const docs = result.rows.slice(0, limit);
  
  return {
    docs: docs.map(row => row.doc),
    hasMore,
    nextKey: hasMore ? docs[docs.length - 1].key : null,
    nextId: hasMore ? docs[docs.length - 1].id : null
  };
}
```

### 4. Full-Text Search
```javascript
// Create search index (requires search plugin)
{
  "_id": "_design/search",
  "indexes": {
    "products": {
      "analyzer": "standard",
      "index": "function(doc) { if(doc.type === 'product') { index('name', doc.name); index('description', doc.description); index('category', doc.category); } }"
    }
  }
}

// Search documents
async function searchProducts(query) {
  const result = await db.search('search', 'products', {
    q: query,
    include_docs: true,
    limit: 20,
    highlights: {
      pre_tag: '<mark>',
      post_tag: '</mark>',
      fields: ['name', 'description']
    }
  });
  
  return result.rows.map(row => ({
    ...row.doc,
    highlights: row.highlights
  }));
}
```

## Performance Optimization

### 1. View Optimization
```javascript
// Use built-in reduces when possible
{
  "views": {
    "count_by_type": {
      "map": "function(doc) { emit(doc.type, 1); }",
      "reduce": "_count"  // Built-in, faster than custom
    },
    "sum_by_category": {
      "map": "function(doc) { if(doc.type === 'order') emit(doc.category, doc.total); }",
      "reduce": "_sum"
    },
    "stats_by_month": {
      "map": "function(doc) { if(doc.type === 'sale') emit(doc.month, doc.amount); }",
      "reduce": "_stats"  // Returns sum, count, min, max, sumsqr
    }
  }
}

// Emit only necessary data
// Bad: emit(doc.email, doc);  // Entire document
// Good: emit(doc.email, null);  // Use include_docs instead
```

### 2. Database Sharding
```javascript
// Configure sharding (cluster setup)
async function createShardedDatabase(dbName, options = {}) {
  const {
    n = 3,  // Number of replicas
    q = 8,  // Number of shards
    partitioned = false
  } = options;
  
  return await couch.db.create(dbName, {
    n,
    q,
    partitioned
  });
}

// Partitioned database for better performance
async function createPartitionedDB() {
  await createShardedDatabase('orders', {
    partitioned: true,
    q: 16
  });
  
  // Documents must include partition key
  const doc = {
    _id: 'customer123:order456',  // partition:docid
    type: 'order',
    // ... other fields
  };
}
```

### 3. Caching Strategies
```javascript
// ETag-based caching
async function getWithCache(docId) {
  const cached = cache.get(docId);
  
  try {
    const headers = cached ? { 'If-None-Match': cached.etag } : {};
    const response = await db.get(docId, { headers });
    
    // Update cache
    cache.set(docId, {
      doc: response,
      etag: response._rev
    });
    
    return response;
  } catch (err) {
    if (err.statusCode === 304) {
      // Not modified, return cached
      return cached.doc;
    }
    throw err;
  }
}
```

## Security Best Practices

### 1. Authentication and Authorization
```javascript
// User management
async function createUser(username, password, roles = []) {
  const usersDb = couch.db.use('_users');
  
  const user = {
    _id: `org.couchdb.user:${username}`,
    name: username,
    password: password,
    roles: roles,
    type: 'user'
  };
  
  return await usersDb.insert(user);
}

// Database permissions
async function setDatabaseSecurity(dbName, admins = [], members = []) {
  const db = couch.db.use(dbName);
  
  return await db.insert({
    admins: {
      names: admins,
      roles: ['admin']
    },
    members: {
      names: members,
      roles: ['user']
    }
  }, '_security');
}
```

### 2. Validate Document Updates
```javascript
// Validation function
{
  "_id": "_design/validation",
  "validate_doc_update": `
    function(newDoc, oldDoc, userCtx, secObj) {
      // Require authentication
      if (!userCtx.name) {
        throw({ forbidden: 'Authentication required' });
      }
      
      // Check document type
      if (!newDoc.type) {
        throw({ forbidden: 'Document must have a type' });
      }
      
      // Validate based on type
      if (newDoc.type === 'user') {
        if (!newDoc.email || !newDoc.email.match(/^[^@]+@[^@]+$/)) {
          throw({ forbidden: 'Valid email required' });
        }
      }
      
      // Prevent unauthorized updates
      if (oldDoc && oldDoc.owner !== userCtx.name && userCtx.roles.indexOf('admin') === -1) {
        throw({ forbidden: 'Only owner or admin can update' });
      }
    }
  `
}
```

## Monitoring and Maintenance

### 1. Database Statistics
```javascript
async function getDatabaseStats(dbName) {
  const info = await couch.db.get(dbName);
  
  return {
    doc_count: info.doc_count,
    deleted_doc_count: info.doc_del_count,
    disk_size: info.disk_size,
    data_size: info.data_size,
    compact_running: info.compact_running,
    cluster: info.cluster
  };
}

// Monitor replication
async function getReplicationStatus() {
  const activeTasks = await couch.request({
    path: '_active_tasks'
  });
  
  return activeTasks.filter(task => task.type === 'replication');
}
```

### 2. Compaction
```javascript
// Compact database
async function compactDatabase(dbName) {
  const db = couch.db.use(dbName);
  await db.compact();
  
  // Compact views
  const designDocs = await db.list({
    startkey: '_design/',
    endkey: '_design0'
  });
  
  for (const row of designDocs.rows) {
    const designName = row.id.replace('_design/', '');
    await db.compact(designName);
  }
}

// Auto-compaction settings (in config)
{
  "compactions": {
    "_default": "[{db_fragmentation, \"70%\"}, {view_fragmentation, \"60%\"}]"
  }
}
```

## Common Pitfalls to Avoid

1. **Not Using Bulk Operations**: Use bulk APIs for multiple documents
2. **Inefficient Views**: Avoid emitting entire documents in views
3. **Missing Indexes**: Create appropriate indexes for Mango queries
4. **Ignoring Conflicts**: Implement conflict resolution strategies
5. **Not Compacting**: Regular compaction prevents disk bloat
6. **Large Attachments**: Consider external storage for large files
7. **Polling Changes**: Use continuous changes feed instead
8. **Not Setting Limits**: Always limit query results
9. **Ignoring Replication Lag**: Monitor replication status
10. **Missing Validation**: Implement validate_doc_update functions

## Useful Tools and Libraries

- **nano**: Node.js CouchDB client
- **PouchDB**: JavaScript database that syncs with CouchDB
- **couchdb-python**: Python CouchDB client
- **Fauxton**: Web-based CouchDB admin interface
- **couchdb-dump**: Backup and restore tool
- **couchdb-bootstrap**: Database initialization tool
- **couchdb-push**: Deploy design documents
- **couchdb-compile**: Compile design documents from files
- **erica**: CouchApp deployment tool