-- Fix: trips INSERT + SELECT so insert().select() works correctly
-- Run in Supabase Dashboard → SQL Editor

-- Fix SELECT policy: creator can always see their own trips
-- (without this, insert().select() fails because trigger hasn't committed yet)
DROP POLICY IF EXISTS "trips_select" ON public.trips;
DROP POLICY IF EXISTS "Users can view trips they are members of" ON public.trips;
DROP POLICY IF EXISTS "Users can view member trips or public trips" ON public.trips;

CREATE OR REPLACE FUNCTION public.get_my_trip_ids()
RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE
AS $$ SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid(); $$;
GRANT EXECUTE ON FUNCTION public.get_my_trip_ids() TO authenticated;

CREATE POLICY "trips_select" ON public.trips
  FOR SELECT TO authenticated
  USING (
    created_by = auth.uid()
    OR id IN (SELECT public.get_my_trip_ids())
    OR is_public = true
  );

-- Fix INSERT policy
DROP POLICY IF EXISTS "trips_insert" ON public.trips;
DROP POLICY IF EXISTS "Users can create trips" ON public.trips;

CREATE POLICY "trips_insert" ON public.trips
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Trigger: auto-add creator to trip_members
CREATE OR REPLACE FUNCTION public.auto_add_trip_creator()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.trip_members (trip_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin')
  ON CONFLICT DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_trip_created ON public.trips;
CREATE TRIGGER on_trip_created
  AFTER INSERT ON public.trips
  FOR EACH ROW EXECUTE FUNCTION public.auto_add_trip_creator();

-- Backfill existing trips
INSERT INTO public.trip_members (trip_id, user_id, role)
SELECT t.id, t.created_by, 'admin'
FROM public.trips t
WHERE NOT EXISTS (
  SELECT 1 FROM public.trip_members tm
  WHERE tm.trip_id = t.id AND tm.user_id = t.created_by
)
ON CONFLICT DO NOTHING;
