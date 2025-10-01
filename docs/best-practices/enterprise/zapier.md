# Zapier Best Practices

## Official Documentation
- **Zapier**: https://zapier.com
- **Developer Platform**: https://platform.zapier.com
- **API Documentation**: https://platform.zapier.com/docs/api
- **CLI Documentation**: https://platform.zapier.com/cli_tutorials/getting-started
- **Help Center**: https://help.zapier.com
- **Community Forum**: https://community.zapier.com
- **Integration Partner Program**: https://zapier.com/app/developer

## Account Setup and Pricing

### Account Tiers
```plaintext
Free Plan:
- 100 tasks/month
- Single-step Zaps
- 15-minute update time
- Limited app connections

Starter Plan ($29.99/month):
- 750 tasks/month
- Multi-step Zaps
- 15-minute update time
- Premium app access

Professional Plan ($73.50/month):
- 2,000 tasks/month
- Unlimited Zaps
- 2-minute update time
- Webhooks, email parsing
- Custom logic with Paths
- Auto-replay for errors

Team Plan ($103.50/month):
- 2,000 tasks/month (shared)
- Unlimited users
- Premier support
- Shared workspaces
- App version control

Company Plan (Custom pricing):
- 50,000+ tasks/month
- Advanced admin permissions
- SSO (SAML)
- Dedicated account manager
- Custom data retention
- SLA guarantees
```

### Task Consumption
```plaintext
Task Counting Rules:
- Each successful action step = 1 task
- Triggers do not count as tasks
- Failed steps = 0 tasks (but retries count)
- Filters, Formatters, Paths = 0 tasks
- Search actions = 1 task
- Loop iterations = 1 task per iteration
- Storage operations = 1 task per set/get

Example Zap Task Consumption:
1. Trigger: New email in Gmail (0 tasks)
2. Filter: Only if subject contains "Invoice" (0 tasks)
3. Action: Parse email with Email Parser (1 task)
4. Formatter: Split text by comma (0 tasks)
5. Action: Create row in Google Sheets (1 task)
6. Action: Send Slack notification (1 task)
Total: 3 tasks per email processed
```

## Core Concepts

### Zaps
A Zap is an automated workflow connecting two or more apps. Each Zap consists of a trigger and one or more actions.

```plaintext
Basic Zap Structure:
┌─────────────────┐
│    Trigger      │ → Event that starts the workflow
│  (App Event)    │
└────────┬────────┘
         │
┌────────▼────────┐
│     Filter      │ → Optional condition check
│  (If/Then)      │
└────────┬────────┘
         │
┌────────▼────────┐
│    Action 1     │ → First action to perform
│  (Do This)      │
└────────┬────────┘
         │
┌────────▼────────┐
│    Action 2     │ → Additional action
│  (Then This)    │
└─────────────────┘
```

### Triggers
Events that start a Zap. Triggers are monitored by Zapier at intervals based on your plan.

```plaintext
Trigger Types:

1. Polling Triggers (Most Common):
   - Check for new data at intervals
   - Example: "New Row in Google Sheets"
   - Interval: 1-15 minutes based on plan

2. Instant Triggers (Webhooks):
   - Real-time notifications via webhook
   - Example: "New Payment in Stripe"
   - Latency: Typically < 10 seconds

3. Scheduled Triggers:
   - Time-based execution
   - Example: "Every Day at 9 AM"
   - Useful for batch processing

4. Manual Triggers:
   - User-initiated via button click
   - Example: Chrome extension trigger
   - Best for ad-hoc workflows
```

### Actions
Tasks performed when a Zap is triggered. Actions interact with apps to create, update, or search for data.

```plaintext
Action Types:

1. Create Actions:
   - Add new records
   - Example: "Create Contact in HubSpot"

2. Update Actions:
   - Modify existing records
   - Example: "Update Issue in Jira"

3. Search Actions:
   - Find existing records
   - Example: "Find User in Salesforce"
   - Can be followed by create if not found

4. Custom Actions (Code):
   - JavaScript or Python code
   - Example: "Run Python Code"
   - Maximum execution time: 10 seconds
```

### Filters
Conditional logic that determines whether a Zap continues or stops.

```plaintext
Filter Operators:
- Equals / Does not equal
- Contains / Does not contain
- Greater than / Less than
- Starts with / Ends with
- Exists / Does not exist
- Is true / Is false

Filter Logic:
- AND: All conditions must be true
- OR: At least one condition must be true
- Mixed: Combine AND/OR groups
```

### Paths
Branching logic that routes data to different actions based on conditions.

```plaintext
Path Structure:
┌──────────────┐
│   Trigger    │
└──────┬───────┘
       │
┌──────▼───────┐
│  Path Rules  │
└──┬───────┬───┘
   │       │
Path A   Path B
   │       │
   ▼       ▼
Action  Action
```

### Formatters
Built-in utilities for data transformation without consuming tasks.

```plaintext
Formatter Categories:
- Text: Split, replace, capitalize, truncate
- Numbers: Math operations, formatting
- Date/Time: Parse, format, calculate
- Utilities: Line items, pick from list
- URL: Encode/decode
```

## Building Basic Zaps

### Example 1: Gmail to Google Sheets
```plaintext
Trigger: New Email in Gmail
- Label: Invoices
- Search String: subject:"Invoice"

Filter: Only Continue If...
- Subject: Contains: "Invoice"
- From Email: Contains: "@vendor.com"

Action: Create Spreadsheet Row in Google Sheets
- Spreadsheet: Invoice Tracker
- Worksheet: 2024 Invoices
- Date: {{trigger.date}}
- From: {{trigger.from_email}}
- Subject: {{trigger.subject}}
- Amount: {{trigger.body__parsed_amount}}
```

### Example 2: Form Submission to Multiple Apps
```plaintext
Trigger: New Entry in Typeform
- Form: Contact Form

Action 1: Create Contact in HubSpot
- Email: {{trigger.email}}
- First Name: {{trigger.first_name}}
- Last Name: {{trigger.last_name}}
- Company: {{trigger.company}}
- Source: Typeform

Action 2: Create Row in Google Sheets
- Spreadsheet: Leads Database
- Email: {{trigger.email}}
- Timestamp: {{trigger.submitted_at}}
- Status: New Lead

Action 3: Send Channel Message in Slack
- Channel: #sales
- Message: New lead: {{trigger.first_name}} {{trigger.last_name}} from {{trigger.company}}
```

### Example 3: RSS Feed to Social Media
```plaintext
Trigger: New Item in Feed
- Feed URL: https://blog.example.com/feed.xml

Filter: Only Continue If...
- Title: Does not contain: "[Draft]"

Formatter: Text
- Transform: Truncate
- Input: {{trigger.description}}
- Max Length: 250

Action 1: Create Tweet in Twitter
- Message: New blog post: {{trigger.title}} {{trigger.link}}
- Include Link: Yes

Action 2: Create Page Post in Facebook
- Message: {{formatter.output}}
- Link: {{trigger.link}}
```

## Multi-Step Zaps and Conditional Logic

### Example: Advanced Lead Qualification
```plaintext
Trigger: New Row in Google Sheets
- Spreadsheet: Lead List
- Worksheet: Raw Leads

Action 1: Lookup Spreadsheet Row in Google Sheets
- Spreadsheet: Company Database
- Lookup Column: Domain
- Lookup Value: {{trigger.company_domain}}

Filter: Only Continue If...
- Company Found: (Exists)
- Employee Count: Greater than: 50
- Industry: Equals: Technology

Paths:
┌─────────────────────────────────────┐
│ Path A: High Priority (Score > 80)  │
└─────────────────────────────────────┘
  Rule: Lead Score > 80 AND Budget > 10000

  Action: Create Contact in Salesforce
  - Type: Hot Lead
  - Owner: Enterprise Sales Team

  Action: Send Email in Gmail
  - To: enterprise-sales@company.com
  - Subject: High Priority Lead: {{trigger.company}}

┌─────────────────────────────────────┐
│ Path B: Medium Priority (Score 50-80)│
└─────────────────────────────────────┘
  Rule: Lead Score >= 50 AND Lead Score <= 80

  Action: Create Contact in HubSpot
  - Lifecycle Stage: Marketing Qualified Lead

  Action: Add to Campaign in Mailchimp
  - List: Nurture Campaign

┌─────────────────────────────────────┐
│ Path C: Low Priority (Score < 50)   │
└─────────────────────────────────────┘
  Rule: Lead Score < 50

  Action: Create Row in Google Sheets
  - Spreadsheet: Low Priority Leads
  - Status: For Review
```

### Example: Multi-App Data Sync
```plaintext
Trigger: Updated Contact in Salesforce
- Object: Contact
- Fields to Watch: Email, Phone, Company

Action 1: Search User in HubSpot
- Email: {{trigger.email}}

Paths:
┌─────────────────────────────────────┐
│ Path A: User Exists in HubSpot      │
└─────────────────────────────────────┘
  Rule: Search Result (Exists)

  Action: Update Contact in HubSpot
  - Contact ID: {{path_a.search_result_id}}
  - Email: {{trigger.email}}
  - Phone: {{trigger.phone}}
  - Company: {{trigger.company}}

┌─────────────────────────────────────┐
│ Path B: User Does Not Exist         │
└─────────────────────────────────────┘
  Rule: Search Result (Does not exist)

  Action: Create Contact in HubSpot
  - Email: {{trigger.email}}
  - Phone: {{trigger.phone}}
  - Company: {{trigger.company}}
  - Source: Salesforce Sync
```

## Webhooks

### Webhooks by Zapier: Receiving Data

#### Catch Hook (Receive Webhooks)
```plaintext
Setup:
1. Create new Zap
2. Select "Webhooks by Zapier" as trigger
3. Choose "Catch Hook" event
4. Copy provided webhook URL

Webhook URL Format:
https://hooks.zapier.com/hooks/catch/12345678/abcdefg/

Example Webhook Payload:
POST https://hooks.zapier.com/hooks/catch/12345678/abcdefg/
Content-Type: application/json

{
  "event_type": "payment.success",
  "customer_id": "cust_123456",
  "amount": 99.99,
  "currency": "USD",
  "timestamp": "2024-10-02T10:30:00Z"
}

Using in Zap:
- Access data: {{trigger.event_type}}
- Amount: {{trigger.amount}}
- Customer: {{trigger.customer_id}}
```

#### Custom Webhook with Authentication
```bash
# Send authenticated webhook
curl -X POST "https://hooks.zapier.com/hooks/catch/12345678/abcdefg/" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-key" \
  -d '{
    "order_id": "ORD-12345",
    "status": "completed",
    "total": 299.99,
    "items": [
      {"sku": "PROD-001", "quantity": 2},
      {"sku": "PROD-002", "quantity": 1}
    ]
  }'

# Validate in Zap Filter:
Filter: Only Continue If...
- X-API-Key header: Equals: your-secret-key
```

### Webhooks by Zapier: Sending Data

#### POST Request
```plaintext
Action: POST in Webhooks by Zapier

URL: https://api.example.com/v1/orders

Headers:
- Authorization: Bearer {{env.API_TOKEN}}
- Content-Type: application/json
- X-Request-ID: {{trigger.id}}_{{zap_meta_human_now}}

Data (JSON):
{
  "customer": {
    "email": "{{trigger.customer_email}}",
    "name": "{{trigger.customer_name}}"
  },
  "order": {
    "id": "{{trigger.order_id}}",
    "total": {{trigger.total}},
    "currency": "USD"
  },
  "items": {{trigger.line_items}},
  "metadata": {
    "source": "zapier",
    "zap_id": "{{zap_meta_id}}",
    "timestamp": "{{zap_meta_timestamp}}"
  }
}

Data Passthrough: No
Wrap Request in Array: No
Unflatten: No
```

#### GET Request with Query Parameters
```plaintext
Action: GET in Webhooks by Zapier

URL: https://api.example.com/v1/customers

Query String Params:
- email: {{trigger.email}}
- include: orders,subscriptions
- limit: 10
- sort: created_at:desc

Headers:
- Authorization: Bearer {{env.API_TOKEN}}
- Accept: application/json

Example Full URL:
https://api.example.com/v1/customers?email=user@example.com&include=orders,subscriptions&limit=10&sort=created_at:desc
```

#### PUT/PATCH Request
```plaintext
Action: PUT in Webhooks by Zapier

URL: https://api.example.com/v1/users/{{trigger.user_id}}

Headers:
- Authorization: Bearer {{env.API_TOKEN}}
- Content-Type: application/json
- If-Match: {{trigger.etag}}

Data (JSON):
{
  "email": "{{trigger.email}}",
  "profile": {
    "first_name": "{{trigger.first_name}}",
    "last_name": "{{trigger.last_name}}",
    "phone": "{{trigger.phone}}"
  },
  "preferences": {
    "notifications": {{trigger.notifications_enabled}},
    "newsletter": {{trigger.newsletter_enabled}}
  }
}
```

## Zapier CLI for Custom Integrations

### Installation and Setup
```bash
# Install Node.js 18+ first
node --version  # Should be 18.x or higher

# Install Zapier CLI
npm install -g zapier-platform-cli

# Verify installation
zapier --version  # Should show 15.x or higher

# Login to Zapier
zapier login

# View your account details
zapier integrations

# Set up environment
export ZAPIER_API_KEY="your_api_key"
```

### Creating a Custom Integration
```bash
# Initialize new integration
zapier init my-app --template minimal

cd my-app

# Project structure:
# my-app/
# ├── index.js              # Main integration definition
# ├── package.json          # Dependencies
# ├── triggers/             # Trigger implementations
# ├── creates/              # Create action implementations
# ├── searches/             # Search action implementations
# ├── authentication.js     # Auth configuration
# └── test/                 # Test files
```

### Authentication Configuration
```javascript
// authentication.js
module.exports = {
  type: 'oauth2',
  oauth2Config: {
    authorizeUrl: {
      method: 'GET',
      url: 'https://api.example.com/oauth/authorize',
      params: {
        client_id: '{{process.env.CLIENT_ID}}',
        redirect_uri: '{{bundle.inputData.redirect_uri}}',
        response_type: 'code',
        scope: 'read write'
      }
    },
    getAccessToken: {
      method: 'POST',
      url: 'https://api.example.com/oauth/token',
      body: {
        code: '{{bundle.inputData.code}}',
        client_id: '{{process.env.CLIENT_ID}}',
        client_secret: '{{process.env.CLIENT_SECRET}}',
        redirect_uri: '{{bundle.inputData.redirect_uri}}',
        grant_type: 'authorization_code'
      },
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    },
    refreshAccessToken: {
      method: 'POST',
      url: 'https://api.example.com/oauth/token',
      body: {
        refresh_token: '{{bundle.authData.refresh_token}}',
        client_id: '{{process.env.CLIENT_ID}}',
        client_secret: '{{process.env.CLIENT_SECRET}}',
        grant_type: 'refresh_token'
      }
    },
    scope: 'read,write',
    autoRefresh: true
  },
  test: {
    url: 'https://api.example.com/v1/me',
    method: 'GET',
    headers: {
      Authorization: 'Bearer {{bundle.authData.access_token}}'
    }
  },
  connectionLabel: '{{bundle.inputData.email}}'
};

// Alternative: API Key Authentication
module.exports = {
  type: 'custom',
  fields: [
    {
      key: 'apiKey',
      label: 'API Key',
      required: true,
      type: 'string',
      helpText: 'Find your API key at https://example.com/settings/api'
    }
  ],
  test: {
    url: 'https://api.example.com/v1/me',
    method: 'GET',
    headers: {
      'X-API-Key': '{{bundle.authData.apiKey}}'
    }
  },
  connectionLabel: '{{bundle.inputData.email}}'
};
```

### Implementing Triggers
```javascript
// triggers/new_order.js
const performList = async (z, bundle) => {
  const response = await z.request({
    url: 'https://api.example.com/v1/orders',
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${bundle.authData.access_token}`,
      'Accept': 'application/json'
    },
    params: {
      sort: 'created_at:desc',
      limit: 100,
      created_after: bundle.meta.page ? bundle.meta.page : undefined
    }
  });

  // Return array of orders
  return response.data;
};

// Subscribe to webhook (instant trigger)
const performSubscribe = async (z, bundle) => {
  const response = await z.request({
    url: 'https://api.example.com/v1/webhooks',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${bundle.authData.access_token}`,
      'Content-Type': 'application/json'
    },
    body: {
      target_url: bundle.targetUrl,
      event: 'order.created'
    }
  });

  return response.data;
};

// Unsubscribe from webhook
const performUnsubscribe = async (z, bundle) => {
  const response = await z.request({
    url: `https://api.example.com/v1/webhooks/${bundle.subscribeData.id}`,
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${bundle.authData.access_token}`
    }
  });

  return response.data;
};

// Handle incoming webhook
const perform = async (z, bundle) => {
  // bundle.cleanedRequest contains the parsed webhook payload
  return [bundle.cleanedRequest];
};

module.exports = {
  key: 'new_order',
  noun: 'Order',
  display: {
    label: 'New Order',
    description: 'Triggers when a new order is created.',
    important: true
  },
  operation: {
    type: 'hook',
    perform: perform,
    performList: performList,
    performSubscribe: performSubscribe,
    performUnsubscribe: performUnsubscribe,

    // Input fields for trigger configuration
    inputFields: [
      {
        key: 'status',
        label: 'Order Status',
        type: 'string',
        choices: ['pending', 'processing', 'completed', 'cancelled'],
        required: false,
        helpText: 'Filter orders by status'
      }
    ],

    // Sample data for testing
    sample: {
      id: 'ord_123456',
      customer_id: 'cust_789',
      status: 'completed',
      total: 299.99,
      currency: 'USD',
      created_at: '2024-10-02T10:30:00Z'
    },

    // Output fields definition
    outputFields: [
      { key: 'id', label: 'Order ID', type: 'string' },
      { key: 'customer_id', label: 'Customer ID', type: 'string' },
      { key: 'status', label: 'Status', type: 'string' },
      { key: 'total', label: 'Total', type: 'number' },
      { key: 'currency', label: 'Currency', type: 'string' },
      { key: 'created_at', label: 'Created At', type: 'datetime' }
    ]
  }
};
```

### Implementing Create Actions
```javascript
// creates/create_customer.js
const perform = async (z, bundle) => {
  const response = await z.request({
    url: 'https://api.example.com/v1/customers',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${bundle.authData.access_token}`,
      'Content-Type': 'application/json'
    },
    body: {
      email: bundle.inputData.email,
      first_name: bundle.inputData.first_name,
      last_name: bundle.inputData.last_name,
      phone: bundle.inputData.phone,
      company: bundle.inputData.company,
      tags: bundle.inputData.tags ? bundle.inputData.tags.split(',') : []
    }
  });

  return response.data;
};

module.exports = {
  key: 'create_customer',
  noun: 'Customer',
  display: {
    label: 'Create Customer',
    description: 'Creates a new customer in your account.',
    important: true
  },
  operation: {
    perform: perform,

    inputFields: [
      {
        key: 'email',
        label: 'Email',
        type: 'string',
        required: true,
        helpText: 'The customer\'s email address'
      },
      {
        key: 'first_name',
        label: 'First Name',
        type: 'string',
        required: true
      },
      {
        key: 'last_name',
        label: 'Last Name',
        type: 'string',
        required: true
      },
      {
        key: 'phone',
        label: 'Phone',
        type: 'string',
        required: false,
        helpText: 'Phone number in E.164 format (e.g., +14155552671)'
      },
      {
        key: 'company',
        label: 'Company',
        type: 'string',
        required: false
      },
      {
        key: 'tags',
        label: 'Tags',
        type: 'string',
        required: false,
        helpText: 'Comma-separated list of tags'
      }
    ],

    sample: {
      id: 'cust_123456',
      email: 'john.doe@example.com',
      first_name: 'John',
      last_name: 'Doe',
      phone: '+14155552671',
      company: 'Acme Corp',
      tags: ['vip', 'enterprise'],
      created_at: '2024-10-02T10:30:00Z'
    },

    outputFields: [
      { key: 'id', label: 'Customer ID' },
      { key: 'email', label: 'Email' },
      { key: 'first_name', label: 'First Name' },
      { key: 'last_name', label: 'Last Name' },
      { key: 'created_at', label: 'Created At' }
    ]
  }
};
```

### Implementing Search Actions
```javascript
// searches/find_customer.js
const perform = async (z, bundle) => {
  const response = await z.request({
    url: 'https://api.example.com/v1/customers',
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${bundle.authData.access_token}`
    },
    params: {
      email: bundle.inputData.email,
      limit: 1
    }
  });

  // Return array of results (even if only one)
  return response.data;
};

module.exports = {
  key: 'find_customer',
  noun: 'Customer',
  display: {
    label: 'Find Customer',
    description: 'Finds an existing customer by email.',
    important: true
  },
  operation: {
    perform: perform,

    inputFields: [
      {
        key: 'email',
        label: 'Email',
        type: 'string',
        required: true,
        helpText: 'Email address of the customer to find'
      }
    ],

    sample: {
      id: 'cust_123456',
      email: 'john.doe@example.com',
      first_name: 'John',
      last_name: 'Doe'
    },

    outputFields: [
      { key: 'id', label: 'Customer ID' },
      { key: 'email', label: 'Email' },
      { key: 'first_name', label: 'First Name' },
      { key: 'last_name', label: 'Last Name' }
    ]
  }
};
```

### Testing and Deployment
```bash
# Run tests
npm test

# Test specific function
zapier test --debug

# Validate integration
zapier validate

# Push to Zapier (creates new version)
zapier push

# Promote version to production
zapier promote 1.0.1

# Migrate users to new version
zapier migrate 1.0.0 1.0.1 --percent 10

# Monitor integration
zapier logs --type http --detailed

# View integration usage
zapier integrations
```

## Error Handling and Retry Logic

### Built-in Error Handling
```plaintext
Automatic Retries:
- Zapier automatically retries failed tasks
- Retry schedule: 1m, 5m, 15m, 1h, 4h, 8h, 24h
- Maximum 13 retries over ~48 hours
- Only for Professional plans and above

Error Types:
1. Temporary Errors (Retry):
   - Network timeouts
   - 429 Rate limit errors
   - 500, 502, 503, 504 Server errors

2. Permanent Errors (Stop):
   - 400 Bad Request
   - 401 Unauthorized
   - 403 Forbidden
   - 404 Not Found
   - Invalid data format

3. Throttled Actions:
   - Rate limit exceeded
   - Pauses Zap temporarily
   - Auto-resumes when rate limit resets
```

### Custom Error Handling in CLI
```javascript
// Throw appropriate errors in your integration
const perform = async (z, bundle) => {
  try {
    const response = await z.request({
      url: 'https://api.example.com/v1/orders',
      method: 'POST',
      body: bundle.inputData
    });

    return response.data;

  } catch (error) {
    // Check error status code
    if (error.status === 429) {
      // Rate limit - throw error to trigger retry
      throw new z.errors.ThrottledError(
        'Rate limit exceeded. Zapier will retry this request.',
        3600 // Retry after 3600 seconds (1 hour)
      );
    }

    if (error.status === 401) {
      // Authentication error - don't retry
      throw new z.errors.RefreshAuthError(
        'Authentication failed. Please reconnect your account.'
      );
    }

    if (error.status >= 500) {
      // Server error - allow retry
      throw new z.errors.Error(
        `Server error: ${error.message}`,
        'ServerError',
        error.status
      );
    }

    if (error.status === 400) {
      // Bad request - don't retry, show helpful message
      const errorDetails = error.json ? JSON.stringify(error.json) : error.message;
      throw new z.errors.Error(
        `Invalid data: ${errorDetails}`,
        'BadRequest',
        400
      );
    }

    // Generic error
    throw new z.errors.Error(error.message);
  }
};

// Middleware for error handling
const handleHTTPError = (response, z, bundle) => {
  if (response.status >= 400) {
    throw new z.errors.Error(
      `API Error: ${response.status} - ${response.content}`,
      'APIError',
      response.status
    );
  }
  return response;
};

// Add middleware to app
const App = {
  version: require('./package.json').version,
  platformVersion: require('zapier-platform-core').version,

  afterResponse: [handleHTTPError],

  // ... rest of app definition
};
```

### Error Notifications
```plaintext
Configure Error Alerts:
1. Go to Zap History
2. Click "Set up Zap error alerts"
3. Choose notification method:
   - Email (default)
   - Slack channel
   - Custom webhook

Error Alert Settings:
- Frequency: Immediate, Daily digest, Weekly digest
- Threshold: Alert after X consecutive errors
- Include: Error details, affected Zaps
```

## Data Formatting and Transformation

### Text Formatters
```plaintext
Split Text:
Input: "John,Doe,john@example.com"
Separator: ,
Segment Index: 1 (first name)
Output: "John"

Replace:
Input: "Order #12345 has been shipped"
Find: "Order #"
Replace: "ORD-"
Output: "ORD-12345 has been shipped"

Capitalize:
Input: "john doe"
To: Title Case
Output: "John Doe"

Truncate:
Input: "This is a very long description that needs to be shortened"
Max Length: 50
Append Ellipsis: Yes
Output: "This is a very long description that needs to..."

Extract Pattern:
Input: "Invoice #INV-2024-001 for $299.99"
Pattern: \$([0-9.]+)
Output: "299.99"

Extract Email:
Input: "Contact us at support@example.com for help"
Output: "support@example.com"

Extract URL:
Input: "Visit https://example.com for more info"
Output: "https://example.com"
```

### Number Formatters
```plaintext
Math Operations:
Input 1: 299.99
Operation: Multiply
Input 2: 1.08
Output: 323.99 (with tax)

Format Number:
Input: 1234567.89
Format: Currency
Decimals: 2
Output: "$1,234,567.89"

Random Number:
Min: 100000
Max: 999999
Output: 742891 (random order number)
```

### Date/Time Formatters
```plaintext
Format Date:
Input: 2024-10-02T10:30:00Z
From Format: ISO 8601
To Format: MM/DD/YYYY hh:mm A
Timezone: America/New_York
Output: 10/02/2024 06:30 AM

Add/Subtract Time:
Input: 2024-10-02T10:30:00Z
Expression: +7 days
Output: 2024-10-09T10:30:00Z

Compare Dates:
Date 1: 2024-10-02
Date 2: 2024-10-09
Unit: Days
Output: 7

Default to Current Date:
Input: {{trigger.due_date}} (empty)
Default Value: now
Output: 2024-10-02T10:30:00Z
```

### Utilities
```plaintext
Line Items:
Input: [
  {"name": "Product A", "price": 99.99, "qty": 2},
  {"name": "Product B", "price": 49.99, "qty": 1}
]
Output:
- Line Item 1 Name: Product A
- Line Item 1 Price: 99.99
- Line Item 1 Qty: 2
- Line Item 2 Name: Product B
- Line Item 2 Price: 49.99
- Line Item 2 Qty: 1

Pick from List:
Input: Red, Blue, Green, Yellow
Pick: random
Output: Blue

Spreadsheet-Style Formula:
Input: {{trigger.subtotal}}
Formula: {{input}} * 1.08
Output: Subtotal with 8% tax
```

## Filters and Conditional Workflows

### Filter Rules
```plaintext
Example 1: Email Filter
Only Continue If...
Rule 1 (AND):
- From Email: Contains: "@company.com"
- Subject: Contains: "Order"
Rule 2 (OR):
- Subject: Contains: "Invoice"

Example 2: Number Range Filter
Only Continue If...
- Order Total: Greater than or equal to: 100
- Order Total: Less than: 1000
- Status: Equals: "completed"

Example 3: Date Filter
Only Continue If...
- Created Date: Is after: 2024-01-01
- Created Date: Is before: now

Example 4: List Membership
Only Continue If...
- Country: Is in: US,CA,GB,AU
- Product Category: Is not in: Draft,Archived

Example 5: Field Existence
Only Continue If...
- Email: (Exists)
- Phone: (Exists)
- Company: Does not exist
```

### Advanced Filters with Formatters
```plaintext
Scenario: Process only business hours

Step 1: Formatter by Zapier - Date/Time
- Transform: Format
- Input: {{trigger.created_at}}
- To Format: HH (24-hour)
- Output: 14 (2 PM)

Step 2: Filter by Zapier
Only Continue If...
- Hour: Greater than or equal to: 9
- Hour: Less than: 17

Step 3: Formatter by Zapier - Date/Time
- Transform: Format
- Input: {{trigger.created_at}}
- To Format: ddd (day name)
- Output: Mon

Step 4: Filter by Zapier
Only Continue If...
- Day: Is not in: Sat,Sun
```

## Paths (Branching Logic)

### Example 1: Lead Routing by Company Size
```plaintext
Paths Configuration:

Path A: Enterprise (500+ employees)
Rules:
- Employee Count: Greater than or equal to: 500
OR
- Annual Revenue: Greater than: 10000000

Actions:
1. Create Lead in Salesforce
   - Type: Enterprise
   - Owner: Enterprise Sales Team

2. Send Email in Gmail
   - To: enterprise@company.com
   - Subject: New Enterprise Lead: {{trigger.company}}
   - Body: Lead details...

Path B: Mid-Market (50-499 employees)
Rules:
- Employee Count: Greater than or equal to: 50
- Employee Count: Less than: 500

Actions:
1. Create Contact in HubSpot
   - Lifecycle Stage: Sales Qualified Lead
   - Owner: Mid-Market Team

2. Create Task in Asana
   - Project: Mid-Market Pipeline
   - Assignee: Sales Manager

Path C: SMB (1-49 employees)
Rules:
- Employee Count: Less than: 50

Actions:
1. Add Subscriber to Mailchimp
   - List: SMB Nurture
   - Tags: Small Business, Needs Demo

2. Create Row in Google Sheets
   - Spreadsheet: SMB Leads
   - Status: Nurture
```

### Example 2: Support Ticket Priority Routing
```plaintext
Paths Configuration:

Path A: Critical Priority
Rules:
- Priority: Equals: Critical
OR
- Subject: Contains: "Down"
OR
- Subject: Contains: "Urgent"

Actions:
1. Create Incident in PagerDuty
   - Severity: High
   - Escalation Policy: On-Call Team

2. Send Channel Message in Slack
   - Channel: #critical-alerts
   - Message: @channel Critical ticket: {{trigger.subject}}

3. Create Issue in Jira
   - Project: Support
   - Issue Type: Incident
   - Priority: Highest

Path B: High Priority
Rules:
- Priority: Equals: High
- SLA: Less than: 4 hours remaining

Actions:
1. Create Issue in Jira
   - Priority: High
   - Assignee: Next Available

2. Send Channel Message in Slack
   - Channel: #support-team
   - Message: High priority ticket needs attention

Path C: Normal Priority
Rules:
- Priority: Equals: Medium
OR
- Priority: Equals: Low

Actions:
1. Create Ticket in Zendesk
   - Priority: Normal
   - Group: General Support

2. Update Spreadsheet Row
   - Status: In Queue
```

### Example 3: Multi-Region Processing
```plaintext
Paths Configuration:

Path A: North America
Rules:
- Country: Is in: US,CA,MX

Actions:
1. Create Contact in Salesforce
   - Owner: NA Sales Team
   - Region: North America

2. Send from Gmail
   - From: na-sales@company.com
   - Template: NA Welcome

Path B: Europe
Rules:
- Country: Is in: GB,FR,DE,IT,ES,NL,SE,NO,DK

Actions:
1. Create Contact in Salesforce
   - Owner: EU Sales Team
   - Region: Europe

2. Send from Gmail
   - From: eu-sales@company.com
   - Template: EU Welcome (GDPR compliant)

Path C: Asia Pacific
Rules:
- Country: Is in: AU,NZ,SG,JP,CN,IN

Actions:
1. Create Contact in Salesforce
   - Owner: APAC Sales Team
   - Region: Asia Pacific

2. Send from Gmail
   - From: apac-sales@company.com
   - Template: APAC Welcome
```

## Storage and Looping

### Storage by Zapier
```plaintext
Storage allows you to save and retrieve data between Zap runs.

Use Case: Counter
Step 1: Get Value from Storage
- Key: order_counter
- Default Value: 0

Step 2: Formatter - Number
- Operation: Add
- Input 1: {{storage.value}}
- Input 2: 1
- Output: New counter value

Step 3: Set Value in Storage
- Key: order_counter
- Value: {{formatter.output}}

Step 4: Use Counter
- Order Number: ORD-{{formatter.output}}

---

Use Case: Last Run Timestamp
Step 1: Get Value from Storage
- Key: last_sync_timestamp
- Default Value: 2024-01-01T00:00:00Z

Step 2: Search Records API Call
- URL: https://api.example.com/records
- Params: updated_after={{storage.value}}

Step 3: Set Value in Storage
- Key: last_sync_timestamp
- Value: {{zap_meta_timestamp}}

---

Use Case: Temporary Cache
Step 1: Get Value from Storage
- Key: customer_{{trigger.customer_id}}
- Default Value: (empty)

Step 2: Path A: Cache Hit
- Rule: Storage Value (Exists)
- Action: Use cached data

Step 3: Path B: Cache Miss
- Rule: Storage Value (Does not exist)
- Action: Fetch from API
- Set Storage: customer_{{trigger.customer_id}} = {{api.response}}

Storage Limits:
- Free/Starter: Not available
- Professional: 500 MB
- Team: 2 GB
- Company: 10 GB
- Key length: Max 256 characters
- Value size: Max 3 MB per key
- Expiration: Optional (default: permanent)
```

### Looping by Zapier
```plaintext
Loop over line items or arrays to perform actions for each item.

Example 1: Process Order Line Items
Step 1: Create Loop from Line Items
- Source: {{trigger.line_items}}

Step 2: Actions inside loop (runs for each item):

   Action 1: Update Inventory (runs per item)
   - Product ID: {{loop.sku}}
   - Quantity: -{{loop.quantity}}

   Action 2: Create Activity Log
   - Type: Sale
   - Product: {{loop.name}}
   - Quantity Sold: {{loop.quantity}}

---

Example 2: Batch Email Sending
Step 1: Lookup Spreadsheet Rows
- Returns: Multiple rows

Step 2: Create Loop from Line Items
- Source: {{spreadsheet.rows}}

Step 3: Send Email in Gmail (runs per row)
   - To: {{loop.email}}
   - Subject: Hello {{loop.first_name}}
   - Body: Personalized message...

---

Example 3: Multi-App Data Sync
Step 1: Search Contacts in HubSpot
- Returns: Array of contacts

Step 2: Create Loop from Line Items
- Source: {{hubspot.contacts}}

Step 3: Actions per contact:

   Action 1: Search User in Salesforce
   - Email: {{loop.email}}

   Action 2: Path A - Create if not found
   - Create Contact in Salesforce
   - Data from: {{loop}}

   Action 3: Path B - Update if found
   - Update Contact in Salesforce
   - ID: {{salesforce.id}}
   - Data from: {{loop}}

Loop Limits:
- Max iterations per run: 500
- Task consumption: 1 task per iteration
- Nested loops: Not supported
- Failed iterations: Continue or stop
```

## API Integration Patterns

### REST API Integration
```plaintext
Pattern 1: CRUD Operations

Create (POST):
Action: POST in Webhooks by Zapier
URL: https://api.example.com/v1/resources
Headers:
- Authorization: Bearer {{env.API_TOKEN}}
- Content-Type: application/json
Body:
{
  "name": "{{trigger.name}}",
  "type": "{{trigger.type}}",
  "data": {{trigger.data}}
}

Read (GET):
Action: GET in Webhooks by Zapier
URL: https://api.example.com/v1/resources/{{trigger.resource_id}}
Headers:
- Authorization: Bearer {{env.API_TOKEN}}

Update (PUT/PATCH):
Action: PUT in Webhooks by Zapier
URL: https://api.example.com/v1/resources/{{trigger.resource_id}}
Headers:
- Authorization: Bearer {{env.API_TOKEN}}
- Content-Type: application/json
Body:
{
  "status": "{{trigger.new_status}}",
  "updated_at": "{{zap_meta_timestamp}}"
}

Delete (DELETE):
Action: Custom Request in Webhooks by Zapier
URL: https://api.example.com/v1/resources/{{trigger.resource_id}}
Method: DELETE
Headers:
- Authorization: Bearer {{env.API_TOKEN}}
```

### Pagination Handling
```plaintext
Pattern: Fetch All Pages

Step 1: Get Value from Storage (page counter)
- Key: api_page
- Default: 1

Step 2: GET Request
URL: https://api.example.com/v1/resources
Params:
- page: {{storage.value}}
- per_page: 100

Step 3: Code by Zapier (Python)
```python
import json

response = json.loads(input_data['response'])
items = response.get('data', [])
has_more = response.get('has_more', False)
current_page = int(input_data['current_page'])

output = {
    'items': items,
    'has_more': has_more,
    'next_page': current_page + 1 if has_more else current_page
}
```

Step 4: Set Value in Storage
- Key: api_page
- Value: {{code.next_page}}

Step 5: Looping
- Loop over: {{code.items}}

Step 6: Process each item...
```

### Rate Limit Handling
```plaintext
Pattern: Respect Rate Limits

Headers to Check:
- X-RateLimit-Limit: 1000
- X-RateLimit-Remaining: 50
- X-RateLimit-Reset: 1696252800

Implementation in CLI:
```javascript
const perform = async (z, bundle) => {
  const response = await z.request({
    url: 'https://api.example.com/v1/resources',
    method: 'GET'
  });

  // Check rate limit headers
  const remaining = response.headers.get('x-ratelimit-remaining');
  const reset = response.headers.get('x-ratelimit-reset');

  if (remaining && parseInt(remaining) < 10) {
    const resetTime = new Date(parseInt(reset) * 1000);
    const now = new Date();
    const waitSeconds = Math.ceil((resetTime - now) / 1000);

    throw new z.errors.ThrottledError(
      `Rate limit nearly exceeded. Waiting until ${resetTime.toISOString()}`,
      waitSeconds
    );
  }

  return response.data;
};
```

Built-in Zapier Handling:
- Delay After Queue: Add delay between actions
- Settings > Advanced > Add delay
- Delay: 1-60 seconds between actions
```

### Authentication Patterns
```plaintext
Bearer Token:
Headers:
- Authorization: Bearer {{env.API_TOKEN}}

API Key (Header):
Headers:
- X-API-Key: {{env.API_KEY}}

API Key (Query Parameter):
URL: https://api.example.com/v1/resources?api_key={{env.API_KEY}}

Basic Auth:
Headers:
- Authorization: Basic {{base64(username:password)}}

OAuth 2.0:
Handled automatically by Zapier OAuth2 integration

Custom Auth Token Refresh:
Step 1: Check if token expired
Step 2: POST to refresh endpoint
Step 3: Store new token in Storage
Step 4: Use token in API request
```

## Testing and Debugging Zaps

### Testing Workflow
```plaintext
1. Test Trigger:
   - "Test trigger" finds recent data
   - Verify correct data is retrieved
   - Check all required fields are present

2. Test Actions:
   - Use "Test action" for each step
   - Verify API calls succeed
   - Check data mappings are correct

3. Test Filters:
   - Use test data that should pass
   - Use test data that should fail
   - Verify filter logic works correctly

4. Test Paths:
   - Send test data for each path
   - Verify correct path is taken
   - Check all paths have been tested

5. Full End-to-End Test:
   - Turn on Zap
   - Trigger real event
   - Monitor Zap History
   - Verify all steps execute correctly
```

### Debugging Tools
```plaintext
Zap History:
- View all Zap runs (last 7-30 days depending on plan)
- Filter by status: Success, Error, Filtered, Halted
- Search by trigger data
- View detailed logs for each step
- Replay failed Zaps

Detailed Logs:
- Request URL and method
- Request headers and body
- Response status and headers
- Response body
- Execution time
- Error messages

Common Issues:

1. Missing Data:
   Problem: Field shows as blank
   Debug: Check trigger test data
   Solution: Verify field exists in source app

2. Authentication Errors:
   Problem: 401 Unauthorized
   Debug: Check connection status
   Solution: Reconnect account

3. Rate Limits:
   Problem: 429 Too Many Requests
   Debug: Check API usage
   Solution: Add delays, reduce frequency

4. Data Format Errors:
   Problem: 400 Bad Request
   Debug: Check API requirements
   Solution: Add formatter to transform data

5. Timeout Errors:
   Problem: Request timeout
   Debug: Check API response time
   Solution: Increase timeout in webhook settings
```

### Code by Zapier Debugging
```javascript
// JavaScript
// Available variables: inputData, fetch, z

// Log values for debugging
console.log('Input data:', inputData);

try {
  // Your code here
  const result = {
    output: 'success',
    data: inputData.someField
  };

  console.log('Result:', result);
  return result;

} catch (error) {
  console.error('Error occurred:', error.message);
  throw new Error(`Processing failed: ${error.message}`);
}

// Python
# Available variables: input_data

import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    # Log input for debugging
    logger.info(f"Input data: {input_data}")

    # Your code here
    result = {
        'output': 'success',
        'data': input_data.get('some_field')
    }

    logger.info(f"Result: {result}")
    return result

except Exception as e:
    logger.error(f"Error occurred: {str(e)}")
    raise Exception(f"Processing failed: {str(e)}")
```

### CLI Integration Testing
```bash
# Test authentication
zapier test --debug

# Test specific trigger
zapier test --trigger new_order --debug

# Test with sample data
echo '{"email": "test@example.com"}' | zapier test --action create_customer

# View logs
zapier logs --type http --detailed --limit 50

# Test locally with environment variables
export API_KEY="test_key"
zapier test --debug

# Integration testing script
cat > test-integration.js << 'EOF'
const zapier = require('zapier-platform-core');
const App = require('./index');
const appTester = zapier.createAppTester(App);

describe('Integration Tests', () => {
  it('should create customer', async () => {
    const bundle = {
      authData: {
        api_key: process.env.API_KEY
      },
      inputData: {
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User'
      }
    };

    const result = await appTester(
      App.creates.create_customer.operation.perform,
      bundle
    );

    expect(result).toBeDefined();
    expect(result.email).toBe('test@example.com');
  });
});
EOF

npm test
```

## Performance Optimization

### Task Consumption Optimization
```plaintext
Strategy 1: Use Filters Early
Bad:
- Trigger (all records)
- Action 1: Lookup data (1 task)
- Action 2: Create record (1 task)
- Filter: Check condition
- Action 3: Send notification (1 task)
Result: 3 tasks even if filtered out

Good:
- Trigger (all records)
- Filter: Check condition immediately
- Action 1: Lookup data (1 task)
- Action 2: Create record (1 task)
- Action 3: Send notification (1 task)
Result: 0 tasks if filtered, 3 tasks if passed

---

Strategy 2: Combine Multiple Actions
Bad:
- Action 1: Get customer (1 task)
- Action 2: Get orders (1 task)
- Action 3: Get preferences (1 task)
Result: 3 tasks

Good:
- Action: Single API call to get all data (1 task)
  GET /api/customers/{{id}}?include=orders,preferences
Result: 1 task

---

Strategy 3: Batch Processing
Bad:
- Trigger: New row (runs 100 times/day)
- Action: Process row (1 task × 100)
Result: 100 tasks

Good:
- Trigger: Schedule (runs 1 time/day)
- Action: Get all new rows
- Loop: Process each row (1 task × 100)
Result: 100 tasks but fewer API calls

---

Strategy 4: Use Storage Instead of Searches
Bad (runs every time):
- Action 1: Search for customer (1 task)
- Action 2: Create/Update customer (1 task)
Result: 2 tasks per run

Good (cached):
- Action 1: Get from Storage (0 tasks)
- Filter: If found in storage, skip search
- Action 2: Search only if not cached (1 task)
- Action 3: Update Storage with result (0 tasks)
- Action 4: Create/Update customer (1 task)
Result: 1 task if cached, 2 tasks if not

---

Strategy 5: Reduce Trigger Frequency
Bad:
- Trigger: Every 5 minutes (288 times/day)
- Average 10 events/day
- Waste: 278 empty checks

Good:
- Trigger: Every 15 minutes (96 times/day)
- Or use Webhooks (instant, no polling)
- Reduce overhead and faster processing
```

### Webhook Optimization
```plaintext
Use Instant Triggers:
✓ Real-time processing (< 10 seconds)
✓ No polling overhead
✓ More reliable for time-sensitive workflows

Supported Apps with Instant Triggers:
- Stripe (webhooks)
- GitHub (webhooks)
- Shopify (webhooks)
- Mailchimp (webhooks)
- Typeform (webhooks)
- Many more...

Configure Webhooks:
1. Use app's built-in webhook trigger
2. Or use "Webhooks by Zapier" - Catch Hook
3. Configure source app to send webhooks
4. Test webhook delivery
```

### Zap Organization
```plaintext
Best Practices:
1. One Zap per workflow
   - Don't create mega-Zaps
   - Split complex logic into multiple Zaps

2. Use clear naming:
   - Bad: "My Zap 1"
   - Good: "Gmail Invoice → Sheets + Slack"

3. Use folders to organize:
   - Sales Automation
   - Marketing Campaigns
   - Customer Support
   - Data Sync

4. Document your Zaps:
   - Add descriptions
   - Document custom code
   - Note dependencies

5. Version control for CLI integrations:
   - Use semantic versioning
   - Document breaking changes
   - Test before promoting
```

## Security Best Practices

### API Key Management
```plaintext
1. Never Hardcode Keys in Zaps:
   Bad:
   - API Key: "sk_live_abc123xyz456"

   Good:
   - Use app authentication
   - Use environment variables in CLI

2. Use Environment Variables (CLI):
```bash
# .env file (never commit to git)
API_KEY=sk_live_abc123xyz456
CLIENT_SECRET=super_secret_value
WEBHOOK_SECRET=webhook_signing_secret

# .zapierapprc file
{
  "deployments": {
    "production": {
      "environment": {
        "API_KEY": "{{process.env.API_KEY}}"
      }
    }
  }
}
```

3. Rotate Keys Regularly:
   - Set expiration dates
   - Rotate every 90 days
   - Update in Zapier connections

4. Use Least Privilege:
   - Request minimum required scopes
   - Example: Read-only vs Read-Write
   - Audit permissions regularly
```

### Data Security
```plaintext
1. Sensitive Data Handling:
   - Never log sensitive data (SSN, credit cards, passwords)
   - Use PCI-compliant services for payment data
   - Comply with GDPR, CCPA regulations

2. Data Retention:
   - Zap History retention: 7-30 days
   - Configure auto-delete for sensitive data
   - Company plan: Custom retention policies

3. Encryption:
   - All data encrypted in transit (TLS 1.2+)
   - Data encrypted at rest
   - Credentials stored in encrypted vault

4. Access Control:
   - Team plan: Role-based access
   - Admin, Member, Guest roles
   - Audit logs for team actions
   - SSO/SAML for Company plan
```

### Webhook Security
```plaintext
1. Verify Webhook Sources:
```javascript
// Validate webhook signature in Code step
const crypto = require('crypto');

const validateWebhook = (payload, signature, secret) => {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(payload));
  const calculatedSignature = hmac.digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(calculatedSignature)
  );
};

// In Zap:
const isValid = validateWebhook(
  inputData.payload,
  inputData.headers['X-Signature'],
  inputData.webhook_secret
);

if (!isValid) {
  throw new Error('Invalid webhook signature');
}

return { verified: true, payload: inputData.payload };
```

2. Use HTTPS Only:
   - Zapier webhook URLs are HTTPS by default
   - Never expose webhook URLs publicly

3. Implement IP Allowlisting:
   - Get Zapier IP ranges
   - Configure firewall rules
   - Document: https://help.zapier.com/hc/en-us/articles/8496181725453

4. Add Authentication Headers:
```plaintext
Filter Step:
Only Continue If...
- X-API-Key header: Equals: {{env.SECRET_KEY}}
```
```

### CLI Security
```bash
# .gitignore file (always include)
.env
.env.local
.zapierapprc
build/
node_modules/
*.log

# Never commit sensitive data
# Use environment variables

# Secure your integration
zapier env:set API_KEY sk_live_abc123xyz456
zapier env:set CLIENT_SECRET super_secret_value

# View environment variables (values hidden)
zapier env:list

# Audit dependencies
npm audit
npm audit fix

# Use security scanning
npm install -g snyk
snyk test
```

## CI/CD for Custom Integrations

### GitHub Actions Workflow
```yaml
# .github/workflows/zapier-deploy.yml
name: Zapier Integration CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  NODE_VERSION: '18'

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Run linter
      run: npm run lint

    - name: Run tests
      run: npm test
      env:
        API_KEY: ${{ secrets.TEST_API_KEY }}
        CLIENT_SECRET: ${{ secrets.TEST_CLIENT_SECRET }}

    - name: Run integration tests
      run: npm run test:integration
      env:
        API_KEY: ${{ secrets.TEST_API_KEY }}

    - name: Security audit
      run: npm audit --audit-level=moderate

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'

    steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}

    - name: Install dependencies
      run: npm ci

    - name: Install Zapier CLI
      run: npm install -g zapier-platform-cli

    - name: Login to Zapier
      run: echo "${{ secrets.ZAPIER_DEPLOY_KEY }}" | zapier login --sso

    - name: Deploy to staging
      run: |
        zapier push --version=staging-${{ github.sha }}
        echo "Deployed staging-${{ github.sha }}"

  deploy-production:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}

    - name: Install dependencies
      run: npm ci

    - name: Install Zapier CLI
      run: npm install -g zapier-platform-cli

    - name: Login to Zapier
      run: echo "${{ secrets.ZAPIER_DEPLOY_KEY }}" | zapier login --sso

    - name: Get version from package.json
      id: package-version
      run: echo "VERSION=$(node -p "require('./package.json').version")" >> $GITHUB_OUTPUT

    - name: Push to Zapier
      run: zapier push

    - name: Promote to production
      run: zapier promote ${{ steps.package-version.outputs.VERSION }}

    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: v${{ steps.package-version.outputs.VERSION }}
        release_name: Release v${{ steps.package-version.outputs.VERSION }}
        body: |
          Zapier Integration Release ${{ steps.package-version.outputs.VERSION }}

          Deployed to production.
        draft: false
        prerelease: false

    - name: Notify Slack
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: 'Zapier integration v${{ steps.package-version.outputs.VERSION }} deployed to production'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
      if: always()
```

### Deployment Script
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

# Configuration
VERSION=$(node -p "require('./package.json').version")
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Deploying Zapier Integration v${VERSION} from branch ${BRANCH}"

# Run tests
echo "Running tests..."
npm test

# Run integration tests
echo "Running integration tests..."
npm run test:integration

# Validate integration
echo "Validating integration..."
zapier validate

# Push to Zapier
echo "Pushing to Zapier..."
zapier push

# Promote if on main branch
if [ "$BRANCH" = "main" ]; then
  echo "Promoting v${VERSION} to production..."
  zapier promote ${VERSION}

  # Create git tag
  git tag -a "v${VERSION}" -m "Release v${VERSION}"
  git push origin "v${VERSION}"

  echo "Deployment complete! Integration v${VERSION} is now live."
else
  echo "Pushed v${VERSION} to staging. Promote manually when ready."
fi
```

### Gradual Rollout Strategy
```bash
# Deploy new version
zapier push

# Promote to 10% of users
zapier migrate 1.0.0 1.0.1 --percent 10

# Monitor for 24 hours, check error rates

# Promote to 50%
zapier migrate 1.0.0 1.0.1 --percent 50

# Monitor for another 24 hours

# Promote to 100%
zapier migrate 1.0.0 1.0.1 --percent 100

# Or promote all at once if confident
zapier promote 1.0.1
```

## Monitoring and Logging

### Monitoring Zap Health
```plaintext
Built-in Monitoring:
1. Zap History Dashboard:
   - Success rate (last 7/30 days)
   - Error trends
   - Task consumption
   - Performance metrics

2. Error Alerts:
   - Configure email/Slack alerts
   - Set error thresholds
   - Immediate vs digest notifications

3. Task Usage Dashboard:
   - View task consumption by Zap
   - Identify high-usage Zaps
   - Forecast monthly usage
   - Set usage alerts
```

### External Monitoring
```plaintext
Create Monitoring Zap:

Trigger: Schedule (Every 1 Hour)

Action 1: GET Request to Zapier API
URL: https://api.zapier.com/v1/zaps
Headers:
- Authorization: Bearer {{api_key}}

Action 2: Code by Zapier (Python)
import json

zaps = json.loads(input_data['response'])
issues = []

for zap in zaps:
    if zap.get('state') == 'off':
        issues.append(f"Zap '{zap['title']}' is OFF")

    error_rate = zap.get('error_rate', 0)
    if error_rate > 5.0:
        issues.append(f"Zap '{zap['title']}' has {error_rate}% error rate")

output = {
    'has_issues': len(issues) > 0,
    'issues': issues,
    'issue_count': len(issues)
}

Action 3: Filter - Only Continue If
- Has Issues: true

Action 4: Send Slack Alert
Channel: #monitoring
Message: Zapier Health Alert:
{{code.issues}}
```

### Application Logging
```javascript
// Custom integration logging
const perform = async (z, bundle) => {
  // Zapier automatically logs request/response
  z.console.log('Processing order:', bundle.inputData.order_id);

  try {
    const response = await z.request({
      url: 'https://api.example.com/orders',
      method: 'POST',
      body: bundle.inputData
    });

    z.console.log('Order created successfully:', response.data.id);
    return response.data;

  } catch (error) {
    z.console.error('Order creation failed:', error.message);

    // Log to external service
    await z.request({
      url: 'https://logging-service.com/api/log',
      method: 'POST',
      body: {
        level: 'error',
        message: error.message,
        context: {
          order_id: bundle.inputData.order_id,
          user_id: bundle.authData.user_id,
          timestamp: new Date().toISOString()
        }
      }
    });

    throw error;
  }
};
```

### Performance Monitoring
```plaintext
Monitor These Metrics:

1. Execution Time:
   - View in Zap History
   - Typical: < 30 seconds per Zap run
   - Optimize if > 60 seconds

2. Error Rate:
   - Target: < 1% error rate
   - Investigate if > 5%
   - Alert if > 10%

3. Task Consumption:
   - Monitor daily/weekly trends
   - Compare to plan limits
   - Optimize high-usage Zaps

4. Trigger Frequency:
   - Polling triggers: Check interval
   - Reduce if too frequent
   - Use webhooks when possible

5. API Rate Limits:
   - Monitor 429 errors
   - Add delays if needed
   - Respect app-specific limits
```

## Cost Optimization Strategies

### Task Reduction Techniques
```plaintext
1. Consolidate Zaps:
   Before: 3 separate Zaps
   - Gmail → Sheets (1 task)
   - Gmail → Slack (1 task)
   - Gmail → HubSpot (1 task)
   Total: 3 tasks per email

   After: 1 multi-step Zap
   - Gmail → Sheets + Slack + HubSpot
   Total: 3 tasks per email (same)

   But saves on: Redundant triggers, easier maintenance

2. Use Filters Aggressively:
   Bad:
   - Process 1000 records/day
   - 80% don't meet criteria
   - 800 wasted tasks

   Good:
   - Filter at trigger level
   - Use trigger filters in app
   - Only process 200 relevant records
   - Save 800 tasks/day

3. Batch Operations:
   Bad:
   - Process 1 record at a time
   - 100 records = 100 Zap runs = 200 tasks

   Good:
   - Schedule: Run once daily
   - Fetch all new records (1 task)
   - Loop through records (100 tasks)
   - Total: 101 tasks (save 99 tasks)

4. Cache with Storage:
   Scenario: Look up customer data

   Without cache:
   - Search customer (1 task) × 100 times = 100 tasks

   With cache:
   - First run: Search + store (1 task)
   - Next 99 runs: Get from storage (0 tasks)
   - Total: 1 task (save 99 tasks)

5. Optimize Search Actions:
   Bad:
   - Search for customer
   - If not found, search again in different app
   - 2 tasks even if found first time

   Good:
   - Search in primary app
   - Use Paths: only search secondary if not found
   - 1 task if found, 2 tasks if not found

6. Reduce Trigger Frequency:
   Scenario: Check for new records

   5-minute interval:
   - 288 checks/day
   - 10 actual events/day
   - Unnecessary overhead

   15-minute interval:
   - 96 checks/day
   - Same 10 events captured
   - Same result, better performance
```

### Plan Optimization
```plaintext
Analyze Your Usage:
1. Go to Task History
2. Identify highest-usage Zaps
3. Calculate average tasks/month
4. Compare to plan limits

Right-Sizing Your Plan:

Free (100 tasks):
- 1-2 simple Zaps
- Personal use
- Testing/learning

Starter ($29.99 - 750 tasks):
- 3-5 multi-step Zaps
- Small business automation
- ~25 tasks/day average

Professional ($73.50 - 2,000 tasks):
- 10-20 Zaps
- Advanced features (webhooks, paths)
- ~65 tasks/day average

Team ($103.50 - 2,000 tasks):
- Multiple users
- Shared workspace
- Same task limits as Professional

Company (Custom):
- 50,000+ tasks
- Enterprise features
- Calculate: (tasks/month ÷ 50,000) × base price

Cost Per Task:
- Free: $0 (limited)
- Starter: $0.04/task
- Professional: $0.037/task
- Team: $0.052/task (shared)
- Company: ~$0.01-0.02/task (bulk)

Optimization Recommendations:
- If usage < 50% plan limit: Downgrade
- If usage > 80% plan limit: Upgrade or optimize
- If seasonal spikes: Consider on-demand tasks
```

### Alternative Architectures
```plaintext
When to Use Alternatives:

Scenario 1: Very High Volume
Problem: 100,000+ tasks/month on Zapier
Cost: $2,000+/month

Alternative:
- Build custom middleware
- Use message queue (RabbitMQ, SQS)
- Self-host integration platform (n8n, Huginn)
- Cost: $500-1,000/month (infrastructure + dev time)

Scenario 2: Complex Data Transformation
Problem: Heavy computation in Code steps
Limitation: 10-second timeout per step

Alternative:
- External API for processing
- AWS Lambda / Cloud Functions
- Webhook to trigger, webhook back to continue
- Faster execution, no timeout limits

Scenario 3: Real-time Requirements
Problem: 15-minute polling delay (Free/Starter)
Need: < 1 minute latency

Alternative:
- Upgrade to Professional (2-min polling)
- Use webhooks (instant)
- Or direct API integration

Scenario 4: Very Simple Workflow
Problem: Overkill to use Zapier
Example: Forward email → Slack

Alternative:
- Email filter rules
- App-native integrations
- IFTTT (simpler, cheaper for basic tasks)
```

## Pros and Cons

### Pros

1. **No-Code/Low-Code Platform**
   - Visual workflow builder
   - Non-technical users can create automations
   - Reduces development time by 80-90%
   - 5,000+ pre-built app integrations

2. **Extensive App Ecosystem**
   - Supports major platforms (Google, Microsoft, Salesforce, etc.)
   - Regular updates and new integrations
   - Community-built integrations
   - Partner program for custom apps

3. **Rapid Development and Deployment**
   - Build workflows in minutes vs weeks of coding
   - No infrastructure management
   - Instant deployment
   - Easy modifications and testing

4. **Built-in Error Handling and Monitoring**
   - Automatic retry logic
   - Error notifications
   - Zap History for debugging
   - Uptime and reliability tracking

5. **Scalability and Reliability**
   - Handles millions of tasks daily
   - 99.9%+ uptime SLA (Company plan)
   - Auto-scaling infrastructure
   - Load balancing and redundancy

6. **Cost-Effective for Small to Medium Workloads**
   - No upfront infrastructure costs
   - Pay only for what you use
   - Includes hosting, monitoring, maintenance
   - Faster ROI than custom development

7. **Strong Security and Compliance**
   - SOC 2 Type II certified
   - GDPR compliant
   - Data encryption (transit and rest)
   - SSO/SAML (enterprise plans)

### Cons

1. **Task Limits and Costs at Scale**
   - Can become expensive at high volumes (50,000+ tasks/month)
   - Each action step consumes a task
   - Need careful optimization
   - Alternative solutions may be cheaper for very high volume

2. **Limited Control and Customization**
   - Constrained by Zapier's architecture
   - Cannot modify core platform
   - Limited debugging capabilities
   - Dependent on Zapier's roadmap

3. **Performance Limitations**
   - Polling intervals: 1-15 minutes (plan-dependent)
   - Code step timeout: 10 seconds
   - Not suitable for real-time critical operations
   - Rate limits on API calls

4. **Vendor Lock-in**
   - Workflows tied to Zapier platform
   - Migration to alternatives requires rebuild
   - No export of Zap logic to code
   - Dependency on Zapier's availability

5. **Learning Curve for Advanced Features**
   - Paths, filters, and loops can be complex
   - Code steps require programming knowledge
   - CLI development needs technical expertise
   - Documentation can be scattered

## Common Pitfalls

1. **Not Using Filters Early in Workflow**
   - Problem: Actions execute before filtering, consuming tasks unnecessarily
   - Solution: Place filters immediately after trigger to prevent wasted tasks
   - Impact: Can waste 50-80% of task allocation on irrelevant data

2. **Hardcoding Values Instead of Using Variables**
   - Problem: Zaps break when values change; difficult to maintain
   - Solution: Use variables, storage, or environment variables for configuration
   - Example: Store API endpoints, team emails, account IDs as variables

3. **Ignoring Error Notifications**
   - Problem: Broken Zaps continue failing silently; data loss occurs
   - Solution: Configure alerts, monitor Zap History weekly, set up dashboard
   - Impact: Missing critical automation, poor user experience

4. **Poor Naming Conventions**
   - Problem: "My Zap 1", "Copy of My Zap" - impossible to identify purpose
   - Solution: Use descriptive names: "Stripe Payment → QuickBooks + Slack Alert"
   - Best practice: Include trigger + main actions in name

5. **Not Testing Zaps Thoroughly**
   - Problem: Edge cases not covered; Zaps fail in production
   - Solution: Test with various data scenarios, null values, edge cases
   - Process: Test each step individually, then full end-to-end

6. **Overcomplicating Single Zaps**
   - Problem: 20+ step mega-Zaps that are impossible to debug
   - Solution: Split into multiple focused Zaps, use clear boundaries
   - Rule of thumb: Keep Zaps under 10-12 steps

7. **Not Considering Rate Limits**
   - Problem: Hitting API rate limits, causing failures and delays
   - Solution: Add delays between actions, use batch processing, respect app limits
   - Monitor: Check for 429 errors in Zap History

8. **Assuming Instant Execution**
   - Problem: Users expect real-time when using polling triggers
   - Solution: Set expectations, use webhooks for time-critical workflows
   - Reality: Polling = 1-15 min delay; Webhooks = < 10 sec typically

9. **Insufficient Error Handling in Code Steps**
   - Problem: Cryptic errors, no logging, difficult debugging
   - Solution: Add try-catch blocks, log variables, validate inputs
   - Practice: Test code with edge cases, null values, unexpected formats

10. **Not Monitoring Task Consumption**
    - Problem: Surprise billing, running out of tasks mid-month
    - Solution: Set up usage alerts, review Task History weekly, optimize high-usage Zaps
    - Prevention: Audit Zaps monthly, identify optimization opportunities

## Real-World Automation Examples

### Example 1: E-commerce Order Processing
```plaintext
Scenario: Automate order fulfillment workflow

Trigger: New Order in Shopify (Webhook - Instant)

Step 1: Filter - Only Continue If
- Order Status: Equals: "paid"
- Fulfillment Status: Equals: "unfulfilled"

Step 2: Create Spreadsheet Row in Google Sheets
- Spreadsheet: Orders Master
- Order ID: {{trigger.id}}
- Customer: {{trigger.customer.name}}
- Total: {{trigger.total_price}}
- Items: {{trigger.line_items}}
- Date: {{trigger.created_at}}

Step 3: Paths - Route by Product Type

Path A: Physical Products
- Rule: Product Type equals "physical"
- Action 1: Create Shipment in ShipStation
  - Order Number: {{trigger.order_number}}
  - Ship To: {{trigger.shipping_address}}
  - Items: {{trigger.line_items}}

- Action 2: Send Email in Gmail
  - To: {{trigger.customer.email}}
  - Template: Shipping Confirmation
  - Tracking: {{shipstation.tracking_number}}

Path B: Digital Products
- Rule: Product Type equals "digital"
- Action 1: Send Email in SendGrid
  - To: {{trigger.customer.email}}
  - Template: Digital Delivery
  - Attachment: {{trigger.download_links}}

- Action 2: Add Tag in Mailchimp
  - Email: {{trigger.customer.email}}
  - Tag: Digital Customer

Step 4: Create Invoice in QuickBooks
- Customer: {{trigger.customer.name}}
- Amount: {{trigger.total_price}}
- Line Items: {{trigger.line_items}}
- Due Date: Immediate

Step 5: Send Channel Message in Slack
- Channel: #sales
- Message: New order {{trigger.order_number}} for ${{trigger.total_price}} from {{trigger.customer.name}}

Task Consumption: 4-5 tasks per order
Benefits: Saves 15-20 minutes per order, reduces errors
```

### Example 2: Lead Qualification and Routing
```plaintext
Scenario: Qualify and route leads from multiple sources

Trigger: New Form Submission in Typeform

Step 1: Code by Zapier - Calculate Lead Score
import json

score = 0
data = input_data

# Company size scoring
employees = int(data.get('employees', 0))
if employees > 500: score += 30
elif employees > 50: score += 20
elif employees > 10: score += 10

# Budget scoring
budget = int(data.get('budget', 0))
if budget > 50000: score += 30
elif budget > 10000: score += 20
elif budget > 5000: score += 10

# Urgency scoring
if data.get('urgency') == 'immediate': score += 25
elif data.get('urgency') == 'this_month': score += 15
elif data.get('urgency') == 'this_quarter': score += 5

# Authority scoring
if data.get('role') in ['CEO', 'CTO', 'VP']: score += 15
elif data.get('role') in ['Director', 'Manager']: score += 10

output = {'lead_score': score}

Step 2: Search Company in Clearbit (Enrichment)
- Domain: {{trigger.email_domain}}
- Returns: Company data, employee count, tech stack

Step 3: Paths - Route by Lead Score

Path A: Hot Lead (Score 70+)
- Action 1: Create Lead in Salesforce
  - First Name: {{trigger.first_name}}
  - Last Name: {{trigger.last_name}}
  - Email: {{trigger.email}}
  - Company: {{clearbit.company_name}}
  - Lead Score: {{code.lead_score}}
  - Lead Source: Typeform
  - Status: Hot Lead

- Action 2: Create Task in Salesforce
  - Subject: Call {{trigger.first_name}} ASAP
  - Priority: High
  - Due Date: Today
  - Assigned To: Enterprise Sales Team

- Action 3: Send Channel Message in Slack
  - Channel: #hot-leads
  - Message: @channel Hot lead: {{trigger.first_name}} {{trigger.last_name}} from {{clearbit.company_name}} - Score: {{code.lead_score}}
  - Include: Contact details and form responses

Path B: Warm Lead (Score 40-69)
- Action 1: Create Contact in HubSpot
  - Email: {{trigger.email}}
  - Lead Score: {{code.lead_score}}
  - Lifecycle Stage: Marketing Qualified Lead

- Action 2: Add to Sequence in Outreach.io
  - Sequence: Nurture Campaign
  - Contact: {{trigger.email}}
  - Variables: Custom fields from form

Path C: Cold Lead (Score < 40)
- Action 1: Add Subscriber to Mailchimp
  - List: Newsletter
  - Email: {{trigger.email}}
  - Tags: Cold Lead, Needs Nurturing

- Action 2: Create Row in Google Sheets
  - Spreadsheet: Lead Database
  - Status: Cold - Long-term Nurture

Step 4: Update Storage (Tracking)
- Key: lead_count_{{format_date}}
- Value: Increment counter

Task Consumption: 4-6 tasks per lead (varies by path)
Benefits: Instant lead routing, no manual qualification, 10x faster
```

### Example 3: Customer Support Automation
```plaintext
Scenario: Automate support ticket triage and response

Trigger: New Ticket in Zendesk (Webhook)

Step 1: Code by Zapier - Analyze Ticket Content
import re

subject = input_data.get('subject', '').lower()
description = input_data.get('description', '').lower()

# Categorize by keywords
categories = {
    'billing': ['invoice', 'payment', 'charge', 'refund', 'billing'],
    'technical': ['error', 'bug', 'not working', 'crash', 'broken'],
    'account': ['login', 'password', 'access', 'account', 'locked'],
    'feature': ['how to', 'question', 'help', 'tutorial']
}

detected_category = 'general'
for category, keywords in categories.items():
    if any(keyword in subject or keyword in description for keyword in keywords):
        detected_category = category
        break

# Detect urgency
urgent_keywords = ['urgent', 'asap', 'critical', 'down', 'broken', 'emergency']
is_urgent = any(keyword in subject or keyword in description for keyword in urgent_keywords)

output = {
    'category': detected_category,
    'is_urgent': is_urgent,
    'priority': 'high' if is_urgent else 'normal'
}

Step 2: Update Ticket in Zendesk
- Ticket ID: {{trigger.id}}
- Category: {{code.category}}
- Priority: {{code.priority}}
- Tags: {{code.category}}, auto-triaged

Step 3: Paths - Route by Category

Path A: Billing Issues
- Action 1: Assign to Group in Zendesk
  - Group: Billing Team

- Action 2: Send Channel Message in Slack
  - Channel: #billing-support
  - Message: New billing ticket #{{trigger.id}} from {{trigger.requester.name}}

Path B: Technical Issues
- Action 1: Create Issue in Jira
  - Project: Support Engineering
  - Summary: {{trigger.subject}}
  - Description: {{trigger.description}}
  - Reporter: {{trigger.requester.email}}

- Action 2: Add Comment to Zendesk Ticket
  - Comment: Engineering ticket created: {{jira.key}}

- Action 3: Send Email if Urgent
  - Filter: Only if is_urgent = true
  - To: engineering-oncall@company.com
  - Subject: Urgent: {{trigger.subject}}

Path C: Account Issues
- Action 1: Search User in Database (Webhook)
  - GET: https://api.company.com/users/{{trigger.requester.email}}

- Action 2: Send Reply in Zendesk
  - Status: Open
  - Comment: Template response with account details

- Action 3: Assign to Agent
  - Group: Account Support

Path D: General Questions
- Action 1: Search Help Center Articles
  - Query: {{trigger.subject}}

- Action 2: Add Private Note in Zendesk
  - Note: Suggested articles: {{helpcenter.articles}}

- Action 3: Auto-Reply with Articles
  - Template: Here are some articles that might help...

Step 4: Create Spreadsheet Row (Analytics)
- Spreadsheet: Support Metrics
- Date: {{trigger.created_at}}
- Category: {{code.category}}
- Priority: {{code.priority}}
- Response Time: Calculate later

Task Consumption: 3-7 tasks per ticket (varies by path)
Benefits: Instant triage, 50% faster response time, better routing
```

## Best Practices Summary

1. **Design for Maintainability**
   - Use clear, descriptive names for Zaps and steps
   - Document complex logic with step descriptions
   - Organize Zaps into folders by function
   - Version control CLI integrations

2. **Optimize Task Consumption**
   - Place filters early in workflows
   - Use Paths instead of multiple Zaps
   - Leverage Storage for caching
   - Batch operations when possible
   - Monitor and analyze task usage regularly

3. **Implement Robust Error Handling**
   - Configure error notifications
   - Add filters to validate data
   - Use try-catch in code steps
   - Plan for API rate limits
   - Monitor Zap History regularly

4. **Security First**
   - Never hardcode credentials
   - Use environment variables for secrets
   - Validate webhook sources
   - Apply principle of least privilege
   - Audit team access regularly

5. **Test Thoroughly**
   - Test each step individually
   - Use realistic test data
   - Cover edge cases and null values
   - Perform end-to-end testing
   - Monitor first production runs closely

6. **Plan for Scale**
   - Design for growth from start
   - Use webhooks over polling
   - Consider rate limits
   - Implement backoff strategies
   - Choose appropriate plan tier

7. **Monitor and Iterate**
   - Review Zap History weekly
   - Track error rates and patterns
   - Measure task consumption trends
   - Gather user feedback
   - Continuously optimize workflows

8. **Leverage Advanced Features**
   - Use Paths for complex branching
   - Implement Storage for stateful logic
   - Apply Formatters to avoid code steps
   - Create custom CLI integrations when needed
   - Utilize Looping for batch processing

9. **Follow API Best Practices**
   - Respect rate limits
   - Implement retry logic
   - Use pagination for large datasets
   - Cache frequently accessed data
   - Handle timeouts gracefully

10. **Document Everything**
    - Add descriptions to Zaps
    - Comment code steps thoroughly
    - Maintain runbooks for complex workflows
    - Document integrations in CLI
    - Keep team members informed

## Conclusion

Zapier is a powerful automation platform that enables organizations to connect their apps and automate workflows without extensive coding. Its extensive integration ecosystem, user-friendly interface, and robust features make it ideal for businesses of all sizes looking to streamline operations and improve efficiency.

Key takeaways:
- Start simple with single-step Zaps and gradually add complexity
- Invest time in proper design and testing to avoid costly mistakes
- Monitor task consumption and optimize regularly to control costs
- Leverage advanced features like Paths, Storage, and CLI integrations for complex scenarios
- Prioritize security and error handling from the beginning
- Use webhooks instead of polling for time-sensitive workflows
- Document your automations for easier maintenance and team collaboration

While Zapier has limitations in terms of cost at scale and customization depth, its rapid development capabilities, reliability, and extensive ecosystem make it an excellent choice for most automation needs. For very high-volume scenarios or highly specialized requirements, consider hybrid approaches combining Zapier with custom-built solutions.

The platform continues to evolve with new features, integrations, and capabilities. Stay updated with the official documentation, participate in the community, and experiment with new features to maximize the value of your automation investments.

With proper planning, implementation, and optimization, Zapier can significantly reduce manual work, improve data accuracy, and free up your team to focus on higher-value activities.
