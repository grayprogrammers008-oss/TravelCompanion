# Post-Migration Configuration Update Guide

After successfully migrating your Supabase database, you need to update the app configuration to use the new project.

---

## Current Configuration (OLD PROJECT)

**Supabase Project:**
- **Project Ref:** `ckgaoxajvonazdwpsmai`
- **URL:** `https://ckgaoxajvonazdwpsmai.supabase.co`
- **Account:** `palkarfoods224@gmail.com`

**Brevo Email:**
- **Sender Email:** `palkarfoods224@gmail.com`

---

## Step-by-Step Update Process

### Step 1: Get New Project Credentials

1. **Login to new Supabase project:**
   - Go to [https://app.supabase.com](https://app.supabase.com)
   - Login with `grayprogrammers008@gmail.com`
   - Open your TravelCompanion project

2. **Copy Project URL:**
   - Go to **Settings** → **API**
   - Copy the **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - Save it as: `NEW_SUPABASE_URL`

3. **Copy Anon/Public Key:**
   - Still in **Settings** → **API**
   - Copy the **anon public** key
   - Save it as: `NEW_SUPABASE_ANON_KEY`

4. **Copy Service Role Key (Optional):**
   - Copy the **service_role** key
   - Save it securely - this is your admin key!
   - Save it as: `NEW_SUPABASE_SERVICE_KEY`

---

### Step 2: Update Flutter Configuration

#### File: `lib/core/config/supabase_config.dart`

**Find these lines (around line 11-20):**

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ckgaoxajvonazdwpsmai.supabase.co', // ← OLD URL
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // ← OLD KEY
);
```

**Replace with:**

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'YOUR_NEW_PROJECT_URL_HERE', // ← Paste NEW_SUPABASE_URL
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'YOUR_NEW_ANON_KEY_HERE', // ← Paste NEW_SUPABASE_ANON_KEY
);
```

**Example (with placeholder):**
```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://abcdefgh.supabase.co', // NEW URL
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS...', // NEW KEY
);
```

---

### Step 3: Update Brevo Email Configuration

If you're using a different email for the new project:

#### File: `lib/core/config/supabase_config.dart`

**Find these lines (around line 32-38):**

```dart
static const String brevoSenderEmail = String.fromEnvironment(
  'BREVO_SENDER_EMAIL',
  defaultValue: 'palkarfoods224@gmail.com', // ← OLD EMAIL
);
```

**Replace with:**

```dart
static const String brevoSenderEmail = String.fromEnvironment(
  'BREVO_SENDER_EMAIL',
  defaultValue: 'grayprogrammers008@gmail.com', // ← NEW EMAIL
);
```

**Note:** If you want to keep using the same Brevo account and API key, you can leave this unchanged.

---

### Step 4: Update Environment Variables (if using)

If you're using environment variables instead of hardcoding:

#### Create/Update `.env` file:

```env
# OLD (backup)
# OLD_SUPABASE_URL=https://ckgaoxajvonazdwpsmai.supabase.co
# OLD_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# NEW
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**To use environment variables when running:**

```bash
# Build with environment variables
flutter build apk --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...

# Run with environment variables
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

### Step 5: Clean and Rebuild the App

```bash
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Run code generation (if using freezed/json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

---

### Step 6: Verify the Connection

After starting the app, check the debug console for:

```
✅ Supabase initialized successfully
```

If you see errors like:
```
❌ Error: Invalid API key
❌ Error: Could not connect to Supabase
```

Then double-check that:
1. The URL is correct (no trailing slash)
2. The anon key is complete (starts with `eyJ...`)
3. No extra spaces or quotes in the configuration

---

## Update Checklist

Use this checklist to ensure everything is updated:

### Configuration Files
- [ ] Updated `lib/core/config/supabase_config.dart` with new URL
- [ ] Updated `lib/core/config/supabase_config.dart` with new anon key
- [ ] Updated Brevo sender email (if changed)
- [ ] Updated `.env` file (if using environment variables)

### Project Reference (OLD)
```
Project Ref: ckgaoxajvonazdwpsmai
URL: https://ckgaoxajvonazdwpsmai.supabase.co
```

### Project Reference (NEW)
```
Project Ref: [FILL IN AFTER MIGRATION]
URL: [FILL IN AFTER MIGRATION]
```

### Testing
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run app and verify Supabase connection
- [ ] Test user authentication (login/signup)
- [ ] Test data fetching (trips list)
- [ ] Test data creation (create new trip)
- [ ] Test image uploads (profile pictures, trip images)
- [ ] Test real-time updates (if applicable)

### Verification Queries

Run these in the Supabase SQL Editor to verify data:

```sql
-- Check user count
SELECT COUNT(*) FROM auth.users;

-- Check trips count
SELECT COUNT(*) FROM trips;

-- Check expenses count
SELECT COUNT(*) FROM expenses;

-- Check checklists count
SELECT COUNT(*) FROM checklists;

-- Check storage buckets
SELECT * FROM storage.buckets;
```

---

## Rollback Plan

If something goes wrong, you can quickly rollback:

### Quick Rollback Steps:

1. **Restore old configuration:**
   ```dart
   static const String supabaseUrl = 'https://ckgaoxajvonazdwpsmai.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg';
   ```

2. **Run:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Common Issues and Solutions

### Issue 1: "Invalid API Key"

**Cause:** Anon key is incorrect or incomplete

**Solution:**
- Go to new project → Settings → API
- Copy the complete `anon public` key
- Ensure no extra spaces or line breaks

---

### Issue 2: "Connection Timeout"

**Cause:** URL is incorrect or project is paused

**Solution:**
- Verify URL format: `https://xxxxx.supabase.co` (no trailing slash)
- Check project status in Supabase dashboard
- Ensure project is not paused

---

### Issue 3: "Permission Denied"

**Cause:** RLS policies not migrated properly

**Solution:**
- Go to Supabase Dashboard → Authentication → Policies
- Verify all RLS policies are present
- Manually add missing policies from old project

---

### Issue 4: "Storage Upload Fails"

**Cause:** Storage buckets not created or wrong permissions

**Solution:**
- Go to Storage in new project
- Create buckets with same names as old project
- Set correct permissions (public/private)

---

## Support Resources

- **Supabase Docs:** https://supabase.com/docs
- **Migration Guide:** SUPABASE_MIGRATION_GUIDE.md
- **Supabase Discord:** https://discord.supabase.com

---

**Last Updated:** 2026-04-06
**Migration:** palkarfoods224@gmail.com → grayprogrammers008@gmail.com
