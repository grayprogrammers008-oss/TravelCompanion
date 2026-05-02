// Tests for the Place model used by PlaceSearchService.
//
// The actual searchPlaces() method makes HTTP calls to OpenStreetMap Nominatim
// and is therefore intentionally NOT tested here. The Place data class and
// fromNominatim() factory are pure and fully testable.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/place_search_service.dart';

void main() {
  group('Place.fromNominatim', () {
    test('uses display_name and explicit name when provided', () {
      final place = Place.fromNominatim({
        'display_name': 'Mumbai, Maharashtra, India',
        'name': 'Mumbai',
        'lat': '19.076',
        'lon': '72.877',
        'type': 'city',
        'address': {
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'country': 'India',
        },
      });

      expect(place.displayName, equals('Mumbai, Maharashtra, India'));
      expect(place.name, equals('Mumbai'));
      expect(place.city, equals('Mumbai'));
      expect(place.state, equals('Maharashtra'));
      expect(place.country, equals('India'));
      expect(place.latitude, closeTo(19.076, 0.001));
      expect(place.longitude, closeTo(72.877, 0.001));
      expect(place.type, equals('city'));
    });

    test('falls back to address.city when name is empty', () {
      final place = Place.fromNominatim({
        'display_name': 'X',
        'name': '',
        'lat': '0',
        'lon': '0',
        'type': 'city',
        'address': {
          'city': 'Bangalore',
          'state': 'Karnataka',
        },
      });

      expect(place.name, equals('Bangalore'));
    });

    test('falls back to town/village/country chain', () {
      final placeTown = Place.fromNominatim({
        'display_name': 'X',
        'lat': '0',
        'lon': '0',
        'address': {'town': 'Smalltown'},
      });
      expect(placeTown.name, equals('Smalltown'));

      final placeVillage = Place.fromNominatim({
        'display_name': 'X',
        'lat': '0',
        'lon': '0',
        'address': {'village': 'Hamlet'},
      });
      expect(placeVillage.name, equals('Hamlet'));

      final placeCountry = Place.fromNominatim({
        'display_name': 'X',
        'lat': '0',
        'lon': '0',
        'address': {'country': 'India'},
      });
      expect(placeCountry.name, equals('India'));
    });

    test('handles missing lat/lon as zero', () {
      final place = Place.fromNominatim({
        'display_name': 'X',
        'name': 'X',
        'address': {'city': 'X'},
      });
      expect(place.latitude, equals(0.0));
      expect(place.longitude, equals(0.0));
    });

    test('handles missing address map gracefully', () {
      final place = Place.fromNominatim({
        'display_name': 'Just a place',
        'name': 'Place',
        'lat': '1.0',
        'lon': '2.0',
        'type': 'place',
      });
      expect(place.city, isNull);
      expect(place.country, isNull);
      expect(place.name, equals('Place'));
    });

    test('defaults type to "place" when missing', () {
      final place = Place.fromNominatim({
        'display_name': 'X',
        'name': 'X',
        'lat': '0',
        'lon': '0',
      });
      expect(place.type, equals('place'));
    });
  });

  group('Place.shortName', () {
    test('joins distinct name, city, state, country up to 3 parts', () {
      const place = Place(
        displayName: 'Long display',
        name: 'Goa',
        city: 'Panaji',
        state: 'Goa',
        country: 'India',
        latitude: 0,
        longitude: 0,
        type: 'state',
      );
      // Implementation does parts.take(3); name+city+state takes first 3.
      expect(place.shortName, contains('Goa'));
      expect(place.shortName, contains('Panaji'));
    });

    test('skips city duplicate of name', () {
      const place = Place(
        displayName: '',
        name: 'Mumbai',
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
        latitude: 0,
        longitude: 0,
        type: 'city',
      );
      // city == name should be skipped, so 'Mumbai' should appear only once.
      final occurrences =
          place.shortName.split(', ').where((p) => p == 'Mumbai').length;
      expect(occurrences, equals(1));
    });

    test('handles only-name case', () {
      const place = Place(
        displayName: '',
        name: 'OnlyName',
        latitude: 0,
        longitude: 0,
        type: 'place',
      );
      expect(place.shortName, equals('OnlyName'));
    });
  });

  group('Place.typeIcon', () {
    test('returns city emoji for city/town/village', () {
      for (final t in ['city', 'town', 'village', 'CITY']) {
        final p = Place(
          displayName: '',
          name: 'X',
          latitude: 0,
          longitude: 0,
          type: t,
        );
        expect(p.typeIcon, equals('🏙️'));
      }
    });

    test('returns globe emoji for country', () {
      const p = Place(
        displayName: '',
        name: 'X',
        latitude: 0,
        longitude: 0,
        type: 'country',
      );
      expect(p.typeIcon, equals('🌍'));
    });

    test('returns island emoji for island', () {
      const p = Place(
        displayName: '',
        name: 'X',
        latitude: 0,
        longitude: 0,
        type: 'island',
      );
      expect(p.typeIcon, equals('🏝️'));
    });

    test('returns beach emoji for beach', () {
      const p = Place(
        displayName: '',
        name: 'X',
        latitude: 0,
        longitude: 0,
        type: 'beach',
      );
      expect(p.typeIcon, equals('🏖️'));
    });

    test('returns mountain emoji for mountain', () {
      const p = Place(
        displayName: '',
        name: 'X',
        latitude: 0,
        longitude: 0,
        type: 'mountain',
      );
      expect(p.typeIcon, equals('⛰️'));
    });

    test('returns default pin for unknown type', () {
      const p = Place(
        displayName: '',
        name: 'X',
        latitude: 0,
        longitude: 0,
        type: 'unknown-type',
      );
      expect(p.typeIcon, equals('📍'));
    });
  });

  group('Place.toString', () {
    test('uses shortName', () {
      const place = Place(
        displayName: 'Long display',
        name: 'Mumbai',
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
        latitude: 0,
        longitude: 0,
        type: 'city',
      );
      expect(place.toString(), equals(place.shortName));
    });
  });
}
