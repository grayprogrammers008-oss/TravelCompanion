-- Migration: Add mark_conversation_as_read function
-- Date: 2025-12-08
-- Description: Server-side function to mark conversations as read with proper timezone handling
--              Uses database NOW() to ensure consistent timestamps

-- ============================================================================
-- FUNCTION: Mark conversation as read using server-side time
-- ============================================================================
-- This function uses database NOW() instead of client-side time
-- to ensure consistent timezone handling and prevent timing issues

CREATE OR REPLACE FUNCTION mark_conversation_as_read(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.conversation_members
    SET last_read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION mark_conversation_as_read TO authenticated;

-- ============================================================================
-- COMMENT
-- ============================================================================

COMMENT ON FUNCTION mark_conversation_as_read IS
'Marks a conversation as read for a user using server-side NOW() timestamp.
This ensures consistent timezone handling across all clients.';
