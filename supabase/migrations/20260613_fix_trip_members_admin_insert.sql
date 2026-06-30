-- Fix: Allow trip admins (role = 'admin') to add members, not just creators.
--
-- Root cause: The INSERT policy on trip_members only permits the trip creator
-- (trips.created_by = auth.uid()). But the UI grants "canManageMembers" to
-- any member with role='admin'. Those admins hit an RLS violation when they
-- try to add someone.
--
-- Solution: Add a SECURITY DEFINER helper (avoids recursion) and extend the
-- INSERT policy to cover admins.

-- Helper: returns TRUE if the current user has role 'admin' in the given trip.
-- SECURITY DEFINER bypasses RLS on trip_members, preventing infinite recursion.
CREATE OR REPLACE FUNCTION public.is_trip_admin(p_trip_id UUID)
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
      AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_trip_admin(UUID) TO authenticated;

-- Extend the INSERT policy so trip admins can also add members.
DROP POLICY IF EXISTS "trip_members_insert" ON public.trip_members;

CREATE POLICY "trip_members_insert" ON public.trip_members
  FOR INSERT
  WITH CHECK (
    -- user is adding themselves (e.g. joining via invite link)
    user_id = auth.uid()
    -- or the logged-in user is the trip creator
    OR EXISTS (
      SELECT 1 FROM public.trips
      WHERE trips.id = trip_id
        AND trips.created_by = auth.uid()
    )
    -- or the logged-in user is a trip admin
    OR public.is_trip_admin(trip_id)
  );
