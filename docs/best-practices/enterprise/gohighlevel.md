# GoHighLevel Best Practices

## Official Documentation
- **GoHighLevel Platform**: https://www.gohighlevel.com
- **API Documentation**: https://highlevel.stoplight.io/docs/integrations/
- **Developer Portal**: https://developers.gohighlevel.com
- **API v2 Reference**: https://highlevel.stoplight.io/docs/integrations/a04191c0fabf9-overview
- **Webhook Documentation**: https://highlevel.stoplight.io/docs/integrations/9d4c7c8d1e6b5-webhooks
- **Community & Support**: https://community.gohighlevel.com

## Platform Overview

GoHighLevel is an all-in-one white-label marketing and sales platform designed for agencies and SaaS businesses. It provides CRM, marketing automation, funnel building, appointment scheduling, SMS/email campaigns, and payment processing capabilities.

### Key Features
- Multi-tenant agency architecture with sub-accounts
- White-label customization for reselling
- Built-in CRM with pipelines and opportunities
- Funnel and website builder
- Marketing automation workflows
- Calendar and appointment booking
- SMS and email marketing
- Payment processing integration
- Comprehensive REST API v2
- OAuth 2.0 authentication

## Account Setup and Architecture

### Account Types

#### Agency Account
```
Agency Account (Top Level)
├── Agency Settings
├── White-Label Configuration
├── Billing Management
└── Sub-Accounts (Locations)
    ├── Location 1
    ├── Location 2
    └── Location N
```

#### Sub-Account (Location)
Each sub-account represents a client location with:
- Independent CRM database
- Separate contacts and opportunities
- Custom pipelines and workflows
- Individual calendars and users
- Isolated campaigns and funnels

### Initial Setup Steps

1. **Agency Account Creation**
```bash
# Access agency dashboard
https://app.gohighlevel.com

# Navigate to Settings > Company
# Configure:
# - Company name
# - Branding
# - Domain settings
# - SMTP configuration
```

2. **API Access Setup**
```bash
# Navigate to Settings > Integrations > API
# Create API credentials:
# - Application Name
# - Redirect URI (for OAuth)
# - Scopes selection
# - Note the Client ID and Client Secret
```

3. **White-Label Configuration**
```bash
# Settings > White Label
# Configure:
# - Custom domain (e.g., app.youragency.com)
# - Logo and favicon
# - Brand colors
# - Email templates
# - SMS sender ID
```

## Core Concepts

### Sub-Accounts (Locations)

Sub-accounts are client workspaces with complete CRM isolation.

**Create Sub-Account via API:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/locations/' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Client Business Name",
    "address": "123 Main St",
    "city": "New York",
    "state": "NY",
    "country": "US",
    "postalCode": "10001",
    "website": "https://clientwebsite.com",
    "timezone": "America/New_York",
    "email": "client@example.com",
    "phone": "+12125551234"
  }'
```

**Response:**
```json
{
  "location": {
    "id": "ve9EPM428h8vShlRW1KT",
    "name": "Client Business Name",
    "address": "123 Main St",
    "city": "New York",
    "state": "NY",
    "country": "US",
    "postalCode": "10001",
    "website": "https://clientwebsite.com",
    "timezone": "America/New_York",
    "email": "client@example.com",
    "phone": "+12125551234",
    "createdAt": "2025-01-15T10:30:00.000Z"
  }
}
```

### Contacts

Contacts are the core entity in the CRM system.

**Create Contact:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/contacts/' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "locationId": "ve9EPM428h8vShlRW1KT",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "+12125555678",
    "tags": ["lead", "website"],
    "source": "Website Form",
    "customFields": {
      "company": "Acme Corp",
      "industry": "Technology"
    }
  }'
```

**Response:**
```json
{
  "contact": {
    "id": "9NkT25Vor1v4aQy6LEY9",
    "locationId": "ve9EPM428h8vShlRW1KT",
    "firstName": "John",
    "lastName": "Doe",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "phone": "+12125555678",
    "tags": ["lead", "website"],
    "source": "Website Form",
    "dateAdded": "2025-01-15T10:35:00.000Z",
    "customFields": {
      "company": "Acme Corp",
      "industry": "Technology"
    }
  }
}
```

### Opportunities (Pipeline Stages)

Opportunities track deals through sales pipelines.

**Create Opportunity:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/opportunities/' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "locationId": "ve9EPM428h8vShlRW1KT",
    "pipelineId": "pPqRs7U8vWxY1z2A3b4C",
    "name": "Website Redesign Project",
    "pipelineStageId": "stg_initial_contact",
    "status": "open",
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "monetaryValue": 15000,
    "assignedTo": "user_abc123"
  }'
```

**Response:**
```json
{
  "opportunity": {
    "id": "opp_5d6E7f8G9h0I1j2K",
    "locationId": "ve9EPM428h8vShlRW1KT",
    "pipelineId": "pPqRs7U8vWxY1z2A3b4C",
    "name": "Website Redesign Project",
    "pipelineStageId": "stg_initial_contact",
    "status": "open",
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "monetaryValue": 15000,
    "assignedTo": "user_abc123",
    "createdAt": "2025-01-15T10:40:00.000Z"
  }
}
```

### Campaigns

Campaigns organize marketing communications.

**Campaign Structure:**
```json
{
  "campaign": {
    "id": "camp_1m2N3o4P5q6R7s8T",
    "locationId": "ve9EPM428h8vShlRW1KT",
    "name": "Welcome Series",
    "status": "active",
    "steps": [
      {
        "id": "step_1",
        "type": "email",
        "delay": 0,
        "subject": "Welcome to Our Service",
        "template": "template_welcome_001"
      },
      {
        "id": "step_2",
        "type": "sms",
        "delay": 86400,
        "message": "Thanks for joining! Reply HELP for assistance."
      },
      {
        "id": "step_3",
        "type": "email",
        "delay": 259200,
        "subject": "Getting Started Guide",
        "template": "template_guide_001"
      }
    ]
  }
}
```

## API Integration

### OAuth 2.0 Authentication

GoHighLevel uses OAuth 2.0 for secure API access.

**Step 1: Authorization URL**
```bash
https://marketplace.gohighlevel.com/oauth/chooselocation?response_type=code&client_id={client_id}&redirect_uri={redirect_uri}&scope={scopes}
```

**Available Scopes:**
- `contacts.readonly` - Read contacts
- `contacts.write` - Create/update contacts
- `opportunities.readonly` - Read opportunities
- `opportunities.write` - Create/update opportunities
- `calendars.readonly` - Read calendars
- `calendars.write` - Manage calendars
- `locations.readonly` - Read locations
- `locations.write` - Manage locations
- `workflows.readonly` - Read workflows
- `campaigns.readonly` - Read campaigns
- `users.readonly` - Read users

**Step 2: Exchange Code for Token**
```bash
curl -X POST 'https://services.leadconnectorhq.com/oauth/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'client_id={client_id}' \
  -d 'client_secret={client_secret}' \
  -d 'grant_type=authorization_code' \
  -d 'code={authorization_code}' \
  -d 'redirect_uri={redirect_uri}'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "scope": "contacts.readonly contacts.write opportunities.write",
  "locationId": "ve9EPM428h8vShlRW1KT",
  "companyId": "comp_9z8Y7x6W5v4U3t2S"
}
```

**Step 3: Refresh Token**
```bash
curl -X POST 'https://services.leadconnectorhq.com/oauth/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'client_id={client_id}' \
  -d 'client_secret={client_secret}' \
  -d 'grant_type=refresh_token' \
  -d 'refresh_token={refresh_token}'
```

### REST API Best Practices

**API Headers:**
```bash
Authorization: Bearer {access_token}
Version: 2021-07-28
Content-Type: application/json
Accept: application/json
```

**Error Handling:**
```javascript
async function makeAPIRequest(endpoint, method, data) {
  try {
    const response = await fetch(`https://services.leadconnectorhq.com${endpoint}`, {
      method: method,
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Version': '2021-07-28',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      const error = await response.json();

      // Handle specific error codes
      if (response.status === 401) {
        // Token expired, refresh
        await refreshAccessToken();
        return makeAPIRequest(endpoint, method, data);
      }

      if (response.status === 429) {
        // Rate limit, wait and retry
        const retryAfter = response.headers.get('Retry-After') || 60;
        await sleep(retryAfter * 1000);
        return makeAPIRequest(endpoint, method, data);
      }

      throw new Error(`API Error: ${error.message}`);
    }

    return await response.json();
  } catch (error) {
    console.error('API Request Failed:', error);
    throw error;
  }
}
```

### Webhooks

Configure webhooks to receive real-time events.

**Webhook Configuration:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/webhooks/' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "locationId": "ve9EPM428h8vShlRW1KT",
    "url": "https://your-server.com/webhooks/ghl",
    "events": [
      "contact.created",
      "contact.updated",
      "opportunity.created",
      "opportunity.status_changed",
      "appointment.created",
      "campaign.completed"
    ]
  }'
```

**Webhook Payload Example (Contact Created):**
```json
{
  "type": "contact.created",
  "locationId": "ve9EPM428h8vShlRW1KT",
  "timestamp": "2025-01-15T10:50:00.000Z",
  "data": {
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "+12125555678",
    "tags": ["lead", "website"],
    "source": "Website Form"
  }
}
```

**Webhook Handler:**
```javascript
const crypto = require('crypto');
const express = require('express');
const app = express();

app.use(express.json());

// Verify webhook signature
function verifyWebhookSignature(payload, signature, secret) {
  const hmac = crypto.createHmac('sha256', secret);
  const digest = hmac.update(payload).digest('hex');
  return signature === digest;
}

app.post('/webhooks/ghl', (req, res) => {
  const signature = req.headers['x-ghl-signature'];
  const payload = JSON.stringify(req.body);

  if (!verifyWebhookSignature(payload, signature, process.env.WEBHOOK_SECRET)) {
    return res.status(401).send('Invalid signature');
  }

  const event = req.body;

  // Process event
  switch (event.type) {
    case 'contact.created':
      handleContactCreated(event.data);
      break;
    case 'opportunity.created':
      handleOpportunityCreated(event.data);
      break;
    case 'appointment.created':
      handleAppointmentCreated(event.data);
      break;
    default:
      console.log('Unhandled event:', event.type);
  }

  res.status(200).send('OK');
});

async function handleContactCreated(data) {
  console.log('New contact created:', data.contactId);
  // Add to your external CRM, send notifications, etc.
}
```

## White-Label Setup and Configuration

### Custom Domain Setup

1. **Add Custom Domain**
```bash
# In Agency Settings > White Label > Custom Domain
# Add: app.youragency.com
```

2. **DNS Configuration**
```
# CNAME Record
Host: app
Points to: proxy-ssl.leadconnectorhq.com
TTL: 3600
```

3. **SSL Certificate**
```bash
# GoHighLevel automatically provisions SSL via Let's Encrypt
# Verify after DNS propagation (24-48 hours)
```

### Branding Configuration

**Custom CSS:**
```css
/* Custom branding CSS */
:root {
  --primary-color: #0066cc;
  --secondary-color: #ff6600;
  --accent-color: #00cc66;
  --text-color: #333333;
  --background-color: #ffffff;
}

.navbar-brand img {
  max-height: 40px;
  width: auto;
}

.btn-primary {
  background-color: var(--primary-color);
  border-color: var(--primary-color);
}

.sidebar {
  background-color: var(--background-color);
}
```

**Email Branding:**
```html
<!-- Email Template Header -->
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td align="center" style="padding: 20px 0;">
      <img src="{{agency.logo}}" alt="{{agency.name}}" height="50">
    </td>
  </tr>
  <tr>
    <td style="padding: 20px; font-family: Arial, sans-serif;">
      <!-- Email content here -->
    </td>
  </tr>
  <tr>
    <td align="center" style="padding: 20px; color: #666; font-size: 12px;">
      <p>&copy; 2025 {{agency.name}}. All rights reserved.</p>
      <p>{{agency.address}}</p>
    </td>
  </tr>
</table>
```

## Funnel and Website Builder Best Practices

### Funnel Structure

**Sales Funnel Architecture:**
```
Landing Page → Opt-in Form → Thank You Page → Email Sequence → Sales Page → Checkout → Order Confirmation
```

**Best Practices:**
1. **Keep it simple**: Single call-to-action per page
2. **Mobile-first**: Design for mobile, enhance for desktop
3. **Fast loading**: Optimize images, minimize scripts
4. **Clear value proposition**: Above the fold
5. **Trust signals**: Testimonials, guarantees, security badges

**Landing Page Template:**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{page.title}}</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; }
    .hero { min-height: 100vh; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .cta-button { background: #ff6600; color: white; padding: 15px 30px; border: none; border-radius: 5px; font-size: 18px; cursor: pointer; }
  </style>
</head>
<body>
  <section class="hero">
    <div class="container">
      <h1>{{page.headline}}</h1>
      <p>{{page.subheadline}}</p>
      <form id="lead-form" action="/api/forms/submit" method="POST">
        <input type="text" name="firstName" placeholder="First Name" required>
        <input type="email" name="email" placeholder="Email" required>
        <input type="tel" name="phone" placeholder="Phone">
        <button type="submit" class="cta-button">{{page.cta_text}}</button>
      </form>
    </div>
  </section>
</body>
</html>
```

### Form Integration

**Custom Form Handler:**
```javascript
document.getElementById('lead-form').addEventListener('submit', async (e) => {
  e.preventDefault();

  const formData = {
    locationId: 've9EPM428h8vShlRW1KT',
    firstName: e.target.firstName.value,
    email: e.target.email.value,
    phone: e.target.phone.value,
    tags: ['website-lead', 'funnel-landing'],
    source: 'Landing Page'
  };

  try {
    const response = await fetch('https://services.leadconnectorhq.com/contacts/', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + apiToken,
        'Version': '2021-07-28',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(formData)
    });

    if (response.ok) {
      window.location.href = '/thank-you';
    } else {
      alert('Error submitting form. Please try again.');
    }
  } catch (error) {
    console.error('Form submission error:', error);
    alert('Network error. Please try again.');
  }
});
```

## Automation Workflows and Triggers

### Workflow Structure

**Basic Workflow Components:**
- Trigger (entry point)
- Conditions (filters)
- Actions (operations)
- Delays (timing)

**Example: Lead Nurture Workflow**
```yaml
workflow:
  name: "New Lead Nurture Sequence"
  trigger:
    type: "contact.created"
    filters:
      - tag: "lead"
      - source: "Website Form"

  steps:
    - action: "send_email"
      template: "welcome_email"
      delay: 0

    - action: "wait"
      duration: 86400  # 24 hours

    - condition:
        if: "email_opened"
        then:
          - action: "send_sms"
            message: "Thanks for your interest! Book a call: {{calendar_link}}"
        else:
          - action: "send_email"
            template: "follow_up_email_1"

    - action: "wait"
      duration: 259200  # 72 hours

    - condition:
        if: "appointment_booked"
        then:
          - action: "add_tag"
            tag: "appointment-scheduled"
          - action: "send_email"
            template: "appointment_confirmation"
          - action: "end_workflow"
        else:
          - action: "send_email"
            template: "last_chance_offer"

    - action: "wait"
      duration: 172800  # 48 hours

    - action: "add_tag"
      tag: "cold-lead"
    - action: "end_workflow"
```

### Trigger Types

1. **Contact Triggers**
   - Contact created
   - Contact updated
   - Tag added
   - Custom field changed

2. **Opportunity Triggers**
   - Opportunity created
   - Stage changed
   - Status changed
   - Won/Lost

3. **Appointment Triggers**
   - Appointment booked
   - Appointment confirmed
   - Appointment cancelled
   - Appointment completed

4. **Form Triggers**
   - Form submitted
   - Survey completed

5. **Campaign Triggers**
   - Campaign completed
   - Email opened
   - Link clicked
   - SMS replied

## CRM Management

### Contact Organization

**Tagging Strategy:**
```javascript
const tagHierarchy = {
  status: ['lead', 'prospect', 'customer', 'churned'],
  source: ['website', 'referral', 'paid-ad', 'social-media'],
  interest: ['service-a', 'service-b', 'service-c'],
  engagement: ['hot', 'warm', 'cold'],
  lifecycle: ['new', 'nurture', 'sales-ready', 'closed']
};

// Apply tags programmatically
async function tagContact(contactId, tags) {
  await fetch(`https://services.leadconnectorhq.com/contacts/${contactId}/tags`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Version': '2021-07-28',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ tags })
  });
}
```

### Pipeline Management

**Pipeline Configuration:**
```json
{
  "pipeline": {
    "name": "Sales Pipeline",
    "stages": [
      {
        "id": "stage_1",
        "name": "New Lead",
        "order": 1,
        "probability": 10
      },
      {
        "id": "stage_2",
        "name": "Contacted",
        "order": 2,
        "probability": 25
      },
      {
        "id": "stage_3",
        "name": "Qualified",
        "order": 3,
        "probability": 50
      },
      {
        "id": "stage_4",
        "name": "Proposal Sent",
        "order": 4,
        "probability": 75
      },
      {
        "id": "stage_5",
        "name": "Negotiation",
        "order": 5,
        "probability": 90
      },
      {
        "id": "stage_6",
        "name": "Closed Won",
        "order": 6,
        "probability": 100
      }
    ]
  }
}
```

**Move Opportunity Between Stages:**
```bash
curl -X PUT 'https://services.leadconnectorhq.com/opportunities/opp_5d6E7f8G9h0I1j2K' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "pipelineStageId": "stage_3",
    "status": "open"
  }'
```

## Calendar and Appointment Booking

### Calendar Setup

**Create Calendar:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/calendars/' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "locationId": "ve9EPM428h8vShlRW1KT",
    "name": "Sales Consultation",
    "description": "30-minute sales consultation call",
    "slug": "sales-consultation",
    "duration": 30,
    "bufferTime": 15,
    "availability": {
      "monday": [
        {"start": "09:00", "end": "17:00"}
      ],
      "tuesday": [
        {"start": "09:00", "end": "17:00"}
      ],
      "wednesday": [
        {"start": "09:00", "end": "17:00"}
      ],
      "thursday": [
        {"start": "09:00", "end": "17:00"}
      ],
      "friday": [
        {"start": "09:00", "end": "15:00"}
      ]
    },
    "timezone": "America/New_York",
    "appointmentType": "virtual",
    "meetingLocation": "Zoom",
    "confirmationEmails": true,
    "reminderEmails": true,
    "reminderSms": true
  }'
```

### Booking Widget Integration

**Embed Calendar Widget:**
```html
<div id="ghl-calendar-widget"></div>
<script src="https://link.msgsndr.com/js/form_embed.js"></script>
<script>
  GHL.initCalendarWidget({
    calendarId: 'cal_1a2B3c4D5e6F',
    container: 'ghl-calendar-widget',
    styles: {
      primaryColor: '#0066cc',
      backgroundColor: '#ffffff',
      textColor: '#333333'
    }
  });
</script>
```

**Create Appointment via API:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/calendars/cal_1a2B3c4D5e6F/appointments' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "startTime": "2025-01-20T14:00:00.000Z",
    "endTime": "2025-01-20T14:30:00.000Z",
    "timezone": "America/New_York",
    "notes": "Interested in premium package",
    "assignedTo": "user_abc123"
  }'
```

## SMS and Email Marketing Campaigns

### SMS Campaign Best Practices

**SMS Message Guidelines:**
- Keep messages under 160 characters
- Include opt-out instructions (STOP, UNSUBSCRIBE)
- Personalize with contact names
- Clear call-to-action
- Timing: 9 AM - 8 PM local time

**Send SMS via API:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/conversations/messages' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "SMS",
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "locationId": "ve9EPM428h8vShlRW1KT",
    "message": "Hi {{contact.first_name}}, your appointment is confirmed for {{appointment.date}} at {{appointment.time}}. Reply CANCEL to reschedule."
  }'
```

### Email Campaign Best Practices

**Email Template Structure:**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
    .container { max-width: 600px; margin: 0 auto; }
    .header { background: #0066cc; padding: 20px; text-align: center; }
    .content { padding: 30px 20px; }
    .cta { background: #ff6600; color: white; padding: 12px 24px; text-decoration: none; display: inline-block; border-radius: 5px; }
    .footer { background: #f4f4f4; padding: 20px; text-align: center; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="{{agency.logo}}" alt="{{agency.name}}" height="40">
    </div>
    <div class="content">
      <h1>Hi {{contact.first_name}},</h1>
      <p>{{email.body}}</p>
      <p style="text-align: center;">
        <a href="{{email.cta_link}}" class="cta">{{email.cta_text}}</a>
      </p>
    </div>
    <div class="footer">
      <p>{{agency.name}}</p>
      <p>{{agency.address}}</p>
      <p><a href="{{unsubscribe_link}}">Unsubscribe</a></p>
    </div>
  </div>
</body>
</html>
```

**Send Email via API:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/conversations/messages' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "Email",
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "locationId": "ve9EPM428h8vShlRW1KT",
    "subject": "Your Exclusive Offer Awaits",
    "html": "<html>...</html>",
    "attachments": []
  }'
```

## Payment Integration

### Stripe Integration

**Configure Stripe:**
```bash
# Navigate to: Settings > Integrations > Payments
# Add Stripe credentials:
# - Publishable Key
# - Secret Key
# - Webhook Secret
```

**Create Payment Link:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/payments/orders' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "locationId": "ve9EPM428h8vShlRW1KT",
    "contactId": "9NkT25Vor1v4aQy6LEY9",
    "amount": 199.99,
    "currency": "USD",
    "description": "Monthly Subscription",
    "successUrl": "https://yoursite.com/success",
    "cancelUrl": "https://yoursite.com/cancel"
  }'
```

**Response:**
```json
{
  "order": {
    "id": "order_7h8I9j0K1l2M",
    "paymentUrl": "https://payments.msgsndr.com/pay/order_7h8I9j0K1l2M",
    "amount": 199.99,
    "currency": "USD",
    "status": "pending"
  }
}
```

**Subscription Setup:**
```javascript
const subscription = {
  locationId: 've9EPM428h8vShlRW1KT',
  contactId: '9NkT25Vor1v4aQy6LEY9',
  planId: 'plan_monthly_199',
  amount: 199.99,
  currency: 'USD',
  interval: 'month',
  intervalCount: 1,
  trialDays: 14,
  metadata: {
    productName: 'Premium Package',
    tier: 'Gold'
  }
};
```

## Custom Values and Custom Fields

### Custom Field Configuration

**Create Custom Field:**
```bash
curl -X POST 'https://services.leadconnectorhq.com/locations/ve9EPM428h8vShlRW1KT/customFields' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Annual Revenue",
    "dataType": "NUMBER",
    "position": 1,
    "placeholder": "Enter annual revenue"
  }'
```

**Field Types:**
- TEXT
- TEXTAREA
- NUMBER
- MONETARY
- PHONE
- EMAIL
- DATE
- CHECKBOX
- SINGLE_OPTIONS (dropdown)
- MULTIPLE_OPTIONS (multi-select)

**Update Contact Custom Fields:**
```bash
curl -X PUT 'https://services.leadconnectorhq.com/contacts/9NkT25Vor1v4aQy6LEY9' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -H 'Content-Type: application/json' \
  -d '{
    "customFields": {
      "annual_revenue": 500000,
      "company_size": "50-100",
      "industry": "Technology",
      "last_contact_date": "2025-01-15"
    }
  }'
```

## Reporting and Analytics

### Built-in Reports

**Available Reports:**
- Contact growth
- Opportunity pipeline value
- Conversion rates
- Campaign performance
- Appointment statistics
- Revenue tracking
- User activity

**Get Analytics via API:**
```bash
curl -X GET 'https://services.leadconnectorhq.com/locations/ve9EPM428h8vShlRW1KT/analytics?startDate=2025-01-01&endDate=2025-01-31' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28'
```

**Response:**
```json
{
  "analytics": {
    "contacts": {
      "total": 1250,
      "new": 120,
      "active": 980
    },
    "opportunities": {
      "total": 85,
      "totalValue": 425000,
      "won": 12,
      "wonValue": 95000,
      "conversionRate": 14.1
    },
    "appointments": {
      "scheduled": 145,
      "completed": 112,
      "noShow": 18,
      "showRate": 77.2
    },
    "revenue": {
      "total": 125000,
      "recurring": 85000,
      "oneTime": 40000
    }
  }
}
```

## API Rate Limits and Optimization

### Rate Limits

**Current Limits (as of 2025):**
- 100 requests per 10 seconds per location
- 10,000 requests per day per location
- Webhook: 100 events per minute

**Rate Limit Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1642253400
```

### Optimization Strategies

**1. Batch Operations**
```javascript
// Bad: Individual requests
for (const contact of contacts) {
  await createContact(contact);
}

// Good: Bulk import
await bulkImportContacts(contacts);
```

**2. Implement Exponential Backoff**
```javascript
async function apiRequestWithRetry(fn, maxRetries = 3) {
  let retries = 0;

  while (retries < maxRetries) {
    try {
      return await fn();
    } catch (error) {
      if (error.status === 429) {
        const waitTime = Math.pow(2, retries) * 1000;
        await sleep(waitTime);
        retries++;
      } else {
        throw error;
      }
    }
  }

  throw new Error('Max retries exceeded');
}
```

**3. Caching**
```javascript
const cache = new Map();
const CACHE_TTL = 300000; // 5 minutes

async function getCachedLocation(locationId) {
  const cached = cache.get(locationId);

  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }

  const location = await fetchLocation(locationId);
  cache.set(locationId, {
    data: location,
    timestamp: Date.now()
  });

  return location;
}
```

**4. Webhook vs Polling**
```javascript
// Bad: Polling
setInterval(async () => {
  const newContacts = await fetchContacts({ since: lastCheck });
  processContacts(newContacts);
}, 60000);

// Good: Webhook
app.post('/webhooks/contact-created', (req, res) => {
  processContact(req.body.data);
  res.sendStatus(200);
});
```

## Security Considerations

### OAuth Scopes

**Principle of Least Privilege:**
```javascript
// Only request necessary scopes
const requiredScopes = [
  'contacts.readonly',
  'opportunities.readonly',
  'calendars.write'
];

// Not all scopes
const unnecessaryScopes = [
  'contacts.readonly',
  'contacts.write',
  'opportunities.readonly',
  'opportunities.write',
  'locations.write',
  'users.write'  // Don't request if not needed
];
```

### API Key Storage

**Environment Variables:**
```bash
# .env
GHL_CLIENT_ID=your_client_id
GHL_CLIENT_SECRET=your_client_secret
GHL_WEBHOOK_SECRET=your_webhook_secret

# Never commit .env to version control
# Add to .gitignore
echo ".env" >> .gitignore
```

**Secure Token Storage:**
```javascript
// Use encrypted storage for tokens
const CryptoJS = require('crypto-js');

function encryptToken(token, secret) {
  return CryptoJS.AES.encrypt(token, secret).toString();
}

function decryptToken(encryptedToken, secret) {
  const bytes = CryptoJS.AES.decrypt(encryptedToken, secret);
  return bytes.toString(CryptoJS.enc.Utf8);
}
```

### Data Protection

**PII Handling:**
```javascript
// Log without exposing sensitive data
function logAPICall(endpoint, data) {
  const sanitized = { ...data };
  delete sanitized.email;
  delete sanitized.phone;
  delete sanitized.ssn;

  console.log(`API Call: ${endpoint}`, sanitized);
}

// Implement data retention policies
async function cleanupOldContacts() {
  const threeYearsAgo = new Date();
  threeYearsAgo.setFullYear(threeYearsAgo.getFullYear() - 3);

  // Delete or anonymize old contacts
  await anonymizeInactiveContacts(threeYearsAgo);
}
```

## Integration with External Tools

### Zapier Integration

**Trigger: New Contact Created**
```javascript
// Zapier webhook trigger
{
  "trigger": "new_contact",
  "locationId": "ve9EPM428h8vShlRW1KT",
  "contact": {
    "id": "{{contact.id}}",
    "firstName": "{{contact.firstName}}",
    "lastName": "{{contact.lastName}}",
    "email": "{{contact.email}}",
    "tags": "{{contact.tags}}"
  }
}
```

### Make (formerly Integromat)

**Scenario: Sync Contacts to Google Sheets**
```json
{
  "scenario": {
    "name": "GHL to Google Sheets",
    "modules": [
      {
        "type": "gohighlevel:watchContacts",
        "parameters": {
          "locationId": "ve9EPM428h8vShlRW1KT"
        }
      },
      {
        "type": "google-sheets:addRow",
        "parameters": {
          "spreadsheetId": "your_spreadsheet_id",
          "sheetName": "Contacts",
          "values": [
            "{{1.firstName}}",
            "{{1.lastName}}",
            "{{1.email}}",
            "{{1.phone}}",
            "{{formatDate(1.dateAdded, 'YYYY-MM-DD')}}"
          ]
        }
      }
    ]
  }
}
```

### Custom Integration

**Sync with External CRM:**
```javascript
const express = require('express');
const axios = require('axios');

class GHLSync {
  constructor(ghlToken, externalCRMToken) {
    this.ghlToken = ghlToken;
    this.externalCRMToken = externalCRMToken;
  }

  async syncContact(ghlContactId) {
    // Fetch from GHL
    const ghlContact = await this.fetchGHLContact(ghlContactId);

    // Transform data
    const externalFormat = this.transformContact(ghlContact);

    // Push to external CRM
    await this.pushToExternalCRM(externalFormat);
  }

  async fetchGHLContact(contactId) {
    const response = await axios.get(
      `https://services.leadconnectorhq.com/contacts/${contactId}`,
      {
        headers: {
          'Authorization': `Bearer ${this.ghlToken}`,
          'Version': '2021-07-28'
        }
      }
    );
    return response.data.contact;
  }

  transformContact(ghlContact) {
    return {
      external_id: ghlContact.id,
      first_name: ghlContact.firstName,
      last_name: ghlContact.lastName,
      email: ghlContact.email,
      phone: ghlContact.phone,
      tags: ghlContact.tags,
      custom_fields: ghlContact.customFields
    };
  }

  async pushToExternalCRM(contact) {
    await axios.post(
      'https://external-crm.com/api/contacts',
      contact,
      {
        headers: {
          'Authorization': `Bearer ${this.externalCRMToken}`
        }
      }
    );
  }
}
```

## Testing Strategies for Workflows

### Workflow Testing

**Test Environment Setup:**
```bash
# Create test sub-account
curl -X POST 'https://services.leadconnectorhq.com/locations/' \
  -H 'Authorization: Bearer {access_token}' \
  -H 'Version: 2021-07-28' \
  -d '{
    "name": "TEST - Workflow Testing",
    "timezone": "America/New_York",
    "email": "test@example.com"
  }'
```

**Test Contact Creation:**
```javascript
async function createTestContact(scenario) {
  const testContact = {
    locationId: TEST_LOCATION_ID,
    firstName: `Test-${scenario}`,
    lastName: 'Contact',
    email: `test-${Date.now()}@example.com`,
    phone: '+15555551234',
    tags: scenario.tags,
    source: 'Test Suite'
  };

  return await createContact(testContact);
}

// Test scenarios
const testScenarios = [
  {
    name: 'Lead nurture workflow',
    tags: ['lead', 'website'],
    expectedActions: ['welcome_email', 'sms_followup']
  },
  {
    name: 'Appointment booking workflow',
    tags: ['sales-ready'],
    expectedActions: ['booking_email', 'calendar_link']
  }
];

for (const scenario of testScenarios) {
  const contact = await createTestContact(scenario);
  await verifyWorkflowExecution(contact.id, scenario.expectedActions);
}
```

### API Testing

**Unit Tests:**
```javascript
const { expect } = require('chai');
const GHLClient = require('./ghl-client');

describe('GoHighLevel API', () => {
  let client;

  beforeEach(() => {
    client = new GHLClient(process.env.GHL_TEST_TOKEN);
  });

  describe('Contacts', () => {
    it('should create a contact', async () => {
      const contact = await client.createContact({
        locationId: TEST_LOCATION_ID,
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com'
      });

      expect(contact).to.have.property('id');
      expect(contact.firstName).to.equal('Test');
    });

    it('should handle duplicate emails', async () => {
      try {
        await client.createContact({
          locationId: TEST_LOCATION_ID,
          email: 'duplicate@example.com'
        });

        await client.createContact({
          locationId: TEST_LOCATION_ID,
          email: 'duplicate@example.com'
        });

        throw new Error('Should have thrown duplicate error');
      } catch (error) {
        expect(error.message).to.include('duplicate');
      }
    });
  });
});
```

## Pros and Cons

### Pros

1. **All-in-One Platform**: Complete marketing and sales toolkit in one system, eliminating the need for multiple tools
2. **White-Label Capabilities**: Full customization for agencies to brand and resell as their own product
3. **Affordable Pricing**: Competitive pricing compared to using multiple separate tools
4. **Comprehensive API**: Well-documented REST API v2 with OAuth 2.0 support
5. **Visual Workflow Builder**: No-code automation builder for complex marketing workflows
6. **Built-in Communication**: Native SMS, email, and calling capabilities without external integrations
7. **Active Development**: Regular updates and new features from the development team

### Cons

1. **Learning Curve**: Complex platform with many features requires significant onboarding time
2. **API Rate Limits**: 100 requests per 10 seconds can be restrictive for high-volume applications
3. **Limited Customization**: Some UI elements and workflows have constraints that can't be modified
4. **Reporting Limitations**: Advanced analytics and custom reporting require external tools or API extraction
5. **Performance Issues**: Platform can experience slowdowns during peak usage times

## Common Pitfalls

1. **Not Setting Up Test Environment**: Always create a test sub-account before implementing workflows in production locations

2. **Ignoring Rate Limits**: Implement proper rate limiting and exponential backoff to avoid API throttling

3. **Poor Tag Management**: Create a consistent tagging strategy early; inconsistent tags make segmentation difficult

4. **Overcomplicating Workflows**: Start simple and iterate; complex workflows are harder to debug and maintain

5. **Not Using Webhook Verification**: Always verify webhook signatures to prevent unauthorized data injection

6. **Hardcoding Location IDs**: Use environment variables for location IDs to support multiple environments

7. **Insufficient Error Handling**: API calls can fail; implement robust error handling and logging

8. **Not Caching Static Data**: Cache location settings, custom fields, and pipeline configurations to reduce API calls

9. **Neglecting Token Refresh**: Implement automatic token refresh before expiration to prevent authentication failures

10. **Missing GDPR Compliance**: Implement proper data retention, deletion, and consent management for international compliance

## Real-World Use Cases

### Agency Workflows

**Multi-Client Management:**
```javascript
class AgencyManager {
  async onboardNewClient(clientData) {
    // 1. Create sub-account
    const location = await this.createSubAccount(clientData);

    // 2. Configure pipelines
    await this.setupDefaultPipelines(location.id);

    // 3. Import contacts
    await this.importContacts(location.id, clientData.contacts);

    // 4. Setup automation workflows
    await this.deployWorkflows(location.id);

    // 5. Configure calendar
    await this.setupCalendar(location.id, clientData.businessHours);

    // 6. Setup reporting
    await this.configureReporting(location.id);

    return location;
  }

  async generateClientReport(locationId, dateRange) {
    const [contacts, opportunities, appointments, revenue] = await Promise.all([
      this.getContactStats(locationId, dateRange),
      this.getOpportunityStats(locationId, dateRange),
      this.getAppointmentStats(locationId, dateRange),
      this.getRevenueStats(locationId, dateRange)
    ]);

    return {
      contacts,
      opportunities,
      appointments,
      revenue,
      generatedAt: new Date()
    };
  }
}
```

### SaaS Mode

**Multi-Tenant Application:**
```javascript
class SaaSPlatform {
  async provisionNewTenant(tenantData) {
    // Create dedicated sub-account for tenant
    const location = await ghl.createLocation({
      name: tenantData.companyName,
      email: tenantData.adminEmail,
      timezone: tenantData.timezone
    });

    // Setup tenant-specific configuration
    await this.configureTenant(location.id, tenantData.config);

    // Create admin user
    await this.createTenantAdmin(location.id, tenantData.adminEmail);

    // Setup billing
    await this.setupSubscription(location.id, tenantData.plan);

    return {
      tenantId: location.id,
      loginUrl: `https://app.yoursaas.com/tenant/${location.id}`,
      apiKey: await this.generateAPIKey(location.id)
    };
  }

  async handleWebhook(event) {
    const tenantId = event.locationId;

    switch (event.type) {
      case 'contact.created':
        await this.trackUsage(tenantId, 'contact', 1);
        await this.checkUsageLimits(tenantId);
        break;

      case 'message.sent':
        await this.trackUsage(tenantId, 'sms', 1);
        await this.deductCredits(tenantId, 1);
        break;
    }
  }
}
```

## Best Practices Summary

1. **Architecture**: Plan your sub-account structure before implementation
2. **Authentication**: Use OAuth 2.0 for production, implement token refresh logic
3. **Rate Limiting**: Implement exponential backoff and caching strategies
4. **Error Handling**: Log all errors, implement retry logic for transient failures
5. **Testing**: Maintain separate test sub-accounts, test workflows thoroughly
6. **Security**: Store credentials securely, use environment variables, verify webhooks
7. **Data Management**: Implement consistent tagging, use custom fields strategically
8. **Workflows**: Start simple, document complex workflows, monitor execution
9. **Integration**: Use webhooks over polling, batch operations when possible
10. **Monitoring**: Track API usage, monitor workflow performance, review analytics regularly

## Conclusion

GoHighLevel provides a comprehensive platform for agencies and SaaS businesses to manage client relationships and marketing automation. Success requires careful planning of account architecture, strategic use of automation workflows, and proper API integration practices. By following these best practices, implementing robust error handling, and maintaining clean data management, teams can build scalable and efficient marketing systems.

The platform's white-label capabilities and extensive API make it ideal for agencies building their own branded solutions. However, proper testing, rate limit management, and security considerations are essential for production deployments. Regular monitoring and optimization ensure long-term success with the platform.
