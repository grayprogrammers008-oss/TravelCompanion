-- Migration: Add location coordinates to itinerary_items table
-- Date: 2025-12-13
-- Description: Adds latitude, longitude, and place_id columns to support Google Maps location sharing

-- Add new columns to itinerary_items table
ALTER TABLE public.itinerary_items
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS place_id TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.itinerary_items.latitude IS 'Latitude coordinate from Google Maps share';
COMMENT ON COLUMN public.itinerary_items.longitude IS 'Longitude coordinate from Google Maps share';
COMMENT ON COLUMN public.itinerary_items.place_id IS 'Google Maps Place ID for the location';

-- Create index for geospatial queries (optional, for future use)
CREATE INDEX IF NOT EXISTS idx_itinerary_items_location
ON public.itinerary_items (latitude, longitude)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
