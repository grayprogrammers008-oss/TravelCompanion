# 🎯 Complete Migration Checklist

## Quick Overview

**Migrating from:** palkarfoods224@gmail.com → grayprogrammers008@gmail.com

**Total Time:** 1-2 hours

---

## Phase 1: Setup (15 minutes)

### ✅ Create New Supabase Project

- [ ] Login to Supabase with grayprogrammers008@gmail.com
- [ ] Create new project: "TravelCompanion"
- [ ] Save database password
- [ ] Save Project URL
- [ ] Save anon/public API key

**File:** None needed

---

## Phase 2: Database Schema (15 minutes)

### ✅ Create All Tables, Functions, Policies

- [ ] Login to NEW Supabase
- [ ] Open SQL Editor
- [ ] Copy `CLEAN_MIGRATION.sql`
- [ ] Paste and RUN
- [ ] Verify success: `SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';`
  - Should return: 26 tables

**File:** `CLEAN_MIGRATION.sql`

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 3: Export Data from OLD Database (5 minutes)

### ✅ Export All Data

- [ ] Login to OLD Supabase (palkarfoods224@gmail.com)
- [ ] Open SQL Editor
- [ ] Copy `DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql`
- [ ] Paste and RUN
- [ ] Copy ALL output (Ctrl+A, Ctrl+C)
- [ ] Save to `MY_DATA_IMPORT.sql`
- [ ] Verify file size > 10 KB

**File:** `DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql` (run in OLD)

**Output:** `MY_DATA_IMPORT.sql`

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 4: Import Data to NEW Database (10 minutes)

### ✅ Import All Data

- [ ] Login to NEW Supabase (grayprogrammers008@gmail.com)
- [ ] Open SQL Editor
- [ ] Copy `MY_DATA_IMPORT.sql`
- [ ] Paste and RUN
- [ ] Wait for "Success" message
- [ ] Verify data imported:

```sql
SELECT
  (SELECT COUNT(*) FROM profiles) as profiles,
  (SELECT COUNT(*) FROM trips) as trips,
  (SELECT COUNT(*) FROM expenses) as expenses;
```

**File:** `MY_DATA_IMPORT.sql` (run in NEW)

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 5: Storage Buckets (10 minutes)

### ✅ Create Storage Buckets

- [ ] Login to NEW Supabase
- [ ] Go to Storage
- [ ] Create bucket: `avatars` (Public, 2 MB)
- [ ] Create bucket: `trip-covers` (Public, 5 MB)
- [ ] Create bucket: `receipts` (Private, 10 MB)

**File:** None (use Dashboard UI)

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 6: Storage Policies (2 minutes)

### ✅ Create Storage Policies

- [ ] Login to NEW Supabase
- [ ] Open SQL Editor
- [ ] Copy `CREATE_STORAGE_POLICIES.sql`
- [ ] Paste and RUN
- [ ] Verify: Should create 12 policies (4 per bucket)

**File:** `CREATE_STORAGE_POLICIES.sql`

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 7: Migrate Storage Files (20 minutes)

### ✅ Option A: Manual Upload (< 100 files)

**From OLD Database:**
- [ ] Storage → avatars → Select all → Download
- [ ] Storage → trip-covers → Select all → Download
- [ ] Storage → receipts → Select all → Download

**To NEW Database:**
- [ ] Storage → avatars → Upload files
- [ ] Storage → trip-covers → Upload files
- [ ] Storage → receipts → Upload files

### ✅ Option B: Supabase CLI (> 100 files)

```bash
# Export from OLD
supabase login  # palkarfoods224@gmail.com
supabase link --project-ref OLD_REF
supabase storage export avatars ./backup/avatars
supabase storage export trip-covers ./backup/trip-covers
supabase storage export receipts ./backup/receipts

# Import to NEW
supabase logout
supabase login  # grayprogrammers008@gmail.com
supabase link --project-ref NEW_REF
supabase storage import avatars ./backup/avatars
supabase storage import trip-covers ./backup/trip-covers
supabase storage import receipts ./backup/receipts
```

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 8: Authentication Users (5 minutes + wait time)

### ✅ Option A: User Re-Registration (Recommended)

- [ ] Update Flutter app with user linking code
- [ ] Deploy app with new database config
- [ ] Send email to users (10 users)
- [ ] Users create new accounts with same email
- [ ] App auto-links to existing data

**Time:** 5 minutes setup + users re-register

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

### ✅ Option B: Contact Supabase Support

- [ ] Email support@supabase.com
- [ ] Request auth.users migration
- [ ] Provide OLD and NEW project refs
- [ ] Wait for support (1-2 business days)

**Time:** 5 minutes + 1-2 days wait

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 9: Update App Configuration (10 minutes)

### ✅ Update Flutter App

- [ ] Get NEW Supabase URL from Settings → API
- [ ] Get NEW anon key from Settings → API
- [ ] Update `lib/main.dart` or config file:

```dart
const supabaseUrl = 'https://NEW_PROJECT.supabase.co';
const supabaseAnonKey = 'NEW_ANON_KEY';
```

- [ ] Test build locally
- [ ] Deploy to production

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 10: Testing & Verification (15 minutes)

### ✅ Database Testing

```sql
-- Check all tables exist
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
-- Should return: 26

-- Check data counts
SELECT
  (SELECT COUNT(*) FROM profiles) as profiles,
  (SELECT COUNT(*) FROM trips) as trips,
  (SELECT COUNT(*) FROM trip_members) as trip_members,
  (SELECT COUNT(*) FROM expenses) as expenses,
  (SELECT COUNT(*) FROM checklists) as checklists;

-- Check foreign keys work
SELECT t.name, p.full_name as creator
FROM trips t
JOIN profiles p ON t.created_by = p.id
LIMIT 5;
```

### ✅ Storage Testing

- [ ] Go to Storage → avatars → Upload test image
- [ ] Verify can view uploaded image
- [ ] Check public URL works
- [ ] Test private bucket (receipts) requires auth

### ✅ App Testing

- [ ] User can register/login
- [ ] Profile data loads
- [ ] Trips display correctly
- [ ] Trip members show correctly
- [ ] Expenses load
- [ ] Checklists work
- [ ] Images/avatars load
- [ ] Can create new trip
- [ ] Can add expense
- [ ] Can send message
- [ ] No errors in console

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 11: Cleanup (Optional)

### ✅ After 1-2 Weeks of Successful Operation

- [ ] Verify NEW database working perfectly
- [ ] No user complaints
- [ ] All features functional
- [ ] Backup OLD database (pg_dump)
- [ ] Archive OLD Supabase project (don't delete immediately)
- [ ] After 1 month, can delete OLD project

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## 📊 Progress Tracker

Track your overall progress:

```
Phase 1:  Setup                    ⬜
Phase 2:  Database Schema          ⬜
Phase 3:  Export Data              ⬜
Phase 4:  Import Data              ⬜
Phase 5:  Storage Buckets          ⬜
Phase 6:  Storage Policies         ⬜
Phase 7:  Migrate Files            ⬜
Phase 8:  Auth Users               ⬜
Phase 9:  Update App Config        ⬜
Phase 10: Testing                  ⬜
Phase 11: Cleanup                  ⬜
```

**Overall Status:** 0/11 Complete (0%)

---

## 🚨 Critical Files Needed

Make sure you have these files ready:

- ✅ `CLEAN_MIGRATION.sql` - Creates database schema
- ✅ `DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql` - Exports data from OLD
- ⬜ `MY_DATA_IMPORT.sql` - Generated after export (you create this)
- ✅ `CREATE_STORAGE_POLICIES.sql` - Creates storage policies
- ✅ `DATA_EXPORT_IMPORT_COMPLETE_GUIDE.md` - Step-by-step guide

**All files location:** `d:\Nithya\Travel Companion\TravelCompanion\`

---

## 🎯 Quick Start - Do This First!

If you're starting fresh right now:

1. ✅ **Create NEW Supabase project** (5 min)
2. ✅ **Run CLEAN_MIGRATION.sql** in NEW database (15 min)
3. ✅ **Run DATA_MIGRATION_EXPORT_BARE_MINIMUM.sql** in OLD database (5 min)
4. ✅ **Save output as MY_DATA_IMPORT.sql** (2 min)
5. ✅ **Run MY_DATA_IMPORT.sql in NEW database** (5 min)
6. ✅ **Verify data imported** (2 min)

**Then you're 50% done!** 🎉

---

## 📞 Need Help?

If you get stuck on any phase:

1. Check the detailed guide for that phase
2. Look for error messages
3. Verify prerequisites completed
4. Ask for help with:
   - Which phase you're on
   - Error message
   - What you've tried

---

**Good luck with your migration! 🚀**

Update this checklist as you go by changing ⬜ to ✅
