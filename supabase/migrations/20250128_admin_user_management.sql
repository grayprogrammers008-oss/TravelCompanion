-- Admin User Management System
-- This migration adds admin roles, permissions, and user management capabilities

-- =====================================================
-- PART 1: ENUM TYPES
-- =====================================================

-- User roles
CREATE TYPE user_role AS ENUM ('user', 'admin', 'super_admin');

-- User status
CREATE TYPE user_status AS ENUM ('active', 'suspended', 'deleted');

-- Admin action types
CREATE TYPE admin_action_type AS ENUM (
  'user_created',
  'user_updated',
  'user_suspended',
  'user_activated',
  'user_deleted',
  'role_changed',
  'password_reset',
  'profile_updated'
);

-- =====================================================
-- PART 2: EXTEND PROFILES TABLE
-- =====================================================

-- Add admin-related fields to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS role user_role DEFAULT 'user' NOT NULL,
ADD COLUMN IF NOT EXISTS status user_status DEFAULT 'active' NOT NULL,
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS account_locked_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS account_locked_reason TEXT,
ADD COLUMN IF NOT EXISTS trips_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS messages_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0;

-- Create index on role and status for faster admin queries
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_last_login ON profiles(last_login_at);

-- =====================================================
-- PART 3: ADMIN ACTIVITY LOG TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS admin_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type admin_action_type NOT NULL,
  target_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for admin activity log
CREATE INDEX IF NOT EXISTS idx_admin_activity_admin_id ON admin_activity_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_target_user ON admin_activity_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_created_at ON admin_activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_activity_action_type ON admin_activity_log(action_type);

-- =====================================================
-- PART 4: USER STATISTICS VIEW
-- =====================================================

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
  p.login_count,
  COUNT(DISTINCT tm.trip_id) as trips_count,
  COUNT(DISTINCT m.id) as messages_count,
  COUNT(DISTINCT e.id) as expenses_count,
  COALESCE(SUM(e.amount), 0) as total_expenses
FROM profiles p
LEFT JOIN trip_members tm ON p.id = tm.user_id
LEFT JOIN messages m ON p.id = m.sender_id
LEFT JOIN expenses e ON p.id = e.paid_by
GROUP BY p.id, p.email, p.full_name, p.avatar_url, p.role, p.status,
         p.created_at, p.updated_at, p.last_login_at, p.last_active_at, p.login_count;

-- =====================================================
-- PART 5: ADMIN FUNCTIONS
-- =====================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = user_id
    AND role IN ('admin', 'super_admin')
    AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log admin activity
CREATE OR REPLACE FUNCTION log_admin_activity(
  p_admin_id UUID,
  p_action_type admin_action_type,
  p_target_user_id UUID,
  p_description TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO admin_activity_log (
    admin_id,
    action_type,
    target_user_id,
    description,
    metadata
  ) VALUES (
    p_admin_id,
    p_action_type,
    p_target_user_id,
    p_description,
    p_metadata
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all users with statistics (admin only)
CREATE OR REPLACE FUNCTION get_all_users_admin(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_search TEXT DEFAULT NULL,
  p_role user_role DEFAULT NULL,
  p_status user_status DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  role user_role,
  status user_status,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  last_login_at TIMESTAMP WITH TIME ZONE,
  last_active_at TIMESTAMP WITH TIME ZONE,
  login_count INTEGER,
  trips_count BIGINT,
  messages_count BIGINT,
  expenses_count BIGINT,
  total_expenses NUMERIC
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;

  RETURN QUERY
  SELECT
    us.id,
    us.email,
    us.full_name,
    us.avatar_url,
    us.role,
    us.status,
    us.created_at,
    us.updated_at,
    us.last_login_at,
    us.last_active_at,
    us.login_count,
    us.trips_count,
    us.messages_count,
    us.expenses_count,
    us.total_expenses
  FROM user_statistics us
  WHERE
    (p_search IS NULL OR
     us.email ILIKE '%' || p_search || '%' OR
     us.full_name ILIKE '%' || p_search || '%')
    AND (p_role IS NULL OR us.role = p_role)
    AND (p_status IS NULL OR us.status = p_status)
  ORDER BY us.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to suspend user (admin only)
CREATE OR REPLACE FUNCTION suspend_user(
  p_user_id UUID,
  p_reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := auth.uid();

  -- Check if caller is admin
  IF NOT is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;

  -- Cannot suspend yourself
  IF p_user_id = v_admin_id THEN
    RAISE EXCEPTION 'Cannot suspend your own account';
  END IF;

  -- Update user status
  UPDATE profiles
  SET
    status = 'suspended',
    account_locked_at = NOW(),
    account_locked_reason = p_reason,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Log the action
  PERFORM log_admin_activity(
    v_admin_id,
    'user_suspended',
    p_user_id,
    'User suspended: ' || p_reason,
    jsonb_build_object('reason', p_reason)
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to activate user (admin only)
CREATE OR REPLACE FUNCTION activate_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := auth.uid();

  -- Check if caller is admin
  IF NOT is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;

  -- Update user status
  UPDATE profiles
  SET
    status = 'active',
    account_locked_at = NULL,
    account_locked_reason = NULL,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Log the action
  PERFORM log_admin_activity(
    v_admin_id,
    'user_activated',
    p_user_id,
    'User activated',
    '{}'::jsonb
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user role (super_admin only)
CREATE OR REPLACE FUNCTION update_user_role(
  p_user_id UUID,
  p_new_role user_role
)
RETURNS BOOLEAN AS $$
DECLARE
  v_admin_id UUID;
  v_admin_role user_role;
BEGIN
  v_admin_id := auth.uid();

  -- Get admin's role
  SELECT role INTO v_admin_role
  FROM profiles
  WHERE id = v_admin_id;

  -- Only super_admin can change roles
  IF v_admin_role != 'super_admin' THEN
    RAISE EXCEPTION 'Access denied: Super admin privileges required';
  END IF;

  -- Cannot change your own role
  IF p_user_id = v_admin_id THEN
    RAISE EXCEPTION 'Cannot change your own role';
  END IF;

  -- Update role
  UPDATE profiles
  SET
    role = p_new_role,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Log the action
  PERFORM log_admin_activity(
    v_admin_id,
    'role_changed',
    p_user_id,
    'Role changed to: ' || p_new_role::text,
    jsonb_build_object('new_role', p_new_role)
  );

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get admin dashboard statistics
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  -- Check if caller is admin
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: Admin privileges required';
  END IF;

  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM profiles WHERE status != 'deleted'),
    'active_users', (SELECT COUNT(*) FROM profiles WHERE status = 'active'),
    'suspended_users', (SELECT COUNT(*) FROM profiles WHERE status = 'suspended'),
    'admins_count', (SELECT COUNT(*) FROM profiles WHERE role IN ('admin', 'super_admin')),
    'new_users_today', (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE),
    'new_users_week', (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
    'new_users_month', (SELECT COUNT(*) FROM profiles WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'),
    'total_trips', (SELECT COUNT(*) FROM trips),
    'total_messages', (SELECT COUNT(*) FROM messages),
    'active_users_today', (SELECT COUNT(*) FROM profiles WHERE last_active_at >= CURRENT_DATE)
  ) INTO v_stats;

  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PART 6: ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on admin_activity_log
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Admins can view all activity logs
CREATE POLICY "Admins can view activity logs"
ON admin_activity_log
FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

-- Only system can insert (via functions)
CREATE POLICY "System can insert activity logs"
ON admin_activity_log
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Update RLS on profiles to allow admin access
CREATE POLICY "Admins can view all profiles"
ON profiles
FOR SELECT
TO authenticated
USING (is_admin(auth.uid()) OR id = auth.uid());

-- =====================================================
-- PART 7: TRIGGERS
-- =====================================================

-- Trigger to update last_login_at
CREATE OR REPLACE FUNCTION update_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET
    last_login_at = NOW(),
    login_count = COALESCE(login_count, 0) + 1
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: This trigger would be attached to auth.users table by Supabase
-- You'll need to add it via Supabase dashboard or auth hooks

-- =====================================================
-- PART 8: INITIAL SETUP
-- =====================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION is_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION log_admin_activity(UUID, admin_action_type, UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_admin(INTEGER, INTEGER, TEXT, user_role, user_status) TO authenticated;
GRANT EXECUTE ON FUNCTION suspend_user(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION activate_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_role(UUID, user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_dashboard_stats() TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE admin_activity_log IS 'Logs all admin actions for audit trail';
COMMENT ON FUNCTION is_admin(UUID) IS 'Check if a user has admin privileges';
COMMENT ON FUNCTION get_all_users_admin IS 'Get all users with statistics (admin only)';
COMMENT ON FUNCTION suspend_user IS 'Suspend a user account (admin only)';
COMMENT ON FUNCTION activate_user IS 'Activate a suspended user account (admin only)';
COMMENT ON FUNCTION update_user_role IS 'Change user role (super_admin only)';
COMMENT ON FUNCTION get_admin_dashboard_stats IS 'Get dashboard statistics for admins';

