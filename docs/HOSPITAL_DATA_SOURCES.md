# 🏥 Hospital Data Sources - Complete Guide

## 🎯 Quick Comparison

| Source | Cost | API Key | Data Quality | Best For |
|--------|------|---------|--------------|----------|
| **Manual Entry** | 🆓 FREE | ❌ No | ⭐⭐⭐⭐⭐ Perfect | Small datasets |
| **OpenStreetMap** | 🆓 FREE | ❌ No | ⭐⭐⭐⭐ Very Good | **Recommended!** |
| **Google Places** | 💰 $$$$ | ✅ Yes | ⭐⭐⭐⭐⭐ Excellent | When budget allows |

---

## 1️⃣ Manual Entry (Pre-seeded)

### ✅ What You Have Now

**35 verified hospitals** across 7 major Indian cities:
- Mumbai (5)
- Delhi (5)
- Bangalore (5)
- Chennai (5)
- Hyderabad (5)
- Kolkata (5)
- Pune (4)

### ✨ Features

- ✅ Hand-picked major hospitals
- ✅ Verified phone numbers
- ✅ Accurate locations
- ✅ Complete specialty information
- ✅ Emergency capabilities verified
- ✅ Ready to use immediately

### 📊 Coverage

**Great for:**
- Quick start and MVP
- Major city coverage
- Testing and development

**Limitations:**
- Only 35 hospitals
- Limited to 7 cities
- Manual updates needed

---

## 2️⃣ OpenStreetMap (Recommended!) ⭐

### 💰 Cost: $0 Forever

**100% FREE - No API keys, no billing, no credit card!**

### ✨ Features

#### What You Get
- ✅ **Unlimited hospital data** worldwide
- ✅ **No API keys** required
- ✅ **No costs** ever
- ✅ **Hospital-specific details:**
  - Bed counts (total, ICU, emergency)
  - Emergency department status
  - Operator type (government/private)
  - Wheelchair accessibility
  - Opening hours (24/7 status)
  - Department and specialties
- ✅ **Community-maintained** and up-to-date
- ✅ **Open data license** (ODbL)
- ✅ **Offline-friendly** (cache freely)

#### What's Missing
- ❌ User ratings (Google-specific)
- ❌ User reviews (Google-specific)
- ⚠️ Data completeness varies by region

### 📈 Coverage in India

| Region | Coverage | Quality |
|--------|----------|---------|
| **Major Cities** | ⭐⭐⭐⭐⭐ | Excellent |
| **Tier 2 Cities** | ⭐⭐⭐⭐ | Very Good |
| **Tier 3 Cities** | ⭐⭐⭐ | Good |
| **Rural Areas** | ⭐⭐⭐ | Moderate |

**Verdict:** Excellent for urban areas where most travel happens!

### 🚀 How to Use

#### Step 1: Query Overpass API (FREE!)

```bash
# Example: Get all hospitals in Mumbai
curl -X POST "https://overpass-api.de/api/interpreter" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "data=[out:json];
    (
      node[\"amenity\"=\"hospital\"](18.8,72.7,19.3,73.1);
      way[\"amenity\"=\"hospital\"](18.8,72.7,19.3,73.1);
    );
    out center;
    out tags;" \
  -o mumbai_hospitals.json
```

#### Step 2: Import to Database

```dart
// Parse OSM data and import
final hospitals = parseOSMData(jsonResponse);
await supabase.rpc('batch_insert_osm_hospitals', params: {
  'hospitals_json': hospitals,
});
```

### 📖 Documentation

- **Complete Guide:** [OSM_HOSPITAL_IMPORT_GUIDE.md](OSM_HOSPITAL_IMPORT_GUIDE.md)
- **Migration:** `supabase/migrations/20250202_openstreetmap_integration.sql`
- **API Docs:** https://wiki.openstreetmap.org/wiki/Overpass_API

### 💡 Pro Tips

1. **Cache for 7-30 days** - OSM data doesn't change frequently
2. **Import city by city** - Better than entire country at once
3. **Verify critical data** - Phone numbers may need verification
4. **Use bounding boxes** - More efficient than radius queries

---

## 3️⃣ Google Places API (Premium Option)

### 💰 Cost: $$$$ Expensive

| Usage | Monthly Cost |
|-------|--------------|
| 1,000 requests | $17-$32 |
| 10,000 requests | $170-$320 |
| 50,000 requests | **$850-$1,600** |
| 100,000 requests | **$1,700-$3,200** |

**Free tier:** $200/month credit (runs out quickly!)

### ✨ Features

#### What You Get
- ✅ **User ratings** (1-5 stars)
- ✅ **User reviews** and photos
- ✅ **Popular times** (crowd density)
- ✅ **Business-verified data**
- ✅ **Global coverage** (excellent everywhere)
- ✅ **Real-time updates** from businesses
- ✅ **Opening hours** (verified)
- ✅ **Commercial data** (pricing info)

#### What's Missing
- ❌ Bed counts
- ❌ Detailed emergency capabilities
- ❌ Operator information
- 💰 **Very expensive!**

### 📊 When to Use Google Places

✅ **Use Google Places if:**
- You have budget ($500+/month)
- User ratings are critical
- You need business-verified data only
- Popular times feature is essential
- Your users trust Google brands

❌ **Don't use Google Places if:**
- Budget is limited
- Building MVP/startup
- Need detailed hospital infrastructure data
- Offline functionality is important

### 🚀 How to Use

#### Setup

1. Get API key from Google Cloud Console
2. Enable Places API
3. Set up billing (credit card required)
4. Add API key to your app

#### Import Hospitals

```dart
final places = await PlacesService.nearbySearch(
  location: LatLng(19.0760, 72.8777),
  radius: 5000,
  type: 'hospital',
);

await supabase.rpc('batch_insert_google_hospitals', params: {
  'hospitals_json': places,
});
```

### 📖 Documentation

- **Migration:** `supabase/migrations/20250202_google_places_integration.sql`
- **Setup Guide:** [EMERGENCY_HOSPITALS_SETUP.md](EMERGENCY_HOSPITALS_SETUP.md)
- **Google Docs:** https://developers.google.com/maps/documentation/places

---

## 🏆 Recommendation Matrix

### Scenario 1: Startup / MVP

**Use:** ✅ **OpenStreetMap**

**Why:**
- $0 cost (save $29,400/year!)
- No API keys hassle
- Excellent hospital data
- Perfect for India

**Start With:**
1. Pre-seeded 35 hospitals (already done!)
2. Import top 20 cities from OSM (FREE!)
3. Add Google later if revenue allows

---

### Scenario 2: Established App with Budget

**Use:** ✅ **Hybrid (OSM + Google)**

**Strategy:**
1. Use OSM for bulk data (FREE)
2. Add Google ratings selectively
3. Best of both worlds!

**Implementation:**
```dart
// Get hospitals from OSM (FREE)
final hospitals = await getOSMHospitals();

// Enrich top 100 with Google ratings (controlled cost)
await enrichWithGoogleRatings(hospitals.take(100));
```

**Cost Savings:** 90% reduction!

---

### Scenario 3: Enterprise with Large Budget

**Use:** ✅ **Google Places**

**Why:**
- Need business-verified data only
- User ratings critical
- Budget allows ($2,000+/month)
- Global consistent coverage

---

## 📊 Real-World Cost Example

**Scenario:** Travel app with 10,000 active users
- Each user checks hospitals 5 times/month
- Total: 50,000 requests/month

### Option A: Google Places Only
```
50,000 Nearby Search × $17/1K = $850
50,000 Place Details × $32/1K = $1,600
Total: $2,450/month = $29,400/year
```

### Option B: OpenStreetMap Only
```
50,000 Overpass API requests × $0 = $0
Total: $0/month = $0/year
Savings: $29,400/year! 🎉
```

### Option C: Hybrid (Recommended)
```
50,000 OSM requests × $0 = $0
500 Google enrichments × $32/1K = $16
Total: $16/month = $192/year
Savings: $29,208/year! 💰
```

---

## 🎯 Implementation Roadmap

### Phase 1: Launch (Week 1)
✅ Use pre-seeded 35 hospitals
✅ Test with real users
✅ Gather feedback

**Cost:** $0

### Phase 2: Expansion (Week 2-4)
✅ Import top 20 Indian cities from OSM
✅ Add 500-1000 hospitals (FREE!)
✅ Cover 80% of use cases

**Cost:** $0

### Phase 3: Enhancement (Month 2+)
🔄 Optionally add Google ratings
🔄 Only for frequently viewed hospitals
🔄 Keep costs under $50/month

**Cost:** $0-$50/month

### Total Savings vs Google-Only
**$29,400/year → $0-$600/year = 98% savings!**

---

## 🛠️ Database Functions Available

### OpenStreetMap Functions

```sql
-- Import single hospital from OSM
upsert_hospital_from_osm(...)

-- Batch import from OSM
batch_insert_osm_hospitals(hospitals_json)

-- Get hospitals in bounding box
get_osm_hospitals_in_bbox(min_lat, min_lon, max_lat, max_lon)

-- Mark for sync refresh
mark_osm_hospitals_for_sync(days_old)

-- Parse OSM address
extract_location_from_osm_address(address_json)
```

### Google Places Functions

```sql
-- Import single hospital from Google
upsert_hospital_from_google_places(...)

-- Batch import from Google
batch_insert_google_hospitals(hospitals_json)
```

### Universal Functions

```sql
-- Find nearest (works with all sources)
find_nearest_hospitals(lat, lng, max_distance_km, limit)

-- Search by name
search_hospitals(search_term, city, state)

-- Get statistics
get_hospital_statistics()
```

---

## 📚 Quick Start Guides

1. **[HOSPITAL_SERVICE_QUICK_START.md](../HOSPITAL_SERVICE_QUICK_START.md)**
   - 5-minute setup
   - Test the system
   - Basic usage

2. **[OSM_HOSPITAL_IMPORT_GUIDE.md](OSM_HOSPITAL_IMPORT_GUIDE.md)**
   - Complete OSM integration
   - Flutter code examples
   - City bounding boxes

3. **[OSM_VS_GOOGLE_COMPARISON.md](../OSM_VS_GOOGLE_COMPARISON.md)**
   - Detailed comparison
   - Cost analysis
   - Decision framework

4. **[EMERGENCY_HOSPITALS_SETUP.md](EMERGENCY_HOSPITALS_SETUP.md)**
   - Google Places setup
   - Advanced features
   - Production deployment

---

## 🎉 Conclusion

### 🏆 Winner: OpenStreetMap

**For 95% of use cases, OpenStreetMap is the clear winner:**

✅ **$0 cost** - No API keys, no billing, no surprises
✅ **Better hospital data** - Beds, emergency, operator info
✅ **Perfect for India** - Excellent coverage in cities
✅ **Offline-friendly** - Cache and use without internet
✅ **No legal restrictions** - Open data license

**Start with OSM, add Google later only if revenue justifies the cost.**

---

## 📞 Support

- **OSM Questions:** https://help.openstreetmap.org/
- **Google Places:** https://developers.google.com/maps/support
- **Our Docs:** See links above

---

**🚀 Ready to import FREE hospital data? Start with [OSM_HOSPITAL_IMPORT_GUIDE.md](OSM_HOSPITAL_IMPORT_GUIDE.md)!**

---

*Last Updated: 2025-02-02*
*Created for Travel Companion App*
