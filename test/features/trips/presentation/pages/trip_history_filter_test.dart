import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/usecases/filter_trips_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_history_usecase.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Unit tests for FilterTripsUseCase and TripHistoryFilterController.
/// No providers, no widgets — pure domain logic.

// ─────────────────────────────────────────────────────────────────────────────
// Builders
// ─────────────────────────────────────────────────────────────────────────────

TripWithMembers _completedTrip({
  required String id,
  required String name,
  String? destination,
  String? description,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? completedAt,
  double rating = 0.0,
  double? cost,
}) {
  final now = DateTime.now();
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      destination: destination,
      description: description,
      startDate: startDate ?? now.subtract(const Duration(days: 60)),
      endDate: endDate ?? now.subtract(const Duration(days: 53)),
      completedAt: completedAt ?? now.subtract(const Duration(days: 53)),
      createdAt: now.subtract(const Duration(days: 90)),
      createdBy: 'user-1',
      isCompleted: true,
      rating: rating,
      cost: cost,
    ),
    members: [
      TripMemberModel(
        id: 'mem-$id',
        tripId: id,
        userId: 'user-1',
        role: 'admin',
        joinedAt: now.subtract(const Duration(days: 90)),
      ),
    ],
  );
}

void main() {
  late FilterTripsUseCase useCase;
  final now = DateTime.now();

  setUp(() {
    useCase = FilterTripsUseCase();
  });

  // Sample completed trips
  late TripWithMembers trip1;
  late TripWithMembers trip2;
  late TripWithMembers trip3;
  late TripWithMembers trip4;
  late List<TripWithMembers> allTrips;

  setUp(() {
    useCase = FilterTripsUseCase();

    trip1 = _completedTrip(
      id: 't1',
      name: 'Goa Beach',
      destination: 'Goa',
      startDate: now.subtract(const Duration(days: 100)),
      endDate: now.subtract(const Duration(days: 93)),
      completedAt: now.subtract(const Duration(days: 93)),
      rating: 4.5,
      cost: 50000,
    );

    trip2 = _completedTrip(
      id: 't2',
      name: 'Manali Trek',
      destination: 'Manali',
      startDate: now.subtract(const Duration(days: 60)),
      endDate: now.subtract(const Duration(days: 53)),
      completedAt: now.subtract(const Duration(days: 53)),
      rating: 5.0,
      cost: 30000,
    );

    trip3 = _completedTrip(
      id: 't3',
      name: 'Kerala Backwaters',
      destination: 'Kerala',
      startDate: now.subtract(const Duration(days: 200)),
      endDate: now.subtract(const Duration(days: 193)),
      completedAt: now.subtract(const Duration(days: 193)),
      rating: 3.0,
      cost: 80000,
    );

    trip4 = _completedTrip(
      id: 't4',
      name: 'Rajasthan Heritage',
      destination: 'Rajasthan',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.subtract(const Duration(days: 23)),
      completedAt: now.subtract(const Duration(days: 23)),
      rating: 0.0, // Unrated
      cost: 45000,
    );

    allTrips = [trip1, trip2, trip3, trip4];
  });

  // ── Default behaviour ─────────────────────────────────────────────────────

  group('Default filter (filterType=all, sortBy=dateNewest)', () {
    test('returns all trips when no filters applied', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(),
      );
      expect(result.length, equals(4));
    });

    test('sorts by dateNewest by default (most recent start date first)', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(),
      );
      // trip4 started 30 days ago, trip2 60 days ago, trip1 100 days ago, trip3 200 days ago
      final ids = result.map((t) => t.trip.id).toList();
      expect(ids, equals(['t4', 't2', 't1', 't3']));
    });
  });

  // ── Sort Tests ─────────────────────────────────────────────────────────────

  group('Sort: nameAsc', () {
    test('sorts alphabetically A→Z', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.nameAsc),
      );
      final names = result.map((t) => t.trip.name).toList();
      for (int i = 0; i < names.length - 1; i++) {
        expect(names[i].compareTo(names[i + 1]), lessThanOrEqualTo(0));
      }
    });
  });

  group('Sort: nameDesc', () {
    test('sorts alphabetically Z→A', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.nameDesc),
      );
      final names = result.map((t) => t.trip.name).toList();
      for (int i = 0; i < names.length - 1; i++) {
        expect(names[i].compareTo(names[i + 1]), greaterThanOrEqualTo(0));
      }
    });
  });

  group('Sort: dateOldest', () {
    test('trips with oldest start date come first', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.dateOldest),
      );
      final dates = result
          .where((t) => t.trip.startDate != null)
          .map((t) => t.trip.startDate!)
          .toList();
      for (int i = 0; i < dates.length - 1; i++) {
        expect(
          dates[i].isBefore(dates[i + 1]) ||
              dates[i].isAtSameMomentAs(dates[i + 1]),
          isTrue,
        );
      }
    });
  });

  group('Sort: ratingHighest', () {
    test('highest rated trips come first', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.ratingHighest),
      );
      final ratings = result.map((t) => t.trip.rating).toList();
      for (int i = 0; i < ratings.length - 1; i++) {
        expect(ratings[i], greaterThanOrEqualTo(ratings[i + 1]));
      }
    });

    test('unrated trips (rating=0) come last', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.ratingHighest),
      );
      expect(result.last.trip.rating, equals(0.0));
      expect(result.last.trip.id, equals('t4'));
    });
  });

  group('Sort: ratingLowest', () {
    test('lowest rated trips come first', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.ratingLowest),
      );
      final ratings = result.map((t) => t.trip.rating).toList();
      for (int i = 0; i < ratings.length - 1; i++) {
        expect(ratings[i], lessThanOrEqualTo(ratings[i + 1]));
      }
    });
  });

  group('Sort: createdNewest / createdOldest', () {
    test('createdNewest puts most recently created first', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.createdNewest),
      );
      final dates = result
          .where((t) => t.trip.createdAt != null)
          .map((t) => t.trip.createdAt!)
          .toList();
      for (int i = 0; i < dates.length - 1; i++) {
        expect(
          dates[i].isAfter(dates[i + 1]) ||
              dates[i].isAtSameMomentAs(dates[i + 1]),
          isTrue,
        );
      }
    });

    test('createdOldest puts oldest created first', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(sortBy: TripSortBy.createdOldest),
      );
      final dates = result
          .where((t) => t.trip.createdAt != null)
          .map((t) => t.trip.createdAt!)
          .toList();
      for (int i = 0; i < dates.length - 1; i++) {
        expect(
          dates[i].isBefore(dates[i + 1]) ||
              dates[i].isAtSameMomentAs(dates[i + 1]),
          isTrue,
        );
      }
    });
  });

  // ── Rating Range Filter ────────────────────────────────────────────────────

  group('Rating Range Filter', () {
    test('minRating filters out trips below threshold', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(minRating: 4.0),
      );
      for (final t in result) {
        expect(t.trip.rating, greaterThanOrEqualTo(4.0));
      }
      expect(result.any((t) => t.trip.id == 't1'), isTrue); // 4.5
      expect(result.any((t) => t.trip.id == 't2'), isTrue); // 5.0
    });

    test('maxRating filters out trips above threshold', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(maxRating: 3.5),
      );
      for (final t in result) {
        expect(t.trip.rating, lessThanOrEqualTo(3.5));
      }
    });

    test('rating range includes only trips within [min, max]', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(minRating: 3.0, maxRating: 4.5),
      );
      for (final t in result) {
        expect(t.trip.rating, greaterThanOrEqualTo(3.0));
        expect(t.trip.rating, lessThanOrEqualTo(4.5));
      }
      expect(result.any((t) => t.trip.id == 't1'), isTrue); // 4.5
      expect(result.any((t) => t.trip.id == 't3'), isTrue); // 3.0
      expect(result.any((t) => t.trip.id == 't2'), isFalse); // 5.0 above max
      expect(result.any((t) => t.trip.id == 't4'), isFalse); // 0.0 below min
    });

    test('exact rating match', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(minRating: 5.0, maxRating: 5.0),
      );
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('t2'));
    });

    test('impossible rating range returns empty', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(minRating: 6.0),
      );
      expect(result, isEmpty);
    });
  });

  // ── Custom Date Range Filter ───────────────────────────────────────────────

  group('Custom Date Range Filter (start date)', () {
    test('customStartDate filters trips starting after date', () {
      final cutoff = now.subtract(const Duration(days: 70));
      final result = useCase(
        trips: allTrips,
        params: TripFilterParams(customStartDate: cutoff),
      );
      for (final t in result) {
        expect(
          t.trip.startDate != null &&
              (t.trip.startDate!.isAfter(cutoff) ||
                  t.trip.startDate!.isAtSameMomentAs(cutoff)),
          isTrue,
        );
      }
      // trip1 started 100 days ago — before cutoff → excluded
      expect(result.any((t) => t.trip.id == 't1'), isFalse);
      // trip2 started 60 days ago — after cutoff → included
      expect(result.any((t) => t.trip.id == 't2'), isTrue);
    });

    test('customEndDate filters trips ending before date', () {
      final cutoff = now.subtract(const Duration(days: 60));
      final result = useCase(
        trips: allTrips,
        params: TripFilterParams(customEndDate: cutoff),
      );
      for (final t in result) {
        expect(
          t.trip.endDate != null &&
              (t.trip.endDate!.isBefore(cutoff) ||
                  t.trip.endDate!.isAtSameMomentAs(cutoff)),
          isTrue,
        );
      }
    });

    test('trips with null start date excluded by customStartDate filter', () {
      final tripNoDate = TripWithMembers(
        trip: TripModel(
          id: 'nodate',
          name: 'No Dates',
          createdBy: 'user',
          isCompleted: true,
        ),
        members: [],
      );
      final cutoff = now.subtract(const Duration(days: 50));
      final result = useCase(
        trips: [tripNoDate],
        params: TripFilterParams(customStartDate: cutoff),
      );
      expect(result, isEmpty);
    });
  });

  // ── Search Filter ─────────────────────────────────────────────────────────

  group('Search Filter', () {
    test('searchQuery by name', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(searchQuery: 'goa'),
      );
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('t1'));
    });

    test('searchQuery by destination', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(searchQuery: 'kerala'),
      );
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('t3'));
    });

    test('empty searchQuery returns all trips', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(searchQuery: ''),
      );
      expect(result.length, equals(allTrips.length));
    });

    test('no match returns empty', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(searchQuery: 'zzznomatch'),
      );
      expect(result, isEmpty);
    });
  });

  // ── Filter Type Tests ─────────────────────────────────────────────────────

  group('FilterType', () {
    test('filterType.all returns all completed trips', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(filterType: TripFilterType.all),
      );
      expect(result.length, equals(allTrips.length));
    });

    test('filterType.withDates returns only trips with both dates', () {
      final tripMissingEndDate = _completedTrip(
        id: 'noend',
        name: 'No End Date',
        endDate: null,
      ).copyWith(
        trip: TripModel(
          id: 'noend',
          name: 'No End Date',
          createdBy: 'u',
          startDate: now.subtract(const Duration(days: 10)),
          endDate: null,
          isCompleted: true,
        ),
      );
      final result = useCase(
        trips: [...allTrips, tripMissingEndDate],
        params: const TripFilterParams(filterType: TripFilterType.withDates),
      );
      for (final t in result) {
        expect(t.trip.startDate, isNotNull);
        expect(t.trip.endDate, isNotNull);
      }
      expect(result.any((t) => t.trip.id == 'noend'), isFalse);
    });

    test('filterType.past excludes future trips', () {
      final futureTrip = TripWithMembers(
        trip: TripModel(
          id: 'future',
          name: 'Future Trip',
          createdBy: 'u',
          startDate: now.add(const Duration(days: 10)),
          endDate: now.add(const Duration(days: 17)),
          isCompleted: false,
        ),
        members: [],
      );
      final result = useCase(
        trips: [...allTrips, futureTrip],
        params: const TripFilterParams(filterType: TripFilterType.past),
      );
      expect(result.any((t) => t.trip.id == 'future'), isFalse);
    });
  });

  // ── Combined Filters ──────────────────────────────────────────────────────

  group('Combined Filters', () {
    test('search + rating range', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(
          searchQuery: 'manali',
          minRating: 4.0,
        ),
      );
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('t2'));
    });

    test('search + rating range + sort', () {
      final result = useCase(
        trips: allTrips,
        params: const TripFilterParams(
          minRating: 3.0,
          sortBy: TripSortBy.ratingHighest,
        ),
      );
      // trip4 (0.0) excluded; remaining sorted by rating desc
      final ratings = result.map((t) => t.trip.rating).toList();
      expect(ratings.first, greaterThanOrEqualTo(ratings.last));
      expect(result.any((t) => t.trip.id == 't4'), isFalse);
    });

    test('empty trips list always returns empty', () {
      final result = useCase(
        trips: [],
        params: const TripFilterParams(
          minRating: 3.0,
          searchQuery: 'goa',
          sortBy: TripSortBy.ratingHighest,
        ),
      );
      expect(result, isEmpty);
    });
  });

  // ── TripHistoryFilterController Tests ─────────────────────────────────────

  group('TripHistoryFilterController', () {
    test('default state has filterType=all and sortBy=dateNewest', () {
      final controller = TripHistoryFilterController();
      final state = controller.build();
      expect(state.filterType, equals(TripFilterType.all));
      expect(state.sortBy, equals(TripSortBy.dateNewest));
      expect(state.searchQuery, isNull);
      expect(state.minRating, isNull);
      expect(state.maxRating, isNull);
    });

    test('updateSortBy changes sortBy', () {
      const defaultState = TripFilterParams(
        filterType: TripFilterType.all,
        sortBy: TripSortBy.dateNewest,
      );
      final updated = defaultState.copyWith(sortBy: TripSortBy.ratingHighest);
      expect(updated.sortBy, equals(TripSortBy.ratingHighest));
      expect(updated.filterType, equals(TripFilterType.all)); // unchanged
    });

    test('updateRatingRange changes rating bounds', () {
      const defaultState = TripFilterParams(
        filterType: TripFilterType.all,
        sortBy: TripSortBy.dateNewest,
      );
      final updated = defaultState.copyWith(minRating: 3.0, maxRating: 5.0);
      expect(updated.minRating, equals(3.0));
      expect(updated.maxRating, equals(5.0));
    });

    test('reset returns to default state', () {
      const defaultState = TripFilterParams(
        filterType: TripFilterType.all,
        sortBy: TripSortBy.dateNewest,
      );
      // Apply some changes
      final modified = defaultState.copyWith(
        minRating: 4.0,
        searchQuery: 'goa',
        sortBy: TripSortBy.ratingHighest,
      );
      // Reset — verify const default matches expected values
      const resetState = TripFilterParams(
        filterType: TripFilterType.all,
        sortBy: TripSortBy.dateNewest,
      );
      expect(resetState.filterType, equals(TripFilterType.all));
      expect(resetState.sortBy, equals(TripSortBy.dateNewest));
      expect(resetState.minRating, isNull);
      expect(resetState.searchQuery, isNull);
      // Verify modified state differs from default
      expect(modified.minRating, equals(4.0));
    });
  });

  // ── TripHistoryStatistics Tests ───────────────────────────────────────────

  group('TripHistoryStatistics', () {
    test('empty() factory returns zeroed statistics', () {
      final stats = TripHistoryStatistics.empty();
      expect(stats.totalCompletedTrips, equals(0));
      expect(stats.averageRating, equals(0.0));
      expect(stats.totalRatedTrips, equals(0));
      expect(stats.earliestCompletionDate, isNull);
      expect(stats.latestCompletionDate, isNull);
      expect(stats.hasAnyTrips, isFalse);
      expect(stats.hasRatedTrips, isFalse);
    });

    test('formattedAverageRating returns one decimal place', () {
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 3,
        averageRating: 4.333,
        totalRatedTrips: 3,
      );
      expect(stats.formattedAverageRating, equals('4.3'));
    });

    test('hasAnyTrips is true when totalCompletedTrips > 0', () {
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 5,
        averageRating: 4.0,
        totalRatedTrips: 3,
      );
      expect(stats.hasAnyTrips, isTrue);
    });

    test('hasRatedTrips is false when totalRatedTrips == 0', () {
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 2,
        averageRating: 0.0,
        totalRatedTrips: 0,
      );
      expect(stats.hasRatedTrips, isFalse);
    });

    test('statistics with completion dates', () {
      final early = now.subtract(const Duration(days: 200));
      final late_ = now.subtract(const Duration(days: 10));
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 3,
        averageRating: 3.5,
        totalRatedTrips: 2,
        earliestCompletionDate: early,
        latestCompletionDate: late_,
      );
      expect(stats.earliestCompletionDate, equals(early));
      expect(stats.latestCompletionDate, equals(late_));
    });

    test('perfect rating format', () {
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 1,
        averageRating: 5.0,
        totalRatedTrips: 1,
      );
      expect(stats.formattedAverageRating, equals('5.0'));
    });
  });

  // ── TripFilterParams.copyWith Tests ──────────────────────────────────────

  group('TripFilterParams.copyWith', () {
    test('copyWith updates only specified fields', () {
      const original = TripFilterParams(
        filterType: TripFilterType.all,
        sortBy: TripSortBy.dateNewest,
        minRating: 3.0,
      );
      final updated = original.copyWith(sortBy: TripSortBy.ratingHighest);
      expect(updated.sortBy, equals(TripSortBy.ratingHighest));
      expect(updated.filterType, equals(TripFilterType.all)); // unchanged
      expect(updated.minRating, equals(3.0)); // unchanged
    });

    test('copyWith can clear nullable fields by passing null', () {
      const original = TripFilterParams(
        minRating: 3.0,
        searchQuery: 'goa',
      );
      final cleared = original.copyWith(minRating: null, searchQuery: null);
      expect(cleared.minRating, isNull);
      expect(cleared.searchQuery, isNull);
    });

    test('const equality for default params', () {
      const a = TripFilterParams();
      const b = TripFilterParams(
        filterType: TripFilterType.all,
        sortBy: TripSortBy.dateNewest,
      );
      expect(a == b, isTrue);
    });
  });
}
