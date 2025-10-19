# Mailgun Email Service Setup Guide

This guide will help you configure Mailgun for sending trip invitation emails in the Travel Crew app.

## 📧 What is Mailgun?

Mailgun is a powerful email delivery service that allows the app to send beautiful, professional trip invitation emails to your friends and family.

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Get Your Mailgun Domain

You'll need to provide your **Mailgun domain** to complete the setup. Your API key is already configured:

**API Key**: ✅ `a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0` (Already added)

**What you need**:
- Mailgun Domain (e.g., `mg.yourdomain.com` or `sandbox123.mailgun.org`)
- From Email Address (e.g., `Travel Crew <noreply@mg.yourdomain.com>`)

---

### Step 2: Configure the Domain

Open `lib/core/config/supabase_config.dart` and update the Mailgun configuration:

```dart
/// Mailgun API Configuration for Email Invites
static const String mailgunApiKey = String.fromEnvironment(
  'MAILGUN_API_KEY',
  defaultValue: 'a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0', // ✅ Already configured
);

static const String mailgunDomain = String.fromEnvironment(
  'MAILGUN_DOMAIN',
  defaultValue: 'YOUR_MAILGUN_DOMAIN_HERE', // ⚠️ UPDATE THIS
);

static const String mailgunFromEmail = String.fromEnvironment(
  'MAILGUN_FROM_EMAIL',
  defaultValue: 'Travel Crew <noreply@mg.yourdomain.com>', // ⚠️ UPDATE THIS
);
```

**Example**:
```dart
defaultValue: 'mg.travelcrew.com', // Your Mailgun domain
defaultValue: 'Travel Crew <noreply@mg.travelcrew.com>', // Your from email
```

---

### Step 3: Test the Email Service

The email service is automatically integrated with the trip invite feature. To test:

1. **Create a trip** in the app
2. **Invite a friend** using their email address
3. **Check the console** for email sending status:
   - ✅ `Trip invitation email sent to user@example.com` - Success!
   - ❌ `Failed to send email` - Check your configuration

---

## 📋 Configuration Reference

### Option 1: Direct Configuration (Recommended for Development)

Edit `lib/core/config/supabase_config.dart`:

```dart
static const String mailgunDomain = String.fromEnvironment(
  'MAILGUN_DOMAIN',
  defaultValue: 'mg.yourdomain.com', // Your actual domain
);
```

### Option 2: Environment Variables (Recommended for Production)

Create a `.env` file in the project root:

```bash
# Copy from .env.example
cp .env.example .env
```

Edit `.env`:
```env
MAILGUN_API_KEY=a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0
MAILGUN_DOMAIN=mg.yourdomain.com
MAILGUN_FROM_EMAIL=Travel Crew <noreply@mg.yourdomain.com>
```

Run the app with environment variables:
```bash
flutter run --dart-define=MAILGUN_DOMAIN=mg.yourdomain.com \
            --dart-define=MAILGUN_FROM_EMAIL="Travel Crew <noreply@mg.yourdomain.com>"
```

---

## 🎨 Email Template Preview

The trip invitation emails include:

✨ **Premium Design Features**:
- Beautiful gradient header with Travel Crew branding
- Trip details card with destination and dates
- Highlighted invite code in a dashed border box
- Glossy CTA button with deep link to the app
- Responsive design (works on all devices)
- Professional footer

📧 **Email Content**:
- Personal greeting with invitee's name
- Inviter's name and trip details
- Unique 6-character invite code
- Deep link to open the app directly
- Fallback plain text version

---

## 🔧 Advanced Configuration

### Custom Email Templates

To customize the email template, edit `lib/core/services/email_service.dart`:

```dart
String _buildInviteEmailHtml({...}) {
  // Customize your HTML email template here
  return '''<!DOCTYPE html>...''';
}
```

### Sending Test Emails

```dart
import 'package:travel_crew/core/services/email_service.dart';

final emailService = EmailService();

await emailService.sendTripInvite(
  toEmail: 'test@example.com',
  toName: 'Test User',
  tripName: 'Bali Adventure 2024',
  inviterName: 'You',
  inviteCode: 'ABC123',
  tripDestination: 'Bali, Indonesia',
  tripStartDate: '2024-12-01',
  tripEndDate: '2024-12-10',
);
```

---

## 📊 Email Service Features

### Automatic Features
- ✅ HTML email with fallback plain text
- ✅ Responsive design (mobile & desktop)
- ✅ Deep linking to app
- ✅ Professional branding
- ✅ Error handling and logging
- ✅ Configuration validation

### Future Enhancements
- 📅 Trip reminder emails
- 🎉 Trip confirmation emails
- 💰 Expense settlement notifications
- 📝 Daily itinerary summaries

---

## 🐛 Troubleshooting

### Issue: "Mailgun not configured" warning

**Solution**: Update the `mailgunDomain` in `supabase_config.dart` with your actual Mailgun domain.

```dart
defaultValue: 'mg.yourdomain.com', // Replace with your domain
```

### Issue: "Failed to send email" error

**Possible causes**:
1. **Invalid domain**: Check that your Mailgun domain is correct
2. **API key mismatch**: Verify the API key matches your Mailgun account
3. **Sandbox restrictions**: If using sandbox domain, add recipient to authorized list in Mailgun dashboard
4. **Network error**: Check internet connection

**Debug steps**:
1. Check Flutter console for detailed error messages
2. Verify API key and domain in Mailgun dashboard
3. Test with curl:
```bash
curl -s --user 'api:YOUR_API_KEY' \
  https://api.mailgun.net/v3/YOUR_DOMAIN/messages \
  -F from='Test <test@YOUR_DOMAIN>' \
  -F to='you@example.com' \
  -F subject='Test Email' \
  -F text='Testing Mailgun'
```

### Issue: Emails going to spam

**Solutions**:
- Set up SPF, DKIM, and DMARC records in your domain DNS
- Use a verified sending domain (not sandbox)
- Add "Travel Crew" to sender name
- Avoid spam trigger words in subject/body

---

## 📚 Additional Resources

- **Mailgun Documentation**: https://documentation.mailgun.com
- **Email Service Code**: `lib/core/services/email_service.dart`
- **Configuration File**: `lib/core/config/supabase_config.dart`
- **Environment Template**: `.env.example`

---

## ✅ Checklist

- [x] Mailgun API key configured (`a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0`)
- [ ] Mailgun domain configured
- [ ] From email address configured
- [ ] Test email sent successfully
- [ ] Deep links working (opens app)
- [ ] Emails not going to spam

---

## 🎉 You're All Set!

Once configured, the Travel Crew app will automatically send beautiful invitation emails whenever you invite friends to your trips. No additional code needed!

**Questions?** Check the troubleshooting section above or review the email service implementation in `lib/core/services/email_service.dart`.

---

**Last Updated**: 2025-10-19
**Email Service Version**: 1.0.0
