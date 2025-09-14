# PHP-FPM Best Practices

## Introduction

PHP-FPM (FastCGI Process Manager) is the traditional and most widely adopted method for serving PHP applications in production environments. It provides a robust process management system that interfaces with web servers through the FastCGI protocol, offering advanced features for high-traffic websites including adaptive process spawning, graceful reloads, and comprehensive logging capabilities.

Originally developed as a patch for PHP to improve FastCGI SAPI performance, PHP-FPM has been part of PHP core since version 5.3.3 (released in 2010). The current implementation in PHP 8.x continues to be the default choice for production PHP deployments, powering millions of websites from small blogs to large-scale applications.

## Architecture Overview

### How It Works

PHP-FPM operates as a separate daemon process that manages a pool of PHP worker processes. Web servers like Nginx or Apache communicate with PHP-FPM through FastCGI protocol, typically over Unix sockets or TCP connections. This separation of concerns allows the web server to handle static content efficiently while delegating PHP processing to specialized workers.

The architecture follows a master-worker pattern where the master process manages worker lifecycles, handles configuration reloads, and provides process monitoring. Worker processes execute PHP code in isolated environments, ensuring that failures in one request don't affect others.

### Request Lifecycle

1. **Client Request**: Browser sends HTTP request to web server
2. **Web Server Processing**: Nginx/Apache receives request and determines if PHP processing is needed
3. **FastCGI Forward**: Web server forwards PHP requests to PHP-FPM via socket/TCP
4. **Worker Assignment**: PHP-FPM master assigns request to available worker
5. **Script Execution**: Worker process executes PHP script
6. **Response Return**: Worker sends response back through FastCGI to web server
7. **Client Response**: Web server delivers final response to client
8. **Worker Recycling**: After configured requests, worker restarts to prevent memory leaks

### Process Management Model

PHP-FPM supports three process management modes:

- **Static**: Fixed number of worker processes
- **Dynamic**: Workers scale between minimum and maximum based on demand
- **Ondemand**: Workers spawn only when needed and terminate after idle timeout

Each mode offers different trade-offs between resource usage and response time, allowing optimization for specific workload patterns.

## Installation & Setup

### System Requirements

- PHP 5.3.3 or higher (included in PHP core)
- Web server with FastCGI support (Nginx, Apache, Caddy)
- Unix/Linux operating system (Windows support via WSL)
- Memory: 128MB minimum per worker
- CPU: Any modern processor

### Installation Steps

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install php8.2-fpm

# CentOS/RHEL/Fedora
sudo yum install php-fpm

# macOS (Homebrew)
brew install php

# Verify installation
php-fpm -v
```

### Basic Configuration

```ini
; /etc/php/8.2/fpm/pool.d/www.conf
[www]
user = www-data
group = www-data

listen = /run/php/php8.2-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

pm.status_path = /status
ping.path = /ping

access.log = /var/log/php8.2-fpm.access.log
slowlog = /var/log/php8.2-fpm.slow.log
request_slowlog_timeout = 10s

php_admin_value[memory_limit] = 128M
php_admin_value[error_log] = /var/log/php8.2-fpm.error.log
php_admin_flag[log_errors] = on
```

## Use Cases

### Ideal Scenarios

**Traditional Web Applications**: WordPress, Drupal, Joomla, and other CMS platforms run optimally with PHP-FPM's request-based model. The process isolation ensures stability and predictable resource usage.

**Shared Hosting Environments**: Multiple sites can run with different PHP versions and configurations using separate FPM pools, providing isolation and security between tenants.

**Legacy Applications**: Applications built for traditional PHP execution model work without modification. Full compatibility with all PHP extensions and debugging tools.

**High-Traffic Websites**: Proven scalability for sites handling millions of requests daily. Process pooling provides consistent performance under load.

### Real-World Applications

E-commerce platforms like Magento and WooCommerce rely on PHP-FPM for stable transaction processing. News websites use it for content delivery with aggressive caching strategies. Educational platforms leverage its reliability for online learning systems. Government websites choose it for its proven track record and security audit trail.

### Performance Expectations

PHP-FPM typically handles 100-500 requests per second per server depending on application complexity. Response times range from 50-200ms for typical web applications. Memory usage is predictable at 20-50MB per worker process. CPU utilization scales linearly with request rate.

## Best Practices

### Configuration Optimization

**Process Manager Tuning**: Choose the right PM mode for your workload:

```ini
; For consistent traffic (recommended for most)
pm = dynamic
pm.max_children = (Total RAM - Memory for other processes) / Average memory per process
pm.start_servers = CPU cores * 2
pm.min_spare_servers = CPU cores
pm.max_spare_servers = CPU cores * 4

; For variable traffic
pm = ondemand
pm.max_children = 100
pm.process_idle_timeout = 10s

; For predictable high traffic
pm = static
pm.max_children = 50
```

### Resource Management

**Memory Optimization**: Calculate optimal worker count:

```bash
# Find average memory usage per process
ps aux | grep php-fpm | awk '{sum+=$6; count++} END {print sum/count/1024 " MB"}'

# Calculate max children
# Example: 4GB RAM, 500MB for system, 30MB per process
# max_children = (4096 - 500) / 30 = 120
```

**OPcache Configuration**: Essential for performance:

```ini
; php.ini or pool configuration
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
opcache.enable_cli=1
```

### Common Patterns

**Multi-Pool Configuration**: Separate pools for different applications:

```ini
; /etc/php/8.2/fpm/pool.d/app1.conf
[app1]
user = app1
group = app1
listen = /run/php/app1.sock
pm = dynamic
pm.max_children = 20
php_admin_value[open_basedir] = /var/www/app1

; /etc/php/8.2/fpm/pool.d/app2.conf
[app2]
user = app2
group = app2
listen = /run/php/app2.sock
pm = dynamic
pm.max_children = 30
php_admin_value[open_basedir] = /var/www/app2
```

**Nginx Integration**: Optimal FastCGI configuration:

```nginx
location ~ \.php$ {
    fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;

    # Performance optimizations
    fastcgi_buffer_size 32k;
    fastcgi_buffers 8 16k;
    fastcgi_busy_buffers_size 64k;
    fastcgi_temp_file_write_size 256k;
    fastcgi_connect_timeout 60;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
}
```

## Pros & Cons

### Pros

- **Stability**: Decades of production use with proven reliability
- **Compatibility**: Works with all PHP code and extensions
- **Process Isolation**: Crashes don't affect other requests
- **Resource Control**: Fine-grained control over memory and process limits
- **Debugging Support**: Full support for Xdebug, profilers, and APM tools
- **Security**: Mature security model with extensive hardening options
- **Documentation**: Extensive documentation and community knowledge

### Cons

- **Bootstrap Overhead**: Full framework initialization on every request
- **Memory Usage**: Each process requires separate memory allocation
- **No Shared State**: Cannot share data between requests efficiently
- **Scaling Limitations**: Process-based model has inherent scaling limits
- **Configuration Complexity**: Requires tuning for optimal performance
- **No WebSocket Support**: Limited to request-response model

## Comparison Matrix

| Feature | PHP-FPM | FrankenPHP | Laravel Octane | Open Swoole | RoadRunner |
|---------|---------|------------|----------------|-------------|------------|
| **Request/sec** | 100-500 | 3,000-15,000 | 5,000-50,000 | 10,000-100,000 | 4,000-20,000 |
| **Memory per Worker** | 20-50MB | 10-30MB | 50-200MB | 50-200MB | 30-100MB |
| **Startup Overhead** | Every request | Once | Once | Once | Once |
| **Compatibility** | 100% | 95% | 90% | 80% | 90% |
| **Debugging** | Excellent | Good | Limited | Limited | Good |
| **Configuration** | Complex | Simple | Moderate | Complex | Moderate |
| **Production Maturity** | Excellent | Good | Good | Good | Good |
| **Learning Curve** | Low | Low | Moderate | High | Moderate |

## Security and Safety

### Security Configuration Best Practices

**User Isolation**: Run each pool as separate user:

```ini
[production]
user = app_prod
group = app_prod
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; Restrict file access
php_admin_value[open_basedir] = /var/www/app:/tmp
php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
php_admin_flag[allow_url_include] = off
```

**Chroot Environment**: Isolate applications completely:

```ini
[secure_app]
prefix = /var/www/chroot/app
chroot = $prefix
chdir = /
```

### Common Vulnerabilities and Mitigations

**File Upload Attacks**: Restrict upload capabilities:

```ini
php_admin_value[upload_max_filesize] = 2M
php_admin_value[post_max_size] = 8M
php_admin_value[max_file_uploads] = 20
php_admin_value[upload_tmp_dir] = /var/www/app/tmp
```

**Resource Exhaustion**: Implement strict limits:

```ini
php_admin_value[max_execution_time] = 30
php_admin_value[max_input_time] = 60
php_admin_value[memory_limit] = 128M
request_terminate_timeout = 30
request_slowlog_timeout = 10s
```

### Update and Patching Strategies

Implement rolling updates without downtime:

```bash
#!/bin/bash
# Graceful reload after updates
sudo php-fpm -t && sudo systemctl reload php8.2-fpm

# Monitor reload success
sleep 2
systemctl status php8.2-fpm || systemctl restart php8.2-fpm
```

### Resource Limit Configurations

Prevent DoS attacks through proper limits:

```ini
; Global limits in php-fpm.conf
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s

; Per-pool limits
[www]
pm.max_children = 50
pm.max_requests = 1000
rlimit_files = 1024
rlimit_core = 0
```

## Best Practice Summary

1. **Monitor Metrics**: Track memory usage, slow requests, and error rates
2. **Use OPcache**: Always enable OPcache in production
3. **Tune Process Manager**: Start with dynamic PM and adjust based on metrics
4. **Implement Health Checks**: Use status and ping endpoints for monitoring
5. **Separate Pools**: Isolate applications in different pools
6. **Regular Updates**: Keep PHP and FPM updated for security patches
7. **Log Analysis**: Regularly review slow logs and error logs
8. **Capacity Planning**: Plan for 20% headroom in process allocation

## Conclusion

PHP-FPM remains the gold standard for traditional PHP deployments, offering unmatched stability, compatibility, and operational maturity. While newer solutions provide better performance through persistent processes, PHP-FPM's process isolation model ensures reliability and predictable resource usage that many production environments require.

The extensive ecosystem support, comprehensive documentation, and decades of production hardening make PHP-FPM the safe choice for applications where stability trumps raw performance. Its ability to run any PHP code without modification, combined with excellent debugging support, makes it ideal for development and legacy application support.

For teams prioritizing stability, compatibility, and operational simplicity over maximum performance, PHP-FPM continues to be the optimal choice. Modern optimizations like OPcache, careful tuning, and proper caching strategies can deliver excellent performance while maintaining the reliability that PHP-FPM is known for.