# 📦 Complete Data Migration Guide

## Migrate Supabase Data from Old to New Account

**From:** `palkarfoods224@gmail.com` → **To:** `grayprogrammers008@gmail.com`

---

## 🎯 Overview

This guide helps you migrate:
- ✅ All user accounts (profiles)
- ✅ All trips and trip members
- ✅ All itineraries and checklists
- ✅ All expenses and settlements
- ✅ All messages and conversations
- ✅ All favorites and cached data
- ✅ Storage files (avatars, trip covers, receipts)

---

## 📋 Prerequisites

Before starting:
- [ ] **NEW database setup complete** - Run `CLEAN_MIGRATION.sql` on new Supabase project first
- [ ] **Both projects accessible** - Can log into both Supabase accounts
- [ ] **Connection strings ready** - Know how to get database connection strings

---

## 🚀 Method 1: Using Export Script (Recommended)

This method generates SQL INSERT statements from your old database.

### Step 1: Run Export Script on OLD Database

1. **Log in to OLD Supabase project**
   - Go to https://supabase.com
   - Log in with `palkarfoods224@gmail.com`
   - Select your TravelCompanion project

2. **Open SQL Editor**
   - Click **SQL Editor** in left sidebar
   - Click **New query**

3. **Run the Export Script**
   - Open file: `DATA_MIGRATION_EXPORT.sql`
   - Copy **entire contents**
   - Paste into Supabase SQL Editor
   - Click **RUN** (or press Ctrl+Enter)

4. **Copy the Output**
   - The script will generate INSERT statements
   - **Select ALL output** (Ctrl+A)
   - **Copy** (Ctrl+C)
   - **Save** to a new file named `DATA_IMPORT_GENERATED.sql`

### Step 2: Run Import Script on NEW Database

1. **Log in to NEW Supabase project**
   - Go to https://supabase.com
   - Log in with `grayprogrammers008@gmail.com`
   - Select your NEW TravelCompanion project

2. **⚠️ IMPORTANT: First run CLEAN_MIGRATION.sql**
   - If you haven't already, run `CLEAN_MIGRATION.sql` first
   - This creates all tables and schema
   - **Don't skip this step!**

3. **Open SQL Editor**
   - Click **SQL Editor** in left sidebar
   - Click **New query**

4. **Run the Import Script**
   - Open your saved `DATA_IMPORT_GENERATED.sql` file
   - Copy **entire contents**
   - Paste into Supabase SQL Editor
   - Click **RUN**
   - Wait for completion (may take 1-5 minutes depending on data size)

5. **Verify the Import**
   ```sql
   -- Check profiles
   SELECT COUNT(*) FROM profiles;

   -- Check trips
   SELECT COUNT(*) FROM trips;

   -- Check messages
   SELECT COUNT(*) FROM messages;
   ```

✅ **Done!** Your data is now migrated.

---

## 🔧 Method 2: Using pg_dump (Advanced)

This method uses PostgreSQL's native backup/restore tools.

### Prerequisites
- Install PostgreSQL client tools on your computer
- Get database connection strings from both projects

### Step 1: Get Connection Strings

**For OLD Database (palkarfoods224@gmail.com):**
1. Go to Supabase Dashboard → **Settings** → **Database**
2. Scroll to **Connection string**
3. Select **URI** format
4. Copy the connection string (looks like: `postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres`)
5. Replace `[PASSWORD]` with your actual database password

**For NEW Database (grayprogrammers008@gmail.com):**
1. Repeat the same steps for your new project
2. Save both connection strings

### Step 2: Export Data from OLD Database

Open terminal/command prompt and run:

```bash
# Windows (Command Prompt)
pg_dump "postgresql://postgres:[OLD_PASSWORD]@[OLD_HOST]:5432/postgres" ^
  --data-only ^
  --no-owner ^
  --no-privileges ^
  --schema=public ^
  --exclude-table=auth.* ^
  --exclude-table=storage.* ^
  > old_data_dump.sql

# Mac/Linux
pg_dump "postgresql://postgres:[OLD_PASSWORD]@[OLD_HOST]:5432/postgres" \
  --data-only \
  --no-owner \
  --no-privileges \
  --schema=public \
  --exclude-table='auth.*' \
  --exclude-table='storage.*' \
  > old_data_dump.sql
```

**Explanation:**
- `--data-only` - Export only data, not schema
- `--no-owner` - Don't include ownership statements
- `--no-privileges` - Don't include permission statements
- `--schema=public` - Only export from public schema
- `--exclude-table` - Skip auth and storage internal tables

### Step 3: Import Data to NEW Database

⚠️ **IMPORTANT:** Run `CLEAN_MIGRATION.sql` on new database first!

```bash
# Windows
psql "postgresql://postgres:[NEW_PASSWORD]@[NEW_HOST]:5432/postgres" ^
  -f old_data_dump.sql

# Mac/Linux
psql "postgresql://postgres:[NEW_PASSWORD]@[NEW_HOST]:5432/postgres" \
  -f old_data_dump.sql
```

### Step 4: Verify Import

```sql
-- Run in NEW database SQL Editor
SELECT
  (SELECT COUNT(*) FROM profiles) as profiles,
  (SELECT COUNT(*) FROM trips) as trips,
  (SELECT COUNT(*) FROM trip_members) as members,
  (SELECT COUNT(*) FROM messages) as messages;
```

---

## 📁 Method 3: Migrate Storage Files

Storage files (avatars, trip covers, receipts) need separate migration.

### Option A: Manual Download/Upload (Small datasets)

**For Avatars:**
1. Go to OLD project → **Storage** → `avatars` bucket
2. Download all files
3. Go to NEW project → **Storage** → `avatars` bucket
4. Upload all files (maintain folder structure)

**For Trip Covers:**
1. Repeat for `trip-covers` bucket

**For Receipts:**
1. Repeat for `receipts` bucket (if you have this)

### Option B: Using Supabase CLI (Faster for large datasets)

```bash
# Install Supabase CLI
npm install -g supabase

# Login to OLD account
supabase login

# Link OLD project
supabase link --project-ref [OLD_PROJECT_REF]

# Export storage
supabase storage export avatars ./storage_backup/avatars
supabase storage export trip-covers ./storage_backup/trip-covers
supabase storage export receipts ./storage_backup/receipts

# Switch to NEW account
supabase logout
supabase login

# Link NEW project
supabase link --project-ref [NEW_PROJECT_REF]

# Import storage
supabase storage import avatars ./storage_backup/avatars
supabase storage import trip-covers ./storage_backup/trip-covers
supabase storage import receipts ./storage_backup/receipts
```

---

## ⚠️ Important Notes

### 1. Authentication Users
Supabase auth users are **separate** from your `profiles` table. You need to:

**Option A: Users re-register** (Recommended for clean migration)
- Users create new accounts on new database
- App links new auth.users.id to existing profile by email matching

**Option B: Migrate auth users** (Advanced)
- Requires Supabase support assistance
- Contact Supabase support to migrate auth users
- Not recommended for small user bases

### 2. Order Matters
Always import in this order:
1. ✅ **Schema first** - Run `CLEAN_MIGRATION.sql`
2. ✅ **Data second** - Run import script
3. ✅ **Storage last** - Migrate files

### 3. Foreign Key Constraints
The import script handles foreign keys by:
- Inserting parent records first (profiles, trips)
- Then child records (trip_members, itinerary_items)
- Using `ON CONFLICT DO NOTHING` to handle duplicates

### 4. UUID Preservation
All UUIDs are preserved during migration, so:
- User IDs stay the same
- Trip IDs stay the same
- All relationships maintained

---

## 🧪 Testing After Migration

### Test Checklist

1. **Profile Test**
   ```sql
   -- Check if profiles exist
   SELECT id, email, full_name FROM profiles LIMIT 5;
   ```

2. **Trip Test**
   ```sql
   -- Check trips with members
   SELECT t.name, t.destination, COUNT(tm.id) as member_count
   FROM trips t
   LEFT JOIN trip_members tm ON tm.trip_id = t.id
   GROUP BY t.id, t.name, t.destination
   LIMIT 5;
   ```

3. **Itinerary Test**
   ```sql
   -- Check itinerary items
   SELECT t.name, COUNT(ii.id) as item_count
   FROM trips t
   LEFT JOIN itinerary_items ii ON ii.trip_id = t.id
   GROUP BY t.id, t.name
   LIMIT 5;
   ```

4. **Message Test**
   ```sql
   -- Check messages
   SELECT COUNT(*) as total_messages FROM messages;
   SELECT COUNT(*) as conversations FROM conversations;
   ```

5. **Storage Test**
   - Go to Storage → avatars
   - Verify files are visible
   - Try opening a few files

### App Testing

1. **Can't log in with old password?**
   - This is **expected** if auth users weren't migrated
   - Users need to create new accounts
   - App should match by email to existing profile

2. **Data appears correctly?**
   - Open app with new Supabase config
   - Create test user or use existing
   - Check if trips show up
   - Check if messages show up

3. **Images loading?**
   - Check if profile avatars load
   - Check if trip cover images load

---

## 🆘 Troubleshooting

### "relation does not exist"
**Problem:** Tables don't exist in new database
**Solution:** Run `CLEAN_MIGRATION.sql` first to create schema

### "duplicate key value violates unique constraint"
**Problem:** Trying to insert data that already exists
**Solution:** This is normal with `ON CONFLICT DO NOTHING`, the script skips duplicates

### "foreign key constraint violation"
**Problem:** Trying to insert child record before parent
**Solution:** The export script orders data correctly. If using custom script, insert parents first.

### "permission denied"
**Problem:** Don't have permission to insert data
**Solution:** Make sure you're using Supabase SQL Editor which has admin permissions

### "column does not exist"
**Problem:** Old database has different schema
**Solution:**
1. Check if column name changed
2. Update export script to match your schema
3. Or manually adjust the generated import script

### Import takes too long
**Problem:** Large dataset (100k+ rows)
**Solution:**
1. Break import into smaller chunks
2. Import one table at a time
3. Use `pg_dump` method instead (faster for bulk data)

### Some data missing after import
**Problem:** Data didn't import for some tables
**Solution:**
1. Check export script output - did it generate statements for that table?
2. Check if table exists in old database: `SELECT COUNT(*) FROM table_name;`
3. Re-run export for specific table

---

## 📊 Migration Checklist

### Pre-Migration
- [ ] Backed up old database (just in case)
- [ ] Created new Supabase project
- [ ] Ran CLEAN_MIGRATION.sql on new database
- [ ] Created storage buckets in new project
- [ ] Have both database connection strings ready

### Data Migration
- [ ] Exported data from old database
- [ ] Saved export output to file
- [ ] Imported data to new database
- [ ] Verified row counts match
- [ ] Tested data integrity (foreign keys work)

### Storage Migration
- [ ] Downloaded/exported storage files
- [ ] Uploaded to new storage buckets
- [ ] Verified file accessibility
- [ ] Updated any hardcoded URLs in app

### App Configuration
- [ ] Updated supabaseUrl in app config
- [ ] Updated supabaseAnonKey in app config
- [ ] Tested app login
- [ ] Tested app features
- [ ] Verified data displays correctly

### Post-Migration
- [ ] All users can log in (or re-register)
- [ ] All trips load correctly
- [ ] All images/files load correctly
- [ ] Notifications still work
- [ ] No data loss confirmed
- [ ] Old database can be archived/deleted

---

## 🎯 Quick Reference

### Export Command
```bash
# Run this in OLD Supabase SQL Editor
# Copy entire DATA_MIGRATION_EXPORT.sql file
# Save output to DATA_IMPORT_GENERATED.sql
```

### Import Command
```bash
# Run CLEAN_MIGRATION.sql first (if not done)
# Then run DATA_IMPORT_GENERATED.sql in NEW Supabase SQL Editor
```

### Verify Command
```sql
SELECT
  (SELECT COUNT(*) FROM profiles) as profiles,
  (SELECT COUNT(*) FROM trips) as trips,
  (SELECT COUNT(*) FROM messages) as messages,
  (SELECT COUNT(*) FROM expenses) as expenses;
```

---

## 📞 Need Help?

1. **Check SQL Editor Output** - Look for error messages
2. **Verify Schema First** - Make sure CLEAN_MIGRATION.sql ran successfully
3. **Test Small Batch** - Try importing just profiles first
4. **Check Supabase Logs** - Go to Logs section in Dashboard

---

**Good luck with your migration! 🚀**

If you encounter issues not covered here, check the Supabase documentation or reach out to their support team.
