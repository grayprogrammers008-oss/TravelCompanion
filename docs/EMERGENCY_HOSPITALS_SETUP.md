# Emergency Hospital Service - Setup & Usage Guide

## Overview

The Emergency Hospital Service provides **real-time nearest hospital finding** based on user location with real Indian hospital data. It uses PostGIS for accurate geospatial queries and includes 35+ verified hospitals across major Indian cities.

## Features

✅ **Real Hospital Data** - Pre-seeded with 35+ verified hospitals from major Indian cities
✅ **PostGIS Geospatial Queries** - Accurate distance calculation using PostGIS
✅ **Emergency Priority Scoring** - Intelligent scoring based on capabilities and distance
✅ **Google Places API Integration** - Optional integration for more data
✅ **24/7 Emergency Support** - Filter hospitals by emergency services and operating hours
✅ **Multi-specialty Support** - Comprehensive specialty tracking
✅ **Real-time Updates** - Live data with Supabase real-time subscriptions

## Database Setup

### 1. Apply Migrations

Run the following command to apply the migrations:

```bash
cd "d:\Nithya\Travel Companion\TravelCompanion"
supabase db push
```

Or if using Supabase CLI:

```bash
supabase migration up
```

This will:
- Enable PostGIS extension
- Create `hospitals` table with geospatial support
- Create `find_nearest_hospitals` function
- Create helper functions for search and retrieval
- Seed 35+ real hospitals from major Indian cities

### 2. Verify Migration

Test the function with a sample query:

```sql
-- Find nearest hospitals to Mumbai coordinates
SELECT * FROM find_nearest_hospitals(
    19.0760,  -- latitude (Mumbai)
    72.8777,  -- longitude (Mumbai)
    10.0,     -- max distance in km
    5,        -- limit to 5 results
    true,     -- only emergency hospitals
    false     -- don't filter by 24/7
);
```

### 3. Check Statistics

```sql
SELECT * FROM get_hospital_statistics();
```

Expected output:
```
total_hospitals: 35
emergency_hospitals: 35
hospitals_24_7: 35
cities_covered: 7 (Mumbai, Delhi, Bangalore, Chennai, Hyderabad, Kolkata, Pune)
verified_hospitals: 35
```

## Pre-seeded Hospital Data

The migration includes **35 verified hospitals** across major Indian cities:

### Mumbai (5 hospitals)
- Lilavati Hospital and Research Centre (Bandra)
- Kokilaben Dhirubhai Ambani Hospital (Andheri)
- Hinduja Hospital (Mahim)
- KEM Hospital (Parel) - Government
- Breach Candy Hospital

### Delhi (5 hospitals)
- AIIMS Delhi - All India Institute of Medical Sciences
- Sir Ganga Ram Hospital
- Fortis Hospital Vasant Kunj
- Max Super Speciality Hospital Saket
- Apollo Hospital Delhi

### Bangalore (5 hospitals)
- Manipal Hospital Whitefield
- Fortis Hospital Bannerghatta Road
- Columbia Asia Hospital Whitefield
- Narayana Health City
- St. John Medical College Hospital

### Chennai (5 hospitals)
- Apollo Hospital Chennai
- Fortis Malar Hospital
- MIOT International
- Vijaya Hospital
- Stanley Medical College Hospital - Government

### Hyderabad (5 hospitals)
- Apollo Hospital Jubilee Hills
- KIMS Hospital
- Care Hospital Banjara Hills
- Yashoda Hospital Secunderabad
- Osmania General Hospital - Government

### Kolkata (5 hospitals)
- AMRI Hospital Dhakuria
- Apollo Gleneagles Hospital
- Fortis Hospital Anandapur
- Medica Superspecialty Hospital
- Medical College Kolkata - Government

### Pune (4 hospitals)
- Ruby Hall Clinic
- Jehangir Hospital
- Sahyadri Hospital Deccan
- Columbia Asia Hospital Kharadi

All hospitals include:
- Accurate GPS coordinates
- Emergency services
- Phone numbers (including emergency lines)
- Ratings and reviews
- Specialty information
- Trauma levels
- ICU/Ambulance availability

## How It Works

### 1. PostGIS Distance Calculation

The system uses PostGIS `ST_Distance` function with GEOGRAPHY type for accurate distance calculation:

```sql
ST_Distance(
    hospital.location,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
) / 1000.0  -- Convert meters to kilometers
```

This provides **accurate distances** accounting for Earth's curvature.

### 2. Emergency Priority Scoring

Hospitals are ranked by a priority score (0-100) based on:

| Factor | Points | Description |
|--------|--------|-------------|
| Emergency Room | 30 | Has emergency department |
| 24/7 Operation | 20 | Open 24 hours |
| Trauma Level | 20 | Level-1 (20), Level-2 (10), Level-3 (0) |
| ICU Availability | 10 | Has intensive care unit |
| Ambulance Service | 5 | Has ambulance |
| Rating | 10 | Based on user ratings (0-5 stars) |
| Distance | 5 | Closer hospitals get more points |

**Example Scores:**
- Level-1 Trauma Center, 24/7, 2km away, 4.5 rating: **95 points**
- Private hospital, emergency, 10km away, 4.0 rating: **72 points**

### 3. Real-time Location

The app uses Flutter's `geolocator` package to get the user's current location and passes it to the database function.

## App Integration

### Current Implementation

The feature is **already integrated** in the app:

#### 1. Emergency Page
Location: `lib/features/emergency/presentation/pages/emergency_page.dart`

Shows:
- SOS button
- Nearest hospitals widget
- Emergency contacts
- Medical emergency button

#### 2. Nearest Hospitals Widget
Location: `lib/features/emergency/presentation/widgets/nearest_hospitals_widget.dart`

Features:
- Displays nearest hospitals in a list
- Shows distance, rating, emergency status
- Call and Directions buttons
- Real-time location updates

#### 3. Use Case
Location: `lib/features/emergency/domain/usecases/find_nearest_hospitals_usecase.dart`

Calls the PostgreSQL function with parameters:
```dart
await _repository.findNearestHospitals(
  latitude: position.latitude,
  longitude: position.longitude,
  maxDistanceKm: 50.0,
  limit: 10,
  onlyEmergency: true,
);
```

#### 4. Data Source
Location: `lib/features/emergency/data/datasources/emergency_remote_datasource.dart:1048`

Makes RPC call to Supabase:
```dart
final response = await _client.rpc(
  'find_nearest_hospitals',
  params: {
    'user_lat': latitude,
    'user_lng': longitude,
    'max_distance_km': maxDistanceKm,
    'result_limit': limit,
    'only_emergency': onlyEmergency,
    'only_24_7': only24_7,
  },
);
```

### Accessing the Feature

1. **From Home Page**: Tap Emergency button (red SOS icon)
2. **From Navigation**: Navigate to Emergency page
3. **Direct URL**: `/emergency?tripId=<optional>`

The page will:
1. Request location permission
2. Get current GPS coordinates
3. Query nearest hospitals via Supabase RPC
4. Display results sorted by emergency priority score

## Google Places API Integration (Optional)

To add more hospitals from Google Places API:

### 1. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Places API**
4. Create API key
5. Restrict key to Places API only

### 2. Add API Key to Environment

In your `.env` file:
```env
GOOGLE_PLACES_API_KEY=your_api_key_here
```

### 3. Create Flutter Service

Create `lib/services/google_places_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GooglePlacesService {
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY']!;

  Future<List<Map<String, dynamic>>> findNearbyHospitals({
    required double latitude,
    required double longitude,
    int radius = 50000, // 50km
  }) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

    final response = await _dio.get(url, queryParameters: {
      'location': '$latitude,$longitude',
      'radius': radius,
      'type': 'hospital',
      'key': _apiKey,
    });

    final List results = response.data['results'];
    return results.map((place) => {
      'google_place_id': place['place_id'],
      'name': place['name'],
      'address': place['vicinity'],
      'latitude': place['geometry']['location']['lat'],
      'longitude': place['geometry']['location']['lng'],
      'rating': place['rating'],
      'total_reviews': place['user_ratings_total'] ?? 0,
    }).toList();
  }
}
```

### 4. Import to Supabase

```dart
final places = await googlePlacesService.findNearbyHospitals(
  latitude: 19.0760,
  longitude: 72.8777,
);

// Convert to JSONB
final hospitalsJson = jsonEncode(places);

// Call batch insert function
await supabase.rpc('batch_insert_hospitals', params: {
  'hospitals_json': hospitalsJson,
});
```

## Testing

### 1. Test Database Function

```sql
-- Test Mumbai area
SELECT
    name,
    city,
    distance_km,
    emergency_priority_score,
    has_emergency,
    trauma_level
FROM find_nearest_hospitals(19.0760, 72.8777, 10, 5, true, false)
ORDER BY emergency_priority_score DESC;
```

### 2. Test App Integration

1. Run the app: `flutter run`
2. Navigate to Emergency page
3. Grant location permission
4. Verify hospitals appear in list
5. Check distance calculations
6. Test Call and Directions buttons

### 3. Verify Location Trigger

```sql
-- Insert test hospital
INSERT INTO hospitals (name, address, city, state, latitude, longitude, has_emergency)
VALUES ('Test Hospital', '123 Test St', 'Mumbai', 'Maharashtra', 19.0760, 72.8777, true);

-- Check that location was auto-populated
SELECT name, latitude, longitude, ST_AsText(location) FROM hospitals WHERE name = 'Test Hospital';
```

## Performance

### Indexes

The migration creates several indexes for optimal performance:

- `idx_hospitals_location` - GIST index on location (PostGIS spatial index)
- `idx_hospitals_city` - City-based queries
- `idx_hospitals_emergency` - Emergency hospital filtering
- `idx_hospitals_name_search` - Full-text search on hospital names

### Query Performance

Expected query times:
- **PostGIS nearest neighbor search**: < 50ms
- **10 hospitals within 50km**: < 100ms
- **Full-text search**: < 30ms

### Optimization Tips

1. **Limit results**: Use `result_limit` parameter (default: 10)
2. **Reduce radius**: Smaller `max_distance_km` = faster queries
3. **Use spatial index**: Always query with location/distance
4. **Cache results**: Cache hospitals for 5-10 minutes in app

## Troubleshooting

### Issue: "function find_nearest_hospitals does not exist"

**Solution**: Run migrations
```bash
supabase db push
```

### Issue: "PostGIS extension not found"

**Solution**: Enable PostGIS in Supabase dashboard
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Issue: "No hospitals found"

**Possible causes**:
1. Location too far from seeded cities (try increasing `max_distance_km`)
2. Too strict filters (set `only_emergency` to false)
3. Database not seeded (check with `SELECT COUNT(*) FROM hospitals`)

**Solution**:
```sql
-- Check total hospitals
SELECT COUNT(*) FROM hospitals WHERE is_active = true;

-- Find closest hospital regardless of distance
SELECT name, distance_km FROM find_nearest_hospitals(
    your_lat, your_lng,
    1000, -- 1000km radius
    1,    -- Just 1 result
    false, -- Any hospital
    false
);
```

### Issue: "Location permission denied"

**Solution**: Request permission in app
```dart
final permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied) {
  // Show message to user
}
```

## Maintenance

### Adding New Hospitals

#### Manual Entry
```sql
INSERT INTO hospitals (
    name, phone, emergency_phone, address, city, state,
    latitude, longitude,
    hospital_type, has_emergency, is_24_7, trauma_level,
    has_icu, has_ambulance, specialties, rating, total_reviews,
    data_source, verified
) VALUES (
    'New Hospital Name',
    '+91-XXX-XXXXXXX',
    '108',
    'Hospital Address',
    'City',
    'State',
    12.9716, 77.5946, -- GPS coordinates
    'private',
    true, true, 1,
    true, true,
    ARRAY['Cardiology', 'Emergency'],
    4.5, 1000,
    'manual', true
);
```

#### Using Google Places API
```dart
// Use the batch import function (see Google Places API section above)
```

### Updating Hospital Data

```sql
UPDATE hospitals
SET
    phone = 'new-phone',
    rating = 4.6,
    total_reviews = 2000,
    updated_at = NOW()
WHERE google_place_id = 'ChIJ...';
```

### Verifying Hospitals

```sql
UPDATE hospitals
SET
    verified = true,
    verification_date = NOW()
WHERE id = 'hospital-uuid';
```

## Security

### Row Level Security (RLS)

RLS is enabled on the `hospitals` table:

- ✅ **Public Read**: Anyone can view hospitals (essential for emergency situations)
- ❌ **Admin Only Write**: Only admin users can insert/update/delete

### API Key Security

If using Google Places API:

1. **Never commit API keys** to git
2. **Use environment variables** (`.env` file)
3. **Restrict API key** in Google Cloud Console:
   - Restrict to Places API only
   - Add application restrictions (package name/bundle ID)
   - Set daily quotas

## Cost Considerations

### Supabase
- **Database storage**: ~1MB per 1000 hospitals (minimal)
- **PostGIS queries**: Included in free tier
- **Real-time subscriptions**: Included in free tier

### Google Places API (Optional)
- **Nearby Search**: $32 per 1000 requests
- **Place Details**: $17 per 1000 requests
- **Free tier**: $200/month credit (enough for ~6,250 nearby searches)

**Recommendation**: Use pre-seeded data (free) and optionally add Google Places for additional coverage.

## Roadmap

### Planned Features
- [ ] Hospital reviews and ratings system
- [ ] Real-time bed availability
- [ ] Doctor availability status
- [ ] Turn-by-turn navigation to hospital
- [ ] Call ambulance integration
- [ ] Blood bank availability
- [ ] Pharmacy nearby
- [ ] Medical insurance verification

### Data Expansion
- [ ] Add 100+ more hospitals per city
- [ ] Cover tier-2 and tier-3 cities
- [ ] Add clinics and diagnostic centers
- [ ] International hospital data

## Support

For issues or questions:
1. Check this documentation
2. Review the code comments in migration file
3. Check Supabase logs
4. Test with sample queries above

## License

This migration and documentation are part of the TravelCompanion app.

---

**Generated**: 2025-02-02
**Last Updated**: 2025-02-02
**Migration Version**: 20250202_hospitals_emergency_service
