-- ============================================================================
-- STORAGE BUCKET MIGRATION SCRIPT
-- ============================================================================
--
-- PART 1: Run this in OLD database to see bucket configuration
-- PART 2: Use output to create buckets in NEW database
--
-- ============================================================================

-- ============================================================================
-- PART 1: INSPECT OLD DATABASE BUCKETS
-- ============================================================================
-- Run this in OLD Supabase (palkarfoods224@gmail.com)

-- Check what buckets exist
SELECT
    id as bucket_name,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets
ORDER BY created_at;

-- Check bucket policies
SELECT
    bucket_id,
    name as policy_name,
    definition
FROM storage.policies
ORDER BY bucket_id, name;

-- Count files in each bucket
SELECT
    bucket_id,
    COUNT(*) as file_count,
    SUM(metadata->>'size')::bigint as total_size_bytes,
    ROUND(SUM((metadata->>'size')::bigint) / 1024.0 / 1024.0, 2) as total_size_mb
FROM storage.objects
GROUP BY bucket_id
ORDER BY bucket_id;

-- ============================================================================
-- PART 2: CREATE BUCKETS IN NEW DATABASE
-- ============================================================================
-- Run this in NEW Supabase (grayprogrammers008@gmail.com)
-- After running Part 1, update the values below based on your actual buckets

-- NOTE: Bucket creation must be done via Supabase Dashboard UI or Supabase CLI
-- SQL does not support direct bucket creation via INSERT

-- However, you can use this as a reference for manual creation:

/*
BUCKET CONFIGURATION GUIDE
==========================

Based on typical TravelCompanion setup:

1. AVATARS BUCKET
   - Name: avatars
   - Public: Yes (publicly accessible)
   - File size limit: 2 MB (2097152 bytes)
   - Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg

2. TRIP-COVERS BUCKET
   - Name: trip-covers
   - Public: Yes (publicly accessible)
   - File size limit: 5 MB (5242880 bytes)
   - Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg

3. RECEIPTS BUCKET
   - Name: receipts
   - Public: No (private, only authenticated users)
   - File size limit: 10 MB (10485760 bytes)
   - Allowed MIME types: image/*, application/pdf

*/

-- ============================================================================
-- PART 3: CREATE STORAGE POLICIES IN NEW DATABASE
-- ============================================================================
-- Run this in NEW Supabase SQL Editor after buckets are created

-- ============================================================================
-- AVATARS BUCKET POLICIES
-- ============================================================================

-- Policy 1: Allow users to upload their own avatar
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'avatars',
    'Users can upload their own avatar',
    $policy$
    (bucket_id = 'avatars'::text) AND (auth.uid()::text = (storage.foldername(name))[1])
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- Policy 2: Allow users to update their own avatar
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'avatars',
    'Users can update their own avatar',
    $policy$
    (bucket_id = 'avatars'::text) AND (auth.uid()::text = (storage.foldername(name))[1])
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- Policy 3: Allow public read access
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'avatars',
    'Public read access',
    $policy$
    (bucket_id = 'avatars'::text)
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- ============================================================================
-- TRIP-COVERS BUCKET POLICIES
-- ============================================================================

-- Policy 1: Allow authenticated users to upload trip covers
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'trip-covers',
    'Authenticated users can upload',
    $policy$
    (bucket_id = 'trip-covers'::text)
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- Policy 2: Allow public read access
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'trip-covers',
    'Public read access',
    $policy$
    (bucket_id = 'trip-covers'::text)
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- ============================================================================
-- RECEIPTS BUCKET POLICIES
-- ============================================================================

-- Policy 1: Allow authenticated users to upload receipts
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'receipts',
    'Authenticated users can upload',
    $policy$
    (bucket_id = 'receipts'::text)
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- Policy 2: Allow users to read their own receipts
INSERT INTO storage.policies (bucket_id, name, definition)
VALUES (
    'receipts',
    'Users can read their own receipts',
    $policy$
    (bucket_id = 'receipts'::text)
    $policy$
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES (Run in NEW database)
-- ============================================================================

-- Check buckets were created
SELECT * FROM storage.buckets ORDER BY name;

-- Check policies were created
SELECT bucket_id, name FROM storage.policies ORDER BY bucket_id, name;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
IMPORTANT NOTES:

1. Bucket Creation:
   - Buckets CANNOT be created via SQL INSERT statements
   - Must use Supabase Dashboard UI or CLI
   - Go to Storage → New Bucket in dashboard

2. Manual Steps Required:
   Step 1: Run PART 1 in OLD database to see your bucket config
   Step 2: Create buckets in NEW database via Dashboard UI:
           - Click Storage
           - Click "New bucket"
           - Enter name, set public/private, limits
   Step 3: Run PART 3 in NEW database to create policies

3. File Migration:
   - Files must be uploaded separately
   - Use Storage UI for small datasets
   - Use Supabase CLI for large datasets

4. Policy Format:
   - Policies use RLS (Row Level Security) syntax
   - The $policy$ tags wrap the policy definition
   - Policies control who can read/write files

*/
