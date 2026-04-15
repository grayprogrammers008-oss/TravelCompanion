-- ============================================================================
-- EXPORT STORAGE POLICIES FROM OLD DATABASE
-- ============================================================================
--
-- PURPOSE: Export storage bucket policies from OLD database to recreate in NEW
--
-- HOW TO USE:
-- STEP 1: Run this in OLD Supabase (palkarfoods224@gmail.com) SQL Editor
-- STEP 2: Copy the output
-- STEP 3: Save as IMPORT_STORAGE_POLICIES.sql
-- STEP 4: Run in NEW Supabase (grayprogrammers008@gmail.com)
--
-- ============================================================================

-- ============================================================================
-- SECTION 1: INSPECT OLD DATABASE STORAGE
-- ============================================================================

SELECT '-- ============================================================================' as export_script;
SELECT '-- STORAGE MIGRATION SCRIPT' as export_script;
SELECT '-- Generated from OLD database storage configuration' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '' as export_script;

-- ============================================================================
-- SECTION 2: BUCKET INFORMATION
-- ============================================================================

SELECT '-- ============================================================================' as export_script;
SELECT '-- BUCKETS IN OLD DATABASE' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '' as export_script;

SELECT format(
    '-- Bucket: %s | Public: %s | Size Limit: %s MB | MIME Types: %s',
    id,
    CASE WHEN public THEN 'Yes' ELSE 'No' END,
    COALESCE((file_size_limit / 1024.0 / 1024.0)::text, 'No limit'),
    COALESCE(array_to_string(allowed_mime_types, ', '), 'All types')
) as export_script
FROM storage.buckets
ORDER BY created_at;

SELECT '' as export_script;

-- ============================================================================
-- SECTION 3: FILE COUNT PER BUCKET
-- ============================================================================

SELECT '-- ============================================================================' as export_script;
SELECT '-- FILE STATISTICS' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '' as export_script;

SELECT format(
    '-- Bucket: %s | Files: %s | Total Size: %s MB',
    bucket_id,
    COUNT(*)::text,
    ROUND(COALESCE(SUM((metadata->>'size')::bigint) / 1024.0 / 1024.0, 0), 2)::text
) as export_script
FROM storage.objects
GROUP BY bucket_id
ORDER BY bucket_id;

SELECT '' as export_script;

-- ============================================================================
-- SECTION 4: STORAGE POLICIES (CREATE POLICY STATEMENTS)
-- ============================================================================

SELECT '-- ============================================================================' as export_script;
SELECT '-- STORAGE POLICIES - Run these in NEW database' as export_script;
SELECT '-- IMPORTANT: Create buckets FIRST via Dashboard UI, THEN run these policies' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '' as export_script;

-- Generate CREATE POLICY statements for all existing policies
SELECT format(
    E'CREATE POLICY "%s"\nON storage.objects\nFOR %s\nTO %s\n%s%s;\n',
    name,
    UPPER(COALESCE(command, 'ALL')),
    COALESCE(roles::text, 'public'),
    CASE WHEN qual IS NOT NULL THEN 'USING (' || qual || E')\n' ELSE '' END,
    CASE WHEN with_check IS NOT NULL THEN 'WITH CHECK (' || with_check || ')' ELSE '' END
) as export_script
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
ORDER BY policyname;

-- Alternative simpler format if the above doesn't work
SELECT '' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '-- ALTERNATIVE: Simplified Policy Recreation' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '' as export_script;

-- For each bucket, create standard policies
SELECT format(
    E'-- Policies for bucket: %s\n' ||
    E'CREATE POLICY "Authenticated users can upload to %s"\n' ||
    E'ON storage.objects FOR INSERT\n' ||
    E'TO authenticated\n' ||
    E'WITH CHECK (bucket_id = %L);\n\n' ||
    E'CREATE POLICY "Authenticated users can update in %s"\n' ||
    E'ON storage.objects FOR UPDATE\n' ||
    E'TO authenticated\n' ||
    E'USING (bucket_id = %L);\n\n' ||
    E'CREATE POLICY "Authenticated users can delete from %s"\n' ||
    E'ON storage.objects FOR DELETE\n' ||
    E'TO authenticated\n' ||
    E'USING (bucket_id = %L);\n\n' ||
    E'CREATE POLICY "%s to %s"\n' ||
    E'ON storage.objects FOR SELECT\n' ||
    E'TO %s\n' ||
    E'USING (bucket_id = %L);\n',
    id,
    id, id,
    id, id,
    id, id,
    CASE WHEN public THEN 'Public can read' ELSE 'Authenticated users can read' END, id,
    CASE WHEN public THEN 'public' ELSE 'authenticated' END,
    id
) as export_script
FROM storage.buckets
ORDER BY created_at;

SELECT '' as export_script;

-- ============================================================================
-- SECTION 5: BUCKET CONFIGURATION SUMMARY
-- ============================================================================

SELECT '-- ============================================================================' as export_script;
SELECT '-- MANUAL BUCKET CREATION INSTRUCTIONS (Do this FIRST in Dashboard)' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '' as export_script;

SELECT format(
    E'/*\nBucket: %s\n- Public: %s\n- File size limit: %s MB\n- Allowed MIME types: %s\n- Files to migrate: %s files\n*/\n',
    b.id,
    CASE WHEN b.public THEN 'Yes' ELSE 'No' END,
    COALESCE((b.file_size_limit / 1024.0 / 1024.0)::text, 'Unlimited'),
    COALESCE(array_to_string(b.allowed_mime_types, ', '), 'All types'),
    COALESCE(file_counts.count::text, '0')
) as export_script
FROM storage.buckets b
LEFT JOIN (
    SELECT bucket_id, COUNT(*) as count
    FROM storage.objects
    GROUP BY bucket_id
) file_counts ON b.id = file_counts.bucket_id
ORDER BY b.created_at;

SELECT '' as export_script;
SELECT '-- ============================================================================' as export_script;
SELECT '-- EXPORT COMPLETE!' as export_script;
SELECT '-- Next steps:' as export_script;
SELECT '-- 1. Copy all output above' as export_script;
SELECT '-- 2. Save as IMPORT_STORAGE_POLICIES.sql' as export_script;
SELECT '-- 3. Create buckets manually in NEW database Dashboard' as export_script;
SELECT '-- 4. Run IMPORT_STORAGE_POLICIES.sql in NEW database' as export_script;
SELECT '-- ============================================================================' as export_script;
