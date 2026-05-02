import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/trip_planning_assistant_sheet.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

class _FakeDiscoverStateNotifier extends DiscoverStateNotifier {
  _FakeDiscoverStateNotifier(this._initialState, {this.favoritePlaces = const []});
  final DiscoverState _initialState;
  final List<DiscoverPlace> favoritePlaces;

  @override
  DiscoverState build() => _initialState;

  @override
  Future<List<DiscoverPlace>> getFavoritePlaces() async {
    return favoritePlaces;
  }
}

DiscoverPlace makePlace({
  required String id,
  String name = 'Place',
  PlaceCategory category = PlaceCategory.heritage,
  double rating = 4.5,
  double? lat = 12.97,
  double? lng = 77.59,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      latitude: lat,
      longitude: lng,
      types: const ['point_of_interest'],
      rating: rating,
      userRatingsTotal: 200,
      photos: const [],
      category: category,
    );

TripWithMembers makeTrip({
  String id = 'trip-1',
  String name = 'Goa Trip',
  String? destination = 'Goa',
  bool isCompleted = false,
}) {
  final now = DateTime(2025, 6, 1);
  final trip = TripModel(
    id: id,
    name: name,
    destination: destination,
    startDate: now,
    endDate: now.add(const Duration(days: 2)),
    createdBy: 'user-1',
    createdAt: now,
    updatedAt: now,
    isCompleted: isCompleted,
  );
  return TripWithMembers(trip: trip, members: const []);
}

void main() {
  Widget buildScope({
    required _FakeDiscoverStateNotifier notifier,
    List<TripWithMembers> trips = const [],
  }) {
    return ProviderScope(
      overrides: [
        discoverStateProvider.overrideWith(() => notifier),
        userTripsProvider.overrideWith((ref) async => trips),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TripPlanningAssistantSheet()),
      ),
    );
  }

  group('TripPlanningAssistantSheet', () {
    testWidgets('renders header and step 0 title', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = _FakeDiscoverStateNotifier(
        const DiscoverState(),
        favoritePlaces: const [],
      );

      await tester.pumpWidget(buildScope(notifier: notifier));
      // Allow initState future to resolve
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Trip Planning Assistant'), findsOneWidget);
      expect(find.text('Select places from your favorites'), findsOneWidget);
    });

    testWidgets('shows "No Favorites Yet" empty state when favorites are empty',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = _FakeDiscoverStateNotifier(
        const DiscoverState(),
        favoritePlaces: const [],
      );

      await tester.pumpWidget(buildScope(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No Favorites Yet'), findsOneWidget);
      expect(find.text('Explore Places'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsAtLeastNWidgets(1));
    });

    testWidgets('renders favorite place cards when favorites are populated',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final favorites = [
        makePlace(id: 'p1', name: 'Beach One', category: PlaceCategory.beach),
        makePlace(id: 'p2', name: 'Castle One', category: PlaceCategory.heritage),
      ];
      final notifier = _FakeDiscoverStateNotifier(
        DiscoverState(
          places: favorites,
          favoriteIds: const {'p1', 'p2'},
        ),
        favoritePlaces: favorites,
      );

      await tester.pumpWidget(buildScope(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Counter shows "0 of 2 selected" before any selection
      expect(find.text('0 of 2 selected'), findsOneWidget);
      expect(find.text('Beach One'), findsOneWidget);
      expect(find.text('Castle One'), findsOneWidget);
      // Select All button
      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('Select All toggles all favorites', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final favorites = [
        makePlace(id: 'p1', name: 'Beach One', category: PlaceCategory.beach),
        makePlace(id: 'p2', name: 'Castle One', category: PlaceCategory.heritage),
      ];
      final notifier = _FakeDiscoverStateNotifier(
        DiscoverState(
          places: favorites,
          favoriteIds: const {'p1', 'p2'},
        ),
        favoritePlaces: favorites,
      );

      await tester.pumpWidget(buildScope(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Select All'));
      await tester.pump();

      expect(find.text('2 of 2 selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);
    });

    testWidgets(
        'Continue button is disabled when no favorites are selected',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final favorites = [
        makePlace(id: 'p1', name: 'Beach One', category: PlaceCategory.beach),
      ];
      final notifier = _FakeDiscoverStateNotifier(
        DiscoverState(
          places: favorites,
          favoriteIds: const {'p1'},
        ),
        favoritePlaces: favorites,
      );

      await tester.pumpWidget(buildScope(notifier: notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Step 0 button label includes selected count
      final continueButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(continueButton.onPressed, isNull);
      expect(find.text('Continue (0 selected)'), findsOneWidget);
    });

    testWidgets(
        'progressing through steps generates a GeneratedTripPlan in step 3',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final favorites = [
        makePlace(id: 'p1', name: 'Beach One', category: PlaceCategory.beach),
        makePlace(id: 'p2', name: 'Castle One', category: PlaceCategory.heritage),
      ];
      final notifier = _FakeDiscoverStateNotifier(
        DiscoverState(
          places: favorites,
          favoriteIds: const {'p1', 'p2'},
          userLatitude: 12.97,
          userLongitude: 77.59,
        ),
        favoritePlaces: favorites,
      );

      final trips = [
        makeTrip(id: 'trip-1', name: 'Goa Trip'),
      ];

      await tester.pumpWidget(buildScope(notifier: notifier, trips: trips));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Step 0: Select all, then Continue
      await tester.tap(find.text('Select All'));
      await tester.pump();

      await tester.tap(find.text('Continue (2 selected)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Step 1: Trip selection — should show Goa Trip
      expect(find.text('Choose a trip to add activities'), findsOneWidget);
      expect(find.text('Goa Trip'), findsOneWidget);

      await tester.tap(find.text('Goa Trip'));
      await tester.pump();

      // Click "Configure Preferences"
      await tester.tap(find.text('Configure Preferences'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Step 2: Preferences
      expect(find.text('Set your travel preferences'), findsOneWidget);
      expect(find.text('Travel Pace'), findsOneWidget);

      // Click "Generate Itinerary"
      await tester.tap(find.text('Generate Itinerary'));
      // The widget awaits a 800ms delay, then sets _generatedPlan.
      await tester.pump(); // start generating, set isGenerating
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();

      // Step 3: Review
      expect(find.text('Review your generated itinerary'), findsOneWidget);
      expect(find.text('Your Itinerary'), findsOneWidget);
      // Trip is 3 days (start->end inclusive)
      expect(find.textContaining('Days'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Activities'), findsAtLeastNWidgets(1));
    });
  });
}
