# Traefik Best Practices

## Official Documentation
- **Main Documentation**: https://doc.traefik.io/traefik/
- **Getting Started**: https://doc.traefik.io/traefik/getting-started/quick-start/
- **API Reference**: https://doc.traefik.io/traefik/reference/dynamic-configuration/
- **Community**: https://community.traefik.io/

## Core Concepts

### Architecture Components
```yaml
# Key Components
- Edge Router: Entry point for requests
- Services: Backend applications
- Middlewares: Request/response processors
- Providers: Configuration sources
- EntryPoints: Network entry points
```

## Project Structure
```
traefik/
├── docker-compose.yml
├── traefik.yml              # Static configuration
├── config/
│   ├── dynamic/            # Dynamic configurations
│   │   ├── routers.yml
│   │   ├── services.yml
│   │   └── middlewares.yml
│   └── certificates/       # SSL certificates
├── logs/
└── acme.json              # Let's Encrypt certificates
```

## Configuration Best Practices

### 1. Static Configuration
```yaml
# traefik.yml
api:
  dashboard: true
  debug: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt
        domains:
          - main: example.com
            sans:
              - "*.example.com"

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: acme.json
      httpChallenge:
        entryPoint: web
      # Use staging for testing
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik-public
  file:
    directory: /config/dynamic
    watch: true

log:
  level: INFO
  filePath: /logs/traefik.log

accessLog:
  filePath: /logs/access.log
  bufferingSize: 100
  filters:
    statusCodes:
      - "200-299"
      - "400-499"
      - "500-599"

metrics:
  prometheus:
    addEntryPointsLabels: true
    addServicesLabels: true
```

### 2. Docker Integration
```yaml
# docker-compose.yml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - traefik-public
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./config/dynamic:/config/dynamic:ro
      - ./acme.json:/acme.json
      - ./logs:/logs
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.example.com`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=admin:$$2y$$10$$..."

  app:
    image: nginx:alpine
    container_name: app
    networks:
      - traefik-public
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.app.entrypoints=websecure"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"
      - "traefik.http.services.app.loadbalancer.server.port=80"
      - "traefik.http.routers.app.middlewares=compress,ratelimit"

networks:
  traefik-public:
    external: true
```

### 3. Kubernetes Integration
```yaml
# traefik-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
      - name: traefik
        image: traefik:v3.0
        args:
          - --api.dashboard=true
          - --providers.kubernetesingress
          - --providers.kubernetescrd
          - --entrypoints.web.address=:80
          - --entrypoints.websecure.address=:443
          - --certificatesresolvers.letsencrypt.acme.httpchallenge=true
          - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
          - --certificatesresolvers.letsencrypt.acme.email=admin@example.com
          - --certificatesresolvers.letsencrypt.acme.storage=/data/acme.json
        ports:
        - name: web
          containerPort: 80
        - name: websecure
          containerPort: 443
        - name: dashboard
          containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /data
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: traefik-data
```

## Middleware Configuration

### 1. Security Headers
```yaml
# security-headers.yml
http:
  middlewares:
    security-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customFrameOptionsValue: "SAMEORIGIN"
        referrerPolicy: "strict-origin-when-cross-origin"
        contentSecurityPolicy: |
          default-src 'self';
          script-src 'self' 'unsafe-inline';
          style-src 'self' 'unsafe-inline';
        permissionsPolicy: |
          camera=(),
          microphone=(),
          geolocation=(),
          interest-cohort=()
```

### 2. Rate Limiting
```yaml
# rate-limit.yml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        period: 1m
        burst: 50
    
    rate-limit-api:
      rateLimit:
        average: 20
        period: 1m
        burst: 10
        sourceCriterion:
          ipStrategy:
            depth: 2
            excludedIPs:
              - 127.0.0.1/32
              - 192.168.1.0/24
```

### 3. Circuit Breaker
```yaml
# circuit-breaker.yml
http:
  middlewares:
    circuit-breaker:
      circuitBreaker:
        expression: NetworkErrorRatio() > 0.5
        checkPeriod: 10s
        fallbackDuration: 10s
        recoveryDuration: 10s
```

## Load Balancing Strategies

### 1. Service Configuration
```yaml
# services.yml
http:
  services:
    app-service:
      loadBalancer:
        servers:
          - url: "http://app1:8080"
          - url: "http://app2:8080"
          - url: "http://app3:8080"
        sticky:
          cookie:
            name: server_id
            secure: true
            httpOnly: true
            sameSite: strict
        healthCheck:
          path: /health
          interval: 10s
          timeout: 3s
          hostname: app.example.com
          scheme: http
          method: GET
          followRedirects: true
    
    weighted-service:
      weighted:
        services:
          - name: app-v1
            weight: 80
          - name: app-v2
            weight: 20
```

## Advanced Routing

### 1. Path-Based Routing
```yaml
# routers.yml
http:
  routers:
    api-router:
      rule: "Host(`api.example.com`) && PathPrefix(`/v1`)"
      service: api-v1
      middlewares:
        - auth
        - rate-limit-api
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
    
    app-router:
      rule: "Host(`example.com`) || Host(`www.example.com`)"
      service: app-service
      middlewares:
        - redirect-www
        - compress
        - security-headers
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
```

### 2. Header-Based Routing
```yaml
http:
  routers:
    mobile-router:
      rule: "Host(`api.example.com`) && HeadersRegexp(`User-Agent`, `.*Mobile.*`)"
      service: mobile-api
      entryPoints:
        - websecure
    
    desktop-router:
      rule: "Host(`api.example.com`) && !HeadersRegexp(`User-Agent`, `.*Mobile.*`)"
      service: desktop-api
      entryPoints:
        - websecure
```

## Monitoring and Observability

### 1. Prometheus Integration
```yaml
# traefik.yml
metrics:
  prometheus:
    buckets:
      - 0.1
      - 0.3
      - 1.2
      - 5.0
    addEntryPointsLabels: true
    addServicesLabels: true
    addRoutersLabels: true
    entryPoint: metrics

entryPoints:
  metrics:
    address: ":8082"
```

### 2. Access Logging
```yaml
accessLog:
  filePath: /logs/access.log
  format: json
  fields:
    defaultMode: keep
    names:
      ClientUsername: drop
    headers:
      defaultMode: keep
      names:
        User-Agent: keep
        Authorization: drop
```

## Performance Optimization

### 1. Compression
```yaml
http:
  middlewares:
    compress:
      compress:
        excludedContentTypes:
          - text/event-stream
        minResponseBodyBytes: 1024
```

### 2. Buffering
```yaml
http:
  middlewares:
    buffering:
      buffering:
        maxRequestBodyBytes: 2000000
        memRequestBodyBytes: 100000
        maxResponseBodyBytes: 2000000
        memResponseBodyBytes: 100000
        retryExpression: "IsNetworkError() && Attempts() < 2"
```

## Security Best Practices

### 1. Basic Authentication
```yaml
http:
  middlewares:
    auth:
      basicAuth:
        users:
          - "admin:$2y$10$..."
        realm: "Traefik Admin"
        removeHeader: true
```

### 2. IP Whitelisting
```yaml
http:
  middlewares:
    ip-whitelist:
      ipWhiteList:
        sourceRange:
          - "192.168.1.0/24"
          - "10.0.0.0/8"
        ipStrategy:
          depth: 2
          excludedIPs:
            - "192.168.1.1/32"
```

### 3. ForwardAuth
```yaml
http:
  middlewares:
    forward-auth:
      forwardAuth:
        address: "http://auth-service:4181"
        trustForwardHeader: true
        authResponseHeaders:
          - "X-Auth-User"
          - "X-Secret"
        authResponseHeadersRegex: "^X-"
        authRequestHeaders:
          - "Accept"
          - "X-CustomHeader"
```

## High Availability Setup

### 1. Redis Backend
```yaml
# traefik.yml for HA
providers:
  redis:
    endpoints:
      - "redis-1:6379"
      - "redis-2:6379"
      - "redis-3:6379"
    rootKey: traefik
    username: traefik
    password: ${REDIS_PASSWORD}
```

### 2. Consul Backend
```yaml
providers:
  consul:
    endpoints:
      - "consul-1:8500"
      - "consul-2:8500"
      - "consul-3:8500"
    prefix: traefik
    watch: true
```

## Common Patterns

### 1. Canary Deployments
```yaml
http:
  services:
    canary-service:
      weighted:
        services:
          - name: stable
            weight: 90
          - name: canary
            weight: 10
        sticky:
          cookie:
            name: canary_affinity
```

### 2. Blue-Green Deployments
```yaml
http:
  routers:
    production:
      rule: "Host(`app.example.com`)"
      service: "{{ .Env.ACTIVE_COLOR }}-service"
      entryPoints:
        - websecure
```

### 3. Request Mirroring
```yaml
http:
  services:
    mirroring:
      mirroring:
        service: production
        mirrors:
          - name: staging
            percent: 10
```

## Troubleshooting

### Common Issues
1. **Certificate Issues**
   ```bash
   # Check certificate resolver
   docker logs traefik | grep -i acme
   
   # Verify acme.json permissions
   chmod 600 acme.json
   ```

2. **Routing Problems**
   ```bash
   # Enable debug mode
   docker exec traefik traefik version
   
   # Check router status
   curl http://traefik.example.com:8080/api/http/routers
   ```

3. **Performance Issues**
   ```bash
   # Check metrics
   curl http://localhost:8082/metrics | grep traefik
   
   # Monitor connections
   netstat -an | grep -c ESTABLISHED
   ```

## Best Practices Summary

### Do's ✅
- Use environment-specific configurations
- Implement proper health checks
- Enable access logging for debugging
- Use middleware for cross-cutting concerns
- Implement rate limiting and circuit breakers
- Secure the dashboard with authentication
- Use sticky sessions for stateful applications
- Monitor with Prometheus/Grafana
- Backup acme.json regularly
- Use semantic versioning for Traefik images

### Don'ts ❌
- Don't expose Docker socket without protection
- Don't use wildcard certificates unnecessarily
- Don't ignore security headers
- Don't skip health checks in production
- Don't use debug mode in production
- Don't store sensitive data in labels
- Don't use default credentials
- Don't ignore certificate renewal
- Don't mix static and dynamic configuration
- Don't forget to set resource limits

## Additional Resources
- **Traefik Pilot**: https://pilot.traefik.io/
- **Plugin Catalog**: https://plugins.traefik.io/
- **Migration Guide**: https://doc.traefik.io/traefik/migration/
- **Enterprise Edition**: https://traefik.io/traefik-enterprise/