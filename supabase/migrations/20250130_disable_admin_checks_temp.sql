-- TEMPORARY: Disable admin checks for development/testing
-- ⚠️ WARNING: This makes ALL users able to access admin functions
-- ⚠️ REVERT THIS BEFORE PRODUCTION!

-- Function to get all users with statistics (TEMP: no admin check)
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
  -- TEMP: Admin check disabled for development
  -- IF NOT is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

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

-- Function to suspend user (TEMP: no admin check)
CREATE OR REPLACE FUNCTION suspend_user(
  p_user_id UUID,
  p_reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := auth.uid();

  -- TEMP: Admin check disabled for development
  -- IF NOT is_admin(v_admin_id) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

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

-- Function to activate user (TEMP: no admin check)
CREATE OR REPLACE FUNCTION activate_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_admin_id UUID;
BEGIN
  v_admin_id := auth.uid();

  -- TEMP: Admin check disabled for development
  -- IF NOT is_admin(v_admin_id) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

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

-- Function to update user role (TEMP: no super admin check)
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

  -- TEMP: Super admin check disabled for development
  -- IF v_admin_role != 'super_admin' THEN
  --   RAISE EXCEPTION 'Access denied: Super admin privileges required';
  -- END IF;

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

-- Function to get admin dashboard statistics (TEMP: no admin check)
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  -- TEMP: Admin check disabled for development
  -- IF NOT is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

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

-- Add a comment to remind about reverting
COMMENT ON FUNCTION get_all_users_admin IS '⚠️ TEMP: Admin check disabled for development - REVERT BEFORE PRODUCTION!';
COMMENT ON FUNCTION suspend_user IS '⚠️ TEMP: Admin check disabled for development - REVERT BEFORE PRODUCTION!';
COMMENT ON FUNCTION activate_user IS '⚠️ TEMP: Admin check disabled for development - REVERT BEFORE PRODUCTION!';
COMMENT ON FUNCTION update_user_role IS '⚠️ TEMP: Super admin check disabled for development - REVERT BEFORE PRODUCTION!';
COMMENT ON FUNCTION get_admin_dashboard_stats IS '⚠️ TEMP: Admin check disabled for development - REVERT BEFORE PRODUCTION!';
