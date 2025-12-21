import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_places_service.dart';

/// Service for caching Google Places data in Supabase
///
/// Minimizes API calls by storing place details locally
/// Reduces costs and improves performance for repeated searches
class PlaceCacheService {
  final SupabaseClient _supabase;
  final GooglePlacesService _placesService;

  PlaceCacheService({
    SupabaseClient? supabase,
    GooglePlacesService? placesService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _placesService = placesService ?? GooglePlacesService();

  /// Get place details - first checks cache, then fetches from Google Places
  ///
  /// Returns cached data if available, otherwise fetches from API and caches
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    debugPrint('🔍 [PlaceCacheService] getPlaceDetails called for: $placeId');

    // First, try to get from cache
    final cached = await _getFromCache(placeId);
    if (cached != null) {
      debugPrint('📦 [PlaceCacheService] Place loaded from cache: ${cached.name}');
      debugPrint('📦 [PlaceCacheService] Cached photos count: ${cached.photos.length}');
      return cached;
    }

    debugPrint('📦 [PlaceCacheService] Not in cache, fetching from Google Places API...');

    // Not in cache, fetch from Google Places API
    final details = await _placesService.getPlaceDetails(placeId: placeId);
    if (details != null) {
      debugPrint('✅ [PlaceCacheService] Got details from API: ${details.name}');
      debugPrint('✅ [PlaceCacheService] Photos count: ${details.photos.length}');
      if (details.photos.isNotEmpty) {
        debugPrint('✅ [PlaceCacheService] First photo reference: ${details.photos.first.photoReference.substring(0, 50)}...');
      }
      // Save to cache
      await _saveToCache(details);
      debugPrint('💾 [PlaceCacheService] Place cached: ${details.name}');
    } else {
      debugPrint('⚠️ [PlaceCacheService] No details returned from API for: $placeId');
    }

    return details;
  }

  /// Search places - first checks cache, then uses Google Places
  Future<List<PlacePrediction>> searchPlaces({
    required String query,
    String? types,
    String? components,
  }) async {
    // First search in cache
    final cachedResults = await _searchCache(query);
    if (cachedResults.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📦 Found ${cachedResults.length} places in cache for "$query"');
      }
      // Convert cached results to predictions format
      // But still fetch from Google for fresh autocomplete suggestions
    }

    // Always fetch from Google for autocomplete (free with $200 credit)
    return _placesService.getAutocomplete(
      query: query,
      types: types,
      components: components,
    );
  }

  /// Get photo URL for a place
  ///
  /// Returns the photo URL using the photo reference
  String? getPhotoUrl(String placeId, {int maxWidth = 400}) {
    // Note: Photo URLs are generated dynamically and don't need caching
    // The photo reference is stored in cache
    return null; // Will be implemented when we have photo reference
  }

  /// Get photo URL from photo reference
  String getPhotoUrlFromReference(String photoReference, {int maxWidth = 400}) {
    return _placesService.getPhotoUrl(
      photoReference: photoReference,
      maxWidth: maxWidth,
    );
  }

  /// Get cached place by place_id
  Future<PlaceDetails?> _getFromCache(String placeId) async {
    try {
      debugPrint('📦 [PlaceCacheService] Checking Supabase cache for: $placeId');
      final response = await _supabase
          .rpc('get_place_from_cache', params: {'p_place_id': placeId});

      if (response != null && (response as List).isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        debugPrint('📦 [PlaceCacheService] Found in Supabase cache');
        return _mapCachedToPlaceDetails(data);
      }
      debugPrint('📦 [PlaceCacheService] Not found in Supabase cache');
      return null;
    } catch (e) {
      debugPrint('❌ [PlaceCacheService] Cache read error: $e');
      return null;
    }
  }

  /// Save place details to cache
  Future<void> _saveToCache(PlaceDetails details) async {
    try {
      await _supabase.rpc('upsert_place_cache', params: {
        'p_place_id': details.placeId,
        'p_name': details.name,
        'p_formatted_address': details.formattedAddress,
        'p_latitude': details.latitude,
        'p_longitude': details.longitude,
        'p_city': details.city,
        'p_state': details.state,
        'p_country': details.country,
        'p_country_code': details.countryCode,
        'p_types': details.types,
        'p_photo_references': details.photos
            .take(5)
            .map((p) => p.photoReference)
            .toList(),
        'p_website': details.website,
        'p_google_maps_url': details.url,
        'p_rating': details.rating,
        'p_user_ratings_total': details.userRatingsTotal,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cache write error: $e');
      }
    }
  }

  /// Search places in cache
  Future<List<CachedPlace>> _searchCache(String query) async {
    try {
      final response = await _supabase.rpc('search_cached_places', params: {
        'p_query': query,
        'p_limit': 10,
      });

      if (response != null) {
        return (response as List)
            .map((data) => CachedPlace.fromJson(data as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cache search error: $e');
      }
      return [];
    }
  }

  /// Convert cached data to PlaceDetails
  PlaceDetails _mapCachedToPlaceDetails(Map<String, dynamic> data) {
    final photoRefs = (data['photo_references'] as List?)?.cast<String>() ?? [];

    return PlaceDetails(
      placeId: data['place_id'] as String,
      name: data['name'] as String,
      formattedAddress: data['formatted_address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      photos: photoRefs
          .map((ref) => PlacePhoto(
                photoReference: ref,
                width: 0,
                height: 0,
                htmlAttributions: [],
              ))
          .toList(),
      types: (data['types'] as List?)?.cast<String>() ?? [],
      website: data['website'] as String?,
      url: data['google_maps_url'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      userRatingsTotal: data['user_ratings_total'] as int?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      countryCode: data['country_code'] as String?,
    );
  }

  /// Clear local cache in the service (not Supabase)
  void clearLocalCache() {
    _placesService.clearCache();
  }

  /// Dispose resources
  void dispose() {
    _placesService.dispose();
  }
}

/// Simplified cached place for search results
class CachedPlace {
  final String placeId;
  final String name;
  final String? city;
  final String? state;
  final String? country;
  final List<String> types;
  final double? latitude;
  final double? longitude;

  const CachedPlace({
    required this.placeId,
    required this.name,
    this.city,
    this.state,
    this.country,
    required this.types,
    this.latitude,
    this.longitude,
  });

  factory CachedPlace.fromJson(Map<String, dynamic> json) {
    return CachedPlace(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      types: (json['types'] as List?)?.cast<String>() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /// Get display name
  String get displayName {
    final parts = <String>[name];
    if (city != null && city != name) parts.add(city!);
    if (state != null && state != city) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  /// Convert to PlacePrediction for UI compatibility
  PlacePrediction toPrediction() {
    return PlacePrediction(
      placeId: placeId,
      description: displayName,
      mainText: name,
      secondaryText: [city, state, country]
          .where((s) => s != null && s != name)
          .join(', '),
      types: types,
    );
  }
}
