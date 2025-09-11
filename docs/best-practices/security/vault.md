# HashiCorp Vault Best Practices

## Table of Contents
- [Official Documentation](#official-documentation)
- [Core Concepts](#core-concepts)
- [Project Structure Examples](#project-structure-examples)
- [Configuration Examples](#configuration-examples)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Do's and Don'ts](#dos-and-donts)
- [Additional Resources](#additional-resources)

## Official Documentation

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Vault API Documentation](https://www.vaultproject.io/api-docs)
- [Vault Configuration](https://www.vaultproject.io/docs/configuration)
- [Vault Auth Methods](https://www.vaultproject.io/docs/auth)
- [Vault Secrets Engines](https://www.vaultproject.io/docs/secrets)
- [Vault Security Model](https://www.vaultproject.io/docs/internals/security)
- [Vault Production Hardening](https://learn.hashicorp.com/tutorials/vault/production-hardening)

## Core Concepts

### Core Components
- **Secrets Engine**: Stores, generates, or encrypts data
- **Auth Method**: Authenticates users and machines to Vault
- **Policy**: Defines permissions for paths and operations
- **Token**: Credentials used to authenticate and authorize
- **Lease**: Time-limited access to secrets with automatic revocation
- **Audit Device**: Logs all requests and responses to Vault

### Architecture
- **Storage Backend**: Where Vault data is stored (encrypted)
- **Barrier**: Cryptographic steel and concrete around Vault data
- **Master Key**: Encrypts all data in the storage backend
- **Unseal Keys**: Used to reconstruct the master key
- **Root Token**: Initial access token with full permissions

### Key Features
- **Dynamic Secrets**: Secrets generated on-demand
- **Data Encryption**: Encryption as a Service
- **Identity-based Access**: Fine-grained access control
- **Secure Secret Storage**: Encrypted at rest and in transit
- **Detailed Audit Logs**: Complete audit trail
- **High Availability**: Multi-node clustering support

## Project Structure Examples

### Basic Vault Deployment Structure
```
vault-deployment/
├── config/
│   ├── vault.hcl
│   ├── vault-dev.hcl
│   └── vault-prod.hcl
├── policies/
│   ├── admin.hcl
│   ├── app.hcl
│   ├── ci-cd.hcl
│   └── readonly.hcl
├── scripts/
│   ├── init.sh
│   ├── unseal.sh
│   ├── setup-auth.sh
│   └── backup.sh
├── secrets/
│   ├── kv/
│   ├── database/
│   ├── aws/
│   └── pki/
├── auth/
│   ├── userpass/
│   ├── ldap/
│   ├── kubernetes/
│   └── jwt/
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── docker-compose-ha.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Enterprise Multi-Environment Structure
```
vault-infrastructure/
├── environments/
│   ├── production/
│   │   ├── config/
│   │   │   ├── vault.hcl
│   │   │   └── consul.hcl
│   │   ├── policies/
│   │   ├── secrets-engines/
│   │   └── auth-methods/
│   ├── staging/
│   ├── development/
│   └── disaster-recovery/
├── shared/
│   ├── policies/
│   │   ├── base/
│   │   ├── applications/
│   │   └── infrastructure/
│   ├── scripts/
│   │   ├── initialization/
│   │   ├── backup-restore/
│   │   ├── monitoring/
│   │   └── maintenance/
│   └── templates/
│       ├── policy-templates/
│       ├── secret-templates/
│       └── auth-templates/
├── kubernetes/
│   ├── namespace.yaml
│   ├── vault/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── configmap.yaml
│   ├── consul/
│   └── monitoring/
├── terraform/
│   ├── modules/
│   │   ├── vault-cluster/
│   │   ├── auth-methods/
│   │   └── secrets-engines/
│   ├── environments/
│   │   ├── prod/
│   │   ├── staging/
│   │   └── dev/
│   └── global/
├── ansible/
│   ├── playbooks/
│   ├── roles/
│   └── inventory/
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   └── alerts/
└── documentation/
    ├── runbooks/
    ├── procedures/
    └── architecture/
```

### Application Integration Structure
```
app-vault-integration/
├── vault-client/
│   ├── config.go
│   ├── auth.go
│   ├── secrets.go
│   └── client.go
├── policies/
│   ├── app-read.hcl
│   ├── app-write.hcl
│   └── app-admin.hcl
├── auth/
│   ├── kubernetes.go
│   ├── jwt.go
│   └── userpass.go
├── secrets/
│   ├── database.go
│   ├── aws.go
│   └── custom.go
├── config/
│   ├── vault-config.yaml
│   ├── secrets-config.yaml
│   └── auth-config.yaml
├── scripts/
│   ├── setup-vault.sh
│   ├── create-policies.sh
│   └── setup-auth.sh
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
└── kubernetes/
    ├── secret.yaml
    ├── serviceaccount.yaml
    └── deployment.yaml
```

## Configuration Examples

### Basic Vault Configuration (vault.hcl)
```hcl
# vault.hcl
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = false
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
}

api_addr = "https://vault.example.com:8200"
cluster_addr = "https://vault.example.com:8201"

ui = true
log_level = "INFO"
disable_mlock = false

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# Seal configuration (auto-unseal with AWS KMS)
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "12345678-1234-1234-1234-123456789012"
  endpoint   = "https://kms.us-east-1.amazonaws.com"
}
```

### High Availability Configuration
```hcl
# vault-ha.hcl
storage "consul" {
  address = "consul.service.consul:8500"
  path    = "vault/"
  
  # Consul token for ACL
  token = "your-consul-token"
  
  # TLS Configuration
  scheme = "https"
  tls_ca_file = "/vault/certs/consul-ca.pem"
  tls_cert_file = "/vault/certs/consul.pem"
  tls_key_file = "/vault/certs/consul-key.pem"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file   = "/vault/certs/vault.crt"
  tls_key_file    = "/vault/certs/vault.key"
  tls_min_version = "tls12"
}

cluster_addr = "https://VAULT_NODE_IP:8201"
api_addr = "https://vault.example.com:8200"

ui = true
log_level = "INFO"
disable_mlock = false

# Performance and HA settings
default_lease_ttl = "168h"
max_lease_ttl = "720h"
disable_clustering = false

# Auto-unseal with Transit
seal "transit" {
  address            = "https://vault.example.com:8200"
  token              = "vault-token"
  disable_renewal    = "false"
  key_name           = "autounseal"
  mount_path         = "transit/"
  tls_ca_cert        = "/vault/certs/ca.pem"
}
```

### Kubernetes Vault Configuration
```yaml
# kubernetes/vault-deployment.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: vault
  namespace: vault
spec:
  serviceName: vault
  replicas: 3
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      serviceAccountName: vault
      securityContext:
        runAsNonRoot: true
        runAsUser: 100
        fsGroup: 1000
      containers:
      - name: vault
        image: hashicorp/vault:1.14.0
        imagePullPolicy: IfNotPresent
        command:
        - "/bin/sh"
        - "-ec"
        args:
        - |
          cp /vault/config/vault.hcl /tmp/vault.hcl
          sed -E "s/HOST_IP/${HOST_IP?}/g" /tmp/vault.hcl > /tmp/vault-final.hcl
          vault server -config=/tmp/vault-final.hcl
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            add: ["IPC_LOCK"]
        ports:
        - containerPort: 8200
          name: vault-port
          protocol: TCP
        - containerPort: 8201
          name: vault-cluster
          protocol: TCP
        env:
        - name: HOST_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: VAULT_K8S_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: VAULT_K8S_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: VAULT_ADDR
          value: "https://127.0.0.1:8200"
        - name: VAULT_API_ADDR
          value: "https://$(HOST_IP):8200"
        - name: VAULT_CLUSTER_ADDR
          value: "https://$(HOST_IP):8201"
        - name: VAULT_RAFT_NODE_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: config
          mountPath: /vault/config
        - name: data
          mountPath: /vault/data
        - name: certs
          mountPath: /vault/certs
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        readinessProbe:
          exec:
            command: ["/bin/sh", "-c", "vault status -tls-skip-verify"]
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          exec:
            command: ["/bin/sh", "-c", "vault status -tls-skip-verify"]
          initialDelaySeconds: 60
          periodSeconds: 5
      volumes:
      - name: config
        configMap:
          name: vault-config
      - name: certs
        secret:
          secretName: vault-certs
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "fast-ssd"
      resources:
        requests:
          storage: 10Gi
```

### Policy Examples
```hcl
# policies/admin.hcl - Administrative policy
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# policies/app.hcl - Application policy
path "secret/data/myapp/*" {
  capabilities = ["read"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["list"]
}

path "database/creds/myapp-role" {
  capabilities = ["read"]
}

path "aws/creds/myapp-role" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# policies/ci-cd.hcl - CI/CD policy
path "secret/data/ci-cd/*" {
  capabilities = ["create", "read", "update", "delete"]
}

path "auth/kubernetes/role/ci-cd" {
  capabilities = ["read", "update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
```

### Secrets Engine Configuration
```bash
#!/bin/bash
# scripts/setup-secrets-engines.sh

# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Enable database secrets engine
vault secrets enable database

# Configure database connection
vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/myapp?sslmode=disable" \
  allowed_roles="readonly,readwrite" \
  username="vault" \
  password="vaultpass"

# Create database roles
vault write database/roles/readonly \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

vault write database/roles/readwrite \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS secrets engine
vault write aws/config/root \
  access_key=AKIAI... \
  secret_key=... \
  region=us-east-1

# Create AWS roles
vault write aws/roles/myapp-role \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::myapp-bucket/*"
    }
  ]
}
EOF

# Enable PKI secrets engine
vault secrets enable pki

# Configure PKI
vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal \
  common_name="example.com" \
  ttl=87600h > CA_cert.crt

vault write pki/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

vault write pki/roles/example-dot-com \
  allowed_domains="example.com" \
  allow_subdomains=true \
  max_ttl="720h"
```

### Authentication Methods Setup
```bash
#!/bin/bash
# scripts/setup-auth-methods.sh

# Enable userpass auth method
vault auth enable userpass

# Create users
vault write auth/userpass/users/admin \
  password=adminpass \
  policies=admin

vault write auth/userpass/users/developer \
  password=devpass \
  policies=app

# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create Kubernetes role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=default \
  policies=app \
  ttl=24h

# Enable JWT auth method
vault auth enable jwt

# Configure JWT auth
vault write auth/jwt/config \
  bound_issuer="https://mycompany.auth0.com/" \
  oidc_discovery_url="https://mycompany.auth0.com/"

# Create JWT role
vault write auth/jwt/role/webapp \
  bound_audiences="https://myapp.example.com" \
  bound_subject="webapp" \
  user_claim="sub" \
  role_type="jwt" \
  policies=app \
  ttl=1h

# Enable AppRole auth method
vault auth enable approle

# Create AppRole
vault write auth/approle/role/myapp \
  token_policies="app" \
  token_ttl=1h \
  token_max_ttl=4h

# Get role ID and secret ID
ROLE_ID=$(vault read -field=role_id auth/approle/role/myapp/role-id)
SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/myapp/secret-id)

echo "Role ID: $ROLE_ID"
echo "Secret ID: $SECRET_ID"
```

### Application Integration Examples
```go
// vault-client/client.go
package vault

import (
    "fmt"
    "log"
    "os"
    "time"

    "github.com/hashicorp/vault/api"
)

type VaultClient struct {
    client *api.Client
}

func NewVaultClient() (*VaultClient, error) {
    config := api.DefaultConfig()
    config.Address = os.Getenv("VAULT_ADDR")
    
    client, err := api.NewClient(config)
    if err != nil {
        return nil, fmt.Errorf("unable to initialize Vault client: %w", err)
    }

    // Authenticate using Kubernetes service account
    err = authenticateKubernetes(client)
    if err != nil {
        return nil, fmt.Errorf("unable to authenticate: %w", err)
    }

    return &VaultClient{client: client}, nil
}

func authenticateKubernetes(client *api.Client) error {
    jwt, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/token")
    if err != nil {
        return err
    }

    params := map[string]interface{}{
        "role": "myapp",
        "jwt":  string(jwt),
    }

    resp, err := client.Logical().Write("auth/kubernetes/login", params)
    if err != nil {
        return err
    }

    client.SetToken(resp.Auth.ClientToken)

    // Start token renewal
    go func() {
        renewer, err := client.NewRenewer(&api.RenewerInput{
            Secret: &api.Secret{
                Auth: resp.Auth,
            },
        })
        if err != nil {
            log.Printf("Error creating renewer: %v", err)
            return
        }

        go renewer.Renew()
        defer renewer.Stop()

        for {
            select {
            case renewal := <-renewer.RenewCh():
                log.Printf("Token renewed successfully at %v", renewal.RenewedAt)
            case err := <-renewer.ErrorCh():
                log.Printf("Error renewing token: %v", err)
                return
            }
        }
    }()

    return nil
}

func (vc *VaultClient) GetSecret(path string) (map[string]interface{}, error) {
    secret, err := vc.client.Logical().Read(path)
    if err != nil {
        return nil, err
    }
    
    if secret == nil {
        return nil, fmt.Errorf("secret not found at path: %s", path)
    }
    
    return secret.Data, nil
}

func (vc *VaultClient) GetDatabaseCredentials(role string) (*DatabaseCredentials, error) {
    secret, err := vc.client.Logical().Read(fmt.Sprintf("database/creds/%s", role))
    if err != nil {
        return nil, err
    }

    if secret == nil {
        return nil, fmt.Errorf("credentials not found for role: %s", role)
    }

    creds := &DatabaseCredentials{
        Username: secret.Data["username"].(string),
        Password: secret.Data["password"].(string),
        LeaseID:  secret.LeaseID,
        TTL:      time.Duration(secret.LeaseDuration) * time.Second,
    }

    return creds, nil
}

type DatabaseCredentials struct {
    Username string
    Password string
    LeaseID  string
    TTL      time.Duration
}
```

## Best Practices

### Security
1. **Auto-Unseal**: Use auto-unseal with cloud HSM/KMS for production
2. **TLS Everywhere**: Enable TLS for all communications
3. **Least Privilege**: Grant minimal required permissions
4. **Audit Logging**: Enable comprehensive audit logging
5. **Regular Rotation**: Implement regular secret rotation

### High Availability
1. **Multi-Node Cluster**: Deploy Vault in HA mode
2. **Load Balancing**: Use load balancers for client connections
3. **Backup Strategy**: Implement regular backup procedures
4. **Disaster Recovery**: Plan for disaster recovery scenarios
5. **Health Monitoring**: Monitor cluster health continuously

### Operations
1. **Version Control**: Store configurations in version control
2. **Infrastructure as Code**: Use Terraform for deployment
3. **Monitoring**: Implement comprehensive monitoring
4. **Documentation**: Maintain detailed documentation
5. **Testing**: Test disaster recovery procedures regularly

### Development Integration
1. **Dynamic Secrets**: Use dynamic secrets where possible
2. **Short-Lived Tokens**: Use short TTLs and automatic renewal
3. **Policy-Based Access**: Use policies for access control
4. **Secret Versioning**: Use KV v2 for secret versioning
5. **Integration Testing**: Test Vault integration in CI/CD

## Common Patterns

### Token Renewal Pattern
```go
func (vc *VaultClient) renewToken() {
    token := vc.client.Token()
    
    renewer, err := vc.client.NewRenewer(&api.RenewerInput{
        Secret: &api.Secret{
            Auth: &api.SecretAuth{
                ClientToken:   token,
                LeaseDuration: 3600, // 1 hour
            },
        },
    })
    if err != nil {
        log.Fatal(err)
    }

    go renewer.Renew()
    defer renewer.Stop()

    for {
        select {
        case renewal := <-renewer.RenewCh():
            log.Printf("Token renewed at %v", renewal.RenewedAt)
        case err := <-renewer.ErrorCh():
            log.Printf("Error renewing token: %v", err)
            // Re-authenticate or exit
            return
        }
    }
}
```

### Secret Caching Pattern
```go
type SecretCache struct {
    cache   map[string]*CachedSecret
    mutex   sync.RWMutex
    client  *VaultClient
}

type CachedSecret struct {
    Data      map[string]interface{}
    ExpiresAt time.Time
    LeaseID   string
}

func (sc *SecretCache) GetSecret(path string) (map[string]interface{}, error) {
    sc.mutex.RLock()
    cached, exists := sc.cache[path]
    sc.mutex.RUnlock()

    if exists && time.Now().Before(cached.ExpiresAt) {
        return cached.Data, nil
    }

    // Fetch from Vault
    data, err := sc.client.GetSecret(path)
    if err != nil {
        return nil, err
    }

    sc.mutex.Lock()
    sc.cache[path] = &CachedSecret{
        Data:      data,
        ExpiresAt: time.Now().Add(5 * time.Minute), // Cache for 5 minutes
    }
    sc.mutex.Unlock()

    return data, nil
}
```

### Initialization and Unseal Automation
```bash
#!/bin/bash
# scripts/init-and-unseal.sh

# Initialize Vault (only once)
if ! vault status > /dev/null 2>&1; then
    echo "Initializing Vault..."
    vault operator init -key-shares=5 -key-threshold=3 -format=json > vault-init.json
    
    # Extract unseal keys and root token
    UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' vault-init.json)
    UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' vault-init.json)
    UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' vault-init.json)
    ROOT_TOKEN=$(jq -r '.root_token' vault-init.json)
    
    # Store keys securely (this is just an example)
    echo "Root token: $ROOT_TOKEN"
    echo "Store unseal keys securely!"
fi

# Unseal Vault
if vault status | grep -q "Sealed.*true"; then
    echo "Unsealing Vault..."
    vault operator unseal $UNSEAL_KEY_1
    vault operator unseal $UNSEAL_KEY_2
    vault operator unseal $UNSEAL_KEY_3
fi

# Verify Vault is ready
vault status
```

## Do's and Don'ts

### Do's
✅ **Use auto-unseal** with cloud KMS for production deployments
✅ **Enable audit logging** for all Vault operations
✅ **Implement proper RBAC** with policies and auth methods
✅ **Use dynamic secrets** whenever possible
✅ **Regularly backup** Vault data and configuration
✅ **Monitor Vault health** and performance metrics
✅ **Use TLS encryption** for all communications
✅ **Implement token renewal** in applications
✅ **Test disaster recovery** procedures regularly
✅ **Keep Vault updated** with latest security patches

### Don'ts
❌ **Don't store unseal keys** with Vault data
❌ **Don't use root tokens** for application access
❌ **Don't ignore audit logs** or disable auditing
❌ **Don't use static secrets** when dynamic secrets are available
❌ **Don't hardcode Vault tokens** in applications
❌ **Don't deploy single-node Vault** in production
❌ **Don't skip TLS configuration** for production
❌ **Don't ignore Vault security advisories**
❌ **Don't use default configurations** in production
❌ **Don't forget to revoke** unused secrets and tokens

## Additional Resources

### Official Tools and Extensions
- [Vault CLI](https://www.vaultproject.io/docs/commands) - Command-line interface
- [Vault Agent](https://www.vaultproject.io/docs/agent) - Client-side agent for auth and caching
- [Vault Operator](https://github.com/hashicorp/vault-k8s) - Kubernetes operator
- [Consul Template](https://github.com/hashicorp/consul-template) - Template rendering tool

### Integration Libraries
- [Vault Go Client](https://github.com/hashicorp/vault/tree/main/api) - Official Go client
- [Python HVAC](https://github.com/hvac/hvac) - Python client
- [Java Vault Driver](https://github.com/BetterCloud/vault-java-driver) - Java client
- [Node.js Vault Client](https://github.com/kr1sp1n/node-vault) - Node.js client

### Deployment Tools
- [Vault Helm Chart](https://github.com/hashicorp/vault-helm) - Official Kubernetes Helm chart
- [Vault Terraform Provider](https://registry.terraform.io/providers/hashicorp/vault) - Terraform integration
- [Vault Ansible Collection](https://galaxy.ansible.com/community/hashi_vault) - Ansible integration

### Learning Resources
- [HashiCorp Learn](https://learn.hashicorp.com/vault) - Official tutorials
- [Vault Associate Certification](https://www.hashicorp.com/certification/vault-associate) - Professional certification
- [Vault Reference Architecture](https://learn.hashicorp.com/tutorials/vault/reference-architecture) - Architecture guidance
- [Production Hardening Guide](https://learn.hashicorp.com/tutorials/vault/production-hardening) - Security hardening

### Community Resources
- [Vault GitHub](https://github.com/hashicorp/vault) - Source code and issues
- [HashiCorp Discuss](https://discuss.hashicorp.com/c/vault) - Community forum
- [Vault Subreddit](https://www.reddit.com/r/hashicorp/) - Community discussions
- [Stack Overflow](https://stackoverflow.com/questions/tagged/hashicorp-vault) - Q&A platform

### Monitoring and Operations
- [Vault Metrics](https://www.vaultproject.io/docs/configuration/telemetry) - Telemetry and metrics
- [Vault Exporter](https://github.com/gruntwork-io/vault-exporter) - Prometheus exporter
- [Vault Monitoring](https://learn.hashicorp.com/tutorials/vault/monitor-telemetry-audit-splunk) - Monitoring best practices