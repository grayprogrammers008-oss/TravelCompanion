-- ============================================================================
-- DATA EXPORT SCRIPT - FIXED FOR SUPABASE SQL EDITOR
-- ============================================================================
-- Run this on OLD Supabase Database (palkarfoods224@gmail.com)
--
-- This script generates INSERT statements for all your data
-- Copy ALL the output and save it to a new file
-- Then run that file on your NEW Supabase database
-- ============================================================================

-- ============================================================================
-- HOW TO USE:
-- 1. Copy this ENTIRE script
-- 2. Paste into OLD Supabase SQL Editor
-- 3. Click RUN
-- 4. Copy ALL output from the Results panel below
-- 5. Save to new file: MY_DATA_IMPORT.sql
-- 6. Run MY_DATA_IMPORT.sql in NEW Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- SECTION 1: HEADER
-- ============================================================================

SELECT '-- ============================================================================' as import_script;
SELECT '-- TRAVELCOMPANION DATA IMPORT SCRIPT' as import_script;
SELECT '-- Generated from old Supabase database' as import_script;
SELECT '-- Run this on NEW Supabase database to import all data' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT '-- Disable triggers temporarily for faster import' as import_script;
SELECT 'SET session_replication_role = replica;' as import_script;
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
    'INSERT INTO public.profiles (id, email, full_name, avatar_url, bio, phone, role, status, created_at, updated_at) VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    email,
    full_name,
    avatar_url,
    bio,
    phone,
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
    'INSERT INTO public.trip_members (id, trip_id, user_id, role, joined_at) VALUES (%L, %L, %L, %L, %L) ON CONFLICT (trip_id, user_id) DO NOTHING;',
    id,
    trip_id,
    user_id,
    role,
    joined_at
) as import_script
FROM public.trip_members
ORDER BY joined_at;

-- ============================================================================
-- SECTION 5: ITINERARY ITEMS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- ITINERARY ITEMS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.itinerary_items
ORDER BY trip_id, day_number, order_index;

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
) as import_script
FROM public.checklist_items
ORDER BY checklist_id, order_index;

-- ============================================================================
-- SECTION 8: EXPENSES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- EXPENSES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
    'INSERT INTO public.expense_splits (id, expense_id, user_id, amount, is_settled, settled_at, created_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    expense_id,
    user_id,
    amount,
    is_settled,
    settled_at,
    created_at
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
) as import_script
FROM public.settlements
ORDER BY created_at;

-- ============================================================================
-- SECTION 11: MESSAGES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- MESSAGES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.messages
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'messages')
ORDER BY created_at;

-- ============================================================================
-- SECTION 12: CONVERSATIONS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CONVERSATIONS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.conversations
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversations')
ORDER BY created_at;

-- ============================================================================
-- SECTION 13: CONVERSATION MEMBERS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- CONVERSATION MEMBERS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.conversation_members (id, conversation_id, user_id, role, joined_at, is_muted, last_read_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (conversation_id, user_id) DO NOTHING;',
    id,
    conversation_id,
    user_id,
    role,
    joined_at,
    is_muted,
    last_read_at
) as import_script
FROM public.conversation_members
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversation_members')
ORDER BY joined_at;

-- ============================================================================
-- SECTION 14: TRIP INVITES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIP INVITES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trip_invites (id, trip_id, email, invited_by, status, created_at, expires_at) VALUES (%L, %L, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    trip_id,
    email,
    invited_by,
    status,
    created_at,
    expires_at
) as import_script
FROM public.trip_invites
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trip_invites')
ORDER BY created_at;

-- ============================================================================
-- SECTION 15: FCM TOKENS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- FCM TOKENS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.user_fcm_tokens
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_fcm_tokens')
ORDER BY created_at;

-- ============================================================================
-- SECTION 16: TRIP JOIN REQUESTS DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIP JOIN REQUESTS DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trip_join_requests (id, trip_id, user_id, message, status, responded_by, responded_at, created_at, updated_at) VALUES (%L, %L, %L, %L, %L::join_request_status, %L, %L, %L, %L) ON CONFLICT (trip_id, user_id) DO NOTHING;',
    id,
    trip_id,
    user_id,
    message,
    status::text,
    responded_by,
    responded_at,
    created_at,
    updated_at
) as import_script
FROM public.trip_join_requests
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trip_join_requests')
ORDER BY created_at;

-- ============================================================================
-- SECTION 17: TRIP FAVORITES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- TRIP FAVORITES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.trip_favorites (id, user_id, trip_id, created_at) VALUES (%L, %L, %L, %L) ON CONFLICT (user_id, trip_id) DO NOTHING;',
    id,
    user_id,
    trip_id,
    created_at
) as import_script
FROM public.trip_favorites
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trip_favorites')
ORDER BY created_at;

-- ============================================================================
-- SECTION 18: DISCOVER FAVORITES DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- DISCOVER FAVORITES DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.discover_favorites
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'discover_favorites')
ORDER BY created_at;

-- ============================================================================
-- SECTION 19: AI USAGE TRACKING DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- AI USAGE TRACKING DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.ai_usage_tracking
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_usage_tracking')
ORDER BY created_at;

-- ============================================================================
-- SECTION 20: PLACE CACHE DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- PLACE CACHE DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

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
) as import_script
FROM public.place_cache
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'place_cache')
ORDER BY created_at;

-- ============================================================================
-- SECTION 21: ADMIN ACTIVITY LOG DATA
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- ADMIN ACTIVITY LOG DATA' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format(
    'INSERT INTO public.admin_activity_log (id, admin_id, action_type, target_user_id, target_resource_id, target_resource_type, details, created_at) VALUES (%L, %L, %L::admin_action_type, %L, %L, %L, %L, %L) ON CONFLICT (id) DO NOTHING;',
    id,
    admin_id,
    action_type::text,
    target_user_id,
    target_resource_id,
    target_resource_type,
    details,
    created_at
) as import_script
FROM public.admin_activity_log
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_activity_log')
ORDER BY created_at;

-- ============================================================================
-- SECTION 22: RE-ENABLE TRIGGERS AND FINISH
-- ============================================================================

SELECT '' as import_script;
SELECT '-- Re-enable triggers' as import_script;
SELECT 'SET session_replication_role = DEFAULT;' as import_script;
SELECT '' as import_script;

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- DATA IMPORT COMPLETE!' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- Summary:' as import_script;
SELECT '-- - All user profiles imported' as import_script;
SELECT '-- - All trips and members imported' as import_script;
SELECT '-- - All itineraries and checklists imported' as import_script;
SELECT '-- - All expenses and settlements imported' as import_script;
SELECT '-- - All messages and conversations imported' as import_script;
SELECT '-- - All favorites and caches imported' as import_script;
SELECT '--' as import_script;
SELECT '-- Next steps:' as import_script;
SELECT '-- 1. Verify data in Supabase Dashboard' as import_script;
SELECT '-- 2. Test login with existing users' as import_script;
SELECT '-- 3. Check that trips load correctly' as import_script;
SELECT '-- 4. Migrate storage files (avatars, trip covers, receipts)' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

-- ============================================================================
-- SECTION 23: MIGRATION STATISTICS
-- ============================================================================

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- MIGRATION STATISTICS' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '' as import_script;

SELECT format('-- Profiles migrated: %s', COUNT(*)) as import_script FROM public.profiles;
SELECT format('-- Trips migrated: %s', COUNT(*)) as import_script FROM public.trips;
SELECT format('-- Trip members migrated: %s', COUNT(*)) as import_script FROM public.trip_members;
SELECT format('-- Itinerary items migrated: %s', COUNT(*)) as import_script FROM public.itinerary_items;
SELECT format('-- Checklists migrated: %s', COUNT(*)) as import_script FROM public.checklists;
SELECT format('-- Checklist items migrated: %s', COUNT(*)) as import_script FROM public.checklist_items;
SELECT format('-- Expenses migrated: %s', COUNT(*)) as import_script FROM public.expenses;

SELECT '' as import_script;
SELECT '-- ============================================================================' as import_script;
SELECT '-- END OF IMPORT SCRIPT' as import_script;
SELECT '-- ============================================================================' as import_script;
