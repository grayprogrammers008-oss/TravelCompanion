-- RESCUE: Restore working RLS policies for trips and trip_members
-- Run this in Supabase Dashboard → SQL Editor

-- ── Helper functions (SECURITY DEFINER — no recursion) ───────────────────────

CREATE OR REPLACE FUNCTION public.get_my_trip_ids()
RETURNS SETOF UUID
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = public
AS $$
  SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid();
$$;
GRANT EXECUTE ON FUNCTION public.get_my_trip_ids() TO authenticated;

-- ── trips policies ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "trips_select" ON public.trips;
DROP POLICY IF EXISTS "trips_insert" ON public.trips;
DROP POLICY IF EXISTS "trips_update" ON public.trips;
DROP POLICY IF EXISTS "trips_delete" ON public.trips;
DROP POLICY IF EXISTS "Users can view trips they are members of" ON public.trips;
DROP POLICY IF EXISTS "Users can view member trips or public trips" ON public.trips;
DROP POLICY IF EXISTS "Users can create trips" ON public.trips;
DROP POLICY IF EXISTS "Trip creator and admins can update trips" ON public.trips;
DROP POLICY IF EXISTS "Trip creator can delete trips" ON public.trips;
DROP POLICY IF EXISTS "Trip owners can update their trips" ON public.trips;
DROP POLICY IF EXISTS "Trip owners can delete their trips" ON public.trips;

CREATE POLICY "trips_select" ON public.trips
  FOR SELECT TO authenticated
  USING (id IN (SELECT public.get_my_trip_ids()) OR is_public = true);

CREATE POLICY "trips_insert" ON public.trips
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "trips_update" ON public.trips
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "trips_delete" ON public.trips
  FOR DELETE TO authenticated
  USING (created_by = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.trips TO authenticated;

-- ── trip_members policies ─────────────────────────────────────────────────────

DROP POLICY IF EXISTS "trip_members_select" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_insert" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_update" ON public.trip_members;
DROP POLICY IF EXISTS "trip_members_delete" ON public.trip_members;
DROP POLICY IF EXISTS "Users can view trip members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip members can view other members" ON public.trip_members;
DROP POLICY IF EXISTS "Members can view trip members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can add members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can remove members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can update members" ON public.trip_members;
DROP POLICY IF EXISTS "Users can leave trips" ON public.trip_members;
DROP POLICY IF EXISTS "Trip members can view members" ON public.trip_members;
DROP POLICY IF EXISTS "Trip owners can manage members" ON public.trip_members;

CREATE POLICY "trip_members_select" ON public.trip_members
  FOR SELECT
  USING (trip_id IN (SELECT public.get_my_trip_ids()));

CREATE POLICY "trip_members_insert" ON public.trip_members
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.trips
      WHERE trips.id = trip_id AND trips.created_by = auth.uid()
    )
  );

CREATE POLICY "trip_members_update" ON public.trip_members
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.trips
      WHERE trips.id = trip_id AND trips.created_by = auth.uid()
    )
  );

CREATE POLICY "trip_members_delete" ON public.trip_members
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.trips
      WHERE trips.id = trip_id AND trips.created_by = auth.uid()
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.trip_members TO authenticated;

-- ── Auto-add creator trigger ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.auto_add_trip_creator()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.trip_members (trip_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin')
  ON CONFLICT DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_trip_created ON public.trips;
CREATE TRIGGER on_trip_created
  AFTER INSERT ON public.trips
  FOR EACH ROW EXECUTE FUNCTION public.auto_add_trip_creator();

-- ── Backfill existing trips ───────────────────────────────────────────────────

INSERT INTO public.trip_members (trip_id, user_id, role)
SELECT t.id, t.created_by, 'admin'
FROM public.trips t
WHERE NOT EXISTS (
  SELECT 1 FROM public.trip_members tm
  WHERE tm.trip_id = t.id AND tm.user_id = t.created_by
)
ON CONFLICT DO NOTHING;
