# 🔧 Login Troubleshooting Guide - Travel Crew

## Issue: "Invalid email and password" for Remote Collaborators

If your collaborator (especially from India or other regions) cannot login, follow this guide.

---

## ✅ Quick Checklist

Before diving deep, verify:

- [ ] User has signed up (not trying to login before signup)
- [ ] Using correct email and password (no typos)
- [ ] Email has been confirmed
- [ ] Internet connection is working
- [ ] Can access https://ckgaoxajvonazdwpsmai.supabase.co in browser

---

## 🎯 Solution 1: Confirm Email (MOST COMMON)

### Problem
Supabase requires email confirmation. Unconfirmed accounts cannot login.

### Check
1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai)
2. Navigate to: **Authentication → Users**
3. Find the user's email
4. Check **"Email Confirmed At"** column
5. If empty or ❌ → Email not confirmed!

### Fix Option A: Manual Confirmation (Fastest)
```sql
-- Run in Supabase SQL Editor
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'collaborator@example.com';
```

### Fix Option B: Dashboard Confirmation
1. Click on the user row
2. Click **"Send confirmation email"** button
3. Or click the **"..."** menu → **"Confirm email"**

### Fix Option C: Disable Email Confirmation (Development Only)
1. Go to: **Authentication → Settings**
2. Click **Email** under Auth Providers
3. Toggle **"Confirm email"** to **OFF**
4. Click **Save**
5. ⚠️ **Warning**: Only for development! Re-enable for production

---

## 🎯 Solution 2: Create Account First

### Problem
User trying to login before account exists.

### Check
1. In Supabase Dashboard → **Authentication → Users**
2. Search for the email
3. If not found → Account doesn't exist

### Fix Option A: User Signs Up
1. Have user click **"Sign Up"** instead of "Login"
2. Fill registration form
3. Confirm email
4. Then login

### Fix Option B: Admin Creates Account
1. In Supabase Dashboard → **Authentication → Users**
2. Click **"Add user"** (might need to enable email provider first)
3. Or create via SQL:
```sql
-- This creates the auth user but may not create profile
-- Better to use the app's Sign Up flow
```

---

## 🎯 Solution 3: Network/Firewall Issues (India-Specific)

### Problem
Some ISPs or corporate networks block Supabase URLs.

### Test Connectivity
Ask collaborator to:
1. Open browser
2. Navigate to: `https://ckgaoxajvonazdwpsmai.supabase.co`
3. If it times out or shows error → Network issue!

### Fix Options

#### A. Try Mobile Hotspot
1. Disconnect from WiFi
2. Use mobile data hotspot
3. Try login again
4. If works → WiFi/ISP is blocking

#### B. Try VPN
1. Install VPN:
   - Cloudflare WARP (Free): https://1.1.1.1/
   - ProtonVPN (Free)
   - Any trusted VPN
2. Connect to VPN
3. Try login again

#### C. Check Firewall
If on corporate network:
1. Contact IT department
2. Ask to whitelist: `*.supabase.co`
3. Specifically: `ckgaoxajvonazdwpsmai.supabase.co`

#### D. Check Supabase Status
1. Visit: https://status.supabase.com
2. Check if there are any outages
3. Check India region specifically

---

## 🎯 Solution 4: Password Issues

### Problem
Password has encoding issues or extra characters.

### Fix
1. **No Copy/Paste**: Type password manually
2. **Simple Test Password**: Try `Test123456!`
3. **Reset Password**:
   - Click "Forgot Password" in app
   - Or reset via Supabase Dashboard
4. **Check for Spaces**: Trim spaces before/after password

---

## 🎯 Solution 5: App Configuration Issues

### Problem
App pointing to wrong Supabase instance or wrong credentials.

### Check
1. Open: `lib/core/config/supabase_config.dart`
2. Verify:
```dart
supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co'
supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

### Fix
1. Get latest credentials from Supabase Dashboard:
   - **Settings → API**
   - Copy **Project URL** and **anon public** key
2. Update `supabase_config.dart`
3. Restart app

---

## 🎯 Solution 6: Row Level Security (RLS) Issue

### Problem
User can authenticate but cannot fetch profile.

### Check
1. In Supabase Dashboard → **Authentication → Policies**
2. Check `profiles` table policies
3. Should have policy allowing users to read own profile

### Fix
Run this SQL in Supabase SQL Editor:

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);
```

---

## 🔍 Advanced Debugging

### Get Detailed Error Logs

The app now shows detailed error messages! When login fails, you'll see:

```
Invalid email or password. Possible reasons:
• Email not confirmed (check your inbox)
• Wrong password
• Account doesn't exist (try Sign Up)
• Account disabled

Original error: [Supabase error message]
```

### Enable Flutter Debug Logs

1. Run app in debug mode:
```bash
flutter run --verbose
```

2. Watch console for:
```
🔐 Signing in with Supabase
   Email: user@example.com
❌ Sign in failed: [error details]
```

### Test with Diagnostic Script

Run the diagnostic script:
```bash
dart diagnose_login_issue.dart
```

This will test:
- Supabase connectivity
- Network access
- Common configuration issues

---

## 📋 Checklist for Collaborators in India

1. **Account Setup**
   - [ ] Signed up through the app
   - [ ] Email confirmed (check inbox/spam)
   - [ ] Can see account in Supabase Dashboard

2. **Network Check**
   - [ ] Can access supabase.co in browser
   - [ ] Not on restricted corporate network
   - [ ] Tried mobile hotspot
   - [ ] Tried VPN if needed

3. **Credentials**
   - [ ] Using correct email (no typos)
   - [ ] Using correct password
   - [ ] No extra spaces when typing
   - [ ] Tried password reset if unsure

4. **App Version**
   - [ ] Using latest code from git
   - [ ] Ran `flutter pub get`
   - [ ] Ran `flutter clean && flutter pub get` if issues persist

---

## 🆘 Still Not Working?

### Collect Information

Have the collaborator send you:

1. **Screenshot** of the error message
2. **Email address** they're trying to use
3. **Network type**: WiFi, Mobile Data, Corporate
4. **Location**: City, ISP name
5. **Console logs** from running in debug mode

### Manual Account Creation

As admin, you can create the account manually:

1. Go to Supabase Dashboard → **Authentication → Users**
2. Click **"Add user"**
3. Enter email and password
4. Mark **"Auto confirm user"** = Yes
5. Click **Create user**
6. Share credentials with collaborator

---

## 📞 Contact

If all else fails:
- Check Supabase Discord: https://discord.supabase.com
- Supabase Support: https://supabase.com/support
- GitHub Issues: Report app-specific issues

---

## ✅ Success Indicators

Login is working when:
- ✅ User sees: "Welcome back! 🎉"
- ✅ Navigates to home page
- ✅ Can see trips and data
- ✅ No error messages

---

**Last Updated**: 2025-10-21
**App Version**: 1.0.0
**Supabase Project**: ckgaoxajvonazdwpsmai
