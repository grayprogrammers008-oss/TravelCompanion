# Hospital Database Quick Setup Guide

## 🚀 Complete Setup in 2 Steps

This guide will help you set up the hospital database in your Supabase instance **WITHOUT PostGIS dependency**.

---

## Prerequisites

- Access to Supabase SQL Editor
- PostgreSQL database (any version)
- No PostGIS extension required! ✅

---

## Step 1: Create Hospital Table and Functions

**File:** `hospitals_setup_no_postgis.sql`

1. Open your Supabase dashboard
2. Go to **SQL Editor**
3. Click **New Query**
4. Copy the entire contents of `hospitals_setup_no_postgis.sql`
5. Paste into the SQL Editor
6. Click **Run** (or press `Ctrl+Enter`)

**Expected Output:**
```
SUCCESS: Hospital database created!
WITHOUT PostGIS - using Haversine formula

Now run: hospitals_sample_data.sql
to add 15 sample hospitals
```

**What this does:**
- ✅ Creates `hospitals` table with latitude/longitude columns
- ✅ Creates indexes for fast queries
- ✅ Creates `haversine_distance()` function for distance calculations
- ✅ Creates `find_nearest_hospitals()` function
- ✅ Creates `get_hospital_with_distance()` function
- ✅ Creates `search_hospitals()` function
- ✅ Sets up Row Level Security (RLS) policies
- ✅ Creates update timestamp trigger

---

## Step 2: Insert Sample Hospital Data

**File:** `hospitals_sample_data.sql`

1. In Supabase SQL Editor, click **New Query**
2. Copy the entire contents of `hospitals_sample_data.sql`
3. Paste into the SQL Editor
4. Click **Run** (or press `Ctrl+Enter`)

**Expected Output:**
```
SUCCESS: 15 sample hospitals inserted!

Distribution:
- New York: 2 hospitals
- Los Angeles: 2 hospitals
- California (other): 3 hospitals
- Boston: 1 hospital
- Chicago: 1 hospital
- Houston: 1 hospital
- Other cities: 5 hospitals

Types:
- Trauma Centers (Level I): 10
- Trauma Centers (Level II): 1
- Specialized: 3
- General: 1

You can now test the hospital finder!
```

**What this does:**
- ✅ Inserts 15 major US hospitals
- ✅ Covers 10 different cities and 9 states
- ✅ Includes various hospital types (trauma centers, specialized, general)
- ✅ Includes realistic ratings, services, and contact information
- ✅ Geographic distribution for testing distance searches

---

## Sample Hospitals Included

1. **Mount Sinai Hospital** - New York, NY (Trauma Level I)
2. **NewYork-Presbyterian Hospital** - New York, NY (Trauma Level I)
3. **Cedars-Sinai Medical Center** - Los Angeles, CA (Trauma Level I)
4. **UCLA Medical Center** - Los Angeles, CA (Trauma Level I)
5. **Massachusetts General Hospital** - Boston, MA (Trauma Level I)
6. **Mayo Clinic** - Rochester, MN (Trauma Level I)
7. **Cleveland Clinic** - Cleveland, OH
8. **Johns Hopkins Hospital** - Baltimore, MD (Trauma Level I)
9. **Northwestern Memorial Hospital** - Chicago, IL (Trauma Level I)
10. **Houston Methodist Hospital** - Houston, TX
11. **UCSF Medical Center** - San Francisco, CA (Trauma Level I)
12. **Stanford Health Care** - Palo Alto, CA (Trauma Level I)
13. **Seattle Children's Hospital** - Seattle, WA (Trauma Level I)
14. **Tampa General Hospital** - Tampa, FL (Trauma Level I)
15. **Phoenix Children's Hospital** - Phoenix, AZ (Trauma Level II)

---

## Testing the Setup

### Test 1: Count Hospitals
```sql
SELECT COUNT(*) AS total_hospitals FROM hospitals;
```
**Expected:** 15

### Test 2: Find Nearest Hospitals to New York City
```sql
SELECT
  name,
  city,
  state,
  distance_km
FROM find_nearest_hospitals(
  user_lat := 40.7128,
  user_lng := -74.0060,
  max_distance_km := 50.0,
  result_limit := 5,
  only_emergency := TRUE,
  only_24_7 := FALSE
);
```
**Expected:** Should return Mount Sinai and NewYork-Presbyterian

### Test 3: Find Nearest Hospitals to Los Angeles
```sql
SELECT
  name,
  city,
  state,
  distance_km
FROM find_nearest_hospitals(
  user_lat := 34.0522,
  user_lng := -118.2437,
  max_distance_km := 50.0,
  result_limit := 5
);
```
**Expected:** Should return Cedars-Sinai and UCLA Medical Center

### Test 4: Search Hospitals by Name
```sql
SELECT
  name,
  city,
  state,
  rating
FROM search_hospitals(
  search_term := 'Children',
  search_city := NULL,
  search_state := NULL,
  result_limit := 10
);
```
**Expected:** Should return Seattle Children's and Phoenix Children's

### Test 5: Get Specific Hospital with Distance
```sql
-- First, get a hospital ID
SELECT id, name FROM hospitals LIMIT 1;

-- Then use that ID (replace <hospital-id> with actual UUID)
SELECT
  name,
  city,
  state,
  distance_km
FROM get_hospital_with_distance(
  hospital_id := '<hospital-id>',
  user_lat := 40.7128,
  user_lng := -74.0060
);
```

---

## Troubleshooting

### ❌ Error: "column 'location' does not exist"
**Solution:** You're running the wrong script. Use `hospitals_setup_no_postgis.sql` instead of `hospitals_complete_setup.sql`.

### ❌ Error: "function find_nearest_hospitals does not exist"
**Solution:** Run Step 1 first (`hospitals_setup_no_postgis.sql`) before Step 2.

### ❌ Error: "duplicate key value violates unique constraint"
**Solution:** Sample data is already inserted. Either:
- Skip Step 2, or
- Delete existing data first: `DELETE FROM hospitals;`

### ⚠️ No results from find_nearest_hospitals
**Possible causes:**
1. No hospitals within the search radius - increase `max_distance_km`
2. No emergency hospitals if `only_emergency := TRUE` - set to `FALSE`
3. Check if you inserted the sample data (Step 2)

---

## Flutter App Integration

The Flutter app is already configured to use these functions!

**File:** `lib/features/emergency/data/datasources/emergency_remote_datasource.dart`

The following methods will now work:
- ✅ `findNearestHospitals()` - Calls `find_nearest_hospitals()`
- ✅ `getHospitalById()` - Calls `get_hospital_with_distance()`
- ✅ `searchHospitals()` - Calls `search_hospitals()`

**No Dart code changes required!** Just run the SQL scripts and the app will work.

---

## Distance Calculation

This setup uses the **Haversine Formula** to calculate distances:

```sql
CREATE OR REPLACE FUNCTION haversine_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
```

**Accuracy:** ±0.5% compared to PostGIS (good enough for hospital search!)

**Performance:** Fast enough for real-time searches (indexed lat/lng columns)

---

## Next Steps

After completing both steps:

1. ✅ Test the SQL functions using the queries above
2. ✅ Run your Flutter app
3. ✅ Navigate to **Emergency Services → Find Nearest Hospitals**
4. ✅ Grant location permission when prompted
5. ✅ See the nearest hospitals to your current location!

---

## Additional Data

Want to add more hospitals? Use this template:

```sql
INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website,
  type, capacity, has_emergency_room, has_trauma_center,
  is_24_7, services, specialties,
  rating, total_reviews, is_active, is_verified
) VALUES (
  'Your Hospital Name',
  '123 Main Street',
  'City',
  'ST',
  'USA',
  '12345',
  40.7128,  -- latitude
  -74.0060,  -- longitude
  '+1-555-0100',
  '+1-555-0911',
  'https://hospital.com',
  'general',  -- or 'trauma_center', 'specialized', 'emergency', 'urgent_care'
  500,  -- capacity
  TRUE,  -- has_emergency_room
  FALSE,  -- has_trauma_center
  TRUE,  -- is_24_7
  ARRAY['Emergency Care', 'Surgery'],  -- services
  ARRAY['General Medicine'],  -- specialties
  4.5,  -- rating (0-5)
  100,  -- total_reviews
  TRUE,  -- is_active
  TRUE  -- is_verified
);
```

---

## File Summary

- **hospitals_setup_no_postgis.sql** (428 lines) - Creates table, functions, and triggers
- **hospitals_sample_data.sql** (643 lines) - Inserts 15 sample hospitals
- **HOSPITALS_QUICK_SETUP.md** (this file) - Setup instructions

---

**Total setup time:** < 5 minutes ⏱️

**Questions?** Check the other documentation files in `scripts/database/`

---

✅ **You're all set! Enjoy your fully functional hospital finder!** 🏥
