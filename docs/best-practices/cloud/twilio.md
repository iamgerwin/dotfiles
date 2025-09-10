# Twilio Best Practices

## Overview
Twilio is a cloud communications platform that enables developers to integrate voice, video, messaging, and authentication into applications. These best practices ensure reliable, secure, and scalable Twilio implementations.

## Account Setup and Security

### Account Structure
```
Twilio Account Hierarchy:
├── Main Account
│   ├── Production Subaccount
│   ├── Staging Subaccount
│   └── Development Subaccount
├── API Keys
│   ├── Production Keys
│   ├── CI/CD Keys
│   └── Development Keys
└── Security Settings
    ├── IP Whitelisting
    ├── Webhook Signatures
    └── Audit Logs
```

### Environment Configuration
```javascript
// config/twilio.js
export const twilioConfig = {
  development: {
    accountSid: process.env.TWILIO_DEV_ACCOUNT_SID,
    authToken: process.env.TWILIO_DEV_AUTH_TOKEN,
    apiKey: process.env.TWILIO_DEV_API_KEY,
    apiSecret: process.env.TWILIO_DEV_API_SECRET,
    messagingServiceSid: process.env.TWILIO_DEV_MESSAGING_SERVICE_SID,
    verifyServiceSid: process.env.TWILIO_DEV_VERIFY_SERVICE_SID,
    twimlAppSid: process.env.TWILIO_DEV_TWIML_APP_SID
  },
  production: {
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    apiKey: process.env.TWILIO_API_KEY,
    apiSecret: process.env.TWILIO_API_SECRET,
    messagingServiceSid: process.env.TWILIO_MESSAGING_SERVICE_SID,
    verifyServiceSid: process.env.TWILIO_VERIFY_SERVICE_SID,
    twimlAppSid: process.env.TWILIO_TWIML_APP_SID
  }
};

// Initialize Twilio client
import twilio from 'twilio';

const config = twilioConfig[process.env.NODE_ENV || 'development'];

export const twilioClient = twilio(
  config.apiKey || config.accountSid,
  config.apiSecret || config.authToken,
  {
    accountSid: config.accountSid,
    lazyLoading: true,
    autoRetry: true,
    maxRetries: 3
  }
);
```

## SMS and Messaging

### SMS Service Implementation
```javascript
// services/sms.service.js
import { twilioClient } from '../config/twilio.js';
import logger from '../utils/logger.js';

class SMSService {
  constructor() {
    this.client = twilioClient;
    this.messagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID;
  }

  async sendSMS(to, body, options = {}) {
    try {
      // Validate phone number
      const phoneNumber = await this.validatePhoneNumber(to);
      
      // Check opt-out status
      if (await this.isOptedOut(phoneNumber)) {
        throw new Error('Recipient has opted out of SMS messages');
      }

      // Rate limiting check
      if (await this.isRateLimited(phoneNumber)) {
        throw new Error('Rate limit exceeded for this number');
      }

      const message = await this.client.messages.create({
        to: phoneNumber,
        messagingServiceSid: this.messagingServiceSid,
        body: this.sanitizeMessage(body),
        statusCallback: `${process.env.APP_URL}/webhooks/twilio/sms-status`,
        ...options
      });

      // Log message
      await this.logMessage(message);

      return {
        sid: message.sid,
        status: message.status,
        to: message.to,
        from: message.from,
        dateSent: message.dateSent
      };
    } catch (error) {
      logger.error('SMS send failed', { error, to, body });
      throw this.handleTwilioError(error);
    }
  }

  async sendBulkSMS(recipients, body, options = {}) {
    const chunks = this.chunkArray(recipients, 100); // Twilio recommends 100 messages per batch
    const results = [];

    for (const chunk of chunks) {
      const promises = chunk.map(recipient => 
        this.sendSMS(recipient, body, options).catch(err => ({
          error: err.message,
          recipient
        }))
      );

      const chunkResults = await Promise.allSettled(promises);
      results.push(...chunkResults);

      // Add delay between batches to avoid rate limiting
      await this.delay(1000);
    }

    return {
      successful: results.filter(r => r.status === 'fulfilled').length,
      failed: results.filter(r => r.status === 'rejected').length,
      results
    };
  }

  async validatePhoneNumber(phoneNumber) {
    try {
      const lookup = await this.client.lookups.v2
        .phoneNumbers(phoneNumber)
        .fetch({
          fields: 'line_type_intelligence,caller_name'
        });

      if (!lookup.valid) {
        throw new Error('Invalid phone number');
      }

      // Check if it's a mobile number (can receive SMS)
      if (lookup.lineTypeIntelligence?.type === 'landline') {
        logger.warn('Attempting to send SMS to landline', { phoneNumber });
      }

      return lookup.phoneNumber.nationalFormat;
    } catch (error) {
      throw new Error(`Phone validation failed: ${error.message}`);
    }
  }

  sanitizeMessage(message) {
    // Remove any potential injection attempts
    let sanitized = message.replace(/[<>]/g, '');
    
    // Ensure message length is within limits (1600 characters for SMS)
    if (sanitized.length > 1600) {
      sanitized = sanitized.substring(0, 1597) + '...';
    }

    return sanitized;
  }

  async isOptedOut(phoneNumber) {
    // Check your database for opt-out status
    // This is a placeholder implementation
    const optOutList = await this.getOptOutList();
    return optOutList.includes(phoneNumber);
  }

  async isRateLimited(phoneNumber) {
    // Implement rate limiting logic
    const key = `sms_rate_limit:${phoneNumber}`;
    const count = await redis.incr(key);
    
    if (count === 1) {
      await redis.expire(key, 3600); // 1 hour window
    }

    return count > 10; // Max 10 messages per hour per number
  }

  handleTwilioError(error) {
    const errorMap = {
      21211: 'Invalid phone number',
      21408: 'Permission to send to this region denied',
      21610: 'Message cannot be sent - Recipient opted out',
      21614: 'Invalid mobile number',
      30003: 'Messaging service not found',
      30004: 'Message blocked',
      30005: 'Unknown destination',
      30006: 'Landline or unreachable carrier',
      30007: 'Carrier violation',
      30008: 'Unknown error occurred',
      30009: 'Missing required parameters'
    };

    const message = errorMap[error.code] || error.message || 'Failed to send SMS';
    return new Error(message);
  }

  chunkArray(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async logMessage(message) {
    // Log to database for audit trail
    await db.collection('sms_logs').insertOne({
      sid: message.sid,
      to: message.to,
      from: message.from,
      body: message.body,
      status: message.status,
      price: message.price,
      priceUnit: message.priceUnit,
      errorCode: message.errorCode,
      errorMessage: message.errorMessage,
      dateSent: message.dateSent,
      dateCreated: message.dateCreated
    });
  }
}

export default SMSService;
```

### WhatsApp Integration
```javascript
// services/whatsapp.service.js
class WhatsAppService {
  constructor() {
    this.client = twilioClient;
    this.whatsappNumber = process.env.TWILIO_WHATSAPP_NUMBER;
  }

  async sendWhatsAppMessage(to, body, mediaUrl = null) {
    try {
      const message = {
        from: `whatsapp:${this.whatsappNumber}`,
        to: `whatsapp:${to}`,
        body
      };

      if (mediaUrl) {
        message.mediaUrl = Array.isArray(mediaUrl) ? mediaUrl : [mediaUrl];
      }

      const result = await this.client.messages.create(message);

      return {
        sid: result.sid,
        status: result.status,
        to: result.to
      };
    } catch (error) {
      throw this.handleWhatsAppError(error);
    }
  }

  async sendWhatsAppTemplate(to, templateName, parameters = {}) {
    const templates = {
      order_confirmation: 'Your order {{1}} has been confirmed and will be delivered by {{2}}',
      appointment_reminder: 'Reminder: You have an appointment on {{1}} at {{2}}',
      verification_code: 'Your verification code is {{1}}. Valid for 10 minutes.'
    };

    const template = templates[templateName];
    if (!template) {
      throw new Error(`Template ${templateName} not found`);
    }

    let body = template;
    Object.keys(parameters).forEach((key, index) => {
      body = body.replace(`{{${index + 1}}}`, parameters[key]);
    });

    return this.sendWhatsAppMessage(to, body);
  }

  async sendInteractiveMessage(to, options) {
    const { header, body, footer, buttons } = options;

    const message = {
      from: `whatsapp:${this.whatsappNumber}`,
      to: `whatsapp:${to}`,
      body: body,
      persistentAction: buttons.map(button => ({
        type: 'button',
        text: button.text,
        id: button.id
      }))
    };

    return await this.client.messages.create(message);
  }

  handleWhatsAppError(error) {
    if (error.code === 63016) {
      return new Error('Recipient has not initiated conversation with your WhatsApp number');
    }
    return new Error(`WhatsApp error: ${error.message}`);
  }
}
```

## Voice Calling

### Voice Call Service
```javascript
// services/voice.service.js
class VoiceService {
  constructor() {
    this.client = twilioClient;
    this.twimlAppSid = process.env.TWILIO_TWIML_APP_SID;
  }

  async makeCall(to, from, options = {}) {
    try {
      const call = await this.client.calls.create({
        to,
        from: from || process.env.TWILIO_PHONE_NUMBER,
        url: options.url || `${process.env.APP_URL}/webhooks/twilio/voice`,
        method: 'POST',
        record: options.record || false,
        recordingStatusCallback: options.recordingCallback,
        statusCallback: `${process.env.APP_URL}/webhooks/twilio/call-status`,
        statusCallbackEvent: ['initiated', 'ringing', 'answered', 'completed'],
        statusCallbackMethod: 'POST',
        timeout: options.timeout || 60,
        ...options
      });

      return {
        sid: call.sid,
        status: call.status,
        to: call.to,
        from: call.from,
        duration: call.duration
      };
    } catch (error) {
      throw this.handleVoiceError(error);
    }
  }

  generateTwiML(actions) {
    const VoiceResponse = twilio.twiml.VoiceResponse;
    const response = new VoiceResponse();

    actions.forEach(action => {
      switch (action.type) {
        case 'say':
          response.say({
            voice: action.voice || 'alice',
            language: action.language || 'en-US'
          }, action.text);
          break;

        case 'play':
          response.play({
            loop: action.loop || 1
          }, action.url);
          break;

        case 'gather':
          const gather = response.gather({
            numDigits: action.numDigits || 1,
            timeout: action.timeout || 5,
            action: action.action,
            method: 'POST',
            finishOnKey: action.finishOnKey || '#'
          });
          
          if (action.say) {
            gather.say(action.say);
          }
          break;

        case 'record':
          response.record({
            maxLength: action.maxLength || 60,
            action: action.action,
            method: 'POST',
            transcribe: action.transcribe || false,
            transcribeCallback: action.transcribeCallback
          });
          break;

        case 'dial':
          const dial = response.dial({
            callerId: action.callerId,
            record: action.record || false,
            timeout: action.timeout || 30
          });
          
          if (action.number) {
            dial.number(action.number);
          }
          
          if (action.conference) {
            dial.conference(action.conference);
          }
          break;

        case 'sms':
          response.sms(action.to, action.body);
          break;

        case 'redirect':
          response.redirect({
            method: 'POST'
          }, action.url);
          break;

        case 'hangup':
          response.hangup();
          break;
      }
    });

    return response.toString();
  }

  async createConference(name, options = {}) {
    const conference = await this.client.conferences.create({
      friendlyName: name,
      statusCallback: `${process.env.APP_URL}/webhooks/twilio/conference-status`,
      statusCallbackEvent: ['start', 'end', 'join', 'leave'],
      record: options.record || false,
      ...options
    });

    return conference;
  }

  async transferCall(callSid, to) {
    const call = await this.client.calls(callSid).update({
      twiml: `<Response><Dial>${to}</Dial></Response>`
    });

    return call;
  }

  handleVoiceError(error) {
    const errorMap = {
      21201: 'Invalid phone number',
      21202: 'Invalid URL',
      21203: 'Invalid method',
      21205: 'Call in progress',
      21210: 'Caller phone number not verified',
      21213: 'Caller phone number required',
      21401: 'Invalid phone number (country)',
      21402: 'Invalid phone number (format)'
    };

    const message = errorMap[error.code] || error.message || 'Voice call failed';
    return new Error(message);
  }
}
```

## Video Integration

### Twilio Video Implementation
```javascript
// services/video.service.js
import { jwt } from 'twilio';

class VideoService {
  constructor() {
    this.accountSid = process.env.TWILIO_ACCOUNT_SID;
    this.apiKey = process.env.TWILIO_API_KEY;
    this.apiSecret = process.env.TWILIO_API_SECRET;
  }

  generateAccessToken(identity, roomName, options = {}) {
    const AccessToken = jwt.AccessToken;
    const VideoGrant = AccessToken.VideoGrant;

    // Create access token
    const token = new AccessToken(
      this.accountSid,
      this.apiKey,
      this.apiSecret,
      {
        ttl: options.ttl || 3600, // 1 hour default
        identity: identity
      }
    );

    // Create video grant
    const videoGrant = new VideoGrant({
      room: roomName
    });

    // Add grant to token
    token.addGrant(videoGrant);

    return {
      token: token.toJwt(),
      identity,
      roomName,
      expiresAt: new Date(Date.now() + (options.ttl || 3600) * 1000)
    };
  }

  async createRoom(uniqueName, options = {}) {
    try {
      const room = await twilioClient.video.rooms.create({
        uniqueName,
        type: options.type || 'group', // 'peer-to-peer', 'group', 'group-small'
        maxParticipants: options.maxParticipants || 50,
        recordParticipantsOnConnect: options.record || false,
        statusCallback: `${process.env.APP_URL}/webhooks/twilio/room-status`,
        statusCallbackMethod: 'POST',
        mediaRegion: options.region || 'us1'
      });

      return {
        sid: room.sid,
        name: room.uniqueName,
        status: room.status,
        type: room.type,
        maxParticipants: room.maxParticipants,
        url: room.url
      };
    } catch (error) {
      if (error.code === 53113) {
        // Room already exists
        return this.getRoom(uniqueName);
      }
      throw error;
    }
  }

  async getRoom(roomNameOrSid) {
    const room = await twilioClient.video.rooms(roomNameOrSid).fetch();
    return room;
  }

  async completeRoom(roomSid) {
    const room = await twilioClient.video.rooms(roomSid).update({
      status: 'completed'
    });
    return room;
  }

  async listParticipants(roomSid) {
    const participants = await twilioClient.video
      .rooms(roomSid)
      .participants
      .list();

    return participants.map(p => ({
      sid: p.sid,
      identity: p.identity,
      status: p.status,
      startTime: p.startTime,
      endTime: p.endTime,
      duration: p.duration
    }));
  }

  async getRecordings(roomSid) {
    const recordings = await twilioClient.video
      .rooms(roomSid)
      .recordings
      .list();

    return recordings.map(r => ({
      sid: r.sid,
      status: r.status,
      type: r.type,
      size: r.size,
      duration: r.duration,
      url: r.links.media
    }));
  }

  async kickParticipant(roomSid, participantSid) {
    await twilioClient.video
      .rooms(roomSid)
      .participants(participantSid)
      .update({ status: 'disconnected' });
  }
}
```

## Authentication with Verify

### Two-Factor Authentication
```javascript
// services/verify.service.js
class VerifyService {
  constructor() {
    this.client = twilioClient;
    this.verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
  }

  async sendVerification(to, channel = 'sms', options = {}) {
    try {
      const verification = await this.client.verify.v2
        .services(this.verifyServiceSid)
        .verifications
        .create({
          to,
          channel, // 'sms', 'call', 'email', 'whatsapp'
          locale: options.locale || 'en',
          customFriendlyName: options.friendlyName,
          customMessage: options.customMessage,
          channelConfiguration: options.channelConfiguration
        });

      return {
        sid: verification.sid,
        to: verification.to,
        channel: verification.channel,
        status: verification.status,
        valid: verification.valid
      };
    } catch (error) {
      throw this.handleVerifyError(error);
    }
  }

  async checkVerification(to, code) {
    try {
      const verificationCheck = await this.client.verify.v2
        .services(this.verifyServiceSid)
        .verificationChecks
        .create({
          to,
          code
        });

      return {
        status: verificationCheck.status,
        valid: verificationCheck.valid,
        to: verificationCheck.to,
        channel: verificationCheck.channel
      };
    } catch (error) {
      throw this.handleVerifyError(error);
    }
  }

  async sendPushVerification(identity, factorSid) {
    const challenge = await this.client.verify.v2
      .services(this.verifyServiceSid)
      .entities(identity)
      .challenges
      .create({
        factorSid,
        expirationDate: new Date(Date.now() + 5 * 60000) // 5 minutes
      });

    return challenge;
  }

  async createAccessToken(identity, factorType = 'push') {
    const AccessToken = jwt.AccessToken;
    const ChatGrant = AccessToken.ChatGrant;

    const token = new AccessToken(
      this.accountSid,
      this.apiKey,
      this.apiSecret,
      {
        identity: identity
      }
    );

    const grant = new ChatGrant({
      serviceSid: this.verifyServiceSid,
      pushCredentialSid: process.env.TWILIO_PUSH_CREDENTIAL_SID
    });

    token.addGrant(grant);

    return token.toJwt();
  }

  async createTOTPFactor(identity, friendlyName) {
    const newFactor = await this.client.verify.v2
      .services(this.verifyServiceSid)
      .entities(identity)
      .newFactors
      .create({
        friendlyName,
        factorType: 'totp'
      });

    return {
      sid: newFactor.sid,
      identity: newFactor.identity,
      binding: newFactor.binding,
      config: newFactor.config
    };
  }

  handleVerifyError(error) {
    const errorMap = {
      60200: 'Invalid verification code',
      60202: 'Max verification attempts reached',
      60203: 'Max send attempts reached',
      60204: 'Service not found',
      60205: 'SMS is not supported for landline phone number',
      60212: 'Too many concurrent requests'
    };

    const message = errorMap[error.code] || error.message || 'Verification failed';
    return new Error(message);
  }
}
```

## Webhook Security

### Webhook Validation
```javascript
// middleware/twilio-webhook.middleware.js
import twilio from 'twilio';

export const validateTwilioWebhook = (req, res, next) => {
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const signature = req.headers['x-twilio-signature'];
  const url = `${req.protocol}://${req.get('host')}${req.originalUrl}`;

  // Get the request body for validation
  const params = req.body || {};

  // Validate the request
  const isValid = twilio.validateRequest(
    authToken,
    signature,
    url,
    params
  );

  if (!isValid) {
    logger.warn('Invalid Twilio webhook signature', {
      url,
      signature,
      ip: req.ip
    });
    
    return res.status(403).json({
      error: 'Invalid signature'
    });
  }

  next();
};

// Webhook handlers
export const handleSMSWebhook = async (req, res) => {
  const { MessageSid, MessageStatus, ErrorCode, ErrorMessage } = req.body;

  try {
    // Update message status in database
    await db.collection('sms_logs').updateOne(
      { sid: MessageSid },
      {
        $set: {
          status: MessageStatus,
          errorCode: ErrorCode,
          errorMessage: ErrorMessage,
          updatedAt: new Date()
        }
      }
    );

    // Handle specific statuses
    switch (MessageStatus) {
      case 'delivered':
        await handleDelivered(MessageSid);
        break;
      case 'failed':
      case 'undelivered':
        await handleFailed(MessageSid, ErrorCode, ErrorMessage);
        break;
    }

    res.status(200).send('OK');
  } catch (error) {
    logger.error('Webhook processing failed', { error, body: req.body });
    res.status(500).send('Error');
  }
};
```

## Error Handling and Retry Logic

### Resilient Service Wrapper
```javascript
// utils/twilio-resilient.js
class ResilientTwilioService {
  constructor(service, options = {}) {
    this.service = service;
    this.maxRetries = options.maxRetries || 3;
    this.retryDelay = options.retryDelay || 1000;
    this.backoffMultiplier = options.backoffMultiplier || 2;
  }

  async executeWithRetry(operation, ...args) {
    let lastError;
    let delay = this.retryDelay;

    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        return await operation.apply(this.service, args);
      } catch (error) {
        lastError = error;
        
        // Don't retry on certain errors
        if (this.isNonRetryableError(error)) {
          throw error;
        }

        logger.warn(`Attempt ${attempt} failed, retrying...`, {
          error: error.message,
          attempt,
          maxRetries: this.maxRetries
        });

        if (attempt < this.maxRetries) {
          await this.delay(delay);
          delay *= this.backoffMultiplier;
        }
      }
    }

    throw lastError;
  }

  isNonRetryableError(error) {
    const nonRetryableCodes = [
      21211, // Invalid phone number
      21614, // Invalid mobile number
      21610, // Recipient opted out
      30003, // Service not found
      60200, // Invalid verification code
    ];

    return nonRetryableCodes.includes(error.code);
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Cost Optimization

### Usage Monitoring
```javascript
// services/usage-monitor.service.js
class TwilioUsageMonitor {
  constructor() {
    this.client = twilioClient;
  }

  async getUsageRecords(options = {}) {
    const {
      category = 'totalprice',
      startDate = new Date(new Date().setDate(1)), // First day of month
      endDate = new Date()
    } = options;

    const records = await this.client.usage.records.list({
      category,
      startDate,
      endDate
    });

    return records.map(record => ({
      category: record.category,
      description: record.description,
      usage: record.usage,
      usageUnit: record.usageUnit,
      price: record.price,
      priceUnit: record.priceUnit,
      startDate: record.startDate,
      endDate: record.endDate
    }));
  }

  async setUsageAlert(threshold, webhookUrl) {
    const trigger = await this.client.usage.triggers.create({
      usageCategory: 'totalprice',
      triggerValue: threshold,
      callbackUrl: webhookUrl,
      callbackMethod: 'POST',
      friendlyName: `Usage alert at $${threshold}`,
      recurring: 'monthly'
    });

    return trigger;
  }

  async estimateMonthlyCost() {
    const currentMonth = new Date().getMonth();
    const daysInMonth = new Date(new Date().getFullYear(), currentMonth + 1, 0).getDate();
    const daysPassed = new Date().getDate();
    
    const usage = await this.getUsageRecords();
    const totalCost = usage.reduce((sum, record) => sum + parseFloat(record.price), 0);
    
    const estimatedMonthly = (totalCost / daysPassed) * daysInMonth;
    
    return {
      currentCost: totalCost,
      estimatedMonthly,
      daysRemaining: daysInMonth - daysPassed
    };
  }
}
```

## Testing

### Mock Twilio for Testing
```javascript
// test/mocks/twilio.mock.js
export class TwilioMock {
  constructor() {
    this.messages = {
      create: jest.fn().mockResolvedValue({
        sid: 'SM' + Math.random().toString(36).substr(2, 32),
        status: 'sent',
        to: '+1234567890',
        from: '+0987654321',
        body: 'Test message',
        dateSent: new Date()
      })
    };

    this.calls = {
      create: jest.fn().mockResolvedValue({
        sid: 'CA' + Math.random().toString(36).substr(2, 32),
        status: 'initiated',
        to: '+1234567890',
        from: '+0987654321'
      })
    };

    this.verify = {
      v2: {
        services: () => ({
          verifications: {
            create: jest.fn().mockResolvedValue({
              sid: 'VE' + Math.random().toString(36).substr(2, 32),
              status: 'pending',
              valid: false
            })
          },
          verificationChecks: {
            create: jest.fn().mockResolvedValue({
              status: 'approved',
              valid: true
            })
          }
        })
      }
    };
  }
}

// Test implementation
describe('SMS Service', () => {
  let smsService;
  let twilioMock;

  beforeEach(() => {
    twilioMock = new TwilioMock();
    smsService = new SMSService();
    smsService.client = twilioMock;
  });

  test('should send SMS successfully', async () => {
    const result = await smsService.sendSMS('+1234567890', 'Test message');
    
    expect(twilioMock.messages.create).toHaveBeenCalledWith(
      expect.objectContaining({
        to: '+1234567890',
        body: 'Test message'
      })
    );
    
    expect(result).toHaveProperty('sid');
    expect(result.status).toBe('sent');
  });

  test('should handle rate limiting', async () => {
    smsService.isRateLimited = jest.fn().mockResolvedValue(true);
    
    await expect(
      smsService.sendSMS('+1234567890', 'Test')
    ).rejects.toThrow('Rate limit exceeded');
  });
});
```

## Best Practices Summary

1. **Use Subaccounts**: Separate environments with subaccounts
2. **Implement Webhook Security**: Always validate webhook signatures
3. **Handle Errors Gracefully**: Implement comprehensive error handling
4. **Rate Limiting**: Implement rate limiting to avoid abuse
5. **Phone Number Validation**: Validate numbers before sending
6. **Opt-Out Management**: Respect user preferences
7. **Cost Monitoring**: Monitor usage and set alerts
8. **Retry Logic**: Implement exponential backoff for retries
9. **Logging and Auditing**: Log all communications for compliance
10. **Testing**: Use mocks for testing without incurring costs

## Conclusion

Twilio provides powerful communication capabilities for applications. Following these best practices ensures reliable, secure, and cost-effective implementations while maintaining compliance and user trust.