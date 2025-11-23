-- Migration: Add budget and currency columns to trips table
-- Date: 2025-01-23
-- Description: Adds budget tracking fields to support trip budgeting feature

-- Add budget column (optional, can be null)
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS budget DECIMAL(12, 2) DEFAULT NULL;

-- Add currency column (required, defaults to INR)
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'INR';

-- Add index on currency for faster queries
CREATE INDEX IF NOT EXISTS idx_trips_currency ON trips(currency);

-- Add comment for documentation
COMMENT ON COLUMN trips.budget IS 'Planned budget for the trip in the specified currency';
COMMENT ON COLUMN trips.currency IS 'Currency code (e.g., INR, USD, EUR) for trip budget and expenses';

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'trips'
AND column_name IN ('budget', 'currency')
ORDER BY column_name;
