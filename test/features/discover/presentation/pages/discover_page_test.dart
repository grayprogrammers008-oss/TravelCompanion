import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/pages/discover_page.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';

/// `_FakeDiscoverStateNotifier` returns a fixed state and records calls so
/// tests can verify which methods the page invokes. Every notifier method
/// the page might call is overridden as a no-op so plugin channels and the
/// real Supabase / GooglePlaces / Geolocator stack are never touched.
class _FakeDiscoverStateNotifier extends DiscoverStateNotifier {
  _FakeDiscoverStateNotifier(this._initialState);
  final DiscoverState _initialState;

  // Call counters
  int initializeCalls = 0;
  int getUserLocationCalls = 0;
  int loadPlacesCalls = 0;
  int refreshCalls = 0;
  int toggleViewModeCalls = 0;
  int toggleShowFavoritesOnlyCalls = 0;
  int changeCategoryCalls = 0;
  PlaceCategory? lastChangedCategory;
  int toggleFavoriteCalls = 0;
  int changeDistanceCalls = 0;

  @override
  DiscoverState build() => _initialState;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> getUserLocation() async {
    getUserLocationCalls++;
  }

  @override
  Future<void> loadPlaces(PlaceCategory? category, {bool skipCache = false}) async {
    loadPlacesCalls++;
  }

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  void toggleViewMode() {
    toggleViewModeCalls++;
  }

  @override
  void toggleShowFavoritesOnly() {
    toggleShowFavoritesOnlyCalls++;
  }

  @override
  Future<void> changeCategory(PlaceCategory category) async {
    changeCategoryCalls++;
    lastChangedCategory = category;
  }

  @override
  Future<void> changeDistance(DiscoverDistance distance) async {
    changeDistanceCalls++;
  }

  @override
  Future<bool> toggleFavorite(String placeId, {DiscoverPlace? place}) async {
    toggleFavoriteCalls++;
    return true;
  }
}

DiscoverPlace _samplePlace({
  String id = 'p1',
  String name = 'Test Place',
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      types: const [],
      photos: const [PlacePhoto(
        photoReference: 'ref',
        width: 100,
        height: 100,
        htmlAttributions: [],
      )],
      category: PlaceCategory.beach,
      vicinity: 'Test City',
      rating: 4.5,
      userRatingsTotal: 200,
      latitude: 12.97,
      longitude: 77.59,
    );

Widget _buildPage(
  DiscoverState state, {
  _FakeDiscoverStateNotifier? notifier,
}) {
  final fake = notifier ?? _FakeDiscoverStateNotifier(state);
  return ProviderScope(
    overrides: [
      discoverStateProvider.overrideWith(() => fake),
      placePhotoUrlProvider.overrideWith((ref, photoRef) async => null),
      placeDetailsProvider.overrideWith((ref, placeId) async => null),
      locationWeatherProvider.overrideWith((ref) async => null),
    ],
    child: const MaterialApp(home: DiscoverPage()),
  );
}

void main() {
  // The Discover page renders many horizontal lists, sliver categories,
  // and FloatingActionButton positioning that exceed the default
  // 800x600 test viewport. Use a tall viewport globally.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('DiscoverPage — render branches', () {
    testWidgets('shows "Getting your location..." when isGettingLocation',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(isGettingLocation: true),
      ));
      await tester.pump();

      expect(find.text('Getting your location...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error state when error is set', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(error: 'Something went wrong'),
      ));
      await tester.pump();

      // Page shows "Oops! Something went wrong" header AND the actual
      // error message — at least 2 matches.
      expect(
        find.textContaining('went wrong', findRichText: true),
        findsAtLeastNWidgets(2),
      );
    });

    testWidgets('shows "Finding places near you..." when isLoading',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(
          isLoading: true,
          userLatitude: 12.97,
          userLongitude: 77.59,
        ),
      ));
      await tester.pump();

      expect(find.text('Finding places near you...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('shows location prompt when no location set and not loading',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(),
      ));
      await tester.pump();

      // Without location, the page renders the discover-prompt CTA which
      // includes the search icon (Search Destinations) action.
      expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));
    });

    testWidgets('renders place grid when location set and places present',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
          places: [_samplePlace(id: '1'), _samplePlace(id: '2')],
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Grid view: place cards rendered (PlaceCard widget) — verify one
      // signal that a place card is on screen.
      expect(find.text('Test Place'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders empty state when location set but places empty',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // No PlaceCard / "Test Place" text since no places exist.
      expect(find.text('Test Place'), findsNothing);
    });
  });

  group('DiscoverPage — FAB', () {
    testWidgets('FAB hidden when favoriteIds is empty', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
        ),
      ));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('FAB shows "Plan Trip (n)" when favoriteIds has items',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
          places: [_samplePlace(id: 'a'), _samplePlace(id: 'b')],
          favoriteIds: const {'a', 'b'},
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Plan Trip (2)'), findsOneWidget);
    });
  });

  group('DiscoverPage — AppBar interactions', () {
    testWidgets('refresh button taps notifier.refresh()', (tester) async {
      useTallViewport(tester);
      final notifier = _FakeDiscoverStateNotifier(
        const DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
        ),
      );
      await tester.pumpWidget(_buildPage(
        const DiscoverState(),
        notifier: notifier,
      ));
      await tester.pump();

      final refreshBtn = find.byTooltip('Refresh');
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();

      expect(notifier.refreshCalls, 1);
    });

    testWidgets('favorites filter button toggles showFavoritesOnly',
        (tester) async {
      useTallViewport(tester);
      final notifier = _FakeDiscoverStateNotifier(
        const DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
        ),
      );
      await tester.pumpWidget(_buildPage(
        const DiscoverState(),
        notifier: notifier,
      ));
      await tester.pump();

      // Tooltip says "Show Favorites Only" when not currently filtering.
      final favBtn = find.byTooltip('Show Favorites Only');
      expect(favBtn, findsOneWidget);
      await tester.tap(favBtn);
      await tester.pump();

      expect(notifier.toggleShowFavoritesOnlyCalls, 1);
    });

    testWidgets('view-mode toggle visible only with location and places',
        (tester) async {
      useTallViewport(tester);
      final notifier = _FakeDiscoverStateNotifier(
        DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
          places: [_samplePlace()],
        ),
      );
      await tester.pumpWidget(_buildPage(
        const DiscoverState(),
        notifier: notifier,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 'Map View' tooltip is on the toggle when current viewMode is grid.
      final mapBtn = find.byTooltip('Map View');
      expect(mapBtn, findsOneWidget);
      await tester.tap(mapBtn);
      await tester.pump();

      expect(notifier.toggleViewModeCalls, 1);
    });

    testWidgets('view-mode toggle hidden when no places', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(
        const DiscoverState(
          userLatitude: 12.97,
          userLongitude: 77.59,
          locationName: 'Bangalore',
        ),
      ));
      await tester.pump();

      // No places → toggle button hidden
      expect(find.byTooltip('Map View'), findsNothing);
      expect(find.byTooltip('Grid View'), findsNothing);
    });
  });
}
