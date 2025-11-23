# Hospital Database Troubleshooting Guide

## Problem: "No hospitals found" in Emergency Services

If you're seeing "No hospitals found" when using the Nearest Hospitals feature, follow this guide.

---

## Step 1: Run the Diagnostic Script

In your Supabase SQL Editor:

1. Open **hospitals_diagnostic.sql**
2. Copy and paste the entire contents
3. Click **Run**

This will check:
- ✅ If the `hospitals` table exists
- ✅ If there are any hospitals in the database
- ✅ If all required functions exist
- ✅ If the functions work correctly

---

## Step 2: Interpret the Results

### Scenario A: Table Does Not Exist
```
❌ hospitals table DOES NOT EXIST
```

**Solution:**
1. Run `hospitals_setup_no_postgis.sql` in Supabase SQL Editor
2. Then run `hospitals_sample_data.sql`
3. Test again

---

### Scenario B: Table Exists but No Data
```
✅ hospitals table EXISTS with 0 records
⚠️  WARNING: No hospitals in database!
```

**Solution:**
1. Run `hospitals_sample_data.sql` in Supabase SQL Editor
2. Test again

---

### Scenario C: Functions Do Not Exist
```
❌ find_nearest_hospitals function DOES NOT EXIST
```

**Solution:**
1. Run `hospitals_setup_no_postgis.sql` completely
2. Check for any errors during execution
3. Test again

---

### Scenario D: Everything Exists but Still No Results

If the diagnostic shows:
- ✅ Table exists with 15 records
- ✅ All functions exist
- But the app still shows "No hospitals found"

**Possible Causes:**

#### 1. Your Location is Too Far from Sample Hospitals

The sample data includes hospitals in:
- New York, NY
- Los Angeles, CA
- Boston, MA
- Chicago, IL
- Houston, TX
- San Francisco, CA
- Palo Alto, CA
- Seattle, WA
- Tampa, FL
- Phoenix, AZ
- Rochester, MN
- Cleveland, OH
- Baltimore, MD

If you're testing from outside the USA or far from these cities, increase the search radius:

**Temporary Test:**
Run this in Supabase SQL Editor to find ANY hospital within 5000 km:
```sql
SELECT
  name,
  city,
  state,
  distance_km
FROM find_nearest_hospitals(
  user_lat := 40.7128,  -- NYC coordinates for testing
  user_lng := -74.0060,
  max_distance_km := 5000.0,  -- Very large radius
  result_limit := 10,
  only_emergency := FALSE,  -- Don't filter
  only_24_7 := FALSE         -- Don't filter
);
```

If this returns results, the database is working correctly!

#### 2. Location Permission Not Granted

**Check:**
- Did you grant location permission to the app?
- Is your device's location services enabled?

**Solution:**
1. Go to device Settings → Apps → TravelCompanion → Permissions
2. Enable Location permission
3. Set to "Allow all the time" or "Allow while using app"

#### 3. Row Level Security (RLS) Issue

The database has RLS policies that only show active hospitals.

**Check in Supabase:**
```sql
-- Check if there are active hospitals
SELECT COUNT(*) FROM hospitals WHERE is_active = TRUE;
```

If this returns 0, your hospitals are not active.

**Fix:**
```sql
-- Activate all hospitals
UPDATE hospitals SET is_active = TRUE;
```

#### 4. Authentication Issue

The RLS policy requires viewing hospitals:
```sql
CREATE POLICY "Anyone can view active hospitals"
  ON hospitals FOR SELECT
  USING (is_active = TRUE);
```

This should work for all users (authenticated or not).

**Test without RLS:**
```sql
-- Temporarily disable RLS (for testing only!)
ALTER TABLE hospitals DISABLE ROW LEVEL SECURITY;

-- Try the query again
SELECT COUNT(*) FROM hospitals;

-- Re-enable RLS (important!)
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
```

#### 5. Check the App's Search Parameters

The app uses these defaults:
- **Max Distance:** 50 km
- **Only Emergency:** true (only shows hospitals with emergency rooms)
- **Only 24/7:** false

If your nearest hospital is >50 km away, you won't see results.

**Check Distance from Your Location:**
```sql
-- Replace with YOUR actual latitude/longitude
SELECT
  name,
  city,
  state,
  ROUND(haversine_distance(
    YOUR_LATITUDE,    -- e.g., 37.7749 for San Francisco
    YOUR_LONGITUDE,   -- e.g., -122.4194
    latitude,
    longitude
  )::NUMERIC, 2) AS distance_km
FROM hospitals
WHERE is_active = TRUE
ORDER BY distance_km
LIMIT 5;
```

---

## Step 3: Test with Known Coordinates

Try these test locations that should definitely find hospitals:

### Test 1: New York City
```sql
SELECT
  name,
  city,
  distance_km
FROM find_nearest_hospitals(
  user_lat := 40.7128,
  user_lng := -74.0060,
  max_distance_km := 50.0,
  result_limit := 10,
  only_emergency := TRUE,
  only_24_7 := FALSE
);
```
**Expected:** Mount Sinai Hospital, NewYork-Presbyterian Hospital

### Test 2: Los Angeles
```sql
SELECT
  name,
  city,
  distance_km
FROM find_nearest_hospitals(
  user_lat := 34.0522,
  user_lng := -118.2437,
  max_distance_km := 50.0,
  result_limit := 10,
  only_emergency := TRUE,
  only_24_7 := FALSE
);
```
**Expected:** Cedars-Sinai Medical Center, UCLA Medical Center

---

## Step 4: Add More Hospitals Near Your Location

If you're testing from a location far from the sample hospitals, add some local ones:

```sql
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, type, has_emergency_room, is_24_7,
  rating, is_active, is_verified
) VALUES (
  'Your Local Hospital',           -- Name
  '123 Main Street',                -- Address
  'Your City',                      -- City
  'YS',                            -- State (2 letters)
  'USA',                           -- Country
  '12345',                         -- Postal code
  YOUR_LATITUDE,                   -- e.g., 37.7749
  YOUR_LONGITUDE,                  -- e.g., -122.4194
  '+1-555-0100',                   -- Phone
  'general',                       -- Type
  TRUE,                            -- Has emergency room
  TRUE,                            -- 24/7
  4.5,                            -- Rating
  TRUE,                            -- Is active
  TRUE                             -- Is verified
);
```

---

## Step 5: Check Flutter App Debug Output

When running the app in debug mode, check the console for errors:

```dart
// The app should log something like:
❌ Error getting nearest hospitals: <error message>
```

Common errors and solutions:

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "function find_nearest_hospitals does not exist" | Function not created | Run hospitals_setup_no_postgis.sql |
| "relation 'hospitals' does not exist" | Table not created | Run hospitals_setup_no_postgis.sql |
| "column 'location' does not exist" | Used PostGIS script instead | Use hospitals_setup_no_postgis.sql |
| "permission denied for table hospitals" | RLS issue | Check Step 2, Scenario D, Item 4 |

---

## Step 6: Verify Complete Setup

Run this complete verification:

```sql
-- 1. Check table exists
SELECT COUNT(*) AS total_hospitals FROM hospitals;
-- Expected: 15

-- 2. Check functions exist
SELECT COUNT(*) FROM pg_proc WHERE proname = 'find_nearest_hospitals';
-- Expected: 1

-- 3. Test function with NYC coordinates
SELECT COUNT(*) FROM find_nearest_hospitals(
  40.7128, -74.0060, 50.0, 10, TRUE, FALSE
);
-- Expected: 2 (Mount Sinai and NewYork-Presbyterian)

-- 4. Check RLS
SHOW row_security;
-- Expected: on

-- 5. Check active hospitals
SELECT COUNT(*) FROM hospitals WHERE is_active = TRUE;
-- Expected: 15
```

---

## Quick Fixes Checklist

- [ ] Run `hospitals_diagnostic.sql` to identify the issue
- [ ] Ensure `hospitals_setup_no_postgis.sql` was run successfully
- [ ] Ensure `hospitals_sample_data.sql` was run successfully
- [ ] Verify 15 hospitals exist in database
- [ ] Verify `find_nearest_hospitals` function exists
- [ ] Test function with known coordinates (NYC or LA)
- [ ] Check app has location permission
- [ ] Verify hospitals are within 50km of test location
- [ ] Check for errors in Flutter debug console
- [ ] Verify RLS policies allow SELECT for all users

---

## Still Having Issues?

1. **Export your diagnostic results:**
   - Run `hospitals_diagnostic.sql`
   - Copy the output
   - Share with your team

2. **Check the exact error:**
   - Look at Flutter console output
   - Look at Supabase logs
   - Check for network issues

3. **Verify your Supabase project:**
   - Ensure you're connected to the correct project
   - Check that other tables work correctly
   - Verify your API keys are correct

---

## Common Mistakes

1. ❌ **Running `hospitals_complete_setup.sql` instead of `hospitals_setup_no_postgis.sql`**
   - The complete setup requires PostGIS
   - Use the no_postgis version instead

2. ❌ **Not running `hospitals_sample_data.sql` after setup**
   - Setup creates the table and functions
   - Sample data inserts the actual hospitals

3. ❌ **Testing from a location far from sample hospitals**
   - Sample hospitals are only in major US cities
   - Add local hospitals or test with known coordinates

4. ❌ **Location permission not granted**
   - App needs location permission to find nearest hospitals
   - Grant permission in device settings

---

## Success Criteria

You know everything is working when:
- ✅ Diagnostic script shows 15 hospitals in database
- ✅ All 4 functions exist
- ✅ Test queries return results
- ✅ App shows nearest hospitals (when near a major US city)
- ✅ Can call hospitals and get directions

---

**Need more help?** Check the other documentation files:
- `HOSPITALS_QUICK_SETUP.md` - Setup instructions
- `HOSPITALS_QUICK_REFERENCE.md` - Function usage
- `hospitals_diagnostic.sql` - Diagnostic queries
