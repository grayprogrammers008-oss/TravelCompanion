import '../../../../core/services/google_places_service.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/discover_place.dart';

/// Model class for DiscoverPlace with JSON serialization for Hive storage
class DiscoverPlaceModel {
  final String placeId;
  final String name;
  final String? vicinity;
  final double? latitude;
  final double? longitude;
  final List<String> types;
  final double? rating;
  final int? userRatingsTotal;
  final bool? openNow;
  final List<PlacePhotoModel> photos;
  final String categoryName; // Store as string for serialization
  final DateTime cachedAt;

  const DiscoverPlaceModel({
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
    required this.categoryName,
    required this.cachedAt,
  });

  /// Create from DiscoverPlace entity
  factory DiscoverPlaceModel.fromEntity(DiscoverPlace entity) {
    return DiscoverPlaceModel(
      placeId: entity.placeId,
      name: entity.name,
      vicinity: entity.vicinity,
      latitude: entity.latitude,
      longitude: entity.longitude,
      types: entity.types,
      rating: entity.rating,
      userRatingsTotal: entity.userRatingsTotal,
      openNow: entity.openNow,
      photos: entity.photos.map((p) => PlacePhotoModel.fromPlacePhoto(p)).toList(),
      categoryName: entity.category.name,
      cachedAt: DateTime.now(),
    );
  }

  /// Create from JSON (Hive storage)
  factory DiscoverPlaceModel.fromJson(Map<String, dynamic> json) {
    return DiscoverPlaceModel(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      vicinity: json['vicinity'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      openNow: json['open_now'] as bool?,
      photos: (json['photos'] as List?)
              ?.map((p) => PlacePhotoModel.fromJson(Map<String, dynamic>.from(p)))
              .toList() ??
          [],
      categoryName: json['category_name'] as String,
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );
  }

  /// Convert to JSON for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'name': name,
      'vicinity': vicinity,
      'latitude': latitude,
      'longitude': longitude,
      'types': types,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'open_now': openNow,
      'photos': photos.map((p) => p.toJson()).toList(),
      'category_name': categoryName,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  /// Convert to DiscoverPlace entity
  DiscoverPlace toEntity() {
    final category = PlaceCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => PlaceCategory.nature,
    );

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
      photos: photos.map((p) => p.toPlacePhoto()).toList(),
      category: category,
    );
  }

  /// Check if cache is expired (24 hours for places)
  bool get isExpired {
    const cacheDuration = Duration(hours: 24);
    return DateTime.now().difference(cachedAt) > cacheDuration;
  }
}

/// Model for PlacePhoto serialization
class PlacePhotoModel {
  final String photoReference;
  final int? width;
  final int? height;
  final List<String> htmlAttributions;

  const PlacePhotoModel({
    required this.photoReference,
    this.width,
    this.height,
    this.htmlAttributions = const [],
  });

  factory PlacePhotoModel.fromPlacePhoto(PlacePhoto photo) {
    return PlacePhotoModel(
      photoReference: photo.photoReference,
      width: photo.width,
      height: photo.height,
      htmlAttributions: photo.htmlAttributions,
    );
  }

  factory PlacePhotoModel.fromJson(Map<String, dynamic> json) {
    return PlacePhotoModel(
      photoReference: json['photo_reference'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      htmlAttributions: List<String>.from(json['html_attributions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_reference': photoReference,
      'width': width,
      'height': height,
      'html_attributions': htmlAttributions,
    };
  }

  PlacePhoto toPlacePhoto() {
    return PlacePhoto(
      photoReference: photoReference,
      width: width ?? 0,
      height: height ?? 0,
      htmlAttributions: htmlAttributions,
    );
  }
}

/// Model for caching favorites
class FavoritesModel {
  final Set<String> favoriteIds;
  final DateTime updatedAt;

  const FavoritesModel({
    required this.favoriteIds,
    required this.updatedAt,
  });

  factory FavoritesModel.fromJson(Map<String, dynamic> json) {
    return FavoritesModel(
      favoriteIds: Set<String>.from(json['favorite_ids'] ?? []),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorite_ids': favoriteIds.toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Model for cache metadata
class DiscoverCacheMetadata {
  final String key;
  final DateTime cachedAt;
  final int itemCount;
  final double? latitude;
  final double? longitude;

  const DiscoverCacheMetadata({
    required this.key,
    required this.cachedAt,
    required this.itemCount,
    this.latitude,
    this.longitude,
  });

  factory DiscoverCacheMetadata.fromJson(Map<String, dynamic> json) {
    return DiscoverCacheMetadata(
      key: json['key'] as String,
      cachedAt: DateTime.parse(json['cached_at'] as String),
      itemCount: json['item_count'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'cached_at': cachedAt.toIso8601String(),
      'item_count': itemCount,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Check if cache is expired
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
