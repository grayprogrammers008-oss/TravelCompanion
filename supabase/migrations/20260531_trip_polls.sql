-- Feature: Targeted trip voting (polls).
--
-- Why:
--   A trip organizer often needs to make a group decision — where to go,
--   which activity to pick, which restaurant to book. Doing this in chat
--   means votes scroll away and laggards block progress. A first-class
--   poll, with an organizer-set default for non-voters and a deadline,
--   keeps decisions moving.
--
-- Design:
--   * trip_polls            — one row per poll. Owned by `created_by`,
--                             tied to a trip. Has a deadline and a
--                             `default_option_id` whose vote is implicitly
--                             cast for any member who hasn't voted at
--                             tally time. `status` is 'open' or 'closed';
--                             a poll past its deadline is *treated as*
--                             closed by `get_poll_results` even if status
--                             hasn't been flipped yet (lazy close).
--   * trip_poll_options     — one row per choice. Ordered via `position`.
--                             Default option is referenced from the poll.
--   * trip_poll_votes       — one vote per (poll, user). Updating a vote
--                             is an UPSERT.
--
--   * Tally semantics: when results are computed, every trip member who
--     hasn't explicitly voted is counted as voting for the poll's
--     `default_option_id`. Ghost / non-member users are ignored. The
--     creator's "default wins for non-voters" rule is implemented in
--     tally code, not by inserting placeholder vote rows — keeps the
--     audit trail honest about who actually clicked.
--
--   * Only the organizer (= trip creator) can create or close a poll.
--     Any trip member can vote and read polls for their trips.
--
-- Idempotent: safe to re-run.

BEGIN;

-- 1. Tables ----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.trip_polls (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id            uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  created_by         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question           text NOT NULL CHECK (length(btrim(question)) > 0),
  default_option_id  uuid,
  deadline           timestamptz NOT NULL,
  status             text NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open', 'closed')),
  closed_at          timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS trip_polls_trip_id_idx
  ON public.trip_polls(trip_id);
CREATE INDEX IF NOT EXISTS trip_polls_created_by_idx
  ON public.trip_polls(created_by);
CREATE INDEX IF NOT EXISTS trip_polls_status_idx
  ON public.trip_polls(status);

CREATE TABLE IF NOT EXISTS public.trip_poll_options (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id   uuid NOT NULL REFERENCES public.trip_polls(id) ON DELETE CASCADE,
  label     text NOT NULL CHECK (length(btrim(label)) > 0),
  position  int  NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (poll_id, position)
);

CREATE INDEX IF NOT EXISTS trip_poll_options_poll_id_idx
  ON public.trip_poll_options(poll_id);

-- default_option_id references trip_poll_options; declared after the table
-- exists. Drop-then-add so the migration is idempotent across re-runs.
ALTER TABLE public.trip_polls
  DROP CONSTRAINT IF EXISTS trip_polls_default_option_fk;
ALTER TABLE public.trip_polls
  ADD CONSTRAINT trip_polls_default_option_fk
  FOREIGN KEY (default_option_id)
  REFERENCES public.trip_poll_options(id)
  ON DELETE SET NULL
  DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE IF NOT EXISTS public.trip_poll_votes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id    uuid NOT NULL REFERENCES public.trip_polls(id) ON DELETE CASCADE,
  option_id  uuid NOT NULL REFERENCES public.trip_poll_options(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  voted_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (poll_id, user_id)
);

CREATE INDEX IF NOT EXISTS trip_poll_votes_poll_id_idx
  ON public.trip_poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS trip_poll_votes_option_id_idx
  ON public.trip_poll_votes(option_id);
CREATE INDEX IF NOT EXISTS trip_poll_votes_user_id_idx
  ON public.trip_poll_votes(user_id);

-- 2. Row Level Security ----------------------------------------------------

ALTER TABLE public.trip_polls         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_poll_options  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_poll_votes    ENABLE ROW LEVEL SECURITY;

-- trip_polls --------------------------------------------------------------

DROP POLICY IF EXISTS "Trip members can read polls" ON public.trip_polls;
CREATE POLICY "Trip members can read polls"
  ON public.trip_polls FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trip_members tm
      WHERE tm.trip_id = trip_polls.trip_id
        AND tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Trip creator can insert polls" ON public.trip_polls;
CREATE POLICY "Trip creator can insert polls"
  ON public.trip_polls FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.trips t
      WHERE t.id = trip_polls.trip_id
        AND t.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Trip creator can update polls" ON public.trip_polls;
CREATE POLICY "Trip creator can update polls"
  ON public.trip_polls FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Trip creator can delete polls" ON public.trip_polls;
CREATE POLICY "Trip creator can delete polls"
  ON public.trip_polls FOR DELETE
  USING (created_by = auth.uid());

-- trip_poll_options -------------------------------------------------------

DROP POLICY IF EXISTS "Trip members can read poll options"
  ON public.trip_poll_options;
CREATE POLICY "Trip members can read poll options"
  ON public.trip_poll_options FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.trip_polls p
      JOIN public.trip_members tm ON tm.trip_id = p.trip_id
      WHERE p.id = trip_poll_options.poll_id
        AND tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Poll creator can manage poll options"
  ON public.trip_poll_options;
CREATE POLICY "Poll creator can manage poll options"
  ON public.trip_poll_options FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.trip_polls p
      WHERE p.id = trip_poll_options.poll_id
        AND p.created_by = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trip_polls p
      WHERE p.id = trip_poll_options.poll_id
        AND p.created_by = auth.uid()
    )
  );

-- trip_poll_votes ---------------------------------------------------------

DROP POLICY IF EXISTS "Trip members can read poll votes"
  ON public.trip_poll_votes;
CREATE POLICY "Trip members can read poll votes"
  ON public.trip_poll_votes FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.trip_polls p
      JOIN public.trip_members tm ON tm.trip_id = p.trip_id
      WHERE p.id = trip_poll_votes.poll_id
        AND tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Trip members can cast their own vote"
  ON public.trip_poll_votes;
CREATE POLICY "Trip members can cast their own vote"
  ON public.trip_poll_votes FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.trip_polls p
      JOIN public.trip_members tm ON tm.trip_id = p.trip_id
      WHERE p.id = trip_poll_votes.poll_id
        AND tm.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Voters can change their own vote"
  ON public.trip_poll_votes;
CREATE POLICY "Voters can change their own vote"
  ON public.trip_poll_votes FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Voters can retract their own vote"
  ON public.trip_poll_votes;
CREATE POLICY "Voters can retract their own vote"
  ON public.trip_poll_votes FOR DELETE
  USING (user_id = auth.uid());

-- 3. RPCs ------------------------------------------------------------------

-- Create a poll with options in a single transaction. Returns the poll id.
-- p_options is a JSON array of objects: [{"label": "Goa"}, {"label": "Manali"}].
-- p_default_index is the 0-based position of the default option within p_options.
CREATE OR REPLACE FUNCTION public.create_trip_poll(
  p_trip_id          uuid,
  p_question         text,
  p_options          jsonb,
  p_default_index    int,
  p_deadline         timestamptz
) RETURNS uuid AS $$
DECLARE
  v_poll_id      uuid;
  v_default_id   uuid;
  v_option       jsonb;
  v_position     int := 0;
  v_inserted_id  uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.trips
    WHERE id = p_trip_id AND created_by = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only the trip organizer can create polls';
  END IF;

  IF jsonb_array_length(p_options) < 2 THEN
    RAISE EXCEPTION 'A poll needs at least 2 options';
  END IF;

  IF p_default_index < 0 OR p_default_index >= jsonb_array_length(p_options) THEN
    RAISE EXCEPTION 'Default option index out of range';
  END IF;

  IF p_deadline <= now() THEN
    RAISE EXCEPTION 'Deadline must be in the future';
  END IF;

  INSERT INTO public.trip_polls (trip_id, created_by, question, deadline)
  VALUES (p_trip_id, auth.uid(), p_question, p_deadline)
  RETURNING id INTO v_poll_id;

  FOR v_option IN SELECT * FROM jsonb_array_elements(p_options) LOOP
    INSERT INTO public.trip_poll_options (poll_id, label, position)
    VALUES (v_poll_id, v_option->>'label', v_position)
    RETURNING id INTO v_inserted_id;

    IF v_position = p_default_index THEN
      v_default_id := v_inserted_id;
    END IF;

    v_position := v_position + 1;
  END LOOP;

  UPDATE public.trip_polls
  SET default_option_id = v_default_id
  WHERE id = v_poll_id;

  RETURN v_poll_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_trip_poll TO authenticated;

-- Cast or change a vote. Reject votes on closed / past-deadline polls.
CREATE OR REPLACE FUNCTION public.cast_poll_vote(
  p_poll_id    uuid,
  p_option_id  uuid
) RETURNS void AS $$
DECLARE
  v_poll  public.trip_polls%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_poll FROM public.trip_polls WHERE id = p_poll_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Poll not found';
  END IF;

  IF v_poll.status <> 'open' OR v_poll.deadline <= now() THEN
    RAISE EXCEPTION 'Poll is closed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_id = v_poll.trip_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only trip members can vote';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.trip_poll_options
    WHERE id = p_option_id AND poll_id = p_poll_id
  ) THEN
    RAISE EXCEPTION 'Option does not belong to this poll';
  END IF;

  INSERT INTO public.trip_poll_votes (poll_id, option_id, user_id)
  VALUES (p_poll_id, p_option_id, auth.uid())
  ON CONFLICT (poll_id, user_id)
  DO UPDATE SET option_id = EXCLUDED.option_id, voted_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.cast_poll_vote TO authenticated;

-- Close a poll early. Idempotent: closing an already-closed poll is a no-op.
CREATE OR REPLACE FUNCTION public.close_trip_poll(
  p_poll_id uuid
) RETURNS void AS $$
DECLARE
  v_creator uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT created_by INTO v_creator FROM public.trip_polls WHERE id = p_poll_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Poll not found';
  END IF;

  IF v_creator <> auth.uid() THEN
    RAISE EXCEPTION 'Only the poll organizer can close this poll';
  END IF;

  UPDATE public.trip_polls
  SET status = 'closed', closed_at = COALESCE(closed_at, now())
  WHERE id = p_poll_id AND status = 'open';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.close_trip_poll TO authenticated;

-- Tally results. Non-voting trip members are counted as voting for the
-- poll's `default_option_id`. Returns one row per option with explicit
-- and effective vote counts. `is_final` is true once the poll is closed
-- or past its deadline; until then the default-fill is treated as
-- projected, not authoritative.
-- `position` is a non-reserved Postgres keyword that the parser refuses in
-- a RETURNS TABLE column list (it's fine inside CREATE TABLE). We expose
-- it to clients as `opt_position` to dodge that grammar quirk.
DROP FUNCTION IF EXISTS public.get_poll_results(uuid);
CREATE OR REPLACE FUNCTION public.get_poll_results(
  p_poll_id uuid
) RETURNS TABLE (
  option_id        uuid,
  label            text,
  opt_position     int,
  is_default       boolean,
  explicit_votes   bigint,
  effective_votes  bigint,
  is_final         boolean,
  total_members    bigint,
  total_voted      bigint
) AS $$
DECLARE
  v_poll          public.trip_polls%ROWTYPE;
  v_total_members bigint;
  v_total_voted   bigint;
  v_non_voters    bigint;
  v_is_final      boolean;
BEGIN
  SELECT * INTO v_poll FROM public.trip_polls WHERE id = p_poll_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Poll not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_id = v_poll.trip_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only trip members can view results';
  END IF;

  v_is_final := v_poll.status = 'closed' OR v_poll.deadline <= now();

  SELECT COUNT(*) INTO v_total_members
  FROM public.trip_members WHERE trip_id = v_poll.trip_id;

  SELECT COUNT(*) INTO v_total_voted
  FROM public.trip_poll_votes WHERE poll_id = p_poll_id;

  v_non_voters := GREATEST(v_total_members - v_total_voted, 0);

  RETURN QUERY
  SELECT
    o.id                                                AS option_id,
    o.label                                             AS label,
    o.position                                          AS opt_position,
    (o.id = v_poll.default_option_id)                   AS is_default,
    COALESCE(vc.votes, 0)                               AS explicit_votes,
    COALESCE(vc.votes, 0)
      + CASE WHEN o.id = v_poll.default_option_id
             THEN v_non_voters ELSE 0 END               AS effective_votes,
    v_is_final                                          AS is_final,
    v_total_members                                     AS total_members,
    v_total_voted                                       AS total_voted
  FROM public.trip_poll_options o
  LEFT JOIN (
    SELECT option_id, COUNT(*) AS votes
    FROM public.trip_poll_votes
    WHERE poll_id = p_poll_id
    GROUP BY option_id
  ) vc ON vc.option_id = o.id
  WHERE o.poll_id = p_poll_id
  ORDER BY o.position;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_poll_results TO authenticated;

-- List polls for a trip with summary info. Used by the polls list page.
CREATE OR REPLACE FUNCTION public.get_trip_polls(
  p_trip_id uuid
) RETURNS TABLE (
  id                  uuid,
  trip_id             uuid,
  created_by          uuid,
  creator_name        text,
  question            text,
  default_option_id   uuid,
  default_option_label text,
  deadline            timestamptz,
  status              text,
  closed_at           timestamptz,
  created_at          timestamptz,
  option_count        bigint,
  vote_count          bigint,
  current_user_voted  boolean,
  current_user_option uuid
) AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_id = p_trip_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only trip members can list polls';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.trip_id,
    p.created_by,
    pr.full_name                                AS creator_name,
    p.question,
    p.default_option_id,
    d.label                                     AS default_option_label,
    p.deadline,
    p.status,
    p.closed_at,
    p.created_at,
    (SELECT COUNT(*) FROM public.trip_poll_options o
       WHERE o.poll_id = p.id)                  AS option_count,
    (SELECT COUNT(*) FROM public.trip_poll_votes v
       WHERE v.poll_id = p.id)                  AS vote_count,
    EXISTS (
      SELECT 1 FROM public.trip_poll_votes v
      WHERE v.poll_id = p.id AND v.user_id = auth.uid()
    )                                            AS current_user_voted,
    (SELECT v.option_id FROM public.trip_poll_votes v
       WHERE v.poll_id = p.id AND v.user_id = auth.uid()
       LIMIT 1)                                  AS current_user_option
  FROM public.trip_polls p
  LEFT JOIN public.profiles pr        ON pr.id = p.created_by
  LEFT JOIN public.trip_poll_options d ON d.id = p.default_option_id
  WHERE p.trip_id = p_trip_id
  ORDER BY
    CASE WHEN p.status = 'open' AND p.deadline > now() THEN 0 ELSE 1 END,
    p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_trip_polls TO authenticated;

COMMIT;
