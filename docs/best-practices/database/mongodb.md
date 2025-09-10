# MongoDB Best Practices

## Official Documentation
- **MongoDB Documentation**: https://docs.mongodb.com/
- **MongoDB University**: https://university.mongodb.com/
- **MongoDB Atlas**: https://www.mongodb.com/atlas
- **MongoDB Compass**: https://www.mongodb.com/products/compass

## Architecture Overview
```
Application Layer
    ↓
MongoDB Driver (mongoose, pymongo, etc.)
    ↓
Connection Pool
    ↓
MongoDB Cluster
├── Primary Node
├── Secondary Nodes
└── Arbiter (optional)
    ↓
Sharded Clusters (optional)
├── Config Servers
├── Query Routers (mongos)
└── Shards
```

## Core Best Practices

### 1. Connection Management

#### Node.js with Mongoose
```javascript
const mongoose = require('mongoose');

// Connection options
const options = {
  maxPoolSize: 10,
  minPoolSize: 2,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  family: 4 // Use IPv4
};

// Connect with retry logic
const connectWithRetry = async () => {
  try {
    await mongoose.connect('mongodb://localhost:27017/myapp', options);
    console.log('MongoDB connected');
  } catch (err) {
    console.error('MongoDB connection error:', err);
    setTimeout(connectWithRetry, 5000);
  }
};

connectWithRetry();

// Connection events
mongoose.connection.on('disconnected', () => {
  console.log('MongoDB disconnected');
});

mongoose.connection.on('error', (err) => {
  console.error('MongoDB error:', err);
});
```

#### Python with PyMongo
```python
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
import time

class MongoDBConnection:
    def __init__(self, uri, database):
        self.uri = uri
        self.database = database
        self.client = None
        self.db = None
        
    def connect(self):
        try:
            self.client = MongoClient(
                self.uri,
                maxPoolSize=50,
                minPoolSize=10,
                serverSelectionTimeoutMS=5000,
                connectTimeoutMS=10000,
                retryWrites=True
            )
            # Test connection
            self.client.admin.command('ping')
            self.db = self.client[self.database]
            print("MongoDB connected successfully")
        except ConnectionFailure as e:
            print(f"Could not connect to MongoDB: {e}")
            raise
            
    def get_collection(self, collection_name):
        return self.db[collection_name]

# Usage
mongo = MongoDBConnection('mongodb://localhost:27017/', 'myapp')
mongo.connect()
```

### 2. Schema Design

#### Mongoose Schema
```javascript
const mongoose = require('mongoose');

// User schema with validation
const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
      message: 'Invalid email format'
    }
  },
  username: {
    type: String,
    required: true,
    unique: true,
    minlength: [3, 'Username must be at least 3 characters'],
    maxlength: [30, 'Username cannot exceed 30 characters']
  },
  profile: {
    firstName: String,
    lastName: String,
    avatar: String,
    bio: {
      type: String,
      maxlength: 500
    },
    dateOfBirth: Date,
    address: {
      street: String,
      city: String,
      state: String,
      country: String,
      zipCode: String
    }
  },
  roles: [{
    type: String,
    enum: ['user', 'admin', 'moderator'],
    default: 'user'
  }],
  preferences: {
    theme: {
      type: String,
      enum: ['light', 'dark'],
      default: 'light'
    },
    notifications: {
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: false }
    }
  },
  stats: {
    loginCount: { type: Number, default: 0 },
    lastLogin: Date,
    totalPurchases: { type: Number, default: 0 }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  metadata: {
    source: String,
    referrer: String,
    campaign: String
  }
}, {
  timestamps: true, // Adds createdAt and updatedAt
  versionKey: false // Disable __v field
});

// Indexes
userSchema.index({ email: 1 });
userSchema.index({ username: 1 });
userSchema.index({ 'profile.firstName': 1, 'profile.lastName': 1 });
userSchema.index({ createdAt: -1 });
userSchema.index({ isActive: 1, createdAt: -1 });

// Virtual properties
userSchema.virtual('fullName').get(function() {
  return `${this.profile.firstName} ${this.profile.lastName}`;
});

// Instance methods
userSchema.methods.incrementLoginCount = async function() {
  this.stats.loginCount += 1;
  this.stats.lastLogin = new Date();
  return this.save();
};

// Static methods
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Pre-save middleware
userSchema.pre('save', function(next) {
  if (this.isModified('email')) {
    this.email = this.email.toLowerCase();
  }
  next();
});

// Post-save middleware
userSchema.post('save', function(doc) {
  console.log(`User ${doc.email} was saved`);
});

const User = mongoose.model('User', userSchema);
```

### 3. Data Relationships

#### Embedding vs Referencing
```javascript
// Embedding - Good for 1:Few relationships
const postSchema = new mongoose.Schema({
  title: String,
  content: String,
  author: {
    id: mongoose.Schema.Types.ObjectId,
    name: String,
    avatar: String
  },
  comments: [{
    user: String,
    text: String,
    createdAt: { type: Date, default: Date.now }
  }],
  tags: [String]
});

// Referencing - Good for 1:Many relationships
const orderSchema = new mongoose.Schema({
  orderNumber: String,
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  items: [{
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product'
    },
    quantity: Number,
    price: Number
  }],
  total: Number,
  status: {
    type: String,
    enum: ['pending', 'processing', 'shipped', 'delivered'],
    default: 'pending'
  }
});

// Hybrid approach
const blogPostSchema = new mongoose.Schema({
  title: String,
  content: String,
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  // Embed frequently accessed data
  authorInfo: {
    name: String,
    avatar: String
  },
  // Reference for large collections
  comments: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Comment'
  }],
  // Embed small, static data
  metadata: {
    views: { type: Number, default: 0 },
    likes: { type: Number, default: 0 },
    readTime: Number
  }
});
```

### 4. Query Optimization

#### Efficient Queries
```javascript
// Use projection to limit returned fields
const users = await User.find(
  { isActive: true },
  { email: 1, username: 1, 'profile.firstName': 1 }
).limit(10);

// Use lean() for read-only operations
const products = await Product.find({ category: 'electronics' })
  .lean()
  .limit(20);

// Populate with specific fields
const orders = await Order.find({ status: 'pending' })
  .populate('customer', 'email username')
  .populate({
    path: 'items.product',
    select: 'name price',
    options: { lean: true }
  });

// Cursor for large datasets
const cursor = User.find({ isActive: true }).cursor();

cursor.on('data', (doc) => {
  // Process each document
  processUser(doc);
});

cursor.on('error', (err) => {
  console.error('Cursor error:', err);
});

cursor.on('end', () => {
  console.log('Processing complete');
});
```

### 5. Aggregation Pipeline
```javascript
// Complex aggregation
const salesReport = await Order.aggregate([
  // Match stage
  {
    $match: {
      status: 'delivered',
      createdAt: {
        $gte: new Date('2024-01-01'),
        $lt: new Date('2025-01-01')
      }
    }
  },
  // Lookup stage (join)
  {
    $lookup: {
      from: 'users',
      localField: 'customer',
      foreignField: '_id',
      as: 'customerInfo'
    }
  },
  // Unwind array
  {
    $unwind: '$customerInfo'
  },
  // Group stage
  {
    $group: {
      _id: {
        month: { $month: '$createdAt' },
        year: { $year: '$createdAt' }
      },
      totalSales: { $sum: '$total' },
      orderCount: { $sum: 1 },
      avgOrderValue: { $avg: '$total' },
      uniqueCustomers: { $addToSet: '$customer' }
    }
  },
  // Project stage
  {
    $project: {
      _id: 0,
      period: {
        $concat: [
          { $toString: '$_id.year' },
          '-',
          { $toString: '$_id.month' }
        ]
      },
      totalSales: { $round: ['$totalSales', 2] },
      orderCount: 1,
      avgOrderValue: { $round: ['$avgOrderValue', 2] },
      customerCount: { $size: '$uniqueCustomers' }
    }
  },
  // Sort stage
  {
    $sort: { period: 1 }
  },
  // Facet for multiple aggregations
  {
    $facet: {
      monthlyStats: [{ $limit: 12 }],
      summary: [
        {
          $group: {
            _id: null,
            totalRevenue: { $sum: '$totalSales' },
            totalOrders: { $sum: '$orderCount' }
          }
        }
      ]
    }
  }
]);
```

### 6. Indexing Strategies
```javascript
// Single field index
db.users.createIndex({ email: 1 });

// Compound index
db.orders.createIndex({ customer: 1, createdAt: -1 });

// Text index for search
db.products.createIndex({ 
  name: 'text', 
  description: 'text' 
});

// 2dsphere index for geospatial
db.locations.createIndex({ coordinates: '2dsphere' });

// TTL index for automatic deletion
db.sessions.createIndex(
  { createdAt: 1 },
  { expireAfterSeconds: 3600 }
);

// Partial index
db.users.createIndex(
  { email: 1 },
  { 
    partialFilterExpression: { 
      isActive: true 
    } 
  }
);

// Unique index
db.users.createIndex(
  { username: 1 },
  { unique: true }
);

// Index management
async function analyzeIndexes() {
  // Get all indexes
  const indexes = await db.users.getIndexes();
  
  // Index statistics
  const stats = await db.users.aggregate([
    { $indexStats: {} }
  ]).toArray();
  
  // Find unused indexes
  const unused = stats.filter(idx => 
    idx.accesses.ops === 0 && 
    idx.name !== '_id_'
  );
  
  return { indexes, stats, unused };
}
```

### 7. Transactions
```javascript
// Multi-document transaction
async function transferFunds(fromAccount, toAccount, amount) {
  const session = await mongoose.startSession();
  
  try {
    await session.withTransaction(async () => {
      // Debit from account
      const sender = await Account.findById(fromAccount).session(session);
      if (sender.balance < amount) {
        throw new Error('Insufficient funds');
      }
      sender.balance -= amount;
      await sender.save({ session });
      
      // Credit to account
      const receiver = await Account.findById(toAccount).session(session);
      receiver.balance += amount;
      await receiver.save({ session });
      
      // Create transaction record
      await Transaction.create([{
        from: fromAccount,
        to: toAccount,
        amount: amount,
        type: 'transfer',
        status: 'completed'
      }], { session });
    });
    
    console.log('Transfer successful');
  } catch (error) {
    console.error('Transfer failed:', error);
    throw error;
  } finally {
    await session.endSession();
  }
}
```

### 8. Change Streams
```javascript
// Watch for changes
async function watchCollection() {
  const changeStream = User.watch(
    [
      { $match: { 
        'fullDocument.isActive': true,
        operationType: { $in: ['insert', 'update'] }
      }}
    ],
    { fullDocument: 'updateLookup' }
  );
  
  changeStream.on('change', (change) => {
    console.log('Change detected:', change);
    
    switch(change.operationType) {
      case 'insert':
        handleNewUser(change.fullDocument);
        break;
      case 'update':
        handleUserUpdate(change.fullDocument);
        break;
      case 'delete':
        handleUserDeletion(change.documentKey._id);
        break;
    }
  });
  
  changeStream.on('error', (error) => {
    console.error('Change stream error:', error);
  });
}
```

## Advanced Patterns

### 1. Sharding
```javascript
// Enable sharding on database
sh.enableSharding("myapp");

// Shard collection with hashed key
sh.shardCollection("myapp.users", { _id: "hashed" });

// Shard with compound key
sh.shardCollection("myapp.orders", { 
  customerId: 1, 
  createdAt: 1 
});

// Add shard tags for zone sharding
sh.addShardTag("shard0", "US");
sh.addShardTag("shard1", "EU");
sh.addShardTag("shard2", "ASIA");

// Define tag ranges
sh.addTagRange("myapp.users", 
  { region: "US" }, 
  { region: "US\uffff" }, 
  "US"
);
```

### 2. GridFS for Large Files
```javascript
const multer = require('multer');
const GridFSBucket = require('mongodb').GridFSBucket;

// Initialize GridFS
const bucket = new GridFSBucket(mongoose.connection.db, {
  bucketName: 'uploads'
});

// Upload file
async function uploadFile(file) {
  const uploadStream = bucket.openUploadStream(file.originalname, {
    metadata: {
      userId: req.user._id,
      uploadDate: new Date()
    }
  });
  
  return new Promise((resolve, reject) => {
    uploadStream.on('finish', resolve);
    uploadStream.on('error', reject);
    file.stream.pipe(uploadStream);
  });
}

// Download file
async function downloadFile(fileId, res) {
  const downloadStream = bucket.openDownloadStream(fileId);
  downloadStream.pipe(res);
}

// Delete file
async function deleteFile(fileId) {
  await bucket.delete(fileId);
}
```

### 3. Caching with Redis
```javascript
const redis = require('redis');
const client = redis.createClient();

// Cache wrapper
async function cachedQuery(key, queryFn, ttl = 3600) {
  // Check cache
  const cached = await client.get(key);
  if (cached) {
    return JSON.parse(cached);
  }
  
  // Execute query
  const result = await queryFn();
  
  // Store in cache
  await client.setex(key, ttl, JSON.stringify(result));
  
  return result;
}

// Usage
const products = await cachedQuery(
  'products:electronics',
  () => Product.find({ category: 'electronics' }).lean(),
  1800
);
```

### 4. Bulk Operations
```javascript
// Bulk write operations
async function bulkUpdate(updates) {
  const bulkOps = updates.map(update => ({
    updateOne: {
      filter: { _id: update.id },
      update: { $set: update.data },
      upsert: true
    }
  }));
  
  const result = await User.bulkWrite(bulkOps, {
    ordered: false // Continue on error
  });
  
  console.log(`Modified: ${result.modifiedCount}`);
  console.log(`Upserted: ${result.upsertedCount}`);
}

// Bulk insert with validation
async function bulkInsert(documents) {
  try {
    const result = await User.insertMany(documents, {
      ordered: false,
      rawResult: true
    });
    
    return {
      inserted: result.insertedCount,
      errors: result.writeErrors
    };
  } catch (error) {
    if (error.code === 11000) {
      console.error('Duplicate key errors:', error.writeErrors);
    }
    throw error;
  }
}
```

## Performance Optimization

### 1. Query Performance
```javascript
// Explain query execution
const explanation = await User.find({ age: { $gte: 18 } })
  .explain('executionStats');

console.log('Documents examined:', explanation.executionStats.totalDocsExamined);
console.log('Execution time:', explanation.executionStats.executionTimeMillis);

// Use hint to force index
const users = await User.find({ email: 'test@example.com' })
  .hint({ email: 1 });

// Covered queries (all fields in index)
const emails = await User.find(
  { isActive: true },
  { email: 1, _id: 0 }
).hint({ isActive: 1, email: 1 });
```

### 2. Connection Pooling
```javascript
// Optimal connection pool settings
const options = {
  maxPoolSize: 100,        // Maximum connections
  minPoolSize: 10,         // Minimum connections
  maxIdleTimeMS: 30000,    // Close idle connections after 30s
  waitQueueTimeoutMS: 5000 // Timeout waiting for connection
};

// Monitor connection pool
mongoose.connection.on('connected', () => {
  const poolSize = mongoose.connection.db.serverConfig.connections().length;
  console.log(`Connection pool size: ${poolSize}`);
});
```

### 3. Memory Management
```javascript
// Use cursor for large datasets
async function processLargeCollection() {
  const cursor = User.find({}).cursor();
  
  for (let doc = await cursor.next(); doc != null; doc = await cursor.next()) {
    await processDocument(doc);
    
    // Manual garbage collection hint
    if (global.gc && Math.random() < 0.01) {
      global.gc();
    }
  }
}

// Stream processing
const stream = User.find({}).stream();

stream.on('data', (doc) => {
  // Process document
  processDocument(doc);
});

stream.on('error', (err) => {
  console.error('Stream error:', err);
});

stream.on('close', () => {
  console.log('Stream closed');
});
```

## Security Best Practices

### 1. Authentication and Authorization
```javascript
// Connection with authentication
const uri = 'mongodb://username:password@localhost:27017/myapp?authSource=admin';

// Role-based access
async function createRestrictedUser() {
  await db.createUser({
    user: 'app_user',
    pwd: 'secure_password',
    roles: [
      { role: 'readWrite', db: 'myapp' },
      { role: 'read', db: 'analytics' }
    ]
  });
}

// Field-level security with Mongoose
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  delete obj.ssn;
  delete obj.creditCard;
  return obj;
};
```

### 2. Input Validation
```javascript
// Sanitize user input
const sanitize = require('mongo-sanitize');

app.post('/search', (req, res) => {
  const query = sanitize(req.body.query);
  
  User.find({
    $or: [
      { username: new RegExp(query, 'i') },
      { email: new RegExp(query, 'i') }
    ]
  });
});

// Prevent NoSQL injection
const username = req.body.username.replace(/[^\w\s]/gi, '');
const user = await User.findOne({ username });
```

## Monitoring and Maintenance

### 1. Performance Monitoring
```javascript
// Database statistics
const stats = await db.stats();
console.log('Database size:', stats.dataSize);
console.log('Index size:', stats.indexSize);

// Collection statistics
const collStats = await db.collection('users').stats();
console.log('Document count:', collStats.count);
console.log('Average document size:', collStats.avgObjSize);

// Current operations
const currentOps = await db.admin().currentOp();
const slowOps = currentOps.inprog.filter(op => 
  op.secs_running > 5
);
```

### 2. Backup and Restore
```bash
# Backup database
mongodump --db myapp --out /backup/$(date +%Y%m%d)

# Backup with compression
mongodump --db myapp --gzip --archive=/backup/myapp.gz

# Restore database
mongorestore --db myapp /backup/20240101/myapp

# Point-in-time restore with oplog
mongodump --oplog --out /backup/full
mongorestore --oplogReplay /backup/full
```

## Common Pitfalls to Avoid

1. **Not Using Indexes**: Always index frequently queried fields
2. **Over-embedding**: Don't embed large arrays that grow unbounded
3. **Not Using Projection**: Select only needed fields
4. **Ignoring Write Concern**: Set appropriate write concern for critical data
5. **Schema-less Chaos**: Define and validate schemas
6. **Not Monitoring**: Track slow queries and performance metrics
7. **Large Documents**: Keep documents under 16MB limit
8. **Not Using Aggregation**: Use aggregation pipeline for complex queries
9. **Ignoring Sharding**: Plan for sharding early for large datasets
10. **Not Handling Errors**: Implement proper error handling and retries

## Useful Tools and Libraries

- **Mongoose**: Elegant MongoDB object modeling for Node.js
- **PyMongo**: Python driver for MongoDB
- **MongoDB Compass**: GUI for MongoDB
- **Robo 3T**: MongoDB GUI tool
- **mongo-express**: Web-based MongoDB admin interface
- **mongodb-memory-server**: In-memory MongoDB for testing
- **mongoose-paginate-v2**: Pagination plugin for Mongoose
- **mongoose-unique-validator**: Unique validation plugin
- **mongoose-autopopulate**: Automatic population plugin
- **mongodb-backup**: Backup utility