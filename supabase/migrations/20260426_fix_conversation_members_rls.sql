-- Fix: infinite recursion in conversation_members RLS policies
-- The SELECT policy was querying conversation_members from within a policy ON conversation_members.
-- Fix: use a SECURITY DEFINER helper function (bypasses RLS, no recursion).

-- ── Helper function (SECURITY DEFINER — no recursion) ────────────────────────

CREATE OR REPLACE FUNCTION public.get_my_conversation_ids()
RETURNS SETOF UUID
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT conversation_id FROM public.conversation_members WHERE user_id = auth.uid();
$$;
GRANT EXECUTE ON FUNCTION public.get_my_conversation_ids() TO authenticated;

-- ── conversation_members policies ────────────────────────────────────────────

DROP POLICY IF EXISTS "Users can view conversation members" ON public.conversation_members;
DROP POLICY IF EXISTS "Conversation admins can add members" ON public.conversation_members;
DROP POLICY IF EXISTS "Conversation admins can remove members" ON public.conversation_members;
DROP POLICY IF EXISTS "Users can update their own membership" ON public.conversation_members;
DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_members;

-- SELECT: user can see members of conversations they belong to (no recursion)
CREATE POLICY "conversation_members_select" ON public.conversation_members
  FOR SELECT TO authenticated
  USING (conversation_id IN (SELECT public.get_my_conversation_ids()));

-- INSERT: conversation creator OR existing admin can add members
CREATE POLICY "conversation_members_insert" ON public.conversation_members
  FOR INSERT TO authenticated
  WITH CHECK (
    -- Conversation creator can add initial members
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
    -- Trip members can add themselves (self-join)
    OR user_id = auth.uid()
  );

-- UPDATE: users can update their own membership (mute, last_read_at)
CREATE POLICY "conversation_members_update" ON public.conversation_members
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- DELETE: users can leave (delete own row); admins can remove others via conversations check
CREATE POLICY "conversation_members_delete" ON public.conversation_members
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
  );

-- ── conversations SELECT policy also used conversation_members — fix it too ──

DROP POLICY IF EXISTS "Users can view conversations they are members of" ON public.conversations;
DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;
DROP POLICY IF EXISTS "Conversation admins can delete conversations" ON public.conversations;

CREATE POLICY "conversations_select" ON public.conversations
  FOR SELECT TO authenticated
  USING (id IN (SELECT public.get_my_conversation_ids()));

CREATE POLICY "conversations_update" ON public.conversations
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid());

CREATE POLICY "conversations_delete" ON public.conversations
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());
