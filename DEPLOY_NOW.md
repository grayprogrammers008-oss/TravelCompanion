# 🚀 Deploy Database Schema - Quick Guide

## ⚡ 3-Minute Deployment

### Step 1: Open Supabase SQL Editor
1. Go to: https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai
2. Click **SQL Editor** (⚡ icon) in left sidebar
3. Click **New Query** button

### Step 2: Copy & Run Schema
1. Open `SUPABASE_SCHEMA.sql` in this folder
2. Select all (Cmd+A) and copy (Cmd+C)
3. Paste into Supabase SQL Editor
4. Click **Run** or press `Cmd+Enter`
5. Wait 5-10 seconds

### Step 3: Verify Success
You should see:
```
✅ TRAVEL CREW DATABASE SCHEMA DEPLOYED SUCCESSFULLY!

📊 Tables Created (12):
   ✓ profiles         - User profiles extending auth.users
   ✓ trips            - Group travel trips
   ✓ trip_members     - Trip crew/members
   ✓ trip_invites     - Invitation system
   ✓ itinerary_items  - Daily activities
   ✓ checklists       - Packing/todo lists
   ✓ checklist_items  - Checklist items
   ✓ expenses         - Shared expenses
   ✓ expense_splits   - Expense distribution
   ✓ settlements      - Payment records
   ✓ autopilot_suggestions - AI recommendations
   ✓ notifications    - In-app notifications
```

## ✅ Verify Tables

1. Click **Table Editor** (📋 icon) in left sidebar
2. You should see 12 new tables
3. Click on any table to see its structure

## 🎉 Done! Run Your App

```bash
flutter run
```

Look for:
```
✅ Supabase initialized successfully
✅ SQLite database initialized successfully
```

---

## 🧪 Test It

1. **Sign Up**: Create a new account in the app
2. **Check Supabase**: Go to Authentication → Users (you should see your account!)
3. **Create Trip**: Add a new trip in the app
4. **Check Supabase**: Go to Table Editor → trips (you should see your trip!)

---

## ❌ If You See Errors

**"relation does not exist"**: This is fixed! Just re-run the schema.

**"permission denied"**: Make sure you're logged into the correct Supabase account.

**"already exists"**: The schema will drop and recreate. Re-run it.

---

## 📚 Full Documentation

- Detailed guide: [SUPABASE_DEPLOYMENT_GUIDE.md](SUPABASE_DEPLOYMENT_GUIDE.md)
- Quick reference: [SUPABASE_QUICK_START.md](SUPABASE_QUICK_START.md)
- Integration details: [SUPABASE_INTEGRATION.md](SUPABASE_INTEGRATION.md)

---

**Ready? Go deploy! 🚀**
