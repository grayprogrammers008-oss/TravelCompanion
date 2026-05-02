import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Unit tests for BrowseTripsPage filter and sort logic.
///
/// Replicates _filterTrips() from _BrowseTripsPageState and tests every
/// filter/sort combination in isolation — no widgets, no providers.

// ─────────────────────────────────────────────────────────────────────────────
// Replication of _filterTrips() logic
// ─────────────────────────────────────────────────────────────────────────────

List<TripWithMembers> _applyFilters(
  List<TripWithMembers> trips, {
  String searchQuery = '',
  String statusFilter = 'all',
  int? minMembers,
  int? maxMembers,
  bool showFavoritesOnly = false,
  String sortBy = 'nearest_date',
}) {
  final query = searchQuery.toLowerCase().trim();
  final now = DateTime.now();

  var filtered = trips.where((t) {
    if (query.isEmpty) return true;
    final trip = t.trip;
    return trip.name.toLowerCase().contains(query) ||
        (trip.destination?.toLowerCase().contains(query) ?? false) ||
        (trip.description?.toLowerCase().contains(query) ?? false);
  }).toList();

  if (statusFilter != 'all') {
    filtered = filtered.where((t) {
      final trip = t.trip;
      final hasStarted =
          trip.startDate != null && trip.startDate!.isBefore(now);
      final hasEnded = trip.endDate != null && trip.endDate!.isBefore(now);
      final isOngoing = hasStarted &&
          (trip.endDate == null || trip.endDate!.isAfter(now));
      switch (statusFilter) {
        case 'upcoming':
          return !hasStarted;
        case 'in_progress':
          return isOngoing;
        case 'ended':
          return hasEnded;
        default:
          return true;
      }
    }).toList();
  }

  if (minMembers != null || maxMembers != null) {
    filtered = filtered.where((t) {
      final count = t.members.length;
      if (minMembers != null && count < minMembers) return false;
      if (maxMembers != null && count > maxMembers) return false;
      return true;
    }).toList();
  }

  if (showFavoritesOnly) {
    filtered = filtered.where((t) => t.isFavorite).toList();
  }

  switch (sortBy) {
    case 'nearest_date':
      filtered.sort((a, b) {
        final aDate = a.trip.startDate;
        final bDate = b.trip.startDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
      break;
    case 'farthest_date':
      filtered.sort((a, b) {
        final aDate = a.trip.startDate;
        final bDate = b.trip.startDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      break;
    case 'most_members':
      filtered
          .sort((a, b) => b.members.length.compareTo(a.members.length));
      break;
    case 'recently_created':
      filtered.sort((a, b) {
        final aC = a.trip.createdAt;
        final bC = b.trip.createdAt;
        if (aC == null && bC == null) return 0;
        if (aC == null) return 1;
        if (bC == null) return -1;
        return bC.compareTo(aC);
      });
      break;
  }

  return filtered;
}

// ─────────────────────────────────────────────────────────────────────────────
// Test-data builders — all dates relative to DateTime.now()
// ─────────────────────────────────────────────────────────────────────────────

TripWithMembers _trip({
  required String id,
  required String name,
  String? destination,
  String? description,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? createdAt,
  int memberCount = 1,
  bool isFavorite = false,
}) {
  final members = List.generate(
    memberCount,
    (i) => TripMemberModel(
      id: 'mem-$id-$i',
      tripId: id,
      userId: 'user-$i',
      role: i == 0 ? 'admin' : 'member',
      joinedAt: DateTime.now(),
    ),
  );
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      destination: destination,
      description: description,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt ?? DateTime.now(),
      createdBy: 'creator',
      isPublic: true,
    ),
    members: members,
    isFavorite: isFavorite,
  );
}

void main() {
  // Relative to "now" so tests remain valid regardless of when they run.
  final now = DateTime.now();

  late TripWithMembers upcoming1;
  late TripWithMembers upcoming2;
  late TripWithMembers inProgress;
  late TripWithMembers ended;
  late TripWithMembers noDate;
  late TripWithMembers favorited;
  late List<TripWithMembers> allTrips;

  setUp(() {
    upcoming1 = _trip(
      id: 'u1',
      name: 'Goa Beach Trip',
      destination: 'Goa, India',
      description: 'Relaxing beach vacation',
      startDate: now.add(const Duration(days: 10)),
      endDate: now.add(const Duration(days: 17)),
      memberCount: 3,
      createdAt: now.subtract(const Duration(days: 45)),
    );

    upcoming2 = _trip(
      id: 'u2',
      name: 'Manali Trek',
      destination: 'Manali, HP',
      description: 'Mountain adventure',
      startDate: now.add(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 37)),
      memberCount: 5,
      createdAt: now.subtract(const Duration(days: 25)),
    );

    inProgress = _trip(
      id: 'ip1',
      name: 'Rajasthan Tour',
      destination: 'Rajasthan',
      description: 'Heritage tour',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 5)),
      memberCount: 4,
      createdAt: now.subtract(const Duration(days: 75)),
    );

    ended = _trip(
      id: 'e1',
      name: 'Kerala Backwaters',
      destination: 'Kerala',
      description: 'Houseboat trip',
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.subtract(const Duration(days: 23)),
      memberCount: 2,
      createdAt: now.subtract(const Duration(days: 107)),
    );

    noDate = _trip(
      id: 'nd1',
      name: 'Open-Ended Adventure',
      destination: 'Unknown',
      memberCount: 1,
      createdAt: now.subtract(const Duration(days: 14)),
    );

    favorited = _trip(
      id: 'fav1',
      name: 'Favorite Beach',
      destination: 'Phuket',
      startDate: now.add(const Duration(days: 15)),
      endDate: now.add(const Duration(days: 22)),
      memberCount: 2,
      isFavorite: true,
      createdAt: now.subtract(const Duration(days: 35)),
    );

    allTrips = [upcoming1, upcoming2, inProgress, ended, noDate, favorited];
  });

  // ── Search Tests ───────────────────────────────────────────────────────────

  group('Search Filter', () {
    test('empty query returns all trips', () {
      final result = _applyFilters(allTrips, searchQuery: '');
      expect(result.length, equals(allTrips.length));
    });

    test('search by trip name (case-insensitive)', () {
      final result = _applyFilters(allTrips, searchQuery: 'goa');
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u1'));
    });

    test('search by destination', () {
      final result = _applyFilters(allTrips, searchQuery: 'kerala');
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('e1'));
    });

    test('search by description', () {
      final result = _applyFilters(allTrips, searchQuery: 'mountain adventure');
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u2'));
    });

    test('partial match works', () {
      // 'beach' matches 'Goa Beach Trip' (name) and 'Favorite Beach' (name)
      final result = _applyFilters(allTrips, searchQuery: 'beach');
      expect(result.length, equals(2));
      expect(result.any((t) => t.trip.id == 'u1'), isTrue);
      expect(result.any((t) => t.trip.id == 'fav1'), isTrue);
    });

    test('no matches returns empty list', () {
      final result = _applyFilters(allTrips, searchQuery: 'zzz_no_match_xyz');
      expect(result, isEmpty);
    });

    test('search is case-insensitive', () {
      final lower = _applyFilters(allTrips, searchQuery: 'beach');
      final upper = _applyFilters(allTrips, searchQuery: 'BEACH');
      final mixed = _applyFilters(allTrips, searchQuery: 'BeAcH');
      final ids = lower.map((t) => t.trip.id).toSet();
      expect(upper.map((t) => t.trip.id).toSet(), equals(ids));
      expect(mixed.map((t) => t.trip.id).toSet(), equals(ids));
    });

    test('null destination handled gracefully', () {
      final t = _trip(id: 'nd', name: 'No Destination Trip');
      final result = _applyFilters([t], searchQuery: 'goa');
      expect(result, isEmpty);
    });

    test('whitespace-only query returns all trips', () {
      final result = _applyFilters(allTrips, searchQuery: '   ');
      expect(result.length, equals(allTrips.length));
    });
  });

  // ── Status Filter Tests ────────────────────────────────────────────────────

  group('Status Filter', () {
    test('"all" returns every trip', () {
      final result = _applyFilters(allTrips, statusFilter: 'all');
      expect(result.length, equals(allTrips.length));
    });

    test('"upcoming" only returns trips that have not started', () {
      final result = _applyFilters(allTrips, statusFilter: 'upcoming');
      for (final t in result) {
        final start = t.trip.startDate;
        if (start != null) {
          expect(start.isAfter(DateTime.now()), isTrue);
        }
      }
      expect(result.any((t) => t.trip.id == 'u1'), isTrue);
      expect(result.any((t) => t.trip.id == 'u2'), isTrue);
      expect(result.any((t) => t.trip.id == 'fav1'), isTrue);
    });

    test('"upcoming" includes trips with null startDate (not-yet-started)', () {
      // Per page logic: hasStarted = startDate != null && startDate.isBefore(now)
      // If startDate is null → hasStarted = false → !hasStarted = true → included
      final result = _applyFilters(allTrips, statusFilter: 'upcoming');
      expect(result.any((t) => t.trip.id == 'nd1'), isTrue);
    });

    test('"upcoming" excludes ended and in-progress trips', () {
      final result = _applyFilters(allTrips, statusFilter: 'upcoming');
      expect(result.any((t) => t.trip.id == 'ip1'), isFalse);
      expect(result.any((t) => t.trip.id == 'e1'), isFalse);
    });

    test('"in_progress" returns only ongoing trips', () {
      final result = _applyFilters(allTrips, statusFilter: 'in_progress');
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('ip1'));
    });

    test('"ended" returns only trips that have finished', () {
      final result = _applyFilters(allTrips, statusFilter: 'ended');
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('e1'));
    });

    test('"ended" excludes upcoming and in-progress trips', () {
      final result = _applyFilters(allTrips, statusFilter: 'ended');
      expect(result.any((t) => t.trip.id == 'u1'), isFalse);
      expect(result.any((t) => t.trip.id == 'ip1'), isFalse);
    });

    test('status filter on empty list returns empty', () {
      final result = _applyFilters([], statusFilter: 'upcoming');
      expect(result, isEmpty);
    });
  });

  // ── Member Count Filter Tests ──────────────────────────────────────────────

  group('Member Count Filter', () {
    test('no member filter returns all trips', () {
      final result = _applyFilters(allTrips);
      expect(result.length, equals(allTrips.length));
    });

    test('minMembers filters out trips with fewer members', () {
      final result = _applyFilters(allTrips, minMembers: 3);
      for (final t in result) {
        expect(t.members.length, greaterThanOrEqualTo(3));
      }
    });

    test('maxMembers filters out trips with more members', () {
      final result = _applyFilters(allTrips, maxMembers: 3);
      for (final t in result) {
        expect(t.members.length, lessThanOrEqualTo(3));
      }
    });

    test('member count range', () {
      final result = _applyFilters(allTrips, minMembers: 2, maxMembers: 4);
      for (final t in result) {
        expect(t.members.length, greaterThanOrEqualTo(2));
        expect(t.members.length, lessThanOrEqualTo(4));
      }
    });

    test('exact member count (min == max)', () {
      final result = _applyFilters(allTrips, minMembers: 5, maxMembers: 5);
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u2'));
    });

    test('impossible range returns empty', () {
      final result =
          _applyFilters(allTrips, minMembers: 100, maxMembers: 200);
      expect(result, isEmpty);
    });
  });

  // ── Favorites Filter Tests ─────────────────────────────────────────────────

  group('Favorites Filter', () {
    test('showFavoritesOnly=false returns all trips', () {
      final result = _applyFilters(allTrips, showFavoritesOnly: false);
      expect(result.length, equals(allTrips.length));
    });

    test('showFavoritesOnly=true returns only favorited trips', () {
      final result = _applyFilters(allTrips, showFavoritesOnly: true);
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('fav1'));
      expect(result[0].isFavorite, isTrue);
    });

    test('showFavoritesOnly returns empty when none favorited', () {
      final noFavs =
          allTrips.map((t) => t.copyWith(isFavorite: false)).toList();
      final result = _applyFilters(noFavs, showFavoritesOnly: true);
      expect(result, isEmpty);
    });

    test('showFavoritesOnly with multiple favorited trips', () {
      final extra = _trip(id: 'fav2', name: 'Another Fav', isFavorite: true);
      final result = _applyFilters(
        [...allTrips, extra],
        showFavoritesOnly: true,
      );
      expect(result.length, equals(2));
      expect(result.every((t) => t.isFavorite), isTrue);
    });
  });

  // ── Sort Tests ─────────────────────────────────────────────────────────────

  group('Sort: nearest_date (ascending)', () {
    test('trips are sorted by start date ascending', () {
      final result = _applyFilters(
        [upcoming2, upcoming1, inProgress],
        sortBy: 'nearest_date',
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

    test('trips without start date go to end', () {
      final result =
          _applyFilters([upcoming1, noDate, upcoming2], sortBy: 'nearest_date');
      expect(result.last.trip.id, equals('nd1'));
    });
  });

  group('Sort: farthest_date (descending)', () {
    test('trips are sorted by start date descending', () {
      final result = _applyFilters(
        [upcoming1, upcoming2, inProgress],
        sortBy: 'farthest_date',
      );
      final dates = result
          .where((t) => t.trip.startDate != null)
          .map((t) => t.trip.startDate!)
          .toList();
      for (int i = 0; i < dates.length - 1; i++) {
        expect(
          dates[i].isAfter(dates[i + 1]) ||
              dates[i].isAtSameMomentAs(dates[i + 1]),
          isTrue,
        );
      }
    });

    test('trips without start date go to end', () {
      final result = _applyFilters(
        [upcoming1, noDate, upcoming2],
        sortBy: 'farthest_date',
      );
      expect(result.last.trip.id, equals('nd1'));
    });
  });

  group('Sort: most_members', () {
    test('sorted by member count descending', () {
      final result = _applyFilters(
        [upcoming1, upcoming2, ended],
        sortBy: 'most_members',
      );
      final counts = result.map((t) => t.members.length).toList();
      for (int i = 0; i < counts.length - 1; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i + 1]));
      }
    });

    test('highest member count is first', () {
      final result = _applyFilters(allTrips, sortBy: 'most_members');
      expect(
        result.first.members.length,
        greaterThanOrEqualTo(result.last.members.length),
      );
    });
  });

  group('Sort: recently_created', () {
    test('most recently created trip is first', () {
      final result = _applyFilters(
        [upcoming1, upcoming2, ended],
        sortBy: 'recently_created',
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

    test('trips without createdAt go to end', () {
      final noCreated = TripWithMembers(
        trip: TripModel(
            id: 'nc', name: 'No Created', createdBy: 'u', createdAt: null),
        members: [],
      );
      final result = _applyFilters(
        [upcoming1, noCreated],
        sortBy: 'recently_created',
      );
      expect(result.last.trip.id, equals('nc'));
    });
  });

  // ── Combined Filter Tests ──────────────────────────────────────────────────

  group('Combined Filters', () {
    test('search + upcoming status', () {
      final result = _applyFilters(
        allTrips,
        searchQuery: 'manali',
        statusFilter: 'upcoming',
      );
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u2'));
    });

    test('upcoming status + min members', () {
      final result = _applyFilters(
        allTrips,
        statusFilter: 'upcoming',
        minMembers: 4,
      );
      // upcoming: u1(3), u2(5), fav1(2), nd1(1) — only u2 has ≥4
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u2'));
    });

    test('search + favorites only', () {
      final result = _applyFilters(
        allTrips,
        searchQuery: 'beach',
        showFavoritesOnly: true,
      );
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('fav1'));
    });

    test('search that matches upcoming + status=ended returns empty', () {
      // 'Goa Beach Trip' is upcoming, not ended
      final result = _applyFilters(
        allTrips,
        searchQuery: 'goa',
        statusFilter: 'ended',
      );
      expect(result, isEmpty);
    });

    test('search + status + members + sort', () {
      final result = _applyFilters(
        allTrips,
        searchQuery: 'trek',
        statusFilter: 'upcoming',
        minMembers: 3,
        sortBy: 'most_members',
      );
      // 'Manali Trek' is upcoming and has 5 members
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u2'));
    });

    test('very strict filters produce no results', () {
      final result = _applyFilters(
        allTrips,
        searchQuery: 'goa',
        statusFilter: 'ended',
        minMembers: 10,
      );
      expect(result, isEmpty);
    });
  });

  // ── Edge Cases ─────────────────────────────────────────────────────────────

  group('Edge Cases', () {
    test('empty input returns empty output', () {
      expect(_applyFilters([]), isEmpty);
    });

    test('single trip passes default filters', () {
      final result = _applyFilters([upcoming1]);
      expect(result.length, equals(1));
    });

    test('trip with all null dates passes status=all', () {
      final result = _applyFilters([noDate], statusFilter: 'all');
      expect(result.length, equals(1));
    });

    test('sorting empty list returns empty', () {
      expect(_applyFilters([], sortBy: 'most_members'), isEmpty);
    });

    test('sorting single-item list returns same item', () {
      final result = _applyFilters([upcoming1], sortBy: 'nearest_date');
      expect(result.length, equals(1));
      expect(result[0].trip.id, equals('u1'));
    });

    test('ties in nearest_date sort do not crash', () {
      final sameDate = now.add(const Duration(days: 5));
      final t1 = _trip(id: 'x1', name: 'X1', startDate: sameDate);
      final t2 = _trip(id: 'x2', name: 'X2', startDate: sameDate);
      final result = _applyFilters([t1, t2], sortBy: 'nearest_date');
      expect(result.length, equals(2));
    });

    test('search with special characters does not crash', () {
      final result =
          _applyFilters(allTrips, searchQuery: 'São Paulo & Tokyo!');
      expect(result, isEmpty);
    });
  });
}
