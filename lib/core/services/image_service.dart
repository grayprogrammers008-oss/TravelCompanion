import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'google_places_service.dart';

/// Service for fetching destination images from Google Places API
///
/// Features:
/// - Fetches real destination images from Google Places
/// - Caches image URLs to reduce API calls
/// - Falls back to gradients on error
class ImageService {
  // Cache duration (7 days)
  static const Duration _cacheDuration = Duration(days: 7);

  // Singleton pattern
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Google Places service
  final GooglePlacesService _placesService = GooglePlacesService();

  // In-memory cache
  final Map<String, CachedImage> _memoryCache = {};

  /// Get image URL for a destination using Google Places
  /// Returns null if API fails (caller should fallback to gradient)
  Future<String?> getDestinationImage(String destination) async {
    debugPrint('🌍 [ImageService] getDestinationImage called for: "$destination"');

    try {
      // Check in-memory cache first
      if (_memoryCache.containsKey(destination)) {
        final cached = _memoryCache[destination]!;
        if (!cached.isExpired) {
          debugPrint('📦 [ImageService] Memory cache HIT for: $destination');
          return cached.url;
        } else {
          debugPrint('📦 [ImageService] Memory cache EXPIRED for: $destination');
          _memoryCache.remove(destination);
        }
      }

      // Check persistent cache
      debugPrint('💾 [ImageService] Checking disk cache for: $destination');
      final cachedUrl = await _getCachedUrl(destination);
      if (cachedUrl != null) {
        // Add to memory cache
        _memoryCache[destination] = CachedImage(
          url: cachedUrl,
          cachedAt: DateTime.now(),
        );
        debugPrint('💾 [ImageService] Disk cache HIT for: $destination');
        return cachedUrl;
      }
      debugPrint('💾 [ImageService] Disk cache MISS for: $destination');

      // Fetch from Google Places API
      debugPrint('🌐 [ImageService] Fetching from Google Places API...');
      final url = await _fetchFromGooglePlaces(destination);
      if (url != null) {
        // Cache the result
        await _cacheUrl(destination, url);
        _memoryCache[destination] = CachedImage(
          url: url,
          cachedAt: DateTime.now(),
        );
        debugPrint('✅ [ImageService] Got and cached URL for: $destination');
      } else {
        debugPrint('⚠️ [ImageService] No URL returned for: $destination');
      }

      return url;
    } catch (e, stackTrace) {
      debugPrint('❌ [ImageService] Error fetching image for $destination: $e');
      debugPrint('❌ [ImageService] Stack: $stackTrace');
      return null; // Fallback to gradient
    }
  }

  /// Fetch image from Google Places API
  Future<String?> _fetchFromGooglePlaces(String destination) async {
    try {
      debugPrint('🔍 [ImageService] Searching Google Places for: "$destination"');

      // Search for the destination
      final predictions = await _placesService.getAutocomplete(
        query: destination,
        types: '(cities)',
      );

      debugPrint('🔍 [ImageService] Cities search returned ${predictions.length} results');

      List<PlacePrediction> allPredictions = List.from(predictions);

      if (predictions.isEmpty) {
        // Try without type restriction
        debugPrint('🔍 [ImageService] Trying search without type restriction...');
        final morePredictions = await _placesService.getAutocomplete(
          query: destination,
        );
        debugPrint('🔍 [ImageService] General search returned ${morePredictions.length} results');

        if (morePredictions.isEmpty) {
          debugPrint('⚠️ [ImageService] No places found for: $destination');
          return null;
        }
        allPredictions.addAll(morePredictions);
      }

      // Get the first prediction's place details
      final placeId = allPredictions.first.placeId;
      debugPrint('🔍 [ImageService] Getting details for placeId: $placeId');

      final details = await _placesService.getPlaceDetails(placeId: placeId);

      if (details == null) {
        debugPrint('⚠️ [ImageService] No details returned for: $destination');
        return null;
      }

      debugPrint('🔍 [ImageService] Place details: ${details.name}, photos: ${details.photos.length}');

      if (details.photos.isEmpty) {
        debugPrint('⚠️ [ImageService] No photos found for: $destination');
        return null;
      }

      // Get photo URL from the first photo
      final photoUrl = _placesService.getPhotoUrl(
        photoReference: details.photos.first.photoReference,
        maxWidth: 800,
      );

      debugPrint('📸 [ImageService] Got image URL for $destination: ${photoUrl.substring(0, 80)}...');

      return photoUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ [ImageService] Google Places API call failed: $e');
      debugPrint('❌ [ImageService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Cache image URL in SharedPreferences
  Future<void> _cacheUrl(String destination, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(destination);

      final cacheData = json.encode({
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString(cacheKey, cacheData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to cache image URL: $e');
      }
    }
  }

  /// Get cached image URL from SharedPreferences
  Future<String?> _getCachedUrl(String destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(destination);

      final cacheData = prefs.getString(cacheKey);
      if (cacheData == null) return null;

      final data = json.decode(cacheData) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(data['cachedAt'] as String);

      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) < _cacheDuration) {
        return data['url'] as String;
      } else {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to read cached image URL: $e');
      }
      return null;
    }
  }

  /// Generate cache key for destination
  String _getCacheKey(String destination) {
    // Use MD5 hash for consistent key naming
    final bytes = utf8.encode(destination.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return 'destination_image_$digest';
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove all destination image cache keys
      for (final key in keys) {
        if (key.startsWith('destination_image_')) {
          await prefs.remove(key);
        }
      }

      // Clear memory cache
      _memoryCache.clear();

      if (kDebugMode) {
        debugPrint('✅ Image cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear cache: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _placesService.dispose();
  }
}

/// Cached image data
class CachedImage {
  final String url;
  final DateTime cachedAt;

  CachedImage({required this.url, required this.cachedAt});

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > const Duration(days: 7);
  }
}
