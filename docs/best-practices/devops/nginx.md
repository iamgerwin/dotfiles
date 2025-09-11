# NGINX Best Practices

## Official Documentation
- **Main Documentation**: https://nginx.org/en/docs/
- **Admin Guide**: https://docs.nginx.com/nginx/admin-guide/
- **Config Reference**: https://nginx.org/en/docs/dirindex.html
- **Community**: https://forum.nginx.org/

## Core Concepts

### Architecture
```
Master Process (root)
├── Worker Process 1
├── Worker Process 2
├── Worker Process N
└── Cache Manager/Loader
```

## Project Structure
```
nginx/
├── nginx.conf              # Main configuration
├── conf.d/                # Additional configurations
│   ├── default.conf
│   ├── ssl.conf
│   └── gzip.conf
├── sites-available/       # Available site configurations
│   ├── example.com.conf
│   └── api.example.com.conf
├── sites-enabled/         # Symlinks to enabled sites
├── snippets/             # Reusable configuration snippets
│   ├── ssl-params.conf
│   └── security-headers.conf
├── ssl/                  # SSL certificates
│   ├── certs/
│   └── private/
└── logs/                 # Log files
    ├── access.log
    └── error.log
```

## Main Configuration

### 1. nginx.conf
```nginx
# /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';
    
    access_log /var/log/nginx/access.log main buffer=16k flush=2s;

    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    client_body_buffer_size 128k;
    large_client_header_buffers 4 16k;

    # Hide nginx version
    server_tokens off;
    more_clear_headers Server;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml application/atom+xml image/svg+xml 
               text/x-js text/x-cross-domain-policy application/x-font-ttf 
               application/x-font-opentype application/vnd.ms-fontobject 
               image/x-icon;
    gzip_disable "msie6";

    # Rate Limiting Zones
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    # Cache Zones
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=static_cache:10m 
                     max_size=1g inactive=60m use_temp_path=off;
    
    fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=fastcgi_cache:10m 
                       max_size=1g inactive=60m use_temp_path=off;

    # Load modular configuration files
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

## Server Configurations

### 1. Static Website
```nginx
# sites-available/example.com.conf
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/private/example.com.key;
    
    # SSL Security
    include /etc/nginx/snippets/ssl-params.conf;

    # Security Headers
    include /etc/nginx/snippets/security-headers.conf;

    # Document Root
    root /var/www/example.com/public;
    index index.html index.htm;

    # Logging
    access_log /var/log/nginx/example.com.access.log main;
    error_log /var/log/nginx/example.com.error.log warn;

    # Rate Limiting
    limit_req zone=general burst=20 nodelay;
    limit_conn addr 10;

    location / {
        try_files $uri $uri/ =404;
        
        # Cache static files
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            expires 30d;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
    }

    # Block access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

### 2. PHP Application (Laravel/WordPress)
```nginx
# sites-available/app.example.com.conf
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.example.com;

    root /var/www/app.example.com/public;
    index index.php index.html;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/certs/app.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/private/app.example.com.key;
    include /etc/nginx/snippets/ssl-params.conf;

    # Security
    include /etc/nginx/snippets/security-headers.conf;

    # PHP-FPM Configuration
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # FastCGI Cache
        fastcgi_cache fastcgi_cache;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_valid 404 10m;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
        
        # FastCGI Buffers
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
    }

    # Laravel specific
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # WordPress specific
    # location / {
    #     try_files $uri $uri/ /index.php?$args;
    # }

    # Deny access to sensitive files
    location ~ /\.(?!well-known) {
        deny all;
    }

    location ~ /vendor/ {
        deny all;
    }

    location ~ /\.env {
        deny all;
    }

    # Cache control for static assets
    location ~* \.(jpg|jpeg|gif|png|svg|webp|ico|css|js|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### 3. Reverse Proxy
```nginx
# sites-available/api.example.com.conf
upstream backend {
    least_conn;
    server backend1.example.com:8080 weight=3 max_fails=3 fail_timeout=30s;
    server backend2.example.com:8080 weight=2 max_fails=3 fail_timeout=30s;
    server backend3.example.com:8080 weight=1 backup;
    
    # Connection pooling
    keepalive 32;
    keepalive_requests 100;
    keepalive_timeout 60s;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.example.com;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/certs/api.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/private/api.example.com.key;
    include /etc/nginx/snippets/ssl-params.conf;

    # Rate limiting for API
    limit_req zone=api burst=50 nodelay;
    limit_req_status 429;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Cache
        proxy_cache static_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_background_update on;
        proxy_cache_lock on;
        
        # Keep alive
        proxy_set_header Connection "";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

## Security Configuration

### 1. SSL Parameters (snippets/ssl-params.conf)
```nginx
# SSL Protocol and Ciphers
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/nginx/ssl/certs/chain.pem;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# SSL Session
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

# Diffie-Hellman parameter
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
```

### 2. Security Headers (snippets/security-headers.conf)
```nginx
# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# CSP
add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; font-src 'self' data: https:; connect-src 'self' https:; media-src 'self' https:; object-src 'none'; frame-src 'self' https:; base-uri 'self'; form-action 'self' https:; frame-ancestors 'self'; upgrade-insecure-requests;" always;
```

## Load Balancing Strategies

### 1. Round Robin (Default)
```nginx
upstream backend {
    server 192.168.1.10:8080;
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
}
```

### 2. Least Connections
```nginx
upstream backend {
    least_conn;
    server 192.168.1.10:8080;
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
}
```

### 3. IP Hash (Session Persistence)
```nginx
upstream backend {
    ip_hash;
    server 192.168.1.10:8080;
    server 192.168.1.11:8080;
    server 192.168.1.12:8080;
}
```

### 4. Weighted Load Balancing
```nginx
upstream backend {
    server 192.168.1.10:8080 weight=3;
    server 192.168.1.11:8080 weight=2;
    server 192.168.1.12:8080 weight=1;
}
```

## Caching Strategies

### 1. Static File Caching
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
    add_header X-Cache-Status $upstream_cache_status;
    access_log off;
}
```

### 2. Proxy Cache
```nginx
location /api/ {
    proxy_pass http://backend;
    
    # Cache configuration
    proxy_cache api_cache;
    proxy_cache_key "$scheme$request_method$host$request_uri$is_args$args";
    proxy_cache_valid 200 201 10m;
    proxy_cache_valid 404 1m;
    proxy_cache_methods GET HEAD POST;
    proxy_cache_bypass $http_pragma $http_authorization;
    proxy_no_cache $http_pragma $http_authorization;
    
    # Cache status header
    add_header X-Cache-Status $upstream_cache_status;
}
```

### 3. FastCGI Cache for PHP
```nginx
# Cache configuration
set $no_cache 0;

# POST requests and URLs with query strings should not be cached
if ($request_method = POST) {
    set $no_cache 1;
}
if ($query_string != "") {
    set $no_cache 1;
}

# Don't cache URIs containing the following segments
if ($request_uri ~* "/wp-admin/|/admin/|/user/|/login/") {
    set $no_cache 1;
}

# Don't use the cache for logged-in users
if ($http_cookie ~* "wordpress_logged_in|comment_author") {
    set $no_cache 1;
}

location ~ \.php$ {
    fastcgi_pass unix:/var/run/php/php-fpm.sock;
    
    fastcgi_cache fastcgi_cache;
    fastcgi_cache_key "$scheme$request_method$host$request_uri";
    fastcgi_cache_valid 200 60m;
    fastcgi_cache_bypass $no_cache;
    fastcgi_no_cache $no_cache;
    
    add_header X-FastCGI-Cache $upstream_cache_status;
}
```

## Performance Optimization

### 1. HTTP/2 and HTTP/3
```nginx
# HTTP/2
listen 443 ssl http2;

# HTTP/3 (requires NGINX with QUIC support)
listen 443 ssl http3 reuseport;
add_header Alt-Svc 'h3=":443"; ma=86400';
```

### 2. Connection Optimization
```nginx
http {
    # Keepalive connections
    keepalive_timeout 65;
    keepalive_requests 100;
    
    # Client body
    client_body_timeout 30;
    client_header_timeout 30;
    client_max_body_size 100M;
    client_body_buffer_size 128k;
    
    # Buffers
    large_client_header_buffers 4 32k;
    output_buffers 2 32k;
    postpone_output 1460;
    
    # Sendfile
    sendfile on;
    sendfile_max_chunk 512k;
    tcp_nopush on;
    tcp_nodelay on;
}
```

### 3. Open File Cache
```nginx
http {
    open_file_cache max=2000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
```

## Monitoring and Logging

### 1. Custom Log Format
```nginx
log_format detailed '$remote_addr - $remote_user [$time_local] '
                   '"$request" $status $body_bytes_sent '
                   '"$http_referer" "$http_user_agent" '
                   '$request_time $upstream_response_time $pipe '
                   '$ssl_protocol/$ssl_cipher '
                   '$http_x_forwarded_for $request_id';

access_log /var/log/nginx/access.log detailed buffer=32k flush=5s;
```

### 2. Status Page
```nginx
server {
    listen 127.0.0.1:8080;
    server_name localhost;
    
    location /nginx_status {
        stub_status;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
```

### 3. Request Tracing
```nginx
# Generate unique request ID
map $http_x_request_id $request_id {
    default $http_x_request_id;
    "" $request_id_sequence;
}

map $request_id_sequence $request_id_sequence {
    volatile;
    default $msec-$remote_addr-$connection-$connection_requests;
}

# Add to response headers
add_header X-Request-ID $request_id always;

# Pass to upstream
proxy_set_header X-Request-ID $request_id;
```

## Docker Configuration

### Dockerfile
```dockerfile
FROM nginx:alpine

# Install additional tools
RUN apk add --no-cache curl vim

# Copy configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/
COPY sites-available/ /etc/nginx/sites-available/
COPY snippets/ /etc/nginx/snippets/

# Create necessary directories
RUN mkdir -p /var/cache/nginx /var/log/nginx /etc/nginx/sites-enabled

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf.d:/etc/nginx/conf.d:ro
      - ./sites-available:/etc/nginx/sites-available:ro
      - ./sites-enabled:/etc/nginx/sites-enabled:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./html:/usr/share/nginx/html:ro
      - nginx_cache:/var/cache/nginx
      - nginx_logs:/var/log/nginx
    networks:
      - webnet
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  nginx_cache:
  nginx_logs:

networks:
  webnet:
    driver: bridge
```

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**
```bash
# Check upstream server
curl -I http://backend-server:port

# Check NGINX error logs
tail -f /var/log/nginx/error.log

# Verify upstream configuration
nginx -t
```

2. **413 Request Entity Too Large**
```nginx
# Increase client_max_body_size
client_max_body_size 100M;

# For PHP applications
fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
```

3. **504 Gateway Timeout**
```nginx
# Increase proxy timeouts
proxy_connect_timeout 300;
proxy_send_timeout 300;
proxy_read_timeout 300;
send_timeout 300;
```

4. **Permission Denied**
```bash
# Check file permissions
ls -la /var/www/

# Check SELinux context (if applicable)
ls -Z /var/www/
setsebool -P httpd_can_network_connect 1
```

## Best Practices Summary

### Do's ✅
- Use HTTP/2 and HTTP/3 when possible
- Implement proper caching strategies
- Use rate limiting to prevent abuse
- Enable gzip compression
- Configure proper security headers
- Monitor access and error logs
- Use health checks for upstreams
- Implement SSL/TLS best practices
- Keep NGINX updated
- Test configuration before reload

### Don'ts ❌
- Don't use `if` statements when possible
- Don't disable access logs in production
- Don't use root privileges unnecessarily
- Don't expose sensitive files
- Don't ignore error logs
- Don't use weak SSL ciphers
- Don't forget to rotate logs
- Don't use default server configurations
- Don't cache sensitive data
- Don't expose server version information

## Additional Resources
- **NGINX Plus**: https://www.nginx.com/products/nginx/
- **NGINX Amplify**: https://www.nginx.com/products/nginx-amplify/
- **NGINX Unit**: https://unit.nginx.org/
- **ModSecurity WAF**: https://github.com/SpiderLabs/ModSecurity-nginx