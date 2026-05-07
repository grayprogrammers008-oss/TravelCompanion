import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/statistics/presentation/providers/statistics_providers.dart';

void main() {
  group('quickStatsProvider', () {
    test(
      'returns the default TravelStatistics when no value is available',
      () {
        final container = ProviderContainer(overrides: [
          // Make the upstream stream emit nothing -> stays in loading.
          travelStatisticsProvider.overrideWith(
            (ref) => const Stream<TravelStatistics>.empty(),
          ),
        ]);
        addTearDown(container.dispose);

        final stats = container.read(quickStatsProvider);

        // .value is null, so the provider returns the const default fallback.
        expect(stats.totalTrips, 0);
        expect(stats.primaryCurrency, 'INR');
        expect(stats.hasTrips, false);
        expect(stats.hasExpenses, false);
        expect(stats.hasRatedTrips, false);
        expect(stats.totalDaysTraveled, 0);
        expect(stats.uniqueDestinations, 0);
        expect(stats.uniqueCrewMembers, 0);
      },
    );

    test('returns the latest TravelStatistics when stream has emitted',
        () async {
      const computed = TravelStatistics(
        totalTrips: 3,
        completedTrips: 1,
        totalDaysTraveled: 12,
        uniqueDestinations: 2,
        averageRating: 4.0,
        ratedTrips: 1,
      );

      // Use a long-lived StreamController so the provider stays in a
      // subscribed/data state for the duration of the test.
      final controller = StreamController<TravelStatistics>();
      addTearDown(controller.close);

      final container = ProviderContainer(overrides: [
        travelStatisticsProvider.overrideWith((ref) => controller.stream),
      ]);
      addTearDown(container.dispose);

      // Subscribe so the provider is materialised before we push a value.
      container.listen(travelStatisticsProvider, (_, _) {});

      controller.add(computed);

      // Drain the stream so the provider transitions to a data state.
      final fromStream =
          await container.read(travelStatisticsProvider.future);
      expect(fromStream.totalTrips, 3);

      final stats = container.read(quickStatsProvider);
      expect(stats.totalTrips, 3);
      expect(stats.completedTrips, 1);
      expect(stats.totalDaysTraveled, 12);
      expect(stats.uniqueDestinations, 2);
      expect(stats.hasTrips, true);
      expect(stats.hasRatedTrips, true);
    });

    test('reflects updated value after stream emits multiple times',
        () async {
      final container = ProviderContainer(overrides: [
        travelStatisticsProvider.overrideWith(
          (ref) async* {
            yield const TravelStatistics(totalTrips: 1);
            yield const TravelStatistics(totalTrips: 5);
          },
        ),
      ]);
      addTearDown(container.dispose);

      // Listen so the stream is consumed end-to-end.
      final emitted = <TravelStatistics>[];
      container.listen(
        travelStatisticsProvider,
        (_, next) {
          if (next.hasValue) emitted.add(next.value!);
        },
        fireImmediately: true,
      );

      // Drain through the future once to wait for at least the first emit.
      await container.read(travelStatisticsProvider.future);
      // Pump the event queue so the second value is delivered.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isNotEmpty);
      // Latest value should match what quickStatsProvider returns.
      final latest = emitted.last;
      final fromQuick = container.read(quickStatsProvider);
      expect(fromQuick.totalTrips, latest.totalTrips);
    });
  });

  // NOTE: The travelStatisticsProvider itself uses an internal
  // `Stream.periodic` polling loop and reads two upstream providers
  // (`userTripsProvider` + `userExpensesProvider`). End-to-end testing of
  // its aggregation logic requires the polling loop to observe upstream
  // values, which is brittle under flutter_test (the polling generator
  // never reliably advances in the test event loop and provider tear-down
  // surfaces "disposed during loading state" errors). We therefore test
  // the public surface area exposed via `quickStatsProvider` above and the
  // aggregation behaviour via the page-level widget tests where the
  // override path is much simpler.
}
