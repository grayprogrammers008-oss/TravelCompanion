# 👥 Sharing Credentials with Team Members

## ✅ How to Share User Accounts

Supabase accounts work globally - you can create accounts and share credentials with your team!

---

## 🎯 Method 1: Share Existing Credentials (Recommended)

### Prerequisites
1. You've already created a user account in the app
2. You know the email and password
3. Email has been confirmed

### Steps to Share

**Step 1: Verify Email is Confirmed**
1. Login to [Supabase Dashboard](https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai)
2. Go to **Authentication → Users**
3. Find the user account
4. Check **"Email Confirmed At"** column
5. If it shows a date/time ✅ → Ready to share
6. If it's empty ❌ → Need to confirm (see below)

**Step 2: Confirm Email (if needed)**

Option A - Manual Confirmation (Fastest):
```sql
-- Run in Supabase SQL Editor
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'shared.account@example.com';
```

Option B - Dashboard:
1. Click on the user row
2. Click **"..."** menu → **"Confirm email"**

**Step 3: Share Credentials Securely**
```
Email: shared.account@example.com
Password: YourSecurePassword123!

Send via:
- Encrypted messaging (Signal, WhatsApp)
- Password manager (1Password, LastPass)
- NOT via plain email
```

**Step 4: Teammate Tests Login**
1. Open the app
2. Click **Login** (NOT Sign Up!)
3. Enter the shared credentials
4. Should see "Welcome back! 🎉"

---

## 🎯 Method 2: Create Multiple Test Accounts

Create dedicated accounts for each team member:

### Using the App (Recommended)

1. **You create account**:
   ```
   Email: nithya@example.com
   Password: Test123456!
   Full Name: Nithya
   ```

2. **In Supabase Dashboard**:
   - Go to **Authentication → Users**
   - Find the new user
   - Click **"..."** → **"Confirm email"** (skip email verification)

3. **Share with Nithya**:
   - Send credentials securely
   - She clicks **Login** (not Sign Up)
   - Should work immediately

### Using Supabase Dashboard

1. **Go to**: Authentication → Users
2. **Click**: "Invite user" or "Add user"
3. **Enter**:
   - Email: `teammate@example.com`
   - Password: `SecurePassword123!`
   - Auto-confirm: ✅ **Check this box!**
4. **Click**: Create user
5. **Share** credentials with teammate

---

## 🎯 Method 3: Disable Email Confirmation (Development Only)

For **development/testing**, disable email confirmation completely:

1. **Go to**: Authentication → Settings
2. **Click**: Email (under Auth Providers)
3. **Toggle**: "Confirm email" → **OFF**
4. **Click**: Save

Now ALL signups work immediately without email confirmation!

⚠️ **Warning**: Re-enable for production! This is a security feature.

---

## 🐛 Troubleshooting Shared Credentials

### Issue: "Invalid email or password" on teammate's machine

**Cause**: Email not confirmed

**Fix**:
```sql
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'the.shared@email.com';
```

---

### Issue: Works for you, not for teammate

**Possible causes**:

1. **Cached session on your machine**
   - Your app has saved session, bypassing login
   - Teammate starting fresh, hits unconfirmed email

2. **Network blocking (India-specific)**
   - Have teammate try mobile hotspot
   - Or VPN (Cloudflare WARP is free)

3. **Typo in credentials**
   - Extra spaces
   - Wrong case (email should be lowercase)
   - Copy/paste issue

**Fix**: Have them **type manually** instead of copy/paste

---

### Issue: Session expires quickly

**Cause**: Supabase default session timeout

**Fix**: Adjust in Supabase Dashboard
1. Go to **Authentication → Settings**
2. Find **JWT Expiry**
3. Default: 3600 seconds (1 hour)
4. Increase if needed

---

## 📋 Quick Checklist for Sharing Credentials

- [ ] Account exists in Supabase Users table
- [ ] Email is confirmed (verified in dashboard)
- [ ] Password is known and correct
- [ ] Credentials sent securely (not plain email)
- [ ] Teammate uses **Login** (not Sign Up)
- [ ] Teammate has internet connection
- [ ] Teammate can access supabase.co domain
- [ ] App is latest version (flutter pub get)

---

## 🎯 Best Practices

### For Development/Testing
```
✅ Create 2-3 shared test accounts
✅ Disable email confirmation
✅ Use simple passwords (Test123456!)
✅ Share via team chat
```

### For Production
```
✅ Each user has own account
✅ Enable email confirmation
✅ Use strong passwords
✅ Enable 2FA (if available)
✅ Never share credentials
```

---

## 🔧 SQL Script to Create & Confirm User

If you want to create users programmatically:

```sql
-- This creates an auth user and confirms it
-- Run in Supabase SQL Editor

-- Note: You cannot directly insert into auth.users via SQL
-- You must use Supabase Dashboard or Auth API

-- Instead, manually confirm existing user:
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email IN (
    'user1@example.com',
    'user2@example.com',
    'user3@example.com'
);

-- Verify:
SELECT email, email_confirmed_at, created_at
FROM auth.users
WHERE email IN (
    'user1@example.com',
    'user2@example.com',
    'user3@example.com'
);
```

---

## ✅ Recommended Setup for Your Team

Based on your situation (you + Nithya):

### Option A: Single Shared Test Account
```
Email: testuser@travelcrew.com
Password: Test123456!
Use: Both of you for testing
```

**Setup**:
1. You create via app Sign Up
2. Confirm in Supabase Dashboard
3. Share credentials with Nithya
4. Both login with same account

### Option B: Individual Accounts
```
Vinoth:
  Email: vinoth@example.com
  Password: [your password]

Nithya:
  Email: nithya@example.com
  Password: [her password]
```

**Setup**:
1. Create both accounts via app
2. Confirm both in Supabase Dashboard
3. Each uses their own account

**I recommend Option B** - cleaner for development and testing.

---

## 🆘 If Still Not Working

Run this diagnostic on **both machines**:

### Your Machine (Working):
```bash
flutter run --verbose
# Try login, capture console output
```

### Nithya's Machine (Not Working):
```bash
flutter run --verbose
# Try same credentials, capture console output
```

**Compare the console logs** - the error will show the difference!

---

## 📞 Quick Support Checklist

If Nithya still can't login, collect:

1. **Screenshot** of error message (from latest app version)
2. **Email** being used (verify exact spelling)
3. **Console output** from `flutter run --verbose`
4. **Network test**: Can she access https://ckgaoxajvonazdwpsmai.supabase.co?
5. **Supabase status**: Check her user in Dashboard

Send me these and I'll pinpoint the exact issue!

---

**TL;DR**: Yes, you can share credentials! Just make sure email is confirmed in Supabase Dashboard, then share securely. Should work globally.
