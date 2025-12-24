import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Google Places API Service
///
/// Provides autocomplete, place details, and place photos functionality
/// Uses platform-specific API keys for iOS and Android
/// Includes usage tracking to stay within budget limits
class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  // Platform-specific API keys
  static const String _iosApiKey = 'AIzaSyD158eJBqNAV7n5dA857dtEhEu2OGatg5U';
  static const String _androidApiKey = 'AIzaSyCIcICfzyNy3-ACvBO8oPvtcX9LNGUZUUI';

  // ============================================================
  // BUDGET CONTROL - Using Google's FREE monthly tiers
  // ============================================================
  // Google Places API Free Tiers (as of March 2025):
  // - Autocomplete (Essentials): 10,000 free/month
  // - Place Details (Essentials): 10,000 free/month
  // - Place Photos (Enterprise): 1,000 free/month
  // - Nearby Search (Essentials): 10,000 free/month
  //
  // Daily limits set to stay within FREE tier:
  static const int _dailyAutocompleteLimit = 300;  // 9,000/month (under 10K free)
  static const int _dailyDetailsLimit = 300;       // 9,000/month (under 10K free)
  static const int _dailyPhotoLimit = 100;         // 3,000/month - increased for better UX
  static const int _dailyNearbyLimit = 50;         // 1,500/month (under 10K free, conservative)
  // Total monthly cost: $0 (all within free tiers!)
  // ============================================================

  // SharedPreferences keys for tracking
  static const String _prefAutocompleteCount = 'places_autocomplete_count';
  static const String _prefDetailsCount = 'places_details_count';
  static const String _prefPhotoCount = 'places_photo_count';
  static const String _prefNearbyCount = 'places_nearby_count';
  static const String _prefLastResetDate = 'places_last_reset_date';

  final http.Client _client;
  final Map<String, List<PlacePrediction>> _autocompleteCache = {};
  final Map<String, PlaceDetails> _detailsCache = {};
  Timer? _debounceTimer;

  // In-memory usage counters (synced with SharedPreferences)
  int _autocompleteCount = 0;
  int _detailsCount = 0;
  int _photoCount = 0;
  int _nearbyCount = 0;
  bool _initialized = false;

  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  /// Initialize usage counters from SharedPreferences
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetDate = prefs.getString(_prefLastResetDate);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Reset counters if it's a new day
      if (lastResetDate != today) {
        await prefs.setInt(_prefAutocompleteCount, 0);
        await prefs.setInt(_prefDetailsCount, 0);
        await prefs.setInt(_prefPhotoCount, 0);
        await prefs.setInt(_prefNearbyCount, 0);
        await prefs.setString(_prefLastResetDate, today);
        _autocompleteCount = 0;
        _detailsCount = 0;
        _photoCount = 0;
        _nearbyCount = 0;
        debugPrint('📊 [PlacesAPI] Daily counters reset for $today');
      } else {
        _autocompleteCount = prefs.getInt(_prefAutocompleteCount) ?? 0;
        _detailsCount = prefs.getInt(_prefDetailsCount) ?? 0;
        _photoCount = prefs.getInt(_prefPhotoCount) ?? 0;
        _nearbyCount = prefs.getInt(_prefNearbyCount) ?? 0;
      }

      _initialized = true;
      debugPrint('📊 [PlacesAPI] Usage: autocomplete=$_autocompleteCount/$_dailyAutocompleteLimit, details=$_detailsCount/$_dailyDetailsLimit, photos=$_photoCount/$_dailyPhotoLimit, nearby=$_nearbyCount/$_dailyNearbyLimit');
    } catch (e) {
      debugPrint('⚠️ [PlacesAPI] Failed to initialize counters: $e');
      _initialized = true; // Continue anyway
    }
  }

  /// Force reset all API counters (for debugging/testing)
  Future<void> resetCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefAutocompleteCount, 0);
      await prefs.setInt(_prefDetailsCount, 0);
      await prefs.setInt(_prefPhotoCount, 0);
      await prefs.setInt(_prefNearbyCount, 0);
      _autocompleteCount = 0;
      _detailsCount = 0;
      _photoCount = 0;
      _nearbyCount = 0;
      debugPrint('🔄 [PlacesAPI] All counters reset manually');
    } catch (e) {
      debugPrint('⚠️ [PlacesAPI] Failed to reset counters: $e');
    }
  }

  /// Increment and persist usage counter
  Future<void> _incrementCounter(String key, int Function() getCount, void Function(int) setCount) async {
    try {
      final newCount = getCount() + 1;
      setCount(newCount);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, newCount);
    } catch (e) {
      debugPrint('⚠️ [PlacesAPI] Failed to save counter: $e');
    }
  }

  /// Check if we can make an autocomplete request
  bool get canMakeAutocompleteRequest => _autocompleteCount < _dailyAutocompleteLimit;

  /// Check if we can make a details request
  bool get canMakeDetailsRequest => _detailsCount < _dailyDetailsLimit;

  /// Check if we can make a photo request
  bool get canMakePhotoRequest => _photoCount < _dailyPhotoLimit;

  /// Check if we can make a nearby search request
  bool get canMakeNearbyRequest => _nearbyCount < _dailyNearbyLimit;

  /// Get current usage stats
  Map<String, dynamic> get usageStats => {
    'autocomplete': {'used': _autocompleteCount, 'limit': _dailyAutocompleteLimit},
    'details': {'used': _detailsCount, 'limit': _dailyDetailsLimit},
    'photos': {'used': _photoCount, 'limit': _dailyPhotoLimit},
    'nearby': {'used': _nearbyCount, 'limit': _dailyNearbyLimit},
  };

  /// Get the appropriate API key for the current platform
  static String get apiKey {
    if (Platform.isIOS) {
      return _iosApiKey;
    } else if (Platform.isAndroid) {
      return _androidApiKey;
    }
    // Fallback for development/testing
    return _iosApiKey;
  }

  /// Search for place predictions (autocomplete)
  ///
  /// [query] - The search text
  /// [types] - Filter by place types (e.g., '(cities)', '(regions)', 'geocode')
  /// [components] - Restrict to country (e.g., 'country:in' for India)
  Future<List<PlacePrediction>> getAutocomplete({
    required String query,
    String? types,
    String? components,
    String? sessionToken,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Initialize usage tracking
    await _ensureInitialized();

    final cacheKey = '$query|$types|$components';

    // Check cache first (doesn't count against quota)
    if (_autocompleteCache.containsKey(cacheKey)) {
      debugPrint('📦 [PlacesAPI] Autocomplete cache hit for: $query');
      return _autocompleteCache[cacheKey]!;
    }

    // Check rate limit
    if (!canMakeAutocompleteRequest) {
      debugPrint('🚫 [PlacesAPI] Daily autocomplete limit reached ($_autocompleteCount/$_dailyAutocompleteLimit)');
      return [];
    }

    try {
      final params = <String, String>{
        'input': query,
        'key': apiKey,
      };

      if (types != null) params['types'] = types;
      if (components != null) params['components'] = components;
      if (sessionToken != null) params['sessiontoken'] = sessionToken;

      final uri = Uri.parse('$_baseUrl/autocomplete/json').replace(
        queryParameters: params,
      );

      final response = await _client.get(uri);

      // Count this request
      await _incrementCounter(
        _prefAutocompleteCount,
        () => _autocompleteCount,
        (v) => _autocompleteCount = v,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String;

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final predictions = (data['predictions'] as List? ?? [])
              .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
              .toList();

          // Cache results
          _autocompleteCache[cacheKey] = predictions;
          debugPrint('✅ [PlacesAPI] Autocomplete: $_autocompleteCount/$_dailyAutocompleteLimit used today');

          return predictions;
        } else {
          if (kDebugMode) {
            debugPrint('Google Places Autocomplete error: $status');
            if (data['error_message'] != null) {
              debugPrint('Error message: ${data['error_message']}');
            }
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          debugPrint('Google Places HTTP error: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Places error: $e');
      }
      return [];
    }
  }

  /// Search with debouncing for real-time typing
  void getAutocompleteDebounced({
    required String query,
    required void Function(List<PlacePrediction> predictions) onResults,
    String? types,
    String? components,
    String? sessionToken,
  }) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      onResults([]);
      return;
    }

    _debounceTimer = Timer(_debounceDelay, () async {
      final results = await getAutocomplete(
        query: query,
        types: types,
        components: components,
        sessionToken: sessionToken,
      );
      onResults(results);
    });
  }

  /// Get detailed information about a place
  Future<PlaceDetails?> getPlaceDetails({
    required String placeId,
    String? sessionToken,
    List<String>? fields,
  }) async {
    debugPrint('🔍 [PlacesAPI] getPlaceDetails called for: $placeId');

    // Initialize usage tracking
    await _ensureInitialized();

    // Check cache first (doesn't count against quota)
    if (_detailsCache.containsKey(placeId)) {
      debugPrint('📦 [PlacesAPI] Details cache hit');
      return _detailsCache[placeId];
    }

    // Check rate limit
    if (!canMakeDetailsRequest) {
      debugPrint('🚫 [PlacesAPI] Daily details limit reached ($_detailsCount/$_dailyDetailsLimit)');
      return null;
    }

    try {
      final defaultFields = [
        'place_id',
        'name',
        'formatted_address',
        'geometry',
        'photos',
        'types',
        'address_components',
        'url',
        'website',
        'rating',
        'user_ratings_total',
      ];

      final params = <String, String>{
        'place_id': placeId,
        'key': apiKey,
        'fields': (fields ?? defaultFields).join(','),
      };

      if (sessionToken != null) params['sessiontoken'] = sessionToken;

      final uri = Uri.parse('$_baseUrl/details/json').replace(
        queryParameters: params,
      );

      debugPrint('🌐 [PlacesAPI] Calling Details API...');

      final response = await _client.get(uri);

      // Count this request
      await _incrementCounter(
        _prefDetailsCount,
        () => _detailsCount,
        (v) => _detailsCount = v,
      );

      debugPrint('🌐 [PlacesAPI] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String;

        debugPrint('🌐 [PlacesAPI] API status: $status');

        if (status == 'OK') {
          final details = PlaceDetails.fromJson(
            data['result'] as Map<String, dynamic>,
          );

          debugPrint('✅ [PlacesAPI] Got place: ${details.name}, Photos: ${details.photos.length}');
          debugPrint('✅ [PlacesAPI] Details: $_detailsCount/$_dailyDetailsLimit used today');

          // Cache result
          _detailsCache[placeId] = details;

          return details;
        } else {
          debugPrint('❌ [PlacesAPI] API error status: $status');
          if (data['error_message'] != null) {
            debugPrint('❌ [PlacesAPI] Error message: ${data['error_message']}');
          }
          return null;
        }
      }
      debugPrint('❌ [PlacesAPI] HTTP error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [PlacesAPI] Exception: $e');
      return null;
    }
  }

  /// Get URL for a place photo
  ///
  /// [photoReference] - Photo reference from place details
  /// [maxWidth] - Maximum width in pixels (1-1600)
  /// [maxHeight] - Maximum height in pixels (1-1600)
  ///
  /// Note: Each time this URL is loaded, it counts as a photo request.
  /// The photo limit is tracked when getPhotoUrlWithTracking is used.
  String getPhotoUrl({
    required String photoReference,
    int maxWidth = 400,
    int? maxHeight,
  }) {
    final params = <String, String>{
      'photoreference': photoReference,
      'key': apiKey,
      'maxwidth': maxWidth.toString(),
    };

    if (maxHeight != null) {
      params['maxheight'] = maxHeight.toString();
    }

    return Uri.parse('$_baseUrl/photo')
        .replace(queryParameters: params)
        .toString();
  }

  /// Get URL for a place photo with usage tracking
  ///
  /// Returns null if daily photo limit is reached.
  /// Use this when you want to enforce the photo budget limit.
  Future<String?> getPhotoUrlWithTracking({
    required String photoReference,
    int maxWidth = 400,
    int? maxHeight,
  }) async {
    await _ensureInitialized();

    if (!canMakePhotoRequest) {
      debugPrint('🚫 [PlacesAPI] Daily photo limit reached ($_photoCount/$_dailyPhotoLimit)');
      return null;
    }

    // Count this request
    await _incrementCounter(
      _prefPhotoCount,
      () => _photoCount,
      (v) => _photoCount = v,
    );

    debugPrint('✅ [PlacesAPI] Photos: $_photoCount/$_dailyPhotoLimit used today');

    return getPhotoUrl(
      photoReference: photoReference,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  /// Search for nearby places
  ///
  /// [rankBy] - 'prominence' (default, by popularity) or 'distance'
  /// Note: When using rankBy=distance, you must specify a type or keyword
  Future<List<NearbyPlace>> searchNearby({
    required double latitude,
    required double longitude,
    int? radius,
    String? type,
    String? keyword,
    String rankBy = 'prominence',
  }) async {
    // Initialize usage tracking
    await _ensureInitialized();

    // Check rate limit
    if (!canMakeNearbyRequest) {
      debugPrint('🚫 [PlacesAPI] Daily nearby limit reached ($_nearbyCount/$_dailyNearbyLimit)');
      return [];
    }

    try {
      final params = <String, String>{
        'location': '$latitude,$longitude',
        'key': apiKey,
      };

      // rankby=distance requires type or keyword, and cannot use radius
      if (rankBy == 'distance' && (type != null || keyword != null)) {
        params['rankby'] = 'distance';
      } else if (radius != null) {
        params['radius'] = radius.toString();
      } else {
        // Default radius if not using rankby=distance
        params['radius'] = '15000'; // 15km default
      }

      if (type != null) params['type'] = type;
      if (keyword != null) params['keyword'] = keyword;

      final uri = Uri.parse('$_baseUrl/nearbysearch/json').replace(
        queryParameters: params,
      );

      debugPrint('🔍 [PlacesAPI] Nearby search: ${uri.toString().substring(0, 100)}...');

      final response = await _client.get(uri);

      // Count this request
      await _incrementCounter(
        _prefNearbyCount,
        () => _nearbyCount,
        (v) => _nearbyCount = v,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String;

        debugPrint('✅ [PlacesAPI] Nearby status: $status, count: ${(data['results'] as List?)?.length ?? 0}');
        debugPrint('✅ [PlacesAPI] Nearby: $_nearbyCount/$_dailyNearbyLimit used today');

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final places = (data['results'] as List? ?? [])
              .map((p) => NearbyPlace.fromJson(p as Map<String, dynamic>))
              .toList();

          // Sort by rating (highest first), then by number of reviews
          places.sort((a, b) {
            // Places with ratings come first
            if (a.rating == null && b.rating == null) return 0;
            if (a.rating == null) return 1;
            if (b.rating == null) return -1;

            // Compare by rating
            final ratingCompare = b.rating!.compareTo(a.rating!);
            if (ratingCompare != 0) return ratingCompare;

            // If ratings are equal, compare by number of reviews
            final aReviews = a.userRatingsTotal ?? 0;
            final bReviews = b.userRatingsTotal ?? 0;
            return bReviews.compareTo(aReviews);
          });

          return places;
        } else {
          debugPrint('⚠️ [PlacesAPI] Nearby search status: $status');
          if (data['error_message'] != null) {
            debugPrint('⚠️ [PlacesAPI] Error: ${data['error_message']}');
          }
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Places Nearby error: $e');
      }
      return [];
    }
  }

  /// Clear all caches
  void clearCache() {
    _autocompleteCache.clear();
    _detailsCache.clear();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _client.close();
  }
}

/// Autocomplete prediction result
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.types,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>? ?? {};

    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structured['main_text'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
      types: (json['types'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Check if this is a city/locality
  bool get isCity => types.any((t) =>
    t == 'locality' ||
    t == 'administrative_area_level_2' ||
    t == 'sublocality'
  );

  /// Check if this is a country
  bool get isCountry => types.contains('country');

  /// Check if this is a region/state
  bool get isRegion => types.any((t) =>
    t == 'administrative_area_level_1' ||
    t == 'administrative_area_level_2'
  );

  /// Get appropriate icon for the place type
  String get typeIcon {
    if (isCountry) return '🌍';
    if (isCity) return '🏙️';
    if (isRegion) return '📍';
    if (types.contains('airport')) return '✈️';
    if (types.contains('natural_feature')) return '🏞️';
    if (types.contains('point_of_interest')) return '📌';
    return '📍';
  }

  @override
  String toString() => description;
}

/// Detailed place information
class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final List<PlacePhoto> photos;
  final List<String> types;
  final String? website;
  final String? url;
  final double? rating;
  final int? userRatingsTotal;
  final String? city;
  final String? state;
  final String? country;
  final String? countryCode;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    required this.photos,
    required this.types,
    this.website,
    this.url,
    this.rating,
    this.userRatingsTotal,
    this.city,
    this.state,
    this.country,
    this.countryCode,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final addressComponents = json['address_components'] as List? ?? [];

    // Extract address components
    String? city;
    String? state;
    String? country;
    String? countryCode;

    for (final component in addressComponents) {
      final types = (component['types'] as List?)?.cast<String>() ?? [];
      final longName = component['long_name'] as String?;
      final shortName = component['short_name'] as String?;

      if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = longName;
      } else if (types.contains('country')) {
        country = longName;
        countryCode = shortName;
      }
    }

    return PlaceDetails(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
      photos: (json['photos'] as List? ?? [])
          .map((p) => PlacePhoto.fromJson(p as Map<String, dynamic>))
          .toList(),
      types: (json['types'] as List?)?.cast<String>() ?? [],
      website: json['website'] as String?,
      url: json['url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      city: city,
      state: state,
      country: country,
      countryCode: countryCode,
    );
  }

  /// Get a short display name
  String get shortName {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null && state != city) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.isEmpty ? name : parts.join(', ');
  }
}

/// Place photo reference
class PlacePhoto {
  final String photoReference;
  final int width;
  final int height;
  final List<String> htmlAttributions;

  const PlacePhoto({
    required this.photoReference,
    required this.width,
    required this.height,
    required this.htmlAttributions,
  });

  factory PlacePhoto.fromJson(Map<String, dynamic> json) {
    return PlacePhoto(
      photoReference: json['photo_reference'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      htmlAttributions: (json['html_attributions'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Nearby place result
class NearbyPlace {
  final String placeId;
  final String name;
  final String? vicinity;
  final double? latitude;
  final double? longitude;
  final List<String> types;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;
  final List<PlacePhoto> photos;

  const NearbyPlace({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.latitude,
    this.longitude,
    required this.types,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
    required this.photos,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final openingHours = json['opening_hours'] as Map<String, dynamic>?;

    return NearbyPlace(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      vicinity: json['vicinity'] as String?,
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
      types: (json['types'] as List?)?.cast<String>() ?? [],
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      openNow: openingHours?['open_now'] as bool?,
      photos: (json['photos'] as List? ?? [])
          .map((p) => PlacePhoto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
