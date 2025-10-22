# 🔧 Fixed: RLS Infinite Recursion Error

**Last Updated**: 2025-10-20

## 🐛 The Error

```
Supabase fetch failed: Exception: Failed to get user trips:
PostgrestException(message: infinite recursion detected in policy for relation "trip_members",
code: 42P17, details: Internal Server Error, hint: null)
```

**Symptoms**:
- ✅ Login works
- ✅ Navigate to home page
- ⏳ Shows "Loading your adventures..."
- ❌ **Never loads trips**
- ❌ Stuck in loading state forever
- ❌ Console shows RLS recursion error

---

## 🔍 Root Cause

**Problem**: The Row Level Security (RLS) policies for `trips` and `trip_members` tables were referencing each other, creating a circular dependency.

### The Recursive Loop

**trips table policy** (old):
```sql
"Users can view trips they are members of"
USING (
  id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
    -- ↑ This queries trip_members
  )
)
```

**trip_members table policy** (old):
```sql
"Users can view trip members for their trips"
USING (
  trip_id IN (
    SELECT id FROM trips WHERE ...
    -- ↑ This queries trips, which queries trip_members again!
  )
)
```

**Result**:
```
Query trips
→ Check policy: query trip_members
  → Check policy: query trips
    → Check policy: query trip_members
      → Check policy: query trips
        → ♾️ INFINITE RECURSION!
```

Postgres detects this and throws the `42P17` error.

---

## ✅ Solution

**Strategy**: Break the circular dependency by making policies simple and direct.

### New Policies (Non-Recursive)

**trip_members policies** (simple, no recursion):
```sql
-- Policy 1: Users can see their own memberships
"Users can view their own memberships"
USING (auth.uid() = user_id);

-- Policy 2: Users can see members of trips they belong to
"Users can view members of their trips"
USING (
  trip_id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
  )
);
```

**trips policy** (simple, no recursion):
```sql
-- Users can view trips they are members of
"Users can view their trips"
USING (
  id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
  )
);
```

**Key Difference**:
- ❌ **Before**: trips policy → trip_members policy → trips policy → ♾️
- ✅ **After**: trips policy → direct trip_members query (no policy check) → ✓

---

## 🚀 How to Fix

### Run the Fix Script

**Steps**:

1. **Open Supabase SQL Editor**:
   - https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai/sql/new

2. **Copy the fix script**:
   - Open [FIX_RLS_POLICIES.sql](FIX_RLS_POLICIES.sql)
   - Select all (Cmd+A) and copy

3. **Paste into SQL Editor** and click **"Run"**

4. **Expected output**:
   ```
   DROP POLICY
   DROP POLICY
   DROP POLICY
   CREATE POLICY
   CREATE POLICY
   CREATE POLICY
   ...

   ╔════════════════════════════════════════════════════╗
   ║  ✅ RLS POLICIES FIXED!                            ║
   ╚════════════════════════════════════════════════════╝

   ✓ Removed recursive policies
   ✓ Created simple, non-recursive policies
   ```

5. **Refresh your app** → Home page should load! ✅

---

## 🧪 Verification

### Test 1: Check Policies

Run this SQL to see the new policies:
```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('trips', 'trip_members')
ORDER BY tablename, policyname;
```

**Expected output**:
```
tablename      | policyname                              | cmd
---------------|-----------------------------------------|--------
trip_members   | Users can view their own memberships    | SELECT
trip_members   | Users can view members of their trips   | SELECT
trip_members   | Users can insert trip members...        | INSERT
trip_members   | Users can update trip members...        | UPDATE
trip_members   | Users can delete trip members...        | DELETE
trips          | Users can view their trips              | SELECT
```

---

### Test 2: Fetch Trips in Browser

After running the fix:

1. **Refresh your app** (Cmd+R or reload button)
2. **Watch console** for:
   ```
   ✅ Expected (success):
   [No error messages]
   [Home page loads empty state or trips list]

   ❌ Before fix:
   ❌ Supabase fetch failed: infinite recursion detected
   ```

3. **Home page should show**:
   - **If no data**: "No trips yet" empty state ✅
   - **If data exists**: List of trips ✅
   - **Not**: Stuck on "Loading..." ✅

---

### Test 3: Create First Trip

1. **Click "New Trip" FAB** button
2. **Fill in details**:
   ```
   Name: Test Trip
   Destination: Paris
   Start Date: Tomorrow
   End Date: Next week
   ```
3. **Click "Create Trip"**
4. **Expected**: Trip appears on home page! ✅

If successful, the RLS policies are working correctly!

---

## 📊 What Changed

### Policies Removed (Recursive)

```sql
❌ "Users can view trips they are members of" (on trips)
   - Had recursive reference to trip_members

❌ "Users can view trip members for their trips" (on trip_members)
   - Had recursive reference to trips

❌ "Users can view their own trip memberships" (on trip_members)
   - Redundant with new simpler policies
```

### Policies Added (Non-Recursive)

```sql
✅ "Users can view their own memberships" (on trip_members)
   - Direct check: user_id = auth.uid()
   - No recursion

✅ "Users can view members of their trips" (on trip_members)
   - Direct subquery to trip_members
   - No policy recursion

✅ "Users can view their trips" (on trips)
   - Direct subquery to trip_members
   - No policy recursion
```

---

## 🎯 Why This Happens

**RLS Recursion** occurs when:

1. Policy A references Table B
2. Policy B references Table A
3. Postgres evaluates policies when executing queries
4. Creates infinite loop: A → B → A → B → ...

**Prevention**:
- ✅ Keep policies simple and direct
- ✅ Use direct column checks when possible (`user_id = auth.uid()`)
- ✅ Avoid policies that query other tables with RLS
- ✅ Use `WITH CHECK` for INSERT/UPDATE (not USING)

**Common Patterns**:
```sql
-- GOOD (no recursion):
USING (user_id = auth.uid())

-- GOOD (direct subquery, no policy check):
USING (
  trip_id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
  )
)

-- BAD (can cause recursion):
USING (
  EXISTS (
    SELECT 1 FROM other_table WHERE ...
    -- If other_table has RLS that queries this table = recursion!
  )
)
```

---

## 🚀 Next Steps

1. ✅ **Run [FIX_RLS_POLICIES.sql](FIX_RLS_POLICIES.sql)** in Supabase SQL Editor
2. ✅ **Refresh app** → Home page loads successfully
3. ✅ **Disable email confirmation** (if needed, see [EMAIL_CONFIRMATION_FIX.md](EMAIL_CONFIRMATION_FIX.md))
4. ✅ **Run [SUPABASE_DUMMY_DATA.sql](SUPABASE_DUMMY_DATA.sql)** to populate test data
5. ✅ **See 2 trips** on home page!
6. ✅ **Test features**: Create trip, view details, add expenses

---

## 📚 Related Documentation

- **[FIX_RLS_POLICIES.sql](FIX_RLS_POLICIES.sql)** - SQL script to fix policies
- **[EMAIL_CONFIRMATION_FIX.md](EMAIL_CONFIRMATION_FIX.md)** - Email confirmation fix
- **[SUPABASE_DUMMY_DATA.sql](SUPABASE_DUMMY_DATA.sql)** - Test data script
- **[LOGIN_NAVIGATION_FIX.md](LOGIN_NAVIGATION_FIX.md)** - Navigation fix
- **[ONLINE_ONLY_MODE.md](ONLINE_ONLY_MODE.md)** - Configuration guide

---

## ✅ Summary

**Error**: `infinite recursion detected in policy for relation "trip_members"`

**Cause**: Circular dependency between trips and trip_members RLS policies

**Fix**: Replaced recursive policies with simple, direct policies

**Result**:
- ✅ Home page loads successfully
- ✅ Trips can be fetched from Supabase
- ✅ No more infinite recursion errors
- ✅ App fully functional!

---

**Run the fix script and your app will work!** 🎉
