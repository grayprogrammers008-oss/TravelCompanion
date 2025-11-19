-- ============================================
-- Emergency Feature Database Schema (Idempotent)
-- ============================================
-- This script safely creates/updates all tables needed for the Emergency feature
-- Can be run multiple times without errors

-- ============================================
-- 1. Emergency Contacts Table
-- ============================================

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  email TEXT,
  relationship TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_phone_number CHECK (length(phone_number) >= 10),
  CONSTRAINT valid_name CHECK (length(name) >= 2)
);

-- Indexes for emergency_contacts
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_is_primary ON emergency_contacts(is_primary);

-- RLS Policies for emergency_contacts
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then recreate
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view their own emergency contacts" ON emergency_contacts;
    DROP POLICY IF EXISTS "Users can insert their own emergency contacts" ON emergency_contacts;
    DROP POLICY IF EXISTS "Users can update their own emergency contacts" ON emergency_contacts;
    DROP POLICY IF EXISTS "Users can delete their own emergency contacts" ON emergency_contacts;
END $$;

CREATE POLICY "Users can view their own emergency contacts"
  ON emergency_contacts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own emergency contacts"
  ON emergency_contacts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own emergency contacts"
  ON emergency_contacts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own emergency contacts"
  ON emergency_contacts FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 2. Emergency Alerts Table
-- ============================================

CREATE TABLE IF NOT EXISTS emergency_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('sos', 'help', 'medical')),
  status TEXT NOT NULL CHECK (status IN ('active', 'acknowledged', 'resolved', 'cancelled')),
  message TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  notified_contact_ids UUID[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}',

  -- Constraints
  CONSTRAINT valid_coordinates CHECK (
    (latitude IS NULL AND longitude IS NULL) OR
    (latitude >= -90 AND latitude <= 90 AND longitude >= -180 AND longitude <= 180)
  )
);

-- Indexes for emergency_alerts
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_user_id ON emergency_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_trip_id ON emergency_alerts(trip_id);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_status ON emergency_alerts(status);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_type ON emergency_alerts(type);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_created_at ON emergency_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_emergency_alerts_notified_contacts ON emergency_alerts USING GIN(notified_contact_ids);

-- RLS Policies for emergency_alerts
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then recreate
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view their own emergency alerts" ON emergency_alerts;
    DROP POLICY IF EXISTS "Users can view alerts where they are notified" ON emergency_alerts;
    DROP POLICY IF EXISTS "Users can insert their own emergency alerts" ON emergency_alerts;
    DROP POLICY IF EXISTS "Users can update their own emergency alerts" ON emergency_alerts;
    DROP POLICY IF EXISTS "Notified users can acknowledge alerts" ON emergency_alerts;
END $$;

CREATE POLICY "Users can view their own emergency alerts"
  ON emergency_alerts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view alerts where they are notified"
  ON emergency_alerts FOR SELECT
  USING (auth.uid() = ANY(notified_contact_ids));

CREATE POLICY "Users can insert their own emergency alerts"
  ON emergency_alerts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own emergency alerts"
  ON emergency_alerts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Notified users can acknowledge alerts"
  ON emergency_alerts FOR UPDATE
  USING (auth.uid() = ANY(notified_contact_ids))
  WITH CHECK (auth.uid() = ANY(notified_contact_ids));

-- ============================================
-- 3. Location Shares Table
-- ============================================

CREATE TABLE IF NOT EXISTS location_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  altitude DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'stopped')),
  message TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  shared_with_contact_ids UUID[] DEFAULT '{}',

  -- Constraints
  CONSTRAINT valid_coordinates CHECK (
    latitude >= -90 AND latitude <= 90 AND
    longitude >= -180 AND longitude <= 180
  ),
  CONSTRAINT valid_accuracy CHECK (accuracy IS NULL OR accuracy >= 0),
  CONSTRAINT valid_speed CHECK (speed IS NULL OR speed >= 0)
);

-- Indexes for location_shares
CREATE INDEX IF NOT EXISTS idx_location_shares_user_id ON location_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_location_shares_trip_id ON location_shares(trip_id);
CREATE INDEX IF NOT EXISTS idx_location_shares_status ON location_shares(status);
CREATE INDEX IF NOT EXISTS idx_location_shares_started_at ON location_shares(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_shares_last_updated_at ON location_shares(last_updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_shares_shared_with ON location_shares USING GIN(shared_with_contact_ids);

-- RLS Policies for location_shares
ALTER TABLE location_shares ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then recreate
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view their own location shares" ON location_shares;
    DROP POLICY IF EXISTS "Users can view location shares shared with them" ON location_shares;
    DROP POLICY IF EXISTS "Users can insert their own location shares" ON location_shares;
    DROP POLICY IF EXISTS "Users can update their own location shares" ON location_shares;
    DROP POLICY IF EXISTS "Users can delete their own location shares" ON location_shares;
END $$;

CREATE POLICY "Users can view their own location shares"
  ON location_shares FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view location shares shared with them"
  ON location_shares FOR SELECT
  USING (auth.uid() = ANY(shared_with_contact_ids));

CREATE POLICY "Users can insert their own location shares"
  ON location_shares FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own location shares"
  ON location_shares FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own location shares"
  ON location_shares FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- Triggers for updated_at timestamps
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for emergency_contacts
DROP TRIGGER IF EXISTS update_emergency_contacts_updated_at ON emergency_contacts;
CREATE TRIGGER update_emergency_contacts_updated_at
  BEFORE UPDATE ON emergency_contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to update last_updated_at for location_shares
CREATE OR REPLACE FUNCTION update_location_shares_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for location_shares
DROP TRIGGER IF EXISTS update_location_shares_timestamp ON location_shares;
CREATE TRIGGER update_location_shares_timestamp
  BEFORE UPDATE ON location_shares
  FOR EACH ROW
  EXECUTE FUNCTION update_location_shares_timestamp();

-- ============================================
-- Realtime Subscriptions
-- ============================================

-- Enable realtime for emergency_alerts (for active alerts monitoring)
-- Use DO block to handle if already exists
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE emergency_alerts;
EXCEPTION
    WHEN duplicate_object THEN
        NULL; -- Table already in publication, ignore error
END $$;

-- Enable realtime for location_shares (for live location tracking)
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE location_shares;
EXCEPTION
    WHEN duplicate_object THEN
        NULL; -- Table already in publication, ignore error
END $$;

-- ============================================
-- Helper Functions
-- ============================================

-- Function to get active location share for a user
CREATE OR REPLACE FUNCTION get_active_location_share(p_user_id UUID)
RETURNS location_shares AS $$
  SELECT * FROM location_shares
  WHERE user_id = p_user_id
    AND status = 'active'
    AND (expires_at IS NULL OR expires_at > NOW())
  ORDER BY started_at DESC
  LIMIT 1;
$$ LANGUAGE SQL STABLE;

-- Function to get active alerts for a user
CREATE OR REPLACE FUNCTION get_active_alerts(p_user_id UUID)
RETURNS SETOF emergency_alerts AS $$
  SELECT * FROM emergency_alerts
  WHERE user_id = p_user_id
    AND status IN ('active', 'acknowledged')
  ORDER BY created_at DESC;
$$ LANGUAGE SQL STABLE;

-- Function to get received alerts (where user is a notified contact)
CREATE OR REPLACE FUNCTION get_received_alerts(p_user_id UUID)
RETURNS SETOF emergency_alerts AS $$
  SELECT * FROM emergency_alerts
  WHERE p_user_id = ANY(notified_contact_ids)
    AND status IN ('active', 'acknowledged')
  ORDER BY created_at DESC;
$$ LANGUAGE SQL STABLE;

-- ============================================
-- Comments for Documentation
-- ============================================

COMMENT ON TABLE emergency_contacts IS 'Stores emergency contact information for users';
COMMENT ON TABLE emergency_alerts IS 'Tracks emergency alerts (SOS, help requests, medical emergencies)';
COMMENT ON TABLE location_shares IS 'Tracks real-time location sharing sessions';

COMMENT ON COLUMN emergency_contacts.is_primary IS 'Primary contact will be notified first in emergencies';
COMMENT ON COLUMN emergency_alerts.type IS 'Type of emergency: sos (critical), help (assistance needed), medical (medical emergency)';
COMMENT ON COLUMN emergency_alerts.status IS 'Alert lifecycle: active → acknowledged → resolved/cancelled';
COMMENT ON COLUMN emergency_alerts.notified_contact_ids IS 'Array of contact user IDs who were notified about this alert';
COMMENT ON COLUMN location_shares.status IS 'Sharing status: active (sharing), paused (temporarily stopped), stopped (ended)';
COMMENT ON COLUMN location_shares.shared_with_contact_ids IS 'Array of user IDs who can view this location share';

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify all tables were created:
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'public'
-- AND table_name IN ('emergency_contacts', 'emergency_alerts', 'location_shares');
