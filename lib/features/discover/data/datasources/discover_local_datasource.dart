import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/discover_place.dart';
import '../models/discover_place_model.dart';

/// Discover Local Data Source
/// Handles all local Hive operations for offline-first discover places
class DiscoverLocalDataSource {
  static const String _placesBox = 'discover_places';
  static const String _favoritesBox = 'discover_favorites';
  static const String _metadataBox = 'discover_metadata';
  static const String _photoUrlsBox = 'discover_photo_urls';

  // Cache expiry durations
  static const Duration _placesCacheExpiry = Duration(hours: 24);
  static const Duration _photoUrlCacheExpiry = Duration(days: 7);

  // Max cache sizes
  static const int _maxPlacesPerCategory = 100;
  static const int _maxPhotoUrls = 500;

  /// Initialize Hive boxes for discover places
  Future<void> initialize() async {
    try {
      debugPrint('🔵 [DiscoverLocal] Initializing Hive boxes');

      if (!Hive.isBoxOpen(_placesBox)) {
        await Hive.openBox<Map>(_placesBox);
      }
      if (!Hive.isBoxOpen(_favoritesBox)) {
        await Hive.openBox<Map>(_favoritesBox);
      }
      if (!Hive.isBoxOpen(_metadataBox)) {
        await Hive.openBox<Map>(_metadataBox);
      }
      if (!Hive.isBoxOpen(_photoUrlsBox)) {
        await Hive.openBox<String>(_photoUrlsBox);
      }

      debugPrint('✅ [DiscoverLocal] Hive boxes initialized');
    } catch (e) {
      debugPrint('❌ [DiscoverLocal] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Check if discover boxes are available
  bool get isAvailable =>
      Hive.isBoxOpen(_placesBox) &&
      Hive.isBoxOpen(_favoritesBox) &&
      Hive.isBoxOpen(_metadataBox) &&
      Hive.isBoxOpen(_photoUrlsBox);

  /// Get places box (throws if not available)
  Box<Map> get _places {
    if (!Hive.isBoxOpen(_placesBox)) {
      throw StateError('Places box is not open. Call initialize() first.');
    }
    return Hive.box<Map>(_placesBox);
  }

  /// Get favorites box (throws if not available)
  Box<Map> get _favorites {
    if (!Hive.isBoxOpen(_favoritesBox)) {
      throw StateError('Favorites box is not open. Call initialize() first.');
    }
    return Hive.box<Map>(_favoritesBox);
  }

  /// Get metadata box (throws if not available)
  Box<Map> get _metadata {
    if (!Hive.isBoxOpen(_metadataBox)) {
      throw StateError('Metadata box is not open. Call initialize() first.');
    }
    return Hive.box<Map>(_metadataBox);
  }

  /// Get photo URLs box (throws if not available)
  Box<String> get _photoUrls {
    if (!Hive.isBoxOpen(_photoUrlsBox)) {
      throw StateError('Photo URLs box is not open. Call initialize() first.');
    }
    return Hive.box<String>(_photoUrlsBox);
  }

  // ============================================================================
  // PLACES CRUD OPERATIONS
  // ============================================================================

  /// Generate cache key for category-based places
  String _getCategoryCacheKey(PlaceCategory category, double lat, double lng) {
    // Round coordinates to 2 decimal places for cache key (approx 1km precision)
    final roundedLat = (lat * 100).round() / 100;
    final roundedLng = (lng * 100).round() / 100;
    return '${category.name}_${roundedLat}_$roundedLng';
  }

  /// Save places for a category to local cache
  Future<void> savePlaces({
    required PlaceCategory category,
    required List<DiscoverPlace> places,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cacheKey = _getCategoryCacheKey(category, latitude, longitude);
      debugPrint('🔵 [DiscoverLocal] savePlaces: $cacheKey (${places.length} places)');

      // Convert to models and limit size
      final models = places
          .take(_maxPlacesPerCategory)
          .map((p) => DiscoverPlaceModel.fromEntity(p))
          .toList();

      // Save places data
      final placesData = {
        'places': models.map((m) => m.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      await _places.put(cacheKey, placesData);

      // Update metadata
      await _updateMetadata(cacheKey, places.length, latitude, longitude);

      debugPrint('✅ [DiscoverLocal] Places saved for $cacheKey');
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscoverLocal] savePlaces FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get places for a category from local cache
  Future<List<DiscoverPlace>?> getPlaces({
    required PlaceCategory category,
    required double latitude,
    required double longitude,
    bool ignoreExpiry = false,
  }) async {
    try {
      final cacheKey = _getCategoryCacheKey(category, latitude, longitude);
      debugPrint('🔵 [DiscoverLocal] getPlaces: $cacheKey');

      final data = _places.get(cacheKey);
      if (data == null) {
        debugPrint('   ⚠️ No cached data found');
        return null;
      }

      final placesJson = Map<String, dynamic>.from(data);
      final cachedAt = DateTime.parse(placesJson['cached_at'] as String);

      // Check expiry
      if (!ignoreExpiry && DateTime.now().difference(cachedAt) > _placesCacheExpiry) {
        debugPrint('   ⚠️ Cache expired');
        return null;
      }

      // Parse places
      final placesList = (placesJson['places'] as List?)
              ?.map((p) => DiscoverPlaceModel.fromJson(Map<String, dynamic>.from(p)).toEntity())
              .toList() ??
          [];

      debugPrint('   ✅ Retrieved ${placesList.length} places from cache');
      return placesList;
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscoverLocal] getPlaces FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return null;
    }
  }

  /// Check if cache exists and is valid for a category
  Future<bool> hasCachedPlaces({
    required PlaceCategory category,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final cacheKey = _getCategoryCacheKey(category, latitude, longitude);
      final data = _places.get(cacheKey);

      if (data == null) return false;

      final placesJson = Map<String, dynamic>.from(data);
      final cachedAt = DateTime.parse(placesJson['cached_at'] as String);

      return DateTime.now().difference(cachedAt) <= _placesCacheExpiry;
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] hasCachedPlaces error: $e');
      return false;
    }
  }

  // ============================================================================
  // FAVORITES OPERATIONS
  // ============================================================================

  static const String _favoritesKey = 'user_favorites';

  /// Save favorite place IDs
  Future<void> saveFavorites(Set<String> favoriteIds) async {
    try {
      debugPrint('🔵 [DiscoverLocal] saveFavorites: ${favoriteIds.length} favorites');

      await _favorites.put(_favoritesKey, {
        'favorite_ids': favoriteIds.toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ [DiscoverLocal] Favorites saved');
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscoverLocal] saveFavorites FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get favorite place IDs
  Future<Set<String>> getFavorites() async {
    try {
      debugPrint('🔵 [DiscoverLocal] getFavorites');

      final data = _favorites.get(_favoritesKey);
      if (data == null) {
        debugPrint('   ⚠️ No favorites found');
        return {};
      }

      final favoritesJson = Map<String, dynamic>.from(data);
      final favoriteIds = Set<String>.from(favoritesJson['favorite_ids'] ?? []);

      debugPrint('   ✅ Retrieved ${favoriteIds.length} favorites');
      return favoriteIds;
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscoverLocal] getFavorites FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return {};
    }
  }

  /// Add a favorite
  Future<void> addFavorite(String placeId) async {
    try {
      final favorites = await getFavorites();
      favorites.add(placeId);
      await saveFavorites(favorites);
      debugPrint('❤️ [DiscoverLocal] Added favorite: $placeId');
    } catch (e) {
      debugPrint('❌ [DiscoverLocal] addFavorite FAILED: $e');
      rethrow;
    }
  }

  /// Remove a favorite
  Future<void> removeFavorite(String placeId) async {
    try {
      final favorites = await getFavorites();
      favorites.remove(placeId);
      await saveFavorites(favorites);
      debugPrint('💔 [DiscoverLocal] Removed favorite: $placeId');
    } catch (e) {
      debugPrint('❌ [DiscoverLocal] removeFavorite FAILED: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PHOTO URL CACHING
  // ============================================================================

  /// Cache a photo URL for a photo reference
  Future<void> cachePhotoUrl({
    required String photoReference,
    required String url,
  }) async {
    try {
      // Create a key with expiry timestamp
      final cacheKey = 'photo_$photoReference';
      final cacheData = '$url|${DateTime.now().add(_photoUrlCacheExpiry).toIso8601String()}';

      await _photoUrls.put(cacheKey, cacheData);

      // Cleanup if cache is too large
      if (_photoUrls.length > _maxPhotoUrls) {
        await _cleanupPhotoCache();
      }

      debugPrint('📸 [DiscoverLocal] Photo URL cached');
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] cachePhotoUrl error: $e');
      // Don't rethrow - photo caching is not critical
    }
  }

  /// Get cached photo URL
  Future<String?> getCachedPhotoUrl(String photoReference) async {
    try {
      final cacheKey = 'photo_$photoReference';
      final cacheData = _photoUrls.get(cacheKey);

      if (cacheData == null) return null;

      // Parse cache data
      final parts = cacheData.split('|');
      if (parts.length != 2) return null;

      final url = parts[0];
      final expiryStr = parts[1];
      final expiry = DateTime.parse(expiryStr);

      // Check expiry
      if (DateTime.now().isAfter(expiry)) {
        await _photoUrls.delete(cacheKey);
        return null;
      }

      return url;
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] getCachedPhotoUrl error: $e');
      return null;
    }
  }

  /// Cleanup expired photo URLs
  Future<void> _cleanupPhotoCache() async {
    try {
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (final key in _photoUrls.keys) {
        final cacheData = _photoUrls.get(key);
        if (cacheData == null) {
          keysToDelete.add(key);
          continue;
        }

        final parts = cacheData.split('|');
        if (parts.length != 2) {
          keysToDelete.add(key);
          continue;
        }

        try {
          final expiry = DateTime.parse(parts[1]);
          if (now.isAfter(expiry)) {
            keysToDelete.add(key);
          }
        } catch (_) {
          keysToDelete.add(key);
        }
      }

      await _photoUrls.deleteAll(keysToDelete);
      debugPrint('🧹 [DiscoverLocal] Cleaned up ${keysToDelete.length} expired photo URLs');
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] _cleanupPhotoCache error: $e');
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Update metadata for a cache entry
  Future<void> _updateMetadata(
    String cacheKey,
    int itemCount,
    double latitude,
    double longitude,
  ) async {
    try {
      await _metadata.put(cacheKey, {
        'key': cacheKey,
        'cached_at': DateTime.now().toIso8601String(),
        'item_count': itemCount,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] Failed to update metadata: $e');
    }
  }

  /// Get cache metadata for a key
  Future<DiscoverCacheMetadata?> getMetadata(String cacheKey) async {
    try {
      final data = _metadata.get(cacheKey);
      if (data == null) return null;

      return DiscoverCacheMetadata.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] Failed to get metadata: $e');
      return null;
    }
  }

  /// Clear cache for a specific category
  Future<void> clearCategoryCache(PlaceCategory category) async {
    try {
      debugPrint('🔵 [DiscoverLocal] clearCategoryCache: ${category.name}');

      final keysToDelete = <String>[];
      for (final key in _places.keys) {
        if (key.startsWith('${category.name}_')) {
          keysToDelete.add(key);
        }
      }

      await _places.deleteAll(keysToDelete);

      // Also clear metadata
      for (final key in keysToDelete) {
        await _metadata.delete(key);
      }

      debugPrint('   ✅ Cleared ${keysToDelete.length} cache entries');
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscoverLocal] clearCategoryCache FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear all discover cache
  Future<void> clearAllCache() async {
    try {
      debugPrint('🔵 [DiscoverLocal] clearAllCache');

      await _places.clear();
      await _metadata.clear();
      await _photoUrls.clear();
      // Note: Don't clear favorites - user data

      debugPrint('✅ [DiscoverLocal] All cache cleared');
    } catch (e, stackTrace) {
      debugPrint('❌ [DiscoverLocal] clearAllCache FAILED: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return {
        'places_entries': _places.length,
        'favorites_count': (await getFavorites()).length,
        'photo_urls_cached': _photoUrls.length,
        'metadata_entries': _metadata.length,
      };
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] getCacheStats error: $e');
      return {};
    }
  }

  /// Get approximate cache size in bytes
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;

      for (final json in _places.values) {
        totalSize += json.toString().length;
      }
      for (final json in _favorites.values) {
        totalSize += json.toString().length;
      }
      for (final url in _photoUrls.values) {
        totalSize += url.length;
      }

      debugPrint('📊 [DiscoverLocal] Cache size: $totalSize bytes');
      return totalSize;
    } catch (e) {
      debugPrint('⚠️ [DiscoverLocal] getCacheSize error: $e');
      return 0;
    }
  }

  /// Close all Hive boxes
  Future<void> close() async {
    try {
      debugPrint('🔵 [DiscoverLocal] Closing Hive boxes');

      if (Hive.isBoxOpen(_placesBox)) await _places.close();
      if (Hive.isBoxOpen(_favoritesBox)) await _favorites.close();
      if (Hive.isBoxOpen(_metadataBox)) await _metadata.close();
      if (Hive.isBoxOpen(_photoUrlsBox)) await _photoUrls.close();

      debugPrint('✅ [DiscoverLocal] Hive boxes closed');
    } catch (e) {
      debugPrint('❌ [DiscoverLocal] Failed to close boxes: $e');
    }
  }
}
