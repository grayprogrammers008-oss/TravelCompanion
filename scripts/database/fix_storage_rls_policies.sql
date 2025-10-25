-- ============================================================================
-- FIX: Storage RLS Policies for Message Attachments
-- ============================================================================
--
-- Purpose: Fix "new row violates row level security policy" error
--          when uploading images to message-attachments bucket
--
-- Problem: RLS is enabled but no policies exist to allow uploads
--
-- Solution: Create 4 RLS policies:
--   1. INSERT - Allow authenticated users to upload
--   2. SELECT - Allow public to view (bucket is public)
--   3. UPDATE - Allow authenticated users to update
--   4. DELETE - Allow authenticated users to delete
--
-- How to run:
--   1. Open Supabase Dashboard → SQL Editor
--   2. Click "New query"
--   3. Copy-paste this entire file
--   4. Click "Run" or press Ctrl+Enter / Cmd+Enter
--
-- Date: 2025-10-25
-- ============================================================================

-- ----------------------------------------------------------------------------
-- POLICY 1: Allow authenticated users to UPLOAD (INSERT) files
-- ----------------------------------------------------------------------------
CREATE POLICY "Authenticated users can upload message attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- ----------------------------------------------------------------------------
-- POLICY 2: Allow PUBLIC to VIEW (SELECT) files
-- This is needed because the bucket is public and we use getPublicUrl()
-- ----------------------------------------------------------------------------
CREATE POLICY "Public can view message attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'message-attachments');

-- ----------------------------------------------------------------------------
-- POLICY 3: Allow authenticated users to UPDATE files
-- This allows replacing images, updating metadata, etc.
-- ----------------------------------------------------------------------------
CREATE POLICY "Authenticated users can update message attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- ----------------------------------------------------------------------------
-- POLICY 4: Allow authenticated users to DELETE files
-- This allows deleting message attachments
-- ----------------------------------------------------------------------------
CREATE POLICY "Authenticated users can delete message attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- ----------------------------------------------------------------------------
-- VERIFICATION: Check that policies were created
-- ----------------------------------------------------------------------------
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%message%'
ORDER BY cmd;

-- Expected output: 4 rows showing the policies created above
--
-- schemaname | tablename | policyname                                          | roles         | cmd
-- -----------|-----------|-----------------------------------------------------|---------------|--------
-- storage    | objects   | Authenticated users can upload message attachments  | authenticated | INSERT
-- storage    | objects   | Public can view message attachments                 | public        | SELECT
-- storage    | objects   | Authenticated users can update message attachments  | authenticated | UPDATE
-- storage    | objects   | Authenticated users can delete message attachments  | authenticated | DELETE

-- ============================================================================
-- NOTES:
-- ============================================================================
--
-- 1. These policies apply ONLY to the 'message-attachments' bucket
-- 2. Other storage buckets are NOT affected
-- 3. The policies are PERMISSIVE (allow operations, don't deny)
-- 4. You can run this script multiple times safely (it will error if policies
--    already exist, but won't cause data loss)
--
-- ============================================================================
-- ROLLBACK (if needed):
-- ============================================================================
--
-- If you need to remove these policies, run:
--
-- DROP POLICY IF EXISTS "Authenticated users can upload message attachments" ON storage.objects;
-- DROP POLICY IF EXISTS "Public can view message attachments" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can update message attachments" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can delete message attachments" ON storage.objects;
--
-- ============================================================================
