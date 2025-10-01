# Dokploy Best Practices

## Official Documentation
- **Official Website**: https://dokploy.com
- **GitHub Repository**: https://github.com/Dokploy/dokploy
- **Documentation**: https://docs.dokploy.com
- **Community Discord**: https://discord.gg/2tBnJ3jDJc
- **Helm Charts**: https://github.com/Dokploy/dokploy-helm

## Installation and Setup

### Prerequisites
- Ubuntu 20.04+ or Debian 11+ (recommended)
- Docker 24.0+ installed
- Docker Compose v2.20+
- 2GB RAM minimum (4GB+ recommended)
- 20GB disk space minimum
- Public IP address or domain name
- Ports 80, 443, and 3000 available

### Quick Installation
```bash
# One-line installation script
curl -sSL https://dokploy.com/install.sh | sh

# Alternative: Manual installation
docker pull dokploy/dokploy:latest

# Create dokploy directory
mkdir -p /etc/dokploy

# Run Dokploy container
docker run -d \
  --name dokploy \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/dokploy:/etc/dokploy \
  dokploy/dokploy:latest
```

### Post-Installation Setup
```bash
# Access Dokploy dashboard
# Navigate to http://your-server-ip:3000

# Create admin account
# Username: admin
# Email: your-email@example.com
# Password: (set strong password)

# Verify installation
docker ps | grep dokploy
docker logs dokploy

# Check Dokploy version
docker exec dokploy dokploy version
```

### Custom Installation with Environment Variables
```bash
# Create .env file
cat > /etc/dokploy/.env << EOF
DOKPLOY_PORT=3000
DOKPLOY_SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=postgresql://dokploy:password@postgres:5432/dokploy
REDIS_URL=redis://redis:6379
DOMAIN=dokploy.example.com
SSL_EMAIL=admin@example.com
EOF

# Run with custom configuration
docker-compose -f /etc/dokploy/docker-compose.yml up -d
```

## Server Configuration and System Requirements

### Minimum Requirements
- **CPU**: 1 vCPU (2+ recommended)
- **RAM**: 2GB (4GB+ for production)
- **Storage**: 20GB SSD (50GB+ for production)
- **Network**: 100Mbps connection
- **OS**: Ubuntu 22.04 LTS or Debian 11+

### Recommended Production Requirements
- **CPU**: 4 vCPU or more
- **RAM**: 8GB or more
- **Storage**: 100GB+ SSD with backup
- **Network**: 1Gbps connection
- **OS**: Ubuntu 22.04 LTS
- **Backup**: Daily automated backups
- **Monitoring**: Prometheus + Grafana

### System Optimization
```bash
# Increase file descriptors
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
EOF

# Optimize kernel parameters
cat >> /etc/sysctl.conf << EOF
# Network performance
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300

# Memory management
vm.swappiness = 10
vm.dirty_ratio = 40
vm.dirty_background_ratio = 5
EOF

# Apply changes
sysctl -p

# Setup swap (if needed)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Docker daemon optimization
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "live-restore": true,
  "default-address-pools": [
    {
      "base": "172.17.0.0/12",
      "size": 24
    }
  ]
}
EOF

systemctl restart docker
```

### Security Hardening
```bash
# Enable UFW firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw enable

# Install and configure fail2ban
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban

# Disable root SSH login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Setup automatic security updates
apt install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades
```

## Project Structure and Deployment Architecture

### Dokploy Directory Structure
```
/etc/dokploy/
├── docker-compose.yml          # Main Dokploy compose file
├── .env                        # Environment variables
├── data/
│   ├── postgres/              # PostgreSQL data
│   ├── redis/                 # Redis data
│   └── traefik/              # Traefik configuration
├── projects/
│   ├── project-1/
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── volumes/
│   ├── project-2/
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── app/
│   └── ...
├── backups/                   # Backup storage
│   ├── databases/
│   ├── volumes/
│   └── configs/
├── ssl/                       # SSL certificates
│   ├── certs/
│   └── acme.json
└── logs/                      # Application logs
    ├── dokploy/
    ├── traefik/
    └── applications/
```

### Network Architecture
```yaml
# Dokploy creates isolated networks per project
networks:
  dokploy_network:
    external: true
  project_frontend:
    driver: bridge
  project_backend:
    driver: bridge
    internal: true
```

### Multi-Server Architecture
```
┌─────────────────────────────────────────────────┐
│              Load Balancer / CDN                │
│         (Cloudflare, AWS ALB, etc.)            │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼──────────┐  ┌───────▼──────────┐
│   Dokploy Node 1 │  │   Dokploy Node 2 │
│   (Production)   │  │   (Staging)      │
└──────────────────┘  └──────────────────┘
        │                     │
┌───────▼──────────┐  ┌───────▼──────────┐
│  Database Cluster│  │  Redis Cluster   │
│  (PostgreSQL)    │  │  (Session Store) │
└──────────────────┘  └──────────────────┘
```

## Core Concepts

### Applications
Applications are the primary deployment units in Dokploy. They can be:
- **Git-based**: Deploy directly from Git repositories
- **Docker Image**: Deploy from Docker Hub or private registry
- **Dockerfile**: Build custom images from Dockerfile
- **Docker Compose**: Multi-container applications

### Services
Services are managed infrastructure components:
- **PostgreSQL**: Managed PostgreSQL databases
- **MySQL**: Managed MySQL databases
- **MongoDB**: Managed MongoDB databases
- **Redis**: Managed Redis cache
- **MariaDB**: Managed MariaDB databases

### Compose
Multi-container applications defined using Docker Compose syntax:
- Multiple services in one stack
- Shared networks and volumes
- Environment-specific configurations

### Swarm Mode
For production deployments requiring:
- High availability
- Load balancing
- Rolling updates
- Service discovery
- Secrets management

## Application Deployment Workflows

### Git-Based Deployment
```yaml
# Dokploy application configuration
name: nodejs-app
type: git
repository: https://github.com/username/nodejs-app.git
branch: main
buildType: dockerfile
dockerfilePath: ./Dockerfile
buildContext: .
port: 3000
environment:
  NODE_ENV: production
  PORT: 3000
  DATABASE_URL: ${DATABASE_URL}
domains:
  - nodejs-app.example.com
healthcheck:
  enabled: true
  path: /health
  interval: 30s
  timeout: 10s
  retries: 3
```

### Dockerfile Example
```dockerfile
# Multi-stage build for Node.js application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node healthcheck.js

CMD ["node", "dist/main.js"]
```

### Docker Image Deployment
```yaml
name: redis-cache
type: docker-image
image: redis:7-alpine
port: 6379
volumes:
  - name: redis-data
    mountPath: /data
resources:
  limits:
    memory: 512M
    cpu: 0.5
  reservations:
    memory: 256M
    cpu: 0.25
command: redis-server --appendonly yes
```

### Multi-Container Deployment
```yaml
# docker-compose.yml for Dokploy
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://cache:6379
    depends_on:
      - db
      - cache
    networks:
      - frontend
      - backend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.web.rule=Host(`app.example.com`)"
      - "traefik.http.routers.web.entrypoints=websecure"
      - "traefik.http.routers.web.tls.certresolver=letsencrypt"
      - "traefik.http.services.web.loadbalancer.server.port=3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  worker:
    build:
      context: .
      dockerfile: Dockerfile.worker
    environment:
      - NODE_ENV=production
      - REDIS_URL=redis://cache:6379
    depends_on:
      - cache
    networks:
      - backend
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

volumes:
  postgres_data:
  redis_data:
```

### Automated Build and Deployment Script
```bash
#!/bin/bash

# Build and deploy script for Dokploy
set -e

APP_NAME="myapp"
DOKPLOY_API="https://dokploy.example.com/api"
API_TOKEN="${DOKPLOY_API_TOKEN}"
DOCKER_REGISTRY="registry.example.com"
IMAGE_TAG="${CI_COMMIT_SHA:-latest}"

echo "Building Docker image..."
docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} .

echo "Running tests..."
docker run --rm ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} npm test

echo "Pushing to registry..."
docker push ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG}

echo "Deploying to Dokploy..."
curl -X POST "${DOKPLOY_API}/applications/${APP_NAME}/deploy" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"image\": \"${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG}\",
    \"environment\": \"production\"
  }"

echo "Deployment completed successfully!"
```

## Database Integration and Management

### PostgreSQL Setup
```yaml
# Dokploy PostgreSQL service configuration
name: postgres-prod
type: postgres
version: "15"
database: myapp_production
username: myapp_user
password: ${POSTGRES_PASSWORD}
port: 5432
volumes:
  - name: postgres_data
    size: 50GB
backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 30
resources:
  memory: 2GB
  cpu: 1
```

### Database Backup Script
```bash
#!/bin/bash

# PostgreSQL backup script
BACKUP_DIR="/etc/dokploy/backups/databases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="myapp_production"
DB_USER="myapp_user"
DB_HOST="postgres-prod"

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Perform backup
docker exec postgres-prod pg_dump \
  -U ${DB_USER} \
  -d ${DB_NAME} \
  -F c \
  -f /tmp/backup_${TIMESTAMP}.dump

# Copy backup from container
docker cp postgres-prod:/tmp/backup_${TIMESTAMP}.dump \
  ${BACKUP_DIR}/

# Compress backup
gzip ${BACKUP_DIR}/backup_${TIMESTAMP}.dump

# Upload to S3 (optional)
aws s3 cp ${BACKUP_DIR}/backup_${TIMESTAMP}.dump.gz \
  s3://my-backups/databases/

# Clean up old backups (keep last 30 days)
find ${BACKUP_DIR} -name "backup_*.dump.gz" -mtime +30 -delete

echo "Backup completed: backup_${TIMESTAMP}.dump.gz"
```

### Database Restore Script
```bash
#!/bin/bash

# PostgreSQL restore script
BACKUP_FILE=$1
DB_NAME="myapp_production"
DB_USER="myapp_user"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup_file>"
  exit 1
fi

# Copy backup to container
docker cp ${BACKUP_FILE} postgres-prod:/tmp/restore.dump.gz

# Uncompress
docker exec postgres-prod gunzip /tmp/restore.dump.gz

# Drop existing database
docker exec postgres-prod psql -U ${DB_USER} -c "DROP DATABASE IF EXISTS ${DB_NAME};"

# Create new database
docker exec postgres-prod psql -U ${DB_USER} -c "CREATE DATABASE ${DB_NAME};"

# Restore backup
docker exec postgres-prod pg_restore \
  -U ${DB_USER} \
  -d ${DB_NAME} \
  -F c \
  /tmp/restore.dump

echo "Database restored successfully!"
```

### MySQL Configuration
```yaml
name: mysql-prod
type: mysql
version: "8.0"
database: myapp
username: myapp_user
password: ${MYSQL_PASSWORD}
port: 3306
configuration:
  max_connections: 200
  innodb_buffer_pool_size: 1G
  innodb_log_file_size: 256M
volumes:
  - name: mysql_data
    size: 50GB
```

### MongoDB Setup
```yaml
name: mongodb-prod
type: mongodb
version: "6.0"
database: myapp
username: myapp_user
password: ${MONGO_PASSWORD}
port: 27017
replicaSet: rs0
volumes:
  - name: mongo_data
    size: 100GB
  - name: mongo_config
    mountPath: /etc/mongo
```

### Redis Configuration
```yaml
name: redis-prod
type: redis
version: "7"
port: 6379
password: ${REDIS_PASSWORD}
maxmemory: 512mb
maxmemory_policy: allkeys-lru
persistence: aof
volumes:
  - name: redis_data
    mountPath: /data
```

## Environment Configuration and Secrets

### Environment Variables Management
```bash
# .env.production
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Database
DATABASE_URL=postgresql://user:password@postgres:5432/myapp
DB_POOL_SIZE=10

# Redis
REDIS_URL=redis://redis:6379
REDIS_TTL=3600

# API Keys (use Dokploy secrets)
API_KEY=${SECRET_API_KEY}
JWT_SECRET=${SECRET_JWT_SECRET}
ENCRYPTION_KEY=${SECRET_ENCRYPTION_KEY}

# External Services
STRIPE_SECRET_KEY=${SECRET_STRIPE_KEY}
SENDGRID_API_KEY=${SECRET_SENDGRID_KEY}
AWS_ACCESS_KEY_ID=${SECRET_AWS_ACCESS_KEY}
AWS_SECRET_ACCESS_KEY=${SECRET_AWS_SECRET_KEY}

# Application
APP_URL=https://app.example.com
CORS_ORIGIN=https://app.example.com,https://www.example.com
```

### Secrets Management
```bash
# Create secrets in Dokploy via CLI
dokploy secret create API_KEY "sk_live_xxxxxxxxxxxxx" --project myapp

# Or via API
curl -X POST "https://dokploy.example.com/api/secrets" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "API_KEY",
    "value": "sk_live_xxxxxxxxxxxxx",
    "project": "myapp"
  }'

# Use secrets in docker-compose.yml
version: '3.8'
services:
  app:
    image: myapp:latest
    environment:
      - API_KEY=${SECRET_API_KEY}
    secrets:
      - jwt_secret
      - db_password

secrets:
  jwt_secret:
    external: true
  db_password:
    external: true
```

### Environment-Specific Configurations
```yaml
# config/environments.yml
development:
  debug: true
  log_level: debug
  database:
    pool_size: 5
  cache:
    enabled: false

staging:
  debug: true
  log_level: info
  database:
    pool_size: 10
  cache:
    enabled: true
    ttl: 300

production:
  debug: false
  log_level: warn
  database:
    pool_size: 20
    ssl: true
  cache:
    enabled: true
    ttl: 3600
  monitoring:
    enabled: true
```

## Domain Management and SSL Certificates

### Domain Configuration
```yaml
# Dokploy domain settings
domains:
  - name: app.example.com
    type: primary
    ssl: true
    redirect_www: true
  - name: www.app.example.com
    type: redirect
    redirect_to: app.example.com
  - name: api.example.com
    type: subdomain
    ssl: true
    service: api
  - name: staging.example.com
    type: staging
    ssl: true
    auth:
      enabled: true
      username: admin
      password: ${STAGING_PASSWORD}
```

### Traefik Configuration for SSL
```yaml
# traefik.yml
global:
  checkNewVersion: true
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /etc/traefik/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: dokploy_network
  file:
    directory: /etc/traefik/dynamic
    watch: true

log:
  level: INFO
  filePath: /var/log/traefik/traefik.log

accessLog:
  filePath: /var/log/traefik/access.log
```

### Custom SSL Certificate Installation
```bash
# Upload custom SSL certificates
mkdir -p /etc/dokploy/ssl/certs

# Copy certificate files
cp app.example.com.crt /etc/dokploy/ssl/certs/
cp app.example.com.key /etc/dokploy/ssl/certs/
cp ca-bundle.crt /etc/dokploy/ssl/certs/

# Create Traefik dynamic configuration
cat > /etc/traefik/dynamic/ssl.yml << EOF
tls:
  certificates:
    - certFile: /ssl/certs/app.example.com.crt
      keyFile: /ssl/certs/app.example.com.key
  stores:
    default:
      defaultCertificate:
        certFile: /ssl/certs/app.example.com.crt
        keyFile: /ssl/certs/app.example.com.key
EOF

# Restart Traefik
docker restart traefik
```

### Wildcard Certificate Setup
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /etc/traefik/acme.json
      dnsChallenge:
        provider: cloudflare
        delayBeforeCheck: 30
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"

# Environment variables for DNS provider
environment:
  - CF_API_EMAIL=admin@example.com
  - CF_API_KEY=${CLOUDFLARE_API_KEY}
```

## Load Balancing and Proxy Configuration

### Traefik Load Balancing
```yaml
services:
  web:
    image: myapp:latest
    deploy:
      replicas: 3
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.web.rule=Host(`app.example.com`)"
        - "traefik.http.services.web.loadbalancer.server.port=3000"
        - "traefik.http.services.web.loadbalancer.sticky.cookie=true"
        - "traefik.http.services.web.loadbalancer.sticky.cookie.name=lb"
        - "traefik.http.services.web.loadbalancer.healthcheck.path=/health"
        - "traefik.http.services.web.loadbalancer.healthcheck.interval=10s"
```

### Advanced Traefik Middleware
```yaml
# Rate limiting
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 200
        period: 1s

    # IP whitelist
    ip-whitelist:
      ipWhiteList:
        sourceRange:
          - "10.0.0.0/8"
          - "192.168.0.0/16"
          - "172.16.0.0/12"

    # Authentication
    basic-auth:
      basicAuth:
        users:
          - "admin:$apr1$xxx$xxx"

    # CORS
    cors-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
        accessControlAllowOriginList:
          - "https://example.com"
        accessControlMaxAge: 100
        addVaryHeader: true

    # Security headers
    security-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        customFrameOptionsValue: "SAMEORIGIN"
```

### Nginx Reverse Proxy (Alternative)
```nginx
# nginx.conf
upstream backend {
    least_conn;
    server web-1:3000 max_fails=3 fail_timeout=30s;
    server web-2:3000 max_fails=3 fail_timeout=30s;
    server web-3:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    server_name app.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name app.example.com;

    ssl_certificate /etc/ssl/certs/app.example.com.crt;
    ssl_certificate_key /etc/ssl/private/app.example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /health {
        access_log off;
        proxy_pass http://backend/health;
    }
}
```

## Monitoring and Logging Solutions

### Prometheus and Grafana Setup
```yaml
# monitoring-stack.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3001:3000"
    networks:
      - monitoring
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`grafana.example.com`)"

  node-exporter:
    image: prom/node-exporter:latest
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

### Prometheus Configuration
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'dokploy'
    static_configs:
      - targets: ['dokploy:3000']
    metrics_path: '/api/metrics'

  - job_name: 'applications'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels: [__meta_docker_container_label_com_docker_compose_service]
        target_label: service
      - source_labels: [__meta_docker_container_label_com_docker_compose_project]
        target_label: project
```

### Loki for Log Aggregation
```yaml
# loki-stack.yml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring

volumes:
  loki_data:

networks:
  monitoring:
    external: true
```

### Application Logging Best Practices
```javascript
// logger.js - Structured logging example
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: process.env.SERVICE_NAME,
    environment: process.env.NODE_ENV,
    host: process.env.HOSTNAME
  },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    new winston.transports.File({
      filename: '/var/log/app/error.log',
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    new winston.transports.File({
      filename: '/var/log/app/combined.log',
      maxsize: 5242880,
      maxFiles: 5
    })
  ]
});

// Add request logging middleware
function requestLogger(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration,
      ip: req.ip,
      userAgent: req.get('user-agent')
    });
  });

  next();
}

module.exports = { logger, requestLogger };
```

## CI/CD Integration Patterns

### GitHub Actions Integration
```yaml
# .github/workflows/deploy.yml
name: Deploy to Dokploy

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  DOKPLOY_URL: https://dokploy.example.com
  PROJECT_NAME: myapp

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linter
        run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Registry
        uses: docker/login-action@v2
        with:
          registry: registry.example.com
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            registry.example.com/${{ env.PROJECT_NAME }}:latest
            registry.example.com/${{ env.PROJECT_NAME }}:${{ github.sha }}
          cache-from: type=registry,ref=registry.example.com/${{ env.PROJECT_NAME }}:buildcache
          cache-to: type=registry,ref=registry.example.com/${{ env.PROJECT_NAME }}:buildcache,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Dokploy
        run: |
          curl -X POST "${{ env.DOKPLOY_URL }}/api/applications/${{ env.PROJECT_NAME }}/deploy" \
            -H "Authorization: Bearer ${{ secrets.DOKPLOY_API_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d "{
              \"image\": \"registry.example.com/${{ env.PROJECT_NAME }}:${{ github.sha }}\",
              \"environment\": \"production\"
            }"

      - name: Wait for deployment
        run: |
          for i in {1..30}; do
            STATUS=$(curl -s -H "Authorization: Bearer ${{ secrets.DOKPLOY_API_TOKEN }}" \
              "${{ env.DOKPLOY_URL }}/api/applications/${{ env.PROJECT_NAME }}/status" | \
              jq -r '.status')

            if [ "$STATUS" = "running" ]; then
              echo "Deployment successful!"
              exit 0
            fi

            echo "Waiting for deployment... ($i/30)"
            sleep 10
          done

          echo "Deployment timeout!"
          exit 1

      - name: Run smoke tests
        run: |
          curl -f https://app.example.com/health || exit 1
          echo "Smoke tests passed!"
```

### GitLab CI Integration
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy
  - verify

variables:
  DOCKER_REGISTRY: registry.example.com
  PROJECT_NAME: myapp
  DOKPLOY_URL: https://dokploy.example.com

test:
  stage: test
  image: node:20-alpine
  script:
    - npm ci
    - npm run test
    - npm run lint
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

build:
  stage: build
  image: docker:24-dind
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $DOCKER_REGISTRY
  script:
    - docker build -t $DOCKER_REGISTRY/$PROJECT_NAME:$CI_COMMIT_SHA .
    - docker tag $DOCKER_REGISTRY/$PROJECT_NAME:$CI_COMMIT_SHA $DOCKER_REGISTRY/$PROJECT_NAME:latest
    - docker push $DOCKER_REGISTRY/$PROJECT_NAME:$CI_COMMIT_SHA
    - docker push $DOCKER_REGISTRY/$PROJECT_NAME:latest

deploy:production:
  stage: deploy
  script:
    - |
      curl -X POST "$DOKPLOY_URL/api/applications/$PROJECT_NAME/deploy" \
        -H "Authorization: Bearer $DOKPLOY_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"image\": \"$DOCKER_REGISTRY/$PROJECT_NAME:$CI_COMMIT_SHA\",
          \"environment\": \"production\"
        }"
  only:
    - main
  environment:
    name: production
    url: https://app.example.com

verify:
  stage: verify
  script:
    - sleep 30
    - curl -f https://app.example.com/health
    - echo "Deployment verified!"
  only:
    - main
```

### Webhook-Based Deployment
```bash
# webhook-deploy.sh
#!/bin/bash

# Webhook endpoint for Dokploy auto-deployment
WEBHOOK_URL="https://dokploy.example.com/api/webhooks/deploy"
WEBHOOK_SECRET="${DOKPLOY_WEBHOOK_SECRET}"
PROJECT="myapp"
BRANCH="main"

# Create webhook payload
PAYLOAD=$(cat <<EOF
{
  "project": "${PROJECT}",
  "branch": "${BRANCH}",
  "commit": "${GIT_COMMIT}",
  "author": "${GIT_AUTHOR}",
  "message": "${GIT_MESSAGE}"
}
EOF
)

# Calculate signature
SIGNATURE=$(echo -n "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print $2}')

# Send webhook
curl -X POST "${WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -H "X-Dokploy-Signature: sha256=${SIGNATURE}" \
  -d "${PAYLOAD}"
```

## Backup and Disaster Recovery

### Automated Backup Strategy
```bash
#!/bin/bash

# comprehensive-backup.sh
BACKUP_ROOT="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Backup databases
backup_databases() {
  echo "Backing up databases..."

  # PostgreSQL
  for DB in $(docker exec postgres psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';"); do
    DB_TRIMMED=$(echo $DB | xargs)
    docker exec postgres pg_dump -U postgres -F c ${DB_TRIMMED} > \
      ${BACKUP_ROOT}/databases/postgres_${DB_TRIMMED}_${TIMESTAMP}.dump
  done

  # MySQL
  docker exec mysql mysqldump --all-databases -u root -p${MYSQL_ROOT_PASSWORD} | \
    gzip > ${BACKUP_ROOT}/databases/mysql_all_${TIMESTAMP}.sql.gz

  # MongoDB
  docker exec mongodb mongodump --archive | \
    gzip > ${BACKUP_ROOT}/databases/mongodb_${TIMESTAMP}.archive.gz

  # Redis
  docker exec redis redis-cli BGSAVE
  sleep 5
  docker cp redis:/data/dump.rdb ${BACKUP_ROOT}/databases/redis_${TIMESTAMP}.rdb
}

# Backup volumes
backup_volumes() {
  echo "Backing up volumes..."

  for VOLUME in $(docker volume ls -q | grep dokploy); do
    docker run --rm \
      -v ${VOLUME}:/source:ro \
      -v ${BACKUP_ROOT}/volumes:/backup \
      alpine tar czf /backup/${VOLUME}_${TIMESTAMP}.tar.gz -C /source .
  done
}

# Backup configurations
backup_configs() {
  echo "Backing up configurations..."

  tar czf ${BACKUP_ROOT}/configs/dokploy_${TIMESTAMP}.tar.gz \
    /etc/dokploy \
    /etc/traefik \
    --exclude='*.log' \
    --exclude='*.sock'
}

# Upload to S3
upload_to_s3() {
  echo "Uploading to S3..."

  aws s3 sync ${BACKUP_ROOT} s3://my-dokploy-backups/${HOSTNAME}/ \
    --storage-class STANDARD_IA \
    --exclude "*" \
    --include "*_${TIMESTAMP}.*"
}

# Clean old backups
cleanup_old_backups() {
  echo "Cleaning up old backups..."

  find ${BACKUP_ROOT}/databases -type f -mtime +${RETENTION_DAYS} -delete
  find ${BACKUP_ROOT}/volumes -type f -mtime +${RETENTION_DAYS} -delete
  find ${BACKUP_ROOT}/configs -type f -mtime +${RETENTION_DAYS} -delete
}

# Main execution
mkdir -p ${BACKUP_ROOT}/{databases,volumes,configs}

backup_databases
backup_volumes
backup_configs
upload_to_s3
cleanup_old_backups

echo "Backup completed: ${TIMESTAMP}"
```

### Disaster Recovery Plan
```bash
#!/bin/bash

# disaster-recovery.sh
BACKUP_SOURCE=$1
RECOVERY_TYPE=${2:-full}

if [ -z "$BACKUP_SOURCE" ]; then
  echo "Usage: $0 <backup_timestamp> [full|databases|volumes|configs]"
  exit 1
fi

# Stop Dokploy services
stop_services() {
  echo "Stopping services..."
  docker-compose -f /etc/dokploy/docker-compose.yml down
}

# Restore databases
restore_databases() {
  echo "Restoring databases..."

  # PostgreSQL
  for DUMP in /backups/databases/postgres_*_${BACKUP_SOURCE}.dump; do
    DB_NAME=$(basename $DUMP | cut -d_ -f2)
    docker exec postgres dropdb -U postgres --if-exists ${DB_NAME}
    docker exec postgres createdb -U postgres ${DB_NAME}
    cat $DUMP | docker exec -i postgres pg_restore -U postgres -d ${DB_NAME}
  done

  # MySQL
  gunzip < /backups/databases/mysql_all_${BACKUP_SOURCE}.sql.gz | \
    docker exec -i mysql mysql -u root -p${MYSQL_ROOT_PASSWORD}

  # MongoDB
  gunzip < /backups/databases/mongodb_${BACKUP_SOURCE}.archive.gz | \
    docker exec -i mongodb mongorestore --archive --drop

  # Redis
  docker cp /backups/databases/redis_${BACKUP_SOURCE}.rdb redis:/data/dump.rdb
  docker restart redis
}

# Restore volumes
restore_volumes() {
  echo "Restoring volumes..."

  for BACKUP in /backups/volumes/*_${BACKUP_SOURCE}.tar.gz; do
    VOLUME=$(basename $BACKUP | sed "s/_${BACKUP_SOURCE}.tar.gz//")

    docker volume rm ${VOLUME} || true
    docker volume create ${VOLUME}

    docker run --rm \
      -v ${VOLUME}:/target \
      -v /backups/volumes:/backup \
      alpine tar xzf /backup/$(basename $BACKUP) -C /target
  done
}

# Restore configurations
restore_configs() {
  echo "Restoring configurations..."

  tar xzf /backups/configs/dokploy_${BACKUP_SOURCE}.tar.gz -C /
}

# Start services
start_services() {
  echo "Starting services..."
  docker-compose -f /etc/dokploy/docker-compose.yml up -d
}

# Main recovery process
case $RECOVERY_TYPE in
  full)
    stop_services
    restore_configs
    restore_volumes
    restore_databases
    start_services
    ;;
  databases)
    restore_databases
    ;;
  volumes)
    stop_services
    restore_volumes
    start_services
    ;;
  configs)
    stop_services
    restore_configs
    start_services
    ;;
  *)
    echo "Invalid recovery type: $RECOVERY_TYPE"
    exit 1
    ;;
esac

echo "Recovery completed!"
```

## Scaling Strategies

### Horizontal Scaling
```yaml
# docker-compose.scale.yml
version: '3.8'

services:
  web:
    image: myapp:latest
    deploy:
      mode: replicated
      replicas: 5
      update_config:
        parallelism: 2
        delay: 10s
        order: start-first
      rollback_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  worker:
    image: myapp:latest
    command: npm run worker
    deploy:
      mode: replicated
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    networks:
      - app_network

networks:
  app_network:
    driver: overlay
```

### Vertical Scaling Configuration
```yaml
# Resource allocation per service
services:
  database:
    image: postgres:15
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
    shm_size: 1g
    command:
      - postgres
      - -c
      - shared_buffers=2GB
      - -c
      - effective_cache_size=6GB
      - -c
      - maintenance_work_mem=1GB
      - -c
      - max_connections=200

  cache:
    image: redis:7
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
    command: redis-server --maxmemory 3gb --maxmemory-policy allkeys-lru
```

### Auto-Scaling Script
```bash
#!/bin/bash

# auto-scale.sh - Simple auto-scaling based on CPU usage
SERVICE="web"
MIN_REPLICAS=2
MAX_REPLICAS=10
CPU_THRESHOLD=70

while true; do
  # Get current replicas
  CURRENT_REPLICAS=$(docker service ls --filter name=${SERVICE} --format "{{.Replicas}}" | cut -d/ -f1)

  # Get CPU usage
  CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" ${SERVICE} | sed 's/%//' | awk '{sum+=$1} END {print sum/NR}')

  echo "Current replicas: ${CURRENT_REPLICAS}, CPU usage: ${CPU_USAGE}%"

  # Scale up
  if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )) && [ $CURRENT_REPLICAS -lt $MAX_REPLICAS ]; then
    NEW_REPLICAS=$((CURRENT_REPLICAS + 1))
    echo "Scaling up to ${NEW_REPLICAS} replicas"
    docker service scale ${SERVICE}=${NEW_REPLICAS}
  fi

  # Scale down
  if (( $(echo "$CPU_USAGE < 30" | bc -l) )) && [ $CURRENT_REPLICAS -gt $MIN_REPLICAS ]; then
    NEW_REPLICAS=$((CURRENT_REPLICAS - 1))
    echo "Scaling down to ${NEW_REPLICAS} replicas"
    docker service scale ${SERVICE}=${NEW_REPLICAS}
  fi

  sleep 60
done
```

## Security Best Practices

### Container Security
```dockerfile
# Secure Dockerfile example
FROM node:20-alpine AS builder

# Run as non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy only necessary files
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --chown=nodejs:nodejs . .
RUN npm run build

# Production image
FROM node:20-alpine

# Security updates
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Remove unnecessary binaries
RUN rm -rf /usr/local/bin/npm /usr/local/bin/npx

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main.js"]
```

### Network Security
```yaml
# docker-compose.security.yml
version: '3.8'

services:
  web:
    image: myapp:latest
    networks:
      - frontend
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,nodev
      - /run:noexec,nosuid,nodev

  api:
    image: myapp-api:latest
    networks:
      - frontend
      - backend
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

  database:
    image: postgres:15
    networks:
      - backend
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

networks:
  frontend:
    driver: bridge
    internal: false
  backend:
    driver: bridge
    internal: true
```

### Security Scanning
```bash
#!/bin/bash

# security-scan.sh
IMAGE=$1

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <docker-image>"
  exit 1
fi

# Scan with Trivy
echo "Scanning with Trivy..."
trivy image --severity HIGH,CRITICAL ${IMAGE}

# Scan with Snyk
echo "Scanning with Snyk..."
snyk container test ${IMAGE}

# Check for secrets
echo "Checking for secrets..."
docker run --rm -v $(pwd):/src trufflesecurity/trufflehog:latest filesystem /src

# CIS Docker Benchmark
echo "Running CIS Docker Benchmark..."
docker run --rm \
  --net host \
  --pid host \
  --userns host \
  --cap-add audit_control \
  -v /var/lib:/var/lib \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/etc:ro \
  docker/docker-bench-security
```

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Container Won't Start
```bash
# Check logs
docker logs <container-name> --tail 100

# Check events
docker events --since '10m' --filter 'type=container'

# Inspect container
docker inspect <container-name>

# Check resource limits
docker stats <container-name>
```

#### 2. Network Connectivity Issues
```bash
# List networks
docker network ls

# Inspect network
docker network inspect dokploy_network

# Test connectivity
docker run --rm --network dokploy_network alpine ping -c 3 service-name

# Check DNS resolution
docker run --rm --network dokploy_network alpine nslookup service-name
```

#### 3. Volume Permission Issues
```bash
# Fix ownership
docker run --rm \
  -v volume-name:/data \
  alpine chown -R 1000:1000 /data

# Check volume contents
docker run --rm \
  -v volume-name:/data \
  alpine ls -la /data
```

#### 4. SSL Certificate Issues
```bash
# Check Traefik logs
docker logs traefik --tail 100

# Verify certificate
docker exec traefik cat /etc/traefik/acme.json

# Test SSL
openssl s_client -connect example.com:443 -servername example.com
```

#### 5. High Memory Usage
```bash
# Check container memory
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"

# Inspect memory limits
docker inspect -f '{{.HostConfig.Memory}}' <container-name>

# Clean up
docker system prune -af
docker volume prune -f
```

### Debug Mode Configuration
```bash
# Enable debug logging
cat >> /etc/dokploy/.env << EOF
LOG_LEVEL=debug
DEBUG=true
DOCKER_LOG_LEVEL=debug
EOF

# Restart Dokploy
docker restart dokploy

# Watch logs in real-time
docker logs -f dokploy
```

## Comparison with Coolify and Other PaaS

### Feature Comparison

| Feature | Dokploy | Coolify | Heroku | Railway | Render |
|---------|---------|---------|--------|---------|--------|
| Self-Hosted | Yes | Yes | No | No | No |
| Docker Support | Yes | Yes | Yes | Yes | Yes |
| Docker Compose | Yes | Yes | Limited | No | No |
| Git Integration | Yes | Yes | Yes | Yes | Yes |
| Database Management | Yes | Yes | Yes | Yes | Yes |
| SSL Automation | Yes | Yes | Yes | Yes | Yes |
| Load Balancing | Yes (Traefik) | Yes (Traefik) | Yes | Yes | Yes |
| Monitoring | Basic | Built-in | Advanced | Basic | Basic |
| Cost | Free (self-hosted) | Free (self-hosted) | Paid | Paid | Paid |
| Scaling | Manual/API | Manual | Auto | Auto | Auto |
| Swarm Support | Yes | No | No | No | No |

### When to Choose Dokploy

**Choose Dokploy when:**
- You need full control over infrastructure
- You want to avoid vendor lock-in
- You have existing Docker Compose applications
- You need multi-server deployments with Swarm
- You want zero monthly platform costs
- You require custom networking configurations

**Choose Coolify when:**
- You want more built-in features out of the box
- You need better monitoring without additional setup
- You prefer a more polished UI/UX
- You want integrated backup solutions

**Choose Heroku/Railway/Render when:**
- You don't want to manage infrastructure
- You need auto-scaling without configuration
- You prefer managed databases
- You want enterprise support
- Cost is not a primary concern

## Pros and Cons

### Pros

1. **Full Control and Ownership**
   - Complete control over infrastructure
   - No vendor lock-in
   - Deploy on any server or cloud provider
   - Full access to underlying Docker engine

2. **Cost-Effective**
   - Zero platform fees
   - Pay only for server resources
   - Scale without platform pricing tiers
   - No per-app or per-developer costs

3. **Docker Native**
   - Native Docker and Docker Compose support
   - Use existing Dockerfiles and compose files
   - Support for Docker Swarm
   - Access to full Docker ecosystem

4. **Flexible Architecture**
   - Deploy multi-container applications easily
   - Custom networking configurations
   - Support for microservices
   - Integration with existing Docker infrastructure

5. **Privacy and Security**
   - Data stays on your infrastructure
   - No third-party data access
   - Complete control over security policies
   - Compliance-friendly for regulated industries

6. **Open Source**
   - Transparent codebase
   - Community contributions
   - Customizable to specific needs
   - No proprietary dependencies

7. **Git Integration**
   - Auto-deploy from Git repositories
   - Support for GitHub, GitLab, Bitbucket
   - Webhook-based deployments
   - Branch-based environments

### Cons

1. **Manual Infrastructure Management**
   - Requires server setup and maintenance
   - No automatic server provisioning
   - System updates are your responsibility
   - Need to manage backups and disaster recovery

2. **Limited Built-in Monitoring**
   - Basic monitoring capabilities
   - Requires integration with external tools
   - No built-in alerting system
   - Manual setup for advanced metrics

3. **Steeper Learning Curve**
   - Requires Docker knowledge
   - Infrastructure management skills needed
   - Less hand-holding than managed PaaS
   - Troubleshooting requires system knowledge

4. **No Auto-Scaling**
   - Manual scaling or custom scripts required
   - No built-in load-based scaling
   - Requires additional setup for auto-scaling
   - Limited high-availability features without Swarm

5. **Smaller Community**
   - Fewer resources compared to established platforms
   - Limited third-party integrations
   - Documentation still growing
   - Smaller support community

## Common Pitfalls

1. **Insufficient Resource Allocation**
   - Not reserving enough RAM for applications
   - Underestimating CPU requirements
   - Running out of disk space from logs and images
   - Solution: Monitor resources, set up alerts, implement log rotation

2. **Missing Health Checks**
   - Deploying without proper health check endpoints
   - Not configuring Docker health checks
   - No monitoring of application availability
   - Solution: Always implement /health endpoints and configure health checks

3. **Ignoring Log Management**
   - Logs filling up disk space
   - No centralized logging
   - Missing critical error messages
   - Solution: Configure log rotation, use log aggregation tools

4. **Weak Security Practices**
   - Exposing unnecessary ports
   - Not using secrets management
   - Running containers as root
   - Weak SSL configuration
   - Solution: Follow security best practices, use secrets, enable firewall

5. **No Backup Strategy**
   - Not backing up databases regularly
   - No disaster recovery plan
   - Missing volume backups
   - Solution: Implement automated backup scripts, test recovery procedures

6. **Improper Environment Management**
   - Mixing staging and production on same server
   - Not separating environment variables
   - Using production credentials in development
   - Solution: Use separate servers for different environments

7. **Network Configuration Errors**
   - Not using isolated networks
   - Exposing internal services
   - DNS resolution issues
   - Solution: Properly configure Docker networks, use internal networks

8. **Neglecting Updates**
   - Running outdated Docker images
   - Not updating Dokploy
   - Ignoring security patches
   - Solution: Implement update schedule, monitor security advisories

9. **Poor Resource Limits**
   - Not setting memory limits
   - No CPU quotas
   - Allowing unlimited resource usage
   - Solution: Set appropriate resource limits for all containers

10. **Inadequate Testing**
    - Deploying directly to production
    - No staging environment
    - Missing integration tests
    - Solution: Set up staging environment, implement CI/CD pipeline

## Real-World Deployment Examples

### Example 1: Full-Stack SaaS Application
```yaml
# production-saas.yml
version: '3.8'

services:
  frontend:
    image: registry.example.com/saas-frontend:latest
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    networks:
      - frontend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`app.example.com`)"
      - "traefik.http.services.frontend.loadbalancer.server.port=3000"
    environment:
      - API_URL=https://api.example.com
      - SENTRY_DSN=${SENTRY_DSN}

  api:
    image: registry.example.com/saas-api:latest
    deploy:
      replicas: 5
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
    networks:
      - frontend
      - backend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.example.com`)"
      - "traefik.http.services.api.loadbalancer.server.port=8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/saas
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${SECRET_JWT_SECRET}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s

  worker:
    image: registry.example.com/saas-api:latest
    command: npm run worker
    deploy:
      replicas: 3
    networks:
      - backend
    environment:
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgresql://user:pass@postgres:5432/saas

  postgres:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - backend

networks:
  frontend:
  backend:
    internal: true

volumes:
  postgres_data:
  redis_data:
```

### Example 2: E-commerce Platform
```yaml
# ecommerce-stack.yml
version: '3.8'

services:
  storefront:
    image: registry.example.com/storefront:latest
    deploy:
      replicas: 4
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.store.rule=Host(`shop.example.com`)"

  checkout:
    image: registry.example.com/checkout:latest
    deploy:
      replicas: 2
    networks:
      - web
      - backend
    environment:
      - STRIPE_SECRET_KEY=${SECRET_STRIPE_KEY}
      - DATABASE_URL=postgresql://ecom:pass@postgres:5432/checkout

  inventory:
    image: registry.example.com/inventory:latest
    deploy:
      replicas: 2
    networks:
      - backend
    environment:
      - DATABASE_URL=postgresql://ecom:pass@postgres:5432/inventory

  orders:
    image: registry.example.com/orders:latest
    deploy:
      replicas: 3
    networks:
      - backend
    environment:
      - DATABASE_URL=postgresql://ecom:pass@postgres:5432/orders
      - RABBITMQ_URL=amqp://rabbitmq:5672

  rabbitmq:
    image: rabbitmq:3-management-alpine
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - backend

  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend

networks:
  web:
  backend:
    internal: true

volumes:
  postgres_data:
  rabbitmq_data:
```

## Best Practices Summary

1. **Always use environment-specific configurations** - Separate dev, staging, and production
2. **Implement comprehensive health checks** - Monitor all critical services
3. **Set up automated backups** - Daily backups with tested recovery procedures
4. **Use secrets management** - Never hardcode sensitive data
5. **Configure resource limits** - Prevent resource exhaustion
6. **Implement proper logging** - Centralized, structured logging
7. **Enable monitoring and alerting** - Proactive issue detection
8. **Use multi-stage Docker builds** - Optimize image size and security
9. **Implement CI/CD pipelines** - Automate testing and deployment
10. **Regular security audits** - Keep images and dependencies updated
11. **Use isolated networks** - Segment application components
12. **Document your architecture** - Maintain up-to-date documentation
13. **Test disaster recovery** - Regularly test backup restoration
14. **Monitor costs** - Track resource usage and optimize
15. **Keep Dokploy updated** - Stay current with latest features and fixes

## Conclusion

Dokploy is a powerful self-hosted platform that brings PaaS-like deployment capabilities to your own infrastructure. It excels in scenarios where you need full control, cost optimization, and Docker-native deployments. While it requires more infrastructure management compared to fully managed platforms, it offers unparalleled flexibility and zero platform costs.

The platform is ideal for:
- Teams with DevOps expertise
- Projects requiring infrastructure control
- Organizations avoiding vendor lock-in
- Cost-sensitive deployments
- Docker-based architectures
- Regulated industries with data residency requirements

Success with Dokploy requires investment in proper setup, monitoring, and maintenance practices. Following the best practices outlined in this guide will help ensure reliable, secure, and scalable deployments. The self-hosted nature means you're responsible for infrastructure management, but in return, you gain complete control and significant cost savings at scale.
