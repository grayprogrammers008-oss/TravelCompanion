# ⚡ Quick Migration Steps - Data Migration

## 5 Simple Steps to Migrate Your Data

---

## 📝 Step 1: Setup New Database (10 minutes)

1. **Create new Supabase project**
   - Go to https://supabase.com
   - Log in with `grayprogrammers008@gmail.com`
   - Click "New Project"
   - Name: "TravelCompanion"
   - Save the password!

2. **Run schema migration**
   - Open **SQL Editor** in new project
   - Copy entire `CLEAN_MIGRATION.sql` file
   - Paste and click **RUN**
   - Wait for "Success" message

3. **Create storage buckets**
   - Go to **Storage**
   - Create buckets: `avatars`, `trip-covers`, `receipts`
   - Follow policies from MIGRATION_GUIDE.md

✅ **Your new database is ready!**

---

## 📤 Step 2: Export Data from Old Database (5 minutes)

1. **Log in to old Supabase**
   - Go to https://supabase.com
   - Log in with `palkarfoods224@gmail.com`
   - Open your TravelCompanion project

2. **Run export script**
   - Open **SQL Editor**
   - Copy entire `DATA_MIGRATION_EXPORT.sql` file
   - Paste and click **RUN**

3. **Save the output**
   - Script will print many INSERT statements
   - **Select ALL output** (Ctrl+A)
   - **Copy** (Ctrl+C)
   - Create new file: `MY_DATA_IMPORT.sql`
   - **Paste and Save**

✅ **Your data is exported!**

---

## 📥 Step 3: Import Data to New Database (5 minutes)

1. **Go back to new Supabase**
   - Already logged in with `grayprogrammers008@gmail.com`
   - Open your NEW TravelCompanion project

2. **Run import script**
   - Open **SQL Editor**
   - Copy entire `MY_DATA_IMPORT.sql` file (the one you just created)
   - Paste and click **RUN**
   - Wait for completion (1-5 minutes)

3. **Verify data**
   ```sql
   SELECT COUNT(*) as profiles FROM profiles;
   SELECT COUNT(*) as trips FROM trips;
   SELECT COUNT(*) as messages FROM messages;
   ```

✅ **Your data is imported!**

---

## 📁 Step 4: Migrate Storage Files (10-30 minutes)

### Small Dataset (< 100 files)

1. **Download from old storage**
   - Old Supabase → **Storage** → `avatars`
   - Download all files
   - Repeat for `trip-covers` and `receipts`

2. **Upload to new storage**
   - New Supabase → **Storage** → `avatars`
   - Upload all files
   - Repeat for `trip-covers` and `receipts`

### Large Dataset (> 100 files)

Use Supabase CLI - see DATA_MIGRATION_GUIDE.md for instructions

✅ **Your files are migrated!**

---

## 🔧 Step 5: Update App Configuration (2 minutes)

1. **Get new project credentials**
   - New Supabase → **Settings** → **API**
   - Copy **Project URL**
   - Copy **anon public** key

2. **Update your Flutter app**
   ```dart
   // Update these values:
   const supabaseUrl = 'YOUR_NEW_PROJECT_URL';
   const supabaseAnonKey = 'YOUR_NEW_ANON_KEY';
   ```

3. **Test the app**
   - Run your app
   - Try logging in (may need to create new account)
   - Check if trips load
   - Check if images load

✅ **Migration complete!**

---

## 📋 Quick Checklist

- [ ] New Supabase project created
- [ ] CLEAN_MIGRATION.sql ran successfully
- [ ] Storage buckets created
- [ ] Data exported from old database
- [ ] Data imported to new database
- [ ] Storage files migrated
- [ ] App configuration updated
- [ ] App tested and working

---

## 🎯 Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│  OLD SUPABASE (palkarfoods224@gmail.com)                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Run DATA_MIGRATION_EXPORT.sql                    │  │
│  │  2. Copy output                                       │  │
│  │  3. Save as MY_DATA_IMPORT.sql                       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ (Copy SQL output)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  NEW SUPABASE (grayprogrammers008@gmail.com)               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Run CLEAN_MIGRATION.sql (schema)                 │  │
│  │  2. Run MY_DATA_IMPORT.sql (data)                    │  │
│  │  3. Create storage buckets                           │  │
│  │  4. Upload storage files                             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ (Update config)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  FLUTTER APP                                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Update supabaseUrl                               │  │
│  │  2. Update supabaseAnonKey                           │  │
│  │  3. Test app                                         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Setup new database | 10 min |
| Export data | 5 min |
| Import data | 5 min |
| Migrate storage (small) | 10 min |
| Migrate storage (large) | 30 min |
| Update app config | 2 min |
| **Total** | **32-62 min** |

---

## 🆘 Common Issues

### ❌ "relation does not exist"
**Fix:** Run CLEAN_MIGRATION.sql first

### ❌ Export script returns no output
**Fix:** Check if tables have data in old database

### ❌ Import script fails with errors
**Fix:** Make sure you ran CLEAN_MIGRATION.sql first

### ❌ Can't log in to app
**Fix:** Users may need to create new accounts (auth users not migrated)

### ❌ Images not loading
**Fix:** Storage files need to be migrated separately (Step 4)

---

## 📞 Files You Need

1. **CLEAN_MIGRATION.sql** - Creates database schema (run on NEW database)
2. **DATA_MIGRATION_EXPORT.sql** - Exports your data (run on OLD database)
3. **MY_DATA_IMPORT.sql** - The output you save (run on NEW database)

That's it! Just 3 files and 5 steps.

---

## 💡 Pro Tip

**Test First!**
1. Create a **test** Supabase project first
2. Practice the migration
3. Once comfortable, do the real migration

This way you can make mistakes without affecting anything important.

---

**Ready? Let's go! 🚀**

Start with Step 1 above.
