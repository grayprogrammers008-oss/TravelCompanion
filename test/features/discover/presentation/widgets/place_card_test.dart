import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/place_card.dart';

DiscoverPlace _place({
  String placeId = 'p-1',
  String name = 'Sunset Beach',
  String? vicinity = '123 Coast Rd',
  double? lat = 12.9716,
  double? lng = 77.5946,
  double? rating = 4.5,
  int? userRatingsTotal = 1234,
  bool? openNow,
  List<PlacePhoto> photos = const [],
  PlaceCategory category = PlaceCategory.beach,
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

void main() {
  Widget buildScope({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        home: Scaffold(body: SizedBox(width: 220, height: 320, child: child)),
      ),
    );
  }

  group('PlaceCard', () {
    testWidgets('renders place name and rating', (tester) async {
      final place = _place();

      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      expect(find.text('Sunset Beach'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('shows fallback (category icon) when place has no photos',
        (tester) async {
      final place = _place(category: PlaceCategory.heritage);

      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      // Heritage icon used in fallback
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('shows distance badge when user lat/lng provided',
        (tester) async {
      final place = _place(lat: 12.9716, lng: 77.5946);

      await tester.pumpWidget(buildScope(
        child: PlaceCard(
          place: place,
          userLatitude: 12.9716,
          userLongitude: 77.5946,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.near_me), findsOneWidget);
      // Distance to itself is 0 m
      expect(find.text('0 m'), findsOneWidget);
    });

    testWidgets('does not show distance badge when user location is missing',
        (tester) async {
      final place = _place();
      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.near_me), findsNothing);
    });

    testWidgets('shows filled heart when isFavorite is true', (tester) async {
      final place = _place();
      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place, isFavorite: true),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('shows outline heart when isFavorite is false', (tester) async {
      final place = _place();
      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('invokes onFavoriteToggle when heart tapped', (tester) async {
      final place = _place();
      var toggleCount = 0;

      await tester.pumpWidget(buildScope(
        child: PlaceCard(
          place: place,
          onFavoriteToggle: () => toggleCount++,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      expect(toggleCount, 1);
    });

    testWidgets('shows quick add button when onQuickAdd is provided',
        (tester) async {
      final place = _place();
      var quickAddTapped = false;

      await tester.pumpWidget(buildScope(
        child: PlaceCard(
          place: place,
          onQuickAdd: () => quickAddTapped = true,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.add_location_alt), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_location_alt));
      await tester.pump();
      expect(quickAddTapped, isTrue);
    });

    testWidgets('hides quick add button when onQuickAdd is null',
        (tester) async {
      final place = _place();
      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.add_location_alt), findsNothing);
    });

    testWidgets('invokes onTap when card is tapped', (tester) async {
      final place = _place(
        // No image so no overlapping image area; ensures tap region is the card.
        photos: const [],
      );
      var tapCount = 0;

      await tester.pumpWidget(buildScope(
        child: PlaceCard(
          place: place,
          onTap: () => tapCount++,
        ),
      ));
      await tester.pump();

      // Tap the place name text — bubbles up to card's GestureDetector
      await tester.tap(find.text('Sunset Beach'));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('shows "Open now" status badge when openNow is true',
        (tester) async {
      final place = _place(openNow: true);
      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      expect(find.text('Open now'), findsOneWidget);
    });

    testWidgets('shows "Closed" status badge when openNow is false',
        (tester) async {
      final place = _place(openNow: false);
      await tester.pumpWidget(buildScope(
        child: PlaceCard(place: place),
      ));
      await tester.pump();

      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('shows fallback image when placePhotoUrlProvider returns null',
        (tester) async {
      final place = _place(
        category: PlaceCategory.urban,
        photos: const [
          PlacePhoto(
            photoReference: 'ref-1',
            width: 100,
            height: 100,
            htmlAttributions: [],
          ),
        ],
      );

      await tester.pumpWidget(buildScope(
        overrides: [
          placePhotoUrlProvider('ref-1').overrideWith((ref) async => null),
        ],
        child: PlaceCard(place: place),
      ));
      // Allow the future provider to resolve
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Falls back to category icon (urban -> Icons.location_city)
      expect(find.byIcon(Icons.location_city), findsOneWidget);
    });
  });
}
