-- Trip Completion Feature - Database Schema Update
-- Date: November 19, 2025
-- Description: Adds trip completion tracking with rating support

-- Add is_completed column
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;

-- Add completed_at column
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Add rating column
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION DEFAULT 0.0;

-- Add constraint for rating range (0.0 to 5.0)
-- Drop constraint if it exists, then add it
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rating_range') THEN
        ALTER TABLE trips DROP CONSTRAINT rating_range;
    END IF;
END $$;

ALTER TABLE trips
ADD CONSTRAINT rating_range CHECK (rating >= 0.0 AND rating <= 5.0);

-- Create index for querying completed trips
CREATE INDEX IF NOT EXISTS idx_trips_completed ON trips(is_completed, completed_at DESC);

-- Create index for trips with ratings
CREATE INDEX IF NOT EXISTS idx_trips_rating ON trips(rating DESC) WHERE rating > 0.0;

-- Add comment to columns
COMMENT ON COLUMN trips.is_completed IS 'Indicates whether the trip has been marked as completed';
COMMENT ON COLUMN trips.completed_at IS 'Timestamp when the trip was marked as completed';
COMMENT ON COLUMN trips.rating IS 'User rating for the trip (0.0 to 5.0 stars)';
