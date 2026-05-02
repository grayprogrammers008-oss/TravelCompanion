import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/data/datasources/discover_local_datasource.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';

/// Helper to build a [DiscoverPlace] entity for tests.
DiscoverPlace _buildPlace({
  String placeId = 'place-1',
  String name = 'Test Place',
  PlaceCategory category = PlaceCategory.beach,
  double? latitude = 12.97,
  double? longitude = 77.59,
  double? rating = 4.5,
  int? userRatingsTotal = 200,
  bool? openNow = true,
  String? vicinity = 'Some street',
  List<String> types = const ['point_of_interest'],
  List<PlacePhoto> photos = const [
    PlacePhoto(
      photoReference: 'ref-1',
      width: 400,
      height: 300,
      htmlAttributions: ['<a>Photographer</a>'],
    ),
  ],
}) {
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('discover_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup
    }
  });

  late DiscoverLocalDataSource ds;

  setUp(() async {
    ds = DiscoverLocalDataSource();
    await ds.initialize();
    // Always start each test with empty caches.
    await ds.clearAllCache();
    // Also wipe favorites box (clearAllCache deliberately preserves it).
    final favBox = Hive.box<Map>('discover_favorites');
    await favBox.clear();
  });

  tearDown(() async {
    await ds.clearAllCache();
    final favBox = Hive.box<Map>('discover_favorites');
    await favBox.clear();
  });

  group('initialize / availability', () {
    test('initialize() opens all required boxes', () {
      expect(ds.isAvailable, isTrue);
      expect(Hive.isBoxOpen('discover_places'), isTrue);
      expect(Hive.isBoxOpen('discover_favorites'), isTrue);
      expect(Hive.isBoxOpen('discover_metadata'), isTrue);
      expect(Hive.isBoxOpen('discover_photo_urls'), isTrue);
    });

    test('initialize() is idempotent and can be called multiple times', () async {
      await ds.initialize();
      await ds.initialize();
      expect(ds.isAvailable, isTrue);
    });

    test('isAvailable returns true after initialization', () {
      expect(ds.isAvailable, isTrue);
    });
  });

  group('savePlaces / getPlaces round-trip', () {
    test('round-trips a single place', () async {
      final place = _buildPlace(placeId: 'p-1', name: 'Sunny Beach');
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [place],
        latitude: 12.9716,
        longitude: 77.5946,
      );

      final fetched = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(fetched, isNotNull);
      expect(fetched!.length, 1);
      expect(fetched.first.placeId, 'p-1');
      expect(fetched.first.name, 'Sunny Beach');
      expect(fetched.first.category, PlaceCategory.beach);
      expect(fetched.first.rating, 4.5);
      expect(fetched.first.photos.length, 1);
      expect(fetched.first.photos.first.photoReference, 'ref-1');
    });

    test('round-trips multiple places preserving order', () async {
      final places = List<DiscoverPlace>.generate(
        5,
        (i) => _buildPlace(placeId: 'p-$i', name: 'Place $i'),
      );

      await ds.savePlaces(
        category: PlaceCategory.nature,
        places: places,
        latitude: 10.0,
        longitude: 20.0,
      );

      final fetched = await ds.getPlaces(
        category: PlaceCategory.nature,
        latitude: 10.0,
        longitude: 20.0,
      );

      expect(fetched, isNotNull);
      expect(fetched!.length, 5);
      for (var i = 0; i < 5; i++) {
        expect(fetched[i].placeId, 'p-$i');
      }
    });

    test('handles empty places list', () async {
      await ds.savePlaces(
        category: PlaceCategory.urban,
        places: const [],
        latitude: 1.0,
        longitude: 2.0,
      );

      final fetched = await ds.getPlaces(
        category: PlaceCategory.urban,
        latitude: 1.0,
        longitude: 2.0,
      );

      expect(fetched, isNotNull);
      expect(fetched, isEmpty);
    });

    test('cache key uses ~1km rounded coordinates - close coords share cache',
        () async {
      // 12.971 and 12.974 both round to 12.97 (2-decimal-place precision).
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(placeId: 'rounded-1')],
        latitude: 12.971,
        longitude: 77.591,
      );

      // Slightly different coords that round to the same key.
      final fetched = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 12.974,
        longitude: 77.594,
      );

      expect(fetched, isNotNull);
      expect(fetched!.length, 1);
      expect(fetched.first.placeId, 'rounded-1');
    });

    test('different coordinates miss the cache', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(placeId: 'one')],
        latitude: 12.97,
        longitude: 77.59,
      );

      // Far away (> 1km) — should NOT hit the same cache key.
      final fetched = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 40.71,
        longitude: -74.00,
      );

      expect(fetched, isNull);
    });

    test('different categories at same coords are cached separately', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(placeId: 'b-1', category: PlaceCategory.beach)],
        latitude: 12.97,
        longitude: 77.59,
      );
      await ds.savePlaces(
        category: PlaceCategory.heritage,
        places: [_buildPlace(placeId: 'h-1', category: PlaceCategory.heritage)],
        latitude: 12.97,
        longitude: 77.59,
      );

      final beach = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 12.97,
        longitude: 77.59,
      );
      final heritage = await ds.getPlaces(
        category: PlaceCategory.heritage,
        latitude: 12.97,
        longitude: 77.59,
      );

      expect(beach!.first.placeId, 'b-1');
      expect(heritage!.first.placeId, 'h-1');
    });

    test('getPlaces returns null when nothing cached', () async {
      final fetched = await ds.getPlaces(
        category: PlaceCategory.adventure,
        latitude: 0.0,
        longitude: 0.0,
      );
      expect(fetched, isNull);
    });

    test('savePlaces caps stored entries at the per-category limit (100)',
        () async {
      final many = List<DiscoverPlace>.generate(
        150,
        (i) => _buildPlace(placeId: 'big-$i'),
      );

      await ds.savePlaces(
        category: PlaceCategory.urban,
        places: many,
        latitude: 5.0,
        longitude: 5.0,
      );

      final fetched = await ds.getPlaces(
        category: PlaceCategory.urban,
        latitude: 5.0,
        longitude: 5.0,
      );

      expect(fetched, isNotNull);
      expect(fetched!.length, 100);
    });

    test('overwriting an existing cache key replaces the data', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(placeId: 'first')],
        latitude: 1.0,
        longitude: 1.0,
      );
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [
          _buildPlace(placeId: 'second-a'),
          _buildPlace(placeId: 'second-b'),
        ],
        latitude: 1.0,
        longitude: 1.0,
      );

      final fetched = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 1.0,
        longitude: 1.0,
      );
      expect(fetched!.map((p) => p.placeId).toList(), ['second-a', 'second-b']);
    });
  });

  group('hasCachedPlaces', () {
    test('returns false when nothing cached', () async {
      final has = await ds.hasCachedPlaces(
        category: PlaceCategory.beach,
        latitude: 1.0,
        longitude: 1.0,
      );
      expect(has, isFalse);
    });

    test('returns true after savePlaces', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace()],
        latitude: 1.0,
        longitude: 1.0,
      );

      final has = await ds.hasCachedPlaces(
        category: PlaceCategory.beach,
        latitude: 1.0,
        longitude: 1.0,
      );
      expect(has, isTrue);
    });

    test('returns false when cache is expired (>24h)', () async {
      // Manually plant an expired cache entry.
      final expired = DateTime.now().subtract(const Duration(hours: 25));
      final placesBox = Hive.box<Map>('discover_places');
      await placesBox.put('beach_1.0_1.0', {
        'places': <Map<String, dynamic>>[],
        'cached_at': expired.toIso8601String(),
      });

      final has = await ds.hasCachedPlaces(
        category: PlaceCategory.beach,
        latitude: 1.0,
        longitude: 1.0,
      );
      expect(has, isFalse);
    });
  });

  group('getPlaces expiry handling', () {
    test('returns null when cache entry is older than 24h', () async {
      final expired = DateTime.now().subtract(const Duration(hours: 25));
      final placesBox = Hive.box<Map>('discover_places');
      await placesBox.put('beach_2.0_2.0', {
        'places': <Map<String, dynamic>>[],
        'cached_at': expired.toIso8601String(),
      });

      final fetched = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 2.0,
        longitude: 2.0,
      );
      expect(fetched, isNull);
    });

    test('returns cached data even when expired if ignoreExpiry is true',
        () async {
      final expired = DateTime.now().subtract(const Duration(hours: 30));
      final placesBox = Hive.box<Map>('discover_places');
      await placesBox.put('beach_3.0_3.0', {
        'places': [
          {
            'place_id': 'old-1',
            'name': 'Old Place',
            'vicinity': null,
            'latitude': 3.0,
            'longitude': 3.0,
            'types': <String>[],
            'rating': null,
            'user_ratings_total': null,
            'open_now': null,
            'photos': <Map<String, dynamic>>[],
            'category_name': PlaceCategory.beach.name,
            'cached_at': expired.toIso8601String(),
          }
        ],
        'cached_at': expired.toIso8601String(),
      });

      final fetched = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 3.0,
        longitude: 3.0,
        ignoreExpiry: true,
      );

      expect(fetched, isNotNull);
      expect(fetched!.length, 1);
      expect(fetched.first.placeId, 'old-1');
    });
  });

  group('favorites (IDs)', () {
    test('getFavorites returns empty set initially', () async {
      final favs = await ds.getFavorites();
      expect(favs, isEmpty);
    });

    test('saveFavorites + getFavorites round-trip', () async {
      await ds.saveFavorites({'a', 'b', 'c'});
      final favs = await ds.getFavorites();
      expect(favs, equals({'a', 'b', 'c'}));
    });

    test('saveFavorites overwrites previous set', () async {
      await ds.saveFavorites({'a', 'b'});
      await ds.saveFavorites({'x'});
      final favs = await ds.getFavorites();
      expect(favs, equals({'x'}));
    });

    test('addFavorite adds an id', () async {
      await ds.addFavorite('alpha');
      await ds.addFavorite('beta');
      final favs = await ds.getFavorites();
      expect(favs, equals({'alpha', 'beta'}));
    });

    test('addFavorite is idempotent (Set semantics)', () async {
      await ds.addFavorite('alpha');
      await ds.addFavorite('alpha');
      final favs = await ds.getFavorites();
      expect(favs.length, 1);
      expect(favs.contains('alpha'), isTrue);
    });

    test('removeFavorite removes an id', () async {
      await ds.saveFavorites({'a', 'b', 'c'});
      await ds.removeFavorite('b');
      final favs = await ds.getFavorites();
      expect(favs, equals({'a', 'c'}));
    });

    test('removeFavorite on missing id is a no-op', () async {
      await ds.saveFavorites({'a'});
      await ds.removeFavorite('nonexistent');
      final favs = await ds.getFavorites();
      expect(favs, equals({'a'}));
    });
  });

  group('favorite places (full data)', () {
    test('getFavoritePlaces returns empty list initially', () async {
      final favs = await ds.getFavoritePlaces();
      expect(favs, isEmpty);
    });

    test('saveFavoritePlace + getFavoritePlaces round-trip', () async {
      final place = _buildPlace(placeId: 'fav-1', name: 'Loved Place');
      await ds.saveFavoritePlace(place);

      final favs = await ds.getFavoritePlaces();
      expect(favs.length, 1);
      expect(favs.first.placeId, 'fav-1');
      expect(favs.first.name, 'Loved Place');
    });

    test('saveFavoritePlace can store many distinct places', () async {
      await ds.saveFavoritePlace(_buildPlace(placeId: 'a'));
      await ds.saveFavoritePlace(_buildPlace(placeId: 'b'));
      await ds.saveFavoritePlace(_buildPlace(placeId: 'c'));

      final favs = await ds.getFavoritePlaces();
      expect(favs.length, 3);
      expect(
        favs.map((p) => p.placeId).toSet(),
        equals({'a', 'b', 'c'}),
      );
    });

    test('saveFavoritePlace upserts an existing id', () async {
      await ds.saveFavoritePlace(_buildPlace(placeId: 'x', name: 'Old Name'));
      await ds.saveFavoritePlace(_buildPlace(placeId: 'x', name: 'New Name'));

      final favs = await ds.getFavoritePlaces();
      expect(favs.length, 1);
      expect(favs.first.name, 'New Name');
    });

    test('removeFavoritePlace removes by id', () async {
      await ds.saveFavoritePlace(_buildPlace(placeId: 'a'));
      await ds.saveFavoritePlace(_buildPlace(placeId: 'b'));
      await ds.removeFavoritePlace('a');

      final favs = await ds.getFavoritePlaces();
      expect(favs.length, 1);
      expect(favs.first.placeId, 'b');
    });

    test('removeFavoritePlace on empty store is a no-op', () async {
      await ds.removeFavoritePlace('nope');
      final favs = await ds.getFavoritePlaces();
      expect(favs, isEmpty);
    });
  });

  group('photo URL caching', () {
    test('getCachedPhotoUrl returns null for unknown reference', () async {
      final url = await ds.getCachedPhotoUrl('does-not-exist');
      expect(url, isNull);
    });

    test('cachePhotoUrl + getCachedPhotoUrl round-trip', () async {
      await ds.cachePhotoUrl(
        photoReference: 'ref-abc',
        url: 'https://example.com/photo.jpg',
      );

      final url = await ds.getCachedPhotoUrl('ref-abc');
      expect(url, 'https://example.com/photo.jpg');
    });

    test('cachePhotoUrl overwrites existing entry', () async {
      await ds.cachePhotoUrl(
        photoReference: 'r',
        url: 'https://old.example.com',
      );
      await ds.cachePhotoUrl(
        photoReference: 'r',
        url: 'https://new.example.com',
      );

      final url = await ds.getCachedPhotoUrl('r');
      expect(url, 'https://new.example.com');
    });

    test('getCachedPhotoUrl returns null for malformed cached data', () async {
      // Plant a malformed entry directly.
      final box = Hive.box<String>('discover_photo_urls');
      await box.put('photo_bad', 'no-pipe-here');

      final url = await ds.getCachedPhotoUrl('bad');
      expect(url, isNull);
    });

    test('getCachedPhotoUrl deletes and returns null when expired', () async {
      // Plant an expired entry directly.
      final box = Hive.box<String>('discover_photo_urls');
      final expiry =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      await box.put('photo_expired', 'https://expired.example.com|$expiry');

      final url = await ds.getCachedPhotoUrl('expired');
      expect(url, isNull);
      // Cleanup: should also have been deleted from the box.
      expect(box.get('photo_expired'), isNull);
    });
  });

  group('clearCategoryCache', () {
    test('clears only entries for the targeted category', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(placeId: 'b-1')],
        latitude: 1.0,
        longitude: 1.0,
      );
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(placeId: 'b-2')],
        latitude: 5.0,
        longitude: 5.0,
      );
      await ds.savePlaces(
        category: PlaceCategory.heritage,
        places: [_buildPlace(placeId: 'h-1')],
        latitude: 1.0,
        longitude: 1.0,
      );

      await ds.clearCategoryCache(PlaceCategory.beach);

      final beachAtOne = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 1.0,
        longitude: 1.0,
      );
      final beachAtFive = await ds.getPlaces(
        category: PlaceCategory.beach,
        latitude: 5.0,
        longitude: 5.0,
      );
      final heritageAtOne = await ds.getPlaces(
        category: PlaceCategory.heritage,
        latitude: 1.0,
        longitude: 1.0,
      );

      expect(beachAtOne, isNull);
      expect(beachAtFive, isNull);
      expect(heritageAtOne, isNotNull);
      expect(heritageAtOne!.first.placeId, 'h-1');
    });

    test('is a no-op when no matching keys exist', () async {
      await ds.clearCategoryCache(PlaceCategory.adventure);
      // Should not throw and stats should remain zero.
      final stats = await ds.getCacheStats();
      expect(stats['places_entries'], 0);
    });
  });

  group('clearAllCache', () {
    test('clears places, metadata, and photo URLs', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace()],
        latitude: 1.0,
        longitude: 1.0,
      );
      await ds.cachePhotoUrl(
        photoReference: 'pr',
        url: 'https://example.com',
      );

      await ds.clearAllCache();

      final placesBox = Hive.box<Map>('discover_places');
      final metaBox = Hive.box<Map>('discover_metadata');
      final photoBox = Hive.box<String>('discover_photo_urls');
      expect(placesBox.length, 0);
      expect(metaBox.length, 0);
      expect(photoBox.length, 0);
    });

    test('preserves favorites (user data)', () async {
      await ds.saveFavorites({'keepme'});
      await ds.saveFavoritePlace(_buildPlace(placeId: 'fav'));
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace()],
        latitude: 1.0,
        longitude: 1.0,
      );

      await ds.clearAllCache();

      final favs = await ds.getFavorites();
      expect(favs, equals({'keepme'}));

      final favPlaces = await ds.getFavoritePlaces();
      expect(favPlaces.length, 1);
      expect(favPlaces.first.placeId, 'fav');
    });
  });

  group('getCacheStats', () {
    test('reports zeros on a fresh instance', () async {
      final stats = await ds.getCacheStats();
      expect(stats['places_entries'], 0);
      expect(stats['favorites_count'], 0);
      expect(stats['photo_urls_cached'], 0);
      expect(stats['metadata_entries'], 0);
    });

    test('reflects added entries', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace()],
        latitude: 1.0,
        longitude: 1.0,
      );
      await ds.savePlaces(
        category: PlaceCategory.heritage,
        places: [_buildPlace()],
        latitude: 2.0,
        longitude: 2.0,
      );
      await ds.saveFavorites({'a', 'b', 'c'});
      await ds.cachePhotoUrl(
        photoReference: 'r1',
        url: 'https://e.com/1',
      );
      await ds.cachePhotoUrl(
        photoReference: 'r2',
        url: 'https://e.com/2',
      );

      final stats = await ds.getCacheStats();
      expect(stats['places_entries'], 2);
      expect(stats['favorites_count'], 3);
      expect(stats['photo_urls_cached'], 2);
      expect(stats['metadata_entries'], 2);
    });
  });

  group('getCacheSize', () {
    test('returns 0 immediately after clearAllCache + favorites cleared',
        () async {
      // setUp already cleared everything, including favorites.
      final size = await ds.getCacheSize();
      expect(size, greaterThanOrEqualTo(0));
      expect(size, 0);
    });

    test('returns a positive number when entries exist', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace()],
        latitude: 1.0,
        longitude: 1.0,
      );
      await ds.cachePhotoUrl(
        photoReference: 'r1',
        url: 'https://example.com/photo.jpg',
      );
      await ds.saveFavorites({'a'});

      final size = await ds.getCacheSize();
      expect(size, greaterThan(0));
    });
  });

  group('getMetadata', () {
    test('returns null for unknown key', () async {
      final meta = await ds.getMetadata('totally_unknown');
      expect(meta, isNull);
    });

    test('returns metadata for a saved cache entry', () async {
      await ds.savePlaces(
        category: PlaceCategory.beach,
        places: [_buildPlace(), _buildPlace(placeId: 'p-2')],
        latitude: 12.97,
        longitude: 77.59,
      );

      // Cache key matches the rounded-coords scheme used internally.
      final meta = await ds.getMetadata('beach_12.97_77.59');
      expect(meta, isNotNull);
      expect(meta!.itemCount, 2);
      expect(meta.latitude, 12.97);
      expect(meta.longitude, 77.59);
    });
  });
}
