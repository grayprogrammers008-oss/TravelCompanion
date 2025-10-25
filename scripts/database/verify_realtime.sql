-- =====================================================
-- VERIFY REALTIME CONFIGURATION
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Check if tables are in the realtime publication
SELECT
    schemaname,
    tablename,
    CASE
        WHEN tablename = ANY(
            SELECT tablename
            FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
        ) THEN '✅ ENABLED'
        ELSE '❌ NOT ENABLED'
    END as realtime_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
    'trips',
    'trip_members',
    'expenses',
    'itinerary_items',
    'checklists',
    'checklist_items',
    'expense_splits'
)
ORDER BY tablename;

-- 2. Show all tables currently in supabase_realtime publication
SELECT
    '📡 Tables in supabase_realtime publication:' as info;
SELECT
    schemaname,
    tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- 3. Check if publication exists
SELECT
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
        THEN '✅ supabase_realtime publication EXISTS'
        ELSE '❌ supabase_realtime publication DOES NOT EXIST'
    END as publication_status;

-- 4. If any tables are missing, run this to add them:
-- (Uncomment the lines below if needed)

/*
ALTER PUBLICATION supabase_realtime ADD TABLE trips;
ALTER PUBLICATION supabase_realtime ADD TABLE trip_members;
ALTER PUBLICATION supabase_realtime ADD TABLE expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE expense_splits;
ALTER PUBLICATION supabase_realtime ADD TABLE itinerary_items;
ALTER PUBLICATION supabase_realtime ADD TABLE checklists;
ALTER PUBLICATION supabase_realtime ADD TABLE checklist_items;
*/
