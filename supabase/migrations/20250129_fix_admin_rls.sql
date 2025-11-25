-- Fix RLS policies to not break existing authentication
-- This patch ensures that regular users can still access their own profiles

-- Drop the restrictive admin policy
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- Create a more permissive policy that allows:
-- 1. Users to see their own profile
-- 2. Admins to see all profiles
CREATE POLICY "Users can view own profile and admins can view all"
ON profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
    AND status = 'active'
  )
);

-- Ensure users can update their own profiles
CREATE POLICY "Users can update own profile"
ON profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Recreate user_statistics view with better handling
-- This fixes potential issues with the view
DROP VIEW IF EXISTS user_statistics;
CREATE OR REPLACE VIEW user_statistics AS
SELECT
  p.id,
  p.email,
  p.full_name,
  p.avatar_url,
  p.role,
  p.status,
  p.created_at,
  p.updated_at,
  p.last_login_at,
  p.last_active_at,
  p.account_locked_at,
  p.account_locked_reason,
  p.login_count,
  p.trips_count,
  p.messages_count,
  COALESCE(COUNT(DISTINCT e.id), 0)::INTEGER as expenses_count,
  COALESCE(SUM(e.amount), 0) as total_expenses
FROM profiles p
LEFT JOIN expenses e ON p.id = e.paid_by
GROUP BY p.id, p.email, p.full_name, p.avatar_url, p.role, p.status,
         p.created_at, p.updated_at, p.last_login_at, p.last_active_at,
         p.account_locked_at, p.account_locked_reason, p.login_count,
         p.trips_count, p.messages_count;
