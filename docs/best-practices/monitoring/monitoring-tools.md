# Application Monitoring Tools Best Practices

## Overview
Application monitoring tools help track performance, errors, uptime, and user behavior in production environments. This guide covers best practices for implementing Datadog, Rollbar, Sentry, and New Relic.

## Datadog

### Overview
Datadog is a comprehensive monitoring and analytics platform for cloud-scale applications, providing observability across infrastructure, applications, and logs.

### Documentation
- [Official Documentation](https://docs.datadoghq.com)
- [API Reference](https://docs.datadoghq.com/api)
- [Integrations](https://docs.datadoghq.com/integrations)

### Implementation

#### Basic Setup
```javascript
// Node.js implementation
const tracer = require('dd-trace').init({
  env: 'production',
  service: 'my-application',
  version: '1.0.0',
  analytics: true,
  logInjection: true,
  profiling: true,
  runtimeMetrics: true
});

// Custom spans
const span = tracer.startSpan('custom.operation');
span.setTag('user.id', userId);
span.setTag('resource.name', 'process-payment');

try {
  // Your operation
  const result = await processPayment();
  span.setTag('payment.success', true);
  return result;
} catch (error) {
  span.setTag('error', true);
  span.setTag('error.message', error.message);
  throw error;
} finally {
  span.finish();
}
```

#### Metrics Collection
```javascript
const StatsD = require('node-statsd');
const client = new StatsD({
  host: 'localhost',
  port: 8125,
  prefix: 'myapp.'
});

// Counter
client.increment('user.signup');
client.increment('api.request', 1, ['endpoint:users', 'method:GET']);

// Gauge
client.gauge('queue.size', queueSize);
client.gauge('memory.usage', process.memoryUsage().heapUsed);

// Histogram
client.histogram('api.response_time', responseTime, ['endpoint:users']);

// Distribution
client.distribution('payment.amount', amount, ['currency:USD']);
```

#### Log Management
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'my-application',
    env: process.env.NODE_ENV
  },
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'app.log' })
  ]
});

// Structured logging
logger.info('User action', {
  userId: user.id,
  action: 'purchase',
  amount: 99.99,
  dd: {
    trace_id: tracer.scope().active()?.context().toTraceId(),
    span_id: tracer.scope().active()?.context().toSpanId()
  }
});
```

#### Infrastructure Monitoring
```yaml
# datadog.yaml
api_key: YOUR_API_KEY
site: datadoghq.com

logs_enabled: true
process_config:
  enabled: true

apm_config:
  enabled: true
  env: production

tags:
  - environment:production
  - team:backend
  - service:api

integrations:
  postgres:
    - host: localhost
      port: 5432
      username: datadog
      password: ${DD_POSTGRES_PASSWORD}
      dbname: myapp
      tags:
        - instance:primary
```

### Best Practices
1. **Use tags consistently** across metrics, logs, and traces
2. **Set up monitors** for critical business metrics
3. **Create dashboards** for different stakeholder groups
4. **Implement SLOs** (Service Level Objectives)
5. **Use APM** for distributed tracing
6. **Enable profiling** for performance optimization
7. **Set up alerting** with appropriate thresholds

## Sentry

### Overview
Sentry provides real-time error tracking and performance monitoring, helping developers identify, triage, and resolve issues faster.

### Documentation
- [Official Documentation](https://docs.sentry.io)
- [SDK Documentation](https://docs.sentry.io/platforms)
- [API Reference](https://docs.sentry.io/api)

### Implementation

#### Basic Setup
```javascript
// Node.js/Express
const Sentry = require('@sentry/node');
const Tracing = require('@sentry/tracing');

Sentry.init({
  dsn: 'YOUR_SENTRY_DSN',
  environment: process.env.NODE_ENV,
  release: process.env.RELEASE_VERSION,
  integrations: [
    new Sentry.Integrations.Http({ tracing: true }),
    new Tracing.Integrations.Express({ app }),
    new Tracing.Integrations.Postgres(),
    new Tracing.Integrations.Redis()
  ],
  tracesSampleRate: 0.1,
  profilesSampleRate: 0.1,
  beforeSend(event, hint) {
    // Filter sensitive data
    if (event.request?.cookies) {
      delete event.request.cookies;
    }
    return event;
  },
  ignoreErrors: [
    'NetworkError',
    'Non-Error promise rejection captured'
  ]
});

// Express middleware
app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());
```

#### Error Handling
```javascript
// Manual error capture
try {
  processPayment(order);
} catch (error) {
  Sentry.captureException(error, {
    tags: {
      section: 'payment',
      payment_provider: 'stripe'
    },
    extra: {
      orderId: order.id,
      amount: order.total
    },
    user: {
      id: user.id,
      email: user.email
    },
    level: 'error'
  });
  throw error;
}

// Breadcrumbs
Sentry.addBreadcrumb({
  message: 'User clicked checkout',
  category: 'ui',
  level: 'info',
  data: {
    cartItems: cart.items.length,
    total: cart.total
  }
});

// Custom context
Sentry.configureScope((scope) => {
  scope.setTag('feature_flag', 'new_checkout');
  scope.setContext('cart', {
    items: cart.items.length,
    total: cart.total
  });
  scope.setUser({
    id: user.id,
    email: user.email,
    subscription: user.subscription
  });
});
```

#### Performance Monitoring
```javascript
// Transaction monitoring
const transaction = Sentry.startTransaction({
  op: 'task',
  name: 'Process Order'
});

Sentry.configureScope(scope => {
  scope.setSpan(transaction);
});

const span = transaction.startChild({
  op: 'db',
  description: 'SELECT FROM orders'
});

try {
  const order = await db.query('SELECT * FROM orders WHERE id = ?', [orderId]);
  span.setStatus('ok');
} catch (error) {
  span.setStatus('internal_error');
  throw error;
} finally {
  span.finish();
  transaction.finish();
}
```

#### Frontend Implementation
```javascript
// React
import * as Sentry from '@sentry/react';
import { BrowserTracing } from '@sentry/tracing';

Sentry.init({
  dsn: 'YOUR_SENTRY_DSN',
  integrations: [
    new BrowserTracing(),
    new Sentry.Replay({
      maskAllText: false,
      blockAllMedia: false
    })
  ],
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0
});

// Error Boundary
const MyApp = () => (
  <Sentry.ErrorBoundary fallback={ErrorFallback} showDialog>
    <App />
  </Sentry.ErrorBoundary>
);

// Performance monitoring
const ProfiledComponent = Sentry.withProfiler(MyComponent);
```

### Best Practices
1. **Filter sensitive data** before sending to Sentry
2. **Use release tracking** for better issue resolution
3. **Set up source maps** for frontend applications
4. **Configure alert rules** for critical errors
5. **Use breadcrumbs** for better error context
6. **Implement performance monitoring** for key transactions
7. **Enable session replay** for user experience issues

## Rollbar

### Overview
Rollbar provides real-time error monitoring and debugging tools, with advanced grouping algorithms and deployment tracking.

### Documentation
- [Official Documentation](https://docs.rollbar.com)
- [API Documentation](https://docs.rollbar.com/reference)
- [SDK Guides](https://docs.rollbar.com/docs)

### Implementation

#### Basic Setup
```javascript
// Node.js
const Rollbar = require('rollbar');

const rollbar = new Rollbar({
  accessToken: 'YOUR_ACCESS_TOKEN',
  environment: process.env.NODE_ENV,
  captureUncaught: true,
  captureUnhandledRejections: true,
  payload: {
    code_version: process.env.GIT_SHA,
    server: {
      host: process.env.HOSTNAME,
      root: process.cwd()
    },
    person: {
      id: user?.id,
      email: user?.email
    }
  },
  scrubFields: ['password', 'token', 'api_key', 'secret'],
  scrubHeaders: ['Authorization', 'Cookie'],
  checkIgnore: (isUncaught, args, payload) => {
    // Ignore specific errors
    return payload.body.trace?.exception?.message?.includes('ETIMEDOUT');
  }
});

// Express middleware
app.use(rollbar.errorHandler());
```

#### Error Tracking
```javascript
// Manual error logging
try {
  riskyOperation();
} catch (error) {
  rollbar.error('Risky operation failed', error, {
    customData: {
      operation: 'data_import',
      fileSize: file.size,
      userId: user.id
    }
  });
  throw error;
}

// Different severity levels
rollbar.critical('Database connection lost', { 
  connectionString: dbConfig.host 
});
rollbar.error('Payment processing failed', error);
rollbar.warning('API rate limit approaching', { 
  remaining: rateLimitRemaining 
});
rollbar.info('User completed onboarding', { userId: user.id });
rollbar.debug('Cache miss', { key: cacheKey });

// Custom fingerprinting
rollbar.configure({
  transform: (payload) => {
    // Group similar errors together
    if (payload.body.trace?.exception?.message?.includes('timeout')) {
      payload.fingerprint = 'timeout-error';
    }
    return payload;
  }
});
```

#### Deployment Tracking
```bash
# Notify Rollbar of deployment
curl https://api.rollbar.com/api/1/deploy/ \
  -F access_token=YOUR_ACCESS_TOKEN \
  -F environment=production \
  -F revision=$(git rev-parse HEAD) \
  -F local_username=$(whoami) \
  -F comment="Deploy version 1.2.3"
```

#### Frontend Implementation
```javascript
// Browser JavaScript
const _rollbarConfig = {
  accessToken: 'YOUR_CLIENT_ACCESS_TOKEN',
  captureUncaught: true,
  captureUnhandledRejections: true,
  payload: {
    environment: 'production',
    client: {
      javascript: {
        source_map_enabled: true,
        code_version: '1.0.0',
        guess_uncaught_frames: true
      }
    }
  },
  scrubTelemetryInputs: true,
  autoInstrument: {
    network: true,
    log: true,
    dom: true,
    navigation: true,
    connectivity: true
  }
};

// React Error Boundary
class ErrorBoundary extends React.Component {
  componentDidCatch(error, errorInfo) {
    Rollbar.error(error, errorInfo);
  }
  
  render() {
    if (this.state.hasError) {
      return <h1>Something went wrong.</h1>;
    }
    return this.props.children;
  }
}
```

### Best Practices
1. **Use semantic versioning** for code_version
2. **Implement custom fingerprinting** for better grouping
3. **Track deployments** for regression detection
4. **Configure person tracking** for user-specific issues
5. **Set up occurrence rate alerts** for anomaly detection
6. **Use telemetry** for detailed error context
7. **Implement source maps** for minified code

## New Relic

### Overview
New Relic provides full-stack observability with APM, infrastructure monitoring, browser monitoring, and synthetic monitoring capabilities.

### Documentation
- [Official Documentation](https://docs.newrelic.com)
- [API Documentation](https://docs.newrelic.com/docs/apis)
- [Agent Documentation](https://docs.newrelic.com/docs/agents)

### Implementation

#### APM Setup
```javascript
// newrelic.js (must be first require in app)
exports.config = {
  app_name: ['My Application'],
  license_key: 'YOUR_LICENSE_KEY',
  logging: {
    level: 'info',
    filepath: 'stdout'
  },
  distributed_tracing: {
    enabled: true
  },
  transaction_tracer: {
    enabled: true,
    transaction_threshold: 'apdex_f',
    record_sql: 'obfuscated',
    explain_threshold: 500
  },
  error_collector: {
    enabled: true,
    ignore_status_codes: [404],
    expected_errors: [
      { class: 'ValidationError' }
    ]
  },
  custom_insights_events: {
    enabled: true,
    max_samples_stored: 3000
  },
  labels: 'environment:production;team:backend'
};

// Application file
require('newrelic');
const express = require('express');
```

#### Custom Instrumentation
```javascript
const newrelic = require('newrelic');

// Custom transactions
function processBackgroundJob(job) {
  return newrelic.startBackgroundTransaction('process-job', () => {
    const transaction = newrelic.getTransaction();
    
    return processJob(job)
      .then(result => {
        transaction.end();
        return result;
      })
      .catch(error => {
        newrelic.noticeError(error);
        transaction.end();
        throw error;
      });
  });
}

// Custom metrics
newrelic.recordMetric('Custom/QueueSize', queue.length);
newrelic.recordMetric('Custom/ProcessingTime', processingTime);

// Custom events
newrelic.recordCustomEvent('OrderProcessed', {
  orderId: order.id,
  amount: order.total,
  itemCount: order.items.length,
  customer: order.customerId,
  paymentMethod: order.paymentMethod
});

// Custom attributes
newrelic.addCustomAttribute('user.subscription', user.subscriptionLevel);
newrelic.addCustomAttribute('feature.flag', featureFlag);
```

#### Browser Monitoring
```javascript
// Server-side injection
app.use((req, res, next) => {
  res.locals.newRelicScript = newrelic.getBrowserTimingHeader();
  next();
});

// In HTML template
// <head>
//   <%- newRelicScript %>
// </head>

// Client-side custom events
if (window.newrelic) {
  newrelic.addPageAction('clickCheckout', {
    cartValue: cart.total,
    itemCount: cart.items.length
  });
  
  newrelic.setCustomAttribute('userType', 'premium');
  newrelic.setErrorHandler((error) => {
    // Custom error handling
    return true; // Prevent default handling
  });
}
```

#### Infrastructure Monitoring
```yaml
# newrelic-infra.yml
license_key: YOUR_LICENSE_KEY
display_name: production-web-01
custom_attributes:
  environment: production
  team: platform
  service: api

integrations:
  - name: nri-redis
    env:
      HOSTNAME: localhost
      PORT: 6379
  
  - name: nri-postgresql
    env:
      USERNAME: newrelic
      PASSWORD: ${DB_PASSWORD}
      DATABASE: myapp
      COLLECTION_LIST: '["postgres", "myapp"]'
```

### Best Practices
1. **Use meaningful transaction names** for better grouping
2. **Implement custom dashboards** for business metrics
3. **Set up alert policies** with multiple conditions
4. **Use distributed tracing** for microservices
5. **Configure browser monitoring** for frontend performance
6. **Implement synthetic monitoring** for uptime checks
7. **Use custom attributes** for detailed filtering

## Common Integration Patterns

### Multi-Tool Setup
```javascript
class MonitoringService {
  constructor() {
    this.sentry = Sentry;
    this.rollbar = new Rollbar(rollbarConfig);
    this.datadog = require('dd-trace').init(datadogConfig);
    this.newrelic = require('newrelic');
  }
  
  captureError(error, context = {}) {
    // Send to multiple providers
    this.sentry.captureException(error, { extra: context });
    this.rollbar.error(error, context);
    this.newrelic.noticeError(error, context);
    
    // Log for Datadog
    logger.error('Application error', {
      error: error.message,
      stack: error.stack,
      ...context
    });
  }
  
  trackMetric(name, value, tags = {}) {
    // Datadog
    statsd.gauge(name, value, tags);
    
    // New Relic
    this.newrelic.recordMetric(`Custom/${name}`, value);
    
    // Custom event for analysis
    this.trackEvent('metric_recorded', {
      metric: name,
      value,
      ...tags
    });
  }
  
  startTransaction(name, operation) {
    const ddSpan = this.datadog.startSpan(name);
    const nrHandle = this.newrelic.startBackgroundTransaction(name);
    const sentryTransaction = this.sentry.startTransaction({ name, op: operation });
    
    return {
      finish: () => {
        ddSpan.finish();
        nrHandle.end();
        sentryTransaction.finish();
      }
    };
  }
}
```

### Unified Alerting
```javascript
class AlertManager {
  async checkThresholds() {
    const metrics = await this.gatherMetrics();
    
    // Check error rate
    if (metrics.errorRate > 0.05) {
      this.createIncident({
        severity: 'high',
        title: 'High error rate detected',
        description: `Error rate: ${metrics.errorRate * 100}%`,
        runbook: 'https://wiki.company.com/runbooks/high-error-rate'
      });
    }
    
    // Check response time
    if (metrics.p95ResponseTime > 1000) {
      this.createIncident({
        severity: 'medium',
        title: 'Slow response times',
        description: `P95: ${metrics.p95ResponseTime}ms`,
        runbook: 'https://wiki.company.com/runbooks/slow-response'
      });
    }
  }
  
  createIncident(incident) {
    // PagerDuty integration
    pagerduty.createIncident(incident);
    
    // Slack notification
    slack.postMessage({
      channel: '#incidents',
      text: `🚨 ${incident.title}`,
      attachments: [{
        color: incident.severity === 'high' ? 'danger' : 'warning',
        fields: [
          { title: 'Description', value: incident.description },
          { title: 'Runbook', value: incident.runbook }
        ]
      }]
    });
  }
}
```

## Best Practices Summary

1. **Consistent Tagging**: Use the same tags across all tools
2. **Correlation IDs**: Track requests across services
3. **Sampling Strategy**: Balance cost with observability
4. **Alert Fatigue**: Set appropriate thresholds
5. **Runbook Links**: Include remediation steps
6. **Cost Management**: Monitor usage and optimize
7. **Data Retention**: Configure based on compliance needs
8. **Team Training**: Ensure team knows how to use tools
9. **Regular Reviews**: Audit monitoring coverage
10. **Automation**: Automate incident response where possible