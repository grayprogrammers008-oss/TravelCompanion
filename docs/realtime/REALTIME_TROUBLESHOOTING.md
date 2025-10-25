# 🔧 Real-time Sync Troubleshooting Guide

**Issue**: Real-time synchronization not working between devices

---

## Quick Diagnosis

Run through this checklist:

- [ ] **Step 1**: Verify Supabase Realtime is enabled
- [ ] **Step 2**: Check console logs for subscription status
- [ ] **Step 3**: Test the connection
- [ ] **Step 4**: Verify RLS policies

---

## Step 1: Enable Realtime in Supabase

### Option A: Using Supabase Dashboard (Easiest)

1. Go to your Supabase project: https://supabase.com/dashboard/project/ckgaoxajvonazdwpsmai
2. Navigate to **Database** → **Replication**
3. Scroll down to **supabase_realtime** publication
4. Click **Manage**
5. Enable these tables:
   - ✅ `trips`
   - ✅ `trip_members`
   - ✅ `expenses`
   - ✅ `expense_splits`
   - ✅ `itinerary_items`
   - ✅ `checklists`
   - ✅ `checklist_items`

### Option B: Using SQL (Recommended)

1. Open Supabase SQL Editor
2. Run the verification script:
   ```bash
   # Contents of scripts/database/verify_realtime.sql
   ```
3. If tables are missing, run:
   ```bash
   # Contents of scripts/database/enable_realtime.sql
   ```

**Run this SQL in Supabase SQL Editor:**

```sql
-- Quick check - run this first
SELECT
    tablename,
    CASE
        WHEN tablename = ANY(
            SELECT tablename FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
        ) THEN '✅ ENABLED'
        ELSE '❌ NOT ENABLED - RUN SCRIPT BELOW!'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('trips', 'trip_members', 'expenses');
```

**If any show ❌, run this:**

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE trips;
ALTER PUBLICATION supabase_realtime ADD TABLE trip_members;
ALTER PUBLICATION supabase_realtime ADD TABLE expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE expense_splits;
ALTER PUBLICATION supabase_realtime ADD TABLE itinerary_items;
ALTER PUBLICATION supabase_realtime ADD TABLE checklists;
ALTER PUBLICATION supabase_realtime ADD TABLE checklist_items;
```

---

## Step 2: Check Console Logs

### What You Should See (Working)

When real-time is working, you'll see these messages:

```bash
# When app starts and navigates to trips list:
📡 Creating NEW subscription for user trips: abc-123-user-id
✅ Successfully subscribed to user trips for user:abc-123-user-id

# When someone creates/updates a trip:
🔄 User trip membership change detected: PostgresChangeEvent.insert
   Trip Member Payload: {trip_id: xyz, user_id: abc, ...}
✅ Fetching updated trips...
```

### What You'll See (NOT Working)

```bash
# Timeout = Realtime not enabled in Supabase
❌ User trips subscription TIMED OUT for user:abc-123

# Channel Error = Configuration issue
❌ User trips channel ERROR for user:abc-123 - Error: unauthorized

# Nothing = Subscription not being created
# (Check if you're using the watchUserTrips() method)
```

---

## Step 3: Test the Setup

### Quick Test (2 minutes)

1. **Run the test script:**
   ```bash
   cd /Users/vinothvs/Development/TravelCompanion
   ./scripts/test_realtime.sh
   ```

2. **Select option 2** (iOS + Chrome - easiest)

3. **Watch the console output**:
   - Look for `📡 Creating NEW subscription...`
   - Look for `✅ Successfully subscribed...`
   - If you see `❌ TIMED OUT`, Realtime is **NOT** enabled in Supabase

4. **Test the sync**:
   - Device A: Open trips list
   - Device B: Create a new trip
   - Device A: Should see trip appear within 1 second

### Manual Test

**Terminal 1:**
```bash
flutter run -d chrome
```

**Terminal 2:**
```bash
flutter run -d "iPhone 15 Pro"
```

---

## Step 4: Verify RLS Policies

Realtime respects Row Level Security policies. Make sure SELECT is allowed:

```sql
-- Check existing policies
SELECT
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('trips', 'trip_members')
ORDER BY tablename;
```

You should see policies that allow SELECT for authenticated users.

---

## Common Issues & Solutions

### Issue 1: "Subscription TIMED OUT"

**Cause**: Realtime not enabled in Supabase for those tables

**Solution**:
1. Go to Supabase Dashboard → Database → Replication
2. Add tables to `supabase_realtime` publication
3. OR run: `scripts/database/enable_realtime.sql`

---

### Issue 2: "Channel ERROR - unauthorized"

**Cause**: RLS policies blocking access

**Solution**:
```sql
-- Create policy to allow authenticated users to read trips
CREATE POLICY "Users can view trips they're members of"
ON trips FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT trip_id FROM trip_members
        WHERE user_id = auth.uid()
    )
);
```

---

### Issue 3: No subscription messages at all

**Cause**: `watchUserTrips()` or `watchTrip()` not being called

**Check**: Look for where trips are being fetched. Should use:
- `watchUserTrips()` for trips list page
- `watchTrip(tripId)` for trip detail page

**Not**: `getUserTrips()` (one-time fetch, no realtime)

---

### Issue 4: Subscription works but updates don't appear

**Cause**: Stream not being listened to, or UI not rebuilding

**Check**: Make sure you're using `StreamBuilder` or Riverpod's `stream` provider

**Example**:
```dart
// ✅ GOOD - Uses stream
final tripsProvider = StreamProvider<List<TripWithMembers>>((ref) {
  final datasource = ref.watch(tripRemoteDataSourceProvider);
  return datasource.watchUserTrips();
});

// ❌ BAD - One-time fetch
final tripsProvider = FutureProvider<List<TripWithMembers>>((ref) {
  final datasource = ref.watch(tripRemoteDataSourceProvider);
  return datasource.getUserTrips();
});
```

---

### Issue 5: Works for a while, then stops

**Cause**: WebSocket disconnection

**Check**: Network stability, firewall rules

**Solution**: The Supabase client should auto-reconnect, but you can add retry logic

---

## Testing Checklist

Before closing this issue, verify:

- [ ] Can run two instances simultaneously
- [ ] Console shows `✅ Successfully subscribed...`
- [ ] Creating trip on Device B appears on Device A (< 2 sec)
- [ ] Editing trip on Device B updates on Device A (< 2 sec)
- [ ] Deleting trip on Device B removes from Device A (< 2 sec)
- [ ] Works after app backgrounding
- [ ] Works after network reconnection

---

## Debug Commands

### Check what's running:
```bash
flutter devices
```

### View realtime channels in Supabase:
1. Go to Supabase Dashboard
2. Navigate to **Logs** → **Realtime**
3. You should see active subscriptions

### Enable verbose logging:

Already enabled! Look for emoji indicators:
- 📡 = Subscription created
- ✅ = Success
- ❌ = Error
- 🔄 = Data change detected

---

## Still Not Working?

1. **Verify Supabase project is not paused**:
   - Go to Settings → General
   - Check project status

2. **Check Supabase service status**:
   - https://status.supabase.com

3. **Test with Supabase Dashboard**:
   - Go to Table Editor
   - Make a change to `trips` table
   - See if change triggers realtime event in Logs

4. **Review database setup**:
   ```bash
   # Re-run the schema with realtime enabled
   # In Supabase SQL Editor, run:
   scripts/database/SUPABASE_SCHEMA.sql
   ```

---

## Next Steps

Once realtime is working:

1. ✅ Mark Trip realtime as complete
2. 🔄 Test Expenses realtime
3. 🔄 Test Itinerary realtime
4. 🔄 Test Checklists realtime

All use the same pattern, so if trips work, the others should too!

---

## Quick Reference

### Start Testing:
```bash
./scripts/test_realtime.sh
```

### Verify Realtime in Supabase:
```sql
-- In Supabase SQL Editor
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

### Enable Realtime:
```sql
-- In Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE trips;
ALTER PUBLICATION supabase_realtime ADD TABLE trip_members;
```

---

**Last Updated**: October 22, 2025
