-- ============================================================================
-- CLEANUP SCRIPT FOR NITHYA'S DUMMY DATA
-- ============================================================================
-- This script removes all dummy data for nithyaganesan53@gmail.com
-- Run this BEFORE running CREATE_NITHYA_DUMMY_DATA.sql if you need to reset
-- ============================================================================

DO $$
DECLARE
    nithya_user_id UUID;
    deleted_count INTEGER;
BEGIN
    -- Get Nithya's user ID
    SELECT id INTO nithya_user_id FROM auth.users WHERE email = 'nithyaganesan53@gmail.com';

    -- Check if Nithya's account exists
    IF nithya_user_id IS NULL THEN
        RAISE NOTICE 'User nithyaganesan53@gmail.com not found. Nothing to cleanup.';
        RETURN;
    END IF;

    RAISE NOTICE 'Cleaning up dummy data for Nithya (User ID: %)', nithya_user_id;

    -- Delete in order to respect foreign key constraints

    -- 1. Delete checklist items (via their parent checklists created by Nithya)
    DELETE FROM checklist_items
    WHERE checklist_id IN (SELECT id FROM checklists WHERE created_by = nithya_user_id);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % checklist items', deleted_count;

    -- 2. Delete checklists
    DELETE FROM checklists
    WHERE created_by = nithya_user_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % checklists', deleted_count;

    -- 3. Delete expense splits (for expenses Nithya was part of)
    DELETE FROM expense_splits
    WHERE user_id = nithya_user_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % expense splits', deleted_count;

    -- 4. Delete expenses paid by Nithya
    DELETE FROM expenses
    WHERE paid_by = nithya_user_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % expenses', deleted_count;

    -- 5. Delete itinerary items
    DELETE FROM itinerary_items
    WHERE created_by = nithya_user_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % itinerary items', deleted_count;

    -- 6. Delete trip members (Nithya's membership in trips)
    DELETE FROM trip_members
    WHERE user_id = nithya_user_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % trip memberships', deleted_count;

    -- 7. Delete trips created by Nithya
    DELETE FROM trips
    WHERE created_by = nithya_user_id;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '   ✓ Deleted % trips', deleted_count;

    RAISE NOTICE '';
    RAISE NOTICE '✅ Cleanup completed successfully!';
    RAISE NOTICE '   All dummy data for nithyaganesan53@gmail.com has been removed.';
    RAISE NOTICE '   You can now run CREATE_NITHYA_DUMMY_DATA.sql to add fresh data.';

END $$;
