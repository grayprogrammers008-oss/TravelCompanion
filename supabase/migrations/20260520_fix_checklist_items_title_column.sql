-- Fix: checklist_items is also missing the 'title' column.
--
-- Symptom (after applying schema fix for assigned_to et al):
--   PostgrestException(
--     message: Could not find the 'title' column of 'checklist_items' in the schema cache,
--     code: PGRST204
--   )
--
-- The Dart ChecklistItemModel writes the item text into a column called
-- 'title'. The early schema may have called it 'name', 'item', or 'text'
-- instead. This migration:
--   1. Adds 'title TEXT' if it doesn't exist
--   2. Migrates data from likely-old column names if they're present
--   3. Reloads PostgREST schema cache so the next insert sees it
--
-- Safe to run multiple times.

DO $$
DECLARE
  has_title BOOLEAN;
  has_name  BOOLEAN;
  has_item  BOOLEAN;
  has_text  BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'checklist_items'
      AND column_name = 'title'
  ) INTO has_title;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'checklist_items'
      AND column_name = 'name'
  ) INTO has_name;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'checklist_items'
      AND column_name = 'item'
  ) INTO has_item;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'checklist_items'
      AND column_name = 'text'
  ) INTO has_text;

  RAISE NOTICE 'checklist_items columns — title: %, name: %, item: %, text: %',
    has_title, has_name, has_item, has_text;

  IF NOT has_title THEN
    ALTER TABLE public.checklist_items
      ADD COLUMN title TEXT;
    RAISE NOTICE 'Added title column.';

    -- Backfill from whichever legacy column exists
    IF has_name THEN
      UPDATE public.checklist_items SET title = name WHERE title IS NULL;
      RAISE NOTICE 'Backfilled title from name.';
    ELSIF has_item THEN
      UPDATE public.checklist_items SET title = item WHERE title IS NULL;
      RAISE NOTICE 'Backfilled title from item.';
    ELSIF has_text THEN
      UPDATE public.checklist_items SET title = text WHERE title IS NULL;
      RAISE NOTICE 'Backfilled title from text.';
    END IF;
  END IF;
END $$;

-- Make sure title is NOT NULL going forward (existing nulls already filled
-- by backfill above, so this is safe).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='checklist_items'
      AND column_name='title' AND is_nullable='YES'
  ) THEN
    -- Default any remaining NULL titles to a sentinel so we can set NOT NULL.
    UPDATE public.checklist_items SET title = '(no title)' WHERE title IS NULL;
    ALTER TABLE public.checklist_items ALTER COLUMN title SET NOT NULL;
    RAISE NOTICE 'Set title NOT NULL.';
  END IF;
END $$;

-- Reload PostgREST schema cache so the change is visible immediately.
NOTIFY pgrst, 'reload schema';

-- Show the full current schema so you can sanity-check.
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='checklist_items'
ORDER BY ordinal_position;
