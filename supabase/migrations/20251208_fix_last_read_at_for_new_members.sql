-- Migration: Fix last_read_at for new conversation members
-- Date: 2025-12-08
-- Description: Ensures new conversation members start with last_read_at = NULL
--              so all existing messages appear as unread

-- ============================================================================
-- FIX: Update ensure_user_in_default_group to NOT set last_read_at
-- ============================================================================
-- This ensures new members see all messages as unread

CREATE OR REPLACE FUNCTION ensure_user_in_default_group(
    p_trip_id UUID,
    p_user_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_is_trip_member BOOLEAN;
BEGIN
    -- First check if user is a trip member
    SELECT EXISTS(
        SELECT 1 FROM public.trip_members
        WHERE trip_id = p_trip_id AND user_id = p_user_id
    ) INTO v_is_trip_member;

    -- If not a trip member, return null
    IF NOT v_is_trip_member THEN
        RETURN NULL;
    END IF;

    -- Find the default group for this trip
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If no default group exists, create it
    IF v_conversation_id IS NULL THEN
        v_conversation_id := ensure_trip_default_group(p_trip_id);
    END IF;

    -- If still no conversation, return null
    IF v_conversation_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Add user to the default group if not already a member
    -- IMPORTANT: Do NOT set last_read_at - leave it NULL so all messages appear unread
    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role,
        last_read_at  -- Explicitly set to NULL
    ) VALUES (
        v_conversation_id,
        p_user_id,
        'member',
        NULL  -- New members should see all messages as unread
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FIX: Update ensure_trip_default_group to NOT set last_read_at
-- ============================================================================

CREATE OR REPLACE FUNCTION ensure_trip_default_group(p_trip_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_trip RECORD;
BEGIN
    -- Check if default group already exists
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If doesn't exist, create it
    IF v_conversation_id IS NULL THEN
        -- Get trip details
        SELECT id, name, created_by INTO v_trip
        FROM public.trips
        WHERE id = p_trip_id;

        IF v_trip.id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Create the default group
        v_conversation_id := create_trip_default_group(
            p_trip_id,
            v_trip.name,
            v_trip.created_by
        );
    END IF;

    -- ALWAYS sync missing trip members to the default group
    -- IMPORTANT: Set last_read_at to NULL so all existing messages appear as unread
    INSERT INTO public.conversation_members (conversation_id, user_id, role, last_read_at)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END,
        NULL  -- New members should see all messages as unread
    FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id
    AND NOT EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = v_conversation_id
        AND cm.user_id = tm.user_id
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FIX: Update on_trip_member_added trigger to NOT set last_read_at
-- ============================================================================

CREATE OR REPLACE FUNCTION on_trip_member_added()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    -- Find the default group for this trip
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = NEW.trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If default group exists, add the new member
    IF v_default_conversation_id IS NOT NULL THEN
        -- Insert the member with last_read_at = NULL
        -- This ensures all existing messages appear as unread for the new member
        INSERT INTO public.conversation_members (
            conversation_id,
            user_id,
            role,
            last_read_at
        ) VALUES (
            v_default_conversation_id,
            NEW.user_id,
            'member',
            NULL  -- New members should see all messages as unread
        )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- BACKFILL: Reset last_read_at for members who haven't actually read messages
-- ============================================================================
-- This fixes existing members who were added with last_read_at = NOW()
-- We reset to NULL so they can see unread counts properly

-- Option 1: Reset ALL members' last_read_at to NULL (aggressive but simple)
-- This will make all messages appear as unread for everyone

-- UPDATE public.conversation_members SET last_read_at = NULL;

-- Option 2: Only reset for members who joined recently (within last 7 days)
-- and haven't sent any messages (likely they were just added)

UPDATE public.conversation_members cm
SET last_read_at = NULL
WHERE cm.joined_at > NOW() - INTERVAL '7 days'
AND NOT EXISTS (
    SELECT 1 FROM public.messages m
    WHERE m.conversation_id = cm.conversation_id
    AND m.sender_id = cm.user_id
);

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION ensure_user_in_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;
