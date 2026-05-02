import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/place_detail_sheet.dart';

DiscoverPlace makePlace({
  String placeId = 'p-1',
  String name = 'Eiffel Tower',
  String? vicinity = 'Champ de Mars, Paris',
  double? lat = 48.8584,
  double? lng = 2.2945,
  double? rating = 4.7,
  int? userRatingsTotal = 1234,
  bool? openNow = true,
  List<PlacePhoto> photos = const [],
  PlaceCategory category = PlaceCategory.heritage,
}) =>
    DiscoverPlace(
      placeId: placeId,
      name: name,
      vicinity: vicinity,
      latitude: lat,
      longitude: lng,
      types: const ['point_of_interest'],
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      openNow: openNow,
      photos: photos,
      category: category,
    );

PlaceDetails makeDetails({
  String placeId = 'p-1',
  String name = 'Eiffel Tower',
  String formattedAddress = 'Champ de Mars, 5 Av. Anatole France, 75007 Paris',
  String? website = 'https://www.toureiffel.paris',
  String? url = 'https://maps.google.com/?cid=12345',
}) =>
    PlaceDetails(
      placeId: placeId,
      name: name,
      formattedAddress: formattedAddress,
      latitude: 48.8584,
      longitude: 2.2945,
      photos: const [],
      types: const ['tourist_attraction'],
      website: website,
      url: url,
      rating: 4.7,
      userRatingsTotal: 1234,
    );

void main() {
  Widget buildScope({
    required DiscoverPlace place,
    PlaceDetails? details,
  }) {
    return ProviderScope(
      overrides: [
        placeDetailsProvider(place.placeId)
            .overrideWith((ref) async => details),
      ],
      child: MaterialApp(
        home: Scaffold(body: PlaceDetailSheet(place: place)),
      ),
    );
  }

  group('PlaceDetailSheet', () {
    testWidgets('renders place name and category chip', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace(name: 'Eiffel Tower');

      await tester.pumpWidget(buildScope(
        place: place,
        details: makeDetails(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Eiffel Tower'), findsOneWidget);
      // Category chip label "Heritage"
      expect(find.text(PlaceCategory.heritage.displayName), findsOneWidget);
    });

    testWidgets('renders rating text and reviews count', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace(rating: 4.7, userRatingsTotal: 1234);

      await tester.pumpWidget(buildScope(
        place: place,
        details: makeDetails(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('4.7'), findsOneWidget);
      // 1234 reviews => "1.2k reviews"
      expect(find.text('1.2k reviews'), findsOneWidget);
    });

    testWidgets('renders vicinity text when provided', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace(vicinity: 'Champ de Mars, Paris');

      await tester.pumpWidget(buildScope(
        place: place,
        details: makeDetails(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Champ de Mars, Paris'), findsOneWidget);
    });

    testWidgets('shows "Open now" status badge when openNow is true',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace(openNow: true);

      await tester.pumpWidget(buildScope(
        place: place,
        details: makeDetails(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Open now'), findsOneWidget);
    });

    testWidgets(
        'renders details section with website and Google Maps link from PlaceDetails',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace();

      await tester.pumpWidget(buildScope(
        place: place,
        details: makeDetails(
          website: 'https://www.toureiffel.paris',
          url: 'https://maps.google.com/?cid=12345',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Website'), findsOneWidget);
      expect(find.text('https://www.toureiffel.paris'), findsOneWidget);
      expect(find.text('View on Google Maps'), findsOneWidget);
    });

    testWidgets('renders Add to Trip and Directions action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace();

      await tester.pumpWidget(buildScope(
        place: place,
        details: makeDetails(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // ElevatedButton.icon and OutlinedButton.icon constructors do not
      // produce ElevatedButton/OutlinedButton in the tree; assert via labels
      // and icons.
      expect(find.text('Add to Trip'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.byIcon(Icons.add_location_alt), findsOneWidget);
      expect(find.byIcon(Icons.directions), findsOneWidget);
    });

    testWidgets('details section renders nothing when PlaceDetails is null',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final place = makePlace();

      await tester.pumpWidget(buildScope(
        place: place,
        details: null, // Provider resolves to null
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Should not render website/maps detail rows
      expect(find.text('Website'), findsNothing);
      expect(find.text('View on Google Maps'), findsNothing);
      // But the rest still renders
      expect(find.text('Eiffel Tower'), findsOneWidget);
    });
  });
}
