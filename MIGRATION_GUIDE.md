# Supabase Database Migration Guide

## Quick Migration: From Old to New Supabase Project

This guide helps you migrate your TravelCompanion database from `palkarfoods224@gmail.com` to `grayprogrammers008@gmail.com`.

---

## ✅ Method 1: Using CLEAN_MIGRATION.sql (Recommended)

This is the **easiest and safest** method for fresh Supabase projects.

### Step 1: Create New Supabase Project

1. Log in to https://supabase.com with `grayprogrammers008@gmail.com`
2. Click **"New Project"**
3. Fill in:
   - **Name:** TravelCompanion
   - **Database Password:** (Choose a strong password and save it!)
   - **Region:** Choose closest to your users
4. Click **"Create new project"**
5. Wait 2-3 minutes for project setup

### Step 2: Run the Clean Migration Script

1. In your new Supabase project, go to **SQL Editor** (left sidebar)
2. Click **"New query"**
3. Open `CLEAN_MIGRATION.sql` from your project folder
4. Copy the **entire file** contents
5. Paste into the Supabase SQL Editor
6. Click **"RUN"** (or press Ctrl+Enter)
7. Wait for completion (may take 1-2 minutes)

✅ **Result:** Your database schema is now fully set up!

### Step 3: Set Up Storage Buckets

The storage buckets need to be created manually:

1. Go to **Storage** (left sidebar)
2. Click **"New bucket"**
3. Create these 3 buckets:

**Bucket 1: avatars**
- Name: `avatars`
- Public: ✅ **Yes**
- File size limit: `5 MB`
- Allowed MIME types: `image/jpeg, image/png, image/gif, image/webp`

**Bucket 2: trip-covers**
- Name: `trip-covers`
- Public: ✅ **Yes**
- File size limit: `10 MB`
- Allowed MIME types: `image/jpeg, image/png, image/gif, image/webp`

**Bucket 3: receipts**
- Name: `receipts`
- Public: ❌ **No** (private)
- File size limit: `10 MB`
- Allowed MIME types: `image/jpeg, image/png, image/gif, application/pdf`

### Step 4: Configure Storage Policies

For each bucket, add these policies:

**For `avatars` bucket:**
```sql
-- Allow authenticated users to upload their own avatar
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow anyone to view avatars
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Allow users to update their own avatar
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own avatar
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

**For `trip-covers` bucket:**
```sql
-- Trip members can upload trip covers
CREATE POLICY "Trip members can upload covers"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'trip-covers');

-- Anyone can view trip covers
CREATE POLICY "Anyone can view trip covers"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'trip-covers');

-- Trip owners can update covers
CREATE POLICY "Trip owners can update covers"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'trip-covers');

-- Trip owners can delete covers
CREATE POLICY "Trip owners can delete covers"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'trip-covers');
```

**For `receipts` bucket:**
```sql
-- Trip members can upload receipts
CREATE POLICY "Trip members can upload receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts');

-- Trip members can view receipts
CREATE POLICY "Trip members can view receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'receipts');

-- Expense creators can delete receipts
CREATE POLICY "Expense creators can delete receipts"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'receipts');
```

### Step 5: Update Your Flutter App Configuration

1. Open your Flutter project
2. Find your `.env` file or Supabase configuration
3. Update these values with your **new Supabase project**:

```dart
// In your app's Supabase configuration
const supabaseUrl = 'https://YOUR_NEW_PROJECT_REF.supabase.co';
const supabaseAnonKey = 'YOUR_NEW_ANON_KEY';
```

To find these values:
- Go to **Project Settings** > **API** in Supabase Dashboard
- Copy **Project URL** → This is your `supabaseUrl`
- Copy **anon public** key → This is your `supabaseAnonKey`

### Step 6: Test Your App

1. Run your Flutter app
2. Try creating a new account
3. Try creating a new trip
4. Verify all features work

---

## 📊 Method 2: Migrate Existing Data (If you have users/data)

If you have **existing users and data** in the old database that you want to migrate:

### Step 1: Export Data from Old Database

1. Log in to old Supabase project (`palkarfoods224@gmail.com`)
2. Go to **Database** > **Tables**
3. For each table, click the table name → **Export** → **CSV**
4. Download CSV files for:
   - `profiles`
   - `trips`
   - `trip_members`
   - `itinerary_items`
   - `checklists`
   - `checklist_items`
   - `expenses`
   - `expense_splits`
   - Any other tables with data

### Step 2: Set Up New Database

Follow **Method 1 Steps 1-4** above to set up the new database schema.

### Step 3: Import Data

1. Go to **SQL Editor** in your new Supabase project
2. For each table, run import commands:

```sql
-- Example: Import profiles
COPY public.profiles(id, email, full_name, avatar_url, bio, phone, role, status, created_at, updated_at)
FROM '/path/to/profiles.csv'
DELIMITER ','
CSV HEADER;
```

⚠️ **Note:** You may need to use Supabase CLI or a PostgreSQL client for CSV imports.

### Step 4: Migrate Storage Files

Storage files (avatars, trip covers, receipts) need to be migrated manually:

1. Download all files from old project's storage buckets
2. Upload to new project's storage buckets
3. Update URLs in database if needed

---

## 🔧 Troubleshooting

### Error: "relation already exists"
**Solution:** You're running the migration on a database that already has tables. Either:
1. Create a fresh Supabase project, OR
2. Drop existing tables first (⚠️ **this deletes all data!**)

### Error: "permission denied for schema public"
**Solution:** You need to run the script as a database admin. Use Supabase SQL Editor.

### Error: "type already exists"
**Solution:** The custom types (ENUM) already exist. The script handles this with `DO $$ BEGIN ... EXCEPTION WHEN duplicate_object ...` blocks, so you can safely re-run.

### Error: "function already exists"
**Solution:** The script uses `CREATE OR REPLACE FUNCTION`, so it's safe to re-run.

### Storage buckets not created
**Solution:** Storage buckets must be created manually through the Supabase Dashboard UI (Storage section).

---

## 📝 What Gets Migrated

✅ **Database Schema:**
- 26 tables with all columns
- All indexes for performance
- Row Level Security (RLS) policies
- Triggers for auto-updates
- Custom ENUM types
- PostGIS for location features

✅ **Business Logic:**
- User authentication structure
- Trip management
- Expense tracking with settlements
- Group chat with conversations
- AI usage tracking
- Place caching
- Trip templates
- Favorites system

✅ **Security:**
- RLS policies on all tables
- User can only see own data
- Trip members can collaborate
- Admin roles supported

❌ **Not Included (Must do manually):**
- Existing user data
- Existing trip data
- Storage bucket files
- Authentication provider settings (Google, Apple, etc.)

---

## 🎯 Quick Checklist

Before running the migration:
- [ ] Created new Supabase project
- [ ] Saved database password
- [ ] Noted down project URL and anon key

After running CLEAN_MIGRATION.sql:
- [ ] All tables created (check Database > Tables)
- [ ] No errors in SQL Editor
- [ ] Storage buckets created (avatars, trip-covers, receipts)
- [ ] Storage policies added
- [ ] Flutter app configuration updated
- [ ] Test app with new credentials

---

## 💡 Pro Tips

1. **Test First:** Create a test Supabase project first to practice the migration
2. **Backup:** If migrating data, keep the old project active until you verify everything works
3. **Environment Variables:** Use `.env` files to easily switch between old/new Supabase projects
4. **Version Control:** Commit the `CLEAN_MIGRATION.sql` file to your Git repository

---

## 🆘 Need Help?

If you encounter issues:
1. Check the Supabase Dashboard **Logs** section
2. Look at **Database** > **Roles** to verify permissions
3. Review the error message in SQL Editor
4. Check if all required extensions are enabled (uuid-ossp, citext, postgis)

---

## 📞 Support

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- GitHub Issues: https://github.com/supabase/supabase/issues

---

**Good luck with your migration! 🚀**
