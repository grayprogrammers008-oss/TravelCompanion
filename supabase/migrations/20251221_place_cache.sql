-- ============================================================================
-- Place Cache Table for Google Places API
-- Description: Cache place details to minimize API calls and costs
-- Date: 2025-12-21
-- ============================================================================

-- ============================================================================
-- 1. Place Cache Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.place_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Google Places identifiers
    place_id TEXT UNIQUE NOT NULL,

    -- Basic info
    name TEXT NOT NULL,
    formatted_address TEXT,

    -- Location
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,

    -- Address components
    city TEXT,
    state TEXT,
    country TEXT,
    country_code TEXT,

    -- Place types (array of strings like 'locality', 'country', etc.)
    types TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Photo references (store first 5 photo references)
    photo_references TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Additional info
    website TEXT,
    google_maps_url TEXT,
    rating DECIMAL(2,1),
    user_ratings_total INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    access_count INTEGER DEFAULT 1
);

-- ============================================================================
-- 2. Indexes for Performance
-- ============================================================================

-- Index on place_id for quick lookups
CREATE INDEX IF NOT EXISTS idx_place_cache_place_id ON public.place_cache(place_id);

-- Index on city for destination searches
CREATE INDEX IF NOT EXISTS idx_place_cache_city ON public.place_cache(city);

-- Index on country for filtering
CREATE INDEX IF NOT EXISTS idx_place_cache_country ON public.place_cache(country);

-- Index on last_accessed_at for cache cleanup
CREATE INDEX IF NOT EXISTS idx_place_cache_last_accessed ON public.place_cache(last_accessed_at);

-- GIN index on types array for type-based searches
CREATE INDEX IF NOT EXISTS idx_place_cache_types ON public.place_cache USING GIN(types);

-- ============================================================================
-- 3. Functions
-- ============================================================================

-- Function to upsert a place into cache
CREATE OR REPLACE FUNCTION upsert_place_cache(
    p_place_id TEXT,
    p_name TEXT,
    p_formatted_address TEXT DEFAULT NULL,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_country TEXT DEFAULT NULL,
    p_country_code TEXT DEFAULT NULL,
    p_types TEXT[] DEFAULT NULL,
    p_photo_references TEXT[] DEFAULT NULL,
    p_website TEXT DEFAULT NULL,
    p_google_maps_url TEXT DEFAULT NULL,
    p_rating DECIMAL DEFAULT NULL,
    p_user_ratings_total INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.place_cache (
        place_id,
        name,
        formatted_address,
        latitude,
        longitude,
        city,
        state,
        country,
        country_code,
        types,
        photo_references,
        website,
        google_maps_url,
        rating,
        user_ratings_total
    )
    VALUES (
        p_place_id,
        p_name,
        p_formatted_address,
        p_latitude,
        p_longitude,
        p_city,
        p_state,
        p_country,
        p_country_code,
        COALESCE(p_types, ARRAY[]::TEXT[]),
        COALESCE(p_photo_references, ARRAY[]::TEXT[]),
        p_website,
        p_google_maps_url,
        p_rating,
        p_user_ratings_total
    )
    ON CONFLICT (place_id) DO UPDATE SET
        name = EXCLUDED.name,
        formatted_address = EXCLUDED.formatted_address,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        country = EXCLUDED.country,
        country_code = EXCLUDED.country_code,
        types = EXCLUDED.types,
        photo_references = EXCLUDED.photo_references,
        website = EXCLUDED.website,
        google_maps_url = EXCLUDED.google_maps_url,
        rating = EXCLUDED.rating,
        user_ratings_total = EXCLUDED.user_ratings_total,
        updated_at = NOW(),
        last_accessed_at = NOW(),
        access_count = place_cache.access_count + 1
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get place from cache and update access stats
CREATE OR REPLACE FUNCTION get_place_from_cache(p_place_id TEXT)
RETURNS TABLE (
    id UUID,
    place_id TEXT,
    name TEXT,
    formatted_address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    city TEXT,
    state TEXT,
    country TEXT,
    country_code TEXT,
    types TEXT[],
    photo_references TEXT[],
    website TEXT,
    google_maps_url TEXT,
    rating DECIMAL,
    user_ratings_total INTEGER
) AS $$
BEGIN
    -- Update access stats
    UPDATE public.place_cache
    SET
        last_accessed_at = NOW(),
        access_count = place_cache.access_count + 1
    WHERE place_cache.place_id = p_place_id;

    -- Return the place
    RETURN QUERY
    SELECT
        pc.id,
        pc.place_id,
        pc.name,
        pc.formatted_address,
        pc.latitude,
        pc.longitude,
        pc.city,
        pc.state,
        pc.country,
        pc.country_code,
        pc.types,
        pc.photo_references,
        pc.website,
        pc.google_maps_url,
        pc.rating,
        pc.user_ratings_total
    FROM public.place_cache pc
    WHERE pc.place_id = p_place_id;
END;
$$ LANGUAGE plpgsql;

-- Function to search places in cache
CREATE OR REPLACE FUNCTION search_cached_places(
    p_query TEXT,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    place_id TEXT,
    name TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    types TEXT[],
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.place_id,
        pc.name,
        pc.city,
        pc.state,
        pc.country,
        pc.types,
        pc.latitude,
        pc.longitude
    FROM public.place_cache pc
    WHERE
        pc.name ILIKE '%' || p_query || '%' OR
        pc.city ILIKE '%' || p_query || '%' OR
        pc.state ILIKE '%' || p_query || '%' OR
        pc.country ILIKE '%' || p_query || '%'
    ORDER BY
        pc.access_count DESC,
        pc.last_accessed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to clean up old cache entries (not accessed in 90 days)
CREATE OR REPLACE FUNCTION cleanup_place_cache(p_days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM public.place_cache
    WHERE last_accessed_at < NOW() - (p_days_old || ' days')::INTERVAL;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. RLS Policies
-- ============================================================================

ALTER TABLE public.place_cache ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read cache
CREATE POLICY "Authenticated users can read place cache"
    ON public.place_cache
    FOR SELECT
    TO authenticated
    USING (true);

-- Allow all authenticated users to insert into cache
CREATE POLICY "Authenticated users can insert place cache"
    ON public.place_cache
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow all authenticated users to update cache
CREATE POLICY "Authenticated users can update place cache"
    ON public.place_cache
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- 5. Grant Permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON public.place_cache TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_place_cache TO authenticated;
GRANT EXECUTE ON FUNCTION get_place_from_cache TO authenticated;
GRANT EXECUTE ON FUNCTION search_cached_places TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_place_cache TO authenticated;

-- ============================================================================
-- DONE!
-- ============================================================================
