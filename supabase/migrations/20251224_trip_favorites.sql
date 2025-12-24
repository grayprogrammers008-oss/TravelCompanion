-- Trip Favorites Feature
-- Allows users to mark trips as favorites for quick access

-- Create trip_favorites table
CREATE TABLE IF NOT EXISTS public.trip_favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Unique constraint: one favorite per user per trip
  UNIQUE(user_id, trip_id)
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_trip_favorites_user_id ON public.trip_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_favorites_trip_id ON public.trip_favorites(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_favorites_user_trip ON public.trip_favorites(user_id, trip_id);

-- Enable RLS
ALTER TABLE public.trip_favorites ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running migration)
DROP POLICY IF EXISTS "Users can view own favorites" ON public.trip_favorites;
DROP POLICY IF EXISTS "Users can add own favorites" ON public.trip_favorites;
DROP POLICY IF EXISTS "Users can remove own favorites" ON public.trip_favorites;

-- RLS Policies
-- Users can view their own favorites
CREATE POLICY "Users can view own favorites"
  ON public.trip_favorites FOR SELECT
  USING (auth.uid() = user_id);

-- Users can add their own favorites
CREATE POLICY "Users can add own favorites"
  ON public.trip_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can remove their own favorites
CREATE POLICY "Users can remove own favorites"
  ON public.trip_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Function to toggle favorite status
CREATE OR REPLACE FUNCTION public.toggle_trip_favorite(p_trip_id UUID)
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
    SELECT 1 FROM public.trip_favorites
    WHERE user_id = v_user_id AND trip_id = p_trip_id
  ) INTO v_exists;

  IF v_exists THEN
    -- Remove favorite
    DELETE FROM public.trip_favorites
    WHERE user_id = v_user_id AND trip_id = p_trip_id;
    RETURN FALSE; -- Not a favorite anymore
  ELSE
    -- Add favorite
    INSERT INTO public.trip_favorites (user_id, trip_id)
    VALUES (v_user_id, p_trip_id);
    RETURN TRUE; -- Now a favorite
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's favorite trip IDs
CREATE OR REPLACE FUNCTION public.get_user_favorite_trip_ids()
RETURNS TABLE(trip_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT tf.trip_id
  FROM public.trip_favorites tf
  WHERE tf.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.toggle_trip_favorite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_favorite_trip_ids() TO authenticated;

-- Add comment
COMMENT ON TABLE public.trip_favorites IS 'Stores user favorite trips for quick access';
