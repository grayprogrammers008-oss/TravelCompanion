// Tests for the MapApp enum exposed by MapLauncherService.
//
// MapLauncherService itself depends on shared_preferences, dart:io Platform,
// and url_launcher; those side-effecting paths are NOT tested here. The
// MapApp value type and fromKey() pure logic are exercised below.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/map_launcher_service.dart';

void main() {
  group('MapApp enum', () {
    test('googleMaps has expected display name and key', () {
      expect(MapApp.googleMaps.displayName, equals('Google Maps'));
      expect(MapApp.googleMaps.key, equals('google_maps'));
    });

    test('appleMaps has expected display name and key', () {
      expect(MapApp.appleMaps.displayName, equals('Apple Maps'));
      expect(MapApp.appleMaps.key, equals('apple_maps'));
    });

    test('there are exactly two map app values', () {
      expect(MapApp.values.length, equals(2));
    });

    test('keys are unique', () {
      final keys = MapApp.values.map((m) => m.key).toSet();
      expect(keys.length, equals(MapApp.values.length));
    });

    test('display names are unique', () {
      final names = MapApp.values.map((m) => m.displayName).toSet();
      expect(names.length, equals(MapApp.values.length));
    });
  });

  group('MapApp.fromKey', () {
    test('returns googleMaps for "google_maps"', () {
      expect(MapApp.fromKey('google_maps'), equals(MapApp.googleMaps));
    });

    test('returns appleMaps for "apple_maps"', () {
      expect(MapApp.fromKey('apple_maps'), equals(MapApp.appleMaps));
    });

    test('returns a sensible default for unknown key', () {
      // Default falls back to a real enum value (platform-dependent).
      final result = MapApp.fromKey('not_a_real_app');
      expect(MapApp.values.contains(result), isTrue);
    });
  });
}
