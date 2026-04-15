-- ============================================
-- PRE-MIGRATION FIX SCRIPT
-- ============================================
-- Run this BEFORE COMBINED_MIGRATIONS.sql if you have an existing database
-- where the trips table was created with a different schema.
--
-- This script safely adds missing columns to existing tables without
-- affecting data that already exists.
-- ============================================

-- ============================================
-- FIX 1: Add missing columns to TRIPS table
-- ============================================
-- If the trips table existed before BASE_SCHEMA_MINIMAL.sql was run,
-- CREATE TABLE IF NOT EXISTS won't add these columns.

DO $$
BEGIN
    -- Add destination column if missing (used throughout migrations)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'destination'
    ) THEN
        RAISE NOTICE 'Adding destination column to trips table...';
        ALTER TABLE public.trips ADD COLUMN destination TEXT;
        -- Set default value for existing rows
        UPDATE public.trips SET destination = 'Unknown' WHERE destination IS NULL;
        -- Make it NOT NULL after populating
        ALTER TABLE public.trips ALTER COLUMN destination SET NOT NULL;
        RAISE NOTICE 'destination column added successfully.';
    ELSE
        RAISE NOTICE 'destination column already exists.';
    END IF;

    -- Add is_public column if missing (for discover/public trips feature)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'is_public'
    ) THEN
        RAISE NOTICE 'Adding is_public column to trips table...';
        ALTER TABLE public.trips ADD COLUMN is_public BOOLEAN DEFAULT false;
        RAISE NOTICE 'is_public column added successfully.';
    ELSE
        RAISE NOTICE 'is_public column already exists.';
    END IF;

    -- Add cost column if missing (trip cost per person)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'cost'
    ) THEN
        RAISE NOTICE 'Adding cost column to trips table...';
        ALTER TABLE public.trips ADD COLUMN cost DOUBLE PRECISION;
        RAISE NOTICE 'cost column added successfully.';
    ELSE
        RAISE NOTICE 'cost column already exists.';
    END IF;

    -- Add is_completed column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'is_completed'
    ) THEN
        RAISE NOTICE 'Adding is_completed column to trips table...';
        ALTER TABLE public.trips ADD COLUMN is_completed BOOLEAN DEFAULT false;
        RAISE NOTICE 'is_completed column added successfully.';
    ELSE
        RAISE NOTICE 'is_completed column already exists.';
    END IF;

    -- Add completed_at column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'completed_at'
    ) THEN
        RAISE NOTICE 'Adding completed_at column to trips table...';
        ALTER TABLE public.trips ADD COLUMN completed_at TIMESTAMPTZ;
        RAISE NOTICE 'completed_at column added successfully.';
    ELSE
        RAISE NOTICE 'completed_at column already exists.';
    END IF;

    -- Add rating column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'rating'
    ) THEN
        RAISE NOTICE 'Adding rating column to trips table...';
        ALTER TABLE public.trips ADD COLUMN rating DOUBLE PRECISION;
        RAISE NOTICE 'rating column added successfully.';
    ELSE
        RAISE NOTICE 'rating column already exists.';
    END IF;

    -- Add currency column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'currency'
    ) THEN
        RAISE NOTICE 'Adding currency column to trips table...';
        ALTER TABLE public.trips ADD COLUMN currency TEXT DEFAULT 'INR';
        RAISE NOTICE 'currency column added successfully.';
    ELSE
        RAISE NOTICE 'currency column already exists.';
    END IF;

    -- Add cover_image_url column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'trips'
        AND column_name = 'cover_image_url'
    ) THEN
        RAISE NOTICE 'Adding cover_image_url column to trips table...';
        ALTER TABLE public.trips ADD COLUMN cover_image_url TEXT;
        RAISE NOTICE 'cover_image_url column added successfully.';
    ELSE
        RAISE NOTICE 'cover_image_url column already exists.';
    END IF;

END $$;

-- ============================================
-- FIX 2: Add missing columns to CHECKLIST_ITEMS table
-- ============================================
-- The copy_trip function expects both 'name' and 'content' columns

DO $$
BEGIN
    -- Add name column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'checklist_items'
        AND column_name = 'name'
    ) THEN
        RAISE NOTICE 'Adding name column to checklist_items table...';
        ALTER TABLE public.checklist_items ADD COLUMN name TEXT;
        RAISE NOTICE 'name column added successfully.';
    ELSE
        RAISE NOTICE 'name column already exists in checklist_items.';
    END IF;

    -- Add content column if missing (this is NOT NULL in base schema)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'checklist_items'
        AND column_name = 'content'
    ) THEN
        RAISE NOTICE 'Adding content column to checklist_items table...';
        ALTER TABLE public.checklist_items ADD COLUMN content TEXT;
        -- Set default value for existing rows before making NOT NULL
        UPDATE public.checklist_items SET content = COALESCE(name, 'Item') WHERE content IS NULL;
        ALTER TABLE public.checklist_items ALTER COLUMN content SET NOT NULL;
        RAISE NOTICE 'content column added successfully.';
    ELSE
        RAISE NOTICE 'content column already exists in checklist_items.';
    END IF;
END $$;

-- ============================================
-- FIX 3: Ensure required indexes exist
-- ============================================
CREATE INDEX IF NOT EXISTS idx_trips_destination ON public.trips(destination);
CREATE INDEX IF NOT EXISTS idx_trips_is_public ON public.trips(is_public);
CREATE INDEX IF NOT EXISTS idx_trips_is_completed ON public.trips(is_completed);

-- ============================================
-- VERIFICATION: Show current trips table structure
-- ============================================
DO $$
DECLARE
    col_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'trips';

    RAISE NOTICE '============================================';
    RAISE NOTICE 'PRE-MIGRATION FIX COMPLETE';
    RAISE NOTICE 'Trips table now has % columns', col_count;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'You can now run COMBINED_MIGRATIONS.sql';
    RAISE NOTICE '============================================';
END $$;
