# Docker Best Practices

## Official Documentation
- **Docker Documentation**: https://docs.docker.com
- **Docker Hub**: https://hub.docker.com
- **Docker Compose**: https://docs.docker.com/compose
- **Best Practices Guide**: https://docs.docker.com/develop/dev-best-practices

## Project Structure

```
project-root/
├── docker/
│   ├── app/
│   │   └── Dockerfile
│   ├── nginx/
│   │   ├── Dockerfile
│   │   └── default.conf
│   └── mysql/
│       └── my.cnf
├── docker-compose.yml
├── docker-compose.override.yml
├── docker-compose.prod.yml
├── .dockerignore
└── Makefile
```

## Core Best Practices

### 1. Dockerfile Best Practices

```dockerfile
# Use specific version tags, not latest
FROM node:18.17-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Build application
RUN npm run build

# Multi-stage build for smaller image
FROM node:18.17-alpine

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Use non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

# Start application
CMD ["node", "dist/index.js"]
```

### 2. Multi-Stage Builds

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Final stage
FROM alpine:3.18

RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /build/app .

CMD ["./app"]
```

### 3. Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: docker/app/Dockerfile
      args:
        - NODE_ENV=production
    image: myapp:${VERSION:-latest}
    container_name: myapp
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - NODE_ENV=production
    ports:
      - "3000:3000"
    volumes:
      - ./uploads:/app/uploads
    networks:
      - app-network
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./docker/nginx/conf.d:/etc/nginx/conf.d:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./certbot/www:/var/www/certbot:ro
    networks:
      - app-network
    depends_on:
      - app

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - app-network

volumes:
  postgres-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

### 4. Environment-Specific Configurations

```yaml
# docker-compose.override.yml (development)
version: '3.8'

services:
  app:
    build:
      target: development
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev

# docker-compose.prod.yml (production)
version: '3.8'

services:
  app:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 5. Efficient Layer Caching

```dockerfile
# Bad - Invalidates cache on any file change
COPY . .
RUN npm install

# Good - Leverages layer caching
COPY package*.json ./
RUN npm ci --only=production
COPY . .
```

### 6. Security Best Practices

```dockerfile
# Use minimal base images
FROM alpine:3.18

# Don't run as root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Scan for vulnerabilities
# Run: docker scan myimage:latest

# Use secrets for sensitive data
RUN --mount=type=secret,id=mysecret \
    cat /run/secrets/mysecret

# Set read-only filesystem
FROM nginx:alpine
COPY --chown=nginx:nginx build /usr/share/nginx/html
USER nginx
```

### 7. .dockerignore File

```dockerignore
# Version control
.git
.gitignore

# Dependencies
node_modules
vendor

# Build artifacts
dist
build
*.log

# IDE
.vscode
.idea
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Environment files
.env
.env.local

# Test files
__tests__
*.test.js
coverage

# Documentation
README.md
docs
```

### 8. Container Orchestration

```yaml
# docker-compose with scaling
version: '3.8'

services:
  web:
    image: myapp:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

### 9. Logging Best Practices

```dockerfile
# Configure logging
FROM node:18-alpine

# Log to stdout/stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
```

```yaml
# docker-compose.yml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 10. Resource Management

```yaml
# docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    mem_limit: 1g
    cpus: 1.0
```

### 11. Makefile for Common Tasks

```makefile
.PHONY: help build up down logs shell clean

help:
	@echo "Available commands:"
	@echo "  make build    - Build Docker images"
	@echo "  make up       - Start containers"
	@echo "  make down     - Stop containers"
	@echo "  make logs     - View logs"
	@echo "  make shell    - Enter app container"
	@echo "  make clean    - Clean up"

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

shell:
	docker-compose exec app sh

clean:
	docker-compose down -v
	docker system prune -f
```

### 12. Development Workflow

```bash
#!/bin/bash
# dev.sh - Development helper script

case "$1" in
  start)
    docker-compose up -d
    docker-compose logs -f
    ;;
  stop)
    docker-compose down
    ;;
  rebuild)
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
    ;;
  shell)
    docker-compose exec app sh
    ;;
  logs)
    docker-compose logs -f $2
    ;;
  *)
    echo "Usage: ./dev.sh {start|stop|rebuild|shell|logs}"
    exit 1
esac
```

### 13. Health Checks

```dockerfile
# Dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

```javascript
// healthcheck.js
const http = require('http');

const options = {
  host: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 2000
};

const request = http.request(options, (res) => {
  process.exit(res.statusCode === 200 ? 0 : 1);
});

request.on('error', () => {
  process.exit(1);
});

request.end();
```

### 14. CI/CD Integration

```yaml
# .github/workflows/docker.yml
name: Docker Build and Push

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        
      - name: Login to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
          
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            myapp:latest
            myapp:${{ github.sha }}
          cache-from: type=registry,ref=myapp:buildcache
          cache-to: type=registry,ref=myapp:buildcache,mode=max
```

### Common Pitfalls to Avoid

1. **Using latest tags in production**
2. **Running containers as root**
3. **Storing secrets in images**
4. **Not using .dockerignore**
5. **Installing unnecessary packages**
6. **Not leveraging build cache**
7. **Using large base images**
8. **Not setting resource limits**
9. **Ignoring security scanning**
10. **Not using health checks**

### Useful Tools and Commands

```bash
# Inspect image layers
docker history myimage:latest

# Check image size
docker images myimage

# Remove unused resources
docker system prune -a

# Security scanning
docker scan myimage:latest

# View resource usage
docker stats

# Export/Import images
docker save -o myimage.tar myimage:latest
docker load -i myimage.tar

# Multi-architecture builds
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest .
```

### Performance Optimization

1. **Use Alpine Linux** for smaller images
2. **Multi-stage builds** to reduce final image size
3. **Combine RUN commands** to reduce layers
4. **Order Dockerfile commands** from least to most frequently changing
5. **Use specific tags** instead of latest
6. **Minimize layer count**
7. **Remove package managers** after installation
8. **Use BuildKit** for advanced caching