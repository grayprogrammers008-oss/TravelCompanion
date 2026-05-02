import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/data/datasources/discover_local_datasource.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';

/// Minimal hand-rolled fake of `GooglePlacesService` so tests don't hit the
/// real Google Places HTTP API. Records the calls they made and returns
/// configurable canned responses.
class _FakeGooglePlacesService extends GooglePlacesService {
  Map<String, String?> photoUrlsByRef = {};
  Map<String, PlaceDetails?> detailsByPlaceId = {};
  bool throwOnPhoto = false;
  bool throwOnDetails = false;
  final List<String> photoCalls = [];
  final List<String> detailsCalls = [];

  @override
  Future<String?> getPhotoUrlWithTracking({
    required String photoReference,
    int maxWidth = 400,
    int? maxHeight,
  }) async {
    photoCalls.add(photoReference);
    if (throwOnPhoto) throw Exception('photo fetch failed');
    return photoUrlsByRef[photoReference];
  }

  @override
  Future<PlaceDetails?> getPlaceDetails({
    required String placeId,
    List<String>? fields,
    String? sessionToken,
  }) async {
    detailsCalls.add(placeId);
    if (throwOnDetails) throw Exception('details fetch failed');
    return detailsByPlaceId[placeId];
  }
}

/// Minimal hand-rolled fake of `DiscoverLocalDataSource` covering only the
/// methods exercised by the photo provider.
class _FakeLocalDataSource extends DiscoverLocalDataSource {
  bool overrideAvailability = true;
  Map<String, String> photoCache = {};
  bool throwOnGetCachedPhotoUrl = false;
  bool throwOnCachePhotoUrl = false;
  final List<MapEntry<String, String>> savedPhotoUrls = [];

  @override
  bool get isAvailable => overrideAvailability;

  @override
  Future<String?> getCachedPhotoUrl(String photoReference) async {
    if (throwOnGetCachedPhotoUrl) throw Exception('cache get failed');
    return photoCache[photoReference];
  }

  @override
  Future<void> cachePhotoUrl({
    required String photoReference,
    required String url,
  }) async {
    if (throwOnCachePhotoUrl) throw Exception('cache save failed');
    photoCache[photoReference] = url;
    savedPhotoUrls.add(MapEntry(photoReference, url));
  }
}

/// Minimal `DiscoverStateNotifier` substitute that just emits a fixed state.
class _FakeDiscoverStateNotifier extends DiscoverStateNotifier {
  _FakeDiscoverStateNotifier(this._initialState);
  final DiscoverState _initialState;

  @override
  DiscoverState build() => _initialState;
}

/// Build a ProviderContainer with our fakes. `weatherStubFn`, when provided,
/// is used by an HTTP overrides zone to short-circuit the OpenWeatherMap call.
ProviderContainer makeContainer({
  required GooglePlacesService places,
  required DiscoverLocalDataSource local,
  DiscoverState? discoverState,
}) {
  return ProviderContainer(
    overrides: [
      googlePlacesServiceProvider.overrideWithValue(places),
      discoverLocalDataSourceProvider.overrideWithValue(local),
      if (discoverState != null)
        discoverStateProvider.overrideWith(
          () => _FakeDiscoverStateNotifier(discoverState),
        ),
    ],
  );
}

void main() {
  late _FakeGooglePlacesService places;
  late _FakeLocalDataSource local;

  setUp(() {
    places = _FakeGooglePlacesService();
    local = _FakeLocalDataSource();
  });

  group('placePhotoUrlProvider', () {
    test('returns cached URL when local data source has it', () async {
      local.photoCache['ref-1'] = 'https://cached/img.jpg';
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final url =
          await container.read(placePhotoUrlProvider('ref-1').future);
      expect(url, 'https://cached/img.jpg');
      // Service should NOT have been called
      expect(places.photoCalls, isEmpty);
    });

    test('falls back to Google Places when no cache hit, and writes through',
        () async {
      places.photoUrlsByRef['ref-2'] = 'https://api/img.jpg';
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final url =
          await container.read(placePhotoUrlProvider('ref-2').future);
      expect(url, 'https://api/img.jpg');
      expect(places.photoCalls, ['ref-2']);
      // Cache should have been populated
      expect(local.photoCache['ref-2'], 'https://api/img.jpg');
      expect(local.savedPhotoUrls.first.key, 'ref-2');
    });

    test('returns null when service returns null and does NOT cache', () async {
      // No mapping for 'unknown' → service returns null
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final url =
          await container.read(placePhotoUrlProvider('unknown').future);
      expect(url, isNull);
      expect(local.photoCache, isEmpty);
    });

    test('survives cache-read failure (still calls service)', () async {
      local.throwOnGetCachedPhotoUrl = true;
      places.photoUrlsByRef['ref-3'] = 'https://api/img.jpg';
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final url =
          await container.read(placePhotoUrlProvider('ref-3').future);
      expect(url, 'https://api/img.jpg');
      expect(places.photoCalls, ['ref-3']);
    });

    test('survives cache-write failure (still returns the URL)', () async {
      local.throwOnCachePhotoUrl = true;
      places.photoUrlsByRef['ref-4'] = 'https://api/img.jpg';
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final url =
          await container.read(placePhotoUrlProvider('ref-4').future);
      expect(url, 'https://api/img.jpg');
    });

    test('skips cache layer when local data source is unavailable', () async {
      local.overrideAvailability = false;
      places.photoUrlsByRef['ref-5'] = 'https://api/img.jpg';
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final url =
          await container.read(placePhotoUrlProvider('ref-5').future);
      expect(url, 'https://api/img.jpg');
      // Should not have written to cache (it's unavailable)
      expect(local.photoCache, isEmpty);
    });
  });

  group('placeDetailsProvider', () {
    test('returns details from GooglePlacesService for given placeId',
        () async {
      const fakeDetails = PlaceDetails(
        placeId: 'p-1',
        name: 'Marina Beach',
        formattedAddress: 'Chennai, India',
        photos: [],
        types: ['point_of_interest'],
      );
      places.detailsByPlaceId['p-1'] = fakeDetails;

      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final details =
          await container.read(placeDetailsProvider('p-1').future);
      expect(details, isNotNull);
      expect(details!.placeId, 'p-1');
      expect(details.name, 'Marina Beach');
      expect(places.detailsCalls, ['p-1']);
    });

    test('returns null when service returns null for unknown id', () async {
      final container = makeContainer(places: places, local: local);
      addTearDown(container.dispose);

      final details =
          await container.read(placeDetailsProvider('missing').future);
      expect(details, isNull);
    });

  });

  group('locationWeatherProvider', () {
    DiscoverState withLocation = const DiscoverState(
      userLatitude: 12.97,
      userLongitude: 77.59,
      locationName: 'Bangalore',
    );

    test('returns null when DiscoverState has no location', () async {
      final container = makeContainer(
        places: places,
        local: local,
        discoverState: const DiscoverState(),
      );
      addTearDown(container.dispose);

      final weather = await container.read(locationWeatherProvider.future);
      expect(weather, isNull);
    });

    test(
        'falls back to mock weather when HTTP fails (HTTP overrides intercept)',
        () async {
      // Run inside an HTTP overrides zone so the provider's http.get fails
      // immediately and we exercise the catch-block fallback path.
      await HttpOverrides.runZoned<Future<void>>(() async {
        final container = makeContainer(
          places: places,
          local: local,
          discoverState: withLocation,
        );
        addTearDown(container.dispose);

        final weather =
            await container.read(locationWeatherProvider.future);
        // Fallback path returns mock WeatherData with the location name
        expect(weather, isNotNull);
        expect(weather!.locationName, isNotEmpty);
        // Mock fallback creates a WeatherData with sane defaults
        expect(weather.temperature, isA<double>());
      }, createHttpClient: (context) => _AlwaysFailHttpClient());
    });
  });
}

/// HttpClient that throws on every request — used to force the
/// `locationWeatherProvider`'s http.get into its catch fallback.
class _AlwaysFailHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) {
    final m = invocation.memberName;
    if (m == #getUrl ||
        m == #openUrl ||
        m == #get ||
        m == #open ||
        m == #postUrl ||
        m == #post ||
        m == #headUrl ||
        m == #head ||
        m == #patchUrl ||
        m == #patch ||
        m == #putUrl ||
        m == #put ||
        m == #deleteUrl ||
        m == #delete) {
      return Future<HttpClientRequest>.error(
        const SocketException('test: network disabled'),
      );
    }
    return super.noSuchMethod(invocation);
  }
}
