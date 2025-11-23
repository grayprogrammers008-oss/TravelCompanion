-- ============================================
-- HOSPITAL DATABASE DIAGNOSTIC SCRIPT
-- ============================================
-- Run this to diagnose "No hospitals found" issues
-- ============================================

-- ============================================
-- 1. CHECK IF TABLE EXISTS
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hospitals') THEN
    RAISE NOTICE '✅ hospitals table EXISTS';
  ELSE
    RAISE NOTICE '❌ hospitals table DOES NOT EXIST - Run hospitals_setup_no_postgis.sql first!';
  END IF;
END $$;

-- ============================================
-- 2. CHECK TABLE STRUCTURE
-- ============================================
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'hospitals'
ORDER BY ordinal_position;

-- ============================================
-- 3. COUNT HOSPITALS IN DATABASE
-- ============================================
SELECT
  COUNT(*) AS total_hospitals,
  COUNT(*) FILTER (WHERE is_active = TRUE) AS active_hospitals,
  COUNT(*) FILTER (WHERE has_emergency_room = TRUE) AS emergency_hospitals,
  COUNT(*) FILTER (WHERE is_24_7 = TRUE) AS hospitals_24_7
FROM hospitals;

-- ============================================
-- 4. LIST ALL HOSPITALS (Basic Info)
-- ============================================
SELECT
  id,
  name,
  city,
  state,
  type,
  has_emergency_room,
  is_24_7,
  is_active,
  ROUND(latitude::NUMERIC, 4) AS lat,
  ROUND(longitude::NUMERIC, 4) AS lng
FROM hospitals
ORDER BY state, city;

-- ============================================
-- 5. CHECK IF FUNCTIONS EXIST
-- ============================================
DO $$
DECLARE
  func_count INTEGER;
BEGIN
  -- Check haversine_distance
  SELECT COUNT(*) INTO func_count
  FROM pg_proc
  WHERE proname = 'haversine_distance';

  IF func_count > 0 THEN
    RAISE NOTICE '✅ haversine_distance function EXISTS';
  ELSE
    RAISE NOTICE '❌ haversine_distance function DOES NOT EXIST';
  END IF;

  -- Check find_nearest_hospitals
  SELECT COUNT(*) INTO func_count
  FROM pg_proc
  WHERE proname = 'find_nearest_hospitals';

  IF func_count > 0 THEN
    RAISE NOTICE '✅ find_nearest_hospitals function EXISTS';
  ELSE
    RAISE NOTICE '❌ find_nearest_hospitals function DOES NOT EXIST';
  END IF;

  -- Check get_hospital_with_distance
  SELECT COUNT(*) INTO func_count
  FROM pg_proc
  WHERE proname = 'get_hospital_with_distance';

  IF func_count > 0 THEN
    RAISE NOTICE '✅ get_hospital_with_distance function EXISTS';
  ELSE
    RAISE NOTICE '❌ get_hospital_with_distance function DOES NOT EXIST';
  END IF;

  -- Check search_hospitals
  SELECT COUNT(*) INTO func_count
  FROM pg_proc
  WHERE proname = 'search_hospitals';

  IF func_count > 0 THEN
    RAISE NOTICE '✅ search_hospitals function EXISTS';
  ELSE
    RAISE NOTICE '❌ search_hospitals function DOES NOT EXIST';
  END IF;
END $$;

-- ============================================
-- 6. TEST haversine_distance FUNCTION
-- ============================================
-- Test distance between New York and Los Angeles (~3944 km)
SELECT
  haversine_distance(40.7128, -74.0060, 34.0522, -118.2437) AS ny_to_la_distance_km;
-- Expected result: ~3944 km

-- ============================================
-- 7. TEST find_nearest_hospitals - New York
-- ============================================
-- Find hospitals near NYC (should find Mount Sinai and NewYork-Presbyterian)
SELECT
  name,
  city,
  state,
  distance_km,
  has_emergency_room,
  is_24_7
FROM find_nearest_hospitals(
  user_lat := 40.7128,
  user_lng := -74.0060,
  max_distance_km := 50.0,
  result_limit := 5,
  only_emergency := TRUE,
  only_24_7 := FALSE
)
ORDER BY distance_km;

-- ============================================
-- 8. TEST find_nearest_hospitals - Los Angeles
-- ============================================
-- Find hospitals near LA (should find Cedars-Sinai and UCLA)
SELECT
  name,
  city,
  state,
  distance_km,
  has_emergency_room,
  is_24_7
FROM find_nearest_hospitals(
  user_lat := 34.0522,
  user_lng := -118.2437,
  max_distance_km := 50.0,
  result_limit := 5,
  only_emergency := TRUE,
  only_24_7 := FALSE
)
ORDER BY distance_km;

-- ============================================
-- 9. TEST find_nearest_hospitals - Wide Search
-- ============================================
-- Try a very wide search from NYC (500km radius)
SELECT
  name,
  city,
  state,
  distance_km
FROM find_nearest_hospitals(
  user_lat := 40.7128,
  user_lng := -74.0060,
  max_distance_km := 500.0,
  result_limit := 10,
  only_emergency := FALSE,  -- Don't filter by emergency
  only_24_7 := FALSE         -- Don't filter by 24/7
)
ORDER BY distance_km;

-- ============================================
-- 10. TEST search_hospitals
-- ============================================
SELECT
  name,
  city,
  state,
  rating
FROM search_hospitals(
  search_term := 'Hospital',
  search_city := NULL,
  search_state := NULL,
  result_limit := 10
)
ORDER BY rating DESC;

-- ============================================
-- 11. CHECK ROW LEVEL SECURITY POLICIES
-- ============================================
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'hospitals';

-- ============================================
-- 12. MANUAL DISTANCE CALCULATION TEST
-- ============================================
-- Manually calculate distances from NYC to all hospitals
SELECT
  name,
  city,
  state,
  latitude,
  longitude,
  ROUND(haversine_distance(40.7128, -74.0060, latitude, longitude)::NUMERIC, 2) AS distance_from_nyc_km,
  has_emergency_room,
  is_24_7,
  is_active
FROM hospitals
WHERE is_active = TRUE
ORDER BY distance_from_nyc_km
LIMIT 10;

-- ============================================
-- DIAGNOSTIC SUMMARY
-- ============================================
DO $$
DECLARE
  table_exists BOOLEAN;
  hospital_count INTEGER;
  func_count INTEGER;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'DIAGNOSTIC SUMMARY';
  RAISE NOTICE '========================================';

  -- Check table
  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hospitals') INTO table_exists;

  IF table_exists THEN
    SELECT COUNT(*) INTO hospital_count FROM hospitals;
    RAISE NOTICE 'hospitals table: ✅ EXISTS with % records', hospital_count;

    IF hospital_count = 0 THEN
      RAISE NOTICE '';
      RAISE NOTICE '⚠️  WARNING: No hospitals in database!';
      RAISE NOTICE '   Run hospitals_sample_data.sql to insert sample data';
    END IF;
  ELSE
    RAISE NOTICE 'hospitals table: ❌ DOES NOT EXIST';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 ACTION REQUIRED:';
    RAISE NOTICE '   1. Run hospitals_setup_no_postgis.sql';
    RAISE NOTICE '   2. Then run hospitals_sample_data.sql';
  END IF;

  -- Check functions
  SELECT COUNT(*) INTO func_count FROM pg_proc WHERE proname = 'find_nearest_hospitals';
  IF func_count > 0 THEN
    RAISE NOTICE 'find_nearest_hospitals: ✅ EXISTS';
  ELSE
    RAISE NOTICE 'find_nearest_hospitals: ❌ DOES NOT EXIST';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 ACTION REQUIRED: Run hospitals_setup_no_postgis.sql';
  END IF;

  RAISE NOTICE '========================================';
END $$;
