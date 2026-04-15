-- ============================================================================
-- CREATE STORAGE POLICIES IN NEW DATABASE
-- ============================================================================
--
-- PURPOSE: Create standard storage policies for TravelCompanion app
--
-- PREREQUISITES:
-- 1. Buckets must be created FIRST via Dashboard UI
-- 2. Run this script in NEW Supabase (grayprogrammers008@gmail.com)
--
-- BUCKETS REQUIRED:
-- - avatars (public)
-- - trip-covers (public)
-- - receipts (private)
--
-- ============================================================================

-- ============================================================================
-- SECTION 1: ENABLE ROW LEVEL SECURITY (if not already enabled)
-- ============================================================================

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SECTION 2: DROP EXISTING POLICIES (clean slate)
-- ============================================================================

-- Drop all existing storage policies (if any)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT policyname FROM pg_policies
             WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON storage.objects';
    END LOOP;
END $$;

-- ============================================================================
-- SECTION 3: AVATARS BUCKET POLICIES
-- ============================================================================

-- Policy 1: Allow authenticated users to upload avatars
CREATE POLICY "Authenticated users can upload to avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Policy 2: Allow authenticated users to update avatars
CREATE POLICY "Authenticated users can update in avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Policy 3: Allow authenticated users to delete avatars
CREATE POLICY "Authenticated users can delete from avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

-- Policy 4: Allow public read access to avatars
CREATE POLICY "Public can read avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- ============================================================================
-- SECTION 4: TRIP-COVERS BUCKET POLICIES
-- ============================================================================

-- Policy 1: Allow authenticated users to upload trip covers
CREATE POLICY "Authenticated users can upload to trip-covers"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'trip-covers');

-- Policy 2: Allow authenticated users to update trip covers
CREATE POLICY "Authenticated users can update in trip-covers"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'trip-covers');

-- Policy 3: Allow authenticated users to delete trip covers
CREATE POLICY "Authenticated users can delete from trip-covers"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'trip-covers');

-- Policy 4: Allow public read access to trip covers
CREATE POLICY "Public can read trip-covers"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'trip-covers');

-- ============================================================================
-- SECTION 5: RECEIPTS BUCKET POLICIES (Private)
-- ============================================================================

-- Policy 1: Allow authenticated users to upload receipts
CREATE POLICY "Authenticated users can upload to receipts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts');

-- Policy 2: Allow authenticated users to update receipts
CREATE POLICY "Authenticated users can update in receipts"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'receipts');

-- Policy 3: Allow authenticated users to delete receipts
CREATE POLICY "Authenticated users can delete from receipts"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'receipts');

-- Policy 4: Allow authenticated users to read receipts (private bucket)
CREATE POLICY "Authenticated users can read receipts"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'receipts');

-- ============================================================================
-- SECTION 6: OPTIONAL - USER-SPECIFIC FOLDER POLICIES
-- ============================================================================

-- Uncomment these if you want users to only access their OWN files
-- (Files should be stored in folders named with user ID: /avatars/{user_id}/filename.jpg)

/*
-- Users can only upload to their own folder in avatars
CREATE POLICY "Users can upload to own avatar folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can only update their own avatars
CREATE POLICY "Users can update own avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can only delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Everyone can still read all avatars (public)
CREATE POLICY "Public can read all avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');
*/

-- ============================================================================
-- SECTION 7: VERIFICATION
-- ============================================================================

-- List all storage policies
SELECT
    policyname as policy_name,
    cmd as operation,
    CASE
        WHEN roles = '{public}' THEN 'public'
        WHEN roles = '{authenticated}' THEN 'authenticated'
        ELSE roles::text
    END as applies_to,
    CASE
        WHEN qual LIKE '%avatars%' THEN 'avatars'
        WHEN qual LIKE '%trip-covers%' THEN 'trip-covers'
        WHEN qual LIKE '%receipts%' THEN 'receipts'
        ELSE 'other'
    END as bucket
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY bucket, policyname;

-- Count policies per bucket
SELECT
    CASE
        WHEN qual LIKE '%avatars%' THEN 'avatars'
        WHEN qual LIKE '%trip-covers%' THEN 'trip-covers'
        WHEN qual LIKE '%receipts%' THEN 'receipts'
        ELSE 'other'
    END as bucket,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
GROUP BY bucket
ORDER BY bucket;

-- ============================================================================
-- SECTION 8: TEST QUERIES
-- ============================================================================

-- Check if RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'storage'
  AND tablename IN ('objects', 'buckets');

-- Check bucket configuration
SELECT
    id as bucket_name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
ORDER BY id;

-- ============================================================================
-- COMPLETED!
-- ============================================================================

-- Expected results:
-- ✅ 12 policies created (4 per bucket × 3 buckets)
-- ✅ avatars: INSERT, UPDATE, DELETE (authenticated), SELECT (public)
-- ✅ trip-covers: INSERT, UPDATE, DELETE (authenticated), SELECT (public)
-- ✅ receipts: INSERT, UPDATE, DELETE, SELECT (authenticated only)

-- Next steps:
-- 1. Verify policies created correctly (check output above)
-- 2. Test file upload via Dashboard
-- 3. Test public access for avatars and trip-covers
-- 4. Migrate files from OLD database
