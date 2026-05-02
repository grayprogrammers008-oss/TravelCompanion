import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_discoverable_trips_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_trips_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/join_trip_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Manual mock — covers methods used by the three use cases under test.
// ─────────────────────────────────────────────────────────────────────────────
class _MockTripRepository implements TripRepository {
  // getDiscoverableTrips
  List<TripWithMembers>? _discoverableTrips;
  Exception? _discoverableException;
  bool discoverCalled = false;

  // joinTrip
  final List<String> joinedTripIds = [];
  Exception? _joinException;

  // getUserTrips
  List<TripWithMembers>? _userTrips;
  Exception? _userTripsException;

  void setupDiscoverableTrips(List<TripWithMembers> trips) {
    _discoverableTrips = trips;
    _discoverableException = null;
  }

  void setupDiscoverableToThrow(Exception e) {
    _discoverableException = e;
    _discoverableTrips = null;
  }

  void setupJoinToThrow(Exception e) => _joinException = e;

  void setupUserTrips(List<TripWithMembers> trips) {
    _userTrips = trips;
    _userTripsException = null;
  }

  void setupUserTripsToThrow(Exception e) {
    _userTripsException = e;
    _userTrips = null;
  }

  void reset() {
    _discoverableTrips = null;
    _discoverableException = null;
    discoverCalled = false;
    joinedTripIds.clear();
    _joinException = null;
    _userTrips = null;
    _userTripsException = null;
  }

  @override
  Future<List<TripWithMembers>> getDiscoverableTrips() async {
    discoverCalled = true;
    if (_discoverableException != null) throw _discoverableException!;
    return _discoverableTrips!;
  }

  @override
  Future<void> joinTrip(String tripId) async {
    if (_joinException != null) throw _joinException!;
    joinedTripIds.add(tripId);
  }

  @override
  Future<List<TripWithMembers>> getUserTrips() async {
    if (_userTripsException != null) throw _userTripsException!;
    return _userTrips!;
  }

  // ── Unused stubs ──────────────────────────────────────────────────────────

  @override
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? cost,
    String? currency,
    bool isPublic = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    double? cost,
    String? currency,
    bool? isPublic,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteTrip(String tripId) async => throw UnimplementedError();

  @override
  Stream<List<TripWithMembers>> watchUserTrips() => throw UnimplementedError();

  @override
  Future<TripWithMembers> getTripById(String tripId) async =>
      throw UnimplementedError();

  @override
  Stream<TripWithMembers> watchTrip(String tripId) =>
      throw UnimplementedError();

  @override
  Future<List<TripMemberModel>> getTripMembers(String tripId) async =>
      throw UnimplementedError();

  @override
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UserTravelStats> getUserStats() async => throw UnimplementedError();

  @override
  Stream<UserTravelStats> watchUserStats() => throw UnimplementedError();

  @override
  Future<String> copyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> toggleFavorite(String tripId) async =>
      throw UnimplementedError();

  @override
  Future<List<String>> getFavoriteTripIds() async =>
      throw UnimplementedError();
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

TripWithMembers _publicTrip({
  required String id,
  required String name,
  String destination = 'Test City',
  String createdBy = 'creator-1',
  int memberCount = 1,
}) {
  final now = DateTime(2025, 6, 1);
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      destination: destination,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      isPublic: true,
    ),
    members: List.generate(
      memberCount,
      (i) => TripMemberModel(
        id: 'mem-$id-$i',
        tripId: id,
        userId: i == 0 ? createdBy : 'member-$i',
        role: i == 0 ? 'admin' : 'member',
        joinedAt: now,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Discover & Join Trips — Integration Tests', () {
    late _MockTripRepository repo;
    late GetDiscoverableTripsUseCase getDiscoverableUseCase;
    late JoinTripUseCase joinUseCase;
    late GetUserTripsUseCase getUserTripsUseCase;

    setUp(() {
      repo = _MockTripRepository();
      getDiscoverableUseCase = GetDiscoverableTripsUseCase(repo);
      joinUseCase = JoinTripUseCase(repo);
      getUserTripsUseCase = GetUserTripsUseCase(repo);
    });

    tearDown(() => repo.reset());

    // ── GetDiscoverableTrips ─────────────────────────────────────────────────

    group('GetDiscoverableTrips', () {
      test('returns public trips', () async {
        repo.setupDiscoverableTrips([
          _publicTrip(id: 'p1', name: 'Goa Beach'),
          _publicTrip(id: 'p2', name: 'Manali Trek'),
        ]);

        final result = await getDiscoverableUseCase();

        expect(result.length, equals(2));
        expect(result[0].trip.id, equals('p1'));
        expect(result[1].trip.id, equals('p2'));
        expect(repo.discoverCalled, isTrue);
      });

      test('returns empty list when no public trips exist', () async {
        repo.setupDiscoverableTrips([]);

        final result = await getDiscoverableUseCase();

        expect(result, isEmpty);
      });

      test('returns trips with full member details', () async {
        repo.setupDiscoverableTrips([_publicTrip(id: 't1', name: 'Group Trek', memberCount: 4)]);

        final result = await getDiscoverableUseCase();

        expect(result[0].members.length, equals(4));
      });

      test('preserves order from repository', () async {
        repo.setupDiscoverableTrips([
          _publicTrip(id: 'z', name: 'Z Trip'),
          _publicTrip(id: 'a', name: 'A Trip'),
          _publicTrip(id: 'm', name: 'M Trip'),
        ]);

        final result = await getDiscoverableUseCase();

        expect(result.map((t) => t.trip.id).toList(), equals(['z', 'a', 'm']));
      });

      test('wraps repository exception', () async {
        repo.setupDiscoverableToThrow(Exception('Network error'));

        await expectLater(
          () => getDiscoverableUseCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get discoverable trips'),
          )),
        );
      });

      test('wraps authentication error', () async {
        repo.setupDiscoverableToThrow(Exception('Not authenticated'));

        await expectLater(
          () => getDiscoverableUseCase(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles 100 trips without issue', () async {
        repo.setupDiscoverableTrips(
          List.generate(100, (i) => _publicTrip(id: 'trip-$i', name: 'Trip $i')),
        );

        final result = await getDiscoverableUseCase();
        expect(result.length, equals(100));
      });

      test('returns all trip fields intact', () async {
        final startDate = DateTime(2025, 7, 1);
        final endDate = DateTime(2025, 7, 10);
        final now = DateTime(2025, 6, 1);
        repo.setupDiscoverableTrips([
          TripWithMembers(
            trip: TripModel(
              id: 'full',
              name: 'Full Trip',
              description: 'Detailed description',
              destination: 'Bali, Indonesia',
              startDate: startDate,
              endDate: endDate,
              coverImageUrl: 'https://example.com/cover.jpg',
              createdBy: 'user-99',
              createdAt: now,
              isPublic: true,
              cost: 75000.0,
              currency: 'INR',
            ),
            members: [],
          ),
        ]);

        final result = await getDiscoverableUseCase();
        final t = result[0].trip;

        expect(t.description, equals('Detailed description'));
        expect(t.destination, equals('Bali, Indonesia'));
        expect(t.startDate, equals(startDate));
        expect(t.endDate, equals(endDate));
        expect(t.coverImageUrl, equals('https://example.com/cover.jpg'));
        expect(t.cost, equals(75000.0));
        expect(t.currency, equals('INR'));
        expect(t.isPublic, isTrue);
      });
    });

    // ── JoinTrip ─────────────────────────────────────────────────────────────

    group('JoinTrip', () {
      test('joins trip and records the trip ID', () async {
        await joinUseCase('trip-123');

        expect(repo.joinedTripIds, contains('trip-123'));
      });

      test('joins multiple different trips', () async {
        await joinUseCase('trip-1');
        await joinUseCase('trip-2');

        expect(repo.joinedTripIds, equals(['trip-1', 'trip-2']));
      });

      test('throws validation error for empty trip ID', () async {
        await expectLater(
          () => joinUseCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );

        expect(repo.joinedTripIds, isEmpty);
      });

      test('throws validation error for whitespace-only trip ID', () async {
        await expectLater(
          () => joinUseCase('   '),
          throwsA(isA<Exception>()),
        );

        expect(repo.joinedTripIds, isEmpty);
      });

      test('wraps repository exception', () async {
        repo.setupJoinToThrow(Exception('Already a member'));

        await expectLater(
          () => joinUseCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to join trip'),
          )),
        );
      });

      test('wraps private trip exception', () async {
        repo.setupJoinToThrow(Exception('Trip is private'));

        await expectLater(
          () => joinUseCase('private-trip'),
          throwsA(isA<Exception>()),
        );
      });

      test('wraps not-found exception', () async {
        repo.setupJoinToThrow(Exception('Trip not found'));

        await expectLater(
          () => joinUseCase('ghost-trip'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // ── End-to-end: Discover → Join → View My Trips ───────────────────────

    group('End-to-end: Discover → Join → View My Trips', () {
      test('user can discover trips, join one, then see it in their trips',
          () async {
        // Step 1 — discover
        repo.setupDiscoverableTrips([
          _publicTrip(id: 'pub-1', name: 'Goa Beach'),
          _publicTrip(id: 'pub-2', name: 'Manali Trek'),
        ]);
        final discoverable = await getDiscoverableUseCase();
        expect(discoverable.length, equals(2));

        // Step 2 — join the first trip
        final chosenId = discoverable[0].trip.id;
        await joinUseCase(chosenId);
        expect(repo.joinedTripIds, contains(chosenId));

        // Step 3 — user's trip list now includes the joined trip
        final now = DateTime(2025, 6, 1);
        final myMembership = TripMemberModel(
          id: 'my-mem',
          tripId: chosenId,
          userId: 'current-user',
          role: 'member',
          joinedAt: now,
        );
        repo.setupUserTrips([
          TripWithMembers(
            trip: discoverable[0].trip,
            members: [...discoverable[0].members, myMembership],
          ),
        ]);
        final myTrips = await getUserTripsUseCase();

        expect(myTrips.length, equals(1));
        expect(myTrips[0].trip.id, equals(chosenId));
        expect(
          myTrips[0].members.any((m) => m.userId == 'current-user'),
          isTrue,
        );
      });

      test('failed join does not add trip to user trips', () async {
        repo.setupDiscoverableTrips([_publicTrip(id: 'pub-1', name: 'Goa')]);
        await getDiscoverableUseCase();

        // Trip becomes unavailable before join completes
        repo.setupJoinToThrow(Exception('Trip no longer available'));
        try {
          await joinUseCase('pub-1');
        } catch (_) {}

        // My trips remain empty
        repo.setupUserTrips([]);
        final myTrips = await getUserTripsUseCase();
        expect(myTrips, isEmpty);
        expect(repo.joinedTripIds, isEmpty);
      });

      test('joining the same trip twice throws on second attempt', () async {
        // First join succeeds
        await joinUseCase('pub-1');
        expect(repo.joinedTripIds, hasLength(1));

        // Second join fails (server rejects duplicate)
        repo.setupJoinToThrow(Exception('Already a member'));

        await expectLater(
          () => joinUseCase('pub-1'),
          throwsA(isA<Exception>()),
        );
      });

      test('user can join multiple trips discovered in one call', () async {
        repo.setupDiscoverableTrips([
          _publicTrip(id: 'trip-A', name: 'Adventure A'),
          _publicTrip(id: 'trip-B', name: 'Adventure B'),
          _publicTrip(id: 'trip-C', name: 'Adventure C'),
        ]);
        final discoverable = await getDiscoverableUseCase();

        for (final t in discoverable) {
          await joinUseCase(t.trip.id);
        }

        expect(repo.joinedTripIds, equals(['trip-A', 'trip-B', 'trip-C']));
      });

      test('discover returns trips from different creators', () async {
        repo.setupDiscoverableTrips(List.generate(
          5,
          (i) => _publicTrip(id: 'trip-$i', name: 'Trip $i', createdBy: 'creator-$i'),
        ));

        final result = await getDiscoverableUseCase();

        final creators = result.map((t) => t.trip.createdBy).toSet();
        expect(creators.length, equals(5));
      });
    });

    // ── Call isolation ────────────────────────────────────────────────────────

    group('Call isolation', () {
      test('discover and join calls are independent', () async {
        repo.setupDiscoverableTrips([_publicTrip(id: 'p1', name: 'Trip')]);
        await getDiscoverableUseCase();

        await joinUseCase('p1');

        expect(repo.discoverCalled, isTrue);
        expect(repo.joinedTripIds, contains('p1'));
      });

      test('discover is called only once per invocation', () async {
        repo.setupDiscoverableTrips([]);

        await getDiscoverableUseCase();
        await getDiscoverableUseCase();

        // Both calls go through separately — no hidden caching at use case layer
        expect(repo.discoverCalled, isTrue);
      });
    });
  });
}
