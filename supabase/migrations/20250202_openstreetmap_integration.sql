-- ============================================================================
-- OpenStreetMap Overpass API Integration (100% FREE)
-- Description: Functions to import hospital data from OpenStreetMap
-- Date: 2025-02-02
-- API: https://overpass-api.de/ (No API key needed, completely free!)
-- ============================================================================

-- ============================================================================
-- 1. Function to Upsert Hospital from OpenStreetMap Data
-- ============================================================================

CREATE OR REPLACE FUNCTION upsert_hospital_from_osm(
    p_osm_id TEXT,
    p_name TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_city TEXT,
    p_state TEXT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_amenity TEXT DEFAULT 'hospital',
    p_emergency TEXT DEFAULT NULL,
    p_beds INTEGER DEFAULT NULL,
    p_website TEXT DEFAULT NULL,
    p_opening_hours TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_hospital_id UUID;
    v_has_emergency BOOLEAN;
    v_is_24_7 BOOLEAN;
    v_hospital_type TEXT;
BEGIN
    -- Determine if hospital has emergency
    v_has_emergency := (
        p_emergency IS NOT NULL OR
        p_amenity = 'hospital' OR
        p_name ILIKE '%emergency%' OR
        p_name ILIKE '%trauma%'
    );

    -- Determine if 24/7 based on opening_hours
    v_is_24_7 := (
        p_opening_hours = '24/7' OR
        p_opening_hours ILIKE '%24%' OR
        p_amenity = 'hospital' OR
        p_name ILIKE '%24%'
    );

    -- Determine hospital type (government hospitals often have specific names in India)
    v_hospital_type := CASE
        WHEN p_name ILIKE '%government%' THEN 'government'
        WHEN p_name ILIKE '%district%' THEN 'government'
        WHEN p_name ILIKE '%civil%' THEN 'government'
        WHEN p_name ILIKE '%general hospital%' THEN 'government'
        WHEN p_name ILIKE '%medical college%' THEN 'government'
        WHEN p_name ILIKE '%aiims%' THEN 'government'
        WHEN p_name ILIKE '%esi%' THEN 'government'
        WHEN p_name ILIKE '%railway%' THEN 'government'
        ELSE 'private'
    END;

    -- Insert or update hospital
    INSERT INTO hospitals (
        metadata, -- Store OSM ID in metadata
        name,
        phone,
        address,
        city,
        state,
        latitude,
        longitude,
        hospital_type,
        has_emergency,
        is_24_7,
        total_beds,
        website,
        data_source,
        verified,
        country
    )
    VALUES (
        jsonb_build_object('osm_id', p_osm_id, 'osm_amenity', p_amenity),
        p_name,
        p_phone,
        COALESCE(p_address, 'Address not available'),
        COALESCE(p_city, 'Unknown'),
        COALESCE(p_state, 'Unknown'),
        p_latitude,
        p_longitude,
        v_hospital_type,
        v_has_emergency,
        v_is_24_7,
        p_beds,
        p_website,
        'openstreetmap',
        false, -- Not verified yet
        'India'
    )
    ON CONFLICT ((metadata->>'osm_id'))
    WHERE metadata->>'osm_id' IS NOT NULL
    DO UPDATE SET
        name = EXCLUDED.name,
        phone = EXCLUDED.phone,
        address = EXCLUDED.address,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        hospital_type = EXCLUDED.hospital_type,
        has_emergency = EXCLUDED.has_emergency,
        is_24_7 = EXCLUDED.is_24_7,
        total_beds = EXCLUDED.total_beds,
        website = EXCLUDED.website,
        updated_at = NOW()
    RETURNING id INTO v_hospital_id;

    RETURN v_hospital_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Batch Insert Function for OpenStreetMap Hospitals
-- ============================================================================

CREATE OR REPLACE FUNCTION batch_insert_osm_hospitals(
    hospitals_json JSONB
)
RETURNS TABLE (
    inserted_count INTEGER,
    updated_count INTEGER,
    failed_count INTEGER,
    skipped_count INTEGER
) AS $$
DECLARE
    v_hospital JSONB;
    v_inserted INTEGER := 0;
    v_updated INTEGER := 0;
    v_failed INTEGER := 0;
    v_skipped INTEGER := 0;
    v_existing_id UUID;
    v_osm_id TEXT;
BEGIN
    FOR v_hospital IN SELECT * FROM jsonb_array_elements(hospitals_json)
    LOOP
        BEGIN
            v_osm_id := v_hospital->>'osm_id';

            -- Skip if no OSM ID
            IF v_osm_id IS NULL OR v_osm_id = '' THEN
                v_skipped := v_skipped + 1;
                CONTINUE;
            END IF;

            -- Check if hospital already exists
            SELECT id INTO v_existing_id
            FROM hospitals
            WHERE metadata->>'osm_id' = v_osm_id;

            IF v_existing_id IS NOT NULL THEN
                v_updated := v_updated + 1;
            ELSE
                v_inserted := v_inserted + 1;
            END IF;

            -- Upsert hospital
            PERFORM upsert_hospital_from_osm(
                v_osm_id,
                v_hospital->>'name',
                v_hospital->>'phone',
                v_hospital->>'address',
                v_hospital->>'city',
                v_hospital->>'state',
                (v_hospital->>'latitude')::DOUBLE PRECISION,
                (v_hospital->>'longitude')::DOUBLE PRECISION,
                v_hospital->>'amenity',
                v_hospital->>'emergency',
                CASE WHEN v_hospital->>'beds' IS NOT NULL
                     THEN (v_hospital->>'beds')::INTEGER
                     ELSE NULL END,
                v_hospital->>'website',
                v_hospital->>'opening_hours'
            );
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            RAISE NOTICE 'Failed to insert hospital: % (OSM ID: %)', v_hospital->>'name', v_osm_id;
        END;
    END LOOP;

    RETURN QUERY SELECT v_inserted, v_updated, v_failed, v_skipped;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. Create Unique Index for OSM ID
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_hospitals_osm_id
ON hospitals ((metadata->>'osm_id'))
WHERE metadata->>'osm_id' IS NOT NULL;

-- ============================================================================
-- 4. Grant Permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION upsert_hospital_from_osm TO authenticated;
GRANT EXECUTE ON FUNCTION batch_insert_osm_hospitals TO authenticated;

-- ============================================================================
-- DONE! 100% FREE - No API Key Required
-- ============================================================================

-- Usage Instructions:
--
-- 1. Fetch hospitals from Overpass API:
--    URL: https://overpass-api.de/api/interpreter
--    Query example (find hospitals in Mumbai):
--
--    [out:json];
--    (
--      node["amenity"="hospital"](18.8,72.7,19.3,73.0);
--      way["amenity"="hospital"](18.8,72.7,19.3,73.0);
--      relation["amenity"="hospital"](18.8,72.7,19.3,73.0);
--    );
--    out body;
--    >;
--    out skel qt;
--
-- 2. Parse the response and format as JSON array
-- 3. Call batch_insert_osm_hospitals(json_data)
--
-- No API key needed! Completely free!
-- Rate limit: ~1 request per second (generous for normal use)
