# 🏥 Import Hospitals from South Indian States (100% FREE)

> **Import hospitals from Tamil Nadu, Karnataka, Kerala, and Andhra Pradesh using OpenStreetMap**

This guide will help you import hospital data from all cities across 4 major South Indian states using the **100% FREE** OpenStreetMap Overpass API.

---

## 📊 Expected Results

| State | Major Cities | Estimated Hospitals | Coverage |
|-------|--------------|---------------------|----------|
| **Tamil Nadu** | 30+ cities | 800-1,200 hospitals | Excellent |
| **Karnataka** | 25+ cities | 600-900 hospitals | Excellent |
| **Kerala** | 20+ cities | 400-600 hospitals | Very Good |
| **Andhra Pradesh** | 20+ cities | 500-700 hospitals | Good |
| **TOTAL** | ~95 cities | **2,300-3,400 hospitals** | **FREE!** 🎉 |

---

## 🗺️ State Bounding Boxes

### Tamil Nadu
```
Bounding Box: (8.0, 76.2, 13.5, 80.3)
Area: Covers entire state from Kanyakumari to Chennai
Major Cities: Chennai, Coimbatore, Madurai, Salem, Tiruchirappalli
```

### Karnataka
```
Bounding Box: (11.5, 74.0, 18.5, 78.6)
Area: Covers entire state from Bidar to Bangalore
Major Cities: Bangalore, Mysore, Hubli-Dharwad, Mangalore, Belgaum
```

### Kerala
```
Bounding Box: (8.2, 74.8, 12.8, 77.5)
Area: Covers entire state from Thiruvananthapuram to Kasaragod
Major Cities: Thiruvananthapuram, Kochi, Kozhikode, Thrissur, Kollam
```

### Andhra Pradesh
```
Bounding Box: (12.6, 77.0, 19.9, 84.8)
Area: Covers entire state including Rayalaseema and coastal regions
Major Cities: Visakhapatnam, Vijayawada, Guntur, Nellore, Tirupati
```

---

## 🚀 Quick Import (All States)

### Option 1: Import All States at Once (Recommended for Production)

**Step 1: Create Import Script**

Save this as `import_south_india_hospitals.sh`:

```bash
#!/bin/bash

# South India Hospital Import Script
# Uses OpenStreetMap Overpass API (100% FREE)

OVERPASS_URL="https://overpass-api.de/api/interpreter"

echo "🏥 Starting South India Hospital Import..."
echo "================================================"

# Function to import hospitals from a state
import_state() {
    local state_name=$1
    local bbox=$2
    local output_file="${state_name}_hospitals.json"

    echo ""
    echo "📍 Importing hospitals from $state_name..."

    # Overpass query
    local query="[out:json][timeout:90];
    (
      node[\"amenity\"=\"hospital\"]($bbox);
      way[\"amenity\"=\"hospital\"]($bbox);
      relation[\"amenity\"=\"hospital\"]($bbox);
    );
    out center;
    out tags;"

    # Make API request
    curl -X POST "$OVERPASS_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "data=$query" \
      -o "$output_file" \
      --progress-bar

    if [ $? -eq 0 ]; then
        local count=$(jq '.elements | length' "$output_file" 2>/dev/null || echo "0")
        echo "✅ $state_name: Downloaded $count hospitals"
    else
        echo "❌ $state_name: Failed to download"
    fi

    # Be nice to the API - wait 5 seconds between requests
    sleep 5
}

# Import each state
import_state "tamil_nadu" "8.0,76.2,13.5,80.3"
import_state "karnataka" "11.5,74.0,18.5,78.6"
import_state "kerala" "8.2,74.8,12.8,77.5"
import_state "andhra_pradesh" "12.6,77.0,19.9,84.8"

echo ""
echo "================================================"
echo "✅ Import complete! Check the *_hospitals.json files"
echo ""
echo "Next steps:"
echo "1. Review the JSON files"
echo "2. Use the Flutter import script to load into database"
echo "3. Run: dart run scripts/import_osm_hospitals.dart"
```

**Step 2: Make it executable and run**

```bash
chmod +x import_south_india_hospitals.sh
./import_south_india_hospitals.sh
```

---

### Option 2: Import States One by One

#### Tamil Nadu

```bash
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json][timeout:90];
    (
      node[\"amenity\"=\"hospital\"](8.0,76.2,13.5,80.3);
      way[\"amenity\"=\"hospital\"](8.0,76.2,13.5,80.3);
      relation[\"amenity\"=\"hospital\"](8.0,76.2,13.5,80.3);
    );
    out center;
    out tags;" \
  -o tamil_nadu_hospitals.json
```

**Expected Output:** 800-1,200 hospitals

---

#### Karnataka

```bash
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json][timeout:90];
    (
      node[\"amenity\"=\"hospital\"](11.5,74.0,18.5,78.6);
      way[\"amenity\"=\"hospital\"](11.5,74.0,18.5,78.6);
      relation[\"amenity\"=\"hospital\"](11.5,74.0,18.5,78.6);
    );
    out center;
    out tags;" \
  -o karnataka_hospitals.json
```

**Expected Output:** 600-900 hospitals

---

#### Kerala

```bash
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json][timeout:90];
    (
      node[\"amenity\"=\"hospital\"](8.2,74.8,12.8,77.5);
      way[\"amenity\"=\"hospital\"](8.2,74.8,12.8,77.5);
      relation[\"amenity\"=\"hospital\"](8.2,74.8,12.8,77.5);
    );
    out center;
    out tags;" \
  -o kerala_hospitals.json
```

**Expected Output:** 400-600 hospitals

---

#### Andhra Pradesh

```bash
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json][timeout:90];
    (
      node[\"amenity\"=\"hospital\"](12.6,77.0,19.9,84.8);
      way[\"amenity\"=\"hospital\"](12.6,77.0,19.9,84.8);
      relation[\"amenity\"=\"hospital\"](12.6,77.0,19.9,84.8);
    );
    out center;
    out tags;" \
  -o andhra_pradesh_hospitals.json
```

**Expected Output:** 500-700 hospitals

---

## 💻 Flutter/Dart Import Script

Create `scripts/import_osm_hospitals.dart`:

```dart
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Import OSM hospitals from JSON files into Supabase
void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final supabase = Supabase.instance.client;

  // States to import
  final states = [
    'tamil_nadu',
    'karnataka',
    'kerala',
    'andhra_pradesh',
  ];

  int totalInserted = 0;
  int totalUpdated = 0;
  int totalFailed = 0;

  print('🏥 Starting South India Hospital Import...');
  print('============================================\n');

  for (final state in states) {
    final filename = '${state}_hospitals.json';
    final file = File(filename);

    if (!file.existsSync()) {
      print('⚠️  $state: File not found - $filename');
      continue;
    }

    print('📍 Processing $state...');

    try {
      // Read JSON file
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString);
      final elements = data['elements'] as List;

      print('   Found ${elements.length} hospitals in OSM data');

      // Parse OSM elements
      final hospitals = _parseOSMElements(elements);
      print('   Parsed ${hospitals.length} valid hospitals');

      // Batch import to database
      final result = await supabase.rpc(
        'batch_insert_osm_hospitals',
        params: {'hospitals_json': hospitals},
      ).single();

      final inserted = result['inserted_count'] as int;
      final updated = result['updated_count'] as int;
      final failed = result['failed_count'] as int;

      totalInserted += inserted;
      totalUpdated += updated;
      totalFailed += failed;

      print('   ✅ Inserted: $inserted');
      print('   🔄 Updated: $updated');
      print('   ❌ Failed: $failed\n');

      // Be nice to the database - pause between states
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print('   ❌ Error importing $state: $e\n');
    }
  }

  print('============================================');
  print('📊 Import Summary:');
  print('   Total Inserted: $totalInserted');
  print('   Total Updated: $totalUpdated');
  print('   Total Failed: $totalFailed');
  print('   Total Processed: ${totalInserted + totalUpdated + totalFailed}');
  print('✅ Import complete!\n');

  exit(0);
}

/// Parse OSM elements to hospital format
List<Map<String, dynamic>> _parseOSMElements(List elements) {
  return elements
      .map((element) {
        try {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};

          // Get coordinates
          double? lat, lon;
          if (element['type'] == 'node') {
            lat = element['lat'] as double?;
            lon = element['lon'] as double?;
          } else if (element['center'] != null) {
            lat = element['center']['lat'] as double?;
            lon = element['center']['lon'] as double?;
          }

          if (lat == null || lon == null) return null;

          return {
            'osm_id': element['id'].toString(),
            'osm_type': element['type'] as String,
            'name': tags['name'] ?? 'Unnamed Hospital',
            'phone': tags['phone'] ?? tags['contact:phone'],
            'address': _buildAddress(tags),
            'city': tags['addr:city'] ?? tags['addr:town'],
            'state': tags['addr:state'] ?? tags['addr:province'],
            'postcode': tags['addr:postcode'],
            'latitude': lat,
            'longitude': lon,
            'website': tags['website'] ?? tags['contact:website'],
            'emergency': tags['emergency'],
            'healthcare': tags['healthcare'],
            'beds': tags['beds'] != null ? int.tryParse(tags['beds']) : null,
            'operator': tags['operator'],
            'operator_type': tags['operator:type'],
            'opening_hours': tags['opening_hours'],
            'wheelchair': tags['wheelchair'],
            'specialties': _extractSpecialties(tags),
          };
        } catch (e) {
          print('   ⚠️  Error parsing element: $e');
          return null;
        }
      })
      .whereType<Map<String, dynamic>>()
      .toList();
}

String? _buildAddress(Map<String, dynamic> tags) {
  final parts = <String>[];

  if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber']);
  if (tags['addr:street'] != null) parts.add(tags['addr:street']);
  if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb']);

  return parts.isEmpty ? null : parts.join(', ');
}

List<String>? _extractSpecialties(Map<String, dynamic> tags) {
  final specialties = <String>[];

  // Check various specialty tags
  if (tags['healthcare:speciality'] != null) {
    final spec = tags['healthcare:speciality'] as String;
    specialties.addAll(spec.split(';').map((s) => s.trim()));
  }

  // Add based on other tags
  if (tags['emergency'] == 'yes') specialties.add('Emergency');
  if (tags['healthcare:speciality:intensive_care'] == 'yes') {
    specialties.add('ICU');
  }
  if (tags['healthcare:speciality:cardiac'] == 'yes') {
    specialties.add('Cardiology');
  }

  return specialties.isEmpty ? null : specialties;
}
```

---

## 📋 Step-by-Step Import Process

### Step 1: Download Hospital Data (15-20 minutes)

Run the bash script or cURL commands to download OSM data:

```bash
./import_south_india_hospitals.sh
```

**Expected files:**
- `tamil_nadu_hospitals.json` (~5-8 MB)
- `karnataka_hospitals.json` (~4-6 MB)
- `kerala_hospitals.json` (~3-5 MB)
- `andhra_pradesh_hospitals.json` (~3-5 MB)

---

### Step 2: Review Downloaded Data

Check the data quality:

```bash
# Count hospitals per state
jq '.elements | length' tamil_nadu_hospitals.json
jq '.elements | length' karnataka_hospitals.json
jq '.elements | length' kerala_hospitals.json
jq '.elements | length' andhra_pradesh_hospitals.json

# Preview first hospital
jq '.elements[0]' tamil_nadu_hospitals.json
```

---

### Step 3: Import to Database

**Option A: Using Flutter/Dart Script**

```bash
# Update Supabase credentials in the script
dart run scripts/import_osm_hospitals.dart
```

**Option B: Manual SQL Import (for smaller datasets)**

```sql
-- Example: Import Tamil Nadu hospitals manually
SELECT * FROM batch_insert_osm_hospitals(
  '[...]'::jsonb  -- Paste JSON from file
);
```

---

### Step 4: Verify Import

```sql
-- Check total hospitals
SELECT COUNT(*) FROM hospitals WHERE data_source = 'openstreetmap';

-- Breakdown by state
SELECT state, COUNT(*) as hospital_count
FROM hospitals
WHERE data_source = 'openstreetmap'
GROUP BY state
ORDER BY hospital_count DESC;

-- Check data quality
SELECT
  COUNT(*) as total,
  COUNT(phone) as with_phone,
  COUNT(emergency_phone) as with_emergency_phone,
  COUNT(*) FILTER (WHERE has_emergency = true) as with_emergency_dept,
  COUNT(*) FILTER (WHERE is_24_7 = true) as open_24_7,
  AVG(CASE WHEN beds IS NOT NULL THEN beds ELSE 0 END) as avg_beds
FROM hospitals
WHERE data_source = 'openstreetmap';
```

---

## 🎯 Major Cities Covered

### Tamil Nadu (30+ cities)
- **Tier 1:** Chennai, Coimbatore, Madurai
- **Tier 2:** Salem, Tiruchirappalli, Tirunelveli, Vellore, Erode
- **Tier 3:** Thoothukudi, Dindigul, Thanjavur, Nagercoil, Kanchipuram
- Plus 18+ smaller cities

### Karnataka (25+ cities)
- **Tier 1:** Bangalore, Mysore, Mangalore
- **Tier 2:** Hubli-Dharwad, Belgaum, Gulbarga, Bellary
- **Tier 3:** Tumkur, Shimoga, Davangere, Bijapur, Raichur
- Plus 14+ smaller cities

### Kerala (20+ cities)
- **Tier 1:** Thiruvananthapuram, Kochi, Kozhikode
- **Tier 2:** Thrissur, Kollam, Kannur, Palakkad
- **Tier 3:** Malappuram, Alappuzha, Kottayam, Pathanamthitta
- Plus 9+ smaller cities

### Andhra Pradesh (20+ cities)
- **Tier 1:** Visakhapatnam, Vijayawada, Guntur
- **Tier 2:** Nellore, Tirupati, Rajahmundry, Kakinada
- **Tier 3:** Anantapur, Kurnool, Vizianagaram, Eluru
- Plus 9+ smaller cities

---

## 💰 Cost Analysis

### What You're Getting (100% FREE)

| State | Hospitals | Google Places Cost/Year | OSM Cost |
|-------|-----------|-------------------------|----------|
| Tamil Nadu | ~1,000 | $32,000 | **$0** ✅ |
| Karnataka | ~750 | $24,000 | **$0** ✅ |
| Kerala | ~500 | $16,000 | **$0** ✅ |
| Andhra Pradesh | ~650 | $20,800 | **$0** ✅ |
| **TOTAL** | **~2,900** | **$92,800/year** | **$0** 🎉 |

**Savings:** $92,800/year by using OpenStreetMap! 💰

---

## ⚡ Performance Tips

### 1. Batch Import Optimization

Process states in parallel (if you have good internet):

```bash
# Run all imports simultaneously
./import_tamil_nadu.sh &
./import_karnataka.sh &
./import_kerala.sh &
./import_andhra_pradesh.sh &
wait
```

### 2. Database Optimization

Create indexes before import:

```sql
-- Already created in migration, but verify
SELECT indexname FROM pg_indexes WHERE tablename = 'hospitals';
```

### 3. Cache Strategy

Set up periodic refresh:

```sql
-- Mark OSM hospitals older than 30 days for refresh
SELECT * FROM mark_osm_hospitals_for_sync(30);
```

---

## 🔧 Troubleshooting

### Issue 1: Overpass API Timeout

**Error:** `504 Gateway Timeout`

**Solution:**
- Increase timeout: `[timeout:120]` instead of `[timeout:90]`
- Import smaller regions (district by district)
- Try alternative Overpass endpoints:
  - `https://overpass.openstreetmap.fr/api/interpreter`
  - `https://overpass.kumi.systems/api/interpreter`

### Issue 2: Large File Size

**Error:** JSON files too large (>50 MB)

**Solution:**
- Split state into smaller regions
- Import district by district instead of entire state
- Use streaming JSON parser

### Issue 3: Duplicate Hospitals

**Error:** Same hospital appearing multiple times

**Solution:**
The `upsert_hospital_from_osm()` function handles this automatically:
- Uses `osm_id` + `osm_type` as unique key
- Updates existing records instead of creating duplicates
- No action needed!

---

## 📊 Expected Data Quality

### What You'll Get from OSM

**Coverage:**
- ✅ All major cities: 90-95% coverage
- ✅ Tier 2 cities: 80-90% coverage
- ✅ Tier 3 cities: 60-80% coverage
- ⚠️ Rural areas: 40-60% coverage

**Data Completeness:**
- ✅ Name: 98%
- ✅ Location: 100%
- ✅ Address: 70-80%
- ⚠️ Phone: 40-60%
- ✅ Emergency status: 50-70%
- ⚠️ Bed count: 20-40%

**Recommendation:** OSM provides excellent coverage for urban areas where most travel happens!

---

## 🎉 What's Next After Import

### 1. Verify Coverage

```sql
-- Test nearest hospital search in major cities
SELECT
  name, city, distance_km
FROM find_nearest_hospitals(
  13.0827,  -- Chennai
  80.2707,
  10.0,     -- 10km radius
  10,       -- 10 results
  true,     -- emergency only
  false     -- don't filter 24/7
);
```

### 2. Update App UI

The app already has everything configured! Just:
- Open Emergency page
- Grant location permission
- See all imported hospitals

### 3. Monitor & Maintain

```sql
-- Get statistics
SELECT * FROM get_hospital_statistics();

-- Check OSM data freshness
SELECT
  state,
  COUNT(*) as total,
  MAX(osm_last_sync_at) as last_sync
FROM hospitals
WHERE data_source = 'openstreetmap'
GROUP BY state;
```

---

## 📚 Additional Resources

- **Overpass Turbo (Web UI):** https://overpass-turbo.eu/
- **OSM India Community:** https://openstreetmap.in/
- **OSM Wiki - India:** https://wiki.openstreetmap.org/wiki/India

---

## ✅ Summary

**What You'll Accomplish:**

✅ Import 2,300-3,400 hospitals across 4 states
✅ Cover 95+ major cities in South India
✅ Save $92,800/year vs Google Places API
✅ 100% FREE with no API keys required
✅ Complete coverage for travel app users
✅ Better hospital-specific data (beds, emergency, operator)

**Total Time:** 30-60 minutes for complete import

**Total Cost:** $0.00 🎉

---

**Ready to import 3,000+ hospitals for FREE? Run the script now!** 🚀

```bash
./import_south_india_hospitals.sh
```

---

*Created: 2025-02-02*
*For: Travel Companion App - South India Hospital Coverage*
