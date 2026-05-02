-- Add missing core columns to messages table
-- message_type was missing from the schema cache (PGRST204)

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'text',
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Backfill updated_at for any existing rows
UPDATE public.messages SET updated_at = created_at WHERE updated_at IS NULL;

-- Reload schema cache so PostgREST picks up the new columns immediately
NOTIFY pgrst, 'reload schema';
