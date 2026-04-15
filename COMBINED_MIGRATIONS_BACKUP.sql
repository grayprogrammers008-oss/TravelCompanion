-- ============================================
-- REQUIRED POSTGRESQL EXTENSIONS
-- ============================================
-- These extensions must be enabled before running migrations
-- They provide additional data types and functions used throughout the schema

-- Enable CITEXT extension for case-insensitive text (used for email fields)
CREATE EXTENSION IF NOT EXISTS citext;

-- Enable UUID-OSSP extension for UUID generation functions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS extension for geospatial queries (used in hospital/emergency features)
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- Migration: 20250125_admin_trip_management.sql
-- ============================================

-- Admin Trip Management
-- Allows admins to view, create, edit, and delete all trips
-- Created: January 25, 2025

-- Function to get all trips with member counts (admin only)
CREATE OR REPLACE FUNCTION public.get_all_trips_admin(
  p_search TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL, -- 'active', 'completed', 'all'
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  destination TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  cover_image_url TEXT,
  created_by UUID,
  creator_name TEXT,
  creator_email TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  is_completed BOOLEAN,
  completed_at TIMESTAMPTZ,
  rating DOUBLE PRECISION,
  budget DOUBLE PRECISION,
  currency TEXT,
  member_count BIGINT,
  total_expenses DOUBLE PRECISION
) AS $$
BEGIN
  -- Note: Admin checks temporarily disabled for development
  -- TODO: Re-enable before production
  -- Check if user is admin
  -- IF NOT EXISTS (
  --   SELECT 1 FROM public.profiles
  --   WHERE id = auth.uid()
  --   AND role IN ('admin', 'super_admin')
  -- ) THEN
  --   RAISE EXCEPTION 'Only admins can view all trips';
  -- END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.name,
    t.description,
    t.destination,
    t.start_date,
    t.end_date,
    t.cover_image_url,
    t.created_by,
    p.full_name as creator_name,
    p.email as creator_email,
    t.created_at,
    t.updated_at,
    t.is_completed,
    t.completed_at,
    t.rating,
    t.budget,
    t.currency,
    (SELECT COUNT(*) FROM public.trip_members WHERE trip_id = t.id) as member_count,
    COALESCE((SELECT SUM(amount) FROM public.expenses WHERE trip_id = t.id), 0.0) as total_expenses
  FROM public.trips t
  JOIN public.profiles p ON t.created_by = p.id
  WHERE (p_search IS NULL OR
         t.name ILIKE '%' || p_search || '%' OR
         t.destination ILIKE '%' || p_search || '%' OR
         t.description ILIKE '%' || p_search || '%')
    AND (p_status IS NULL OR
         (p_status = 'active' AND t.is_completed = false) OR
         (p_status = 'completed' AND t.is_completed = true))
  ORDER BY t.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_all_trips_admin TO authenticated;

-- Function to get trip statistics (admin dashboard)
CREATE OR REPLACE FUNCTION public.get_admin_trip_stats()
RETURNS TABLE (
  total_trips BIGINT,
  active_trips BIGINT,
  completed_trips BIGINT,
  total_members BIGINT,
  total_expenses DOUBLE PRECISION,
  trips_this_month BIGINT,
  trips_this_week BIGINT
) AS $$
BEGIN
  -- Note: Admin checks temporarily disabled for development
  -- TODO: Re-enable before production
  -- Check if user is admin
  -- IF NOT EXISTS (
  --   SELECT 1 FROM public.profiles
  --   WHERE id = auth.uid()
  --   AND role IN ('admin', 'super_admin')
  -- ) THEN
  --   RAISE EXCEPTION 'Only admins can view trip statistics';
  -- END IF;

  RETURN QUERY
  SELECT
    COUNT(*) as total_trips,
    COUNT(*) FILTER (WHERE is_completed = false) as active_trips,
    COUNT(*) FILTER (WHERE is_completed = true) as completed_trips,
    (SELECT COUNT(*) FROM public.trip_members) as total_members,
    (SELECT COALESCE(SUM(amount), 0.0) FROM public.expenses) as total_expenses,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as trips_this_month,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as trips_this_week
  FROM public.trips;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_admin_trip_stats TO authenticated;

-- Function to delete trip (admin only)
CREATE OR REPLACE FUNCTION public.admin_delete_trip(
  p_trip_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Note: Admin checks temporarily disabled for development
  -- TODO: Re-enable before production
  -- Check if user is admin
  -- SELECT EXISTS (
  --   SELECT 1 FROM public.profiles
  --   WHERE id = auth.uid()
  --   AND role IN ('admin', 'super_admin')
  -- ) INTO v_is_admin;

  -- IF NOT v_is_admin THEN
  --   RAISE EXCEPTION 'Only admins can delete trips';
  -- END IF;

  -- Delete related data first (cascade should handle this, but being explicit)
  DELETE FROM public.trip_members WHERE trip_id = p_trip_id;
  DELETE FROM public.expenses WHERE trip_id = p_trip_id;
  DELETE FROM public.checklists WHERE trip_id = p_trip_id;
  DELETE FROM public.itinerary_items WHERE trip_id = p_trip_id;

  -- Delete the trip
  DELETE FROM public.trips WHERE id = p_trip_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.admin_delete_trip TO authenticated;

-- Function to update trip (admin only)
CREATE OR REPLACE FUNCTION public.admin_update_trip(
  p_trip_id UUID,
  p_name TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_destination TEXT DEFAULT NULL,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL,
  p_budget DOUBLE PRECISION DEFAULT NULL,
  p_currency TEXT DEFAULT NULL,
  p_is_completed BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  -- Note: Admin checks temporarily disabled for development
  -- TODO: Re-enable before production
  -- Check if user is admin
  -- SELECT EXISTS (
  --   SELECT 1 FROM public.profiles
  --   WHERE id = auth.uid()
  --   AND role IN ('admin', 'super_admin')
  -- ) INTO v_is_admin;

  -- IF NOT v_is_admin THEN
  --   RAISE EXCEPTION 'Only admins can update trips';
  -- END IF;

  UPDATE public.trips
  SET
    name = COALESCE(p_name, name),
    description = COALESCE(p_description, description),
    destination = COALESCE(p_destination, destination),
    start_date = COALESCE(p_start_date, start_date),
    end_date = COALESCE(p_end_date, end_date),
    budget = COALESCE(p_budget, budget),
    currency = COALESCE(p_currency, currency),
    is_completed = COALESCE(p_is_completed, is_completed),
    completed_at = CASE
      WHEN p_is_completed = true AND is_completed = false THEN NOW()
      WHEN p_is_completed = false THEN NULL
      ELSE completed_at
    END,
    updated_at = NOW()
  WHERE id = p_trip_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.admin_update_trip TO authenticated;

-- Add comments
COMMENT ON FUNCTION public.get_all_trips_admin IS 'Get all trips with member counts and expenses (admin only)';
COMMENT ON FUNCTION public.get_admin_trip_stats IS 'Get trip statistics for admin dashboard';
COMMENT ON FUNCTION public.admin_delete_trip IS 'Delete a trip and all related data (admin only)';
COMMENT ON FUNCTION public.admin_update_trip IS 'Update trip details (admin only)';


-- ============================================
-- Migration: 20250125_fix_trip_admin_function.sql
-- ============================================

-- Fix get_all_trips_admin function to handle CITEXT email type
-- This fixes the "structure of query does not match function result type" error

DROP FUNCTION IF EXISTS public.get_all_trips_admin(TEXT, TEXT, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.get_all_trips_admin(
  p_search TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  destination TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  cover_image_url TEXT,
  created_by UUID,
  creator_name TEXT,
  creator_email CITEXT,  -- Changed from TEXT to CITEXT to match profiles table
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  is_completed BOOLEAN,
  completed_at TIMESTAMPTZ,
  rating DOUBLE PRECISION,
  budget DOUBLE PRECISION,
  currency TEXT,
  member_count BIGINT,
  total_expenses DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.name,
    t.description,
    t.destination,
    t.start_date,
    t.end_date,
    t.cover_image_url,
    t.created_by,
    p.full_name as creator_name,
    p.email as creator_email,
    t.created_at,
    t.updated_at,
    t.is_completed,
    t.completed_at,
    t.rating,
    t.budget,
    t.currency,
    (SELECT COUNT(*) FROM public.trip_members WHERE trip_id = t.id) as member_count,
    COALESCE((SELECT SUM(amount) FROM public.expenses WHERE trip_id = t.id), 0.0) as total_expenses
  FROM public.trips t
  JOIN public.profiles p ON t.created_by = p.id
  WHERE (p_search IS NULL OR
         t.name ILIKE '%' || p_search || '%' OR
         t.destination ILIKE '%' || p_search || '%' OR
         t.description ILIKE '%' || p_search || '%')
    AND (p_status IS NULL OR
         (p_status = 'active' AND t.is_completed = false) OR
         (p_status = 'completed' AND t.is_completed = true))
  ORDER BY t.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_all_trips_admin TO authenticated;

COMMENT ON FUNCTION public.get_all_trips_admin IS 'Get all trips with member counts and expenses (admin only) - Fixed CITEXT type';


-- ============================================
-- Migration: 20250127_trip_notifications.sql
-- ============================================

-- Migration: Trip Push Notifications
-- Description: Add FCM token storage and database triggers for trip notifications
-- Date: 2025-01-27

-- ============================================================================
-- 1. Create FCM Tokens Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_id TEXT,
    device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure one token per device
    UNIQUE(user_id, device_id)
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active) WHERE is_active = true;

-- Enable RLS
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies for FCM tokens
DROP POLICY IF EXISTS "Users can view their own FCM tokens" ON user_fcm_tokens;
CREATE POLICY "Users can view their own FCM tokens"
    ON user_fcm_tokens
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own FCM tokens" ON user_fcm_tokens;
CREATE POLICY "Users can insert their own FCM tokens"
    ON user_fcm_tokens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own FCM tokens" ON user_fcm_tokens;
CREATE POLICY "Users can update their own FCM tokens"
    ON user_fcm_tokens
    FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own FCM tokens" ON user_fcm_tokens;
CREATE POLICY "Users can delete their own FCM tokens"
    ON user_fcm_tokens
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 2. Function to update FCM token timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_fcm_token_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_used_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update timestamp
CREATE TRIGGER trigger_update_fcm_token_timestamp
    BEFORE UPDATE ON user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_fcm_token_timestamp();

-- ============================================================================
-- 3. Function to send trip update notification
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_trip_updated()
RETURNS TRIGGER AS $$
DECLARE
    v_trip_name TEXT;
    v_updater_name TEXT;
    v_updated_field TEXT;
BEGIN
    -- Get trip name
    v_trip_name := NEW.name;

    -- Get updater's name
    SELECT full_name INTO v_updater_name
    FROM profiles
    WHERE id = auth.uid()
    LIMIT 1;

    -- Determine what field was updated
    IF OLD.name IS DISTINCT FROM NEW.name THEN
        v_updated_field := 'name';
    ELSIF OLD.destination IS DISTINCT FROM NEW.destination THEN
        v_updated_field := 'destination';
    ELSIF OLD.start_date IS DISTINCT FROM NEW.start_date OR OLD.end_date IS DISTINCT FROM NEW.end_date THEN
        v_updated_field := 'dates';
    ELSIF OLD.description IS DISTINCT FROM NEW.description THEN
        v_updated_field := 'description';
    ELSIF OLD.cover_image_url IS DISTINCT FROM NEW.cover_image_url THEN
        v_updated_field := 'cover image';
    ELSE
        v_updated_field := 'details';
    END IF;

    -- Call edge function to send notification (async via pg_net or supabase_functions)
    -- Note: This requires pg_net extension or manual invocation
    -- For now, we'll log it and you can call it from the app layer
    RAISE NOTICE 'Trip updated: %, Field: %, By: %', v_trip_name, v_updated_field, v_updater_name;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. Function to send member added notification
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_member_added()
RETURNS TRIGGER AS $$
DECLARE
    v_trip_name TEXT;
    v_member_name TEXT;
BEGIN
    -- Get trip name
    SELECT name INTO v_trip_name
    FROM trips
    WHERE id = NEW.trip_id
    LIMIT 1;

    -- Get member's name
    SELECT full_name INTO v_member_name
    FROM profiles
    WHERE id = NEW.user_id
    LIMIT 1;

    -- Log notification (edge function will be called from app layer)
    RAISE NOTICE 'Member added to trip: %, Member: %', v_trip_name, v_member_name;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. Create triggers for notifications
-- ============================================================================

-- Trigger for trip updates
DROP TRIGGER IF EXISTS trigger_notify_trip_updated ON trips;
CREATE TRIGGER trigger_notify_trip_updated
    AFTER UPDATE ON trips
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION notify_trip_updated();

-- Trigger for member additions
DROP TRIGGER IF EXISTS trigger_notify_member_added ON trip_members;
CREATE TRIGGER trigger_notify_member_added
    AFTER INSERT ON trip_members
    FOR EACH ROW
    EXECUTE FUNCTION notify_member_added();

-- ============================================================================
-- 6. Helper function to register FCM token
-- ============================================================================

CREATE OR REPLACE FUNCTION register_fcm_token(
    p_fcm_token TEXT,
    p_device_id TEXT,
    p_device_type TEXT
)
RETURNS UUID AS $$
DECLARE
    v_token_id UUID;
BEGIN
    -- Deactivate old tokens for this device
    UPDATE user_fcm_tokens
    SET is_active = false
    WHERE user_id = auth.uid()
    AND device_id = p_device_id
    AND fcm_token != p_fcm_token;

    -- Insert or update token
    INSERT INTO user_fcm_tokens (user_id, fcm_token, device_id, device_type)
    VALUES (auth.uid(), p_fcm_token, p_device_id, p_device_type)
    ON CONFLICT (user_id, device_id)
    DO UPDATE SET
        fcm_token = EXCLUDED.fcm_token,
        device_type = EXCLUDED.device_type,
        is_active = true,
        updated_at = NOW(),
        last_used_at = NOW()
    RETURNING id INTO v_token_id;

    RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Helper function to unregister FCM token
-- ============================================================================

CREATE OR REPLACE FUNCTION unregister_fcm_token(
    p_device_id TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE user_fcm_tokens
    SET is_active = false
    WHERE user_id = auth.uid()
    AND device_id = p_device_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. Grant permissions
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION register_fcm_token(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION unregister_fcm_token(TEXT) TO authenticated;

-- ============================================================================
-- DONE!
-- ============================================================================

COMMENT ON TABLE user_fcm_tokens IS 'Stores Firebase Cloud Messaging tokens for push notifications';
COMMENT ON FUNCTION notify_trip_updated() IS 'Trigger function to send notification when trip is updated';
COMMENT ON FUNCTION notify_member_added() IS 'Trigger function to send notification when member is added';
COMMENT ON FUNCTION register_fcm_token(TEXT, TEXT, TEXT) IS 'Register or update FCM token for current user';
COMMENT ON FUNCTION unregister_fcm_token(TEXT) IS 'Deactivate FCM token for current user device';


-- ============================================
-- Migration: 20250128_admin_user_management.sql
-- ============================================

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
DROP POLICY IF EXISTS "Admins can view activity logs" ON admin_activity_log;
CREATE POLICY "Admins can view activity logs"
ON admin_activity_log
FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

-- Only system can insert (via functions)
DROP POLICY IF EXISTS "System can insert activity logs" ON admin_activity_log;
CREATE POLICY "System can insert activity logs"
ON admin_activity_log
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Update RLS on profiles to allow admin access
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
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



-- ============================================
-- Migration: 20250129_fix_admin_rls.sql
-- ============================================

-- Fix RLS policies to not break existing authentication
-- This patch ensures that regular users can still access their own profiles

-- Drop the restrictive admin policy
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- Create a more permissive policy that allows:
-- 1. Users to see their own profile
-- 2. Admins to see all profiles
DROP POLICY IF EXISTS "Users can view own profile and admins can view all" ON profiles;
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

-- Drop existing policy if it exists (for idempotency)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

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


-- ============================================
-- Migration: 20250130_disable_admin_checks_temp.sql
-- ============================================

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


-- ============================================
-- Migration: 20250131_fix_function_return_types.sql
-- ============================================

-- Fix function return types to match actual column types
-- The email column is CITEXT but function was declaring TEXT

-- Drop the existing function first (required when changing return type)
DROP FUNCTION IF EXISTS get_all_users_admin(INTEGER, INTEGER, TEXT, user_role, user_status);

-- Recreate the function with correct return types
CREATE OR REPLACE FUNCTION get_all_users_admin(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_search TEXT DEFAULT NULL,
  p_role user_role DEFAULT NULL,
  p_status user_status DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  email CITEXT,  -- Changed from TEXT to CITEXT to match profiles table
  full_name TEXT,
  avatar_url TEXT,
  role user_role,
  status user_status,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  last_login_at TIMESTAMP WITH TIME ZONE,
  last_active_at TIMESTAMP WITH TIME ZONE,
  login_count INTEGER,
  trips_count INTEGER,  -- Changed from BIGINT to INTEGER to match profiles table
  messages_count INTEGER,  -- Changed from BIGINT to INTEGER to match profiles table
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

COMMENT ON FUNCTION get_all_users_admin IS '⚠️ TEMP: Admin check disabled for development - REVERT BEFORE PRODUCTION!';


-- ============================================
-- Migration: 20250131_fix_user_statistics_view.sql
-- ============================================

-- Fix user_statistics view to work without expenses table
-- This creates a simpler view that only uses data from the profiles table

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
  0::BIGINT as expenses_count,  -- Default to 0 for now
  0::NUMERIC as total_expenses  -- Default to 0 for now
FROM profiles p;

-- Grant permissions
GRANT SELECT ON user_statistics TO authenticated;

COMMENT ON VIEW user_statistics IS 'Simplified user statistics view for admin panel - expenses calculation removed for performance';


-- ============================================
-- Migration: 20250201_storage_buckets_setup.sql
-- ============================================

-- =============================================
-- Storage Buckets Setup for Travel Crew
-- =============================================
-- Created: 2025-02-01
-- Purpose: Create storage buckets for user avatars, trip covers,
--          expense receipts, and settlement proofs with proper RLS policies

-- =============================================
-- 1. CREATE STORAGE BUCKETS
-- =============================================

-- Profile Avatars Bucket (public read, authenticated upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-avatars',
  'profile-avatars',
  true, -- Public read access
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Trip Covers Bucket (public read, trip members upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'trip-covers',
  'trip-covers',
  true, -- Public read access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Expense Receipts Bucket (private, only trip members can access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'expense-receipts',
  'expense-receipts',
  false, -- Private access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Settlement Proofs Bucket (private, only involved users can access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'settlement-proofs',
  'settlement-proofs',
  false, -- Private access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- =============================================
-- 2. RLS POLICIES FOR PROFILE AVATARS
-- =============================================

-- Allow authenticated users to upload their own avatars
DROP POLICY IF EXISTS "Users can upload their own profile avatars" ON storage.objects;
CREATE POLICY "Users can upload their own profile avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own avatars
DROP POLICY IF EXISTS "Users can update their own profile avatars" ON storage.objects;
CREATE POLICY "Users can update their own profile avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own avatars
DROP POLICY IF EXISTS "Users can delete their own profile avatars" ON storage.objects;
CREATE POLICY "Users can delete their own profile avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access to all profile avatars
DROP POLICY IF EXISTS "Public can view profile avatars" ON storage.objects;
CREATE POLICY "Public can view profile avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-avatars');

-- =============================================
-- 3. RLS POLICIES FOR TRIP COVERS
-- =============================================

-- Allow trip members to upload trip covers
DROP POLICY IF EXISTS "Trip members can upload trip covers" ON storage.objects;
CREATE POLICY "Trip members can upload trip covers"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow trip members to update trip covers
DROP POLICY IF EXISTS "Trip members can update trip covers" ON storage.objects;
CREATE POLICY "Trip members can update trip covers"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow trip members to delete trip covers
DROP POLICY IF EXISTS "Trip members can delete trip covers" ON storage.objects;
CREATE POLICY "Trip members can delete trip covers"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow public read access to all trip covers
DROP POLICY IF EXISTS "Public can view trip covers" ON storage.objects;
CREATE POLICY "Public can view trip covers"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'trip-covers');

-- =============================================
-- 4. RLS POLICIES FOR EXPENSE RECEIPTS
-- =============================================

-- Allow trip members to upload expense receipts
DROP POLICY IF EXISTS "Trip members can upload expense receipts" ON storage.objects;
CREATE POLICY "Trip members can upload expense receipts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    JOIN trip_members tm ON e.trip_id = tm.trip_id
    WHERE e.id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow trip members to view expense receipts
DROP POLICY IF EXISTS "Trip members can view expense receipts" ON storage.objects;
CREATE POLICY "Trip members can view expense receipts"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    JOIN trip_members tm ON e.trip_id = tm.trip_id
    WHERE e.id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow expense creator to update their receipts
DROP POLICY IF EXISTS "Expense creators can update receipts" ON storage.objects;
CREATE POLICY "Expense creators can update receipts"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    WHERE e.id::text = (storage.foldername(name))[1]
    AND e.paid_by = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    WHERE e.id::text = (storage.foldername(name))[1]
    AND e.paid_by = auth.uid()
  )
);

-- Allow expense creator to delete their receipts
DROP POLICY IF EXISTS "Expense creators can delete receipts" ON storage.objects;
CREATE POLICY "Expense creators can delete receipts"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    WHERE e.id::text = (storage.foldername(name))[1]
    AND e.paid_by = auth.uid()
  )
);

-- =============================================
-- 5. RLS POLICIES FOR SETTLEMENT PROOFS
-- =============================================

-- Allow payer to upload settlement proofs
DROP POLICY IF EXISTS "Payers can upload settlement proofs" ON storage.objects;
CREATE POLICY "Payers can upload settlement proofs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
);

-- Allow involved users to view settlement proofs
DROP POLICY IF EXISTS "Involved users can view settlement proofs" ON storage.objects;
CREATE POLICY "Involved users can view settlement proofs"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND (s.from_user = auth.uid() OR s.to_user = auth.uid())
  )
);

-- Allow payer to update settlement proofs
DROP POLICY IF EXISTS "Payers can update settlement proofs" ON storage.objects;
CREATE POLICY "Payers can update settlement proofs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
);

-- Allow payer to delete settlement proofs
DROP POLICY IF EXISTS "Payers can delete settlement proofs" ON storage.objects;
CREATE POLICY "Payers can delete settlement proofs"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
);

-- =============================================
-- MIGRATION COMPLETE
-- =============================================
-- All storage buckets and RLS policies have been created successfully.
--
-- Bucket Summary:
-- 1. profile-avatars: 5MB, public read, user-owned uploads
-- 2. trip-covers: 10MB, public read, trip member uploads
-- 3. expense-receipts: 10MB, private, trip member access
-- 4. settlement-proofs: 10MB, private, payer/receiver access
--
-- All policies enforce proper access control based on user roles and ownership.


-- ============================================
-- Migration: 20250202_add_trip_visibility.sql
-- ============================================

-- Migration: Add trip visibility (public/private) feature
-- Date: 2025-02-02
-- Description: Add is_public column to trips table to support public/private trip visibility

-- Add is_public column to trips table
-- Default to true (public) for backward compatibility with existing trips
ALTER TABLE public.trips
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true NOT NULL;

-- Add comment explaining the column
COMMENT ON COLUMN public.trips.is_public IS 'Trip visibility: true = public (discoverable by others), false = private (only visible to members)';

-- Create index for better query performance when filtering by visibility
CREATE INDEX IF NOT EXISTS idx_trips_is_public ON public.trips(is_public);

-- Update RLS policies to respect trip visibility
-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Users can view trips they are members of" ON public.trips;

-- Create new policy: Users can view trips they are members of OR public trips
DROP POLICY IF EXISTS "Users can view member trips or public trips" ON public.trips;
CREATE POLICY "Users can view member trips or public trips"
ON public.trips
FOR SELECT
TO authenticated
USING (
  -- User is a member of the trip
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = trips.id
    AND trip_members.user_id = auth.uid()
  )
  OR
  -- Trip is public (anyone can discover it)
  is_public = true
);

-- Policy for creating trips (no change needed, but recreate for consistency)
DROP POLICY IF EXISTS "Users can create trips" ON public.trips;
CREATE POLICY "Users can create trips"
ON public.trips
FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- Policy for updating trips (only trip creator or admin members can update)
DROP POLICY IF EXISTS "Trip creator and admins can update trips" ON public.trips;
CREATE POLICY "Trip creator and admins can update trips"
ON public.trips
FOR UPDATE
TO authenticated
USING (
  created_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = trips.id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  created_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = trips.id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Policy for deleting trips (only trip creator can delete)
DROP POLICY IF EXISTS "Trip creator can delete trips" ON public.trips;
CREATE POLICY "Trip creator can delete trips"
ON public.trips
FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trips TO authenticated;


-- ============================================
-- Migration: 20250202_google_places_integration.sql
-- ============================================

-- ============================================================================
-- Google Places API Integration Helper Functions
-- Description: Functions to import hospital data from Google Places API
-- Date: 2025-02-02
-- ============================================================================

-- ============================================================================
-- 1. Function to Upsert Hospital from Google Places Data
-- ============================================================================

CREATE OR REPLACE FUNCTION upsert_hospital_from_google_places(
    p_google_place_id TEXT,
    p_name TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_city TEXT,
    p_state TEXT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_rating DECIMAL DEFAULT NULL,
    p_total_reviews INTEGER DEFAULT 0,
    p_website TEXT DEFAULT NULL,
    p_specialties TEXT[] DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_hospital_id UUID;
    v_has_emergency BOOLEAN;
    v_is_24_7 BOOLEAN;
BEGIN
    -- Determine if hospital has emergency based on name/type
    v_has_emergency := (
        p_name ILIKE '%emergency%' OR
        p_name ILIKE '%trauma%' OR
        p_name ILIKE '%hospital%' OR
        p_name ILIKE '%medical college%' OR
        p_name ILIKE '%health%'
    );

    -- Assume large hospitals are 24/7
    v_is_24_7 := (
        p_name ILIKE '%hospital%' OR
        p_name ILIKE '%medical college%' OR
        p_name ILIKE '%super%' OR
        p_name ILIKE '%multi%'
    );

    -- Insert or update hospital
    INSERT INTO hospitals (
        google_place_id,
        name,
        phone,
        address,
        city,
        state,
        latitude,
        longitude,
        hospital_type,
        has_emergency,
        is_24_7,
        rating,
        total_reviews,
        website,
        specialties,
        data_source,
        verified
    )
    VALUES (
        p_google_place_id,
        p_name,
        p_phone,
        p_address,
        p_city,
        p_state,
        p_latitude,
        p_longitude,
        'private', -- Default to private, can be updated manually
        v_has_emergency,
        v_is_24_7,
        p_rating,
        p_total_reviews,
        p_website,
        COALESCE(p_specialties, ARRAY['General Medicine']),
        'google_places',
        false -- Not verified yet
    )
    ON CONFLICT (google_place_id) DO UPDATE SET
        name = EXCLUDED.name,
        phone = EXCLUDED.phone,
        address = EXCLUDED.address,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        rating = EXCLUDED.rating,
        total_reviews = EXCLUDED.total_reviews,
        website = EXCLUDED.website,
        specialties = EXCLUDED.specialties,
        updated_at = NOW()
    RETURNING id INTO v_hospital_id;

    RETURN v_hospital_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Batch Insert Function for Multiple Hospitals
-- ============================================================================

CREATE OR REPLACE FUNCTION batch_insert_hospitals(
    hospitals_json JSONB
)
RETURNS TABLE (
    inserted_count INTEGER,
    updated_count INTEGER,
    failed_count INTEGER
) AS $$
DECLARE
    v_hospital JSONB;
    v_inserted INTEGER := 0;
    v_updated INTEGER := 0;
    v_failed INTEGER := 0;
    v_existing_id UUID;
BEGIN
    FOR v_hospital IN SELECT * FROM jsonb_array_elements(hospitals_json)
    LOOP
        BEGIN
            -- Check if hospital already exists
            SELECT id INTO v_existing_id
            FROM hospitals
            WHERE google_place_id = v_hospital->>'google_place_id';

            IF v_existing_id IS NOT NULL THEN
                v_updated := v_updated + 1;
            ELSE
                v_inserted := v_inserted + 1;
            END IF;

            -- Upsert hospital
            PERFORM upsert_hospital_from_google_places(
                v_hospital->>'google_place_id',
                v_hospital->>'name',
                v_hospital->>'phone',
                v_hospital->>'address',
                v_hospital->>'city',
                v_hospital->>'state',
                (v_hospital->>'latitude')::DOUBLE PRECISION,
                (v_hospital->>'longitude')::DOUBLE PRECISION,
                CASE WHEN v_hospital->>'rating' IS NOT NULL
                     THEN (v_hospital->>'rating')::DECIMAL
                     ELSE NULL END,
                COALESCE((v_hospital->>'total_reviews')::INTEGER, 0),
                v_hospital->>'website',
                CASE WHEN v_hospital->'specialties' IS NOT NULL
                     THEN ARRAY(SELECT jsonb_array_elements_text(v_hospital->'specialties'))
                     ELSE NULL END
            );
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            RAISE NOTICE 'Failed to insert hospital: %', v_hospital->>'name';
        END;
    END LOOP;

    RETURN QUERY SELECT v_inserted, v_updated, v_failed;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. Function to Get Statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_hospital_statistics()
RETURNS TABLE (
    total_hospitals BIGINT,
    government_hospitals BIGINT,
    private_hospitals BIGINT,
    emergency_hospitals BIGINT,
    hospitals_24_7 BIGINT,
    verified_hospitals BIGINT,
    cities_covered BIGINT,
    states_covered BIGINT,
    avg_rating DECIMAL,
    google_places_count BIGINT,
    manual_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT AS total_hospitals,
        COUNT(*) FILTER (WHERE hospital_type = 'government')::BIGINT AS government_hospitals,
        COUNT(*) FILTER (WHERE hospital_type = 'private')::BIGINT AS private_hospitals,
        COUNT(*) FILTER (WHERE has_emergency = true)::BIGINT AS emergency_hospitals,
        COUNT(*) FILTER (WHERE is_24_7 = true)::BIGINT AS hospitals_24_7,
        COUNT(*) FILTER (WHERE verified = true)::BIGINT AS verified_hospitals,
        COUNT(DISTINCT city)::BIGINT AS cities_covered,
        COUNT(DISTINCT state)::BIGINT AS states_covered,
        ROUND(AVG(rating), 2) AS avg_rating,
        COUNT(*) FILTER (WHERE data_source = 'google_places')::BIGINT AS google_places_count,
        COUNT(*) FILTER (WHERE data_source = 'manual')::BIGINT AS manual_count
    FROM hospitals
    WHERE is_active = true;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 4. Grant Permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION upsert_hospital_from_google_places TO authenticated;
GRANT EXECUTE ON FUNCTION batch_insert_hospitals TO authenticated;
GRANT EXECUTE ON FUNCTION get_hospital_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION get_hospital_statistics TO anon;

-- ============================================================================
-- DONE!
-- ============================================================================


-- ============================================
-- Migration: 20250202_hospitals_emergency_service.sql
-- ============================================

-- ============================================================================
-- Migration: Emergency Hospital Service with Real Indian Hospital Data
-- Description: Creates hospitals table, PostGIS functions, and real data
-- Date: 2025-02-02
--
-- ⚠️ WARNING: This migration will DROP the existing hospitals table if present
-- and recreate it from scratch with 35 pre-seeded hospitals.
-- ============================================================================

-- ============================================================================
-- 1. Enable PostGIS Extension for Geospatial Queries
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- 2. Drop Existing Table and Create Fresh (for clean migration)
-- ============================================================================

-- Drop existing table if it exists (clean slate)
DROP TABLE IF EXISTS hospitals CASCADE;

-- Create Hospitals Table
CREATE TABLE hospitals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Basic Information
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    website TEXT,

    -- Address Information
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT,
    country TEXT DEFAULT 'India',

    -- Geospatial Data (PostGIS)
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326), -- PostGIS geography type

    -- Hospital Type & Services
    hospital_type TEXT CHECK (hospital_type IN ('government', 'private', 'trust', 'military')),
    has_emergency BOOLEAN DEFAULT true,
    has_ambulance BOOLEAN DEFAULT false,
    is_24_7 BOOLEAN DEFAULT true,

    -- Emergency Services
    emergency_phone TEXT,
    trauma_level INTEGER CHECK (trauma_level BETWEEN 1 AND 3), -- 1=Level-1 Trauma Center (highest)
    has_icu BOOLEAN DEFAULT false,
    has_nicu BOOLEAN DEFAULT false,
    has_burn_unit BOOLEAN DEFAULT false,
    has_cardiac_unit BOOLEAN DEFAULT false,

    -- Specialties (Array of specialties)
    specialties TEXT[],

    -- Ratings & Reviews
    rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
    total_reviews INTEGER DEFAULT 0,

    -- Capacity
    total_beds INTEGER,
    icu_beds INTEGER,
    emergency_beds INTEGER,

    -- Data Source & Verification
    data_source TEXT, -- 'google_places', 'manual', 'government_db', etc.
    google_place_id TEXT UNIQUE,
    verified BOOLEAN DEFAULT false,
    verification_date TIMESTAMP WITH TIME ZONE,

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_operational BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================================================
-- 3. Create Indexes for Performance
-- ============================================================================

-- Primary indexes for common queries
CREATE INDEX IF NOT EXISTS idx_hospitals_city ON hospitals(city);
CREATE INDEX IF NOT EXISTS idx_hospitals_state ON hospitals(state);
CREATE INDEX IF NOT EXISTS idx_hospitals_emergency ON hospitals(has_emergency) WHERE has_emergency = true;
CREATE INDEX IF NOT EXISTS idx_hospitals_24_7 ON hospitals(is_24_7) WHERE is_24_7 = true;
CREATE INDEX IF NOT EXISTS idx_hospitals_active ON hospitals(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_hospitals_google_place_id ON hospitals(google_place_id);

-- PostGIS spatial index for geospatial queries (CRITICAL for performance)
CREATE INDEX IF NOT EXISTS idx_hospitals_location ON hospitals USING GIST(location);

-- Composite index for common filter combinations
CREATE INDEX IF NOT EXISTS idx_hospitals_city_emergency ON hospitals(city, has_emergency)
WHERE is_active = true;

-- Text search index
CREATE INDEX IF NOT EXISTS idx_hospitals_name_search ON hospitals USING gin(to_tsvector('english', name));

-- ============================================================================
-- 4. Create Trigger to Auto-Update Location from Lat/Lng
-- ============================================================================

CREATE OR REPLACE FUNCTION update_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
    -- Automatically set PostGIS geography point from latitude/longitude
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_hospital_location ON hospitals;
CREATE TRIGGER trigger_update_hospital_location
    BEFORE INSERT OR UPDATE OF latitude, longitude ON hospitals
    FOR EACH ROW
    EXECUTE FUNCTION update_hospital_location();

-- ============================================================================
-- 5. Create Function to Calculate Emergency Priority Score
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS calculate_emergency_priority_score CASCADE;

CREATE FUNCTION calculate_emergency_priority_score(
    p_has_emergency BOOLEAN,
    p_is_24_7 BOOLEAN,
    p_trauma_level INTEGER,
    p_has_icu BOOLEAN,
    p_has_ambulance BOOLEAN,
    p_rating DECIMAL,
    p_distance_km DOUBLE PRECISION
)
RETURNS DECIMAL AS $$
DECLARE
    score DECIMAL := 0;
BEGIN
    -- Emergency room availability (30 points)
    IF p_has_emergency THEN
        score := score + 30;
    END IF;

    -- 24/7 operation (20 points)
    IF p_is_24_7 THEN
        score := score + 20;
    END IF;

    -- Trauma level (20 points max)
    IF p_trauma_level IS NOT NULL THEN
        score := score + (20 - ((p_trauma_level - 1) * 10));
    END IF;

    -- ICU availability (10 points)
    IF p_has_icu THEN
        score := score + 10;
    END IF;

    -- Ambulance service (5 points)
    IF p_has_ambulance THEN
        score := score + 5;
    END IF;

    -- Rating score (10 points max: rating/5 * 10)
    IF p_rating IS NOT NULL THEN
        score := score + (p_rating / 5.0 * 10);
    END IF;

    -- Distance penalty (closer is better, max 5 points)
    -- Hospitals within 5km get full points, decreases linearly
    IF p_distance_km <= 5 THEN
        score := score + 5;
    ELSIF p_distance_km <= 50 THEN
        score := score + (5 - ((p_distance_km - 5) / 45 * 5));
    END IF;

    RETURN ROUND(score, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 6. Create Main Function: Find Nearest Hospitals
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS find_nearest_hospitals CASCADE;

CREATE FUNCTION find_nearest_hospitals(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    max_distance_km DOUBLE PRECISION DEFAULT 50.0,
    result_limit INTEGER DEFAULT 10,
    only_emergency BOOLEAN DEFAULT true,
    only_24_7 BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone TEXT,
    emergency_phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    hospital_type TEXT,
    has_emergency BOOLEAN,
    has_ambulance BOOLEAN,
    is_24_7 BOOLEAN,
    trauma_level INTEGER,
    has_icu BOOLEAN,
    has_nicu BOOLEAN,
    has_burn_unit BOOLEAN,
    has_cardiac_unit BOOLEAN,
    specialties TEXT[],
    rating DECIMAL,
    total_reviews INTEGER,
    total_beds INTEGER,
    distance_km DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION,
    emergency_priority_score DECIMAL,
    google_place_id TEXT,
    website TEXT,
    is_operational BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.phone,
        h.emergency_phone,
        h.address,
        h.city,
        h.state,
        h.latitude,
        h.longitude,
        h.hospital_type,
        h.has_emergency,
        h.has_ambulance,
        h.is_24_7,
        h.trauma_level,
        h.has_icu,
        h.has_nicu,
        h.has_burn_unit,
        h.has_cardiac_unit,
        h.specialties,
        h.rating,
        h.total_reviews,
        h.total_beds,
        -- Calculate distance in kilometers using PostGIS
        ROUND(
            (ST_Distance(
                h.location,
                ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
            ) / 1000.0)::numeric,
            2
        )::DOUBLE PRECISION AS distance_km,
        -- Distance in meters
        ST_Distance(
            h.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        )::DOUBLE PRECISION AS distance_meters,
        -- Calculate emergency priority score
        calculate_emergency_priority_score(
            h.has_emergency,
            h.is_24_7,
            h.trauma_level,
            h.has_icu,
            h.has_ambulance,
            h.rating,
            ROUND(
                (ST_Distance(
                    h.location,
                    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
                ) / 1000.0)::numeric,
                2
            )::DOUBLE PRECISION
        ) AS emergency_priority_score,
        h.google_place_id,
        h.website,
        h.is_operational
    FROM hospitals h
    WHERE
        h.is_active = true
        AND (NOT only_emergency OR h.has_emergency = true)
        AND (NOT only_24_7 OR h.is_24_7 = true)
        -- Filter by distance using PostGIS
        AND ST_DWithin(
            h.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
            max_distance_km * 1000 -- Convert km to meters
        )
    ORDER BY
        emergency_priority_score DESC,
        distance_meters ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 7. Create Search Hospitals Function
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS search_hospitals CASCADE;

CREATE FUNCTION search_hospitals(
    search_term TEXT,
    search_city TEXT DEFAULT NULL,
    search_state TEXT DEFAULT NULL,
    result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    has_emergency BOOLEAN,
    is_24_7 BOOLEAN,
    rating DECIMAL,
    hospital_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.phone,
        h.address,
        h.city,
        h.state,
        h.latitude,
        h.longitude,
        h.has_emergency,
        h.is_24_7,
        h.rating,
        h.hospital_type
    FROM hospitals h
    WHERE
        h.is_active = true
        AND (
            h.name ILIKE '%' || search_term || '%'
            OR h.address ILIKE '%' || search_term || '%'
        )
        AND (search_city IS NULL OR h.city ILIKE search_city)
        AND (search_state IS NULL OR h.state ILIKE search_state)
    ORDER BY h.rating DESC NULLS LAST, h.name ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 8. Create Get Hospital By ID Function
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS get_hospital_with_distance CASCADE;

CREATE FUNCTION get_hospital_with_distance(
    hospital_id UUID,
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone TEXT,
    emergency_phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    hospital_type TEXT,
    has_emergency BOOLEAN,
    has_ambulance BOOLEAN,
    is_24_7 BOOLEAN,
    trauma_level INTEGER,
    has_icu BOOLEAN,
    has_nicu BOOLEAN,
    has_burn_unit BOOLEAN,
    has_cardiac_unit BOOLEAN,
    specialties TEXT[],
    rating DECIMAL,
    total_reviews INTEGER,
    total_beds INTEGER,
    distance_km DOUBLE PRECISION,
    google_place_id TEXT,
    website TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.phone,
        h.emergency_phone,
        h.address,
        h.city,
        h.state,
        h.latitude,
        h.longitude,
        h.hospital_type,
        h.has_emergency,
        h.has_ambulance,
        h.is_24_7,
        h.trauma_level,
        h.has_icu,
        h.has_nicu,
        h.has_burn_unit,
        h.has_cardiac_unit,
        h.specialties,
        h.rating,
        h.total_reviews,
        h.total_beds,
        CASE
            WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
                ROUND(
                    (ST_Distance(
                        h.location,
                        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
                    ) / 1000.0)::numeric,
                    2
                )::DOUBLE PRECISION
            ELSE NULL
        END AS distance_km,
        h.google_place_id,
        h.website
    FROM hospitals h
    WHERE h.id = hospital_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 9. Seed Real Indian Hospital Data (Major Cities)
-- ============================================================================

-- Mumbai Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Lilavati Hospital and Research Centre', '+91-22-26567891', '108', 'A-791, Bandra Reclamation, Bandra West', 'Mumbai', 'Maharashtra', 19.0596, 72.8295, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Neurology', 'Emergency', 'Trauma Care'], 4.5, 2800, 600, 'manual', true),
('Kokilaben Dhirubhai Ambani Hospital', '+91-22-30999999', '108', 'Rao Saheb Achutrao Patwardhan Marg, Four Bungalows, Andheri West', 'Mumbai', 'Maharashtra', 19.1290, 72.8264, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Cardiology', 'Oncology', 'Emergency'], 4.6, 3200, 750, 'manual', true),
('Hinduja Hospital', '+91-22-44510000', '108', 'Veer Savarkar Marg, Mahim', 'Mumbai', 'Maharashtra', 19.0368, 72.8389, 'private', true, true, true, 1, true, true, ARRAY['General Medicine', 'Surgery', 'Emergency'], 4.4, 2100, 450, 'manual', true),
('KEM Hospital', '+91-22-24107000', '108', 'Acharya Donde Marg, Parel', 'Mumbai', 'Maharashtra', 19.0037, 72.8420, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.2, 1500, 1800, 'manual', true),
('Breach Candy Hospital', '+91-22-23667000', '108', '60-A, Bhulabhai Desai Road, Breach Candy', 'Mumbai', 'Maharashtra', 18.9696, 72.8060, 'private', true, true, true, 2, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 1800, 350, 'manual', true);

-- Delhi Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('AIIMS Delhi', '+91-11-26588500', '108', 'Ansari Nagar, Aurobindo Marg', 'New Delhi', 'Delhi', 28.5672, 77.2100, 'government', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Trauma', 'Cardiology'], 4.7, 5000, 2478, 'manual', true),
('Sir Ganga Ram Hospital', '+91-11-25750000', '108', 'Rajinder Nagar, Old Rajinder Nagar', 'New Delhi', 'Delhi', 28.6389, 77.1883, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Cardiology'], 4.5, 3500, 675, 'manual', true),
('Fortis Hospital Vasant Kunj', '+91-11-42776222', '108', 'Sector B, Pocket 1, Aruna Asaf Ali Marg, Vasant Kunj', 'New Delhi', 'Delhi', 28.5244, 77.1586, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Cardiac Surgery'], 4.4, 2900, 400, 'manual', true),
('Max Super Speciality Hospital Saket', '+91-11-26515050', '108', '1, Press Enclave Road, Saket', 'New Delhi', 'Delhi', 28.5244, 77.2066, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Oncology'], 4.6, 3800, 500, 'manual', true),
('Apollo Hospital Delhi', '+91-11-26925858', '108', 'Mathura Road, Sarita Vihar', 'New Delhi', 'Delhi', 28.5355, 77.2951, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Neurology', 'Emergency'], 4.5, 3200, 710, 'manual', true);

-- Bangalore Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Manipal Hospital Whitefield', '+91-80-66453333', '108', 'ITPL Main Road, Brookefield', 'Bangalore', 'Karnataka', 12.9826, 77.7499, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Orthopedics'], 4.5, 2600, 400, 'manual', true),
('Fortis Hospital Bannerghatta Road', '+91-80-66214444', '108', '154/9, Opp. IIM-B, Bannerghatta Road', 'Bangalore', 'Karnataka', 12.8996, 77.6011, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Neurology', 'Emergency'], 4.4, 2400, 400, 'manual', true),
('Columbia Asia Hospital Whitefield', '+91-80-66554444', '108', 'Survey No. 10P & 12P, Ramagondanahalli, Varthur Hobli', 'Bangalore', 'Karnataka', 12.9897, 77.7497, 'private', true, true, true, 2, true, true, ARRAY['General Medicine', 'Pediatrics', 'Emergency'], 4.3, 1900, 200, 'manual', true),
('Narayana Health City', '+91-80-71222222', '108', '258/A, Bommasandra Industrial Area, Anekal Taluk', 'Bangalore', 'Karnataka', 12.8054, 77.6874, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Multi-specialty', 'Emergency'], 4.6, 3400, 1400, 'manual', true),
('St. John Medical College Hospital', '+91-80-49467000', '108', 'Sarjapur Road, John Nagar', 'Bangalore', 'Karnataka', 12.9516, 77.6221, 'private', true, true, true, 2, true, true, ARRAY['General Medicine', 'Surgery', 'Emergency'], 4.4, 2200, 1050, 'manual', true);

-- Chennai Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Apollo Hospital Chennai', '+91-44-28293333', '108', '21, Greams Lane, Off Greams Road', 'Chennai', 'Tamil Nadu', 13.0569, 80.2499, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Oncology', 'Emergency'], 4.6, 4200, 550, 'manual', true),
('Fortis Malar Hospital', '+91-44-42892222', '108', '52, 1st Main Road, Gandhi Nagar, Adyar', 'Chennai', 'Tamil Nadu', 13.0067, 80.2582, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Neurology', 'Emergency'], 4.4, 2800, 180, 'manual', true),
('MIOT International', '+91-44-42005000', '108', '4/112, Mount Poonamallee Road, Manapakkam', 'Chennai', 'Tamil Nadu', 13.0158, 80.1680, 'private', true, true, true, 1, true, true, ARRAY['Orthopedics', 'Cardiology', 'Emergency'], 4.5, 3100, 450, 'manual', true),
('Vijaya Hospital', '+91-44-24361090', '108', '434, NSK Salai, Vadapalani', 'Chennai', 'Tamil Nadu', 13.0502, 80.2121, 'private', true, true, true, 2, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2400, 314, 'manual', true),
('Stanley Medical College Hospital', '+91-44-25281351', '108', 'No.1, Old Jail Road, Royapuram', 'Chennai', 'Tamil Nadu', 13.1067, 80.2897, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.1, 1600, 900, 'manual', true);

-- Hyderabad Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Apollo Hospital Jubilee Hills', '+91-40-23607777', '108', 'Film Nagar, Jubilee Hills', 'Hyderabad', 'Telangana', 17.4239, 78.4127, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Oncology', 'Emergency'], 4.5, 3600, 500, 'manual', true),
('KIMS Hospital', '+91-40-44885000', '108', '1-112/86, Survey No 55/E, Kondapur', 'Hyderabad', 'Telangana', 17.4617, 78.3623, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Neurology'], 4.4, 2900, 300, 'manual', true),
('Care Hospital Banjara Hills', '+91-40-61656565', '108', 'Road No. 1, Banjara Hills', 'Hyderabad', 'Telangana', 17.4128, 78.4483, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Emergency'], 4.5, 3200, 435, 'manual', true),
('Yashoda Hospital Secunderabad', '+91-40-44889999', '108', 'Alexander Road, Kummabavighar', 'Hyderabad', 'Telangana', 17.4382, 78.5042, 'private', true, true, true, 2, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2500, 350, 'manual', true),
('Osmania General Hospital', '+91-40-24600146', '108', '5-9-22, Goshamahal Road, Koti', 'Hyderabad', 'Telangana', 17.3754, 78.4809, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.0, 1400, 1000, 'manual', true);

-- Kolkata Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('AMRI Hospital Dhakuria', '+91-33-66063800', '108', '97 Sarat Bose Road, Kolkata', 'Kolkata', 'West Bengal', 22.5163, 88.3553, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Cardiology'], 4.4, 2700, 400, 'manual', true),
('Apollo Gleneagles Hospital', '+91-33-23203040', '108', '58, Canal Circular Road, Kolkata', 'Kolkata', 'West Bengal', 22.5431, 88.3661, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Oncology', 'Emergency'], 4.5, 3100, 515, 'manual', true),
('Fortis Hospital Anandapur', '+91-33-66286666', '108', '730, Anandapur, EM Bypass Road', 'Kolkata', 'West Bengal', 22.5072, 88.3904, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2400, 400, 'manual', true),
('Medica Superspecialty Hospital', '+91-33-66521100', '108', '127, Mukundapur, EM Bypass', 'Kolkata', 'West Bengal', 22.5012, 88.3950, 'private', true, true, true, 2, true, true, ARRAY['Cardiology', 'Neurology', 'Emergency'], 4.4, 2600, 350, 'manual', true),
('Medical College Kolkata', '+91-33-22441752', '108', '88, College Street', 'Kolkata', 'West Bengal', 22.5826, 88.3639, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.1, 1700, 2300, 'manual', true);

-- Pune Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Ruby Hall Clinic', '+91-20-66455000', '108', '40, Sassoon Road, Pune', 'Pune', 'Maharashtra', 18.5204, 73.8567, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Emergency', 'Multi-specialty'], 4.4, 2900, 750, 'manual', true),
('Jehangir Hospital', '+91-20-26261000', '108', '32, Sassoon Road, Pune', 'Pune', 'Maharashtra', 18.5195, 73.8553, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2500, 350, 'manual', true),
('Sahyadri Hospital Deccan', '+91-20-67206700', '108', 'Plot 30C, Erandwane', 'Pune', 'Maharashtra', 18.5074, 73.8477, 'private', true, true, true, 2, true, true, ARRAY['Cardiac Surgery', 'Neurology', 'Emergency'], 4.5, 2800, 200, 'manual', true),
('Columbia Asia Hospital Kharadi', '+91-20-67264444', '108', 'Mundhwa - Kharadi Road, EON Free Zone, Kharadi', 'Pune', 'Maharashtra', 18.5515, 73.9471, 'private', true, true, true, 2, true, true, ARRAY['General Medicine', 'Pediatrics', 'Emergency'], 4.2, 1800, 150, 'manual', true);

-- ============================================================================
-- 10. Enable Row Level Security (RLS)
-- ============================================================================

ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;

-- Public read access (anyone can view hospitals)
DROP POLICY IF EXISTS "Hospitals are viewable by everyone" ON hospitals;
CREATE POLICY "Hospitals are viewable by everyone"
    ON hospitals
    FOR SELECT
    USING (is_active = true);

-- Only authenticated admins can insert/update/delete
DROP POLICY IF EXISTS "Only admins can modify hospitals" ON hospitals;
CREATE POLICY "Only admins can modify hospitals"
    ON hospitals
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );

-- ============================================================================
-- 11. Grant Execute Permissions on Functions
-- ============================================================================

GRANT EXECUTE ON FUNCTION find_nearest_hospitals(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION find_nearest_hospitals(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, BOOLEAN, BOOLEAN) TO anon;

GRANT EXECUTE ON FUNCTION search_hospitals(TEXT, TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION search_hospitals(TEXT, TEXT, TEXT, INTEGER) TO anon;

GRANT EXECUTE ON FUNCTION get_hospital_with_distance(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION get_hospital_with_distance(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO anon;

-- ============================================================================
-- 12. Add Comments for Documentation
-- ============================================================================

COMMENT ON TABLE hospitals IS 'Real hospital data with geospatial support for emergency services';
COMMENT ON FUNCTION find_nearest_hospitals IS 'Find nearest hospitals using PostGIS geospatial queries with emergency priority scoring';
COMMENT ON FUNCTION search_hospitals IS 'Search hospitals by name, city, or state';
COMMENT ON FUNCTION get_hospital_with_distance IS 'Get hospital details with optional distance calculation';
COMMENT ON FUNCTION calculate_emergency_priority_score IS 'Calculate emergency priority score based on hospital capabilities and distance';

-- ============================================================================
-- DONE!
-- ============================================================================
--
-- Next Steps:
-- 1. Run this migration: supabase db push
-- 2. Optionally integrate Google Places API for more data (see companion script)
-- 3. Test the function: SELECT * FROM find_nearest_hospitals(19.0760, 72.8777, 10, 5, true, false);
--
-- ============================================================================


-- ============================================
-- Migration: 20250202_openstreetmap_integration.sql
-- ============================================

-- ============================================================================
-- OpenStreetMap Overpass API Integration (100% FREE)
-- Description: Functions to import hospital data from OpenStreetMap
-- Date: 2025-02-02
-- API: https://overpass-api.de/ (No API key needed, completely free!)
-- ============================================================================

-- ============================================================================
-- 1. Function to Upsert Hospital from OpenStreetMap Data
-- ============================================================================

CREATE OR REPLACE FUNCTION upsert_hospital_from_osm(
    p_osm_id TEXT,
    p_name TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_city TEXT,
    p_state TEXT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_amenity TEXT DEFAULT 'hospital',
    p_emergency TEXT DEFAULT NULL,
    p_beds INTEGER DEFAULT NULL,
    p_website TEXT DEFAULT NULL,
    p_opening_hours TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_hospital_id UUID;
    v_has_emergency BOOLEAN;
    v_is_24_7 BOOLEAN;
    v_hospital_type TEXT;
BEGIN
    -- Determine if hospital has emergency
    v_has_emergency := (
        p_emergency IS NOT NULL OR
        p_amenity = 'hospital' OR
        p_name ILIKE '%emergency%' OR
        p_name ILIKE '%trauma%'
    );

    -- Determine if 24/7 based on opening_hours
    v_is_24_7 := (
        p_opening_hours = '24/7' OR
        p_opening_hours ILIKE '%24%' OR
        p_amenity = 'hospital' OR
        p_name ILIKE '%24%'
    );

    -- Determine hospital type (government hospitals often have specific names in India)
    v_hospital_type := CASE
        WHEN p_name ILIKE '%government%' THEN 'government'
        WHEN p_name ILIKE '%district%' THEN 'government'
        WHEN p_name ILIKE '%civil%' THEN 'government'
        WHEN p_name ILIKE '%general hospital%' THEN 'government'
        WHEN p_name ILIKE '%medical college%' THEN 'government'
        WHEN p_name ILIKE '%aiims%' THEN 'government'
        WHEN p_name ILIKE '%esi%' THEN 'government'
        WHEN p_name ILIKE '%railway%' THEN 'government'
        ELSE 'private'
    END;

    -- Insert or update hospital
    INSERT INTO hospitals (
        metadata, -- Store OSM ID in metadata
        name,
        phone,
        address,
        city,
        state,
        latitude,
        longitude,
        hospital_type,
        has_emergency,
        is_24_7,
        total_beds,
        website,
        data_source,
        verified,
        country
    )
    VALUES (
        jsonb_build_object('osm_id', p_osm_id, 'osm_amenity', p_amenity),
        p_name,
        p_phone,
        COALESCE(p_address, 'Address not available'),
        COALESCE(p_city, 'Unknown'),
        COALESCE(p_state, 'Unknown'),
        p_latitude,
        p_longitude,
        v_hospital_type,
        v_has_emergency,
        v_is_24_7,
        p_beds,
        p_website,
        'openstreetmap',
        false, -- Not verified yet
        'India'
    )
    ON CONFLICT ((metadata->>'osm_id'))
    WHERE metadata->>'osm_id' IS NOT NULL
    DO UPDATE SET
        name = EXCLUDED.name,
        phone = EXCLUDED.phone,
        address = EXCLUDED.address,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        hospital_type = EXCLUDED.hospital_type,
        has_emergency = EXCLUDED.has_emergency,
        is_24_7 = EXCLUDED.is_24_7,
        total_beds = EXCLUDED.total_beds,
        website = EXCLUDED.website,
        updated_at = NOW()
    RETURNING id INTO v_hospital_id;

    RETURN v_hospital_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Batch Insert Function for OpenStreetMap Hospitals
-- ============================================================================

CREATE OR REPLACE FUNCTION batch_insert_osm_hospitals(
    hospitals_json JSONB
)
RETURNS TABLE (
    inserted_count INTEGER,
    updated_count INTEGER,
    failed_count INTEGER,
    skipped_count INTEGER
) AS $$
DECLARE
    v_hospital JSONB;
    v_inserted INTEGER := 0;
    v_updated INTEGER := 0;
    v_failed INTEGER := 0;
    v_skipped INTEGER := 0;
    v_existing_id UUID;
    v_osm_id TEXT;
BEGIN
    FOR v_hospital IN SELECT * FROM jsonb_array_elements(hospitals_json)
    LOOP
        BEGIN
            v_osm_id := v_hospital->>'osm_id';

            -- Skip if no OSM ID
            IF v_osm_id IS NULL OR v_osm_id = '' THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            -- Check if hospital already exists
            SELECT id INTO v_existing_id
            FROM hospitals
            WHERE metadata->>'osm_id' = v_osm_id;

            IF v_existing_id IS NOT NULL THEN
                v_updated := v_updated + 1;
            ELSE
                v_inserted := v_inserted + 1;
            END IF;

            -- Upsert hospital
            PERFORM upsert_hospital_from_osm(
                v_osm_id,
                v_hospital->>'name',
                v_hospital->>'phone',
                v_hospital->>'address',
                v_hospital->>'city',
                v_hospital->>'state',
                (v_hospital->>'latitude')::DOUBLE PRECISION,
                (v_hospital->>'longitude')::DOUBLE PRECISION,
                v_hospital->>'amenity',
                v_hospital->>'emergency',
                CASE WHEN v_hospital->>'beds' IS NOT NULL
                     THEN (v_hospital->>'beds')::INTEGER
                     ELSE NULL END,
                v_hospital->>'website',
                v_hospital->>'opening_hours'
            );
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            RAISE NOTICE 'Failed to insert hospital: % (OSM ID: %)', v_hospital->>'name', v_osm_id;
        END;
    END LOOP;

    RETURN QUERY SELECT v_inserted, v_updated, v_failed, v_skipped;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. Create Unique Index for OSM ID
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_hospitals_osm_id
ON hospitals ((metadata->>'osm_id'))
WHERE metadata->>'osm_id' IS NOT NULL;

-- ============================================================================
-- 4. Grant Permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION upsert_hospital_from_osm TO authenticated;
GRANT EXECUTE ON FUNCTION batch_insert_osm_hospitals TO authenticated;

-- ============================================================================
-- DONE! 100% FREE - No API Key Required
-- ============================================================================

-- Usage Instructions:
--
-- 1. Fetch hospitals from Overpass API:
--    URL: https://overpass-api.de/api/interpreter
--    Query example (find hospitals in Mumbai):
--
--    [out:json];
--    (
--      node["amenity"="hospital"](18.8,72.7,19.3,73.0);
--      way["amenity"="hospital"](18.8,72.7,19.3,73.0);
--      relation["amenity"="hospital"](18.8,72.7,19.3,73.0);
--    );
--    out body;
--    >;
--    out skel qt;
--
-- 2. Parse the response and format as JSON array
-- 3. Call batch_insert_osm_hospitals(json_data)
--
-- No API key needed! Completely free!
-- Rate limit: ~1 request per second (generous for normal use)


-- ============================================
-- Migration: 20251129_admin_checklist_management.sql
-- ============================================

-- Admin Checklist Management Functions
-- Created: November 29, 2025

-- ============================================================
-- GET ALL CHECKLISTS (Admin)
-- Returns all checklists with trip info, creator, and statistics
-- ============================================================

DROP FUNCTION IF EXISTS public.get_all_checklists_admin(TEXT, TEXT, UUID, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.get_all_checklists_admin(
  p_search TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_trip_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  trip_id UUID,
  trip_name TEXT,
  trip_destination TEXT,
  name TEXT,
  created_by UUID,
  creator_name TEXT,
  creator_email CITEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  item_count BIGINT,
  completed_count BIGINT,
  pending_count BIGINT
) AS $$
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  RETURN QUERY
  SELECT
    c.id,
    c.trip_id,
    t.name as trip_name,
    t.destination as trip_destination,
    c.name,
    c.created_by,
    p.full_name as creator_name,
    p.email as creator_email,
    c.created_at,
    c.updated_at,
    (SELECT COUNT(*) FROM public.checklist_items WHERE checklist_id = c.id) as item_count,
    (SELECT COUNT(*) FROM public.checklist_items WHERE checklist_id = c.id AND is_completed = true) as completed_count,
    (SELECT COUNT(*) FROM public.checklist_items WHERE checklist_id = c.id AND is_completed = false) as pending_count
  FROM public.checklists c
  JOIN public.trips t ON c.trip_id = t.id
  LEFT JOIN public.profiles p ON c.created_by = p.id
  WHERE (p_search IS NULL OR
         c.name ILIKE '%' || p_search || '%' OR
         t.name ILIKE '%' || p_search || '%' OR
         t.destination ILIKE '%' || p_search || '%')
    AND (p_trip_id IS NULL OR c.trip_id = p_trip_id)
    AND (p_status IS NULL OR
         (p_status = 'completed' AND NOT EXISTS (
           SELECT 1 FROM public.checklist_items ci
           WHERE ci.checklist_id = c.id AND ci.is_completed = false
         ) AND EXISTS (
           SELECT 1 FROM public.checklist_items ci2
           WHERE ci2.checklist_id = c.id
         )) OR
         (p_status = 'pending' AND EXISTS (
           SELECT 1 FROM public.checklist_items ci
           WHERE ci.checklist_id = c.id AND ci.is_completed = false
         )) OR
         (p_status = 'empty' AND NOT EXISTS (
           SELECT 1 FROM public.checklist_items ci
           WHERE ci.checklist_id = c.id
         )))
  ORDER BY c.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_all_checklists_admin TO authenticated;

-- ============================================================
-- GET CHECKLIST STATISTICS (Admin Dashboard)
-- Returns overall checklist statistics
-- ============================================================

DROP FUNCTION IF EXISTS public.get_admin_checklist_stats();

CREATE OR REPLACE FUNCTION public.get_admin_checklist_stats()
RETURNS TABLE (
  total_checklists BIGINT,
  total_items BIGINT,
  completed_items BIGINT,
  pending_items BIGINT,
  completion_rate DOUBLE PRECISION,
  checklists_with_all_completed BIGINT,
  empty_checklists BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM public.checklists)::BIGINT as total_checklists,
    (SELECT COUNT(*) FROM public.checklist_items)::BIGINT as total_items,
    (SELECT COUNT(*) FROM public.checklist_items WHERE is_completed = true)::BIGINT as completed_items,
    (SELECT COUNT(*) FROM public.checklist_items WHERE is_completed = false)::BIGINT as pending_items,
    CASE
      WHEN (SELECT COUNT(*) FROM public.checklist_items) = 0 THEN 0.0
      ELSE ROUND(
        (SELECT COUNT(*) FROM public.checklist_items WHERE is_completed = true)::DOUBLE PRECISION /
        (SELECT COUNT(*) FROM public.checklist_items)::DOUBLE PRECISION * 100, 2
      )
    END as completion_rate,
    (SELECT COUNT(*) FROM public.checklists c
     WHERE NOT EXISTS (
       SELECT 1 FROM public.checklist_items ci
       WHERE ci.checklist_id = c.id AND ci.is_completed = false
     ) AND EXISTS (
       SELECT 1 FROM public.checklist_items ci2
       WHERE ci2.checklist_id = c.id
     ))::BIGINT as checklists_with_all_completed,
    (SELECT COUNT(*) FROM public.checklists c
     WHERE NOT EXISTS (
       SELECT 1 FROM public.checklist_items ci
       WHERE ci.checklist_id = c.id
     ))::BIGINT as empty_checklists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_admin_checklist_stats TO authenticated;

-- ============================================================
-- DELETE CHECKLIST (Admin)
-- Deletes a checklist and all its items
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_delete_checklist(UUID);

CREATE OR REPLACE FUNCTION public.admin_delete_checklist(
  p_checklist_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  -- Delete checklist items first (should cascade, but being explicit)
  DELETE FROM public.checklist_items WHERE checklist_id = p_checklist_id;

  -- Delete the checklist
  DELETE FROM public.checklists WHERE id = p_checklist_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_delete_checklist TO authenticated;

-- ============================================================
-- UPDATE CHECKLIST (Admin)
-- Updates checklist properties
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_update_checklist(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.admin_update_checklist(
  p_checklist_id UUID,
  p_name TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  UPDATE public.checklists
  SET
    name = COALESCE(p_name, name),
    updated_at = NOW()
  WHERE id = p_checklist_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_update_checklist TO authenticated;

-- ============================================================
-- BULK UPDATE CHECKLIST ITEMS (Admin)
-- Marks all items in a checklist as completed or pending
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_bulk_update_checklist_items(UUID, BOOLEAN);

CREATE OR REPLACE FUNCTION public.admin_bulk_update_checklist_items(
  p_checklist_id UUID,
  p_is_completed BOOLEAN
)
RETURNS INTEGER AS $$
DECLARE
  affected_count INTEGER;
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  UPDATE public.checklist_items
  SET
    is_completed = p_is_completed,
    completed_at = CASE WHEN p_is_completed THEN NOW() ELSE NULL END,
    completed_by = CASE WHEN p_is_completed THEN auth.uid() ELSE NULL END,
    updated_at = NOW()
  WHERE checklist_id = p_checklist_id;

  GET DIAGNOSTICS affected_count = ROW_COUNT;

  RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_bulk_update_checklist_items TO authenticated;


-- ============================================
-- Migration: 20251129_admin_expense_management.sql
-- ============================================

-- Admin Expense Management Functions
-- Created: November 29, 2025

-- ============================================================
-- GET ALL EXPENSES (Admin)
-- Returns all expenses with trip info, payer, and split statistics
-- ============================================================

DROP FUNCTION IF EXISTS public.get_all_expenses_admin(TEXT, TEXT, UUID, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.get_all_expenses_admin(
  p_search TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL,
  p_trip_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  trip_id UUID,
  trip_name TEXT,
  trip_destination TEXT,
  title TEXT,
  description TEXT,
  amount DECIMAL(12, 2),
  currency TEXT,
  category TEXT,
  paid_by UUID,
  payer_name TEXT,
  payer_email CITEXT,
  split_type TEXT,
  receipt_url TEXT,
  transaction_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  split_count BIGINT,
  settled_count BIGINT,
  pending_amount DECIMAL(12, 2)
) AS $$
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  RETURN QUERY
  SELECT
    e.id,
    e.trip_id,
    t.name as trip_name,
    t.destination as trip_destination,
    e.title,
    e.description,
    e.amount,
    e.currency,
    e.category,
    e.paid_by,
    p.full_name as payer_name,
    p.email as payer_email,
    e.split_type,
    e.receipt_url,
    e.transaction_date,
    e.created_at,
    e.updated_at,
    (SELECT COUNT(*) FROM public.expense_splits WHERE expense_id = e.id) as split_count,
    (SELECT COUNT(*) FROM public.expense_splits WHERE expense_id = e.id AND is_settled = true) as settled_count,
    (SELECT COALESCE(SUM(es.amount), 0) FROM public.expense_splits es WHERE es.expense_id = e.id AND es.is_settled = false) as pending_amount
  FROM public.expenses e
  LEFT JOIN public.trips t ON e.trip_id = t.id
  LEFT JOIN public.profiles p ON e.paid_by = p.id
  WHERE (p_search IS NULL OR
         e.title ILIKE '%' || p_search || '%' OR
         e.description ILIKE '%' || p_search || '%' OR
         t.name ILIKE '%' || p_search || '%' OR
         p.full_name ILIKE '%' || p_search || '%')
    AND (p_category IS NULL OR e.category = p_category)
    AND (p_trip_id IS NULL OR e.trip_id = p_trip_id)
  ORDER BY e.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_all_expenses_admin TO authenticated;

-- ============================================================
-- GET EXPENSE STATISTICS (Admin Dashboard)
-- Returns overall expense statistics
-- ============================================================

DROP FUNCTION IF EXISTS public.get_admin_expense_stats();

CREATE OR REPLACE FUNCTION public.get_admin_expense_stats()
RETURNS TABLE (
  total_expenses BIGINT,
  total_amount DECIMAL(12, 2),
  total_settled DECIMAL(12, 2),
  total_pending DECIMAL(12, 2),
  settlement_rate DOUBLE PRECISION,
  expenses_with_receipts BIGINT,
  standalone_expenses BIGINT,
  trip_expenses BIGINT,
  category_breakdown JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM public.expenses)::BIGINT as total_expenses,
    (SELECT COALESCE(SUM(amount), 0) FROM public.expenses) as total_amount,
    (SELECT COALESCE(SUM(es.amount), 0) FROM public.expense_splits es WHERE es.is_settled = true) as total_settled,
    (SELECT COALESCE(SUM(es.amount), 0) FROM public.expense_splits es WHERE es.is_settled = false) as total_pending,
    CASE
      WHEN (SELECT COUNT(*) FROM public.expense_splits) = 0 THEN 0.0
      ELSE ROUND(
        (SELECT COUNT(*) FROM public.expense_splits WHERE is_settled = true)::DOUBLE PRECISION /
        (SELECT COUNT(*) FROM public.expense_splits)::DOUBLE PRECISION * 100, 2
      )
    END as settlement_rate,
    (SELECT COUNT(*) FROM public.expenses WHERE receipt_url IS NOT NULL)::BIGINT as expenses_with_receipts,
    (SELECT COUNT(*) FROM public.expenses WHERE trip_id IS NULL)::BIGINT as standalone_expenses,
    (SELECT COUNT(*) FROM public.expenses WHERE trip_id IS NOT NULL)::BIGINT as trip_expenses,
    (SELECT jsonb_object_agg(COALESCE(category, 'uncategorized'), cnt)
     FROM (
       SELECT category, COUNT(*) as cnt
       FROM public.expenses
       GROUP BY category
     ) cat_counts
    ) as category_breakdown;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_admin_expense_stats TO authenticated;

-- ============================================================
-- DELETE EXPENSE (Admin)
-- Deletes an expense and all its splits
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_delete_expense(UUID);

CREATE OR REPLACE FUNCTION public.admin_delete_expense(
  p_expense_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  -- Delete expense splits first (should cascade, but being explicit)
  DELETE FROM public.expense_splits WHERE expense_id = p_expense_id;

  -- Delete the expense
  DELETE FROM public.expenses WHERE id = p_expense_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_delete_expense TO authenticated;

-- ============================================================
-- UPDATE EXPENSE (Admin)
-- Updates expense properties
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_update_expense(UUID, TEXT, TEXT, DECIMAL, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.admin_update_expense(
  p_expense_id UUID,
  p_title TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_amount DECIMAL DEFAULT NULL,
  p_currency TEXT DEFAULT NULL,
  p_category TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  UPDATE public.expenses
  SET
    title = COALESCE(p_title, title),
    description = COALESCE(p_description, description),
    amount = COALESCE(p_amount, amount),
    currency = COALESCE(p_currency, currency),
    category = COALESCE(p_category, category),
    updated_at = NOW()
  WHERE id = p_expense_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_update_expense TO authenticated;

-- ============================================================
-- SETTLE ALL SPLITS (Admin)
-- Marks all splits for an expense as settled
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_settle_expense_splits(UUID);

CREATE OR REPLACE FUNCTION public.admin_settle_expense_splits(
  p_expense_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  affected_count INTEGER;
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  UPDATE public.expense_splits
  SET
    is_settled = true,
    settled_at = NOW()
  WHERE expense_id = p_expense_id AND is_settled = false;

  GET DIAGNOSTICS affected_count = ROW_COUNT;

  RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_settle_expense_splits TO authenticated;

-- ============================================================
-- UNSETTLE ALL SPLITS (Admin)
-- Marks all splits for an expense as unsettled
-- ============================================================

DROP FUNCTION IF EXISTS public.admin_unsettle_expense_splits(UUID);

CREATE OR REPLACE FUNCTION public.admin_unsettle_expense_splits(
  p_expense_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  affected_count INTEGER;
BEGIN
  -- Admin check temporarily disabled for development
  -- IF NOT public.is_admin(auth.uid()) THEN
  --   RAISE EXCEPTION 'Access denied: Admin privileges required';
  -- END IF;

  UPDATE public.expense_splits
  SET
    is_settled = false,
    settled_at = NULL
  WHERE expense_id = p_expense_id AND is_settled = true;

  GET DIAGNOSTICS affected_count = ROW_COUNT;

  RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_unsettle_expense_splits TO authenticated;


-- ============================================
-- Migration: 20251202_group_chat.sql
-- ============================================

-- Migration: Group Chat Feature
-- Date: 2025-12-02
-- Description: Add conversations and conversation_members tables for group chat functionality

-- ============================================================================
-- CONVERSATIONS TABLE
-- ============================================================================
-- Stores group chat conversations within trips

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_direct_message BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add comment explaining the table
COMMENT ON TABLE public.conversations IS 'Group chat conversations within trips';
COMMENT ON COLUMN public.conversations.is_direct_message IS 'True for 1:1 direct messages, false for group chats';

-- ============================================================================
-- CONVERSATION_MEMBERS TABLE
-- ============================================================================
-- Tracks members of each conversation

CREATE TABLE IF NOT EXISTS public.conversation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_muted BOOLEAN DEFAULT false,
    last_read_at TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);

-- Add comment explaining the table
COMMENT ON TABLE public.conversation_members IS 'Members of group chat conversations';
COMMENT ON COLUMN public.conversation_members.role IS 'Member role: admin or member';
COMMENT ON COLUMN public.conversation_members.is_muted IS 'Whether notifications are muted for this member';
COMMENT ON COLUMN public.conversation_members.last_read_at IS 'Timestamp of last read message for unread count';

-- ============================================================================
-- UPDATE MESSAGES TABLE
-- ============================================================================
-- Add conversation_id column (nullable for backward compatibility)

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;

COMMENT ON COLUMN public.messages.conversation_id IS 'Optional conversation reference for group chats. NULL for legacy trip-wide messages.';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Conversations indexes
CREATE INDEX IF NOT EXISTS idx_conversations_trip ON public.conversations(trip_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);

-- Conversation members indexes
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_user ON public.conversation_members(user_id);

-- Messages by conversation index
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC)
WHERE conversation_id IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;

-- Conversations: Users can view conversations they are members of
DROP POLICY IF EXISTS "Users can view conversations they are members of" ON public.conversations;
CREATE POLICY "Users can view conversations they are members of"
ON public.conversations
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
    )
);

-- Conversations: Trip members can create conversations
DROP POLICY IF EXISTS "Trip members can create conversations" ON public.conversations;
CREATE POLICY "Trip members can create conversations"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = conversations.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

-- Conversations: Admins can update conversations
DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;
CREATE POLICY "Conversation admins can update conversations"
ON public.conversations
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
);

-- Conversations: Admins can delete conversations
DROP POLICY IF EXISTS "Conversation admins can delete conversations" ON public.conversations;
CREATE POLICY "Conversation admins can delete conversations"
ON public.conversations
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
);

-- Conversation Members: Users can view members of conversations they belong to
DROP POLICY IF EXISTS "Users can view conversation members" ON public.conversation_members;
CREATE POLICY "Users can view conversation members"
ON public.conversation_members
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
    )
);

-- Conversation Members: Admins can add members
DROP POLICY IF EXISTS "Conversation admins can add members" ON public.conversation_members;
CREATE POLICY "Conversation admins can add members"
ON public.conversation_members
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR
    -- Creator of a new conversation can add initial members
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- Conversation Members: Users can update their own membership (mute, last_read)
DROP POLICY IF EXISTS "Users can update their own membership" ON public.conversation_members;
CREATE POLICY "Users can update their own membership"
ON public.conversation_members
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Conversation Members: Users can leave conversations (delete their membership)
DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_members;
CREATE POLICY "Users can leave conversations"
ON public.conversation_members
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Conversation Members: Admins can remove members
DROP POLICY IF EXISTS "Conversation admins can remove members" ON public.conversation_members;
CREATE POLICY "Conversation admins can remove members"
ON public.conversation_members
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for conversations updated_at
DROP TRIGGER IF EXISTS conversations_updated_at_trigger ON public.conversations;
CREATE TRIGGER conversations_updated_at_trigger
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_conversations_updated_at();

-- Function to get conversation with last message and unread count
CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all conversations for a trip with details
CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    ORDER BY last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to find existing DM conversation between two users in a trip
CREATE OR REPLACE FUNCTION find_existing_dm(
    p_trip_id UUID,
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Find a DM conversation where both users are members
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND c.is_direct_message = true
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm1
        WHERE cm1.conversation_id = c.id AND cm1.user_id = p_user1_id
    )
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm2
        WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user2_id
    )
    AND (
        SELECT COUNT(*) FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id
    ) = 2
    LIMIT 1;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_members TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION find_existing_dm TO authenticated;

-- ============================================================================
-- REALTIME
-- ============================================================================
-- Enable realtime for conversations (uncomment in Supabase dashboard or via migration)
-- ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
-- ALTER PUBLICATION supabase_realtime ADD TABLE conversation_members;


-- ============================================
-- Migration: 20251203_trip_join_requests.sql
-- ============================================

-- Migration: Trip Join Requests
-- Date: 2025-12-03
-- Description: Create trip_join_requests table for managing join requests to public trips

-- Create enum type for request status
DO $$ BEGIN
    CREATE TYPE public.join_request_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create trip_join_requests table
CREATE TABLE IF NOT EXISTS public.trip_join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status public.join_request_status NOT NULL DEFAULT 'pending',
    message TEXT, -- Optional message from requester
    response_message TEXT, -- Optional response from trip owner
    responded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at TIMESTAMPTZ,

    -- Ensure a user can only have one pending request per trip
    CONSTRAINT unique_pending_request UNIQUE (trip_id, user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_join_requests_trip_id ON public.trip_join_requests(trip_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_user_id ON public.trip_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON public.trip_join_requests(status);
CREATE INDEX IF NOT EXISTS idx_join_requests_created_at ON public.trip_join_requests(created_at DESC);

-- Add comments
COMMENT ON TABLE public.trip_join_requests IS 'Stores join requests for public trips';
COMMENT ON COLUMN public.trip_join_requests.message IS 'Optional message from the user requesting to join';
COMMENT ON COLUMN public.trip_join_requests.response_message IS 'Optional response from the trip owner/admin';
COMMENT ON COLUMN public.trip_join_requests.responded_by IS 'User ID of the person who approved/rejected the request';

-- Enable RLS
ALTER TABLE public.trip_join_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view their own requests
DROP POLICY IF EXISTS "Users can view own join requests" ON public.trip_join_requests;
CREATE POLICY "Users can view own join requests"
ON public.trip_join_requests
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Trip owners/admins can view requests for their trips
DROP POLICY IF EXISTS "Trip owners can view requests for their trips" ON public.trip_join_requests;
CREATE POLICY "Trip owners can view requests for their trips"
ON public.trip_join_requests
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = trip_join_requests.trip_id
        AND t.created_by = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = trip_join_requests.trip_id
        AND tm.user_id = auth.uid()
        AND tm.role = 'admin'
    )
);

-- Users can create join requests for public trips they're not members of
DROP POLICY IF EXISTS "Users can request to join public trips" ON public.trip_join_requests;
CREATE POLICY "Users can request to join public trips"
ON public.trip_join_requests
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
    AND
    -- Trip must be public
    EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = trip_join_requests.trip_id
        AND t.is_public = true
    )
    AND
    -- User must not already be a member
    NOT EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = trip_join_requests.trip_id
        AND tm.user_id = auth.uid()
    )
);

-- Users can cancel their own pending requests
DROP POLICY IF EXISTS "Users can cancel own pending requests" ON public.trip_join_requests;
CREATE POLICY "Users can cancel own pending requests"
ON public.trip_join_requests
FOR UPDATE
TO authenticated
USING (
    user_id = auth.uid()
    AND status = 'pending'
)
WITH CHECK (
    user_id = auth.uid()
    AND status = 'cancelled'
);

-- Trip owners/admins can approve or reject requests
DROP POLICY IF EXISTS "Trip owners can respond to requests" ON public.trip_join_requests;
CREATE POLICY "Trip owners can respond to requests"
ON public.trip_join_requests
FOR UPDATE
TO authenticated
USING (
    status = 'pending'
    AND
    (
        EXISTS (
            SELECT 1 FROM public.trips t
            WHERE t.id = trip_join_requests.trip_id
            AND t.created_by = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM public.trip_members tm
            WHERE tm.trip_id = trip_join_requests.trip_id
            AND tm.user_id = auth.uid()
            AND tm.role = 'admin'
        )
    )
)
WITH CHECK (
    status IN ('approved', 'rejected')
);

-- Users can delete their own cancelled/rejected requests
DROP POLICY IF EXISTS "Users can delete own non-pending requests" ON public.trip_join_requests;
CREATE POLICY "Users can delete own non-pending requests"
ON public.trip_join_requests
FOR DELETE
TO authenticated
USING (
    user_id = auth.uid()
    AND status IN ('cancelled', 'rejected')
);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trip_join_requests TO authenticated;

-- Function to get public trips with join status
CREATE OR REPLACE FUNCTION public.get_public_trips(
    p_search TEXT DEFAULT NULL,
    p_destination TEXT DEFAULT NULL,
    p_min_budget DOUBLE PRECISION DEFAULT NULL,
    p_max_budget DOUBLE PRECISION DEFAULT NULL,
    p_start_after DATE DEFAULT NULL,
    p_start_before DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    destination TEXT,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    cover_image_url TEXT,
    created_by UUID,
    creator_name TEXT,
    creator_avatar TEXT,
    created_at TIMESTAMPTZ,
    budget DOUBLE PRECISION,
    currency TEXT,
    member_count BIGINT,
    is_member BOOLEAN,
    join_request_status public.join_request_status
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.id,
        t.name,
        t.description,
        t.destination,
        t.start_date,
        t.end_date,
        t.cover_image_url,
        t.created_by,
        p.full_name as creator_name,
        p.avatar_url as creator_avatar,
        t.created_at,
        t.budget,
        t.currency,
        (SELECT COUNT(*) FROM public.trip_members WHERE trip_id = t.id) as member_count,
        EXISTS (
            SELECT 1 FROM public.trip_members tm
            WHERE tm.trip_id = t.id AND tm.user_id = auth.uid()
        ) as is_member,
        (
            SELECT jr.status FROM public.trip_join_requests jr
            WHERE jr.trip_id = t.id AND jr.user_id = auth.uid()
            ORDER BY jr.created_at DESC
            LIMIT 1
        ) as join_request_status
    FROM public.trips t
    JOIN public.profiles p ON t.created_by = p.id
    WHERE t.is_public = true
        AND t.is_completed = false -- Only show active trips
        AND (p_search IS NULL OR
             t.name ILIKE '%' || p_search || '%' OR
             t.destination ILIKE '%' || p_search || '%' OR
             t.description ILIKE '%' || p_search || '%')
        AND (p_destination IS NULL OR t.destination ILIKE '%' || p_destination || '%')
        AND (p_min_budget IS NULL OR t.budget >= p_min_budget)
        AND (p_max_budget IS NULL OR t.budget <= p_max_budget)
        AND (p_start_after IS NULL OR t.start_date >= p_start_after)
        AND (p_start_before IS NULL OR t.start_date <= p_start_before)
    ORDER BY t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_public_trips TO authenticated;

-- Function to create a join request
CREATE OR REPLACE FUNCTION public.create_join_request(
    p_trip_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_request_id UUID;
BEGIN
    -- Check if trip is public
    IF NOT EXISTS (SELECT 1 FROM public.trips WHERE id = p_trip_id AND is_public = true) THEN
        RAISE EXCEPTION 'Trip is not public';
    END IF;

    -- Check if user is already a member
    IF EXISTS (SELECT 1 FROM public.trip_members WHERE trip_id = p_trip_id AND user_id = auth.uid()) THEN
        RAISE EXCEPTION 'You are already a member of this trip';
    END IF;

    -- Check if there's already a pending request
    IF EXISTS (SELECT 1 FROM public.trip_join_requests WHERE trip_id = p_trip_id AND user_id = auth.uid() AND status = 'pending') THEN
        RAISE EXCEPTION 'You already have a pending request for this trip';
    END IF;

    -- Create the request
    INSERT INTO public.trip_join_requests (trip_id, user_id, message)
    VALUES (p_trip_id, auth.uid(), p_message)
    RETURNING id INTO v_request_id;

    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_join_request TO authenticated;

-- Function to respond to a join request (approve/reject)
CREATE OR REPLACE FUNCTION public.respond_to_join_request(
    p_request_id UUID,
    p_approved BOOLEAN,
    p_response_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_trip_id UUID;
    v_user_id UUID;
    v_status public.join_request_status;
BEGIN
    -- Get the request details
    SELECT trip_id, user_id, status INTO v_trip_id, v_user_id, v_status
    FROM public.trip_join_requests
    WHERE id = p_request_id;

    IF v_trip_id IS NULL THEN
        RAISE EXCEPTION 'Request not found';
    END IF;

    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Request has already been processed';
    END IF;

    -- Check if current user is trip owner or admin
    IF NOT EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = v_trip_id AND t.created_by = auth.uid()
    ) AND NOT EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = v_trip_id AND tm.user_id = auth.uid() AND tm.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'You do not have permission to respond to this request';
    END IF;

    -- Update the request
    UPDATE public.trip_join_requests
    SET
        status = CASE WHEN p_approved THEN 'approved'::public.join_request_status ELSE 'rejected'::public.join_request_status END,
        response_message = p_response_message,
        responded_by = auth.uid(),
        responded_at = now(),
        updated_at = now()
    WHERE id = p_request_id;

    -- If approved, add user as member
    IF p_approved THEN
        INSERT INTO public.trip_members (trip_id, user_id, role)
        VALUES (v_trip_id, v_user_id, 'member');
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.respond_to_join_request TO authenticated;

-- Function to get pending join requests for a trip (for trip owners)
CREATE OR REPLACE FUNCTION public.get_trip_join_requests(p_trip_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_name TEXT,
    user_email CITEXT,
    user_avatar TEXT,
    message TEXT,
    status public.join_request_status,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Check if current user is trip owner or admin
    IF NOT EXISTS (
        SELECT 1 FROM public.trips t
        WHERE t.id = p_trip_id AND t.created_by = auth.uid()
    ) AND NOT EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = p_trip_id AND tm.user_id = auth.uid() AND tm.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'You do not have permission to view requests for this trip';
    END IF;

    RETURN QUERY
    SELECT
        jr.id,
        jr.user_id,
        p.full_name as user_name,
        p.email as user_email,
        p.avatar_url as user_avatar,
        jr.message,
        jr.status,
        jr.created_at
    FROM public.trip_join_requests jr
    JOIN public.profiles p ON jr.user_id = p.id
    WHERE jr.trip_id = p_trip_id
    ORDER BY
        CASE WHEN jr.status = 'pending' THEN 0 ELSE 1 END,
        jr.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_trip_join_requests TO authenticated;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_join_request_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_join_request_updated_at ON public.trip_join_requests;
CREATE TRIGGER trigger_update_join_request_updated_at
    BEFORE UPDATE ON public.trip_join_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.update_join_request_updated_at();


-- ============================================
-- Migration: 20251203_trip_member_permissions_rls.sql
-- ============================================

-- =====================================================
-- Trip Member Permissions - Row Level Security Policies
-- =====================================================
-- This migration adds RLS policies to enforce that:
-- 1. Only trip owner can edit/delete trip details
-- 2. Only trip owner/admin can edit itinerary and checklists
-- 3. All members can add expenses, but only edit/delete their own
-- =====================================================

-- =====================================================
-- TRIPS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip owners can update their trips" ON public.trips;
DROP POLICY IF EXISTS "Trip owners can delete their trips" ON public.trips;

-- Only trip owner can update trip details
CREATE POLICY "Trip owners can update their trips"
ON public.trips
FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Only trip owner can delete trips
CREATE POLICY "Trip owners can delete their trips"
ON public.trips
FOR DELETE
USING (created_by = auth.uid());

-- =====================================================
-- ITINERARY_ITEMS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view itinerary" ON public.itinerary_items;
DROP POLICY IF EXISTS "Trip owners and admins can insert itinerary" ON public.itinerary_items;
DROP POLICY IF EXISTS "Trip owners and admins can update itinerary" ON public.itinerary_items;
DROP POLICY IF EXISTS "Trip owners and admins can delete itinerary" ON public.itinerary_items;

-- All trip members can view itinerary
CREATE POLICY "Trip members can view itinerary"
ON public.itinerary_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Only trip owner or admin can insert itinerary items
CREATE POLICY "Trip owners and admins can insert itinerary"
ON public.itinerary_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can update itinerary items
CREATE POLICY "Trip owners and admins can update itinerary"
ON public.itinerary_items
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can delete itinerary items
CREATE POLICY "Trip owners and admins can delete itinerary"
ON public.itinerary_items
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- =====================================================
-- CHECKLISTS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view checklists" ON public.checklists;
DROP POLICY IF EXISTS "Trip owners and admins can insert checklists" ON public.checklists;
DROP POLICY IF EXISTS "Trip owners and admins can update checklists" ON public.checklists;
DROP POLICY IF EXISTS "Trip owners and admins can delete checklists" ON public.checklists;

-- All trip members can view checklists
CREATE POLICY "Trip members can view checklists"
ON public.checklists
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Only trip owner or admin can insert checklists
CREATE POLICY "Trip owners and admins can insert checklists"
ON public.checklists
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can update checklists
CREATE POLICY "Trip owners and admins can update checklists"
ON public.checklists
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can delete checklists
CREATE POLICY "Trip owners and admins can delete checklists"
ON public.checklists
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- =====================================================
-- CHECKLIST_ITEMS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Trip owners and admins can insert checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Trip owners and admins can update checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Trip owners and admins can delete checklist items" ON public.checklist_items;

-- All trip members can view checklist items
CREATE POLICY "Trip members can view checklist items"
ON public.checklist_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
  )
);

-- Only trip owner or admin can insert checklist items
CREATE POLICY "Trip owners and admins can insert checklist items"
ON public.checklist_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- Only trip owner or admin can update checklist items
CREATE POLICY "Trip owners and admins can update checklist items"
ON public.checklist_items
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- Only trip owner or admin can delete checklist items
CREATE POLICY "Trip owners and admins can delete checklist items"
ON public.checklist_items
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- =====================================================
-- EXPENSES TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view expenses" ON public.expenses;
DROP POLICY IF EXISTS "Trip members can insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Expense owners and trip admins can update expenses" ON public.expenses;
DROP POLICY IF EXISTS "Expense owners and trip admins can delete expenses" ON public.expenses;

-- All trip members can view expenses
CREATE POLICY "Trip members can view expenses"
ON public.expenses
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- All trip members can insert expenses (add their own expenses)
CREATE POLICY "Trip members can insert expenses"
ON public.expenses
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Only expense creator (payer), trip owner, or admin can update expenses
CREATE POLICY "Expense owners and trip admins can update expenses"
ON public.expenses
FOR UPDATE
USING (
  -- Expense creator (payer) can update
  paid_by = auth.uid()
  OR
  -- Trip owner can update any expense
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = expenses.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  -- Trip admin can update any expense
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  paid_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = expenses.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only expense creator (payer), trip owner, or admin can delete expenses
CREATE POLICY "Expense owners and trip admins can delete expenses"
ON public.expenses
FOR DELETE
USING (
  -- Expense creator (payer) can delete
  paid_by = auth.uid()
  OR
  -- Trip owner can delete any expense
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = expenses.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  -- Trip admin can delete any expense
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- =====================================================
-- EXPENSE_SPLITS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Trip members can insert expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Expense owners and trip admins can update expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Expense owners and trip admins can delete expense splits" ON public.expense_splits;

-- All trip members can view expense splits
CREATE POLICY "Trip members can view expense splits"
ON public.expense_splits
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
  )
);

-- All trip members can insert expense splits (when creating expenses)
CREATE POLICY "Trip members can insert expense splits"
ON public.expense_splits
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
  )
);

-- Only expense creator (payer), trip owner, or admin can update expense splits
CREATE POLICY "Expense owners and trip admins can update expense splits"
ON public.expense_splits
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_splits.expense_id
    AND e.paid_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trips t ON t.id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_splits.expense_id
    AND e.paid_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trips t ON t.id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- Only expense creator (payer), trip owner, or admin can delete expense splits
CREATE POLICY "Expense owners and trip admins can delete expense splits"
ON public.expense_splits
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_splits.expense_id
    AND e.paid_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trips t ON t.id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- =====================================================
-- SUMMARY
-- =====================================================
-- Trips: Only owner can edit/delete
-- Itinerary: Owner and admins can edit, all members can view
-- Checklists: Owner and admins can edit, all members can view
-- Checklist Items: Owner and admins can edit, all members can view
-- Expenses: All members can add, only creator/owner/admin can edit/delete
-- Expense Splits: Same as expenses
-- =====================================================


-- ============================================
-- Migration: 20251204_create_trip_templates_schema.sql
-- ============================================

-- =====================================================
-- TRIP TEMPLATES DATABASE SCHEMA
-- =====================================================
-- Creates the tables for trip templates feature:
-- 1. trip_templates - Main template information
-- 2. template_itinerary_items - Day-by-day activities
-- 3. template_checklists - Packing list categories
-- 4. template_checklist_items - Individual checklist items
-- 5. ai_usage_tracking - Track AI itinerary generation usage
-- =====================================================

-- =====================================================
-- 1. TRIP TEMPLATES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.trip_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  destination TEXT NOT NULL,
  destination_state TEXT,
  duration_days INTEGER NOT NULL DEFAULT 1,
  budget_min DOUBLE PRECISION,
  budget_max DOUBLE PRECISION,
  currency TEXT NOT NULL DEFAULT 'INR',
  category TEXT NOT NULL DEFAULT 'adventure',
  tags TEXT[] DEFAULT '{}',
  best_season TEXT[] DEFAULT '{}',
  difficulty_level TEXT NOT NULL DEFAULT 'easy',
  cover_image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  use_count INTEGER NOT NULL DEFAULT 0,
  rating DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add comments
COMMENT ON TABLE public.trip_templates IS 'Pre-built trip templates that users can use as starting points';
COMMENT ON COLUMN public.trip_templates.category IS 'Template category: adventure, beach, heritage, family, pilgrimage, wildlife, hillStation, roadTrip, weekend';
COMMENT ON COLUMN public.trip_templates.difficulty_level IS 'Trip difficulty: easy, moderate, difficult';
COMMENT ON COLUMN public.trip_templates.best_season IS 'Array of months when this trip is best (e.g., October, November)';

-- Index for efficient queries
CREATE INDEX IF NOT EXISTS idx_trip_templates_category ON public.trip_templates(category);
CREATE INDEX IF NOT EXISTS idx_trip_templates_is_active ON public.trip_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_trip_templates_is_featured ON public.trip_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_trip_templates_destination ON public.trip_templates(destination);

-- =====================================================
-- 2. TEMPLATE ITINERARY ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_itinerary_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.trip_templates(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  location_url TEXT,
  start_time TEXT, -- HH:mm format
  end_time TEXT,
  duration_minutes INTEGER,
  category TEXT NOT NULL DEFAULT 'activity',
  estimated_cost DOUBLE PRECISION,
  tips TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.template_itinerary_items IS 'Day-by-day itinerary items for templates';
COMMENT ON COLUMN public.template_itinerary_items.category IS 'Item category: activity, transport, food, accommodation, sightseeing';

CREATE INDEX IF NOT EXISTS idx_template_itinerary_template_id ON public.template_itinerary_items(template_id);
CREATE INDEX IF NOT EXISTS idx_template_itinerary_day ON public.template_itinerary_items(template_id, day_number);

-- =====================================================
-- 3. TEMPLATE CHECKLISTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.trip_templates(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.template_checklists IS 'Packing checklist categories for templates';

CREATE INDEX IF NOT EXISTS idx_template_checklists_template_id ON public.template_checklists(template_id);

-- =====================================================
-- 4. TEMPLATE CHECKLIST ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES public.template_checklists(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_essential BOOLEAN NOT NULL DEFAULT false,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.template_checklist_items IS 'Individual items in template checklists';
COMMENT ON COLUMN public.template_checklist_items.is_essential IS 'Whether this item is essential/must-have';
COMMENT ON COLUMN public.template_checklist_items.category IS 'Item category: clothing, toiletries, electronics, documents, misc';

CREATE INDEX IF NOT EXISTS idx_template_checklist_items_checklist_id ON public.template_checklist_items(checklist_id);

-- =====================================================
-- 5. AI USAGE TRACKING TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_usage_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  feature TEXT NOT NULL DEFAULT 'itinerary_generation',
  usage_count INTEGER NOT NULL DEFAULT 0,
  last_used_at TIMESTAMPTZ,
  monthly_limit INTEGER NOT NULL DEFAULT 5,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  premium_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, feature)
);

COMMENT ON TABLE public.ai_usage_tracking IS 'Tracks AI feature usage per user for freemium model';
COMMENT ON COLUMN public.ai_usage_tracking.monthly_limit IS 'Free tier monthly limit (default 5)';
COMMENT ON COLUMN public.ai_usage_tracking.is_premium IS 'Whether user has premium subscription';

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON public.ai_usage_tracking(user_id);

-- =====================================================
-- 6. AI GENERATION LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_generation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  feature TEXT NOT NULL DEFAULT 'itinerary_generation',
  request_data JSONB,
  response_summary TEXT,
  tokens_used INTEGER,
  generation_time_ms INTEGER,
  was_successful BOOLEAN NOT NULL DEFAULT true,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.ai_generation_logs IS 'Logs of AI generation requests for analytics and debugging';

CREATE INDEX IF NOT EXISTS idx_ai_logs_user_id ON public.ai_generation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_logs_created_at ON public.ai_generation_logs(created_at);

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.trip_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_logs ENABLE ROW LEVEL SECURITY;

-- Trip Templates: Everyone can read active templates
DROP POLICY IF EXISTS "Anyone can read active templates" ON public.trip_templates;
CREATE POLICY "Anyone can read active templates"
  ON public.trip_templates
  FOR SELECT
  USING (is_active = true);

-- Template Itinerary Items: Everyone can read
DROP POLICY IF EXISTS "Anyone can read template itinerary items" ON public.template_itinerary_items;
CREATE POLICY "Anyone can read template itinerary items"
  ON public.template_itinerary_items
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.trip_templates t
    WHERE t.id = template_id AND t.is_active = true
  ));

-- Template Checklists: Everyone can read
DROP POLICY IF EXISTS "Anyone can read template checklists" ON public.template_checklists;
CREATE POLICY "Anyone can read template checklists"
  ON public.template_checklists
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.trip_templates t
    WHERE t.id = template_id AND t.is_active = true
  ));

-- Template Checklist Items: Everyone can read
DROP POLICY IF EXISTS "Anyone can read template checklist items" ON public.template_checklist_items;
CREATE POLICY "Anyone can read template checklist items"
  ON public.template_checklist_items
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.template_checklists c
    JOIN public.trip_templates t ON t.id = c.template_id
    WHERE c.id = checklist_id AND t.is_active = true
  ));

-- AI Usage Tracking: Users can only access their own data
DROP POLICY IF EXISTS "Users can read own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can read own AI usage"
  ON public.ai_usage_tracking
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can insert own AI usage"
  ON public.ai_usage_tracking
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can update own AI usage"
  ON public.ai_usage_tracking
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- AI Generation Logs: Users can only access their own logs
DROP POLICY IF EXISTS "Users can read own AI logs" ON public.ai_generation_logs;
CREATE POLICY "Users can read own AI logs"
  ON public.ai_generation_logs
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own AI logs" ON public.ai_generation_logs;
CREATE POLICY "Users can insert own AI logs"
  ON public.ai_generation_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to increment template use count
CREATE OR REPLACE FUNCTION public.increment_template_use_count(p_template_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.trip_templates
  SET use_count = use_count + 1,
      updated_at = NOW()
  WHERE id = p_template_id;
END;
$$;

-- Function to get or create AI usage record
CREATE OR REPLACE FUNCTION public.get_or_create_ai_usage(p_user_id UUID, p_feature TEXT DEFAULT 'itinerary_generation')
RETURNS public.ai_usage_tracking
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  -- Try to get existing record
  SELECT * INTO v_usage
  FROM public.ai_usage_tracking
  WHERE user_id = p_user_id AND feature = p_feature;

  -- If not found, create new record
  IF v_usage IS NULL THEN
    INSERT INTO public.ai_usage_tracking (user_id, feature, usage_count, monthly_limit)
    VALUES (p_user_id, p_feature, 0, 5)
    RETURNING * INTO v_usage;
  END IF;

  RETURN v_usage;
END;
$$;

-- Function to increment AI usage and check limit
CREATE OR REPLACE FUNCTION public.increment_ai_usage(p_user_id UUID, p_feature TEXT DEFAULT 'itinerary_generation')
RETURNS TABLE (
  can_use BOOLEAN,
  current_count INTEGER,
  monthly_limit INTEGER,
  is_premium BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
  v_can_use BOOLEAN;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, p_feature);

  -- Reset count if new month (simple monthly reset)
  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    v_usage.usage_count := 0;
  END IF;

  -- Check if can use
  v_can_use := v_usage.is_premium OR (v_usage.usage_count < v_usage.monthly_limit);

  -- Increment if allowed
  IF v_can_use THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = usage_count + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE id = v_usage.id
    RETURNING usage_count INTO v_usage.usage_count;
  END IF;

  RETURN QUERY SELECT v_can_use, v_usage.usage_count, v_usage.monthly_limit, v_usage.is_premium;
END;
$$;

-- Function to log AI generation
CREATE OR REPLACE FUNCTION public.log_ai_generation(
  p_user_id UUID,
  p_feature TEXT,
  p_request_data JSONB,
  p_response_summary TEXT,
  p_tokens_used INTEGER DEFAULT NULL,
  p_generation_time_ms INTEGER DEFAULT NULL,
  p_was_successful BOOLEAN DEFAULT true,
  p_error_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.ai_generation_logs (
    user_id, feature, request_data, response_summary,
    tokens_used, generation_time_ms, was_successful, error_message
  ) VALUES (
    p_user_id, p_feature, p_request_data, p_response_summary,
    p_tokens_used, p_generation_time_ms, p_was_successful, p_error_message
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- Function to check if user can generate AI itinerary
CREATE OR REPLACE FUNCTION public.can_generate_ai_itinerary(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, 'itinerary_generation');

  -- Reset count if new month
  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    RETURN true;
  END IF;

  -- Premium users always can generate
  IF v_usage.is_premium THEN
    RETURN true;
  END IF;

  -- Free users check monthly limit
  RETURN v_usage.usage_count < v_usage.monthly_limit;
END;
$$;

-- Function to get remaining AI generations
CREATE OR REPLACE FUNCTION public.get_remaining_ai_generations(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, 'itinerary_generation');

  -- Reset count if new month
  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    v_usage.usage_count := 0;
  END IF;

  -- Premium users return -1 (unlimited)
  IF v_usage.is_premium THEN
    RETURN -1;
  END IF;

  -- Free users return remaining count
  RETURN GREATEST(0, v_usage.monthly_limit - v_usage.usage_count);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.increment_template_use_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_ai_generation TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_generate_ai_itinerary TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_remaining_ai_generations TO authenticated;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to trip_templates
DROP TRIGGER IF EXISTS update_trip_templates_updated_at ON public.trip_templates;
CREATE TRIGGER update_trip_templates_updated_at
  BEFORE UPDATE ON public.trip_templates
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Apply trigger to ai_usage_tracking
DROP TRIGGER IF EXISTS update_ai_usage_updated_at ON public.ai_usage_tracking;
CREATE TRIGGER update_ai_usage_updated_at
  BEFORE UPDATE ON public.ai_usage_tracking
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created tables:
-- 1. trip_templates - Main template storage
-- 2. template_itinerary_items - Day activities
-- 3. template_checklists - Checklist categories
-- 4. template_checklist_items - Checklist items
-- 5. ai_usage_tracking - Freemium usage tracking
-- 6. ai_generation_logs - AI request logs
--
-- Created functions:
-- - increment_template_use_count
-- - get_or_create_ai_usage
-- - increment_ai_usage
-- - log_ai_generation
-- =====================================================


-- ============================================
-- Migration: 20251204_group_chat_fix.sql
-- ============================================

-- Migration: Group Chat Feature - FIX
-- Date: 2025-12-04
-- Description: Fix for partial migration - drops existing policies and recreates

-- ============================================================================
-- DROP EXISTING POLICIES (if they exist from partial migration)
-- ============================================================================

DROP POLICY IF EXISTS "Users can view conversations they are members of" ON public.conversations;
DROP POLICY IF EXISTS "Trip members can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;
DROP POLICY IF EXISTS "Conversation admins can delete conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can view conversation members" ON public.conversation_members;
DROP POLICY IF EXISTS "Conversation admins can add members" ON public.conversation_members;
DROP POLICY IF EXISTS "Users can update their own membership" ON public.conversation_members;
DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_members;
DROP POLICY IF EXISTS "Conversation admins can remove members" ON public.conversation_members;

-- ============================================================================
-- CONVERSATIONS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_direct_message BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.conversations IS 'Group chat conversations within trips';
COMMENT ON COLUMN public.conversations.is_direct_message IS 'True for 1:1 direct messages, false for group chats';

-- ============================================================================
-- CONVERSATION_MEMBERS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_muted BOOLEAN DEFAULT false,
    last_read_at TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);

COMMENT ON TABLE public.conversation_members IS 'Members of group chat conversations';
COMMENT ON COLUMN public.conversation_members.role IS 'Member role: admin or member';
COMMENT ON COLUMN public.conversation_members.is_muted IS 'Whether notifications are muted for this member';
COMMENT ON COLUMN public.conversation_members.last_read_at IS 'Timestamp of last read message for unread count';

-- ============================================================================
-- UPDATE MESSAGES TABLE
-- ============================================================================

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;

COMMENT ON COLUMN public.messages.conversation_id IS 'Optional conversation reference for group chats. NULL for legacy trip-wide messages.';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_conversations_trip ON public.conversations(trip_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_user ON public.conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC)
WHERE conversation_id IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;

-- Conversations: Users can view conversations they are members of
DROP POLICY IF EXISTS "Users can view conversations they are members of" ON public.conversations;
CREATE POLICY "Users can view conversations they are members of"
ON public.conversations
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
    )
    OR created_by = auth.uid()
);

-- Conversations: Trip members can create conversations
DROP POLICY IF EXISTS "Trip members can create conversations" ON public.conversations;
CREATE POLICY "Trip members can create conversations"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = conversations.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

-- Conversations: Admins can update conversations
DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;
CREATE POLICY "Conversation admins can update conversations"
ON public.conversations
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
    OR created_by = auth.uid()
);

-- Conversations: Admins can delete conversations
DROP POLICY IF EXISTS "Conversation admins can delete conversations" ON public.conversations;
CREATE POLICY "Conversation admins can delete conversations"
ON public.conversations
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
    OR created_by = auth.uid()
);

-- Conversation Members: Users can view members of conversations they belong to
DROP POLICY IF EXISTS "Users can view conversation members" ON public.conversation_members;
CREATE POLICY "Users can view conversation members"
ON public.conversation_members
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- Conversation Members: Creator or Admins can add members
DROP POLICY IF EXISTS "Conversation admins can add members" ON public.conversation_members;
CREATE POLICY "Conversation admins can add members"
ON public.conversation_members
FOR INSERT
TO authenticated
WITH CHECK (
    -- Creator can always add members (especially for initial member setup)
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
    OR
    -- Existing admins can add members
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR
    -- Users can add themselves if they're trip members
    (
        conversation_members.user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.conversations c
            JOIN public.trip_members tm ON tm.trip_id = c.trip_id
            WHERE c.id = conversation_members.conversation_id
            AND tm.user_id = auth.uid()
        )
    )
);

-- Conversation Members: Users can update their own membership (mute, last_read)
DROP POLICY IF EXISTS "Users can update their own membership" ON public.conversation_members;
CREATE POLICY "Users can update their own membership"
ON public.conversation_members
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Conversation Members: Users can leave conversations (delete their membership)
DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_members;
CREATE POLICY "Users can leave conversations"
ON public.conversation_members
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Conversation Members: Admins can remove members
DROP POLICY IF EXISTS "Conversation admins can remove members" ON public.conversation_members;
CREATE POLICY "Conversation admins can remove members"
ON public.conversation_members
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS conversations_updated_at_trigger ON public.conversations;
CREATE TRIGGER conversations_updated_at_trigger
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_conversations_updated_at();

CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    ORDER BY last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION find_existing_dm(
    p_trip_id UUID,
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND c.is_direct_message = true
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm1
        WHERE cm1.conversation_id = c.id AND cm1.user_id = p_user1_id
    )
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm2
        WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user2_id
    )
    AND (
        SELECT COUNT(*) FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id
    ) = 2
    LIMIT 1;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_members TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION find_existing_dm TO authenticated;


-- ============================================
-- Migration: 20251204_seed_trip_templates.sql
-- ============================================

-- =====================================================
-- SEED DATA: Trip Templates
-- =====================================================
-- This file contains 10 pre-built trip templates for
-- popular Indian destinations with detailed itineraries
-- and packing checklists.
-- =====================================================

-- =====================================================
-- 1. GOA BEACH VACATION (3 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Goa Beach Getaway',
  'Experience the perfect beach vacation in Goa with stunning beaches, vibrant nightlife, and delicious seafood. Visit iconic churches, enjoy water sports, and relax by the Arabian Sea.',
  'Goa',
  'Goa',
  3,
  15000,
  35000,
  'INR',
  'beach',
  ARRAY['beach', 'party', 'seafood', 'water-sports', 'nightlife'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  true
);

-- Get the template ID for Goa
DO $$
DECLARE
  goa_template_id UUID;
BEGIN
  SELECT id INTO goa_template_id FROM public.trip_templates WHERE name = 'Goa Beach Getaway';

  -- Day 1 Itinerary
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (goa_template_id, 1, 1, 'Arrive at Goa Airport', 'Land at Dabolim Airport and transfer to your hotel in North Goa', 'Dabolim Airport', 'transport', '10:00', 500, 'Pre-book airport transfer for better rates'),
  (goa_template_id, 1, 2, 'Check-in & Freshen Up', 'Check into your beach resort and freshen up', 'Calangute/Baga', 'accommodation', '12:00', 3000, 'Choose hotels near the beach for convenience'),
  (goa_template_id, 1, 3, 'Lunch at Beach Shack', 'Enjoy fresh seafood at a beach shack', 'Baga Beach', 'food', '13:30', 800, 'Try the fish curry rice - a Goan specialty'),
  (goa_template_id, 1, 4, 'Calangute Beach', 'Relax at Goa''s most popular beach, enjoy water sports', 'Calangute Beach', 'activity', '15:00', 1500, 'Best time for parasailing is afternoon'),
  (goa_template_id, 1, 5, 'Sunset at Baga Beach', 'Watch the beautiful sunset and enjoy beach activities', 'Baga Beach', 'sightseeing', '17:30', 0, 'Grab a beer and watch the sunset'),
  (goa_template_id, 1, 6, 'Dinner & Nightlife', 'Experience Goa''s famous nightlife at Tito''s Lane', 'Tito''s Lane, Baga', 'food', '20:00', 2000, 'Weekends are more crowded but more fun');

  -- Day 2 Itinerary
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (goa_template_id, 2, 1, 'Breakfast at Cafe', 'Start with a hearty breakfast at a beach cafe', 'Anjuna', 'food', '09:00', 400, 'Try the Goan pork sausage breakfast'),
  (goa_template_id, 2, 2, 'Old Goa Churches', 'Visit UNESCO heritage churches including Basilica of Bom Jesus', 'Old Goa', 'sightseeing', '10:30', 0, 'Dress modestly for church visits'),
  (goa_template_id, 2, 3, 'Lunch in Panjim', 'Authentic Goan thali at a local restaurant', 'Panjim', 'food', '13:00', 500, 'Try Ritz Classic for authentic Goan food'),
  (goa_template_id, 2, 4, 'Fontainhas Latin Quarter', 'Walk through the colorful Portuguese streets', 'Fontainhas, Panjim', 'sightseeing', '14:30', 0, 'Great for photography'),
  (goa_template_id, 2, 5, 'Anjuna Beach', 'Explore the famous flea market beach', 'Anjuna Beach', 'activity', '16:30', 500, 'Flea market is on Wednesdays'),
  (goa_template_id, 2, 6, 'Curlies Beach Club', 'Dinner and chill music at the iconic beach club', 'Anjuna', 'food', '19:00', 1500, 'Great for sunset and live music');

  -- Day 3 Itinerary
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (goa_template_id, 3, 1, 'Breakfast & Checkout', 'Pack up and checkout from hotel', 'Hotel', 'accommodation', '09:00', 400, 'Keep luggage at hotel if late flight'),
  (goa_template_id, 3, 2, 'Vagator Beach & Chapora Fort', 'Visit the Dil Chahta Hai fort and scenic beach', 'Vagator', 'sightseeing', '10:30', 0, 'Best views from the fort'),
  (goa_template_id, 3, 3, 'Lunch at Thalassa', 'Greek food with stunning cliff views', 'Vagator', 'food', '13:00', 1500, 'Book in advance for cliff-side table'),
  (goa_template_id, 3, 4, 'Souvenir Shopping', 'Buy cashews, feni, and local crafts', 'Mapusa Market', 'activity', '15:00', 2000, 'Bargain for better prices'),
  (goa_template_id, 3, 5, 'Depart from Airport', 'Transfer to airport for departure', 'Dabolim Airport', 'transport', '17:00', 500, 'Reach 2 hours before flight');

  -- Goa Packing Checklist
  INSERT INTO public.template_checklists (template_id, name, icon, order_index) VALUES
  (goa_template_id, 'Beach Essentials', 'beach_access', 1);

  INSERT INTO public.template_checklist_items (checklist_id, content, order_index, is_essential, category)
  SELECT c.id, item.content, item.order_index, item.is_essential, item.category
  FROM public.template_checklists c
  CROSS JOIN (VALUES
    ('Swimsuit/Beachwear', 1, true, 'clothing'),
    ('Sunscreen SPF 50+', 2, true, 'toiletries'),
    ('Sunglasses', 3, true, 'misc'),
    ('Beach towel', 4, false, 'misc'),
    ('Flip flops/Sandals', 5, true, 'clothing'),
    ('Light cotton clothes', 6, true, 'clothing'),
    ('Hat/Cap', 7, false, 'clothing'),
    ('Waterproof phone pouch', 8, false, 'electronics'),
    ('After-sun lotion', 9, false, 'toiletries'),
    ('Insect repellent', 10, false, 'toiletries')
  ) AS item(content, order_index, is_essential, category)
  WHERE c.template_id = goa_template_id AND c.name = 'Beach Essentials';

  INSERT INTO public.template_checklists (template_id, name, icon, order_index) VALUES
  (goa_template_id, 'Documents & Money', 'article', 2);

  INSERT INTO public.template_checklist_items (checklist_id, content, order_index, is_essential, category)
  SELECT c.id, item.content, item.order_index, item.is_essential, item.category
  FROM public.template_checklists c
  CROSS JOIN (VALUES
    ('ID Card (Aadhar/Passport)', 1, true, 'documents'),
    ('Flight tickets', 2, true, 'documents'),
    ('Hotel booking confirmation', 3, true, 'documents'),
    ('Debit/Credit cards', 4, true, 'documents'),
    ('Some cash for local shops', 5, true, 'documents'),
    ('Travel insurance details', 6, false, 'documents')
  ) AS item(content, order_index, is_essential, category)
  WHERE c.template_id = goa_template_id AND c.name = 'Documents & Money';
END $$;

-- =====================================================
-- 2. RAJASTHAN HERITAGE TOUR (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Royal Rajasthan Heritage Tour',
  'Explore the magnificent forts, palaces, and rich culture of Rajasthan. From the Pink City of Jaipur to the Blue City of Jodhpur, experience royal India.',
  'Jaipur - Jodhpur - Udaipur',
  'Rajasthan',
  5,
  25000,
  60000,
  'INR',
  'heritage',
  ARRAY['forts', 'palaces', 'culture', 'history', 'photography'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  true
);

DO $$
DECLARE
  rajasthan_template_id UUID;
BEGIN
  SELECT id INTO rajasthan_template_id FROM public.trip_templates WHERE name = 'Royal Rajasthan Heritage Tour';

  -- Day 1: Jaipur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 1, 1, 'Arrive in Jaipur', 'Land at Jaipur Airport, transfer to hotel', 'Jaipur Airport', 'transport', '10:00', 600, 'Book hotel near City Palace for convenience'),
  (rajasthan_template_id, 1, 2, 'Hawa Mahal', 'Visit the iconic Palace of Winds', 'Hawa Mahal', 'sightseeing', '14:00', 50, 'Best photos from the opposite cafe'),
  (rajasthan_template_id, 1, 3, 'City Palace', 'Explore the magnificent royal residence', 'City Palace, Jaipur', 'sightseeing', '15:30', 500, 'Hire a guide for detailed history'),
  (rajasthan_template_id, 1, 4, 'Jantar Mantar', 'UNESCO World Heritage astronomical site', 'Jantar Mantar', 'sightseeing', '17:00', 200, 'Amazing ancient scientific instruments'),
  (rajasthan_template_id, 1, 5, 'Dinner at Chokhi Dhani', 'Traditional Rajasthani village experience', 'Chokhi Dhani', 'food', '19:30', 1500, 'Book in advance, great cultural show');

  -- Day 2: Jaipur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 2, 1, 'Amber Fort', 'Explore the majestic fort with elephant ride option', 'Amber Fort', 'sightseeing', '09:00', 500, 'Go early to avoid crowds and heat'),
  (rajasthan_template_id, 2, 2, 'Jal Mahal (Photo Stop)', 'View the Water Palace from the shore', 'Jal Mahal', 'sightseeing', '12:00', 0, 'Entry not allowed, but great views'),
  (rajasthan_template_id, 2, 3, 'Lunch at 1135 AD', 'Royal dining inside Amber Fort', '1135 AD Restaurant', 'food', '13:00', 1200, 'Try the Laal Maas'),
  (rajasthan_template_id, 2, 4, 'Nahargarh Fort', 'Sunset point with city views', 'Nahargarh Fort', 'sightseeing', '16:00', 200, 'Perfect for sunset photography'),
  (rajasthan_template_id, 2, 5, 'Johari Bazaar Shopping', 'Shop for gems, jewelry, and textiles', 'Johari Bazaar', 'activity', '18:30', 2000, 'Bargain hard, fixed price shops available');

  -- Day 3: Jaipur to Jodhpur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 3, 1, 'Drive to Jodhpur', 'Scenic 5-hour drive through Rajasthan', 'Highway', 'transport', '07:00', 4000, 'Hire a driver, stop at Ajmer if time permits'),
  (rajasthan_template_id, 3, 2, 'Check-in Jodhpur', 'Rest at heritage haveli', 'Jodhpur', 'accommodation', '13:00', 3500, 'Stay in the old city for authentic experience'),
  (rajasthan_template_id, 3, 3, 'Mehrangarh Fort', 'One of India''s largest forts', 'Mehrangarh Fort', 'sightseeing', '15:00', 600, 'Audio guide highly recommended'),
  (rajasthan_template_id, 3, 4, 'Blue City Walk', 'Walk through blue-painted houses', 'Old Jodhpur', 'sightseeing', '17:30', 0, 'Best views from the fort'),
  (rajasthan_template_id, 3, 5, 'Dinner at Indique', 'Rooftop dining with fort views', 'Indique Restaurant', 'food', '19:30', 1500, 'Book rooftop table in advance');

  -- Day 4: Jodhpur to Udaipur
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 4, 1, 'Jaswant Thada', 'Beautiful marble cenotaph', 'Jaswant Thada', 'sightseeing', '08:00', 50, 'Peaceful early morning visit'),
  (rajasthan_template_id, 4, 2, 'Drive to Udaipur', '5-hour scenic drive via Ranakpur', 'Highway', 'transport', '10:00', 4000, 'Stop at Ranakpur Jain Temple'),
  (rajasthan_template_id, 4, 3, 'Ranakpur Jain Temple', 'Intricate 1444-pillar marble temple', 'Ranakpur', 'sightseeing', '12:30', 0, 'Remove leather items before entry'),
  (rajasthan_template_id, 4, 4, 'Arrive Udaipur', 'Check-in to lakeside hotel', 'Udaipur', 'accommodation', '17:00', 4000, 'Stay near Lake Pichola'),
  (rajasthan_template_id, 4, 5, 'Lake Pichola Sunset', 'Boat ride during sunset', 'Lake Pichola', 'activity', '18:00', 800, 'Book through hotel for better rates');

  -- Day 5: Udaipur & Departure
  INSERT INTO public.template_itinerary_items (template_id, day_number, order_index, title, description, location, category, start_time, estimated_cost, tips) VALUES
  (rajasthan_template_id, 5, 1, 'City Palace Udaipur', 'Explore the largest palace complex in Rajasthan', 'City Palace, Udaipur', 'sightseeing', '09:00', 300, 'Start from museum section'),
  (rajasthan_template_id, 5, 2, 'Jagdish Temple', 'Beautiful Indo-Aryan temple', 'Jagdish Temple', 'sightseeing', '11:30', 0, 'Active temple, witness aarti'),
  (rajasthan_template_id, 5, 3, 'Lunch & Shopping', 'Local cuisine and handicrafts', 'Hathi Pol Bazaar', 'food', '12:30', 1500, 'Great for miniature paintings'),
  (rajasthan_template_id, 5, 4, 'Departure', 'Transfer to airport/station', 'Udaipur', 'transport', '15:00', 500, 'Udaipur airport is 25km from city');

  -- Rajasthan Packing Checklist
  INSERT INTO public.template_checklists (template_id, name, icon, order_index) VALUES
  (rajasthan_template_id, 'Heritage Tour Essentials', 'castle', 1);

  INSERT INTO public.template_checklist_items (checklist_id, content, order_index, is_essential, category)
  SELECT c.id, item.content, item.order_index, item.is_essential, item.category
  FROM public.template_checklists c
  CROSS JOIN (VALUES
    ('Comfortable walking shoes', 1, true, 'clothing'),
    ('Light cotton clothes', 2, true, 'clothing'),
    ('Scarf/Stole for temples', 3, true, 'clothing'),
    ('Sunscreen SPF 50+', 4, true, 'toiletries'),
    ('Sunglasses', 5, true, 'misc'),
    ('Hat/Cap', 6, true, 'clothing'),
    ('Water bottle', 7, true, 'misc'),
    ('Camera with extra batteries', 8, false, 'electronics'),
    ('Power bank', 9, true, 'electronics'),
    ('Light jacket (winter months)', 10, false, 'clothing'),
    ('Moisturizer (dry climate)', 11, false, 'toiletries')
  ) AS item(content, order_index, is_essential, category)
  WHERE c.template_id = rajasthan_template_id AND c.name = 'Heritage Tour Essentials';
END $$;

-- =====================================================
-- 3. KERALA BACKWATERS (4 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Kerala Backwaters & Hills',
  'Experience God''s Own Country with serene backwaters, lush tea gardens, and pristine beaches. A perfect blend of relaxation and natural beauty.',
  'Kochi - Alleppey - Munnar',
  'Kerala',
  4,
  20000,
  45000,
  'INR',
  'family',
  ARRAY['backwaters', 'houseboat', 'tea-gardens', 'nature', 'ayurveda'],
  ARRAY['September', 'October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  true
);

-- =====================================================
-- 4. HIMACHAL ADVENTURE (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Himachal Mountains Adventure',
  'From Shimla''s colonial charm to Manali''s adventure sports, experience the majestic Himalayas. Perfect for adventure seekers and nature lovers.',
  'Shimla - Manali',
  'Himachal Pradesh',
  5,
  20000,
  50000,
  'INR',
  'adventure',
  ARRAY['mountains', 'trekking', 'snow', 'adventure', 'paragliding'],
  ARRAY['March', 'April', 'May', 'June', 'September', 'October'],
  'moderate',
  true,
  true
);

-- =====================================================
-- 5. VARANASI SPIRITUAL (3 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Varanasi Spiritual Journey',
  'Experience the spiritual heart of India. Witness the mesmerizing Ganga Aarti, explore ancient temples, and discover the city''s timeless traditions.',
  'Varanasi',
  'Uttar Pradesh',
  3,
  10000,
  25000,
  'INR',
  'pilgrimage',
  ARRAY['spiritual', 'temples', 'ganga', 'culture', 'photography'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  false
);

-- =====================================================
-- 6. ANDAMAN ISLANDS (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Andaman Island Paradise',
  'Discover pristine beaches, crystal-clear waters, and vibrant coral reefs. Perfect for beach lovers, snorkeling enthusiasts, and history buffs.',
  'Port Blair - Havelock - Neil Island',
  'Andaman & Nicobar',
  5,
  35000,
  80000,
  'INR',
  'beach',
  ARRAY['island', 'snorkeling', 'scuba', 'beaches', 'coral-reefs'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March', 'April', 'May'],
  'easy',
  true,
  true
);

-- =====================================================
-- 7. LADAKH ROAD TRIP (7 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Ladakh - The Ultimate Road Trip',
  'Conquer the world''s highest motorable passes, witness stunning landscapes, and experience the unique Ladakhi culture. An adventure of a lifetime.',
  'Leh - Nubra - Pangong',
  'Ladakh',
  7,
  40000,
  100000,
  'INR',
  'roadTrip',
  ARRAY['road-trip', 'high-altitude', 'monasteries', 'lakes', 'adventure'],
  ARRAY['June', 'July', 'August', 'September'],
  'difficult',
  true,
  true
);

-- =====================================================
-- 8. DARJEELING & SIKKIM (5 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Darjeeling & Sikkim Hills',
  'From world-famous tea gardens to views of Kanchenjunga, explore the enchanting hill stations of Eastern Himalayas.',
  'Darjeeling - Gangtok',
  'West Bengal & Sikkim',
  5,
  25000,
  55000,
  'INR',
  'hillStation',
  ARRAY['tea-gardens', 'mountains', 'toy-train', 'monasteries', 'nature'],
  ARRAY['March', 'April', 'May', 'September', 'October', 'November'],
  'moderate',
  true,
  false
);

-- =====================================================
-- 9. KARNATAKA WILDLIFE (4 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Karnataka Wildlife Safari',
  'Experience India''s rich wildlife at Bandipur and Nagarhole. Spot tigers, elephants, leopards, and diverse bird species in their natural habitat.',
  'Mysore - Bandipur - Nagarhole',
  'Karnataka',
  4,
  30000,
  70000,
  'INR',
  'wildlife',
  ARRAY['safari', 'tigers', 'elephants', 'birds', 'nature'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March', 'April', 'May', 'June'],
  'easy',
  true,
  false
);

-- =====================================================
-- 10. PONDICHERRY WEEKEND (2 Days)
-- =====================================================
INSERT INTO public.trip_templates (
  name, description, destination, destination_state, duration_days,
  budget_min, budget_max, currency, category, tags, best_season,
  difficulty_level, is_active, is_featured
) VALUES (
  'Pondicherry French Escape',
  'A perfect weekend getaway to India''s French Quarter. Explore colorful streets, pristine beaches, spiritual ashrams, and delightful cafes.',
  'Pondicherry',
  'Puducherry',
  2,
  8000,
  20000,
  'INR',
  'weekend',
  ARRAY['french-quarter', 'beaches', 'cafes', 'ashram', 'cycling'],
  ARRAY['October', 'November', 'December', 'January', 'February', 'March'],
  'easy',
  true,
  false
);

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created 10 trip templates:
-- 1. Goa Beach Getaway (3 days, Featured)
-- 2. Royal Rajasthan Heritage Tour (5 days, Featured)
-- 3. Kerala Backwaters & Hills (4 days, Featured)
-- 4. Himachal Mountains Adventure (5 days, Featured)
-- 5. Varanasi Spiritual Journey (3 days)
-- 6. Andaman Island Paradise (5 days, Featured)
-- 7. Ladakh - The Ultimate Road Trip (7 days, Featured)
-- 8. Darjeeling & Sikkim Hills (5 days)
-- 9. Karnataka Wildlife Safari (4 days)
-- 10. Pondicherry French Escape (2 days)
-- =====================================================


-- ============================================
-- Migration: 20251204_trip_templates.sql
-- ============================================

-- =====================================================
-- Trip Templates System
-- =====================================================
-- This migration creates the trip templates system that allows:
-- 1. Pre-built trip templates for popular destinations
-- 2. Template itineraries with day-by-day activities
-- 3. Template checklists with packing items
-- 4. AI usage tracking for freemium model
-- =====================================================

-- =====================================================
-- TRIP TEMPLATES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.trip_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  destination TEXT NOT NULL,
  destination_state TEXT, -- For Indian states
  duration_days INTEGER NOT NULL,
  budget_min DECIMAL(12, 2),
  budget_max DECIMAL(12, 2),
  currency TEXT DEFAULT 'INR',
  cover_image_url TEXT,
  category TEXT NOT NULL DEFAULT 'adventure', -- adventure, pilgrimage, beach, hill_station, heritage, wildlife, honeymoon, family
  tags TEXT[] DEFAULT '{}', -- Array of tags for filtering
  best_season TEXT[], -- Array of months: ['October', 'November', 'December']
  difficulty_level TEXT DEFAULT 'easy', -- easy, moderate, difficult
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  use_count INTEGER DEFAULT 0, -- Track popularity
  rating DECIMAL(2, 1) DEFAULT 0, -- Average rating from users
  rating_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_trip_templates_destination ON public.trip_templates(destination);
CREATE INDEX IF NOT EXISTS idx_trip_templates_category ON public.trip_templates(category);
CREATE INDEX IF NOT EXISTS idx_trip_templates_duration ON public.trip_templates(duration_days);
CREATE INDEX IF NOT EXISTS idx_trip_templates_active ON public.trip_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_trip_templates_featured ON public.trip_templates(is_featured);

-- =====================================================
-- TEMPLATE ITINERARY ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_itinerary_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES public.trip_templates(id) ON DELETE CASCADE NOT NULL,
  day_number INTEGER NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  location_url TEXT, -- Google Maps URL
  start_time TIME, -- Suggested start time
  end_time TIME,
  duration_minutes INTEGER,
  category TEXT DEFAULT 'activity', -- activity, transport, food, accommodation, sightseeing
  estimated_cost DECIMAL(10, 2),
  tips TEXT, -- Local tips for this activity
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_template_itinerary_template ON public.template_itinerary_items(template_id);
CREATE INDEX IF NOT EXISTS idx_template_itinerary_day ON public.template_itinerary_items(template_id, day_number);

-- =====================================================
-- TEMPLATE CHECKLISTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_id UUID REFERENCES public.trip_templates(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  icon TEXT DEFAULT 'checklist', -- Icon identifier
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_template_checklists_template ON public.template_checklists(template_id);

-- =====================================================
-- TEMPLATE CHECKLIST ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.template_checklist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  checklist_id UUID REFERENCES public.template_checklists(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_essential BOOLEAN DEFAULT false, -- Mark must-have items
  category TEXT, -- clothing, documents, electronics, toiletries, medicines, misc
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_template_checklist_items_checklist ON public.template_checklist_items(checklist_id);

-- =====================================================
-- AI USAGE TRACKING TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_ai_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  ai_generations_used INTEGER DEFAULT 0,
  ai_generations_limit INTEGER DEFAULT 5, -- Free tier limit
  is_premium BOOLEAN DEFAULT false,
  premium_plan TEXT, -- 'monthly', 'annual', null for free
  premium_started_at TIMESTAMPTZ,
  premium_expires_at TIMESTAMPTZ,
  lifetime_generations INTEGER DEFAULT 0, -- Total ever generated
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_ai_usage_user ON public.user_ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_user_ai_usage_premium ON public.user_ai_usage(is_premium);

-- =====================================================
-- AI GENERATION LOGS TABLE (For analytics)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_generation_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  destination TEXT NOT NULL,
  duration_days INTEGER NOT NULL,
  budget DECIMAL(12, 2),
  interests TEXT[], -- User selected interests
  trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL, -- If applied to a trip
  generation_time_ms INTEGER, -- How long it took
  was_successful BOOLEAN DEFAULT true,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_generation_logs_user ON public.ai_generation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_generation_logs_destination ON public.ai_generation_logs(destination);
CREATE INDEX IF NOT EXISTS idx_ai_generation_logs_date ON public.ai_generation_logs(created_at);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.trip_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_logs ENABLE ROW LEVEL SECURITY;

-- Trip templates are public read
DROP POLICY IF EXISTS "Anyone can view active templates" ON public.trip_templates;
CREATE POLICY "Anyone can view active templates"
ON public.trip_templates FOR SELECT
USING (is_active = true);

-- Template itinerary items are public read
DROP POLICY IF EXISTS "Anyone can view template itinerary items" ON public.template_itinerary_items;
CREATE POLICY "Anyone can view template itinerary items"
ON public.template_itinerary_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_templates
    WHERE trip_templates.id = template_itinerary_items.template_id
    AND trip_templates.is_active = true
  )
);

-- Template checklists are public read
DROP POLICY IF EXISTS "Anyone can view template checklists" ON public.template_checklists;
CREATE POLICY "Anyone can view template checklists"
ON public.template_checklists FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_templates
    WHERE trip_templates.id = template_checklists.template_id
    AND trip_templates.is_active = true
  )
);

-- Template checklist items are public read
DROP POLICY IF EXISTS "Anyone can view template checklist items" ON public.template_checklist_items;
CREATE POLICY "Anyone can view template checklist items"
ON public.template_checklist_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.template_checklists tc
    JOIN public.trip_templates t ON t.id = tc.template_id
    WHERE tc.id = template_checklist_items.checklist_id
    AND t.is_active = true
  )
);

-- Users can only see their own AI usage
DROP POLICY IF EXISTS "Users can view own AI usage" ON public.user_ai_usage;
CREATE POLICY "Users can view own AI usage"
ON public.user_ai_usage FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own AI usage" ON public.user_ai_usage;
CREATE POLICY "Users can insert own AI usage"
ON public.user_ai_usage FOR INSERT
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own AI usage" ON public.user_ai_usage;
CREATE POLICY "Users can update own AI usage"
ON public.user_ai_usage FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can only see their own generation logs
DROP POLICY IF EXISTS "Users can view own generation logs" ON public.ai_generation_logs;
CREATE POLICY "Users can view own generation logs"
ON public.ai_generation_logs FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own generation logs" ON public.ai_generation_logs;
CREATE POLICY "Users can insert own generation logs"
ON public.ai_generation_logs FOR INSERT
WITH CHECK (user_id = auth.uid());

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to get or create user AI usage record
CREATE OR REPLACE FUNCTION public.get_or_create_ai_usage(p_user_id UUID)
RETURNS public.user_ai_usage AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Try to get existing record
  SELECT * INTO v_usage
  FROM public.user_ai_usage
  WHERE user_id = p_user_id;

  -- If not found, create new record
  IF NOT FOUND THEN
    INSERT INTO public.user_ai_usage (user_id)
    VALUES (p_user_id)
    RETURNING * INTO v_usage;
  END IF;

  RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment AI usage
CREATE OR REPLACE FUNCTION public.increment_ai_usage(p_user_id UUID)
RETURNS public.user_ai_usage AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id);

  -- Update the usage count
  UPDATE public.user_ai_usage
  SET
    ai_generations_used = ai_generations_used + 1,
    lifetime_generations = lifetime_generations + 1,
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING * INTO v_usage;

  RETURN v_usage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can generate AI itinerary
CREATE OR REPLACE FUNCTION public.can_generate_ai_itinerary(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id);

  -- Premium users with valid subscription can always generate
  IF v_usage.is_premium AND v_usage.premium_expires_at > NOW() THEN
    RETURN true;
  END IF;

  -- Free users check against limit
  RETURN v_usage.ai_generations_used < v_usage.ai_generations_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get remaining AI generations
CREATE OR REPLACE FUNCTION public.get_remaining_ai_generations(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_usage public.user_ai_usage;
BEGIN
  -- Get or create usage record
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id);

  -- Premium users get -1 (unlimited)
  IF v_usage.is_premium AND v_usage.premium_expires_at > NOW() THEN
    RETURN -1;
  END IF;

  -- Free users get remaining count
  RETURN GREATEST(0, v_usage.ai_generations_limit - v_usage.ai_generations_used);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment template use count
CREATE OR REPLACE FUNCTION public.increment_template_use_count(p_template_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.trip_templates
  SET use_count = use_count + 1
  WHERE id = p_template_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to apply template to trip
CREATE OR REPLACE FUNCTION public.apply_template_to_trip(
  p_template_id UUID,
  p_trip_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_template public.trip_templates;
  v_itinerary_item RECORD;
  v_checklist RECORD;
  v_checklist_item RECORD;
  v_new_checklist_id UUID;
  v_trip_start_date DATE;
BEGIN
  -- Get template
  SELECT * INTO v_template
  FROM public.trip_templates
  WHERE id = p_template_id AND is_active = true;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Get trip start date
  SELECT start_date::DATE INTO v_trip_start_date
  FROM public.trips
  WHERE id = p_trip_id;

  -- Copy itinerary items
  FOR v_itinerary_item IN
    SELECT * FROM public.template_itinerary_items
    WHERE template_id = p_template_id
    ORDER BY day_number, order_index
  LOOP
    INSERT INTO public.itinerary_items (
      trip_id,
      day_number,
      order_index,
      title,
      description,
      location,
      start_time,
      end_time,
      created_by
    ) VALUES (
      p_trip_id,
      v_itinerary_item.day_number,
      v_itinerary_item.order_index,
      v_itinerary_item.title,
      v_itinerary_item.description,
      v_itinerary_item.location,
      -- Convert time to timestamp using trip start date + day offset
      CASE WHEN v_itinerary_item.start_time IS NOT NULL
        THEN (v_trip_start_date + (v_itinerary_item.day_number - 1) * INTERVAL '1 day' + v_itinerary_item.start_time)::TIMESTAMPTZ
        ELSE NULL
      END,
      CASE WHEN v_itinerary_item.end_time IS NOT NULL
        THEN (v_trip_start_date + (v_itinerary_item.day_number - 1) * INTERVAL '1 day' + v_itinerary_item.end_time)::TIMESTAMPTZ
        ELSE NULL
      END,
      p_user_id
    );
  END LOOP;

  -- Copy checklists
  FOR v_checklist IN
    SELECT * FROM public.template_checklists
    WHERE template_id = p_template_id
    ORDER BY order_index
  LOOP
    INSERT INTO public.checklists (trip_id, name, created_by)
    VALUES (p_trip_id, v_checklist.name, p_user_id)
    RETURNING id INTO v_new_checklist_id;

    -- Copy checklist items
    FOR v_checklist_item IN
      SELECT * FROM public.template_checklist_items
      WHERE checklist_id = v_checklist.id
      ORDER BY order_index
    LOOP
      INSERT INTO public.checklist_items (checklist_id, content, is_completed)
      VALUES (v_new_checklist_id, v_checklist_item.content, false);
    END LOOP;
  END LOOP;

  -- Increment template use count
  PERFORM public.increment_template_use_count(p_template_id);

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_or_create_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_generate_ai_itinerary TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_remaining_ai_generations TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_template_use_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_template_to_trip TO authenticated;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Tables created:
-- - trip_templates: Pre-built trip templates
-- - template_itinerary_items: Day-by-day activities for templates
-- - template_checklists: Packing lists for templates
-- - template_checklist_items: Items in template checklists
-- - user_ai_usage: Track AI generation usage per user
-- - ai_generation_logs: Log each AI generation for analytics
--
-- Functions created:
-- - get_or_create_ai_usage: Get/create user AI usage record
-- - increment_ai_usage: Increment user's AI usage count
-- - can_generate_ai_itinerary: Check if user can generate
-- - get_remaining_ai_generations: Get remaining free generations
-- - increment_template_use_count: Track template popularity
-- - apply_template_to_trip: Copy template to user's trip
-- =====================================================


-- ============================================
-- Migration: 20251205_dm_display_name.sql
-- ============================================

-- Migration: DM Display Name
-- Date: 2025-12-05
-- Description: Update conversation functions to return the other member's name for DMs

-- ============================================================================
-- UPDATE get_trip_conversations FUNCTION
-- ============================================================================
-- Add dm_other_member_name column that returns the other member's name for DMs

DROP FUNCTION IF EXISTS get_trip_conversations(UUID, UUID);

CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        -- For DMs, get the other member's name (not the current user)
        CASE WHEN c.is_direct_message THEN
            (SELECT p.full_name FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_name,
        -- For DMs, get the other member's avatar
        CASE WHEN c.is_direct_message THEN
            (SELECT p.avatar_url FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    ORDER BY last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- UPDATE get_conversation_with_details FUNCTION
-- ============================================================================
-- Add dm_other_member_name column for consistency

DROP FUNCTION IF EXISTS get_conversation_with_details(UUID, UUID);

CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        -- For DMs, get the other member's name
        CASE WHEN c.is_direct_message THEN
            (SELECT p.full_name FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_name,
        -- For DMs, get the other member's avatar
        CASE WHEN c.is_direct_message THEN
            (SELECT p.avatar_url FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;


-- ============================================
-- Migration: 20251206_auto_create_all_members_group.sql
-- ============================================

-- Migration: Auto-create 'All Members' group when trip is created
-- Date: 2025-12-06
-- Description: Automatically creates an "All Members" group chat when a new trip is created
--              and auto-adds new trip members to this group

-- ============================================================================
-- ADD is_default_group COLUMN
-- ============================================================================
-- This column marks the "All Members" group as the default group for the trip
-- Only one default group should exist per trip

ALTER TABLE public.conversations
ADD COLUMN IF NOT EXISTS is_default_group BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.conversations.is_default_group IS 'True for the default "All Members" group created with the trip';

-- Create index for quick lookup
CREATE INDEX IF NOT EXISTS idx_conversations_default_group
ON public.conversations(trip_id)
WHERE is_default_group = true;

-- ============================================================================
-- FUNCTION: Create default group for a trip
-- ============================================================================
-- This function creates the "All Members" group chat for a trip

CREATE OR REPLACE FUNCTION create_trip_default_group(
    p_trip_id UUID,
    p_trip_name TEXT,
    p_created_by UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Insert the default "All Members" conversation
    INSERT INTO public.conversations (
        trip_id,
        name,
        description,
        created_by,
        is_direct_message,
        is_default_group
    ) VALUES (
        p_trip_id,
        '📢 All Members',
        'Everyone in ' || COALESCE(p_trip_name, 'this trip') || '. Share updates, plans, and announcements here!',
        p_created_by,
        false,
        true
    )
    RETURNING id INTO v_conversation_id;

    -- Add the creator as admin of the conversation
    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role
    ) VALUES (
        v_conversation_id,
        p_created_by,
        'admin'
    );

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER FUNCTION: Auto-create group on trip creation
-- ============================================================================

CREATE OR REPLACE FUNCTION on_trip_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Create the default "All Members" group
    PERFORM create_trip_default_group(
        NEW.id,
        NEW.name,
        NEW.created_by
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: On new trip created
-- ============================================================================

DROP TRIGGER IF EXISTS trip_created_create_default_group ON public.trips;
CREATE TRIGGER trip_created_create_default_group
    AFTER INSERT ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_created();

-- ============================================================================
-- TRIGGER FUNCTION: Auto-add member to default group
-- ============================================================================
-- When a new member joins a trip, automatically add them to the "All Members" group

CREATE OR REPLACE FUNCTION on_trip_member_added()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    -- Find the default group for this trip
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = NEW.trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If default group exists, add the new member
    IF v_default_conversation_id IS NOT NULL THEN
        -- Insert the member (ignore if already exists)
        INSERT INTO public.conversation_members (
            conversation_id,
            user_id,
            role
        ) VALUES (
            v_default_conversation_id,
            NEW.user_id,
            'member'
        )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: On new trip member added
-- ============================================================================

DROP TRIGGER IF EXISTS trip_member_added_join_default_group ON public.trip_members;
CREATE TRIGGER trip_member_added_join_default_group
    AFTER INSERT ON public.trip_members
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_member_added();

-- ============================================================================
-- TRIGGER FUNCTION: Auto-remove member from default group when leaving trip
-- ============================================================================

CREATE OR REPLACE FUNCTION on_trip_member_removed()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    -- Find the default group for this trip
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = OLD.trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If default group exists, remove the member
    IF v_default_conversation_id IS NOT NULL THEN
        DELETE FROM public.conversation_members
        WHERE conversation_id = v_default_conversation_id
        AND user_id = OLD.user_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: On trip member removed
-- ============================================================================

DROP TRIGGER IF EXISTS trip_member_removed_leave_default_group ON public.trip_members;
CREATE TRIGGER trip_member_removed_leave_default_group
    AFTER DELETE ON public.trip_members
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_member_removed();

-- ============================================================================
-- FUNCTION: Get or create default group for existing trips
-- ============================================================================
-- This function can be called to create default groups for trips that existed
-- before this migration

CREATE OR REPLACE FUNCTION ensure_trip_default_group(p_trip_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_trip RECORD;
BEGIN
    -- Check if default group already exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If exists, return it
    IF v_conversation_id IS NOT NULL THEN
        RETURN v_conversation_id;
    END IF;

    -- Get trip details
    SELECT id, name, created_by INTO v_trip
    FROM public.trips
    WHERE id = p_trip_id;

    IF v_trip.id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Create the default group
    v_conversation_id := create_trip_default_group(
        p_trip_id,
        v_trip.name,
        v_trip.created_by
    );

    -- Add all existing trip members to the group
    INSERT INTO public.conversation_members (conversation_id, user_id, role)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END
    FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id
    AND tm.user_id != v_trip.created_by  -- Creator already added
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- BACKFILL: Create default groups for existing trips
-- ============================================================================
-- Uncomment to run the backfill for existing trips

-- DO $$
-- DECLARE
--     trip_record RECORD;
-- BEGIN
--     FOR trip_record IN SELECT id FROM public.trips LOOP
--         PERFORM ensure_trip_default_group(trip_record.id);
--     END LOOP;
-- END $$;

-- ============================================================================
-- UPDATE get_trip_conversations FUNCTION
-- ============================================================================
-- Add is_default_group to the returned columns
-- Must drop first because return type is changing

DROP FUNCTION IF EXISTS get_trip_conversations(uuid, uuid);

CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    is_default_group BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        COALESCE(c.is_default_group, false) as is_default_group,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        -- Get other member's name for DMs
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.full_name FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_name,
        -- Get other member's avatar for DMs
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.avatar_url FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    -- Order: default group first, then by last message, then by creation
    ORDER BY
        COALESCE(c.is_default_group, false) DESC,
        last_message_at DESC NULLS LAST,
        c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION create_trip_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;

-- ============================================================================
-- UPDATE RLS POLICY FOR DEFAULT GROUPS
-- ============================================================================
-- Allow system to insert conversation members for default groups

-- Drop existing policy if exists and recreate with updated rules
DROP POLICY IF EXISTS "System can add members to default groups" ON public.conversation_members;

CREATE POLICY "System can add members to default groups"
ON public.conversation_members
FOR INSERT
TO authenticated
WITH CHECK (
    -- Existing rules: creator or admin can add
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
    OR
    -- New rule: Trip members can be added to default group of their trip
    EXISTS (
        SELECT 1 FROM public.conversations c
        JOIN public.trip_members tm ON tm.trip_id = c.trip_id
        WHERE c.id = conversation_members.conversation_id
        AND c.is_default_group = true
        AND tm.user_id = conversation_members.user_id
    )
);


-- ============================================
-- Migration: 20251206_fix_conversation_details.sql
-- ============================================

-- Migration: Fix get_conversation_with_details to include is_default_group
-- Date: 2025-12-06
-- Description: Add is_default_group column to get_conversation_with_details function
--              so the conversation info page can properly detect default groups

-- ============================================================================
-- UPDATE get_conversation_with_details FUNCTION
-- ============================================================================
-- Add is_default_group to the returned columns
-- Must drop first because return type is changing

DROP FUNCTION IF EXISTS get_conversation_with_details(uuid, uuid);

CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    is_default_group BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        COALESCE(c.is_default_group, false) as is_default_group,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        -- For DMs, get the other member's name
        CASE WHEN c.is_direct_message THEN
            (SELECT p.full_name FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_name,
        -- For DMs, get the other member's avatar
        CASE WHEN c.is_direct_message THEN
            (SELECT p.avatar_url FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;


-- ============================================
-- Migration: 20251207_fix_default_group_membership.sql
-- ============================================

-- Migration: Fix Default Group Membership
-- Date: 2025-12-07
-- Description: Fix ensure_trip_default_group to always sync missing trip members
--              and add a new function to ensure a specific user is in the default group

-- ============================================================================
-- FUNCTION: Ensure trip member is in default group
-- ============================================================================
-- This function ensures a specific trip member is added to the default group
-- Call this when loading unread count to ensure the user can see messages

CREATE OR REPLACE FUNCTION ensure_user_in_default_group(
    p_trip_id UUID,
    p_user_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_is_trip_member BOOLEAN;
BEGIN
    -- First check if user is a trip member
    SELECT EXISTS(
        SELECT 1 FROM public.trip_members
        WHERE trip_id = p_trip_id AND user_id = p_user_id
    ) INTO v_is_trip_member;

    -- If not a trip member, return null
    IF NOT v_is_trip_member THEN
        RETURN NULL;
    END IF;

    -- Find the default group for this trip
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If no default group exists, create it
    IF v_conversation_id IS NULL THEN
        v_conversation_id := ensure_trip_default_group(p_trip_id);
    END IF;

    -- If still no conversation, return null
    IF v_conversation_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Add user to the default group if not already a member
    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role
    ) VALUES (
        v_conversation_id,
        p_user_id,
        'member'
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- UPDATE: ensure_trip_default_group to always sync members
-- ============================================================================
-- This version always adds any missing trip members to the default group

CREATE OR REPLACE FUNCTION ensure_trip_default_group(p_trip_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_trip RECORD;
BEGIN
    -- Check if default group already exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If doesn't exist, create it
    IF v_conversation_id IS NULL THEN
        -- Get trip details
        SELECT id, name, created_by INTO v_trip
        FROM public.trips
        WHERE id = p_trip_id;

        IF v_trip.id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Create the default group
        v_conversation_id := create_trip_default_group(
            p_trip_id,
            v_trip.name,
            v_trip.created_by
        );
    END IF;

    -- ALWAYS sync missing trip members to the default group
    -- This ensures users added before the migration are included
    INSERT INTO public.conversation_members (conversation_id, user_id, role)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END
    FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id
    AND NOT EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = v_conversation_id
        AND cm.user_id = tm.user_id
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- BACKFILL: Add all existing trip members to their default groups
-- ============================================================================
-- This runs once to fix any existing trips

DO $$
DECLARE
    trip_record RECORD;
BEGIN
    FOR trip_record IN SELECT id FROM public.trips LOOP
        PERFORM ensure_trip_default_group(trip_record.id);
    END LOOP;
END $$;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION ensure_user_in_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;


-- ============================================
-- Migration: 20251207_fix_message_delete_rls.sql
-- ============================================




-- ============================================
-- Migration: 20251207_user_delete_trip.sql
-- ============================================

-- User Delete Trip Function
-- Allows trip owners to delete their own trips with proper cascade
-- Created: December 7, 2025

-- Function to delete trip (for trip owner)
CREATE OR REPLACE FUNCTION public.user_delete_trip(
  p_trip_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_trip_owner UUID;
BEGIN
  -- Check if the trip exists and get the owner
  SELECT created_by INTO v_trip_owner
  FROM public.trips
  WHERE id = p_trip_id;

  -- If trip doesn't exist, return false
  IF v_trip_owner IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  -- Check if the user is the trip owner
  IF v_trip_owner != auth.uid() THEN
    RAISE EXCEPTION 'Only the trip owner can delete this trip';
  END IF;

  -- Delete related data in the correct order (respecting foreign key constraints)

  -- 1. Delete conversation messages first
  DELETE FROM public.conversation_messages
  WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE trip_id = p_trip_id
  );

  -- 2. Delete conversation members
  DELETE FROM public.conversation_members
  WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE trip_id = p_trip_id
  );

  -- 3. Delete conversations
  DELETE FROM public.conversations WHERE trip_id = p_trip_id;

  -- 4. Delete join requests
  DELETE FROM public.trip_join_requests WHERE trip_id = p_trip_id;

  -- 5. Delete expense splits
  DELETE FROM public.expense_splits
  WHERE expense_id IN (
    SELECT id FROM public.expenses WHERE trip_id = p_trip_id
  );

  -- 6. Delete expenses
  DELETE FROM public.expenses WHERE trip_id = p_trip_id;

  -- 7. Delete checklist items
  DELETE FROM public.checklist_items
  WHERE checklist_id IN (
    SELECT id FROM public.checklists WHERE trip_id = p_trip_id
  );

  -- 8. Delete checklists
  DELETE FROM public.checklists WHERE trip_id = p_trip_id;

  -- 9. Delete itinerary items
  DELETE FROM public.itinerary_items WHERE trip_id = p_trip_id;

  -- 10. Delete trip invites
  DELETE FROM public.trip_invites WHERE trip_id = p_trip_id;

  -- 11. Delete trip members
  DELETE FROM public.trip_members WHERE trip_id = p_trip_id;

  -- 12. Finally delete the trip
  DELETE FROM public.trips WHERE id = p_trip_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.user_delete_trip TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.user_delete_trip IS 'Delete a trip and all related data (trip owner only)';


-- ============================================
-- Migration: 20251208_fix_last_read_at_for_new_members.sql
-- ============================================

-- Migration: Fix last_read_at for new conversation members
-- Date: 2025-12-08
-- Description: Ensures new conversation members start with last_read_at = NULL
--              so all existing messages appear as unread

-- ============================================================================
-- FIX: Update ensure_user_in_default_group to NOT set last_read_at
-- ============================================================================
-- This ensures new members see all messages as unread

CREATE OR REPLACE FUNCTION ensure_user_in_default_group(
    p_trip_id UUID,
    p_user_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_is_trip_member BOOLEAN;
BEGIN
    -- First check if user is a trip member
    SELECT EXISTS(
        SELECT 1 FROM public.trip_members
        WHERE trip_id = p_trip_id AND user_id = p_user_id
    ) INTO v_is_trip_member;

    -- If not a trip member, return null
    IF NOT v_is_trip_member THEN
        RETURN NULL;
    END IF;

    -- Find the default group for this trip
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If no default group exists, create it
    IF v_conversation_id IS NULL THEN
        v_conversation_id := ensure_trip_default_group(p_trip_id);
    END IF;

    -- If still no conversation, return null
    IF v_conversation_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Add user to the default group if not already a member
    -- IMPORTANT: Do NOT set last_read_at - leave it NULL so all messages appear unread
    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role,
        last_read_at  -- Explicitly set to NULL
    ) VALUES (
        v_conversation_id,
        p_user_id,
        'member',
        NULL  -- New members should see all messages as unread
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FIX: Update ensure_trip_default_group to NOT set last_read_at
-- ============================================================================

CREATE OR REPLACE FUNCTION ensure_trip_default_group(p_trip_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_trip RECORD;
BEGIN
    -- Check if default group already exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If doesn't exist, create it
    IF v_conversation_id IS NULL THEN
        -- Get trip details
        SELECT id, name, created_by INTO v_trip
        FROM public.trips
        WHERE id = p_trip_id;

        IF v_trip.id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Create the default group
        v_conversation_id := create_trip_default_group(
            p_trip_id,
            v_trip.name,
            v_trip.created_by
        );
    END IF;

    -- ALWAYS sync missing trip members to the default group
    -- IMPORTANT: Set last_read_at to NULL so all existing messages appear as unread
    INSERT INTO public.conversation_members (conversation_id, user_id, role, last_read_at)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END,
        NULL  -- New members should see all messages as unread
    FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id
    AND NOT EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = v_conversation_id
        AND cm.user_id = tm.user_id
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FIX: Update on_trip_member_added trigger to NOT set last_read_at
-- ============================================================================

CREATE OR REPLACE FUNCTION on_trip_member_added()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    -- Find the default group for this trip
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = NEW.trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If default group exists, add the new member
    IF v_default_conversation_id IS NOT NULL THEN
        -- Insert the member with last_read_at = NULL
        -- This ensures all existing messages appear as unread for the new member
        INSERT INTO public.conversation_members (
            conversation_id,
            user_id,
            role,
            last_read_at
        ) VALUES (
            v_default_conversation_id,
            NEW.user_id,
            'member',
            NULL  -- New members should see all messages as unread
        )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- BACKFILL: Reset last_read_at for members who haven't actually read messages
-- ============================================================================
-- This fixes existing members who were added with last_read_at = NOW()
-- We reset to NULL so they can see unread counts properly

-- Option 1: Reset ALL members' last_read_at to NULL (aggressive but simple)
-- This will make all messages appear as unread for everyone

-- UPDATE public.conversation_members SET last_read_at = NULL;

-- Option 2: Only reset for members who joined recently (within last 7 days)
-- and haven't sent any messages (likely they were just added)

UPDATE public.conversation_members cm
SET last_read_at = NULL
WHERE cm.joined_at > NOW() - INTERVAL '7 days'
AND NOT EXISTS (
    SELECT 1 FROM public.messages m
    WHERE m.conversation_id = cm.conversation_id
    AND m.sender_id = cm.user_id
);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION ensure_user_in_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;


-- ============================================
-- Migration: 20251208_mark_conversation_as_read_function.sql
-- ============================================

-- Migration: Add mark_conversation_as_read function
-- Date: 2025-12-08
-- Description: Server-side function to mark conversations as read with proper timezone handling
--              Uses database NOW() to ensure consistent timestamps

-- ============================================================================
-- FUNCTION: Mark conversation as read using server-side time
-- ============================================================================
-- This function uses database NOW() instead of client-side time
-- to ensure consistent timezone handling and prevent timing issues

CREATE OR REPLACE FUNCTION mark_conversation_as_read(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.conversation_members
    SET last_read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION mark_conversation_as_read TO authenticated;

-- ============================================================================
-- COMMENT
-- ============================================================================

COMMENT ON FUNCTION mark_conversation_as_read IS
'Marks a conversation as read for a user using server-side NOW() timestamp.
This ensures consistent timezone handling across all clients.';


-- ============================================
-- Migration: 20251210_fix_unread_count_calculation.sql
-- ============================================

-- Migration: Fix unread count calculation to use joined_at as fallback
-- Date: 2025-12-10
-- Description: When last_read_at is NULL (user never opened chat), use joined_at
--              instead of '1970-01-01' to count only messages since user joined
--              This fixes the bug where unread count shows ALL messages instead of
--              just the truly unread ones.

-- ============================================================================
-- UPDATE get_trip_conversations FUNCTION
-- ============================================================================
-- Fix the unread count calculation to use joined_at as fallback when
-- last_read_at is NULL. This ensures:
-- 1. If user has read messages before: count since last_read_at
-- 2. If user never opened chat (last_read_at = NULL): count since joined_at
--
-- Previous behavior: Used '1970-01-01' as fallback, counting ALL messages

DROP FUNCTION IF EXISTS get_trip_conversations(uuid, uuid);

CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    is_default_group BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        COALESCE(c.is_default_group, false) as is_default_group,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        -- FIX: Use joined_at as fallback instead of '1970-01-01'
        -- This ensures users only see unread count for messages sent AFTER they joined
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm2.last_read_at FROM public.conversation_members cm2
              WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user_id),
             -- Fallback to joined_at if last_read_at is NULL
             (SELECT cm3.joined_at FROM public.conversation_members cm3
              WHERE cm3.conversation_id = c.id AND cm3.user_id = p_user_id),
             -- Ultimate fallback (should never happen) - use conversation creation
             c.created_at
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        -- Get other member's name for DMs
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.full_name FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_name,
        -- Get other member's avatar for DMs
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.avatar_url FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    -- Order: default group first, then by last message, then by creation
    ORDER BY
        COALESCE(c.is_default_group, false) DESC,
        last_message_at DESC NULLS LAST,
        c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;

-- ============================================================================
-- COMMENT
-- ============================================================================

COMMENT ON FUNCTION get_trip_conversations IS
'Gets all conversations for a trip that the user is a member of.
Returns conversation details including unread count.
FIXED: Unread count now uses joined_at as fallback when last_read_at is NULL,
instead of counting all messages since 1970.';


-- ============================================
-- Migration: 20251213_itinerary_location_columns.sql
-- ============================================

-- Migration: Add location coordinates to itinerary_items table
-- Date: 2025-12-13
-- Description: Adds latitude, longitude, and place_id columns to support Google Maps location sharing

-- Add new columns to itinerary_items table
ALTER TABLE public.itinerary_items
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS place_id TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.itinerary_items.latitude IS 'Latitude coordinate from Google Maps share';
COMMENT ON COLUMN public.itinerary_items.longitude IS 'Longitude coordinate from Google Maps share';
COMMENT ON COLUMN public.itinerary_items.place_id IS 'Google Maps Place ID for the location';

-- Create index for geospatial queries (optional, for future use)
CREATE INDEX IF NOT EXISTS idx_itinerary_items_location
ON public.itinerary_items (latitude, longitude)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;


-- ============================================
-- Migration: 20251221_place_cache.sql
-- ============================================

-- ============================================================================
-- Place Cache Table for Google Places API
-- Description: Cache place details to minimize API calls and costs
-- Date: 2025-12-21
-- ============================================================================

-- ============================================================================
-- 1. Place Cache Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.place_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Google Places identifiers
    place_id TEXT UNIQUE NOT NULL,

    -- Basic info
    name TEXT NOT NULL,
    formatted_address TEXT,

    -- Location
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,

    -- Address components
    city TEXT,
    state TEXT,
    country TEXT,
    country_code TEXT,

    -- Place types (array of strings like 'locality', 'country', etc.)
    types TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Photo references (store first 5 photo references)
    photo_references TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Additional info
    website TEXT,
    google_maps_url TEXT,
    rating DECIMAL(2,1),
    user_ratings_total INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    access_count INTEGER DEFAULT 1
);

-- ============================================================================
-- 2. Indexes for Performance
-- ============================================================================

-- Index on place_id for quick lookups
CREATE INDEX IF NOT EXISTS idx_place_cache_place_id ON public.place_cache(place_id);

-- Index on city for destination searches
CREATE INDEX IF NOT EXISTS idx_place_cache_city ON public.place_cache(city);

-- Index on country for filtering
CREATE INDEX IF NOT EXISTS idx_place_cache_country ON public.place_cache(country);

-- Index on last_accessed_at for cache cleanup
CREATE INDEX IF NOT EXISTS idx_place_cache_last_accessed ON public.place_cache(last_accessed_at);

-- GIN index on types array for type-based searches
CREATE INDEX IF NOT EXISTS idx_place_cache_types ON public.place_cache USING GIN(types);

-- ============================================================================
-- 3. Functions
-- ============================================================================

-- Function to upsert a place into cache
CREATE OR REPLACE FUNCTION upsert_place_cache(
    p_place_id TEXT,
    p_name TEXT,
    p_formatted_address TEXT DEFAULT NULL,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_country TEXT DEFAULT NULL,
    p_country_code TEXT DEFAULT NULL,
    p_types TEXT[] DEFAULT NULL,
    p_photo_references TEXT[] DEFAULT NULL,
    p_website TEXT DEFAULT NULL,
    p_google_maps_url TEXT DEFAULT NULL,
    p_rating DECIMAL DEFAULT NULL,
    p_user_ratings_total INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.place_cache (
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
        user_ratings_total
    )
    VALUES (
        p_place_id,
        p_name,
        p_formatted_address,
        p_latitude,
        p_longitude,
        p_city,
        p_state,
        p_country,
        p_country_code,
        COALESCE(p_types, ARRAY[]::TEXT[]),
        COALESCE(p_photo_references, ARRAY[]::TEXT[]),
        p_website,
        p_google_maps_url,
        p_rating,
        p_user_ratings_total
    )
    ON CONFLICT (place_id) DO UPDATE SET
        name = EXCLUDED.name,
        formatted_address = EXCLUDED.formatted_address,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        country = EXCLUDED.country,
        country_code = EXCLUDED.country_code,
        types = EXCLUDED.types,
        photo_references = EXCLUDED.photo_references,
        website = EXCLUDED.website,
        google_maps_url = EXCLUDED.google_maps_url,
        rating = EXCLUDED.rating,
        user_ratings_total = EXCLUDED.user_ratings_total,
        updated_at = NOW(),
        last_accessed_at = NOW(),
        access_count = place_cache.access_count + 1
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get place from cache and update access stats
CREATE OR REPLACE FUNCTION get_place_from_cache(p_place_id TEXT)
RETURNS TABLE (
    id UUID,
    place_id TEXT,
    name TEXT,
    formatted_address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    city TEXT,
    state TEXT,
    country TEXT,
    country_code TEXT,
    types TEXT[],
    photo_references TEXT[],
    website TEXT,
    google_maps_url TEXT,
    rating DECIMAL,
    user_ratings_total INTEGER
) AS $$
BEGIN
    -- Update access stats
    UPDATE public.place_cache
    SET
        last_accessed_at = NOW(),
        access_count = place_cache.access_count + 1
    WHERE place_cache.place_id = p_place_id;

    -- Return the place
    RETURN QUERY
    SELECT
        pc.id,
        pc.place_id,
        pc.name,
        pc.formatted_address,
        pc.latitude,
        pc.longitude,
        pc.city,
        pc.state,
        pc.country,
        pc.country_code,
        pc.types,
        pc.photo_references,
        pc.website,
        pc.google_maps_url,
        pc.rating,
        pc.user_ratings_total
    FROM public.place_cache pc
    WHERE pc.place_id = p_place_id;
END;
$$ LANGUAGE plpgsql;

-- Function to search places in cache
CREATE OR REPLACE FUNCTION search_cached_places(
    p_query TEXT,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    place_id TEXT,
    name TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    types TEXT[],
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.place_id,
        pc.name,
        pc.city,
        pc.state,
        pc.country,
        pc.types,
        pc.latitude,
        pc.longitude
    FROM public.place_cache pc
    WHERE
        pc.name ILIKE '%' || p_query || '%' OR
        pc.city ILIKE '%' || p_query || '%' OR
        pc.state ILIKE '%' || p_query || '%' OR
        pc.country ILIKE '%' || p_query || '%'
    ORDER BY
        pc.access_count DESC,
        pc.last_accessed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to clean up old cache entries (not accessed in 90 days)
CREATE OR REPLACE FUNCTION cleanup_place_cache(p_days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM public.place_cache
    WHERE last_accessed_at < NOW() - (p_days_old || ' days')::INTERVAL;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. RLS Policies
-- ============================================================================

ALTER TABLE public.place_cache ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read cache
DROP POLICY IF EXISTS "Authenticated users can read place cache" ON public.place_cache;
CREATE POLICY "Authenticated users can read place cache"
    ON public.place_cache
    FOR SELECT
    TO authenticated
    USING (true);

-- Allow all authenticated users to insert into cache
DROP POLICY IF EXISTS "Authenticated users can insert place cache" ON public.place_cache;
CREATE POLICY "Authenticated users can insert place cache"
    ON public.place_cache
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow all authenticated users to update cache
DROP POLICY IF EXISTS "Authenticated users can update place cache" ON public.place_cache;
CREATE POLICY "Authenticated users can update place cache"
    ON public.place_cache
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 5. Grant Permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON public.place_cache TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_place_cache TO authenticated;
GRANT EXECUTE ON FUNCTION get_place_from_cache TO authenticated;
GRANT EXECUTE ON FUNCTION search_cached_places TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_place_cache TO authenticated;

-- ============================================================================
-- DONE!
-- ============================================================================


-- ============================================
-- Migration: 20251223_rename_budget_to_cost.sql
-- ============================================

-- Migration: Rename budget to cost
-- This reflects the semantic change: "cost" is what the trip costs (factual)
-- Budget tracking is removed - expense tracking + settlements handle money management

-- Rename the column
ALTER TABLE public.trips
RENAME COLUMN budget TO cost;

-- Add comment explaining the field
COMMENT ON COLUMN public.trips.cost IS 'The cost of the trip per person (set by organizer/creator). This is informational - actual expense tracking is done via the expenses table.';


-- ============================================
-- Migration: 20251224_copy_trip.sql
-- ============================================

-- Copy Trip Function
-- Copies a trip with its itinerary and checklists in a single transaction
-- Created: 2024-12-24

CREATE OR REPLACE FUNCTION public.copy_trip(
  p_source_trip_id UUID,
  p_new_name TEXT,
  p_new_start_date TIMESTAMPTZ,
  p_new_end_date TIMESTAMPTZ,
  p_copy_itinerary BOOLEAN DEFAULT true,
  p_copy_checklists BOOLEAN DEFAULT true
)
RETURNS UUID  -- Returns the new trip ID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_new_trip_id UUID;
  v_source_trip RECORD;
  v_checklist RECORD;
  v_new_checklist_id UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify user has access to source trip (is a member)
  IF NOT EXISTS (
    SELECT 1 FROM trip_members
    WHERE trip_id = p_source_trip_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Access denied to source trip';
  END IF;

  -- Get source trip data
  SELECT * INTO v_source_trip FROM trips WHERE id = p_source_trip_id;
  IF v_source_trip IS NULL THEN
    RAISE EXCEPTION 'Source trip not found';
  END IF;

  -- Create new trip
  INSERT INTO trips (
    name,
    description,
    destination,
    start_date,
    end_date,
    cover_image_url,
    cost,
    currency,
    is_public,
    created_by,
    is_completed,
    rating,
    completed_at
  ) VALUES (
    p_new_name,
    v_source_trip.description,
    v_source_trip.destination,
    p_new_start_date,
    p_new_end_date,
    v_source_trip.cover_image_url,
    v_source_trip.cost,
    v_source_trip.currency,
    v_source_trip.is_public,
    v_user_id,           -- Current user becomes creator
    false,               -- Reset to not completed
    NULL,                -- Reset rating
    NULL                 -- Reset completed_at
  ) RETURNING id INTO v_new_trip_id;

  -- Add current user as trip member (admin role)
  -- Use ON CONFLICT in case a trigger already added the creator
  INSERT INTO trip_members (trip_id, user_id, role)
  VALUES (v_new_trip_id, v_user_id, 'admin')
  ON CONFLICT (trip_id, user_id) DO UPDATE SET role = 'admin';

  -- Copy itinerary if requested
  IF p_copy_itinerary THEN
    INSERT INTO itinerary_items (
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
      end_time
    )
    SELECT
      v_new_trip_id,
      title,
      description,
      location,
      latitude,
      longitude,
      place_id,
      day_number,        -- Keep same day numbers
      order_index,
      NULL,              -- Clear start_time (will be recalculated based on new dates)
      NULL               -- Clear end_time
    FROM itinerary_items
    WHERE trip_id = p_source_trip_id;
  END IF;

  -- Copy checklists if requested
  IF p_copy_checklists THEN
    FOR v_checklist IN
      SELECT * FROM checklists WHERE trip_id = p_source_trip_id
    LOOP
      -- Create new checklist
      INSERT INTO checklists (trip_id, name, created_by)
      VALUES (v_new_trip_id, v_checklist.name, v_user_id)
      RETURNING id INTO v_new_checklist_id;

      -- Copy checklist items (all unchecked)
      INSERT INTO checklist_items (
        checklist_id,
        name,
        is_completed,
        order_index
      )
      SELECT
        v_new_checklist_id,
        name,
        false,           -- Reset all to unchecked
        order_index
      FROM checklist_items
      WHERE checklist_id = v_checklist.id;
    END LOOP;
  END IF;

  RETURN v_new_trip_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.copy_trip TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION public.copy_trip IS 'Copies a trip with optional itinerary and checklists. Returns the new trip ID.';


-- ============================================
-- Migration: 20251224_trip_favorites.sql
-- ============================================

-- Trip Favorites Feature
-- Allows users to mark trips as favorites for quick access

-- Create trip_favorites table
CREATE TABLE IF NOT EXISTS public.trip_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Unique constraint: one favorite per user per trip
  UNIQUE(user_id, trip_id)
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_trip_favorites_user_id ON public.trip_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_favorites_trip_id ON public.trip_favorites(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_favorites_user_trip ON public.trip_favorites(user_id, trip_id);

-- Enable RLS
ALTER TABLE public.trip_favorites ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running migration)
DROP POLICY IF EXISTS "Users can view own favorites" ON public.trip_favorites;
DROP POLICY IF EXISTS "Users can add own favorites" ON public.trip_favorites;
DROP POLICY IF EXISTS "Users can remove own favorites" ON public.trip_favorites;

-- RLS Policies
-- Users can view their own favorites
CREATE POLICY "Users can view own favorites"
  ON public.trip_favorites FOR SELECT
  USING (auth.uid() = user_id);

-- Users can add their own favorites
CREATE POLICY "Users can add own favorites"
  ON public.trip_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can remove their own favorites
CREATE POLICY "Users can remove own favorites"
  ON public.trip_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Function to toggle favorite status
CREATE OR REPLACE FUNCTION public.toggle_trip_favorite(p_trip_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Check if favorite exists
  SELECT EXISTS(
    SELECT 1 FROM public.trip_favorites
    WHERE user_id = v_user_id AND trip_id = p_trip_id
  ) INTO v_exists;

  IF v_exists THEN
    -- Remove favorite
    DELETE FROM public.trip_favorites
    WHERE user_id = v_user_id AND trip_id = p_trip_id;
    RETURN FALSE; -- Not a favorite anymore
  ELSE
    -- Add favorite
    INSERT INTO public.trip_favorites (user_id, trip_id)
    VALUES (v_user_id, p_trip_id);
    RETURN TRUE; -- Now a favorite
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's favorite trip IDs
CREATE OR REPLACE FUNCTION public.get_user_favorite_trip_ids()
RETURNS TABLE(trip_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT tf.trip_id
  FROM public.trip_favorites tf
  WHERE tf.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.toggle_trip_favorite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_favorite_trip_ids() TO authenticated;

-- Add comment
COMMENT ON TABLE public.trip_favorites IS 'Stores user favorite trips for quick access';


-- ============================================
-- Migration: 20251225_discover_favorites.sql
-- ============================================

-- Discover Favorites Feature
-- Allows users to mark discovered places (from Google Places) as favorites
-- Persists across devices and syncs with the cloud

-- Create discover_favorites table
CREATE TABLE IF NOT EXISTS public.discover_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id TEXT NOT NULL, -- Google Places ID
  place_name TEXT NOT NULL, -- For display when offline
  place_category TEXT, -- Category like 'beach', 'heritage', etc.
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Unique constraint: one favorite per user per place
  UNIQUE(user_id, place_id)
);

-- Add indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_discover_favorites_user_id ON public.discover_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_discover_favorites_place_id ON public.discover_favorites(place_id);
CREATE INDEX IF NOT EXISTS idx_discover_favorites_user_place ON public.discover_favorites(user_id, place_id);

-- Enable RLS
ALTER TABLE public.discover_favorites ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running migration)
DROP POLICY IF EXISTS "Users can view own discover favorites" ON public.discover_favorites;
DROP POLICY IF EXISTS "Users can add own discover favorites" ON public.discover_favorites;
DROP POLICY IF EXISTS "Users can remove own discover favorites" ON public.discover_favorites;

-- RLS Policies
-- Users can view their own favorites
CREATE POLICY "Users can view own discover favorites"
  ON public.discover_favorites FOR SELECT
  USING (auth.uid() = user_id);

-- Users can add their own favorites
CREATE POLICY "Users can add own discover favorites"
  ON public.discover_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can remove their own favorites
CREATE POLICY "Users can remove own discover favorites"
  ON public.discover_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Function to toggle discover favorite status
-- Returns TRUE if added, FALSE if removed
CREATE OR REPLACE FUNCTION public.toggle_discover_favorite(
  p_place_id TEXT,
  p_place_name TEXT DEFAULT NULL,
  p_place_category TEXT DEFAULT NULL,
  p_latitude DOUBLE PRECISION DEFAULT NULL,
  p_longitude DOUBLE PRECISION DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Check if favorite exists
  SELECT EXISTS(
    SELECT 1 FROM public.discover_favorites
    WHERE user_id = v_user_id AND place_id = p_place_id
  ) INTO v_exists;

  IF v_exists THEN
    -- Remove favorite
    DELETE FROM public.discover_favorites
    WHERE user_id = v_user_id AND place_id = p_place_id;
    RETURN FALSE; -- Not a favorite anymore
  ELSE
    -- Add favorite with metadata
    INSERT INTO public.discover_favorites (user_id, place_id, place_name, place_category, latitude, longitude)
    VALUES (v_user_id, p_place_id, COALESCE(p_place_name, 'Unknown Place'), p_place_category, p_latitude, p_longitude);
    RETURN TRUE; -- Now a favorite
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's favorite discover place IDs
CREATE OR REPLACE FUNCTION public.get_user_discover_favorite_ids()
RETURNS TABLE(place_id TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT df.place_id
  FROM public.discover_favorites df
  WHERE df.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's discover favorites with full metadata
CREATE OR REPLACE FUNCTION public.get_user_discover_favorites()
RETURNS TABLE(
  place_id TEXT,
  place_name TEXT,
  place_category TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    df.place_id,
    df.place_name,
    df.place_category,
    df.latitude,
    df.longitude,
    df.created_at
  FROM public.discover_favorites df
  WHERE df.user_id = auth.uid()
  ORDER BY df.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.toggle_discover_favorite(TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_discover_favorite_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_discover_favorites() TO authenticated;

-- Add comment
COMMENT ON TABLE public.discover_favorites IS 'Stores user favorite discovered places from Google Places for quick access';


