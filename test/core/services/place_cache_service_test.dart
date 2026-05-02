// Tests for the CachedPlace value object exposed by PlaceCacheService.
//
// The PlaceCacheService class itself wraps Supabase RPC calls and the
// Google Places HTTP API, both of which require initialized SDKs / network
// access; those code paths are intentionally NOT tested here.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/place_cache_service.dart';
import 'package:travel_crew/core/services/google_places_service.dart';

void main() {
  group('CachedPlace.fromJson', () {
    test('parses a fully populated payload', () {
      final cp = CachedPlace.fromJson({
        'place_id': 'p1',
        'name': 'Eiffel Tower',
        'city': 'Paris',
        'state': 'IDF',
        'country': 'France',
        'types': ['tourist_attraction', 'landmark'],
        'latitude': 48.8584,
        'longitude': 2.2945,
      });

      expect(cp.placeId, equals('p1'));
      expect(cp.name, equals('Eiffel Tower'));
      expect(cp.city, equals('Paris'));
      expect(cp.state, equals('IDF'));
      expect(cp.country, equals('France'));
      expect(cp.types, equals(['tourist_attraction', 'landmark']));
      expect(cp.latitude, closeTo(48.8584, 0.0001));
      expect(cp.longitude, closeTo(2.2945, 0.0001));
    });

    test('handles missing optional fields', () {
      final cp = CachedPlace.fromJson({
        'place_id': 'p2',
        'name': 'Solo',
      });
      expect(cp.placeId, equals('p2'));
      expect(cp.city, isNull);
      expect(cp.state, isNull);
      expect(cp.country, isNull);
      expect(cp.latitude, isNull);
      expect(cp.longitude, isNull);
      expect(cp.types, isEmpty);
    });

    test('coerces num to double for coordinates', () {
      final cp = CachedPlace.fromJson({
        'place_id': 'p3',
        'name': 'X',
        'latitude': 1, // int, not double
        'longitude': 2,
      });
      expect(cp.latitude, equals(1.0));
      expect(cp.longitude, equals(2.0));
    });
  });

  group('CachedPlace.displayName', () {
    test('joins name + city + state + country', () {
      const cp = CachedPlace(
        placeId: 'p',
        name: 'Eiffel Tower',
        city: 'Paris',
        state: 'IDF',
        country: 'France',
        types: [],
      );
      expect(cp.displayName, equals('Eiffel Tower, Paris, IDF, France'));
    });

    test('skips city when equal to name', () {
      const cp = CachedPlace(
        placeId: 'p',
        name: 'Paris',
        city: 'Paris',
        country: 'France',
        types: [],
      );
      expect(cp.displayName, equals('Paris, France'));
    });

    test('skips state when equal to city', () {
      const cp = CachedPlace(
        placeId: 'p',
        name: 'Goa',
        city: 'Goa',
        state: 'Goa',
        country: 'India',
        types: [],
      );
      expect(cp.displayName.split(', ').where((s) => s == 'Goa').length,
          equals(1));
    });

    test('returns just name when no other fields set', () {
      const cp = CachedPlace(placeId: 'p', name: 'Atlantis', types: []);
      expect(cp.displayName, equals('Atlantis'));
    });
  });

  group('CachedPlace.toPrediction', () {
    test('produces a PlacePrediction with same id and display fields', () {
      const cp = CachedPlace(
        placeId: 'pid42',
        name: 'Eiffel Tower',
        city: 'Paris',
        country: 'France',
        types: ['attraction'],
      );
      final pred = cp.toPrediction();
      expect(pred, isA<PlacePrediction>());
      expect(pred.placeId, equals('pid42'));
      expect(pred.mainText, equals('Eiffel Tower'));
      expect(pred.description, equals(cp.displayName));
      expect(pred.types, equals(['attraction']));
      expect(pred.secondaryText, contains('Paris'));
      expect(pred.secondaryText, contains('France'));
    });

    test('omits parts equal to name from secondaryText', () {
      const cp = CachedPlace(
        placeId: 'pid',
        name: 'Goa',
        city: 'Goa',
        state: 'Goa',
        country: 'India',
        types: [],
      );
      final pred = cp.toPrediction();
      expect(pred.secondaryText, equals('India'));
    });
  });
}
