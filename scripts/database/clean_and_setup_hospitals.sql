-- ============================================
-- COMPLETE CLEAN AND SETUP FOR HOSPITALS
-- ============================================
-- This script completely removes any existing hospitals setup
-- and creates everything fresh with PostGIS enabled
--
-- IMPORTANT: Run this entire script at once
-- ============================================

-- ============================================
-- STEP 1: ENABLE POSTGIS (CRITICAL!)
-- ============================================

-- Enable PostGIS extension - this MUST succeed
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify PostGIS is working (will error if not available)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'postgis'
    ) THEN
        RAISE EXCEPTION 'PostGIS extension is not available. Contact Supabase support.';
    END IF;
END $$;

-- ============================================
-- STEP 2: DROP EVERYTHING (Clean slate)
-- ============================================

-- Drop all dependent objects first
DROP TRIGGER IF EXISTS trigger_update_hospital_location ON hospitals CASCADE;
DROP TRIGGER IF EXISTS trigger_update_hospitals_timestamp ON hospitals CASCADE;

-- Drop all functions
DROP FUNCTION IF EXISTS find_nearest_hospitals CASCADE;
DROP FUNCTION IF EXISTS get_hospital_with_distance CASCADE;
DROP FUNCTION IF EXISTS search_hospitals CASCADE;
DROP FUNCTION IF EXISTS search_hospitals_by_name CASCADE;
DROP FUNCTION IF EXISTS get_hospitals_by_city CASCADE;
DROP FUNCTION IF EXISTS update_hospital_location CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

-- Drop the table
DROP TABLE IF EXISTS hospitals CASCADE;

-- ============================================
-- STEP 3: CREATE TABLE WITH POSTGIS
-- ============================================

CREATE TABLE hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT DEFAULT 'USA' NOT NULL,
  postal_code TEXT,

  -- Coordinates
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  location GEOGRAPHY(POINT, 4326),

  -- Contact
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  email TEXT,

  -- Type
  type TEXT NOT NULL CHECK (type IN ('general', 'specialized', 'emergency', 'trauma_center', 'urgent_care')),
  capacity INTEGER CHECK (capacity IS NULL OR capacity > 0),
  has_emergency_room BOOLEAN DEFAULT TRUE NOT NULL,
  has_trauma_center BOOLEAN DEFAULT FALSE NOT NULL,
  trauma_level TEXT CHECK (trauma_level IS NULL OR trauma_level IN ('I', 'II', 'III', 'IV', 'V')),
  accepts_ambulance BOOLEAN DEFAULT TRUE NOT NULL,

  -- Hours
  is_24_7 BOOLEAN DEFAULT TRUE NOT NULL,
  opening_hours JSONB DEFAULT '{}',

  -- Services
  services TEXT[] DEFAULT '{}',
  specialties TEXT[] DEFAULT '{}',

  -- Ratings
  rating DOUBLE PRECISION CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5)),
  total_reviews INTEGER DEFAULT 0 NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE NOT NULL,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',

  CONSTRAINT valid_coordinates CHECK (
    latitude >= -90 AND latitude <= 90 AND
    longitude >= -180 AND longitude <= 180
  )
);

-- ============================================
-- STEP 4: VERIFY TABLE WAS CREATED
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'hospitals' AND column_name = 'location'
    ) THEN
        RAISE EXCEPTION 'Hospital table was created but location column is missing. PostGIS may not be properly enabled.';
    END IF;

    RAISE NOTICE 'SUCCESS: Hospitals table created with PostGIS location column';
END $$;

-- ============================================
-- STEP 5: CREATE INDEXES
-- ============================================

CREATE INDEX idx_hospitals_location ON hospitals USING GIST(location);
CREATE INDEX idx_hospitals_city ON hospitals(city);
CREATE INDEX idx_hospitals_state ON hospitals(state);
CREATE INDEX idx_hospitals_type ON hospitals(type);
CREATE INDEX idx_hospitals_is_active ON hospitals(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_hospitals_has_emergency_room ON hospitals(has_emergency_room) WHERE has_emergency_room = TRUE;
CREATE INDEX idx_hospitals_is_24_7 ON hospitals(is_24_7) WHERE is_24_7 = TRUE;
CREATE INDEX idx_hospitals_rating ON hospitals(rating DESC NULLS LAST);
CREATE INDEX idx_hospitals_emergency_active ON hospitals(is_active, has_emergency_room, is_24_7)
  WHERE is_active = TRUE AND has_emergency_room = TRUE;
CREATE INDEX idx_hospitals_services ON hospitals USING GIN(services);
CREATE INDEX idx_hospitals_specialties ON hospitals USING GIN(specialties);

-- ============================================
-- STEP 6: CREATE TRIGGER FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION update_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
  NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 7: CREATE TRIGGERS
-- ============================================

CREATE TRIGGER trigger_update_hospital_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_hospital_location();

CREATE TRIGGER trigger_update_hospitals_timestamp
  BEFORE UPDATE ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 8: INSERT ONE TEST HOSPITAL
-- ============================================

INSERT INTO hospitals (
  name, address, city, state, latitude, longitude,
  phone_number, type, has_emergency_room, is_24_7
) VALUES (
  'Test Hospital - DELETE ME',
  '123 Test Street',
  'New York',
  'NY',
  40.7128,
  -74.0060,
  '+1-555-TEST',
  'general',
  TRUE,
  TRUE
);

-- Verify the trigger worked
DO $$
DECLARE
  loc_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO loc_count
  FROM hospitals
  WHERE name = 'Test Hospital - DELETE ME' AND location IS NOT NULL;

  IF loc_count = 0 THEN
    RAISE EXCEPTION 'TEST FAILED: Location trigger did not populate location column';
  END IF;

  RAISE NOTICE 'SUCCESS: Test hospital inserted and location auto-populated';
END $$;

-- Clean up test
DELETE FROM hospitals WHERE name = 'Test Hospital - DELETE ME';

-- ============================================
-- DONE! Now you can run hospitals_complete_setup.sql
-- to add the functions and sample data
-- ============================================

RAISE NOTICE '========================================';
RAISE NOTICE 'SETUP COMPLETE!';
RAISE NOTICE 'Table created successfully with PostGIS';
RAISE NOTICE 'Indexes created';
RAISE NOTICE 'Triggers working';
RAISE NOTICE '';
RAISE NOTICE 'Next step: Run hospitals_complete_setup.sql';
RAISE NOTICE 'to add PostgreSQL functions and sample data';
RAISE NOTICE '========================================';
