import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/google_places_service.dart';
import '../../data/datasources/discover_local_datasource.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/weather_suggestion.dart';

/// Provider for Supabase client
final discoverSupabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

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
  SupabaseClient get _supabase => ref.read(discoverSupabaseProvider);

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

  /// Initialize local cache and load favorites from Supabase
  Future<void> _initializeCache() async {
    if (_cacheInitialized) return;
    try {
      await _localDataSource.initialize();
      _cacheInitialized = true;
      debugPrint('✅ [Discover] Cache initialized');

      // Try to load favorites from Supabase first
      await _loadFavoritesFromSupabase();
    } catch (e) {
      debugPrint('⚠️ [Discover] Cache initialization failed: $e');
      _cacheInitialized = true; // Continue without cache
    }
  }

  /// Load favorites from Supabase, fallback to local storage
  Future<void> _loadFavoritesFromSupabase() async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [Discover] User not authenticated, loading from local');
        final savedFavorites = await _localDataSource.getFavorites();
        if (savedFavorites.isNotEmpty) {
          state = state.copyWith(favoriteIds: savedFavorites);
          debugPrint('❤️ [Discover] Loaded ${savedFavorites.length} favorites from local');
        }
        return;
      }

      // Fetch from Supabase
      final response = await _supabase.rpc('get_user_discover_favorite_ids');
      final favoriteIds = <String>{};

      if (response != null && response is List) {
        for (final item in response) {
          if (item is Map && item['place_id'] != null) {
            favoriteIds.add(item['place_id'].toString());
          }
        }
      }

      state = state.copyWith(favoriteIds: favoriteIds);
      debugPrint('❤️ [Discover] Loaded ${favoriteIds.length} favorites from Supabase');

      // Sync to local storage for offline access
      if (_cacheInitialized) {
        await _localDataSource.saveFavorites(favoriteIds);
      }
    } catch (e) {
      debugPrint('⚠️ [Discover] Failed to load favorites from Supabase: $e');
      // Fallback to local storage
      final savedFavorites = await _localDataSource.getFavorites();
      if (savedFavorites.isNotEmpty) {
        state = state.copyWith(favoriteIds: savedFavorites);
        debugPrint('❤️ [Discover] Loaded ${savedFavorites.length} favorites from local (fallback)');
      }
    }
  }

  /// Initialize cache, favorites, and automatically get user's location
  Future<void> initialize() async {
    debugPrint('🎬 [Discover] initialize() called');
    debugPrint('📊 [Discover] Current state - hasLocation: ${state.hasLocation}, error: ${state.error}');

    // Initialize cache and load favorites
    await _initializeCache();

    // Automatically get user's location (default behavior)
    await getUserLocation();
    debugPrint('✅ [Discover] Initialized with current location');
  }

  /// Public method to get user's GPS location (called when user clicks "Use My Location")
  Future<void> getUserLocation() async {
    await _getUserLocation();
    if (state.hasLocation) {
      debugPrint('✅ [Discover] Has location, loading places...');
      await loadPlaces(state.selectedCategory);
    }
  }

  /// Get current user location
  Future<void> _getUserLocation() async {
    debugPrint('🚀 [Discover] _getUserLocation() called');

    // Show loading state immediately
    state = state.copyWith(
      isGettingLocation: true,
      isPermissionDeniedForever: false,
      error: null,
    );

    try {
      // Check if location services are enabled
      debugPrint('🔍 [Discover] Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📱 [Discover] Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        debugPrint('❌ [Discover] Location services are disabled');
        state = state.copyWith(
          isGettingLocation: false,
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
            isGettingLocation: false,
            error: 'Location permission denied. Please grant location access.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('🚫 [Discover] Permission permanently denied');
        state = state.copyWith(
          isGettingLocation: false,
          isPermissionDeniedForever: true,
          error: 'Location permission permanently denied. Please enable in device settings.',
        );
        return;
      }

      // Get current position - try last known first for faster response
      debugPrint('📍 [Discover] Getting current position (permission: $permission)...');

      Position? position;

      // Step 1: Try to get last known position first (instant)
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          debugPrint('📍 [Discover] Using last known position: ${position.latitude}, ${position.longitude}');
          // Update state immediately with last known position
          state = state.copyWith(
            userLatitude: position.latitude,
            userLongitude: position.longitude,
            error: null,
          );
        }
      } catch (e) {
        debugPrint('⚠️ [Discover] Could not get last known position: $e');
      }

      // Step 2: Get fresh position with longer timeout
      try {
        final freshPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 30),
          ),
        );
        position = freshPosition;
        debugPrint('📍 [Discover] Got fresh position: ${position.latitude}, ${position.longitude}');
      } on TimeoutException {
        debugPrint('⏱️ [Discover] Location timeout with medium accuracy');
        // Step 3: Try with lower accuracy if timeout
        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 15),
              ),
            );
            debugPrint('📍 [Discover] Got position with low accuracy: ${position.latitude}, ${position.longitude}');
          } catch (e) {
            debugPrint('❌ [Discover] Failed to get position even with low accuracy: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Discover] getCurrentPosition error: $e');
        // Keep using last known position if available
      }

      if (position == null) {
        debugPrint('❌ [Discover] Could not determine location');
        state = state.copyWith(
          isGettingLocation: false,
          error: 'Could not determine your location. Please check GPS settings.',
        );
        return;
      }

      state = state.copyWith(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        isGettingLocation: false,
        error: null,
      );

      debugPrint('✅ [Discover] Location obtained: ${position.latitude}, ${position.longitude}');

      // Get location name via reverse geocoding (run in background, don't block)
      // This will update state.locationName when ready
      _reverseGeocode(); // Don't await - runs in parallel with places loading
    } catch (e, stackTrace) {
      debugPrint('❌ [Discover] Location error: $e');
      debugPrint('📋 [Discover] Stack trace: $stackTrace');
      state = state.copyWith(
        isGettingLocation: false,
        error: 'Failed to get location: $e',
      );
    }
  }

  /// Load places for a specific category (offline-first)
  /// Set [skipCache] to true to force fresh API data (useful when distance changes)
  Future<void> loadPlaces(PlaceCategory category, {bool skipCache = false}) async {
    if (!state.hasLocation) {
      state = state.copyWith(error: 'Location not available');
      return;
    }

    // If a country is selected, update coordinates based on category
    // (different categories may have different popular destinations)
    double lat = state.userLatitude!;
    double lng = state.userLongitude!;
    String? locationName = state.locationName;

    if (state.selectedCountry != null) {
      final coords = _getCoordinatesForCountryAndCategory(state.selectedCountry!, category);
      if (coords != null) {
        lat = coords['lat']!;
        lng = coords['lng']!;
        final destName = _getPopularDestinationName(state.selectedCountry!, category);
        locationName = destName != null ? '$destName, ${state.selectedCountry}' : state.selectedCountry;
        debugPrint('🎯 [Discover] Category changed to ${category.displayName}, using $locationName');
      }
    }

    state = state.copyWith(
      isLoading: true,
      selectedCategory: category,
      userLatitude: lat,
      userLongitude: lng,
      locationName: locationName,
      error: null,
    );

    try {
      debugPrint('🔍 [Discover] Loading ${category.displayName}...');

      // Step 1: Try to load from cache first (instant response)
      // Skip cache if explicitly requested (e.g., when distance changes)
      List<DiscoverPlace>? cachedPlaces;
      if (_cacheInitialized && !skipCache) {
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
      } else if (skipCache) {
        debugPrint('⏭️ [Discover] Skipping cache, fetching fresh data from API...');
      }

      // Step 2: Check connectivity and fetch from API if available
      final hasInternet = await _hasConnectivity();

      if (hasInternet) {
        debugPrint('🌐 [Discover] Fetching fresh data from API...');
        debugPrint('📏 [Discover] Using distance: ${state.selectedDistance.displayName} (${state.selectedDistance.radiusInMeters}m)');

        // Build keyword - include country name for better search relevance
        String keyword = category.googlePlaceKeyword;
        if (state.selectedCountry != null) {
          keyword = '${category.googlePlaceKeyword} ${state.selectedCountry}';
          debugPrint('🌍 [Discover] Enhanced keyword with country: "$keyword"');
        }

        final nearbyPlaces = await _placesService.searchNearby(
          latitude: lat,
          longitude: lng,
          radius: state.selectedDistance.radiusInMeters,
          type: category.googlePlaceType,
          keyword: keyword,
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
    debugPrint('🔄 [Discover] Refresh triggered');

    // Show loading state immediately
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      // If location was from search, don't re-fetch GPS - just reload places
      if (state.isLocationFromSearch && state.hasLocation) {
        debugPrint('🔄 [Discover] Refreshing with search location');
        await loadPlaces(state.selectedCategory);
      } else {
        // Re-fetch GPS location and then load places
        debugPrint('🔄 [Discover] Refreshing with GPS location');
        await _getUserLocation();
        if (state.hasLocation) {
          await loadPlaces(state.selectedCategory);
        }
      }
      debugPrint('✅ [Discover] Refresh completed');
    } catch (e) {
      debugPrint('❌ [Discover] Refresh failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Refresh failed: $e',
      );
    }
  }

  /// Set a custom location (for searching by destination)
  ///
  /// When [country] is provided, category-specific coordinates will be used
  /// (e.g., Phuket for beaches in Thailand instead of center of Thailand)
  Future<void> setLocation({
    required double latitude,
    required double longitude,
    String? locationName,
    String? country,
  }) async {
    // If country is provided and we have it in our popular destinations,
    // use the category-specific coordinates for better results
    double lat = latitude;
    double lng = longitude;
    String? displayName = locationName;

    if (country != null && _popularDestinations.containsKey(country)) {
      final coords = _getCoordinatesForCountryAndCategory(country, state.selectedCategory);
      if (coords != null) {
        lat = coords['lat']!;
        lng = coords['lng']!;
        final destName = _getPopularDestinationName(country, state.selectedCategory);
        displayName = destName != null ? '$destName, $country' : locationName;
        debugPrint('🎯 [Discover] Using category-specific location: $displayName');
      }
    }

    state = state.copyWith(
      userLatitude: lat,
      userLongitude: lng,
      locationName: displayName,
      selectedCountry: country, // Set the country for category switching
      clearCountry: country == null, // Clear country when searching by place name
      isLocationFromSearch: true, // Location set via search
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

  /// Toggle favorite status for a place (persisted to Supabase and local storage)
  Future<bool> toggleFavorite(String placeId, {DiscoverPlace? place}) async {
    final newFavorites = Set<String>.from(state.favoriteIds);
    final wasAdded = !newFavorites.contains(placeId);

    // Optimistic update
    if (wasAdded) {
      newFavorites.add(placeId);
      debugPrint('❤️ [Discover] Adding to favorites: $placeId');
    } else {
      newFavorites.remove(placeId);
      debugPrint('💔 [Discover] Removing from favorites: $placeId');
    }
    state = state.copyWith(favoriteIds: newFavorites);

    // Persist to Supabase
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.rpc('toggle_discover_favorite', params: {
          'p_place_id': placeId,
          'p_place_name': place?.name,
          'p_place_category': place?.category.name,
          'p_latitude': place?.latitude,
          'p_longitude': place?.longitude,
        });
        debugPrint('✅ [Discover] Favorite synced to Supabase');
      }
    } catch (e) {
      debugPrint('⚠️ [Discover] Failed to sync favorite to Supabase: $e');
      // Continue with local storage even if Supabase fails
    }

    // Persist to local storage for offline access
    if (_cacheInitialized) {
      if (wasAdded) {
        _localDataSource.addFavorite(placeId);
        // Also save place data for the planning assistant
        if (place != null) {
          _localDataSource.saveFavoritePlace(place);
        }
      } else {
        _localDataSource.removeFavorite(placeId);
        _localDataSource.removeFavoritePlace(placeId);
      }
    }

    return wasAdded;
  }

  /// Get all favorite places with full data (for planning assistant)
  Future<List<DiscoverPlace>> getFavoritePlaces() async {
    final Set<String> addedIds = {};
    final List<DiscoverPlace> result = [];

    // 1. Get stored favorite places from cache (new favorites with full data)
    if (_cacheInitialized) {
      final storedPlaces = await _localDataSource.getFavoritePlaces();
      for (final place in storedPlaces) {
        if (!addedIds.contains(place.placeId)) {
          result.add(place);
          addedIds.add(place.placeId);
        }
      }
    }

    // 2. Add favorites from current loaded places (for backward compatibility)
    for (final place in state.places) {
      if (state.favoriteIds.contains(place.placeId) && !addedIds.contains(place.placeId)) {
        result.add(place);
        addedIds.add(place.placeId);
        // Also save for future use
        if (_cacheInitialized) {
          _localDataSource.saveFavoritePlace(place);
        }
      }
    }

    // 3. Try to load from all cached categories if still missing favorites
    if (_cacheInitialized && result.length < state.favoriteIds.length) {
      for (final category in PlaceCategory.values) {
        final cachedPlaces = await _localDataSource.getPlaces(
          category: category,
          latitude: state.userLatitude ?? 0,
          longitude: state.userLongitude ?? 0,
        );
        if (cachedPlaces != null) {
          for (final place in cachedPlaces) {
            if (state.favoriteIds.contains(place.placeId) && !addedIds.contains(place.placeId)) {
              result.add(place);
              addedIds.add(place.placeId);
              // Save for future use
              _localDataSource.saveFavoritePlace(place);
            }
          }
        }
      }
    }

    debugPrint('❤️ [Discover] getFavoritePlaces: ${result.length} places (${state.favoriteIds.length} favorite IDs)');
    return result;
  }

  /// Toggle show favorites only filter
  void toggleShowFavoritesOnly() {
    state = state.copyWith(showFavoritesOnly: !state.showFavoritesOnly);
  }

  /// Change the selected distance and reload places
  Future<void> changeDistance(DiscoverDistance distance) async {
    if (distance == state.selectedDistance) return;

    // Clear current places and show loading immediately when distance changes
    state = state.copyWith(
      selectedDistance: distance,
      isLoading: true,
      places: [], // Clear old places to avoid showing stale data
      error: null,
    );

    debugPrint('📏 [Discover] Distance changed to: ${distance.displayName}');

    if (state.hasLocation) {
      // Skip cache to force fresh API data with new distance
      await loadPlaces(state.selectedCategory, skipCache: true);
    }
  }

  /// Default country coordinates (fallback)
  static const Map<String, Map<String, double>> _countryCoordinates = {
    'India': {'lat': 20.5937, 'lng': 78.9629},
    'Thailand': {'lat': 15.8700, 'lng': 100.9925},
    'Indonesia': {'lat': -0.7893, 'lng': 113.9213},
    'Japan': {'lat': 36.2048, 'lng': 138.2529},
    'Singapore': {'lat': 1.3521, 'lng': 103.8198},
    'Malaysia': {'lat': 4.2105, 'lng': 101.9758},
    'Vietnam': {'lat': 14.0583, 'lng': 108.2772},
    'Sri Lanka': {'lat': 7.8731, 'lng': 80.7718},
    'Nepal': {'lat': 28.3949, 'lng': 84.1240},
    'UAE': {'lat': 23.4241, 'lng': 53.8478},
    'Maldives': {'lat': 3.2028, 'lng': 73.2207},
    'Australia': {'lat': -25.2744, 'lng': 133.7751},
    'New Zealand': {'lat': -40.9006, 'lng': 174.8860},
    'France': {'lat': 46.2276, 'lng': 2.2137},
    'Italy': {'lat': 41.8719, 'lng': 12.5674},
    'Spain': {'lat': 40.4637, 'lng': -3.7492},
    'Greece': {'lat': 39.0742, 'lng': 21.8243},
    'Turkey': {'lat': 38.9637, 'lng': 35.2433},
    'Egypt': {'lat': 26.8206, 'lng': 30.8025},
    'South Africa': {'lat': -30.5595, 'lng': 22.9375},
    'USA': {'lat': 37.0902, 'lng': -95.7129},
    'Canada': {'lat': 56.1304, 'lng': -106.3468},
    'Mexico': {'lat': 23.6345, 'lng': -102.5528},
    'Brazil': {'lat': -14.2350, 'lng': -51.9253},
    'UK': {'lat': 55.3781, 'lng': -3.4360},
    'Germany': {'lat': 51.1657, 'lng': 10.4515},
    'Switzerland': {'lat': 46.8182, 'lng': 8.2275},
    'Philippines': {'lat': 12.8797, 'lng': 121.7740},
    'Cambodia': {'lat': 12.5657, 'lng': 104.9910},
    'Myanmar': {'lat': 21.9162, 'lng': 95.9560},
  };

  /// Popular destination coordinates by country and category
  /// Maps country -> category -> {lat, lng, name} of the best tourist area
  static const Map<String, Map<PlaceCategory, Map<String, dynamic>>> _popularDestinations = {
    'India': {
      PlaceCategory.beach: {'lat': 15.2993, 'lng': 74.1240, 'name': 'Goa'},
      PlaceCategory.hillStation: {'lat': 31.1048, 'lng': 77.1734, 'name': 'Shimla'},
      PlaceCategory.heritage: {'lat': 27.1751, 'lng': 78.0421, 'name': 'Agra'},
      PlaceCategory.adventure: {'lat': 30.0869, 'lng': 78.2676, 'name': 'Rishikesh'},
      PlaceCategory.wildlife: {'lat': 23.4315, 'lng': 80.5523, 'name': 'Bandhavgarh'},
      PlaceCategory.religious: {'lat': 25.3176, 'lng': 82.9739, 'name': 'Varanasi'},
      PlaceCategory.nature: {'lat': 27.1767, 'lng': 88.2626, 'name': 'Darjeeling'},
      PlaceCategory.urban: {'lat': 28.6139, 'lng': 77.2090, 'name': 'Delhi'},
      PlaceCategory.familyKids: {'lat': 12.9716, 'lng': 77.5946, 'name': 'Bangalore'}, // Wonderla, parks
      PlaceCategory.honeymoon: {'lat': 9.4981, 'lng': 76.2673, 'name': 'Kerala'}, // Backwaters
      PlaceCategory.pilgrimage: {'lat': 27.1751, 'lng': 78.0421, 'name': 'Mathura-Vrindavan'},
      PlaceCategory.seniorFriendly: {'lat': 15.4909, 'lng': 73.8278, 'name': 'Goa'}, // Peaceful beaches
    },
    'Thailand': {
      PlaceCategory.beach: {'lat': 7.8804, 'lng': 98.3923, 'name': 'Phuket'},
      PlaceCategory.hillStation: {'lat': 18.7883, 'lng': 98.9853, 'name': 'Chiang Mai'},
      PlaceCategory.heritage: {'lat': 13.7525, 'lng': 100.4936, 'name': 'Bangkok'},
      PlaceCategory.adventure: {'lat': 8.0863, 'lng': 98.9063, 'name': 'Krabi'},
      PlaceCategory.wildlife: {'lat': 14.4409, 'lng': 101.3693, 'name': 'Khao Yai'},
      PlaceCategory.religious: {'lat': 13.7525, 'lng': 100.4936, 'name': 'Bangkok'},
      PlaceCategory.nature: {'lat': 9.1382, 'lng': 99.3267, 'name': 'Koh Samui'},
      PlaceCategory.urban: {'lat': 13.7525, 'lng': 100.4936, 'name': 'Bangkok'},
      PlaceCategory.familyKids: {'lat': 13.7525, 'lng': 100.4936, 'name': 'Bangkok'}, // Safari World, Siam Park
      PlaceCategory.honeymoon: {'lat': 9.4561, 'lng': 100.0454, 'name': 'Koh Samui'}, // Romantic resorts
      PlaceCategory.pilgrimage: {'lat': 18.7883, 'lng': 98.9853, 'name': 'Chiang Mai'}, // Buddhist temples
      PlaceCategory.seniorFriendly: {'lat': 12.9236, 'lng': 100.8825, 'name': 'Pattaya'}, // Easy access beaches
    },
    'Indonesia': {
      PlaceCategory.beach: {'lat': -8.4095, 'lng': 115.1889, 'name': 'Bali'},
      PlaceCategory.hillStation: {'lat': -6.6842, 'lng': 106.9297, 'name': 'Puncak'},
      PlaceCategory.heritage: {'lat': -7.7893, 'lng': 110.3649, 'name': 'Yogyakarta'},
      PlaceCategory.adventure: {'lat': -8.3405, 'lng': 116.0417, 'name': 'Lombok'},
      PlaceCategory.wildlife: {'lat': -2.5308, 'lng': 116.1657, 'name': 'Borneo'},
      PlaceCategory.religious: {'lat': -7.6079, 'lng': 110.2038, 'name': 'Borobudur'},
      PlaceCategory.nature: {'lat': -8.3493, 'lng': 115.5089, 'name': 'Ubud'},
      PlaceCategory.urban: {'lat': -6.2088, 'lng': 106.8456, 'name': 'Jakarta'},
      PlaceCategory.familyKids: {'lat': -6.2088, 'lng': 106.8456, 'name': 'Jakarta'}, // Ancol, Taman Mini
      PlaceCategory.honeymoon: {'lat': -8.5069, 'lng': 115.2625, 'name': 'Bali'}, // Ubud villas
      PlaceCategory.pilgrimage: {'lat': -7.6079, 'lng': 110.2038, 'name': 'Borobudur'}, // Buddhist temple
      PlaceCategory.seniorFriendly: {'lat': -8.3493, 'lng': 115.5089, 'name': 'Ubud'}, // Peaceful gardens
    },
    'Japan': {
      PlaceCategory.beach: {'lat': 26.2124, 'lng': 127.6809, 'name': 'Okinawa'},
      PlaceCategory.hillStation: {'lat': 36.2323, 'lng': 137.9696, 'name': 'Hakuba'},
      PlaceCategory.heritage: {'lat': 35.0116, 'lng': 135.7681, 'name': 'Kyoto'},
      PlaceCategory.adventure: {'lat': 35.3606, 'lng': 138.7274, 'name': 'Mt. Fuji'},
      PlaceCategory.wildlife: {'lat': 43.0621, 'lng': 141.3544, 'name': 'Hokkaido'},
      PlaceCategory.religious: {'lat': 34.6851, 'lng': 135.8048, 'name': 'Nara'},
      PlaceCategory.nature: {'lat': 36.5613, 'lng': 136.3629, 'name': 'Kanazawa'},
      PlaceCategory.urban: {'lat': 35.6762, 'lng': 139.6503, 'name': 'Tokyo'},
      PlaceCategory.familyKids: {'lat': 35.6762, 'lng': 139.6503, 'name': 'Tokyo'}, // Disneyland, Sanrio
      PlaceCategory.honeymoon: {'lat': 35.0116, 'lng': 135.7681, 'name': 'Kyoto'}, // Ryokans
      PlaceCategory.pilgrimage: {'lat': 34.6851, 'lng': 135.8048, 'name': 'Nara'}, // Temples, shrines
      PlaceCategory.seniorFriendly: {'lat': 35.0116, 'lng': 135.7681, 'name': 'Kyoto'}, // Gardens, temples
    },
    'Malaysia': {
      PlaceCategory.beach: {'lat': 5.9549, 'lng': 116.0753, 'name': 'Sabah'},
      PlaceCategory.hillStation: {'lat': 4.4913, 'lng': 101.3895, 'name': 'Cameron Highlands'},
      PlaceCategory.heritage: {'lat': 5.4141, 'lng': 100.3288, 'name': 'Penang'},
      PlaceCategory.adventure: {'lat': 6.0535, 'lng': 116.5586, 'name': 'Mt. Kinabalu'},
      PlaceCategory.wildlife: {'lat': 5.5124, 'lng': 118.6067, 'name': 'Sandakan'},
      PlaceCategory.religious: {'lat': 3.0738, 'lng': 101.5183, 'name': 'Batu Caves'},
      PlaceCategory.nature: {'lat': 6.4414, 'lng': 99.7329, 'name': 'Langkawi'},
      PlaceCategory.urban: {'lat': 3.1390, 'lng': 101.6869, 'name': 'Kuala Lumpur'},
      PlaceCategory.familyKids: {'lat': 3.1390, 'lng': 101.6869, 'name': 'Kuala Lumpur'}, // KLCC, Legoland
      PlaceCategory.honeymoon: {'lat': 6.4414, 'lng': 99.7329, 'name': 'Langkawi'}, // Island resorts
      PlaceCategory.pilgrimage: {'lat': 3.0738, 'lng': 101.5183, 'name': 'Batu Caves'}, // Hindu temple
      PlaceCategory.seniorFriendly: {'lat': 4.4913, 'lng': 101.3895, 'name': 'Cameron Highlands'}, // Tea plantations
    },
    'Vietnam': {
      PlaceCategory.beach: {'lat': 12.2388, 'lng': 109.1967, 'name': 'Nha Trang'},
      PlaceCategory.hillStation: {'lat': 22.3364, 'lng': 103.8440, 'name': 'Sapa'},
      PlaceCategory.heritage: {'lat': 16.4637, 'lng': 107.5909, 'name': 'Hue'},
      PlaceCategory.adventure: {'lat': 20.9101, 'lng': 107.1839, 'name': 'Halong Bay'},
      PlaceCategory.wildlife: {'lat': 11.9467, 'lng': 108.4419, 'name': 'Cat Tien'},
      PlaceCategory.religious: {'lat': 21.0285, 'lng': 105.8542, 'name': 'Hanoi'},
      PlaceCategory.nature: {'lat': 15.8794, 'lng': 108.3350, 'name': 'Hoi An'},
      PlaceCategory.urban: {'lat': 10.8231, 'lng': 106.6297, 'name': 'Ho Chi Minh'},
      PlaceCategory.familyKids: {'lat': 10.8231, 'lng': 106.6297, 'name': 'Ho Chi Minh'}, // Dam Sen, Suoi Tien
      PlaceCategory.honeymoon: {'lat': 11.9404, 'lng': 108.4583, 'name': 'Da Lat'}, // French colonial romance
      PlaceCategory.pilgrimage: {'lat': 21.0285, 'lng': 105.8542, 'name': 'Hanoi'}, // Pagodas
      PlaceCategory.seniorFriendly: {'lat': 15.8794, 'lng': 108.3350, 'name': 'Hoi An'}, // Old town walks
    },
    'Sri Lanka': {
      PlaceCategory.beach: {'lat': 6.0329, 'lng': 80.2168, 'name': 'Galle'},
      PlaceCategory.hillStation: {'lat': 6.9497, 'lng': 80.7891, 'name': 'Nuwara Eliya'},
      PlaceCategory.heritage: {'lat': 7.9519, 'lng': 80.7608, 'name': 'Sigiriya'},
      PlaceCategory.adventure: {'lat': 6.9934, 'lng': 81.0550, 'name': 'Ella'},
      PlaceCategory.wildlife: {'lat': 6.4772, 'lng': 81.2281, 'name': 'Yala'},
      PlaceCategory.religious: {'lat': 7.2947, 'lng': 80.6365, 'name': 'Kandy'},
      PlaceCategory.nature: {'lat': 6.9271, 'lng': 80.4818, 'name': 'Horton Plains'},
      PlaceCategory.urban: {'lat': 6.9271, 'lng': 79.8612, 'name': 'Colombo'},
      PlaceCategory.familyKids: {'lat': 6.9271, 'lng': 79.8612, 'name': 'Colombo'}, // Dehiwala Zoo
      PlaceCategory.honeymoon: {'lat': 5.9549, 'lng': 80.4549, 'name': 'Bentota'}, // Beach resorts
      PlaceCategory.pilgrimage: {'lat': 7.2947, 'lng': 80.6365, 'name': 'Kandy'}, // Temple of Tooth
      PlaceCategory.seniorFriendly: {'lat': 6.9497, 'lng': 80.7891, 'name': 'Nuwara Eliya'}, // Tea country
    },
    'UAE': {
      PlaceCategory.beach: {'lat': 25.2048, 'lng': 55.2708, 'name': 'Dubai'},
      PlaceCategory.hillStation: {'lat': 25.1366, 'lng': 56.1269, 'name': 'Jebel Jais'},
      PlaceCategory.heritage: {'lat': 24.4539, 'lng': 54.3773, 'name': 'Abu Dhabi'},
      PlaceCategory.adventure: {'lat': 25.0657, 'lng': 55.1713, 'name': 'Dubai Desert'},
      PlaceCategory.wildlife: {'lat': 24.0889, 'lng': 52.8828, 'name': 'Sir Bani Yas'},
      PlaceCategory.religious: {'lat': 24.4128, 'lng': 54.4745, 'name': 'Sheikh Zayed Mosque'},
      PlaceCategory.nature: {'lat': 25.7617, 'lng': 55.9882, 'name': 'Fujairah'},
      PlaceCategory.urban: {'lat': 25.2048, 'lng': 55.2708, 'name': 'Dubai'},
      PlaceCategory.familyKids: {'lat': 25.2048, 'lng': 55.2708, 'name': 'Dubai'}, // IMG Worlds, Legoland
      PlaceCategory.honeymoon: {'lat': 25.2048, 'lng': 55.2708, 'name': 'Dubai'}, // Luxury resorts
      PlaceCategory.pilgrimage: {'lat': 24.4128, 'lng': 54.4745, 'name': 'Sheikh Zayed Mosque'},
      PlaceCategory.seniorFriendly: {'lat': 24.4539, 'lng': 54.3773, 'name': 'Abu Dhabi'}, // Corniche walks
    },
    'Greece': {
      PlaceCategory.beach: {'lat': 36.4618, 'lng': 25.3773, 'name': 'Santorini'},
      PlaceCategory.hillStation: {'lat': 39.7178, 'lng': 21.6304, 'name': 'Meteora'},
      PlaceCategory.heritage: {'lat': 37.9715, 'lng': 23.7257, 'name': 'Athens'},
      PlaceCategory.adventure: {'lat': 35.2401, 'lng': 24.9028, 'name': 'Crete'},
      PlaceCategory.wildlife: {'lat': 40.0659, 'lng': 23.6716, 'name': 'Halkidiki'},
      PlaceCategory.religious: {'lat': 39.7178, 'lng': 21.6304, 'name': 'Meteora'},
      PlaceCategory.nature: {'lat': 39.6243, 'lng': 19.9217, 'name': 'Corfu'},
      PlaceCategory.urban: {'lat': 37.9838, 'lng': 23.7275, 'name': 'Athens'},
      PlaceCategory.familyKids: {'lat': 37.9838, 'lng': 23.7275, 'name': 'Athens'}, // Attica Zoo, Allou Fun Park
      PlaceCategory.honeymoon: {'lat': 36.4618, 'lng': 25.3773, 'name': 'Santorini'}, // Romantic sunsets
      PlaceCategory.pilgrimage: {'lat': 39.7178, 'lng': 21.6304, 'name': 'Meteora'}, // Orthodox monasteries
      PlaceCategory.seniorFriendly: {'lat': 39.6243, 'lng': 19.9217, 'name': 'Corfu'}, // Peaceful island
    },
    'Italy': {
      PlaceCategory.beach: {'lat': 40.6333, 'lng': 14.6027, 'name': 'Amalfi Coast'},
      PlaceCategory.hillStation: {'lat': 46.4102, 'lng': 11.8440, 'name': 'Dolomites'},
      PlaceCategory.heritage: {'lat': 41.9028, 'lng': 12.4964, 'name': 'Rome'},
      PlaceCategory.adventure: {'lat': 46.5396, 'lng': 11.9283, 'name': 'Cortina'},
      PlaceCategory.wildlife: {'lat': 42.4602, 'lng': 14.2161, 'name': 'Abruzzo'},
      PlaceCategory.religious: {'lat': 41.9029, 'lng': 12.4534, 'name': 'Vatican'},
      PlaceCategory.nature: {'lat': 43.7696, 'lng': 11.2558, 'name': 'Tuscany'},
      PlaceCategory.urban: {'lat': 45.4642, 'lng': 9.1900, 'name': 'Milan'},
      PlaceCategory.familyKids: {'lat': 41.9028, 'lng': 12.4964, 'name': 'Rome'}, // Rainbow MagicLand, Bioparco
      PlaceCategory.honeymoon: {'lat': 45.4408, 'lng': 12.3155, 'name': 'Venice'}, // Romantic canals
      PlaceCategory.pilgrimage: {'lat': 41.9029, 'lng': 12.4534, 'name': 'Vatican'}, // St. Peter's Basilica
      PlaceCategory.seniorFriendly: {'lat': 43.7696, 'lng': 11.2558, 'name': 'Tuscany'}, // Scenic countryside
    },
    'Spain': {
      PlaceCategory.beach: {'lat': 36.7213, 'lng': -4.4214, 'name': 'Costa del Sol'},
      PlaceCategory.hillStation: {'lat': 37.0892, 'lng': -3.3969, 'name': 'Sierra Nevada'},
      PlaceCategory.heritage: {'lat': 37.3886, 'lng': -5.9823, 'name': 'Seville'},
      PlaceCategory.adventure: {'lat': 42.6953, 'lng': -0.0098, 'name': 'Pyrenees'},
      PlaceCategory.wildlife: {'lat': 36.9741, 'lng': -6.4421, 'name': 'Doñana'},
      PlaceCategory.religious: {'lat': 41.4036, 'lng': 2.1744, 'name': 'Barcelona'},
      PlaceCategory.nature: {'lat': 39.4699, 'lng': -0.3763, 'name': 'Valencia'},
      PlaceCategory.urban: {'lat': 40.4168, 'lng': -3.7038, 'name': 'Madrid'},
      PlaceCategory.familyKids: {'lat': 41.3851, 'lng': 2.1734, 'name': 'Barcelona'}, // PortAventura, Tibidabo
      PlaceCategory.honeymoon: {'lat': 28.2916, 'lng': -16.6291, 'name': 'Tenerife'}, // Canary Islands
      PlaceCategory.pilgrimage: {'lat': 42.8805, 'lng': -8.5459, 'name': 'Santiago de Compostela'}, // Cathedral
      PlaceCategory.seniorFriendly: {'lat': 37.3886, 'lng': -5.9823, 'name': 'Seville'}, // Parks and plazas
    },
    'France': {
      PlaceCategory.beach: {'lat': 43.5528, 'lng': 7.0174, 'name': 'French Riviera'},
      PlaceCategory.hillStation: {'lat': 45.8326, 'lng': 6.8652, 'name': 'Chamonix'},
      PlaceCategory.heritage: {'lat': 48.8566, 'lng': 2.3522, 'name': 'Paris'},
      PlaceCategory.adventure: {'lat': 45.9237, 'lng': 6.8694, 'name': 'Mont Blanc'},
      PlaceCategory.wildlife: {'lat': 44.1164, 'lng': 6.6346, 'name': 'Mercantour'},
      PlaceCategory.religious: {'lat': 48.8530, 'lng': 2.3499, 'name': 'Notre-Dame'},
      PlaceCategory.nature: {'lat': 47.3220, 'lng': -0.8910, 'name': 'Loire Valley'},
      PlaceCategory.urban: {'lat': 48.8566, 'lng': 2.3522, 'name': 'Paris'},
      PlaceCategory.familyKids: {'lat': 48.8674, 'lng': 2.7836, 'name': 'Disneyland Paris'}, // Theme parks
      PlaceCategory.honeymoon: {'lat': 48.8566, 'lng': 2.3522, 'name': 'Paris'}, // City of Love
      PlaceCategory.pilgrimage: {'lat': 43.0930, 'lng': -0.0482, 'name': 'Lourdes'}, // Sacred pilgrimage site
      PlaceCategory.seniorFriendly: {'lat': 47.3220, 'lng': -0.8910, 'name': 'Loire Valley'}, // Châteaux tours
    },
    'Australia': {
      PlaceCategory.beach: {'lat': -28.0023, 'lng': 153.4145, 'name': 'Gold Coast'},
      PlaceCategory.hillStation: {'lat': -33.7233, 'lng': 150.3116, 'name': 'Blue Mountains'},
      PlaceCategory.heritage: {'lat': -33.8568, 'lng': 151.2153, 'name': 'Sydney'},
      PlaceCategory.adventure: {'lat': -16.9186, 'lng': 145.7781, 'name': 'Cairns'},
      PlaceCategory.wildlife: {'lat': -25.2744, 'lng': 130.9756, 'name': 'Uluru'},
      PlaceCategory.religious: {'lat': -33.8688, 'lng': 151.2093, 'name': 'Sydney'},
      PlaceCategory.nature: {'lat': -16.5085, 'lng': 145.4683, 'name': 'Great Barrier Reef'},
      PlaceCategory.urban: {'lat': -37.8136, 'lng': 144.9631, 'name': 'Melbourne'},
      PlaceCategory.familyKids: {'lat': -28.0023, 'lng': 153.4145, 'name': 'Gold Coast'}, // Theme parks, Sea World
      PlaceCategory.honeymoon: {'lat': -20.2588, 'lng': 148.8785, 'name': 'Whitsundays'}, // Romantic islands
      PlaceCategory.pilgrimage: {'lat': -25.2744, 'lng': 130.9756, 'name': 'Uluru'}, // Sacred Aboriginal site
      PlaceCategory.seniorFriendly: {'lat': -37.8136, 'lng': 144.9631, 'name': 'Melbourne'}, // Gardens, culture
    },
    'USA': {
      PlaceCategory.beach: {'lat': 25.7617, 'lng': -80.1918, 'name': 'Miami'},
      PlaceCategory.hillStation: {'lat': 39.5501, 'lng': -105.7821, 'name': 'Colorado'},
      PlaceCategory.heritage: {'lat': 38.9072, 'lng': -77.0369, 'name': 'Washington DC'},
      PlaceCategory.adventure: {'lat': 36.1069, 'lng': -112.1129, 'name': 'Grand Canyon'},
      PlaceCategory.wildlife: {'lat': 44.4280, 'lng': -110.5885, 'name': 'Yellowstone'},
      PlaceCategory.religious: {'lat': 40.7580, 'lng': -73.9855, 'name': 'New York'},
      PlaceCategory.nature: {'lat': 37.8651, 'lng': -119.5383, 'name': 'Yosemite'},
      PlaceCategory.urban: {'lat': 40.7128, 'lng': -74.0060, 'name': 'New York'},
      PlaceCategory.familyKids: {'lat': 28.3772, 'lng': -81.5707, 'name': 'Orlando'}, // Disney World, Universal
      PlaceCategory.honeymoon: {'lat': 21.3069, 'lng': -157.8583, 'name': 'Hawaii'}, // Romantic beaches
      PlaceCategory.pilgrimage: {'lat': 40.7580, 'lng': -73.9855, 'name': 'New York'}, // St. Patrick's Cathedral
      PlaceCategory.seniorFriendly: {'lat': 32.7157, 'lng': -117.1611, 'name': 'San Diego'}, // Mild weather, parks
    },
    'Maldives': {
      PlaceCategory.beach: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male Atoll'},
      PlaceCategory.hillStation: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male'},
      PlaceCategory.heritage: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male'},
      PlaceCategory.adventure: {'lat': 3.2028, 'lng': 73.2207, 'name': 'Ari Atoll'},
      PlaceCategory.wildlife: {'lat': 5.4570, 'lng': 73.0707, 'name': 'Baa Atoll'},
      PlaceCategory.religious: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male'},
      PlaceCategory.nature: {'lat': 3.2028, 'lng': 73.2207, 'name': 'Ari Atoll'},
      PlaceCategory.urban: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male'},
      PlaceCategory.familyKids: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male Atoll'}, // Resort kids clubs
      PlaceCategory.honeymoon: {'lat': 3.2028, 'lng': 73.2207, 'name': 'Ari Atoll'}, // Overwater villas
      PlaceCategory.pilgrimage: {'lat': 4.1755, 'lng': 73.5093, 'name': 'Male'}, // Islamic Heritage Centre
      PlaceCategory.seniorFriendly: {'lat': 5.4570, 'lng': 73.0707, 'name': 'Baa Atoll'}, // Relaxing resorts
    },
    'Philippines': {
      PlaceCategory.beach: {'lat': 9.8349, 'lng': 118.7384, 'name': 'Palawan'},
      PlaceCategory.hillStation: {'lat': 16.4023, 'lng': 120.5960, 'name': 'Baguio'},
      PlaceCategory.heritage: {'lat': 10.3157, 'lng': 123.8854, 'name': 'Cebu'},
      PlaceCategory.adventure: {'lat': 11.9674, 'lng': 121.9182, 'name': 'Boracay'},
      PlaceCategory.wildlife: {'lat': 9.4667, 'lng': 117.9833, 'name': 'Puerto Princesa'},
      PlaceCategory.religious: {'lat': 14.5995, 'lng': 120.9842, 'name': 'Manila'},
      PlaceCategory.nature: {'lat': 9.6536, 'lng': 123.8573, 'name': 'Bohol'},
      PlaceCategory.urban: {'lat': 14.5995, 'lng': 120.9842, 'name': 'Manila'},
      PlaceCategory.familyKids: {'lat': 14.5995, 'lng': 120.9842, 'name': 'Manila'}, // Ocean Park, Enchanted Kingdom
      PlaceCategory.honeymoon: {'lat': 9.8349, 'lng': 118.7384, 'name': 'Palawan'}, // El Nido, romantic beaches
      PlaceCategory.pilgrimage: {'lat': 10.3157, 'lng': 123.8854, 'name': 'Cebu'}, // Basilica del Santo Niño
      PlaceCategory.seniorFriendly: {'lat': 16.4023, 'lng': 120.5960, 'name': 'Baguio'}, // Cool climate, gardens
    },
  };

  /// Get coordinates for country based on category (uses popular tourist destination)
  Map<String, double>? _getCoordinatesForCountryAndCategory(String country, PlaceCategory category) {
    // First, try to get category-specific destination
    final categoryDestinations = _popularDestinations[country];
    if (categoryDestinations != null && categoryDestinations.containsKey(category)) {
      final dest = categoryDestinations[category]!;
      debugPrint('🎯 [Discover] Using popular destination: ${dest['name']} for $category in $country');
      return {'lat': dest['lat'] as double, 'lng': dest['lng'] as double};
    }

    // Fallback to default country coordinates
    return _countryCoordinates[country];
  }

  /// Set the selected country and load places for that location
  Future<void> setCountry(String? country) async {
    if (country == null) {
      await clearCountry();
      return;
    }

    // Get coordinates based on country and current category
    final coords = _getCoordinatesForCountryAndCategory(country, state.selectedCategory);
    if (coords == null) {
      debugPrint('⚠️ [Discover] Unknown country: $country');
      return;
    }

    // Get destination name for display
    final destName = _getPopularDestinationName(country, state.selectedCategory);
    final locationName = destName != null ? '$destName, $country' : country;

    debugPrint('🌍 [Discover] Setting country to: $country');
    debugPrint('📍 [Discover] Using coordinates: ${coords['lat']}, ${coords['lng']} ($locationName)');

    // Update state with country and its coordinates
    state = state.copyWith(
      selectedCountry: country,
      userLatitude: coords['lat'],
      userLongitude: coords['lng'],
      locationName: locationName,
    );

    // Reload places for the new location
    await loadPlaces(state.selectedCategory);
  }

  /// Get the name of the popular destination for a country and category
  String? _getPopularDestinationName(String country, PlaceCategory category) {
    final categoryDestinations = _popularDestinations[country];
    if (categoryDestinations != null && categoryDestinations.containsKey(category)) {
      return categoryDestinations[category]!['name'] as String?;
    }
    return null;
  }

  /// Clear the country filter and restore user's GPS location
  Future<void> clearCountry() async {
    debugPrint('🌍 [Discover] Clearing country filter, restoring GPS location');
    state = state.copyWith(
      clearCountry: true,
      isLocationFromSearch: false, // Using GPS location
    );

    // Get user's actual GPS location and reload places
    await _getUserLocation();
    if (state.hasLocation) {
      await loadPlaces(state.selectedCategory);
    }
  }

  /// Check if a place is favorited
  bool isFavorite(String placeId) {
    return state.favoriteIds.contains(placeId);
  }

  /// Get list of available countries for selection
  static List<String> getAvailableCountries() {
    return _countryCoordinates.keys.toList()..sort();
  }

  /// Get location name using native reverse geocoding (free, fast, accurate)
  Future<void> _reverseGeocode() async {
    if (!state.hasLocation) return;

    try {
      debugPrint('🔍 [Discover] Starting native reverse geocoding...');

      // Use native geocoding (Android Geocoder / iOS CLGeocoder) - FREE and accurate
      final placemarks = await geo.placemarkFromCoordinates(
        state.userLatitude!,
        state.userLongitude!,
      );

      String locationName = 'Current Location';

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        debugPrint('📍 [Discover] Placemark: subLocality=${placemark.subLocality}, locality=${placemark.locality}, administrativeArea=${placemark.administrativeArea}');

        // Build location name from most specific to least specific
        // Priority: subLocality (neighborhood/area) > locality (city) > administrativeArea (state)
        final parts = <String>[];

        // Add neighborhood/area (e.g., "KR Puram")
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          parts.add(placemark.subLocality!);
        }

        // Add city (e.g., "Bengaluru")
        if (placemark.locality != null &&
            placemark.locality!.isNotEmpty &&
            placemark.locality != placemark.subLocality) {
          parts.add(placemark.locality!);
        }

        // If no subLocality or locality, use administrativeArea (state)
        if (parts.isEmpty && placemark.administrativeArea != null) {
          parts.add(placemark.administrativeArea!);
        }

        if (parts.isNotEmpty) {
          locationName = parts.join(', ');
        }
      }

      state = state.copyWith(locationName: locationName);
      debugPrint('✅ [Discover] Location name: $locationName');
    } catch (e) {
      debugPrint('⚠️ [Discover] Native reverse geocoding failed: $e');
      // Use "Current Location" as fallback
      state = state.copyWith(
        locationName: 'Current Location',
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

/// Provider to get weather for the selected location
final locationWeatherProvider = FutureProvider<WeatherData?>((ref) async {
  final discoverState = ref.watch(discoverStateProvider);

  // Need location to fetch weather
  if (!discoverState.hasLocation) {
    debugPrint('🌤️ [Weather] No location available');
    return null;
  }

  final lat = discoverState.userLatitude!;
  final lon = discoverState.userLongitude!;
  final locationName = discoverState.locationName ?? 'Current Location';

  debugPrint('🌤️ [Weather] Fetching weather for $locationName ($lat, $lon)');

  try {
    // Fetch from OpenWeatherMap API
    final response = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&units=metric&appid=$_openWeatherApiKey',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final weather = WeatherData.fromOpenWeatherMap(data);
      debugPrint('🌤️ [Weather] Got: ${weather.temperatureText} ${weather.condition.displayName} at ${weather.locationName}');
      return weather;
    } else {
      debugPrint('⚠️ [Weather] API error: ${response.statusCode}');
      // Return mock weather as fallback with location name
      return _getMockWeatherForLocation(locationName);
    }
  } catch (e) {
    debugPrint('⚠️ [Weather] Failed to fetch: $e');
    // Return mock weather as fallback with location name
    return _getMockWeatherForLocation(locationName);
  }
});

// OpenWeatherMap API key (free tier)
const String _openWeatherApiKey = '4d3c2b1a0f9e8d7c6b5a4321abcdef01'; // Replace with actual key

/// Generate mock weather for a location when API is unavailable
WeatherData _getMockWeatherForLocation(String locationName) {
  final hour = DateTime.now().hour;

  // Simulate different weather based on time of day
  WeatherCondition condition;
  double temp;

  if (hour >= 6 && hour < 10) {
    temp = 24;
    condition = WeatherCondition.sunny;
  } else if (hour >= 10 && hour < 14) {
    temp = 32;
    condition = WeatherCondition.sunny;
  } else if (hour >= 14 && hour < 18) {
    temp = 30;
    condition = WeatherCondition.sunny;
  } else if (hour >= 18 && hour < 21) {
    temp = 26;
    condition = WeatherCondition.sunny;
  } else {
    temp = 22;
    condition = WeatherCondition.sunny;
  }

  return WeatherData(
    temperature: temp,
    feelsLike: temp + 2,
    condition: condition,
    humidity: 65,
    windSpeed: 12,
    description: condition.displayName,
    locationName: locationName,
    timestamp: DateTime.now(),
  );
}
