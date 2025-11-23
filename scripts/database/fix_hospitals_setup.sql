-- ============================================
-- DIAGNOSTIC AND FIX SCRIPT FOR HOSPITALS TABLE
-- ============================================
-- Run this script to diagnose and fix the hospitals setup issue
--
-- Step 1: Check if PostGIS is enabled
-- Step 2: Drop and recreate the hospitals table if needed
-- Step 3: Verify everything is working
-- ============================================

-- ============================================
-- 1. ENABLE POSTGIS (Run this first)
-- ============================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify PostGIS is installed
SELECT PostGIS_Version();

-- ============================================
-- 2. DROP EXISTING OBJECTS (Clean slate)
-- ============================================

-- Drop triggers first
DROP TRIGGER IF EXISTS trigger_update_hospital_location ON hospitals;
DROP TRIGGER IF EXISTS trigger_update_hospitals_timestamp ON hospitals;

-- Drop functions
DROP FUNCTION IF EXISTS find_nearest_hospitals CASCADE;
DROP FUNCTION IF EXISTS get_hospital_with_distance CASCADE;
DROP FUNCTION IF EXISTS search_hospitals CASCADE;
DROP FUNCTION IF EXISTS search_hospitals_by_name CASCADE;
DROP FUNCTION IF EXISTS get_hospitals_by_city CASCADE;
DROP FUNCTION IF EXISTS update_hospital_location CASCADE;

-- Drop table
DROP TABLE IF EXISTS hospitals CASCADE;

-- ============================================
-- 3. CREATE HOSPITALS TABLE WITH POSTGIS
-- ============================================

CREATE TABLE hospitals (
  -- Primary Information
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,

  -- Location Details
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT DEFAULT 'USA' NOT NULL,
  postal_code TEXT,

  -- Geospatial Coordinates
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  location GEOGRAPHY(POINT, 4326), -- PostGIS geography point

  -- Contact Information
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  email TEXT,

  -- Hospital Type and Capabilities
  type TEXT NOT NULL CHECK (type IN ('general', 'specialized', 'emergency', 'trauma_center', 'urgent_care')),
  capacity INTEGER CHECK (capacity IS NULL OR capacity > 0),
  has_emergency_room BOOLEAN DEFAULT TRUE NOT NULL,
  has_trauma_center BOOLEAN DEFAULT FALSE NOT NULL,
  trauma_level TEXT CHECK (trauma_level IS NULL OR trauma_level IN ('I', 'II', 'III', 'IV', 'V')),
  accepts_ambulance BOOLEAN DEFAULT TRUE NOT NULL,

  -- Operating Hours
  is_24_7 BOOLEAN DEFAULT TRUE NOT NULL,
  opening_hours JSONB DEFAULT '{}',

  -- Services and Specialties
  services TEXT[] DEFAULT '{}',
  specialties TEXT[] DEFAULT '{}',

  -- Ratings and Status
  rating DOUBLE PRECISION CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5)),
  total_reviews INTEGER DEFAULT 0 NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE NOT NULL,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',

  -- Constraints
  CONSTRAINT valid_coordinates CHECK (
    latitude >= -90 AND latitude <= 90 AND
    longitude >= -180 AND longitude <= 180
  )
);

-- ============================================
-- 4. VERIFY TABLE WAS CREATED
-- ============================================

-- Check if the location column exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'hospitals'
  AND column_name = 'location';

-- This should return: location | USER-DEFINED

-- ============================================
-- 5. CREATE TRIGGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
  NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. CREATE TRIGGER
-- ============================================

CREATE TRIGGER trigger_update_hospital_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_hospital_location();

-- ============================================
-- 7. TEST WITH SAMPLE INSERT
-- ============================================

-- Insert one test hospital
INSERT INTO hospitals (
  name, address, city, state, latitude, longitude,
  phone_number, type, has_emergency_room
) VALUES (
  'Test Hospital',
  '123 Test Street',
  'Test City',
  'NY',
  40.7128,
  -74.0060,
  '+1-555-0100',
  'general',
  TRUE
);

-- Verify the location was auto-populated
SELECT
  id,
  name,
  latitude,
  longitude,
  ST_AsText(location::geometry) as location_wkt,
  location IS NOT NULL as has_location
FROM hospitals
WHERE name = 'Test Hospital';

-- This should show the location is populated

-- Clean up test data
DELETE FROM hospitals WHERE name = 'Test Hospital';

-- ============================================
-- SUCCESS! Now run the main hospitals_complete_setup.sql
-- ============================================
