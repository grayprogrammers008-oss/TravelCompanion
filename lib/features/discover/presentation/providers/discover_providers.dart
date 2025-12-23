import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/services/google_places_service.dart';
import '../../data/datasources/discover_local_datasource.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/discover_place.dart';

/// Provider for Google Places Service
final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService();
});

/// Provider for Discover Local Data Source (offline caching)
final discoverLocalDataSourceProvider = Provider<DiscoverLocalDataSource>((ref) {
  return DiscoverLocalDataSource();
});

/// Provider for the discover state notifier using Notifier (Riverpod 2.0+)
final discoverStateProvider =
    NotifierProvider<DiscoverStateNotifier, DiscoverState>(
  DiscoverStateNotifier.new,
);


/// State notifier for managing discover places using Notifier (Riverpod 2.0+)
class DiscoverStateNotifier extends Notifier<DiscoverState> {
  bool _cacheInitialized = false;

  @override
  DiscoverState build() {
    return const DiscoverState();
  }

  GooglePlacesService get _placesService => ref.read(googlePlacesServiceProvider);
  DiscoverLocalDataSource get _localDataSource => ref.read(discoverLocalDataSourceProvider);

  /// Check if device has internet connectivity
  Future<bool> _hasConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      debugPrint('⚠️ [Discover] Connectivity check failed: $e');
      return true; // Assume connected if check fails
    }
  }

  /// Initialize local cache
  Future<void> _initializeCache() async {
    if (_cacheInitialized) return;
    try {
      await _localDataSource.initialize();
      _cacheInitialized = true;
      debugPrint('✅ [Discover] Cache initialized');

      // Load saved favorites
      final savedFavorites = await _localDataSource.getFavorites();
      if (savedFavorites.isNotEmpty) {
        state = state.copyWith(favoriteIds: savedFavorites);
        debugPrint('❤️ [Discover] Loaded ${savedFavorites.length} saved favorites');
      }
    } catch (e) {
      debugPrint('⚠️ [Discover] Cache initialization failed: $e');
      _cacheInitialized = true; // Continue without cache
    }
  }

  /// Initialize and get user location
  Future<void> initialize() async {
    debugPrint('🎬 [Discover] initialize() called');
    debugPrint('📊 [Discover] Current state - hasLocation: ${state.hasLocation}, error: ${state.error}');

    // Initialize cache first
    await _initializeCache();

    await _getUserLocation();
    debugPrint('📊 [Discover] After _getUserLocation - hasLocation: ${state.hasLocation}, error: ${state.error}');
    if (state.hasLocation) {
      debugPrint('✅ [Discover] Has location, loading places...');
      await loadPlaces(state.selectedCategory);
    } else {
      debugPrint('⚠️ [Discover] No location available, cannot load places');
    }
  }

  /// Get current user location
  Future<void> _getUserLocation() async {
    debugPrint('🚀 [Discover] _getUserLocation() called');
    try {
      // Check if location services are enabled
      debugPrint('🔍 [Discover] Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📱 [Discover] Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        debugPrint('❌ [Discover] Location services are disabled');
        state = state.copyWith(
          error: 'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      // Check location permission
      debugPrint('🔍 [Discover] Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🔐 [Discover] Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ [Discover] Permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('🔐 [Discover] Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          debugPrint('❌ [Discover] Permission still denied after request');
          state = state.copyWith(
            error: 'Location permission denied.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('🚫 [Discover] Permission permanently denied');
        state = state.copyWith(
          error: 'Location permission permanently denied. Enable in settings.',
        );
        return;
      }

      // Get current position
      debugPrint('📍 [Discover] Getting current position (permission: $permission)...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        error: null,
      );

      debugPrint('✅ [Discover] Location obtained: ${position.latitude}, ${position.longitude}');

      // Get location name via reverse geocoding
      await _reverseGeocode();
    } catch (e, stackTrace) {
      debugPrint('❌ [Discover] Location error: $e');
      debugPrint('📋 [Discover] Stack trace: $stackTrace');
      state = state.copyWith(
        error: 'Failed to get location: $e',
      );
    }
  }

  /// Load places for a specific category (offline-first)
  Future<void> loadPlaces(PlaceCategory category) async {
    if (!state.hasLocation) {
      state = state.copyWith(error: 'Location not available');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      selectedCategory: category,
      error: null,
    );

    final lat = state.userLatitude!;
    final lng = state.userLongitude!;

    try {
      debugPrint('🔍 [Discover] Loading ${category.displayName}...');

      // Step 1: Try to load from cache first (instant response)
      List<DiscoverPlace>? cachedPlaces;
      if (_cacheInitialized) {
        cachedPlaces = await _localDataSource.getPlaces(
          category: category,
          latitude: lat,
          longitude: lng,
        );

        if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
          debugPrint('📦 [Discover] Loaded ${cachedPlaces.length} places from cache');
          state = state.copyWith(
            places: cachedPlaces,
            isLoading: false,
            isFromCache: true,
            error: null,
          );
        }
      }

      // Step 2: Check connectivity and fetch from API if available
      final hasInternet = await _hasConnectivity();

      if (hasInternet) {
        debugPrint('🌐 [Discover] Fetching fresh data from API...');
        debugPrint('📏 [Discover] Using distance: ${state.selectedDistance.displayName} (${state.selectedDistance.radiusInMeters}m)');
        final nearbyPlaces = await _placesService.searchNearby(
          latitude: lat,
          longitude: lng,
          radius: state.selectedDistance.radiusInMeters,
          type: category.googlePlaceType,
          keyword: category.googlePlaceKeyword,
        );

        final discoverPlaces = nearbyPlaces
            .map((place) => DiscoverPlace.fromNearbyPlace(place, category))
            .toList();

        debugPrint('✅ [Discover] Found ${discoverPlaces.length} places from API');

        // Save to cache for offline use
        if (_cacheInitialized && discoverPlaces.isNotEmpty) {
          await _localDataSource.savePlaces(
            category: category,
            places: discoverPlaces,
            latitude: lat,
            longitude: lng,
          );
          debugPrint('💾 [Discover] Saved ${discoverPlaces.length} places to cache');
        }

        state = state.copyWith(
          places: discoverPlaces,
          isLoading: false,
          isFromCache: false,
          error: null,
        );
      } else if (cachedPlaces == null || cachedPlaces.isEmpty) {
        // No internet and no cache - show error
        debugPrint('📴 [Discover] No internet and no cached data');
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please check your network and try again.',
        );
      } else {
        // Using cached data (already set above), just update loading state
        debugPrint('📴 [Discover] Using cached data (offline mode)');
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('❌ [Discover] Error loading places: $e');

      // If we have cached data, show it with a warning
      if (state.places.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not refresh data. Showing cached results.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load places: $e',
        );
      }
    }
  }

  /// Change the selected category and load places
  Future<void> changeCategory(PlaceCategory category) async {
    if (category == state.selectedCategory && state.places.isNotEmpty) {
      return; // Already loaded this category
    }
    await loadPlaces(category);
  }

  /// Refresh places for current category
  Future<void> refresh() async {
    await _getUserLocation();
    if (state.hasLocation) {
      await loadPlaces(state.selectedCategory);
    }
  }

  /// Set a custom location (for searching by destination)
  Future<void> setLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    state = state.copyWith(
      userLatitude: latitude,
      userLongitude: longitude,
      locationName: locationName,
    );
    await loadPlaces(state.selectedCategory);
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search query
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Toggle view mode between grid and map
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == DiscoverViewMode.grid
          ? DiscoverViewMode.map
          : DiscoverViewMode.grid,
    );
  }

  /// Set view mode
  void setViewMode(DiscoverViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Toggle favorite status for a place (persisted to local storage)
  void toggleFavorite(String placeId) {
    final newFavorites = Set<String>.from(state.favoriteIds);
    if (newFavorites.contains(placeId)) {
      newFavorites.remove(placeId);
      debugPrint('💔 [Discover] Removed from favorites: $placeId');
      // Persist to local storage
      if (_cacheInitialized) {
        _localDataSource.removeFavorite(placeId);
      }
    } else {
      newFavorites.add(placeId);
      debugPrint('❤️ [Discover] Added to favorites: $placeId');
      // Persist to local storage
      if (_cacheInitialized) {
        _localDataSource.addFavorite(placeId);
      }
    }
    state = state.copyWith(favoriteIds: newFavorites);
  }

  /// Toggle show favorites only filter
  void toggleShowFavoritesOnly() {
    state = state.copyWith(showFavoritesOnly: !state.showFavoritesOnly);
  }

  /// Change the selected distance and reload places
  Future<void> changeDistance(DiscoverDistance distance) async {
    if (distance == state.selectedDistance) return;
    state = state.copyWith(selectedDistance: distance);
    debugPrint('📏 [Discover] Distance changed to: ${distance.displayName}');
    if (state.hasLocation) {
      await loadPlaces(state.selectedCategory);
    }
  }

  /// Set the selected country (optional filter)
  void setCountry(String? country) {
    if (country == null) {
      state = state.copyWith(clearCountry: true);
    } else {
      state = state.copyWith(selectedCountry: country);
    }
    debugPrint('🌍 [Discover] Country set to: ${country ?? "Current Location"}');
  }

  /// Clear the country filter
  void clearCountry() {
    state = state.copyWith(clearCountry: true);
  }

  /// Check if a place is favorited
  bool isFavorite(String placeId) {
    return state.favoriteIds.contains(placeId);
  }

  /// Get location name using reverse geocoding (via Google Places nearby)
  Future<void> _reverseGeocode() async {
    if (!state.hasLocation) return;

    try {
      // Use a simple approach - get the nearest place and use its vicinity
      final nearbyPlaces = await _placesService.searchNearby(
        latitude: state.userLatitude!,
        longitude: state.userLongitude!,
        radius: 1000, // 1km radius
        type: 'locality',
      );

      if (nearbyPlaces.isNotEmpty) {
        final locationName = nearbyPlaces.first.vicinity ?? nearbyPlaces.first.name;
        state = state.copyWith(locationName: locationName);
        debugPrint('📍 [Discover] Location name: $locationName');
      }
    } catch (e) {
      debugPrint('⚠️ [Discover] Reverse geocoding failed: $e');
      // Use coordinates as fallback
      state = state.copyWith(
        locationName: '${state.userLatitude!.toStringAsFixed(4)}, ${state.userLongitude!.toStringAsFixed(4)}',
      );
    }
  }
}

/// Provider to get photo URL for a place (with offline caching)
final placePhotoUrlProvider = FutureProvider.family<String?, String>((ref, photoReference) async {
  final placesService = ref.watch(googlePlacesServiceProvider);
  final localDataSource = ref.watch(discoverLocalDataSourceProvider);

  // Try to get from cache first
  try {
    if (localDataSource.isAvailable) {
      final cachedUrl = await localDataSource.getCachedPhotoUrl(photoReference);
      if (cachedUrl != null) {
        debugPrint('📸 [Discover] Photo URL from cache');
        return cachedUrl;
      }
    }
  } catch (e) {
    debugPrint('⚠️ [Discover] Photo cache check failed: $e');
  }

  // Fetch from API
  final url = await placesService.getPhotoUrlWithTracking(
    photoReference: photoReference,
    maxWidth: 400,
  );

  // Cache the URL for offline use
  if (url != null) {
    try {
      if (localDataSource.isAvailable) {
        await localDataSource.cachePhotoUrl(
          photoReference: photoReference,
          url: url,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [Discover] Photo cache save failed: $e');
    }
  }

  return url;
});

/// Provider to get place details
final placeDetailsProvider = FutureProvider.family<PlaceDetails?, String>((ref, placeId) async {
  final placesService = ref.watch(googlePlacesServiceProvider);
  return placesService.getPlaceDetails(placeId: placeId);
});
