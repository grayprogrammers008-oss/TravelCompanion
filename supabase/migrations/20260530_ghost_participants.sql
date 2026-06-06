-- Feature: Non-member ("ghost") expense participants.
--
-- Why:
--   A trip often involves people who don't have app accounts — kids, elderly
--   relatives, guests — but who still need to be counted when splitting a
--   shared expense (think "X adults + Y kids" on a hotel booking). Storing
--   them only in the splitter's head means the split math is always wrong.
--
-- Design:
--   * A ghost belongs to a single trip and is created by a single real user
--     (the "creator"). That creator owns the ghost's debts: any amount the
--     ghost would owe gets folded into the creator's balance. Ghosts never
--     appear as debtors/creditors in settlement.
--   * expense_splits gets an optional ghost_id alongside the existing
--     user_id, with a check constraint that exactly one is set. Existing
--     rows keep user_id NOT NULL semantics in practice; the column is
--     relaxed only because the XOR constraint replaces it.
--   * Deleting a trip cascades to ghosts; deleting a ghost cascades to its
--     splits (matches how user_id splits behave when a member is removed).
--   * RLS: any trip member can read ghosts for that trip; only the creator
--     can edit/delete the ones they made.
--
-- Idempotent: safe to re-run.

BEGIN;

-- 1. Ghost participant table -----------------------------------------------

CREATE TABLE IF NOT EXISTS public.trip_ghost_participants (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id     uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  name        text NOT NULL CHECK (length(btrim(name)) > 0),
  created_by  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS trip_ghost_participants_trip_id_idx
  ON public.trip_ghost_participants(trip_id);

CREATE INDEX IF NOT EXISTS trip_ghost_participants_created_by_idx
  ON public.trip_ghost_participants(created_by);

ALTER TABLE public.trip_ghost_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trip members can read ghost participants"
  ON public.trip_ghost_participants;
CREATE POLICY "Trip members can read ghost participants"
  ON public.trip_ghost_participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trip_members tm
      WHERE tm.trip_id = trip_ghost_participants.trip_id
        AND tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Trip members can create ghost participants"
  ON public.trip_ghost_participants;
CREATE POLICY "Trip members can create ghost participants"
  ON public.trip_ghost_participants FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.trip_members tm
      WHERE tm.trip_id = trip_ghost_participants.trip_id
        AND tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Creator can update ghost participants"
  ON public.trip_ghost_participants;
CREATE POLICY "Creator can update ghost participants"
  ON public.trip_ghost_participants FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Creator can delete ghost participants"
  ON public.trip_ghost_participants;
CREATE POLICY "Creator can delete ghost participants"
  ON public.trip_ghost_participants FOR DELETE
  USING (created_by = auth.uid());

-- 2. Expense splits: add ghost_id + XOR constraint -------------------------

ALTER TABLE public.expense_splits
  ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE public.expense_splits
  ADD COLUMN IF NOT EXISTS ghost_id uuid
  REFERENCES public.trip_ghost_participants(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS expense_splits_ghost_id_idx
  ON public.expense_splits(ghost_id);

-- Exactly one of (user_id, ghost_id) must be set. Drop-then-add so the
-- migration is idempotent across re-runs.
ALTER TABLE public.expense_splits
  DROP CONSTRAINT IF EXISTS expense_splits_participant_xor;

ALTER TABLE public.expense_splits
  ADD CONSTRAINT expense_splits_participant_xor
  CHECK ((user_id IS NOT NULL) <> (ghost_id IS NOT NULL));

COMMIT;
