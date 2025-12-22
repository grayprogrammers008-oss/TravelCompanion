import 'package:flutter/material.dart';
import 'discover_place.dart';
import 'place_category.dart';

/// Types of recommendations
enum RecommendationType {
  /// Based on user's favorite places
  basedOnFavorites,
  /// Based on current location
  nearYou,
  /// Based on time of day
  timeOfDay,
  /// Based on season
  seasonal,
  /// Trending in the area
  trending,
  /// Hidden gems (high rating, low reviews)
  hiddenGems,
}

/// Extension for recommendation type metadata
extension RecommendationTypeExtension on RecommendationType {
  String get title {
    switch (this) {
      case RecommendationType.basedOnFavorites:
        return 'Because You Liked';
      case RecommendationType.nearYou:
        return 'Near You';
      case RecommendationType.timeOfDay:
        return 'Perfect for Now';
      case RecommendationType.seasonal:
        return 'Seasonal Picks';
      case RecommendationType.trending:
        return 'Trending Now';
      case RecommendationType.hiddenGems:
        return 'Hidden Gems';
    }
  }

  String get subtitle {
    switch (this) {
      case RecommendationType.basedOnFavorites:
        return 'Places similar to your favorites';
      case RecommendationType.nearYou:
        return 'Discover what\'s around you';
      case RecommendationType.timeOfDay:
        return 'Great places to visit right now';
      case RecommendationType.seasonal:
        return 'Best for this time of year';
      case RecommendationType.trending:
        return 'Popular with other travelers';
      case RecommendationType.hiddenGems:
        return 'Highly rated but less crowded';
    }
  }

  IconData get icon {
    switch (this) {
      case RecommendationType.basedOnFavorites:
        return Icons.favorite;
      case RecommendationType.nearYou:
        return Icons.near_me;
      case RecommendationType.timeOfDay:
        return Icons.access_time;
      case RecommendationType.seasonal:
        return Icons.wb_sunny;
      case RecommendationType.trending:
        return Icons.trending_up;
      case RecommendationType.hiddenGems:
        return Icons.diamond;
    }
  }

  Color get color {
    switch (this) {
      case RecommendationType.basedOnFavorites:
        return Colors.red;
      case RecommendationType.nearYou:
        return Colors.blue;
      case RecommendationType.timeOfDay:
        return Colors.orange;
      case RecommendationType.seasonal:
        return Colors.green;
      case RecommendationType.trending:
        return Colors.purple;
      case RecommendationType.hiddenGems:
        return Colors.teal;
    }
  }
}

/// A personalized place recommendation
class PlaceRecommendation {
  final DiscoverPlace place;
  final RecommendationType type;
  final String reason;
  final double matchScore; // 0.0 to 1.0

  const PlaceRecommendation({
    required this.place,
    required this.type,
    required this.reason,
    required this.matchScore,
  });
}

/// A group of recommendations
class RecommendationGroup {
  final RecommendationType type;
  final List<PlaceRecommendation> recommendations;
  final String? basedOn; // e.g., "Based on your love for beaches"

  const RecommendationGroup({
    required this.type,
    required this.recommendations,
    this.basedOn,
  });

  bool get isEmpty => recommendations.isEmpty;
  bool get isNotEmpty => recommendations.isNotEmpty;
}

/// Recommendation engine that analyzes user preferences
class RecommendationEngine {
  /// Generate recommendations based on user's favorites
  static List<PlaceRecommendation> getBasedOnFavorites({
    required List<DiscoverPlace> allPlaces,
    required Set<String> favoriteIds,
    int limit = 5,
  }) {
    if (favoriteIds.isEmpty) return [];

    // Get favorite places
    final favorites = allPlaces.where((p) => favoriteIds.contains(p.placeId)).toList();
    if (favorites.isEmpty) return [];

    // Find the most common category among favorites
    final categoryCount = <PlaceCategory, int>{};
    for (final fav in favorites) {
      categoryCount[fav.category] = (categoryCount[fav.category] ?? 0) + 1;
    }

    final topCategory = categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Get non-favorite places in the same category
    final recommendations = allPlaces
        .where((p) =>
            !favoriteIds.contains(p.placeId) &&
            p.category == topCategory &&
            (p.rating ?? 0) >= 4.0)
        .map((place) => PlaceRecommendation(
          place: place,
          type: RecommendationType.basedOnFavorites,
          reason: 'Similar to your favorite ${topCategory.displayName.toLowerCase()}',
          matchScore: _calculateMatchScore(place, favorites),
        ))
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations.take(limit).toList();
  }

  /// Get places near the user
  static List<PlaceRecommendation> getNearYou({
    required List<DiscoverPlace> allPlaces,
    required double? userLat,
    required double? userLng,
    int limit = 5,
  }) {
    if (userLat == null || userLng == null) return [];

    final placesWithDistance = allPlaces
        .where((p) => p.latitude != null && p.longitude != null)
        .map((place) {
          final distance = place.distanceFrom(userLat, userLng) ?? double.infinity;
          return (place: place, distance: distance);
        })
        .where((item) => item.distance < 10) // Within 10km
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    return placesWithDistance
        .take(limit)
        .map((item) => PlaceRecommendation(
          place: item.place,
          type: RecommendationType.nearYou,
          reason: '${item.place.distanceText(userLat, userLng)} away',
          matchScore: 1.0 - (item.distance / 10).clamp(0.0, 1.0),
        ))
        .toList();
  }

  /// Get places perfect for the current time of day
  static List<PlaceRecommendation> getTimeOfDay({
    required List<DiscoverPlace> allPlaces,
    int limit = 5,
  }) {
    final hour = DateTime.now().hour;

    // Determine what's good for this time
    PlaceCategory? preferredCategory;
    String timeDescription;

    if (hour >= 6 && hour < 10) {
      // Morning - Nature, Religious
      preferredCategory = PlaceCategory.nature;
      timeDescription = 'Perfect for a morning walk';
    } else if (hour >= 10 && hour < 14) {
      // Late morning/Early afternoon - Heritage, Urban
      preferredCategory = PlaceCategory.heritage;
      timeDescription = 'Great time to explore';
    } else if (hour >= 14 && hour < 17) {
      // Afternoon - Beach, Adventure
      preferredCategory = PlaceCategory.beach;
      timeDescription = 'Ideal afternoon destination';
    } else if (hour >= 17 && hour < 20) {
      // Evening - Beach (sunset), Hill Station
      preferredCategory = PlaceCategory.hillStation;
      timeDescription = 'Beautiful at this hour';
    } else {
      // Night - Urban
      preferredCategory = PlaceCategory.urban;
      timeDescription = 'Great for evening entertainment';
    }

    final recommendations = allPlaces
        .where((p) => p.category == preferredCategory && p.openNow == true)
        .map((place) => PlaceRecommendation(
          place: place,
          type: RecommendationType.timeOfDay,
          reason: timeDescription,
          matchScore: (place.rating ?? 3.0) / 5.0,
        ))
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations.take(limit).toList();
  }

  /// Get seasonal recommendations
  static List<PlaceRecommendation> getSeasonal({
    required List<DiscoverPlace> allPlaces,
    int limit = 5,
  }) {
    final month = DateTime.now().month;

    // Determine season and preferred categories
    List<PlaceCategory> seasonalCategories;
    String seasonDescription;

    if (month >= 3 && month <= 5) {
      // Summer - Hill stations, beaches
      seasonalCategories = [PlaceCategory.hillStation, PlaceCategory.beach];
      seasonDescription = 'Perfect for summer';
    } else if (month >= 6 && month <= 9) {
      // Monsoon - Nature, waterfalls
      seasonalCategories = [PlaceCategory.nature, PlaceCategory.hillStation];
      seasonDescription = 'Beautiful during monsoon';
    } else if (month >= 10 && month <= 11) {
      // Post-monsoon - Wildlife, heritage
      seasonalCategories = [PlaceCategory.wildlife, PlaceCategory.heritage];
      seasonDescription = 'Ideal post-monsoon destination';
    } else {
      // Winter - Desert, beaches
      seasonalCategories = [PlaceCategory.beach, PlaceCategory.adventure];
      seasonDescription = 'Perfect winter escape';
    }

    final recommendations = allPlaces
        .where((p) => seasonalCategories.contains(p.category))
        .map((place) => PlaceRecommendation(
          place: place,
          type: RecommendationType.seasonal,
          reason: seasonDescription,
          matchScore: (place.rating ?? 3.0) / 5.0,
        ))
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations.take(limit).toList();
  }

  /// Get trending places (high ratings, many reviews)
  static List<PlaceRecommendation> getTrending({
    required List<DiscoverPlace> allPlaces,
    int limit = 5,
  }) {
    final recommendations = allPlaces
        .where((p) =>
            (p.rating ?? 0) >= 4.0 &&
            (p.userRatingsTotal ?? 0) >= 100)
        .map((place) {
          final trendScore = ((place.rating ?? 0) / 5.0) * 0.6 +
              ((place.userRatingsTotal ?? 0) / 1000).clamp(0.0, 0.4);
          return PlaceRecommendation(
            place: place,
            type: RecommendationType.trending,
            reason: '${place.userRatingsTotal} reviews • ${place.ratingText}',
            matchScore: trendScore,
          );
        })
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations.take(limit).toList();
  }

  /// Get hidden gems (high rating, low reviews)
  static List<PlaceRecommendation> getHiddenGems({
    required List<DiscoverPlace> allPlaces,
    int limit = 5,
  }) {
    final recommendations = allPlaces
        .where((p) =>
            (p.rating ?? 0) >= 4.2 &&
            (p.userRatingsTotal ?? 0) < 50 &&
            (p.userRatingsTotal ?? 0) >= 5)
        .map((place) => PlaceRecommendation(
          place: place,
          type: RecommendationType.hiddenGems,
          reason: 'Highly rated but less crowded',
          matchScore: (place.rating ?? 0) / 5.0,
        ))
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations.take(limit).toList();
  }

  /// Generate all recommendation groups
  static List<RecommendationGroup> generateAllRecommendations({
    required List<DiscoverPlace> allPlaces,
    required Set<String> favoriteIds,
    required double? userLat,
    required double? userLng,
  }) {
    final groups = <RecommendationGroup>[];

    // Based on favorites (if user has favorites)
    final favoriteBased = getBasedOnFavorites(
      allPlaces: allPlaces,
      favoriteIds: favoriteIds,
    );
    if (favoriteBased.isNotEmpty) {
      groups.add(RecommendationGroup(
        type: RecommendationType.basedOnFavorites,
        recommendations: favoriteBased,
        basedOn: 'Based on your ${favoriteBased.first.place.category.displayName.toLowerCase()} favorites',
      ));
    }

    // Near you
    final nearBy = getNearYou(
      allPlaces: allPlaces,
      userLat: userLat,
      userLng: userLng,
    );
    if (nearBy.isNotEmpty) {
      groups.add(RecommendationGroup(
        type: RecommendationType.nearYou,
        recommendations: nearBy,
      ));
    }

    // Hidden gems
    final gems = getHiddenGems(allPlaces: allPlaces);
    if (gems.isNotEmpty) {
      groups.add(RecommendationGroup(
        type: RecommendationType.hiddenGems,
        recommendations: gems,
      ));
    }

    // Trending
    final trending = getTrending(allPlaces: allPlaces);
    if (trending.isNotEmpty) {
      groups.add(RecommendationGroup(
        type: RecommendationType.trending,
        recommendations: trending,
      ));
    }

    // Time of day
    final timeRecs = getTimeOfDay(allPlaces: allPlaces);
    if (timeRecs.isNotEmpty) {
      groups.add(RecommendationGroup(
        type: RecommendationType.timeOfDay,
        recommendations: timeRecs,
      ));
    }

    // Seasonal
    final seasonal = getSeasonal(allPlaces: allPlaces);
    if (seasonal.isNotEmpty) {
      groups.add(RecommendationGroup(
        type: RecommendationType.seasonal,
        recommendations: seasonal,
      ));
    }

    return groups;
  }

  /// Calculate match score between a place and user's favorites
  static double _calculateMatchScore(DiscoverPlace place, List<DiscoverPlace> favorites) {
    double score = 0.0;

    // Rating similarity
    final avgFavRating = favorites.map((f) => f.rating ?? 0).reduce((a, b) => a + b) / favorites.length;
    final ratingDiff = ((place.rating ?? 0) - avgFavRating).abs();
    score += (1.0 - (ratingDiff / 5.0)) * 0.4;

    // Category match
    final favCategories = favorites.map((f) => f.category).toSet();
    if (favCategories.contains(place.category)) {
      score += 0.4;
    }

    // Base rating
    score += ((place.rating ?? 0) / 5.0) * 0.2;

    return score.clamp(0.0, 1.0);
  }
}
