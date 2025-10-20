-- =====================================================
-- DEBUG: Check Trips and Trip Members
-- =====================================================
-- Run this to see what's in your database
-- =====================================================

-- Check trips
SELECT
    id,
    name,
    destination,
    created_by,
    created_at
FROM trips
ORDER BY created_at DESC;

-- Check trip_members
SELECT
    id,
    trip_id,
    user_id,
    role,
    joined_at
FROM trip_members
ORDER BY joined_at DESC;

-- Check auth users
SELECT
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
ORDER BY created_at DESC;

-- Check if trip_members exist for your trips
SELECT
    t.id as trip_id,
    t.name as trip_name,
    t.created_by,
    COUNT(tm.id) as member_count
FROM trips t
LEFT JOIN trip_members tm ON t.id = tm.trip_id
GROUP BY t.id, t.name, t.created_by
ORDER BY t.created_at DESC;
