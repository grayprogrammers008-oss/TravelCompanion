# 🚀 Supabase Migration Quick Start

**From:** palkarfoods224@gmail.com → **To:** grayprogrammers008@gmail.com

---

## ⏱️ Estimated Time: 30-45 minutes

---

## 📋 Quick Checklist

### Before You Start (5 min)
- [ ] Create new Supabase project with grayprogrammers008@gmail.com
- [ ] Note down NEW project URL and anon key
- [ ] Keep OLD project dashboard open in another tab

### Migration Steps (20-30 min)
- [ ] **Step 1:** Run migration script (10 min)
- [ ] **Step 2:** Migrate data (10 min)
- [ ] **Step 3:** Migrate storage files (5 min)
- [ ] **Step 4:** Update app configuration (5 min)

### Testing (10 min)
- [ ] Test authentication
- [ ] Test data operations
- [ ] Test file uploads

---

## 🎯 Method 1: Automated (Recommended)

### Prerequisites
Install Supabase CLI:
```bash
npm install -g supabase
```

### Run Migration Script
```bash
cd "d:\Nithya\Travel Companion\TravelCompanion"
migrate_to_new_supabase.bat
```

Follow the prompts:
1. Login to Supabase
2. Enter OLD project ref: `ckgaoxajvonazdwpsmai`
3. Enter NEW project ref: `[your-new-project-ref]`
4. Confirm migration

**What this does:**
- ✅ Exports schema from old project
- ✅ Applies all 37 migration files to new project
- ✅ Preserves all tables, functions, triggers, RLS policies

---

## 🎯 Method 2: Manual (No CLI Required)

### Step 1: Copy Schema (15 min)

**In OLD project (palkarfoods224):**
1. Go to SQL Editor
2. Copy all migration files from `supabase/migrations/` folder
3. Run them one by one in order (by date)

**Files to run (in order):**
```
20250125_admin_trip_management.sql
20250125_fix_trip_admin_function.sql
20250127_trip_notifications.sql
... (all 37 files)
20251225_discover_favorites.sql
```

**In NEW project (grayprogrammers008):**
1. Go to SQL Editor
2. Paste and run each migration file
3. Verify no errors

### Step 2: Copy Data (10 min)

**For each table:**

**In OLD project:**
1. Go to Table Editor
2. Select table (e.g., `trips`)
3. Click "Export" → "CSV"
4. Save file

**In NEW project:**
1. Go to Table Editor
2. Select same table
3. Click "Import" → "CSV"
4. Upload saved file

**Important tables to migrate:**
- [ ] profiles
- [ ] trips
- [ ] trip_members
- [ ] expenses
- [ ] checklists
- [ ] checklist_items
- [ ] itinerary_days
- [ ] itinerary_activities
- [ ] conversations
- [ ] messages

### Step 3: Copy Storage (5 min)

**In OLD project:**
1. Go to Storage
2. For each bucket (avatars, trip-images, etc.):
   - Download all files

**In NEW project:**
1. Go to Storage
2. Create bucket with same name
3. Upload downloaded files

---

## 📝 Post-Migration: Update App Config

### Quick Update (Copy-Paste)

**Open:** `lib/core/config/supabase_config.dart`

**Find line 13:**
```dart
defaultValue: 'https://ckgaoxajvonazdwpsmai.supabase.co',
```

**Replace with:**
```dart
defaultValue: 'https://YOUR-NEW-PROJECT-REF.supabase.co',
```

**Find line 19:**
```dart
defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg',
```

**Replace with:**
```dart
defaultValue: 'YOUR-NEW-ANON-KEY-HERE',
```

**Get new credentials from:**
- New project → Settings → API
- Copy "Project URL"
- Copy "anon public" key

---

## 🧪 Quick Test

```bash
flutter clean
flutter pub get
flutter run
```

**Test these features:**
1. Login/Signup ✓
2. View trips ✓
3. Create new trip ✓
4. Upload image ✓

---

## 🆘 Quick Troubleshooting

### Error: "Invalid API Key"
**Fix:** Double-check anon key is complete (starts with `eyJ...`)

### Error: "Connection Failed"
**Fix:** Verify URL format: `https://xxxxx.supabase.co` (no trailing slash)

### Error: "Permission Denied"
**Fix:** Check RLS policies are migrated (SQL Editor → Policies)

### Data Missing
**Fix:** Re-export/import CSV files for affected tables

---

## 📚 Detailed Guides

For more details, see:
- **Full Guide:** `SUPABASE_MIGRATION_GUIDE.md` (comprehensive)
- **Config Update:** `UPDATE_CONFIG_AFTER_MIGRATION.md` (step-by-step)

---

## 🎉 Migration Complete Checklist

Once everything works:
- [ ] Old project data matches new project data
- [ ] App connects to new project
- [ ] Authentication works
- [ ] CRUD operations work
- [ ] File uploads work
- [ ] No errors in console

### Keep Old Project Active
- ✅ Keep old project active for 1-2 weeks as backup
- ✅ Monitor new project for any issues
- ✅ Once stable, you can pause/delete old project

---

## 📊 Migration Summary

| Item | Old Project | New Project | Status |
|------|-------------|-------------|--------|
| Project Ref | `ckgaoxajvonazdwpsmai` | `[new-ref]` | ⏳ |
| Account | palkarfoods224@gmail.com | grayprogrammers008@gmail.com | ⏳ |
| Schema | 37 migrations | 37 migrations | ⏳ |
| Data | [X tables] | [X tables] | ⏳ |
| Storage | [Y buckets] | [Y buckets] | ⏳ |
| App Config | Old URL/Key | New URL/Key | ⏳ |

---

**Good luck with your migration! 🚀**

If you encounter issues, check the detailed guides or reach out to Supabase support.
