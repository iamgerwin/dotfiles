# Open Swoole Best Practices

## Introduction

Open Swoole is a high-performance, coroutine-based PHP extension that transforms PHP into a language capable of building scalable concurrent applications. Forked from Swoole in 2021, Open Swoole focuses on open-source development, enhanced PHP compatibility, and providing enterprise-grade asynchronous programming capabilities. It enables PHP developers to write non-blocking I/O applications similar to Node.js or Go while maintaining PHP's familiar syntax.

The extension provides native coroutines, channels, and async I/O operations, allowing PHP to handle thousands of concurrent connections with minimal resource usage. Open Swoole 4.x supports PHP 8.0+ and continues to evolve with strong community backing, offering features like HTTP/2, WebSocket servers, TCP/UDP servers, and coroutine-based clients for Redis, MySQL, and PostgreSQL.

## Architecture Overview

### How It Works

Open Swoole extends PHP at the engine level, implementing an event-driven, non-blocking I/O model using epoll (Linux), kqueue (BSD/macOS), and IOCP (Windows). Unlike traditional PHP that follows a share-nothing architecture, Open Swoole maintains application state in memory across requests, operating more like Node.js or Java application servers.

The extension provides coroutines that allow asynchronous operations without callback hell. When a coroutine encounters I/O operations, it yields control to the scheduler, which switches to another coroutine. This cooperative multitasking model enables thousands of concurrent operations with minimal overhead.

### Request Lifecycle

1. **Server Initialization**: Open Swoole server starts and loads application code
2. **Worker Process Spawn**: Multiple worker processes are created based on configuration
3. **Event Loop Start**: Each worker runs an event loop waiting for connections
4. **Connection Accept**: New connections are accepted and assigned to workers
5. **Coroutine Creation**: Each request spawns a lightweight coroutine
6. **Async Processing**: Coroutines handle requests with non-blocking I/O
7. **Response Delivery**: Results are sent back to clients asynchronously
8. **Coroutine Cleanup**: Coroutines are destroyed after request completion

### Process Management Model

Open Swoole uses a multi-process architecture with several process types:

- **Master Process**: Manages worker processes and handles signals
- **Manager Process**: Monitors and restarts worker processes
- **Worker Processes**: Handle business logic and client requests
- **Task Workers**: Process time-consuming tasks asynchronously
- **User Processes**: Custom processes for specialized tasks

Each worker process can handle thousands of coroutines concurrently, providing massive scalability.

## Installation & Setup

### System Requirements

- PHP 8.0 or higher
- Linux, macOS, or Windows (WSL2)
- GCC 4.8+ or Clang
- Memory: Minimum 512MB, recommended 2GB+
- CPU: Multi-core processor recommended
- Development headers for PHP

### Installation Steps

```bash
# Install via PECL (recommended)
pecl install openswoole

# Or compile from source
git clone https://github.com/openswoole/swoole-src.git
cd swoole-src
phpize
./configure --enable-openssl --enable-http2 --enable-mysqlnd
make && make install

# Add to php.ini
echo "extension=openswoole.so" >> php.ini

# Verify installation
php -m | grep openswoole
```

### Basic Configuration

```php
<?php
use OpenSwoole\Http\Server;
use OpenSwoole\Http\Request;
use OpenSwoole\Http\Response;

$server = new Server("0.0.0.0", 9501);

$server->set([
    'worker_num' => 4,
    'task_worker_num' => 2,
    'max_coroutine' => 10000,
    'dispatch_mode' => 3,
    'daemonize' => false,
    'log_file' => '/var/log/openswoole.log',
    'log_level' => 1,
    'max_request' => 10000,
    'buffer_output_size' => 32 * 1024 * 1024,
]);

$server->on("start", function ($server) {
    echo "OpenSwoole HTTP server started at http://0.0.0.0:9501\n";
});

$server->on("request", function (Request $request, Response $response) {
    $response->header("Content-Type", "text/plain");
    $response->end("Hello from Open Swoole\n");
});

$server->start();
```

## Use Cases

### Ideal Scenarios

**Real-Time Applications**: Chat systems, gaming servers, and live collaboration tools benefit from WebSocket support and low-latency communication. Open Swoole handles millions of concurrent WebSocket connections efficiently.

**High-Performance APIs**: RESTful and GraphQL APIs requiring microsecond response times. Coroutine-based database clients eliminate blocking operations, enabling true concurrent request processing.

**Microservices**: Service mesh implementations with built-in HTTP/2, gRPC support, and service discovery. Coroutine HTTP clients enable efficient service-to-service communication.

**IoT Platforms**: MQTT brokers and IoT gateways handling massive device connections. Event-driven architecture efficiently manages thousands of persistent connections.

### Real-World Applications

Trading platforms use Open Swoole for real-time market data streaming and order execution. Video streaming services leverage it for signaling servers and presence systems. Online gaming companies build multiplayer game servers handling thousands of concurrent players. Analytics platforms process billions of events using Open Swoole's async capabilities.

### Performance Expectations

Open Swoole typically achieves 10,000-100,000 requests per second on modern hardware. WebSocket servers handle 100,000+ concurrent connections on a single server. Response times consistently measure in microseconds for cached data. Memory usage remains stable at 50-200MB per worker regardless of connection count.

## Best Practices

### Configuration Optimization

**Worker Tuning**: Configure workers based on workload characteristics:

```php
$server->set([
    // CPU-bound tasks
    'worker_num' => swoole_cpu_num(),

    // I/O-bound tasks
    'worker_num' => swoole_cpu_num() * 2,

    // Task workers for blocking operations
    'task_worker_num' => swoole_cpu_num(),

    // Coroutine settings
    'max_coroutine' => 100000,
    'enable_coroutine' => true,

    // Connection settings
    'max_connection' => 10000,
    'heartbeat_check_interval' => 60,
    'heartbeat_idle_time' => 120,
]);
```

### Resource Management

**Coroutine Pool Management**: Implement connection pooling for databases:

```php
use OpenSwoole\Coroutine\Channel;
use OpenSwoole\Coroutine\MySQL;

class MySQLPool {
    private Channel $pool;
    private array $config;

    public function __construct(array $config, int $size = 10) {
        $this->config = $config;
        $this->pool = new Channel($size);

        for ($i = 0; $i < $size; $i++) {
            $mysql = new MySQL();
            $mysql->connect($this->config);
            $this->pool->push($mysql);
        }
    }

    public function get(): MySQL {
        return $this->pool->pop();
    }

    public function put(MySQL $mysql): void {
        $this->pool->push($mysql);
    }
}
```

### Common Patterns

**Async Task Processing**: Delegate heavy operations to task workers:

```php
$server->on('request', function ($request, $response) use ($server) {
    // Non-blocking task dispatch
    $task_id = $server->task([
        'type' => 'email',
        'data' => $request->post
    ]);

    $response->end(json_encode(['task_id' => $task_id]));
});

$server->on('task', function ($server, $task_id, $reactor_id, $data) {
    // Process heavy task
    switch ($data['type']) {
        case 'email':
            sendEmail($data['data']);
            break;
    }

    return ['status' => 'completed'];
});
```

**WebSocket Implementation**: Build real-time features:

```php
$server = new OpenSwoole\WebSocket\Server("0.0.0.0", 9502);

$server->on('open', function ($server, $request) {
    echo "Connection opened: {$request->fd}\n";
});

$server->on('message', function ($server, $frame) {
    // Broadcast to all connections
    foreach ($server->connections as $fd) {
        if ($server->isEstablished($fd)) {
            $server->push($fd, $frame->data);
        }
    }
});

$server->on('close', function ($server, $fd) {
    echo "Connection closed: {$fd}\n";
});

$server->start();
```

## Pros & Cons

### Pros

- **Extreme Performance**: 10-100x faster than traditional PHP for concurrent workloads
- **True Async**: Native coroutines without callback complexity
- **Memory Efficient**: Handles thousands of connections with minimal memory
- **Built-in Features**: HTTP/2, WebSocket, TCP/UDP servers included
- **Coroutine Clients**: Async MySQL, Redis, HTTP clients built-in
- **Process Management**: Sophisticated worker and task management
- **Hot Reload**: Code updates without dropping connections

### Cons

- **Learning Curve**: Requires understanding of async programming concepts
- **Debugging Difficulty**: Traditional debugging tools don't work well
- **Extension Dependency**: Requires compilation and maintenance
- **Limited Compatibility**: Many PHP libraries assume blocking I/O
- **Memory Leaks Risk**: Improper cleanup causes memory issues
- **Development Complexity**: Async code is harder to write and maintain
- **Platform Limitations**: Best performance on Linux systems only

## Comparison Matrix

| Feature | Open Swoole | PHP-FPM | FrankenPHP | Laravel Octane | RoadRunner |
|---------|-------------|---------|------------|----------------|------------|
| **Request/sec** | 10,000-100,000 | 100-500 | 3,000-15,000 | 5,000-50,000 | 4,000-20,000 |
| **Concurrent Connections** | 100,000+ | 100-500 | 1,000-5,000 | 10,000-50,000 | 5,000-20,000 |
| **Memory per Connection** | <1KB | 20-50MB | 5-10MB | 2-5MB | 5-10MB |
| **Coroutine Support** | Native | No | No | Via Swoole | No |
| **WebSocket** | Native | No | Via proxy | Native (Swoole) | Plugin |
| **Learning Curve** | Very High | Low | Low | Moderate | Moderate |
| **PHP Compatibility** | Limited | Full | High | High | High |
| **Production Maturity** | Good | Excellent | Good | Good | Good |

## Security and Safety

### Security Configuration Best Practices

**Input Validation**: Implement strict input validation:

```php
$server->on('request', function ($request, $response) {
    // Validate request size
    if (strlen($request->rawContent()) > 1024 * 1024) {
        $response->status(413);
        $response->end('Request too large');
        return;
    }

    // Rate limiting per IP
    static $requests = [];
    $ip = $request->server['remote_addr'];
    $requests[$ip] = ($requests[$ip] ?? 0) + 1;

    if ($requests[$ip] > 100) {
        $response->status(429);
        $response->end('Too many requests');
        return;
    }
});
```

**Secure WebSocket**: Implement authentication for WebSocket:

```php
$server->on('handshake', function ($request, $response) {
    // Verify token
    $token = $request->header['authorization'] ?? '';
    if (!validateToken($token)) {
        $response->status(401);
        $response->end();
        return false;
    }

    // Complete handshake
    $key = $request->header['sec-websocket-key'];
    $accept = base64_encode(sha1($key . '258EAFA5-E914-47DA-95CA-C5AB0DC85B11', true));

    $response->header('Upgrade', 'websocket');
    $response->header('Connection', 'Upgrade');
    $response->header('Sec-WebSocket-Accept', $accept);
    $response->status(101);
    $response->end();

    return true;
});
```

### Common Vulnerabilities and Mitigations

**Memory Exhaustion**: Prevent memory attacks:

```php
$server->set([
    'max_connection' => 10000,
    'max_request' => 1000,
    'buffer_output_size' => 32 * 1024 * 1024,
    'package_max_length' => 2 * 1024 * 1024,
]);
```

**Coroutine Leaks**: Ensure proper cleanup:

```php
OpenSwoole\Coroutine::create(function () {
    try {
        // Coroutine logic
    } finally {
        // Always cleanup resources
        OpenSwoole\Coroutine::defer(function () {
            // Cleanup code
        });
    }
});
```

### Update and Patching Strategies

Implement graceful reloading:

```php
// Signal handler for reload
$server->on('managerStart', function ($server) {
    OpenSwoole\Process::signal(SIGUSR1, function () use ($server) {
        $server->reload();
    });
});

// Reload command
// kill -USR1 `cat /var/run/openswoole.pid`
```

### Resource Limit Configurations

Configure limits to prevent DoS:

```php
$server->set([
    // Connection limits
    'max_connection' => 10000,
    'max_request' => 10000,

    // Memory limits
    'buffer_output_size' => 32 * 1024 * 1024,
    'socket_buffer_size' => 128 * 1024 * 1024,

    // Timeout settings
    'request_slowlog_timeout' => 2,
    'request_slowlog_file' => '/var/log/slow.log',

    // Coroutine limits
    'max_coroutine' => 100000,
    'enable_deadlock_check' => true,
]);
```

## Best Practice Summary

1. **Master Coroutines First**: Understand coroutine concepts before production use
2. **Use Connection Pools**: Always pool database and cache connections
3. **Monitor Memory**: Track memory usage and implement cleanup strategies
4. **Handle Errors Properly**: Implement comprehensive error handling in coroutines
5. **Load Test Extensively**: Test with realistic concurrent connection loads
6. **Profile Performance**: Use built-in profiling tools to identify bottlenecks
7. **Document Async Patterns**: Maintain clear documentation of async workflows
8. **Plan for Debugging**: Implement logging strategies for async operations

## Conclusion

Open Swoole represents the cutting edge of PHP performance, offering capabilities that rival dedicated async platforms like Node.js and Go. Its coroutine-based model and comprehensive async features enable PHP developers to build highly scalable applications that were previously impossible with traditional PHP.

The extreme performance comes with significant complexity. Teams must invest in understanding async programming, coroutine management, and the implications of long-running processes. The learning curve is steep, but for applications requiring extreme concurrency, real-time features, or microsecond response times, Open Swoole provides unmatched capabilities within the PHP ecosystem.

For teams with the expertise to handle its complexity and applications that can leverage its async capabilities, Open Swoole offers transformative performance improvements. However, traditional applications or teams without async programming experience should carefully evaluate whether the complexity is justified by their performance requirements.