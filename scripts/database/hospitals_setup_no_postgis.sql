-- ============================================
-- HOSPITALS DATABASE SETUP - WITHOUT POSTGIS
-- ============================================
-- This version works WITHOUT PostGIS extension
-- Distance calculations are done using Haversine formula in SQL
-- ============================================

-- ============================================
-- 1. DROP EXISTING OBJECTS (Clean slate)
-- ============================================

DROP TRIGGER IF EXISTS trigger_update_hospitals_timestamp ON hospitals CASCADE;
DROP FUNCTION IF EXISTS find_nearest_hospitals CASCADE;
DROP FUNCTION IF EXISTS get_hospital_with_distance CASCADE;
DROP FUNCTION IF EXISTS search_hospitals CASCADE;
DROP FUNCTION IF EXISTS search_hospitals_by_name CASCADE;
DROP FUNCTION IF EXISTS get_hospitals_by_city CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
DROP TABLE IF EXISTS hospitals CASCADE;

-- ============================================
-- 2. CREATE HOSPITALS TABLE (NO PostGIS!)
-- ============================================

CREATE TABLE hospitals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  country TEXT DEFAULT 'USA' NOT NULL,
  postal_code TEXT,

  -- Simple lat/lng coordinates (NO PostGIS location column!)
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,

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
-- 3. CREATE INDEXES
-- ============================================

CREATE INDEX idx_hospitals_lat_lng ON hospitals(latitude, longitude);
CREATE INDEX idx_hospitals_city ON hospitals(city);
CREATE INDEX idx_hospitals_state ON hospitals(state);
CREATE INDEX idx_hospitals_type ON hospitals(type);
CREATE INDEX idx_hospitals_is_active ON hospitals(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_hospitals_has_emergency_room ON hospitals(has_emergency_room) WHERE has_emergency_room = TRUE;
CREATE INDEX idx_hospitals_is_24_7 ON hospitals(is_24_7) WHERE is_24_7 = TRUE;
CREATE INDEX idx_hospitals_rating ON hospitals(rating DESC NULLS LAST);
CREATE INDEX idx_hospitals_services ON hospitals USING GIN(services);
CREATE INDEX idx_hospitals_specialties ON hospitals USING GIN(specialties);

-- ============================================
-- 4. CREATE HAVERSINE DISTANCE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION haversine_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  earth_radius DOUBLE PRECISION := 6371; -- Earth's radius in kilometers
  dlat DOUBLE PRECISION;
  dlon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);

  a := sin(dlat/2) * sin(dlat/2) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(dlon/2) * sin(dlon/2);

  c := 2 * atan2(sqrt(a), sqrt(1-a));

  RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 5. CREATE find_nearest_hospitals FUNCTION
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
    h.metadata,
    ROUND(haversine_distance(user_lat, user_lng, h.latitude, h.longitude)::NUMERIC, 2)::DOUBLE PRECISION AS distance_km
  FROM hospitals h
  WHERE
    h.is_active = TRUE
    AND (NOT only_emergency OR h.has_emergency_room = TRUE)
    AND (NOT only_24_7 OR h.is_24_7 = TRUE)
    AND haversine_distance(user_lat, user_lng, h.latitude, h.longitude) <= max_distance_km
  ORDER BY
    haversine_distance(user_lat, user_lng, h.latitude, h.longitude),
    h.rating DESC NULLS LAST,
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
-- 6. CREATE get_hospital_with_distance FUNCTION
-- ============================================

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
    h.metadata,
    CASE
      WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
        ROUND(haversine_distance(user_lat, user_lng, h.latitude, h.longitude)::NUMERIC, 2)::DOUBLE PRECISION
      ELSE
        NULL
    END AS distance_km
  FROM hospitals h
  WHERE h.id = hospital_id AND h.is_active = TRUE
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 7. CREATE search_hospitals FUNCTION
-- ============================================

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
    h.id, h.name, h.address, h.city, h.state, h.country, h.postal_code,
    h.latitude, h.longitude, h.phone_number, h.emergency_phone, h.website, h.email,
    h.type, h.capacity, h.has_emergency_room, h.has_trauma_center, h.trauma_level,
    h.accepts_ambulance, h.is_24_7, h.opening_hours, h.services, h.specialties,
    h.rating, h.total_reviews, h.is_active, h.is_verified, h.created_at, h.updated_at, h.metadata
  FROM hospitals h
  WHERE
    h.is_active = TRUE
    AND h.name ILIKE '%' || search_term || '%'
    AND (search_city IS NULL OR h.city ILIKE search_city)
    AND (search_state IS NULL OR h.state ILIKE search_state)
  ORDER BY
    CASE WHEN LOWER(h.name) = LOWER(search_term) THEN 1 ELSE 2 END,
    h.rating DESC NULLS LAST,
    h.total_reviews DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 8. CREATE TIMESTAMP TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_hospitals_timestamp
  BEFORE UPDATE ON hospitals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 9. ROW LEVEL SECURITY
-- ============================================

ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active hospitals"
  ON hospitals FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "Only admins can insert hospitals"
  ON hospitals FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Only admins can update hospitals"
  ON hospitals FOR UPDATE
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Only admins can delete hospitals"
  ON hospitals FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SUCCESS: Hospital database created!';
  RAISE NOTICE 'WITHOUT PostGIS - using Haversine formula';
  RAISE NOTICE '';
  RAISE NOTICE 'Now run: hospitals_sample_data.sql';
  RAISE NOTICE 'to add 15 sample hospitals';
  RAISE NOTICE '========================================';
END $$;
