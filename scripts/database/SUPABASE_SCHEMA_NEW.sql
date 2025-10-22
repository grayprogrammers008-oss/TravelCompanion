-- =====================================================
-- TRAVEL CREW APP - SUPABASE DATABASE SCHEMA
-- Comprehensive End-to-End Schema with Idempotent Setup
-- Version: 2.0 - Enhanced with DROP IF EXISTS
-- =====================================================

-- =====================================================
-- CLEANUP: Drop existing objects in reverse dependency order
-- =====================================================

-- Drop policies first
DO $$
BEGIN
    -- Drop all RLS policies for all tables
    DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
    DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
    DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

    DROP POLICY IF EXISTS "Users can view trips they are members of" ON trips;
    DROP POLICY IF EXISTS "Users can create trips" ON trips;
    DROP POLICY IF EXISTS "Trip admins can update trips" ON trips;
    DROP POLICY IF EXISTS "Trip admins can delete trips" ON trips;

    DROP POLICY IF EXISTS "Users can view trip members" ON trip_members;
    DROP POLICY IF EXISTS "Trip admins can add members" ON trip_members;
    DROP POLICY IF EXISTS "Trip admins can remove members" ON trip_members;

    DROP POLICY IF EXISTS "Users can view invites for their trips" ON trip_invites;
    DROP POLICY IF EXISTS "Trip members can create invites" ON trip_invites;
    DROP POLICY IF EXISTS "Users can update invite status" ON trip_invites;

    DROP POLICY IF EXISTS "Trip members can view itinerary items" ON itinerary_items;
    DROP POLICY IF EXISTS "Trip members can create itinerary items" ON itinerary_items;
    DROP POLICY IF EXISTS "Trip members can update itinerary items" ON itinerary_items;
    DROP POLICY IF EXISTS "Trip members can delete itinerary items" ON itinerary_items;

    DROP POLICY IF EXISTS "Trip members can view checklists" ON checklists;
    DROP POLICY IF EXISTS "Trip members can create checklists" ON checklists;
    DROP POLICY IF EXISTS "Trip members can update checklists" ON checklists;
    DROP POLICY IF EXISTS "Trip members can delete checklists" ON checklists;

    DROP POLICY IF EXISTS "Users can view checklist items" ON checklist_items;
    DROP POLICY IF EXISTS "Users can manage checklist items" ON checklist_items;

    DROP POLICY IF EXISTS "Trip members can view expenses" ON expenses;
    DROP POLICY IF EXISTS "Trip members can create expenses" ON expenses;
    DROP POLICY IF EXISTS "Trip members can update expenses" ON expenses;
    DROP POLICY IF EXISTS "Trip members can delete expenses" ON expenses;

    DROP POLICY IF EXISTS "Users can view expense splits" ON expense_splits;
    DROP POLICY IF EXISTS "Users can manage expense splits" ON expense_splits;

    DROP POLICY IF EXISTS "Trip members can view settlements" ON settlements;
    DROP POLICY IF EXISTS "Users can create settlements" ON settlements;
    DROP POLICY IF EXISTS "Users can update settlement status" ON settlements;

    DROP POLICY IF EXISTS "Trip members can view suggestions" ON autopilot_suggestions;
    DROP POLICY IF EXISTS "Trip members can accept suggestions" ON autopilot_suggestions;

    DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
    DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
END $$;

-- Drop indexes
DROP INDEX IF EXISTS idx_trip_members_trip_id;
DROP INDEX IF EXISTS idx_trip_members_user_id;
DROP INDEX IF EXISTS idx_trip_invites_trip_id;
DROP INDEX IF EXISTS idx_trip_invites_invite_code;
DROP INDEX IF EXISTS idx_trip_invites_email;
DROP INDEX IF EXISTS idx_trip_invites_status;
DROP INDEX IF EXISTS idx_itinerary_items_trip_id;
DROP INDEX IF EXISTS idx_itinerary_items_day_number;
DROP INDEX IF EXISTS idx_itinerary_items_trip_day;
DROP INDEX IF EXISTS idx_checklists_trip_id;
DROP INDEX IF EXISTS idx_checklist_items_checklist_id;
DROP INDEX IF EXISTS idx_checklist_items_assigned_to;
DROP INDEX IF EXISTS idx_expenses_trip_id;
DROP INDEX IF EXISTS idx_expenses_paid_by;
DROP INDEX IF EXISTS idx_expenses_transaction_date;
DROP INDEX IF EXISTS idx_expense_splits_expense_id;
DROP INDEX IF EXISTS idx_expense_splits_user_id;
DROP INDEX IF EXISTS idx_expense_splits_unsettled;
DROP INDEX IF EXISTS idx_settlements_trip_id;
DROP INDEX IF EXISTS idx_settlements_from_user;
DROP INDEX IF EXISTS idx_settlements_to_user;
DROP INDEX IF EXISTS idx_settlements_status;
DROP INDEX IF EXISTS idx_autopilot_suggestions_trip_id;
DROP INDEX IF EXISTS idx_autopilot_suggestions_unaccepted;
DROP INDEX IF EXISTS idx_notifications_user_id;
DROP INDEX IF EXISTS idx_notifications_is_read;
DROP INDEX IF EXISTS idx_notifications_created_at;

-- Drop triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_trips_updated_at ON trips;
DROP TRIGGER IF EXISTS update_itinerary_items_updated_at ON itinerary_items;
DROP TRIGGER IF EXISTS update_checklists_updated_at ON checklists;
DROP TRIGGER IF EXISTS update_checklist_items_updated_at ON checklist_items;
DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses;
DROP TRIGGER IF EXISTS create_trip_member_for_creator ON trips;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- Drop functions
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS create_trip_member_for_creator() CASCADE;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS autopilot_suggestions CASCADE;
DROP TABLE IF EXISTS settlements CASCADE;
DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS expenses CASCADE;
DROP TABLE IF EXISTS checklist_items CASCADE;
DROP TABLE IF EXISTS checklists CASCADE;
DROP TABLE IF EXISTS itinerary_items CASCADE;
DROP TABLE IF EXISTS trip_invites CASCADE;
DROP TABLE IF EXISTS trip_members CASCADE;
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- =====================================================
-- EXTENSIONS
-- =====================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable case-insensitive text searches
CREATE EXTENSION IF NOT EXISTS "citext";

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user creation (creates profile automatically)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create trip member for trip creator
CREATE OR REPLACE FUNCTION create_trip_member_for_creator()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.trip_members (trip_id, user_id, role, joined_at)
    VALUES (NEW.id, NEW.created_by, 'admin', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

