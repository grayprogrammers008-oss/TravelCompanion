-- ============================================================================
-- Travel Crew - User Account Troubleshooting SQL Script
-- Run this in Supabase SQL Editor to diagnose and fix login issues
-- ============================================================================

-- STEP 1: Check if user exists
-- Replace 'user@example.com' with the actual email
SELECT
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at,
    CASE
        WHEN email_confirmed_at IS NULL THEN '❌ NOT CONFIRMED'
        ELSE '✅ CONFIRMED'
    END as status
FROM auth.users
WHERE email = 'user@example.com'; -- CHANGE THIS EMAIL

-- ============================================================================

-- STEP 2: If user exists but email not confirmed, fix it:
-- IMPORTANT: Replace 'user@example.com' with actual email
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'user@example.com'  -- CHANGE THIS EMAIL
AND email_confirmed_at IS NULL;

-- ============================================================================

-- STEP 3: Check if user has a profile in profiles table
SELECT
    p.id,
    p.email,
    p.full_name,
    p.created_at,
    CASE
        WHEN p.id IS NULL THEN '❌ NO PROFILE'
        ELSE '✅ HAS PROFILE'
    END as profile_status
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE u.email = 'user@example.com'; -- CHANGE THIS EMAIL

-- ============================================================================

-- STEP 4: If profile is missing, create it manually
-- This should normally be done by the trigger, but we can do it manually
-- REPLACE the values below:

/*
INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
SELECT
    u.id,
    u.email,
    'User Full Name', -- CHANGE THIS
    NOW(),
    NOW()
FROM auth.users u
WHERE u.email = 'user@example.com'  -- CHANGE THIS EMAIL
AND NOT EXISTS (
    SELECT 1 FROM public.profiles p WHERE p.id = u.id
);
*/

-- ============================================================================

-- STEP 5: List all users and their status (for admin review)
SELECT
    u.email,
    u.email_confirmed_at,
    u.created_at,
    u.last_sign_in_at,
    CASE
        WHEN u.email_confirmed_at IS NULL THEN '❌ Needs confirmation'
        WHEN p.id IS NULL THEN '⚠️  Missing profile'
        ELSE '✅ Ready'
    END as account_status,
    p.full_name
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at DESC
LIMIT 20;

-- ============================================================================

-- STEP 6: Check RLS policies on profiles table
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'profiles';

-- ============================================================================

-- STEP 7: If RLS policies are missing, create them
-- Uncomment and run if needed:

/*
-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
CREATE POLICY "Users can read own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- Allow authenticated users to insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);
*/

-- ============================================================================

-- STEP 8: Test if email confirmation is required in project settings
-- This queries the auth config
SELECT
    key,
    value
FROM auth.config
WHERE key IN ('MAILER_AUTOCONFIRM', 'DISABLE_SIGNUP', 'ENABLE_SIGNUP');

-- ============================================================================

-- STEP 9: Bulk confirm all unconfirmed emails (USE WITH CAUTION!)
-- Only for development/testing - DO NOT use in production
-- Uncomment to run:

/*
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;
*/

-- ============================================================================

-- STEP 10: Check for specific error cases

-- A. Check for duplicate emails (shouldn't happen but worth checking)
SELECT email, COUNT(*) as count
FROM auth.users
GROUP BY email
HAVING COUNT(*) > 1;

-- B. Check for users without profiles
SELECT u.id, u.email, u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- C. Check recent authentication attempts (if audit log is enabled)
-- This requires auth.audit_log_entries table to exist
SELECT
    created_at,
    payload->>'action' as action,
    payload->>'actor_id' as user_id,
    payload->>'error_message' as error
FROM auth.audit_log_entries
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 50;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================

-- Quick Reference:
-- 1. Find user: SELECT * FROM auth.users WHERE email = 'email@example.com';
-- 2. Confirm email: UPDATE auth.users SET email_confirmed_at = NOW() WHERE email = 'email@example.com';
-- 3. Check profile: SELECT * FROM profiles WHERE email = 'email@example.com';
-- 4. List all users: SELECT email, email_confirmed_at FROM auth.users ORDER BY created_at DESC;
