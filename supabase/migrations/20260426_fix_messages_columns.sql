-- Add missing columns to messages table
-- These columns are referenced by the Flutter app but missing from the schema

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS attachment_url TEXT,
  ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS read_by TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;

-- Index for conversation messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation
  ON public.messages(conversation_id, created_at DESC)
  WHERE conversation_id IS NOT NULL;

-- RLS for messages (allow trip members to insert and read)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trip members can view messages" ON public.messages;
DROP POLICY IF EXISTS "Trip members can send messages" ON public.messages;
DROP POLICY IF EXISTS "Message senders can delete their messages" ON public.messages;
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;
DROP POLICY IF EXISTS "messages_delete" ON public.messages;

-- SELECT: trip members can read messages for their trips
CREATE POLICY "messages_select" ON public.messages
  FOR SELECT TO authenticated
  USING (
    trip_id IN (SELECT public.get_my_trip_ids())
    OR conversation_id IN (SELECT public.get_my_conversation_ids())
  );

-- INSERT: trip members can send messages
CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND (
      trip_id IN (SELECT public.get_my_trip_ids())
      OR conversation_id IN (SELECT public.get_my_conversation_ids())
    )
  );

-- UPDATE: only the sender can edit/soft-delete their own message
CREATE POLICY "messages_update" ON public.messages
  FOR UPDATE TO authenticated
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

-- DELETE: only the sender can delete their own message
CREATE POLICY "messages_delete" ON public.messages
  FOR DELETE TO authenticated
  USING (sender_id = auth.uid());
