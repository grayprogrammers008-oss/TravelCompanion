# Step-by-Step: Migrate Storage Policies from OLD to NEW Database

## 🎯 Goal
Export storage policies from OLD database and recreate them in NEW database

---

## Overview

Storage migration has 3 parts:
1. **Create buckets** (via Dashboard UI)
2. **Create policies** (via SQL) ← YOU ARE HERE
3. **Migrate files** (via Dashboard or CLI)

---

## Part 1: Export Policies from OLD Database

### Step 1: Login to OLD Supabase

1. Go to https://supabase.com
2. Login with **palkarfoods224@gmail.com**
3. Open TravelCompanion project
4. Click **SQL Editor** in left sidebar

### Step 2: Run Export Script

1. Open file: `EXPORT_STORAGE_POLICIES.sql`
2. **Copy entire contents** (Ctrl+A, Ctrl+C)
3. **Paste** into Supabase SQL Editor
4. Click **RUN**
5. Wait for execution (5-10 seconds)

### Step 3: Copy Output

1. Scroll through the output in results panel
2. You'll see sections like:
   ```
   -- Bucket: avatars | Public: Yes | Size Limit: 2 MB
   -- Bucket: trip-covers | Public: Yes | Size Limit: 5 MB

   CREATE POLICY "Authenticated users can upload to avatars"
   ON storage.objects FOR INSERT
   TO authenticated
   WITH CHECK (bucket_id = 'avatars');
   ```

3. **Select ALL output** (click in results, Ctrl+A)
4. **Copy** (Ctrl+C)

### Step 4: Save Export

1. Create new file: `IMPORT_STORAGE_POLICIES.sql`
2. **Paste** all copied output
3. Save file to: `d:\Nithya\Travel Companion\TravelCompanion\IMPORT_STORAGE_POLICIES.sql`

---

## Part 2: Create Buckets in NEW Database

⚠️ **IMPORTANT:** You MUST create buckets BEFORE creating policies!

### Step 1: Login to NEW Supabase

1. Go to https://supabase.com
2. Login with **grayprogrammers008@gmail.com**
3. Open your NEW TravelCompanion project
4. Click **Storage** in left sidebar

### Step 2: Create Each Bucket

Based on your export output, create buckets. Common ones:

#### Bucket 1: avatars (or profile-avatars)

1. Click **New Bucket**
2. Fill in:
   - **Bucket name:** `avatars` (or match name from OLD database)
   - **Public bucket:** ✅ Check this (public)
   - **File size limit:** 2 MB (2097152 bytes)
   - **Allowed MIME types:** `image/jpeg,image/png,image/webp,image/jpg`
3. Click **Create bucket**

#### Bucket 2: trip-covers

1. Click **New Bucket**
2. Fill in:
   - **Bucket name:** `trip-covers`
   - **Public bucket:** ✅ Check this (public)
   - **File size limit:** 5 MB (5242880 bytes)
   - **Allowed MIME types:** `image/jpeg,image/png,image/webp,image/jpg`
3. Click **Create bucket**

#### Bucket 3: receipts

1. Click **New Bucket**
2. Fill in:
   - **Bucket name:** `receipts`
   - **Public bucket:** ❌ Uncheck (private)
   - **File size limit:** 10 MB (10485760 bytes)
   - **Allowed MIME types:** `image/*,application/pdf`
3. Click **Create bucket**

### Step 3: Verify Buckets

1. Go to **Storage** in left sidebar
2. You should see all buckets listed
3. Check each bucket:
   - Click on bucket name
   - Verify it's empty (no files yet)
   - Note the public/private setting

---

## Part 3: Import Policies to NEW Database

### Step 1: Open SQL Editor in NEW Database

1. Still in NEW Supabase project
2. Click **SQL Editor** in left sidebar
3. Click **New Query**

### Step 2: Run Import Script

1. Open your saved file: `IMPORT_STORAGE_POLICIES.sql`
2. **Copy entire contents** (Ctrl+A, Ctrl+C)
3. **Paste** into Supabase SQL Editor
4. Click **RUN**

### Step 3: Verify Policies Created

Run this query to check:

```sql
-- See all storage policies
SELECT
    policyname as policy_name,
    cmd as command,
    qual as using_clause,
    with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;
```

You should see policies like:
- Authenticated users can upload to avatars
- Authenticated users can update in avatars
- Public can read avatars
- (and similar for other buckets)

---

## Part 4: Test Policies

### Test Upload (via Dashboard)

1. Go to **Storage** → **avatars** bucket
2. Click **Upload file**
3. Select any test image file
4. Click **Upload**
5. If successful ✅ policies are working!

### Test Public Access (for public buckets)

1. After uploading a test file
2. Click on the file name
3. Copy the **Public URL**
4. Open URL in new browser tab
5. If image loads ✅ public read policy works!

---

## Common Policies Explained

### For Public Buckets (avatars, trip-covers):

```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload to avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update in avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete from avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

-- Allow everyone to read (public access)
CREATE POLICY "Public can read avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');
```

### For Private Buckets (receipts):

```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload to receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update in receipts"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'receipts');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete from receipts"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'receipts');

-- Allow only authenticated users to read (private)
CREATE POLICY "Authenticated users can read receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'receipts');
```

---

## Advanced: User-Specific Policies

If you want users to only access their own files:

```sql
-- Users can only upload to their own folder
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can only update their own files
CREATE POLICY "Users can update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can only delete their own files
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Everyone can read (but upload/update/delete restricted to owner)
CREATE POLICY "Public can read avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');
```

---

## Troubleshooting

### Problem: "Policy already exists"

**Solution:**
```sql
-- Drop existing policy first
DROP POLICY IF EXISTS "policy_name" ON storage.objects;

-- Then create new one
CREATE POLICY "policy_name" ON storage.objects ...
```

### Problem: "Relation 'storage.objects' does not exist"

**Solution:** Storage is not enabled. Contact Supabase support.

### Problem: "Permission denied for table objects"

**Solution:** You need to be the project owner or have proper permissions.

### Problem: "Cannot upload files even with policy"

**Solution:**
1. Check RLS is enabled:
   ```sql
   ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
   ```
2. Verify policy exists:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'objects';
   ```
3. Check you're using authenticated user, not anon key

### Problem: "Files upload but can't be read publicly"

**Solution:**
1. Verify bucket is set to public in Storage settings
2. Check SELECT policy exists for 'public' role
3. Try accessing with bucket URL format:
   `https://PROJECT.supabase.co/storage/v1/object/public/BUCKET/FILE`

---

## Verification Checklist

After completing all steps:

- [ ] All buckets created in NEW database
- [ ] Bucket settings match OLD database (public/private, size limits)
- [ ] All policies created successfully
- [ ] Test file upload works
- [ ] Test file read/download works
- [ ] Public buckets accessible via public URL
- [ ] Private buckets require authentication
- [ ] Ready to migrate actual files

---

## Next Step: Migrate Files

Now that buckets and policies are ready, you can migrate the actual files:

**Option A: Manual (< 100 files)**
- Download from OLD database Storage
- Upload to NEW database Storage

**Option B: Supabase CLI (> 100 files)**
```bash
supabase storage export BUCKET ./backup/
supabase storage import BUCKET ./backup/
```

---

## Summary

**What you did:**
1. ✅ Exported storage configuration from OLD database
2. ✅ Created buckets in NEW database
3. ✅ Created policies in NEW database
4. ✅ Tested policies work

**What's next:**
- Migrate actual files (images, PDFs, etc.)
- Update app configuration
- Test app with new storage

---

Need help with any step? Let me know!
