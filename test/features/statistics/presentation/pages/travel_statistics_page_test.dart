import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/statistics/presentation/pages/travel_statistics_page.dart';
import 'package:pathio/features/statistics/presentation/providers/statistics_providers.dart';

Widget _wrap(Widget child, {required List<Object> overrides}) {
  return ProviderScope(
    // ignore: invalid_use_of_internal_member
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: ThemeData.light(),
      home: child,
    ),
  );
}

void main() {
  group('TravelStatisticsPage', () {
    // The loading branch renders an animated AppLoadingIndicator that uses
    // multiple long-running tickers. flutter_test refuses to let the test
    // end with pending tickers, so we exercise the loading-state code path
    // here only enough to confirm the AppBar title still mounts; we then
    // immediately pump a data value through the same stream to let the
    // tickers dispose cleanly.
    testWidgets('mounts cleanly while in loading state then transitions',
        (tester) async {
      final controller = StreamController<TravelStatistics>();
      addTearDown(controller.close);

      await tester.pumpWidget(_wrap(
        const TravelStatisticsPage(),
        overrides: [
          travelStatisticsProvider.overrideWith((ref) => controller.stream),
        ],
      ));
      await tester.pump();

      // App-bar title should always be present.
      expect(find.text('Travel Statistics'), findsOneWidget);

      // None of the data sections render while loading.
      expect(find.text('Trip Overview'), findsNothing);
      expect(find.text('Failed to load statistics'), findsNothing);

      // Emit a value so the loading indicator unmounts and its animation
      // tickers are disposed before the test ends.
      controller.add(const TravelStatistics());
      await tester.pumpAndSettle();
      expect(find.text('Trip Overview'), findsOneWidget);
    });

    testWidgets('renders error state when stream errors', (tester) async {
      await tester.pumpWidget(_wrap(
        const TravelStatisticsPage(),
        overrides: [
          travelStatisticsProvider.overrideWith(
            (ref) async* {
              throw Exception('boom');
            },
          ),
        ],
      ));
      // Allow the stream to throw and the UI to rebuild.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.text('Failed to load statistics'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders zero-state for empty trip stats', (tester) async {
      const stats = TravelStatistics();

      await tester.pumpWidget(_wrap(
        const TravelStatisticsPage(),
        overrides: [
          travelStatisticsProvider.overrideWith(
            (ref) => Stream<TravelStatistics>.value(stats),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Section headers always present
      expect(find.text('Trip Overview'), findsOneWidget);
      expect(find.text('Expense Summary'), findsOneWidget);
      expect(find.text('Travel Achievements'), findsOneWidget);
      expect(find.text('Trip Status'), findsOneWidget);

      // Empty trips message inside the status breakdown
      expect(find.text('No trips yet'), findsOneWidget);
      expect(
        find.text('Start planning your first adventure!'),
        findsOneWidget,
      );

      // Trip Ratings section is only shown when stats.hasRatedTrips
      expect(find.text('Trip Ratings'), findsNothing);
    });

    testWidgets(
        'renders ratings section and stat values when stats have data',
        (tester) async {
      const stats = TravelStatistics(
        totalTrips: 5,
        activeTrips: 1,
        upcomingTrips: 1,
        completedTrips: 3,
        totalDaysTraveled: 25,
        uniqueDestinations: 4,
        uniqueCrewMembers: 7,
        totalExpenses: 12500.0,
        expenseCount: 12,
        tripsWithExpenses: 3,
        averageExpensePerTrip: 4166.67,
        primaryCurrency: 'INR',
        averageRating: 4.5,
        ratedTrips: 4,
      );

      await tester.pumpWidget(_wrap(
        const TravelStatisticsPage(),
        overrides: [
          travelStatisticsProvider.overrideWith(
            (ref) => Stream<TravelStatistics>.value(stats),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Ratings section is now visible
      expect(find.text('Trip Ratings'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('4 trips rated'), findsOneWidget);

      // Trip overview values
      expect(find.text('5'), findsOneWidget); // total trips
      expect(find.text('25'), findsOneWidget); // days traveled

      // Expense summary
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('12 expenses recorded'), findsOneWidget);
    });

    testWidgets('formats large amounts with K/L suffixes', (tester) async {
      // > 1000 -> "K", > 100000 -> "L"
      const stats = TravelStatistics(
        totalTrips: 1,
        totalExpenses: 250000.0, // -> 2.5L
        averageExpensePerTrip: 5500.0, // -> 5.5K
        expenseCount: 1,
        tripsWithExpenses: 1,
        primaryCurrency: 'INR',
      );

      await tester.pumpWidget(_wrap(
        const TravelStatisticsPage(),
        overrides: [
          travelStatisticsProvider.overrideWith(
            (ref) => Stream<TravelStatistics>.value(stats),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Currency-prefixed amount strings
      expect(find.textContaining('2.5L'), findsOneWidget);
      expect(find.textContaining('5.5K'), findsOneWidget);
    });

    testWidgets('uses USD currency symbol when primaryCurrency != INR',
        (tester) async {
      const stats = TravelStatistics(
        totalTrips: 1,
        totalExpenses: 500.0,
        primaryCurrency: 'USD',
      );

      await tester.pumpWidget(_wrap(
        const TravelStatisticsPage(),
        overrides: [
          travelStatisticsProvider.overrideWith(
            (ref) => Stream<TravelStatistics>.value(stats),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Currency prefix becomes "$" rather than "₹"
      expect(find.textContaining('\$500'), findsOneWidget);
    });
  });
}
