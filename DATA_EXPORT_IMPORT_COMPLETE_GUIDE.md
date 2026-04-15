# Complete Guide: Export & Import Data Between Supabase Accounts

## 🎯 Goal
Export ALL data from OLD database → Import to NEW database

**From:** palkarfoods224@gmail.com → **To:** grayprogrammers008@gmail.com

---

## 📋 Overview - 3 Main Steps

```
Step 1: Export Data from OLD Database     [5 minutes]
   ↓
Step 2: Prepare Import File               [2 minutes]
   ↓
Step 3: Import Data to NEW Database       [5 minutes]
   ↓
Step 4: Verify Import                     [3 minutes]
```

**Total Time:** 15 minutes

---

# STEP 1: Export Data from OLD Database

## 1.1 Login to OLD Supabase

1. Open browser: https://supabase.com
2. Click **Sign In**
3. Email: **palkarfoods224@gmail.com**
4. Enter password
5. Click on **TravelCompanion** project

## 1.2 Open SQL Editor

1. In left sidebar, click **SQL Editor**
2. Click **New Query** button (top right)
3. You'll see an empty SQL editor window

## 1.3 Copy Export Script

1. Open this file on your computer:
   ```
   d:\Nithya\Travel Companion\TravelCompanion\DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql
   ```

2. Open it in Notepad or VS Code

3. **Select ALL** (Ctrl+A)

4. **Copy** (Ctrl+C)

## 1.4 Run Export Script

1. Go back to Supabase SQL Editor window

2. **Paste** the script (Ctrl+V)

3. Click **RUN** button (or press Ctrl+Enter)

4. Wait 5-10 seconds

5. You'll see output in the "Results" panel at bottom

## 1.5 Copy ALL Output (IMPORTANT!)

⚠️ **This is the most important step!** You need to copy ALL rows, not just the first few.

1. Click inside the Results panel

2. Look for a column named **"import_script"**

3. You'll see MANY rows (could be 100-1000+ rows):
   ```
   Row 1:  -- ============================================================================
   Row 2:  -- DATA IMPORT SCRIPT
   Row 10: BEGIN;
   Row 20: INSERT INTO profiles...
   Row 30: INSERT INTO profiles...
   Row 50: INSERT INTO trips...
   Row 100: INSERT INTO expenses...
   Row 500: COMMIT;
   Row 510: -- Statistics
   ```

4. **Scroll down** to see if there are more rows

5. **Select ALL rows:**
   - Click inside the results panel
   - Press **Ctrl+A** (this selects ALL rows, even ones you can't see)

6. **Copy:**
   - Press **Ctrl+C**

## 1.6 Alternative: Download as CSV

If there's too much data to copy:

1. Look for a **Download** or **Export** button in the results panel

2. Click it to download as CSV

3. Open the CSV file in Excel or Notepad

4. Copy the entire "import_script" column

---

# STEP 2: Prepare Import File

## 2.1 Create Import File

1. Open **Notepad** (or VS Code)

2. **Paste** all the data you copied (Ctrl+V)

3. Your file should look like this:

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
-- ... more profiles ...


-- ============================================================================
-- TRIPS DATA
-- ============================================================================


INSERT INTO public.trips (id, name, destination, created_by) VALUES (...);
INSERT INTO public.trips (id, name, destination, created_by) VALUES (...);
-- ... more trips ...


-- ============================================================================
-- TRIP MEMBERS DATA
-- ============================================================================


INSERT INTO public.trip_members (id, trip_id, user_id) VALUES (...);
-- ... more trip members ...


-- ... more sections for other tables ...


COMMIT;


-- ============================================================================
-- MIGRATION STATISTICS
-- ============================================================================


-- Profiles exported: 10
-- Trips exported: 25
-- Trip members exported: 47
-- Expenses exported: 103
-- ... more statistics ...
```

## 2.2 Save the File

1. Click **File** → **Save As**

2. Save as:
   - **File name:** `MY_DATA_IMPORT.sql`
   - **Location:** `d:\Nithya\Travel Companion\TravelCompanion\`
   - **Save as type:** All Files (*.*)

3. Click **Save**

## 2.3 Verify the File

1. Check the file size:
   - Right-click `MY_DATA_IMPORT.sql`
   - Click **Properties**
   - Size should be at least 50 KB (if you have data)
   - If it's less than 10 KB, you might not have copied everything

2. Open the file and check:
   - ✅ Starts with `BEGIN;`
   - ✅ Has multiple sections (PROFILES, TRIPS, EXPENSES, etc.)
   - ✅ Has many INSERT statements
   - ✅ Ends with `COMMIT;`
   - ✅ Has statistics at the end

---

# STEP 3: Import Data to NEW Database

## 3.1 PREREQUISITE: Create Schema First

⚠️ **IMPORTANT:** You MUST run this BEFORE importing data!

### Option A: If you haven't created the schema yet

1. Login to https://supabase.com with **grayprogrammers008@gmail.com**

2. Open your NEW TravelCompanion project

3. Go to **SQL Editor** → **New Query**

4. Open file: `CLEAN_MIGRATION.sql`

5. Copy entire contents

6. Paste into SQL Editor

7. Click **RUN**

8. Wait for "Success" message (30-60 seconds)

9. Now you're ready to import data!

### Option B: If you already created the schema

Skip to 3.2

## 3.2 Login to NEW Supabase

1. Go to https://supabase.com

2. If you were logged into OLD account, logout first:
   - Click your profile icon (top right)
   - Click **Sign Out**

3. Click **Sign In**

4. Email: **grayprogrammers008@gmail.com**

5. Enter password

6. Click on your **NEW TravelCompanion** project

## 3.3 Open SQL Editor

1. Click **SQL Editor** in left sidebar

2. Click **New Query**

## 3.4 Copy Import File

1. Open your saved file: `MY_DATA_IMPORT.sql`

2. **Select ALL** (Ctrl+A)

3. **Copy** (Ctrl+C)

## 3.5 Run Import

1. Go back to Supabase SQL Editor

2. **Paste** (Ctrl+V)

3. Click **RUN** button

4. Wait for completion:
   - Small dataset (< 100 records): 5-10 seconds
   - Medium dataset (100-1000 records): 30-60 seconds
   - Large dataset (1000+ records): 1-5 minutes

5. Look for success message:
   ```
   Success. No rows returned
   ```

   Or it might show:
   ```
   Rows affected: 0
   ```

   **Both are correct!** The import uses `ON CONFLICT DO NOTHING`, so it won't return row counts.

---

# STEP 4: Verify Import

## 4.1 Check Data Imported

Run these queries in the NEW database SQL Editor:

```sql
-- Check profiles imported
SELECT COUNT(*) as profile_count FROM profiles;

-- Check trips imported
SELECT COUNT(*) as trip_count FROM trips;

-- Check trip members imported
SELECT COUNT(*) as trip_member_count FROM trip_members;

-- Check expenses imported
SELECT COUNT(*) as expense_count FROM expenses;

-- Check checklists imported
SELECT COUNT(*) as checklist_count FROM checklists;

-- Check checklist items imported
SELECT COUNT(*) as checklist_item_count FROM checklist_items;

-- Check expense splits imported
SELECT COUNT(*) as expense_split_count FROM expense_splits;
```

## 4.2 Compare with Export Statistics

Look at the bottom of your `MY_DATA_IMPORT.sql` file:

```sql
-- Profiles exported: 10
-- Trips exported: 25
-- Trip members exported: 47
-- ...
```

**Compare these numbers with the counts from Step 4.1.**

✅ If they match → Perfect! All data imported successfully!

❌ If they don't match → Some data might not have imported. Check for errors.

## 4.3 Check Actual Data

Run these queries to see actual records:

```sql
-- See profiles
SELECT id, email, full_name FROM profiles LIMIT 10;

-- See trips with creator names
SELECT t.name, t.destination, p.full_name as creator
FROM trips t
JOIN profiles p ON t.created_by = p.id
LIMIT 10;

-- See expenses
SELECT title, amount, paid_by FROM expenses LIMIT 10;

-- Check foreign key relationships work
SELECT
    t.name as trip,
    COUNT(tm.id) as member_count
FROM trips t
LEFT JOIN trip_members tm ON tm.trip_id = t.id
GROUP BY t.id, t.name
LIMIT 10;
```

If you see data in these queries → ✅ Import successful!

---

# Troubleshooting

## Problem: "relation does not exist"

**Error Example:**
```
ERROR: relation "public.profiles" does not exist
```

**Solution:**
You didn't run `CLEAN_MIGRATION.sql` first!

1. Go back to Step 3.1
2. Run `CLEAN_MIGRATION.sql` to create all tables
3. Then run your import script again

---

## Problem: "duplicate key value violates unique constraint"

**Error Example:**
```
ERROR: duplicate key value violates unique constraint "profiles_pkey"
```

**Solution:**
This is normal if you run the import twice. The script uses `ON CONFLICT DO NOTHING`, so duplicates are skipped. The import should still succeed.

If you want to re-import from scratch:

1. Delete existing data:
   ```sql
   TRUNCATE TABLE profiles CASCADE;
   ```

2. Run import script again

---

## Problem: "foreign key constraint violation"

**Error Example:**
```
ERROR: insert or update on table "trips" violates foreign key constraint
```

**Solution:**
The import script is in the wrong order (child tables before parent tables).

Run this to check the import order in your file:
- Profiles should come FIRST
- Trips should come SECOND (after profiles)
- Trip members should come THIRD (after trips)
- Everything else after that

If order is wrong, re-run the export script to generate correct order.

---

## Problem: "No data appears when I query"

**Possible causes:**

1. **Import didn't run:**
   - Check for success message after running import
   - Look for error messages

2. **Import ran but no data was exported:**
   - Check OLD database has data: `SELECT COUNT(*) FROM profiles;`
   - Re-run export script

3. **Data imported but RLS policies blocking access:**
   - Check RLS policies exist
   - Try using service_role key temporarily to test

---

## Problem: "Only profiles imported, other tables empty"

**Solution:**
You didn't copy ALL the output from the export script.

1. Go back to OLD database
2. Re-run the export script
3. Make sure you scroll down and see ALL sections
4. Use Ctrl+A to select ALL rows (not just visible ones)
5. Copy and save again

---

## Problem: "File is too large to paste"

**Solution:**

If you have a huge dataset (10,000+ records):

**Option 1: Split into chunks**
1. Copy only first 500 rows
2. Import those
3. Copy next 500 rows
4. Import those
5. Repeat

**Option 2: Use pg_dump (advanced)**
See: `DATA_MIGRATION_GUIDE.md` for pg_dump instructions

---

# Summary

## ✅ What You Accomplished:

1. **Exported data from OLD database** (palkarfoods224@gmail.com)
   - All profiles (10 users)
   - All trips
   - All expenses
   - All checklists
   - All other tables

2. **Created import file** (`MY_DATA_IMPORT.sql`)
   - Contains all INSERT statements
   - Properly formatted SQL

3. **Imported to NEW database** (grayprogrammers008@gmail.com)
   - All tables populated
   - Foreign keys intact
   - Data verified

## 📊 Verification Checklist:

- [ ] Can see profiles in NEW database
- [ ] Can see trips in NEW database
- [ ] Can see expenses in NEW database
- [ ] Row counts match export statistics
- [ ] Foreign key relationships work (trips show correct creators)
- [ ] No errors when querying data

## 🎯 Next Steps:

Now that data is migrated, you need to:

1. **Create storage buckets** (avatars, trip-covers, receipts)
2. **Migrate storage files** (profile pictures, trip images)
3. **Handle authentication users** (users re-register or contact Supabase support)
4. **Update app configuration** (new Supabase URL and keys)
5. **Test the app** with new database

---

# Quick Reference

## File Locations:

```
d:\Nithya\Travel Companion\TravelCompanion\
├── CLEAN_MIGRATION.sql              (Run FIRST in NEW database)
├── DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql  (Run in OLD database)
├── MY_DATA_IMPORT.sql               (Generated file - run in NEW database)
└── This guide
```

## Important Commands:

```sql
-- Check table exists
SELECT * FROM information_schema.tables WHERE table_name = 'profiles';

-- Count records
SELECT COUNT(*) FROM profiles;

-- See data
SELECT * FROM profiles LIMIT 10;

-- Check foreign keys work
SELECT t.*, p.full_name FROM trips t JOIN profiles p ON t.created_by = p.id;

-- Clear all data (be careful!)
TRUNCATE TABLE profiles CASCADE;
```

---

# Need More Help?

If you get stuck:

1. **Check error message carefully** - it usually tells you what's wrong
2. **Verify schema exists** - Run `\dt` to list tables
3. **Check data in OLD database** - Make sure there's data to export
4. **Re-read this guide** - Make sure you didn't skip a step
5. **Ask for help** - Provide:
   - Error message (exact text)
   - Which step you're on
   - Screenshot if possible

---

**Good luck with your migration! 🚀**
