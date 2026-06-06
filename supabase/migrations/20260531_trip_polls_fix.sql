-- Fix: ambiguous column references in trip-poll table-returning functions.
--
-- Why:
--   `get_trip_polls` and `get_poll_results` declare RETURNS TABLE with
--   column names like `trip_id` and `option_id`. PL/pgSQL puts those
--   names in scope as variables for the entire function body. Bare
--   references to the same names in the body (against `trip_members`,
--   `trip_poll_votes`, etc.) become ambiguous and Postgres rejects them
--   at runtime with code 42702.
--
-- Fix:
--   * Add the `#variable_conflict use_column` pragma so PL/pgSQL resolves
--     bare names to the underlying table column rather than the return
--     variable. This is the smallest possible change.
--   * Add an explicit table alias to the trip-membership check for
--     readability while we're in there.
--
-- Idempotent: CREATE OR REPLACE both functions, no signature changes.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_trip_polls(
  p_trip_id uuid
) RETURNS TABLE (
  id                   uuid,
  trip_id              uuid,
  created_by           uuid,
  creator_name         text,
  question             text,
  default_option_id    uuid,
  default_option_label text,
  deadline             timestamptz,
  status               text,
  closed_at            timestamptz,
  created_at           timestamptz,
  option_count         bigint,
  vote_count           bigint,
  current_user_voted   boolean,
  current_user_option  uuid
) AS $$
#variable_conflict use_column
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id AND tm.user_id = auth.uid()
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
    )                                           AS current_user_voted,
    (SELECT v.option_id FROM public.trip_poll_votes v
       WHERE v.poll_id = p.id AND v.user_id = auth.uid()
       LIMIT 1)                                 AS current_user_option
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
#variable_conflict use_column
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
    SELECT 1 FROM public.trip_members tm
    WHERE tm.trip_id = v_poll.trip_id AND tm.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only trip members can view results';
  END IF;

  v_is_final := v_poll.status = 'closed' OR v_poll.deadline <= now();

  SELECT COUNT(*) INTO v_total_members
  FROM public.trip_members tm WHERE tm.trip_id = v_poll.trip_id;

  SELECT COUNT(*) INTO v_total_voted
  FROM public.trip_poll_votes v WHERE v.poll_id = p_poll_id;

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
    SELECT v.option_id AS oid, COUNT(*) AS votes
    FROM public.trip_poll_votes v
    WHERE v.poll_id = p_poll_id
    GROUP BY v.option_id
  ) vc ON vc.oid = o.id
  WHERE o.poll_id = p_poll_id
  ORDER BY o.position;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_poll_results TO authenticated;

COMMIT;
