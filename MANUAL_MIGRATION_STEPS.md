
# Manual Supabase Migration Steps (No CLI Required)

Since Supabase CLI installation has issues, here's a simple manual migration process.

---

## ⏱️ Estimated Time: 45-60 minutes

---

## Step 1: Create New Supabase Project (5 minutes)

1. **Open browser** and go to: https://supabase.com
2. **Login** with: `grayprogrammers008@gmail.com`
3. Click **"New Project"**
4. Fill in:
   - **Name:** TravelCompanion
   - **Database Password:** [Choose a strong password - SAVE IT!]
   - **Region:** Same as old project (Southeast Asia or closest to you)
   - **Pricing Plan:** Free (or your preferred plan)
5. Click **"Create new project"**
6. Wait 2-3 minutes for project to be ready
7. **Save these credentials:**
   - Project URL: `https://______.supabase.co`
   - Anon Key: `eyJ...` (from Settings → API)

---

## Step 2: Apply All 37 Migrations (30-40 minutes)

You need to run each SQL migration file in order. Here's the complete list:

### Method A: Copy-Paste Each File (Recommended)

**In your new Supabase project:**
1. Go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. For each file below, copy its content and run it
4. Wait for "Success" message before moving to next file
5. If you get an error, note it down and continue (we'll fix later)

### Migration Files (Run in This Order):

```
1.  20250125_admin_trip_management.sql
2.  20250125_fix_trip_admin_function.sql
3.  20250127_trip_notifications.sql
4.  20250128_admin_user_management.sql
5.  20250129_fix_admin_rls.sql
6.  20250130_disable_admin_checks_temp.sql
7.  20250131_fix_function_return_types.sql
8.  20250131_fix_user_statistics_view.sql
9.  20250201_storage_buckets_setup.sql
10. 20250202_add_trip_visibility.sql
11. 20250202_google_places_integration.sql
12. 20250202_hospitals_emergency_service.sql
13. 20250202_openstreetmap_integration.sql
14. 20251129_admin_checklist_management.sql
15. 20251129_admin_expense_management.sql
16. 20251202_group_chat.sql
17. 20251203_trip_join_requests.sql
18. 20251203_trip_member_permissions_rls.sql
19. 20251204_create_trip_templates_schema.sql
20. 20251204_group_chat_fix.sql
21. 20251204_seed_trip_templates.sql
22. 20251204_trip_templates.sql
23. 20251205_dm_display_name.sql
24. 20251206_auto_create_all_members_group.sql
25. 20251206_fix_conversation_details.sql
26. 20251207_fix_default_group_membership.sql
27. 20251207_fix_message_delete_rls.sql
28. 20251207_user_delete_trip.sql
29. 20251208_fix_last_read_at_for_new_members.sql
30. 20251208_mark_conversation_as_read_function.sql
31. 20251210_fix_unread_count_calculation.sql
32. 20251213_itinerary_location_columns.sql
33. 20251221_place_cache.sql
34. 20251223_rename_budget_to_cost.sql
35. 20251224_copy_trip.sql
36. 20251224_trip_favorites.sql
37. 20251225_discover_favorites.sql
```

**How to apply each file:**

1. Open file in VS Code: `supabase/migrations/[filename]`
2. Select All (Ctrl+A), Copy (Ctrl+C)
3. Go to Supabase SQL Editor
4. Paste (Ctrl+V)
5. Click **"Run"** or press Ctrl+Enter
6. Wait for "Success" ✓
7. Move to next file

**Pro Tip:** Keep a checklist and mark off each file as you complete it!

---

## Step 3: Verify Schema (5 minutes)

After running all migrations, verify the database structure:

**In SQL Editor, run:**

```sql
-- Check all tables created
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

**You should see tables like:**
- profiles
- trips
- trip_members
- expenses
- checklists
- checklist_items
- itinerary_days
- itinerary_activities
- conversations
- messages
- etc.

**Check functions:**
```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public';
```

---

## Step 4: Export Data from Old Project (10-15 minutes)

**Login to OLD project** (`palkarfoods224@gmail.com`)

### For Each Important Table:

**Tables to export (in this order):**
1. profiles
2. trips
3. trip_members
4. trip_favorites
5. expenses
6. checklists
7. checklist_items
8. itinerary_days
9. itinerary_activities
10. conversations
11. conversation_members
12. messages

**How to export:**
1. Go to **Table Editor**
2. Click table name
3. Click **"Export"** button (top right)
4. Choose **"CSV"**
5. Save file as `[table_name].csv`

**Save all CSV files in a folder like:**
`D:\Nithya\Travel Companion\migration_backup\`

---

## Step 5: Import Data to New Project (10-15 minutes)

**Login to NEW project** (`grayprogrammers008@gmail.com`)

### For Each Table You Exported:

1. Go to **Table Editor**
2. Click table name
3. Click **"Insert"** → **"Import data from CSV"**
4. Select the CSV file you exported
5. Click **"Import"**
6. Wait for success message

**⚠️ Import in the same order you exported!**
(This maintains referential integrity - e.g., trips must exist before trip_members)

---

## Step 6: Migrate Storage (10 minutes)

### Copy Storage Buckets:

**In OLD project:**
1. Go to **Storage**
2. You should see buckets like:
   - `avatars`
   - `trip-images`
   - `expense-receipts`
3. For each bucket:
   - Click bucket name
   - Download all files (if manageable size)
   - Note bucket settings (Public/Private)

**In NEW project:**
1. Go to **Storage**
2. Click **"Create new bucket"**
3. For each bucket:
   - Same name as old bucket
   - Same public/private settings
   - Upload downloaded files

**If too many files:**
- You can skip this for now
- New uploads will go to new project
- Old files remain accessible in old project temporarily

---

## Step 7: Update App Configuration (5 minutes)

### Update Supabase Config:

**Open:** `lib/core/config/supabase_config.dart`

**Line 13 - Update URL:**
```dart
defaultValue: 'https://YOUR-NEW-PROJECT-REF.supabase.co',
```

**Line 19 - Update Anon Key:**
```dart
defaultValue: 'eyJ...YOUR-NEW-ANON-KEY...',
```

**Get new credentials from:**
- New project → **Settings** → **API**
- Copy **Project URL**
- Copy **anon public** key

**Line 37 - Update Email (Optional):**
```dart
defaultValue: 'grayprogrammers008@gmail.com', // NEW EMAIL
```

---

## Step 8: Test the App (10 minutes)

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Test Checklist:**
- [ ] App starts without errors
- [ ] Can see login/signup page
- [ ] Can login (if you have test account)
- [ ] Can see trips list
- [ ] Can create new trip
- [ ] Can upload images
- [ ] No errors in console

---

## ✅ Migration Complete Checklist

```
Setup:
[x] New Supabase project created
[x] New project credentials saved

Schema:
[x] All 37 migration files applied
[x] Tables verified in new project
[x] Functions verified

Data:
[x] Data exported from old project (CSV files)
[x] Data imported to new project
[x] Row counts match between old and new

Storage:
[x] Storage buckets created
[x] Files migrated (or skipped for later)

App Config:
[x] supabase_config.dart updated with new URL
[x] supabase_config.dart updated with new anon key
[x] App tested and working

Verification:
[x] Login works
[x] Data loads correctly
[x] Can create new data
[x] Images upload (if tested)
[x] No errors in console
```

---

## 🆘 Troubleshooting

### Migration File Fails

**Error:** "relation already exists"
- **Fix:** Skip and continue to next file (table already created)

**Error:** "function already exists"
- **Fix:** Skip and continue (function already created)

**Error:** "permission denied"
- **Fix:** Check you're running in SQL Editor as authenticated user

### CSV Import Fails

**Error:** "foreign key constraint"
- **Fix:** Import tables in correct order (profiles first, then trips, then trip_members, etc.)

**Error:** "duplicate key"
- **Fix:** Table might already have data, clear it first:
  ```sql
  DELETE FROM [table_name];
  ```

### App Won't Connect

**Error:** "Invalid API Key"
- **Fix:** Double-check anon key is complete (starts with `eyJ...`)

**Error:** "Connection timeout"
- **Fix:** Verify URL format: `https://xxxxx.supabase.co` (no trailing slash)

---

## 📊 Data Verification Queries

**Run these in BOTH old and new projects to compare:**

```sql
-- Table row counts
SELECT
    'profiles' as table_name,
    COUNT(*) as row_count
FROM profiles
UNION ALL
SELECT 'trips', COUNT(*) FROM trips
UNION ALL
SELECT 'expenses', COUNT(*) FROM expenses
UNION ALL
SELECT 'checklists', COUNT(*) FROM checklists
UNION ALL
SELECT 'messages', COUNT(*) FROM messages
ORDER BY table_name;
```

**Row counts should match!**

---

## 🎉 Success!

Once all checkboxes are ✓ and the app works:

1. **Keep old project active** for 1-2 weeks as backup
2. **Monitor new project** for any issues
3. **Test thoroughly** over next few days
4. **Once confident:** Pause/delete old project to save costs

---

## 📝 Notes Section

**New Project Details:**
```
Project URL: ___________________________________
Anon Key: ______________________________________
Project Password: ______________________________
Region: ________________________________________
Created: _______________________________________
```

**Migration Date:** ________________

**Issues Encountered:**
_________________________________________________
_________________________________________________
_________________________________________________

**Resolution:**
_________________________________________________
_________________________________________________
_________________________________________________

---

**Good luck with your migration! 🚀**
