# Hospitals Database - Quick Reference

## Setup (One-Time)

```sql
-- Copy and paste the entire contents of hospitals_complete_setup.sql into Supabase SQL Editor
-- Then click "Run"
```

---

## Common Queries

### Find Nearest Hospitals

```sql
-- Basic usage (default filters)
SELECT name, city, distance_km, emergency_phone
FROM find_nearest_hospitals(
  40.7580,  -- your latitude
  -73.9855, -- your longitude
  50.0,     -- max distance (km)
  10,       -- max results
  true,     -- only emergency rooms
  false     -- don't require 24/7
);
```

```sql
-- Find nearest trauma centers
SELECT name, city, trauma_level, distance_km, emergency_phone
FROM find_nearest_hospitals(
  user_lat,
  user_lng,
  100.0,    -- wider search radius
  5,
  true,
  true      -- require 24/7
)
WHERE has_trauma_center = TRUE
ORDER BY distance_km;
```

### Search by Name

```sql
SELECT name, city, state, phone_number
FROM search_hospitals_by_name('General', 10);
```

### Get Hospitals by City

```sql
SELECT name, type, emergency_phone
FROM get_hospitals_by_city('New York', 20);
```

### Get Hospital Details

```sql
SELECT *
FROM get_hospital_by_id('hospital-uuid-here');
```

---

## Common Filters

### Filter by Services

```sql
SELECT name, city, services
FROM hospitals
WHERE 'Cardiac Care' = ANY(services)
  AND is_active = TRUE
  AND has_emergency_room = TRUE;
```

### Filter by Specialty

```sql
SELECT name, city, specialties, rating
FROM hospitals
WHERE 'Cardiology' = ANY(specialties)
  AND is_active = TRUE
ORDER BY rating DESC NULLS LAST;
```

### Top Rated Hospitals

```sql
SELECT name, city, rating, total_reviews
FROM hospitals
WHERE is_active = TRUE
  AND total_reviews > 100
ORDER BY rating DESC, total_reviews DESC
LIMIT 10;
```

---

## Management Operations

### Add a New Hospital

```sql
INSERT INTO hospitals (
  name, address, city, state, postal_code,
  latitude, longitude,
  phone_number, emergency_phone,
  type, has_emergency_room, is_24_7,
  services, is_verified
) VALUES (
  'New Hospital Name',
  '123 Main St',
  'City Name',
  'ST',
  '12345',
  40.7128,
  -74.0060,
  '+1-555-123-4567',
  '+1-555-123-4911',
  'emergency',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'ICU'],
  TRUE
);
```

### Update Hospital Information

```sql
UPDATE hospitals
SET
  phone_number = '+1-555-NEW-NUM',
  rating = 4.8,
  total_reviews = total_reviews + 1,
  updated_at = NOW()
WHERE id = 'hospital-uuid-here';
```

### Update Hospital Rating

```sql
UPDATE hospitals
SET
  rating = (rating * total_reviews + new_rating) / (total_reviews + 1),
  total_reviews = total_reviews + 1,
  updated_at = NOW()
WHERE id = 'hospital-uuid-here';
```

### Deactivate Hospital

```sql
UPDATE hospitals
SET is_active = FALSE, updated_at = NOW()
WHERE id = 'hospital-uuid-here';
```

### Delete Sample Data

```sql
DELETE FROM hospitals
WHERE metadata->>'is_sample_data' = 'true';
```

---

## Verification Queries

### Check Setup

```sql
-- Verify table exists
SELECT COUNT(*) FROM hospitals;

-- Check PostGIS extension
SELECT extname, extversion FROM pg_extension WHERE extname = 'postgis';

-- Check indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'hospitals';
```

### Verify Data Quality

```sql
-- Check for hospitals without coordinates
SELECT name, city FROM hospitals
WHERE latitude IS NULL OR longitude IS NULL;

-- Check for hospitals without emergency phones
SELECT name, city FROM hospitals
WHERE has_emergency_room = TRUE
  AND emergency_phone IS NULL;

-- Check geographic distribution
SELECT state, COUNT(*) as hospital_count
FROM hospitals
GROUP BY state
ORDER BY hospital_count DESC;
```

---

## Performance Queries

### Check Index Usage

```sql
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan as times_used,
  idx_tup_read as tuples_read
FROM pg_stat_user_indexes
WHERE tablename = 'hospitals'
ORDER BY idx_scan DESC;
```

### Analyze Table

```sql
ANALYZE hospitals;
```

### Rebuild Indexes

```sql
REINDEX TABLE hospitals;
```

### View Query Plan

```sql
EXPLAIN ANALYZE
SELECT * FROM find_nearest_hospitals(40.7580, -73.9855, 50.0, 10, true, false);
```

---

## Testing Coordinates

Use these coordinates to test the function with sample data:

| City | Latitude | Longitude |
|------|----------|-----------|
| New York (Times Square) | 40.7580 | -73.9855 |
| Los Angeles (Downtown) | 34.0522 | -118.2437 |
| Chicago (Downtown) | 41.8781 | -87.6298 |
| Houston (Downtown) | 29.7604 | -95.3698 |
| Miami (Downtown) | 25.7617 | -80.1918 |
| Seattle (Downtown) | 47.6062 | -122.3321 |
| Boston (Downtown) | 42.3601 | -71.0589 |
| Phoenix (Downtown) | 33.4484 | -112.0740 |
| Denver (Downtown) | 39.7392 | -104.9903 |
| San Francisco (Downtown) | 37.7749 | -122.4194 |
| Atlanta (Downtown) | 33.7490 | -84.3880 |
| Washington DC (Downtown) | 38.9072 | -77.0369 |

---

## Flutter App Integration

The app calls the function via Supabase RPC:

```dart
final response = await supabase.rpc(
  'find_nearest_hospitals',
  params: {
    'user_lat': 40.7580,
    'user_lng': -73.9855,
    'max_distance_km': 50.0,
    'result_limit': 10,
    'only_emergency': true,
    'only_24_7': false,
  },
);
```

---

## Troubleshooting

### No results returned

```sql
-- Check if there are active hospitals
SELECT COUNT(*) FROM hospitals WHERE is_active = TRUE;

-- Try with larger radius
SELECT * FROM find_nearest_hospitals(lat, lng, 500.0, 20, false, false);
```

### Slow queries

```sql
-- Check if geospatial index exists
SELECT indexname FROM pg_indexes
WHERE tablename = 'hospitals' AND indexname = 'idx_hospitals_location';

-- If missing, recreate it
CREATE INDEX idx_hospitals_location ON hospitals USING GIST(location);
```

### Permission errors

```sql
-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'hospitals';

-- Temporarily disable for testing (re-enable after!)
ALTER TABLE hospitals DISABLE ROW LEVEL SECURITY;
```

---

## Quick Stats

```sql
-- Hospital summary
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE has_emergency_room) as with_er,
  COUNT(*) FILTER (WHERE has_trauma_center) as trauma_centers,
  COUNT(*) FILTER (WHERE is_24_7) as open_24_7,
  ROUND(AVG(rating)::numeric, 2) as avg_rating
FROM hospitals
WHERE is_active = TRUE;
```

```sql
-- Hospitals by type
SELECT type, COUNT(*) as count
FROM hospitals
WHERE is_active = TRUE
GROUP BY type
ORDER BY count DESC;
```

```sql
-- Top cities by hospital count
SELECT city, state, COUNT(*) as count
FROM hospitals
WHERE is_active = TRUE
GROUP BY city, state
ORDER BY count DESC
LIMIT 10;
```

---

## RLS Policies

View current policies:

```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'hospitals';
```

---

**Pro Tip:** Bookmark this page for quick reference when working with the hospitals database!
