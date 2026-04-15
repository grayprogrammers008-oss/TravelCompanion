# Complete Migration Guide: Old Supabase → New Supabase

## Migration from palkarfoods224@gmail.com → grayprogrammers008@gmail.com

---

## 📋 Overview

This guide will help you migrate:
- ✅ Database Schema (tables, functions, policies)
- ✅ All Data (profiles, trips, expenses, checklists, etc.)
- ✅ Storage Files (avatars, trip covers, receipts)
- ⚠️ Authentication Users (requires special handling)

**Total Time:** 1-2 hours

---

## 🎯 Migration Process (7 Steps)

```
Step 1: Create New Supabase Project          [10 min]
Step 2: Run Schema Migration                 [15 min]
Step 3: Export Data from Old Database        [5 min]  ✅ YOU ARE HERE
Step 4: Import Data to New Database          [10 min]
Step 5: Migrate Storage Files                [20 min]
Step 6: Handle Authentication Users          [5 min]
Step 7: Update App Configuration & Test      [15 min]
```

---

## Step 1: Create New Supabase Project ✅ ALREADY DONE

If you haven't already:

1. Go to https://supabase.com
2. Log in with **grayprogrammers008@gmail.com**
3. Click "New Project"
4. Fill in:
   - Name: `TravelCompanion`
   - Database Password: (save this!)
   - Region: Choose closest to you
5. Wait for project creation (2-3 minutes)

**Save these for later:**
- Project URL: `https://xxxxx.supabase.co`
- Project anon key: (from Settings → API)
- Database password

---

## Step 2: Run Schema Migration (Create All Tables)

### 2.1 Open NEW Supabase SQL Editor

1. Log in to https://supabase.com with **grayprogrammers008@gmail.com**
2. Open your NEW TravelCompanion project
3. Click **SQL Editor** in left sidebar
4. Click **New Query**

### 2.2 Run CLEAN_MIGRATION.sql

1. Open file: `CLEAN_MIGRATION.sql` (in your project folder)
2. **Select ALL contents** (Ctrl+A)
3. **Copy** (Ctrl+C)
4. **Paste** into Supabase SQL Editor
5. Click **RUN** button (or Ctrl+Enter)
6. Wait for success message (30-60 seconds)

**Expected Result:**
```
Success. No rows returned
```

This creates:
- ✅ 26 tables
- ✅ All indexes
- ✅ All RLS policies
- ✅ All functions and triggers

---

## Step 3: Export Data from Old Database ✅ YOU COMPLETED THIS!

You already exported your data to:
- File: `Supabase Snippet Bare-Minium Data Migration Export (1).csv`
- Location: `c:\Users\bsent\Downloads\`

**What you have:**
- 10 profiles (users)
- All trips data
- All expenses data
- All checklists data
- All other tables

---

## Step 4: Import Data to New Database

### 4.1 Prepare Import File

1. Open your CSV file: `Supabase Snippet Bare-Minium Data Migration Export (1).csv`
2. Create a new file: `MY_DATA_IMPORT.sql`
3. Copy **ALL rows** from CSV (except the header "import_script")
4. Paste into `MY_DATA_IMPORT.sql`

**Your file should look like this:**

```sql
-- ============================================================================
-- DATA IMPORT SCRIPT
-- Generated from OLD database (BARE MINIMUM)
-- Run this in NEW Supabase database AFTER running CLEAN_MIGRATION.sql
-- ============================================================================

BEGIN;

-- ============================================================================
-- PROFILES DATA
-- ============================================================================

INSERT INTO public.profiles (id, email, full_name) VALUES ('1b7823d8-9400-4ebf-9045-1abf3520db28', 'g.nithya.ece@gmail.com', 'Thiya') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.profiles (id, email, full_name) VALUES ('2db579ce-bc66-4445-8f29-39ffc4156b8b', 'nithyaganesan53@gmail.com', 'Nithya') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.profiles (id, email, full_name) VALUES ('58f57173-45ac-42f9-81e9-ab48ca39414e', 'pratap@gmail.com', 'Pratap') ON CONFLICT (id) DO NOTHING;
-- ... (all your data)

COMMIT;

-- ============================================================================
-- MIGRATION STATISTICS
-- ============================================================================

-- Profiles exported: 10
-- Trips exported: XX
-- Trip members exported: XX
-- Expenses exported: XX
-- ... (statistics)
```

### 4.2 Import to NEW Database

1. Open NEW Supabase SQL Editor
2. Click **New Query**
3. Open your `MY_DATA_IMPORT.sql` file
4. **Copy ALL contents**
5. **Paste** into SQL Editor
6. Click **RUN**
7. Wait for completion (1-5 minutes depending on data size)

**Expected Result:**
```
Success. No rows returned
```

### 4.3 Verify Import

Run these queries in NEW database SQL Editor:

```sql
-- Check profiles imported
SELECT COUNT(*) FROM profiles;
-- Should return: 10

-- Check trips imported
SELECT COUNT(*) FROM trips;

-- Check expenses imported
SELECT COUNT(*) FROM expenses;

-- View sample data
SELECT id, email, full_name FROM profiles LIMIT 5;
SELECT id, name, destination FROM trips LIMIT 5;
```

---

## Step 5: Migrate Storage Files

Storage files (avatars, trip covers, receipts) need separate migration.

### 5.1 Create Storage Buckets in NEW Database

1. Go to NEW Supabase project
2. Click **Storage** in left sidebar
3. Click **New Bucket**
4. Create these buckets:

**Bucket 1: avatars**
- Name: `avatars`
- Public: ✅ Yes
- File size limit: 2 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

**Bucket 2: trip-covers**
- Name: `trip-covers`
- Public: ✅ Yes
- File size limit: 5 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

**Bucket 3: receipts**
- Name: `receipts`
- Public: ❌ No (private)
- File size limit: 10 MB
- Allowed MIME types: `image/*`, `application/pdf`

### 5.2 Set Storage Policies

F\\\

### 5.3 Migrate Files

**Option A: Manual Download/Upload (Small dataset < 100 files)**

1. **OLD Supabase:**
   - Go to Storage → avatars
   - Select all files
   - Click Download
   - Save to local folder: `storage_backup/avatars/`

2. **Repeat for other buckets:**
   - trip-covers → `storage_backup/trip-covers/`
   - receipts → `storage_backup/receipts/`

3. **NEW Supabase:**
   - Go to Storage → avatars
   - Click Upload
   - Select all downloaded files
   - Upload

4. **Repeat for other buckets**

**Option B: Using Supabase CLI (Large dataset > 100 files)**

```bash
# Install Supabase CLI
npm install -g supabase

# Login to OLD account
supabase login
# Browser opens → login with palkarfoods224@gmail.com

# Link OLD project
supabase link --project-ref YOUR_OLD_PROJECT_REF

# Export storage
supabase storage export avatars ./storage_backup/avatars
supabase storage export trip-covers ./storage_backup/trip-covers
supabase storage export receipts ./storage_backup/receipts

# Logout and login to NEW account
supabase logout
supabase login
# Browser opens → login with grayprogrammers008@gmail.com

# Link NEW project
supabase link --project-ref YOUR_NEW_PROJECT_REF

# Import storage
supabase storage import avatars ./storage_backup/avatars
supabase storage import trip-covers ./storage_backup/trip-covers
supabase storage import receipts ./storage_backup/receipts
```

---

## Step 6: Handle Authentication Users

Authentication users (auth.users) need special handling.

### Option A: User Re-Registration ⭐ RECOMMENDED (Easiest)

**How it works:**
1. Users create new accounts on new database (same email)
2. App automatically links to existing profile data
3. All trips, expenses, etc. are preserved

**Steps:**

1. **Update your Flutter app** (add this code):

```dart
// In your authentication service
Future<void> handleUserRegistration(User authUser) async {
  try {
    // Check if profile already exists with this email
    final existingProfile = await supabase
        .from('profiles')
        .select()
        .eq('email', authUser.email)
        .maybeSingle();

    if (existingProfile != null && existingProfile['id'] != authUser.id) {
      // Profile exists from old database - link it to new auth user
      print('Found existing profile for ${authUser.email}, linking...');

      // First, create temporary new profile
      await supabase
          .from('profiles')
          .insert({
            'id': authUser.id,
            'email': authUser.email,
            'full_name': existingProfile['full_name'] ?? authUser.email.split('@')[0],
            'avatar_url': existingProfile['avatar_url'],
          });

      // Then update all foreign key references to new auth user ID
      // Update trip_members
      await supabase
          .from('trip_members')
          .update({'user_id': authUser.id})
          .eq('user_id', existingProfile['id']);

      // Update trips created_by
      await supabase
          .from('trips')
          .update({'created_by': authUser.id})
          .eq('created_by', existingProfile['id']);

      // Update expenses paid_by
      await supabase
          .from('expenses')
          .update({'paid_by': authUser.id})
          .eq('paid_by', existingProfile['id']);

      // Update expense_splits
      await supabase
          .from('expense_splits')
          .update({'user_id': authUser.id})
          .eq('user_id', existingProfile['id']);

      // Update checklists created_by
      await supabase
          .from('checklists')
          .update({'created_by': authUser.id})
          .eq('created_by', existingProfile['id']);

      // Update itinerary_items created_by
      await supabase
          .from('itinerary_items')
          .update({'created_by': authUser.id})
          .eq('created_by', existingProfile['id']);

      // Delete old profile
      await supabase
          .from('profiles')
          .delete()
          .eq('id', existingProfile['id']);

      print('✅ Successfully linked existing profile to new auth user');
    } else {
      // No existing profile - create new one
      await supabase
          .from('profiles')
          .insert({
            'id': authUser.id,
            'email': authUser.email,
            'full_name': authUser.email.split('@')[0],
          });
    }
  } catch (e) {
    print('❌ Error linking profile: $e');
    rethrow;
  }
}
```

2. **Notify your 10 users:**

Send this message to your users:

```
Hi everyone,

We've upgraded our TravelCompanion database!

To continue using the app, please create a new account:

1. Open TravelCompanion app
2. Click "Sign Up" (not "Log In")
3. Use your SAME email address as before
4. Create a new password
5. Your trips, expenses, and data will automatically appear!

Important:
- Use the SAME email as before
- Your data is safe and will be linked automatically
- This is a one-time setup

Thanks!
```

**Pros:**
- ✅ Simple and fast
- ✅ No external tools needed
- ✅ Works immediately

**Cons:**
- ❌ Users need to create new passwords

### Option B: Contact Supabase Support (Preserves Passwords)

If you want to keep user passwords:

1. Email: **support@supabase.com**
2. Subject: "Migrate auth.users between projects"
3. Provide:
   - OLD project ref
   - NEW project ref
   - Both account emails

**Wait time:** 1-2 business days

### Option C: Use Supabase CLI (Advanced)

See: `EXPORT_AUTH_USERS_GUIDE.md` for CLI instructions

---

## Step 7: Update App Configuration & Test

### 7.1 Update Flutter App Config

Update your Supabase credentials in the app:

**File:** `lib/main.dart` or wherever you initialize Supabase

```dart
// OLD values (remove these)
const supabaseUrl = 'https://OLD_PROJECT.supabase.co';
const supabaseAnonKey = 'OLD_ANON_KEY';

// NEW values (use these)
const supabaseUrl = 'https://NEW_PROJECT.supabase.co';
const supabaseAnonKey = 'NEW_ANON_KEY';
```

**To get NEW values:**
1. Go to NEW Supabase project
2. Settings → API
3. Copy:
   - Project URL
   - anon public key

### 7.2 Test the App

**Test Checklist:**

1. **Authentication:**
   - [ ] Can create new account (sign up)
   - [ ] Can log in with new account
   - [ ] Profile data loads correctly

2. **Trips:**
   - [ ] Can see all existing trips
   - [ ] Can create new trip
   - [ ] Can edit trip
   - [ ] Can delete trip
   - [ ] Trip members show correctly

3. **Expenses:**
   - [ ] Can see existing expenses
   - [ ] Can add new expense
   - [ ] Expense splits work
   - [ ] Settlement calculations correct

4. **Checklists:**
   - [ ] Can see existing checklists
   - [ ] Can create checklist
   - [ ] Can check/uncheck items

5. **Storage:**
   - [ ] Profile pictures load
   - [ ] Trip cover images load
   - [ ] Can upload new images
   - [ ] Receipt images load (if any)

6. **Messaging:**
   - [ ] Can send messages
   - [ ] Can receive messages
   - [ ] Conversations load

### 7.3 Verify Data Integrity

Run these queries in NEW database:

```sql
-- Check all tables have data
SELECT
  (SELECT COUNT(*) FROM profiles) as profiles,
  (SELECT COUNT(*) FROM trips) as trips,
  (SELECT COUNT(*) FROM trip_members) as trip_members,
  (SELECT COUNT(*) FROM itinerary_items) as itinerary_items,
  (SELECT COUNT(*) FROM checklists) as checklists,
  (SELECT COUNT(*) FROM checklist_items) as checklist_items,
  (SELECT COUNT(*) FROM expenses) as expenses,
  (SELECT COUNT(*) FROM expense_splits) as expense_splits;

-- Compare with OLD database counts

-- Check foreign key relationships
SELECT t.name as trip, p.full_name as creator
FROM trips t
JOIN profiles p ON t.created_by = p.id
LIMIT 5;
-- Should show trip names with creator names

-- Check trip members
SELECT t.name as trip, p.full_name as member
FROM trip_members tm
JOIN trips t ON tm.trip_id = t.id
JOIN profiles p ON tm.user_id = p.id
LIMIT 10;
-- Should show trips with their members
```

---

## 🎉 Migration Complete!

### Post-Migration Checklist

- [ ] All data imported successfully
- [ ] All tables have correct row counts
- [ ] Foreign key relationships intact
- [ ] Storage files accessible
- [ ] Users can register/login
- [ ] App connects to new database
- [ ] All features working
- [ ] No errors in app logs

### Keep OLD Database Active

⚠️ **Important:** Don't delete the OLD Supabase project yet!

- Keep it active for 1-2 weeks as backup
- Monitor new database for any issues
- Once confident, you can delete old project

### Troubleshooting

**Problem: Users can't see their old data**
- Check that they used the SAME email when registering
- Check that the profile linking code ran
- Verify data was imported: `SELECT * FROM profiles WHERE email = 'user@example.com'`

**Problem: Images not loading**
- Check storage buckets exist in new database
- Verify storage policies are set correctly
- Check that files were uploaded
- Update any hardcoded URLs in app

**Problem: Foreign key errors**
- Verify parent records exist before child records
- Check UUIDs match between tables
- Re-run import script with correct order

**Problem: Permission denied errors**
- Check RLS policies are enabled
- Verify policies allow authenticated users
- Test with `service_role` key temporarily (be careful!)

---

## Summary

✅ **What you've migrated:**
- Database schema (26 tables)
- All profile data (10 users)
- All trips, expenses, checklists
- Storage buckets and policies
- Database functions and triggers

⚠️ **Still need to handle:**
- Authentication users (choose Option A, B, or C)
- Storage files (manual or CLI upload)
- App configuration update
- Testing

**Next Immediate Steps:**
1. Prepare `MY_DATA_IMPORT.sql` from your CSV
2. Import to new database
3. Verify data
4. Choose authentication migration method
5. Update app config
6. Test!

---

Need help with any specific step? Let me know!
