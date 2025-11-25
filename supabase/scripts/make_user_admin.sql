-- Script to make a user an admin for testing
-- Replace 'your-email@example.com' with your actual email

-- Step 1: View your user info
SELECT
  id,
  email,
  created_at
FROM auth.users
WHERE email = 'your-email@example.com';  -- CHANGE THIS

-- Step 2: After you see your user ID from Step 1,
-- uncomment and run the UPDATE below with your actual user ID

-- UPDATE profiles
-- SET
--   role = 'admin',  -- or 'super_admin' for full access
--   status = 'active'
-- WHERE id = 'YOUR_USER_ID_FROM_STEP_1';  -- CHANGE THIS

-- Step 3: Verify the change
-- SELECT
--   id,
--   email,
--   role,
--   status
-- FROM profiles
-- WHERE id = 'YOUR_USER_ID_FROM_STEP_1';  -- CHANGE THIS
