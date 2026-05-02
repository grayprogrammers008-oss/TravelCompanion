import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/widgets/mini_map_preview.dart';

DiscoverPlace _place({
  required String id,
  required String name,
  double? lat,
  double? lng,
  PlaceCategory category = PlaceCategory.nature,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      latitude: lat,
      longitude: lng,
      types: const ['point_of_interest'],
      photos: const [],
      category: category,
    );

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('MiniMapPreview', () {
    testWidgets('shows no-location placeholder when user lat/lng are null',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MiniMapPreview(places: []),
      ));
      await tester.pump();

      expect(find.text('Location needed for map preview'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('renders header, place count badge and legend with location',
        (tester) async {
      // Set a larger viewport so the map content fits
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final places = [
        _place(id: '1', name: 'Park One', lat: 12.97, lng: 77.59),
        _place(id: '2', name: 'Park Two', lat: 12.98, lng: 77.60),
      ];

      await tester.pumpWidget(wrap(
        MiniMapPreview(
          places: places,
          userLatitude: 12.9716,
          userLongitude: 77.5946,
          radiusKm: 10,
          category: PlaceCategory.nature,
        ),
      ));
      await tester.pump();

      expect(find.text('Places around you'), findsOneWidget);
      expect(find.text('2 places'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('10 km radius'), findsOneWidget);
    });

    testWidgets('renders with empty places list and shows count of 0',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        const MiniMapPreview(
          places: [],
          userLatitude: 12.97,
          userLongitude: 77.59,
        ),
      ));
      await tester.pump();

      expect(find.text('0 places'), findsOneWidget);
      // Default category is null -> "Popular Places" label in legend
      expect(find.text('Popular Places'), findsOneWidget);
    });

    testWidgets('uses custom radiusKm in legend label', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        const MiniMapPreview(
          places: [],
          userLatitude: 12.97,
          userLongitude: 77.59,
          radiusKm: 25,
        ),
      ));
      await tester.pump();

      expect(find.text('25 km radius'), findsOneWidget);
    });

    testWidgets('shows expand button when onExpandTapped is provided',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var expandTapped = false;

      await tester.pumpWidget(wrap(
        MiniMapPreview(
          places: const [],
          userLatitude: 12.97,
          userLongitude: 77.59,
          onExpandTapped: () => expandTapped = true,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pump();
      expect(expandTapped, isTrue);
    });

    testWidgets('hides expand button when onExpandTapped is null',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        const MiniMapPreview(
          places: [],
          userLatitude: 12.97,
          userLongitude: 77.59,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.fullscreen), findsNothing);
    });

    testWidgets('clusters multiple places into one marker count badge',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 5 places, all within ~500m of each other -> single cluster.
      final places = List.generate(
        5,
        (i) => _place(
          id: 'p$i',
          name: 'P$i',
          lat: 12.9716 + i * 0.0001,
          lng: 77.5946 + i * 0.0001,
        ),
      );

      await tester.pumpWidget(wrap(
        MiniMapPreview(
          places: places,
          userLatitude: 12.9716,
          userLongitude: 77.5946,
          category: PlaceCategory.heritage,
        ),
      ));
      await tester.pump();

      expect(find.text('5 places'), findsOneWidget);
      expect(find.text('Heritage'), findsOneWidget);
    });
  });
}
