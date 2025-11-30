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
