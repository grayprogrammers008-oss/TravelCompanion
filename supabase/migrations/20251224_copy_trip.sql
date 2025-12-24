-- Copy Trip Function
-- Copies a trip with its itinerary and checklists in a single transaction
-- Created: 2024-12-24

CREATE OR REPLACE FUNCTION public.copy_trip(
  p_source_trip_id UUID,
  p_new_name TEXT,
  p_new_start_date TIMESTAMPTZ,
  p_new_end_date TIMESTAMPTZ,
  p_copy_itinerary BOOLEAN DEFAULT true,
  p_copy_checklists BOOLEAN DEFAULT true
)
RETURNS UUID  -- Returns the new trip ID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_new_trip_id UUID;
  v_source_trip RECORD;
  v_checklist RECORD;
  v_new_checklist_id UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify user has access to source trip (is a member)
  IF NOT EXISTS (
    SELECT 1 FROM trip_members
    WHERE trip_id = p_source_trip_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Access denied to source trip';
  END IF;

  -- Get source trip data
  SELECT * INTO v_source_trip FROM trips WHERE id = p_source_trip_id;
  IF v_source_trip IS NULL THEN
    RAISE EXCEPTION 'Source trip not found';
  END IF;

  -- Create new trip
  INSERT INTO trips (
    name,
    description,
    destination,
    start_date,
    end_date,
    cover_image_url,
    cost,
    currency,
    is_public,
    created_by,
    is_completed,
    rating,
    completed_at
  ) VALUES (
    p_new_name,
    v_source_trip.description,
    v_source_trip.destination,
    p_new_start_date,
    p_new_end_date,
    v_source_trip.cover_image_url,
    v_source_trip.cost,
    v_source_trip.currency,
    v_source_trip.is_public,
    v_user_id,           -- Current user becomes creator
    false,               -- Reset to not completed
    NULL,                -- Reset rating
    NULL                 -- Reset completed_at
  ) RETURNING id INTO v_new_trip_id;

  -- Add current user as trip member (admin role)
  INSERT INTO trip_members (trip_id, user_id, role)
  VALUES (v_new_trip_id, v_user_id, 'admin');

  -- Copy itinerary if requested
  IF p_copy_itinerary THEN
    INSERT INTO itinerary_items (
      trip_id,
      title,
      description,
      location,
      latitude,
      longitude,
      place_id,
      day_number,
      order_index,
      start_time,
      end_time
    )
    SELECT
      v_new_trip_id,
      title,
      description,
      location,
      latitude,
      longitude,
      place_id,
      day_number,        -- Keep same day numbers
      order_index,
      NULL,              -- Clear start_time (will be recalculated based on new dates)
      NULL               -- Clear end_time
    FROM itinerary_items
    WHERE trip_id = p_source_trip_id;
  END IF;

  -- Copy checklists if requested
  IF p_copy_checklists THEN
    FOR v_checklist IN
      SELECT * FROM checklists WHERE trip_id = p_source_trip_id
    LOOP
      -- Create new checklist
      INSERT INTO checklists (trip_id, name, created_by)
      VALUES (v_new_trip_id, v_checklist.name, v_user_id)
      RETURNING id INTO v_new_checklist_id;

      -- Copy checklist items (all unchecked)
      INSERT INTO checklist_items (
        checklist_id,
        name,
        is_completed,
        order_index
      )
      SELECT
        v_new_checklist_id,
        name,
        false,           -- Reset all to unchecked
        order_index
      FROM checklist_items
      WHERE checklist_id = v_checklist.id;
    END LOOP;
  END IF;

  RETURN v_new_trip_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.copy_trip TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION public.copy_trip IS 'Copies a trip with optional itinerary and checklists. Returns the new trip ID.';
