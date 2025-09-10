# Firebase Best Practices

## Overview
Firebase is Google's comprehensive app development platform providing backend services, hosting, and real-time databases. These best practices ensure scalable, secure, and efficient Firebase applications.

## Project Structure

### Organized Firebase Project
```
project/
├── firebase.json
├── .firebaserc
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── functions/
│   ├── src/
│   │   ├── index.ts
│   │   ├── auth/
│   │   ├── firestore/
│   │   ├── storage/
│   │   └── utils/
│   ├── package.json
│   └── tsconfig.json
├── hosting/
│   └── public/
└── emulators/
    └── data/
```

### Firebase Configuration
```javascript
// firebase.config.js
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getStorage, connectStorageEmulator } from 'firebase/storage';
import { getFunctions, connectFunctionsEmulator } from 'firebase/functions';
import { getAnalytics } from 'firebase/analytics';
import { getPerformance } from 'firebase/performance';

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID
};

const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const functions = getFunctions(app);
export const analytics = typeof window !== 'undefined' ? getAnalytics(app) : null;
export const performance = typeof window !== 'undefined' ? getPerformance(app) : null;

// Connect to emulators in development
if (process.env.NODE_ENV === 'development') {
  connectAuthEmulator(auth, 'http://localhost:9099');
  connectFirestoreEmulator(db, 'localhost', 8080);
  connectStorageEmulator(storage, 'localhost', 9199);
  connectFunctionsEmulator(functions, 'localhost', 5001);
}

export default app;
```

## Authentication

### Multi-Provider Authentication
```javascript
// auth/providers.js
import { 
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  FacebookAuthProvider,
  GithubAuthProvider,
  signInWithCustomToken,
  sendEmailVerification,
  sendPasswordResetEmail,
  updateProfile,
  linkWithCredential
} from 'firebase/auth';

class AuthService {
  constructor(auth) {
    this.auth = auth;
    this.googleProvider = new GoogleAuthProvider();
    this.facebookProvider = new FacebookAuthProvider();
    this.githubProvider = new GithubAuthProvider();
  }

  // Email/Password authentication
  async signUpWithEmail(email, password, displayName) {
    try {
      const { user } = await createUserWithEmailAndPassword(this.auth, email, password);
      
      // Update profile
      await updateProfile(user, { displayName });
      
      // Send verification email
      await sendEmailVerification(user);
      
      // Create user document
      await this.createUserDocument(user);
      
      return user;
    } catch (error) {
      throw this.handleAuthError(error);
    }
  }

  // Social authentication
  async signInWithProvider(providerName) {
    const providers = {
      google: this.googleProvider,
      facebook: this.facebookProvider,
      github: this.githubProvider
    };

    try {
      const result = await signInWithPopup(this.auth, providers[providerName]);
      
      // Get additional user info
      const additionalUserInfo = result._tokenResponse;
      
      // Create/update user document
      await this.createUserDocument(result.user, additionalUserInfo);
      
      return result.user;
    } catch (error) {
      throw this.handleAuthError(error);
    }
  }

  // Link multiple auth providers
  async linkProvider(providerName) {
    const user = this.auth.currentUser;
    if (!user) throw new Error('No authenticated user');

    const providers = {
      google: this.googleProvider,
      facebook: this.facebookProvider,
      github: this.githubProvider
    };

    try {
      const result = await linkWithCredential(user, providers[providerName]);
      return result.user;
    } catch (error) {
      throw this.handleAuthError(error);
    }
  }

  handleAuthError(error) {
    const errorMessages = {
      'auth/email-already-in-use': 'Email is already registered',
      'auth/invalid-email': 'Invalid email address',
      'auth/operation-not-allowed': 'Operation not allowed',
      'auth/weak-password': 'Password is too weak',
      'auth/user-disabled': 'User account has been disabled',
      'auth/user-not-found': 'User not found',
      'auth/wrong-password': 'Invalid password'
    };

    return new Error(errorMessages[error.code] || error.message);
  }
}
```

### Custom Claims and Role-Based Access
```javascript
// functions/src/auth/claims.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const setCustomClaims = functions.https.onCall(async (data, context) => {
  // Verify admin privileges
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can set custom claims'
    );
  }

  const { uid, claims } = data;

  try {
    await admin.auth().setCustomUserClaims(uid, claims);
    
    // Update user document with new role
    await admin.firestore()
      .collection('users')
      .doc(uid)
      .update({
        role: claims.role,
        permissions: claims.permissions,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Verify claims in security rules
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return request.auth != null && request.auth.token.admin == true;
    }
    
    function hasRole(role) {
      return request.auth != null && request.auth.token.role == role;
    }
    
    match /admin/{document=**} {
      allow read, write: if isAdmin();
    }
    
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if isAdmin();
    }
  }
}
```

## Firestore

### Data Modeling
```javascript
// models/user.model.js
class UserModel {
  constructor(data = {}) {
    this.uid = data.uid;
    this.email = data.email;
    this.displayName = data.displayName;
    this.photoURL = data.photoURL;
    this.phoneNumber = data.phoneNumber;
    this.role = data.role || 'user';
    this.permissions = data.permissions || [];
    this.metadata = {
      createdAt: data.createdAt || new Date(),
      updatedAt: data.updatedAt || new Date(),
      lastLoginAt: data.lastLoginAt,
      loginCount: data.loginCount || 0
    };
    this.preferences = data.preferences || {};
    this.isActive = data.isActive !== false;
  }

  toFirestore() {
    return {
      uid: this.uid,
      email: this.email,
      displayName: this.displayName,
      photoURL: this.photoURL,
      phoneNumber: this.phoneNumber,
      role: this.role,
      permissions: this.permissions,
      metadata: this.metadata,
      preferences: this.preferences,
      isActive: this.isActive
    };
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new UserModel({
      ...data,
      createdAt: data.metadata?.createdAt?.toDate(),
      updatedAt: data.metadata?.updatedAt?.toDate(),
      lastLoginAt: data.metadata?.lastLoginAt?.toDate()
    });
  }
}
```

### Optimized Queries
```javascript
// firestore/queries.js
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit, 
  startAfter,
  endBefore,
  getDocs,
  onSnapshot,
  documentId,
  FieldPath
} from 'firebase/firestore';

class FirestoreService {
  constructor(db) {
    this.db = db;
  }

  // Paginated query with caching
  async getPaginatedData(collectionName, options = {}) {
    const {
      pageSize = 10,
      orderByField = 'createdAt',
      orderDirection = 'desc',
      startAfterDoc = null,
      filters = []
    } = options;

    let q = collection(this.db, collectionName);
    
    // Apply filters
    filters.forEach(filter => {
      q = query(q, where(filter.field, filter.operator, filter.value));
    });
    
    // Apply ordering
    q = query(q, orderBy(orderByField, orderDirection));
    
    // Apply pagination
    if (startAfterDoc) {
      q = query(q, startAfter(startAfterDoc));
    }
    
    q = query(q, limit(pageSize));

    const snapshot = await getDocs(q);
    const data = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    return {
      data,
      lastDoc: snapshot.docs[snapshot.docs.length - 1],
      hasMore: snapshot.docs.length === pageSize
    };
  }

  // Compound queries
  async complexQuery(collectionName) {
    const q = query(
      collection(this.db, collectionName),
      where('status', '==', 'active'),
      where('category', 'in', ['electronics', 'books']),
      where('price', '>=', 10),
      where('price', '<=', 100),
      orderBy('price', 'desc'),
      limit(20)
    );

    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }

  // Real-time subscription with error handling
  subscribeToCollection(collectionName, callback, errorCallback) {
    const q = query(
      collection(this.db, collectionName),
      orderBy('updatedAt', 'desc')
    );

    return onSnapshot(
      q,
      (snapshot) => {
        const changes = snapshot.docChanges().map(change => ({
          type: change.type,
          doc: { id: change.doc.id, ...change.doc.data() }
        }));
        callback(changes);
      },
      errorCallback
    );
  }

  // Batch operations
  async batchWrite(operations) {
    const batch = writeBatch(this.db);
    
    operations.forEach(op => {
      const ref = doc(this.db, op.collection, op.id);
      
      switch (op.type) {
        case 'set':
          batch.set(ref, op.data);
          break;
        case 'update':
          batch.update(ref, op.data);
          break;
        case 'delete':
          batch.delete(ref);
          break;
      }
    });

    await batch.commit();
  }
}
```

### Security Rules
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
      return request.auth.uid == userId;
    }
    
    function isAdmin() {
      return request.auth.token.admin == true;
    }
    
    function hasRole(role) {
      return request.auth.token.role == role;
    }
    
    function isValidEmail(email) {
      return email.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
    }
    
    // User documents
    match /users/{userId} {
      allow read: if isSignedIn() && (isOwner(userId) || isAdmin());
      allow create: if isSignedIn() && isOwner(userId) && 
        isValidEmail(request.resource.data.email);
      allow update: if isSignedIn() && isOwner(userId) &&
        request.resource.data.uid == resource.data.uid;
      allow delete: if isAdmin();
    }
    
    // Public read, authenticated write
    match /posts/{postId} {
      allow read: if true;
      allow create: if isSignedIn() &&
        request.resource.data.authorId == request.auth.uid &&
        request.resource.data.createdAt == request.time;
      allow update: if isSignedIn() &&
        resource.data.authorId == request.auth.uid;
      allow delete: if isSignedIn() &&
        (resource.data.authorId == request.auth.uid || isAdmin());
    }
    
    // Rate limiting example
    match /messages/{messageId} {
      allow create: if isSignedIn() &&
        request.time > resource.data.lastMessageTime + duration.value(1, 's');
    }
  }
}
```

## Cloud Functions

### Optimized Functions
```typescript
// functions/src/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Storage } from '@google-cloud/storage';

// Initialize admin with limited scope
admin.initializeApp({
  projectId: functions.config().project.id,
  storageBucket: functions.config().storage.bucket
});

const db = admin.firestore();
const storage = new Storage();

// Use region-specific deployment
const regionalFunctions = functions.region('us-central1');

// HTTP Function with CORS
export const api = regionalFunctions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Route handling
  try {
    switch (req.path) {
      case '/users':
        await handleUsers(req, res);
        break;
      case '/posts':
        await handlePosts(req, res);
        break;
      default:
        res.status(404).json({ error: 'Not found' });
    }
  } catch (error) {
    console.error('API Error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Background Function with retry
export const processImage = regionalFunctions
  .runWith({
    timeoutSeconds: 300,
    memory: '2GB'
  })
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;

    // Only process images
    if (!contentType?.startsWith('image/')) {
      return null;
    }

    try {
      // Process image (resize, optimize, etc.)
      await processAndOptimizeImage(filePath);
      
      // Update metadata
      await db.collection('uploads').doc(object.generation).set({
        path: filePath,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        size: object.size,
        contentType: contentType
      });
    } catch (error) {
      console.error('Image processing failed:', error);
      throw error; // Triggers retry
    }
  });

// Scheduled Function
export const dailyCleanup = regionalFunctions
  .pubsub
  .schedule('every 24 hours')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30);

    // Delete old temporary files
    const oldFiles = await db.collection('temp_files')
      .where('createdAt', '<', cutoffDate)
      .get();

    const batch = db.batch();
    oldFiles.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${oldFiles.size} old temporary files`);
  });

// Callable Function with validation
export const createOrder = regionalFunctions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  // Input validation
  const { items, shippingAddress, paymentMethod } = data;
  
  if (!items || !Array.isArray(items) || items.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Order must contain items'
    );
  }

  try {
    // Create order with transaction
    const orderId = await db.runTransaction(async (transaction) => {
      const orderRef = db.collection('orders').doc();
      
      // Verify inventory
      for (const item of items) {
        const productRef = db.collection('products').doc(item.productId);
        const product = await transaction.get(productRef);
        
        if (!product.exists) {
          throw new Error(`Product ${item.productId} not found`);
        }
        
        if (product.data().stock < item.quantity) {
          throw new Error(`Insufficient stock for ${product.data().name}`);
        }
        
        // Update stock
        transaction.update(productRef, {
          stock: admin.firestore.FieldValue.increment(-item.quantity)
        });
      }
      
      // Create order
      transaction.set(orderRef, {
        userId: context.auth.uid,
        items,
        shippingAddress,
        paymentMethod,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return orderRef.id;
    });

    return { orderId, success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

## Storage

### File Upload Management
```javascript
// storage/upload.js
import { 
  ref, 
  uploadBytesResumable, 
  getDownloadURL,
  deleteObject,
  listAll
} from 'firebase/storage';

class StorageService {
  constructor(storage) {
    this.storage = storage;
  }

  // Upload with progress tracking
  uploadFile(file, path, onProgress) {
    return new Promise((resolve, reject) => {
      const storageRef = ref(this.storage, path);
      const uploadTask = uploadBytesResumable(storageRef, file);

      uploadTask.on(
        'state_changed',
        (snapshot) => {
          const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          if (onProgress) onProgress(progress);
        },
        (error) => {
          reject(this.handleStorageError(error));
        },
        async () => {
          const downloadURL = await getDownloadURL(uploadTask.snapshot.ref);
          resolve({
            url: downloadURL,
            path: uploadTask.snapshot.ref.fullPath,
            size: uploadTask.snapshot.totalBytes,
            contentType: uploadTask.snapshot.metadata.contentType
          });
        }
      );
    });
  }

  // Upload with automatic resizing
  async uploadImage(file, userId, options = {}) {
    const {
      maxWidth = 1920,
      maxHeight = 1080,
      quality = 0.85,
      generateThumbnail = true
    } = options;

    // Resize image client-side
    const resizedImage = await this.resizeImage(file, maxWidth, maxHeight, quality);
    
    // Generate unique filename
    const timestamp = Date.now();
    const filename = `${userId}/${timestamp}_${file.name}`;
    
    // Upload main image
    const mainUpload = await this.uploadFile(resizedImage, `images/${filename}`);
    
    // Generate and upload thumbnail
    let thumbnailUpload = null;
    if (generateThumbnail) {
      const thumbnail = await this.resizeImage(file, 200, 200, 0.7);
      thumbnailUpload = await this.uploadFile(
        thumbnail, 
        `thumbnails/${filename}`
      );
    }

    return {
      main: mainUpload,
      thumbnail: thumbnailUpload
    };
  }

  async resizeImage(file, maxWidth, maxHeight, quality) {
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          let { width, height } = img;

          // Calculate new dimensions
          if (width > maxWidth || height > maxHeight) {
            const ratio = Math.min(maxWidth / width, maxHeight / height);
            width *= ratio;
            height *= ratio;
          }

          canvas.width = width;
          canvas.height = height;

          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, width, height);

          canvas.toBlob(
            (blob) => resolve(blob),
            file.type,
            quality
          );
        };
        img.src = e.target.result;
      };
      reader.readAsDataURL(file);
    });
  }

  handleStorageError(error) {
    const errorMessages = {
      'storage/unauthorized': 'User is not authorized to perform this action',
      'storage/canceled': 'Upload was cancelled',
      'storage/unknown': 'An unknown error occurred',
      'storage/object-not-found': 'File not found',
      'storage/bucket-not-found': 'Storage bucket not found',
      'storage/project-not-found': 'Project not found',
      'storage/quota-exceeded': 'Storage quota exceeded',
      'storage/unauthenticated': 'User is not authenticated',
      'storage/retry-limit-exceeded': 'Max retry time exceeded',
      'storage/invalid-checksum': 'File checksum does not match',
      'storage/cannot-slice-blob': 'Cannot slice blob for upload',
      'storage/server-file-wrong-size': 'Server file size mismatch'
    };

    return new Error(errorMessages[error.code] || error.message);
  }
}
```

### Storage Security Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isValidImageFile() {
      return request.resource.contentType.matches('image/.*') &&
             request.resource.size < 10 * 1024 * 1024; // 10MB
    }
    
    function isValidDocument() {
      return request.resource.contentType.matches('application/pdf') &&
             request.resource.size < 50 * 1024 * 1024; // 50MB
    }
    
    // User uploads
    match /users/{userId}/{allPaths=**} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId) && isValidImageFile();
      allow delete: if isSignedIn() && isOwner(userId);
    }
    
    // Public images
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // Protected documents
    match /documents/{document} {
      allow read: if isSignedIn() && 
        firestore.get(/databases/(default)/documents/documents/$(document))
          .data.allowedUsers.hasAny([request.auth.uid]);
      allow write: if isSignedIn() && isValidDocument();
    }
  }
}
```

## Performance Optimization

### Lazy Loading and Code Splitting
```javascript
// Lazy load Firebase services
const loadFirebaseAuth = () => import('./services/auth');
const loadFirestore = () => import('./services/firestore');
const loadStorage = () => import('./services/storage');

// Use dynamic imports
async function initializeFirebase() {
  const { auth } = await loadFirebaseAuth();
  const { firestore } = await loadFirestore();
  
  return { auth, firestore };
}

// Bundle size optimization
import { getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
// Don't import entire Firebase SDK
```

### Caching Strategies
```javascript
// Enable offline persistence
import { enableIndexedDbPersistence } from 'firebase/firestore';

enableIndexedDbPersistence(db).catch((err) => {
  if (err.code === 'failed-precondition') {
    console.log('Multiple tabs open, persistence enabled in first tab only');
  } else if (err.code === 'unimplemented') {
    console.log('Browser doesn't support persistence');
  }
});

// Implement custom caching
class CacheService {
  constructor(ttl = 3600000) { // 1 hour default
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

  clear() {
    this.cache.clear();
  }
}
```

## Testing

### Unit Testing Firebase Functions
```javascript
// functions/test/index.test.js
const functions = require('firebase-functions-test')();
const admin = require('firebase-admin');
const sinon = require('sinon');

describe('Cloud Functions', () => {
  let myFunctions;
  
  before(() => {
    // Mock admin SDK
    const adminStub = sinon.stub(admin, 'initializeApp');
    myFunctions = require('../src/index');
  });
  
  after(() => {
    functions.cleanup();
    sinon.restore();
  });
  
  describe('createOrder', () => {
    it('should create order successfully', async () => {
      const wrapped = functions.wrap(myFunctions.createOrder);
      const data = {
        items: [{ productId: '123', quantity: 2 }],
        shippingAddress: { street: '123 Main St' },
        paymentMethod: 'card'
      };
      const context = {
        auth: { uid: 'user123' }
      };
      
      const result = await wrapped(data, context);
      expect(result).to.have.property('orderId');
      expect(result.success).to.be.true;
    });
  });
});
```

## Best Practices Summary

1. **Security First**: Always implement proper security rules and validate inputs
2. **Optimize Bundle Size**: Use modular imports and lazy loading
3. **Handle Errors Gracefully**: Implement comprehensive error handling
4. **Use Transactions**: Ensure data consistency with transactions
5. **Enable Offline Support**: Use offline persistence for better UX
6. **Monitor Performance**: Use Firebase Performance Monitoring
7. **Test Thoroughly**: Write unit and integration tests
8. **Use Emulators**: Develop locally with Firebase emulators
9. **Implement Caching**: Cache frequently accessed data
10. **Follow Firebase Limits**: Be aware of quotas and limits

## Conclusion

Firebase provides a comprehensive platform for building scalable applications. Following these best practices ensures secure, performant, and maintainable Firebase applications.