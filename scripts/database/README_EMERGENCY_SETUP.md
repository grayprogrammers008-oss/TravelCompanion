# Emergency Feature Database Setup

This guide will help you set up the database tables for the Emergency feature in Supabase.

## Prerequisites

- Access to your Supabase project dashboard
- The `trips` table should already exist (referenced in emergency_alerts)
- Basic familiarity with SQL and Supabase

## Database Tables Overview

The Emergency feature requires 3 tables:

1. **emergency_contacts** - Store user's emergency contacts
2. **emergency_alerts** - Track SOS and emergency alerts
3. **location_shares** - Track real-time location sharing sessions

## Setup Instructions

### Option 1: Using Supabase SQL Editor (Recommended)

1. **Open Supabase Dashboard**
   - Go to [https://supabase.com](https://supabase.com)
   - Navigate to your TravelCompanion project

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New query" button

3. **Run the Migration Script**
   - Copy the entire contents of `emergency_schema.sql`
   - Paste into the SQL editor
   - Click "Run" (or press Ctrl+Enter)

4. **Verify Tables Were Created**
   - Navigate to "Table Editor" in the left sidebar
   - You should see 3 new tables:
     - `emergency_contacts`
     - `emergency_alerts`
     - `location_shares`

### Option 2: Using Supabase CLI

```bash
# Make sure you're in the project directory
cd "d:\Nithya\Travel Companion\TravelCompanion"

# Login to Supabase (if not already logged in)
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Run the migration
supabase db push scripts/database/emergency_schema.sql
```

## Verify Setup

After running the migration, verify the following:

### 1. Check Tables Exist

In Supabase Table Editor, you should see:

- ✅ `emergency_contacts` table
- ✅ `emergency_alerts` table
- ✅ `location_shares` table

### 2. Check Row Level Security (RLS)

For each table, verify RLS is enabled:

1. Click on table name → "..." menu → "View policies"
2. Each table should have multiple policies listed

**emergency_contacts** should have:
- Users can view their own emergency contacts
- Users can insert their own emergency contacts
- Users can update their own emergency contacts
- Users can delete their own emergency contacts

**emergency_alerts** should have:
- Users can view their own emergency alerts
- Users can view alerts where they are notified
- Users can insert their own emergency alerts
- Users can update their own emergency alerts
- Notified users can acknowledge alerts

**location_shares** should have:
- Users can view their own location shares
- Users can view location shares shared with them
- Users can insert their own location shares
- Users can update their own location shares
- Users can delete their own location shares

### 3. Check Realtime Subscriptions

1. Go to "Database" → "Replication" in Supabase
2. Verify that `emergency_alerts` and `location_shares` are enabled for realtime

### 4. Test with Sample Data (Optional)

You can insert test data to verify everything works:

```sql
-- Insert a test emergency contact
INSERT INTO emergency_contacts (user_id, name, phone_number, relationship, is_primary)
VALUES (
  auth.uid(),
  'Test Contact',
  '+1234567890',
  'Friend',
  true
);

-- Verify it was inserted
SELECT * FROM emergency_contacts WHERE user_id = auth.uid();
```

## Table Schemas

### emergency_contacts

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Reference to auth.users |
| name | TEXT | Contact name |
| phone_number | TEXT | Contact phone |
| email | TEXT | Contact email (optional) |
| relationship | TEXT | Relationship to user |
| is_primary | BOOLEAN | Primary contact flag |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

### emergency_alerts

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | User who triggered alert |
| trip_id | UUID | Associated trip (optional) |
| type | TEXT | Alert type: sos, help, medical |
| status | TEXT | active, acknowledged, resolved, cancelled |
| message | TEXT | Custom message (optional) |
| latitude | DOUBLE | GPS latitude |
| longitude | DOUBLE | GPS longitude |
| created_at | TIMESTAMPTZ | Alert creation time |
| acknowledged_at | TIMESTAMPTZ | When alert was acknowledged |
| acknowledged_by | UUID | User who acknowledged |
| resolved_at | TIMESTAMPTZ | When alert was resolved |
| notified_contact_ids | UUID[] | Array of notified contacts |
| metadata | JSONB | Additional metadata |

### location_shares

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | User sharing location |
| trip_id | UUID | Associated trip (optional) |
| latitude | DOUBLE | GPS latitude |
| longitude | DOUBLE | GPS longitude |
| accuracy | DOUBLE | Location accuracy (meters) |
| altitude | DOUBLE | Altitude (meters) |
| speed | DOUBLE | Speed (m/s) |
| heading | DOUBLE | Heading (degrees) |
| status | TEXT | active, paused, stopped |
| message | TEXT | Custom message (optional) |
| started_at | TIMESTAMPTZ | When sharing started |
| last_updated_at | TIMESTAMPTZ | Last location update |
| expires_at | TIMESTAMPTZ | When sharing expires (optional) |
| shared_with_contact_ids | UUID[] | Array of users who can view |

## Helper Functions

The migration also creates several helper functions:

- `get_active_location_share(user_id)` - Get user's active location share
- `get_active_alerts(user_id)` - Get user's active alerts
- `get_received_alerts(user_id)` - Get alerts where user is notified

These can be called from your Flutter app via Supabase RPC.

## Troubleshooting

### Error: "relation trips does not exist"

The `emergency_alerts` table references the `trips` table. If you get this error:

1. Make sure the trips table exists first
2. Or comment out the trips reference temporarily:
   ```sql
   -- trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
   trip_id UUID,
   ```

### Error: "permission denied"

Make sure you're authenticated in the SQL editor. You can check by running:
```sql
SELECT auth.uid();
```
If it returns NULL, you need to authenticate first.

### RLS Policies Not Working

If you can't insert/view data:

1. Temporarily disable RLS to test:
   ```sql
   ALTER TABLE emergency_contacts DISABLE ROW LEVEL SECURITY;
   ```
2. Test your queries
3. Re-enable RLS and check policies:
   ```sql
   ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
   ```

## Next Steps

After setting up the database:

1. ✅ Test the Emergency feature in your Flutter app
2. ✅ Try creating emergency contacts
3. ✅ Test location sharing
4. ✅ Test SOS alerts
5. ✅ Verify realtime updates work

## Support

If you encounter any issues:

1. Check the Supabase logs in the Dashboard
2. Review the RLS policies
3. Verify your Supabase credentials in the Flutter app
4. Check that realtime is enabled for the tables

---

**Created:** 2024-01-16
**Last Updated:** 2024-01-16
**Version:** 1.0.0
