# How to Add Dummy Data for Nithya

This guide explains how to add sample trips, expenses, and checklists for testing.

---

## 📦 What Dummy Data Will Be Created

### 3 Trips
1. **Weekend Getaway to Goa** (Upcoming - 15 days from now)
   - 3-day beach vacation
   - 6 itinerary items (airport, resort, beach activities, water sports, fort visit)
   - 2 expenses (flights ₹8,500, resort ₹12,000)
   - 1 packing checklist with 8 items

2. **Ooty Hill Station Retreat** (Past - 30 days ago)
   - Completed trip
   - 2 expenses (toy train ₹2,500, tea garden tour ₹1,200)

3. **Kerala Backwaters Experience** (Future - 60 days from now)
   - Planning stage
   - 1 checklist with 4 pre-trip tasks

### Standalone Expenses (3 items)
- Travel guide books ₹1,200
- New backpack ₹3,500
- Travel insurance ₹4,500

**Total Data**:
- 3 Trips
- 6 Expenses
- 6 Itinerary Items
- 2 Checklists (12 items total)

---

## 🚀 How to Run the SQL Script

### Option 1: Using Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Navigate to SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy and Paste SQL**
   - Open `CREATE_NITHYA_DUMMY_DATA.sql`
   - Copy the entire content
   - Paste into the SQL editor

4. **Run the Script**
   - Click "Run" button (or press Cmd/Ctrl + Enter)
   - Wait for completion message

5. **Verify Success**
   - You should see: "✅ Dummy data created successfully!"
   - Along with counts of created items

---

### Option 2: Using Supabase CLI

```bash
# Make sure you're in the project directory
cd /Users/vinothvs/Development/TravelCompanion

# Run the SQL script
supabase db reset --db-url "your-database-url"
```

---

### Option 3: Using psql (PostgreSQL Client)

```bash
# Connect to your Supabase database
psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT].supabase.co:5432/postgres"

# Run the script
\i CREATE_NITHYA_DUMMY_DATA.sql

# Exit
\q
```

---

## ✅ Verification

After running the script, verify the data was created:

### Check Trips
```sql
SELECT id, name, destination, start_date, end_date, status
FROM trips
WHERE created_by = (SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com')
ORDER BY start_date;
```

**Expected**: 3 trips (Ooty, Goa, Kerala)

---

### Check Expenses
```sql
SELECT e.id, e.title, e.amount, e.category, t.name as trip_name
FROM expenses e
LEFT JOIN trips t ON e.trip_id = t.id
WHERE e.paid_by = (SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com')
ORDER BY e.transaction_date DESC;
```

**Expected**: 6 expenses total (3 trip-related, 3 standalone)

---

### Check Checklists
```sql
SELECT c.title, COUNT(ci.id) as items_count,
       SUM(CASE WHEN ci.is_completed THEN 1 ELSE 0 END) as completed_count
FROM checklists c
LEFT JOIN checklist_items ci ON c.id = ci.checklist_id
WHERE c.created_by = (SELECT id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com')
GROUP BY c.id, c.title;
```

**Expected**: 2 checklists with items

---

## 📱 Test in the App

After running the SQL script:

1. **Login** as `nithyaganesan53@gmail.com`
2. **Home Page** - Should show 3 trips
3. **Expenses Tab** - Should show 6 expenses
4. **Goa Trip Details** - Should show:
   - 6 itinerary items
   - 2 expenses
   - 1 checklist with 8 items

---

## 🎨 Customization

You can modify the SQL script to:

### Change Trip Dates
```sql
-- Line 47: Change start date
start_date => CURRENT_DATE + INTERVAL '15 days',  -- Change '15' to your preference
```

### Change Budget
```sql
-- Line 51: Change budget amount
budget => 25000.00,  -- Change to your amount
```

### Add More Expenses
```sql
-- After line 180, add:
INSERT INTO expenses (id, trip_id, title, description, amount, category, paid_by, transaction_date)
VALUES (
    gen_random_uuid(),
    trip1_id,
    'Your Expense Title',
    'Description',
    1500.00,
    'food',  -- or: transport, accommodation, activity, shopping, other
    nithya_user_id,
    CURRENT_DATE
);
```

### Add More Checklist Items
```sql
-- After line 142, add:
INSERT INTO checklist_items (id, checklist_id, title, is_completed, assigned_to, created_by)
VALUES (gen_random_uuid(), checklist1_id, 'Your Item', false, nithya_user_id, nithya_user_id);
```

---

## 🔄 Re-running the Script

**IMPORTANT**: If you get an error like `duplicate key value violates unique constraint`, it means the data already exists. You need to clean up first!

### Option 1: Use the Cleanup Script (Recommended)

We've created a cleanup script to remove all existing data safely:

**File**: `CLEANUP_NITHYA_DATA.sql`

**Steps**:
1. Go to Supabase Dashboard → SQL Editor → New Query
2. Copy entire content from `CLEANUP_NITHYA_DATA.sql`
3. Paste and click **Run**
4. You'll see a summary of deleted items
5. Now run `CREATE_NITHYA_DUMMY_DATA.sql` again

**Expected Output**:
```
Cleaning up dummy data for Nithya (User ID: ...)
   ✓ Deleted 12 checklist items
   ✓ Deleted 2 checklists
   ✓ Deleted 6 expense splits
   ✓ Deleted 6 expenses
   ✓ Deleted 6 itinerary items
   ✓ Deleted 4 trip memberships
   ✓ Deleted 3 trips

✅ Cleanup completed successfully!
```

### Option 2: Manual Cleanup (Quick)

If you prefer SQL commands directly:

```sql
-- Delete all Nithya's data (run these in order)
DO $$
DECLARE nithya_id UUID;
BEGIN
    SELECT id INTO nithya_id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com';

    DELETE FROM checklist_items WHERE checklist_id IN (SELECT id FROM checklists WHERE created_by = nithya_id);
    DELETE FROM checklists WHERE created_by = nithya_id;
    DELETE FROM expense_splits WHERE user_id = nithya_id;
    DELETE FROM expenses WHERE paid_by = nithya_id;
    DELETE FROM itinerary_items WHERE created_by = nithya_id;
    DELETE FROM trip_members WHERE user_id = nithya_id;
    DELETE FROM trips WHERE created_by = nithya_id;

    RAISE NOTICE 'Cleanup complete!';
END $$;
```

Then run the dummy data script again.

---

## 🆘 Troubleshooting

### Error: "User nithyaganesan53@gmail.com not found"
**Solution**: Make sure Nithya's account exists. Sign up in the app first.

### Error: "violates foreign key constraint"
**Solution**: Run the delete queries above first, then re-run the script.

### Error: "permission denied"
**Solution**: Make sure you're running the script with proper database permissions.

### No Data Shows in App
**Solution**:
1. Check if script ran successfully (should see ✅ message)
2. Verify data in Supabase dashboard
3. Try logging out and logging back in
4. Check if `ref.invalidate(currentUserProvider)` fix is applied

---

## 📊 Summary

**File**: `CREATE_NITHYA_DUMMY_DATA.sql`

**What it creates**:
- ✅ 3 realistic trips with different statuses
- ✅ 6 expenses (split between trips and standalone)
- ✅ 6 itinerary items for upcoming trip
- ✅ 2 checklists with 12 items
- ✅ Beautiful cover images from Unsplash
- ✅ Realistic dates (past, present, future)

**Safe to use**: Yes, uses proper UUID generation and foreign keys

**Idempotent**: No, creates new data each run (use delete script first if needed)

---

_Last Updated: October 20, 2025_
_Created for: nithyaganesan53@gmail.com testing_
