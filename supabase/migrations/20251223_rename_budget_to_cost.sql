-- Migration: Rename budget to cost
-- This reflects the semantic change: "cost" is what the trip costs (factual)
-- Budget tracking is removed - expense tracking + settlements handle money management

-- Rename the column
ALTER TABLE public.trips
RENAME COLUMN budget TO cost;

-- Add comment explaining the field
COMMENT ON COLUMN public.trips.cost IS 'The cost of the trip per person (set by organizer/creator). This is informational - actual expense tracking is done via the expenses table.';
