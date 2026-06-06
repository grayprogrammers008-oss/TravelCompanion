-- Fix: user_fcm_tokens table exists but is missing columns the
-- register_fcm_token / unregister_fcm_token functions expect.
--
-- Symptom: PostgrestException 42703 "column device_id does not exist"
-- on token registration after applying 20250127_trip_notifications.sql.
--
-- Cause: an earlier migration created user_fcm_tokens without all the
-- columns; the CREATE TABLE IF NOT EXISTS in 20250127 was a no-op and
-- left the old shape.
--
-- This patch adds any missing columns + unique constraint + index +
-- RLS policies. Safe to run multiple times (idempotent).

-- ── Add missing columns (no-ops if they already exist) ─────────────────────────

ALTER TABLE public.user_fcm_tokens
  ADD COLUMN IF NOT EXISTS device_id TEXT,
  ADD COLUMN IF NOT EXISTS device_type TEXT,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ DEFAULT NOW();

-- ── Make sure device_type allows expected values (drop+re-add the check) ───────

ALTER TABLE public.user_fcm_tokens
  DROP CONSTRAINT IF EXISTS user_fcm_tokens_device_type_check;

ALTER TABLE public.user_fcm_tokens
  ADD CONSTRAINT user_fcm_tokens_device_type_check
  CHECK (device_type IS NULL OR device_type IN ('ios', 'android', 'web'));

-- ── Unique (user_id, device_id) so register_fcm_token's ON CONFLICT works ──────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_fcm_tokens_user_id_device_id_key'
  ) THEN
    ALTER TABLE public.user_fcm_tokens
      ADD CONSTRAINT user_fcm_tokens_user_id_device_id_key
      UNIQUE (user_id, device_id);
  END IF;
END $$;

-- ── Indexes ────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id
  ON public.user_fcm_tokens(user_id);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active
  ON public.user_fcm_tokens(is_active)
  WHERE is_active = true;

-- ── RLS policies (idempotent) ──────────────────────────────────────────────────

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can view their own FCM tokens"
  ON public.user_fcm_tokens FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can insert their own FCM tokens"
  ON public.user_fcm_tokens FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can update their own FCM tokens"
  ON public.user_fcm_tokens FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can delete their own FCM tokens"
  ON public.user_fcm_tokens FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ── Re-grant function permissions in case the earlier migration didn't ─────────

GRANT EXECUTE ON FUNCTION public.register_fcm_token(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unregister_fcm_token(TEXT) TO authenticated;

-- Verify quickly: this should return all the expected columns.
-- SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='user_fcm_tokens'
--   ORDER BY ordinal_position;
