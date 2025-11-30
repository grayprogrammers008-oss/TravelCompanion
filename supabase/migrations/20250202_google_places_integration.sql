-- ============================================================================
-- Google Places API Integration Helper Functions
-- Description: Functions to import hospital data from Google Places API
-- Date: 2025-02-02
-- ============================================================================

-- ============================================================================
-- 1. Function to Upsert Hospital from Google Places Data
-- ============================================================================

CREATE OR REPLACE FUNCTION upsert_hospital_from_google_places(
    p_google_place_id TEXT,
    p_name TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_city TEXT,
    p_state TEXT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_rating DECIMAL DEFAULT NULL,
    p_total_reviews INTEGER DEFAULT 0,
    p_website TEXT DEFAULT NULL,
    p_specialties TEXT[] DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_hospital_id UUID;
    v_has_emergency BOOLEAN;
    v_is_24_7 BOOLEAN;
BEGIN
    -- Determine if hospital has emergency based on name/type
    v_has_emergency := (
        p_name ILIKE '%emergency%' OR
        p_name ILIKE '%trauma%' OR
        p_name ILIKE '%hospital%' OR
        p_name ILIKE '%medical college%' OR
        p_name ILIKE '%health%'
    );

    -- Assume large hospitals are 24/7
    v_is_24_7 := (
        p_name ILIKE '%hospital%' OR
        p_name ILIKE '%medical college%' OR
        p_name ILIKE '%super%' OR
        p_name ILIKE '%multi%'
    );

    -- Insert or update hospital
    INSERT INTO hospitals (
        google_place_id,
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
        rating,
        total_reviews,
        website,
        specialties,
        data_source,
        verified
    )
    VALUES (
        p_google_place_id,
        p_name,
        p_phone,
        p_address,
        p_city,
        p_state,
        p_latitude,
        p_longitude,
        'private', -- Default to private, can be updated manually
        v_has_emergency,
        v_is_24_7,
        p_rating,
        p_total_reviews,
        p_website,
        COALESCE(p_specialties, ARRAY['General Medicine']),
        'google_places',
        false -- Not verified yet
    )
    ON CONFLICT (google_place_id) DO UPDATE SET
        name = EXCLUDED.name,
        phone = EXCLUDED.phone,
        address = EXCLUDED.address,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        rating = EXCLUDED.rating,
        total_reviews = EXCLUDED.total_reviews,
        website = EXCLUDED.website,
        specialties = EXCLUDED.specialties,
        updated_at = NOW()
    RETURNING id INTO v_hospital_id;

    RETURN v_hospital_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. Batch Insert Function for Multiple Hospitals
-- ============================================================================

CREATE OR REPLACE FUNCTION batch_insert_hospitals(
    hospitals_json JSONB
)
RETURNS TABLE (
    inserted_count INTEGER,
    updated_count INTEGER,
    failed_count INTEGER
) AS $$
DECLARE
    v_hospital JSONB;
    v_inserted INTEGER := 0;
    v_updated INTEGER := 0;
    v_failed INTEGER := 0;
    v_existing_id UUID;
BEGIN
    FOR v_hospital IN SELECT * FROM jsonb_array_elements(hospitals_json)
    LOOP
        BEGIN
            -- Check if hospital already exists
            SELECT id INTO v_existing_id
            FROM hospitals
            WHERE google_place_id = v_hospital->>'google_place_id';

            IF v_existing_id IS NOT NULL THEN
                v_updated := v_updated + 1;
            ELSE
                v_inserted := v_inserted + 1;
            END IF;

            -- Upsert hospital
            PERFORM upsert_hospital_from_google_places(
                v_hospital->>'google_place_id',
                v_hospital->>'name',
                v_hospital->>'phone',
                v_hospital->>'address',
                v_hospital->>'city',
                v_hospital->>'state',
                (v_hospital->>'latitude')::DOUBLE PRECISION,
                (v_hospital->>'longitude')::DOUBLE PRECISION,
                CASE WHEN v_hospital->>'rating' IS NOT NULL
                     THEN (v_hospital->>'rating')::DECIMAL
                     ELSE NULL END,
                COALESCE((v_hospital->>'total_reviews')::INTEGER, 0),
                v_hospital->>'website',
                CASE WHEN v_hospital->'specialties' IS NOT NULL
                     THEN ARRAY(SELECT jsonb_array_elements_text(v_hospital->'specialties'))
                     ELSE NULL END
            );
        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            RAISE NOTICE 'Failed to insert hospital: %', v_hospital->>'name';
        END;
    END LOOP;

    RETURN QUERY SELECT v_inserted, v_updated, v_failed;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. Function to Get Statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_hospital_statistics()
RETURNS TABLE (
    total_hospitals BIGINT,
    government_hospitals BIGINT,
    private_hospitals BIGINT,
    emergency_hospitals BIGINT,
    hospitals_24_7 BIGINT,
    verified_hospitals BIGINT,
    cities_covered BIGINT,
    states_covered BIGINT,
    avg_rating DECIMAL,
    google_places_count BIGINT,
    manual_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT AS total_hospitals,
        COUNT(*) FILTER (WHERE hospital_type = 'government')::BIGINT AS government_hospitals,
        COUNT(*) FILTER (WHERE hospital_type = 'private')::BIGINT AS private_hospitals,
        COUNT(*) FILTER (WHERE has_emergency = true)::BIGINT AS emergency_hospitals,
        COUNT(*) FILTER (WHERE is_24_7 = true)::BIGINT AS hospitals_24_7,
        COUNT(*) FILTER (WHERE verified = true)::BIGINT AS verified_hospitals,
        COUNT(DISTINCT city)::BIGINT AS cities_covered,
        COUNT(DISTINCT state)::BIGINT AS states_covered,
        ROUND(AVG(rating), 2) AS avg_rating,
        COUNT(*) FILTER (WHERE data_source = 'google_places')::BIGINT AS google_places_count,
        COUNT(*) FILTER (WHERE data_source = 'manual')::BIGINT AS manual_count
    FROM hospitals
    WHERE is_active = true;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 4. Grant Permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION upsert_hospital_from_google_places TO authenticated;
GRANT EXECUTE ON FUNCTION batch_insert_hospitals TO authenticated;
GRANT EXECUTE ON FUNCTION get_hospital_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION get_hospital_statistics TO anon;

-- ============================================================================
-- DONE!
-- ============================================================================
