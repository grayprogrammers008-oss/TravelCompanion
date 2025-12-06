-- Migration: Fix get_conversation_with_details to include is_default_group
-- Date: 2025-12-06
-- Description: Add is_default_group column to get_conversation_with_details function
--              so the conversation info page can properly detect default groups

-- ============================================================================
-- UPDATE get_conversation_with_details FUNCTION
-- ============================================================================
-- Add is_default_group to the returned columns
-- Must drop first because return type is changing

DROP FUNCTION IF EXISTS get_conversation_with_details(uuid, uuid);

CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
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
         WHERE cm.conversation_id = c.id) as member_count,
        -- For DMs, get the other member's name
        CASE WHEN c.is_direct_message THEN
            (SELECT p.full_name FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_name,
        -- For DMs, get the other member's avatar
        CASE WHEN c.is_direct_message THEN
            (SELECT p.avatar_url FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;
