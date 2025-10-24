# Supabase Storage Setup Guide
## Message Attachments Bucket Configuration

This guide explains how to set up the `message-attachments` bucket in Supabase Storage for the messaging module's image attachment functionality.

---

## Quick Setup (Recommended)

### Option 1: Using Supabase Dashboard (Easiest)

1. **Navigate to Storage:**
   - Go to your Supabase project dashboard: https://supabase.com/dashboard
   - Click on **Storage** in the left sidebar
   - Click on the **Storage** tab

2. **Create New Bucket:**
   - Click **"New bucket"** button (top right)
   - Enter the following details:
     - **Name:** `message-attachments`
     - **Public bucket:** Toggle **ON** ✅ (This is IMPORTANT!)
     - **File size limit:** 10 MB (optional, for extra validation)
     - **Allowed MIME types:** Leave empty or specify: `image/jpeg, image/png, image/gif, image/webp`
   - Click **"Create bucket"**

3. **Verify Setup:**
   - You should see `message-attachments` in your buckets list
   - There should be a 🌐 globe icon next to it indicating it's public
   - Click on the bucket to explore (it will be empty initially)

4. **Done!** ✅
   - Your app can now upload images to this bucket
   - Public URLs will work immediately

---

## Option 2: Using SQL Editor (Advanced)

If you prefer SQL or need to automate the setup:

1. **Navigate to SQL Editor:**
   - Go to your Supabase project dashboard
   - Click on **SQL Editor** in the left sidebar
   - Click **"New query"**

2. **Create Bucket:**
   ```sql
   -- Create the message-attachments bucket
   INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
   VALUES (
     'message-attachments',
     'message-attachments',
     true,  -- Public bucket
     10485760,  -- 10 MB in bytes (optional)
     ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']  -- Allowed types (optional)
   );
   ```

3. **Run the Query:**
   - Click **"Run"** or press `Ctrl+Enter` / `Cmd+Enter`
   - You should see: "Success. No rows returned"

4. **Verify:**
   - Go to **Storage** tab
   - Confirm `message-attachments` bucket exists and is public

---

## Option 3: With Row Level Security (RLS) Policies (Production-Recommended)

For better security control, you can set up RLS policies. This requires the bucket to be public OR use authenticated URLs.

### Step 1: Create Bucket (Public)
```sql
-- Create public bucket (same as Option 2)
INSERT INTO storage.buckets (id, name, public)
VALUES ('message-attachments', 'message-attachments', true);
```

### Step 2: Enable RLS on Storage Objects
```sql
-- Enable RLS on the storage.objects table (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

### Step 3: Create Upload Policy (Authenticated Users Only)
```sql
-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload message attachments"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message-attachments' AND
  auth.role() = 'authenticated'
);
```

### Step 4: Create Read Policy (Everyone Can View)
```sql
-- Allow everyone to view images (since bucket is public)
CREATE POLICY "Public can view message attachments"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'message-attachments');
```

### Step 5: Create Update Policy (Optional - Owner Only)
```sql
-- Allow users to update their own uploads
-- (Requires storing user_id in metadata or path structure)
CREATE POLICY "Users can update own attachments"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### Step 6: Create Delete Policy (Optional - Owner Only)
```sql
-- Allow users to delete their own uploads
CREATE POLICY "Users can delete own attachments"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'message-attachments' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

**Note:** The delete/update policies assume your folder structure includes user ID. Currently, the app uses `tripId/uuid.ext`, so these policies may need adjustment.

---

## Verification Steps

### Test 1: Check Bucket Exists
```sql
SELECT * FROM storage.buckets WHERE id = 'message-attachments';
```

**Expected Result:**
```
id                   | name                 | public | created_at
---------------------|----------------------|--------|-------------------
message-attachments  | message-attachments  | true   | 2025-10-24...
```

### Test 2: Check Policies (If Using RLS)
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%message%';
```

### Test 3: Test Upload from App
1. Open your app
2. Navigate to a trip's chat screen
3. Tap the attachment button (📎 icon in message input)
4. Select Camera or Gallery
5. Choose an image
6. Watch for "Uploading image..." dialog
7. Image should appear in chat

### Test 4: Verify in Supabase Dashboard
1. Go to **Storage** → **message-attachments**
2. You should see folders named after trip IDs
3. Inside each folder, UUID-named images
4. Click on an image to preview

---

## Folder Structure

After users start uploading, your bucket will look like this:

```
message-attachments/
├── trip-abc123/
│   ├── a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg
│   ├── b2c3d4e5-f6a7-8901-bcde-f12345678901.png
│   └── c3d4e5f6-a7b8-9012-cdef-123456789012.webp
├── trip-def456/
│   ├── d4e5f6a7-b8c9-0123-defg-234567890123.jpg
│   └── e5f6a7b8-c9d0-1234-efgh-345678901234.gif
└── trip-ghi789/
    └── f6a7b8c9-d0e1-2345-fghi-456789012345.png
```

**Benefits of this structure:**
- Easy to find all images for a specific trip
- UUID filenames prevent naming conflicts
- Can implement trip-based deletion (delete all images when trip is deleted)
- Can implement trip-based RLS policies

---

## Troubleshooting

### Issue: "Bucket not found" error
**Solution:**
- Verify bucket name is exactly `message-attachments` (no typos)
- Check bucket exists in Supabase dashboard
- Ensure Supabase client is initialized in your app

### Issue: Upload fails with 403 Forbidden
**Solutions:**
1. **Bucket not public:** Go to Storage dashboard → Click bucket → Settings → Toggle "Public bucket" ON
2. **RLS blocking:** Check policies with the SQL query above
3. **Auth issue:** Ensure user is authenticated before uploading

### Issue: Image URL returns 404
**Solutions:**
1. **Bucket not public:** Make bucket public in settings
2. **File doesn't exist:** Verify upload succeeded in dashboard
3. **Wrong URL format:** Ensure using `getPublicUrl()` method

### Issue: Upload succeeds but image doesn't display
**Solutions:**
1. **Check URL in message:** Print `attachmentUrl` to debug console
2. **Test URL in browser:** Copy URL and open in browser
3. **Check CORS:** Supabase Storage should handle CORS automatically for public buckets
4. **Cache issue:** Clear app cache or restart app

---

## Security Considerations

### Public Bucket Pros:
✅ Simple setup
✅ No auth required for viewing
✅ Works with cached_network_image
✅ Fast image loading
✅ Easy sharing via URL

### Public Bucket Cons:
❌ Anyone with URL can view image
❌ No access control
❌ URLs can be shared/leaked

### Private Bucket Alternative:
If you need private images:
1. Set bucket to `public: false`
2. Use `createSignedUrl()` instead of `getPublicUrl()`
3. URLs expire after specified duration
4. Requires authentication to access
5. More complex implementation

**For messaging attachments, public buckets are typically fine** since:
- Messages are meant to be seen by trip members
- Trip members can already screenshot/save images
- Signed URLs add complexity for minimal security gain
- You can still use RLS policies to control who can upload/delete

---

## Storage Limits

### Supabase Free Tier:
- **Storage:** 1 GB total
- **Bandwidth:** 2 GB/month
- **File uploads:** Unlimited number
- **File size:** Limited by bucket settings (we set 10 MB)

### Supabase Pro Tier:
- **Storage:** 100 GB included (+ $0.021/GB after)
- **Bandwidth:** 250 GB/month (+ $0.09/GB after)
- **File uploads:** Unlimited
- **File size:** Limited by bucket settings

### App-Level Validation:
Our `ImagePickerService` validates:
- Max file size: 10 MB
- Allowed formats: jpg, jpeg, png, gif, webp
- Image compression: Max 1920x1920, 85% quality

This ensures most images are 200 KB - 2 MB after compression.

---

## Monitoring Usage

### Check Storage Usage:
```sql
-- Total storage used by message-attachments bucket
SELECT
  bucket_id,
  COUNT(*) as file_count,
  pg_size_pretty(SUM(metadata->>'size')::bigint) as total_size
FROM storage.objects
WHERE bucket_id = 'message-attachments'
GROUP BY bucket_id;
```

### Check Recent Uploads:
```sql
-- Recent uploads (last 7 days)
SELECT
  name,
  metadata->>'size' as size_bytes,
  created_at
FROM storage.objects
WHERE
  bucket_id = 'message-attachments' AND
  created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 20;
```

### Check by Trip:
```sql
-- Storage used per trip
SELECT
  split_part(name, '/', 1) as trip_id,
  COUNT(*) as image_count,
  pg_size_pretty(SUM((metadata->>'size')::bigint)) as total_size
FROM storage.objects
WHERE bucket_id = 'message-attachments'
GROUP BY split_part(name, '/', 1)
ORDER BY SUM((metadata->>'size')::bigint) DESC;
```

---

## Cleanup / Maintenance

### Delete All Images for a Trip:
```sql
-- Delete all images for a specific trip
DELETE FROM storage.objects
WHERE
  bucket_id = 'message-attachments' AND
  name LIKE 'trip-abc123/%';
```

### Delete Old Images (e.g., >1 year):
```sql
-- Delete images older than 1 year
DELETE FROM storage.objects
WHERE
  bucket_id = 'message-attachments' AND
  created_at < NOW() - INTERVAL '1 year';
```

### Implement in App:
You can add cleanup logic to:
- Delete trip images when trip is deleted
- Delete message images when message is deleted
- Implement retention policy (auto-delete after X months)

---

## Next Steps After Setup

1. ✅ **Create bucket** (using Option 1 or 2 above)
2. ✅ **Verify** bucket is public and accessible
3. ✅ **Test** upload from your app
4. ✅ **Monitor** initial usage
5. 📋 **Optional:** Set up RLS policies for production
6. 📋 **Optional:** Implement cleanup logic for deleted messages/trips
7. 📋 **Optional:** Set up storage alerts for quota limits

---

## Quick Start Commands

**If you just want to get started quickly, run this in SQL Editor:**

```sql
-- Quick setup: Create public bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('message-attachments', 'message-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Verify it was created
SELECT * FROM storage.buckets WHERE id = 'message-attachments';
```

**Expected Output:**
```
id                   | name                 | public | created_at
---------------------|----------------------|--------|-------------------
message-attachments  | message-attachments  | true   | 2025-10-24 ...
```

**That's it! You're ready to upload images.** 🎉

---

## Support

If you encounter issues:
1. Check Supabase docs: https://supabase.com/docs/guides/storage
2. Check Supabase status: https://status.supabase.com/
3. Review app logs for specific error messages
4. Verify Supabase project is not paused (Free tier pauses after 7 days inactivity)

---

**Last Updated:** 2025-10-24
**Related:** MESSAGING_PHASE1A_ISSUE5_COMPLETE.md
