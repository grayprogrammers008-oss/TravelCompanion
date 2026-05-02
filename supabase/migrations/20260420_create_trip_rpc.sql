-- Final fix: permissive INSERT policy + robust RPC for trip creation
-- Run this in Supabase Dashboard → SQL Editor

-- ── 1. Fix trips INSERT policy — most permissive safe option ─────────────────
DROP POLICY IF EXISTS "trips_insert" ON public.trips;
DROP POLICY IF EXISTS "Users can create trips" ON public.trips;

CREATE POLICY "trips_insert" ON public.trips
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- ── 2. Ensure trips SELECT policy exists ─────────────────────────────────────
DROP POLICY IF EXISTS "trips_select" ON public.trips;
DROP POLICY IF EXISTS "Users can view trips they are members of" ON public.trips;
DROP POLICY IF EXISTS "Users can view member trips or public trips" ON public.trips;

CREATE OR REPLACE FUNCTION public.get_my_trip_ids()
RETURNS SETOF UUID LANGUAGE sql SECURITY DEFINER STABLE
AS $$ SELECT trip_id FROM public.trip_members WHERE user_id = auth.uid(); $$;
GRANT EXECUTE ON FUNCTION public.get_my_trip_ids() TO authenticated;

CREATE POLICY "trips_select" ON public.trips
  FOR SELECT TO authenticated
  USING (id IN (SELECT public.get_my_trip_ids()) OR is_public = true);

-- ── 3. RPC for trip creation (atomic: trip + member in one call) ──────────────
CREATE OR REPLACE FUNCTION public.create_trip_for_user(
  p_name        TEXT,
  p_description TEXT        DEFAULT NULL,
  p_destination TEXT        DEFAULT NULL,
  p_start_date  TIMESTAMPTZ DEFAULT NULL,
  p_end_date    TIMESTAMPTZ DEFAULT NULL,
  p_cover_image TEXT        DEFAULT NULL,
  p_cost        FLOAT8      DEFAULT NULL,
  p_currency    TEXT        DEFAULT 'USD',
  p_is_public   BOOLEAN     DEFAULT true
)
RETURNS SETOF public.trips
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_trip_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.trips (
    name, description, destination,
    start_date, end_date, cover_image_url,
    cost, currency, is_public, created_by
  ) VALUES (
    p_name, p_description, p_destination,
    p_start_date, p_end_date, p_cover_image,
    p_cost, p_currency, p_is_public, v_user_id
  ) RETURNING id INTO v_trip_id;

  INSERT INTO public.trip_members (trip_id, user_id, role)
  VALUES (v_trip_id, v_user_id, 'admin')
  ON CONFLICT DO NOTHING;

  RETURN QUERY SELECT * FROM public.trips WHERE id = v_trip_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_trip_for_user(
  TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, FLOAT8, TEXT, BOOLEAN
) TO authenticated;

-- ── 4. Trigger to auto-add creator (safety net for direct inserts) ────────────
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

-- ── 5. Backfill existing trips ────────────────────────────────────────────────
INSERT INTO public.trip_members (trip_id, user_id, role)
SELECT t.id, t.created_by, 'admin'
FROM public.trips t
WHERE NOT EXISTS (
  SELECT 1 FROM public.trip_members tm
  WHERE tm.trip_id = t.id AND tm.user_id = t.created_by
)
ON CONFLICT DO NOTHING;
