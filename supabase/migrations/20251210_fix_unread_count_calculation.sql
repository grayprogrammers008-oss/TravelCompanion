-- Migration: Fix unread count calculation to use joined_at as fallback
-- Date: 2025-12-10
-- Description: When last_read_at is NULL (user never opened chat), use joined_at
--              instead of '1970-01-01' to count only messages since user joined
--              This fixes the bug where unread count shows ALL messages instead of
--              just the truly unread ones.

-- ============================================================================
-- UPDATE get_trip_conversations FUNCTION
-- ============================================================================
-- Fix the unread count calculation to use joined_at as fallback when
-- last_read_at is NULL. This ensures:
-- 1. If user has read messages before: count since last_read_at
-- 2. If user never opened chat (last_read_at = NULL): count since joined_at
--
-- Previous behavior: Used '1970-01-01' as fallback, counting ALL messages

DROP FUNCTION IF EXISTS get_trip_conversations(uuid, uuid);

CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    is_default_group BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
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
        COALESCE(c.is_default_group, false) as is_default_group,
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
        -- FIX: Use joined_at as fallback instead of '1970-01-01'
        -- This ensures users only see unread count for messages sent AFTER they joined
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm2.last_read_at FROM public.conversation_members cm2
              WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user_id),
             -- Fallback to joined_at if last_read_at is NULL
             (SELECT cm3.joined_at FROM public.conversation_members cm3
              WHERE cm3.conversation_id = c.id AND cm3.user_id = p_user_id),
             -- Ultimate fallback (should never happen) - use conversation creation
             c.created_at
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        -- Get other member's name for DMs
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.full_name FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_name,
        -- Get other member's avatar for DMs
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.avatar_url FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    -- Order: default group first, then by last message, then by creation
    ORDER BY
        COALESCE(c.is_default_group, false) DESC,
        last_message_at DESC NULLS LAST,
        c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;

-- ============================================================================
-- COMMENT
-- ============================================================================

COMMENT ON FUNCTION get_trip_conversations IS
'Gets all conversations for a trip that the user is a member of.
Returns conversation details including unread count.
FIXED: Unread count now uses joined_at as fallback when last_read_at is NULL,
instead of counting all messages since 1970.';
