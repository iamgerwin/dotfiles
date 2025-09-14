# RoadRunner Best Practices

## Introduction

RoadRunner is a high-performance PHP application server and process manager written in Go. It keeps PHP applications in memory between requests, eliminating bootstrap overhead while providing a robust infrastructure for building microservices, queue processing, and WebSocket applications. Unlike PHP extensions like Swoole, RoadRunner runs as a separate process, communicating with PHP workers through a lightweight protocol, making it compatible with any PHP application without extensions.

First released in 2018 by Spiral Scout, RoadRunner has evolved into a comprehensive application server supporting multiple protocols and integrations. Version 2.x brought significant improvements including a plugin architecture, native Windows support, and seamless integration with major PHP frameworks. The current version provides production-ready features for enterprises requiring high performance without sacrificing PHP compatibility.

## Architecture Overview

### How It Works

RoadRunner operates as a Go-based application server that manages pools of PHP worker processes. Communication between RoadRunner and PHP workers occurs through Goridge - a high-performance IPC protocol supporting various transports including pipes, TCP sockets, and Unix sockets. This architecture keeps PHP workers warm between requests while maintaining process isolation for stability.

The server pre-loads your PHP application into worker processes that stay resident in memory. When requests arrive, RoadRunner dispatches them to available workers through the communication protocol. Workers process requests using the already-loaded application and return responses to RoadRunner for delivery to clients.

### Request Lifecycle

1. **Server Bootstrap**: RoadRunner starts and reads configuration
2. **Worker Pool Creation**: PHP worker processes are spawned and application loaded
3. **Request Reception**: RoadRunner receives HTTP/gRPC/WebSocket requests
4. **Load Balancing**: Requests are distributed to available workers
5. **Worker Processing**: PHP workers handle requests with pre-loaded application
6. **Response Return**: Workers send responses back through Goridge
7. **Client Delivery**: RoadRunner sends responses to clients
8. **Worker Recycling**: Workers restart after configured requests/memory limits

### Process Management Model

RoadRunner implements a supervisor pattern where the Go server manages PHP worker lifecycles. The architecture includes:

- **Application Server**: Main Go process handling connections and routing
- **Worker Pools**: Groups of PHP processes for different tasks
- **Plugin System**: Modular components for HTTP, gRPC, jobs, WebSockets
- **Relay Protocol**: Goridge communication between Go and PHP

This model provides excellent fault tolerance - crashed workers are automatically replaced without affecting others.

## Installation & Setup

### System Requirements

- PHP 7.4 or higher
- Operating System: Linux, macOS, Windows
- Memory: Minimum 256MB per worker
- CPU: Any modern processor
- No PHP extensions required

### Installation Steps

```bash
# Download RoadRunner binary
curl -s https://raw.githubusercontent.com/roadrunner-server/roadrunner/master/download-latest.sh | sh

# Or use Composer
composer require spiral/roadrunner:^2.0 nyholm/psr7
./vendor/bin/rr get-binary

# Or use Docker
docker pull spiralscout/roadrunner:2.12.3

# Verify installation
./rr version
```

### Basic Configuration

```yaml
# .rr.yaml
version: "2.7"

server:
  command: "php worker.php"
  relay: pipes

http:
  address: 0.0.0.0:8080
  pool:
    num_workers: 4
    max_jobs: 500
    allocate_timeout: 60s
    destroy_timeout: 60s
  middleware:
    - gzip
    - headers

logs:
  level: info
  channels:
    http:
      level: info
      output: stdout
    server:
      level: info
      output: stderr

# Worker file (worker.php)
<?php
use Spiral\RoadRunner;
use Nyholm\Psr7;

include "vendor/autoload.php";

$worker = RoadRunner\Worker::create();
$psrFactory = new Psr7\Factory\Psr17Factory();

$psr7 = new RoadRunner\Http\PSR7Worker($worker, $psrFactory, $psrFactory, $psrFactory);

while ($req = $psr7->waitRequest()) {
    try {
        $resp = new Psr7\Response();
        $resp->getBody()->write("Hello from RoadRunner!");

        $psr7->respond($resp);
    } catch (\Throwable $e) {
        $psr7->getWorker()->error((string)$e);
    }
}
```

## Use Cases

### Ideal Scenarios

**Laravel/Symfony Applications**: Seamless integration with major frameworks through official packages. Applications see 10-20x performance improvements with minimal code changes.

**Microservices Architecture**: Built-in support for gRPC, service discovery, and distributed tracing. Protocol buffer support enables efficient inter-service communication.

**Queue Processing**: Native job queue implementation with multiple brokers (AMQP, SQS, Beanstalk). Workers process jobs with pre-loaded application context for maximum efficiency.

**WebSocket Applications**: Built-in WebSocket server with broadcasting and presence channels. Integrates with Centrifugo for scalable real-time features.

### Real-World Applications

E-commerce platforms use RoadRunner to handle traffic spikes during sales events. Financial services leverage it for real-time transaction processing with guaranteed delivery. SaaS providers utilize its multi-tenancy support for isolated customer environments. Media companies employ it for video transcoding pipelines and real-time analytics.

### Performance Expectations

RoadRunner typically achieves 4,000-20,000 requests per second depending on application complexity. Response times improve from 50-100ms to 5-20ms for typical web applications. Memory usage stabilizes at 30-100MB per worker. CPU utilization decreases by 60-80% compared to PHP-FPM for the same throughput.

## Best Practices

### Configuration Optimization

**Worker Pool Tuning**: Configure pools based on workload:

```yaml
http:
  pool:
    # CPU-bound applications
    num_workers: 4  # Number of CPU cores
    max_jobs: 1000

    # I/O-bound applications
    num_workers: 16  # 4x CPU cores
    max_jobs: 500

    # Memory management
    ttl: 300s  # Worker lifetime
    idle_ttl: 10s  # Idle timeout
    max_worker_memory: 128  # MB

    # Supervisor settings
    supervisor:
      watch_tick: 1s
      ttl: 0
      idle_ttl: 10s
      exec_ttl: 10s
      max_worker_memory: 128
```

### Resource Management

**Memory Leak Prevention**: Configure automatic worker recycling:

```yaml
http:
  pool:
    num_workers: 8
    max_jobs: 1000  # Restart after 1000 requests
    max_worker_memory: 128  # Restart if memory exceeds 128MB
    allocate_timeout: 10s
    destroy_timeout: 10s

# Monitor memory in PHP worker
$worker = RoadRunner\Worker::create();
$psr7 = new RoadRunner\Http\PSR7Worker($worker, $psrFactory);

while ($req = $psr7->waitRequest()) {
    // Process request...

    // Check memory usage
    if (memory_get_usage(true) > 100 * 1024 * 1024) {
        $worker->stop();
        break;
    }
}
```

### Common Patterns

**Laravel Integration**: Configure Laravel with Octane:

```bash
composer require laravel/octane spiral/roadrunner

php artisan octane:install --server=roadrunner
```

```yaml
# octane-rr.yaml
version: "2.7"

server:
  command: "php artisan octane:start --server=roadrunner --host=0.0.0.0 --port=8000"
  relay: pipes

http:
  address: 0.0.0.0:8000
  pool:
    num_workers: 4
    max_jobs: 500

# Start server
php artisan octane:start --server=roadrunner
```

**Queue Processing**: Implement job queues:

```yaml
jobs:
  pool:
    num_workers: 10
    max_jobs: 100
    allocate_timeout: 60s
    destroy_timeout: 60s

  pipelines:
    default:
      driver: memory
      config:
        priority: 10
        prefetch: 10

  consume:
    - default

# PHP Job Processor
$consumer = new Spiral\RoadRunner\Jobs\Consumer();

while ($task = $consumer->waitTask()) {
    try {
        // Process job
        $payload = $task->getPayload();
        processJob($payload);

        $task->complete();
    } catch (\Throwable $e) {
        $task->error($e->getMessage());
    }
}
```

## Pros & Cons

### Pros

- **High Performance**: 10-20x faster than PHP-FPM for most applications
- **No Extensions Required**: Works with standard PHP installation
- **Framework Support**: Official integration with Laravel, Symfony, Spiral
- **Protocol Support**: HTTP/1.1, HTTP/2, gRPC, WebSocket built-in
- **Queue Processing**: Native job queue with multiple broker support
- **Cross-Platform**: Native support for Linux, macOS, Windows
- **Metrics & Monitoring**: Built-in Prometheus metrics and health checks
- **Developer Friendly**: Hot reload and debugging support

### Cons

- **Memory Usage**: Higher memory consumption than PHP-FPM
- **Learning Curve**: Requires understanding of long-running processes
- **Static Variables**: Global state persists between requests
- **Debugging Complexity**: Traditional debugging tools need adaptation
- **Package Compatibility**: Some packages assume request isolation
- **Configuration Overhead**: YAML configuration can be complex

## Comparison Matrix

| Feature | RoadRunner | PHP-FPM | FrankenPHP | Laravel Octane | Open Swoole |
|---------|------------|---------|------------|----------------|-------------|
| **Request/sec** | 4,000-20,000 | 100-500 | 3,000-15,000 | 5,000-50,000 | 10,000-100,000 |
| **Memory per Worker** | 30-100MB | 20-50MB | 10-30MB | 50-200MB | 50-200MB |
| **PHP Extensions** | None | None | None | Optional | Required |
| **Windows Support** | Native | Native | WSL2 | Limited | WSL2 |
| **gRPC Support** | Native | No | No | No | Extension |
| **Queue Processing** | Native | No | No | Via packages | Manual |
| **Framework Integration** | Excellent | Universal | Good | Laravel only | Limited |
| **Learning Curve** | Moderate | Low | Low | Moderate | High |

## Security and Safety

### Security Configuration Best Practices

**Access Control**: Implement proper security headers and limits:

```yaml
http:
  address: 127.0.0.1:8080  # Bind to localhost only

  middleware:
    - headers:
        response:
          X-Frame-Options: "DENY"
          X-Content-Type-Options: "nosniff"
          X-XSS-Protection: "1; mode=block"
          Strict-Transport-Security: "max-age=31536000"

    - request_id
    - gzip

  uploads:
    max_request_size: 10MB
    forbidden: [".php", ".exe", ".sh"]

  trusted_subnets:
    - 10.0.0.0/8
    - 127.0.0.0/8
    - 172.16.0.0/12
    - 192.168.0.0/16
```

**Static File Security**: Prevent directory traversal:

```yaml
static:
  dir: "./public"
  forbid:
    - ".git"
    - ".env"
    - ".htaccess"

  allow:
    - ".css"
    - ".js"
    - ".png"
    - ".jpg"
    - ".jpeg"
    - ".gif"
    - ".svg"
```

### Common Vulnerabilities and Mitigations

**Memory Leaks**: Implement strict memory controls:

```php
// Worker memory monitoring
class MemoryGuard {
    private int $limit;
    private int $requests = 0;

    public function __construct(int $limitMB = 128) {
        $this->limit = $limitMB * 1024 * 1024;
    }

    public function check(): bool {
        $this->requests++;

        if (memory_get_usage(true) > $this->limit) {
            return false; // Signal worker restart
        }

        if ($this->requests > 1000) {
            return false; // Periodic restart
        }

        return true;
    }
}
```

**Request Validation**: Implement input validation:

```php
$psr7 = new RoadRunner\Http\PSR7Worker($worker, $psrFactory);

while ($req = $psr7->waitRequest()) {
    // Validate request size
    $contentLength = $req->getHeaderLine('Content-Length');
    if ($contentLength > 10 * 1024 * 1024) {
        $psr7->respond(new Response(413));
        continue;
    }

    // Rate limiting
    if (!$rateLimiter->allow($req->getServerParams()['REMOTE_ADDR'])) {
        $psr7->respond(new Response(429));
        continue;
    }
}
```

### Update and Patching Strategies

Zero-downtime deployment strategy:

```bash
#!/bin/bash
# Rolling update script

# Download new binary
curl -s https://raw.githubusercontent.com/roadrunner-server/roadrunner/master/download-latest.sh | sh -s -- -o rr.new

# Test new binary
./rr.new serve -c .rr.yaml -p > /dev/null 2>&1 &
TEST_PID=$!
sleep 2
kill $TEST_PID

# Graceful reload
./rr reset -c .rr.yaml
mv rr rr.old
mv rr.new rr
./rr serve -c .rr.yaml
```

### Resource Limit Configurations

Prevent resource exhaustion:

```yaml
server:
  command: "php worker.php"
  relay: pipes
  relay_timeout: 60s

http:
  pool:
    num_workers: 10
    max_jobs: 1000
    allocate_timeout: 60s
    destroy_timeout: 60s
    max_worker_memory: 128

  fcgi:
    address: tcp://127.0.0.1:9000

limits:
  services:
    http.maxMemory: 256
    jobs.maxMemory: 256

  requests:
    max_request_size: 10MB
    max_multipart_form_data_size: 10MB
```

## Best Practice Summary

1. **Monitor Worker Health**: Track memory, CPU, and request metrics
2. **Configure Limits**: Set appropriate memory and request limits
3. **Use PSR Standards**: Leverage PSR-7 for request/response handling
4. **Implement Graceful Shutdown**: Handle signals properly in workers
5. **Profile Performance**: Use built-in metrics for optimization
6. **Test State Management**: Verify no data leaks between requests
7. **Document Configuration**: Maintain clear documentation of settings
8. **Automate Deployment**: Implement zero-downtime deployment scripts

## Conclusion

RoadRunner provides an excellent balance between performance and compatibility for PHP applications. Its Go-based architecture delivers significant performance improvements while maintaining compatibility with existing PHP code. The lack of PHP extension requirements and excellent framework integration make it accessible to teams looking to improve performance without extensive rewrites.

The comprehensive feature set including gRPC support, job queues, and WebSocket handling positions RoadRunner as more than just an application server - it's a complete platform for building modern PHP applications. Native Windows support and straightforward configuration further reduce adoption barriers.

For teams seeking significant performance improvements with minimal code changes, especially those using Laravel or Symfony, RoadRunner offers the best combination of performance gains, compatibility, and operational simplicity. While it requires understanding of persistent application concepts, the learning curve is manageable and the benefits substantial for most web applications.