-- Migration: Auto-create 'All Members' group when trip is created
-- Date: 2025-12-06
-- Description: Automatically creates an "All Members" group chat when a new trip is created
--              and auto-adds new trip members to this group

-- ============================================================================
-- ADD is_default_group COLUMN
-- ============================================================================
-- This column marks the "All Members" group as the default group for the trip
-- Only one default group should exist per trip

ALTER TABLE public.conversations
ADD COLUMN IF NOT EXISTS is_default_group BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.conversations.is_default_group IS 'True for the default "All Members" group created with the trip';

-- Create index for quick lookup
CREATE INDEX IF NOT EXISTS idx_conversations_default_group
ON public.conversations(trip_id)
WHERE is_default_group = true;

-- ============================================================================
-- FUNCTION: Create default group for a trip
-- ============================================================================
-- This function creates the "All Members" group chat for a trip

CREATE OR REPLACE FUNCTION create_trip_default_group(
    p_trip_id UUID,
    p_trip_name TEXT,
    p_created_by UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Insert the default "All Members" conversation
    INSERT INTO public.conversations (
        trip_id,
        name,
        description,
        created_by,
        is_direct_message,
        is_default_group
    ) VALUES (
        p_trip_id,
        '📢 All Members',
        'Everyone in ' || COALESCE(p_trip_name, 'this trip') || '. Share updates, plans, and announcements here!',
        p_created_by,
        false,
        true
    )
    RETURNING id INTO v_conversation_id;

    -- Add the creator as admin of the conversation
    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role
    ) VALUES (
        v_conversation_id,
        p_created_by,
        'admin'
    );

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER FUNCTION: Auto-create group on trip creation
-- ============================================================================

CREATE OR REPLACE FUNCTION on_trip_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Create the default "All Members" group
    PERFORM create_trip_default_group(
        NEW.id,
        NEW.name,
        NEW.created_by
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: On new trip created
-- ============================================================================

DROP TRIGGER IF EXISTS trip_created_create_default_group ON public.trips;
CREATE TRIGGER trip_created_create_default_group
    AFTER INSERT ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_created();

-- ============================================================================
-- TRIGGER FUNCTION: Auto-add member to default group
-- ============================================================================
-- When a new member joins a trip, automatically add them to the "All Members" group

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
        -- Insert the member (ignore if already exists)
        INSERT INTO public.conversation_members (
            conversation_id,
            user_id,
            role
        ) VALUES (
            v_default_conversation_id,
            NEW.user_id,
            'member'
        )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: On new trip member added
-- ============================================================================

DROP TRIGGER IF EXISTS trip_member_added_join_default_group ON public.trip_members;
CREATE TRIGGER trip_member_added_join_default_group
    AFTER INSERT ON public.trip_members
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_member_added();

-- ============================================================================
-- TRIGGER FUNCTION: Auto-remove member from default group when leaving trip
-- ============================================================================

CREATE OR REPLACE FUNCTION on_trip_member_removed()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    -- Find the default group for this trip
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = OLD.trip_id
    AND is_default_group = true
    LIMIT 1;

    -- If default group exists, remove the member
    IF v_default_conversation_id IS NOT NULL THEN
        DELETE FROM public.conversation_members
        WHERE conversation_id = v_default_conversation_id
        AND user_id = OLD.user_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: On trip member removed
-- ============================================================================

DROP TRIGGER IF EXISTS trip_member_removed_leave_default_group ON public.trip_members;
CREATE TRIGGER trip_member_removed_leave_default_group
    AFTER DELETE ON public.trip_members
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_member_removed();

-- ============================================================================
-- FUNCTION: Get or create default group for existing trips
-- ============================================================================
-- This function can be called to create default groups for trips that existed
-- before this migration

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

    -- If exists, return it
    IF v_conversation_id IS NOT NULL THEN
        RETURN v_conversation_id;
    END IF;

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

    -- Add all existing trip members to the group
    INSERT INTO public.conversation_members (conversation_id, user_id, role)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END
    FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id
    AND tm.user_id != v_trip.created_by  -- Creator already added
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- BACKFILL: Create default groups for existing trips
-- ============================================================================
-- Uncomment to run the backfill for existing trips

-- DO $$
-- DECLARE
--     trip_record RECORD;
-- BEGIN
--     FOR trip_record IN SELECT id FROM public.trips LOOP
--         PERFORM ensure_trip_default_group(trip_record.id);
--     END LOOP;
-- END $$;

-- ============================================================================
-- UPDATE get_trip_conversations FUNCTION
-- ============================================================================
-- Add is_default_group to the returned columns
-- Must drop first because return type is changing

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

GRANT EXECUTE ON FUNCTION create_trip_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;

-- ============================================================================
-- UPDATE RLS POLICY FOR DEFAULT GROUPS
-- ============================================================================
-- Allow system to insert conversation members for default groups

-- Drop existing policy if exists and recreate with updated rules
DROP POLICY IF EXISTS "System can add members to default groups" ON public.conversation_members;

CREATE POLICY "System can add members to default groups"
ON public.conversation_members
FOR INSERT
TO authenticated
WITH CHECK (
    -- Existing rules: creator or admin can add
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
    OR
    -- New rule: Trip members can be added to default group of their trip
    EXISTS (
        SELECT 1 FROM public.conversations c
        JOIN public.trip_members tm ON tm.trip_id = c.trip_id
        WHERE c.id = conversation_members.conversation_id
        AND c.is_default_group = true
        AND tm.user_id = conversation_members.user_id
    )
);
