-- Migration: Fix Default Group Membership
-- Date: 2025-12-07
-- Description: Fix ensure_trip_default_group to always sync missing trip members
--              and add a new function to ensure a specific user is in the default group

-- ============================================================================
-- FUNCTION: Ensure trip member is in default group
-- ============================================================================
-- This function ensures a specific trip member is added to the default group
-- Call this when loading unread count to ensure the user can see messages

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
    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role
    ) VALUES (
        v_conversation_id,
        p_user_id,
        'member'
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- UPDATE: ensure_trip_default_group to always sync members
-- ============================================================================
-- This version always adds any missing trip members to the default group

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
    -- This ensures users added before the migration are included
    INSERT INTO public.conversation_members (conversation_id, user_id, role)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END
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
-- BACKFILL: Add all existing trip members to their default groups
-- ============================================================================
-- This runs once to fix any existing trips

DO $$
DECLARE
    trip_record RECORD;
BEGIN
    FOR trip_record IN SELECT id FROM public.trips LOOP
        PERFORM ensure_trip_default_group(trip_record.id);
    END LOOP;
END $$;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT EXECUTE ON FUNCTION ensure_user_in_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;
