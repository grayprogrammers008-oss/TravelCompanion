-- ============================================
-- Hospitals Database Setup for Travel Companion
-- ============================================
-- This script creates the hospitals table, geospatial indexes,
-- the find_nearest_hospitals function, and sample hospital data.
--
-- IMPORTANT: This script is idempotent and can be run multiple times.
-- It uses CREATE OR REPLACE and IF NOT EXISTS to prevent errors.
--
-- Prerequisites:
-- - PostgreSQL with PostGIS extension (included in Supabase)
-- - Authenticated user (for testing)
--
-- ============================================

-- ============================================
-- 1. Enable PostGIS Extension (if not enabled)
-- ============================================
-- PostGIS provides geospatial functionality for distance calculations

CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- 2. Create Hospitals Table
-- ============================================

CREATE TABLE IF NOT EXISTS hospitals (
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
  location GEOGRAPHY(POINT, 4326), -- PostGIS geography point for efficient distance queries

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

  -- Services and Specialties (Arrays for flexibility)
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
  ),
  CONSTRAINT valid_rating CHECK (rating IS NULL OR (rating >= 0 AND rating <= 5)),
  CONSTRAINT valid_total_reviews CHECK (total_reviews >= 0)
);

-- ============================================
-- 3. Create Indexes for Performance
-- ============================================

-- Geospatial index for efficient distance queries (CRITICAL for performance)
CREATE INDEX IF NOT EXISTS idx_hospitals_location ON hospitals USING GIST(location);

-- Regular indexes for common queries
CREATE INDEX IF NOT EXISTS idx_hospitals_city ON hospitals(city);
CREATE INDEX IF NOT EXISTS idx_hospitals_state ON hospitals(state);
CREATE INDEX IF NOT EXISTS idx_hospitals_country ON hospitals(country);
CREATE INDEX IF NOT EXISTS idx_hospitals_type ON hospitals(type);
CREATE INDEX IF NOT EXISTS idx_hospitals_is_active ON hospitals(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_hospitals_has_emergency_room ON hospitals(has_emergency_room) WHERE has_emergency_room = TRUE;
CREATE INDEX IF NOT EXISTS idx_hospitals_is_24_7 ON hospitals(is_24_7) WHERE is_24_7 = TRUE;
CREATE INDEX IF NOT EXISTS idx_hospitals_rating ON hospitals(rating DESC NULLS LAST);

-- Composite index for common emergency queries
CREATE INDEX IF NOT EXISTS idx_hospitals_emergency_active ON hospitals(is_active, has_emergency_room, is_24_7)
  WHERE is_active = TRUE AND has_emergency_room = TRUE;

-- GIN index for array columns (services and specialties)
CREATE INDEX IF NOT EXISTS idx_hospitals_services ON hospitals USING GIN(services);
CREATE INDEX IF NOT EXISTS idx_hospitals_specialties ON hospitals USING GIN(specialties);

-- ============================================
-- 4. Create Trigger to Auto-Update Location Geography
-- ============================================

-- Function to automatically set location from lat/lng
CREATE OR REPLACE FUNCTION update_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the geography point whenever lat/lng changes
  NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists, then recreate
DROP TRIGGER IF EXISTS trigger_update_hospital_location ON hospitals;

CREATE TRIGGER trigger_update_hospital_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_hospital_location();

-- ============================================
-- 5. Create Trigger for Updated_At Timestamp
-- ============================================

-- Reuse the update_updated_at_column function if it exists from emergency schema
-- Otherwise create it
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists, then recreate
DROP TRIGGER IF EXISTS trigger_update_hospitals_timestamp ON hospitals;

CREATE TRIGGER trigger_update_hospitals_timestamp
  BEFORE UPDATE ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. Create find_nearest_hospitals Function
-- ============================================

CREATE OR REPLACE FUNCTION find_nearest_hospitals(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50.0,
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
  country TEXT,
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  email TEXT,
  type TEXT,
  capacity INTEGER,
  has_emergency_room BOOLEAN,
  has_trauma_center BOOLEAN,
  trauma_level TEXT,
  accepts_ambulance BOOLEAN,
  is_24_7 BOOLEAN,
  opening_hours JSONB,
  services TEXT[],
  specialties TEXT[],
  rating DOUBLE PRECISION,
  total_reviews INTEGER,
  is_active BOOLEAN,
  is_verified BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  metadata JSONB,
  distance_km DOUBLE PRECISION
) AS $$
DECLARE
  user_location GEOGRAPHY;
BEGIN
  -- Create geography point for user location
  user_location := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;

  -- Return hospitals with distance calculation
  RETURN QUERY
  SELECT
    h.id,
    h.name,
    h.address,
    h.city,
    h.state,
    h.country,
    h.postal_code,
    h.latitude,
    h.longitude,
    h.phone_number,
    h.emergency_phone,
    h.website,
    h.email,
    h.type,
    h.capacity,
    h.has_emergency_room,
    h.has_trauma_center,
    h.trauma_level,
    h.accepts_ambulance,
    h.is_24_7,
    h.opening_hours,
    h.services,
    h.specialties,
    h.rating,
    h.total_reviews,
    h.is_active,
    h.is_verified,
    h.created_at,
    h.updated_at,
    h.metadata,
    -- Calculate distance in kilometers using PostGIS
    ROUND((ST_Distance(h.location, user_location) / 1000.0)::NUMERIC, 2)::DOUBLE PRECISION AS distance_km
  FROM hospitals h
  WHERE
    h.is_active = TRUE
    -- Filter by emergency room if requested
    AND (NOT only_emergency OR h.has_emergency_room = TRUE)
    -- Filter by 24/7 availability if requested
    AND (NOT only_24_7 OR h.is_24_7 = TRUE)
    -- Filter by distance (convert km to meters for ST_DWithin)
    AND ST_DWithin(h.location, user_location, max_distance_km * 1000)
  ORDER BY
    -- Sort by distance (closest first)
    h.location <-> user_location,
    -- Secondary sort by rating (highest first)
    h.rating DESC NULLS LAST,
    -- Tertiary sort by trauma level (Level I first)
    CASE h.trauma_level
      WHEN 'I' THEN 1
      WHEN 'II' THEN 2
      WHEN 'III' THEN 3
      WHEN 'IV' THEN 4
      WHEN 'V' THEN 5
      ELSE 6
    END
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 7. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on hospitals table
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can view active hospitals" ON hospitals;
    DROP POLICY IF EXISTS "Only admins can insert hospitals" ON hospitals;
    DROP POLICY IF EXISTS "Only admins can update hospitals" ON hospitals;
    DROP POLICY IF EXISTS "Only admins can delete hospitals" ON hospitals;
END $$;

-- Public read access for active hospitals (hospitals are public information)
CREATE POLICY "Anyone can view active hospitals"
  ON hospitals FOR SELECT
  USING (is_active = TRUE);

-- NOTE: For insert/update/delete, you'll need to implement admin role checking
-- This is a basic example - adjust based on your auth setup

-- Only authenticated users can insert (you can add admin role check here)
CREATE POLICY "Only admins can insert hospitals"
  ON hospitals FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL); -- Replace with actual admin check

-- Only authenticated users can update (you can add admin role check here)
CREATE POLICY "Only admins can update hospitals"
  ON hospitals FOR UPDATE
  USING (auth.uid() IS NOT NULL) -- Replace with actual admin check
  WITH CHECK (auth.uid() IS NOT NULL);

-- Only authenticated users can delete (you can add admin role check here)
CREATE POLICY "Only admins can delete hospitals"
  ON hospitals FOR DELETE
  USING (auth.uid() IS NOT NULL); -- Replace with actual admin check

-- ============================================
-- 8. Sample Hospital Data
-- ============================================
-- Insert sample hospitals for testing
-- This includes a variety of hospitals across different US cities

-- Clear existing sample data (optional - comment out if you want to keep existing data)
-- DELETE FROM hospitals WHERE metadata->>'is_sample_data' = 'true';

INSERT INTO hospitals (
  name, address, city, state, country, postal_code,
  latitude, longitude,
  phone_number, emergency_phone, website, email,
  type, capacity, has_emergency_room, has_trauma_center, trauma_level, accepts_ambulance,
  is_24_7, services, specialties, rating, total_reviews, is_verified, metadata
) VALUES
-- New York City Area
(
  'Mount Sinai Hospital',
  '1468 Madison Avenue',
  'New York',
  'NY',
  'USA',
  '10029',
  40.7903,
  -73.9529,
  '+1-212-241-6500',
  '+1-212-241-9111',
  'https://www.mountsinai.org',
  'info@mountsinai.org',
  'trauma_center',
  1134,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care', 'Pediatric Emergency', 'Stroke Center'],
  ARRAY['Cardiology', 'Neurology', 'Orthopedics', 'Emergency Medicine'],
  4.7,
  2845,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),
(
  'NewYork-Presbyterian Hospital',
  '525 East 68th Street',
  'New York',
  'NY',
  'USA',
  '10065',
  40.7654,
  -73.9541,
  '+1-212-746-5454',
  '+1-212-746-0911',
  'https://www.nyp.org',
  'emergency@nyp.org',
  'trauma_center',
  2478,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Cardiac Care', 'Neonatal ICU'],
  ARRAY['Cardiology', 'Oncology', 'Neurosurgery', 'Emergency Medicine'],
  4.8,
  4521,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Los Angeles Area
(
  'Cedars-Sinai Medical Center',
  '8700 Beverly Boulevard',
  'Los Angeles',
  'CA',
  'USA',
  '90048',
  34.0754,
  -118.3773,
  '+1-310-423-3277',
  '+1-310-423-5911',
  'https://www.cedars-sinai.org',
  'info@cshs.org',
  'trauma_center',
  886,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care', 'Stroke Center'],
  ARRAY['Cardiology', 'Oncology', 'Neurology', 'Orthopedics'],
  4.6,
  3267,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),
(
  'UCLA Medical Center',
  '757 Westwood Plaza',
  'Los Angeles',
  'CA',
  'USA',
  '90095',
  34.0652,
  -118.4453,
  '+1-310-825-9111',
  '+1-310-825-2111',
  'https://www.uclahealth.org',
  'emergency@mednet.ucla.edu',
  'trauma_center',
  520,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Pediatric Emergency'],
  ARRAY['Emergency Medicine', 'Neurosurgery', 'Cardiology'],
  4.7,
  2891,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Chicago Area
(
  'Northwestern Memorial Hospital',
  '251 East Huron Street',
  'Chicago',
  'IL',
  'USA',
  '60611',
  41.8956,
  -87.6211,
  '+1-312-926-2000',
  '+1-312-926-5188',
  'https://www.nm.org',
  'info@nm.org',
  'trauma_center',
  894,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care', 'Stroke Center'],
  ARRAY['Cardiology', 'Neurology', 'Orthopedics', 'Emergency Medicine'],
  4.6,
  3124,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),
(
  'Rush University Medical Center',
  '1653 West Congress Parkway',
  'Chicago',
  'IL',
  'USA',
  '60612',
  41.8745,
  -87.6706,
  '+1-312-942-5000',
  '+1-312-942-6911',
  'https://www.rush.edu',
  'emergency@rush.edu',
  'trauma_center',
  664,
  TRUE,
  TRUE,
  'II',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care'],
  ARRAY['Emergency Medicine', 'Cardiology', 'Orthopedics'],
  4.5,
  2456,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Houston Area
(
  'Texas Medical Center',
  '6565 Fannin Street',
  'Houston',
  'TX',
  'USA',
  '77030',
  29.7074,
  -95.4018,
  '+1-713-704-4000',
  '+1-713-704-4911',
  'https://www.tmc.edu',
  'info@tmc.edu',
  'trauma_center',
  1785,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care', 'Burn Unit', 'Pediatric Emergency'],
  ARRAY['Emergency Medicine', 'Cardiology', 'Neurosurgery', 'Oncology'],
  4.8,
  5234,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Miami Area
(
  'Jackson Memorial Hospital',
  '1611 NW 12th Avenue',
  'Miami',
  'FL',
  'USA',
  '33136',
  25.7931,
  -80.2109,
  '+1-305-585-1111',
  '+1-305-585-6911',
  'https://www.jacksonhealth.org',
  'info@jhsmiami.org',
  'trauma_center',
  1550,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Cardiac Care', 'Pediatric Emergency'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Cardiology', 'Neurology'],
  4.5,
  2987,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Seattle Area
(
  'Harborview Medical Center',
  '325 9th Avenue',
  'Seattle',
  'WA',
  'USA',
  '98104',
  47.6052,
  -122.3241,
  '+1-206-744-3000',
  '+1-206-744-3074',
  'https://www.harborview.org',
  'info@harborview.org',
  'trauma_center',
  413,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Psychiatric Emergency'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Burn Care'],
  4.6,
  2134,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Boston Area
(
  'Massachusetts General Hospital',
  '55 Fruit Street',
  'Boston',
  'MA',
  'USA',
  '02114',
  42.3632,
  -71.0685,
  '+1-617-726-2000',
  '+1-617-726-7100',
  'https://www.massgeneral.org',
  'emergency@mgh.harvard.edu',
  'trauma_center',
  999,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care', 'Stroke Center', 'Pediatric Emergency'],
  ARRAY['Emergency Medicine', 'Cardiology', 'Neurosurgery', 'Oncology'],
  4.8,
  4762,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Phoenix Area
(
  'Banner University Medical Center Phoenix',
  '1111 E McDowell Road',
  'Phoenix',
  'AZ',
  'USA',
  '85006',
  33.4654,
  -112.0621,
  '+1-602-839-2000',
  '+1-602-839-5911',
  'https://www.bannerhealth.com',
  'info@bannerhealth.com',
  'trauma_center',
  732,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Cardiac Care'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Burn Care', 'Cardiology'],
  4.5,
  2345,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Denver Area
(
  'Denver Health Medical Center',
  '777 Bannock Street',
  'Denver',
  'CO',
  'USA',
  '80204',
  39.7289,
  -104.9884,
  '+1-303-436-6000',
  '+1-303-436-6911',
  'https://www.denverhealth.org',
  'info@dhha.org',
  'trauma_center',
  555,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Poison Control'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Toxicology'],
  4.6,
  1987,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- San Francisco Area
(
  'Zuckerberg San Francisco General Hospital',
  '1001 Potrero Avenue',
  'San Francisco',
  'CA',
  'USA',
  '94110',
  37.7562,
  -122.4040,
  '+1-415-206-8000',
  '+1-415-206-8111',
  'https://www.zsfg.org',
  'info@zsfg.org',
  'trauma_center',
  384,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Psychiatric Emergency'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Burn Care', 'Psychiatry'],
  4.5,
  1876,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Atlanta Area
(
  'Grady Memorial Hospital',
  '80 Jesse Hill Jr Drive SE',
  'Atlanta',
  'GA',
  'USA',
  '30303',
  33.7545,
  -84.3794,
  '+1-404-616-1000',
  '+1-404-616-4307',
  'https://www.gradyhealth.org',
  'info@gmh.edu',
  'trauma_center',
  953,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Burn Unit', 'Cardiac Care'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Burn Care', 'Cardiology'],
  4.4,
  2234,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
),

-- Washington DC Area
(
  'MedStar Washington Hospital Center',
  '110 Irving Street NW',
  'Washington',
  'DC',
  'USA',
  '20010',
  38.9329,
  -77.0131,
  '+1-202-877-7000',
  '+1-202-877-7333',
  'https://www.medstarwashington.org',
  'info@medstar.net',
  'trauma_center',
  926,
  TRUE,
  TRUE,
  'I',
  TRUE,
  TRUE,
  ARRAY['Emergency Care', 'Trauma Surgery', 'ICU', 'Cardiac Care', 'Stroke Center', 'Burn Unit'],
  ARRAY['Emergency Medicine', 'Trauma Surgery', 'Cardiology', 'Neurology'],
  4.5,
  2567,
  TRUE,
  '{"is_sample_data": true, "verified_date": "2024-01-15"}'::jsonb
);

-- ============================================
-- 9. Helper Functions for Hospital Management
-- ============================================

-- Function to get hospital by ID with optional distance calculation
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
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  email TEXT,
  type TEXT,
  capacity INTEGER,
  has_emergency_room BOOLEAN,
  has_trauma_center BOOLEAN,
  trauma_level TEXT,
  accepts_ambulance BOOLEAN,
  is_24_7 BOOLEAN,
  opening_hours JSONB,
  services TEXT[],
  specialties TEXT[],
  rating DOUBLE PRECISION,
  total_reviews INTEGER,
  is_active BOOLEAN,
  is_verified BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  metadata JSONB,
  distance_km DOUBLE PRECISION
) AS $$
DECLARE
  user_location GEOGRAPHY;
BEGIN
  -- Create geography point for user location if coordinates are provided
  IF user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
    user_location := ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;
  END IF;

  -- Return hospital with optional distance calculation
  RETURN QUERY
  SELECT
    h.id,
    h.name,
    h.address,
    h.city,
    h.state,
    h.country,
    h.postal_code,
    h.latitude,
    h.longitude,
    h.phone_number,
    h.emergency_phone,
    h.website,
    h.email,
    h.type,
    h.capacity,
    h.has_emergency_room,
    h.has_trauma_center,
    h.trauma_level,
    h.accepts_ambulance,
    h.is_24_7,
    h.opening_hours,
    h.services,
    h.specialties,
    h.rating,
    h.total_reviews,
    h.is_active,
    h.is_verified,
    h.created_at,
    h.updated_at,
    h.metadata,
    -- Calculate distance in kilometers if user location provided, otherwise NULL
    CASE
      WHEN user_location IS NOT NULL THEN
        ROUND((ST_Distance(h.location, user_location) / 1000.0)::NUMERIC, 2)::DOUBLE PRECISION
      ELSE
        NULL
    END AS distance_km
  FROM hospitals h
  WHERE h.id = hospital_id AND h.is_active = TRUE
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to search hospitals by name (alternative version for compatibility)
CREATE OR REPLACE FUNCTION search_hospitals_by_name(search_term TEXT, result_limit INTEGER DEFAULT 20)
RETURNS SETOF hospitals AS $$
  SELECT * FROM hospitals
  WHERE is_active = TRUE
    AND name ILIKE '%' || search_term || '%'
  ORDER BY
    rating DESC NULLS LAST,
    total_reviews DESC
  LIMIT result_limit;
$$ LANGUAGE SQL STABLE;

-- Function to search hospitals (main search function used by the app)
CREATE OR REPLACE FUNCTION search_hospitals(
  search_term TEXT,
  search_city TEXT DEFAULT NULL,
  search_state TEXT DEFAULT NULL,
  result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone_number TEXT,
  emergency_phone TEXT,
  website TEXT,
  email TEXT,
  type TEXT,
  capacity INTEGER,
  has_emergency_room BOOLEAN,
  has_trauma_center BOOLEAN,
  trauma_level TEXT,
  accepts_ambulance BOOLEAN,
  is_24_7 BOOLEAN,
  opening_hours JSONB,
  services TEXT[],
  specialties TEXT[],
  rating DOUBLE PRECISION,
  total_reviews INTEGER,
  is_active BOOLEAN,
  is_verified BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  metadata JSONB
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
    h.postal_code,
    h.latitude,
    h.longitude,
    h.phone_number,
    h.emergency_phone,
    h.website,
    h.email,
    h.type,
    h.capacity,
    h.has_emergency_room,
    h.has_trauma_center,
    h.trauma_level,
    h.accepts_ambulance,
    h.is_24_7,
    h.opening_hours,
    h.services,
    h.specialties,
    h.rating,
    h.total_reviews,
    h.is_active,
    h.is_verified,
    h.created_at,
    h.updated_at,
    h.metadata
  FROM hospitals h
  WHERE
    h.is_active = TRUE
    -- Search by name
    AND h.name ILIKE '%' || search_term || '%'
    -- Filter by city if provided
    AND (search_city IS NULL OR h.city ILIKE search_city)
    -- Filter by state if provided
    AND (search_state IS NULL OR h.state ILIKE search_state)
  ORDER BY
    -- Prioritize exact name matches
    CASE WHEN LOWER(h.name) = LOWER(search_term) THEN 1 ELSE 2 END,
    -- Then by rating
    h.rating DESC NULLS LAST,
    -- Then by review count
    h.total_reviews DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get hospitals by city
CREATE OR REPLACE FUNCTION get_hospitals_by_city(city_name TEXT, result_limit INTEGER DEFAULT 50)
RETURNS SETOF hospitals AS $$
  SELECT * FROM hospitals
  WHERE is_active = TRUE
    AND city ILIKE city_name
  ORDER BY
    has_emergency_room DESC,
    rating DESC NULLS LAST,
    total_reviews DESC
  LIMIT result_limit;
$$ LANGUAGE SQL STABLE;

-- ============================================
-- 10. Comments for Documentation
-- ============================================

COMMENT ON TABLE hospitals IS 'Stores hospital information with geospatial data for emergency services';
COMMENT ON COLUMN hospitals.location IS 'PostGIS geography point for efficient distance calculations';
COMMENT ON COLUMN hospitals.type IS 'Hospital type: general, specialized, emergency, trauma_center, urgent_care';
COMMENT ON COLUMN hospitals.trauma_level IS 'Trauma center level: I (highest) through V (basic)';
COMMENT ON COLUMN hospitals.services IS 'Array of services offered (e.g., Emergency Care, ICU, Cardiac Care)';
COMMENT ON COLUMN hospitals.specialties IS 'Array of medical specialties available';
COMMENT ON COLUMN hospitals.is_24_7 IS 'Whether the hospital operates 24/7';
COMMENT ON COLUMN hospitals.has_emergency_room IS 'Whether the hospital has an emergency room';
COMMENT ON COLUMN hospitals.metadata IS 'Additional metadata in JSON format';

COMMENT ON FUNCTION find_nearest_hospitals IS 'Find nearest hospitals to a given location with optional filters for emergency room and 24/7 availability';
COMMENT ON FUNCTION get_hospital_with_distance IS 'Get a single hospital by ID with optional distance calculation from user location';
COMMENT ON FUNCTION search_hospitals IS 'Search hospitals by name with optional city and state filters (main search function used by the app)';
COMMENT ON FUNCTION search_hospitals_by_name IS 'Search hospitals by name (case-insensitive, alternative version)';
COMMENT ON FUNCTION get_hospitals_by_city IS 'Get all hospitals in a specific city';

-- ============================================
-- 11. Verification Queries
-- ============================================

-- Uncomment these to verify the setup after running the script

-- Check table exists
-- SELECT table_name FROM information_schema.tables WHERE table_name = 'hospitals';

-- Check indexes
-- SELECT indexname FROM pg_indexes WHERE tablename = 'hospitals';

-- Check sample data count
-- SELECT COUNT(*) FROM hospitals;

-- Test the find_nearest_hospitals function
-- Example: Find hospitals near New York City (Times Square)
-- SELECT name, city, distance_km
-- FROM find_nearest_hospitals(40.7580, -73.9855, 25.0, 5, true, false);

-- ============================================
-- Setup Complete!
-- ============================================
--
-- Next steps:
-- 1. Verify the setup by running the verification queries above
-- 2. Test the find_nearest_hospitals function with different coordinates
-- 3. Add more sample hospitals for your target regions if needed
-- 4. Update RLS policies based on your admin role implementation
-- 5. Configure proper admin roles for insert/update/delete operations
--
-- ============================================
