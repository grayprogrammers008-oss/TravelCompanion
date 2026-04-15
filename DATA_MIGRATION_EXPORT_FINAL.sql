-- ============================================================================
-- DATA MIGRATION EXPORT SCRIPT (FINAL VERSION)
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
-- FIXED: Removed columns that may not exist in old database (phone, bio)
--        Only exports core columns that are guaranteed to exist
-- ============================================================================

-- Header
SELECT '-- ============================================================================' as import_script;
SELECT '-- DATA IMPORT SCRIPT' as import_script;
SELECT '-- Generated from OLD database' as import_script;
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
    'INSERT INTO public.profiles (id, email, full_name, avatar_url, role, status, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    email,
    full_name,
    avatar_url,
    role::text,
    status::text,
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
    'INSERT INTO public.trips (id, name, description, destination, start_date, end_date, cover_image_url, created_by, created_at, updated_at, is_completed, completed_at, rating) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    name,
    description,
    destination,
    start_date,
    end_date,
    cover_image_url,
    created_by,
    created_at,
    updated_at,
    COALESCE(is_completed, false),
    completed_at,
    rating
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
    'INSERT INTO public.trip_members (id, trip_id, user_id, role, status, joined_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    user_id,
    role::text,
    status::text,
    joined_at,
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
    'INSERT INTO public.itinerary_items (id, trip_id, title, description, location, start_time, end_time, category, is_completed, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    description,
    location,
    start_time,
    end_time,
    category::text,
    COALESCE(is_completed, false),
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
    'INSERT INTO public.checklist_items (id, checklist_id, title, is_completed, completed_by, completed_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    checklist_id,
    title,
    COALESCE(is_completed, false),
    completed_by,
    completed_at,
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
    'INSERT INTO public.expenses (id, trip_id, title, amount, currency, category, paid_by, date, receipt_url, notes, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    amount,
    currency,
    category::text,
    paid_by,
    date,
    receipt_url,
    notes,
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
    'INSERT INTO public.expense_splits (id, expense_id, user_id, amount, is_settled, settled_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    expense_id,
    user_id,
    amount,
    COALESCE(is_settled, false),
    settled_at,
    created_at,
    updated_at
) as import_script
FROM public.expense_splits
ORDER BY created_at;

-- ============================================================================
-- SECTION 10: SETTLEMENTS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- SETTLEMENTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.settlements (id, trip_id, from_user, to_user, amount, currency, status, settled_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    from_user,
    to_user,
    amount,
    currency,
    status::text,
    settled_at,
    created_at,
    updated_at
) as import_script
FROM public.settlements
ORDER BY created_at;

-- ============================================================================
-- SECTION 11: CONVERSATIONS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CONVERSATIONS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.conversations (id, trip_id, name, type, created_by, created_at, updated_at, last_message_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    name,
    type::text,
    created_by,
    created_at,
    updated_at,
    last_message_at
) as import_script
FROM public.conversations
ORDER BY created_at;

-- ============================================================================
-- SECTION 12: CONVERSATION PARTICIPANTS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CONVERSATION PARTICIPANTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.conversation_participants (id, conversation_id, user_id, joined_at, last_read_at) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    conversation_id,
    user_id,
    joined_at,
    last_read_at
) as import_script
FROM public.conversation_participants
ORDER BY joined_at;

-- ============================================================================
-- SECTION 13: MESSAGES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- MESSAGES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.messages (id, conversation_id, sender_id, content, type, metadata, created_at, updated_at, is_deleted) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    conversation_id,
    sender_id,
    content,
    type::text,
    metadata::text,
    created_at,
    updated_at,
    COALESCE(is_deleted, false)
) as import_script
FROM public.messages
ORDER BY created_at;

-- ============================================================================
-- SECTION 14: FAVORITES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- FAVORITES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.favorites (id, user_id, place_id, place_name, place_type, place_data, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    user_id,
    place_id,
    place_name,
    place_type,
    place_data::text,
    created_at
) as import_script
FROM public.favorites
ORDER BY created_at;

-- ============================================================================
-- SECTION 15: PLACE CACHE DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- PLACE CACHE DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.place_cache (id, place_id, category, name, location, data, expires_at, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    place_id,
    category::text,
    name,
    location,
    data::text,
    expires_at,
    created_at
) as import_script
FROM public.place_cache
ORDER BY created_at;

-- ============================================================================
-- SECTION 16: NEARBY SEARCH CACHE DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- NEARBY SEARCH CACHE DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.nearby_search_cache (id, location, radius, category, results, expires_at, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    location,
    radius,
    category::text,
    results::text,
    expires_at,
    created_at
) as import_script
FROM public.nearby_search_cache
ORDER BY created_at;

-- ============================================================================
-- SECTION 17: END TRANSACTION
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- COMMIT TRANSACTION' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;
SELECT 'COMMIT;' as import_script;

-- ============================================================================
-- SECTION 18: STATISTICS
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
SELECT format('-- Settlements exported: %s', COUNT(*)) as import_script FROM public.settlements;
SELECT format('-- Conversations exported: %s', COUNT(*)) as import_script FROM public.conversations;
SELECT format('-- Conversation participants exported: %s', COUNT(*)) as import_script FROM public.conversation_participants;
SELECT format('-- Messages exported: %s', COUNT(*)) as import_script FROM public.messages;
SELECT format('-- Favorites exported: %s', COUNT(*)) as import_script FROM public.favorites;
SELECT format('-- Place cache exported: %s', COUNT(*)) as import_script FROM public.place_cache;
SELECT format('-- Nearby search cache exported: %s', COUNT(*)) as import_script FROM public.nearby_search_cache;

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPORT COMPLETE!' as import_script;
SELECT '-- Copy all output above and save to: MY_DATA_IMPORT.sql' as import_script;
SELECT '-- Then run MY_DATA_IMPORT.sql in NEW Supabase project' as import_script;
SELECT '-- ============================================================================' as import_script;
