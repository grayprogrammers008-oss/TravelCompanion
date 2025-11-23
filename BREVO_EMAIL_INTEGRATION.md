# 📧 Brevo Email Integration Guide

**Status:** ✅ Fully Integrated and Tested
**Date:** November 15, 2025
**Email Service:** Brevo (SendinBlue)

---

## Overview

TravelCompanion now uses **Brevo (formerly SendinBlue)** for sending transactional emails including trip invitations, notifications, and other user communications.

### Why Brevo?

- ✅ **300 free emails/day** on free plan
- ✅ **Professional SMTP service** with high deliverability
- ✅ **Simple REST API** (v3)
- ✅ **Real-time email tracking** and analytics
- ✅ **Template management** in dashboard
- ✅ **No credit card required** for free tier

---

## Current Configuration

### Account Details
- **Email:** palkarfoods224@gmail.com
- **Company:** palkarfoods
- **Plan:** Free (300 emails/day)
- **Verified Sender:** palkarfoods224@gmail.com

### API Configuration
Location: [lib/core/config/supabase_config.dart](lib/core/config/supabase_config.dart)

```dart
static const String brevoApiKey = String.fromEnvironment(
  'BREVO_API_KEY',
  defaultValue: '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',
);

static const String brevoSenderEmail = String.fromEnvironment(
  'BREVO_SENDER_EMAIL',
  defaultValue: 'palkarfoods224@gmail.com',
);

static const String brevoSenderName = String.fromEnvironment(
  'BREVO_SENDER_NAME',
  defaultValue: 'TravelCompanion',
);
```

---

## Email Service Implementation

### Location
[lib/core/services/email_service.dart](lib/core/services/email_service.dart)

### Features

#### 1. Test Connection
```dart
final emailService = EmailService();
final isConnected = await emailService.testConnection();

if (isConnected) {
  print('✅ Brevo API is working!');
}
```

#### 2. Send Trip Invitation
```dart
await emailService.sendTripInvite(
  toEmail: 'friend@example.com',
  toName: 'John Doe',
  tripName: 'Bali Adventure 2024',
  inviterName: 'Jane Smith',
  inviteCode: 'ABC123',
  tripDestination: 'Bali, Indonesia',
  tripStartDate: 'Dec 15, 2024',
  tripEndDate: 'Dec 22, 2024',
);
```

**Email Preview:**
- Beautiful HTML template with Brilliant theme gradient (#7B5FE8 → #5234B8)
- Responsive design for mobile/desktop
- Deep link button: `travelcompanion://invite/{inviteCode}`
- Fallback plain text version included
- Professional branding with TravelCompanion logo

#### 3. Send Generic Email
```dart
await emailService.sendEmail(
  toEmail: 'user@example.com',
  subject: 'Welcome to TravelCompanion!',
  htmlContent: '<h1>Welcome!</h1><p>Thanks for joining.</p>',
  textContent: 'Welcome! Thanks for joining.',
  toName: 'User Name',
);
```

#### 4. Send Bulk Email
```dart
await emailService.sendBulkEmail(
  toEmails: ['user1@example.com', 'user2@example.com'],
  subject: 'Trip Update',
  htmlContent: '<h1>Trip Update</h1><p>Your trip has been updated.</p>',
);
```

---

## Email Template Features

### Trip Invitation Email

#### Visual Design
- **Header:** Brilliant purple gradient with TravelCompanion branding
- **Content:** Clean white card with trip details
- **Invite Code:** Large, highlighted code in dashed border box
- **CTA Button:** Gradient button with shadow effect
- **Footer:** Subtle gray with sender attribution

#### Information Displayed
1. Recipient's name (personalized greeting)
2. Inviter's name
3. Trip name (prominent heading)
4. Trip destination (optional, with 📍 icon)
5. Trip dates (optional, with 📅 icon)
6. Invite code (large, copy-friendly format)
7. Deep link button for easy acceptance
8. App store links for new users

#### Deep Linking
```
travelcompanion://invite/{inviteCode}
```
When user taps "Accept Invitation" in email, app opens directly to invite acceptance screen.

---

## Testing

### Test Suite
Location: [test/core/services/email_service_test.dart](test/core/services/email_service_test.dart)

### Run Tests
```bash
# Test connection
flutter test test/core/services/email_service_test.dart --plain-name="testConnection"

# Test trip invitation
flutter test test/core/services/email_service_test.dart --plain-name="sendTripInvite"

# Test all email functionality
flutter test test/core/services/email_service_test.dart
```

### Manual Testing Script
Location: [scripts/test_brevo_sender.dart](scripts/test_brevo_sender.dart)

```bash
dart run scripts/test_brevo_sender.dart
```

**Output:**
```
✅ Account Information:
   Email: palkarfoods224@gmail.com
   Company: palkarfoods
   Plan: [{type: free, credits: 300, creditsType: sendLimit}]

📧 Configured Senders:
   - palkarfoods <palkarfoods224@gmail.com>
     Active: true

✅ Email sent successfully!
   Message ID: <202511151905.84750455042@smtp-relay.mailin.fr>
```

---

## API Reference

### Brevo API v3

**Base URL:** `https://api.brevo.com/v3`

#### Endpoints Used

1. **GET /account**
   - Check account info and remaining credits
   - Headers: `api-key`, `Accept: application/json`

2. **GET /senders**
   - List verified sender emails
   - Headers: `api-key`, `Accept: application/json`

3. **POST /smtp/email**
   - Send transactional email
   - Headers: `api-key`, `Content-Type: application/json`, `Accept: application/json`
   - Success: `201 Created`
   - Response: `{"messageId": "<unique-id>"}`

#### Request Format
```json
{
  "sender": {
    "name": "TravelCompanion",
    "email": "palkarfoods224@gmail.com"
  },
  "to": [
    {
      "email": "recipient@example.com",
      "name": "Recipient Name"
    }
  ],
  "subject": "Email Subject",
  "htmlContent": "<html>...</html>",
  "textContent": "Plain text version..."
}
```

---

## Environment Variables

### .env File Setup

Create a `.env` file (not committed to git):

```env
# Brevo Email Service
BREVO_API_KEY=xkeysib-your-api-key-here
BREVO_SENDER_EMAIL=your-verified-email@domain.com
BREVO_SENDER_NAME=TravelCompanion
```

### Using Environment Variables

```bash
# Run with custom sender
flutter run --dart-define=BREVO_SENDER_EMAIL=custom@domain.com

# Build with environment variables
flutter build apk \
  --dart-define=BREVO_API_KEY=your-key \
  --dart-define=BREVO_SENDER_EMAIL=your-email
```

---

## Migration from Mailgun

### What Changed

#### Configuration
- ❌ Removed: `mailgunApiKey`, `mailgunDomain`, `mailgunFromEmail`
- ✅ Added: `brevoApiKey`, `brevoSenderEmail`, `brevoSenderName`

#### API Endpoint
- ❌ Old: `https://api.mailgun.net/v3/{domain}/messages`
- ✅ New: `https://api.brevo.com/v3/smtp/email`

#### Authentication
- ❌ Old: Basic Auth with `api:key`
- ✅ New: Header `api-key: {key}`

#### Success Response
- ❌ Old: `200 OK`
- ✅ New: `201 Created`

#### Backup
Old Mailgun implementation backed up to:
`lib/core/services/email_service.dart.mailgun.backup`

---

## Dashboard & Monitoring

### Brevo Dashboard
🔗 https://app.brevo.com

#### Key Sections

1. **Dashboard**
   - Email statistics
   - Recent emails sent
   - Credit usage

2. **Campaigns > Transactional**
   - View all sent emails
   - Track opens, clicks, bounces
   - Real-time delivery status

3. **Settings > Senders**
   - Manage verified sender emails
   - Add new senders (requires verification)

4. **Settings > SMTP & API**
   - View API keys
   - Generate new keys
   - Monitor API usage

---

## Error Handling

### Common Errors

#### 1. Unverified Sender
**Error:** `{"message": "Sender email not verified"}`

**Solution:**
1. Go to [Brevo Senders](https://app.brevo.com/settings/senders)
2. Add and verify your sender email
3. Update `brevoSenderEmail` in config

#### 2. Daily Limit Reached
**Error:** `{"message": "Daily sending limit exceeded"}`

**Solution:**
- Free plan: 300 emails/day
- Upgrade to paid plan for higher limits
- Or wait until next day (resets at midnight UTC)

#### 3. Invalid API Key
**Error:** `{"message": "Invalid API key"}`

**Solution:**
1. Check API key in [Brevo SMTP & API](https://app.brevo.com/settings/keys/api)
2. Generate new key if needed
3. Update `brevoApiKey` in config

---

## Usage in Features

### Trip Invitations
Location: `lib/features/trips/presentation/pages/invite_members_page.dart`

```dart
final emailService = EmailService();

await emailService.sendTripInvite(
  toEmail: memberEmail,
  toName: memberName,
  tripName: trip.name,
  inviterName: currentUser.name,
  inviteCode: invite.code,
  tripDestination: trip.destination,
  tripStartDate: trip.startDate,
  tripEndDate: trip.endDate,
);
```

### Future Use Cases
- Password reset emails
- Trip update notifications
- Checklist reminder emails
- Group messaging digests
- Welcome emails for new users
- Trip summary reports

---

## Best Practices

### 1. Email Content
- ✅ Always provide both HTML and plain text versions
- ✅ Use responsive HTML templates
- ✅ Include clear call-to-action buttons
- ✅ Add unsubscribe links (for marketing emails)
- ✅ Keep subject lines under 50 characters

### 2. Sender Reputation
- ✅ Use verified sender emails only
- ✅ Avoid spam trigger words in subject/content
- ✅ Monitor bounce rates and complaints
- ✅ Implement proper email validation before sending

### 3. Performance
- ✅ Use bulk email API for multiple recipients
- ✅ Handle errors gracefully with retries
- ✅ Log email sending for debugging
- ✅ Monitor API usage to stay within limits

### 4. Security
- ✅ Never expose API keys in client-side code
- ✅ Use environment variables for sensitive data
- ✅ Validate email addresses before sending
- ✅ Implement rate limiting to prevent abuse

---

## Monitoring & Analytics

### Track Email Performance

```dart
// In Brevo dashboard, track:
- Delivery rate (should be > 95%)
- Open rate (industry average: 20-30%)
- Click rate (industry average: 2-5%)
- Bounce rate (should be < 2%)
- Spam complaint rate (should be < 0.1%)
```

### Debug Mode Logging

Email service includes debug logging:

```dart
if (kDebugMode) {
  debugPrint('✅ Trip invitation email sent to $toEmail');
  debugPrint('Message ID: ${responseData['messageId']}');
}
```

---

## Upgrade Options

### Free Plan Limitations
- 300 emails/day
- Brevo branding in emails
- Basic statistics

### Paid Plans
- **Lite:** Starting at $25/month
  - 10,000 emails/month
  - Remove Brevo branding
  - Advanced statistics

- **Business:** Starting at $65/month
  - 20,000 emails/month
  - Marketing automation
  - A/B testing

🔗 [View Pricing](https://www.brevo.com/pricing/)

---

## Support & Resources

### Official Documentation
- 📚 [Brevo API Docs](https://developers.brevo.com/docs)
- 📚 [SMTP API Reference](https://developers.brevo.com/reference/sendtransacemail)
- 📚 [API Authentication](https://developers.brevo.com/docs/getting-started)

### TravelCompanion Resources
- 📄 Email Service: [lib/core/services/email_service.dart](lib/core/services/email_service.dart)
- 📄 Configuration: [lib/core/config/supabase_config.dart](lib/core/config/supabase_config.dart)
- 📄 Tests: [test/core/services/email_service_test.dart](test/core/services/email_service_test.dart)
- 📄 Test Script: [scripts/test_brevo_sender.dart](scripts/test_brevo_sender.dart)

### Contact
- 💬 Brevo Support: https://help.brevo.com
- 📧 Email: support@brevo.com

---

## Changelog

### v1.0.0 - November 15, 2025
- ✅ Initial Brevo integration
- ✅ Migrated from Mailgun to Brevo
- ✅ Trip invitation email template
- ✅ Test suite and validation script
- ✅ Documentation complete
- ✅ All tests passing

---

**Status: Production Ready ✅**

*Last Updated: November 15, 2025*
