-- Migration: Add trip visibility (public/private) feature
-- Date: 2025-02-02
-- Description: Add is_public column to trips table to support public/private trip visibility

-- Add is_public column to trips table
-- Default to true (public) for backward compatibility with existing trips
ALTER TABLE public.trips
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true NOT NULL;

-- Add comment explaining the column
COMMENT ON COLUMN public.trips.is_public IS 'Trip visibility: true = public (discoverable by others), false = private (only visible to members)';

-- Create index for better query performance when filtering by visibility
CREATE INDEX IF NOT EXISTS idx_trips_is_public ON public.trips(is_public);

-- Update RLS policies to respect trip visibility
-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Users can view trips they are members of" ON public.trips;

-- Create new policy: Users can view trips they are members of OR public trips
CREATE POLICY "Users can view member trips or public trips"
ON public.trips
FOR SELECT
TO authenticated
USING (
  -- User is a member of the trip
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = trips.id
    AND trip_members.user_id = auth.uid()
  )
  OR
  -- Trip is public (anyone can discover it)
  is_public = true
);

-- Policy for creating trips (no change needed, but recreate for consistency)
CREATE POLICY "Users can create trips"
ON public.trips
FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- Policy for updating trips (only trip creator or admin members can update)
CREATE POLICY "Trip creator and admins can update trips"
ON public.trips
FOR UPDATE
TO authenticated
USING (
  created_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = trips.id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  created_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = trips.id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Policy for deleting trips (only trip creator can delete)
CREATE POLICY "Trip creator can delete trips"
ON public.trips
FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trips TO authenticated;
