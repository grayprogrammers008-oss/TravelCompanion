-- ============================================================================
-- TRAVEL COMPANION - CLEAN DATABASE MIGRATION SCRIPT
-- ============================================================================
-- This script sets up the complete database schema for TravelCompanion app
-- Safe to run on a fresh Supabase database (new project)
--
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================================
-- Created: April 2026
-- ============================================================================

-- ============================================================================
-- SECTION 1: ENABLE REQUIRED EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- SECTION 2: CREATE CUSTOM ENUM TYPES
-- ============================================================================

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('user', 'admin', 'super_admin');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('active', 'suspended', 'pending');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE admin_action_type AS ENUM (
        'user_suspended', 'user_activated', 'role_changed',
        'trip_deleted', 'checklist_deleted', 'expense_deleted',
        'user_created', 'settings_changed'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE join_request_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- SECTION 3: CREATE CORE TABLES
-- ============================================================================

-- 3.1 PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email CITEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    phone TEXT,
    role user_role DEFAULT 'user',
    status user_status DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add columns if they don't exist (safe for existing tables)
DO $$ BEGIN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role user_role DEFAULT 'user';
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS status user_status DEFAULT 'active';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 3.2 TRIPS TABLE
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    destination TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    cover_image_url TEXT,
    cost DOUBLE PRECISION,
    currency TEXT DEFAULT 'INR',
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    rating DOUBLE PRECISION,
    is_public BOOLEAN DEFAULT false
);

-- 3.3 TRIP_MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.trip_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(trip_id, user_id)
);

-- 3.4 ITINERARY_ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.itinerary_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    place_id TEXT,
    day_number INTEGER NOT NULL,
    order_index INTEGER DEFAULT 0,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add location columns if missing
DO $$ BEGIN
    ALTER TABLE public.itinerary_items ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
    ALTER TABLE public.itinerary_items ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
    ALTER TABLE public.itinerary_items ADD COLUMN IF NOT EXISTS place_id TEXT;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 3.5 CHECKLISTS TABLE
CREATE TABLE IF NOT EXISTS public.checklists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.6 CHECKLIST_ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.checklist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    checklist_id UUID NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
    name TEXT,
    content TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    completed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.7 EXPENSES TABLE
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(12, 2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    category TEXT,
    paid_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    split_type TEXT DEFAULT 'equal',
    receipt_url TEXT,
    transaction_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.8 EXPENSE_SPLITS TABLE
CREATE TABLE IF NOT EXISTS public.expense_splits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    is_settled BOOLEAN DEFAULT false,
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.9 SETTLEMENTS TABLE
CREATE TABLE IF NOT EXISTS public.settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    from_user UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    to_user UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    is_settled BOOLEAN DEFAULT false,
    settled_at TIMESTAMPTZ,
    proof_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.10 MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    conversation_id UUID,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.11 TRIP_INVITES TABLE
CREATE TABLE IF NOT EXISTS public.trip_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    email CITEXT NOT NULL,
    invited_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- 3.12 USER_FCM_TOKENS TABLE
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_type TEXT,
    device_name TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- 3.13 ADMIN_ACTIVITY_LOG TABLE
CREATE TABLE IF NOT EXISTS public.admin_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action_type admin_action_type NOT NULL,
    target_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    target_resource_id UUID,
    target_resource_type TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.14 HOSPITALS TABLE (for emergency services)
CREATE TABLE IF NOT EXISTS public.hospitals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(Point, 4326),
    hospital_type TEXT DEFAULT 'general',
    is_24x7 BOOLEAN DEFAULT false,
    has_emergency BOOLEAN DEFAULT true,
    rating DECIMAL(2, 1),
    google_place_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.15 CONVERSATIONS TABLE
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_direct_message BOOLEAN DEFAULT false,
    is_default_group BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add is_default_group if missing
DO $$ BEGIN
    ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS is_default_group BOOLEAN DEFAULT false;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Add foreign key to messages for conversation_id
DO $$ BEGIN
    ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 3.16 CONVERSATION_MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.conversation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_muted BOOLEAN DEFAULT false,
    last_read_at TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);

-- 3.17 TRIP_JOIN_REQUESTS TABLE
CREATE TABLE IF NOT EXISTS public.trip_join_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT,
    status join_request_status DEFAULT 'pending',
    responded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(trip_id, user_id)
);

-- 3.18 TRIP_TEMPLATES TABLE
CREATE TABLE IF NOT EXISTS public.trip_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    destination TEXT NOT NULL,
    destination_state TEXT,
    duration_days INTEGER NOT NULL DEFAULT 1,
    budget_min DOUBLE PRECISION,
    budget_max DOUBLE PRECISION,
    currency TEXT NOT NULL DEFAULT 'INR',
    category TEXT NOT NULL DEFAULT 'adventure',
    tags TEXT[] DEFAULT '{}',
    best_season TEXT[] DEFAULT '{}',
    difficulty_level TEXT NOT NULL DEFAULT 'easy',
    cover_image_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_featured BOOLEAN NOT NULL DEFAULT false,
    use_count INTEGER NOT NULL DEFAULT 0,
    rating DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.19 TEMPLATE_ITINERARY_ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.template_itinerary_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES public.trip_templates(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    location_url TEXT,
    start_time TEXT,
    end_time TEXT,
    duration_minutes INTEGER,
    category TEXT NOT NULL DEFAULT 'activity',
    estimated_cost DOUBLE PRECISION,
    tips TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.20 TEMPLATE_CHECKLISTS TABLE
CREATE TABLE IF NOT EXISTS public.template_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES public.trip_templates(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.21 TEMPLATE_CHECKLIST_ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.template_checklist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checklist_id UUID NOT NULL REFERENCES public.template_checklists(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    is_essential BOOLEAN NOT NULL DEFAULT false,
    category TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.22 AI_USAGE_TRACKING TABLE
CREATE TABLE IF NOT EXISTS public.ai_usage_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    feature TEXT NOT NULL DEFAULT 'itinerary_generation',
    usage_count INTEGER NOT NULL DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    monthly_limit INTEGER NOT NULL DEFAULT 5,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    premium_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, feature)
);

-- 3.23 AI_GENERATION_LOGS TABLE
CREATE TABLE IF NOT EXISTS public.ai_generation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    feature TEXT NOT NULL DEFAULT 'itinerary_generation',
    request_data JSONB,
    response_summary TEXT,
    tokens_used INTEGER,
    generation_time_ms INTEGER,
    was_successful BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.24 PLACE_CACHE TABLE
CREATE TABLE IF NOT EXISTS public.place_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    formatted_address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    city TEXT,
    state TEXT,
    country TEXT,
    country_code TEXT,
    types TEXT[] DEFAULT ARRAY[]::TEXT[],
    photo_references TEXT[] DEFAULT ARRAY[]::TEXT[],
    website TEXT,
    google_maps_url TEXT,
    rating DECIMAL(2,1),
    user_ratings_total INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    access_count INTEGER DEFAULT 1
);

-- 3.25 TRIP_FAVORITES TABLE
CREATE TABLE IF NOT EXISTS public.trip_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, trip_id)
);

-- 3.26 DISCOVER_FAVORITES TABLE
CREATE TABLE IF NOT EXISTS public.discover_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    place_id TEXT NOT NULL,
    place_name TEXT NOT NULL,
    place_category TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, place_id)
);

-- ============================================================================
-- SECTION 4: CREATE INDEXES
-- ============================================================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- Trips indexes
CREATE INDEX IF NOT EXISTS idx_trips_created_by ON public.trips(created_by);
CREATE INDEX IF NOT EXISTS idx_trips_start_date ON public.trips(start_date);
CREATE INDEX IF NOT EXISTS idx_trips_is_public ON public.trips(is_public);
CREATE INDEX IF NOT EXISTS idx_trips_destination ON public.trips(destination);

-- Trip members indexes
CREATE INDEX IF NOT EXISTS idx_trip_members_trip_id ON public.trip_members(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_members_user_id ON public.trip_members(user_id);

-- Itinerary indexes
CREATE INDEX IF NOT EXISTS idx_itinerary_items_trip_id ON public.itinerary_items(trip_id);
CREATE INDEX IF NOT EXISTS idx_itinerary_items_location ON public.itinerary_items(latitude, longitude)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Checklists indexes
CREATE INDEX IF NOT EXISTS idx_checklists_trip_id ON public.checklists(trip_id);
CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id ON public.checklist_items(checklist_id);

-- Expenses indexes
CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON public.expenses(trip_id);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON public.expenses(paid_by);
CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON public.expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user_id ON public.expense_splits(user_id);

-- Settlements indexes
CREATE INDEX IF NOT EXISTS idx_settlements_trip_id ON public.settlements(trip_id);
CREATE INDEX IF NOT EXISTS idx_settlements_from_user ON public.settlements(from_user);
CREATE INDEX IF NOT EXISTS idx_settlements_to_user ON public.settlements(to_user);

-- Messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_trip_id ON public.messages(trip_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC)
WHERE conversation_id IS NOT NULL;

-- Trip invites indexes
CREATE INDEX IF NOT EXISTS idx_trip_invites_trip_id ON public.trip_invites(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_invites_email ON public.trip_invites(email);

-- FCM tokens indexes
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON public.user_fcm_tokens(user_id, is_active) WHERE is_active = true;

-- Admin activity log indexes
CREATE INDEX IF NOT EXISTS idx_admin_activity_admin_id ON public.admin_activity_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_target_user ON public.admin_activity_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_created_at ON public.admin_activity_log(created_at DESC);

-- Hospitals indexes
CREATE INDEX IF NOT EXISTS idx_hospitals_location ON public.hospitals USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_hospitals_type ON public.hospitals(hospital_type);

-- Conversations indexes
CREATE INDEX IF NOT EXISTS idx_conversations_trip ON public.conversations(trip_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_default_group ON public.conversations(trip_id) WHERE is_default_group = true;

-- Conversation members indexes
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_user ON public.conversation_members(user_id);

-- Trip join requests indexes
CREATE INDEX IF NOT EXISTS idx_trip_join_requests_trip ON public.trip_join_requests(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_join_requests_user ON public.trip_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_join_requests_status ON public.trip_join_requests(status);

-- Trip templates indexes
CREATE INDEX IF NOT EXISTS idx_trip_templates_category ON public.trip_templates(category);
CREATE INDEX IF NOT EXISTS idx_trip_templates_is_active ON public.trip_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_trip_templates_is_featured ON public.trip_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_trip_templates_destination ON public.trip_templates(destination);

-- Template items indexes
CREATE INDEX IF NOT EXISTS idx_template_itinerary_template_id ON public.template_itinerary_items(template_id);
CREATE INDEX IF NOT EXISTS idx_template_itinerary_day ON public.template_itinerary_items(template_id, day_number);
CREATE INDEX IF NOT EXISTS idx_template_checklists_template_id ON public.template_checklists(template_id);
CREATE INDEX IF NOT EXISTS idx_template_checklist_items_checklist_id ON public.template_checklist_items(checklist_id);

-- AI usage indexes
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON public.ai_usage_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_logs_user_id ON public.ai_generation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_logs_created_at ON public.ai_generation_logs(created_at);

-- Place cache indexes
CREATE INDEX IF NOT EXISTS idx_place_cache_place_id ON public.place_cache(place_id);
CREATE INDEX IF NOT EXISTS idx_place_cache_city ON public.place_cache(city);
CREATE INDEX IF NOT EXISTS idx_place_cache_country ON public.place_cache(country);
CREATE INDEX IF NOT EXISTS idx_place_cache_last_accessed ON public.place_cache(last_accessed_at);
CREATE INDEX IF NOT EXISTS idx_place_cache_types ON public.place_cache USING GIN(types);

-- Trip favorites indexes
CREATE INDEX IF NOT EXISTS idx_trip_favorites_user_id ON public.trip_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_favorites_trip_id ON public.trip_favorites(trip_id);

-- Discover favorites indexes
CREATE INDEX IF NOT EXISTS idx_discover_favorites_user_id ON public.discover_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_discover_favorites_place_id ON public.discover_favorites(place_id);

-- ============================================================================
-- SECTION 5: ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_generation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.place_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discover_favorites ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SECTION 6: CREATE RLS POLICIES
-- ============================================================================

-- ============================================================================
-- 6.1 PROFILES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view all profiles" ON public.profiles;
CREATE POLICY "Users can view all profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- ============================================================================
-- 6.2 TRIPS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own trips" ON public.trips;
CREATE POLICY "Users can view own trips"
ON public.trips FOR SELECT
USING (
    created_by = auth.uid()
    OR is_public = true
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = trips.id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can create trips" ON public.trips;
CREATE POLICY "Users can create trips"
ON public.trips FOR INSERT
WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Trip owners can update trips" ON public.trips;
CREATE POLICY "Trip owners can update trips"
ON public.trips FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Trip owners can delete trips" ON public.trips;
CREATE POLICY "Trip owners can delete trips"
ON public.trips FOR DELETE
USING (created_by = auth.uid());

-- ============================================================================
-- 6.3 TRIP_MEMBERS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view members" ON public.trip_members;
CREATE POLICY "Trip members can view members"
ON public.trip_members FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.trip_members tm
        WHERE tm.trip_id = trip_members.trip_id
        AND tm.user_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = trip_members.trip_id
        AND trips.created_by = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip owners can manage members" ON public.trip_members;
CREATE POLICY "Trip owners can manage members"
ON public.trip_members FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = trip_members.trip_id
        AND trips.created_by = auth.uid()
    )
);

-- ============================================================================
-- 6.4 ITINERARY POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view itinerary" ON public.itinerary_items;
CREATE POLICY "Trip members can view itinerary"
ON public.itinerary_items FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = itinerary_items.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can insert itinerary" ON public.itinerary_items;
CREATE POLICY "Trip members can insert itinerary"
ON public.itinerary_items FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = itinerary_items.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip owners and admins can update itinerary" ON public.itinerary_items;
CREATE POLICY "Trip owners and admins can update itinerary"
ON public.itinerary_items FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = itinerary_items.trip_id
        AND trips.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = itinerary_items.trip_id
        AND trip_members.user_id = auth.uid()
        AND trip_members.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Trip owners and admins can delete itinerary" ON public.itinerary_items;
CREATE POLICY "Trip owners and admins can delete itinerary"
ON public.itinerary_items FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = itinerary_items.trip_id
        AND trips.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = itinerary_items.trip_id
        AND trip_members.user_id = auth.uid()
        AND trip_members.role = 'admin'
    )
);

-- ============================================================================
-- 6.5 CHECKLISTS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view checklists" ON public.checklists;
CREATE POLICY "Trip members can view checklists"
ON public.checklists FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = checklists.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can insert checklists" ON public.checklists;
CREATE POLICY "Trip members can insert checklists"
ON public.checklists FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = checklists.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip owners and admins can update checklists" ON public.checklists;
CREATE POLICY "Trip owners and admins can update checklists"
ON public.checklists FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = checklists.trip_id
        AND trips.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = checklists.trip_id
        AND trip_members.user_id = auth.uid()
        AND trip_members.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Trip owners and admins can delete checklists" ON public.checklists;
CREATE POLICY "Trip owners and admins can delete checklists"
ON public.checklists FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = checklists.trip_id
        AND trips.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = checklists.trip_id
        AND trip_members.user_id = auth.uid()
        AND trip_members.role = 'admin'
    )
);

-- ============================================================================
-- 6.6 CHECKLIST_ITEMS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view checklist items" ON public.checklist_items;
CREATE POLICY "Trip members can view checklist items"
ON public.checklist_items FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.checklists c
        JOIN public.trip_members tm ON tm.trip_id = c.trip_id
        WHERE c.id = checklist_items.checklist_id
        AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can insert checklist items" ON public.checklist_items;
CREATE POLICY "Trip members can insert checklist items"
ON public.checklist_items FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.checklists c
        JOIN public.trip_members tm ON tm.trip_id = c.trip_id
        WHERE c.id = checklist_items.checklist_id
        AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can update checklist items" ON public.checklist_items;
CREATE POLICY "Trip members can update checklist items"
ON public.checklist_items FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.checklists c
        JOIN public.trip_members tm ON tm.trip_id = c.trip_id
        WHERE c.id = checklist_items.checklist_id
        AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip owners and admins can delete checklist items" ON public.checklist_items;
CREATE POLICY "Trip owners and admins can delete checklist items"
ON public.checklist_items FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.checklists c
        JOIN public.trips t ON t.id = c.trip_id
        WHERE c.id = checklist_items.checklist_id
        AND t.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.checklists c
        JOIN public.trip_members tm ON tm.trip_id = c.trip_id
        WHERE c.id = checklist_items.checklist_id
        AND tm.user_id = auth.uid()
        AND tm.role = 'admin'
    )
);

-- ============================================================================
-- 6.7 EXPENSES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view expenses" ON public.expenses;
CREATE POLICY "Trip members can view expenses"
ON public.expenses FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can insert expenses" ON public.expenses;
CREATE POLICY "Trip members can insert expenses"
ON public.expenses FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Expense owners and trip admins can update expenses" ON public.expenses;
CREATE POLICY "Expense owners and trip admins can update expenses"
ON public.expenses FOR UPDATE
USING (
    paid_by = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = expenses.trip_id
        AND trips.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
        AND trip_members.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Expense owners and trip admins can delete expenses" ON public.expenses;
CREATE POLICY "Expense owners and trip admins can delete expenses"
ON public.expenses FOR DELETE
USING (
    paid_by = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = expenses.trip_id
        AND trips.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
        AND trip_members.role = 'admin'
    )
);

-- ============================================================================
-- 6.8 EXPENSE_SPLITS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view expense splits" ON public.expense_splits;
CREATE POLICY "Trip members can view expense splits"
ON public.expense_splits FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.expenses e
        JOIN public.trip_members tm ON tm.trip_id = e.trip_id
        WHERE e.id = expense_splits.expense_id
        AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can insert expense splits" ON public.expense_splits;
CREATE POLICY "Trip members can insert expense splits"
ON public.expense_splits FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.expenses e
        JOIN public.trip_members tm ON tm.trip_id = e.trip_id
        WHERE e.id = expense_splits.expense_id
        AND tm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Expense owners can update splits" ON public.expense_splits;
CREATE POLICY "Expense owners can update splits"
ON public.expense_splits FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.expenses e
        WHERE e.id = expense_splits.expense_id
        AND e.paid_by = auth.uid()
    )
);

DROP POLICY IF EXISTS "Expense owners can delete splits" ON public.expense_splits;
CREATE POLICY "Expense owners can delete splits"
ON public.expense_splits FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.expenses e
        WHERE e.id = expense_splits.expense_id
        AND e.paid_by = auth.uid()
    )
);

-- ============================================================================
-- 6.9 MESSAGES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Trip members can view messages" ON public.messages;
CREATE POLICY "Trip members can view messages"
ON public.messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = messages.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Trip members can insert messages" ON public.messages;
CREATE POLICY "Trip members can insert messages"
ON public.messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = messages.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update own messages" ON public.messages;
CREATE POLICY "Users can update own messages"
ON public.messages FOR UPDATE
USING (sender_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own messages" ON public.messages;
CREATE POLICY "Users can delete own messages"
ON public.messages FOR DELETE
USING (sender_id = auth.uid());

-- ============================================================================
-- 6.10 CONVERSATIONS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view conversations they are members of" ON public.conversations;
CREATE POLICY "Users can view conversations they are members of"
ON public.conversations FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
    )
    OR created_by = auth.uid()
);

DROP POLICY IF EXISTS "Trip members can create conversations" ON public.conversations;
CREATE POLICY "Trip members can create conversations"
ON public.conversations FOR INSERT
TO authenticated
WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.trip_members
        WHERE trip_members.trip_id = conversations.trip_id
        AND trip_members.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Conversation admins can update conversations" ON public.conversations;
CREATE POLICY "Conversation admins can update conversations"
ON public.conversations FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
    OR created_by = auth.uid()
);

DROP POLICY IF EXISTS "Conversation admins can delete conversations" ON public.conversations;
CREATE POLICY "Conversation admins can delete conversations"
ON public.conversations FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members
        WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.role = 'admin'
    )
    OR created_by = auth.uid()
);

-- ============================================================================
-- 6.11 CONVERSATION_MEMBERS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view conversation members" ON public.conversation_members;
CREATE POLICY "Users can view conversation members"
ON public.conversation_members FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Conversation admins can add members" ON public.conversation_members;
CREATE POLICY "Conversation admins can add members"
ON public.conversation_members FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_members.conversation_id
        AND c.created_by = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.role = 'admin'
    )
    OR (
        conversation_members.user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.conversations c
            JOIN public.trip_members tm ON tm.trip_id = c.trip_id
            WHERE c.id = conversation_members.conversation_id
            AND tm.user_id = auth.uid()
        )
    )
);

DROP POLICY IF EXISTS "Users can update their own membership" ON public.conversation_members;
CREATE POLICY "Users can update their own membership"
ON public.conversation_members FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_members;
CREATE POLICY "Users can leave conversations"
ON public.conversation_members FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================================================
-- 6.12 FCM TOKENS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can manage own FCM tokens"
ON public.user_fcm_tokens FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 6.13 HOSPITALS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view hospitals" ON public.hospitals;
CREATE POLICY "Anyone can view hospitals"
ON public.hospitals FOR SELECT
TO authenticated
USING (true);

-- ============================================================================
-- 6.14 TRIP JOIN REQUESTS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view join requests for their trips" ON public.trip_join_requests;
CREATE POLICY "Users can view join requests for their trips"
ON public.trip_join_requests FOR SELECT
USING (
    user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = trip_join_requests.trip_id
        AND trips.created_by = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can create join requests" ON public.trip_join_requests;
CREATE POLICY "Users can create join requests"
ON public.trip_join_requests FOR INSERT
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Trip owners can update join requests" ON public.trip_join_requests;
CREATE POLICY "Trip owners can update join requests"
ON public.trip_join_requests FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.trips
        WHERE trips.id = trip_join_requests.trip_id
        AND trips.created_by = auth.uid()
    )
);

-- ============================================================================
-- 6.15 TRIP TEMPLATES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can read active templates" ON public.trip_templates;
CREATE POLICY "Anyone can read active templates"
ON public.trip_templates FOR SELECT
USING (is_active = true);

DROP POLICY IF EXISTS "Anyone can read template itinerary items" ON public.template_itinerary_items;
CREATE POLICY "Anyone can read template itinerary items"
ON public.template_itinerary_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.trip_templates t
    WHERE t.id = template_id AND t.is_active = true
));

DROP POLICY IF EXISTS "Anyone can read template checklists" ON public.template_checklists;
CREATE POLICY "Anyone can read template checklists"
ON public.template_checklists FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.trip_templates t
    WHERE t.id = template_id AND t.is_active = true
));

DROP POLICY IF EXISTS "Anyone can read template checklist items" ON public.template_checklist_items;
CREATE POLICY "Anyone can read template checklist items"
ON public.template_checklist_items FOR SELECT
USING (EXISTS (
    SELECT 1 FROM public.template_checklists c
    JOIN public.trip_templates t ON t.id = c.template_id
    WHERE c.id = checklist_id AND t.is_active = true
));

-- ============================================================================
-- 6.16 AI USAGE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can read own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can read own AI usage"
ON public.ai_usage_tracking FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can insert own AI usage"
ON public.ai_usage_tracking FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own AI usage" ON public.ai_usage_tracking;
CREATE POLICY "Users can update own AI usage"
ON public.ai_usage_tracking FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can read own AI logs" ON public.ai_generation_logs;
CREATE POLICY "Users can read own AI logs"
ON public.ai_generation_logs FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own AI logs" ON public.ai_generation_logs;
CREATE POLICY "Users can insert own AI logs"
ON public.ai_generation_logs FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 6.17 PLACE CACHE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Authenticated users can read place cache" ON public.place_cache;
CREATE POLICY "Authenticated users can read place cache"
ON public.place_cache FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert place cache" ON public.place_cache;
CREATE POLICY "Authenticated users can insert place cache"
ON public.place_cache FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update place cache" ON public.place_cache;
CREATE POLICY "Authenticated users can update place cache"
ON public.place_cache FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- ============================================================================
-- 6.18 FAVORITES POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own favorites" ON public.trip_favorites;
CREATE POLICY "Users can view own favorites"
ON public.trip_favorites FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can add own favorites" ON public.trip_favorites;
CREATE POLICY "Users can add own favorites"
ON public.trip_favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove own favorites" ON public.trip_favorites;
CREATE POLICY "Users can remove own favorites"
ON public.trip_favorites FOR DELETE
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own discover favorites" ON public.discover_favorites;
CREATE POLICY "Users can view own discover favorites"
ON public.discover_favorites FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can add own discover favorites" ON public.discover_favorites;
CREATE POLICY "Users can add own discover favorites"
ON public.discover_favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove own discover favorites" ON public.discover_favorites;
CREATE POLICY "Users can remove own discover favorites"
ON public.discover_favorites FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- SECTION 7: CREATE UTILITY FUNCTIONS
-- ============================================================================

-- 7.1 Updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7.2 Hospital location trigger function
CREATE OR REPLACE FUNCTION public.update_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::GEOGRAPHY;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 8: CREATE TRIGGERS
-- ============================================================================

-- Updated_at triggers
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_trips_updated_at ON public.trips;
CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON public.trips
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_itinerary_items_updated_at ON public.itinerary_items;
CREATE TRIGGER update_itinerary_items_updated_at
    BEFORE UPDATE ON public.itinerary_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_checklists_updated_at ON public.checklists;
CREATE TRIGGER update_checklists_updated_at
    BEFORE UPDATE ON public.checklists
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_checklist_items_updated_at ON public.checklist_items;
CREATE TRIGGER update_checklist_items_updated_at
    BEFORE UPDATE ON public.checklist_items
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_expenses_updated_at ON public.expenses;
CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_updated_at ON public.messages;
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_fcm_tokens_updated_at ON public.user_fcm_tokens;
CREATE TRIGGER update_user_fcm_tokens_updated_at
    BEFORE UPDATE ON public.user_fcm_tokens
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_hospitals_updated_at ON public.hospitals;
CREATE TRIGGER update_hospitals_updated_at
    BEFORE UPDATE ON public.hospitals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_conversations_updated_at ON public.conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_trip_join_requests_updated_at ON public.trip_join_requests;
CREATE TRIGGER update_trip_join_requests_updated_at
    BEFORE UPDATE ON public.trip_join_requests
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_trip_templates_updated_at ON public.trip_templates;
CREATE TRIGGER update_trip_templates_updated_at
    BEFORE UPDATE ON public.trip_templates
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_ai_usage_updated_at ON public.ai_usage_tracking;
CREATE TRIGGER update_ai_usage_updated_at
    BEFORE UPDATE ON public.ai_usage_tracking
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Hospital location trigger
DROP TRIGGER IF EXISTS update_hospital_location_trigger ON public.hospitals;
CREATE TRIGGER update_hospital_location_trigger
    BEFORE INSERT OR UPDATE OF latitude, longitude ON public.hospitals
    FOR EACH ROW EXECUTE FUNCTION public.update_hospital_location();

-- ============================================================================
-- SECTION 9: CREATE BUSINESS FUNCTIONS
-- ============================================================================

-- 9.1 Find nearby hospitals
CREATE OR REPLACE FUNCTION public.find_nearby_hospitals(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters INTEGER DEFAULT 10000,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    address TEXT,
    phone TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    hospital_type TEXT,
    is_24x7 BOOLEAN,
    has_emergency BOOLEAN,
    rating DECIMAL,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.address,
        h.phone,
        h.latitude,
        h.longitude,
        h.hospital_type,
        h.is_24x7,
        h.has_emergency,
        h.rating,
        ST_Distance(
            h.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::GEOGRAPHY
        ) as distance_meters
    FROM public.hospitals h
    WHERE ST_DWithin(
        h.location,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::GEOGRAPHY,
        p_radius_meters
    )
    ORDER BY distance_meters
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- 9.2 Get trip conversations
CREATE OR REPLACE FUNCTION get_trip_conversations(p_trip_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    is_default_group BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        COALESCE(c.is_default_group, false) as is_default_group,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm2.last_read_at FROM public.conversation_members cm2
              WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user_id),
             (SELECT cm3.joined_at FROM public.conversation_members cm3
              WHERE cm3.conversation_id = c.id AND cm3.user_id = p_user_id),
             c.created_at
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.full_name FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_name,
        CASE
            WHEN c.is_direct_message THEN
                (SELECT pr.avatar_url FROM public.conversation_members cmem
                 JOIN public.profiles pr ON cmem.user_id = pr.id
                 WHERE cmem.conversation_id = c.id AND cmem.user_id != p_user_id
                 LIMIT 1)
            ELSE NULL
        END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id
    )
    ORDER BY
        COALESCE(c.is_default_group, false) DESC,
        last_message_at DESC NULLS LAST,
        c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.3 Get conversation with details
CREATE OR REPLACE FUNCTION get_conversation_with_details(p_conversation_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    name VARCHAR(100),
    description TEXT,
    avatar_url TEXT,
    created_by UUID,
    is_direct_message BOOLEAN,
    is_default_group BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_sender_name TEXT,
    unread_count BIGINT,
    member_count BIGINT,
    dm_other_member_name TEXT,
    dm_other_member_avatar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.trip_id,
        c.name,
        c.description,
        c.avatar_url,
        c.created_by,
        c.is_direct_message,
        COALESCE(c.is_default_group, false) as is_default_group,
        c.created_at,
        c.updated_at,
        (SELECT m.message FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_text,
        (SELECT m.created_at FROM public.messages m
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
        (SELECT p.full_name FROM public.messages m
         JOIN public.profiles p ON m.sender_id = p.id
         WHERE m.conversation_id = c.id AND m.is_deleted = false
         ORDER BY m.created_at DESC LIMIT 1) as last_message_sender_name,
        (SELECT COUNT(*) FROM public.messages m
         WHERE m.conversation_id = c.id
         AND m.is_deleted = false
         AND m.created_at > COALESCE(
             (SELECT cm.last_read_at FROM public.conversation_members cm
              WHERE cm.conversation_id = c.id AND cm.user_id = p_user_id),
             '1970-01-01'::timestamptz
         )
         AND m.sender_id != p_user_id) as unread_count,
        (SELECT COUNT(*) FROM public.conversation_members cm
         WHERE cm.conversation_id = c.id) as member_count,
        CASE WHEN c.is_direct_message THEN
            (SELECT p.full_name FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_name,
        CASE WHEN c.is_direct_message THEN
            (SELECT p.avatar_url FROM public.conversation_members cm
             JOIN public.profiles p ON cm.user_id = p.id
             WHERE cm.conversation_id = c.id AND cm.user_id != p_user_id
             LIMIT 1)
        ELSE NULL END as dm_other_member_avatar
    FROM public.conversations c
    WHERE c.id = p_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.4 Find existing DM
CREATE OR REPLACE FUNCTION find_existing_dm(
    p_trip_id UUID,
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    WHERE c.trip_id = p_trip_id
    AND c.is_direct_message = true
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm1
        WHERE cm1.conversation_id = c.id AND cm1.user_id = p_user1_id
    )
    AND EXISTS (
        SELECT 1 FROM public.conversation_members cm2
        WHERE cm2.conversation_id = c.id AND cm2.user_id = p_user2_id
    )
    AND (
        SELECT COUNT(*) FROM public.conversation_members cm
        WHERE cm.conversation_id = c.id
    ) = 2
    LIMIT 1;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.5 Mark conversation as read
CREATE OR REPLACE FUNCTION mark_conversation_as_read(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.conversation_members
    SET last_read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.6 Create trip default group
CREATE OR REPLACE FUNCTION create_trip_default_group(
    p_trip_id UUID,
    p_trip_name TEXT,
    p_created_by UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    INSERT INTO public.conversations (
        trip_id,
        name,
        description,
        created_by,
        is_direct_message,
        is_default_group
    ) VALUES (
        p_trip_id,
        'All Members',
        'Everyone in ' || COALESCE(p_trip_name, 'this trip') || '. Share updates, plans, and announcements here!',
        p_created_by,
        false,
        true
    )
    RETURNING id INTO v_conversation_id;

    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role
    ) VALUES (
        v_conversation_id,
        p_created_by,
        'admin'
    );

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.7 Ensure trip default group
CREATE OR REPLACE FUNCTION ensure_trip_default_group(p_trip_id UUID)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_trip RECORD;
BEGIN
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        SELECT id, name, created_by INTO v_trip
        FROM public.trips
        WHERE id = p_trip_id;

        IF v_trip.id IS NULL THEN
            RETURN NULL;
        END IF;

        v_conversation_id := create_trip_default_group(
            p_trip_id,
            v_trip.name,
            v_trip.created_by
        );
    END IF;

    INSERT INTO public.conversation_members (conversation_id, user_id, role, last_read_at)
    SELECT
        v_conversation_id,
        tm.user_id,
        CASE WHEN tm.role = 'owner' THEN 'admin' ELSE 'member' END,
        NULL
    FROM public.trip_members tm
    WHERE tm.trip_id = p_trip_id
    AND NOT EXISTS (
        SELECT 1 FROM public.conversation_members cm
        WHERE cm.conversation_id = v_conversation_id
        AND cm.user_id = tm.user_id
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.8 Ensure user in default group
CREATE OR REPLACE FUNCTION ensure_user_in_default_group(
    p_trip_id UUID,
    p_user_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_conversation_id UUID;
    v_is_trip_member BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM public.trip_members
        WHERE trip_id = p_trip_id AND user_id = p_user_id
    ) INTO v_is_trip_member;

    IF NOT v_is_trip_member THEN
        RETURN NULL;
    END IF;

    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE trip_id = p_trip_id
    AND is_default_group = true
    LIMIT 1;

    IF v_conversation_id IS NULL THEN
        v_conversation_id := ensure_trip_default_group(p_trip_id);
    END IF;

    IF v_conversation_id IS NULL THEN
        RETURN NULL;
    END IF;

    INSERT INTO public.conversation_members (
        conversation_id,
        user_id,
        role,
        last_read_at
    ) VALUES (
        v_conversation_id,
        p_user_id,
        'member',
        NULL
    )
    ON CONFLICT (conversation_id, user_id) DO NOTHING;

    RETURN v_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.9 Trip triggers for default group
CREATE OR REPLACE FUNCTION on_trip_created()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM create_trip_default_group(
        NEW.id,
        NEW.name,
        NEW.created_by
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trip_created_create_default_group ON public.trips;
CREATE TRIGGER trip_created_create_default_group
    AFTER INSERT ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_created();

CREATE OR REPLACE FUNCTION on_trip_member_added()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = NEW.trip_id
    AND is_default_group = true
    LIMIT 1;

    IF v_default_conversation_id IS NOT NULL THEN
        INSERT INTO public.conversation_members (
            conversation_id,
            user_id,
            role,
            last_read_at
        ) VALUES (
            v_default_conversation_id,
            NEW.user_id,
            'member',
            NULL
        )
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trip_member_added_join_default_group ON public.trip_members;
CREATE TRIGGER trip_member_added_join_default_group
    AFTER INSERT ON public.trip_members
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_member_added();

CREATE OR REPLACE FUNCTION on_trip_member_removed()
RETURNS TRIGGER AS $$
DECLARE
    v_default_conversation_id UUID;
BEGIN
    SELECT id INTO v_default_conversation_id
    FROM public.conversations
    WHERE trip_id = OLD.trip_id
    AND is_default_group = true
    LIMIT 1;

    IF v_default_conversation_id IS NOT NULL THEN
        DELETE FROM public.conversation_members
        WHERE conversation_id = v_default_conversation_id
        AND user_id = OLD.user_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trip_member_removed_leave_default_group ON public.trip_members;
CREATE TRIGGER trip_member_removed_leave_default_group
    AFTER DELETE ON public.trip_members
    FOR EACH ROW
    EXECUTE FUNCTION on_trip_member_removed();

-- 9.10 AI Usage functions
CREATE OR REPLACE FUNCTION public.get_or_create_ai_usage(p_user_id UUID, p_feature TEXT DEFAULT 'itinerary_generation')
RETURNS public.ai_usage_tracking
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  SELECT * INTO v_usage
  FROM public.ai_usage_tracking
  WHERE user_id = p_user_id AND feature = p_feature;

  IF v_usage IS NULL THEN
    INSERT INTO public.ai_usage_tracking (user_id, feature, usage_count, monthly_limit)
    VALUES (p_user_id, p_feature, 0, 5)
    RETURNING * INTO v_usage;
  END IF;

  RETURN v_usage;
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_ai_usage(p_user_id UUID, p_feature TEXT DEFAULT 'itinerary_generation')
RETURNS TABLE (
  can_use BOOLEAN,
  current_count INTEGER,
  monthly_limit INTEGER,
  is_premium BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
  v_can_use BOOLEAN;
BEGIN
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, p_feature);

  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    v_usage.usage_count := 0;
  END IF;

  v_can_use := v_usage.is_premium OR (v_usage.usage_count < v_usage.monthly_limit);

  IF v_can_use THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = usage_count + 1,
        last_used_at = NOW(),
        updated_at = NOW()
    WHERE id = v_usage.id
    RETURNING usage_count INTO v_usage.usage_count;
  END IF;

  RETURN QUERY SELECT v_can_use, v_usage.usage_count, v_usage.monthly_limit, v_usage.is_premium;
END;
$$;

CREATE OR REPLACE FUNCTION public.can_generate_ai_itinerary(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, 'itinerary_generation');

  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    RETURN true;
  END IF;

  IF v_usage.is_premium THEN
    RETURN true;
  END IF;

  RETURN v_usage.usage_count < v_usage.monthly_limit;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_remaining_ai_generations(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usage public.ai_usage_tracking;
BEGIN
  SELECT * INTO v_usage FROM public.get_or_create_ai_usage(p_user_id, 'itinerary_generation');

  IF v_usage.last_used_at IS NOT NULL AND
     date_trunc('month', v_usage.last_used_at) < date_trunc('month', NOW()) THEN
    UPDATE public.ai_usage_tracking
    SET usage_count = 0
    WHERE id = v_usage.id;
    v_usage.usage_count := 0;
  END IF;

  IF v_usage.is_premium THEN
    RETURN -1;
  END IF;

  RETURN GREATEST(0, v_usage.monthly_limit - v_usage.usage_count);
END;
$$;

-- 9.11 Template use count
CREATE OR REPLACE FUNCTION public.increment_template_use_count(p_template_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.trip_templates
  SET use_count = use_count + 1,
      updated_at = NOW()
  WHERE id = p_template_id;
END;
$$;

-- 9.12 Place cache functions
CREATE OR REPLACE FUNCTION upsert_place_cache(
    p_place_id TEXT,
    p_name TEXT,
    p_formatted_address TEXT DEFAULT NULL,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state TEXT DEFAULT NULL,
    p_country TEXT DEFAULT NULL,
    p_country_code TEXT DEFAULT NULL,
    p_types TEXT[] DEFAULT NULL,
    p_photo_references TEXT[] DEFAULT NULL,
    p_website TEXT DEFAULT NULL,
    p_google_maps_url TEXT DEFAULT NULL,
    p_rating DECIMAL DEFAULT NULL,
    p_user_ratings_total INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO public.place_cache (
        place_id, name, formatted_address, latitude, longitude,
        city, state, country, country_code, types, photo_references,
        website, google_maps_url, rating, user_ratings_total
    )
    VALUES (
        p_place_id, p_name, p_formatted_address, p_latitude, p_longitude,
        p_city, p_state, p_country, p_country_code,
        COALESCE(p_types, ARRAY[]::TEXT[]),
        COALESCE(p_photo_references, ARRAY[]::TEXT[]),
        p_website, p_google_maps_url, p_rating, p_user_ratings_total
    )
    ON CONFLICT (place_id) DO UPDATE SET
        name = EXCLUDED.name,
        formatted_address = EXCLUDED.formatted_address,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        country = EXCLUDED.country,
        country_code = EXCLUDED.country_code,
        types = EXCLUDED.types,
        photo_references = EXCLUDED.photo_references,
        website = EXCLUDED.website,
        google_maps_url = EXCLUDED.google_maps_url,
        rating = EXCLUDED.rating,
        user_ratings_total = EXCLUDED.user_ratings_total,
        updated_at = NOW(),
        last_accessed_at = NOW(),
        access_count = place_cache.access_count + 1
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_place_from_cache(p_place_id TEXT)
RETURNS TABLE (
    id UUID,
    place_id TEXT,
    name TEXT,
    formatted_address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    city TEXT,
    state TEXT,
    country TEXT,
    country_code TEXT,
    types TEXT[],
    photo_references TEXT[],
    website TEXT,
    google_maps_url TEXT,
    rating DECIMAL,
    user_ratings_total INTEGER
) AS $$
BEGIN
    UPDATE public.place_cache
    SET
        last_accessed_at = NOW(),
        access_count = place_cache.access_count + 1
    WHERE place_cache.place_id = p_place_id;

    RETURN QUERY
    SELECT
        pc.id, pc.place_id, pc.name, pc.formatted_address,
        pc.latitude, pc.longitude, pc.city, pc.state,
        pc.country, pc.country_code, pc.types, pc.photo_references,
        pc.website, pc.google_maps_url, pc.rating, pc.user_ratings_total
    FROM public.place_cache pc
    WHERE pc.place_id = p_place_id;
END;
$$ LANGUAGE plpgsql;

-- 9.13 Favorites functions
CREATE OR REPLACE FUNCTION public.toggle_trip_favorite(p_trip_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.trip_favorites
    WHERE user_id = v_user_id AND trip_id = p_trip_id
  ) INTO v_exists;

  IF v_exists THEN
    DELETE FROM public.trip_favorites
    WHERE user_id = v_user_id AND trip_id = p_trip_id;
    RETURN FALSE;
  ELSE
    INSERT INTO public.trip_favorites (user_id, trip_id)
    VALUES (v_user_id, p_trip_id);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_favorite_trip_ids()
RETURNS TABLE(trip_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT tf.trip_id
  FROM public.trip_favorites tf
  WHERE tf.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.toggle_discover_favorite(
  p_place_id TEXT,
  p_place_name TEXT DEFAULT NULL,
  p_place_category TEXT DEFAULT NULL,
  p_latitude DOUBLE PRECISION DEFAULT NULL,
  p_longitude DOUBLE PRECISION DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.discover_favorites
    WHERE user_id = v_user_id AND place_id = p_place_id
  ) INTO v_exists;

  IF v_exists THEN
    DELETE FROM public.discover_favorites
    WHERE user_id = v_user_id AND place_id = p_place_id;
    RETURN FALSE;
  ELSE
    INSERT INTO public.discover_favorites (user_id, place_id, place_name, place_category, latitude, longitude)
    VALUES (v_user_id, p_place_id, COALESCE(p_place_name, 'Unknown Place'), p_place_category, p_latitude, p_longitude);
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_discover_favorite_ids()
RETURNS TABLE(place_id TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT df.place_id
  FROM public.discover_favorites df
  WHERE df.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_discover_favorites()
RETURNS TABLE(
  place_id TEXT,
  place_name TEXT,
  place_category TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    df.place_id, df.place_name, df.place_category,
    df.latitude, df.longitude, df.created_at
  FROM public.discover_favorites df
  WHERE df.user_id = auth.uid()
  ORDER BY df.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.14 Copy trip function
CREATE OR REPLACE FUNCTION public.copy_trip(
  p_source_trip_id UUID,
  p_new_name TEXT,
  p_new_start_date TIMESTAMPTZ,
  p_new_end_date TIMESTAMPTZ,
  p_copy_itinerary BOOLEAN DEFAULT true,
  p_copy_checklists BOOLEAN DEFAULT true
)
RETURNS UUID
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
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM trip_members
    WHERE trip_id = p_source_trip_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Access denied to source trip';
  END IF;

  SELECT * INTO v_source_trip FROM trips WHERE id = p_source_trip_id;
  IF v_source_trip IS NULL THEN
    RAISE EXCEPTION 'Source trip not found';
  END IF;

  INSERT INTO trips (
    name, description, destination, start_date, end_date,
    cover_image_url, cost, currency, is_public, created_by,
    is_completed, rating, completed_at
  ) VALUES (
    p_new_name, v_source_trip.description, v_source_trip.destination,
    p_new_start_date, p_new_end_date, v_source_trip.cover_image_url,
    v_source_trip.cost, v_source_trip.currency, v_source_trip.is_public,
    v_user_id, false, NULL, NULL
  ) RETURNING id INTO v_new_trip_id;

  INSERT INTO trip_members (trip_id, user_id, role)
  VALUES (v_new_trip_id, v_user_id, 'admin')
  ON CONFLICT (trip_id, user_id) DO UPDATE SET role = 'admin';

  IF p_copy_itinerary THEN
    INSERT INTO itinerary_items (
      trip_id, title, description, location, latitude, longitude,
      place_id, day_number, order_index, start_time, end_time
    )
    SELECT
      v_new_trip_id, title, description, location, latitude, longitude,
      place_id, day_number, order_index, NULL, NULL
    FROM itinerary_items
    WHERE trip_id = p_source_trip_id;
  END IF;

  IF p_copy_checklists THEN
    FOR v_checklist IN
      SELECT * FROM checklists WHERE trip_id = p_source_trip_id
    LOOP
      INSERT INTO checklists (trip_id, name, created_by)
      VALUES (v_new_trip_id, v_checklist.name, v_user_id)
      RETURNING id INTO v_new_checklist_id;

      INSERT INTO checklist_items (checklist_id, name, content, is_completed, order_index)
      SELECT v_new_checklist_id, name, content, false, order_index
      FROM checklist_items
      WHERE checklist_id = v_checklist.id;
    END LOOP;
  END IF;

  RETURN v_new_trip_id;
END;
$$;

-- 9.15 User delete trip function
CREATE OR REPLACE FUNCTION public.user_delete_trip(p_trip_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_trip_owner UUID;
BEGIN
  SELECT created_by INTO v_trip_owner
  FROM public.trips WHERE id = p_trip_id;

  IF v_trip_owner IS NULL THEN
    RAISE EXCEPTION 'Trip not found';
  END IF;

  IF v_trip_owner != auth.uid() THEN
    RAISE EXCEPTION 'Only the trip owner can delete this trip';
  END IF;

  DELETE FROM public.messages
  WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE trip_id = p_trip_id
  );

  DELETE FROM public.conversation_members
  WHERE conversation_id IN (
    SELECT id FROM public.conversations WHERE trip_id = p_trip_id
  );

  DELETE FROM public.conversations WHERE trip_id = p_trip_id;
  DELETE FROM public.trip_join_requests WHERE trip_id = p_trip_id;

  DELETE FROM public.expense_splits
  WHERE expense_id IN (
    SELECT id FROM public.expenses WHERE trip_id = p_trip_id
  );

  DELETE FROM public.expenses WHERE trip_id = p_trip_id;

  DELETE FROM public.checklist_items
  WHERE checklist_id IN (
    SELECT id FROM public.checklists WHERE trip_id = p_trip_id
  );

  DELETE FROM public.checklists WHERE trip_id = p_trip_id;
  DELETE FROM public.itinerary_items WHERE trip_id = p_trip_id;
  DELETE FROM public.trip_invites WHERE trip_id = p_trip_id;
  DELETE FROM public.trip_members WHERE trip_id = p_trip_id;
  DELETE FROM public.trips WHERE id = p_trip_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SECTION 10: GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION public.find_nearby_hospitals TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION find_existing_dm TO authenticated;
GRANT EXECUTE ON FUNCTION mark_conversation_as_read TO authenticated;
GRANT EXECUTE ON FUNCTION create_trip_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_trip_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_user_in_default_group TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_ai_usage TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_generate_ai_itinerary TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_remaining_ai_generations TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_template_use_count TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_place_cache TO authenticated;
GRANT EXECUTE ON FUNCTION get_place_from_cache TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_trip_favorite TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_favorite_trip_ids TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_discover_favorite TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_discover_favorite_ids TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_discover_favorites TO authenticated;
GRANT EXECUTE ON FUNCTION public.copy_trip TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_delete_trip TO authenticated;

-- ============================================================================
-- SECTION 11: STORAGE BUCKETS
-- ============================================================================
-- Note: Run these in separate SQL statements in Supabase Dashboard

-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES
--   ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
--   ('trip-covers', 'trip-covers', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
--   ('receipts', 'receipts', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/gif', 'application/pdf'])
-- ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
--
-- This script creates:
-- - 26 tables
-- - All necessary indexes
-- - RLS policies for all tables
-- - Utility functions and triggers
-- - Business logic functions
--
-- Next steps:
-- 1. Configure storage bucket policies in Supabase Dashboard
-- 2. Set up authentication providers
-- 3. Configure environment variables in your Flutter app
-- ============================================================================
