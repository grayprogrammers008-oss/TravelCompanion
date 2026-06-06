-- AUDIT: Are any public tables exposed via the anon key?
-- Run in Supabase Dashboard → SQL Editor. Read-only — safe.
--
-- Use this BEFORE applying 20260518_enable_rls_all_public_tables.sql to see
-- what's exposed, and AFTER to confirm everything is locked down.
--
-- Extension-owned tables (e.g. PostGIS's `spatial_ref_sys`) are excluded
-- from the pass/fail check because we don't have permission to ALTER them
-- and they contain static reference data with no PII. Supabase may still
-- show a dashboard warning for them — that requires Supabase support to
-- resolve, there is no client-side fix.

-- ───────────────────────────────────────────────────────────────────
-- 1. Pass/fail summary (project-owned tables only)
-- ───────────────────────────────────────────────────────────────────
WITH project_tables AS (
  SELECT c.oid, c.relname, c.relrowsecurity
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
    AND NOT EXISTS (
      SELECT 1 FROM pg_depend d
      WHERE d.objid = c.oid AND d.deptype = 'e'
    )
)
SELECT
  count(*) FILTER (WHERE NOT relrowsecurity) AS tables_without_rls,
  count(*) FILTER (WHERE relrowsecurity)     AS tables_with_rls,
  CASE
    WHEN count(*) FILTER (WHERE NOT relrowsecurity) = 0
      THEN 'PASS — every project-owned public table has RLS enabled'
    ELSE 'FAIL — some tables are still publicly accessible (see query 2)'
  END AS status
FROM project_tables;

-- ───────────────────────────────────────────────────────────────────
-- 2. Per-table breakdown
-- ───────────────────────────────────────────────────────────────────
-- rls_enabled = false                       → flagged as rls_disabled_in_public
-- rls_enabled = true and policy_count = 0   → locked down (only service_role
--   / SECURITY DEFINER RPCs can read). Safe, but if the app reads the table
--   directly with the user's JWT those reads return zero rows.
-- rls_enabled = true and policy_count > 0   → properly secured.
-- extension_owned = true                    → out of our control (PostGIS etc).
SELECT
  c.relname        AS table_name,
  c.relrowsecurity AS rls_enabled,
  EXISTS (
    SELECT 1 FROM pg_depend d
    WHERE d.objid = c.oid AND d.deptype = 'e'
  )                AS extension_owned,
  (SELECT count(*) FROM pg_policies p
     WHERE p.schemaname = 'public' AND p.tablename = c.relname) AS policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
ORDER BY c.relrowsecurity ASC, c.relname;
