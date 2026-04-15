-- ============================================================================
-- DATA EXPORT SCRIPT - Run this on OLD Supabase Database
-- ============================================================================
-- Account: palkarfoods224@gmail.com
--
-- This script generates INSERT statements for all your data
-- Copy the output and save it to DATA_MIGRATION_IMPORT.sql
-- Then run that file on your NEW Supabase database
-- ============================================================================

-- Turn off notices for cleaner output
SET client_min_messages TO WARNING;

-- ============================================================================
-- IMPORTANT: How to use this script
-- ============================================================================
-- 1. Log in to OLD Supabase project (palkarfoods224@gmail.com)
-- 2. Go to SQL Editor
-- 3. Run this ENTIRE script
-- 4. Copy ALL the output
-- 5. Save it as DATA_MIGRATION_IMPORT.sql
-- 6. Run DATA_MIGRATION_IMPORT.sql on NEW database
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'TRAVELCOMPANION DATA EXPORT - GENERATED IMPORT SCRIPT'
\echo '============================================================================'
\echo 'Run this output on your NEW Supabase database to import all data'
\echo '============================================================================'
\echo ''

\echo '-- Disable triggers temporarily for faster import'
\echo 'SET session_replication_role = replica;'
\echo ''

-- ============================================================================
-- SECTION 1: PROFILES
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- PROFILES DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.profiles (id, email, full_name, avatar_url, bio, phone, role, status, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    email,
    full_name,
    avatar_url,
    bio,
    phone,
    role,
    status,
    created_at,
    updated_at
)
FROM public.profiles
ORDER BY created_at;

-- ============================================================================
-- SECTION 2: TRIPS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- TRIPS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.trips (id, name, description, destination, start_date, end_date, cover_image_url, cost, currency, created_by, created_at, updated_at, is_completed, completed_at, rating, is_public) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    name,
    description,
    destination,
    start_date,
    end_date,
    cover_image_url,
    cost,
    currency,
    created_by,
    created_at,
    updated_at,
    is_completed,
    completed_at,
    rating,
    is_public
)
FROM public.trips
ORDER BY created_at;

-- ============================================================================
-- SECTION 3: TRIP MEMBERS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- TRIP MEMBERS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.trip_members (id, trip_id, user_id, role, joined_at) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (trip_id, user_id) DO NOTHING;',
    id,
    trip_id,
    user_id,
    role,
    joined_at
)
FROM public.trip_members
ORDER BY joined_at;

-- ============================================================================
-- SECTION 4: ITINERARY ITEMS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- ITINERARY ITEMS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.itinerary_items (id, trip_id, title, description, location, latitude, longitude, place_id, day_number, order_index, start_time, end_time, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    description,
    location,
    latitude,
    longitude,
    place_id,
    day_number,
    order_index,
    start_time,
    end_time,
    created_by,
    created_at,
    updated_at
)
FROM public.itinerary_items
ORDER BY trip_id, day_number, order_index;

-- ============================================================================
-- SECTION 5: CHECKLISTS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- CHECKLISTS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.checklists (id, trip_id, name, created_by, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    name,
    created_by,
    created_at,
    updated_at
)
FROM public.checklists
ORDER BY created_at;

-- ============================================================================
-- SECTION 6: CHECKLIST ITEMS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- CHECKLIST ITEMS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.checklist_items (id, checklist_id, name, content, is_completed, completed_at, completed_by, order_index, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    checklist_id,
    name,
    content,
    is_completed,
    completed_at,
    completed_by,
    order_index,
    created_at,
    updated_at
)
FROM public.checklist_items
ORDER BY checklist_id, order_index;

-- ============================================================================
-- SECTION 7: EXPENSES
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- EXPENSES DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.expenses (id, trip_id, title, description, amount, currency, category, paid_by, split_type, receipt_url, transaction_date, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    title,
    description,
    amount,
    currency,
    category,
    paid_by,
    split_type,
    receipt_url,
    transaction_date,
    created_at,
    updated_at
)
FROM public.expenses
ORDER BY created_at;

-- ============================================================================
-- SECTION 8: EXPENSE SPLITS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- EXPENSE SPLITS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.expense_splits (id, expense_id, user_id, amount, is_settled, settled_at, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    expense_id,
    user_id,
    amount,
    is_settled,
    settled_at,
    created_at
)
FROM public.expense_splits
ORDER BY created_at;

-- ============================================================================
-- SECTION 9: SETTLEMENTS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- SETTLEMENTS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.settlements (id, trip_id, from_user, to_user, amount, currency, is_settled, settled_at, proof_url, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    from_user,
    to_user,
    amount,
    currency,
    is_settled,
    settled_at,
    proof_url,
    created_at
)
FROM public.settlements
ORDER BY created_at;

-- ============================================================================
-- SECTION 10: MESSAGES
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- MESSAGES DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.messages (id, trip_id, conversation_id, sender_id, message, is_deleted, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    conversation_id,
    sender_id,
    message,
    is_deleted,
    created_at,
    updated_at
)
FROM public.messages
ORDER BY created_at;

-- ============================================================================
-- SECTION 11: CONVERSATIONS (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- CONVERSATIONS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.conversations (id, trip_id, name, description, avatar_url, created_by, is_direct_message, is_default_group, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    name,
    description,
    avatar_url,
    created_by,
    is_direct_message,
    COALESCE(is_default_group, false),
    created_at,
    updated_at
)
FROM public.conversations
ORDER BY created_at;

-- ============================================================================
-- SECTION 12: CONVERSATION MEMBERS (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- CONVERSATION MEMBERS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.conversation_members (id, conversation_id, user_id, role, joined_at, is_muted, last_read_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (conversation_id, user_id) DO NOTHING;',
    id,
    conversation_id,
    user_id,
    role,
    joined_at,
    is_muted,
    last_read_at
)
FROM public.conversation_members
ORDER BY joined_at;

-- ============================================================================
-- SECTION 13: TRIP INVITES
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- TRIP INVITES DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.trip_invites (id, trip_id, email, invited_by, status, created_at, expires_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    email,
    invited_by,
    status,
    created_at,
    expires_at
)
FROM public.trip_invites
ORDER BY created_at;

-- ============================================================================
-- SECTION 14: FCM TOKENS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- FCM TOKENS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.user_fcm_tokens (id, user_id, fcm_token, device_type, device_name, is_active, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (user_id, fcm_token) DO NOTHING;',
    id,
    user_id,
    fcm_token,
    device_type,
    device_name,
    is_active,
    created_at,
    updated_at
)
FROM public.user_fcm_tokens
ORDER BY created_at;

-- ============================================================================
-- SECTION 15: TRIP JOIN REQUESTS (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- TRIP JOIN REQUESTS DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.trip_join_requests (id, trip_id, user_id, message, status, responded_by, responded_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (trip_id, user_id) DO NOTHING;',
    id,
    trip_id,
    user_id,
    message,
    status,
    responded_by,
    responded_at,
    created_at,
    updated_at
)
FROM public.trip_join_requests
ORDER BY created_at;

-- ============================================================================
-- SECTION 16: TRIP FAVORITES (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- TRIP FAVORITES DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.trip_favorites (id, user_id, trip_id, created_at) VALUES (%L, %L, %L, %L) ON CONFLICT (user_id, trip_id) DO NOTHING;',
    id,
    user_id,
    trip_id,
    created_at
)
FROM public.trip_favorites
ORDER BY created_at;

-- ============================================================================
-- SECTION 17: DISCOVER FAVORITES (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- DISCOVER FAVORITES DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.discover_favorites (id, user_id, place_id, place_name, place_category, latitude, longitude, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (user_id, place_id) DO NOTHING;',
    id,
    user_id,
    place_id,
    place_name,
    place_category,
    latitude,
    longitude,
    created_at
)
FROM public.discover_favorites
ORDER BY created_at;

-- ============================================================================
-- SECTION 18: AI USAGE TRACKING (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- AI USAGE TRACKING DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.ai_usage_tracking (id, user_id, feature, usage_count, last_used_at, monthly_limit, is_premium, premium_expires_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (user_id, feature) DO NOTHING;',
    id,
    user_id,
    feature,
    usage_count,
    last_used_at,
    monthly_limit,
    is_premium,
    premium_expires_at,
    created_at,
    updated_at
)
FROM public.ai_usage_tracking
ORDER BY created_at;

-- ============================================================================
-- SECTION 19: PLACE CACHE (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- PLACE CACHE DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.place_cache (id, place_id, name, formatted_address, latitude, longitude, city, state, country, country_code, types, photo_references, website, google_maps_url, rating, user_ratings_total, created_at, updated_at, last_accessed_at, access_count) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (place_id) DO NOTHING;',
    id,
    place_id,
    name,
    formatted_address,
    latitude,
    longitude,
    city,
    state,
    country,
    country_code,
    types,
    photo_references,
    website,
    google_maps_url,
    rating,
    user_ratings_total,
    created_at,
    updated_at,
    last_accessed_at,
    access_count
)
FROM public.place_cache
ORDER BY created_at;

-- ============================================================================
-- SECTION 20: ADMIN ACTIVITY LOG (if exists)
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- ADMIN ACTIVITY LOG DATA'
\echo '-- ============================================================================'
\echo ''

SELECT format(
    'INSERT INTO public.admin_activity_log (id, admin_id, action_type, target_user_id, target_resource_id, target_resource_type, details, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    admin_id,
    action_type,
    target_user_id,
    target_resource_id,
    target_resource_type,
    details,
    created_at
)
FROM public.admin_activity_log
ORDER BY created_at;

-- ============================================================================
-- RE-ENABLE TRIGGERS AND FINISH
-- ============================================================================

\echo ''
\echo '-- Re-enable triggers'
\echo 'SET session_replication_role = DEFAULT;'
\echo ''

\echo ''
\echo '-- ============================================================================'
\echo '-- DATA IMPORT COMPLETE!'
\echo '-- ============================================================================'
\echo '-- Summary:'
\echo '-- - All user profiles imported'
\echo '-- - All trips and members imported'
\echo '-- - All itineraries and checklists imported'
\echo '-- - All expenses and settlements imported'
\echo '-- - All messages and conversations imported'
\echo '-- - All favorites and caches imported'
\echo '--'
\echo '-- Next steps:'
\echo '-- 1. Verify data in Supabase Dashboard'
\echo '-- 2. Test login with existing users'
\echo '-- 3. Check that trips load correctly'
\echo '-- 4. Migrate storage files (avatars, trip covers, receipts)'
\echo '-- ============================================================================'
\echo ''

-- ============================================================================
-- STATISTICS
-- ============================================================================

\echo ''
\echo '-- ============================================================================'
\echo '-- MIGRATION STATISTICS'
\echo '-- ============================================================================'
\echo ''

SELECT format('-- Profiles migrated: %s', COUNT(*)) FROM public.profiles;
SELECT format('-- Trips migrated: %s', COUNT(*)) FROM public.trips;
SELECT format('-- Trip members migrated: %s', COUNT(*)) FROM public.trip_members;
SELECT format('-- Itinerary items migrated: %s', COUNT(*)) FROM public.itinerary_items;
SELECT format('-- Checklists migrated: %s', COUNT(*)) FROM public.checklists;
SELECT format('-- Checklist items migrated: %s', COUNT(*)) FROM public.checklist_items;
SELECT format('-- Expenses migrated: %s', COUNT(*)) FROM public.expenses;
SELECT format('-- Messages migrated: %s', COUNT(*)) FROM public.messages;

\echo ''
\echo '-- ============================================================================'
\echo '-- END OF IMPORT SCRIPT'
\echo '-- ============================================================================'
