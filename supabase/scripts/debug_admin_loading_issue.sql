-- Debug Script for Admin Panel Loading Issue
-- Run each section separately in Supabase SQL Editor to diagnose the problem

-- ============================================================================
-- 1. CHECK AUTHENTICATION
-- ============================================================================
-- Verify you're authenticated
SELECT
  auth.uid() as current_user_id,
  auth.jwt() ->> 'email' as current_user_email;

-- Expected: Should return your user ID and email
-- If NULL: You're not authenticated


-- ============================================================================
-- 2. CHECK YOUR PROFILE
-- ============================================================================
-- Check if your profile exists and has required fields
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
WHERE id = auth.uid();

-- Expected: Should return your profile with all fields populated
-- If NOT FOUND: Your profile doesn't exist in profiles table
-- If missing fields: Profile needs to be updated


-- ============================================================================
-- 3. TEST user_statistics VIEW
-- ============================================================================
-- Check if you can access the user_statistics view
SELECT
  id,
  email,
  full_name,
  role,
  status,
  trips_count,
  messages_count,
  expenses_count,
  total_expenses
FROM user_statistics
WHERE id = auth.uid()
LIMIT 1;

-- Expected: Should return your user data from the view
-- If ERROR: View has RLS issues or doesn't exist
-- If NOT FOUND: Your profile isn't being included in the view


-- ============================================================================
-- 4. CHECK VIEW PERMISSIONS
-- ============================================================================
-- Verify RLS policies on user_statistics view
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
WHERE tablename = 'user_statistics';

-- Expected: Should show SELECT policy for authenticated users
-- If EMPTY: No RLS policies configured (might be the issue!)


-- ============================================================================
-- 5. TEST get_all_users_admin FUNCTION
-- ============================================================================
-- Try calling the function directly
SELECT * FROM get_all_users_admin(
  p_limit := 5,
  p_offset := 0,
  p_search := NULL,
  p_role := NULL,
  p_status := NULL
);

-- Expected: Should return list of users
-- If ERROR: Note the exact error message
-- If EMPTY: No users in database or view has issues


-- ============================================================================
-- 6. CHECK FUNCTION EXISTS AND PERMISSIONS
-- ============================================================================
-- Verify function exists and is accessible
SELECT
  proname as function_name,
  prosecdef as is_security_definer,
  provolatile as volatility,
  pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'get_all_users_admin';

-- Expected: Should show function exists with security definer = true
-- If EMPTY: Function doesn't exist or wasn't created


-- ============================================================================
-- 7. CHECK profiles TABLE RLS
-- ============================================================================
-- Check RLS policies on profiles table
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

-- Expected: Should show policies allowing users to view own profile
-- and admins to view all profiles


-- ============================================================================
-- 8. CHECK IF VIEW EXISTS AND DEFINITION
-- ============================================================================
-- Get the actual view definition
SELECT
  viewname,
  definition
FROM pg_views
WHERE viewname = 'user_statistics';

-- Expected: Should show the view with simplified definition (no expenses JOIN)
-- If EMPTY: View doesn't exist


-- ============================================================================
-- 9. TEST BASIC PROFILE ACCESS
-- ============================================================================
-- Can you access profiles table directly?
SELECT COUNT(*) as total_profiles
FROM profiles;

-- Expected: Should return count of all profiles
-- If ERROR: RLS is blocking access to profiles table


-- ============================================================================
-- 10. CHECK FOR MIGRATION HISTORY
-- ============================================================================
-- Verify which migrations have been applied
SELECT * FROM _prisma_migrations
WHERE migration_name LIKE '%admin%'
ORDER BY finished_at DESC;

-- OR if using Supabase migrations:
-- Check supabase_migrations schema table if it exists


-- ============================================================================
-- DIAGNOSTIC SUMMARY
-- ============================================================================
-- Based on results above, common issues:
--
-- 1. VIEW DOESN'T EXIST:
--    → Run migration 20250131_fix_user_statistics_view.sql
--
-- 2. VIEW EXISTS BUT NO RLS POLICY:
--    → Add: GRANT SELECT ON user_statistics TO authenticated;
--    → This is already in the migration, so might need to be run again
--
-- 3. FUNCTION RETURNS ERROR:
--    → Check the exact error message
--    → Might be JOIN issue or missing columns
--
-- 4. RLS BLOCKING ACCESS TO profiles:
--    → Need to verify RLS policies from migration 20250129_fix_admin_rls.sql
--
-- 5. PROFILES TABLE MISSING COLUMNS:
--    → Need to run migration 20250128_admin_user_management.sql
--
-- ============================================================================
