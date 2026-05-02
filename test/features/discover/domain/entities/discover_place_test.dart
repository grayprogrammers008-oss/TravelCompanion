import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';

DiscoverPlace _place({
  String placeId = 'p1',
  String name = 'Test Place',
  String? vicinity,
  double? lat,
  double? lng,
  List<String> types = const ['point_of_interest'],
  double? rating,
  int? userRatingsTotal,
  bool? openNow,
  List<PlacePhoto> photos = const [],
  PlaceCategory category = PlaceCategory.nature,
  bool isFavorite = false,
}) =>
    DiscoverPlace(
      placeId: placeId,
      name: name,
      vicinity: vicinity,
      latitude: lat,
      longitude: lng,
      types: types,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      openNow: openNow,
      photos: photos,
      category: category,
      isFavorite: isFavorite,
    );

void main() {
  group('DiscoverPlace', () {
    group('factory fromNearbyPlace', () {
      test('copies fields and applies category', () {
        final nearby = NearbyPlace(
          placeId: 'p-1',
          name: 'Alpha',
          vicinity: 'street',
          latitude: 12.0,
          longitude: 80.0,
          types: const ['park'],
          rating: 4.6,
          userRatingsTotal: 1234,
          openNow: true,
          photos: const [PlacePhoto(
            photoReference: 'ref',
            width: 100,
            height: 100,
            htmlAttributions: [],
          )],
        );

        final place = DiscoverPlace.fromNearbyPlace(nearby, PlaceCategory.beach);

        expect(place.placeId, 'p-1');
        expect(place.name, 'Alpha');
        expect(place.vicinity, 'street');
        expect(place.latitude, 12.0);
        expect(place.longitude, 80.0);
        expect(place.types, ['park']);
        expect(place.rating, 4.6);
        expect(place.userRatingsTotal, 1234);
        expect(place.openNow, true);
        expect(place.photos, hasLength(1));
        expect(place.category, PlaceCategory.beach);
        expect(place.isFavorite, isFalse);
      });
    });

    group('hasPhotos / firstPhotoReference', () {
      test('hasPhotos is false and firstPhotoReference is null when photos empty', () {
        final p = _place();
        expect(p.hasPhotos, isFalse);
        expect(p.firstPhotoReference, isNull);
      });

      test('hasPhotos is true and firstPhotoReference returns first', () {
        final p = _place(photos: const [
          PlacePhoto(photoReference: 'first', width: 0, height: 0, htmlAttributions: []),
          PlacePhoto(photoReference: 'second', width: 0, height: 0, htmlAttributions: []),
        ]);
        expect(p.hasPhotos, isTrue);
        expect(p.firstPhotoReference, 'first');
      });
    });

    group('ratingText', () {
      test('returns "No rating" when rating is null', () {
        expect(_place().ratingText, 'No rating');
      });

      test('formats rating to one decimal', () {
        expect(_place(rating: 4.567).ratingText, '4.6');
        expect(_place(rating: 3.0).ratingText, '3.0');
      });
    });

    group('reviewsText', () {
      test('returns "No reviews" when null or zero', () {
        expect(_place().reviewsText, 'No reviews');
        expect(_place(userRatingsTotal: 0).reviewsText, 'No reviews');
      });

      test('formats large counts as Nk', () {
        expect(_place(userRatingsTotal: 1000).reviewsText, '1.0k reviews');
        expect(_place(userRatingsTotal: 12345).reviewsText, '12.3k reviews');
      });

      test('formats small counts plainly', () {
        expect(_place(userRatingsTotal: 1).reviewsText, '1 reviews');
        expect(_place(userRatingsTotal: 999).reviewsText, '999 reviews');
      });
    });

    group('statusText', () {
      test('returns null when openNow is null', () {
        expect(_place().statusText, isNull);
      });

      test('returns "Open now" when openNow is true', () {
        expect(_place(openNow: true).statusText, 'Open now');
      });

      test('returns "Closed" when openNow is false', () {
        expect(_place(openNow: false).statusText, 'Closed');
      });
    });

    group('matchesSearch', () {
      test('matches by name (case-insensitive)', () {
        final p = _place(name: 'Goa Beach');
        expect(p.matchesSearch('goa'), isTrue);
        expect(p.matchesSearch('BEACH'), isTrue);
        expect(p.matchesSearch('paris'), isFalse);
      });

      test('matches by vicinity', () {
        final p = _place(name: 'X', vicinity: 'Near Marina');
        expect(p.matchesSearch('marina'), isTrue);
      });

      test('vicinity null does not throw', () {
        final p = _place(name: 'X', vicinity: null);
        expect(p.matchesSearch('any'), isFalse);
      });
    });

    group('distanceFrom', () {
      test('returns null when any coordinate is null', () {
        expect(_place().distanceFrom(0, 0), isNull);
        expect(_place(lat: 1, lng: 1).distanceFrom(null, 0), isNull);
        expect(_place(lat: 1, lng: 1).distanceFrom(0, null), isNull);
      });

      test('returns 0 for identical coordinates', () {
        final d = _place(lat: 12.9716, lng: 77.5946)
            .distanceFrom(12.9716, 77.5946);
        expect(d, isNotNull);
        expect(d!, closeTo(0.0, 0.001));
      });

      test('returns ~2.0 km for ~2 km apart points', () {
        // Two points roughly 2 km apart on the equator
        final d = _place(lat: 0.0, lng: 0.0).distanceFrom(0.0, 0.018);
        expect(d, isNotNull);
        expect(d!, closeTo(2.0, 0.1));
      });
    });

    group('distanceText', () {
      test('returns empty when distance unavailable', () {
        expect(_place().distanceText(0, 0), '');
      });

      test('formats meters when < 1km', () {
        // ~500m apart on equator
        final p = _place(lat: 0.0, lng: 0.0);
        final txt = p.distanceText(0.0, 0.0045);
        expect(txt.endsWith(' m'), isTrue);
      });

      test('formats kilometers when >= 1km', () {
        final p = _place(lat: 0.0, lng: 0.0);
        final txt = p.distanceText(0.0, 0.05); // ~5.5km
        expect(txt.endsWith(' km'), isTrue);
      });
    });

    group('copyWith', () {
      test('overrides only isFavorite', () {
        final original = _place(name: 'X', rating: 4.0);
        final copy = original.copyWith(isFavorite: true);
        expect(copy.placeId, original.placeId);
        expect(copy.name, original.name);
        expect(copy.rating, original.rating);
        expect(copy.isFavorite, isTrue);
        expect(original.isFavorite, isFalse);
      });

      test('preserves isFavorite when null is passed', () {
        final original = _place(isFavorite: true);
        final copy = original.copyWith();
        expect(copy.isFavorite, isTrue);
      });
    });

    group('equality', () {
      test('two places with the same placeId are equal', () {
        final a = _place(placeId: 'same', name: 'A');
        final b = _place(placeId: 'same', name: 'B-different');
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('two places with different placeIds are not equal', () {
        expect(_place(placeId: 'a') == _place(placeId: 'b'), isFalse);
      });

      test('identical reference is equal', () {
        final a = _place();
        expect(a == a, isTrue);
      });
    });
  });

  group('DiscoverDistance', () {
    test('exposes correct kilometers and display name', () {
      expect(DiscoverDistance.veryNear.kilometers, 5);
      expect(DiscoverDistance.veryNear.displayName, contains('5'));
      expect(DiscoverDistance.nearby.kilometers, 10);
      expect(DiscoverDistance.near20.kilometers, 20);
      expect(DiscoverDistance.near30.kilometers, 30);
      expect(DiscoverDistance.far.kilometers, 50);
    });

    test('radiusInMeters multiplies km by 1000', () {
      expect(DiscoverDistance.veryNear.radiusInMeters, 5000);
      expect(DiscoverDistance.nearby.radiusInMeters, 10000);
      expect(DiscoverDistance.near30.radiusInMeters, 30000);
    });

    test('radiusInMeters caps at 50000 (Google Places API limit)', () {
      expect(DiscoverDistance.far.radiusInMeters, 50000);
      // All values must be <= 50000
      for (final d in DiscoverDistance.values) {
        expect(d.radiusInMeters, lessThanOrEqualTo(50000));
      }
    });
  });

  group('DiscoverViewMode', () {
    test('has exactly two modes: grid and map', () {
      expect(DiscoverViewMode.values, [DiscoverViewMode.grid, DiscoverViewMode.map]);
    });
  });

  group('DiscoverState', () {
    test('default constructor uses sensible defaults', () {
      const s = DiscoverState();
      expect(s.selectedCategory, isNull);
      expect(s.places, isEmpty);
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
      expect(s.userLatitude, isNull);
      expect(s.userLongitude, isNull);
      expect(s.searchQuery, '');
      expect(s.viewMode, DiscoverViewMode.grid);
      expect(s.favoriteIds, isEmpty);
      expect(s.showFavoritesOnly, isFalse);
      expect(s.isFromCache, isFalse);
      expect(s.selectedDistance, DiscoverDistance.nearby);
      expect(s.selectedCountry, isNull);
      expect(s.isLocationFromSearch, isFalse);
      expect(s.isGettingLocation, isFalse);
      expect(s.isPermissionDeniedForever, isFalse);
    });

    group('hasLocation', () {
      test('false when either coordinate missing', () {
        expect(const DiscoverState().hasLocation, isFalse);
        expect(const DiscoverState(userLatitude: 1.0).hasLocation, isFalse);
        expect(const DiscoverState(userLongitude: 1.0).hasLocation, isFalse);
      });

      test('true when both coordinates present', () {
        const s = DiscoverState(userLatitude: 1.0, userLongitude: 2.0);
        expect(s.hasLocation, isTrue);
      });
    });

    group('isFavorite', () {
      test('checks the favoriteIds set', () {
        final s = DiscoverState(favoriteIds: const {'a', 'b'});
        expect(s.isFavorite('a'), isTrue);
        expect(s.isFavorite('z'), isFalse);
      });
    });

    group('filteredPlaces', () {
      final p1 = _place(placeId: '1', name: 'Goa Beach');
      final p2 = _place(placeId: '2', name: 'Tokyo Shrine');
      final p3 = _place(placeId: '3', name: 'Paris Museum');

      test('returns all places when no filter active', () {
        final s = DiscoverState(places: [p1, p2, p3]);
        expect(s.filteredPlaces, [p1, p2, p3]);
      });

      test('filters by search query', () {
        final s = DiscoverState(places: [p1, p2, p3], searchQuery: 'beach');
        expect(s.filteredPlaces, [p1]);
      });

      test('search query is case-insensitive', () {
        final s = DiscoverState(places: [p1, p2, p3], searchQuery: 'TOKYO');
        expect(s.filteredPlaces, [p2]);
      });

      test('shows only favorites when showFavoritesOnly is true', () {
        final s = DiscoverState(
          places: [p1, p2, p3],
          favoriteIds: const {'2'},
          showFavoritesOnly: true,
        );
        expect(s.filteredPlaces, [p2]);
      });

      test('combines search and favorites filters (AND)', () {
        final s = DiscoverState(
          places: [p1, p2, p3],
          favoriteIds: const {'1', '3'},
          showFavoritesOnly: true,
          searchQuery: 'paris',
        );
        expect(s.filteredPlaces, [p3]);
      });

      test('returns empty when nothing matches', () {
        final s = DiscoverState(places: [p1, p2], searchQuery: 'NoMatch');
        expect(s.filteredPlaces, isEmpty);
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        const s = DiscoverState();
        final next = s.copyWith(
          isLoading: true,
          searchQuery: 'goa',
          viewMode: DiscoverViewMode.map,
        );
        expect(next.isLoading, isTrue);
        expect(next.searchQuery, 'goa');
        expect(next.viewMode, DiscoverViewMode.map);
        // Unchanged
        expect(next.selectedDistance, DiscoverDistance.nearby);
      });

      test('error is intentionally cleared on copyWith without param', () {
        // Note: error param is `String? error` (not `Object? error = sentinel`),
        // so calling copyWith() with no `error` arg always sets it to null.
        const s = DiscoverState(error: 'previous');
        final next = s.copyWith(isLoading: true);
        expect(next.error, isNull);
      });

      test('clearCountry sets selectedCountry to null even when country also passed', () {
        const s = DiscoverState(selectedCountry: 'India');
        final next = s.copyWith(selectedCountry: 'Japan', clearCountry: true);
        expect(next.selectedCountry, isNull);
      });

      test('selectedCountry retained when clearCountry false and not overridden', () {
        const s = DiscoverState(selectedCountry: 'India');
        final next = s.copyWith(isLoading: true);
        expect(next.selectedCountry, 'India');
      });

      test('selectedCountry overridden when provided and clearCountry false', () {
        const s = DiscoverState(selectedCountry: 'India');
        final next = s.copyWith(selectedCountry: 'Japan');
        expect(next.selectedCountry, 'Japan');
      });
    });
  });
}
