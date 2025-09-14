# FrankenPHP Best Practices

## Introduction

FrankenPHP is a modern application server for PHP built on top of Caddy web server, written in Go. It embeds PHP directly into the web server, enabling exceptional performance while maintaining compatibility with existing PHP applications. Unlike traditional setups that require separate web server and PHP-FPM processes, FrankenPHP provides an all-in-one solution that simplifies deployment and improves efficiency.

Released in 2023 by Kévin Dunglas, FrankenPHP represents a fresh approach to PHP application serving. It supports PHP 8.2+ and leverages Go's concurrency model to handle thousands of simultaneous connections efficiently. The current version provides production-ready features including HTTP/3, automatic HTTPS, and native support for modern PHP applications.

## Architecture Overview

### How It Works

FrankenPHP embeds the PHP interpreter directly into a Go-based web server using CGO (C bindings for Go). This architecture eliminates the traditional separation between web server and PHP processor. When a request arrives, FrankenPHP processes it within the same process space, reducing context switching and inter-process communication overhead.

The server leverages Go's goroutines for handling concurrent requests, providing excellent scalability without the memory overhead of traditional process-based models. Each request runs in its own goroutine with an embedded PHP executor, allowing thousands of concurrent requests with minimal resource consumption.

### Request Lifecycle

1. **Server Initialization**: FrankenPHP starts and initializes the embedded PHP runtime
2. **Request Reception**: The Caddy server receives incoming HTTP/HTTPS/HTTP3 requests
3. **Goroutine Allocation**: Each request spawns a lightweight goroutine
4. **PHP Execution**: The embedded PHP interpreter processes the request
5. **Response Generation**: PHP output is captured and formatted as HTTP response
6. **Connection Management**: Keep-alive connections are efficiently managed
7. **Resource Cleanup**: Goroutines and PHP resources are properly released

### Process Management Model

FrankenPHP uses a hybrid model combining Go's concurrency with PHP's execution model. The main process manages incoming connections and spawns goroutines for request handling. Each goroutine has access to an embedded PHP executor, either through a pool of reusable executors or by creating new ones as needed. This model provides excellent fault isolation while maintaining high performance.

## Installation & Setup

### System Requirements

- Operating System: Linux, macOS, Windows (with WSL2)
- PHP 8.2 or higher
- Memory: Minimum 256MB, recommended 1GB+
- CPU: Any x86_64 or ARM64 processor
- Disk Space: 100MB for binary plus application space

### Installation Steps

```bash
# Download the latest FrankenPHP binary
curl -L https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64 -o frankenphp
chmod +x frankenphp

# Or use Docker
docker run -v $PWD:/app -p 80:80 dunglas/frankenphp

# Or build from source
git clone https://github.com/dunglas/frankenphp.git
cd frankenphp
go build
```

### Basic Configuration

```caddyfile
# Caddyfile configuration
{
    frankenphp {
        num_threads 4
        worker {
            file ./public/index.php
            num 4
            env APP_ENV production
        }
    }
}

localhost {
    root * ./public
    php_server
    encode gzip

    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
    }
}
```

## Use Cases

### Ideal Scenarios

**Containerized Applications**: FrankenPHP's single binary deployment makes it perfect for Docker containers. No need for complex multi-process supervisors or separate web server configurations.

**Edge Computing**: The small footprint and embedded nature make it ideal for edge deployments where resources are constrained and simplified operations are crucial.

**Development Environments**: Built-in HTTPS with automatic certificates, HTTP/3 support, and zero-configuration setup streamline local development.

**API Gateways**: High-performance request handling with built-in features like rate limiting, authentication middleware, and response caching.

### Real-World Applications

Microservices architectures benefit from FrankenPHP's lightweight footprint and fast startup times. Content management systems leverage its compatibility with existing PHP code while gaining performance improvements. Real-time applications utilize its efficient WebSocket handling through Mercure protocol support.

### Performance Expectations

FrankenPHP typically delivers 2-5x better performance than traditional PHP-FPM setups for concurrent requests. Response times improve by 30-50% due to eliminated inter-process communication. Memory usage is often 40-60% lower than equivalent PHP-FPM configurations with similar throughput.

## Best Practices

### Configuration Optimization

**Thread Tuning**: Configure thread count based on CPU cores and workload characteristics:

```caddyfile
{
    frankenphp {
        # For CPU-bound workloads
        num_threads {$GOMAXPROCS}

        # For I/O-bound workloads
        num_threads {$GOMAXPROCS * 2}

        worker {
            file ./public/index.php
            num {$WORKER_COUNT}
            env APP_RUNTIME frankenphp
        }
    }
}
```

### Resource Management

**Memory Optimization**: Configure PHP memory limits appropriately:

```ini
; php.ini settings for FrankenPHP
memory_limit = 128M
max_execution_time = 30
opcache.enable = 1
opcache.enable_cli = 1
opcache.max_accelerated_files = 10000
opcache.memory_consumption = 128
opcache.validate_timestamps = 0
```

**Connection Pooling**: Leverage persistent connections for databases:

```php
// Database configuration
'connections' => [
    'mysql' => [
        'driver' => 'mysql',
        'host' => env('DB_HOST'),
        'options' => [
            PDO::ATTR_PERSISTENT => true,
            PDO::ATTR_EMULATE_PREPARES => false,
        ],
    ],
],
```

### Common Patterns

**Worker Mode Configuration**: Enable worker mode for long-running applications:

```caddyfile
{
    frankenphp {
        worker {
            file ./public/index.php
            num 4
            env APP_WORKER_MODE true
            restart_policy always
            restart_delay 1s
        }
    }
}
```

**Graceful Reloads**: Implement zero-downtime deployments:

```bash
#!/bin/bash
# Graceful reload script
NEW_BINARY="/path/to/new/frankenphp"
OLD_PID=$(pgrep frankenphp)

# Start new instance
$NEW_BINARY --config Caddyfile &
NEW_PID=$!

# Wait for new instance to be ready
sleep 2

# Stop old instance
kill -TERM $OLD_PID
```

## Pros & Cons

### Pros

- **Single Binary**: Simplified deployment with everything in one executable
- **Modern Protocols**: Native HTTP/3, automatic HTTPS, and WebSocket support
- **Go Performance**: Leverages Go's efficient concurrency model
- **Caddy Features**: Built-in reverse proxy, load balancing, and middleware
- **Developer Friendly**: Zero-configuration local development with automatic HTTPS
- **Low Memory Footprint**: Efficient resource usage compared to traditional setups
- **Windows Support**: Native Windows support without WSL for development

### Cons

- **Ecosystem Maturity**: Newer project with smaller community compared to PHP-FPM
- **Extension Compatibility**: Some PHP extensions may require recompilation
- **Debugging Tools**: Limited tooling compared to traditional PHP setups
- **Learning Curve**: Requires understanding Caddy configuration
- **Worker Mode Limitations**: Not all applications benefit from worker mode
- **Binary Size**: Larger binary size compared to standalone PHP

## Comparison Matrix

| Feature | FrankenPHP | PHP-FPM | Laravel Octane | Open Swoole | RoadRunner |
|---------|------------|---------|----------------|-------------|------------|
| **Request/sec** | 3,000-15,000 | 500-2,000 | 5,000-50,000 | 10,000-100,000 | 4,000-20,000 |
| **Memory Usage** | Low-Medium | Low | High | High | Medium |
| **Startup Time** | Fast | Fast | Slow | Slow | Medium |
| **HTTP/3 Support** | Yes | No | No | No | Yes |
| **Automatic HTTPS** | Yes | No | No | No | No |
| **Single Binary** | Yes | No | No | No | Yes |
| **Windows Native** | Yes | Yes | Limited | No | Yes |
| **Learning Curve** | Low | Low | Moderate | High | Moderate |

## Security and Safety

### Security Configuration Best Practices

**TLS Configuration**: Leverage Caddy's automatic HTTPS with strong defaults:

```caddyfile
example.com {
    tls {
        protocols tls1.3
        ciphers TLS_AES_256_GCM_SHA384 TLS_CHACHA20_POLY1305_SHA256
    }

    php_server {
        trusted_proxies 10.0.0.0/8
        client_max_body_size 10M
    }
}
```

**Security Headers**: Implement comprehensive security headers:

```caddyfile
header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Content-Security-Policy "default-src 'self'"
    X-Content-Type-Options nosniff
    X-Frame-Options DENY
    Referrer-Policy strict-origin-when-cross-origin
}
```

### Common Vulnerabilities and Mitigations

**Path Traversal**: FrankenPHP includes built-in protections against path traversal attacks. Ensure proper file serving configuration:

```caddyfile
file_server {
    hide .git
    hide .env
    hide composer.*
    index index.php
}
```

**Request Smuggling**: HTTP/3 and HTTP/2 implementations include protection against request smuggling. Keep FrankenPHP updated for latest security patches.

### Update and Patching Strategies

Implement automated updates with health checks:

```bash
#!/bin/bash
# Update script with health verification
curl -L https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64 -o frankenphp.new
chmod +x frankenphp.new

# Test new binary
./frankenphp.new version || exit 1

# Replace and restart
mv frankenphp frankenphp.old
mv frankenphp.new frankenphp
systemctl restart frankenphp
```

### Resource Limit Configurations

Prevent resource exhaustion attacks:

```caddyfile
{
    servers {
        timeouts {
            read_body 30s
            read_header 10s
            write 30s
            idle 120s
        }
        max_header_size 1MB
    }

    frankenphp {
        num_threads 8
        max_request_body_size 10MB
    }
}
```

## Best Practice Summary

1. **Start with Defaults**: FrankenPHP's defaults are well-tuned for most applications
2. **Monitor Performance**: Use built-in Prometheus metrics for monitoring
3. **Leverage Caching**: Utilize Caddy's caching capabilities for static assets
4. **Enable Compression**: Always enable gzip/brotli compression for responses
5. **Use Worker Mode Carefully**: Test thoroughly before enabling worker mode in production
6. **Keep Updated**: Regular updates provide security and performance improvements
7. **Profile Before Optimizing**: Use profiling tools to identify actual bottlenecks

## Conclusion

FrankenPHP offers a compelling modern alternative to traditional PHP deployment models. By embedding PHP directly into a Go-based web server, it simplifies deployment while providing excellent performance and modern protocol support. The single-binary distribution and automatic HTTPS make it particularly attractive for containerized deployments and development environments.

While the ecosystem is still maturing, FrankenPHP's compatibility with existing PHP applications, combined with its performance benefits and operational simplicity, make it an excellent choice for teams looking to modernize their PHP infrastructure. The built-in Caddy features provide enterprise-grade capabilities without additional complexity.

For applications requiring simple deployment, modern protocol support, and good performance without the complexity of application servers like Swoole or RoadRunner, FrankenPHP strikes an optimal balance between simplicity and capability.