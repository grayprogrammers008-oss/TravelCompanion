-- DIAGNOSTIC: Why is signup / profile creation failing?
-- Run in Supabase Dashboard → SQL Editor. Read-only — safe.
-- Paste the output back to Claude.
--
-- The signup flow needs THREE things in order:
--   1. Auth user is created in auth.users          (Supabase handles this)
--   2. Trigger fires, creates row in public.profiles
--   3. App SELECTs the new profile (RLS allows it)
--
-- This script checks all three.

-- ───────────────────────────────────────────────────────────────────
-- 1. Does the profile-creation trigger exist?
-- ───────────────────────────────────────────────────────────────────
SELECT
  'trigger' AS check_name,
  trigger_name,
  event_object_schema || '.' || event_object_table AS table_name,
  action_timing,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
-- EXPECTED: 1 row. If 0 rows → migration 20260417 was NOT applied. This is the bug.

-- ───────────────────────────────────────────────────────────────────
-- 2. Does the trigger function exist?
-- ───────────────────────────────────────────────────────────────────
SELECT
  'function' AS check_name,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS args,
  p.prosecdef AS is_security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'handle_new_user';
-- EXPECTED: 1 row with is_security_definer = true.

-- ───────────────────────────────────────────────────────────────────
-- 3. What columns does profiles actually have? (vs what the trigger inserts)
-- ───────────────────────────────────────────────────────────────────
SELECT
  'profiles_schema' AS check_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;
-- LOOK FOR: any NOT NULL column without a default that the trigger doesn't fill.
-- The trigger inserts: id, email, full_name, created_at, updated_at.
-- Any OTHER column that is NOT NULL without a default will cause the trigger to fail silently.

-- ───────────────────────────────────────────────────────────────────
-- 4. What RLS policies are on profiles?
-- ───────────────────────────────────────────────────────────────────
SELECT
  'rls_policy' AS check_name,
  policyname,
  cmd AS operation,
  roles,
  qual AS using_expr,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles';
-- EXPECTED: at least one SELECT policy. INSERT policy is OPTIONAL because the
-- trigger uses SECURITY DEFINER and bypasses RLS. But if the trigger is broken,
-- the Dart fallback insert WILL be blocked without an INSERT policy.

-- ───────────────────────────────────────────────────────────────────
-- 5. Is "Confirm email" turned on? (most common silent killer)
-- ───────────────────────────────────────────────────────────────────
-- This can't be queried via SQL — check it in Dashboard:
--   Supabase → Authentication → Sign In / Up → "Confirm email"
-- If ON:  signUp() returns a user but NO session. App is NOT logged in.
--         App tries to SELECT profile → blocked by RLS (no auth.uid()).
-- If OFF: signUp() returns user + session immediately. Recommended for v1.

-- ───────────────────────────────────────────────────────────────────
-- 6. How many auth users exist vs profiles? (orphan check)
-- ───────────────────────────────────────────────────────────────────
SELECT
  'counts' AS check_name,
  (SELECT count(*) FROM auth.users)             AS auth_users,
  (SELECT count(*) FROM public.profiles)        AS profiles,
  (SELECT count(*) FROM auth.users u
     WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
  ) AS orphaned_auth_users;
-- If orphaned_auth_users > 0 → the trigger is NOT running. This is the bug.

-- ───────────────────────────────────────────────────────────────────
-- 7. Show last 5 auth users and whether they have profiles
-- ───────────────────────────────────────────────────────────────────
SELECT
  u.id,
  u.email,
  u.created_at,
  u.email_confirmed_at,
  p.id IS NOT NULL AS has_profile,
  p.full_name AS profile_name
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC
LIMIT 5;
-- If recent users have has_profile = false → trigger is the problem.
-- If email_confirmed_at IS NULL on a user that should have signed in →
-- "Confirm email" is turned on.
