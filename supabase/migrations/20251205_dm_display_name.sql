-- Migration: DM Display Name
-- Date: 2025-12-05
-- Description: Update conversation functions to return the other member's name for DMs

-- ============================================================================
-- UPDATE get_trip_conversations FUNCTION
-- ============================================================================
-- Add dm_other_member_name column that returns the other member's name for DMs

DROP FUNCTION IF EXISTS get_trip_conversations(UUID, UUID);

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
        -- For DMs, get the other member's name (not the current user)
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
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    ORDER BY last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- UPDATE get_conversation_with_details FUNCTION
-- ============================================================================
-- Add dm_other_member_name column for consistency

DROP FUNCTION IF EXISTS get_conversation_with_details(UUID, UUID);

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
GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;
