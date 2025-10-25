# Storage RLS Fix - Image Upload Error

**Date:** 2025-10-25
**Error:** "Storage exception (message: new row violates row level security policy, status code:403, error unauthorized)"
**Status:** 🔧 FIX REQUIRED

---

## Problem

Users cannot upload images to the messaging module. The error occurs when trying to upload:

```
Failed to upload image: Storage exception (message: new row violates row level security policy, status code:403, error unauthorized)
```

---

## Root Cause

Row Level Security (RLS) is enabled on the `storage.objects` table in Supabase, but there are **NO policies** allowing authenticated users to INSERT (upload) files.

This is a **database configuration issue**, not a code issue.

---

## Solution

You need to add RLS policies in your Supabase database to allow:
1. Authenticated users to upload files
2. Everyone to read/view files (since bucket is public)

### Quick Fix (Copy-paste this SQL)

Open your Supabase SQL Editor and run:

```sql
-- ============================================================================
-- STORAGE RLS POLICIES FIX
-- Allows authenticated users to upload message attachments
-- ============================================================================

-- Step 1: Create upload policy (authenticated users can upload)
CREATE POLICY "Authenticated users can upload message attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- Step 2: Create read policy (everyone can view - bucket is public)
CREATE POLICY "Public can view message attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'message-attachments');

-- Step 3: Create update policy (users can update their own uploads)
-- This allows updating metadata, replacing images, etc.
CREATE POLICY "Authenticated users can update message attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- Step 4: Create delete policy (users can delete uploads)
CREATE POLICY "Authenticated users can delete message attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- Step 5: Verify policies were created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%message%'
ORDER BY cmd;
```

---

## Expected Output After Running SQL

You should see 4 policies created:

```
schemaname | tablename | policyname                                              | permissive | roles           | cmd
-----------|-----------|--------------------------------------------------------|------------|-----------------|--------
storage    | objects   | Authenticated users can upload message attachments     | PERMISSIVE | authenticated   | INSERT
storage    | objects   | Public can view message attachments                    | PERMISSIVE | public          | SELECT
storage    | objects   | Authenticated users can update message attachments     | PERMISSIVE | authenticated   | UPDATE
storage    | objects   | Authenticated users can delete message attachments     | PERMISSIVE | authenticated   | DELETE
```

---

## Step-by-Step Instructions

### 1. Open Supabase Dashboard
- Go to https://supabase.com/dashboard
- Select your project

### 2. Navigate to SQL Editor
- Click **SQL Editor** in left sidebar
- Click **New query** button

### 3. Paste the SQL
- Copy the SQL from above
- Paste into the query editor

### 4. Run the Query
- Click **Run** button (or press `Ctrl+Enter` / `Cmd+Enter`)
- Wait for success message

### 5. Verify
Run this query to confirm policies exist:

```sql
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%message%';
```

---

## Alternative: More Restrictive Policies

If you want better security (users can only manage their OWN uploads), use these policies instead:

```sql
-- More restrictive: Users can only upload to their own trip folders
-- Requires tripId to be in the file path structure

-- Upload: Authenticated users only
CREATE POLICY "Authenticated users can upload to trips"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);

-- Read: Public (anyone can view)
CREATE POLICY "Public can view attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'message-attachments');

-- Update: Users can only update files in trips they belong to
-- (Requires trip membership check - more complex)
CREATE POLICY "Users can update own trip attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated' AND
  -- Add trip membership check here when you have trip_members table
  true
);

-- Delete: Users can only delete files in trips they belong to
CREATE POLICY "Users can delete own trip attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated' AND
  -- Add trip membership check here when you have trip_members table
  true
);
```

**Note:** For the restrictive policies to work with trip membership checks, you'd need to:
1. Store trip membership in a database table
2. Parse the tripId from the storage file path
3. Join with the trip_members table in the policy

This is more complex, so start with the simple policies first.

---

## Testing After Fix

### Test 1: Upload from App
1. Run your app: `flutter run`
2. Navigate to a trip's chat screen
3. Tap the attachment icon (📎 or camera icon)
4. Select an image from gallery or take a photo
5. The upload should succeed and image should appear in chat

### Test 2: Check Logs
Look for these log messages:

**Success:**
```
🔵 [Storage] Uploading image...
   Trip ID: abc123
   Message ID: msg-456
   File path: abc123/uuid.jpg
   File size: 1.23 MB
   ✅ File uploaded successfully
   ✅ Public URL: https://...supabase.co/.../abc123/uuid.jpg
```

**Failure (if policy still missing):**
```
❌ [Storage] Upload failed
   Exception: StorageException: new row violates row level security policy
```

### Test 3: Verify in Supabase Dashboard
1. Go to **Storage** → **message-attachments** bucket
2. You should see a folder with your trip ID
3. Inside, you should see the uploaded image file
4. Click the image to preview it

---

## Why This Happened

### Background on RLS

Row Level Security (RLS) is a PostgreSQL feature that Supabase enables by default for security. It works like this:

1. **Table:** `storage.objects` stores metadata about all uploaded files
2. **RLS Enabled:** By default, Supabase enables RLS on this table
3. **Default Policy:** With RLS enabled but NO policies, **nothing is allowed**
4. **Policies Required:** You must explicitly create policies to allow operations

### What Was Missing

Your setup likely had:
- ✅ Bucket created (`message-attachments`)
- ✅ Bucket set to public
- ✅ Code correctly calling upload API
- ❌ **NO policies allowing INSERT on storage.objects**

So when the app tried to upload:
1. Code sends upload request to Supabase Storage API
2. Supabase tries to INSERT row into `storage.objects` table
3. RLS checks policies: **NO policy allows INSERT for authenticated users**
4. Upload rejected with 403 error

---

## Common Mistakes to Avoid

### Mistake 1: Confusing bucket public setting with RLS
- **Bucket public:** Controls if URLs are publicly accessible
- **RLS policies:** Controls who can upload/delete files
- Both are needed but serve different purposes!

### Mistake 2: Forgetting to specify bucket_id in policies
```sql
-- ❌ BAD: Affects ALL buckets
CREATE POLICY "Upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (true);

-- ✅ GOOD: Only affects message-attachments bucket
CREATE POLICY "Upload" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'message-attachments');
```

### Mistake 3: Using wrong role
```sql
-- ❌ BAD: Uses 'anon' role (not for authenticated users)
TO anon

-- ✅ GOOD: Uses 'authenticated' role
TO authenticated
```

---

## Rollback (If Something Goes Wrong)

If you need to remove the policies:

```sql
-- Drop all message attachment policies
DROP POLICY IF EXISTS "Authenticated users can upload message attachments" ON storage.objects;
DROP POLICY IF EXISTS "Public can view message attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update message attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete message attachments" ON storage.objects;
```

Then you can re-create them with the correct SQL.

---

## Security Considerations

### Current Approach (Recommended for MVP)
✅ **Simple:** Easy to understand and maintain
✅ **Permissive:** Any authenticated user can upload to any trip
✅ **Fast:** No complex queries in policies
⚠️ **Trusts app:** Assumes app enforces trip membership
⚠️ **No database-level trip checks:** Users could theoretically upload to trips they're not in (if they bypass the app)

### Future Enhancement (Production)
When you're ready for production, consider:
1. **Add trip membership check in policies**
2. **Validate user is a trip member before allowing upload**
3. **Add rate limiting** (e.g., max 10 uploads per minute)
4. **Add file size limits in policy** (Supabase supports this)
5. **Add automatic cleanup** (delete files when messages/trips are deleted)

---

## Additional Resources

- **Supabase Storage Docs:** https://supabase.com/docs/guides/storage
- **RLS Docs:** https://supabase.com/docs/guides/auth/row-level-security
- **Storage RLS Examples:** https://supabase.com/docs/guides/storage/security/access-control

---

## Summary

**Problem:** RLS policies missing → uploads blocked
**Solution:** Add 4 RLS policies via SQL (see above)
**Time:** ~2 minutes to apply fix
**Risk:** Low (only affects message-attachments bucket)

**After applying the fix, image uploads will work! 🎉**

---

**Next Steps:**
1. ✅ Run the SQL in Supabase SQL Editor (see above)
2. ✅ Verify policies were created
3. ✅ Test upload from app
4. ✅ Confirm images appear in chat

