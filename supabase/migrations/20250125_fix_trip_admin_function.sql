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
