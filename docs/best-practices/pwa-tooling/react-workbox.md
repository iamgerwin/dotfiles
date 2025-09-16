# React with Workbox Best Practices

## Overview

React with Workbox combines the power of React's component-based architecture with Google's Workbox library for building Progressive Web Applications (PWAs). Workbox provides a set of libraries and tools that make it easy to cache assets, manage service workers, and implement offline functionality. When integrated with React applications, this combination enables developers to create fast, reliable, and engaging web applications that work seamlessly across all devices and network conditions.

## Use Cases

### Optimal Scenarios
- **E-commerce Platforms**: Fast page loads and offline browsing capabilities
- **News and Media Sites**: Content caching for offline reading
- **Social Media Applications**: Background sync for posts and messages
- **Enterprise Dashboards**: Reliable access to critical business data
- **Educational Platforms**: Offline course content and progress tracking
- **Travel Applications**: Offline maps and itinerary access
- **Documentation Sites**: Searchable offline documentation
- **Portfolio Websites**: Fast-loading showcases with offline capabilities

### When to Avoid
- Simple landing pages with minimal interactivity
- Applications requiring real-time data with no caching tolerance
- Internal tools where offline access is not required
- Applications with strict data freshness requirements
- Sites with frequently changing content that shouldn't be cached

## Pros and Cons

### Pros
- Significant performance improvements through intelligent caching
- Offline functionality without complex implementation
- Automatic cache management and versioning
- Background sync for resilient data submission
- Push notification support built-in
- Reduced server load through client-side caching
- Improved Core Web Vitals scores
- Seamless integration with React build tools

### Cons
- Added complexity in build configuration
- Cache invalidation challenges
- Larger initial bundle size
- Service worker debugging complexity
- Browser compatibility considerations
- Storage quota limitations
- Potential for serving stale content
- Learning curve for service worker concepts

## Implementation Patterns

### Initial Setup and Configuration

```javascript
// workbox-config.js - Production-ready Workbox configuration
module.exports = {
  globDirectory: 'build/',
  globPatterns: [
    '**/*.{js,css,html,png,jpg,jpeg,gif,svg,woff,woff2,ttf,eot,ico}'
  ],
  swDest: 'build/service-worker.js',
  swSrc: 'src/service-worker.js',

  // Don't cache files larger than 5MB
  maximumFileSizeToCacheInBytes: 5 * 1024 * 1024,

  // Clean up outdated caches
  cleanupOutdatedCaches: true,

  // Skip waiting and claim clients immediately
  skipWaiting: true,
  clientsClaim: true,

  // Runtime caching configuration
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/api\.example\.com\/api/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'api-cache',
        networkTimeoutSeconds: 3,
        expiration: {
          maxEntries: 50,
          maxAgeSeconds: 300 // 5 minutes
        },
        cacheableResponse: {
          statuses: [0, 200]
        }
      }
    },
    {
      urlPattern: /^https:\/\/cdn\.example\.com\/images/,
      handler: 'CacheFirst',
      options: {
        cacheName: 'image-cache',
        expiration: {
          maxEntries: 100,
          maxAgeSeconds: 30 * 24 * 60 * 60 // 30 days
        }
      }
    },
    {
      urlPattern: /^https:\/\/fonts\.(googleapis|gstatic)\.com/,
      handler: 'StaleWhileRevalidate',
      options: {
        cacheName: 'font-cache',
        expiration: {
          maxEntries: 30,
          maxAgeSeconds: 365 * 24 * 60 * 60 // 1 year
        }
      }
    }
  ],

  // Ignore specific URLs
  navigateFallbackDenylist: [/^\/_/, /\/[^/?]+\.[^/]+$/],

  // Manifest transformations
  manifestTransforms: [
    (manifestEntries) => {
      const manifest = manifestEntries.map(entry => {
        // Add revision info for better cache busting
        entry.revision = entry.revision || Date.now().toString();
        return entry;
      });
      return { manifest };
    }
  ]
};
```

### Custom Service Worker Implementation

```javascript
// src/service-worker.js - Advanced service worker with Workbox
import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute, NavigationRoute } from 'workbox-routing';
import {
  NetworkFirst,
  CacheFirst,
  StaleWhileRevalidate
} from 'workbox-strategies';
import { ExpirationPlugin } from 'workbox-expiration';
import { CacheableResponsePlugin } from 'workbox-cacheable-response';
import { BackgroundSyncPlugin } from 'workbox-background-sync';
import { Queue } from 'workbox-background-sync';

// Precache all static assets
precacheAndRoute(self.__WB_MANIFEST);

// Custom cache names
const CACHE_NAMES = {
  api: 'api-cache-v1',
  images: 'image-cache-v1',
  documents: 'document-cache-v1'
};

// API caching with network-first strategy
registerRoute(
  ({ url }) => url.origin === 'https://api.example.com',
  new NetworkFirst({
    cacheName: CACHE_NAMES.api,
    networkTimeoutSeconds: 5,
    plugins: [
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 5 * 60, // 5 minutes
        purgeOnQuotaError: true
      }),
      new CacheableResponsePlugin({
        statuses: [0, 200]
      })
    ]
  })
);

// Image caching with cache-first strategy
registerRoute(
  ({ request }) => request.destination === 'image',
  new CacheFirst({
    cacheName: CACHE_NAMES.images,
    plugins: [
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
        purgeOnQuotaError: true
      }),
      new CacheableResponsePlugin({
        statuses: [0, 200]
      })
    ]
  })
);

// Background sync for failed POST requests
const bgSyncPlugin = new BackgroundSyncPlugin('failed-requests', {
  maxRetentionTime: 24 * 60 // Retry for up to 24 hours
});

registerRoute(
  ({ url }) => url.pathname.startsWith('/api/') &&
              url.searchParams.has('sync'),
  new NetworkFirst({
    plugins: [bgSyncPlugin]
  }),
  'POST'
);

// Custom offline fallback
const FALLBACK_HTML_URL = '/offline.html';
const FALLBACK_IMAGE_URL = '/images/offline.svg';

// Cache offline pages
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open('offline-fallbacks').then(cache => {
      return cache.addAll([FALLBACK_HTML_URL, FALLBACK_IMAGE_URL]);
    })
  );
});

// Provide offline fallbacks
const navigationHandler = async (params) => {
  try {
    return await new NetworkFirst({
      cacheName: 'navigations',
      networkTimeoutSeconds: 3
    }).handle(params);
  } catch (error) {
    return caches.match(FALLBACK_HTML_URL);
  }
};

registerRoute(
  new NavigationRoute(navigationHandler)
);

// Handle image fallbacks
registerRoute(
  ({ request }) => request.destination === 'image',
  async ({ request }) => {
    try {
      return await new CacheFirst().handle({ request });
    } catch (error) {
      return caches.match(FALLBACK_IMAGE_URL);
    }
  }
);

// Message handling for skip waiting
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(cacheName => !Object.values(CACHE_NAMES).includes(cacheName))
          .map(cacheName => caches.delete(cacheName))
      );
    })
  );
});
```

### React Integration

```jsx
// src/serviceWorkerRegistration.js - React service worker registration
import { Workbox } from 'workbox-window';

class ServiceWorkerManager {
  constructor() {
    this.wb = null;
    this.registration = null;
    this.updateAvailable = false;
  }

  register(config = {}) {
    if ('serviceWorker' in navigator) {
      // Create Workbox instance
      this.wb = new Workbox('/service-worker.js');

      // Add event listeners
      this.setupEventListeners(config);

      // Register service worker
      return this.wb.register();
    }

    return Promise.reject(new Error('Service Worker not supported'));
  }

  setupEventListeners(config) {
    // Service worker lifecycle events
    this.wb.addEventListener('installed', event => {
      if (!event.isUpdate) {
        config.onSuccess?.('Content cached for offline use');
      }
    });

    this.wb.addEventListener('waiting', event => {
      this.updateAvailable = true;
      config.onUpdate?.(this.registration);
    });

    this.wb.addEventListener('controlling', event => {
      window.location.reload();
    });

    this.wb.addEventListener('activated', event => {
      if (event.isUpdate) {
        config.onSuccess?.('New content available');
      }
    });

    // Handle messages from service worker
    this.wb.addEventListener('message', event => {
      if (event.data.type === 'CACHE_UPDATED') {
        const { updatedURL } = event.data.payload;
        console.log(`Cache updated for: ${updatedURL}`);
      }
    });
  }

  update() {
    if (this.wb) {
      return this.wb.update();
    }
  }

  skipWaiting() {
    if (this.wb && this.updateAvailable) {
      this.wb.messageSkipWaiting();
      this.wb.addEventListener('controlling', () => {
        window.location.reload();
      });
    }
  }

  unregister() {
    if ('serviceWorker' in navigator) {
      return navigator.serviceWorker.ready.then(registration => {
        return registration.unregister();
      });
    }
  }
}

export default new ServiceWorkerManager();

// src/App.js - React app with PWA features
import React, { useState, useEffect, useCallback } from 'react';
import serviceWorkerManager from './serviceWorkerRegistration';
import UpdatePrompt from './components/UpdatePrompt';
import OfflineIndicator from './components/OfflineIndicator';

function App() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [registration, setRegistration] = useState(null);

  useEffect(() => {
    // Register service worker
    serviceWorkerManager.register({
      onSuccess: (message) => {
        console.log(message);
      },
      onUpdate: (reg) => {
        setRegistration(reg);
        setUpdateAvailable(true);
      }
    });

    // Monitor online/offline status
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Check for updates periodically
    const interval = setInterval(() => {
      serviceWorkerManager.update();
    }, 60000); // Check every minute

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      clearInterval(interval);
    };
  }, []);

  const handleUpdate = useCallback(() => {
    serviceWorkerManager.skipWaiting();
    setUpdateAvailable(false);
  }, []);

  return (
    <div className="App">
      {!isOnline && <OfflineIndicator />}
      {updateAvailable && (
        <UpdatePrompt onUpdate={handleUpdate} />
      )}
      {/* Your app content */}
    </div>
  );
}

// src/components/UpdatePrompt.jsx
const UpdatePrompt = ({ onUpdate }) => {
  return (
    <div className="update-prompt">
      <p>New version available!</p>
      <button onClick={onUpdate}>Update Now</button>
      <button onClick={() => setVisible(false)}>Later</button>
    </div>
  );
};

// src/components/OfflineIndicator.jsx
const OfflineIndicator = () => {
  return (
    <div className="offline-indicator">
      <span>You are currently offline</span>
    </div>
  );
};
```

### Advanced Caching Strategies

```javascript
// src/utils/cachingStrategies.js - Custom caching strategies
import {
  Strategy,
  StrategyHandler
} from 'workbox-strategies';

// Custom strategy: Network first with cache fallback and timeout
class NetworkFirstWithTimeout extends Strategy {
  constructor(options = {}) {
    super(options);
    this._networkTimeoutSeconds = options.networkTimeoutSeconds || 5;
  }

  async _handle(request, handler) {
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Network timeout')),
                this._networkTimeoutSeconds * 1000)
    );

    try {
      const response = await Promise.race([
        handler.fetch(request),
        timeoutPromise
      ]);

      if (response) {
        await handler.cachePut(request, response.clone());
        return response;
      }
    } catch (error) {
      const cachedResponse = await handler.cacheMatch(request);
      if (cachedResponse) {
        return cachedResponse;
      }
      throw error;
    }
  }
}

// Intelligent caching based on resource type
export class IntelligentCachingPlugin {
  constructor() {
    this.cacheDecisions = new Map();
  }

  requestWillFetch({ request }) {
    // Add custom headers for tracking
    const headers = new Headers(request.headers);
    headers.set('X-Cache-Strategy', this.determineStrategy(request));
    return new Request(request, { headers });
  }

  determineStrategy(request) {
    const url = new URL(request.url);

    // API calls - Network first
    if (url.pathname.startsWith('/api/')) {
      return 'network-first';
    }

    // Static assets - Cache first
    if (url.pathname.match(/\.(js|css|woff2?)$/)) {
      return 'cache-first';
    }

    // Images - Stale while revalidate
    if (url.pathname.match(/\.(png|jpg|jpeg|gif|svg)$/)) {
      return 'stale-while-revalidate';
    }

    // Default
    return 'network-first';
  }

  cachedResponseWillBeUsed({ cachedResponse, request }) {
    if (cachedResponse) {
      // Check if cached response is still fresh
      const cachedDate = cachedResponse.headers.get('date');
      if (cachedDate) {
        const age = (Date.now() - new Date(cachedDate).getTime()) / 1000;

        // If older than 24 hours, mark for background refresh
        if (age > 86400) {
          this.scheduleBackgroundRefresh(request);
        }
      }
    }
    return cachedResponse;
  }

  scheduleBackgroundRefresh(request) {
    // Refresh cache in background
    setTimeout(() => {
      fetch(request).then(response => {
        if (response.ok) {
          caches.open('dynamic-cache').then(cache => {
            cache.put(request, response);
          });
        }
      });
    }, 0);
  }
}
```

### Performance Monitoring

```javascript
// src/utils/performanceMonitor.js - PWA performance tracking
class PWAPerformanceMonitor {
  constructor() {
    this.metrics = {
      cacheHits: 0,
      cacheMisses: 0,
      networkRequests: 0,
      offlineServed: 0,
      averageResponseTime: []
    };

    this.setupMonitoring();
  }

  setupMonitoring() {
    // Monitor service worker events
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.addEventListener('message', (event) => {
        if (event.data.type === 'PERFORMANCE_METRIC') {
          this.recordMetric(event.data.metric);
        }
      });
    }

    // Monitor resource timing
    if ('PerformanceObserver' in window) {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          this.recordResourceTiming(entry);
        }
      });

      observer.observe({ entryTypes: ['resource', 'navigation'] });
    }
  }

  recordMetric(metric) {
    switch (metric.name) {
      case 'cache-hit':
        this.metrics.cacheHits++;
        break;
      case 'cache-miss':
        this.metrics.cacheMisses++;
        break;
      case 'network-request':
        this.metrics.networkRequests++;
        break;
      case 'offline-served':
        this.metrics.offlineServed++;
        break;
    }

    this.reportMetrics();
  }

  recordResourceTiming(entry) {
    this.metrics.averageResponseTime.push(entry.duration);

    // Keep only last 100 measurements
    if (this.metrics.averageResponseTime.length > 100) {
      this.metrics.averageResponseTime.shift();
    }
  }

  getCacheHitRate() {
    const total = this.metrics.cacheHits + this.metrics.cacheMisses;
    return total > 0 ? (this.metrics.cacheHits / total) * 100 : 0;
  }

  getAverageResponseTime() {
    const times = this.metrics.averageResponseTime;
    return times.length > 0
      ? times.reduce((a, b) => a + b, 0) / times.length
      : 0;
  }

  reportMetrics() {
    // Send metrics to analytics service
    if (window.gtag) {
      window.gtag('event', 'pwa_performance', {
        cache_hit_rate: this.getCacheHitRate(),
        average_response_time: this.getAverageResponseTime(),
        offline_serves: this.metrics.offlineServed
      });
    }
  }

  getMetricsSummary() {
    return {
      cacheHitRate: `${this.getCacheHitRate().toFixed(2)}%`,
      averageResponseTime: `${this.getAverageResponseTime().toFixed(2)}ms`,
      totalRequests: this.metrics.networkRequests,
      offlineServes: this.metrics.offlineServed
    };
  }
}

export default new PWAPerformanceMonitor();
```

## Security Considerations

### Critical Security Measures

1. **Content Security Policy for Service Workers**
   ```javascript
   // Set strict CSP headers
   self.addEventListener('fetch', event => {
     event.respondWith(
       fetch(event.request).then(response => {
         const newHeaders = new Headers(response.headers);
         newHeaders.set(
           'Content-Security-Policy',
           "default-src 'self'; script-src 'self' 'unsafe-inline'"
         );
         return new Response(response.body, {
           status: response.status,
           statusText: response.statusText,
           headers: newHeaders
         });
       })
     );
   });
   ```

2. **Validate Cached Responses**
   ```javascript
   class SecureCachingPlugin {
     cachedResponseWillBeUsed({ cachedResponse, request }) {
       if (!this.isResponseValid(cachedResponse)) {
         return null; // Force network request
       }
       return cachedResponse;
     }

     isResponseValid(response) {
       // Check response integrity
       const integrity = response.headers.get('x-content-integrity');
       if (integrity) {
         return this.verifyIntegrity(response, integrity);
       }
       return true;
     }
   }
   ```

3. **Prevent Cache Poisoning**
   ```javascript
   registerRoute(
     ({ url }) => url.origin === 'https://api.example.com',
     new NetworkFirst({
       plugins: [
         {
           cacheWillUpdate: async ({ response }) => {
             // Only cache successful responses
             if (!response || response.status !== 200) {
               return null;
             }
             // Verify response origin
             if (response.type !== 'basic' && response.type !== 'cors') {
               return null;
             }
             return response;
           }
         }
       ]
     })
   );
   ```

4. **Secure Storage Management**
   ```javascript
   // Clear sensitive data on logout
   async function clearSensitiveCache() {
     const cacheNames = await caches.keys();
     const sensitiveCache = cacheNames.filter(name =>
       name.includes('user-data') || name.includes('auth')
     );

     await Promise.all(
       sensitiveCache.map(name => caches.delete(name))
     );
   }
   ```

5. **CORS and Origin Validation**
   ```javascript
   const ALLOWED_ORIGINS = [
     'https://api.example.com',
     'https://cdn.example.com'
   ];

   registerRoute(
     ({ url }) => ALLOWED_ORIGINS.includes(url.origin),
     new StaleWhileRevalidate({
       plugins: [
         new CacheableResponsePlugin({
           statuses: [200],
           headers: {
             'Access-Control-Allow-Origin': '*'
           }
         })
       ]
     })
   );
   ```

## Common Pitfalls

### Pitfall 1: Over-Caching Dynamic Content
**Problem**: Caching API responses that change frequently
**Solution**: Use appropriate cache expiration and validation strategies

### Pitfall 2: Service Worker Update Issues
**Problem**: Users stuck with old service worker versions
**Solution**: Implement proper update flow with skip waiting

### Pitfall 3: Storage Quota Exceeded
**Problem**: Cache grows unbounded until quota is exceeded
**Solution**: Implement cache size limits and cleanup strategies

### Pitfall 4: Mixed Content Issues
**Problem**: Service worker on HTTPS trying to cache HTTP resources
**Solution**: Ensure all resources use HTTPS

### Pitfall 5: Poor Offline Experience
**Problem**: Generic offline page for all routes
**Solution**: Create route-specific offline fallbacks

### Pitfall 6: Cache-First Everything
**Problem**: Using cache-first for all resources causing stale content
**Solution**: Choose appropriate strategies per resource type

## Best Practices Summary

- [ ] Use appropriate caching strategies for different resource types
- [ ] Implement cache versioning and cleanup
- [ ] Monitor cache hit rates and performance metrics
- [ ] Provide clear update notifications to users
- [ ] Test offline functionality thoroughly
- [ ] Implement proper error boundaries
- [ ] Use background sync for critical operations
- [ ] Set appropriate cache expiration times
- [ ] Validate cached responses before serving
- [ ] Implement route-specific offline pages
- [ ] Monitor and limit cache size
- [ ] Use Workbox's built-in plugins
- [ ] Implement proper CORS handling
- [ ] Test across different browsers and devices
- [ ] Document caching strategies for team members

## Example

### Complete React PWA Implementation

```jsx
// src/index.js - Application entry point
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import * as serviceWorkerRegistration from './serviceWorkerRegistration';
import performanceMonitor from './utils/performanceMonitor';

const root = ReactDOM.createRoot(document.getElementById('root'));

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// Register service worker
serviceWorkerRegistration.register({
  onSuccess: () => {
    console.log('PWA: Service Worker registered successfully');
  },
  onUpdate: (registration) => {
    console.log('PWA: New content available');
    // Trigger update notification in app
    window.dispatchEvent(
      new CustomEvent('sw-update', { detail: registration })
    );
  }
});

// Monitor performance
if (process.env.NODE_ENV === 'production') {
  performanceMonitor.startMonitoring();
}

// src/App.js - Main application with PWA features
import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  BrowserRouter as Router,
  Routes,
  Route
} from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import UpdateNotification from './components/UpdateNotification';
import OfflineBanner from './components/OfflineBanner';
import NetworkStatusProvider from './contexts/NetworkStatusContext';
import CacheProvider from './contexts/CacheContext';

// Configure React Query for optimal caching
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
      retry: (failureCount, error) => {
        if (error.status === 404) return false;
        return failureCount < 3;
      },
      refetchOnWindowFocus: false,
      refetchOnReconnect: 'always'
    }
  }
});

function App() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [swRegistration, setSwRegistration] = useState(null);

  useEffect(() => {
    // Listen for service worker updates
    const handleSwUpdate = (event) => {
      setSwRegistration(event.detail);
      setUpdateAvailable(true);
    };

    window.addEventListener('sw-update', handleSwUpdate);

    // Monitor network status
    const handleOnline = () => {
      setIsOnline(true);
      queryClient.refetchQueries();
    };

    const handleOffline = () => {
      setIsOnline(false);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Cleanup
    return () => {
      window.removeEventListener('sw-update', handleSwUpdate);
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const handleUpdate = useCallback(() => {
    if (swRegistration && swRegistration.waiting) {
      swRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });
      swRegistration.waiting.addEventListener('statechange', (e) => {
        if (e.target.state === 'activated') {
          window.location.reload();
        }
      });
    }
  }, [swRegistration]);

  const contextValue = useMemo(() => ({
    isOnline,
    updateAvailable,
    handleUpdate
  }), [isOnline, updateAvailable, handleUpdate]);

  return (
    <QueryClientProvider client={queryClient}>
      <NetworkStatusProvider value={contextValue}>
        <CacheProvider>
          <Router>
            <div className="app">
              {!isOnline && <OfflineBanner />}
              {updateAvailable && (
                <UpdateNotification onUpdate={handleUpdate} />
              )}

              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<About />} />
                <Route path="/offline" element={<OfflinePage />} />
              </Routes>
            </div>
          </Router>
        </CacheProvider>
      </NetworkStatusProvider>
    </QueryClientProvider>
  );
}

// src/hooks/useOfflineSync.js - Custom hook for offline sync
import { useState, useEffect, useCallback } from 'react';
import { openDB } from 'idb';

const DB_NAME = 'offline-queue';
const STORE_NAME = 'requests';

export function useOfflineSync() {
  const [queue, setQueue] = useState([]);
  const [isSyncing, setIsSyncing] = useState(false);

  // Initialize IndexedDB
  const initDB = async () => {
    return openDB(DB_NAME, 1, {
      upgrade(db) {
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME, {
            keyPath: 'id',
            autoIncrement: true
          });
        }
      }
    });
  };

  // Add request to queue
  const queueRequest = useCallback(async (request) => {
    const db = await initDB();
    const tx = db.transaction(STORE_NAME, 'readwrite');

    await tx.objectStore(STORE_NAME).add({
      url: request.url,
      method: request.method,
      body: request.body,
      headers: request.headers,
      timestamp: Date.now()
    });

    await loadQueue();
  }, []);

  // Load queued requests
  const loadQueue = useCallback(async () => {
    const db = await initDB();
    const requests = await db.getAll(STORE_NAME);
    setQueue(requests);
  }, []);

  // Sync queued requests
  const syncQueue = useCallback(async () => {
    if (isSyncing || !navigator.onLine) return;

    setIsSyncing(true);
    const db = await initDB();
    const requests = await db.getAll(STORE_NAME);

    for (const request of requests) {
      try {
        const response = await fetch(request.url, {
          method: request.method,
          body: request.body,
          headers: request.headers
        });

        if (response.ok) {
          await db.delete(STORE_NAME, request.id);
        }
      } catch (error) {
        console.error('Sync failed for request:', request, error);
      }
    }

    await loadQueue();
    setIsSyncing(false);
  }, [isSyncing]);

  useEffect(() => {
    loadQueue();

    // Sync when coming online
    const handleOnline = () => {
      syncQueue();
    };

    window.addEventListener('online', handleOnline);

    return () => {
      window.removeEventListener('online', handleOnline);
    };
  }, []);

  return {
    queue,
    queueRequest,
    syncQueue,
    isSyncing
  };
}

export default App;
```

## Conclusion

React with Workbox represents a powerful combination for building modern Progressive Web Applications that deliver exceptional user experiences across all network conditions. The integration enables developers to create fast, reliable, and engaging applications that work seamlessly offline while maintaining the development efficiency that React provides.

**When to use React with Workbox:**
- Building content-rich applications requiring offline access
- E-commerce platforms needing fast page loads
- Enterprise applications requiring reliability
- Media sites with heavy content caching needs
- Applications targeting mobile users with unreliable connections
- Projects where SEO and performance metrics are critical
- Applications requiring background synchronization

**When to seek alternatives:**
- Simple static sites with minimal interactivity (use plain HTML/CSS)
- Real-time applications with no caching tolerance (consider WebSockets)
- Applications with strict data freshness requirements
- Internal tools where offline isn't needed
- Projects with teams unfamiliar with PWA concepts

The key to successful React with Workbox implementation lies in choosing appropriate caching strategies, implementing robust error handling, and maintaining a balance between performance optimization and content freshness. By following the best practices outlined here, teams can create PWAs that provide native-like experiences while leveraging the power of web technologies.