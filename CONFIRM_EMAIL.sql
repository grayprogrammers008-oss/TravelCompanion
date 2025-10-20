-- =====================================================
-- MANUALLY CONFIRM USER EMAIL (Development/Testing)
-- =====================================================
-- Run this if you're getting "Email not confirmed" error
-- This bypasses email verification for testing
-- =====================================================

-- Option 1: Confirm specific email
UPDATE auth.users
SET email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email = 'vinothvsbe@gmail.com';

-- Option 2: Confirm ALL unconfirmed users (if you have multiple test accounts)
-- UPDATE auth.users
-- SET email_confirmed_at = NOW(),
--     confirmed_at = NOW()
-- WHERE email_confirmed_at IS NULL;

-- Verify the update
SELECT
    id,
    email,
    email_confirmed_at,
    confirmed_at,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
