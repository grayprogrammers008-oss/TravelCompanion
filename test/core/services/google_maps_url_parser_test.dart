// Tests for GoogleMapsUrlParser - pure URL parsing logic, no SDK dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_maps_url_parser.dart';

void main() {
  group('GoogleMapsUrlParser.isGoogleMapsUrl', () {
    test('detects google.com/maps URL', () {
      expect(
        GoogleMapsUrlParser.isGoogleMapsUrl('https://www.google.com/maps/place/X'),
        isTrue,
      );
    });

    test('detects maps.google.com URL', () {
      expect(
        GoogleMapsUrlParser.isGoogleMapsUrl('https://maps.google.com/?q=1,2'),
        isTrue,
      );
    });

    test('detects goo.gl/maps URL', () {
      expect(
        GoogleMapsUrlParser.isGoogleMapsUrl('https://goo.gl/maps/abc123'),
        isTrue,
      );
    });

    test('detects maps.app.goo.gl URL', () {
      expect(
        GoogleMapsUrlParser.isGoogleMapsUrl('https://maps.app.goo.gl/xyz'),
        isTrue,
      );
    });

    test('returns false for non-Maps URL', () {
      expect(
        GoogleMapsUrlParser.isGoogleMapsUrl('https://example.com'),
        isFalse,
      );
    });

    test('is case-insensitive', () {
      expect(
        GoogleMapsUrlParser.isGoogleMapsUrl('HTTPS://MAPS.GOOGLE.COM/'),
        isTrue,
      );
    });
  });

  group('GoogleMapsUrlParser.extractUrl', () {
    test('extracts google.com/maps URL from text', () {
      const text = 'Check this out https://www.google.com/maps/place/X awesome';
      expect(
        GoogleMapsUrlParser.extractUrl(text),
        equals('https://www.google.com/maps/place/X'),
      );
    });

    test('extracts maps.google.com URL', () {
      const text = 'Look: https://maps.google.com/?q=1,2 nearby';
      expect(
        GoogleMapsUrlParser.extractUrl(text),
        equals('https://maps.google.com/?q=1,2'),
      );
    });

    test('extracts goo.gl/maps URL', () {
      const text = 'Map: https://goo.gl/maps/abc123 here';
      expect(
        GoogleMapsUrlParser.extractUrl(text),
        equals('https://goo.gl/maps/abc123'),
      );
    });

    test('extracts maps.app.goo.gl URL', () {
      const text = 'Map: https://maps.app.goo.gl/xyz here';
      expect(
        GoogleMapsUrlParser.extractUrl(text),
        equals('https://maps.app.goo.gl/xyz'),
      );
    });

    test('returns null when no URL is found', () {
      expect(GoogleMapsUrlParser.extractUrl('no link in here'), isNull);
    });
  });

  group('GoogleMapsUrlParser.parse', () {
    test('returns null for invalid URL', () {
      expect(GoogleMapsUrlParser.parse(':::not a url'), isNull);
    });

    test('returns null for non-Google host', () {
      expect(GoogleMapsUrlParser.parse('https://example.com/?q=1,2'), isNull);
    });

    test('parses coordinates from "q" query param', () {
      final result = GoogleMapsUrlParser.parse(
          'https://maps.google.com/maps?q=12.9716,77.5946');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(12.9716, 0.0001));
      expect(result.longitude, closeTo(77.5946, 0.0001));
      expect(result.hasCoordinates, isTrue);
    });

    test('parses coordinates from "ll" query param', () {
      final result = GoogleMapsUrlParser.parse(
          'https://maps.google.com/?ll=10.5,20.7');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(10.5, 0.0001));
      expect(result.longitude, closeTo(20.7, 0.0001));
    });

    test('treats non-coordinate q as place name', () {
      final result = GoogleMapsUrlParser.parse(
          'https://maps.google.com/maps?q=Eiffel+Tower');
      expect(result, isNotNull);
      expect(result!.latitude, isNull);
      expect(result.longitude, isNull);
      // Uri.queryParameters decodes '+' as a space.
      expect(result.placeName, equals('Eiffel Tower'));
    });

    test('parses /place/Name/@lat,lng path', () {
      final result = GoogleMapsUrlParser.parse(
          'https://www.google.com/maps/place/Taj+Mahal/@27.1751,78.0421,15z');
      expect(result, isNotNull);
      expect(result!.placeName, equals('Taj Mahal'));
      expect(result.latitude, closeTo(27.1751, 0.0001));
      expect(result.longitude, closeTo(78.0421, 0.0001));
    });

    test('parses /maps/@lat,lng path', () {
      final result = GoogleMapsUrlParser.parse(
          'https://www.google.com/maps/@-33.8688,151.2093,15z');
      expect(result, isNotNull);
      expect(result!.latitude, closeTo(-33.8688, 0.0001));
      expect(result.longitude, closeTo(151.2093, 0.0001));
    });

    test('parses /place/Name without coordinates', () {
      final result = GoogleMapsUrlParser.parse(
          'https://www.google.com/maps/place/Big+Ben');
      expect(result, isNotNull);
      expect(result!.placeName, equals('Big Ben'));
      expect(result.hasCoordinates, isFalse);
    });

    test('marks short goo.gl URLs as short URL', () {
      final result =
          GoogleMapsUrlParser.parse('https://goo.gl/maps/abcdef');
      expect(result, isNotNull);
      expect(result!.isShortUrl, isTrue);
      expect(result.originalUrl, contains('goo.gl'));
    });

    test('rejects coordinates outside valid range', () {
      // Latitude > 90 should be rejected as coords; falls back to place name.
      final result =
          GoogleMapsUrlParser.parse('https://maps.google.com/maps?q=200,500');
      expect(result, isNotNull);
      // Treated as a place name string instead.
      expect(result!.hasCoordinates, isFalse);
      expect(result.placeName, equals('200,500'));
    });
  });

  group('ParsedLocation', () {
    test('hasCoordinates is true when both lat and lng are set', () {
      final loc = ParsedLocation(
        latitude: 1.0,
        longitude: 2.0,
        originalUrl: 'http://x',
      );
      expect(loc.hasCoordinates, isTrue);
    });

    test('hasCoordinates is false when only latitude is set', () {
      final loc = ParsedLocation(latitude: 1.0, originalUrl: 'http://x');
      expect(loc.hasCoordinates, isFalse);
    });

    test('hasCoordinates is false when neither set', () {
      final loc = ParsedLocation(originalUrl: 'http://x');
      expect(loc.hasCoordinates, isFalse);
    });

    test('toString contains lat, lng, name and url', () {
      final loc = ParsedLocation(
        latitude: 1.5,
        longitude: 2.5,
        placeName: 'Place',
        originalUrl: 'http://example',
      );
      final str = loc.toString();
      expect(str, contains('1.5'));
      expect(str, contains('2.5'));
      expect(str, contains('Place'));
      expect(str, contains('http://example'));
    });
  });
}
