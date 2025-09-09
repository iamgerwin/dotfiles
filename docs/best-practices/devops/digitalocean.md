# DigitalOcean Best Practices

## Official Documentation
- **DigitalOcean Documentation**: https://docs.digitalocean.com
- **DigitalOcean CLI (doctl)**: https://docs.digitalocean.com/reference/doctl
- **API Reference**: https://docs.digitalocean.com/reference/api
- **Community Tutorials**: https://www.digitalocean.com/community/tutorials

## Droplet Management

### Sizing and Configuration
```bash
# Use appropriate droplet sizes
# Basic: s-1vcpu-1gb for development
# Standard: s-2vcpu-2gb for small production
# General Purpose: g-2vcpu-8gb for memory-intensive apps
# CPU-Optimized: c-2 for compute-intensive workloads

# Create droplet with proper configuration
doctl compute droplet create my-app \
  --size s-2vcpu-2gb \
  --image ubuntu-22-04-x64 \
  --region nyc3 \
  --vpc-uuid $VPC_UUID \
  --ssh-keys $SSH_KEY_ID \
  --enable-monitoring \
  --enable-backups
```

### SSH and Security
```bash
# Use SSH keys instead of passwords
doctl compute ssh-key create my-key --public-key-file ~/.ssh/id_rsa.pub

# Configure UFW firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Use fail2ban for intrusion prevention
apt install fail2ban
systemctl enable fail2ban
```

## Networking

### VPC Configuration
```bash
# Create VPC for network isolation
doctl vpcs create \
  --name production-vpc \
  --region nyc3 \
  --ip-range 10.0.0.0/16

# Use private networking for internal communication
doctl compute droplet create backend \
  --vpc-uuid $VPC_UUID \
  --enable-private-networking
```

### Load Balancer Setup
```bash
# Create load balancer
doctl compute load-balancer create \
  --name app-lb \
  --forwarding-rules entry_protocol:https,entry_port:443,target_protocol:http,target_port:8080,certificate_id:$CERT_ID \
  --health-check protocol:http,port:8080,path:/health \
  --region nyc3 \
  --vpc-uuid $VPC_UUID \
  --droplet-ids $DROPLET_IDS
```

## Database Management

### Managed Databases
```bash
# Create managed PostgreSQL database
doctl databases create postgres-cluster \
  --engine pg \
  --version 14 \
  --size db-s-1vcpu-1gb \
  --region nyc3 \
  --num-nodes 1

# Enable database backups and monitoring
doctl databases backups list postgres-cluster
doctl databases metrics bandwidth postgres-cluster
```

### Database Security
- Use connection pooling (PgBouncer for PostgreSQL)
- Enable SSL connections
- Restrict access using trusted sources
- Regular backup verification

## Storage Solutions

### Spaces Object Storage
```bash
# Configure Spaces for static assets
s3cmd --configure \
  --access_key=$SPACES_ACCESS_KEY \
  --secret_key=$SPACES_SECRET_KEY \
  --host=nyc3.digitaloceanspaces.com

# Use CDN for global distribution
doctl cdn create \
  --origin nyc3.digitaloceanspaces.com/my-bucket \
  --certificate-id $CERT_ID
```

### Volume Management
```bash
# Create and attach volumes for persistent storage
doctl compute volume create app-data \
  --size 100GiB \
  --region nyc3 \
  --fs-type ext4

doctl compute volume-action attach $VOLUME_ID $DROPLET_ID
```

## Kubernetes (DOKS)

### Cluster Setup
```bash
# Create Kubernetes cluster
doctl kubernetes cluster create production-cluster \
  --region nyc3 \
  --version 1.28.2-do.0 \
  --node-pool "name=worker-pool;size=s-2vcpu-2gb;count=3;auto-scale=true;min-nodes=1;max-nodes=5"

# Configure kubectl
doctl kubernetes cluster kubeconfig save production-cluster
```

### Cluster Management
```yaml
# Use resource limits
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

## Monitoring and Logging

### Built-in Monitoring
```bash
# Enable monitoring on droplets
doctl compute droplet create app \
  --enable-monitoring \
  --enable-backups

# View metrics
doctl monitoring metrics cpu $DROPLET_ID
doctl monitoring metrics memory $DROPLET_ID
```

### Custom Monitoring
```yaml
# Prometheus configuration for DOKS
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
```

## CI/CD Integration

### GitHub Actions with DigitalOcean
```yaml
name: Deploy to DigitalOcean
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install doctl
      uses: digitalocean/action-doctl@v2
      with:
        token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
    
    - name: Build and push Docker image
      run: |
        docker build -t registry.digitalocean.com/my-registry/app:$GITHUB_SHA .
        docker push registry.digitalocean.com/my-registry/app:$GITHUB_SHA
    
    - name: Deploy to Kubernetes
      run: |
        doctl kubernetes cluster kubeconfig save production-cluster
        kubectl set image deployment/app app=registry.digitalocean.com/my-registry/app:$GITHUB_SHA
```

## Cost Optimization

### Resource Management
- Use appropriate droplet sizes for workloads
- Enable auto-scaling for variable traffic
- Use reserved instances for predictable workloads
- Monitor bandwidth usage to avoid overages

### Storage Optimization
```bash
# Use lifecycle policies for Spaces
{
  "Rules": [{
    "ID": "DeleteOldFiles",
    "Status": "Enabled",
    "Expiration": {
      "Days": 30
    },
    "Filter": {
      "Prefix": "logs/"
    }
  }]
}
```

## Backup and Disaster Recovery

### Automated Backups
```bash
# Enable automated backups
doctl compute droplet create app \
  --enable-backups \
  --backup-policy daily

# Create snapshot for point-in-time recovery
doctl compute droplet-action snapshot $DROPLET_ID \
  --snapshot-name "pre-deployment-$(date +%Y%m%d)"
```

### Database Backups
```bash
# Schedule database backups
doctl databases backups create postgres-cluster

# Test backup restoration regularly
doctl databases create postgres-restore \
  --engine pg \
  --restore-from-backup $BACKUP_ID
```

## Security Best Practices

### Access Control
- Use IAM teams and permissions
- Rotate API tokens regularly
- Enable 2FA for all accounts
- Use service accounts for automation

### Network Security
```bash
# Use Cloud Firewalls
doctl compute firewall create app-firewall \
  --inbound-rules "protocol:tcp,ports:80,sources:addresses:0.0.0.0/0,sources:addresses:::/0" \
  --inbound-rules "protocol:tcp,ports:443,sources:addresses:0.0.0.0/0,sources:addresses:::/0" \
  --outbound-rules "protocol:tcp,ports:all,destinations:addresses:0.0.0.0/0,destinations:addresses:::/0"

doctl compute firewall add-droplets app-firewall --droplet-ids $DROPLET_IDS
```

### SSL/TLS Configuration
```bash
# Use Let's Encrypt certificates
doctl certificate create app-cert \
  --name app.example.com \
  --dns-names app.example.com,www.app.example.com \
  --type lets_encrypt
```

## Development Workflow

### Local Development
```bash
# Use doctl for local testing
doctl auth init --context development
doctl compute droplet list --context development

# Test configurations locally
doctl compute droplet create test \
  --size s-1vcpu-1gb \
  --image ubuntu-22-04-x64 \
  --region nyc3 \
  --wait \
  --user-data-file ./cloud-init.yaml
```

### Infrastructure as Code
```yaml
# Use Terraform for infrastructure management
resource "digitalocean_droplet" "app" {
  name   = "app-${var.environment}"
  image  = "ubuntu-22-04-x64"
  region = var.region
  size   = var.droplet_size
  
  vpc_uuid = digitalocean_vpc.main.id
  
  ssh_keys = [digitalocean_ssh_key.main.fingerprint]
  
  monitoring = true
  backups    = var.enable_backups
  
  user_data = file("${path.module}/cloud-init.yaml")
  
  tags = ["environment:${var.environment}", "terraform:true"]
}
```

## Performance Optimization

### Caching Strategies
- Use Redis for session storage and caching
- Implement CDN for static assets
- Enable gzip compression
- Use connection pooling for databases

### Database Performance
- Use read replicas for read-heavy workloads
- Implement proper indexing strategies
- Monitor query performance
- Use connection pooling (PgBouncer, ProxySQL)

## Common Pitfalls

1. **Not using VPCs**: Always isolate resources with VPCs
2. **Oversized droplets**: Right-size resources for actual usage
3. **No monitoring**: Enable monitoring from day one
4. **Weak security**: Use SSH keys, firewalls, and regular updates
5. **No backups**: Implement automated backup strategies
6. **Bandwidth overages**: Monitor and optimize data transfer
7. **Single region**: Consider multi-region for critical applications
8. **No automation**: Use Infrastructure as Code for reproducibility