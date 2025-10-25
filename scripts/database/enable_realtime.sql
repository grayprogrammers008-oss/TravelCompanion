-- =====================================================
-- ENABLE REALTIME FOR TRAVEL COMPANION
-- Run this in your Supabase SQL Editor
-- =====================================================

-- This script will enable Realtime for all required tables
-- It's safe to run multiple times (idempotent)

-- First, ensure the publication exists (it should by default in Supabase)
-- If this fails, it means Realtime is not enabled on your Supabase project

-- Add tables to the realtime publication
-- These commands will fail silently if table is already in publication

-- Note: If tables are already in the publication, they will be skipped automatically
DO $$
DECLARE
    table_name TEXT;
    tables_to_add TEXT[] := ARRAY['trips', 'trip_members', 'trip_invites', 'expenses',
                                   'expense_splits', 'itinerary_items', 'checklists', 'checklist_items'];
    already_added INT := 0;
    newly_added INT := 0;
BEGIN
    FOREACH table_name IN ARRAY tables_to_add
    LOOP
        -- Check if table is already in publication
        IF EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
            AND tablename = table_name
        ) THEN
            RAISE NOTICE '✓ Table % is already in realtime publication', table_name;
            already_added := already_added + 1;
        ELSE
            -- Add table to publication
            BEGIN
                EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I', table_name);
                RAISE NOTICE '✅ Added table % to realtime publication', table_name;
                newly_added := newly_added + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE NOTICE '❌ Failed to add table %: %', table_name, SQLERRM;
            END;
        END IF;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '   - Already enabled: % tables', already_added;
    RAISE NOTICE '   - Newly enabled: % tables', newly_added;
    RAISE NOTICE '   - Total: % tables with realtime', already_added + newly_added;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Realtime configuration complete!';
END $$;

-- Verify the setup
SELECT
    '📡 Realtime is now enabled for the following tables:' as status;

SELECT
    schemaname,
    tablename,
    '✅ ENABLED' as status
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename IN (
    'trips',
    'trip_members',
    'trip_invites',
    'expenses',
    'expense_splits',
    'itinerary_items',
    'checklists',
    'checklist_items'
)
ORDER BY tablename;

-- Count total tables
SELECT
    COUNT(*) as total_tables_with_realtime,
    '✅ Your Realtime setup is complete!' as message
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename IN (
    'trips',
    'trip_members',
    'trip_invites',
    'expenses',
    'expense_splits',
    'itinerary_items',
    'checklists',
    'checklist_items'
);
