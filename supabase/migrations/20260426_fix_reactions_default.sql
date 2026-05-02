-- Fix: reactions column default was '{}' (JSON object) but should be '[]' (JSON array)
-- The Flutter MessageModel expects reactions to be a List, not a Map.

ALTER TABLE public.messages
  ALTER COLUMN reactions SET DEFAULT '[]'::jsonb;

-- Fix any existing rows that have the wrong default {} (empty object) instead of [] (empty array)
UPDATE public.messages
  SET reactions = '[]'::jsonb
  WHERE reactions = '{}'::jsonb;
