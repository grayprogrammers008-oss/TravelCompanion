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
