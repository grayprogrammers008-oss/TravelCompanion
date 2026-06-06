-- Enable realtime broadcasts on the trip-poll tables.
--
-- Why:
--   Supabase only forwards INSERT/UPDATE/DELETE events to clients for
--   tables that are members of the `supabase_realtime` publication. The
--   tables created in `20260531_trip_polls.sql` weren't added, so a vote
--   would save successfully but the UI wouldn't re-render until the user
--   manually pulled to refresh. Adding them lets the existing channel
--   subscriptions in `PollRemoteDataSource.watchTripPolls` /
--   `watchPollResults` actually fire.
--
-- Idempotent: guarded by `pg_publication_tables` lookup so re-runs are
-- safe even if a table was added manually via the Supabase Dashboard.

BEGIN;

DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'trip_polls',
    'trip_poll_options',
    'trip_poll_votes'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname    = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename  = v_table
    ) THEN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        v_table
      );
    END IF;
  END LOOP;
END $$;

COMMIT;
