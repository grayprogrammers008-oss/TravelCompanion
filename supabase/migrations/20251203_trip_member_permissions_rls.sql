-- =====================================================
-- Trip Member Permissions - Row Level Security Policies
-- =====================================================
-- This migration adds RLS policies to enforce that:
-- 1. Only trip owner can edit/delete trip details
-- 2. Only trip owner/admin can edit itinerary and checklists
-- 3. All members can add expenses, but only edit/delete their own
-- =====================================================

-- =====================================================
-- TRIPS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip owners can update their trips" ON public.trips;
DROP POLICY IF EXISTS "Trip owners can delete their trips" ON public.trips;

-- Only trip owner can update trip details
CREATE POLICY "Trip owners can update their trips"
ON public.trips
FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Only trip owner can delete trips
CREATE POLICY "Trip owners can delete their trips"
ON public.trips
FOR DELETE
USING (created_by = auth.uid());

-- =====================================================
-- ITINERARY_ITEMS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view itinerary" ON public.itinerary_items;
DROP POLICY IF EXISTS "Trip owners and admins can insert itinerary" ON public.itinerary_items;
DROP POLICY IF EXISTS "Trip owners and admins can update itinerary" ON public.itinerary_items;
DROP POLICY IF EXISTS "Trip owners and admins can delete itinerary" ON public.itinerary_items;

-- All trip members can view itinerary
CREATE POLICY "Trip members can view itinerary"
ON public.itinerary_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Only trip owner or admin can insert itinerary items
CREATE POLICY "Trip owners and admins can insert itinerary"
ON public.itinerary_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can update itinerary items
CREATE POLICY "Trip owners and admins can update itinerary"
ON public.itinerary_items
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can delete itinerary items
CREATE POLICY "Trip owners and admins can delete itinerary"
ON public.itinerary_items
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = itinerary_items.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = itinerary_items.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- =====================================================
-- CHECKLISTS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view checklists" ON public.checklists;
DROP POLICY IF EXISTS "Trip owners and admins can insert checklists" ON public.checklists;
DROP POLICY IF EXISTS "Trip owners and admins can update checklists" ON public.checklists;
DROP POLICY IF EXISTS "Trip owners and admins can delete checklists" ON public.checklists;

-- All trip members can view checklists
CREATE POLICY "Trip members can view checklists"
ON public.checklists
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Only trip owner or admin can insert checklists
CREATE POLICY "Trip owners and admins can insert checklists"
ON public.checklists
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can update checklists
CREATE POLICY "Trip owners and admins can update checklists"
ON public.checklists
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only trip owner or admin can delete checklists
CREATE POLICY "Trip owners and admins can delete checklists"
ON public.checklists
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = checklists.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = checklists.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- =====================================================
-- CHECKLIST_ITEMS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Trip owners and admins can insert checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Trip owners and admins can update checklist items" ON public.checklist_items;
DROP POLICY IF EXISTS "Trip owners and admins can delete checklist items" ON public.checklist_items;

-- All trip members can view checklist items
CREATE POLICY "Trip members can view checklist items"
ON public.checklist_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
  )
);

-- Only trip owner or admin can insert checklist items
CREATE POLICY "Trip owners and admins can insert checklist items"
ON public.checklist_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- Only trip owner or admin can update checklist items
CREATE POLICY "Trip owners and admins can update checklist items"
ON public.checklist_items
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- Only trip owner or admin can delete checklist items
CREATE POLICY "Trip owners and admins can delete checklist items"
ON public.checklist_items
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trips t ON t.id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.checklists c
    JOIN public.trip_members tm ON tm.trip_id = c.trip_id
    WHERE c.id = checklist_items.checklist_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- =====================================================
-- EXPENSES TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view expenses" ON public.expenses;
DROP POLICY IF EXISTS "Trip members can insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Expense owners and trip admins can update expenses" ON public.expenses;
DROP POLICY IF EXISTS "Expense owners and trip admins can delete expenses" ON public.expenses;

-- All trip members can view expenses
CREATE POLICY "Trip members can view expenses"
ON public.expenses
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- All trip members can insert expenses (add their own expenses)
CREATE POLICY "Trip members can insert expenses"
ON public.expenses
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Only expense creator (payer), trip owner, or admin can update expenses
CREATE POLICY "Expense owners and trip admins can update expenses"
ON public.expenses
FOR UPDATE
USING (
  -- Expense creator (payer) can update
  paid_by = auth.uid()
  OR
  -- Trip owner can update any expense
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = expenses.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  -- Trip admin can update any expense
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
)
WITH CHECK (
  paid_by = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = expenses.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- Only expense creator (payer), trip owner, or admin can delete expenses
CREATE POLICY "Expense owners and trip admins can delete expenses"
ON public.expenses
FOR DELETE
USING (
  -- Expense creator (payer) can delete
  paid_by = auth.uid()
  OR
  -- Trip owner can delete any expense
  EXISTS (
    SELECT 1 FROM public.trips
    WHERE trips.id = expenses.trip_id
    AND trips.created_by = auth.uid()
  )
  OR
  -- Trip admin can delete any expense
  EXISTS (
    SELECT 1 FROM public.trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
    AND trip_members.role = 'admin'
  )
);

-- =====================================================
-- EXPENSE_SPLITS TABLE POLICIES
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Trip members can view expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Trip members can insert expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Expense owners and trip admins can update expense splits" ON public.expense_splits;
DROP POLICY IF EXISTS "Expense owners and trip admins can delete expense splits" ON public.expense_splits;

-- All trip members can view expense splits
CREATE POLICY "Trip members can view expense splits"
ON public.expense_splits
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
  )
);

-- All trip members can insert expense splits (when creating expenses)
CREATE POLICY "Trip members can insert expense splits"
ON public.expense_splits
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
  )
);

-- Only expense creator (payer), trip owner, or admin can update expense splits
CREATE POLICY "Expense owners and trip admins can update expense splits"
ON public.expense_splits
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_splits.expense_id
    AND e.paid_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trips t ON t.id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_splits.expense_id
    AND e.paid_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trips t ON t.id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- Only expense creator (payer), trip owner, or admin can delete expense splits
CREATE POLICY "Expense owners and trip admins can delete expense splits"
ON public.expense_splits
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_splits.expense_id
    AND e.paid_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trips t ON t.id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND t.created_by = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.trip_members tm ON tm.trip_id = e.trip_id
    WHERE e.id = expense_splits.expense_id
    AND tm.user_id = auth.uid()
    AND tm.role = 'admin'
  )
);

-- =====================================================
-- SUMMARY
-- =====================================================
-- Trips: Only owner can edit/delete
-- Itinerary: Owner and admins can edit, all members can view
-- Checklists: Owner and admins can edit, all members can view
-- Checklist Items: Owner and admins can edit, all members can view
-- Expenses: All members can add, only creator/owner/admin can edit/delete
-- Expense Splits: Same as expenses
-- =====================================================
