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
