# Azure Best Practices

## Official Documentation
- **Azure Documentation**: https://docs.microsoft.com/en-us/azure
- **Azure CLI**: https://docs.microsoft.com/en-us/cli/azure
- **Azure PowerShell**: https://docs.microsoft.com/en-us/powershell/azure
- **Azure Well-Architected Framework**: https://docs.microsoft.com/en-us/azure/architecture/framework

## Account Setup and Security

### Azure Active Directory (Entra ID)
```bash
# Create Azure AD user
az ad user create \
  --display-name "John Developer" \
  --password "SecurePassword123!" \
  --user-principal-name john@company.onmicrosoft.com

# Create service principal for applications
az ad sp create-for-rbac \
  --name "MyAppServicePrincipal" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/myResourceGroup

# Enable Multi-Factor Authentication
az ad user update \
  --id john@company.onmicrosoft.com \
  --force-change-password-next-login true
```

### Role-Based Access Control (RBAC)
```json
{
  "Name": "Custom Developer Role",
  "Id": null,
  "IsCustom": true,
  "Description": "Can manage development resources",
  "Actions": [
    "Microsoft.Compute/*/read",
    "Microsoft.Compute/virtualMachines/*",
    "Microsoft.Storage/*/read",
    "Microsoft.Storage/storageAccounts/*",
    "Microsoft.Network/*/read"
  ],
  "NotActions": [
    "Microsoft.Compute/virtualMachines/delete",
    "Microsoft.Storage/storageAccounts/delete"
  ],
  "AssignableScopes": [
    "/subscriptions/{subscription-id}/resourceGroups/development"
  ]
}
```

### Azure Policy
```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Storage/storageAccounts"
        },
        {
          "field": "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly",
          "notEquals": "true"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  },
  "parameters": {},
  "metadata": {
    "displayName": "Require HTTPS for storage accounts",
    "description": "This policy ensures storage accounts only accept HTTPS traffic"
  }
}
```

## Compute Services

### Virtual Machines
```bash
# Create resource group
az group create \
  --name myResourceGroup \
  --location eastus

# Create VM with best practices
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --public-ip-sku Standard \
  --storage-sku Premium_LRS \
  --os-disk-size-gb 128 \
  --enable-auto-update \
  --patch-mode AutomaticByOS \
  --tags Environment=Production Project=MyApp

# Enable VM extensions
az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor
```

### Virtual Machine Scale Sets
```json
{
  "name": "myScaleSet",
  "location": "East US",
  "sku": {
    "name": "Standard_D2s_v3",
    "tier": "Standard",
    "capacity": 3
  },
  "properties": {
    "upgradePolicy": {
      "mode": "Rolling",
      "rollingUpgradePolicy": {
        "maxBatchInstancePercent": 20,
        "maxUnhealthyInstancePercent": 5,
        "maxUnhealthyUpgradedInstancePercent": 5,
        "pauseTimeBetweenBatches": "PT30S"
      }
    },
    "virtualMachineProfile": {
      "osProfile": {
        "computerNamePrefix": "myapp",
        "adminUsername": "azureuser",
        "linuxConfiguration": {
          "disablePasswordAuthentication": true,
          "ssh": {
            "publicKeys": [{
              "path": "/home/azureuser/.ssh/authorized_keys",
              "keyData": "ssh-rsa AAAAB3NzaC1yc2E..."
            }]
          }
        }
      },
      "storageProfile": {
        "imageReference": {
          "publisher": "Canonical",
          "offer": "0001-com-ubuntu-server-jammy",
          "sku": "22_04-lts-gen2",
          "version": "latest"
        },
        "osDisk": {
          "createOption": "FromImage",
          "managedDisk": {
            "storageAccountType": "Premium_LRS"
          }
        }
      }
    }
  }
}
```

### Azure Functions
```csharp
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Text.Json;

public class HttpTriggerFunction
{
    private readonly ILogger _logger;

    public HttpTriggerFunction(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<HttpTriggerFunction>();
    }

    [Function("HttpTrigger")]
    public async Task<HttpResponseData> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");

        try
        {
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json; charset=utf-8");

            var result = new { message = "Hello from Azure Functions!" };
            await response.WriteStringAsync(JsonSerializer.Serialize(result));

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing request");
            
            var errorResponse = req.CreateResponse(HttpStatusCode.InternalServerError);
            await errorResponse.WriteStringAsync("Internal server error");
            return errorResponse;
        }
    }
}
```

## Storage Solutions

### Azure Storage Account
```bash
# Create storage account with best practices
az storage account create \
  --name mystorageaccount \
  --resource-group myResourceGroup \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --enable-hierarchical-namespace true

# Configure blob lifecycle management
az storage account management-policy create \
  --account-name mystorageaccount \
  --resource-group myResourceGroup \
  --policy @lifecycle-policy.json
```

### Blob Storage Lifecycle Policy
```json
{
  "rules": [
    {
      "enabled": true,
      "name": "MoveToCoolTier",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        }
      }
    }
  ]
}
```

### Azure Files Configuration
```bash
# Create file share
az storage share create \
  --name myfileshare \
  --account-name mystorageaccount \
  --quota 100

# Mount Azure Files on Linux
sudo mkdir /mnt/myfileshare
sudo mount -t cifs //mystorageaccount.file.core.windows.net/myfileshare /mnt/myfileshare \
  -o username=mystorageaccount,password=storagekey,uid=1000,gid=1000,iocharset=utf8
```

## Database Services

### Azure SQL Database
```bash
# Create SQL Server
az sql server create \
  --name myserver \
  --resource-group myResourceGroup \
  --location eastus \
  --admin-user sqladmin \
  --admin-password SecurePassword123! \
  --enable-ad-only-auth false

# Create SQL Database with best practices
az sql db create \
  --resource-group myResourceGroup \
  --server myserver \
  --name mydatabase \
  --service-objective S2 \
  --backup-storage-redundancy Local \
  --zone-redundant false \
  --read-scale Disabled

# Configure firewall rules
az sql server firewall-rule create \
  --resource-group myResourceGroup \
  --server myserver \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Enable Advanced Threat Protection
az sql server threat-policy update \
  --resource-group myResourceGroup \
  --server myserver \
  --state Enabled \
  --storage-account mystorageaccount
```

### Cosmos DB Configuration
```bash
# Create Cosmos DB account
az cosmosdb create \
  --name mycosmosdb \
  --resource-group myResourceGroup \
  --default-consistency-level Session \
  --locations regionName=eastus failoverPriority=0 isZoneRedundant=false \
  --locations regionName=westus failoverPriority=1 isZoneRedundant=false \
  --enable-automatic-failover true \
  --enable-multiple-write-locations false

# Create database and container
az cosmosdb sql database create \
  --account-name mycosmosdb \
  --resource-group myResourceGroup \
  --name mydatabase

az cosmosdb sql container create \
  --account-name mycosmosdb \
  --resource-group myResourceGroup \
  --database-name mydatabase \
  --name mycontainer \
  --partition-key-path "/userId" \
  --throughput 400
```

## Networking and Security

### Virtual Network Configuration
```bash
# Create VNet with subnets
az network vnet create \
  --resource-group myResourceGroup \
  --name myVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name frontend \
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name backend \
  --address-prefix 10.0.2.0/24

# Create Network Security Group
az network nsg create \
  --resource-group myResourceGroup \
  --name myNetworkSecurityGroup

# Add security rules
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup \
  --name Allow-HTTP \
  --protocol Tcp \
  --priority 1001 \
  --destination-port-range 80 \
  --source-address-prefix '*' \
  --destination-address-prefix '*' \
  --access Allow \
  --direction Inbound
```

### Application Gateway
```bash
# Create Application Gateway
az network application-gateway create \
  --name myAppGateway \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --subnet frontend \
  --capacity 2 \
  --sku Standard_v2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address myAGPublicIPAddress

# Configure SSL certificate
az network application-gateway ssl-cert create \
  --gateway-name myAppGateway \
  --resource-group myResourceGroup \
  --name myCert \
  --cert-file certificate.pfx \
  --cert-password password
```

### Azure Key Vault
```bash
# Create Key Vault
az keyvault create \
  --name myKeyVault \
  --resource-group myResourceGroup \
  --location eastus \
  --sku standard \
  --enable-soft-delete true \
  --soft-delete-retention-days 90 \
  --enable-purge-protection true

# Add secrets
az keyvault secret set \
  --vault-name myKeyVault \
  --name "DatabaseConnectionString" \
  --value "Server=myserver;Database=mydatabase;..."

# Grant access to applications
az keyvault set-policy \
  --name myKeyVault \
  --spn {service-principal-id} \
  --secret-permissions get list
```

## Container Services

### Azure Container Registry
```bash
# Create container registry
az acr create \
  --resource-group myResourceGroup \
  --name myContainerRegistry \
  --sku Premium \
  --admin-enabled true

# Build and push image
az acr build \
  --registry myContainerRegistry \
  --image myapp:latest \
  --file Dockerfile .

# Configure geo-replication
az acr replication create \
  --registry myContainerRegistry \
  --location westus
```

### Azure Kubernetes Service (AKS)
```bash
# Create AKS cluster
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --kubernetes-version 1.28.5 \
  --enable-addons monitoring,http_application_routing \
  --attach-acr myContainerRegistry \
  --enable-managed-identity \
  --network-plugin azure \
  --network-policy azure \
  --service-cidr 10.0.0.0/16 \
  --dns-service-ip 10.0.0.10 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Get credentials
az aks get-credentials \
  --resource-group myResourceGroup \
  --name myAKSCluster
```

### AKS Deployment Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myContainerRegistry.azurecr.io/myapp:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: AZURE_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: azure-credentials
              key: client-id
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

## Monitoring and Logging

### Azure Monitor Configuration
```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group myResourceGroup \
  --workspace-name myWorkspace \
  --location eastus \
  --sku pergb2018

# Create Application Insights
az monitor app-insights component create \
  --app myAppInsights \
  --location eastus \
  --resource-group myResourceGroup \
  --application-type web \
  --workspace myWorkspace
```

### Custom Metrics and Alerts
```bash
# Create action group
az monitor action-group create \
  --resource-group myResourceGroup \
  --name myActionGroup \
  --short-name myAG \
  --email-receiver name=admin email=admin@company.com

# Create metric alert
az monitor metrics alert create \
  --name "High CPU Alert" \
  --resource-group myResourceGroup \
  --scopes /subscriptions/{subscription-id}/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action myActionGroup \
  --description "Alert when CPU usage is over 80%"
```

### Application Insights Integration
```csharp
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;

public class MyService
{
    private readonly TelemetryClient _telemetryClient;

    public MyService(TelemetryClient telemetryClient)
    {
        _telemetryClient = telemetryClient;
    }

    public async Task<string> ProcessDataAsync(string data)
    {
        using var operation = _telemetryClient.StartOperation<DependencyTelemetry>("ProcessData");
        
        try
        {
            // Add custom properties
            operation.Telemetry.Properties["DataLength"] = data.Length.ToString();
            operation.Telemetry.Properties["ProcessingMethod"] = "Standard";
            
            var result = await ProcessAsync(data);
            
            // Track custom metrics
            _telemetryClient.TrackMetric("ProcessingTime", operation.Telemetry.Duration.TotalMilliseconds);
            _telemetryClient.TrackEvent("DataProcessed", new Dictionary<string, string>
            {
                ["ResultLength"] = result.Length.ToString()
            });
            
            return result;
        }
        catch (Exception ex)
        {
            _telemetryClient.TrackException(ex);
            operation.Telemetry.Success = false;
            throw;
        }
    }
}
```

## DevOps and CI/CD

### Azure DevOps Pipeline
```yaml
trigger:
- main

variables:
  vmImageName: 'ubuntu-latest'
  azureServiceConnection: 'MyServiceConnection'
  containerRegistry: 'myContainerRegistry.azurecr.io'
  imageRepository: 'myapp'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: Build and push stage
  jobs:
  - job: Build
    displayName: Build
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: Docker@2
      displayName: Build and push image
      inputs:
        command: buildAndPush
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(azureServiceConnection)
        tags: |
          $(tag)
          latest

- stage: Deploy
  displayName: Deploy stage
  dependsOn: Build
  jobs:
  - deployment: Deploy
    displayName: Deploy
    pool:
      vmImage: $(vmImageName)
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: Deploy to Kubernetes cluster
            inputs:
              action: deploy
              manifests: |
                $(Pipeline.Workspace)/manifests/deployment.yml
                $(Pipeline.Workspace)/manifests/service.yml
              containers: |
                $(containerRegistry)/$(imageRepository):$(tag)
```

### Bicep Infrastructure as Code
```bicep
param location string = resourceGroup().location
param appName string
param environment string

var storageAccountName = '${appName}${environment}storage'
var appServicePlanName = '${appName}-${environment}-plan'
var webAppName = '${appName}-${environment}-app'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P1v3'
    tier: 'Premium'
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, '2023-01-01').keys[0].value}'
        }
        {
          name: 'NODE_ENV'
          value: environment
        }
      ]
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output storageAccountName string = storageAccount.name
```

## Cost Optimization

### Resource Tagging Strategy
```bash
# Apply consistent tags
az resource tag \
  --tags Environment=Production Project=MyApp CostCenter=Engineering Owner=DevTeam \
  --ids /subscriptions/{subscription-id}/resourceGroups/myResourceGroup

# Use Azure Policy to enforce tagging
az policy assignment create \
  --name "Require-Tags" \
  --policy "/providers/Microsoft.Authorization/policyDefinitions/1e30110a-5ceb-460c-a204-c1c3969c6d62" \
  --scope "/subscriptions/{subscription-id}" \
  --params '{"tagName": {"value": "Environment"}}'
```

### Reserved Instances and Savings Plans
```bash
# Purchase Reserved VM Instances
az consumption reservation purchase \
  --reserved-resource-type VirtualMachines \
  --sku Standard_D2s_v3 \
  --location eastus \
  --quantity 2 \
  --term P1Y \
  --billing-scope /subscriptions/{subscription-id}

# Analyze usage with Cost Management
az consumption usage list \
  --start-date 2023-01-01 \
  --end-date 2023-12-31 \
  --billing-period-name 202312
```

### Automated Resource Management
```powershell
# PowerShell script for automated resource cleanup
Connect-AzAccount

# Find unused resources
$unusedDisks = Get-AzDisk | Where-Object {$_.ManagedBy -eq $null -and $_.TimeCreated -lt (Get-Date).AddDays(-30)}
$unusedNICs = Get-AzNetworkInterface | Where-Object {$_.VirtualMachine -eq $null}
$unusedIPs = Get-AzPublicIpAddress | Where-Object {$_.IpConfiguration -eq $null}

# Clean up unused resources (with confirmation)
foreach ($disk in $unusedDisks) {
    Write-Host "Found unused disk: $($disk.Name)"
    # Remove-AzDisk -ResourceGroupName $disk.ResourceGroupName -DiskName $disk.Name -Force
}
```

## Security Best Practices

### Azure Security Center
```bash
# Enable Security Center
az security auto-provisioning-setting update \
  --name default \
  --auto-provision on

# Configure security policies
az policy assignment create \
  --name "ASC Default" \
  --policy-set-definition "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8" \
  --scope "/subscriptions/{subscription-id}"
```

### Network Security
```bash
# Create DDoS protection plan
az network ddos-protection create \
  --resource-group myResourceGroup \
  --name myDdosProtectionPlan

# Enable DDoS protection on VNet
az network vnet update \
  --resource-group myResourceGroup \
  --name myVNet \
  --ddos-protection-plan myDdosProtectionPlan \
  --ddos-protection true
```

## Common Pitfalls

1. **No resource governance**: Use Azure Policy and Management Groups
2. **Weak identity management**: Implement proper RBAC and Conditional Access
3. **No cost monitoring**: Set up budgets and alerts
4. **Inadequate backup**: Implement Azure Backup for critical resources
5. **Single region deployment**: Consider multi-region for critical workloads
6. **No network security**: Use NSGs, ASGs, and Azure Firewall
7. **Insecure storage**: Enable encryption and disable public access
8. **No monitoring**: Implement comprehensive monitoring with Azure Monitor
9. **Manual deployments**: Use Infrastructure as Code (Bicep/ARM)
10. **No disaster recovery**: Plan for business continuity with Azure Site Recovery