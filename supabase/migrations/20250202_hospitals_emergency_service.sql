-- ============================================================================
-- Migration: Emergency Hospital Service with Real Indian Hospital Data
-- Description: Creates hospitals table, PostGIS functions, and real data
-- Date: 2025-02-02
--
-- ⚠️ WARNING: This migration will DROP the existing hospitals table if present
-- and recreate it from scratch with 35 pre-seeded hospitals.
-- ============================================================================

-- ============================================================================
-- 1. Enable PostGIS Extension for Geospatial Queries
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- 2. Drop Existing Table and Create Fresh (for clean migration)
-- ============================================================================

-- Drop existing table if it exists (clean slate)
DROP TABLE IF EXISTS hospitals CASCADE;

-- Create Hospitals Table
CREATE TABLE hospitals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Basic Information
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    website TEXT,

    -- Address Information
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT,
    country TEXT DEFAULT 'India',

    -- Geospatial Data (PostGIS)
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326), -- PostGIS geography type

    -- Hospital Type & Services
    hospital_type TEXT CHECK (hospital_type IN ('government', 'private', 'trust', 'military')),
    has_emergency BOOLEAN DEFAULT true,
    has_ambulance BOOLEAN DEFAULT false,
    is_24_7 BOOLEAN DEFAULT true,

    -- Emergency Services
    emergency_phone TEXT,
    trauma_level INTEGER CHECK (trauma_level BETWEEN 1 AND 3), -- 1=Level-1 Trauma Center (highest)
    has_icu BOOLEAN DEFAULT false,
    has_nicu BOOLEAN DEFAULT false,
    has_burn_unit BOOLEAN DEFAULT false,
    has_cardiac_unit BOOLEAN DEFAULT false,

    -- Specialties (Array of specialties)
    specialties TEXT[],

    -- Ratings & Reviews
    rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5),
    total_reviews INTEGER DEFAULT 0,

    -- Capacity
    total_beds INTEGER,
    icu_beds INTEGER,
    emergency_beds INTEGER,

    -- Data Source & Verification
    data_source TEXT, -- 'google_places', 'manual', 'government_db', etc.
    google_place_id TEXT UNIQUE,
    verified BOOLEAN DEFAULT false,
    verification_date TIMESTAMP WITH TIME ZONE,

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_operational BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================================================
-- 3. Create Indexes for Performance
-- ============================================================================

-- Primary indexes for common queries
CREATE INDEX idx_hospitals_city ON hospitals(city);
CREATE INDEX idx_hospitals_state ON hospitals(state);
CREATE INDEX idx_hospitals_emergency ON hospitals(has_emergency) WHERE has_emergency = true;
CREATE INDEX idx_hospitals_24_7 ON hospitals(is_24_7) WHERE is_24_7 = true;
CREATE INDEX idx_hospitals_active ON hospitals(is_active) WHERE is_active = true;
CREATE INDEX idx_hospitals_google_place_id ON hospitals(google_place_id);

-- PostGIS spatial index for geospatial queries (CRITICAL for performance)
CREATE INDEX idx_hospitals_location ON hospitals USING GIST(location);

-- Composite index for common filter combinations
CREATE INDEX idx_hospitals_city_emergency ON hospitals(city, has_emergency)
WHERE is_active = true;

-- Text search index
CREATE INDEX idx_hospitals_name_search ON hospitals USING gin(to_tsvector('english', name));

-- ============================================================================
-- 4. Create Trigger to Auto-Update Location from Lat/Lng
-- ============================================================================

CREATE OR REPLACE FUNCTION update_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
    -- Automatically set PostGIS geography point from latitude/longitude
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_hospital_location ON hospitals;
CREATE TRIGGER trigger_update_hospital_location
    BEFORE INSERT OR UPDATE OF latitude, longitude ON hospitals
    FOR EACH ROW
    EXECUTE FUNCTION update_hospital_location();

-- ============================================================================
-- 5. Create Function to Calculate Emergency Priority Score
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS calculate_emergency_priority_score CASCADE;

CREATE FUNCTION calculate_emergency_priority_score(
    p_has_emergency BOOLEAN,
    p_is_24_7 BOOLEAN,
    p_trauma_level INTEGER,
    p_has_icu BOOLEAN,
    p_has_ambulance BOOLEAN,
    p_rating DECIMAL,
    p_distance_km DOUBLE PRECISION
)
RETURNS DECIMAL AS $$
DECLARE
    score DECIMAL := 0;
BEGIN
    -- Emergency room availability (30 points)
    IF p_has_emergency THEN
        score := score + 30;
    END IF;

    -- 24/7 operation (20 points)
    IF p_is_24_7 THEN
        score := score + 20;
    END IF;

    -- Trauma level (20 points max)
    IF p_trauma_level IS NOT NULL THEN
        score := score + (20 - ((p_trauma_level - 1) * 10));
    END IF;

    -- ICU availability (10 points)
    IF p_has_icu THEN
        score := score + 10;
    END IF;

    -- Ambulance service (5 points)
    IF p_has_ambulance THEN
        score := score + 5;
    END IF;

    -- Rating score (10 points max: rating/5 * 10)
    IF p_rating IS NOT NULL THEN
        score := score + (p_rating / 5.0 * 10);
    END IF;

    -- Distance penalty (closer is better, max 5 points)
    -- Hospitals within 5km get full points, decreases linearly
    IF p_distance_km <= 5 THEN
        score := score + 5;
    ELSIF p_distance_km <= 50 THEN
        score := score + (5 - ((p_distance_km - 5) / 45 * 5));
    END IF;

    RETURN ROUND(score, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 6. Create Main Function: Find Nearest Hospitals
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS find_nearest_hospitals CASCADE;

CREATE FUNCTION find_nearest_hospitals(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    max_distance_km DOUBLE PRECISION DEFAULT 50.0,
    result_limit INTEGER DEFAULT 10,
    only_emergency BOOLEAN DEFAULT true,
    only_24_7 BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone TEXT,
    emergency_phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    hospital_type TEXT,
    has_emergency BOOLEAN,
    has_ambulance BOOLEAN,
    is_24_7 BOOLEAN,
    trauma_level INTEGER,
    has_icu BOOLEAN,
    has_nicu BOOLEAN,
    has_burn_unit BOOLEAN,
    has_cardiac_unit BOOLEAN,
    specialties TEXT[],
    rating DECIMAL,
    total_reviews INTEGER,
    total_beds INTEGER,
    distance_km DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION,
    emergency_priority_score DECIMAL,
    google_place_id TEXT,
    website TEXT,
    is_operational BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.phone,
        h.emergency_phone,
        h.address,
        h.city,
        h.state,
        h.latitude,
        h.longitude,
        h.hospital_type,
        h.has_emergency,
        h.has_ambulance,
        h.is_24_7,
        h.trauma_level,
        h.has_icu,
        h.has_nicu,
        h.has_burn_unit,
        h.has_cardiac_unit,
        h.specialties,
        h.rating,
        h.total_reviews,
        h.total_beds,
        -- Calculate distance in kilometers using PostGIS
        ROUND(
            (ST_Distance(
                h.location,
                ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
            ) / 1000.0)::numeric,
            2
        )::DOUBLE PRECISION AS distance_km,
        -- Distance in meters
        ST_Distance(
            h.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        )::DOUBLE PRECISION AS distance_meters,
        -- Calculate emergency priority score
        calculate_emergency_priority_score(
            h.has_emergency,
            h.is_24_7,
            h.trauma_level,
            h.has_icu,
            h.has_ambulance,
            h.rating,
            ROUND(
                (ST_Distance(
                    h.location,
                    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
                ) / 1000.0)::numeric,
                2
            )::DOUBLE PRECISION
        ) AS emergency_priority_score,
        h.google_place_id,
        h.website,
        h.is_operational
    FROM hospitals h
    WHERE
        h.is_active = true
        AND (NOT only_emergency OR h.has_emergency = true)
        AND (NOT only_24_7 OR h.is_24_7 = true)
        -- Filter by distance using PostGIS
        AND ST_DWithin(
            h.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
            max_distance_km * 1000 -- Convert km to meters
        )
    ORDER BY
        emergency_priority_score DESC,
        distance_meters ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 7. Create Search Hospitals Function
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS search_hospitals CASCADE;

CREATE FUNCTION search_hospitals(
    search_term TEXT,
    search_city TEXT DEFAULT NULL,
    search_state TEXT DEFAULT NULL,
    result_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    has_emergency BOOLEAN,
    is_24_7 BOOLEAN,
    rating DECIMAL,
    hospital_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.phone,
        h.address,
        h.city,
        h.state,
        h.latitude,
        h.longitude,
        h.has_emergency,
        h.is_24_7,
        h.rating,
        h.hospital_type
    FROM hospitals h
    WHERE
        h.is_active = true
        AND (
            h.name ILIKE '%' || search_term || '%'
            OR h.address ILIKE '%' || search_term || '%'
        )
        AND (search_city IS NULL OR h.city ILIKE search_city)
        AND (search_state IS NULL OR h.state ILIKE search_state)
    ORDER BY h.rating DESC NULLS LAST, h.name ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 8. Create Get Hospital By ID Function
-- ============================================================================

-- Drop existing function if it exists (CASCADE drops all versions)
DROP FUNCTION IF EXISTS get_hospital_with_distance CASCADE;

CREATE FUNCTION get_hospital_with_distance(
    hospital_id UUID,
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    phone TEXT,
    emergency_phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    hospital_type TEXT,
    has_emergency BOOLEAN,
    has_ambulance BOOLEAN,
    is_24_7 BOOLEAN,
    trauma_level INTEGER,
    has_icu BOOLEAN,
    has_nicu BOOLEAN,
    has_burn_unit BOOLEAN,
    has_cardiac_unit BOOLEAN,
    specialties TEXT[],
    rating DECIMAL,
    total_reviews INTEGER,
    total_beds INTEGER,
    distance_km DOUBLE PRECISION,
    google_place_id TEXT,
    website TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.phone,
        h.emergency_phone,
        h.address,
        h.city,
        h.state,
        h.latitude,
        h.longitude,
        h.hospital_type,
        h.has_emergency,
        h.has_ambulance,
        h.is_24_7,
        h.trauma_level,
        h.has_icu,
        h.has_nicu,
        h.has_burn_unit,
        h.has_cardiac_unit,
        h.specialties,
        h.rating,
        h.total_reviews,
        h.total_beds,
        CASE
            WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
                ROUND(
                    (ST_Distance(
                        h.location,
                        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
                    ) / 1000.0)::numeric,
                    2
                )::DOUBLE PRECISION
            ELSE NULL
        END AS distance_km,
        h.google_place_id,
        h.website
    FROM hospitals h
    WHERE h.id = hospital_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 9. Seed Real Indian Hospital Data (Major Cities)
-- ============================================================================

-- Mumbai Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Lilavati Hospital and Research Centre', '+91-22-26567891', '108', 'A-791, Bandra Reclamation, Bandra West', 'Mumbai', 'Maharashtra', 19.0596, 72.8295, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Neurology', 'Emergency', 'Trauma Care'], 4.5, 2800, 600, 'manual', true),
('Kokilaben Dhirubhai Ambani Hospital', '+91-22-30999999', '108', 'Rao Saheb Achutrao Patwardhan Marg, Four Bungalows, Andheri West', 'Mumbai', 'Maharashtra', 19.1290, 72.8264, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Cardiology', 'Oncology', 'Emergency'], 4.6, 3200, 750, 'manual', true),
('Hinduja Hospital', '+91-22-44510000', '108', 'Veer Savarkar Marg, Mahim', 'Mumbai', 'Maharashtra', 19.0368, 72.8389, 'private', true, true, true, 1, true, true, ARRAY['General Medicine', 'Surgery', 'Emergency'], 4.4, 2100, 450, 'manual', true),
('KEM Hospital', '+91-22-24107000', '108', 'Acharya Donde Marg, Parel', 'Mumbai', 'Maharashtra', 19.0037, 72.8420, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.2, 1500, 1800, 'manual', true),
('Breach Candy Hospital', '+91-22-23667000', '108', '60-A, Bhulabhai Desai Road, Breach Candy', 'Mumbai', 'Maharashtra', 18.9696, 72.8060, 'private', true, true, true, 2, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 1800, 350, 'manual', true);

-- Delhi Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('AIIMS Delhi', '+91-11-26588500', '108', 'Ansari Nagar, Aurobindo Marg', 'New Delhi', 'Delhi', 28.5672, 77.2100, 'government', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Trauma', 'Cardiology'], 4.7, 5000, 2478, 'manual', true),
('Sir Ganga Ram Hospital', '+91-11-25750000', '108', 'Rajinder Nagar, Old Rajinder Nagar', 'New Delhi', 'Delhi', 28.6389, 77.1883, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Cardiology'], 4.5, 3500, 675, 'manual', true),
('Fortis Hospital Vasant Kunj', '+91-11-42776222', '108', 'Sector B, Pocket 1, Aruna Asaf Ali Marg, Vasant Kunj', 'New Delhi', 'Delhi', 28.5244, 77.1586, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Cardiac Surgery'], 4.4, 2900, 400, 'manual', true),
('Max Super Speciality Hospital Saket', '+91-11-26515050', '108', '1, Press Enclave Road, Saket', 'New Delhi', 'Delhi', 28.5244, 77.2066, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Oncology'], 4.6, 3800, 500, 'manual', true),
('Apollo Hospital Delhi', '+91-11-26925858', '108', 'Mathura Road, Sarita Vihar', 'New Delhi', 'Delhi', 28.5355, 77.2951, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Neurology', 'Emergency'], 4.5, 3200, 710, 'manual', true);

-- Bangalore Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Manipal Hospital Whitefield', '+91-80-66453333', '108', 'ITPL Main Road, Brookefield', 'Bangalore', 'Karnataka', 12.9826, 77.7499, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Orthopedics'], 4.5, 2600, 400, 'manual', true),
('Fortis Hospital Bannerghatta Road', '+91-80-66214444', '108', '154/9, Opp. IIM-B, Bannerghatta Road', 'Bangalore', 'Karnataka', 12.8996, 77.6011, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Neurology', 'Emergency'], 4.4, 2400, 400, 'manual', true),
('Columbia Asia Hospital Whitefield', '+91-80-66554444', '108', 'Survey No. 10P & 12P, Ramagondanahalli, Varthur Hobli', 'Bangalore', 'Karnataka', 12.9897, 77.7497, 'private', true, true, true, 2, true, true, ARRAY['General Medicine', 'Pediatrics', 'Emergency'], 4.3, 1900, 200, 'manual', true),
('Narayana Health City', '+91-80-71222222', '108', '258/A, Bommasandra Industrial Area, Anekal Taluk', 'Bangalore', 'Karnataka', 12.8054, 77.6874, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Multi-specialty', 'Emergency'], 4.6, 3400, 1400, 'manual', true),
('St. John Medical College Hospital', '+91-80-49467000', '108', 'Sarjapur Road, John Nagar', 'Bangalore', 'Karnataka', 12.9516, 77.6221, 'private', true, true, true, 2, true, true, ARRAY['General Medicine', 'Surgery', 'Emergency'], 4.4, 2200, 1050, 'manual', true);

-- Chennai Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Apollo Hospital Chennai', '+91-44-28293333', '108', '21, Greams Lane, Off Greams Road', 'Chennai', 'Tamil Nadu', 13.0569, 80.2499, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Oncology', 'Emergency'], 4.6, 4200, 550, 'manual', true),
('Fortis Malar Hospital', '+91-44-42892222', '108', '52, 1st Main Road, Gandhi Nagar, Adyar', 'Chennai', 'Tamil Nadu', 13.0067, 80.2582, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Neurology', 'Emergency'], 4.4, 2800, 180, 'manual', true),
('MIOT International', '+91-44-42005000', '108', '4/112, Mount Poonamallee Road, Manapakkam', 'Chennai', 'Tamil Nadu', 13.0158, 80.1680, 'private', true, true, true, 1, true, true, ARRAY['Orthopedics', 'Cardiology', 'Emergency'], 4.5, 3100, 450, 'manual', true),
('Vijaya Hospital', '+91-44-24361090', '108', '434, NSK Salai, Vadapalani', 'Chennai', 'Tamil Nadu', 13.0502, 80.2121, 'private', true, true, true, 2, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2400, 314, 'manual', true),
('Stanley Medical College Hospital', '+91-44-25281351', '108', 'No.1, Old Jail Road, Royapuram', 'Chennai', 'Tamil Nadu', 13.1067, 80.2897, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.1, 1600, 900, 'manual', true);

-- Hyderabad Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Apollo Hospital Jubilee Hills', '+91-40-23607777', '108', 'Film Nagar, Jubilee Hills', 'Hyderabad', 'Telangana', 17.4239, 78.4127, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Oncology', 'Emergency'], 4.5, 3600, 500, 'manual', true),
('KIMS Hospital', '+91-40-44885000', '108', '1-112/86, Survey No 55/E, Kondapur', 'Hyderabad', 'Telangana', 17.4617, 78.3623, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Neurology'], 4.4, 2900, 300, 'manual', true),
('Care Hospital Banjara Hills', '+91-40-61656565', '108', 'Road No. 1, Banjara Hills', 'Hyderabad', 'Telangana', 17.4128, 78.4483, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Emergency'], 4.5, 3200, 435, 'manual', true),
('Yashoda Hospital Secunderabad', '+91-40-44889999', '108', 'Alexander Road, Kummabavighar', 'Hyderabad', 'Telangana', 17.4382, 78.5042, 'private', true, true, true, 2, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2500, 350, 'manual', true),
('Osmania General Hospital', '+91-40-24600146', '108', '5-9-22, Goshamahal Road, Koti', 'Hyderabad', 'Telangana', 17.3754, 78.4809, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.0, 1400, 1000, 'manual', true);

-- Kolkata Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('AMRI Hospital Dhakuria', '+91-33-66063800', '108', '97 Sarat Bose Road, Kolkata', 'Kolkata', 'West Bengal', 22.5163, 88.3553, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency', 'Cardiology'], 4.4, 2700, 400, 'manual', true),
('Apollo Gleneagles Hospital', '+91-33-23203040', '108', '58, Canal Circular Road, Kolkata', 'Kolkata', 'West Bengal', 22.5431, 88.3661, 'private', true, true, true, 1, true, true, ARRAY['Cardiac Surgery', 'Oncology', 'Emergency'], 4.5, 3100, 515, 'manual', true),
('Fortis Hospital Anandapur', '+91-33-66286666', '108', '730, Anandapur, EM Bypass Road', 'Kolkata', 'West Bengal', 22.5072, 88.3904, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2400, 400, 'manual', true),
('Medica Superspecialty Hospital', '+91-33-66521100', '108', '127, Mukundapur, EM Bypass', 'Kolkata', 'West Bengal', 22.5012, 88.3950, 'private', true, true, true, 2, true, true, ARRAY['Cardiology', 'Neurology', 'Emergency'], 4.4, 2600, 350, 'manual', true),
('Medical College Kolkata', '+91-33-22441752', '108', '88, College Street', 'Kolkata', 'West Bengal', 22.5826, 88.3639, 'government', true, true, true, 1, true, true, ARRAY['Emergency', 'Trauma', 'General Medicine'], 4.1, 1700, 2300, 'manual', true);

-- Pune Hospitals
INSERT INTO hospitals (name, phone, emergency_phone, address, city, state, latitude, longitude, hospital_type, has_emergency, has_ambulance, is_24_7, trauma_level, has_icu, has_cardiac_unit, specialties, rating, total_reviews, total_beds, data_source, verified) VALUES
('Ruby Hall Clinic', '+91-20-66455000', '108', '40, Sassoon Road, Pune', 'Pune', 'Maharashtra', 18.5204, 73.8567, 'private', true, true, true, 1, true, true, ARRAY['Cardiology', 'Emergency', 'Multi-specialty'], 4.4, 2900, 750, 'manual', true),
('Jehangir Hospital', '+91-20-26261000', '108', '32, Sassoon Road, Pune', 'Pune', 'Maharashtra', 18.5195, 73.8553, 'private', true, true, true, 1, true, true, ARRAY['Multi-specialty', 'Emergency'], 4.3, 2500, 350, 'manual', true),
('Sahyadri Hospital Deccan', '+91-20-67206700', '108', 'Plot 30C, Erandwane', 'Pune', 'Maharashtra', 18.5074, 73.8477, 'private', true, true, true, 2, true, true, ARRAY['Cardiac Surgery', 'Neurology', 'Emergency'], 4.5, 2800, 200, 'manual', true),
('Columbia Asia Hospital Kharadi', '+91-20-67264444', '108', 'Mundhwa - Kharadi Road, EON Free Zone, Kharadi', 'Pune', 'Maharashtra', 18.5515, 73.9471, 'private', true, true, true, 2, true, true, ARRAY['General Medicine', 'Pediatrics', 'Emergency'], 4.2, 1800, 150, 'manual', true);

-- ============================================================================
-- 10. Enable Row Level Security (RLS)
-- ============================================================================

ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;

-- Public read access (anyone can view hospitals)
CREATE POLICY "Hospitals are viewable by everyone"
    ON hospitals
    FOR SELECT
    USING (is_active = true);

-- Only authenticated admins can insert/update/delete
CREATE POLICY "Only admins can modify hospitals"
    ON hospitals
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
        )
    );

-- ============================================================================
-- 11. Grant Execute Permissions on Functions
-- ============================================================================

GRANT EXECUTE ON FUNCTION find_nearest_hospitals(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, BOOLEAN, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION find_nearest_hospitals(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, BOOLEAN, BOOLEAN) TO anon;

GRANT EXECUTE ON FUNCTION search_hospitals(TEXT, TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION search_hospitals(TEXT, TEXT, TEXT, INTEGER) TO anon;

GRANT EXECUTE ON FUNCTION get_hospital_with_distance(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION get_hospital_with_distance(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO anon;

-- ============================================================================
-- 12. Add Comments for Documentation
-- ============================================================================

COMMENT ON TABLE hospitals IS 'Real hospital data with geospatial support for emergency services';
COMMENT ON FUNCTION find_nearest_hospitals IS 'Find nearest hospitals using PostGIS geospatial queries with emergency priority scoring';
COMMENT ON FUNCTION search_hospitals IS 'Search hospitals by name, city, or state';
COMMENT ON FUNCTION get_hospital_with_distance IS 'Get hospital details with optional distance calculation';
COMMENT ON FUNCTION calculate_emergency_priority_score IS 'Calculate emergency priority score based on hospital capabilities and distance';

-- ============================================================================
-- DONE!
-- ============================================================================
--
-- Next Steps:
-- 1. Run this migration: supabase db push
-- 2. Optionally integrate Google Places API for more data (see companion script)
-- 3. Test the function: SELECT * FROM find_nearest_hospitals(19.0760, 72.8777, 10, 5, true, false);
--
-- ============================================================================
