-- Fix: Infinite recursion in trip_members RLS policies
-- Policies that query trip_members to check membership cause recursion.
-- Solution: Use a SECURITY DEFINER function that bypasses RLS.

-- Helper function: returns trip IDs the current user belongs to (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_my_trip_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.get_my_trip_ids() TO authenticated;

-- Helper function: check if current user is member of a specific trip
CREATE OR REPLACE FUNCTION public.is_trip_member(p_trip_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_id = p_trip_id
    AND user_id = auth.uid()
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_trip_member(UUID) TO authenticated;

-- Drop all existing trip_members policies
DROP POLICY IF EXISTS "Users can view trip members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip members can view other members" ON public.trip_members;
DROP POLICY IF EXISTS "Members can view trip members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can add members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can remove members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can update members" ON public.trip_members;
DROP POLICY IF EXISTS "Users can leave trips" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_select_policy" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_insert_policy" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_update_policy" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_delete_policy" ON public.trip_members;

-- Recreate policies using the helper function (no recursion)

-- SELECT: members can see all members in their trips
CREATE POLICY "trip_members_select"
ON public.trip_members
FOR SELECT
USING (trip_id IN (SELECT public.get_my_trip_ids()));

-- INSERT: trip owner can add members
CREATE POLICY "trip_members_insert"
ON public.trip_members
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = trip_id
    AND trips.created_by = auth.uid()
  )
  OR user_id = auth.uid()
);

-- UPDATE: trip owner or admin can update members
CREATE POLICY "trip_members_update"
ON public.trip_members
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = trip_id
    AND trips.created_by = auth.uid()
  )
);

-- DELETE: trip owner can remove members, or member can leave themselves
CREATE POLICY "trip_members_delete"
ON public.trip_members
FOR DELETE
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = trip_id
    AND trips.created_by = auth.uid()
  )
);
