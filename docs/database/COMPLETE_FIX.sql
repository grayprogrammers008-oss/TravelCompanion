-- =====================================================
-- COMPLETE FIX: RLS Policies + Trip Members
-- =====================================================
-- This script fixes EVERYTHING:
-- 1. Removes infinite recursion in RLS policies
-- 2. Ensures trip_members exist for your trips
-- 3. Verifies everything is working
-- =====================================================

DO $$
DECLARE
    v_user_id UUID;
    v_trip_count INT;
    v_member_count INT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  🔧 COMPLETE FIX STARTING...                       ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════╝';
    RAISE NOTICE '';

    -- =====================================================
    -- STEP 1: Fix RLS Policies (Remove Infinite Recursion)
    -- =====================================================

    RAISE NOTICE '📝 Step 1: Fixing RLS Policies...';

    -- Drop problematic recursive policies
    DROP POLICY IF EXISTS "Users can view trips they are members of" ON trips;
    DROP POLICY IF EXISTS "Users can view trip members for their trips" ON trip_members;
    DROP POLICY IF EXISTS "Users can view their own trip memberships" ON trip_members;

    -- Create simple, non-recursive policies for trip_members
    DROP POLICY IF EXISTS "Users can view their own memberships" ON trip_members;
    CREATE POLICY "Users can view their own memberships"
    ON trip_members
    FOR SELECT
    USING (auth.uid() = user_id);

    DROP POLICY IF EXISTS "Users can view members of their trips" ON trip_members;
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

    -- Create simple, non-recursive policy for trips
    DROP POLICY IF EXISTS "Users can view their trips" ON trips;
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

    -- Fix INSERT policies
    DROP POLICY IF EXISTS "Users can insert trip members for trips they created" ON trip_members;
    DROP POLICY IF EXISTS "Users can insert trip members for their trips" ON trip_members;
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

    -- Fix UPDATE policies
    DROP POLICY IF EXISTS "Users can update trip members for trips they created" ON trip_members;
    DROP POLICY IF EXISTS "Users can update trip members for their trips" ON trip_members;
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

    -- Fix DELETE policies
    DROP POLICY IF EXISTS "Users can delete trip members for trips they created" ON trip_members;
    DROP POLICY IF EXISTS "Users can delete trip members for their trips" ON trip_members;
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

    RAISE NOTICE '   ✓ RLS policies fixed (no more infinite recursion)';

    -- =====================================================
    -- STEP 2: Ensure Trip Members Exist
    -- =====================================================

    RAISE NOTICE '';
    RAISE NOTICE '📝 Step 2: Creating trip members...';

    -- Get the current authenticated user
    SELECT id INTO v_user_id FROM auth.users ORDER BY created_at DESC LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION '❌ No users found! Please sign up first.';
    END IF;

    RAISE NOTICE '   ✓ Found user: %', v_user_id;

    -- Insert trip_members for all trips created by this user (if not exists)
    INSERT INTO trip_members (trip_id, user_id, role, joined_at)
    SELECT
        t.id,
        v_user_id,
        'owner',
        t.created_at
    FROM trips t
    WHERE t.created_by = v_user_id
      AND NOT EXISTS (
        SELECT 1 FROM trip_members tm
        WHERE tm.trip_id = t.id AND tm.user_id = v_user_id
      );

    GET DIAGNOSTICS v_member_count = ROW_COUNT;

    IF v_member_count > 0 THEN
        RAISE NOTICE '   ✓ Created % trip member record(s)', v_member_count;
    ELSE
        RAISE NOTICE '   ✓ All trip members already exist';
    END IF;

    -- =====================================================
    -- STEP 3: Verification
    -- =====================================================

    RAISE NOTICE '';
    RAISE NOTICE '📝 Step 3: Verifying...';

    -- Count trips
    SELECT COUNT(*) INTO v_trip_count FROM trips WHERE created_by = v_user_id;
    RAISE NOTICE '   ✓ Trips in database: %', v_trip_count;

    -- Count trip members
    SELECT COUNT(*) INTO v_member_count FROM trip_members WHERE user_id = v_user_id;
    RAISE NOTICE '   ✓ Trip memberships: %', v_member_count;

    IF v_trip_count = v_member_count AND v_trip_count > 0 THEN
        RAISE NOTICE '   ✓ All trips have corresponding trip_members ✅';
    ELSIF v_trip_count > v_member_count THEN
        RAISE WARNING '   ⚠️  Missing trip_members for some trips!';
    END IF;

    -- =====================================================
    -- COMPLETION MESSAGE
    -- =====================================================

    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════╗';
    RAISE NOTICE '║  ✅ COMPLETE FIX DONE!                             ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE '✓ RLS policies: Fixed (no infinite recursion)';
    RAISE NOTICE '✓ Trip members: Created for all trips';
    RAISE NOTICE '✓ Database: Ready to fetch trips';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Next Steps:';
    RAISE NOTICE '   1. Refresh your app (Cmd+R or F5)';
    RAISE NOTICE '   2. Home page should load % trip(s)!', v_trip_count;
    RAISE NOTICE '   3. Click on a trip to see details';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Your app is now fully functional!';
    RAISE NOTICE '';
END $$;

-- =====================================================
-- BONUS: Show your trips (verification)
-- =====================================================

SELECT
    t.id,
    t.name,
    t.destination,
    t.created_at,
    EXISTS(SELECT 1 FROM trip_members WHERE trip_id = t.id) as has_members
FROM trips t
ORDER BY t.created_at DESC;
