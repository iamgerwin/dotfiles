# Coolify Best Practices

## Official Documentation
- **Official Website**: https://coolify.io
- **Documentation**: https://coolify.io/docs
- **GitHub Repository**: https://github.com/coollabsio/coolify
- **Discord Community**: https://discord.gg/coolify
- **Deployment Examples**: https://github.com/coollabsio/coolify-examples

## Installation and Setup

### System Requirements
```bash
# Minimum requirements
- CPU: 2 cores
- RAM: 2GB (4GB recommended for production)
- Storage: 20GB minimum
- OS: Ubuntu 20.04/22.04, Debian 11/12, CentOS 8+
- Docker: 24.0+ (installed automatically)
- Architecture: x86_64 or ARM64

# Recommended production setup
- CPU: 4+ cores
- RAM: 8GB+
- Storage: 50GB+ SSD
- Network: Static IP with open ports 80, 443, 8000, 6001, 6002
```

### Self-Hosted Installation
```bash
# Quick installation (automated script)
curl -fsSL https://cdn.coolify.io/install.sh | bash

# Manual installation with custom settings
export COOLIFY_DOMAIN="coolify.example.com"
export COOLIFY_EMAIL="admin@example.com"
curl -fsSL https://cdn.coolify.io/install.sh | bash

# Installation on existing Docker server
wget -q https://cdn.coolify.io/install.sh -O install.sh
chmod +x install.sh
./install.sh

# Verify installation
docker ps | grep coolify
curl http://localhost:8000/health

# Access Coolify dashboard
# Navigate to http://your-server-ip:8000
# Complete initial setup wizard
```

### Post-Installation Configuration
```bash
# Configure firewall (UFW)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8000/tcp  # Coolify dashboard
sudo ufw allow 6001/tcp  # Coolify realtime
sudo ufw allow 6002/tcp  # Coolify websockets
sudo ufw enable

# Configure firewall (firewalld)
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=6001/tcp
sudo firewall-cmd --permanent --add-port=6002/tcp
sudo firewall-cmd --reload

# Update Coolify
# Navigate to Settings > Update in dashboard
# Or via CLI
cd /data/coolify/source
git pull
php artisan migrate --force
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Backup before updates
docker exec coolify php artisan backup:run
```

## Server Configuration and Prerequisites

### DNS Configuration
```bash
# A record for main application
coolify.example.com    A    192.0.2.10

# Wildcard for subdomains (optional)
*.coolify.example.com  A    192.0.2.10

# CNAME for custom domains
app.custom.com         CNAME   coolify.example.com

# Verify DNS propagation
dig coolify.example.com +short
nslookup coolify.example.com
```

### Server Preparation Script
```bash
#!/bin/bash

# Update system
apt-get update && apt-get upgrade -y

# Install required dependencies
apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release

# Configure system limits
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Optimize kernel parameters
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
vm.overcommit_memory=1
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=8192
EOF

sysctl -p

# Setup Docker storage driver
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Install Coolify
curl -fsSL https://cdn.coolify.io/install.sh | bash

echo "Server preparation complete. Access Coolify at http://$(curl -s ifconfig.me):8000"
```

### Docker Network Configuration
```bash
# Coolify creates default networks
docker network ls | grep coolify

# Custom network for isolated environments
docker network create --driver bridge \
  --subnet 172.20.0.0/16 \
  --gateway 172.20.0.1 \
  coolify-custom

# Inspect network
docker network inspect coolify

# Connect existing container to network
docker network connect coolify-custom container_name
```

## Project Structure and Deployment Patterns

### Recommended Directory Structure
```bash
/data/coolify/
├── applications/
│   ├── app-uuid-1/
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── storage/
│   ├── app-uuid-2/
│   └── app-uuid-3/
├── databases/
│   ├── postgresql/
│   │   └── data/
│   ├── mysql/
│   │   └── data/
│   └── redis/
│       └── data/
├── backups/
│   ├── applications/
│   └── databases/
├── logs/
│   ├── applications/
│   └── system/
└── source/
    └── coolify-app/
```

### Application Structure Patterns

#### Pattern 1: Monolithic Application
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    volumes:
      - ./storage:/app/storage
    networks:
      - coolify
    labels:
      - "coolify.managed=true"
      - "coolify.type=application"

networks:
  coolify:
    external: true
```

#### Pattern 2: Microservices Architecture
```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: ./api
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    networks:
      - coolify

  frontend:
    build: ./frontend
    environment:
      - API_URL=${API_URL}
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`app.example.com`)"

  worker:
    build: ./api
    command: ["worker"]
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    networks:
      - coolify

networks:
  coolify:
    external: true
```

#### Pattern 3: Static Site with CDN
```dockerfile
# Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --production

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

## Core Concepts

### Applications
```bash
# Application types supported by Coolify:
- Docker image deployments
- Dockerfile-based builds
- Git repository deployments
- Docker Compose applications
- Static sites
- Serverless functions

# Application lifecycle:
1. Source configuration (Git/Docker)
2. Build process (if applicable)
3. Deployment (container creation)
4. Health checks
5. Traffic routing (Traefik)
6. Monitoring and logs
```

### Databases
```bash
# Supported database services:
- PostgreSQL (12, 13, 14, 15, 16)
- MySQL (5.7, 8.0)
- MariaDB (10.5, 10.6, 10.11)
- MongoDB (4.4, 5.0, 6.0, 7.0)
- Redis (6.2, 7.0)
- KeyDB
- Dragonfly

# Database features:
- Automated backups
- Point-in-time recovery
- Connection pooling
- Read replicas (manual setup)
- Persistent volumes
```

### Services
```bash
# Pre-configured services:
- Plausible Analytics
- Umami Analytics
- Matomo Analytics
- MinIO (S3-compatible storage)
- Appwrite
- WordPress
- Ghost
- Directus
- Strapi
- Supabase
- N8N
- Hasura
- PostHog

# Service templates available in:
Settings > Services > Browse Templates
```

### Teams and Permissions
```bash
# Team structure:
Team (Organization)
├── Members
│   ├── Owner (full access)
│   ├── Admin (manage resources)
│   ├── Member (deploy, view)
│   └── Guest (read-only)
├── Projects
│   ├── Production
│   ├── Staging
│   └── Development
└── Resources
    ├── Servers
    ├── Applications
    └── Databases

# Permission levels:
- Owner: Full control, billing, team management
- Admin: Create/delete resources, manage deployments
- Member: Deploy applications, view logs
- Guest: Read-only access to resources
```

## Application Deployment

### Git-Based Deployment

#### GitHub Integration
```bash
# Connect GitHub repository:
1. Navigate to Applications > New Application
2. Select "Git Repository"
3. Choose GitHub as provider
4. Authorize Coolify app
5. Select repository and branch
6. Configure build settings

# Automatic deployments:
- Enable "Auto Deploy" in application settings
- Coolify creates webhooks automatically
- Push to branch triggers deployment

# Manual webhook configuration (if needed):
Webhook URL: https://coolify.example.com/api/v1/deploy?token=YOUR_TOKEN
Content type: application/json
Events: push, pull_request
```

#### GitLab Integration
```yaml
# .gitlab-ci.yml
stages:
  - deploy

deploy_to_coolify:
  stage: deploy
  only:
    - main
  script:
    - curl -X POST https://coolify.example.com/api/v1/deploy?token=${COOLIFY_TOKEN}
  environment:
    name: production
    url: https://app.example.com
```

#### Build Configuration
```bash
# Build pack detection (automatic):
- Node.js (package.json)
- Python (requirements.txt)
- Ruby (Gemfile)
- PHP (composer.json)
- Go (go.mod)
- Rust (Cargo.toml)

# Custom build commands:
Install Command: npm ci
Build Command: npm run build
Start Command: npm run start

# Build environment variables:
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://api.example.com
```

### Docker Image Deployment
```bash
# Deploy from public registry:
Image: nginx:latest
Port: 80
Environment: production

# Deploy from private registry:
Registry: registry.example.com
Image: myapp:v1.2.3
Username: deploy
Password: ${REGISTRY_PASSWORD}

# Deploy with specific tag:
Image: ghcr.io/username/app:sha-abc123f

# Registry configuration examples:

# Docker Hub
Registry: docker.io
Image: username/application:latest
Username: dockerhub_user
Password: dockerhub_token

# GitHub Container Registry
Registry: ghcr.io
Image: ghcr.io/username/repo:latest
Username: github_username
Password: github_pat_token

# AWS ECR
Registry: 123456789012.dkr.ecr.us-east-1.amazonaws.com
Image: myapp:latest
# Login command: aws ecr get-login-password
```

### Dockerfile Deployment
```dockerfile
# Multi-stage Node.js application
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV PORT 3000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

COPY --from=builder --chown=nodejs:nodejs /app/public ./public
COPY --from=builder --chown=nodejs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nodejs:nodejs /app/.next/static ./.next/static

USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]
```

```dockerfile
# Python FastAPI application
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD curl -f http://localhost:8000/health || exit 1

# Start application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Compose Deployment
```yaml
# docker-compose.yml for full-stack application
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      - REDIS_URL=redis://redis:6379
      - SESSION_SECRET=${SESSION_SECRET}
    depends_on:
      - db
      - redis
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`${APP_DOMAIN}`)"
      - "traefik.http.routers.app.tls=true"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - coolify

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - coolify

volumes:
  postgres_data:
  redis_data:

networks:
  coolify:
    external: true
```

## Database Management

### PostgreSQL Configuration
```bash
# Create PostgreSQL database:
1. Navigate to Databases > New Database
2. Select PostgreSQL
3. Choose version (16 recommended)
4. Set database name, username, password
5. Configure backup schedule
6. Click "Create"

# Connection details:
Host: postgresql-{uuid}
Port: 5432
Database: myapp_production
Username: myapp_user
Password: {generated_or_custom}

# Connection string:
postgresql://myapp_user:password@postgresql-{uuid}:5432/myapp_production

# Backup configuration:
Frequency: Daily
Retention: 7 days
Backup time: 02:00 AM UTC
```

### MySQL Configuration
```bash
# MySQL 8.0 with optimizations:
[mysqld]
# Character set
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# InnoDB settings
innodb_buffer_pool_size=1G
innodb_log_file_size=256M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# Connection settings
max_connections=200
max_allowed_packet=64M

# Query cache (disabled in 8.0)
# Performance schema
performance_schema=ON
```

### MongoDB Configuration
```javascript
// Initialize replica set (if required)
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongodb:27017" }
  ]
});

// Create application user
use admin
db.createUser({
  user: "appuser",
  pwd: "secure_password",
  roles: [
    { role: "readWrite", db: "myapp" }
  ]
});

// Connection string
mongodb://appuser:secure_password@mongodb:27017/myapp?authSource=admin
```

### Redis Configuration
```bash
# Redis configuration for production:
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence options:
save 900 1       # Save after 900 sec if 1 key changed
save 300 10      # Save after 300 sec if 10 keys changed
save 60 10000    # Save after 60 sec if 10000 keys changed

appendonly yes
appendfsync everysec

# Connection with password:
redis://default:password@redis:6379

# TLS connection:
rediss://default:password@redis:6380
```

### Database Backup and Restore
```bash
# Automated backups (configured in dashboard):
- Schedule: Daily at 02:00 UTC
- Retention: 7 days
- Storage: Local or S3-compatible

# Manual backup (PostgreSQL):
docker exec postgresql-{uuid} pg_dump -U username dbname > backup.sql

# Manual restore (PostgreSQL):
docker exec -i postgresql-{uuid} psql -U username dbname < backup.sql

# Manual backup (MySQL):
docker exec mysql-{uuid} mysqldump -u username -p dbname > backup.sql

# Manual restore (MySQL):
docker exec -i mysql-{uuid} mysql -u username -p dbname < backup.sql

# MongoDB backup:
docker exec mongodb-{uuid} mongodump --out /backup

# MongoDB restore:
docker exec mongodb-{uuid} mongorestore /backup
```

## Environment Variables and Secrets

### Environment Variable Management
```bash
# Setting environment variables in Coolify:
1. Navigate to Application > Environment Variables
2. Add variables individually or import from file
3. Mark sensitive variables as "Secret"
4. Save and restart application

# Environment variable types:
- Build variables (available during build)
- Runtime variables (available during execution)
- Shared variables (across environments)

# Example .env file:
NODE_ENV=production
API_URL=https://api.example.com
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://redis:6379
SESSION_SECRET=your-secret-key-here
JWT_SECRET=your-jwt-secret-here
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@example.com
SMTP_PASSWORD=smtp_password
```

### Secrets Management
```bash
# Best practices for secrets:
1. Never commit secrets to Git
2. Use Coolify's secret management (encrypted at rest)
3. Rotate secrets regularly
4. Use different secrets per environment
5. Limit access to secrets by team role

# Generate secure secrets:
openssl rand -base64 32  # 32-byte random string
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
python3 -c "import secrets; print(secrets.token_hex(32))"

# Environment-specific secrets:
# Production
DATABASE_URL=postgresql://prod_user:prod_pass@prod-host:5432/prod_db

# Staging
DATABASE_URL=postgresql://stage_user:stage_pass@stage-host:5432/stage_db

# Development
DATABASE_URL=postgresql://dev_user:dev_pass@dev-host:5432/dev_db
```

### Secrets from External Providers
```bash
# AWS Secrets Manager integration (custom script):
#!/bin/bash
aws secretsmanager get-secret-value \
  --secret-id myapp/production \
  --query SecretString \
  --output text > .env

# HashiCorp Vault integration:
vault kv get -field=api_key secret/myapp/production >> .env

# Doppler integration:
doppler secrets download --no-file --format env > .env
```

## Custom Domains and SSL/TLS Certificates

### Domain Configuration
```bash
# Add custom domain:
1. Navigate to Application > Domains
2. Click "Add Domain"
3. Enter domain name (e.g., app.example.com)
4. Configure DNS A record to point to server IP
5. Enable SSL/TLS
6. Wait for certificate provisioning

# DNS records required:
app.example.com    A     192.0.2.10
www.app.example.com CNAME app.example.com

# Verify DNS propagation:
dig app.example.com +short
curl -I http://app.example.com
```

### SSL/TLS Certificate Management
```bash
# Automatic Let's Encrypt certificates:
- Issued automatically when domain is added
- Auto-renewal 30 days before expiration
- Supports wildcard certificates (*.example.com)
- Free and unlimited

# Custom SSL certificate:
1. Navigate to Application > Domains
2. Select domain
3. Click "Custom Certificate"
4. Upload certificate and private key
5. Save configuration

# Certificate formats:
Certificate: PEM format (.crt, .pem)
Private Key: PEM format (.key, .pem)
Certificate Chain: Include intermediate certificates
```

### Multi-Domain Configuration
```yaml
# Traefik labels for multiple domains:
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.app.rule=Host(`app.example.com`) || Host(`www.app.example.com`)"
  - "traefik.http.routers.app.tls=true"
  - "traefik.http.routers.app.tls.certresolver=letsencrypt"
  - "traefik.http.middlewares.redirect-www.redirectregex.regex=^https://www\\.(.*)"
  - "traefik.http.middlewares.redirect-www.redirectregex.replacement=https://$${1}"
  - "traefik.http.routers.app.middlewares=redirect-www"
```

### SSL/TLS Best Practices
```bash
# Security headers (add to application):
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'

# Traefik middleware for security headers:
labels:
  - "traefik.http.middlewares.security-headers.headers.stsSeconds=31536000"
  - "traefik.http.middlewares.security-headers.headers.stsIncludeSubdomains=true"
  - "traefik.http.middlewares.security-headers.headers.stsPreload=true"
  - "traefik.http.middlewares.security-headers.headers.frameDeny=true"
  - "traefik.http.routers.app.middlewares=security-headers"
```

## Backup and Restore Strategies

### Application Backup
```bash
# Backup strategies:
1. Volume backups (persistent data)
2. Configuration backups (docker-compose, .env)
3. Database backups (automated)
4. Full system backups (server snapshots)

# Manual application backup:
#!/bin/bash
APP_ID="your-app-uuid"
BACKUP_DIR="/backups/applications/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

# Backup volumes
docker run --rm \
  --volumes-from "${APP_ID}" \
  -v "$BACKUP_DIR:/backup" \
  alpine tar czf "/backup/volumes.tar.gz" /data

# Backup configuration
cp /data/coolify/applications/"${APP_ID}"/.env "$BACKUP_DIR/"
cp /data/coolify/applications/"${APP_ID}"/docker-compose.yml "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

### Database Backup Automation
```bash
# Automated backup script:
#!/bin/bash

# Configuration
DB_TYPE="postgresql"  # postgresql, mysql, mongodb
DB_CONTAINER="postgresql-{uuid}"
DB_USER="myapp_user"
DB_NAME="myapp_production"
BACKUP_DIR="/data/coolify/backups/databases"
RETENTION_DAYS=7
S3_BUCKET="s3://my-backups/database"

# Create backup directory
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql.gz"

# PostgreSQL backup
if [ "$DB_TYPE" == "postgresql" ]; then
  docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"
fi

# MySQL backup
if [ "$DB_TYPE" == "mysql" ]; then
  docker exec "$DB_CONTAINER" mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" | gzip > "$BACKUP_FILE"
fi

# Upload to S3 (optional)
aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/"

# Remove old backups
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $BACKUP_FILE"
```

### Disaster Recovery Plan
```bash
# Recovery procedure:

# 1. Restore Coolify instance
curl -fsSL https://cdn.coolify.io/install.sh | bash

# 2. Restore database
docker cp backup.sql postgresql-{uuid}:/tmp/
docker exec -it postgresql-{uuid} psql -U username -d dbname -f /tmp/backup.sql

# 3. Restore application volumes
docker run --rm \
  -v app-volume:/data \
  -v /backup:/backup \
  alpine tar xzf /backup/volumes.tar.gz -C /

# 4. Restore configuration
cp backup/.env /data/coolify/applications/{uuid}/
cp backup/docker-compose.yml /data/coolify/applications/{uuid}/

# 5. Restart application
docker compose -f /data/coolify/applications/{uuid}/docker-compose.yml up -d

# 6. Verify functionality
curl https://app.example.com/health
```

## Monitoring and Logging

### Application Monitoring
```bash
# Built-in monitoring features:
- Container status and health
- Resource usage (CPU, memory, network)
- Application logs (stdout/stderr)
- Build logs
- Deployment history

# Access logs:
1. Navigate to Application > Logs
2. Select log type (application, build, system)
3. Filter by date range or search terms
4. Export logs if needed

# Real-time log streaming:
docker logs -f container-name

# Container statistics:
docker stats container-name
```

### External Monitoring Integration
```yaml
# Prometheus monitoring:
version: '3.8'

services:
  app:
    image: myapp:latest
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=9090"
      - "prometheus.io/path=/metrics"

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - coolify

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.example.com`)"

volumes:
  prometheus_data:
  grafana_data:

networks:
  coolify:
    external: true
```

### Log Aggregation
```yaml
# Loki + Promtail for log aggregation:
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/config.yml
      - loki_data:/loki
    networks:
      - coolify

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers
      - ./promtail-config.yml:/etc/promtail/config.yml
    networks:
      - coolify

volumes:
  loki_data:

networks:
  coolify:
    external: true
```

### Health Checks
```dockerfile
# Dockerfile with health check:
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

```yaml
# Docker Compose health check:
services:
  app:
    image: myapp:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      start_period: 40s
      retries: 3
```

## Webhooks and CI/CD Integration

### Webhook Configuration
```bash
# Coolify webhook URL format:
https://coolify.example.com/api/v1/deploy?token=YOUR_DEPLOY_TOKEN

# Webhook payload:
{
  "branch": "main",
  "commit": "abc123f",
  "message": "Deploy to production",
  "author": "username"
}

# Generate deploy token:
1. Navigate to Application > Settings
2. Click "Webhook"
3. Copy webhook URL
4. Configure in Git provider
```

### GitHub Actions Integration
```yaml
# .github/workflows/deploy.yml
name: Deploy to Coolify

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to Coolify
        run: |
          curl -X POST "${{ secrets.COOLIFY_WEBHOOK_URL }}" \
            -H "Content-Type: application/json" \
            -d '{
              "branch": "${{ github.ref_name }}",
              "commit": "${{ github.sha }}",
              "message": "${{ github.event.head_commit.message }}",
              "author": "${{ github.actor }}"
            }'

      - name: Wait for deployment
        run: sleep 60

      - name: Verify deployment
        run: |
          curl -f https://app.example.com/health || exit 1
```

### GitLab CI/CD Integration
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: registry.gitlab.com/$CI_PROJECT_PATH:$CI_COMMIT_SHORT_SHA

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_IMAGE .
    - docker push $DOCKER_IMAGE
  only:
    - main

test:
  stage: test
  image: node:20
  script:
    - npm ci
    - npm test
  only:
    - main

deploy:
  stage: deploy
  image: curlimages/curl:latest
  script:
    - curl -X POST $COOLIFY_WEBHOOK_URL
  environment:
    name: production
    url: https://app.example.com
  only:
    - main
```

### Custom Deployment Script
```bash
#!/bin/bash

# Advanced deployment script with rollback capability

set -e

COOLIFY_URL="https://coolify.example.com"
DEPLOY_TOKEN="your-deploy-token"
APP_URL="https://app.example.com"
HEALTHCHECK_ENDPOINT="$APP_URL/health"
ROLLBACK_ENABLED=true

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting deployment..."

# Trigger deployment
DEPLOY_RESPONSE=$(curl -s -X POST "$COOLIFY_URL/api/v1/deploy?token=$DEPLOY_TOKEN")
DEPLOYMENT_ID=$(echo "$DEPLOY_RESPONSE" | jq -r '.deployment_id')

echo "Deployment triggered: $DEPLOYMENT_ID"

# Wait for deployment
MAX_WAIT=300
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
  sleep 10
  ELAPSED=$((ELAPSED + 10))

  # Check deployment status
  STATUS=$(curl -s "$COOLIFY_URL/api/v1/deployment/$DEPLOYMENT_ID/status" | jq -r '.status')

  if [ "$STATUS" == "success" ]; then
    echo -e "${GREEN}Deployment successful${NC}"
    break
  elif [ "$STATUS" == "failed" ]; then
    echo -e "${RED}Deployment failed${NC}"
    if [ "$ROLLBACK_ENABLED" == "true" ]; then
      echo "Initiating rollback..."
      curl -X POST "$COOLIFY_URL/api/v1/rollback?token=$DEPLOY_TOKEN"
    fi
    exit 1
  fi

  echo "Waiting for deployment... ($ELAPSED/$MAX_WAIT seconds)"
done

# Verify application health
echo "Verifying application health..."
sleep 15

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTHCHECK_ENDPOINT")
if [ "$HEALTH_CHECK" != "200" ]; then
  echo -e "${RED}Health check failed (HTTP $HEALTH_CHECK)${NC}"
  if [ "$ROLLBACK_ENABLED" == "true" ]; then
    echo "Initiating rollback..."
    curl -X POST "$COOLIFY_URL/api/v1/rollback?token=$DEPLOY_TOKEN"
  fi
  exit 1
fi

echo -e "${GREEN}Deployment completed successfully${NC}"
```

## Scaling and Resource Management

### Horizontal Scaling
```yaml
# Docker Compose with multiple replicas:
version: '3.8'

services:
  app:
    image: myapp:latest
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"

networks:
  coolify:
    external: true
```

### Resource Limits
```yaml
# CPU and memory constraints:
services:
  app:
    image: myapp:latest
    cpus: 1.5
    mem_limit: 2g
    mem_reservation: 1g

  worker:
    image: myapp:latest
    command: worker
    cpus: 0.5
    mem_limit: 512m

  database:
    image: postgres:16
    cpus: 2
    mem_limit: 4g
    shm_size: 256m
```

### Load Balancing Configuration
```yaml
# Traefik load balancing:
services:
  app:
    image: myapp:latest
    deploy:
      replicas: 3
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.services.app.loadbalancer.server.port=3000"
      - "traefik.http.services.app.loadbalancer.sticky.cookie=true"
      - "traefik.http.services.app.loadbalancer.sticky.cookie.name=app_sticky"
      - "traefik.http.services.app.loadbalancer.healthcheck.path=/health"
      - "traefik.http.services.app.loadbalancer.healthcheck.interval=10s"
```

### Auto-Scaling with External Tools
```bash
# Example with Docker Swarm mode:
docker service create \
  --name myapp \
  --replicas 3 \
  --update-parallelism 2 \
  --update-delay 10s \
  --rollback-parallelism 1 \
  --rollback-delay 10s \
  --constraint 'node.role==worker' \
  myapp:latest

# Scale service:
docker service scale myapp=5

# Auto-scale based on metrics (requires external orchestrator)
# Use Kubernetes or Nomad for advanced auto-scaling
```

## Security Considerations

### Network Security
```bash
# Firewall configuration (UFW):
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH (consider changing default port)
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8000/tcp  # Coolify (restrict to admin IPs)
sudo ufw enable

# Restrict Coolify dashboard access:
sudo ufw allow from 203.0.113.0/24 to any port 8000
```

### Container Security
```dockerfile
# Security best practices in Dockerfile:
FROM node:20-alpine

# Run as non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy dependencies first
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --only=production

# Copy application code
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK CMD node healthcheck.js

# Start application
CMD ["node", "server.js"]
```

### Secrets and Credentials
```bash
# Secure secret management:
1. Use Coolify's encrypted secret storage
2. Never log secrets
3. Rotate secrets regularly
4. Use strong passwords (min 16 characters)
5. Enable 2FA for Coolify dashboard
6. Limit secret access by team role

# Password generation:
openssl rand -base64 32

# API key generation:
uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]'
```

### SSL/TLS Hardening
```bash
# Traefik TLS configuration:
labels:
  - "traefik.http.routers.app.tls.options=modern@file"

# tls-options.yml:
tls:
  options:
    modern:
      minVersion: VersionTLS13
      cipherSuites:
        - TLS_AES_256_GCM_SHA384
        - TLS_CHACHA20_POLY1305_SHA256
      curvePreferences:
        - CurveP521
        - CurveP384
```

### Security Headers
```yaml
# Comprehensive security headers:
labels:
  - "traefik.http.middlewares.security.headers.stsSeconds=31536000"
  - "traefik.http.middlewares.security.headers.stsIncludeSubdomains=true"
  - "traefik.http.middlewares.security.headers.stsPreload=true"
  - "traefik.http.middlewares.security.headers.forceSTSHeader=true"
  - "traefik.http.middlewares.security.headers.frameDeny=true"
  - "traefik.http.middlewares.security.headers.contentTypeNosniff=true"
  - "traefik.http.middlewares.security.headers.browserXssFilter=true"
  - "traefik.http.middlewares.security.headers.referrerPolicy=strict-origin-when-cross-origin"
  - "traefik.http.middlewares.security.headers.permissionsPolicy=camera=(), microphone=(), geolocation=()"
  - "traefik.http.routers.app.middlewares=security"
```

### Regular Security Updates
```bash
# Update Coolify:
cd /data/coolify/source
git pull
php artisan migrate --force
docker compose up -d --force-recreate

# Update containers:
docker compose pull
docker compose up -d

# Security audit script:
#!/bin/bash
echo "Running security audit..."

# Check for outdated images
docker images --format "{{.Repository}}:{{.Tag}}" | while read image; do
  echo "Checking $image"
  docker pull "$image" >/dev/null 2>&1
done

# Check for vulnerabilities (requires Trivy)
docker images --format "{{.Repository}}:{{.Tag}}" | while read image; do
  trivy image "$image"
done

echo "Security audit complete"
```

## Troubleshooting Common Issues

### Deployment Failures
```bash
# Issue: Build fails with timeout
# Solution: Increase build timeout
docker-compose.yml:
  build:
    context: .
    args:
      BUILDKIT_PROGRESS=plain

# Issue: Out of memory during build
# Solution: Increase Docker memory limit
/etc/docker/daemon.json:
{
  "default-ulimits": {
    "memlock": {
      "Hard": -1,
      "Name": "memlock",
      "Soft": -1
    }
  }
}

# Issue: Application crashes on startup
# Solution: Check logs and environment variables
docker logs container-name --tail 100
docker exec container-name env | sort

# Issue: Container exits immediately
# Solution: Check entrypoint and command
docker inspect container-name | jq '.[0].Config.Cmd'
docker inspect container-name | jq '.[0].Config.Entrypoint'
```

### Network Issues
```bash
# Issue: Cannot reach application
# Solution: Verify network connectivity
docker network inspect coolify
docker exec container-name ping -c 3 google.com

# Issue: Traefik not routing requests
# Solution: Check Traefik logs and labels
docker logs traefik --tail 100
docker inspect container-name | jq '.[0].Config.Labels'

# Issue: SSL certificate not working
# Solution: Check Let's Encrypt rate limits and DNS
docker exec traefik cat /letsencrypt/acme.json
dig app.example.com +short
```

### Database Connection Issues
```bash
# Issue: Cannot connect to database
# Solution: Verify network and credentials
docker exec app-container nc -zv database-container 5432
docker exec database-container psql -U username -d dbname -c "SELECT 1"

# Issue: Database out of connections
# Solution: Increase max connections
PostgreSQL: max_connections = 200
MySQL: max_connections = 200

# Issue: Database running out of disk space
# Solution: Clean up old data and optimize
docker exec postgres-container psql -U username -c "VACUUM FULL"
docker system prune -a --volumes
```

### Performance Issues
```bash
# Issue: High CPU usage
# Solution: Profile application and optimize
docker stats container-name
docker top container-name

# Issue: High memory usage
# Solution: Check for memory leaks
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"

# Issue: Slow response times
# Solution: Enable caching and optimize queries
# Add Redis for caching
# Optimize database indices
# Enable CDN for static assets

# Issue: Container restart loops
# Solution: Check health checks and logs
docker ps -a | grep container-name
docker logs container-name --tail 100
docker inspect container-name | jq '.[0].State'
```

### Storage Issues
```bash
# Issue: Disk space full
# Solution: Clean up unused resources
docker system df
docker system prune -a --volumes
docker volume prune

# Find large files:
du -sh /data/coolify/* | sort -h

# Clean old backups:
find /data/coolify/backups -mtime +30 -delete

# Issue: Volume mount not working
# Solution: Check permissions and SELinux
ls -la /data/coolify/applications/app-uuid/
docker exec container-name ls -la /mount/point
```

## Migration from Other Platforms

### Migration from Heroku
```bash
# 1. Export Heroku configuration
heroku config -a myapp --shell > heroku.env

# 2. Create application in Coolify
# - Use Git repository or Docker image
# - Import environment variables from heroku.env

# 3. Migrate database
heroku pg:backups:capture -a myapp
heroku pg:backups:download -a myapp

# Import to Coolify database
docker cp latest.dump postgresql-{uuid}:/tmp/
docker exec postgresql-{uuid} pg_restore -U username -d dbname /tmp/latest.dump

# 4. Update DNS
# - Change DNS from Heroku to Coolify server
# - Wait for DNS propagation (24-48 hours)

# 5. Common Heroku features in Coolify:
# - Procfile: Convert to Dockerfile CMD
# - Config vars: Environment variables
# - Add-ons: Deploy as separate services
# - Review apps: Use multiple environments
```

### Migration from Railway
```bash
# 1. Export Railway environment variables
railway variables export > railway.env

# 2. Create new application in Coolify
# - Connect same Git repository
# - Import railway.env

# 3. Migrate volumes
# - Download data from Railway volumes
# - Upload to Coolify volumes
docker cp local-data container-name:/data

# 4. Update webhook URLs
# - Replace Railway webhook with Coolify webhook
# - Test deployment trigger

# 5. Switch DNS
# - Update DNS records to point to Coolify
# - Verify application functionality
```

### Migration from Render
```bash
# 1. Export Render configuration
# - Copy environment variables from Render dashboard
# - Document custom domains and SSL settings

# 2. Create Coolify application
# - Use same Git repository
# - Configure build and start commands

# 3. Migrate database
# Render PostgreSQL backup:
pg_dump $DATABASE_URL > render_backup.sql

# Import to Coolify:
docker exec -i postgresql-{uuid} psql -U username -d dbname < render_backup.sql

# 4. Update DNS
# - Add domains in Coolify
# - Update DNS records
# - Enable SSL/TLS

# 5. Comparison:
# Render: Automatic deploys
# Coolify: Automatic deploys via webhooks
#
# Render: Managed databases
# Coolify: Self-managed databases (more control)
#
# Render: Built-in CDN
# Coolify: Integrate Cloudflare or custom CDN
```

## Pros and Cons

### Pros

1. **Self-Hosted Freedom**
   - Complete control over infrastructure
   - No vendor lock-in
   - Data privacy and compliance control
   - Predictable costs (no per-app pricing)

2. **Cost Effective**
   - Deploy unlimited applications on single server
   - No per-deployment or per-build charges
   - Reduce cloud costs by 70-90% vs managed platforms
   - One-time setup with ongoing hosting costs only

3. **Docker-Native Platform**
   - Full Docker and Docker Compose support
   - Easy migration from containerized applications
   - Flexibility to run any Docker image
   - Support for custom Dockerfiles

4. **Integrated SSL/TLS Management**
   - Automatic Let's Encrypt certificates
   - Auto-renewal of certificates
   - Support for custom SSL certificates
   - Wildcard domain support

5. **Built-In Database Management**
   - Multiple database types supported
   - Automated backups and restore
   - Easy database provisioning
   - Connection string management

6. **Developer-Friendly Interface**
   - Clean, intuitive UI
   - Real-time logs and monitoring
   - Environment variable management
   - Team collaboration features

7. **Git Integration**
   - Direct GitHub/GitLab integration
   - Automatic deployments via webhooks
   - Multiple branch deployments
   - Roll back to previous deployments

### Cons

1. **Self-Hosting Complexity**
   - Requires server administration knowledge
   - Responsible for server security and updates
   - Need to manage backups independently
   - Troubleshooting requires Docker expertise

2. **Limited Scaling Options**
   - Manual horizontal scaling setup
   - No built-in auto-scaling
   - Requires external load balancer for large scale
   - Single server limitations for traffic spikes

3. **No Built-In CDN**
   - Must integrate external CDN (Cloudflare, etc.)
   - Static asset optimization requires configuration
   - No automatic edge caching
   - Additional setup for global distribution

4. **Community and Support**
   - Smaller community compared to major platforms
   - Limited third-party integrations
   - Documentation still evolving
   - Enterprise support not as robust

5. **Manual Server Management**
   - No managed infrastructure
   - Requires monitoring setup
   - Need to handle server failures
   - Backup strategy must be implemented

## Common Pitfalls

1. **Insufficient Server Resources**
   - Deploying too many applications on underpowered server
   - Not monitoring resource usage
   - Running out of disk space
   - Solution: Right-size server, implement monitoring, regular cleanup

2. **Missing Environment Variables**
   - Forgetting to set required environment variables
   - Using development values in production
   - Not marking sensitive variables as secrets
   - Solution: Document all required variables, use different configs per environment

3. **Docker Volume Mismanagement**
   - Not persisting data properly
   - Losing data on container restart
   - Not backing up volumes
   - Solution: Define volumes explicitly, implement backup strategy

4. **Improper SSL Configuration**
   - Not waiting for DNS propagation
   - Rate limiting on Let's Encrypt certificates
   - Missing certificate chain
   - Solution: Verify DNS before requesting certificates, use staging environment for testing

5. **Security Oversights**
   - Leaving default ports open
   - Not implementing rate limiting
   - Weak database passwords
   - Not rotating secrets
   - Solution: Follow security checklist, implement proper firewall rules, use strong credentials

6. **Database Connection Pool Exhaustion**
   - Not configuring connection limits
   - Not closing database connections
   - Too many concurrent connections
   - Solution: Configure connection pooling, optimize application code

7. **Ignoring Docker Image Size**
   - Using large base images
   - Not using multi-stage builds
   - Including development dependencies
   - Solution: Use Alpine images, implement multi-stage builds, optimize layers

8. **No Health Checks**
   - Containers marked healthy when failing
   - No automatic restart on failures
   - Manual intervention required
   - Solution: Implement proper health checks in Docker configuration

9. **Hardcoded Configuration**
   - Configuration in application code
   - Not using environment variables
   - Different configs for different environments
   - Solution: Externalize all configuration, use environment variables

10. **Inadequate Monitoring**
    - No visibility into application performance
    - Not tracking resource usage
    - Unable to detect issues proactively
    - Solution: Implement monitoring, logging, and alerting

## Real-World Deployment Examples

### Example 1: Full-Stack JavaScript Application
```yaml
# docker-compose.yml - Next.js with PostgreSQL
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      - NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
      - NEXTAUTH_URL=${APP_URL}
      - NEXT_PUBLIC_API_URL=${API_URL}
    depends_on:
      - db
      - redis
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nextapp.rule=Host(`app.example.com`)"
      - "traefik.http.routers.nextapp.tls=true"
      - "traefik.http.routers.nextapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.nextapp.loadbalancer.server.port=3000"

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - coolify

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - coolify

volumes:
  postgres_data:
  redis_data:

networks:
  coolify:
    external: true
```

### Example 2: Python FastAPI Microservices
```yaml
# docker-compose.yml - FastAPI with microservices
version: '3.8'

services:
  api-gateway:
    build: ./gateway
    environment:
      - AUTH_SERVICE_URL=http://auth:8001
      - USER_SERVICE_URL=http://users:8002
      - ORDER_SERVICE_URL=http://orders:8003
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.example.com`)"
      - "traefik.http.routers.api.tls=true"

  auth:
    build: ./services/auth
    environment:
      - DATABASE_URL=${AUTH_DB_URL}
      - JWT_SECRET=${JWT_SECRET}
    networks:
      - coolify

  users:
    build: ./services/users
    environment:
      - DATABASE_URL=${USERS_DB_URL}
      - REDIS_URL=redis://redis:6379
    networks:
      - coolify

  orders:
    build: ./services/orders
    environment:
      - DATABASE_URL=${ORDERS_DB_URL}
      - RABBITMQ_URL=${RABBITMQ_URL}
    networks:
      - coolify

  redis:
    image: redis:7-alpine
    networks:
      - coolify

networks:
  coolify:
    external: true
```

### Example 3: WordPress with Redis
```yaml
# docker-compose.yml - WordPress optimized for performance
version: '3.8'

services:
  wordpress:
    image: wordpress:6-php8.2-apache
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=${DB_USER}
      - WORDPRESS_DB_PASSWORD=${DB_PASSWORD}
      - WORDPRESS_DB_NAME=${DB_NAME}
      - WORDPRESS_CONFIG_EXTRA=
          define('WP_REDIS_HOST', 'redis');
          define('WP_REDIS_PORT', 6379);
          define('WP_CACHE', true);
    volumes:
      - wordpress_data:/var/www/html
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
    depends_on:
      - db
      - redis
    networks:
      - coolify
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.wordpress.rule=Host(`blog.example.com`)"
      - "traefik.http.routers.wordpress.tls=true"

  db:
    image: mysql:8.0
    environment:
      - MYSQL_DATABASE=${DB_NAME}
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    command: '--default-authentication-plugin=mysql_native_password'
    networks:
      - coolify

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - coolify

volumes:
  wordpress_data:
  mysql_data:
  redis_data:

networks:
  coolify:
    external: true
```

## Best Practices Summary

1. **Infrastructure Planning**
   - Right-size server for workload
   - Plan for growth and scaling
   - Implement monitoring from day one
   - Document infrastructure decisions

2. **Security First**
   - Use strong passwords and rotate regularly
   - Enable firewall and close unnecessary ports
   - Implement SSL/TLS for all applications
   - Keep Coolify and Docker updated
   - Use security headers

3. **Environment Management**
   - Separate environments (dev, staging, production)
   - Use environment variables for configuration
   - Never commit secrets to version control
   - Document required environment variables

4. **Docker Best Practices**
   - Use multi-stage builds
   - Minimize image size
   - Run as non-root user
   - Implement health checks
   - Use specific image tags (not latest)

5. **Database Management**
   - Enable automated backups
   - Test restore procedures regularly
   - Monitor database performance
   - Implement connection pooling
   - Use read replicas for scale

6. **Monitoring and Logging**
   - Implement centralized logging
   - Set up alerts for critical issues
   - Monitor resource usage
   - Track application metrics
   - Regular log rotation

7. **Deployment Strategy**
   - Use Git-based deployments
   - Implement CI/CD pipelines
   - Test in staging before production
   - Plan rollback strategy
   - Document deployment procedures

8. **Backup and Recovery**
   - Regular automated backups
   - Test recovery procedures
   - Store backups off-server
   - Document recovery process
   - Implement disaster recovery plan

9. **Performance Optimization**
   - Use CDN for static assets
   - Implement caching strategies
   - Optimize database queries
   - Configure resource limits
   - Monitor and optimize regularly

10. **Team Collaboration**
    - Use team features for access control
    - Document deployment procedures
    - Implement code review process
    - Share knowledge and best practices
    - Maintain runbooks for common issues

## Conclusion

Coolify provides a powerful, self-hosted alternative to managed platform-as-a-service solutions, offering complete control over your infrastructure while maintaining ease of use. By following the best practices outlined in this guide, you can deploy and manage applications efficiently while maintaining security, performance, and reliability.

Key takeaways:
- Self-hosting provides cost savings and control but requires infrastructure management skills
- Docker-native approach offers flexibility and portability
- Proper planning and monitoring are essential for production deployments
- Security should be implemented at every layer
- Regular backups and tested recovery procedures are critical
- Documentation and team collaboration improve operational efficiency

For production deployments, invest time in proper setup, monitoring, and maintenance. The initial effort pays dividends in reduced costs, increased control, and improved understanding of your infrastructure. Start small, iterate, and scale as your needs grow.

Remember that Coolify is actively developed, so stay updated with the latest releases and best practices through the official documentation and community channels.
