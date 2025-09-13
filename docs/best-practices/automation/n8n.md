# N8N Best Practices

## Overview

N8N is an extendable workflow automation tool that enables you to connect various services and automate repetitive tasks. With its fair-code distribution model, N8N provides both cloud and self-hosted options, making it suitable for organizations of all sizes.

## Key Concepts

### Workflows
A workflow consists of nodes connected together to process data. Each node represents a specific action or trigger.

### Nodes
- **Trigger Nodes**: Start workflow execution (webhooks, schedules, manual triggers)
- **Action Nodes**: Perform operations (HTTP requests, database queries, transformations)
- **Logic Nodes**: Control flow (IF conditions, loops, merge operations)

### Expressions
N8N uses JavaScript-like expressions for dynamic data access and transformation using `{{ }}` syntax.

### Credentials
Secure storage for API keys, tokens, and authentication details used by nodes.

## Best Practices

### 1. Workflow Organization

#### Naming Conventions
```
project-name_environment_purpose
Example: crm_production_daily-sync
```

#### Folder Structure
- Group workflows by business function or department
- Use clear, descriptive names
- Maintain consistent naming patterns

#### Documentation
- Add descriptions to workflows explaining their purpose
- Document complex logic within sticky notes
- Include contact information for workflow owners

### 2. Error Handling

#### Implement Error Workflows
```javascript
// Error workflow trigger configuration
{
  "nodes": [{
    "parameters": {
      "mode": "trigger",
      "errorWorkflow": "error-handler-workflow-id"
    },
    "type": "n8n-nodes-base.errorTrigger"
  }]
}
```

#### Use Try-Catch Patterns
- Wrap critical operations in error handling nodes
- Set up notification systems for failures
- Log errors to external monitoring systems

#### Retry Logic
```javascript
// Configure automatic retries
{
  "retry": {
    "maxTries": 3,
    "waitBetweenTries": 5000
  }
}
```

### 3. Performance Optimization

#### Batch Processing
- Process items in batches rather than individually
- Use the Split In Batches node for large datasets
- Configure appropriate batch sizes based on API limits

#### Memory Management
```javascript
// Example: Process large datasets efficiently
const batchSize = 100;
const items = $input.all();

for (let i = 0; i < items.length; i += batchSize) {
  const batch = items.slice(i, i + batchSize);
  // Process batch
}
```

#### Parallel Execution
- Enable parallel processing where possible
- Balance between speed and resource consumption
- Monitor system resources during execution

### 4. Security Best Practices

#### Credential Management
- Never hardcode credentials in workflows
- Use N8N's built-in credential storage
- Implement least privilege access
- Rotate credentials regularly

#### Data Protection
```javascript
// Sanitize sensitive data
const sanitizedData = {
  ...originalData,
  password: undefined,
  apiKey: undefined,
  ssn: originalData.ssn.replace(/\d(?=\d{4})/g, '*')
};
```

#### Network Security
- Use HTTPS for all external connections
- Implement IP whitelisting where possible
- Enable webhook authentication
- Use environment-specific endpoints

### 5. Development Workflow

#### Version Control
```bash
# Export workflows for version control
n8n export:workflow --all --output=./workflows

# Import workflows from files
n8n import:workflow --input=./workflows
```

#### Environment Management
- Maintain separate instances for dev/staging/production
- Use environment variables for configuration
- Test workflows thoroughly before production deployment

#### Testing Strategy
```javascript
// Test workflow with sample data
const testData = [
  { id: 1, name: "Test Item 1" },
  { id: 2, name: "Test Item 2" }
];

// Validate output
if (!output || output.length === 0) {
  throw new Error("Workflow produced no output");
}
```

### 6. Common Patterns

#### Data Transformation
```javascript
// Clean and transform data
return items.map(item => ({
  id: item.json.id,
  name: item.json.name?.trim() || 'Unknown',
  timestamp: new Date().toISOString(),
  processed: true
}));
```

#### API Rate Limiting
```javascript
// Implement delay between requests
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

for (const item of items) {
  // Process item
  await delay(1000); // Wait 1 second between requests
}
```

#### Webhook Processing
```javascript
// Validate webhook payload
const requiredFields = ['id', 'action', 'timestamp'];
const payload = $input.item.json;

for (const field of requiredFields) {
  if (!payload[field]) {
    throw new Error(`Missing required field: ${field}`);
  }
}
```

## Configuration Examples

### Basic Webhook Workflow
```json
{
  "name": "Webhook Handler",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "webhook-endpoint",
        "responseMode": "onReceived",
        "responseData": "allEntries"
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300]
    },
    {
      "parameters": {
        "functionCode": "return items.filter(item => item.json.status === 'active');"
      },
      "name": "Filter Active",
      "type": "n8n-nodes-base.function",
      "position": [450, 300]
    }
  ]
}
```

### Database Integration
```javascript
// PostgreSQL query with parameters
const query = `
  SELECT * FROM users
  WHERE created_at > $1
  AND status = $2
  ORDER BY created_at DESC
  LIMIT $3
`;

const parameters = [
  new Date(Date.now() - 24*60*60*1000), // Last 24 hours
  'active',
  100
];
```

### Email Notification Template
```html
<!-- HTML email template -->
<html>
  <body>
    <h2>Workflow Report</h2>
    <p>Workflow: {{$node["Webhook"].json["workflowName"]}}</p>
    <p>Status: {{$node["Process"].json["status"]}}</p>
    <p>Items Processed: {{$node["Process"].json["count"]}}</p>
    <p>Timestamp: {{$now}}</p>
  </body>
</html>
```

## Troubleshooting

### Common Issues

#### Memory Errors
- Reduce batch sizes
- Enable streaming where available
- Increase Node.js memory limit: `NODE_OPTIONS="--max-old-space-size=4096"`

#### Timeout Issues
- Increase execution timeout in settings
- Break long-running workflows into smaller parts
- Use webhook callbacks for async operations

#### Connection Problems
- Verify credentials are correct
- Check network connectivity
- Review firewall rules
- Test endpoints independently

### Debugging Techniques

#### Enable Debug Mode
```bash
# Start N8N with debug logging
N8N_LOG_LEVEL=debug n8n start
```

#### Use Console Nodes
- Add Function nodes with console.log for debugging
- Review execution data in the UI
- Export execution data for analysis

#### Monitor Executions
```javascript
// Log execution details
console.log('Execution ID:', $execution.id);
console.log('Workflow ID:', $workflow.id);
console.log('Run Index:', $runIndex);
console.log('Item Index:', $itemIndex);
```

## Performance Tips

### Optimize Node Configuration
- Disable "Always Output Data" when not needed
- Use "Execute Once" mode for setup operations
- Limit data passed between nodes

### Database Queries
```sql
-- Use indexes and limit results
CREATE INDEX idx_created_at ON records(created_at);
SELECT * FROM records
WHERE created_at > NOW() - INTERVAL '1 day'
LIMIT 1000;
```

### Caching Strategies
```javascript
// Implement simple caching
const cacheKey = `cache_${inputId}`;
let cachedData = await getCacheValue(cacheKey);

if (!cachedData) {
  cachedData = await fetchExpensiveData();
  await setCacheValue(cacheKey, cachedData, 3600); // Cache for 1 hour
}

return cachedData;
```

## Integration Patterns

### Microservices Communication
```javascript
// Service discovery and load balancing
const services = [
  'http://service1.internal',
  'http://service2.internal',
  'http://service3.internal'
];

const selectedService = services[Math.floor(Math.random() * services.length)];
const response = await $http.post(selectedService, payload);
```

### Event-Driven Architecture
```javascript
// Publish events to message queue
const event = {
  eventType: 'ORDER_CREATED',
  timestamp: new Date().toISOString(),
  payload: orderData,
  metadata: {
    source: 'n8n-workflow',
    version: '1.0.0'
  }
};

await publishToQueue('events', event);
```

## Monitoring and Observability

### Metrics Collection
```javascript
// Send metrics to monitoring service
const metrics = {
  workflow: $workflow.name,
  execution_time: Date.now() - startTime,
  items_processed: items.length,
  success_rate: (successCount / items.length) * 100,
  timestamp: new Date().toISOString()
};

await sendMetrics(metrics);
```

### Health Checks
```javascript
// Implement health check endpoint
if ($input.query.health === 'check') {
  return {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    uptime: process.uptime()
  };
}
```

## Resources

- [Official Documentation](https://docs.n8n.io)
- [N8N Community Forum](https://community.n8n.io)
- [Workflow Templates](https://n8n.io/workflows)
- [API Reference](https://docs.n8n.io/api/)
- [Self-Hosting Guide](https://docs.n8n.io/hosting/)