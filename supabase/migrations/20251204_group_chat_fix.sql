-- Migration: Group Chat Feature - FIX
-- Date: 2025-12-04
-- Description: Fix for partial migration - drops existing policies and recreates

-- ============================================================================
-- DROP EXISTING POLICIES (if they exist from partial migration)
-- ============================================================================

DROP POLICY IF EXISTS "Users can view conversations they are members of" ON public.conversations;
DROP POLICY IF EXISTS "Trip members can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;
DROP POLICY IF EXISTS "Conversation admins can delete conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can view conversation members" ON public.conversation_members;
DROP POLICY IF EXISTS "Conversation admins can add members" ON public.conversation_members;
DROP POLICY IF EXISTS "Users can update their own membership" ON public.conversation_members;
DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_members;
DROP POLICY IF EXISTS "Conversation admins can remove members" ON public.conversation_members;

-- ============================================================================
-- CONVERSATIONS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_direct_message BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.conversations IS 'Group chat conversations within trips';
COMMENT ON COLUMN public.conversations.is_direct_message IS 'True for 1:1 direct messages, false for group chats';

-- ============================================================================
-- CONVERSATION_MEMBERS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_muted BOOLEAN DEFAULT false,
    last_read_at TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);

COMMENT ON TABLE public.conversation_members IS 'Members of group chat conversations';
COMMENT ON COLUMN public.conversation_members.role IS 'Member role: admin or member';
COMMENT ON COLUMN public.conversation_members.is_muted IS 'Whether notifications are muted for this member';
COMMENT ON COLUMN public.conversation_members.last_read_at IS 'Timestamp of last read message for unread count';

-- ============================================================================
-- UPDATE MESSAGES TABLE
-- ============================================================================

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;

COMMENT ON COLUMN public.messages.conversation_id IS 'Optional conversation reference for group chats. NULL for legacy trip-wide messages.';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_conversations_trip ON public.conversations(trip_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_user ON public.conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC)
WHERE conversation_id IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;

-- Conversations: Users can view conversations they are members of
CREATE POLICY "Users can view conversations they are members of"
ON public.conversations
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
    )
    OR created_by = auth.uid()
);

-- Conversations: Trip members can create conversations
CREATE POLICY "Trip members can create conversations"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = conversations.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

-- Conversations: Admins can update conversations
CREATE POLICY "Conversation admins can update conversations"
ON public.conversations
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
    OR created_by = auth.uid()
);

-- Conversations: Admins can delete conversations
CREATE POLICY "Conversation admins can delete conversations"
ON public.conversations
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
    OR created_by = auth.uid()
);

-- Conversation Members: Users can view members of conversations they belong to
CREATE POLICY "Users can view conversation members"
ON public.conversation_members
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- Conversation Members: Creator or Admins can add members
CREATE POLICY "Conversation admins can add members"
ON public.conversation_members
FOR INSERT
TO authenticated
WITH CHECK (
    -- Creator can always add members (especially for initial member setup)
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
    OR
    -- Existing admins can add members
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR
    -- Users can add themselves if they're trip members
    (
        conversation_members.user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.conversations c
            JOIN public.trip_members tm ON tm.trip_id = c.trip_id
            WHERE c.id = conversation_members.conversation_id
            AND tm.user_id = auth.uid()
        )
    )
);

-- Conversation Members: Users can update their own membership (mute, last_read)
CREATE POLICY "Users can update their own membership"
ON public.conversation_members
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Conversation Members: Users can leave conversations (delete their membership)
CREATE POLICY "Users can leave conversations"
ON public.conversation_members
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Conversation Members: Admins can remove members
CREATE POLICY "Conversation admins can remove members"
ON public.conversation_members
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS conversations_updated_at_trigger ON public.conversations;
CREATE TRIGGER conversations_updated_at_trigger
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_conversations_updated_at();

CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    ORDER BY last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION find_existing_dm(
    p_trip_id UUID,
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND c.is_direct_message = true
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm1
        WHERE cm1.conversation_id = c.id AND cm1.user_id = p_user1_id
    )
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm2
        WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user2_id
    )
    AND (
        SELECT COUNT(*) FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id
    ) = 2
    LIMIT 1;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversation_members TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION find_existing_dm TO authenticated;
