# India Emergency Services Setup Guide

This guide provides step-by-step instructions to set up the India emergency services database for the TravelCompanion app.

## Overview

The emergency services feature includes:
1. **Emergency Numbers** - India-specific emergency contact numbers (Police, Fire, Ambulance, Helplines)
2. **Hospitals Database** - Major hospitals across India with location-based search capabilities

## Prerequisites

- Access to Supabase SQL Editor
- Database created for TravelCompanion project
- Internet connection

---

## Setup Steps

### Step 1: Setup Hospitals Table and Functions

**File**: `hospitals_setup_no_postgis.sql`

**What it does**:
- Creates the `hospitals` table with all necessary fields
- Creates Haversine distance calculation function (no PostGIS required)
- Creates helper functions for finding nearest hospitals
- Enables Row Level Security (RLS)
- Sets up indexes for performance

**Run this script**:
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Create new query
4. Copy and paste contents of `hospitals_setup_no_postgis.sql`
5. Click "Run"

**Expected output**:
```
✓ Table created: hospitals
✓ Function created: haversine_distance
✓ Function created: find_nearest_hospitals
✓ Function created: search_hospitals
✓ Function created: get_hospital_with_distance
✓ Function created: get_hospitals_by_location
✓ Indexes created successfully
✓ RLS policies enabled
```

---

### Step 2: Insert India Hospitals Sample Data

**File**: `india_hospitals_sample_data.sql`

**What it does**:
- Inserts 20 major hospitals across India
- Covers 10 cities: Delhi, Mumbai, Bangalore, Chennai, Kolkata, Hyderabad, Pune, Ahmedabad, Jaipur, Lucknow
- All hospitals have emergency rooms and 24/7 service
- Mix of government and private hospitals

**Run this script**:
1. In Supabase SQL Editor
2. Create new query
3. Copy and paste contents of `india_hospitals_sample_data.sql`
4. Click "Run"

**Expected output**:
```
✓ 20 hospitals inserted successfully
✓ Total India hospitals: 20
✓ Cities covered: 10
```

**Sample hospitals included**:
- AIIMS (Delhi)
- Apollo Hospitals (Multiple cities)
- Fortis Hospitals (Multiple cities)
- Tata Memorial Hospital (Mumbai)
- Manipal Hospital (Bangalore)
- Yashoda Hospital (Hyderabad)
- Ruby Hall Clinic (Pune)
- Sterling Hospital (Ahmedabad)
- And more...

---

### Step 3: Setup Emergency Numbers Table

**File**: `india_emergency_numbers_setup.sql`

**What it does**:
- Creates the `emergency_numbers` table
- Inserts 15 India-specific emergency service numbers
- Creates helper functions for fetching emergency numbers
- Enables RLS for public read access

**Run this script**:
1. In Supabase SQL Editor
2. Create new query
3. Copy and paste contents of `india_emergency_numbers_setup.sql`
4. Click "Run"

**Expected output**:
```
✓ Table created: emergency_numbers
✓ 15 emergency numbers inserted
✓ Helper functions created
✓ RLS policies enabled
```

**Emergency numbers included**:
- **112** - Unified Emergency (Police, Fire, Ambulance)
- **100** - Police
- **101** - Fire Brigade
- **102** - Ambulance
- **108** - Disaster Management
- **1091** - Women Helpline
- **181** - Women Helpline (Domestic Abuse)
- **1098** - Child Helpline
- **9152987821** - Mental Health Helpline
- **14567** - Senior Citizens Helpline
- **182** - Railway Police
- **1073** - Road Accident Emergency
- **1363** - Tourist Helpline
- **1930** - Cyber Crime Helpline
- **1031** - Anti-Corruption Helpline

---

## Verification

After running all scripts, verify the setup:

### Verify Hospitals

```sql
-- Count total hospitals
SELECT COUNT(*) as total_hospitals FROM hospitals WHERE country = 'India';
-- Expected: 20

-- Check hospitals by city
SELECT city, COUNT(*) as hospital_count
FROM hospitals
WHERE country = 'India'
GROUP BY city
ORDER BY hospital_count DESC;

-- Test nearest hospitals function
SELECT * FROM find_nearest_hospitals(
  12.9716,  -- Bangalore latitude
  77.5946,  -- Bangalore longitude
  50.0,     -- max distance in km
  10,       -- limit
  TRUE,     -- only emergency
  FALSE     -- only 24/7
);
```

### Verify Emergency Numbers

```sql
-- Count total emergency numbers
SELECT COUNT(*) as total_numbers FROM emergency_numbers WHERE country = 'IN';
-- Expected: 15

-- Check by service type
SELECT service_type, COUNT(*) as count
FROM emergency_numbers
WHERE country = 'IN'
GROUP BY service_type
ORDER BY count DESC;

-- Test helper function
SELECT * FROM get_all_emergency_numbers('IN');

-- Test get by type
SELECT * FROM get_emergency_numbers_by_type('police', 'IN');
```

---

## Troubleshooting

### Issue: "column 'location' does not exist"

**Solution**: Make sure you're using `hospitals_setup_no_postgis.sql` instead of older PostGIS-based scripts. The non-PostGIS version uses `latitude` and `longitude` columns instead of a `location` column.

### Issue: "function does not exist"

**Solution**: Run the setup scripts in the correct order:
1. `hospitals_setup_no_postgis.sql` (creates functions)
2. `india_hospitals_sample_data.sql` (uses the functions)
3. `india_emergency_numbers_setup.sql` (creates emergency numbers)

### Issue: "permission denied"

**Solution**: Ensure RLS policies are correctly set up. The scripts include RLS policies for public read access.

### Issue: No hospitals returned from search

**Solution**:
1. Verify hospitals exist: `SELECT COUNT(*) FROM hospitals WHERE country = 'India';`
2. Check if latitude/longitude parameters are correct
3. Increase `max_distance_km` parameter if needed

---

## App Integration

Once the database is set up, the Flutter app will automatically:

1. **Fetch Emergency Numbers** from the database via:
   - `EmergencyNumbersProvider` - Gets all emergency numbers
   - `EmergencyNumbersByTypeProvider` - Gets filtered by type

2. **Find Nearest Hospitals** using GPS:
   - `NearestHospitalsWidget` - Automatically gets current location
   - Calls `find_nearest_hospitals` function with user's GPS coordinates
   - Returns hospitals sorted by distance

3. **Display Services**:
   - Emergency Page shows database-driven emergency numbers
   - Nearest Hospitals widget shows location-based results
   - Call and direction features for all hospitals

---

## Database Schema

### hospitals table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR | Hospital name |
| address | VARCHAR | Street address |
| city | VARCHAR | City name |
| state | VARCHAR | State name |
| country | VARCHAR | Country name |
| postal_code | VARCHAR | Postal/ZIP code |
| latitude | DOUBLE PRECISION | GPS latitude |
| longitude | DOUBLE PRECISION | GPS longitude |
| phone_number | VARCHAR | Main phone |
| emergency_phone | VARCHAR | Emergency phone |
| website | VARCHAR | Website URL |
| type | VARCHAR | government/private/clinic |
| capacity | INTEGER | Bed capacity |
| has_emergency_room | BOOLEAN | Has ER? |
| has_trauma_center | BOOLEAN | Has trauma center? |
| trauma_level | INTEGER | 1-4 (1 = highest) |
| is_24_7 | BOOLEAN | 24/7 service? |
| services | JSON | Available services |
| specialties | JSON | Medical specialties |
| rating | DECIMAL | Rating (0-5) |
| is_verified | BOOLEAN | Verified listing? |
| is_active | BOOLEAN | Active? |

### emergency_numbers table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| service_name | VARCHAR | Service name |
| service_type | VARCHAR | police/fire/ambulance/helpline |
| phone_number | VARCHAR | Primary number |
| alternate_number | VARCHAR | Alternate number |
| country | VARCHAR | Country code (IN) |
| state | VARCHAR | State (optional) |
| city | VARCHAR | City (optional) |
| description | TEXT | Service description |
| is_toll_free | BOOLEAN | Toll-free? |
| is_24_7 | BOOLEAN | 24/7 service? |
| languages | JSON | Supported languages |
| icon | VARCHAR | Icon name for UI |
| color | VARCHAR | Color code for UI |
| display_order | INTEGER | Sort order |
| is_active | BOOLEAN | Active? |

---

## API Functions

### Hospitals

```sql
-- Find nearest hospitals
find_nearest_hospitals(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 50.0,
  result_limit INTEGER DEFAULT 10,
  only_emergency BOOLEAN DEFAULT TRUE,
  only_24_7 BOOLEAN DEFAULT FALSE
)

-- Search hospitals by keyword
search_hospitals(
  search_term VARCHAR,
  search_city VARCHAR DEFAULT NULL,
  search_state VARCHAR DEFAULT NULL,
  result_limit INTEGER DEFAULT 20
)

-- Get hospital by ID with distance
get_hospital_with_distance(
  hospital_id UUID,
  user_lat DOUBLE PRECISION DEFAULT NULL,
  user_lng DOUBLE PRECISION DEFAULT NULL
)
```

### Emergency Numbers

```sql
-- Get all emergency numbers for a country
get_all_emergency_numbers(
  p_country VARCHAR DEFAULT 'IN'
)

-- Get emergency numbers by service type
get_emergency_numbers_by_type(
  p_service_type VARCHAR,
  p_country VARCHAR DEFAULT 'IN'
)
```

---

## Next Steps

After successful database setup:

1. ✅ Test the emergency services in the Flutter app
2. ✅ Verify GPS-based hospital search works correctly
3. ✅ Test calling emergency numbers
4. ✅ Test hospital directions feature
5. 📱 Deploy to production

---

## Support

For issues or questions:
- Check the troubleshooting section above
- Review SQL execution logs in Supabase
- Verify RLS policies are correctly applied
- Check that all functions were created successfully

---

**Last Updated**: November 2025
**Version**: 1.0
**Location**: India
**Country Code**: IN
