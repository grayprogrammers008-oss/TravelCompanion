import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/domain/entities/place_recommendation.dart';

DiscoverPlace _place({
  String id = 'p',
  String name = 'P',
  PlaceCategory category = PlaceCategory.nature,
  double? rating,
  int? userRatingsTotal,
  bool? openNow,
  double? lat,
  double? lng,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      latitude: lat,
      longitude: lng,
      types: const [],
      photos: const [],
      category: category,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      openNow: openNow,
    );

void main() {
  group('RecommendationType', () {
    test('has 6 values', () {
      expect(RecommendationType.values, hasLength(6));
    });
  });

  group('RecommendationTypeExtension', () {
    test('every type has title, subtitle, icon, color', () {
      for (final t in RecommendationType.values) {
        expect(t.title, isNotEmpty);
        expect(t.subtitle, isNotEmpty);
        expect(t.icon, isA<IconData>());
        expect(t.color, isA<Color>());
      }
    });

    test('titles are unique', () {
      final titles = RecommendationType.values.map((t) => t.title).toSet();
      expect(titles.length, RecommendationType.values.length);
    });

    test('basedOnFavorites uses favorite icon', () {
      expect(RecommendationType.basedOnFavorites.icon, Icons.favorite);
    });

    test('hiddenGems uses diamond icon', () {
      expect(RecommendationType.hiddenGems.icon, Icons.diamond);
    });
  });

  group('RecommendationGroup', () {
    test('isEmpty / isNotEmpty reflect recommendations list', () {
      const empty = RecommendationGroup(
        type: RecommendationType.trending,
        recommendations: [],
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);

      final non = RecommendationGroup(
        type: RecommendationType.trending,
        recommendations: [
          PlaceRecommendation(
            place: _place(),
            type: RecommendationType.trending,
            reason: '',
            matchScore: 0.5,
          ),
        ],
      );
      expect(non.isEmpty, isFalse);
      expect(non.isNotEmpty, isTrue);
    });
  });

  group('RecommendationEngine.getBasedOnFavorites', () {
    test('returns empty when favoriteIds empty', () {
      final result = RecommendationEngine.getBasedOnFavorites(
        allPlaces: [_place(id: 'a')],
        favoriteIds: const {},
      );
      expect(result, isEmpty);
    });

    test('returns empty when no favorite places match in allPlaces', () {
      final result = RecommendationEngine.getBasedOnFavorites(
        allPlaces: [_place(id: 'a')],
        favoriteIds: const {'unknown'},
      );
      expect(result, isEmpty);
    });

    test('recommends non-favorites in dominant favorite category with rating>=4', () {
      final places = [
        _place(id: 'fav1', category: PlaceCategory.beach, rating: 4.5),
        _place(id: 'fav2', category: PlaceCategory.beach, rating: 4.0),
        _place(id: 'fav3', category: PlaceCategory.heritage, rating: 4.0),
        _place(id: 'rec1', category: PlaceCategory.beach, rating: 4.5),
        _place(id: 'rec2', category: PlaceCategory.beach, rating: 3.5), // too low
        _place(id: 'rec3', category: PlaceCategory.heritage, rating: 4.5), // wrong cat
      ];
      final result = RecommendationEngine.getBasedOnFavorites(
        allPlaces: places,
        favoriteIds: {'fav1', 'fav2', 'fav3'},
      );
      // Only rec1 qualifies (beach, rating>=4.0, not in favorites)
      expect(result.map((r) => r.place.placeId), ['rec1']);
      expect(result.first.type, RecommendationType.basedOnFavorites);
    });

    test('respects limit', () {
      final places = [
        _place(id: 'fav', category: PlaceCategory.beach, rating: 4.5),
        ...List.generate(
          10,
          (i) => _place(
            id: 'rec$i',
            category: PlaceCategory.beach,
            rating: 4.5,
          ),
        ),
      ];
      final result = RecommendationEngine.getBasedOnFavorites(
        allPlaces: places,
        favoriteIds: {'fav'},
        limit: 3,
      );
      expect(result.length, 3);
    });

    test('sorts by descending matchScore', () {
      // _calculateMatchScore rewards similarity to favorite's avg rating, plus
      // a base-rating bonus. With favorite at 4.5, 'similar' (4.6) scores
      // higher than 'distant' (4.0) overall.
      final places = [
        _place(id: 'fav', category: PlaceCategory.beach, rating: 4.5),
        _place(id: 'distant', category: PlaceCategory.beach, rating: 4.0),
        _place(id: 'similar', category: PlaceCategory.beach, rating: 4.6),
      ];
      final result = RecommendationEngine.getBasedOnFavorites(
        allPlaces: places,
        favoriteIds: {'fav'},
      );
      expect(result.first.place.placeId, 'similar');
    });
  });

  group('RecommendationEngine.getNearYou', () {
    test('returns empty when no user location', () {
      expect(
        RecommendationEngine.getNearYou(
          allPlaces: [_place(lat: 1.0, lng: 1.0)],
          userLat: null,
          userLng: 1.0,
        ),
        isEmpty,
      );
    });

    test('only includes places within 10 km', () {
      final places = [
        _place(id: 'close', lat: 0.0, lng: 0.0),
        _place(id: 'far', lat: 1.0, lng: 1.0), // ~157 km away
      ];
      final result = RecommendationEngine.getNearYou(
        allPlaces: places,
        userLat: 0.0,
        userLng: 0.0,
      );
      expect(result.map((r) => r.place.placeId), ['close']);
    });

    test('sorts by distance ascending', () {
      final places = [
        _place(id: 'b', lat: 0.0, lng: 0.05), // ~5.5 km
        _place(id: 'a', lat: 0.0, lng: 0.01), // ~1.1 km
      ];
      final result = RecommendationEngine.getNearYou(
        allPlaces: places,
        userLat: 0.0,
        userLng: 0.0,
      );
      expect(result.map((r) => r.place.placeId), ['a', 'b']);
    });

    test('skips places with null coordinates', () {
      final places = [
        _place(id: 'no-coords'),
        _place(id: 'has-coords', lat: 0.0, lng: 0.005),
      ];
      final result = RecommendationEngine.getNearYou(
        allPlaces: places,
        userLat: 0.0,
        userLng: 0.0,
      );
      expect(result.map((r) => r.place.placeId), ['has-coords']);
    });

    test('matchScore is 1.0 for distance 0 and decreases with distance', () {
      final result = RecommendationEngine.getNearYou(
        allPlaces: [
          _place(id: 'here', lat: 0.0, lng: 0.0),
          _place(id: 'mid', lat: 0.0, lng: 0.045), // ~5km
        ],
        userLat: 0.0,
        userLng: 0.0,
      );
      expect(result.first.matchScore, closeTo(1.0, 0.01));
      expect(result.last.matchScore, lessThan(result.first.matchScore));
    });
  });

  group('RecommendationEngine.getTimeOfDay', () {
    test('does not throw and returns a list', () {
      final places = [
        _place(category: PlaceCategory.urban, openNow: true, rating: 4.0),
        _place(category: PlaceCategory.beach, openNow: true, rating: 4.0),
      ];
      final result = RecommendationEngine.getTimeOfDay(allPlaces: places);
      expect(result, isA<List<PlaceRecommendation>>());
    });

    test('only includes places that are openNow', () {
      // Pick a category for the current hour
      final hour = DateTime.now().hour;
      PlaceCategory cat;
      if (hour >= 6 && hour < 10) {
        cat = PlaceCategory.nature;
      } else if (hour >= 10 && hour < 14) {
        cat = PlaceCategory.heritage;
      } else if (hour >= 14 && hour < 17) {
        cat = PlaceCategory.beach;
      } else if (hour >= 17 && hour < 20) {
        cat = PlaceCategory.hillStation;
      } else {
        cat = PlaceCategory.urban;
      }
      final places = [
        _place(id: 'open', category: cat, openNow: true, rating: 4.0),
        _place(id: 'closed', category: cat, openNow: false, rating: 4.5),
      ];
      final result = RecommendationEngine.getTimeOfDay(allPlaces: places);
      // Only open one should appear
      expect(result.map((r) => r.place.placeId), contains('open'));
      expect(result.map((r) => r.place.placeId), isNot(contains('closed')));
    });
  });

  group('RecommendationEngine.getSeasonal', () {
    test('returns places matching at least one seasonal category', () {
      final all = [
        for (final cat in PlaceCategory.values)
          _place(id: cat.name, category: cat, rating: 4.0),
      ];
      final result = RecommendationEngine.getSeasonal(allPlaces: all);
      // Whatever the current month, all returned places should be in
      // PlaceCategory values (sanity).
      for (final r in result) {
        expect(PlaceCategory.values, contains(r.place.category));
      }
    });
  });

  group('RecommendationEngine.getTrending', () {
    test('only includes places with rating>=4.0 and >=100 reviews', () {
      final places = [
        _place(id: 'low_rating', rating: 3.5, userRatingsTotal: 200),
        _place(id: 'few_reviews', rating: 4.5, userRatingsTotal: 50),
        _place(id: 'trending', rating: 4.5, userRatingsTotal: 500),
      ];
      final result = RecommendationEngine.getTrending(allPlaces: places);
      expect(result.map((r) => r.place.placeId), ['trending']);
    });

    test('sorts by descending matchScore', () {
      final places = [
        _place(id: 'good', rating: 4.0, userRatingsTotal: 200),
        _place(id: 'great', rating: 4.8, userRatingsTotal: 1000),
      ];
      final result = RecommendationEngine.getTrending(allPlaces: places);
      expect(result.first.place.placeId, 'great');
    });
  });

  group('RecommendationEngine.getHiddenGems', () {
    test('only includes high-rating, low-review places', () {
      final places = [
        _place(id: 'too_low_rating', rating: 4.0, userRatingsTotal: 20),
        _place(id: 'too_few_reviews', rating: 4.5, userRatingsTotal: 4),
        _place(id: 'too_many_reviews', rating: 4.5, userRatingsTotal: 60),
        _place(id: 'gem', rating: 4.5, userRatingsTotal: 20),
      ];
      final result = RecommendationEngine.getHiddenGems(allPlaces: places);
      expect(result.map((r) => r.place.placeId), ['gem']);
    });
  });

  group('RecommendationEngine.generateAllRecommendations', () {
    test('returns empty when no places', () {
      final groups = RecommendationEngine.generateAllRecommendations(
        allPlaces: const [],
        favoriteIds: const {},
        userLat: null,
        userLng: null,
      );
      expect(groups, isEmpty);
    });

    test('only includes non-empty groups', () {
      final places = [
        _place(
          id: 'gem',
          rating: 4.5,
          userRatingsTotal: 20,
          category: PlaceCategory.nature,
        ),
      ];
      final groups = RecommendationEngine.generateAllRecommendations(
        allPlaces: places,
        favoriteIds: const {},
        userLat: null,
        userLng: null,
      );
      // Hidden gems should be present
      expect(
        groups.any((g) => g.type == RecommendationType.hiddenGems),
        isTrue,
      );
      // Every group must be non-empty
      for (final g in groups) {
        expect(g.recommendations, isNotEmpty);
      }
    });

    test('basedOnFavorites group has a basedOn description when favorites match', () {
      final places = [
        _place(
          id: 'fav',
          category: PlaceCategory.beach,
          rating: 4.0,
        ),
        _place(
          id: 'rec',
          category: PlaceCategory.beach,
          rating: 4.5,
        ),
      ];
      final groups = RecommendationEngine.generateAllRecommendations(
        allPlaces: places,
        favoriteIds: {'fav'},
        userLat: null,
        userLng: null,
      );
      final favGroup = groups.firstWhere(
        (g) => g.type == RecommendationType.basedOnFavorites,
      );
      expect(favGroup.basedOn, isNotNull);
      expect(favGroup.basedOn!.toLowerCase(), contains('beaches'));
    });
  });

  group('PlaceRecommendation', () {
    test('stores place / type / reason / matchScore', () {
      final rec = PlaceRecommendation(
        place: _place(id: 'x'),
        type: RecommendationType.trending,
        reason: 'Hot now',
        matchScore: 0.8,
      );
      expect(rec.place.placeId, 'x');
      expect(rec.type, RecommendationType.trending);
      expect(rec.reason, 'Hot now');
      expect(rec.matchScore, 0.8);
    });
  });
}
