# Hospitals Feature Setup Checklist

Use this checklist to set up the nearest hospitals feature in your Travel Companion app.

---

## Pre-Setup Checklist

- [ ] I have access to my Supabase project dashboard
- [ ] I have the TravelCompanion project open in Supabase
- [ ] I have downloaded/have access to `hospitals_complete_setup.sql`
- [ ] I am familiar with the Supabase SQL Editor
- [ ] (Optional) I have read `README_HOSPITALS_SETUP.md` for detailed instructions

**Estimated Time:** 5-10 minutes

---

## Setup Steps

### Step 1: Access Supabase SQL Editor

- [ ] Go to [supabase.com](https://supabase.com)
- [ ] Log in to your account
- [ ] Open your **TravelCompanion** project
- [ ] Click **"SQL Editor"** in the left sidebar
- [ ] Click **"New query"** button

### Step 2: Run the Setup Script

- [ ] Open `scripts/database/hospitals_complete_setup.sql` in a text editor
- [ ] Select all (Ctrl+A) and copy (Ctrl+C) the entire file
- [ ] Paste into the Supabase SQL Editor
- [ ] Click the **"Run"** button (or press Ctrl+Enter)
- [ ] Wait for the script to complete (should take 5-10 seconds)
- [ ] Check for success message (should say "Success. No rows returned")

**Note:** If you see any errors, check the Troubleshooting section below.

---

## Verification Steps

### Step 3: Verify Table Creation

Run this query in SQL Editor:

```sql
SELECT COUNT(*) as total_hospitals FROM hospitals;
```

- [ ] Query runs successfully
- [ ] Result shows **15** hospitals

### Step 4: Verify PostGIS Extension

Run this query:

```sql
SELECT extname, extversion FROM pg_extension WHERE extname = 'postgis';
```

- [ ] Query returns **postgis** with a version number (e.g., 3.x.x)

### Step 5: Verify Function Creation

Run this query:

```sql
SELECT name, city, distance_km
FROM find_nearest_hospitals(
  40.7580,  -- Times Square, New York
  -73.9855,
  50.0,     -- 50km radius
  5,        -- limit 5
  true,     -- emergency rooms only
  false     -- don't require 24/7
)
ORDER BY distance_km;
```

- [ ] Query runs successfully
- [ ] Returns **2** New York hospitals
- [ ] Hospitals have **distance_km** values
- [ ] Results are sorted by distance (smallest first)

### Step 6: Verify Search Function

Run this query:

```sql
SELECT name, city, state
FROM search_hospitals('Medical Center', NULL, NULL, 10);
```

- [ ] Query runs successfully
- [ ] Returns several hospitals with "Medical Center" in the name

### Step 7: Check Indexes

Run this query:

```sql
SELECT indexname
FROM pg_indexes
WHERE tablename = 'hospitals'
ORDER BY indexname;
```

- [ ] Query returns **13 or more** indexes
- [ ] List includes **idx_hospitals_location** (critical for performance)

---

## App Integration Testing

### Step 8: Test in Flutter App

- [ ] Open your Travel Companion app on a device/emulator
- [ ] Navigate to the **Emergency** feature
- [ ] (Grant location permissions if prompted)
- [ ] Click **"Find Nearest Hospitals"** button
- [ ] Verify hospitals appear in the list
- [ ] Verify distances are shown (e.g., "2.5 km")
- [ ] Verify you can see hospital details (name, address, phone)
- [ ] Try tapping a hospital to see more details
- [ ] Try tapping the emergency phone number to call

### Step 9: Test Search Functionality

- [ ] In the app, find the hospital search feature
- [ ] Search for "General" or "Medical"
- [ ] Verify search results appear
- [ ] Verify results match the search term

---

## Optional Steps

### Step 10: Add More Hospitals (Optional)

If you want to add hospitals for your specific region:

- [ ] Prepare hospital data (name, address, coordinates, etc.)
- [ ] Use the template in `README_HOSPITALS_SETUP.md`
- [ ] Insert via SQL Editor
- [ ] Verify with `SELECT * FROM hospitals WHERE id = 'your-new-id'`

### Step 11: Remove Sample Data (Optional)

If you want to remove the 15 sample hospitals and use only your own:

```sql
DELETE FROM hospitals WHERE metadata->>'is_sample_data' = 'true';
```

- [ ] Run the delete query
- [ ] Verify: `SELECT COUNT(*) FROM hospitals` returns **0**
- [ ] Add your own hospital data

### Step 12: Set Up Admin Role (Recommended for Production)

- [ ] Review the admin role setup in `README_HOSPITALS_SETUP.md`
- [ ] Create an `is_admin()` function
- [ ] Update RLS policies to use admin check
- [ ] Test that only admins can insert/update/delete hospitals

---

## Performance Optimization (Optional)

### Step 13: Check Performance

Run this query to see the query execution plan:

```sql
EXPLAIN ANALYZE
SELECT * FROM find_nearest_hospitals(40.7580, -73.9855, 50.0, 10, true, false);
```

- [ ] Execution time is **< 50ms**
- [ ] Query plan shows "Index Scan using idx_hospitals_location"
- [ ] No sequential scans (Seq Scan) appear in the plan

### Step 14: Optimize if Needed

If performance is slow:

```sql
-- Rebuild indexes
REINDEX TABLE hospitals;

-- Update statistics
ANALYZE hospitals;
```

- [ ] Run optimization queries
- [ ] Re-test with EXPLAIN ANALYZE
- [ ] Verify improved performance

---

## Troubleshooting Checklist

### Common Issues

**Issue: "extension 'postgis' does not exist"**

- [ ] Run: `CREATE EXTENSION IF NOT EXISTS postgis;`
- [ ] If that fails, contact Supabase support (PostGIS should be available)

**Issue: "function find_nearest_hospitals does not exist"**

- [ ] Verify you ran the entire SQL script (not just part of it)
- [ ] Check for errors in the SQL Editor output
- [ ] Try running just the function creation part again

**Issue: "No results returned from find_nearest_hospitals"**

- [ ] Check: `SELECT COUNT(*) FROM hospitals WHERE is_active = TRUE`
- [ ] If 0, sample data wasn't inserted - re-run the script
- [ ] Try with larger radius (500.0 instead of 50.0)
- [ ] Try with less restrictive filters (only_emergency=false)

**Issue: "Permission denied for table hospitals"**

- [ ] Check RLS status: `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'hospitals'`
- [ ] Temporarily disable: `ALTER TABLE hospitals DISABLE ROW LEVEL SECURITY;`
- [ ] Test your query
- [ ] Re-enable: `ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;`

**Issue: "Slow queries (> 100ms)"**

- [ ] Check if GIST index exists: `SELECT indexname FROM pg_indexes WHERE tablename = 'hospitals' AND indexname = 'idx_hospitals_location'`
- [ ] If missing, recreate: `CREATE INDEX idx_hospitals_location ON hospitals USING GIST(location);`
- [ ] Run: `ANALYZE hospitals;`
- [ ] Re-test

**Issue: "App shows error 'function not found'"**

- [ ] Verify function exists in Supabase
- [ ] Check app is connected to correct Supabase project
- [ ] Verify Supabase credentials in app's `.env` or config file
- [ ] Try calling the function directly in Supabase SQL Editor
- [ ] Check for typos in function name in the app code

---

## Documentation Reference

- [ ] I know where to find `README_HOSPITALS_SETUP.md` (detailed setup guide)
- [ ] I know where to find `HOSPITALS_QUICK_REFERENCE.md` (quick queries)
- [ ] I know where to find `HOSPITALS_ARCHITECTURE.md` (system architecture)
- [ ] I know where to find `HOSPITALS_SETUP_SUMMARY.md` (overview)

---

## Final Verification

### All Systems Go Checklist

- [ ] ✅ Database table created (hospitals)
- [ ] ✅ PostGIS extension enabled
- [ ] ✅ Sample data loaded (15 hospitals)
- [ ] ✅ find_nearest_hospitals function works
- [ ] ✅ search_hospitals function works
- [ ] ✅ Indexes created (13+ indexes)
- [ ] ✅ RLS policies enabled
- [ ] ✅ Flutter app can find nearest hospitals
- [ ] ✅ Flutter app can search hospitals
- [ ] ✅ Performance is acceptable (< 50ms queries)

**If all items are checked, you're done! The nearest hospitals feature is fully operational.** 🎉

---

## Success Criteria

You've successfully completed the setup when:

1. ✅ You can run `find_nearest_hospitals` in SQL Editor and get results
2. ✅ Your Flutter app's Emergency feature shows nearby hospitals
3. ✅ Distances are calculated and displayed correctly
4. ✅ You can tap hospital phone numbers to call
5. ✅ Search functionality works in the app

---

## Next Steps After Setup

Now that the feature is working, consider:

- [ ] Adding more hospitals for your target regions
- [ ] Implementing real-time hospital data feeds (bed availability, wait times)
- [ ] Adding user reviews and ratings
- [ ] Implementing navigation to hospitals (Google Maps integration)
- [ ] Setting up admin panel for hospital management
- [ ] Monitoring query performance in production
- [ ] Setting up analytics for feature usage

---

## Support Resources

If you need help:

1. **Read the documentation:**
   - `README_HOSPITALS_SETUP.md` - Comprehensive setup guide
   - `HOSPITALS_QUICK_REFERENCE.md` - Quick reference for queries
   - `HOSPITALS_ARCHITECTURE.md` - System architecture details

2. **Check the troubleshooting section** in `README_HOSPITALS_SETUP.md`

3. **Supabase resources:**
   - Supabase Docs: https://supabase.com/docs
   - PostGIS Docs: https://postgis.net/documentation/

4. **Hospital data sources:**
   - CMS Hospital Compare: https://data.cms.gov/provider-data/
   - HIFLD Open Data: https://hifld-geoplatform.opendata.arcgis.com/

---

## Maintenance Schedule

After setup, perform these maintenance tasks:

**Monthly:**
- [ ] Check query performance with EXPLAIN ANALYZE
- [ ] Run ANALYZE hospitals; to update statistics
- [ ] Review and update hospital data for accuracy

**Quarterly:**
- [ ] Run REINDEX TABLE hospitals;
- [ ] Review and optimize RLS policies
- [ ] Check for database updates/migrations

**Annually:**
- [ ] Audit hospital data for accuracy
- [ ] Update sample data if needed
- [ ] Review and update documentation

---

## Completion

**Setup completed on:** _________________ (date)

**Completed by:** _________________ (name)

**Notes:**
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________

**Total setup time:** _______ minutes

**Issues encountered:**
_____________________________________________________________
_____________________________________________________________

**Resolutions:**
_____________________________________________________________
_____________________________________________________________

---

**Congratulations!** 🎉

You have successfully set up the nearest hospitals feature for your Travel Companion app. The emergency feature is now fully functional and ready to help users find medical assistance when traveling.

**Remember:** This feature can save lives in emergency situations. Make sure to:
- Keep hospital data up-to-date
- Monitor performance regularly
- Test the feature periodically
- Have a backup plan for areas with sparse hospital data

---

**Checklist Version:** 1.0.0
**Last Updated:** 2024-01-15
**Status:** ✅ Ready to Use
