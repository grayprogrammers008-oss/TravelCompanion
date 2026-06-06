-- Fix: The original checklist_items column for item text was named
-- 'content' (not 'title'/'name'/'item'/'text' that we already covered).
-- It's marked NOT NULL, so every Dart insert that sends only 'title'
-- but no 'content' fails with:
--   null value in column "content" violates not-null constraint (23502)
--
-- Strategy:
--   1. Backfill title from content for any rows where title is NULL
--      (in case the previous migration ran before this one)
--   2. Backfill content from title for new rows where title was set
--      but content wasn't (covers any rows the app inserted recently)
--   3. Drop NOT NULL on content so future inserts that only send title
--      succeed.
--   4. Keep content and title in lockstep via a BEFORE INSERT/UPDATE
--      trigger so legacy reads of `content` continue to work.

DO $$
DECLARE
  has_content BOOLEAN;
  has_title   BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='checklist_items'
      AND column_name='content'
  ) INTO has_content;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='checklist_items'
      AND column_name='title'
  ) INTO has_title;

  RAISE NOTICE 'Found columns — content: %, title: %', has_content, has_title;

  IF has_content AND has_title THEN
    -- 1. Backfill title from content for legacy rows
    UPDATE public.checklist_items
       SET title = content
     WHERE title IS NULL AND content IS NOT NULL;

    -- 2. Backfill content from title for rows the app inserted with only title
    UPDATE public.checklist_items
       SET content = title
     WHERE content IS NULL AND title IS NOT NULL;

    -- 3. Drop NOT NULL on content (it's now redundant — title is canonical)
    BEGIN
      ALTER TABLE public.checklist_items ALTER COLUMN content DROP NOT NULL;
      RAISE NOTICE 'Dropped NOT NULL on content.';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'content was already nullable.';
    END;
  END IF;
END $$;

-- 4. Sync trigger: when the app inserts/updates with title, mirror to content
--    so any legacy code reading `content` keeps working.
CREATE OR REPLACE FUNCTION public.sync_checklist_item_content_title()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- If only title was provided, copy to content
  IF NEW.title IS NOT NULL AND NEW.content IS NULL THEN
    NEW.content := NEW.title;
  END IF;
  -- If only content was provided, copy to title
  IF NEW.content IS NOT NULL AND NEW.title IS NULL THEN
    NEW.title := NEW.content;
  END IF;
  RETURN NEW;
END;
$$;

-- Only attach the trigger if the content column actually exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='checklist_items'
      AND column_name='content'
  ) THEN
    DROP TRIGGER IF EXISTS trg_sync_content_title ON public.checklist_items;
    CREATE TRIGGER trg_sync_content_title
      BEFORE INSERT OR UPDATE ON public.checklist_items
      FOR EACH ROW EXECUTE FUNCTION public.sync_checklist_item_content_title();
    RAISE NOTICE 'Sync trigger installed.';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';

-- Final sanity check
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema='public' AND table_name='checklist_items'
ORDER BY ordinal_position;
