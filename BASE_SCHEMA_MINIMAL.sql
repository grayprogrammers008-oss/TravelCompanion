-- ============================================
-- MINIMAL BASE SCHEMA - Creates only tables
-- ============================================
-- Run this if BASE_SCHEMA.sql has policy conflicts
-- RLS policies will be added by COMBINED_MIGRATIONS.sql

-- ============================================
-- ENABLE REQUIRED EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;

-- ============================================
-- PROFILES TABLE (if doesn't exist)
-- ============================================
-- This table might already exist from Supabase Auth setup
DO $$ BEGIN
    CREATE TABLE IF NOT EXISTS public.profiles (
        id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
        email CITEXT UNIQUE NOT NULL,
        full_name TEXT,
        avatar_url TEXT,
        bio TEXT,
        phone TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;

-- Add columns if they don't exist (in case table was created with fewer columns)
DO $$ BEGIN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Enable RLS (safe to run multiple times)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TRIPS TABLE
-- ============================================
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

ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_trips_created_by ON public.trips(created_by);
CREATE INDEX IF NOT EXISTS idx_trips_start_date ON public.trips(start_date);

-- ============================================
-- TRIP_MEMBERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.trip_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(trip_id, user_id)
);

ALTER TABLE public.trip_members ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_trip_members_trip_id ON public.trip_members(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_members_user_id ON public.trip_members(user_id);

-- ============================================
-- ITINERARY_ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.itinerary_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    day_number INTEGER NOT NULL,
    order_index INTEGER DEFAULT 0,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.itinerary_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_itinerary_items_trip_id ON public.itinerary_items(trip_id);

-- ============================================
-- CHECKLISTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.checklists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.checklists ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_checklists_trip_id ON public.checklists(trip_id);

-- ============================================
-- CHECKLIST_ITEMS TABLE
-- ============================================
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

ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_checklist_items_checklist_id ON public.checklist_items(checklist_id);

-- ============================================
-- EXPENSES TABLE
-- ============================================
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

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON public.expenses(trip_id);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON public.expenses(paid_by);

-- ============================================
-- EXPENSE_SPLITS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.expense_splits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    is_settled BOOLEAN DEFAULT false,
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_expense_splits_expense_id ON public.expense_splits(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_splits_user_id ON public.expense_splits(user_id);

-- ============================================
-- SETTLEMENTS TABLE
-- ============================================
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

ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_settlements_trip_id ON public.settlements(trip_id);
CREATE INDEX IF NOT EXISTS idx_settlements_from_user ON public.settlements(from_user);
CREATE INDEX IF NOT EXISTS idx_settlements_to_user ON public.settlements(to_user);

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES public.trips(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_messages_trip_id ON public.messages(trip_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

-- ============================================
-- TRIP_INVITES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.trip_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    email CITEXT NOT NULL,
    invited_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

ALTER TABLE public.trip_invites ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_trip_invites_trip_id ON public.trip_invites(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_invites_email ON public.trip_invites(email);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================
-- SUCCESS! Base tables created.
-- Next: Run COMBINED_MIGRATIONS.sql
-- ============================================
