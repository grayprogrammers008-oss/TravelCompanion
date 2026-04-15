-- ============================================================================
-- DATA MIGRATION EXPORT SCRIPT (BARE MINIMUM VERSION)
-- ============================================================================
--
-- PURPOSE: Export all data from OLD Supabase database to importable SQL format
--
-- HOW TO USE:
-- 1. Open OLD Supabase project (palkarfoods224@gmail.com)
-- 2. Go to SQL Editor
-- 3. Copy this ENTIRE file
-- 4. Paste and click RUN
-- 5. Copy ALL output from the "import_script" column
-- 6. Save output to a new file: MY_DATA_IMPORT.sql
-- 7. Run MY_DATA_IMPORT.sql in NEW Supabase project
--
-- BARE MINIMUM: Only IDs, foreign keys, and core text/number fields
--               NO dates, NO timestamps, NO optional columns
-- ============================================================================

-- Header
SELECT '-- ============================================================================' as import_script;
SELECT '-- DATA IMPORT SCRIPT' as import_script;
SELECT '-- Generated from OLD database (BARE MINIMUM)' as import_script;
SELECT '-- Run this in NEW Supabase database AFTER running CLEAN_MIGRATION.sql' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

-- ============================================================================
-- SECTION 1: START TRANSACTION
-- ============================================================================

SELECT 'BEGIN;' as import_script;
SELECT '' as import_script;

-- ============================================================================
-- SECTION 2: PROFILES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- PROFILES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.profiles (id, email, full_name) VALUES (%L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    email,
    COALESCE(full_name, email)
) as import_script
FROM public.profiles
ORDER BY id;

-- ============================================================================
-- SECTION 3: TRIPS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIPS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trips (id, name, destination, created_by) VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    name,
    COALESCE(destination, ''),
    created_by
) as import_script
FROM public.trips
ORDER BY id;

-- ============================================================================
-- SECTION 4: TRIP MEMBERS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIP MEMBERS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trip_members (id, trip_id, user_id) VALUES (%L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    user_id
) as import_script
FROM public.trip_members
ORDER BY id;

-- ============================================================================
-- SECTION 5: ITINERARY ITEMS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- ITINERARY ITEMS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.itinerary_items (id, trip_id, title, created_by) VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    created_by
) as import_script
FROM public.itinerary_items
ORDER BY id;

-- ============================================================================
-- SECTION 6: CHECKLISTS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CHECKLISTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.checklists (id, trip_id, name, created_by) VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    name,
    created_by
) as import_script
FROM public.checklists
ORDER BY id;

-- ============================================================================
-- SECTION 7: CHECKLIST ITEMS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CHECKLIST ITEMS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.checklist_items (id, checklist_id, title, is_completed) VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    checklist_id,
    title,
    COALESCE(is_completed, false)
) as import_script
FROM public.checklist_items
ORDER BY id;

-- ============================================================================
-- SECTION 8: EXPENSES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPENSES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.expenses (id, trip_id, title, amount, paid_by) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    COALESCE(amount, 0),
    paid_by
) as import_script
FROM public.expenses
ORDER BY id;

-- ============================================================================
-- SECTION 9: EXPENSE SPLITS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPENSE SPLITS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.expense_splits (id, expense_id, user_id, amount) VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    expense_id,
    user_id,
    COALESCE(amount, 0)
) as import_script
FROM public.expense_splits
ORDER BY id;

-- ============================================================================
-- SECTION 10: END TRANSACTION
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- COMMIT TRANSACTION' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;
SELECT 'COMMIT;' as import_script;

-- ============================================================================
-- SECTION 11: STATISTICS
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- MIGRATION STATISTICS' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format('-- Profiles exported: %s', COUNT(*)) as import_script FROM public.profiles;
SELECT format('-- Trips exported: %s', COUNT(*)) as import_script FROM public.trips;
SELECT format('-- Trip members exported: %s', COUNT(*)) as import_script FROM public.trip_members;
SELECT format('-- Itinerary items exported: %s', COUNT(*)) as import_script FROM public.itinerary_items;
SELECT format('-- Checklists exported: %s', COUNT(*)) as import_script FROM public.checklists;
SELECT format('-- Checklist items exported: %s', COUNT(*)) as import_script FROM public.checklist_items;
SELECT format('-- Expenses exported: %s', COUNT(*)) as import_script FROM public.expenses;
SELECT format('-- Expense splits exported: %s', COUNT(*)) as import_script FROM public.expense_splits;

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPORT COMPLETE!' as import_script;
SELECT '-- Copy all output above and save to: MY_DATA_IMPORT.sql' as import_script;
SELECT '-- Then run MY_DATA_IMPORT.sql in NEW Supabase project' as import_script;
SELECT '-- NOTE: Missing columns will get default values in new database' as import_script;
SELECT '-- ============================================================================' as import_script;
