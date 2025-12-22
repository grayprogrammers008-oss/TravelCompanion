import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/google_places_service.dart';

/// Google Places Service Provider
final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  final service = GooglePlacesService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// AI Suggestions data model
class AiSuggestions {
  final List<NearbyPlace> places;
  final String contextLabel;
  final String? tripName;
  final double latitude;
  final double longitude;

  const AiSuggestions({
    required this.places,
    required this.contextLabel,
    this.tripName,
    required this.latitude,
    required this.longitude,
  });
}

/// AI Suggestions Provider - Shows top-rated places near user's current location
///
/// Logic:
/// 1. Always use user's current location for suggestions
/// 2. Show top-rated tourist attractions and restaurants nearby
/// 3. Falls back gracefully if location unavailable
final aiSuggestionsProvider = FutureProvider<AiSuggestions?>((ref) async {
  debugPrint('🤖 [AISuggestions] Provider starting...');

  try {
    // Always fetch places near user's current location
    return await _fetchPlacesNearCurrentLocation(ref);
  } catch (e) {
    debugPrint('❌ [AISuggestions] Error: $e');
    return null;
  }
});

/// Fetch places near user's current location
Future<AiSuggestions?> _fetchPlacesNearCurrentLocation(Ref ref) async {
  final placesService = ref.read(googlePlacesServiceProvider);

  try {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ [AISuggestions] Location permission denied');
      return null;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ [AISuggestions] Location services disabled');
      return null;
    }

    // Get current position with timeout
    debugPrint('🤖 [AISuggestions] Getting current location...');
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    ).timeout(const Duration(seconds: 10));

    debugPrint('🤖 [AISuggestions] Current location: ${position.latitude}, ${position.longitude}');

    // Search for nearby attractions with larger radius
    var places = await placesService.searchNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      radius: 15000, // 15km radius for current location
      type: 'tourist_attraction',
    );

    debugPrint('🤖 [AISuggestions] Found ${places.length} attractions nearby');

    // If not enough, add restaurants
    if (places.length < 5) {
      final restaurants = await placesService.searchNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 10000,
        type: 'restaurant',
      );
      for (final r in restaurants) {
        if (!places.any((p) => p.placeId == r.placeId)) {
          places.add(r);
        }
      }
      debugPrint('🤖 [AISuggestions] After adding restaurants: ${places.length} places');
    }

    // Filter for quality
    final qualityPlaces = places.where((p) {
      if (p.rating == null || p.rating! < 3.5) return false;
      if (p.userRatingsTotal == null || p.userRatingsTotal! < 10) return false;
      return true;
    }).toList();

    debugPrint('🤖 [AISuggestions] After quality filter: ${qualityPlaces.length} places');

    if (qualityPlaces.isEmpty) {
      // Fallback
      final fallbackPlaces = places.where((p) => p.rating != null && p.rating! >= 3.0).toList();
      if (fallbackPlaces.isEmpty) return null;

      return AiSuggestions(
        places: fallbackPlaces,
        contextLabel: 'Popular nearby',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    return AiSuggestions(
      places: qualityPlaces,
      contextLabel: 'Top rated nearby',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (e) {
    debugPrint('❌ [AISuggestions] Error fetching nearby places: $e');
    return null;
  }
}
