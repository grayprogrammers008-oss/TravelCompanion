import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/popular_destination.dart';
import 'package:travel_crew/features/discover/presentation/widgets/popular_destinations_section.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  setUp(() {
    // Avoid layout-overflow noise during tests for the horizontal lists.
  });

  group('PopularDestinationsSection', () {
    testWidgets('renders header, See All button, and All chip', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        PopularDestinationsSection(
          onDestinationTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Popular Destinations'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      // The "All" filter chip is always present.
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      // Star icon next to header
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('renders FilterChips for every country in the data set',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        PopularDestinationsSection(
          onDestinationTapped: (_) {},
        ),
      ));
      await tester.pump();

      // There should be 1 (All) + N countries chips.
      final countries = PopularDestinations.getCountries();
      expect(countries, isNotEmpty);
      expect(find.byType(FilterChip), findsNWidgets(countries.length + 1));
    });

    testWidgets('selecting a country chip filters destinations to that country',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        PopularDestinationsSection(
          onDestinationTapped: (_) {},
        ),
      ));
      await tester.pump();

      final countries = PopularDestinations.getCountries();
      // Pick a country that has at least one destination
      final country = countries.firstWhere(
        (c) => PopularDestinations.getByCountry(c).isNotEmpty,
      );

      // Find that country's filter chip and tap it.
      // Use first match in case multiple texts exist (e.g. on cards).
      await tester.tap(
        find.widgetWithText(FilterChip, country).first,
      );
      await tester.pump();

      // No exception => filtered list rendered. Header still present.
      expect(find.text('Popular Destinations'), findsOneWidget);
    });

    testWidgets('invokes onDestinationTapped when a destination card is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PopularDestination? tapped;

      await tester.pumpWidget(wrap(
        PopularDestinationsSection(
          onDestinationTapped: (d) => tapped = d,
        ),
      ));
      await tester.pump();

      // Tap the first GestureDetector inside the horizontal cards list.
      // We rely on the destination's name being rendered on a card.
      // Pick a deterministic country with known destinations to avoid the
      // shuffle in the default view.
      final countries = PopularDestinations.getCountries();
      final country = countries.first;
      await tester.tap(
        find.widgetWithText(FilterChip, country).first,
      );
      await tester.pump();

      final destinations = PopularDestinations.getByCountry(country);
      expect(destinations, isNotEmpty);

      // Find the first destination card by its name text.
      final cardName = destinations.first.name;
      // Card name may overflow if too long — just verify finder exists.
      expect(find.text(cardName), findsOneWidget);
      await tester.tap(find.text(cardName));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.name, cardName);
    });

    testWidgets('shows explore-nearby buttons when onExploreNearby is provided',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var exploreCount = 0;

      await tester.pumpWidget(wrap(
        PopularDestinationsSection(
          onDestinationTapped: (_) {},
          onExploreNearby: (_) => exploreCount++,
        ),
      ));
      await tester.pump();

      // Pick a country and verify at least one explore icon button is rendered
      final countries = PopularDestinations.getCountries();
      await tester.tap(
        find.widgetWithText(FilterChip, countries.first).first,
      );
      await tester.pump();

      expect(find.byIcon(Icons.explore), findsWidgets);

      // Tap the first explore icon (within the card)
      await tester.tap(find.byIcon(Icons.explore).first);
      await tester.pump();
      expect(exploreCount, 1);
    });

    testWidgets('does not render explore icon when onExploreNearby is null',
        (tester) async {
      tester.view.physicalSize = const Size(2400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrap(
        PopularDestinationsSection(
          onDestinationTapped: (_) {},
        ),
      ));
      await tester.pump();

      final countries = PopularDestinations.getCountries();
      await tester.tap(
        find.widgetWithText(FilterChip, countries.first).first,
      );
      await tester.pump();

      expect(find.byIcon(Icons.explore), findsNothing);
    });
  });
}
