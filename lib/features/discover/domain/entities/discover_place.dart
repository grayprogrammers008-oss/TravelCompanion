import 'dart:math' as math;
import '../../../../core/services/google_places_service.dart';
import 'place_category.dart';

/// Entity representing a discovered tourist place
/// Wraps NearbyPlace from Google Places API with category information
class DiscoverPlace {
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
  final PlaceCategory category;
  final bool isFavorite;

  const DiscoverPlace({
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
    required this.category,
    this.isFavorite = false,
  });

  /// Create from NearbyPlace API result
  factory DiscoverPlace.fromNearbyPlace(
    NearbyPlace place,
    PlaceCategory category,
  ) {
    return DiscoverPlace(
      placeId: place.placeId,
      name: place.name,
      vicinity: place.vicinity,
      latitude: place.latitude,
      longitude: place.longitude,
      types: place.types,
      rating: place.rating,
      userRatingsTotal: place.userRatingsTotal,
      openNow: place.openNow,
      photos: place.photos,
      category: category,
    );
  }

  /// Check if the place has photos
  bool get hasPhotos => photos.isNotEmpty;

  /// Get the first photo reference (if available)
  String? get firstPhotoReference =>
      photos.isNotEmpty ? photos.first.photoReference : null;

  /// Get formatted rating text
  String get ratingText {
    if (rating == null) return 'No rating';
    return rating!.toStringAsFixed(1);
  }

  /// Get formatted reviews count
  String get reviewsText {
    if (userRatingsTotal == null || userRatingsTotal == 0) return 'No reviews';
    if (userRatingsTotal! >= 1000) {
      return '${(userRatingsTotal! / 1000).toStringAsFixed(1)}k reviews';
    }
    return '$userRatingsTotal reviews';
  }

  /// Get open/closed status text
  String? get statusText {
    if (openNow == null) return null;
    return openNow! ? 'Open now' : 'Closed';
  }

  /// Check if the place matches a search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        (vicinity?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// Calculate distance from user location using Haversine formula
  double? distanceFrom(double? userLat, double? userLng) {
    if (latitude == null || longitude == null || userLat == null || userLng == null) {
      return null;
    }

    const double earthRadius = 6371; // km
    final dLat = _toRadians(latitude! - userLat);
    final dLng = _toRadians(longitude! - userLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(userLat)) *
            math.cos(_toRadians(latitude!)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  /// Get formatted distance text
  String distanceText(double? userLat, double? userLng) {
    final distance = distanceFrom(userLat, userLng);
    if (distance == null) return '';
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Create a copy with favorite status changed
  DiscoverPlace copyWith({bool? isFavorite}) {
    return DiscoverPlace(
      placeId: placeId,
      name: name,
      vicinity: vicinity,
      latitude: latitude,
      longitude: longitude,
      types: types,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      openNow: openNow,
      photos: photos,
      category: category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverPlace &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;
}

/// View mode for discover page
enum DiscoverViewMode { grid, map }

/// State class for managing discover places
class DiscoverState {
  final PlaceCategory selectedCategory;
  final List<DiscoverPlace> places;
  final bool isLoading;
  final String? error;
  final double? userLatitude;
  final double? userLongitude;
  final String? locationName;
  final String searchQuery;
  final DiscoverViewMode viewMode;
  final Set<String> favoriteIds;
  final bool showFavoritesOnly;
  final bool isFromCache; // Indicates if current data is from offline cache

  const DiscoverState({
    this.selectedCategory = PlaceCategory.beach,
    this.places = const [],
    this.isLoading = false,
    this.error,
    this.userLatitude,
    this.userLongitude,
    this.locationName,
    this.searchQuery = '',
    this.viewMode = DiscoverViewMode.grid,
    this.favoriteIds = const {},
    this.showFavoritesOnly = false,
    this.isFromCache = false,
  });

  DiscoverState copyWith({
    PlaceCategory? selectedCategory,
    List<DiscoverPlace>? places,
    bool? isLoading,
    String? error,
    double? userLatitude,
    double? userLongitude,
    String? locationName,
    String? searchQuery,
    DiscoverViewMode? viewMode,
    Set<String>? favoriteIds,
    bool? showFavoritesOnly,
    bool? isFromCache,
  }) {
    return DiscoverState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      locationName: locationName ?? this.locationName,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  /// Check if location is available
  bool get hasLocation => userLatitude != null && userLongitude != null;

  /// Get filtered places based on search and favorites
  List<DiscoverPlace> get filteredPlaces {
    var result = places;

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      result = result.where((p) => p.matchesSearch(searchQuery)).toList();
    }

    // Filter favorites only
    if (showFavoritesOnly) {
      result = result.where((p) => favoriteIds.contains(p.placeId)).toList();
    }

    return result;
  }

  /// Check if a place is a favorite
  bool isFavorite(String placeId) => favoriteIds.contains(placeId);
}
