-- Allow reading trip_members for public trips (so organizer/member count shows on Explore tab)

DROP POLICY IF EXISTS "trip_members_select" ON public.trip_members;

CREATE POLICY "trip_members_select" ON public.trip_members
  FOR SELECT TO authenticated
  USING (
    trip_id IN (SELECT public.get_my_trip_ids())
    OR EXISTS (
      SELECT 1 FROM public.trips
      WHERE trips.id = trip_id AND trips.is_public = true
    )
  );
