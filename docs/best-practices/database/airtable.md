# Airtable Best Practices

## Official Documentation
- **Airtable Documentation**: https://airtable.com/developers/web
- **Airtable API**: https://airtable.com/developers/web/api/introduction
- **Airtable Scripting**: https://airtable.com/developers/scripting
- **Airtable Apps**: https://airtable.com/developers/apps

## Overview
Airtable is a cloud-based platform that combines the simplicity of a spreadsheet with the power of a database. It's ideal for organizing work, tracking projects, and building custom business applications.

## Core Best Practices

### 1. API Setup and Authentication

#### JavaScript/Node.js
```javascript
// npm install airtable
const Airtable = require('airtable');

// Configure
Airtable.configure({
    apiKey: process.env.AIRTABLE_API_KEY,
    endpointUrl: 'https://api.airtable.com'
});

// Connect to base
const base = Airtable.base('BASE_ID');

// With custom configuration
const base = new Airtable({
    apiKey: process.env.AIRTABLE_API_KEY,
    requestTimeout: 30000,
    // Custom rate limiting
    rateLimitMs: 200 // 5 requests per second
}).base('BASE_ID');
```

#### Python
```python
# pip install pyairtable
from pyairtable import Table, Api

# Connect to table
table = Table('API_KEY', 'BASE_ID', 'TABLE_NAME')

# Or use Api class for multiple tables
api = Api('API_KEY')
base = api.base('BASE_ID')
table = base.table('TABLE_NAME')

# With environment variables
import os
from pyairtable import Table

table = Table(
    api_key=os.environ['AIRTABLE_API_KEY'],
    base_id=os.environ['AIRTABLE_BASE_ID'],
    table_name='Projects'
)
```

### 2. Schema Design

#### Base Structure Best Practices
```javascript
// Example: Project Management Base
const schema = {
    tables: {
        Projects: {
            fields: {
                'Name': 'Single line text',
                'Status': 'Single select',
                'Priority': 'Single select',
                'Start Date': 'Date',
                'End Date': 'Date',
                'Team Members': 'Link to Users',
                'Tasks': 'Link to Tasks',
                'Budget': 'Currency',
                'Progress': 'Percent',
                'Description': 'Long text',
                'Attachments': 'Attachments'
            }
        },
        Tasks: {
            fields: {
                'Title': 'Single line text',
                'Project': 'Link to Projects',
                'Assigned To': 'Link to Users',
                'Status': 'Single select',
                'Due Date': 'Date',
                'Priority': 'Single select',
                'Description': 'Long text',
                'Completed': 'Checkbox',
                'Hours Estimated': 'Number',
                'Hours Actual': 'Number'
            }
        },
        Users: {
            fields: {
                'Name': 'Single line text',
                'Email': 'Email',
                'Role': 'Single select',
                'Department': 'Single select',
                'Projects': 'Link to Projects',
                'Tasks': 'Link to Tasks',
                'Avatar': 'Attachments',
                'Phone': 'Phone number',
                'Start Date': 'Date'
            }
        }
    }
};

// Field types and their uses
const fieldTypes = {
    'Single line text': 'Short text, names, titles',
    'Long text': 'Descriptions, notes',
    'Attachments': 'Files, images, documents',
    'Checkbox': 'Boolean values',
    'Multiple select': 'Tags, categories',
    'Single select': 'Status, priority',
    'Date': 'Dates with optional time',
    'Phone number': 'Formatted phone numbers',
    'Email': 'Email addresses',
    'URL': 'Web links',
    'Number': 'Integers or decimals',
    'Currency': 'Money values',
    'Percent': 'Percentage values',
    'Duration': 'Time durations',
    'Rating': 'Star ratings',
    'Link to another record': 'Relationships',
    'Formula': 'Calculated fields',
    'Rollup': 'Aggregate linked records',
    'Count': 'Count linked records',
    'Lookup': 'Pull data from linked records',
    'Created time': 'Auto timestamp',
    'Last modified time': 'Auto update timestamp',
    'Created by': 'User who created',
    'Last modified by': 'User who last modified',
    'Autonumber': 'Sequential IDs',
    'Barcode': 'Scannable codes',
    'Button': 'Trigger actions'
};
```

### 3. CRUD Operations

#### Create Records
```javascript
// Single record
const record = await base('Projects').create({
    'Name': 'New Website',
    'Status': 'In Progress',
    'Priority': 'High',
    'Start Date': '2024-01-15',
    'Budget': 50000,
    'Team Members': ['rec123', 'rec456'] // Record IDs
});

// Multiple records (batch)
const records = await base('Tasks').create([
    {
        fields: {
            'Title': 'Design Homepage',
            'Project': ['recProjectId'],
            'Status': 'To Do',
            'Priority': 'High'
        }
    },
    {
        fields: {
            'Title': 'Setup Database',
            'Project': ['recProjectId'],
            'Status': 'To Do',
            'Priority': 'Medium'
        }
    }
], { typecast: true }); // Auto-convert types

// With error handling
try {
    const records = await base('Projects').create(
        projectsData.map(data => ({ fields: data })),
        { typecast: true }
    );
    console.log(`Created ${records.length} records`);
} catch (error) {
    if (error.statusCode === 422) {
        console.error('Validation error:', error.message);
    } else {
        console.error('API error:', error);
    }
}
```

#### Read Records
```javascript
// Get single record
const record = await base('Projects').find('recXXXXX');
console.log(record.fields);

// List records with filtering
const records = await base('Tasks').select({
    maxRecords: 100,
    view: 'Grid view',
    filterByFormula: "AND({Status} = 'In Progress', {Priority} = 'High')",
    sort: [
        { field: 'Due Date', direction: 'asc' },
        { field: 'Priority', direction: 'desc' }
    ],
    fields: ['Title', 'Status', 'Assigned To', 'Due Date'],
    returnFieldsByFieldId: false
}).firstPage();

// Iterate through all records
await base('Projects').select({
    view: 'All Projects'
}).eachPage(async (records, fetchNextPage) => {
    for (const record of records) {
        await processRecord(record);
    }
    fetchNextPage();
});

// Get all records
const allRecords = await base('Tasks').select({
    view: 'Grid view'
}).all();
```

#### Update Records
```javascript
// Update single record
const updatedRecord = await base('Projects').update('recXXXXX', {
    'Status': 'Completed',
    'Progress': 1.0,
    'End Date': '2024-03-15'
});

// Update multiple records
const updates = await base('Tasks').update([
    {
        id: 'rec1',
        fields: { 'Status': 'Completed', 'Completed': true }
    },
    {
        id: 'rec2',
        fields: { 'Status': 'In Progress', 'Progress': 0.5 }
    }
]);

// Replace entire record (removes unspecified fields)
const replaced = await base('Projects').replace('recXXXXX', {
    'Name': 'Updated Project Name',
    'Status': 'Active'
    // Other fields will be cleared
});
```

#### Delete Records
```javascript
// Delete single record
await base('Tasks').destroy('recXXXXX');

// Delete multiple records
const deleted = await base('Tasks').destroy(['rec1', 'rec2', 'rec3']);

// Delete with confirmation
async function safeDelete(tableId, recordId) {
    const record = await base(tableId).find(recordId);
    console.log(`Deleting: ${record.fields.Name}`);
    
    if (confirm('Are you sure?')) {
        await base(tableId).destroy(recordId);
        console.log('Record deleted');
    }
}
```

### 4. Formula Fields
```javascript
// Common formula examples
const formulas = {
    // Date calculations
    daysUntilDue: "DATETIME_DIFF({Due Date}, TODAY(), 'days')",
    
    // Conditional logic
    status: "IF({Completed}, 'Done', IF({Due Date} < TODAY(), 'Overdue', 'Pending'))",
    
    // Text manipulation
    fullName: "CONCATENATE({First Name}, ' ', {Last Name})",
    
    // Numeric calculations
    profit: "{Revenue} - {Costs}",
    margin: "IF({Revenue} > 0, ({Revenue} - {Costs}) / {Revenue}, 0)",
    
    // Working with linked records
    projectStatus: "IF(COUNTA({Tasks}) = COUNTA(FILTER({Tasks}, {Status} = 'Done')), 'Complete', 'In Progress')",
    
    // Complex conditions
    priority: `
        SWITCH(
            {Priority Score},
            >= 8, 'Critical',
            >= 5, 'High',
            >= 3, 'Medium',
            'Low'
        )
    `
};
```

### 5. Filtering and Querying
```javascript
// Filter formula examples
const filters = {
    // Basic equality
    byStatus: "{Status} = 'Active'",
    
    // Multiple conditions
    highPriority: "AND({Priority} = 'High', {Status} != 'Completed')",
    
    // Date filters
    thisMonth: "IS_SAME({Created}, TODAY(), 'month')",
    overdue: "AND({Due Date} < TODAY(), {Status} != 'Completed')",
    
    // Text search
    search: "OR(SEARCH('keyword', {Title}), SEARCH('keyword', {Description}))",
    
    // Numeric ranges
    budgetRange: "AND({Budget} >= 10000, {Budget} <= 50000)",
    
    // Linked records
    hasTeam: "COUNTA({Team Members}) > 0",
    
    // Complex filter
    complex: `
        AND(
            OR({Status} = 'Active', {Status} = 'Pending'),
            {Priority} = 'High',
            {Assigned To} != BLANK(),
            DATETIME_DIFF({Due Date}, TODAY(), 'days') <= 7
        )
    `
};

// Apply filter
const urgentTasks = await base('Tasks').select({
    filterByFormula: filters.overdue,
    sort: [{ field: 'Due Date', direction: 'asc' }]
}).all();
```

### 6. Automation Scripts
```javascript
// Airtable Scripting Block
// Get input from user
const projectName = await input.textAsync('Enter project name:');
const priority = await input.buttonsAsync('Select priority:', ['Low', 'Medium', 'High']);

// Query tables
const projectsTable = base.getTable('Projects');
const tasksTable = base.getTable('Tasks');

// Create project
const projectId = await projectsTable.createRecordAsync({
    'Name': projectName,
    'Priority': { name: priority },
    'Status': { name: 'Planning' },
    'Start Date': new Date()
});

// Create default tasks
const defaultTasks = [
    'Initial Planning',
    'Requirements Gathering',
    'Design Phase',
    'Development',
    'Testing',
    'Deployment'
];

for (const taskName of defaultTasks) {
    await tasksTable.createRecordAsync({
        'Title': taskName,
        'Project': [{ id: projectId }],
        'Status': { name: 'To Do' }
    });
}

output.text(`Created project "${projectName}" with ${defaultTasks.length} tasks`);
```

### 7. Webhooks and Integrations
```javascript
// Webhook receiver (Express.js)
const express = require('express');
const app = express();

app.post('/webhook/airtable', express.json(), async (req, res) => {
    const { baseId, tableId, recordId, fields } = req.body;
    
    console.log(`Record ${recordId} updated in ${tableId}`);
    
    // Process the webhook
    if (fields.Status === 'Completed') {
        await sendCompletionNotification(fields);
    }
    
    res.status(200).send('OK');
});

// Zapier/Make integration helper
class AirtableIntegration {
    constructor(base) {
        this.base = base;
    }
    
    async syncToExternalSystem(tableName, record) {
        // Transform Airtable record to external format
        const transformed = this.transformRecord(record);
        
        // Send to external API
        const response = await fetch('https://api.external.com/sync', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${process.env.EXTERNAL_API_KEY}`
            },
            body: JSON.stringify(transformed)
        });
        
        // Update Airtable with sync status
        await this.base(tableName).update(record.id, {
            'Sync Status': response.ok ? 'Synced' : 'Error',
            'Last Sync': new Date().toISOString()
        });
    }
    
    transformRecord(record) {
        return {
            id: record.id,
            name: record.fields.Name,
            status: record.fields.Status,
            // Map fields as needed
        };
    }
}
```

## Advanced Patterns

### 1. Batch Processing
```javascript
class AirtableBatch {
    constructor(base, table) {
        this.base = base;
        this.table = table;
        this.batchSize = 10; // Airtable limit
    }
    
    async createBatch(records) {
        const results = [];
        
        for (let i = 0; i < records.length; i += this.batchSize) {
            const batch = records.slice(i, i + this.batchSize);
            const created = await this.base(this.table).create(
                batch.map(r => ({ fields: r }))
            );
            results.push(...created);
            
            // Rate limiting
            await this.delay(200);
        }
        
        return results;
    }
    
    async updateBatch(updates) {
        const results = [];
        
        for (let i = 0; i < updates.length; i += this.batchSize) {
            const batch = updates.slice(i, i + this.batchSize);
            const updated = await this.base(this.table).update(batch);
            results.push(...updated);
            
            await this.delay(200);
        }
        
        return results;
    }
    
    async deleteBatch(recordIds) {
        const results = [];
        
        for (let i = 0; i < recordIds.length; i += this.batchSize) {
            const batch = recordIds.slice(i, i + this.batchSize);
            const deleted = await this.base(this.table).destroy(batch);
            results.push(...deleted);
            
            await this.delay(200);
        }
        
        return results;
    }
    
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
```

### 2. Caching Layer
```javascript
class AirtableCache {
    constructor(base, ttl = 300000) { // 5 minutes default
        this.base = base;
        this.cache = new Map();
        this.ttl = ttl;
    }
    
    async getRecord(table, recordId, force = false) {
        const key = `${table}:${recordId}`;
        
        if (!force && this.cache.has(key)) {
            const cached = this.cache.get(key);
            if (Date.now() - cached.timestamp < this.ttl) {
                return cached.data;
            }
        }
        
        const record = await this.base(table).find(recordId);
        this.cache.set(key, {
            data: record,
            timestamp: Date.now()
        });
        
        return record;
    }
    
    async getRecords(table, options = {}, force = false) {
        const key = `${table}:${JSON.stringify(options)}`;
        
        if (!force && this.cache.has(key)) {
            const cached = this.cache.get(key);
            if (Date.now() - cached.timestamp < this.ttl) {
                return cached.data;
            }
        }
        
        const records = await this.base(table).select(options).all();
        this.cache.set(key, {
            data: records,
            timestamp: Date.now()
        });
        
        return records;
    }
    
    invalidate(table, recordId = null) {
        if (recordId) {
            this.cache.delete(`${table}:${recordId}`);
        } else {
            // Invalidate all cache entries for table
            for (const key of this.cache.keys()) {
                if (key.startsWith(`${table}:`)) {
                    this.cache.delete(key);
                }
            }
        }
    }
    
    clear() {
        this.cache.clear();
    }
}
```

### 3. Data Sync
```javascript
class AirtableSync {
    constructor(sourceBase, targetBase) {
        this.source = sourceBase;
        this.target = targetBase;
        this.mapping = new Map();
    }
    
    async syncTable(tableName, options = {}) {
        const {
            filter = null,
            transform = (r) => r,
            bidirectional = false
        } = options;
        
        // Get source records
        const sourceRecords = await this.source(tableName)
            .select({ filterByFormula: filter })
            .all();
        
        // Get target records for comparison
        const targetRecords = await this.target(tableName)
            .select()
            .all();
        
        const targetMap = new Map(
            targetRecords.map(r => [r.fields['Sync ID'], r])
        );
        
        const toCreate = [];
        const toUpdate = [];
        
        for (const sourceRecord of sourceRecords) {
            const syncId = sourceRecord.id;
            const transformed = transform(sourceRecord.fields);
            
            if (targetMap.has(syncId)) {
                // Update existing
                const targetRecord = targetMap.get(syncId);
                toUpdate.push({
                    id: targetRecord.id,
                    fields: {
                        ...transformed,
                        'Sync ID': syncId,
                        'Last Sync': new Date().toISOString()
                    }
                });
            } else {
                // Create new
                toCreate.push({
                    ...transformed,
                    'Sync ID': syncId,
                    'Last Sync': new Date().toISOString()
                });
            }
        }
        
        // Batch operations
        if (toCreate.length > 0) {
            await this.batchCreate(tableName, toCreate);
        }
        
        if (toUpdate.length > 0) {
            await this.batchUpdate(tableName, toUpdate);
        }
        
        console.log(`Synced ${toCreate.length} new, ${toUpdate.length} updated`);
        
        if (bidirectional) {
            // Sync in reverse direction
            await this.syncTableReverse(tableName, options);
        }
    }
    
    async batchCreate(table, records) {
        const batchSize = 10;
        for (let i = 0; i < records.length; i += batchSize) {
            const batch = records.slice(i, i + batchSize);
            await this.target(table).create(batch.map(r => ({ fields: r })));
        }
    }
    
    async batchUpdate(table, updates) {
        const batchSize = 10;
        for (let i = 0; i < updates.length; i += batchSize) {
            const batch = updates.slice(i, i + batchSize);
            await this.target(table).update(batch);
        }
    }
}
```

### 4. Custom Field Types
```javascript
// Handle complex field types
class AirtableFieldHandler {
    static formatAttachment(file) {
        return [{
            url: file.url,
            filename: file.name
        }];
    }
    
    static formatLinkedRecord(recordIds) {
        return Array.isArray(recordIds) ? recordIds : [recordIds];
    }
    
    static formatSelect(value, options) {
        if (!options.includes(value)) {
            throw new Error(`Invalid option: ${value}`);
        }
        return value;
    }
    
    static formatDate(date, includeTime = false) {
        const d = new Date(date);
        if (includeTime) {
            return d.toISOString();
        }
        return d.toISOString().split('T')[0];
    }
    
    static formatCurrency(amount, currency = 'USD') {
        return parseFloat(amount.toFixed(2));
    }
    
    static parseFormula(formulaResult) {
        // Handle different formula return types
        if (typeof formulaResult === 'object' && formulaResult.error) {
            return null;
        }
        return formulaResult;
    }
}
```

## Performance Optimization

### 1. Rate Limiting
```javascript
class RateLimiter {
    constructor(requestsPerSecond = 5) {
        this.requestsPerSecond = requestsPerSecond;
        this.minInterval = 1000 / requestsPerSecond;
        this.lastRequest = 0;
    }
    
    async throttle() {
        const now = Date.now();
        const timeSinceLastRequest = now - this.lastRequest;
        
        if (timeSinceLastRequest < this.minInterval) {
            await this.delay(this.minInterval - timeSinceLastRequest);
        }
        
        this.lastRequest = Date.now();
    }
    
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Usage
const limiter = new RateLimiter(5);

async function fetchRecords() {
    await limiter.throttle();
    return await base('Table').select().all();
}
```

### 2. Pagination
```javascript
async function* paginateRecords(base, table, options = {}) {
    let offset = null;
    
    do {
        const query = base(table).select({
            ...options,
            pageSize: 100,
            offset
        });
        
        const page = await query.firstPage();
        yield page;
        
        offset = query._offset;
    } while (offset);
}

// Usage
for await (const page of paginateRecords(base, 'Projects')) {
    for (const record of page) {
        console.log(record.fields.Name);
    }
}
```

## Security Best Practices

### 1. API Key Management
```javascript
// Never hardcode API keys
const config = {
    apiKey: process.env.AIRTABLE_API_KEY,
    baseId: process.env.AIRTABLE_BASE_ID
};

// Validate environment variables
if (!config.apiKey || !config.baseId) {
    throw new Error('Missing Airtable configuration');
}

// Use restricted scopes when possible
const readOnlyBase = new Airtable({
    apiKey: process.env.AIRTABLE_READONLY_KEY
}).base(config.baseId);
```

### 2. Input Validation
```javascript
function validateRecord(fields, schema) {
    const errors = [];
    
    for (const [field, rules] of Object.entries(schema)) {
        const value = fields[field];
        
        if (rules.required && !value) {
            errors.push(`${field} is required`);
        }
        
        if (rules.type === 'email' && value && !isValidEmail(value)) {
            errors.push(`${field} must be a valid email`);
        }
        
        if (rules.maxLength && value && value.length > rules.maxLength) {
            errors.push(`${field} exceeds maximum length`);
        }
        
        if (rules.options && value && !rules.options.includes(value)) {
            errors.push(`${field} must be one of: ${rules.options.join(', ')}`);
        }
    }
    
    return errors;
}
```

## Common Pitfalls to Avoid

1. **Exceeding Rate Limits**: Implement proper rate limiting (5 requests/second)
2. **Large Attachments**: Maximum 5GB per base, optimize file sizes
3. **Formula Complexity**: Complex formulas can slow down base performance
4. **Too Many Linked Records**: Limit links to prevent performance issues
5. **Not Using Views**: Use views to filter and sort data efficiently
6. **Ignoring Field Limits**: Text fields have 100,000 character limit
7. **Batch Size**: Maximum 10 records per create/update/delete request
8. **Missing Error Handling**: Always handle API errors gracefully
9. **Not Caching**: Implement caching to reduce API calls
10. **Hardcoding IDs**: Use environment variables for base and table IDs

## Useful Tools and Libraries

- **airtable.js**: Official JavaScript client
- **pyairtable**: Python client for Airtable
- **Airtable.Net**: C#/.NET client
- **airtable-ruby**: Ruby client
- **Airtable Blocks**: Custom apps within Airtable
- **Airtable Automations**: Built-in workflow automation
- **Airtable Sync**: Sync with external databases
- **Airtable API Encoder**: Formula encoding tool
- **BaseQL**: GraphQL wrapper for Airtable