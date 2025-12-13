-- Script to delete test conversations (Besties, Direct Message)
-- Run this in Supabase Dashboard SQL Editor

-- First, let's see what conversations exist (preview)
SELECT
    c.id,
    c.name,
    c.trip_id,
    c.is_direct_message,
    c.is_default_group,
    t.name as trip_name
FROM public.conversations c
LEFT JOIN public.trips t ON c.trip_id = t.id
WHERE c.name IN ('Besties', 'Direct Message')
   OR c.is_direct_message = true
ORDER BY c.created_at;

-- ============================================================================
-- UNCOMMENT BELOW TO DELETE (after reviewing the preview above)
-- ============================================================================

-- Delete messages first (foreign key constraint)
/*
DELETE FROM public.messages
WHERE conversation_id IN (
    SELECT id FROM public.conversations
    WHERE name IN ('Besties', 'Direct Message')
       OR (is_direct_message = true AND is_default_group = false)
);
*/

-- Delete conversation members
/*
DELETE FROM public.conversation_members
WHERE conversation_id IN (
    SELECT id FROM public.conversations
    WHERE name IN ('Besties', 'Direct Message')
       OR (is_direct_message = true AND is_default_group = false)
);
*/

-- Delete the conversations
/*
DELETE FROM public.conversations
WHERE name IN ('Besties', 'Direct Message')
   OR (is_direct_message = true AND is_default_group = false);
*/

-- Verify deletion
-- SELECT * FROM public.conversations WHERE name IN ('Besties', 'Direct Message');
