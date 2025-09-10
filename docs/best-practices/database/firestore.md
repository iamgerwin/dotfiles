# Firestore Best Practices

## Overview

Cloud Firestore is a flexible, scalable NoSQL cloud database from Firebase and Google Cloud Platform. It provides real-time synchronization, offline support, and automatic scaling.

## Data Modeling

### Document Structure
```javascript
// ✅ Good - Denormalized for read performance
{
  userId: "user123",
  userName: "John Doe",  // Denormalized
  userAvatar: "url",     // Denormalized
  content: "Post content",
  createdAt: serverTimestamp(),
  tags: ["tech", "web"],
  likeCount: 42,
  commentCount: 5
}

// ❌ Bad - Requiring multiple reads
{
  userId: "user123",  // Need additional read to get user info
  content: "Post content",
  createdAt: serverTimestamp()
}
```

### Collection Design
```javascript
// ✅ Good - Flat structure with subcollections
/users/{userId}
/users/{userId}/posts/{postId}
/users/{userId}/followers/{followerId}

// ❌ Bad - Deeply nested
/users/{userId}/posts/{postId}/comments/{commentId}/replies/{replyId}
```

### Data Types and Limits
```javascript
// Document size limit: 1 MiB
// Collection/Document ID: 1,500 bytes
// Maximum depth of subcollections: 100

// ✅ Good - Store large data separately
const post = {
  title: "My Post",
  summary: "Short summary",
  imageUrl: "https://storage.googleapis.com/...", // Store in Cloud Storage
  contentUrl: "https://storage.googleapis.com/..." // Large content in Storage
};

// ❌ Bad - Storing large data in document
const post = {
  title: "My Post",
  content: "Very large HTML content...", // Can exceed 1 MiB
  base64Image: "data:image/png;base64..." // Large binary data
};
```

## Querying Strategies

### Compound Queries
```javascript
// Create composite indexes for complex queries
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}

// Query implementation
const userPosts = await db.collection('posts')
  .where('userId', '==', userId)
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get();
```

### Pagination
```javascript
// ✅ Good - Cursor-based pagination
let query = db.collection('posts')
  .orderBy('createdAt', 'desc')
  .limit(10);

// First page
const firstPage = await query.get();
const lastDoc = firstPage.docs[firstPage.docs.length - 1];

// Next page
if (lastDoc) {
  const nextPage = await query
    .startAfter(lastDoc)
    .get();
}

// ❌ Bad - Offset pagination (inefficient)
const page2 = await db.collection('posts')
  .orderBy('createdAt', 'desc')
  .offset(10)  // Charged for skipped documents
  .limit(10)
  .get();
```

### Array Operations
```javascript
// ✅ Good - Array operators
await db.collection('posts').doc(postId).update({
  tags: firebase.firestore.FieldValue.arrayUnion('newTag'),
  likes: firebase.firestore.FieldValue.arrayRemove(userId)
});

// Query array fields
const taggedPosts = await db.collection('posts')
  .where('tags', 'array-contains', 'javascript')
  .get();

// Query multiple array values
const multiTagPosts = await db.collection('posts')
  .where('tags', 'array-contains-any', ['javascript', 'typescript'])
  .limit(10)
  .get();
```

## Real-time Updates

### Listeners
```javascript
// ✅ Good - Unsubscribe when done
class PostList {
  constructor() {
    this.unsubscribe = null;
  }

  startListening(userId) {
    this.unsubscribe = db.collection('posts')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(50)
      .onSnapshot(
        (snapshot) => {
          snapshot.docChanges().forEach((change) => {
            if (change.type === 'added') {
              this.addPost(change.doc.data());
            } else if (change.type === 'modified') {
              this.updatePost(change.doc.data());
            } else if (change.type === 'removed') {
              this.removePost(change.doc.id);
            }
          });
        },
        (error) => {
          console.error('Listener error:', error);
          this.handleListenerError(error);
        }
      );
  }

  stopListening() {
    if (this.unsubscribe) {
      this.unsubscribe();
      this.unsubscribe = null;
    }
  }
}
```

### Optimistic Updates
```javascript
// ✅ Good - Optimistic UI updates
async function likePost(postId, userId) {
  // Update UI immediately
  updateUIOptimistically(postId, 'liked');
  
  try {
    await db.collection('posts').doc(postId).update({
      likes: firebase.firestore.FieldValue.arrayUnion(userId),
      likeCount: firebase.firestore.FieldValue.increment(1)
    });
  } catch (error) {
    // Revert UI on error
    revertUIUpdate(postId, 'liked');
    throw error;
  }
}
```

## Offline Support

### Enable Offline Persistence
```javascript
// Web
firebase.firestore().enablePersistence()
  .catch((err) => {
    if (err.code === 'failed-precondition') {
      // Multiple tabs open
      console.log('Persistence failed: Multiple tabs open');
    } else if (err.code === 'unimplemented') {
      // Browser doesn't support
      console.log('Persistence not available');
    }
  });

// React Native / Mobile
firebase.firestore().settings({
  persistence: true,
  cacheSizeBytes: firebase.firestore.CACHE_SIZE_UNLIMITED
});
```

### Handle Offline State
```javascript
// Check if data is from cache
const snapshot = await db.collection('posts').get();

snapshot.docs.forEach((doc) => {
  const source = doc.metadata.fromCache ? 'cache' : 'server';
  console.log(`Data from ${source}:`, doc.data());
});

// Listen for metadata changes
const unsubscribe = db.collection('posts')
  .onSnapshot({ includeMetadataChanges: true }, (snapshot) => {
    snapshot.docs.forEach((doc) => {
      if (!doc.metadata.fromCache) {
        // Data is confirmed from server
        markAsSynced(doc.id);
      }
    });
  });
```

## Security Rules

### Basic Security
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isValidPost() {
      return request.resource.data.keys().hasAll(['title', 'content', 'userId']) &&
             request.resource.data.title is string &&
             request.resource.data.title.size() <= 200 &&
             request.resource.data.content is string &&
             request.resource.data.content.size() <= 5000;
    }
    
    // User documents
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }
    
    // Posts
    match /posts/{postId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && 
                       request.resource.data.userId == request.auth.uid &&
                       isValidPost();
      allow update: if isSignedIn() && 
                       resource.data.userId == request.auth.uid &&
                       isValidPost();
      allow delete: if isSignedIn() && 
                       resource.data.userId == request.auth.uid;
    }
  }
}
```

### Advanced Security Patterns
```javascript
// Rate limiting with security rules
match /comments/{comment} {
  allow create: if isSignedIn() &&
    // Limit to 10 comments per minute
    request.time > resource.data.lastCommentTime + duration.value(1, 'm');
}

// Validate data consistency
match /transfers/{transfer} {
  allow create: if isSignedIn() &&
    // Ensure amount matches sum of items
    request.resource.data.amount == 
    request.resource.data.items.reduce((sum, item) => sum + item.price, 0);
}

// Role-based access
match /admin/{document=**} {
  allow read, write: if isSignedIn() &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

## Performance Optimization

### Batch Operations
```javascript
// ✅ Good - Batch writes (up to 500 operations)
const batch = db.batch();

posts.forEach((post) => {
  const docRef = db.collection('posts').doc();
  batch.set(docRef, post);
});

await batch.commit();

// ✅ Good - Batch reads with Promise.all
const postIds = ['post1', 'post2', 'post3'];
const posts = await Promise.all(
  postIds.map(id => db.collection('posts').doc(id).get())
);
```

### Transactions
```javascript
// ✅ Good - Atomic operations
async function transferCredits(fromUserId, toUserId, amount) {
  return db.runTransaction(async (transaction) => {
    const fromDoc = await transaction.get(
      db.collection('users').doc(fromUserId)
    );
    const toDoc = await transaction.get(
      db.collection('users').doc(toUserId)
    );
    
    const fromCredits = fromDoc.data().credits;
    if (fromCredits < amount) {
      throw new Error('Insufficient credits');
    }
    
    transaction.update(fromDoc.ref, {
      credits: fromCredits - amount
    });
    
    transaction.update(toDoc.ref, {
      credits: toDoc.data().credits + amount
    });
    
    // Add transfer record
    transaction.set(db.collection('transfers').doc(), {
      from: fromUserId,
      to: toUserId,
      amount: amount,
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
  });
}
```

### Aggregation Strategies
```javascript
// ✅ Good - Distributed counters for high-frequency updates
class DistributedCounter {
  constructor(db, path, numShards = 10) {
    this.db = db;
    this.path = path;
    this.numShards = numShards;
  }
  
  async increment(amount = 1) {
    const shardId = Math.floor(Math.random() * this.numShards);
    const shardRef = this.db.collection(this.path)
      .doc(shardId.toString());
    
    return shardRef.update({
      count: firebase.firestore.FieldValue.increment(amount)
    });
  }
  
  async getTotal() {
    const shards = await this.db.collection(this.path).get();
    let total = 0;
    shards.forEach((shard) => {
      total += shard.data().count || 0;
    });
    return total;
  }
}

// ✅ Good - Maintain aggregates
const postRef = db.collection('posts').doc(postId);
const statsRef = db.collection('stats').doc('posts');

await db.runTransaction(async (transaction) => {
  transaction.set(postRef, postData);
  transaction.update(statsRef, {
    totalPosts: firebase.firestore.FieldValue.increment(1),
    lastUpdated: firebase.firestore.FieldValue.serverTim