# Supabase Database Migration Guide

**From:** `palkarfoods224@gmail.com's` Supabase Project
**To:** `grayprogrammers008@gmail.com's` Supabase Project

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Method 1: Using Supabase CLI (Recommended)](#method-1-using-supabase-cli-recommended)
3. [Method 2: Manual Migration via Dashboard](#method-2-manual-migration-via-dashboard)
4. [Method 3: Using pg_dump and psql](#method-3-using-pg_dump-and-psql)
5. [Post-Migration Steps](#post-migration-steps)
6. [Update Application Configuration](#update-application-configuration)

---

## Prerequisites

### Information You'll Need

**From Old Project** (palkarfoods224@gmail.com):
- [ ] Project URL (e.g., `https://xxxxx.supabase.co`)
- [ ] Anon/Public Key
- [ ] Service Role Key (from Settings → API)
- [ ] Database Password
- [ ] Connection String

**For New Project** (grayprogrammers008@gmail.com):
- [ ] Create new project at [supabase.com](https://supabase.com)
- [ ] Note the new Project URL
- [ ] Note the new Anon/Public Key
- [ ] Note the new Service Role Key

---

## Method 1: Using Supabase CLI (Recommended)

### Step 1: Install Supabase CLI

**Windows (PowerShell):**
```powershell
# Using Scoop
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# OR using npm
npm install -g supabase
```

**Verify Installation:**
```bash
supabase --version
```

### Step 2: Login to Supabase

```bash
supabase login
```

This will open a browser to authenticate.

### Step 3: Link to Old Project

```bash
# Navigate to your project directory
cd "d:\Nithya\Travel Companion\TravelCompanion"

# Link to the OLD project
supabase link --project-ref <old-project-ref>
```

**How to find project-ref:**
- Go to old project dashboard
- URL will be: `https://app.supabase.com/project/<project-ref>`
- Copy the `<project-ref>` part

### Step 4: Pull Database Schema and Migrations

```bash
# This will create migration files in supabase/migrations/
supabase db pull
```

### Step 5: Export Data

**Option A: Using pg_dump (Full Export)**
```bash
# Get connection string from old project
# Settings → Database → Connection string

# Export schema + data
pg_dump -h <old-host> -U postgres -d postgres -f backup.sql

# Export only data (no schema)
pg_dump -h <old-host> -U postgres -d postgres --data-only -f data-only.sql
```

**Option B: Export Specific Tables**
```bash
# Export specific table
supabase db dump -f trips_backup.sql --table=trips
```

### Step 6: Switch to New Project

```bash
# Unlink from old project
supabase unlink

# Link to NEW project
supabase link --project-ref <new-project-ref>
```

### Step 7: Push Schema to New Project

```bash
# Push all migrations to new project
supabase db push

# OR apply the backup SQL file
supabase db execute -f backup.sql
```

### Step 8: Export and Import Storage Files

```bash
# This requires using the Supabase API or manual download/upload
# See "Storage Migration" section below
```

---

## Method 2: Manual Migration via Dashboard

### Step 1: Export Schema from Old Project

1. **Login to old project** (palkarfoods224@gmail.com)
2. Go to **SQL Editor**
3. Run this query to generate CREATE TABLE statements:

```sql
-- Get all table definitions
SELECT
    'CREATE TABLE ' || table_name || ' (' ||
    string_agg(
        column_name || ' ' || data_type ||
        CASE WHEN character_maximum_length IS NOT NULL
            THEN '(' || character_maximum_length || ')'
            ELSE ''
        END,
        ', '
    ) || ');'
FROM information_schema.columns
WHERE table_schema = 'public'
GROUP BY table_name;
```

4. Copy all CREATE TABLE statements

### Step 2: Get Table Data

For each table, export data:

```sql
-- Example: Export trips table
SELECT * FROM trips;
```

Click **"Export as CSV"** button for each table.

### Step 3: Export Storage Buckets

1. Go to **Storage** in old project
2. For each bucket:
   - Note the bucket name and settings (public/private)
   - Download all files manually or using Supabase Storage API

### Step 4: Export Auth Users (if needed)

```sql
-- Export users
SELECT * FROM auth.users;

-- Save this as users.csv
```

### Step 5: Import to New Project

1. **Login to new project** (grayprogrammers008@gmail.com)
2. Go to **SQL Editor**
3. Run all CREATE TABLE statements
4. For each table, import CSV:
   - Go to **Table Editor**
   - Select table
   - Click **"Import data from CSV"**
5. Recreate storage buckets and upload files
6. Import auth users (if needed)

---

## Method 3: Using pg_dump and psql

### Step 1: Get Database Credentials

**Old Project:**
1. Settings → Database → Connection Info
2. Copy: Host, Database name, Port, User, Password

**New Project:**
1. Settings → Database → Connection Info
2. Copy the same information

### Step 2: Install PostgreSQL Tools

Download from: https://www.postgresql.org/download/windows/

Or use pgAdmin: https://www.pgadmin.org/download/

### Step 3: Export from Old Database

```bash
# Full backup (schema + data)
pg_dump -h <old-host>.supabase.co -U postgres -d postgres -f travelcompanion_backup.sql

# When prompted, enter the old database password

# OR export specific tables only
pg_dump -h <old-host>.supabase.co -U postgres -d postgres -t public.trips -t public.expenses -f specific_tables.sql
```

### Step 4: Import to New Database

```bash
# Restore full backup
psql -h <new-host>.supabase.co -U postgres -d postgres -f travelcompanion_backup.sql

# When prompted, enter the new database password
```

---

## Storage Migration

### Option 1: Using Supabase Storage API

Create a Node.js script:

```javascript
// migrate-storage.js
const { createClient } = require('@supabase/supabase-js');

// Old project
const oldSupabase = createClient(
  'https://old-project.supabase.co',
  'old-service-role-key'
);

// New project
const newSupabase = createClient(
  'https://new-project.supabase.co',
  'new-service-role-key'
);

async function migrateStorage() {
  // Get list of buckets
  const { data: buckets } = await oldSupabase.storage.listBuckets();

  for (const bucket of buckets) {
    console.log(`Migrating bucket: ${bucket.name}`);

    // Create bucket in new project
    await newSupabase.storage.createBucket(bucket.name, {
      public: bucket.public,
    });

    // List all files in bucket
    const { data: files } = await oldSupabase.storage
      .from(bucket.name)
      .list();

    // Download and upload each file
    for (const file of files) {
      const { data: fileData } = await oldSupabase.storage
        .from(bucket.name)
        .download(file.name);

      await newSupabase.storage
        .from(bucket.name)
        .upload(file.name, fileData);

      console.log(`✓ Migrated: ${file.name}`);
    }
  }

  console.log('✅ Storage migration complete!');
}

migrateStorage();
```

Run:
```bash
npm install @supabase/supabase-js
node migrate-storage.js
```

### Option 2: Manual Download/Upload

1. In old project, go to **Storage**
2. For each bucket:
   - Click bucket name
   - Download all files
3. In new project:
   - Create bucket with same name
   - Upload all downloaded files

---

## Post-Migration Steps

### 1. Verify Data Integrity

Run these queries in both old and new projects:

```sql
-- Check table row counts
SELECT
    schemaname,
    tablename,
    n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Compare totals
SELECT COUNT(*) FROM trips;
SELECT COUNT(*) FROM expenses;
SELECT COUNT(*) FROM checklists;
-- ... etc for all tables
```

### 2. Verify Storage

Check that all storage buckets and files are present in new project.

### 3. Test Row Level Security (RLS)

```sql
-- Check RLS policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public';
```

### 4. Verify Database Functions

```sql
-- List all functions
SELECT
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public';
```

### 5. Check Triggers

```sql
-- List all triggers
SELECT
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```

---

## Update Application Configuration

### Step 1: Update Environment Variables

Create/update `.env` file:

```env
# OLD VALUES (backup)
# OLD_SUPABASE_URL=https://old-project.supabase.co
# OLD_SUPABASE_ANON_KEY=eyJhbGc...old-key

# NEW VALUES
SUPABASE_URL=https://new-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...new-key
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...new-service-key
```

### Step 2: Update Flutter App Configuration

Update `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  // OLD (comment out or remove)
  // static const String supabaseUrl = 'https://old-project.supabase.co';
  // static const String supabaseAnonKey = 'old-anon-key';

  // NEW
  static const String supabaseUrl = 'https://new-project.supabase.co';
  static const String supabaseAnonKey = 'new-anon-key';
}
```

### Step 3: Test the App

1. Run the app in debug mode
2. Test all features:
   - [ ] Authentication (login/signup)
   - [ ] Trip creation and listing
   - [ ] Expense tracking
   - [ ] Checklist management
   - [ ] Image uploads
   - [ ] Real-time updates

### Step 4: Update API Keys in Other Services

If you use Supabase webhooks or external services, update:
- Webhook URLs
- API keys
- Service integrations

---

## Migration Checklist

### Pre-Migration
- [ ] Create new Supabase project
- [ ] Note old project credentials
- [ ] Note new project credentials
- [ ] Install necessary tools (CLI, pg_dump)
- [ ] Backup old project data locally

### Database Migration
- [ ] Export schema (CREATE TABLE statements)
- [ ] Export data (CSV or SQL dump)
- [ ] Export RLS policies
- [ ] Export database functions
- [ ] Export triggers
- [ ] Import schema to new project
- [ ] Import data to new project
- [ ] Verify row counts match

### Storage Migration
- [ ] List all storage buckets
- [ ] Download all files
- [ ] Create buckets in new project
- [ ] Upload all files
- [ ] Verify file counts match

### Auth Migration
- [ ] Export auth users (if needed)
- [ ] Import auth users to new project
- [ ] Test authentication flow

### App Configuration
- [ ] Update `.env` file
- [ ] Update `supabase_config.dart`
- [ ] Update any hardcoded URLs
- [ ] Test app with new project

### Testing
- [ ] Test authentication
- [ ] Test CRUD operations
- [ ] Test file uploads
- [ ] Test real-time subscriptions
- [ ] Test RLS policies
- [ ] Test database functions

### Cleanup
- [ ] Keep old project active for 1-2 weeks as backup
- [ ] Monitor new project for any issues
- [ ] Once verified, archive old project

---

## Troubleshooting

### Issue: "Permission Denied" Errors

**Solution:** Check RLS policies are properly migrated:
```sql
-- In new project, verify policies exist
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

### Issue: Functions Not Working

**Solution:** Re-create functions manually in SQL Editor of new project.

### Issue: Storage Upload Fails

**Solution:** Check bucket permissions:
```sql
-- Make bucket public if needed
UPDATE storage.buckets
SET public = true
WHERE name = 'bucket-name';
```

### Issue: Real-time Not Working

**Solution:** Enable real-time for tables:
1. Go to Database → Replication
2. Enable replication for required tables

---

## Important Notes

⚠️ **Data Integrity:** Always verify data after migration
⚠️ **Downtime:** Plan for 15-30 minutes of downtime during migration
⚠️ **Backup:** Keep old project active for at least 1 week as backup
⚠️ **Test Thoroughly:** Test all app features before going live
⚠️ **API Keys:** Update ALL references to old API keys

---

## Need Help?

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- Migration Guide: https://supabase.com/docs/guides/platform/migrating-and-upgrading-projects

---

**Generated:** 2026-04-06
**For Project:** TravelCompanion
**Migration:** palkarfoods224@gmail.com → grayprogrammers008@gmail.com
