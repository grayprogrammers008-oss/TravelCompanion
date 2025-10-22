# Mailgun Sandbox Domain - Authorization Required

## 🚨 Issue Found

Your Mailgun account is using a **sandbox domain** (free tier) which restricts sending emails.

**Error Message**:
```
Domain sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org is not allowed to send:
Free accounts are for test purposes only.
Please upgrade or add the address to your authorized recipients.
```

**HTTP Status**: 403 Forbidden

---

## ✅ Solution 1: Authorize Recipients (Free - Recommended for Testing)

### Step-by-Step Guide

1. **Login to Mailgun Dashboard**
   - Go to: https://app.mailgun.com/
   - Use your Mailgun credentials

2. **Navigate to Your Domain**
   - Click "Sending" in the left sidebar
   - Click "Domains"
   - Select: `sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org`

3. **Add Authorized Recipients**
   - Scroll down to "Authorized Recipients" section
   - Click "Add Recipient"
   - Enter email address: `vinothvsbe@gmail.com`
   - Click "Add"

4. **Confirm Authorization**
   - Check the inbox of `vinothvsbe@gmail.com`
   - Look for an email from Mailgun
   - Click the confirmation link in the email
   - The email address is now authorized!

5. **Test Again**
   - Run the test command below
   - Or use the app to send an invite

### Test Command

```bash
curl --user 'api:a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0' \
  https://api.mailgun.net/v3/sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org/messages \
  -F from='Travel Crew <postmaster@sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org>' \
  -F to='vinothvsbe@gmail.com' \
  -F subject='🎉 Test from Travel Crew' \
  -F text='Test email from Travel Crew app!'
```

**Expected Response** (after authorization):
```json
{
  "id": "<someID@sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org>",
  "message": "Queued. Thank you."
}
```

---

## ✅ Solution 2: Upgrade to Paid Plan (Recommended for Production)

### Benefits of Upgrading

- ✅ Send to **any email address** (no authorization needed)
- ✅ Use a **custom domain** (e.g., `mg.travelcrew.com`)
- ✅ Higher sending limits
- ✅ Better deliverability
- ✅ Professional appearance

### Steps to Upgrade

1. **Go to Billing**
   - https://app.mailgun.com/account/billing

2. **Choose a Plan**
   - **Foundation**: $35/month - Good for small apps
   - **Growth**: Custom pricing - For larger scale

3. **Add a Custom Domain** (optional but recommended)
   - Go to "Sending" → "Domains"
   - Click "Add New Domain"
   - Enter your domain (e.g., `mg.travelcrew.com`)
   - Follow DNS setup instructions

4. **Update Configuration**
   - Edit `lib/core/config/supabase_config.dart`
   - Replace sandbox domain with your custom domain:
   ```dart
   defaultValue: 'mg.travelcrew.com',
   defaultValue: 'Travel Crew <noreply@mg.travelcrew.com>',
   ```

---

## 📊 Current Configuration

**Your Mailgun Settings**:
- ✅ **API Key**: `a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0`
- ✅ **Domain**: `sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org` (sandbox)
- ✅ **From Email**: `postmaster@sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org`
- ⚠️ **Status**: Requires recipient authorization

**Already Configured in App**:
- ✅ `lib/core/config/supabase_config.dart` - Updated with domain
- ✅ `lib/core/services/email_service.dart` - Email service ready
- ✅ `.gitignore` - Environment files excluded
- ✅ `.env.example` - Template provided
- ✅ `MAILGUN_SETUP.md` - Full documentation

---

## 🧪 Quick Test (After Authorization)

### Option 1: Using curl

```bash
# Test sending to your authorized email
curl --user 'api:a90e871ea23589e2e548d10cd52a4c02-5e1ffd43-ac389ec0' \
  https://api.mailgun.net/v3/sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org/messages \
  -F from='Travel Crew <postmaster@sandboxea0ac54e12f242219a426c2219f44e12.mailgun.org>' \
  -F to='vinothvsbe@gmail.com' \
  -F subject='🎉 Travel Crew Test Email' \
  -F html='<h1>Success!</h1><p>Your Mailgun integration is working!</p>'
```

### Option 2: Using the App

1. Run the Travel Crew app
2. Create a trip
3. Invite yourself (`vinothvsbe@gmail.com`)
4. Check console for success message
5. Check your inbox for the invitation email

---

## ❓ FAQ

### Q: How many recipients can I authorize on sandbox?

A: Usually up to 5 authorized recipients on free sandbox domains.

### Q: Can I test with multiple emails?

A: Yes, authorize each test email address following the same steps.

### Q: How long does authorization take?

A: Immediate after clicking the confirmation link in the email.

### Q: What if I don't receive the confirmation email?

A: Check spam folder, or try adding a different email address.

### Q: Should I upgrade for production?

A: Yes! Sandbox domains are only for testing. Upgrade for production use.

---

## 📚 Resources

- **Mailgun Dashboard**: https://app.mailgun.com/
- **Mailgun Documentation**: https://documentation.mailgun.com/
- **Authorized Recipients Guide**: https://documentation.mailgun.com/docs/mailgun/user-manual/get-started/sandbox-sending/
- **Pricing**: https://www.mailgun.com/pricing/

---

## ✅ Next Steps

1. [ ] Authorize `vinothvsbe@gmail.com` in Mailgun dashboard
2. [ ] Confirm authorization via email link
3. [ ] Test email sending with curl or app
4. [ ] Authorize additional test recipients (optional)
5. [ ] Consider upgrading for production (recommended)

---

**Last Updated**: 2025-10-19
**Issue**: Sandbox domain requires recipient authorization
**Status**: Awaiting authorization of recipients
