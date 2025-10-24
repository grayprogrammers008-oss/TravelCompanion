-- ============================================================================
-- Messaging Module - Database Schema
-- ============================================================================
-- This schema supports real-time and offline messaging with P2P capabilities
-- Created: 2025-10-24
-- ============================================================================

-- ============================================================================
-- MESSAGES TABLE
-- ============================================================================
-- Stores all messages sent in trip chats
-- Supports text, images, locations, and expense links
-- ============================================================================

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE SET NULL,
    message TEXT CHECK (LENGTH(message) <= 2000),
    message_type VARCHAR(20) NOT NULL DEFAULT 'text',
        -- Values: 'text', 'image', 'location', 'expense_link'
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
        -- For threaded replies
    attachment_url TEXT,
        -- URL to image in Supabase Storage or location coordinates
    reactions JSONB DEFAULT '[]'::jsonb,
        -- Array of {emoji, user_id, created_at}
    read_by JSONB DEFAULT '[]'::jsonb,
        -- Array of user_ids who have read this message
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Most common query: Get messages for a trip, sorted by time
CREATE INDEX IF NOT EXISTS idx_messages_trip_time
    ON messages(trip_id, created_at DESC);

-- Query messages by sender
CREATE INDEX IF NOT EXISTS idx_messages_sender
    ON messages(sender_id);

-- Query threaded replies
CREATE INDEX IF NOT EXISTS idx_messages_reply_to
    ON messages(reply_to_id)
    WHERE reply_to_id IS NOT NULL;

-- Query undeleted messages (most common case)
CREATE INDEX IF NOT EXISTS idx_messages_not_deleted
    ON messages(trip_id, created_at DESC)
    WHERE is_deleted = false;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can read messages for trips they're members of
CREATE POLICY "Users can read messages for their trips"
    ON messages
    FOR SELECT
    USING (
        trip_id IN (
            SELECT trip_id
            FROM trip_members
            WHERE user_id = auth.uid()
        )
    );

-- Users can insert messages for trips they're members of
CREATE POLICY "Users can insert messages for their trips"
    ON messages
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND trip_id IN (
            SELECT trip_id
            FROM trip_members
            WHERE user_id = auth.uid()
        )
    );

-- Users can update their own messages (for editing, reactions, read status)
CREATE POLICY "Users can update messages in their trips"
    ON messages
    FOR UPDATE
    USING (
        trip_id IN (
            SELECT trip_id
            FROM trip_members
            WHERE user_id = auth.uid()
        )
    );

-- Users can soft-delete their own messages
CREATE POLICY "Users can delete their own messages"
    ON messages
    FOR UPDATE
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid());

-- ============================================================================
-- MESSAGE_QUEUE TABLE
-- ============================================================================
-- Stores messages that failed to send or are queued for offline sync
-- Used for retry logic and offline-first architecture
-- ============================================================================

CREATE TABLE IF NOT EXISTS message_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    message_data JSONB NOT NULL,
        -- Complete message object serialized as JSON
    transmission_method VARCHAR(20) DEFAULT 'internet',
        -- Values: 'internet', 'bluetooth', 'wifi_direct', 'relay'
    relay_path JSONB DEFAULT '[]'::jsonb,
        -- Array of device_ids that relayed this message (for P2P mesh)
    sync_status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- Values: 'pending', 'syncing', 'synced', 'failed'
    retry_count INTEGER DEFAULT 0,
    last_attempt_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- MESSAGE_QUEUE INDEXES
-- ============================================================================

-- Query pending messages for sync
CREATE INDEX IF NOT EXISTS idx_queue_pending
    ON message_queue(sync_status, created_at)
    WHERE sync_status IN ('pending', 'failed');

-- Query by trip for cleanup
CREATE INDEX IF NOT EXISTS idx_queue_trip
    ON message_queue(trip_id);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS messages_updated_at_trigger ON messages;
CREATE TRIGGER messages_updated_at_trigger
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_messages_updated_at();

-- ============================================================================
-- REALTIME PUBLICATION
-- ============================================================================
-- Enable realtime updates for messages table
-- This allows clients to receive instant notifications when messages are inserted/updated

-- Note: Run this in Supabase SQL Editor or via migration
-- ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- ============================================================================
-- CLEANUP FUNCTION
-- ============================================================================
-- Function to clean up old synced messages from queue (optional)

CREATE OR REPLACE FUNCTION cleanup_synced_queue()
RETURNS void AS $$
BEGIN
    DELETE FROM message_queue
    WHERE sync_status = 'synced'
    AND created_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE DATA (for testing - remove in production)
-- ============================================================================

-- Uncomment to insert sample messages for testing
/*
INSERT INTO messages (trip_id, sender_id, message, message_type) VALUES
    ((SELECT id FROM trips LIMIT 1), auth.uid(), 'Hello everyone! Ready for the trip?', 'text'),
    ((SELECT id FROM trips LIMIT 1), auth.uid(), 'Meeting at the airport at 8 AM', 'text');
*/

-- ============================================================================
-- USEFUL QUERIES
-- ============================================================================

-- Get all messages for a trip (most recent first)
-- SELECT * FROM messages WHERE trip_id = '<trip-id>' AND is_deleted = false ORDER BY created_at DESC LIMIT 50;

-- Get unread count for a trip
-- SELECT COUNT(*) FROM messages WHERE trip_id = '<trip-id>' AND NOT ('<user-id>' = ANY(SELECT jsonb_array_elements_text(read_by)));

-- Get pending messages in queue
-- SELECT * FROM message_queue WHERE sync_status IN ('pending', 'failed') ORDER BY created_at;

-- Mark message as read
-- UPDATE messages SET read_by = read_by || '["<user-id>"]'::jsonb WHERE id = '<message-id>';

-- Add reaction to message
-- UPDATE messages SET reactions = reactions || '[{"emoji": "👍", "user_id": "<user-id>", "created_at": "<timestamp>"}]'::jsonb WHERE id = '<message-id>';

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
-- 1. Run this schema after trips and profiles tables exist
-- 2. Ensure uuid_generate_v4() extension is enabled: CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- 3. Enable realtime for messages table in Supabase dashboard or via SQL
-- 4. Test RLS policies thoroughly before deploying to production
-- ============================================================================
