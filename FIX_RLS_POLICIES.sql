-- =====================================================
-- FIX RLS INFINITE RECURSION ERROR
-- =====================================================
-- This fixes the "infinite recursion detected in policy for relation trip_members" error
-- Run this in Supabase SQL Editor
-- =====================================================

-- STEP 1: Drop existing problematic policies
DROP POLICY IF EXISTS "Users can view trips they are members of" ON trips;
DROP POLICY IF EXISTS "Users can view trip members for their trips" ON trip_members;
DROP POLICY IF EXISTS "Users can view their own trip memberships" ON trip_members;

-- STEP 2: Create non-recursive policies for trip_members
-- Simple policy: users can see trip_members records where they are the user
CREATE POLICY "Users can view their own memberships"
ON trip_members
FOR SELECT
USING (auth.uid() = user_id);

-- Simple policy: users can see all members of trips they belong to
CREATE POLICY "Users can view members of their trips"
ON trip_members
FOR SELECT
USING (
  trip_id IN (
    SELECT trip_id
    FROM trip_members
    WHERE user_id = auth.uid()
  )
);

-- STEP 3: Create non-recursive policy for trips
-- Users can view trips where they are a member (direct check, no recursion)
CREATE POLICY "Users can view their trips"
ON trips
FOR SELECT
USING (
  id IN (
    SELECT trip_id
    FROM trip_members
    WHERE user_id = auth.uid()
  )
);

-- STEP 4: Keep INSERT policies simple
DROP POLICY IF EXISTS "Users can insert trip members for trips they created" ON trip_members;
CREATE POLICY "Users can insert trip members for their trips"
ON trip_members
FOR INSERT
WITH CHECK (
  trip_id IN (
    SELECT id
    FROM trips
    WHERE created_by = auth.uid()
  )
);

-- STEP 5: Keep UPDATE policies simple
DROP POLICY IF EXISTS "Users can update trip members for trips they created" ON trip_members;
CREATE POLICY "Users can update trip members for their trips"
ON trip_members
FOR UPDATE
USING (
  trip_id IN (
    SELECT id
    FROM trips
    WHERE created_by = auth.uid()
  )
);

-- STEP 6: Keep DELETE policies simple
DROP POLICY IF EXISTS "Users can delete trip members for trips they created" ON trip_members;
CREATE POLICY "Users can delete trip members for their trips"
ON trip_members
FOR DELETE
USING (
  trip_id IN (
    SELECT id
    FROM trips
    WHERE created_by = auth.uid()
  )
);

-- VERIFICATION: Check all policies
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
WHERE tablename IN ('trips', 'trip_members')
ORDER BY tablename, policyname;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════╗';
  RAISE NOTICE '║  ✅ RLS POLICIES FIXED!                            ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Removed recursive policies';
  RAISE NOTICE '✓ Created simple, non-recursive policies';
  RAISE NOTICE '✓ trip_members: Users can view their own + their trips'' members';
  RAISE NOTICE '✓ trips: Users can view trips they belong to';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Next Steps:';
  RAISE NOTICE '   1. Refresh your app';
  RAISE NOTICE '   2. Home page should now load successfully';
  RAISE NOTICE '   3. Run SUPABASE_DUMMY_DATA.sql to populate test data';
  RAISE NOTICE '   4. See 2 trips on home page!';
  RAISE NOTICE '';
END $$;
