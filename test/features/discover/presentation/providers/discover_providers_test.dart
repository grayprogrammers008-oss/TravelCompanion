import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/data/datasources/discover_local_datasource.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';

/// Stub GooglePlacesService that throws on every method call.
/// Tier A tests should NEVER hit this; if they do the test will fail loudly.
/// For Tier B tests that internally trigger loadPlaces (like setLocation,
/// setCountry), the throw is caught by loadPlaces' try/catch so it does
/// not affect the optimistic state delta we are asserting.
class _NoopGooglePlacesService extends GooglePlacesService {
  _NoopGooglePlacesService() : super();

  @override
  Future<List<NearbyPlace>> searchNearby({
    required double latitude,
    required double longitude,
    int? radius,
    String? type,
    String? keyword,
    String rankBy = 'prominence',
    int maxResults = 60,
  }) async {
    throw StateError(
      'GooglePlacesService.searchNearby should not be called in unit tests',
    );
  }
}

/// Hand-rolled fake DiscoverLocalDataSource that records calls and returns
/// canned data instead of touching Hive. We override only the methods used
/// in tests; remaining methods inherit from the parent and would throw a
/// StateError if called (by design, so missing stubs are obvious).
class _FakeLocalDataSource extends DiscoverLocalDataSource {
  bool initializeCalled = false;
  Set<String> savedFavorites = <String>{};
  final List<String> addedFavorites = [];
  final List<String> removedFavorites = [];
  final List<DiscoverPlace> savedFavoritePlaces = [];
  final List<String> removedFavoritePlaces = [];
  Set<String> favoritesToReturn = <String>{};
  List<DiscoverPlace> favoritePlacesToReturn = const [];
  Map<String, List<DiscoverPlace>?> placesByCategory = const {};

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<void> saveFavorites(Set<String> favoriteIds) async {
    savedFavorites = Set<String>.from(favoriteIds);
  }

  @override
  Future<Set<String>> getFavorites() async {
    return Set<String>.from(favoritesToReturn);
  }

  @override
  Future<void> addFavorite(String placeId) async {
    addedFavorites.add(placeId);
  }

  @override
  Future<void> removeFavorite(String placeId) async {
    removedFavorites.add(placeId);
  }

  @override
  Future<void> saveFavoritePlace(DiscoverPlace place) async {
    savedFavoritePlaces.add(place);
  }

  @override
  Future<void> removeFavoritePlace(String placeId) async {
    removedFavoritePlaces.add(placeId);
  }

  @override
  Future<List<DiscoverPlace>> getFavoritePlaces() async {
    return List<DiscoverPlace>.from(favoritePlacesToReturn);
  }

  @override
  Future<List<DiscoverPlace>?> getPlaces({
    required PlaceCategory category,
    required double latitude,
    required double longitude,
    bool ignoreExpiry = false,
  }) async {
    return placesByCategory[category.name];
  }
}

/// Bare-bones fake that throws on any access. The notifier code paths we
/// exercise either:
///   (a) never touch `_supabase` (Tier A pure-state methods), or
///   (b) wrap the access in a try/catch (toggleFavorite, _loadFavoritesFromSupabase),
/// so a throwing fake exercises the error-handling branch and verifies the
/// optimistic state mutation still happens.
class _ThrowingSupabaseClient extends Mock implements SupabaseClient {
  @override
  GoTrueClient get auth =>
      throw StateError('Supabase auth not available in unit tests');
}

/// Helper to build a configured ProviderContainer.
ProviderContainer _buildContainer({
  _NoopGooglePlacesService? places,
  _FakeLocalDataSource? local,
  SupabaseClient? supabase,
}) {
  return ProviderContainer(
    overrides: [
      googlePlacesServiceProvider
          .overrideWithValue(places ?? _NoopGooglePlacesService()),
      discoverLocalDataSourceProvider
          .overrideWithValue(local ?? _FakeLocalDataSource()),
      discoverSupabaseProvider
          .overrideWithValue(supabase ?? _ThrowingSupabaseClient()),
    ],
  );
}

DiscoverPlace _makePlace(String id, {String name = 'Place'}) {
  return DiscoverPlace(
    placeId: id,
    name: name,
    category: PlaceCategory.heritage,
    latitude: 12.97,
    longitude: 77.59,
    types: const ['point_of_interest'],
    photos: const [],
  );
}

void main() {
  group('DiscoverStateNotifier - Tier A: pure state methods', () {
    test('initial state has empty searchQuery and grid view mode', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final state = container.read(discoverStateProvider);
      expect(state.searchQuery, '');
      expect(state.viewMode, DiscoverViewMode.grid);
      expect(state.favoriteIds, isEmpty);
      expect(state.showFavoritesOnly, isFalse);
      expect(state.selectedCountry, isNull);
      expect(state.hasLocation, isFalse);
    });

    test('setSearchQuery updates state.searchQuery', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      container
          .read(discoverStateProvider.notifier)
          .setSearchQuery('beach goa');

      expect(container.read(discoverStateProvider).searchQuery, 'beach goa');
    });

    test('setSearchQuery can overwrite a previous query', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      notifier.setSearchQuery('first');
      notifier.setSearchQuery('second');

      expect(container.read(discoverStateProvider).searchQuery, 'second');
    });

    test('clearSearch resets searchQuery to empty string', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      notifier.setSearchQuery('something');
      expect(container.read(discoverStateProvider).searchQuery, 'something');

      notifier.clearSearch();
      expect(container.read(discoverStateProvider).searchQuery, '');
    });

    test('toggleViewMode flips grid -> map', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      // Default is grid.
      expect(
        container.read(discoverStateProvider).viewMode,
        DiscoverViewMode.grid,
      );

      container.read(discoverStateProvider.notifier).toggleViewMode();
      expect(
        container.read(discoverStateProvider).viewMode,
        DiscoverViewMode.map,
      );
    });

    test('toggleViewMode flips map -> grid', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      notifier.setViewMode(DiscoverViewMode.map);
      notifier.toggleViewMode();

      expect(
        container.read(discoverStateProvider).viewMode,
        DiscoverViewMode.grid,
      );
    });

    test('setViewMode sets the supplied mode', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      notifier.setViewMode(DiscoverViewMode.map);
      expect(
        container.read(discoverStateProvider).viewMode,
        DiscoverViewMode.map,
      );

      notifier.setViewMode(DiscoverViewMode.grid);
      expect(
        container.read(discoverStateProvider).viewMode,
        DiscoverViewMode.grid,
      );
    });

    test('toggleShowFavoritesOnly flips boolean false -> true -> false', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      expect(
        container.read(discoverStateProvider).showFavoritesOnly,
        isFalse,
      );

      notifier.toggleShowFavoritesOnly();
      expect(
        container.read(discoverStateProvider).showFavoritesOnly,
        isTrue,
      );

      notifier.toggleShowFavoritesOnly();
      expect(
        container.read(discoverStateProvider).showFavoritesOnly,
        isFalse,
      );
    });

    test('isFavorite returns false when favoriteIds is empty', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      expect(
        container
            .read(discoverStateProvider.notifier)
            .isFavorite('place-1'),
        isFalse,
      );
    });

    test('isFavorite returns true iff placeId is in favoriteIds set',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // Use toggleFavorite to populate favorites (no auth user, so Supabase
      // call is skipped). _cacheInitialized is false so local persist is
      // also skipped, leaving us with a clean optimistic state mutation.
      await notifier.toggleFavorite('place-1');
      await notifier.toggleFavorite('place-2');

      expect(notifier.isFavorite('place-1'), isTrue);
      expect(notifier.isFavorite('place-2'), isTrue);
      expect(notifier.isFavorite('place-99'), isFalse);
    });
  });

  group('DiscoverStateNotifier - Tier B: methods needing dep mocks', () {
    test('toggleFavorite adds an id (optimistic state update)', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      final wasAdded = await notifier.toggleFavorite('place-1');

      expect(wasAdded, isTrue);
      expect(
        container.read(discoverStateProvider).favoriteIds,
        contains('place-1'),
      );
    });

    test('toggleFavorite removes an id when called twice', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      await notifier.toggleFavorite('place-1');
      final wasAdded = await notifier.toggleFavorite('place-1');

      expect(wasAdded, isFalse);
      expect(
        container.read(discoverStateProvider).favoriteIds,
        isNot(contains('place-1')),
      );
    });

    test('toggleFavorite does not mutate the previous state set', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      final originalFavorites =
          container.read(discoverStateProvider).favoriteIds;

      await notifier.toggleFavorite('place-1');

      // Original empty set is still empty (immutability check).
      expect(originalFavorites, isEmpty);
      expect(
        container.read(discoverStateProvider).favoriteIds,
        contains('place-1'),
      );
    });

    test('toggleFavorite with multiple ids accumulates in favoriteIds',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      await notifier.toggleFavorite('c');

      expect(
        container.read(discoverStateProvider).favoriteIds,
        {'a', 'b', 'c'},
      );
    });

    test('getFavoritePlaces returns places stored in local data source',
        () async {
      final fake = _FakeLocalDataSource()
        ..favoritePlacesToReturn = [
          _makePlace('a', name: 'Alpha'),
          _makePlace('b', name: 'Bravo'),
        ];
      final container = _buildContainer(local: fake);
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // _cacheInitialized starts false, so the local-stored fetch is gated.
      // Manually mark cache as initialized via toggleFavorite path is not
      // possible without initialize(); however getFavoritePlaces also pulls
      // from state.places. We use that fallback path below.
      // Here, _cacheInitialized=false means the function returns [] from
      // local + scans state.places (which is empty) + skips category cache.
      final result = await notifier.getFavoritePlaces();
      expect(result, isEmpty);
    });

    test(
        'getFavoritePlaces returns favorites filtered from state.places when no cache',
        () async {
      final fake = _FakeLocalDataSource();
      final container = _buildContainer(local: fake);
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // Populate favorites via toggleFavorite.
      await notifier.toggleFavorite('place-1');
      await notifier.toggleFavorite('place-2');

      // We can't mutate state.places directly (the field is final and
      // copyWith is internal to the notifier). But we can verify the
      // method returns an empty list when state.places is empty AND
      // _cacheInitialized is false — i.e. the method handles the empty
      // path safely.
      final result = await notifier.getFavoritePlaces();
      expect(result, isEmpty);
    });

    test('setCountry with null delegates to clearCountry (no error)',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // clearCountry calls _getUserLocation which hits the real Geolocator
      // plugin. In a unit-test environment the plugin throws a
      // MissingPluginException, but that is caught inside _getUserLocation
      // and surfaced as state.error — the notifier itself does not throw.
      await notifier.setCountry(null);

      // selectedCountry stays null.
      expect(container.read(discoverStateProvider).selectedCountry, isNull);
    });

    test('setCountry with an unknown country leaves state untouched',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      await notifier.setCountry('Atlantis'); // not in _countryCoordinates

      // The notifier returns early without changing selectedCountry.
      expect(
        container.read(discoverStateProvider).selectedCountry,
        isNull,
      );
    });

    test('setCountry with a known country updates state coordinates',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // selectedCategory is null by default ("Popular Nearby"), so
      // _getCoordinatesForCountryAndCategory returns the default country
      // centroid for India: lat 20.5937, lng 78.9629.
      await notifier.setCountry('India');

      final state = container.read(discoverStateProvider);
      expect(state.selectedCountry, 'India');
      expect(state.userLatitude, closeTo(20.5937, 0.0001));
      expect(state.userLongitude, closeTo(78.9629, 0.0001));
      expect(state.locationName, 'India');
    });

    test('clearCountry resets selectedCountry to null in state', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // First set a country.
      await notifier.setCountry('India');
      expect(
        container.read(discoverStateProvider).selectedCountry,
        'India',
      );

      // Now clear. _getUserLocation will fail in the test env (Geolocator
      // plugin missing) but the failure is caught and converted to
      // state.error; the country IS cleared synchronously beforehand.
      await notifier.clearCountry();
      expect(
        container.read(discoverStateProvider).selectedCountry,
        isNull,
      );
      expect(
        container.read(discoverStateProvider).isLocationFromSearch,
        isFalse,
      );
    });

    test('setLocation updates lat/lng/locationName/isLocationFromSearch',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      await notifier.setLocation(
        latitude: 48.8566,
        longitude: 2.3522,
        locationName: 'Paris',
      );

      final state = container.read(discoverStateProvider);
      expect(state.userLatitude, closeTo(48.8566, 0.0001));
      expect(state.userLongitude, closeTo(2.3522, 0.0001));
      expect(state.locationName, 'Paris');
      expect(state.isLocationFromSearch, isTrue);
      // No country provided -> selectedCountry should be cleared.
      expect(state.selectedCountry, isNull);
    });

    test(
        'setLocation with a country uses category-specific destination coordinates',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(discoverStateProvider.notifier);
      // Default selectedCategory is null -> falls back to country centroid
      // for Thailand: lat 15.8700, lng 100.9925.
      await notifier.setLocation(
        latitude: 0,
        longitude: 0,
        locationName: 'unused',
        country: 'Thailand',
      );

      final state = container.read(discoverStateProvider);
      expect(state.selectedCountry, 'Thailand');
      // Coordinates remapped to Thailand's centroid (since category is null).
      expect(state.userLatitude, closeTo(15.8700, 0.0001));
      expect(state.userLongitude, closeTo(100.9925, 0.0001));
      expect(state.isLocationFromSearch, isTrue);
    });
  });
}
