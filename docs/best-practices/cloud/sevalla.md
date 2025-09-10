# Sevalla Best Practices

## Overview
Sevalla (formerly Kinsta) is a premium managed hosting platform optimized for WordPress, applications, and databases. These best practices help maximize performance, security, and reliability on the Sevalla platform.

## Application Deployment

### Git-Based Deployments
```yaml
# .sevalla/deploy.yml
version: 1
build:
  environment:
    NODE_VERSION: 18
    PHP_VERSION: 8.2
  commands:
    - npm ci --production
    - npm run build
    - composer install --no-dev --optimize-autoloader
    
deploy:
  commands:
    - php artisan migrate --force
    - php artisan config:cache
    - php artisan route:cache
    - php artisan view:cache
```

### Environment Configuration
```bash
# Production environment variables
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

# Sevalla Redis
REDIS_HOST=your-redis-endpoint.sevalla.com
REDIS_PASSWORD=your-redis-password
REDIS_PORT=6379

# Database configuration
DB_CONNECTION=mysql
DB_HOST=your-db-endpoint.sevalla.com
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

## Performance Optimization

### Caching Strategy
```php
// config/cache.php
'default' => env('CACHE_DRIVER', 'redis'),

'stores' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'cache',
        'lock_connection' => 'default',
    ],
    
    'memcached' => [
        'driver' => 'memcached',
        'persistent_id' => env('MEMCACHED_PERSISTENT_ID'),
        'servers' => [
            [
                'host' => env('MEMCACHED_HOST', '127.0.0.1'),
                'port' => env('MEMCACHED_PORT', 11211),
                'weight' => 100,
            ],
        ],
    ],
];
```

### CDN Integration
```javascript
// Static asset optimization
const assetUrl = process.env.SEVALLA_CDN_URL || '';

export function getAssetUrl(path) {
    if (process.env.NODE_ENV === 'production') {
        return `${assetUrl}/${path}`;
    }
    return `/${path}`;
}

// Image optimization
export function getImageUrl(path, params = {}) {
    const baseUrl = `${assetUrl}/images/${path}`;
    const queryParams = new URLSearchParams(params);
    return queryParams.toString() ? `${baseUrl}?${queryParams}` : baseUrl;
}
```

### Edge Caching
```php
// app/Http/Middleware/CacheResponse.php
class CacheResponse
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);
        
        if ($this->shouldCache($request, $response)) {
            $response->header('Cache-Control', 'public, max-age=3600');
            $response->header('X-Sevalla-Cache', 'HIT');
            $response->header('Vary', 'Accept-Encoding');
        }
        
        return $response;
    }
    
    private function shouldCache($request, $response)
    {
        return $request->isMethod('GET') 
            && $response->getStatusCode() === 200
            && !$request->user();
    }
}
```

## Database Optimization

### Connection Pooling
```php
// config/database.php
'mysql' => [
    'driver' => 'mysql',
    'host' => env('DB_HOST'),
    'port' => env('DB_PORT', '3306'),
    'database' => env('DB_DATABASE'),
    'username' => env('DB_USERNAME'),
    'password' => env('DB_PASSWORD'),
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => '',
    'strict' => true,
    'engine' => 'InnoDB',
    'options' => [
        PDO::ATTR_PERSISTENT => true, // Enable persistent connections
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8mb4' COLLATE 'utf8mb4_unicode_ci'",
    ],
],
```

### Query Optimization
```php
// Use query caching
public function getPopularProducts()
{
    return Cache::remember('popular_products', 3600, function () {
        return Product::with(['category', 'reviews'])
            ->where('status', 'active')
            ->orderByDesc('sales_count')
            ->limit(10)
            ->get();
    });
}

// Index optimization
Schema::table('products', function (Blueprint $table) {
    $table->index(['status', 'sales_count']); // Composite index
    $table->index('category_id');
    $table->fullText(['name', 'description']); // Full-text search
});
```

## Security Best Practices

### SSL/TLS Configuration
```nginx
# Force HTTPS redirect
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### Application Security
```php
// IP Whitelist for admin
class AdminIPWhitelist
{
    private $allowedIPs = [
        '192.168.1.1',
        '10.0.0.0/8',
    ];
    
    public function handle($request, Closure $next)
    {
        if (!$this->isAllowedIP($request->ip())) {
            abort(403, 'Access denied');
        }
        
        return $next($request);
    }
    
    private function isAllowedIP($ip)
    {
        foreach ($this->allowedIPs as $allowed) {
            if ($this->ipInRange($ip, $allowed)) {
                return true;
            }
        }
        return false;
    }
}
```

### WAF Rules
```json
{
  "rules": [
    {
      "id": "block_sql_injection",
      "expression": "http.request.uri.query contains \"union select\" or http.request.uri.query contains \"'; DROP\"",
      "action": "block"
    },
    {
      "id": "rate_limit_api",
      "expression": "http.request.uri.path contains \"/api/\"",
      "action": "challenge",
      "rateLimit": {
        "threshold": 100,
        "period": 60
      }
    }
  ]
}
```

## Monitoring and Logging

### Application Monitoring
```php
// config/logging.php
'channels' => [
    'sevalla' => [
        'driver' => 'custom',
        'via' => App\Logging\SevallaLogger::class,
        'level' => env('LOG_LEVEL', 'info'),
    ],
    
    'slack' => [
        'driver' => 'slack',
        'url' => env('LOG_SLACK_WEBHOOK_URL'),
        'username' => 'Sevalla Logger',
        'emoji' => ':boom:',
        'level' => 'critical',
    ],
];

// Custom logger implementation
class SevallaLogger
{
    public function __invoke(array $config)
    {
        $handler = new StreamHandler(storage_path('logs/sevalla.log'));
        $handler->setFormatter(new LineFormatter(
            "[%datetime%] %channel%.%level_name%: %message% %context%\n"
        ));
        
        return new Logger('sevalla', [$handler]);
    }
}
```

### Performance Monitoring
```javascript
// Frontend performance tracking
class PerformanceMonitor {
    constructor() {
        this.metrics = {};
        this.initializeObservers();
    }
    
    initializeObservers() {
        // Largest Contentful Paint
        new PerformanceObserver((list) => {
            const entries = list.getEntries();
            const lastEntry = entries[entries.length - 1];
            this.metrics.lcp = lastEntry.renderTime || lastEntry.loadTime;
        }).observe({ entryTypes: ['largest-contentful-paint'] });
        
        // First Input Delay
        new PerformanceObserver((list) => {
            const entries = list.getEntries();
            entries.forEach((entry) => {
                this.metrics.fid = entry.processingStart - entry.startTime;
            });
        }).observe({ entryTypes: ['first-input'] });
        
        // Cumulative Layout Shift
        let clsValue = 0;
        new PerformanceObserver((list) => {
            list.getEntries().forEach((entry) => {
                if (!entry.hadRecentInput) {
                    clsValue += entry.value;
                    this.metrics.cls = clsValue;
                }
            });
        }).observe({ entryTypes: ['layout-shift'] });
    }
    
    sendMetrics() {
        fetch('/api/metrics', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(this.metrics)
        });
    }
}
```

## Scaling Strategies

### Horizontal Scaling
```php
// Load balancer health check endpoint
Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        Cache::get('health_check');
        
        return response()->json([
            'status' => 'healthy',
            'timestamp' => now(),
            'checks' => [
                'database' => 'connected',
                'cache' => 'connected',
                'storage' => is_writable(storage_path()),
            ]
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'unhealthy',
            'error' => $e->getMessage()
        ], 503);
    }
});
```

### Queue Management
```php
// config/queue.php
'connections' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'default',
        'queue' => env('REDIS_QUEUE', 'default'),
        'retry_after' => 90,
        'block_for' => 5,
        'after_commit' => true,
    ],
],

// Job implementation with retry logic
class ProcessPayment implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    
    public $tries = 3;
    public $maxExceptions = 2;
    public $timeout = 120;
    public $backoff = [10, 30, 60];
    
    public function handle()
    {
        DB::transaction(function () {
            // Process payment logic
        });
    }
    
    public function failed(Throwable $exception)
    {
        // Notify team of failure
        Log::critical('Payment processing failed', [
            'exception' => $exception->getMessage(),
            'job' => self::class,
        ]);
    }
}
```

## Backup and Disaster Recovery

### Automated Backups
```bash
#!/bin/bash
# backup.sh - Sevalla backup script

# Database backup
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Upload to S3
aws s3 cp backup_*.sql.gz s3://your-backup-bucket/database/

# Application files backup
tar -czf app_backup_$(date +%Y%m%d_%H%M%S).tar.gz --exclude='vendor' --exclude='node_modules' /path/to/app

# Cleanup old backups (keep last 30 days)
find . -name "backup_*.sql.gz" -mtime +30 -delete
```

### Recovery Procedures
```php
// Maintenance mode with custom page
class MaintenanceMode
{
    public function handle($request, Closure $next)
    {
        if (app()->isDownForMaintenance()) {
            $data = json_decode(
                file_get_contents(storage_path('framework/down')),
                true
            );
            
            if (isset($data['secret']) && $request->path() === $data['secret']) {
                return $next($request);
            }
            
            return response()->view('maintenance', [
                'message' => $data['message'] ?? 'We\'ll be right back!',
                'retry' => $data['retry'] ?? 60,
            ], 503);
        }
        
        return $next($request);
    }
}
```

## WordPress-Specific Optimizations

### Object Caching
```php
// wp-config.php
define('WP_CACHE', true);
define('WP_CACHE_KEY_SALT', 'your-unique-salt');

// Redis object cache
define('WP_REDIS_HOST', getenv('REDIS_HOST'));
define('WP_REDIS_PASSWORD', getenv('REDIS_PASSWORD'));
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_MAXTTL', 86400);
```

### Database Optimization
```sql
-- Optimize WordPress tables
OPTIMIZE TABLE wp_posts;
OPTIMIZE TABLE wp_postmeta;
OPTIMIZE TABLE wp_options;

-- Clean up post revisions
DELETE FROM wp_posts WHERE post_type = 'revision';

-- Clean up transients
DELETE FROM wp_options WHERE option_name LIKE '_transient_%';
DELETE FROM wp_options WHERE option_name LIKE '_site_transient_%';
```

## Cost Optimization

### Resource Management
```yaml
# .sevalla/resources.yml
application:
  cpu: 2
  memory: 4Gi
  storage: 50Gi
  
scaling:
  min_replicas: 2
  max_replicas: 10
  target_cpu_utilization: 70
  
schedule:
  - name: "business_hours"
    cron: "0 9 * * 1-5"
    replicas: 5
  - name: "after_hours"
    cron: "0 18 * * 1-5"
    replicas: 2
```

### CDN Optimization
```javascript
// Selective CDN usage
const cdnAssets = [
    '/images/',
    '/videos/',
    '/fonts/',
    '/css/',
    '/js/'
];

function shouldUseCDN(path) {
    return cdnAssets.some(asset => path.startsWith(asset));
}

function getOptimizedUrl(path) {
    if (shouldUseCDN(path)) {
        return `${process.env.CDN_URL}${path}`;
    }
    return path;
}
```

## Development Workflow

### Local Development
```bash
# .env.local
SEVALLA_ENV=local
API_URL=http://localhost:3000
DB_HOST=127.0.0.1
REDIS_HOST=127.0.0.1

# Docker setup for local development
docker-compose up -d mysql redis
npm run dev
php artisan serve
```

### Staging Environment
```yaml
# .sevalla/staging.yml
environment: staging
domain: staging.yourdomain.com
ssl: auto
basic_auth:
  enabled: true
  users:
    - username: admin
      password: $STAGING_PASSWORD
```

## Troubleshooting

### Debug Mode
```php
// Safe debug mode for production
if (request()->hasHeader('X-Debug-Token') 
    && request()->header('X-Debug-Token') === env('DEBUG_TOKEN')) {
    config(['app.debug' => true]);
    config(['app.log_level' => 'debug']);
}
```

### Performance Profiling
```php
class ProfileMiddleware
{
    public function handle($request, Closure $next)
    {
        $start = microtime(true);
        
        $response = $next($request);
        
        $duration = microtime(true) - $start;
        
        $response->headers->set('X-Response-Time', round($duration * 1000) . 'ms');
        
        if ($duration > 1) {
            Log::warning('Slow request detected', [
                'url' => $request->fullUrl(),
                'duration' => $duration,
                'method' => $request->method(),
            ]);
        }
        
        return $response;
    }
}
```

## Conclusion

Sevalla provides a robust platform for hosting modern applications with built-in performance optimization, security, and scaling capabilities. Following these best practices ensures optimal resource utilization, cost efficiency, and application reliability on the Sevalla platform.