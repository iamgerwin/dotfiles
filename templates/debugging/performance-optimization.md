# ⚡ Performance Optimization Template

## Performance Issue Overview
**Component/Page**: [Affected area]
**Current Performance**: [Current metrics]
**Target Performance**: [Goal metrics]
**User Impact**: [How it affects users]

## Performance Metrics

### Current Measurements
- **Page Load Time**: [seconds]
- **Time to Interactive (TTI)**: [seconds]
- **First Contentful Paint (FCP)**: [seconds]
- **Largest Contentful Paint (LCP)**: [seconds]
- **Database Query Time**: [ms]
- **API Response Time**: [ms]
- **Memory Usage**: [MB]
- **CPU Usage**: [%]

## Analysis Process

### 1. Profiling & Monitoring

#### Backend Profiling (Laravel)
```bash
# Enable query logging
DB::enableQueryLog();
// ... run operations
dd(DB::getQueryLog());

# Use Laravel Debugbar
composer require barryvdh/laravel-debugbar --dev

# Use Laravel Telescope
composer require laravel/telescope
php artisan telescope:install
```

#### Frontend Profiling
```javascript
// Performance timing
console.time('operation');
// ... operation code
console.timeEnd('operation');

// Chrome DevTools Performance tab
// Lighthouse audit
// React DevTools Profiler
// Vue DevTools Performance
```

### 2. Database Optimization

#### Query Optimization
```php
// Bad: N+1 Problem
$users = User::all();
foreach ($users as $user) {
    echo $user->posts->count(); // Executes query for each user
}

// Good: Eager Loading
$users = User::with('posts')->get();
foreach ($users as $user) {
    echo $user->posts->count(); // No additional queries
}

// Better: Using withCount
$users = User::withCount('posts')->get();
foreach ($users as $user) {
    echo $user->posts_count; // Optimized count
}
```

#### Index Optimization
```sql
-- Check slow queries
SHOW FULL PROCESSLIST;

-- Analyze query execution
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- Add appropriate indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_created ON posts(user_id, created_at);

-- Composite index for multiple columns
CREATE INDEX idx_orders_status_date ON orders(status, created_at);
```

### 3. Caching Strategies

#### Laravel Caching
```php
// Cache expensive queries
$users = Cache::remember('active-users', 3600, function () {
    return User::where('active', true)
               ->with('profile')
               ->get();
});

// Cache configuration
'cache' => [
    'default' => env('CACHE_DRIVER', 'redis'),
    'stores' => [
        'redis' => [
            'driver' => 'redis',
            'connection' => 'cache',
        ],
    ],
];

// Route caching
php artisan route:cache

// Config caching
php artisan config:cache

// View caching
php artisan view:cache
```

#### Frontend Caching
```javascript
// Service Worker caching
self.addEventListener('fetch', (event) => {
    event.respondWith(
        caches.match(event.request)
            .then(response => response || fetch(event.request))
    );
});

// Browser caching headers
Cache-Control: public, max-age=31536000
ETag: "unique-resource-id"

// Local storage caching
const cachedData = localStorage.getItem('userData');
if (cachedData && !isExpired(cachedData)) {
    return JSON.parse(cachedData);
}
```

### 4. Code Optimization

#### Backend Optimization
```php
// Use chunking for large datasets
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// Use lazy collections for memory efficiency
User::cursor()->each(function ($user) {
    // Process user with minimal memory
});

// Optimize loops
// Bad
for ($i = 0; $i < count($array); $i++) {
    // count() called every iteration
}

// Good
$count = count($array);
for ($i = 0; $i < $count; $i++) {
    // count() called once
}
```

#### Frontend Optimization
```javascript
// Debounce expensive operations
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Virtual scrolling for long lists
// Use libraries like react-window or vue-virtual-scroll

// Lazy loading components
const LazyComponent = lazy(() => import('./HeavyComponent'));

// Memoization
const expensiveResult = useMemo(() => {
    return computeExpensiveValue(a, b);
}, [a, b]);
```

### 5. Asset Optimization

#### Image Optimization
```bash
# Compress images
jpegoptim --strip-all --all-progressive -m85 *.jpg
pngquant --quality=65-80 *.png

# Use modern formats
<picture>
    <source srcset="image.webp" type="image/webp">
    <source srcset="image.jpg" type="image/jpeg">
    <img src="image.jpg" alt="Description">
</picture>

# Lazy loading
<img src="placeholder.jpg" data-src="actual-image.jpg" loading="lazy">
```

#### Bundle Optimization
```javascript
// Webpack configuration
module.exports = {
    optimization: {
        splitChunks: {
            chunks: 'all',
            cacheGroups: {
                vendor: {
                    test: /[\\/]node_modules[\\/]/,
                    name: 'vendors',
                    priority: 10
                }
            }
        },
        minimizer: [
            new TerserPlugin({
                terserOptions: {
                    compress: {
                        drop_console: true,
                    },
                },
            }),
        ],
    }
};
```

## Performance Checklist

### Database
- [ ] Identify and fix N+1 queries
- [ ] Add appropriate indexes
- [ ] Optimize complex queries
- [ ] Implement query caching
- [ ] Use pagination for large datasets

### Backend
- [ ] Enable opcache
- [ ] Cache routes and config
- [ ] Optimize autoloader
- [ ] Use queues for heavy tasks
- [ ] Implement API response caching

### Frontend
- [ ] Minimize bundle size
- [ ] Implement code splitting
- [ ] Lazy load components
- [ ] Optimize images
- [ ] Enable compression (gzip/brotli)
- [ ] Use CDN for static assets

### Infrastructure
- [ ] Configure Redis/Memcached
- [ ] Optimize server settings
- [ ] Enable HTTP/2
- [ ] Configure load balancing
- [ ] Set up monitoring

## Monitoring Tools

### Backend Monitoring
- New Relic
- Datadog
- Laravel Telescope
- Blackfire.io
- Xdebug profiler

### Frontend Monitoring
- Google Lighthouse
- WebPageTest
- GTmetrix
- Chrome DevTools
- Bundle analyzer

## Performance Budget

### Target Metrics
- Page Load: < 3 seconds
- Time to Interactive: < 5 seconds
- First Contentful Paint: < 1.5 seconds
- API Response: < 200ms
- Database Queries: < 50ms per query
- JavaScript Bundle: < 250KB (gzipped)
- CSS Bundle: < 50KB (gzipped)

## Optimization Results

### Before
- Metric 1: [value]
- Metric 2: [value]

### After
- Metric 1: [value] (X% improvement)
- Metric 2: [value] (X% improvement)

### Impact
- User experience improvement
- Server resource reduction
- Cost savings

---
Remember: Measure first, optimize second. Profile in production-like environments.