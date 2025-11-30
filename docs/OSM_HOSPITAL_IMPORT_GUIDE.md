# 🏥 OpenStreetMap Hospital Import Guide - 100% FREE

> **No API Keys | No Costs | No Credit Card | Unlimited Usage**

This guide shows you how to import hospital data from OpenStreetMap using the **completely free** Overpass API.

---

## 🎯 Why OpenStreetMap?

| Feature | Google Places API | OpenStreetMap Overpass API |
|---------|-------------------|---------------------------|
| **Cost** | Free tier, then paid | **100% FREE Forever** |
| **API Key** | Required | **Not Required** |
| **Rate Limits** | Strict limits | Generous (fair use) |
| **Billing** | Credit card needed | **No billing** |
| **Data Coverage** | Excellent | Very good (community) |
| **Global** | Yes | **Yes** |
| **Ratings** | Yes | No (OSM doesn't have ratings) |

---

## 🚀 Quick Start (3 Steps)

### Step 1: Query Overpass API

Use the Overpass API to get hospital data. No authentication needed!

**Endpoint:** `https://overpass-api.de/api/interpreter`

### Step 2: Get Hospital Data for Your City

**Example: Mumbai Hospitals**

```bash
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json];
    (
      node[\"amenity\"=\"hospital\"](18.8,72.7,19.3,73.1);
      way[\"amenity\"=\"hospital\"](18.8,72.7,19.3,73.1);
      relation[\"amenity\"=\"hospital\"](18.8,72.7,19.3,73.1);
    );
    out center;
    out tags;"
```

**Bounding Box Format:** `(min_lat, min_lon, max_lat, max_lon)`

### Step 3: Import to Your Database

Use our SQL function to import the data:

```sql
SELECT * FROM batch_insert_osm_hospitals(
  '[...]'::jsonb  -- Paste the JSON from Overpass API
);
```

---

## 📋 Complete Examples

### Example 1: Get Hospitals in Bangalore

**Overpass QL Query:**

```overpassql
[out:json][timeout:25];
(
  node["amenity"="hospital"](12.8,77.5,13.1,77.7);
  way["amenity"="hospital"](12.8,77.5,13.1,77.7);
  relation["amenity"="hospital"](12.8,77.5,13.1,77.7);
);
out center;
out tags;
```

**cURL Command:**

```bash
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json][timeout:25];
    (
      node[\"amenity\"=\"hospital\"](12.8,77.5,13.1,77.7);
      way[\"amenity\"=\"hospital\"](12.8,77.5,13.1,77.7);
      relation[\"amenity\"=\"hospital\"](12.8,77.5,13.1,77.7);
    );
    out center;
    out tags;" \
  -o bangalore_hospitals.json
```

---

### Example 2: Get Emergency Hospitals Only

```overpassql
[out:json][timeout:25];
(
  node["amenity"="hospital"]["emergency"="yes"](12.8,77.5,13.1,77.7);
  way["amenity"="hospital"]["emergency"="yes"](12.8,77.5,13.1,77.7);
);
out center;
out tags;
```

---

### Example 3: Get Hospitals with ICU

```overpassql
[out:json][timeout:25];
(
  node["amenity"="hospital"]["healthcare:speciality"~"intensive_care"](12.8,77.5,13.1,77.7);
  way["amenity"="hospital"]["healthcare:speciality"~"intensive_care"](12.8,77.5,13.1,77.7);
);
out center;
out tags;
```

---

## 🌍 Major Indian Cities - Bounding Boxes

### Mumbai
```
Bounding Box: (18.8, 72.7, 19.3, 73.1)
Center: 19.0760° N, 72.8777° E
```

### Delhi
```
Bounding Box: (28.4, 77.0, 28.9, 77.4)
Center: 28.6139° N, 77.2090° E
```

### Bangalore
```
Bounding Box: (12.8, 77.5, 13.1, 77.7)
Center: 12.9716° N, 77.5946° E
```

### Chennai
```
Bounding Box: (12.9, 80.1, 13.2, 80.3)
Center: 13.0827° N, 80.2707° E
```

### Kolkata
```
Bounding Box: (22.4, 88.2, 22.7, 88.5)
Center: 22.5726° N, 88.3639° E
```

### Hyderabad
```
Bounding Box: (17.3, 78.3, 17.5, 78.6)
Center: 17.3850° N, 78.4867° E
```

### Pune
```
Bounding Box: (18.4, 73.7, 18.6, 73.9)
Center: 18.5204° N, 73.8567° E
```

---

## 🛠️ Flutter/Dart Implementation

### Step 1: Create OSM Service

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class OSMHospitalService {
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetch hospitals from OpenStreetMap
  static Future<List<Map<String, dynamic>>> fetchHospitals({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    bool emergencyOnly = false,
  }) async {
    // Build Overpass QL query
    final emergencyFilter = emergencyOnly ? '["emergency"="yes"]' : '';

    final query = '''
[out:json][timeout:25];
(
  node["amenity"="hospital"]$emergencyFilter($minLat,$minLon,$maxLat,$maxLon);
  way["amenity"="hospital"]$emergencyFilter($minLat,$minLon,$maxLat,$maxLon);
  relation["amenity"="hospital"]$emergencyFilter($minLat,$minLon,$maxLat,$maxLon);
);
out center;
out tags;
''';

    try {
      final response = await http.post(
        Uri.parse(overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOSMElements(data['elements'] as List);
      } else {
        throw Exception('Failed to fetch OSM data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching OSM hospitals: $e');
    }
  }

  /// Parse OSM elements to hospital format
  static List<Map<String, dynamic>> _parseOSMElements(List elements) {
    return elements.map((element) {
      final tags = element['tags'] as Map<String, dynamic>? ?? {};

      // Get coordinates
      double? lat, lon;
      if (element['type'] == 'node') {
        lat = element['lat'];
        lon = element['lon'];
      } else if (element['center'] != null) {
        lat = element['center']['lat'];
        lon = element['center']['lon'];
      }

      if (lat == null || lon == null) return null;

      return {
        'osm_id': element['id'].toString(),
        'osm_type': element['type'],
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
    }).whereType<Map<String, dynamic>>().toList();
  }

  static String? _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber']);
    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb']);

    return parts.isEmpty ? null : parts.join(', ');
  }

  static List<String>? _extractSpecialties(Map<String, dynamic> tags) {
    final specialties = <String>[];

    // Check various specialty tags
    if (tags['healthcare:speciality'] != null) {
      final spec = tags['healthcare:speciality'] as String;
      specialties.addAll(spec.split(';').map((s) => s.trim()));
    }

    // Add based on other tags
    if (tags['emergency'] == 'yes') specialties.add('Emergency');
    if (tags['healthcare:speciality:intensive_care'] == 'yes') specialties.add('ICU');
    if (tags['healthcare:speciality:cardiac'] == 'yes') specialties.add('Cardiology');

    return specialties.isEmpty ? null : specialties;
  }
}
```

### Step 2: Import to Supabase

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class HospitalImporter {
  final SupabaseClient supabase;

  HospitalImporter(this.supabase);

  /// Import OSM hospitals to database
  Future<Map<String, int>> importOSMHospitals({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) async {
    // Fetch from OSM
    print('Fetching hospitals from OpenStreetMap...');
    final hospitals = await OSMHospitalService.fetchHospitals(
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
    );

    print('Found ${hospitals.length} hospitals');

    // Import to database using our SQL function
    final result = await supabase.rpc(
      'batch_insert_osm_hospitals',
      params: {'hospitals_json': hospitals},
    ).single();

    return {
      'inserted': result['inserted_count'] as int,
      'updated': result['updated_count'] as int,
      'failed': result['failed_count'] as int,
    };
  }
}
```

### Step 3: Usage Example

```dart
void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final importer = HospitalImporter(Supabase.instance.client);

  // Import hospitals for Mumbai
  print('Importing Mumbai hospitals...');
  final result = await importer.importOSMHospitals(
    minLat: 18.8,
    minLon: 72.7,
    maxLat: 19.3,
    maxLon: 73.1,
  );

  print('Import complete:');
  print('  Inserted: ${result['inserted']}');
  print('  Updated: ${result['updated']}');
  print('  Failed: ${result['failed']}');
}
```

---

## 🔥 Advanced Queries

### Get All Healthcare Facilities (Not Just Hospitals)

```overpassql
[out:json][timeout:25];
(
  node["amenity"~"hospital|clinic|doctors"](18.8,72.7,19.3,73.1);
  way["amenity"~"hospital|clinic|doctors"](18.8,72.7,19.3,73.1);
);
out center;
out tags;
```

### Get Hospitals with Specific Specialties

```overpassql
[out:json][timeout:25];
(
  node["amenity"="hospital"]["healthcare:speciality"~"cardiology|intensive_care"](18.8,72.7,19.3,73.1);
  way["amenity"="hospital"]["healthcare:speciality"~"cardiology|intensive_care"](18.8,72.7,19.3,73.1);
);
out center;
out tags;
```

### Get Government Hospitals Only

```overpassql
[out:json][timeout:25];
(
  node["amenity"="hospital"]["operator:type"="government"](18.8,72.7,19.3,73.1);
  way["amenity"="hospital"]["operator:type"="government"](18.8,72.7,19.3,73.1);
);
out center;
out tags;
```

---

## 📊 OSM Tags Reference

### Common Hospital Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `amenity=hospital` | Main hospital tag | Required |
| `name=*` | Hospital name | "AIIMS Delhi" |
| `emergency=yes/no` | Has emergency services | yes |
| `healthcare=hospital` | Healthcare type | hospital |
| `operator=*` | Hospital operator | "Government of India" |
| `operator:type=*` | Operator type | government, private |
| `beds=*` | Number of beds | 500 |
| `opening_hours=*` | Operating hours | 24/7 |
| `phone=*` | Phone number | +91-11-26588500 |
| `website=*` | Website URL | https://aiims.edu |
| `addr:city=*` | City | Delhi |
| `addr:state=*` | State | Delhi |
| `addr:postcode=*` | Postal code | 110029 |
| `wheelchair=*` | Wheelchair access | yes, no, limited |

### Specialty Tags

| Tag | Specialty |
|-----|-----------|
| `healthcare:speciality=cardiology` | Cardiology |
| `healthcare:speciality=intensive_care` | ICU |
| `healthcare:speciality=emergency` | Emergency |
| `healthcare:speciality=trauma` | Trauma Center |
| `healthcare:speciality=paediatrics` | Pediatrics |
| `healthcare:speciality=orthopaedics` | Orthopedics |

---

## 🎯 Best Practices

### 1. **Use Reasonable Bounding Boxes**
- Don't query entire countries at once
- Limit to cities or regions (50-100 km radius)

### 2. **Cache Results**
- OSM data doesn't change frequently
- Cache for 7-30 days
- Use `mark_osm_hospitals_for_sync()` function

### 3. **Be a Good Citizen**
- Don't hammer the API
- Use reasonable timeouts (25-30 seconds)
- Consider setting up your own Overpass instance for heavy use

### 4. **Handle Missing Data**
- OSM data is community-contributed
- Some fields may be missing
- Provide defaults in your app

### 5. **Verify Critical Data**
- Phone numbers may be outdated
- Always verify emergency contacts
- Use `verified=false` flag for OSM data

---

## 🔄 Keeping Data Fresh

### Option 1: Manual Refresh

```dart
// Refresh Mumbai hospitals monthly
await importer.importOSMHospitals(
  minLat: 18.8,
  minLon: 72.7,
  maxLat: 19.3,
  maxLon: 73.1,
);
```

### Option 2: Mark for Sync

```sql
-- Mark hospitals older than 30 days
SELECT * FROM mark_osm_hospitals_for_sync(30);
```

---

## 🌐 Alternative Overpass Endpoints

If the main endpoint is slow, try these mirrors:

1. **Main:** `https://overpass-api.de/api/interpreter`
2. **French:** `https://overpass.openstreetmap.fr/api/interpreter`
3. **Russian:** `https://overpass.kumi.systems/api/interpreter`

---

## 📞 Support & Resources

### Official Documentation
- **Overpass API Guide:** https://wiki.openstreetmap.org/wiki/Overpass_API
- **Overpass Turbo (Web UI):** https://overpass-turbo.eu/
- **OSM Wiki - Hospitals:** https://wiki.openstreetmap.org/wiki/Tag:amenity%3Dhospital

### Community
- **OSM Help Forum:** https://help.openstreetmap.org/
- **OSM India Community:** https://openstreetmap.in/

---

## ✅ Comparison: Sample Data Quality

**Google Places:**
```json
{
  "name": "Lilavati Hospital",
  "rating": 4.5,
  "total_reviews": 2800,
  "phone": "+91-22-26567891"
}
```

**OpenStreetMap:**
```json
{
  "name": "Lilavati Hospital and Research Centre",
  "emergency": "yes",
  "beds": 600,
  "operator": "Lilavati Hospital Trust",
  "operator:type": "private",
  "opening_hours": "24/7",
  "phone": "+91-22-26567891",
  "website": "https://lilavatihospital.com"
}
```

**Verdict:** OSM has more operational details, Google has user ratings.

---

## 🎉 You're All Set!

You now have a **completely FREE** hospital data import system with:

- ✅ No API keys needed
- ✅ No costs ever
- ✅ Unlimited usage (fair use)
- ✅ Global coverage
- ✅ Community-maintained data

**Happy mapping! 🗺️**
