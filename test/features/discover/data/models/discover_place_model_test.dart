import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/data/models/discover_place_model.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';

void main() {
  group('PlacePhotoModel', () {
    test('fromPlacePhoto copies fields', () {
      const original = PlacePhoto(
        photoReference: 'ref-1',
        width: 800,
        height: 600,
        htmlAttributions: ['<a>Photographer</a>'],
      );
      final model = PlacePhotoModel.fromPlacePhoto(original);
      expect(model.photoReference, 'ref-1');
      expect(model.width, 800);
      expect(model.height, 600);
      expect(model.htmlAttributions, ['<a>Photographer</a>']);
    });

    test('toJson / fromJson round-trip', () {
      const model = PlacePhotoModel(
        photoReference: 'r',
        width: 100,
        height: 200,
        htmlAttributions: ['html'],
      );
      final json = model.toJson();
      final back = PlacePhotoModel.fromJson(json);
      expect(back.photoReference, model.photoReference);
      expect(back.width, model.width);
      expect(back.height, model.height);
      expect(back.htmlAttributions, model.htmlAttributions);
    });

    test('fromJson handles missing optional fields', () {
      final model = PlacePhotoModel.fromJson({'photo_reference': 'r'});
      expect(model.photoReference, 'r');
      expect(model.width, isNull);
      expect(model.height, isNull);
      expect(model.htmlAttributions, isEmpty);
    });

    test('toPlacePhoto produces a PlacePhoto with default 0 dimensions when null', () {
      const model = PlacePhotoModel(photoReference: 'r');
      final photo = model.toPlacePhoto();
      expect(photo.photoReference, 'r');
      expect(photo.width, 0);
      expect(photo.height, 0);
      expect(photo.htmlAttributions, isEmpty);
    });
  });

  group('DiscoverPlaceModel', () {
    final entity = DiscoverPlace(
      placeId: 'p-42',
      name: 'Marina Beach',
      vicinity: 'Chennai',
      latitude: 13.05,
      longitude: 80.28,
      types: const ['point_of_interest', 'tourist_attraction'],
      rating: 4.3,
      userRatingsTotal: 25000,
      openNow: true,
      photos: const [
        PlacePhoto(photoReference: 'a', width: 1, height: 2, htmlAttributions: []),
      ],
      category: PlaceCategory.beach,
    );

    test('fromEntity carries fields and stamps cachedAt', () {
      final before = DateTime.now();
      final model = DiscoverPlaceModel.fromEntity(entity);
      final after = DateTime.now();
      expect(model.placeId, entity.placeId);
      expect(model.name, entity.name);
      expect(model.vicinity, entity.vicinity);
      expect(model.latitude, entity.latitude);
      expect(model.longitude, entity.longitude);
      expect(model.types, entity.types);
      expect(model.rating, entity.rating);
      expect(model.userRatingsTotal, entity.userRatingsTotal);
      expect(model.openNow, entity.openNow);
      expect(model.photos, hasLength(1));
      expect(model.categoryName, 'beach');
      expect(model.cachedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(model.cachedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('toEntity reconstructs the entity from the stored model', () {
      final model = DiscoverPlaceModel.fromEntity(entity);
      final back = model.toEntity();
      expect(back.placeId, entity.placeId);
      expect(back.name, entity.name);
      expect(back.category, entity.category);
      expect(back.photos.first.photoReference, 'a');
      // isFavorite is not part of the cache; defaults to false
      expect(back.isFavorite, isFalse);
    });

    test('toEntity falls back to PlaceCategory.nature for unknown category', () {
      final model = DiscoverPlaceModel(
        placeId: 'p',
        name: 'X',
        types: const [],
        photos: const [],
        categoryName: 'martian-canyons',
        cachedAt: DateTime.now(),
      );
      expect(model.toEntity().category, PlaceCategory.nature);
    });

    test('toJson / fromJson round-trip preserves all fields', () {
      final model = DiscoverPlaceModel.fromEntity(entity);
      final json = model.toJson();
      final back = DiscoverPlaceModel.fromJson(json);
      expect(back.placeId, model.placeId);
      expect(back.name, model.name);
      expect(back.vicinity, model.vicinity);
      expect(back.latitude, model.latitude);
      expect(back.longitude, model.longitude);
      expect(back.types, model.types);
      expect(back.rating, model.rating);
      expect(back.userRatingsTotal, model.userRatingsTotal);
      expect(back.openNow, model.openNow);
      expect(back.photos.length, model.photos.length);
      expect(back.categoryName, model.categoryName);
      // cachedAt round-trips through ISO 8601 (microsecond precision may drop)
      expect(
        back.cachedAt.difference(model.cachedAt).inMicroseconds.abs(),
        lessThan(1000),
      );
    });

    test('fromJson handles missing optional fields and empty photos list', () {
      final json = {
        'place_id': 'p',
        'name': 'Name',
        'types': <String>[],
        'category_name': 'urban',
        'cached_at': DateTime(2025, 6, 1).toIso8601String(),
      };
      final model = DiscoverPlaceModel.fromJson(json);
      expect(model.placeId, 'p');
      expect(model.vicinity, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.rating, isNull);
      expect(model.userRatingsTotal, isNull);
      expect(model.openNow, isNull);
      expect(model.photos, isEmpty);
    });

    group('isExpired', () {
      test('false when cached <24h ago', () {
        final model = DiscoverPlaceModel(
          placeId: 'p',
          name: 'X',
          types: const [],
          photos: const [],
          categoryName: 'nature',
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        expect(model.isExpired, isFalse);
      });

      test('true when cached >24h ago', () {
        final model = DiscoverPlaceModel(
          placeId: 'p',
          name: 'X',
          types: const [],
          photos: const [],
          categoryName: 'nature',
          cachedAt: DateTime.now().subtract(const Duration(hours: 25)),
        );
        expect(model.isExpired, isTrue);
      });
    });
  });

  group('FavoritesModel', () {
    test('toJson / fromJson round-trip', () {
      final original = FavoritesModel(
        favoriteIds: const {'a', 'b', 'c'},
        updatedAt: DateTime(2025, 6, 1, 12, 0),
      );
      final back = FavoritesModel.fromJson(original.toJson());
      expect(back.favoriteIds, original.favoriteIds);
      expect(back.updatedAt, original.updatedAt);
    });

    test('fromJson handles missing favorite_ids', () {
      final model = FavoritesModel.fromJson({
        'updated_at': DateTime(2025).toIso8601String(),
      });
      expect(model.favoriteIds, isEmpty);
    });
  });

  group('DiscoverCacheMetadata', () {
    test('toJson / fromJson round-trip', () {
      final original = DiscoverCacheMetadata(
        key: 'beach_12.97_77.59',
        cachedAt: DateTime(2025, 1, 1),
        itemCount: 15,
        latitude: 12.97,
        longitude: 77.59,
      );
      final back = DiscoverCacheMetadata.fromJson(original.toJson());
      expect(back.key, original.key);
      expect(back.cachedAt, original.cachedAt);
      expect(back.itemCount, original.itemCount);
      expect(back.latitude, original.latitude);
      expect(back.longitude, original.longitude);
    });

    test('isExpired compares against custom max-age', () {
      final fresh = DiscoverCacheMetadata(
        key: 'k',
        cachedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        itemCount: 1,
      );
      expect(fresh.isExpired(const Duration(hours: 1)), isFalse);
      expect(fresh.isExpired(const Duration(minutes: 5)), isTrue);
    });
  });
}
