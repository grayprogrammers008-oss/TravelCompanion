-- Migration: Trip Push Notifications
-- Description: Add FCM token storage and database triggers for trip notifications
-- Date: 2025-01-27

-- ============================================================================
-- 1. Create FCM Tokens Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_id TEXT,
    device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure one token per device
    UNIQUE(user_id, device_id)
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active) WHERE is_active = true;

-- Enable RLS
ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies for FCM tokens
CREATE POLICY "Users can view their own FCM tokens"
    ON user_fcm_tokens
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own FCM tokens"
    ON user_fcm_tokens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own FCM tokens"
    ON user_fcm_tokens
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own FCM tokens"
    ON user_fcm_tokens
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 2. Function to update FCM token timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_fcm_token_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_used_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update timestamp
CREATE TRIGGER trigger_update_fcm_token_timestamp
    BEFORE UPDATE ON user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_fcm_token_timestamp();

-- ============================================================================
-- 3. Function to send trip update notification
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_trip_updated()
RETURNS TRIGGER AS $$
DECLARE
    v_trip_name TEXT;
    v_updater_name TEXT;
    v_updated_field TEXT;
BEGIN
    -- Get trip name
    v_trip_name := NEW.name;

    -- Get updater's name
    SELECT full_name INTO v_updater_name
    FROM profiles
    WHERE id = auth.uid()
    LIMIT 1;

    -- Determine what field was updated
    IF OLD.name IS DISTINCT FROM NEW.name THEN
        v_updated_field := 'name';
    ELSIF OLD.destination IS DISTINCT FROM NEW.destination THEN
        v_updated_field := 'destination';
    ELSIF OLD.start_date IS DISTINCT FROM NEW.start_date OR OLD.end_date IS DISTINCT FROM NEW.end_date THEN
        v_updated_field := 'dates';
    ELSIF OLD.description IS DISTINCT FROM NEW.description THEN
        v_updated_field := 'description';
    ELSIF OLD.cover_image_url IS DISTINCT FROM NEW.cover_image_url THEN
        v_updated_field := 'cover image';
    ELSE
        v_updated_field := 'details';
    END IF;

    -- Call edge function to send notification (async via pg_net or supabase_functions)
    -- Note: This requires pg_net extension or manual invocation
    -- For now, we'll log it and you can call it from the app layer
    RAISE NOTICE 'Trip updated: %, Field: %, By: %', v_trip_name, v_updated_field, v_updater_name;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. Function to send member added notification
-- ============================================================================

CREATE OR REPLACE FUNCTION notify_member_added()
RETURNS TRIGGER AS $$
DECLARE
    v_trip_name TEXT;
    v_member_name TEXT;
BEGIN
    -- Get trip name
    SELECT name INTO v_trip_name
    FROM trips
    WHERE id = NEW.trip_id
    LIMIT 1;

    -- Get member's name
    SELECT full_name INTO v_member_name
    FROM profiles
    WHERE id = NEW.user_id
    LIMIT 1;

    -- Log notification (edge function will be called from app layer)
    RAISE NOTICE 'Member added to trip: %, Member: %', v_trip_name, v_member_name;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. Create triggers for notifications
-- ============================================================================

-- Trigger for trip updates
DROP TRIGGER IF EXISTS trigger_notify_trip_updated ON trips;
CREATE TRIGGER trigger_notify_trip_updated
    AFTER UPDATE ON trips
    FOR EACH ROW
    WHEN (OLD.* IS DISTINCT FROM NEW.*)
    EXECUTE FUNCTION notify_trip_updated();

-- Trigger for member additions
DROP TRIGGER IF EXISTS trigger_notify_member_added ON trip_members;
CREATE TRIGGER trigger_notify_member_added
    AFTER INSERT ON trip_members
    FOR EACH ROW
    EXECUTE FUNCTION notify_member_added();

-- ============================================================================
-- 6. Helper function to register FCM token
-- ============================================================================

CREATE OR REPLACE FUNCTION register_fcm_token(
    p_fcm_token TEXT,
    p_device_id TEXT,
    p_device_type TEXT
)
RETURNS UUID AS $$
DECLARE
    v_token_id UUID;
BEGIN
    -- Deactivate old tokens for this device
    UPDATE user_fcm_tokens
    SET is_active = false
    WHERE user_id = auth.uid()
    AND device_id = p_device_id
    AND fcm_token != p_fcm_token;

    -- Insert or update token
    INSERT INTO user_fcm_tokens (user_id, fcm_token, device_id, device_type)
    VALUES (auth.uid(), p_fcm_token, p_device_id, p_device_type)
    ON CONFLICT (user_id, device_id)
    DO UPDATE SET
        fcm_token = EXCLUDED.fcm_token,
        device_type = EXCLUDED.device_type,
        is_active = true,
        updated_at = NOW(),
        last_used_at = NOW()
    RETURNING id INTO v_token_id;

    RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Helper function to unregister FCM token
-- ============================================================================

CREATE OR REPLACE FUNCTION unregister_fcm_token(
    p_device_id TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE user_fcm_tokens
    SET is_active = false
    WHERE user_id = auth.uid()
    AND device_id = p_device_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. Grant permissions
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION register_fcm_token(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION unregister_fcm_token(TEXT) TO authenticated;

-- ============================================================================
-- DONE!
-- ============================================================================

COMMENT ON TABLE user_fcm_tokens IS 'Stores Firebase Cloud Messaging tokens for push notifications';
COMMENT ON FUNCTION notify_trip_updated() IS 'Trigger function to send notification when trip is updated';
COMMENT ON FUNCTION notify_member_added() IS 'Trigger function to send notification when member is added';
COMMENT ON FUNCTION register_fcm_token(TEXT, TEXT, TEXT) IS 'Register or update FCM token for current user';
COMMENT ON FUNCTION unregister_fcm_token(TEXT) IS 'Deactivate FCM token for current user device';
