-- Fix: checklist_items inserts fail with PGRST204 "column not found".
--
-- Symptom: even with RLS allowing inserts, every addChecklistItem call
-- fails with:
--   PostgrestException(
--     message: Could not find the 'assigned_to' column of 'checklist_items' in the schema cache,
--     code: PGRST204
--   )
--
-- Cause: the public.checklist_items table was created from an early
-- schema that only had (id, checklist_id, title, is_completed).
-- The Dart ChecklistItemModel.toDatabaseJson() also sends assigned_to,
-- completed_by, completed_at, order_index, created_at, updated_at —
-- and PostgREST rejects the whole upsert when any column is unknown.
--
-- Fix: add the missing columns (idempotent — safe to re-run).

ALTER TABLE public.checklist_items
  ADD COLUMN IF NOT EXISTS assigned_to  UUID         REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS completed_by UUID         REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS order_index  INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_completed BOOLEAN      NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW();

-- Indexes for the common access patterns the app needs
CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id
  ON public.checklist_items(checklist_id);

CREATE INDEX IF NOT EXISTS idx_checklist_items_assigned_to
  ON public.checklist_items(assigned_to)
  WHERE assigned_to IS NOT NULL;

-- Auto-update updated_at on UPDATE (so the app doesn't have to remember).
CREATE OR REPLACE FUNCTION public.touch_checklist_items_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_checklist_items_touch ON public.checklist_items;
CREATE TRIGGER trg_checklist_items_touch
  BEFORE UPDATE ON public.checklist_items
  FOR EACH ROW EXECUTE FUNCTION public.touch_checklist_items_updated_at();

-- After ALTER TABLE, PostgREST caches the OLD schema for ~10 seconds.
-- Force the schema cache reload so the very next insert from the app
-- sees the new columns immediately.
NOTIFY pgrst, 'reload schema';

-- Verify quickly — run this and confirm all 10 columns are present:
-- SELECT column_name FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='checklist_items'
--   ORDER BY ordinal_position;
