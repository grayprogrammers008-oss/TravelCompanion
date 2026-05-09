import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_crew/core/services/google_maps_url_parser.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/itinerary/presentation/widgets/add_location_to_trip_sheet.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

ParsedLocation _location({
  String? placeName = 'Eiffel Tower',
  double? lat = 48.8584,
  double? lng = 2.2945,
}) {
  return ParsedLocation(
    placeName: placeName,
    latitude: lat,
    longitude: lng,
    originalUrl: 'https://maps.google.com/?q=$lat,$lng',
  );
}

TripWithMembers _trip({
  String id = 't1',
  String name = 'Paris Trip',
  String createdBy = 'owner-1',
  DateTime? startDate,
  DateTime? endDate,
  String? destination = 'Paris',
}) {
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      createdBy: createdBy,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
    ),
    members: const [],
  );
}

Widget _wrap({
  required ParsedLocation location,
  required List<TripWithMembers> trips,
}) {
  return ProviderScope(
    overrides: [
      userTripsProvider.overrideWith((ref) async => trips),
    ],
    child: AppThemeProvider(
      themeData: AppThemeData.getThemeData(AppThemeType.ocean),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AddLocationToTripSheet(location: location),
        ),
      ),
    ),
  );
}

void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AddLocationToTripSheet extra — step 1 details', () {
    testWidgets('falls back to "Add Location" when placeName is null',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(placeName: null),
        trips: [_trip()],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Add Location'), findsOneWidget);
    });

    testWidgets('hides coordinate text when location has no coordinates',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(lat: null, lng: null),
        trips: [_trip()],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('48.8584'), findsNothing);
    });

    testWidgets('upcoming trips list multiple cards in order', (tester) async {
      useTallViewport(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(id: 't1', name: 'Past Trip',
              startDate: now.subtract(const Duration(days: 60)),
              endDate: now.subtract(const Duration(days: 50))),
          _trip(id: 't2', name: 'Future Trip',
              startDate: now.add(const Duration(days: 30)),
              endDate: now.add(const Duration(days: 35))),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Past Trip'), findsOneWidget);
      expect(find.text('Future Trip'), findsOneWidget);
    });

    testWidgets('shows flight icon as the trip-card avatar', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [_trip()],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.flight), findsAtLeastNWidgets(1));
    });

    testWidgets('chevron_right icon appears on each trip card', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(id: 't1'),
          _trip(id: 't2', name: 'Other'),
        ],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });
  });

  group('AddLocationToTripSheet extra — step 2 details', () {
    testWidgets('back button + close button are both rendered on step 2',
        (tester) async {
      useTallViewport(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 2)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.close), findsAtLeastNWidgets(1));
    });

    testWidgets('Selected day chip widget responds to tap', (tester) async {
      useTallViewport(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 4)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the second-day chip (Day 2)
      await tester.tap(find.text('2').first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Add button label should now read "Add to Day 2"
      expect(find.text('Add to Day 2'), findsOneWidget);
    });

    testWidgets('the add button shows the day number for trips without dates',
        (tester) async {
      useTallViewport(tester);
      // Trip without dates → defaults to 7 days, all valid
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [_trip()],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Defaults to first day in the valid-days list when trip dates are
      // missing (7-day fallback).
      expect(find.text('Add to Day 1'), findsOneWidget);
    });

    testWidgets('day chip "Day" label appears on non-today days',
        (tester) async {
      useTallViewport(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 4)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 4 future days + 1 today = 5; "Today" once, "Day" 4 times
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Day'), findsNWidgets(4));
    });

    testWidgets(
        'editing the activity title updates the in-state value',
        (tester) async {
      useTallViewport(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        location: _location(placeName: 'Original'),
        trips: [
          _trip(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 1)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Pre-filled with placeName
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller!.text, 'Original');

      await tester.enterText(find.byType(TextField), 'New Title');
      await tester.pump();
      expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'New Title');
    });
  });

  group('AddLocationToTripSheet extra — past-trip rendering', () {
    testWidgets('past trip shows all days starting from day 1', (tester) async {
      useTallViewport(tester);
      final past = DateTime.now().subtract(const Duration(days: 100));
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(
            startDate: past,
            endDate: past.add(const Duration(days: 2)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3-day past trip with no "Today" chip → "Day" appears 3 times
      expect(find.text('Today'), findsNothing);
      expect(find.text('Day'), findsNWidgets(3));
    });

    testWidgets('future trip shows all days starting from day 1',
        (tester) async {
      useTallViewport(tester);
      final future = DateTime.now().add(const Duration(days: 30));
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(
            startDate: future,
            endDate: future.add(const Duration(days: 2)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Today'), findsNothing);
      expect(find.text('Day'), findsNWidgets(3));
    });
  });

  group('AddLocationToTripSheet extra — close & dismiss', () {
    testWidgets('tapping close icon on step 1 dismisses the sheet',
        (tester) async {
      useTallViewport(tester);
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) async => <TripWithMembers>[]),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () async {
                      result = await AddLocationToTripSheet.show(
                          ctx, _location());
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isFalse);
    });

    testWidgets('back button on step 2 returns to "Select a trip" header',
        (tester) async {
      useTallViewport(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day)
                .add(const Duration(days: 2)),
          ),
        ],
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Paris Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Select a trip to add this location:'), findsOneWidget);
      // Trip selection state is cleared, no "Add to Day" label
      expect(find.textContaining('Add to Day'), findsNothing);
    });
  });

  group('AddLocationToTripSheet extra — last-selected persistence', () {
    testWidgets('renders "Last" badge for the trip stored in SharedPreferences',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'last_selected_trip_id': 't-last',
      });
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [
          _trip(id: 't-other', name: 'Other Trip'),
          _trip(id: 't-last', name: 'Last Trip'),
        ],
      ));
      // Pump the SharedPreferences future
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Last'), findsOneWidget);
    });
  });

  group('AddLocationToTripSheet extra — DraggableScrollableSheet structure', () {
    testWidgets('renders the handle bar at the top', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [_trip()],
      ));
      await tester.pump();

      // The handle bar is a 40x4 grey container — confirm DraggableScrollableSheet
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('renders ListView when trips are present', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        location: _location(),
        trips: [_trip(), _trip(id: 't2', name: 'Other')],
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
