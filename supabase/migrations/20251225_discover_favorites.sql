-- Discover Favorites Feature
-- Allows users to mark discovered places (from Google Places) as favorites
-- Persists across devices and syncs with the cloud

-- Create discover_favorites table
CREATE TABLE IF NOT EXISTS public.discover_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id TEXT NOT NULL, -- Google Places ID
  place_name TEXT NOT NULL, -- For display when offline
  place_category TEXT, -- Category like 'beach', 'heritage', etc.
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Unique constraint: one favorite per user per place
  UNIQUE(user_id, place_id)
);

-- Add indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_discover_favorites_user_id ON public.discover_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_discover_favorites_place_id ON public.discover_favorites(place_id);
CREATE INDEX IF NOT EXISTS idx_discover_favorites_user_place ON public.discover_favorites(user_id, place_id);

-- Enable RLS
ALTER TABLE public.discover_favorites ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running migration)
DROP POLICY IF EXISTS "Users can view own discover favorites" ON public.discover_favorites;
DROP POLICY IF EXISTS "Users can add own discover favorites" ON public.discover_favorites;
DROP POLICY IF EXISTS "Users can remove own discover favorites" ON public.discover_favorites;

-- RLS Policies
-- Users can view their own favorites
CREATE POLICY "Users can view own discover favorites"
  ON public.discover_favorites FOR SELECT
  USING (auth.uid() = user_id);

-- Users can add their own favorites
CREATE POLICY "Users can add own discover favorites"
  ON public.discover_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can remove their own favorites
CREATE POLICY "Users can remove own discover favorites"
  ON public.discover_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Function to toggle discover favorite status
-- Returns TRUE if added, FALSE if removed
CREATE OR REPLACE FUNCTION public.toggle_discover_favorite(
  p_place_id TEXT,
  p_place_name TEXT DEFAULT NULL,
  p_place_category TEXT DEFAULT NULL,
  p_latitude DOUBLE PRECISION DEFAULT NULL,
  p_longitude DOUBLE PRECISION DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Check if favorite exists
  SELECT EXISTS(
    SELECT 1 FROM public.discover_favorites
    WHERE user_id = v_user_id AND place_id = p_place_id
  ) INTO v_exists;

  IF v_exists THEN
    -- Remove favorite
    DELETE FROM public.discover_favorites
    WHERE user_id = v_user_id AND place_id = p_place_id;
    RETURN FALSE; -- Not a favorite anymore
  ELSE
    -- Add favorite with metadata
    INSERT INTO public.discover_favorites (user_id, place_id, place_name, place_category, latitude, longitude)
    VALUES (v_user_id, p_place_id, COALESCE(p_place_name, 'Unknown Place'), p_place_category, p_latitude, p_longitude);
    RETURN TRUE; -- Now a favorite
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's favorite discover place IDs
CREATE OR REPLACE FUNCTION public.get_user_discover_favorite_ids()
RETURNS TABLE(place_id TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT df.place_id
  FROM public.discover_favorites df
  WHERE df.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's discover favorites with full metadata
CREATE OR REPLACE FUNCTION public.get_user_discover_favorites()
RETURNS TABLE(
  place_id TEXT,
  place_name TEXT,
  place_category TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    df.place_id,
    df.place_name,
    df.place_category,
    df.latitude,
    df.longitude,
    df.created_at
  FROM public.discover_favorites df
  WHERE df.user_id = auth.uid()
  ORDER BY df.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.toggle_discover_favorite(TEXT, TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_discover_favorite_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_discover_favorites() TO authenticated;

-- Add comment
COMMENT ON TABLE public.discover_favorites IS 'Stores user favorite discovered places from Google Places for quick access';
