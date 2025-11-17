-- ============================================
-- Hospitals Database Schema
-- ============================================
-- This script creates the hospitals table for the Emergency feature
-- to help users find nearest available hospitals during emergencies.

-- ============================================
-- 0. Enable Required Extensions
-- ============================================

-- Enable cube extension (required for earthdistance)
CREATE EXTENSION IF NOT EXISTS cube;

-- Enable earthdistance extension for geospatial distance calculations
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- ============================================
-- 1. Hospitals Table
-- ============================================

CREATE TABLE IF NOT EXISTS hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'USA',
  postal_code TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  email TEXT,

  -- Hospital Details
  type TEXT NOT NULL CHECK (type IN ('general', 'specialized', 'emergency', 'trauma_center', 'urgent_care')),
  capacity INTEGER,
  has_emergency_room BOOLEAN DEFAULT TRUE,
  has_trauma_center BOOLEAN DEFAULT FALSE,
  trauma_level TEXT CHECK (trauma_level IN ('I', 'II', 'III', 'IV', 'V', NULL)),
  accepts_ambulance BOOLEAN DEFAULT TRUE,

  -- Operating Hours
  is_24_7 BOOLEAN DEFAULT TRUE,
  opening_hours JSONB DEFAULT '{}',

  -- Services Available
  services JSONB DEFAULT '[]',
  specialties JSONB DEFAULT '[]',

  -- Ratings and Status
  rating DECIMAL(2, 1) CHECK (rating >= 0 AND rating <= 5),
  total_reviews INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',

  -- Constraints
  CONSTRAINT valid_coordinates CHECK (
    latitude >= -90 AND latitude <= 90 AND
    longitude >= -180 AND longitude <= 180
  ),
  CONSTRAINT valid_capacity CHECK (capacity IS NULL OR capacity > 0),
  CONSTRAINT valid_rating CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5))
);

-- ============================================
-- 2. Indexes for Performance
-- ============================================

-- Geospatial index for location-based queries
CREATE INDEX IF NOT EXISTS idx_hospitals_location ON hospitals USING GIST (
  ll_to_earth(latitude, longitude)
);

-- Regular indexes
CREATE INDEX IF NOT EXISTS idx_hospitals_name ON hospitals(name);
CREATE INDEX IF NOT EXISTS idx_hospitals_city ON hospitals(city);
CREATE INDEX IF NOT EXISTS idx_hospitals_state ON hospitals(state);
CREATE INDEX IF NOT EXISTS idx_hospitals_type ON hospitals(type);
CREATE INDEX IF NOT EXISTS idx_hospitals_is_active ON hospitals(is_active);
CREATE INDEX IF NOT EXISTS idx_hospitals_has_emergency_room ON hospitals(has_emergency_room);
CREATE INDEX IF NOT EXISTS idx_hospitals_has_trauma_center ON hospitals(has_trauma_center);
CREATE INDEX IF NOT EXISTS idx_hospitals_is_24_7 ON hospitals(is_24_7);
CREATE INDEX IF NOT EXISTS idx_hospitals_rating ON hospitals(rating DESC);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_hospitals_active_emergency ON hospitals(is_active, has_emergency_room);
CREATE INDEX IF NOT EXISTS idx_hospitals_city_state ON hospitals(city, state);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_hospitals_services ON hospitals USING GIN(services);
CREATE INDEX IF NOT EXISTS idx_hospitals_specialties ON hospitals USING GIN(specialties);

-- ============================================
-- 3. Row Level Security (RLS)
-- ============================================

ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;

-- Public read access for all authenticated users
CREATE POLICY "Authenticated users can view active hospitals"
  ON hospitals FOR SELECT
  USING (auth.role() = 'authenticated' AND is_active = TRUE);

-- Admin-only write access (you'll need to define admin role)
CREATE POLICY "Only admins can insert hospitals"
  ON hospitals FOR INSERT
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can update hospitals"
  ON hospitals FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Only admins can delete hospitals"
  ON hospitals FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');

-- ============================================
-- 4. Trigger for updated_at
-- ============================================

-- Reuse the update_updated_at_column function from emergency_schema
DROP TRIGGER IF EXISTS update_hospitals_updated_at ON hospitals;
CREATE TRIGGER update_hospitals_updated_at
  BEFORE UPDATE ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. Helper Functions
-- ============================================

-- Function to find nearest hospitals
CREATE OR REPLACE FUNCTION find_nearest_hospitals(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50,
  result_limit INTEGER DEFAULT 10,
  only_emergency BOOLEAN DEFAULT TRUE,
  only_24_7 BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone_number TEXT,
  emergency_phone TEXT,
  type TEXT,
  has_emergency_room BOOLEAN,
  has_trauma_center BOOLEAN,
  trauma_level TEXT,
  is_24_7 BOOLEAN,
  rating DECIMAL,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    h.id,
    h.name,
    h.address,
    h.city,
    h.state,
    h.latitude,
    h.longitude,
    h.phone_number,
    h.emergency_phone,
    h.type,
    h.has_emergency_room,
    h.has_trauma_center,
    h.trauma_level,
    h.is_24_7,
    h.rating,
    earth_distance(
      ll_to_earth(user_lat, user_lng),
      ll_to_earth(h.latitude, h.longitude)
    ) / 1000.0 AS distance_km
  FROM hospitals h
  WHERE
    h.is_active = TRUE
    AND (NOT only_emergency OR h.has_emergency_room = TRUE)
    AND (NOT only_24_7 OR h.is_24_7 = TRUE)
    AND earth_distance(
      ll_to_earth(user_lat, user_lng),
      ll_to_earth(h.latitude, h.longitude)
    ) / 1000.0 <= max_distance_km
  ORDER BY distance_km ASC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to search hospitals by name or city
CREATE OR REPLACE FUNCTION search_hospitals(
  search_term TEXT,
  search_city TEXT DEFAULT NULL,
  search_state TEXT DEFAULT NULL,
  result_limit INTEGER DEFAULT 20
)
RETURNS SETOF hospitals AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM hospitals h
  WHERE
    h.is_active = TRUE
    AND (
      h.name ILIKE '%' || search_term || '%'
      OR h.city ILIKE '%' || search_term || '%'
      OR h.address ILIKE '%' || search_term || '%'
    )
    AND (search_city IS NULL OR h.city ILIKE search_city)
    AND (search_state IS NULL OR h.state ILIKE search_state)
  ORDER BY
    CASE
      WHEN h.name ILIKE search_term || '%' THEN 1
      WHEN h.name ILIKE '%' || search_term || '%' THEN 2
      ELSE 3
    END,
    h.rating DESC NULLS LAST
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get hospital by ID with distance from user
CREATE OR REPLACE FUNCTION get_hospital_with_distance(
  hospital_id UUID,
  user_lat DOUBLE PRECISION DEFAULT NULL,
  user_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  type TEXT,
  has_emergency_room BOOLEAN,
  has_trauma_center BOOLEAN,
  trauma_level TEXT,
  is_24_7 BOOLEAN,
  services JSONB,
  specialties JSONB,
  rating DECIMAL,
  distance_km DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    h.id,
    h.name,
    h.address,
    h.city,
    h.state,
    h.country,
    h.latitude,
    h.longitude,
    h.phone_number,
    h.emergency_phone,
    h.website,
    h.type,
    h.has_emergency_room,
    h.has_trauma_center,
    h.trauma_level,
    h.is_24_7,
    h.services,
    h.specialties,
    h.rating,
    CASE
      WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
        earth_distance(
          ll_to_earth(user_lat, user_lng),
          ll_to_earth(h.latitude, h.longitude)
        ) / 1000.0
      ELSE NULL
    END AS distance_km
  FROM hospitals h
  WHERE h.id = hospital_id AND h.is_active = TRUE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 6. Sample Data (Optional - for testing)
-- ============================================

-- Insert sample hospitals (San Francisco Bay Area)
INSERT INTO hospitals (name, address, city, state, latitude, longitude, phone_number, emergency_phone, type, has_emergency_room, has_trauma_center, trauma_level, is_24_7, rating, services, specialties) VALUES
  ('UCSF Medical Center', '505 Parnassus Ave', 'San Francisco', 'CA', 37.7625, -122.4589, '+1-415-476-1000', '911', 'trauma_center', TRUE, TRUE, 'I', TRUE, 4.5, '["emergency", "surgery", "cardiology", "neurology", "oncology"]', '["trauma", "cardiac", "neuro", "pediatric"]'),
  ('San Francisco General Hospital', '1001 Potrero Ave', 'San Francisco', 'CA', 37.7571, -122.4045, '+1-415-206-8000', '911', 'trauma_center', TRUE, TRUE, 'I', TRUE, 4.3, '["emergency", "surgery", "trauma", "burn_unit"]', '["trauma", "burn", "psychiatric"]'),
  ('California Pacific Medical Center', '2333 Buchanan St', 'San Francisco', 'CA', 37.7917, -122.4314, '+1-415-600-6000', '911', 'general', TRUE, FALSE, NULL, TRUE, 4.4, '["emergency", "surgery", "maternity", "orthopedics"]', '["orthopedic", "maternity", "cardiac"]'),
  ('Stanford Hospital', '300 Pasteur Dr', 'Stanford', 'CA', 37.4419, -122.1711, '+1-650-723-4000', '911', 'trauma_center', TRUE, TRUE, 'I', TRUE, 4.7, '["emergency", "surgery", "cardiology", "neurology", "oncology", "transplant"]', '["cardiac", "neuro", "oncology", "transplant"]'),
  ('Kaiser Permanente San Francisco', '2425 Geary Blvd', 'San Francisco', 'CA', 37.7829, -122.4364, '+1-415-833-2000', '911', 'general', TRUE, FALSE, NULL, TRUE, 4.2, '["emergency", "primary_care", "urgent_care", "lab"]', '["family_medicine", "internal_medicine"]')
ON CONFLICT DO NOTHING;

-- ============================================
-- 7. Comments for Documentation
-- ============================================

COMMENT ON TABLE hospitals IS 'Stores hospital information for emergency services and medical assistance';
COMMENT ON COLUMN hospitals.type IS 'Type of hospital: general, specialized, emergency, trauma_center, urgent_care';
COMMENT ON COLUMN hospitals.trauma_level IS 'Trauma center level (I is highest): I, II, III, IV, V';
COMMENT ON COLUMN hospitals.services IS 'JSON array of available services';
COMMENT ON COLUMN hospitals.specialties IS 'JSON array of medical specialties';
COMMENT ON COLUMN hospitals.is_24_7 IS 'Whether the hospital operates 24/7';
COMMENT ON COLUMN hospitals.has_emergency_room IS 'Whether the hospital has an emergency room';
COMMENT ON COLUMN hospitals.has_trauma_center IS 'Whether the hospital has a trauma center';

COMMENT ON FUNCTION find_nearest_hospitals IS 'Find nearest hospitals to a given location within a specified distance';
COMMENT ON FUNCTION search_hospitals IS 'Search hospitals by name, city, or address';
COMMENT ON FUNCTION get_hospital_with_distance IS 'Get hospital details with distance from user location';
