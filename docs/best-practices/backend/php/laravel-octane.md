# Laravel Octane Best Practices

## Introduction

Laravel Octane supercharges Laravel application performance by serving applications through high-performance servers including Swoole and RoadRunner. Instead of bootstrapping the framework on every request like traditional PHP applications, Octane keeps your application in memory between requests, dramatically reducing overhead and response times.

First released in April 2021, Octane represents a paradigm shift in how Laravel applications handle requests. The current stable version seamlessly integrates with Laravel 10 and 11, providing production-ready performance improvements without sacrificing Laravel's developer experience.

## Architecture Overview

### How It Works

Octane fundamentally changes the PHP execution model. Traditional PHP applications follow a share-nothing architecture where each request spawns a new process, loads all dependencies, bootstraps the framework, handles the request, and then terminates. This cycle repeats for every single request.

With Octane, your application boots once and stays resident in memory. When requests arrive, they're handled by pre-warmed workers that already have your application loaded. This eliminates the bootstrap overhead that typically consumes 20-50ms per request in complex applications.

### Request Lifecycle

1. **Application Bootstrap**: Octane starts and loads your Laravel application into memory
2. **Worker Initialization**: Multiple worker processes are spawned, each containing a copy of your application
3. **Request Reception**: The server (Swoole/RoadRunner) receives incoming HTTP requests
4. **Worker Assignment**: Requests are distributed to available workers
5. **Request Processing**: Workers process requests using the in-memory application instance
6. **Response Delivery**: Responses are sent back through the server to clients
7. **Worker Reset**: After a configured number of requests, workers restart to prevent memory leaks

### Process Management Model

Octane employs a master-worker architecture. The master process manages worker lifecycles, handles signals, and coordinates request distribution. Worker processes handle actual request processing. This model provides fault tolerance - if a worker crashes, the master spawns a replacement without affecting other workers.

## Installation & Setup

### System Requirements

- PHP 8.0 or higher
- Laravel 8.0 or higher
- One of the following servers:
  - Swoole 4.8+ (recommended for WebSocket support)
  - RoadRunner 2.0+ (recommended for Windows compatibility)
- Memory: Minimum 512MB per worker
- CPU: Multi-core recommended for optimal performance

### Installation Steps

```bash
# Install Octane via Composer
composer require laravel/octane

# Install and configure your chosen server
php artisan octane:install

# For Swoole installation
pecl install swoole

# For RoadRunner installation (handled automatically by octane:install)
```

### Basic Configuration

```php
// config/octane.php
return [
    'server' => env('OCTANE_SERVER', 'swoole'),

    'https' => env('OCTANE_HTTPS', false),

    'listeners' => [
        WorkerStarting::class => [
            EnsureFrontendRequestsAreStateful::class,
        ],

        RequestReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
            ...Octane::prepareApplicationForNextRequest(),
        ],
    ],

    'warm' => [
        ...Octane::defaultServicesToWarm(),
    ],

    'flush' => [
        //
    ],

    'swoole' => [
        'options' => [
            'worker_num' => env('SWOOLE_WORKERS', 'auto'),
            'task_worker_num' => env('SWOOLE_TASK_WORKERS', 'auto'),
            'max_request' => env('SWOOLE_MAX_REQUESTS', 500),
            'buffer_output_size' => env('SWOOLE_BUFFER_SIZE', 10 * 1024 * 1024),
        ],
    ],
];
```

## Use Cases

### Ideal Scenarios

**High-Traffic APIs**: Applications serving millions of API requests daily benefit from sub-10ms response times. Payment gateways, mobile app backends, and microservices see 10-50x throughput improvements.

**Real-Time Applications**: WebSocket connections for chat applications, live notifications, and collaborative tools leverage Swoole's coroutine support for handling thousands of concurrent connections.

**Microservices Architecture**: Service-to-service communication benefits from reduced latency. Internal APIs can handle significantly more requests without scaling horizontally.

**Data Processing Pipelines**: Applications that process large datasets or perform complex calculations benefit from keeping expensive computations in memory between requests.

### Real-World Applications

E-commerce platforms use Octane to handle flash sales where traffic spikes 100x within seconds. Financial services leverage it for real-time trading platforms requiring consistent sub-millisecond processing. SaaS applications employ Octane to serve multi-tenant architectures where bootstrap overhead significantly impacts performance.

### Performance Expectations

Typical improvements range from 200% to 2000% depending on application complexity. Simple applications see modest gains while complex applications with heavy bootstrap processes experience dramatic improvements. Response times often drop from 50-100ms to 5-20ms for typical web requests.

## Best Practices

### Configuration Optimization

**Worker Management**: Set worker count based on your workload profile. CPU-bound tasks benefit from workers equal to CPU cores. I/O-bound tasks can use 2-4x CPU cores. Monitor memory usage to find the optimal balance.

```php
'swoole' => [
    'options' => [
        // For CPU-bound tasks
        'worker_num' => swoole_cpu_num(),

        // For I/O-bound tasks
        'worker_num' => swoole_cpu_num() * 4,

        // Prevent memory leaks
        'max_request' => 1000,

        // Task workers for async processing
        'task_worker_num' => swoole_cpu_num() * 2,
    ],
],
```

### Resource Management

**Memory Leak Prevention**: Static properties and singleton instances persist between requests. Clear stateful services after each request:

```php
// In a service provider
public function register()
{
    $this->app->singleton(Repository::class, function () {
        return new Repository();
    });

    // Reset after each request
    $this->app->afterResolving(Repository::class, function ($repo) {
        Octane::forgetInstance(Repository::class);
    });
}
```

**Database Connection Pooling**: Configure connection pools to handle concurrent requests efficiently:

```php
'database' => [
    'pool' => [
        'min' => 10,
        'max' => 100,
    ],
],
```

### Common Patterns

**Concurrent Task Processing**: Leverage Octane's concurrent features for parallel processing:

```php
use Laravel\Octane\Facades\Octane;

[$users, $orders, $stats] = Octane::concurrently([
    fn () => User::all(),
    fn () => Order::today()->get(),
    fn () => Statistics::calculate(),
]);
```

**Table Management**: Use Octane tables for shared memory storage:

```php
use Laravel\Octane\Facades\Octane;

Octane::table('users')->set('user:1', [
    'name' => 'Taylor Otwell',
    'email' => 'taylor@laravel.com',
]);

$user = Octane::table('users')->get('user:1');
```

## Pros & Cons

### Pros

- **Performance**: 10-50x throughput improvement over traditional PHP-FPM
- **Reduced Latency**: Sub-10ms response times for most requests
- **Resource Efficiency**: Lower CPU usage due to eliminated bootstrap overhead
- **WebSocket Support**: Native support for real-time features with Swoole
- **Concurrent Processing**: Built-in support for parallel task execution
- **Shared Memory**: Octane tables enable ultra-fast data sharing between workers

### Cons

- **Memory Management**: Requires careful handling to prevent memory leaks
- **Compatibility**: Not all packages work with persistent applications
- **Debugging Complexity**: Traditional debugging tools may not work as expected
- **Development Workflow**: File changes require server restart without watching
- **Static Variables**: Global state persists between requests causing unexpected behavior
- **Learning Curve**: Requires understanding of long-running process implications

## Comparison Matrix

| Feature | Laravel Octane | PHP-FPM | FrankenPHP | Open Swoole |
|---------|---------------|---------|------------|-------------|
| **Request/sec** | 5,000-50,000 | 500-2,000 | 3,000-15,000 | 10,000-100,000 |
| **Memory Usage** | High (persistent) | Low (per request) | Medium | High (persistent) |
| **Startup Time** | Slow (once) | Fast (per request) | Fast | Slow (once) |
| **WebSocket Support** | Yes (Swoole) | No | Yes | Yes |
| **Windows Support** | Yes (RoadRunner) | Yes | Yes | Limited |
| **Debugging** | Complex | Simple | Simple | Complex |
| **Package Compatibility** | Most | All | All | Limited |
| **Learning Curve** | Moderate | Low | Low | High |

## Security and Safety

### Security Configuration Best Practices

**Environment Isolation**: Keep production secrets out of worker memory:

```php
// Clear sensitive data after processing
public function handle($request)
{
    $apiKey = env('THIRD_PARTY_API_KEY');
    $result = $this->processWithApiKey($apiKey);
    unset($apiKey); // Clear from memory
    return $result;
}
```

**Request Isolation**: Ensure requests don't leak data between users:

```php
// Reset authentication state
Octane::prepareApplicationForNextRequest([
    'auth',
    'session',
    'view',
]);
```

### Common Vulnerabilities and Mitigations

**Memory Disclosure**: Static properties can leak sensitive data. Solution: Clear static properties after each request or avoid them entirely.

**Session Hijacking**: Sessions may persist incorrectly. Solution: Properly configure session handling and flush session data between requests.

### Update and Patching Strategies

Implement zero-downtime deployments using rolling restarts:

```bash
# Graceful reload without dropping connections
php artisan octane:reload
```

### Resource Limit Configurations

Prevent DoS attacks through proper limits:

```php
'swoole' => [
    'options' => [
        'max_request' => 1000, // Restart workers periodically
        'max_request_execution_time' => 30, // Timeout long requests
        'package_max_length' => 10 * 1024 * 1024, // Limit request size
        'upload_max_filesize' => 50 * 1024 * 1024, // Limit uploads
    ],
],
```

## Best Practice Summary

1. **Start Simple**: Begin with default configurations and optimize based on metrics
2. **Monitor Everything**: Track memory usage, response times, and worker health
3. **Test Thoroughly**: Load test with realistic traffic patterns before production
4. **Handle State Carefully**: Clear stateful services and static properties between requests
5. **Plan for Failures**: Implement health checks and automatic worker recovery
6. **Update Regularly**: Keep Octane and server implementations current
7. **Document Gotchas**: Maintain a list of package incompatibilities and workarounds

## Conclusion

Laravel Octane transforms Laravel from a traditional PHP framework into a high-performance application server competitive with Node.js and Go. While it introduces complexity around state management and debugging, the performance gains justify the learning curve for applications requiring high throughput or low latency.

Success with Octane requires understanding its persistent nature and carefully managing application state. Teams should evaluate their specific needs, considering factors like traffic patterns, response time requirements, and team expertise before adoption.

For applications serving thousands of requests per second, handling WebSocket connections, or requiring consistent sub-20ms response times, Octane provides a production-tested solution that maintains Laravel's excellent developer experience while delivering exceptional performance.