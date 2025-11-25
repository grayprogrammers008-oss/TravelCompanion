-- =============================================
-- Storage Buckets Setup for Travel Crew
-- =============================================
-- Created: 2025-02-01
-- Purpose: Create storage buckets for user avatars, trip covers,
--          expense receipts, and settlement proofs with proper RLS policies

-- =============================================
-- 1. CREATE STORAGE BUCKETS
-- =============================================

-- Profile Avatars Bucket (public read, authenticated upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-avatars',
  'profile-avatars',
  true, -- Public read access
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Trip Covers Bucket (public read, trip members upload)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'trip-covers',
  'trip-covers',
  true, -- Public read access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Expense Receipts Bucket (private, only trip members can access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'expense-receipts',
  'expense-receipts',
  false, -- Private access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Settlement Proofs Bucket (private, only involved users can access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'settlement-proofs',
  'settlement-proofs',
  false, -- Private access
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- =============================================
-- 2. RLS POLICIES FOR PROFILE AVATARS
-- =============================================

-- Allow authenticated users to upload their own avatars
CREATE POLICY "Users can upload their own profile avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own avatars
CREATE POLICY "Users can update their own profile avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own avatars
CREATE POLICY "Users can delete their own profile avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access to all profile avatars
CREATE POLICY "Public can view profile avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-avatars');

-- =============================================
-- 3. RLS POLICIES FOR TRIP COVERS
-- =============================================

-- Allow trip members to upload trip covers
CREATE POLICY "Trip members can upload trip covers"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow trip members to update trip covers
CREATE POLICY "Trip members can update trip covers"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow trip members to delete trip covers
CREATE POLICY "Trip members can delete trip covers"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'trip-covers'
  AND EXISTS (
    SELECT 1 FROM trip_members tm
    WHERE tm.trip_id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow public read access to all trip covers
CREATE POLICY "Public can view trip covers"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'trip-covers');

-- =============================================
-- 4. RLS POLICIES FOR EXPENSE RECEIPTS
-- =============================================

-- Allow trip members to upload expense receipts
CREATE POLICY "Trip members can upload expense receipts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    JOIN trip_members tm ON e.trip_id = tm.trip_id
    WHERE e.id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow trip members to view expense receipts
CREATE POLICY "Trip members can view expense receipts"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    JOIN trip_members tm ON e.trip_id = tm.trip_id
    WHERE e.id::text = (storage.foldername(name))[1]
    AND tm.user_id = auth.uid()
  )
);

-- Allow expense creator to update their receipts
CREATE POLICY "Expense creators can update receipts"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    WHERE e.id::text = (storage.foldername(name))[1]
    AND e.paid_by = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    WHERE e.id::text = (storage.foldername(name))[1]
    AND e.paid_by = auth.uid()
  )
);

-- Allow expense creator to delete their receipts
CREATE POLICY "Expense creators can delete receipts"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'expense-receipts'
  AND EXISTS (
    SELECT 1
    FROM expenses e
    WHERE e.id::text = (storage.foldername(name))[1]
    AND e.paid_by = auth.uid()
  )
);

-- =============================================
-- 5. RLS POLICIES FOR SETTLEMENT PROOFS
-- =============================================

-- Allow payer to upload settlement proofs
CREATE POLICY "Payers can upload settlement proofs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
);

-- Allow involved users to view settlement proofs
CREATE POLICY "Involved users can view settlement proofs"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND (s.from_user = auth.uid() OR s.to_user = auth.uid())
  )
);

-- Allow payer to update settlement proofs
CREATE POLICY "Payers can update settlement proofs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
)
WITH CHECK (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
);

-- Allow payer to delete settlement proofs
CREATE POLICY "Payers can delete settlement proofs"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'settlement-proofs'
  AND EXISTS (
    SELECT 1
    FROM settlements s
    WHERE s.id::text = (storage.foldername(name))[1]
    AND s.from_user = auth.uid()
  )
);

-- =============================================
-- MIGRATION COMPLETE
-- =============================================
-- All storage buckets and RLS policies have been created successfully.
--
-- Bucket Summary:
-- 1. profile-avatars: 5MB, public read, user-owned uploads
-- 2. trip-covers: 10MB, public read, trip member uploads
-- 3. expense-receipts: 10MB, private, trip member access
-- 4. settlement-proofs: 10MB, private, payer/receiver access
--
-- All policies enforce proper access control based on user roles and ownership.
