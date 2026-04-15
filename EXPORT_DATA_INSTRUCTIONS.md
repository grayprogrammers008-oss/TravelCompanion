# Step-by-Step: Export Data from OLD Database

## 🎯 Goal
Export ALL data from palkarfoods224@gmail.com database to importable SQL format

---

## Step 1: Login to OLD Supabase Account

1. Open browser: https://supabase.com
2. Click **Sign In**
3. Enter email: **palkarfoods224@gmail.com**
4. Enter password
5. Click on your **TravelCompanion** project

---

## Step 2: Open SQL Editor

1. In left sidebar, click **SQL Editor**
2. Click **New Query** button (top right)
3. You'll see an empty SQL editor

---

## Step 3: Run Export Script

### Copy the Export Script:

1. Open this file: `DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql`
2. Press **Ctrl+A** (select all)
3. Press **Ctrl+C** (copy)

### Run in Supabase:

1. Go back to Supabase SQL Editor
2. Press **Ctrl+V** (paste the script)
3. Click **RUN** button (or press Ctrl+Enter)
4. Wait 5-10 seconds for execution

---

## Step 4: Copy ALL Output

### Important: Copy Everything!

The output will have MANY rows (not just 10). You need to copy ALL of them.

**In the Results panel at bottom:**

1. You'll see a column named `import_script`
2. Scroll down to see ALL rows (there could be 100-1000+ rows)
3. Click inside the results area
4. Press **Ctrl+A** (select all results)
5. Press **Ctrl+C** (copy all results)

### ⚠️ Common Mistake:
- Don't just copy the first 10 rows!
- Make sure you scroll down and see:
  - Profiles data
  - Trips data
  - Trip members data
  - Expenses data
  - Checklists data
  - Statistics at the end

---

## Step 5: Save to File

### Create Import File:

1. Open **Notepad** or **VS Code**
2. Press **Ctrl+V** (paste all copied data)
3. Save file as: `MY_DATA_EXPORT.sql`
4. Location: `d:\Nithya\Travel Companion\TravelCompanion\MY_DATA_EXPORT.sql`

### Your file should look like this:

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
-- ... (all 10 profiles)

-- ============================================================================
-- TRIPS DATA
-- ============================================================================

INSERT INTO public.trips (id, name, destination, created_by) VALUES (...);
INSERT INTO public.trips (id, name, destination, created_by) VALUES (...);
-- ... (all your trips)

-- ============================================================================
-- TRIP MEMBERS DATA
-- ============================================================================

INSERT INTO public.trip_members (id, trip_id, user_id) VALUES (...);
-- ... (all trip members)

-- ============================================================================
-- EXPENSES DATA
-- ============================================================================

INSERT INTO public.expenses (id, trip_id, title, amount, paid_by) VALUES (...);
-- ... (all expenses)

-- ... (more sections)

COMMIT;

-- ============================================================================
-- MIGRATION STATISTICS
-- ============================================================================

-- Profiles exported: 10
-- Trips exported: 25
-- Trip members exported: 47
-- Expenses exported: 103
-- ... (your actual numbers)
```

---

## Step 6: Verify Your Export

### Check File Size:
- If file is less than 10 KB → You probably didn't copy everything
- If file is 50-500 KB → Good! You got all the data
- If file is > 1 MB → Excellent! Lots of data

### Check Content:
Open `MY_DATA_EXPORT.sql` and verify you see:

- [ ] Header comments at top
- [ ] `BEGIN;` statement
- [ ] Section: PROFILES DATA (with INSERT statements)
- [ ] Section: TRIPS DATA (with INSERT statements)
- [ ] Section: TRIP MEMBERS DATA
- [ ] Section: ITINERARY ITEMS DATA
- [ ] Section: CHECKLISTS DATA
- [ ] Section: CHECKLIST ITEMS DATA
- [ ] Section: EXPENSES DATA
- [ ] Section: EXPENSE SPLITS DATA
- [ ] `COMMIT;` statement
- [ ] Statistics section at end

---

## Step 7: Check Statistics

At the bottom of your export file, you should see something like:

```sql
-- Profiles exported: 10
-- Trips exported: 25
-- Trip members exported: 47
-- Itinerary items exported: 89
-- Checklists exported: 12
-- Checklist items exported: 156
-- Expenses exported: 203
-- Expense splits exported: 456
```

**Write down these numbers!** You'll use them to verify the import later.

---

## Troubleshooting

### Problem: "Nothing happens when I click RUN"
**Solution:** Check that you pasted the script correctly. Try refreshing the page and pasting again.

### Problem: "Error: column does not exist"
**Solution:** The script is trying to export columns that don't exist in your old database. This is expected - the script will skip those tables. Keep the output you got.

### Problem: "Only see 10 rows in output"
**Solution:**
1. Look for a scroll bar in the results panel
2. Scroll down to see more rows
3. Use Ctrl+A to select ALL rows (not just visible ones)

### Problem: "CSV file instead of SQL"
**Solution:**
- Supabase might download as CSV
- Open the CSV in Excel/Notepad
- Copy the "import_script" column contents
- Save as `.sql` file

### Problem: "Too much data to display"
**Solution:**
- Click the "Download CSV" button in results panel
- Open the downloaded CSV
- Copy all contents from "import_script" column
- Save as SQL file

---

## Next Steps

Once you have `MY_DATA_EXPORT.sql` file with ALL data:

✅ **You're ready for Step 4:** Import data to NEW database

---

## Need Help?

If you get stuck:
1. Take a screenshot of the Supabase SQL Editor
2. Take a screenshot of the error (if any)
3. Tell me:
   - How many rows you see in the output
   - What's at the bottom of your export file
   - File size of your export

I'll help you troubleshoot!
