-- Fix: Enable Row-Level Security on every public table that doesn't have it.
--
-- Why:
--   Supabase flags `rls_disabled_in_public` for any table in the `public`
--   schema with RLS turned off — meaning anyone with the project URL +
--   anon key can read/edit/delete every row in it. This migration closes
--   that hole for ALL such tables at once.
--
-- Design choices:
--   * Enable RLS on every public table that doesn't have it.
--   * Skip tables owned by an extension (e.g. PostGIS's `spatial_ref_sys`).
--     We don't own those, so ALTER TABLE fails with 42501. They contain
--     static reference data (no PII) and only Supabase support can fix
--     ownership — there is nothing we can do client-side.
--   * Do NOT auto-create policies. Guessing the wrong policy (e.g.
--     owner-only on a table that's meant to be shared between trip
--     members) would break the app worse than the original vuln. Tables
--     that already have policies keep them; tables that don't are locked
--     down (RLS on, no policy → service_role / SECURITY DEFINER RPCs
--     still work, anon/auth direct queries return zero rows).
--   * The migration verifies its own work at the end and RAISES an
--     EXCEPTION if any non-extension public table is still unprotected,
--     so a partial fix can't accidentally ship.
--
-- Idempotent: safe to re-run.

BEGIN;

DO $$
DECLARE
  r              record;
  enabled_list   text[] := ARRAY[]::text[];
  no_policy_list text[] := ARRAY[]::text[];
BEGIN
  -- 1. Enable RLS on every public table where it's off, skipping tables
  --    owned by an extension (we don't have permission to ALTER those).
  FOR r IN
    SELECT c.relname AS tbl
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind  = 'r'              -- ordinary tables, not views/matviews/partitions
      AND c.relrowsecurity = false
      AND NOT EXISTS (                  -- skip extension-owned tables
        SELECT 1 FROM pg_depend d
        WHERE d.objid = c.oid AND d.deptype = 'e'
      )
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.tbl);
    enabled_list := array_append(enabled_list, r.tbl);
  END LOOP;

  IF array_length(enabled_list, 1) IS NULL THEN
    RAISE NOTICE 'RLS audit: every public table already had RLS enabled. No change.';
  ELSE
    RAISE NOTICE 'RLS turned ON for: %', array_to_string(enabled_list, ', ');
  END IF;

  -- 2. Surface tables that now have RLS on but ZERO policies. Those are
  --    safe (locked down) but unreachable from the client SDK. If the app
  --    reads them directly with the user's JWT, those reads will now
  --    return empty — you need a follow-up migration to add policies.
  SELECT array_agg(c.relname ORDER BY c.relname)
  INTO no_policy_list
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relrowsecurity = true
    AND NOT EXISTS (                    -- skip extension-owned tables
      SELECT 1 FROM pg_depend d
      WHERE d.objid = c.oid AND d.deptype = 'e'
    )
    AND NOT EXISTS (
      SELECT 1 FROM pg_policies p
      WHERE p.schemaname = 'public' AND p.tablename = c.relname
    );

  IF no_policy_list IS NOT NULL THEN
    RAISE NOTICE 'Public tables with RLS on but no policies (locked down — add policies if the client reads these directly): %',
                 array_to_string(no_policy_list, ', ');
  END IF;
END
$$;

-- 3. Verification gate. If a single public table is still missing RLS the
--    whole migration rolls back, so we can't accidentally claim the fix
--    succeeded when it didn't.
DO $$
DECLARE
  still_open text[];
BEGIN
  SELECT array_agg(c.relname ORDER BY c.relname)
  INTO still_open
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND c.relrowsecurity = false
    AND NOT EXISTS (                    -- extension-owned tables are out of our control
      SELECT 1 FROM pg_depend d
      WHERE d.objid = c.oid AND d.deptype = 'e'
    );

  IF still_open IS NOT NULL THEN
    RAISE EXCEPTION
      'RLS fix did NOT cover every public table. Still unprotected: %.  Rolling back.',
      array_to_string(still_open, ', ');
  END IF;

  RAISE NOTICE 'Verification passed: every non-extension public table now has RLS enabled.';
END
$$;

COMMIT;
