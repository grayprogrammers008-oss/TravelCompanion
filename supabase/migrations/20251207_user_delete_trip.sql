-- User Delete Trip Function
-- Allows trip owners to delete their own trips with proper cascade
-- Created: December 7, 2025

-- Function to delete trip (for trip owner)
CREATE OR REPLACE FUNCTION public.user_delete_trip(
  p_trip_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_trip_owner UUID;
BEGIN
  -- Check if the trip exists and get the owner
  SELECT created_by INTO v_trip_owner
  FROM public.trips
  WHERE id = p_trip_id;

  -- If trip doesn't exist, return false
  IF v_trip_owner IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  -- Check if the user is the trip owner
  IF v_trip_owner != auth.uid() THEN
    RAISE EXCEPTION 'Only the trip owner can delete this trip';
  END IF;

  -- Delete related data in the correct order (respecting foreign key constraints)

  -- 1. Delete conversation messages first
  DELETE FROM public.conversation_messages
  WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE trip_id = p_trip_id
  );

  -- 2. Delete conversation members
  DELETE FROM public.conversation_members
  WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE trip_id = p_trip_id
  );

  -- 3. Delete conversations
  DELETE FROM public.conversations WHERE trip_id = p_trip_id;

  -- 4. Delete join requests
  DELETE FROM public.trip_join_requests WHERE trip_id = p_trip_id;

  -- 5. Delete expense splits
  DELETE FROM public.expense_splits
  WHERE expense_id IN (
    SELECT id FROM public.expenses WHERE trip_id = p_trip_id
  );

  -- 6. Delete expenses
  DELETE FROM public.expenses WHERE trip_id = p_trip_id;

  -- 7. Delete checklist items
  DELETE FROM public.checklist_items
  WHERE checklist_id IN (
    SELECT id FROM public.checklists WHERE trip_id = p_trip_id
  );

  -- 8. Delete checklists
  DELETE FROM public.checklists WHERE trip_id = p_trip_id;

  -- 9. Delete itinerary items
  DELETE FROM public.itinerary_items WHERE trip_id = p_trip_id;

  -- 10. Delete trip invites
  DELETE FROM public.trip_invites WHERE trip_id = p_trip_id;

  -- 11. Delete trip members
  DELETE FROM public.trip_members WHERE trip_id = p_trip_id;

  -- 12. Finally delete the trip
  DELETE FROM public.trips WHERE id = p_trip_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.user_delete_trip TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.user_delete_trip IS 'Delete a trip and all related data (trip owner only)';
