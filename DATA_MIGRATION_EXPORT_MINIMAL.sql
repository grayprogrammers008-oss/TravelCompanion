-- ============================================================================
-- DATA MIGRATION EXPORT SCRIPT (MINIMAL VERSION)
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
-- MINIMAL VERSION: Only exports core columns that definitely exist
--                   Removed: phone, bio, status, role, and other optional columns
-- ============================================================================

-- Header
SELECT '-- ============================================================================' as import_script;
SELECT '-- DATA IMPORT SCRIPT' as import_script;
SELECT '-- Generated from OLD database (MINIMAL)' as import_script;
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
    'INSERT INTO public.profiles (id, email, full_name, avatar_url, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    email,
    COALESCE(full_name, ''),
    avatar_url,
    created_at,
    updated_at
) as import_script
FROM public.profiles
ORDER BY created_at;

-- ============================================================================
-- SECTION 3: TRIPS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIPS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trips (id, name, description, destination, start_date, end_date, cover_image_url, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    name,
    COALESCE(description, ''),
    destination,
    start_date,
    end_date,
    cover_image_url,
    created_by,
    created_at,
    updated_at
) as import_script
FROM public.trips
ORDER BY created_at;

-- ============================================================================
-- SECTION 4: TRIP MEMBERS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIP MEMBERS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trip_members (id, trip_id, user_id, created_at, updated_at) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    user_id,
    created_at,
    updated_at
) as import_script
FROM public.trip_members
ORDER BY created_at;

-- ============================================================================
-- SECTION 5: ITINERARY ITEMS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- ITINERARY ITEMS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.itinerary_items (id, trip_id, title, description, location, start_time, end_time, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    COALESCE(description, ''),
    location,
    start_time,
    end_time,
    created_by,
    created_at,
    updated_at
) as import_script
FROM public.itinerary_items
ORDER BY created_at;

-- ============================================================================
-- SECTION 6: CHECKLISTS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CHECKLISTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.checklists (id, trip_id, name, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    name,
    created_by,
    created_at,
    updated_at
) as import_script
FROM public.checklists
ORDER BY created_at;

-- ============================================================================
-- SECTION 7: CHECKLIST ITEMS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CHECKLIST ITEMS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.checklist_items (id, checklist_id, title, is_completed, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    checklist_id,
    title,
    COALESCE(is_completed, false),
    created_at,
    updated_at
) as import_script
FROM public.checklist_items
ORDER BY created_at;

-- ============================================================================
-- SECTION 8: EXPENSES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPENSES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.expenses (id, trip_id, title, amount, currency, paid_by, date, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    amount,
    COALESCE(currency, 'INR'),
    paid_by,
    date,
    created_at,
    updated_at
) as import_script
FROM public.expenses
ORDER BY created_at;

-- ============================================================================
-- SECTION 9: EXPENSE SPLITS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPENSE SPLITS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.expense_splits (id, expense_id, user_id, amount, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    expense_id,
    user_id,
    amount,
    created_at,
    updated_at
) as import_script
FROM public.expense_splits
ORDER BY created_at;

-- ============================================================================
-- SECTION 10: SETTLEMENTS DATA (if table exists)
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- SETTLEMENTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.settlements (id, trip_id, from_user, to_user, amount, currency, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    from_user,
    to_user,
    amount,
    COALESCE(currency, 'INR'),
    created_at,
    updated_at
) as import_script
FROM public.settlements
ORDER BY created_at;

-- ============================================================================
-- SECTION 11: CONVERSATIONS DATA (if table exists)
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CONVERSATIONS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.conversations (id, trip_id, name, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    COALESCE(name, 'Chat'),
    created_by,
    created_at,
    updated_at
) as import_script
FROM public.conversations
ORDER BY created_at;

-- ============================================================================
-- SECTION 12: CONVERSATION PARTICIPANTS DATA (if table exists)
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CONVERSATION PARTICIPANTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.conversation_participants (id, conversation_id, user_id, joined_at) VALUES (%L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    conversation_id,
    user_id,
    joined_at
) as import_script
FROM public.conversation_participants
ORDER BY joined_at;

-- ============================================================================
-- SECTION 13: MESSAGES DATA (if table exists)
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- MESSAGES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.messages (id, conversation_id, sender_id, content, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    conversation_id,
    sender_id,
    content,
    created_at,
    updated_at
) as import_script
FROM public.messages
ORDER BY created_at;

-- ============================================================================
-- SECTION 14: FAVORITES DATA (if table exists)
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- FAVORITES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.favorites (id, user_id, place_id, place_name, created_at) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    user_id,
    place_id,
    place_name,
    created_at
) as import_script
FROM public.favorites
ORDER BY created_at;

-- ============================================================================
-- SECTION 15: PLACE CACHE DATA (if table exists)
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- PLACE CACHE DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.place_cache (id, place_id, name, location, created_at) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    place_id,
    name,
    location,
    created_at
) as import_script
FROM public.place_cache
ORDER BY created_at;

-- ============================================================================
-- SECTION 16: END TRANSACTION
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- COMMIT TRANSACTION' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;
SELECT 'COMMIT;' as import_script;

-- ============================================================================
-- SECTION 17: STATISTICS
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
SELECT '-- NOTE: Some columns will have default values in new database (role, status)' as import_script;
SELECT '-- ============================================================================' as import_script;
