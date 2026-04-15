# Step-by-Step: Create Storage Buckets in NEW Database

## 🎯 Goal
Recreate the same storage buckets from OLD database in NEW database

---

## Part 1: Check OLD Database Buckets

### Step 1: Login to OLD Supabase

1. Go to https://supabase.com
2. Login with **palkarfoods224@gmail.com**
3. Open TravelCompanion project

### Step 2: Check Existing Buckets

**Option A: Using Dashboard (Easiest)**

1. Click **Storage** in left sidebar
2. You'll see list of buckets
3. Write down:
   - Bucket names (e.g., avatars, trip-covers, receipts)
   - Which are public vs private
   - How many files in each

**Option B: Using SQL**

1. Click **SQL Editor**
2. Run this query:

```sql
-- See all buckets
SELECT
    id as bucket_name,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
ORDER BY created_at;

-- Count files in each bucket
SELECT
    bucket_id,
    COUNT(*) as file_count
FROM storage.objects
GROUP BY bucket_id;
```

3. Write down the results

---

## Part 2: Create Buckets in NEW Database

### Step 1: Login to NEW Supabase

1. Go to https://supabase.com
2. Login with **grayprogrammers008@gmail.com**
3. Open your NEW TravelCompanion project

### Step 2: Create Each Bucket

For each bucket you found in OLD database, create it in NEW database:

---

### BUCKET 1: avatars

1. Click **Storage** in left sidebar
2. Click **New Bucket** button
3. Fill in:
   - **Name:** `avatars`
   - **Public bucket:** ✅ Check this (ON)
   - **File size limit:** 2 MB (or leave default)
   - **Allowed MIME types:** Leave blank or add: `image/jpeg,image/png,image/webp`
4. Click **Create bucket**

**Set Policies:**

1. Click on the `avatars` bucket
2. Click **Policies** tab
3. Click **New Policy**
4. Choose template: "Enable insert for authenticated users"
5. Click **Review** → **Save policy**
6. Click **New Policy** again
7. Choose template: "Enable read access to everyone"
8. Click **Review** → **Save policy**

---

### BUCKET 2: trip-covers

1. Click **New Bucket** button
2. Fill in:
   - **Name:** `trip-covers`
   - **Public bucket:** ✅ Check this (ON)
   - **File size limit:** 5 MB
   - **Allowed MIME types:** `image/jpeg,image/png,image/webp`
3. Click **Create bucket**

**Set Policies:**

1. Click on the `trip-covers` bucket
2. Click **Policies** tab
3. Click **New Policy**
4. Choose template: "Enable insert for authenticated users"
5. Click **Review** → **Save policy**
6. Click **New Policy** again
7. Choose template: "Enable read access to everyone"
8. Click **Review** → **Save policy**

---

### BUCKET 3: receipts

1. Click **New Bucket** button
2. Fill in:
   - **Name:** `receipts`
   - **Public bucket:** ❌ Uncheck this (OFF) - Private bucket
   - **File size limit:** 10 MB
   - **Allowed MIME types:** `image/*,application/pdf`
3. Click **Create bucket**

**Set Policies:**

1. Click on the `receipts` bucket
2. Click **Policies** tab
3. Click **New Policy**
4. Choose template: "Enable insert for authenticated users"
5. Click **Review** → **Save policy**
6. Click **New Policy** again
7. Choose template: "Enable read for authenticated users"
8. Click **Review** → **Save policy**

---

## Part 3: Verify Buckets Created

### Check in Dashboard:

1. Go to **Storage** in left sidebar
2. You should see:
   - ✅ avatars (Public)
   - ✅ trip-covers (Public)
   - ✅ receipts (Private)

### Check via SQL (Optional):

```sql
-- See all buckets
SELECT * FROM storage.buckets ORDER BY name;

-- See all policies
SELECT bucket_id, name FROM storage.policies ORDER BY bucket_id;
```

---

## Part 4: Advanced - Create Policies via SQL (Optional)

If you prefer SQL over UI, run this in NEW database SQL Editor:

```sql
-- ============================================================================
-- AVATARS BUCKET POLICIES
-- ============================================================================

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Allow public read access
CREATE POLICY "Public can read avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

-- ============================================================================
-- TRIP-COVERS BUCKET POLICIES
-- ============================================================================

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload trip covers"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'trip-covers');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update trip covers"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'trip-covers');

-- Allow public read access
CREATE POLICY "Public can read trip covers"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'trip-covers');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete trip covers"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'trip-covers');

-- ============================================================================
-- RECEIPTS BUCKET POLICIES (Private)
-- ============================================================================

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts');

-- Allow authenticated users to update
CREATE POLICY "Authenticated users can update receipts"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'receipts');

-- Allow authenticated users to read
CREATE POLICY "Authenticated users can read receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'receipts');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated users can delete receipts"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'receipts');
```

---

## Part 5: Migrate Files (After Buckets Created)

Once buckets are created, you can migrate files:

### Option A: Manual Download/Upload (< 100 files)

**From OLD Database:**
1. Storage → avatars → Select all → Download
2. Save to: `storage_backup/avatars/`
3. Repeat for trip-covers and receipts

**To NEW Database:**
1. Storage → avatars → Upload files
2. Select downloaded files → Upload
3. Repeat for other buckets

### Option B: Supabase CLI (> 100 files)

```bash
# Export from OLD database
supabase login  # Login as palkarfoods224@gmail.com
supabase link --project-ref OLD_PROJECT_REF
supabase storage export avatars ./storage_backup/avatars
supabase storage export trip-covers ./storage_backup/trip-covers
supabase storage export receipts ./storage_backup/receipts

# Import to NEW database
supabase logout
supabase login  # Login as grayprogrammers008@gmail.com
supabase link --project-ref NEW_PROJECT_REF
supabase storage import avatars ./storage_backup/avatars
supabase storage import trip-covers ./storage_backup/trip-covers
supabase storage import receipts ./storage_backup/receipts
```

---

## Troubleshooting

### Problem: "Bucket already exists"
**Solution:** Delete the bucket and try again, or just use the existing one.

### Problem: "Cannot create bucket via SQL"
**Solution:** Correct! Buckets must be created via Dashboard UI or CLI, not SQL.

### Problem: "Policies not working"
**Solution:**
1. Check that RLS is enabled: `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;`
2. Verify policies exist: `SELECT * FROM storage.policies;`
3. Test with authenticated user, not anon key

### Problem: "Files won't upload"
**Solution:**
1. Check file size is under limit
2. Check MIME type is allowed
3. Check insert policy exists
4. Try uploading via Dashboard first

---

## ✅ Checklist

After completing this guide, verify:

- [ ] All buckets created in NEW database
- [ ] Buckets have correct public/private settings
- [ ] Each bucket has policies (insert, select, update, delete)
- [ ] Can upload test file to each bucket via Dashboard
- [ ] Can view uploaded files
- [ ] Ready to migrate actual files from OLD database

---

## Summary

**What you created:**
- ✅ 3 storage buckets (avatars, trip-covers, receipts)
- ✅ Policies for each bucket (read, write, update, delete)
- ✅ Correct public/private settings
- ✅ File size limits and MIME type restrictions

**Next step:** Migrate actual files from OLD to NEW database

---

Need help with any step? Let me know!
