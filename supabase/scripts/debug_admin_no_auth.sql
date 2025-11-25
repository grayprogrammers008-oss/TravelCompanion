-- Debug Script for Admin Panel - NO AUTH CONTEXT VERSION
-- Run these queries in Supabase SQL Editor (doesn't require auth.uid())

-- ============================================================================
-- 1. CHECK IF PROFILES TABLE HAS DATA
-- ============================================================================
SELECT
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN role = 'super_admin' THEN 1 END) as super_admin_count,
  COUNT(CASE WHEN role = 'user' THEN 1 END) as user_count
FROM profiles;

-- Expected: Should show at least 1 user (you)


-- ============================================================================
-- 2. CHECK IF REQUIRED COLUMNS EXIST IN PROFILES
-- ============================================================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN (
    'id', 'email', 'full_name', 'role', 'status',
    'trips_count', 'messages_count', 'login_count',
    'created_at', 'updated_at', 'last_login_at', 'last_active_at'
  )
ORDER BY column_name;

-- Expected: Should show all these columns exist


-- ============================================================================
-- 3. CHECK IF user_statistics VIEW EXISTS
-- ============================================================================
SELECT
  schemaname,
  viewname,
  viewowner,
  definition
FROM pg_views
WHERE viewname = 'user_statistics';

-- Expected: Should show the view exists with simplified definition


-- ============================================================================
-- 4. CHECK IF get_all_users_admin FUNCTION EXISTS
-- ============================================================================
SELECT
  proname as function_name,
  prosecdef as is_security_definer,
  provolatile as volatility,
  pronargs as num_arguments,
  pg_get_function_identity_arguments(oid) as arguments
FROM pg_proc
WHERE proname = 'get_all_users_admin';

-- Expected: Should show function exists


-- ============================================================================
-- 5. TEST VIEW DIRECTLY (BYPASS RLS)
-- ============================================================================
-- This uses ALTER to temporarily bypass RLS for testing
SET LOCAL ROLE postgres;
SELECT
  id,
  email,
  full_name,
  role,
  status,
  trips_count,
  messages_count
FROM user_statistics
LIMIT 5;
RESET ROLE;

-- Expected: Should return user data
-- If ERROR: Note the exact error message


-- ============================================================================
-- 6. CHECK RLS POLICIES ON PROFILES TABLE
-- ============================================================================
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;


-- ============================================================================
-- 7. CHECK IF VIEW HAS RLS ENABLED
-- ============================================================================
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'profiles';

-- Note: Views inherit RLS from their underlying tables


-- ============================================================================
-- 8. CHECK GRANTS ON user_statistics VIEW
-- ============================================================================
SELECT
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'user_statistics';

-- Expected: Should show SELECT granted to authenticated


-- ============================================================================
-- 9. SAMPLE PROFILES DATA (CHECK STRUCTURE)
-- ============================================================================
SET LOCAL ROLE postgres;
SELECT
  id,
  email,
  full_name,
  role,
  status,
  created_at,
  trips_count,
  messages_count,
  login_count
FROM profiles
LIMIT 3;
RESET ROLE;


-- ============================================================================
-- 10. TEST FUNCTION DIRECTLY (BYPASS RLS)
-- ============================================================================
SET LOCAL ROLE postgres;
SELECT * FROM get_all_users_admin(
  p_limit := 5,
  p_offset := 0,
  p_search := NULL,
  p_role := NULL,
  p_status := NULL
);
RESET ROLE;

-- Expected: Should return list of users
-- If ERROR: This is the exact error your Flutter app is encountering!


-- ============================================================================
-- DIAGNOSTIC RESULTS INTERPRETATION
-- ============================================================================
-- Based on the results:
--
-- Query 1 = 0 users → No users in database, need to create profile after signup
-- Query 2 missing columns → Need to run 20250128_admin_user_management.sql
-- Query 3 empty → View doesn't exist, run 20250131_fix_user_statistics_view.sql
-- Query 4 empty → Function doesn't exist, run 20250130_disable_admin_checks_temp.sql
-- Query 5 error → Note the error, this is what Flutter is seeing
-- Query 8 empty → View not granted to authenticated, need to add GRANT
-- Query 10 error → This is the actual error happening in your app!
