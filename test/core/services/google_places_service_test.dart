// Tests for GooglePlacesService.
//
// All HTTP traffic flows through an injected `http.Client` (via the
// `MockClient` helper) so we never touch the real network. Usage counters are
// persisted in SharedPreferences which uses an in-memory fake.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_crew/core/services/google_places_service.dart';

class _FakeHttpDriver {
  final List<http.Response> queue = [];
  int callCount = 0;
  final List<Uri> urls = [];

  void enqueue({required int statusCode, required Map<String, dynamic> body}) {
    queue.add(http.Response(jsonEncode(body), statusCode));
  }

  void enqueueRaw(int statusCode, String body) {
    queue.add(http.Response(body, statusCode));
  }

  void enqueueThrow(Object error) {
    queue.add(http.Response('THROW:${error.toString()}', 599));
  }

  http.Client client() {
    return MockClient((req) async {
      callCount++;
      urls.add(req.url);
      if (queue.isEmpty) {
        return http.Response('{}', 200);
      }
      final resp = queue.removeAt(0);
      // Detect throw markers
      if (resp.statusCode == 599 && resp.body.startsWith('THROW:')) {
        throw Exception(resp.body.substring(6));
      }
      return resp;
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlacePrediction', () {
    test('fromJson parses standard payload', () {
      final p = PlacePrediction.fromJson({
        'place_id': 'p1',
        'description': 'New Delhi, India',
        'structured_formatting': {
          'main_text': 'New Delhi',
          'secondary_text': 'India',
        },
        'types': ['locality'],
      });
      expect(p.placeId, 'p1');
      expect(p.description, 'New Delhi, India');
      expect(p.mainText, 'New Delhi');
      expect(p.secondaryText, 'India');
      expect(p.types, ['locality']);
      expect(p.toString(), 'New Delhi, India');
    });

    test('fromJson handles missing fields', () {
      final p = PlacePrediction.fromJson({});
      expect(p.placeId, '');
      expect(p.description, '');
      expect(p.mainText, '');
      expect(p.types, isEmpty);
    });

    test('isCity flags locality', () {
      expect(
        PlacePrediction.fromJson({'types': ['locality']}).isCity,
        isTrue,
      );
      expect(
        PlacePrediction.fromJson({'types': ['airport']}).isCity,
        isFalse,
      );
    });

    test('isCountry flags country', () {
      expect(
        PlacePrediction.fromJson({'types': ['country']}).isCountry,
        isTrue,
      );
      expect(
        PlacePrediction.fromJson({'types': ['locality']}).isCountry,
        isFalse,
      );
    });

    test('isRegion flags admin areas', () {
      expect(
        PlacePrediction.fromJson({
          'types': ['administrative_area_level_1']
        }).isRegion,
        isTrue,
      );
    });

    test('typeIcon switches by category', () {
      expect(
        PlacePrediction.fromJson({'types': ['country']}).typeIcon,
        '🌍',
      );
      expect(
        PlacePrediction.fromJson({'types': ['locality']}).typeIcon,
        '🏙️',
      );
      expect(
        PlacePrediction.fromJson({
          'types': ['administrative_area_level_1']
        }).typeIcon,
        '📍',
      );
      expect(
        PlacePrediction.fromJson({'types': ['airport']}).typeIcon,
        '✈️',
      );
      expect(
        PlacePrediction.fromJson({
          'types': ['natural_feature']
        }).typeIcon,
        '🏞️',
      );
      expect(
        PlacePrediction.fromJson({
          'types': ['point_of_interest']
        }).typeIcon,
        '📌',
      );
      expect(
        PlacePrediction.fromJson({'types': []}).typeIcon,
        '📍',
      );
    });
  });

  group('PlaceDetails.fromJson', () {
    test('parses all fields including address components', () {
      final d = PlaceDetails.fromJson({
        'place_id': 'pid',
        'name': 'Hotel',
        'formatted_address': '1 Main St',
        'geometry': {
          'location': {'lat': 12.5, 'lng': 77.5},
        },
        'photos': [
          {'photo_reference': 'ref1', 'width': 100, 'height': 200},
        ],
        'types': ['lodging'],
        'website': 'https://x.com',
        'url': 'https://maps/?cid=1',
        'rating': 4.5,
        'user_ratings_total': 100,
        'address_components': [
          {
            'long_name': 'Bangalore',
            'short_name': 'BLR',
            'types': ['locality'],
          },
          {
            'long_name': 'Karnataka',
            'short_name': 'KA',
            'types': ['administrative_area_level_1'],
          },
          {
            'long_name': 'India',
            'short_name': 'IN',
            'types': ['country'],
          },
        ],
      });
      expect(d.placeId, 'pid');
      expect(d.name, 'Hotel');
      expect(d.latitude, 12.5);
      expect(d.longitude, 77.5);
      expect(d.photos, hasLength(1));
      expect(d.rating, 4.5);
      expect(d.userRatingsTotal, 100);
      expect(d.city, 'Bangalore');
      expect(d.state, 'Karnataka');
      expect(d.country, 'India');
      expect(d.countryCode, 'IN');
    });

    test('shortName uses city/state/country', () {
      final d = PlaceDetails.fromJson({
        'name': 'Hotel',
        'address_components': [
          {
            'long_name': 'Bangalore',
            'short_name': 'B',
            'types': ['locality'],
          },
          {
            'long_name': 'India',
            'short_name': 'IN',
            'types': ['country'],
          },
        ],
      });
      expect(d.shortName, 'Bangalore, India');
    });

    test('shortName falls back to name when components are missing', () {
      final d = PlaceDetails.fromJson({'name': 'Some Place'});
      expect(d.shortName, 'Some Place');
    });

    test('handles missing geometry/photos gracefully', () {
      final d = PlaceDetails.fromJson({});
      expect(d.placeId, '');
      expect(d.name, '');
      expect(d.latitude, isNull);
      expect(d.longitude, isNull);
      expect(d.photos, isEmpty);
    });
  });

  group('PlacePhoto.fromJson', () {
    test('parses all fields', () {
      final p = PlacePhoto.fromJson({
        'photo_reference': 'r',
        'width': 100,
        'height': 200,
        'html_attributions': ['<a>x</a>'],
      });
      expect(p.photoReference, 'r');
      expect(p.width, 100);
      expect(p.height, 200);
      expect(p.htmlAttributions, ['<a>x</a>']);
    });

    test('uses defaults for missing fields', () {
      final p = PlacePhoto.fromJson({});
      expect(p.photoReference, '');
      expect(p.width, 0);
      expect(p.height, 0);
      expect(p.htmlAttributions, isEmpty);
    });
  });

  group('NearbyPlace.fromJson', () {
    test('parses geometry, opening_hours and photos', () {
      final n = NearbyPlace.fromJson({
        'place_id': 'p1',
        'name': 'Cafe',
        'vicinity': 'Street X',
        'geometry': {
          'location': {'lat': 1.0, 'lng': 2.0},
        },
        'types': ['cafe'],
        'rating': 4.0,
        'user_ratings_total': 50,
        'opening_hours': {'open_now': true},
        'photos': [
          {'photo_reference': 'ref'},
        ],
      });
      expect(n.placeId, 'p1');
      expect(n.name, 'Cafe');
      expect(n.vicinity, 'Street X');
      expect(n.latitude, 1.0);
      expect(n.longitude, 2.0);
      expect(n.rating, 4.0);
      expect(n.userRatingsTotal, 50);
      expect(n.openNow, isTrue);
      expect(n.photos, hasLength(1));
    });
  });

  group('GooglePlacesService.getAutocomplete', () {
    test('returns empty list for empty query without making a request',
        () async {
      final driver = _FakeHttpDriver();
      final svc = GooglePlacesService(client: driver.client());
      final result = await svc.getAutocomplete(query: '   ');
      expect(result, isEmpty);
      expect(driver.callCount, 0);
    });

    test('parses predictions on OK response', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'predictions': [
          {
            'place_id': 'p1',
            'description': 'Goa, India',
            'structured_formatting': {
              'main_text': 'Goa',
              'secondary_text': 'India',
            },
            'types': ['locality'],
          },
        ],
      });
      final svc = GooglePlacesService(client: driver.client());
      final result = await svc.getAutocomplete(query: 'Goa');
      expect(result, hasLength(1));
      expect(result.first.placeId, 'p1');
      expect(driver.callCount, 1);
      // URL should target the autocomplete endpoint and include input.
      expect(driver.urls.single.toString(), contains('autocomplete/json'));
      expect(driver.urls.single.toString(), contains('input=Goa'));
    });

    test('caches results and skips network on second identical call',
        () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'predictions': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.getAutocomplete(query: 'X');
      await svc.getAutocomplete(query: 'X');
      expect(driver.callCount, 1);
    });

    test('returns empty list on ZERO_RESULTS', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'ZERO_RESULTS',
        'predictions': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      final result = await svc.getAutocomplete(query: 'Q');
      expect(result, isEmpty);
    });

    test('returns empty list on API error status', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'INVALID_REQUEST',
        'error_message': 'oops',
      });
      final svc = GooglePlacesService(client: driver.client());
      final result = await svc.getAutocomplete(query: 'Q');
      expect(result, isEmpty);
    });

    test('returns empty list on non-200', () async {
      final driver = _FakeHttpDriver();
      driver.enqueueRaw(500, 'server down');
      final svc = GooglePlacesService(client: driver.client());
      final result = await svc.getAutocomplete(query: 'Q');
      expect(result, isEmpty);
    });

    test('returns empty list on exception', () async {
      final driver = _FakeHttpDriver();
      driver.enqueueThrow(Exception('net'));
      final svc = GooglePlacesService(client: driver.client());
      final result = await svc.getAutocomplete(query: 'Q');
      expect(result, isEmpty);
    });

    test('passes types/components/sessionToken via URL', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'predictions': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.getAutocomplete(
        query: 'Q',
        types: '(cities)',
        components: 'country:in',
        sessionToken: 'tok',
      );
      final url = driver.urls.single.toString();
      expect(url, contains('types=%28cities%29'));
      expect(url, contains('components=country%3Ain'));
      expect(url, contains('sessiontoken=tok'));
    });
  });

  group('GooglePlacesService.getPlaceDetails', () {
    test('parses OK response', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'result': {
          'place_id': 'p',
          'name': 'X',
          'formatted_address': 'addr',
          'photos': [],
        },
      });
      final svc = GooglePlacesService(client: driver.client());
      final d = await svc.getPlaceDetails(placeId: 'p');
      expect(d, isNotNull);
      expect(d!.name, 'X');
    });

    test('returns null on non-OK status', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'NOT_FOUND',
        'error_message': 'no',
      });
      final svc = GooglePlacesService(client: driver.client());
      final d = await svc.getPlaceDetails(placeId: 'p');
      expect(d, isNull);
    });

    test('returns null on HTTP error', () async {
      final driver = _FakeHttpDriver();
      driver.enqueueRaw(500, '');
      final svc = GooglePlacesService(client: driver.client());
      final d = await svc.getPlaceDetails(placeId: 'p');
      expect(d, isNull);
    });

    test('returns null on exception', () async {
      final driver = _FakeHttpDriver();
      driver.enqueueThrow(Exception('boom'));
      final svc = GooglePlacesService(client: driver.client());
      final d = await svc.getPlaceDetails(placeId: 'p');
      expect(d, isNull);
    });

    test('caches details for same place_id', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'result': {'place_id': 'p', 'name': 'X', 'formatted_address': 'a'},
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.getPlaceDetails(placeId: 'p');
      await svc.getPlaceDetails(placeId: 'p');
      expect(driver.callCount, 1);
    });

    test('passes custom fields list and session token', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'result': {'place_id': 'p', 'name': 'X', 'formatted_address': 'a'},
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.getPlaceDetails(
        placeId: 'p',
        fields: ['name', 'rating'],
        sessionToken: 'tok',
      );
      final url = driver.urls.single.toString();
      expect(url, contains('fields=name%2Crating'));
      expect(url, contains('sessiontoken=tok'));
    });
  });

  group('GooglePlacesService.getPhotoUrl', () {
    test('builds the photo URL with reference and maxwidth', () {
      final svc = GooglePlacesService();
      final url = svc.getPhotoUrl(photoReference: 'ref', maxWidth: 800);
      expect(url, contains('photoreference=ref'));
      expect(url, contains('maxwidth=800'));
      expect(url, contains('/place/photo'));
    });

    test('includes maxheight when given', () {
      final svc = GooglePlacesService();
      final url = svc.getPhotoUrl(
        photoReference: 'ref',
        maxWidth: 100,
        maxHeight: 200,
      );
      expect(url, contains('maxheight=200'));
    });
  });

  group('GooglePlacesService.getPhotoUrlWithTracking', () {
    test('returns URL when under quota', () async {
      final svc = GooglePlacesService();
      final url = await svc.getPhotoUrlWithTracking(
        photoReference: 'ref',
        maxWidth: 200,
      );
      expect(url, isNotNull);
      expect(url!, contains('photoreference=ref'));
    });

    test('returns null when daily limit reached', () async {
      // Pre-load SharedPreferences with the limit already hit. Service uses
      // _dailyPhotoLimit=100 and reads the persisted counter on init.
      SharedPreferences.setMockInitialValues({
        'places_photo_count': 1000,
        'places_last_reset_date':
            DateTime.now().toIso8601String().substring(0, 10),
      });
      final svc = GooglePlacesService();
      final url = await svc.getPhotoUrlWithTracking(
        photoReference: 'ref',
      );
      expect(url, isNull);
    });
  });

  group('GooglePlacesService.searchNearby', () {
    test('parses single-page OK response and sorts by rating', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'results': [
          {
            'place_id': 'a',
            'name': 'Low',
            'rating': 3.5,
          },
          {
            'place_id': 'b',
            'name': 'High',
            'rating': 4.8,
          },
          {
            'place_id': 'c',
            'name': 'Mid',
            'rating': 4.0,
            'user_ratings_total': 50,
          },
          {
            'place_id': 'd',
            'name': 'NoRating',
          },
        ],
      });
      final svc = GooglePlacesService(client: driver.client());
      final places = await svc.searchNearby(
        latitude: 12.0,
        longitude: 77.0,
      );
      expect(places, hasLength(4));
      // Highest rating first
      expect(places.first.name, 'High');
      // Unrated last
      expect(places.last.name, 'NoRating');
    });

    test('returns empty list on ZERO_RESULTS', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'ZERO_RESULTS',
        'results': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      final places = await svc.searchNearby(
        latitude: 1,
        longitude: 2,
      );
      expect(places, isEmpty);
    });

    test('uses rankby=distance when type given', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'results': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.searchNearby(
        latitude: 1,
        longitude: 2,
        type: 'restaurant',
        rankBy: 'distance',
      );
      final url = driver.urls.single.toString();
      expect(url, contains('rankby=distance'));
      expect(url, contains('type=restaurant'));
      expect(url, isNot(contains('radius=')));
    });

    test('uses default 15km radius when not given', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'results': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.searchNearby(latitude: 1, longitude: 2);
      expect(driver.urls.single.toString(), contains('radius=15000'));
    });

    test('uses custom radius when given', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'results': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.searchNearby(
        latitude: 1,
        longitude: 2,
        radius: 5000,
      );
      expect(driver.urls.single.toString(), contains('radius=5000'));
    });

    test('returns empty list on exception', () async {
      final driver = _FakeHttpDriver();
      driver.enqueueThrow(Exception('net'));
      final svc = GooglePlacesService(client: driver.client());
      final places = await svc.searchNearby(latitude: 1, longitude: 2);
      expect(places, isEmpty);
    });
  });

  group('GooglePlacesService usage tracking', () {
    test('all canMake* getters are true initially', () async {
      final svc = GooglePlacesService();
      // Trigger _ensureInitialized via an empty autocomplete request.
      await svc.getAutocomplete(query: '');
      expect(svc.canMakeAutocompleteRequest, isTrue);
      expect(svc.canMakeDetailsRequest, isTrue);
      expect(svc.canMakePhotoRequest, isTrue);
      expect(svc.canMakeNearbyRequest, isTrue);
    });

    test('usageStats exposes the counter map shape', () {
      final svc = GooglePlacesService();
      final stats = svc.usageStats;
      expect(stats.keys,
          containsAll(['autocomplete', 'details', 'photos', 'nearby']));
      for (final v in stats.values) {
        expect((v as Map).keys, containsAll(['used', 'limit']));
      }
    });

    test('resetCounters zeroes counters in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'places_autocomplete_count': 99,
        'places_details_count': 99,
        'places_photo_count': 99,
        'places_nearby_count': 99,
      });
      final svc = GooglePlacesService();
      await svc.resetCounters();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('places_autocomplete_count'), 0);
      expect(prefs.getInt('places_details_count'), 0);
      expect(prefs.getInt('places_photo_count'), 0);
      expect(prefs.getInt('places_nearby_count'), 0);
    });
  });

  group('GooglePlacesService.clearCache', () {
    test('clearCache empties caches so next call re-hits network', () async {
      final driver = _FakeHttpDriver();
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'predictions': [],
      });
      driver.enqueue(statusCode: 200, body: {
        'status': 'OK',
        'predictions': [],
      });
      final svc = GooglePlacesService(client: driver.client());
      await svc.getAutocomplete(query: 'X');
      svc.clearCache();
      await svc.getAutocomplete(query: 'X');
      expect(driver.callCount, 2);
    });
  });
}
