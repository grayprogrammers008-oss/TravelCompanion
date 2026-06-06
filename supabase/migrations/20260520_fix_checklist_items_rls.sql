-- Fix: checklist_items inserts fail silently with RLS violation.
--
-- Symptom: creating a checklist from a template logs
--   "Adding 10 items from template…"
--   "✅ All template items added!"
-- but the resulting checklist has 0 items in the database, and opening
-- the checklist detail page shows it empty.
--
-- Cause: there is no permissive INSERT (and probably no SELECT/UPDATE/
-- DELETE) RLS policy on public.checklist_items, so every upsert from
-- the app gets silently rejected. The Dart provider catches the error
-- and returns null without raising — the loop carries on logging
-- success.
--
-- Fix: allow any trip member (including the creator) to CRUD items on
-- checklists belonging to trips they are a member of.
--
-- Idempotent — safe to run multiple times.

-- ── Helper: is the current user a member of the trip that owns this checklist?
-- SECURITY DEFINER avoids RLS recursion through trip_members.

CREATE OR REPLACE FUNCTION public.is_checklist_member(p_checklist_id UUID)
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.checklists c
    WHERE c.id = p_checklist_id
      AND (
        c.created_by = auth.uid()
        OR EXISTS (
          SELECT 1 FROM public.trip_members tm
          WHERE tm.trip_id = c.trip_id AND tm.user_id = auth.uid()
        )
      )
  );
$$;
GRANT EXECUTE ON FUNCTION public.is_checklist_member(UUID) TO authenticated;

-- ── Enable RLS on checklist_items (no-op if already on) ────────────────────────

ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;

-- ── Drop any conflicting existing policies, then add a clean set ───────────────

DROP POLICY IF EXISTS "checklist_items_select"        ON public.checklist_items;
DROP POLICY IF EXISTS "checklist_items_insert"        ON public.checklist_items;
DROP POLICY IF EXISTS "checklist_items_update"        ON public.checklist_items;
DROP POLICY IF EXISTS "checklist_items_delete"        ON public.checklist_items;
DROP POLICY IF EXISTS "Users can view checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Users can insert checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Users can update checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Users can delete checklist items" ON public.checklist_items;

CREATE POLICY "checklist_items_select" ON public.checklist_items
  FOR SELECT TO authenticated
  USING (public.is_checklist_member(checklist_id));

CREATE POLICY "checklist_items_insert" ON public.checklist_items
  FOR INSERT TO authenticated
  WITH CHECK (public.is_checklist_member(checklist_id));

CREATE POLICY "checklist_items_update" ON public.checklist_items
  FOR UPDATE TO authenticated
  USING (public.is_checklist_member(checklist_id))
  WITH CHECK (public.is_checklist_member(checklist_id));

CREATE POLICY "checklist_items_delete" ON public.checklist_items
  FOR DELETE TO authenticated
  USING (public.is_checklist_member(checklist_id));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.checklist_items TO authenticated;

-- ── While we're here, make sure checklists itself has the same shape ──────────
-- so the parent table is consistent. These are no-ops if already correct.

ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "checklists_select" ON public.checklists;
DROP POLICY IF EXISTS "checklists_insert" ON public.checklists;
DROP POLICY IF EXISTS "checklists_update" ON public.checklists;
DROP POLICY IF EXISTS "checklists_delete" ON public.checklists;

CREATE POLICY "checklists_select" ON public.checklists
  FOR SELECT TO authenticated
  USING (
    created_by = auth.uid()
    OR trip_id IN (
      SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "checklists_insert" ON public.checklists
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "checklists_update" ON public.checklists
  FOR UPDATE TO authenticated
  USING (
    created_by = auth.uid()
    OR trip_id IN (
      SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    created_by = auth.uid()
    OR trip_id IN (
      SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "checklists_delete" ON public.checklists
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.checklists TO authenticated;
