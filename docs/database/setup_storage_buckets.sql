-- =====================================================
-- Supabase Storage Buckets Setup Script
-- =====================================================
-- This script creates all required storage buckets for the TravelCompanion app
-- Run this script in Supabase SQL Editor
--
-- Buckets Created:
-- 1. profile-avatars - User profile photos
-- 2. trip-covers - Trip cover images
-- 3. expense-receipts - Expense receipt photos
-- 4. settlement-proofs - Settlement proof documents
-- 5. message-attachments - Messaging module attachments (may already exist)
--
-- Created: 2025-10-25
-- =====================================================

-- =====================================================
-- 1. CREATE STORAGE BUCKETS
-- =====================================================

-- Profile Avatars Bucket (Public)
-- Used for: User profile photos
-- Access: Public (anyone can view, authenticated users can upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-avatars',
  'profile-avatars',
  true,  -- Public bucket for easy profile photo access
  5242880,  -- 5 MB limit (profile photos should be small)
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Trip Covers Bucket (Public)
-- Used for: Trip cover/header images
-- Access: Public (anyone can view, authenticated users can upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'trip-covers',
  'trip-covers',
  true,  -- Public bucket for trip cover images
  10485760,  -- 10 MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Expense Receipts Bucket (Public)
-- Used for: Expense receipt photos
-- Access: Public (trip members need to view receipts)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'expense-receipts',
  'expense-receipts',
  true,  -- Public bucket for receipt sharing
  10485760,  -- 10 MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Settlement Proofs Bucket (Public)
-- Used for: Settlement proof documents (payment screenshots, etc.)
-- Access: Public (trip members need to verify settlements)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'settlement-proofs',
  'settlement-proofs',
  true,  -- Public bucket for settlement verification
  10485760,  -- 10 MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Message Attachments Bucket (Public)
-- Used for: Messaging module image attachments
-- Access: Public (trip members share images in chat)
-- Note: This may already exist from previous setup
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'message-attachments',
  'message-attachments',
  true,  -- Public bucket for message images
  10485760,  -- 10 MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================
-- Enable RLS on storage.objects table to control access

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. CREATE STORAGE POLICIES
-- =====================================================

-- -----------------------------------------------------
-- Profile Avatars Policies
-- -----------------------------------------------------

-- Allow authenticated users to upload their own profile photos
CREATE POLICY "Users can upload own profile avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-avatars' AND
  auth.role() = 'authenticated' AND
  -- Path structure: userId/profile_timestamp.jpg
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to update their own profile photos
CREATE POLICY "Users can update own profile avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own profile photos
CREATE POLICY "Users can delete own profile avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow everyone to view profile avatars (public bucket)
CREATE POLICY "Anyone can view profile avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-avatars');

-- -----------------------------------------------------
-- Trip Covers Policies
-- -----------------------------------------------------

-- Allow authenticated users to upload trip covers
CREATE POLICY "Authenticated users can upload trip covers"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'trip-covers' AND
  auth.role() = 'authenticated'
);

-- Allow authenticated users to update trip covers
-- (Trip ownership check should be done at application level)
CREATE POLICY "Authenticated users can update trip covers"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'trip-covers');

-- Allow authenticated users to delete trip covers
CREATE POLICY "Authenticated users can delete trip covers"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'trip-covers');

-- Allow everyone to view trip covers (public bucket)
CREATE POLICY "Anyone can view trip covers"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'trip-covers');

-- -----------------------------------------------------
-- Expense Receipts Policies
-- -----------------------------------------------------

-- Allow authenticated users to upload expense receipts
CREATE POLICY "Authenticated users can upload receipts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'expense-receipts' AND
  auth.role() = 'authenticated'
);

-- Allow authenticated users to view receipts
CREATE POLICY "Authenticated users can view receipts"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'expense-receipts');

-- Allow authenticated users to delete receipts
-- (Expense ownership check should be done at application level)
CREATE POLICY "Authenticated users can delete receipts"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'expense-receipts');

-- -----------------------------------------------------
-- Settlement Proofs Policies
-- -----------------------------------------------------

-- Allow authenticated users to upload settlement proofs
CREATE POLICY "Authenticated users can upload settlement proofs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'settlement-proofs' AND
  auth.role() = 'authenticated'
);

-- Allow authenticated users to view settlement proofs
CREATE POLICY "Authenticated users can view settlement proofs"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'settlement-proofs');

-- Allow authenticated users to delete settlement proofs
CREATE POLICY "Authenticated users can delete settlement proofs"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'settlement-proofs');

-- -----------------------------------------------------
-- Message Attachments Policies
-- -----------------------------------------------------

-- Allow authenticated users to upload message attachments
CREATE POLICY "Authenticated users can upload message attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- Allow everyone to view message attachments (public bucket)
-- Note: Could be restricted to trip members in future
CREATE POLICY "Anyone can view message attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'message-attachments');

-- Allow authenticated users to delete message attachments
-- (Message ownership check should be done at application level)
CREATE POLICY "Authenticated users can delete message attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'message-attachments');

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Check all buckets were created
SELECT id, name, public, file_size_limit, created_at
FROM storage.buckets
WHERE id IN (
  'profile-avatars',
  'trip-covers',
  'expense-receipts',
  'settlement-proofs',
  'message-attachments'
)
ORDER BY id;

-- Check all policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'objects'
ORDER BY policyname;

-- =====================================================
-- 5. EXPECTED OUTPUT
-- =====================================================
--
-- Buckets Query Result:
-- id                   | name                 | public | file_size_limit | created_at
-- ---------------------|----------------------|--------|-----------------|-------------------
-- expense-receipts     | expense-receipts     | true   | 10485760        | 2025-10-25 ...
-- message-attachments  | message-attachments  | true   | 10485760        | 2025-10-24 ...
-- profile-avatars      | profile-avatars      | true   | 5242880         | 2025-10-25 ...
-- settlement-proofs    | settlement-proofs    | true   | 10485760        | 2025-10-25 ...
-- trip-covers          | trip-covers          | true   | 10485760        | 2025-10-25 ...
--
-- Policies Query Result:
-- Should show ~15 policies for all buckets
--
-- =====================================================
-- SETUP COMPLETE! ✅
-- =====================================================
--
-- Next Steps:
-- 1. Run verification queries above to confirm setup
-- 2. Test profile photo upload in app
-- 3. Monitor storage usage in Supabase dashboard
-- 4. Consider implementing cleanup logic for deleted records
--
-- Documentation:
-- - See SUPABASE_STORAGE_SETUP.md for message-attachments details
-- - See PROFILE_AVATARS_STORAGE_SETUP.md for profile-avatars details
--
-- =====================================================
