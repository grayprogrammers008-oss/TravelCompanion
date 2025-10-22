-- =====================================================
-- ADD INSERT POLICIES for Trips and Expenses
-- =====================================================
-- This adds RLS policies that allow users to create trips and expenses
-- Run this if you get "User not logged in" when creating trips/expenses
-- =====================================================

-- =====================================================
-- TRIPS: Allow users to create trips
-- =====================================================

DROP POLICY IF EXISTS "Users can create trips" ON trips;
CREATE POLICY "Users can create trips"
ON trips
FOR INSERT
WITH CHECK (auth.uid() = created_by);

RAISE NOTICE '✓ Added INSERT policy for trips';

-- =====================================================
-- TRIP_MEMBERS: Already created in COMPLETE_FIX.sql
-- But let's ensure it exists
-- =====================================================

DROP POLICY IF EXISTS "Users can create trip members" ON trip_members;
CREATE POLICY "Users can create trip members"
ON trip_members
FOR INSERT
WITH CHECK (
  trip_id IN (
    SELECT id FROM trips WHERE created_by = auth.uid()
  )
);

RAISE NOTICE '✓ Added INSERT policy for trip_members';

-- =====================================================
-- EXPENSES: Allow users to create expenses
-- =====================================================

DROP POLICY IF EXISTS "Users can create expenses" ON expenses;
CREATE POLICY "Users can create expenses"
ON expenses
FOR INSERT
WITH CHECK (auth.uid() = paid_by);

RAISE NOTICE '✓ Added INSERT policy for expenses';

-- =====================================================
-- EXPENSE_SPLITS: Allow creating expense splits
-- =====================================================

DROP POLICY IF EXISTS "Users can create expense splits" ON expense_splits;
CREATE POLICY "Users can create expense splits"
ON expense_splits
FOR INSERT
WITH CHECK (
  expense_id IN (
    SELECT id FROM expenses WHERE paid_by = auth.uid()
  )
);

RAISE NOTICE '✓ Added INSERT policy for expense_splits';

-- =====================================================
-- ITINERARY_ITEMS: Allow creating itinerary items
-- =====================================================

DROP POLICY IF EXISTS "Users can create itinerary items" ON itinerary_items;
CREATE POLICY "Users can create itinerary items"
ON itinerary_items
FOR INSERT
WITH CHECK (
  trip_id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
  )
);

RAISE NOTICE '✓ Added INSERT policy for itinerary_items';

-- =====================================================
-- CHECKLISTS: Allow creating checklists
-- =====================================================

DROP POLICY IF EXISTS "Users can create checklists" ON checklists;
CREATE POLICY "Users can create checklists"
ON checklists
FOR INSERT
WITH CHECK (
  trip_id IN (
    SELECT trip_id FROM trip_members WHERE user_id = auth.uid()
  )
);

RAISE NOTICE '✓ Added INSERT policy for checklists';

-- =====================================================
-- CHECKLIST_ITEMS: Allow creating checklist items
-- =====================================================

DROP POLICY IF EXISTS "Users can create checklist items" ON checklist_items;
CREATE POLICY "Users can create checklist items"
ON checklist_items
FOR INSERT
WITH CHECK (
  checklist_id IN (
    SELECT id FROM checklists WHERE created_by = auth.uid()
  )
);

RAISE NOTICE '✓ Added INSERT policy for checklist_items';

-- =====================================================
-- VERIFICATION: Show all INSERT policies
-- =====================================================

SELECT
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE cmd = 'INSERT'
  AND tablename IN ('trips', 'trip_members', 'expenses', 'expense_splits', 'itinerary_items', 'checklists', 'checklist_items')
ORDER BY tablename, policyname;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════╗';
  RAISE NOTICE '║  ✅ INSERT POLICIES ADDED!                         ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Users can now create:';
  RAISE NOTICE '  - Trips';
  RAISE NOTICE '  - Trip members';
  RAISE NOTICE '  - Expenses';
  RAISE NOTICE '  - Expense splits';
  RAISE NOTICE '  - Itinerary items';
  RAISE NOTICE '  - Checklists';
  RAISE NOTICE '  - Checklist items';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Next: Try creating a trip or expense in your app!';
  RAISE NOTICE '';
END $$;
