import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/home/presentation/providers/dashboard_providers.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Helper that builds a `TripWithMembers` with sane defaults so tests can
/// focus only on the fields they care about.
TripWithMembers _trip({
  required String id,
  String name = 'Trip',
  DateTime? startDate,
  DateTime? endDate,
  bool isCompleted = false,
  DateTime? createdAt,
}) {
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      destination: 'Somewhere',
      startDate: startDate,
      endDate: endDate,
      createdBy: 'user1',
      createdAt: createdAt,
      isCompleted: isCompleted,
    ),
    members: const [],
  );
}

ProviderContainer _container(List<TripWithMembers> trips) {
  final container = ProviderContainer(
    overrides: [
      userTripsProvider.overrideWith((ref) => Future.value(trips)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('DashboardStats', () {
    test('constructs with provided fields', () {
      final stats = DashboardStats(
        totalTrips: 5,
        activeTrips: 1,
        upcomingTrips: 2,
        completedTrips: 2,
        totalExpenses: 1500.0,
      );

      expect(stats.totalTrips, 5);
      expect(stats.activeTrips, 1);
      expect(stats.upcomingTrips, 2);
      expect(stats.completedTrips, 2);
      expect(stats.totalExpenses, 1500.0);
    });
  });

  group('activeTripProvider', () {
    test('returns null when there are no trips', () async {
      final container = _container(const []);
      final result = await container.read(activeTripProvider.future);
      expect(result, isNull);
    });

    test('prefers an in-progress trip over upcoming and completed trips',
        () async {
      final now = DateTime.now();
      final inProgress = _trip(
        id: 'in-progress',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 2)),
      );
      final upcoming = _trip(
        id: 'upcoming',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
      );
      final completed = _trip(
        id: 'completed',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 20)),
        isCompleted: true,
      );

      final container = _container([completed, upcoming, inProgress]);
      final result = await container.read(activeTripProvider.future);

      expect(result, isNotNull);
      expect(result!.trip.id, 'in-progress');
    });

    test('returns the closest upcoming trip when none are in progress',
        () async {
      final now = DateTime.now();
      final farUpcoming = _trip(
        id: 'far',
        startDate: now.add(const Duration(days: 30)),
      );
      final closeUpcoming = _trip(
        id: 'close',
        startDate: now.add(const Duration(days: 3)),
      );
      final mid = _trip(
        id: 'mid',
        startDate: now.add(const Duration(days: 10)),
      );

      final container = _container([farUpcoming, mid, closeUpcoming]);
      final result = await container.read(activeTripProvider.future);

      expect(result, isNotNull);
      expect(result!.trip.id, 'close');
    });

    test('ignores completed trips when picking in-progress', () async {
      final now = DateTime.now();
      final completedNow = _trip(
        id: 'completed-now',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        isCompleted: true,
      );
      final upcoming = _trip(
        id: 'upcoming',
        startDate: now.add(const Duration(days: 5)),
      );

      final container = _container([completedNow, upcoming]);
      final result = await container.read(activeTripProvider.future);

      expect(result, isNotNull);
      expect(result!.trip.id, 'upcoming');
    });

    test(
        'falls back to most recently created non-completed trip when no '
        'in-progress or upcoming trips exist', () async {
      final pastA = _trip(
        id: 'a',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 10),
        createdAt: DateTime(2024, 1, 1),
      );
      final pastB = _trip(
        id: 'b',
        startDate: DateTime(2020, 5, 1),
        endDate: DateTime(2020, 5, 10),
        createdAt: DateTime(2024, 6, 1), // most recent
      );
      final pastC = _trip(
        id: 'c',
        startDate: DateTime(2020, 8, 1),
        endDate: DateTime(2020, 8, 10),
        createdAt: DateTime(2024, 3, 1),
      );

      final container = _container([pastA, pastB, pastC]);
      final result = await container.read(activeTripProvider.future);

      expect(result, isNotNull);
      expect(result!.trip.id, 'b');
    });

    test('returns null when all trips are completed', () async {
      final completed1 = _trip(id: '1', isCompleted: true);
      final completed2 = _trip(id: '2', isCompleted: true);

      final container = _container([completed1, completed2]);
      final result = await container.read(activeTripProvider.future);

      expect(result, isNull);
    });

    test('skips trips that have no start date when scanning in-progress',
        () async {
      final now = DateTime.now();
      final noDates = _trip(
        id: 'no-dates',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      final upcoming = _trip(
        id: 'upcoming',
        startDate: now.add(const Duration(days: 5)),
      );

      final container = _container([noDates, upcoming]);
      final result = await container.read(activeTripProvider.future);

      // Since `noDates` cannot be in-progress (no startDate), but `upcoming`
      // also has a future startDate, the upcoming-trip branch should win.
      expect(result, isNotNull);
      expect(result!.trip.id, 'upcoming');
    });
  });

  group('dashboardStatsProvider', () {
    test('returns zero counts for empty list', () async {
      final container = _container(const []);
      final stats = await container.read(dashboardStatsProvider.future);

      expect(stats.totalTrips, 0);
      expect(stats.activeTrips, 0);
      expect(stats.upcomingTrips, 0);
      expect(stats.completedTrips, 0);
      expect(stats.totalExpenses, 0);
    });

    test('classifies trips into active / upcoming / completed buckets',
        () async {
      final now = DateTime.now();
      final active = _trip(
        id: 'active',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
      );
      final upcoming = _trip(
        id: 'upcoming',
        startDate: now.add(const Duration(days: 30)),
      );
      final completed = _trip(
        id: 'completed',
        startDate: now.subtract(const Duration(days: 60)),
        endDate: now.subtract(const Duration(days: 50)),
        isCompleted: true,
      );

      final container = _container([active, upcoming, completed]);
      final stats = await container.read(dashboardStatsProvider.future);

      expect(stats.totalTrips, 3);
      expect(stats.activeTrips, 1);
      expect(stats.upcomingTrips, 1);
      expect(stats.completedTrips, 1);
    });

    test('counts trips without a start date as active', () async {
      final undated = _trip(id: 'undated');

      final container = _container([undated]);
      final stats = await container.read(dashboardStatsProvider.future);

      expect(stats.totalTrips, 1);
      expect(stats.activeTrips, 1);
      expect(stats.upcomingTrips, 0);
      expect(stats.completedTrips, 0);
    });

    test('completed trips are not counted in active or upcoming', () async {
      final now = DateTime.now();
      final completedFuture = _trip(
        id: 'completed-future',
        startDate: now.add(const Duration(days: 5)),
        isCompleted: true,
      );

      final container = _container([completedFuture]);
      final stats = await container.read(dashboardStatsProvider.future);

      expect(stats.totalTrips, 1);
      expect(stats.completedTrips, 1);
      expect(stats.upcomingTrips, 0);
      expect(stats.activeTrips, 0);
    });

    test('totalExpenses is always 0 (not yet aggregated)', () async {
      final now = DateTime.now();
      final t = _trip(
        id: 't',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      final container = _container([t]);
      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats.totalExpenses, 0);
    });
  });
}
