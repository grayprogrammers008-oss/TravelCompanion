# 🎯 SOLUTION: "Request Path is Invalid" Error

## What This Error Means

When you get **"request path is invalid"** from `https://ckgaoxajvonazdwpsmai.supabase.co`, it means:

✅ Network is working (not blocked)
✅ Request reaches Supabase
❌ **Project has an issue**

---

## 🔥 MOST LIKELY CAUSE: Project Paused

### Supabase Free Tier Auto-Pauses Projects

**After 1 week of inactivity, free tier projects pause automatically.**

Symptoms when paused:
- ❌ "Request path is invalid"
- ❌ "Project not found"
- ❌ Login/Signup fails
- ❌ All API calls fail

---

## ✅ SOLUTION: Resume Your Project

### Step 1: Check Project Status

1. Go to https://supabase.com/dashboard
2. Login with your account
3. Find project: **ckgaoxajvonazdwpsmai**
4. Look at the status badge

**If you see "PAUSED" or "INACTIVE":**

### Step 2: Resume the Project

1. Click **"Resume Project"** or **"Restore"** button
2. Wait 2-3 minutes for project to wake up
3. Refresh the page
4. Status should show **"ACTIVE"**

### Step 3: Test Again

1. Have Nithya try login/signup
2. Should work immediately!
3. Both of you can now use the app

---

## 🔍 How to Verify Project is Active

### Method 1: Check in Browser

Open this URL in browser:
```
https://ckgaoxajvonazdwpsmai.supabase.co/rest/v1/
```

**If Active:** Shows JSON with API info
**If Paused:** Shows "Project paused" or 404 error

---

### Method 2: Check API Endpoint

Run this in terminal:

```bash
curl https://ckgaoxajvonazdwpsmai.supabase.co/rest/v1/profiles \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg"
```

**If Active:** Returns 200 or 401 (both OK)
**If Paused:** Returns error about paused project

---

## 🎯 Other Possible Causes

If project is NOT paused, check these:

### 1. API Keys Changed

**Verify keys match:**

1. Supabase Dashboard → **Settings → API**
2. Copy **Project URL** and **anon public** key
3. Compare with your app config:

**File:** `lib/core/config/supabase_config.dart`

**Should be:**
```dart
supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co'
supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

**If different:** Update the file with new keys

---

### 2. Database Tables Missing

**Check if tables exist:**

1. Supabase Dashboard → **Table Editor**
2. Look for `profiles` table
3. Look for `auth.users`

**If missing:** Re-run `SUPABASE_SCHEMA.sql`

---

### 3. Auth Provider Disabled

**Check Email Auth is enabled:**

1. Supabase Dashboard → **Authentication → Providers**
2. Find **Email** in the list
3. Make sure it's **enabled** (toggle should be ON)

**If disabled:** Click to enable

---

### 4. Supabase SDK Version

**Update to latest version:**

```bash
flutter pub add supabase_flutter
flutter pub get
flutter clean
flutter run
```

---

## 🔧 Get Detailed Error from Nithya

Have her run this and capture the output:

```bash
flutter run --verbose 2>&1 | tee debug.log
```

When she tries to login, look for:
```
AuthException: [exact error]
PostgrestException: [exact error]
```

Send me the exact error text!

---

## 📊 Quick Diagnostic Table

| Symptom | Cause | Solution |
|---------|-------|----------|
| "Request path invalid" | Project paused | Resume in dashboard |
| "Project not found" | Wrong URL or deleted | Check URL in config |
| "Invalid API key" | Keys rotated | Update keys in config |
| Network timeout | ISP blocking | Use VPN/hotspot |
| "Email not confirmed" | User not verified | Confirm in dashboard |

---

## ✅ Expected After Resuming Project

Once project is active:

**Both you AND Nithya should be able to:**
- ✅ Login with existing accounts
- ✅ Sign up new accounts
- ✅ Create trips and expenses
- ✅ Access all features

---

## 🚨 If Project Can't Be Resumed

If the resume button doesn't work or project is deleted:

### Create New Project (5 minutes)

1. **Supabase Dashboard → New Project**
2. **Name:** TravelCrew
3. **Region:** Singapore (closest to India)
4. **Database Password:** [strong password]
5. **Click "Create Project"**

Wait 2-3 minutes for provisioning.

### Deploy Schema

1. Copy contents of `SUPABASE_SCHEMA.sql`
2. Supabase Dashboard → **SQL Editor**
3. Paste and run the SQL
4. Verify tables created in **Table Editor**

### Update App Config

1. Get new project URL and keys from **Settings → API**
2. Update `lib/core/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://YOUR_NEW_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_NEW_ANON_KEY';
```

3. Run:
```bash
flutter clean
flutter pub get
flutter run
```

### Share New Config

Send Nithya the updated config file!

---

## 🎯 TL;DR - Do This First

1. **Login to Supabase Dashboard**
2. **Check if project is PAUSED**
3. **If paused → Click RESUME**
4. **Wait 2 minutes**
5. **Try login/signup again**

**This fixes 90% of "request path invalid" errors!**

---

## 📞 Need More Help?

Send me:
1. Screenshot of Supabase project status
2. Exact error message from flutter console
3. Output of: `curl https://ckgaoxajvonazdwpsmai.supabase.co/rest/v1/`

I'll tell you exactly what's wrong! 🚀
