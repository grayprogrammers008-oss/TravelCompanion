-- Feature: ghost participants get a guardian.
--
-- Why:
--   Until now `trip_ghost_participants.created_by` did double duty:
--     1. Audit — which real user inserted the row.
--     2. Finance — whose balance the ghost's debts fold into.
--   That works as long as a member only creates ghosts for *themselves*.
--   But when an organizer pre-creates a ghost meant to ride on a different
--   member's tab ("Mike's daughter"), the daughter's share would
--   incorrectly land on the organizer's balance.
--
--   We split the two roles: `created_by` stays the inserter (audit, RLS
--   anchor) and a new `guardian_user_id` becomes the financial owner.
--   For every existing row we backfill guardian to the creator so behavior
--   is unchanged for already-created data.
--
-- RLS:
--   * Creator (auth.uid() = created_by) keeps full management rights.
--   * Guardian can also rename / delete *their own* ghost — so members
--     stay in control of their guests even if the organizer entered them.
--
-- Idempotent: column add is guarded; constraint/policy adjustments use
-- DROP-IF-EXISTS to allow re-runs.

BEGIN;

ALTER TABLE public.trip_ghost_participants
  ADD COLUMN IF NOT EXISTS guardian_user_id uuid;

UPDATE public.trip_ghost_participants
SET    guardian_user_id = created_by
WHERE  guardian_user_id IS NULL;

ALTER TABLE public.trip_ghost_participants
  ALTER COLUMN guardian_user_id SET NOT NULL;

ALTER TABLE public.trip_ghost_participants
  DROP CONSTRAINT IF EXISTS trip_ghost_participants_guardian_fk;
ALTER TABLE public.trip_ghost_participants
  ADD CONSTRAINT trip_ghost_participants_guardian_fk
  FOREIGN KEY (guardian_user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS trip_ghost_participants_guardian_idx
  ON public.trip_ghost_participants(guardian_user_id);

-- Refresh write policies so creator OR guardian can modify the row.
DROP POLICY IF EXISTS "Creator can update ghost participants"
  ON public.trip_ghost_participants;
DROP POLICY IF EXISTS "Creator can delete ghost participants"
  ON public.trip_ghost_participants;
DROP POLICY IF EXISTS "Creator or guardian can update ghost participants"
  ON public.trip_ghost_participants;
DROP POLICY IF EXISTS "Creator or guardian can delete ghost participants"
  ON public.trip_ghost_participants;

CREATE POLICY "Creator or guardian can update ghost participants"
  ON public.trip_ghost_participants FOR UPDATE
  USING (created_by = auth.uid() OR guardian_user_id = auth.uid())
  WITH CHECK (created_by = auth.uid() OR guardian_user_id = auth.uid());

CREATE POLICY "Creator or guardian can delete ghost participants"
  ON public.trip_ghost_participants FOR DELETE
  USING (created_by = auth.uid() OR guardian_user_id = auth.uid());

-- INSERT policy still requires created_by = auth.uid(), but we extend the
-- existing trip-member check to also require that the chosen guardian is
-- a member of the same trip (can't assign a guest to a non-member).
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
    AND EXISTS (
      SELECT 1 FROM public.trip_members tm
      WHERE tm.trip_id = trip_ghost_participants.trip_id
        AND tm.user_id = guardian_user_id
    )
  );

COMMIT;
