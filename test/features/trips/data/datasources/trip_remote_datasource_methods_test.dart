import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/features/trips/data/datasources/trip_queries.dart';
import 'package:travel_crew/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Comprehensive unit tests for [TripRemoteDataSourceImpl].
///
/// All Supabase chain calls go through [TripQueries] which is faked here.
/// We exercise every public non-stream method's happy + error path,
/// asserting both the args passed to the queries layer and the
/// model/value returned. The realtime-stream methods are intentionally
/// excluded — they wire `_client.channel(...)` directly and are covered
/// by integration / live tests.

class _FakeQueries implements TripQueries {
  // Last-call recorders ------------------------------------------------------
  Map<String, dynamic>? lastInsertedTrip;
  String? lastFindTripIdsForUser;
  List<String>? lastFindTripsByIdsArg;
  String? lastFindTripWithMembersById;
  String? lastUpdateTripId;
  Map<String, dynamic>? lastUpdateTripData;
  Map<String, dynamic>? lastInsertTripMember;
  String? lastDeleteMemberTripId;
  String? lastDeleteMemberUserId;
  String? lastSearchProfilesSearch;
  int? lastSearchProfilesLimit;
  String? lastFindExpenseSplitsUserId;
  List<String>? lastFindCrewMemberTripIds;
  String? lastFindCrewMemberUserId;
  int? lastFindPublicTripsLimit;
  String? lastRpcDeleteTripId;
  String? lastRpcCopyTripSourceId;
  String? lastRpcCopyTripNewName;
  DateTime? lastRpcCopyTripStart;
  DateTime? lastRpcCopyTripEnd;
  bool? lastRpcCopyTripItinerary;
  bool? lastRpcCopyTripChecklists;
  String? lastRpcToggleFavoriteId;

  // Canned responses --------------------------------------------------------
  Map<String, dynamic>? insertTripResponse;
  List<Map<String, dynamic>> findTripIdsForUserResponse = const [];
  List<Map<String, dynamic>> findTripsWithMembersByIdsResponse = const [];
  Map<String, dynamic>? findTripWithMembersByIdResponse;
  bool _findTripWithMembersByIdReturnNull = false;
  List<Map<String, dynamic>> updateTripByIdResponse = const [];
  List<Map<String, dynamic>> insertTripMemberResponse = const [];
  List<Map<String, dynamic>> searchProfilesResponse = const [];
  List<Map<String, dynamic>> findExpenseSplitsForUserResponse = const [];
  List<Map<String, dynamic>> findCrewMemberIdsResponse = const [];
  List<Map<String, dynamic>> findPublicTripsResponse = const [];
  dynamic rpcDeleteTripResponse = true;
  String rpcCopyTripResponse = 'new-trip-id';
  bool rpcToggleFavoriteResponse = true;
  List<Map<String, dynamic>> rpcGetFavoriteTripIdsResponse = const [];

  // Throw triggers ----------------------------------------------------------
  Object? throwOnInsertTrip;
  Object? throwOnFindTripIdsForUser;
  Object? throwOnFindTripsWithMembersByIds;
  Object? throwOnFindTripWithMembersById;
  Object? throwOnUpdateTripById;
  Object? throwOnInsertTripMember;
  Object? throwOnDeleteTripMember;
  Object? throwOnSearchProfiles;
  Object? throwOnFindExpenseSplits;
  Object? throwOnFindCrewMemberIds;
  Object? throwOnFindPublicTrips;
  Object? throwOnRpcDeleteTrip;
  Object? throwOnRpcCopyTrip;
  Object? throwOnRpcToggleFavorite;
  Object? throwOnRpcGetFavoriteTripIds;

  void setFindTripWithMembersByIdReturnNull() {
    _findTripWithMembersByIdReturnNull = true;
  }

  @override
  Future<Map<String, dynamic>> insertTrip(Map<String, dynamic> data) async {
    if (throwOnInsertTrip != null) throw throwOnInsertTrip!;
    lastInsertedTrip = data;
    return insertTripResponse ?? data;
  }

  @override
  Future<List<Map<String, dynamic>>> findTripIdsForUser(String userId) async {
    if (throwOnFindTripIdsForUser != null) throw throwOnFindTripIdsForUser!;
    lastFindTripIdsForUser = userId;
    return findTripIdsForUserResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findTripsWithMembersByIds(
      List<String> tripIds) async {
    if (throwOnFindTripsWithMembersByIds != null) {
      throw throwOnFindTripsWithMembersByIds!;
    }
    lastFindTripsByIdsArg = tripIds;
    return findTripsWithMembersByIdsResponse;
  }

  @override
  Future<Map<String, dynamic>?> findTripWithMembersById(String tripId) async {
    if (throwOnFindTripWithMembersById != null) {
      throw throwOnFindTripWithMembersById!;
    }
    lastFindTripWithMembersById = tripId;
    if (_findTripWithMembersByIdReturnNull) return null;
    return findTripWithMembersByIdResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> updateTripById(
      String tripId, Map<String, dynamic> updates) async {
    if (throwOnUpdateTripById != null) throw throwOnUpdateTripById!;
    lastUpdateTripId = tripId;
    lastUpdateTripData = updates;
    return updateTripByIdResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> insertTripMember(
      Map<String, dynamic> data) async {
    if (throwOnInsertTripMember != null) throw throwOnInsertTripMember!;
    lastInsertTripMember = data;
    return insertTripMemberResponse;
  }

  @override
  Future<void> deleteTripMember(String tripId, String userId) async {
    if (throwOnDeleteTripMember != null) throw throwOnDeleteTripMember!;
    lastDeleteMemberTripId = tripId;
    lastDeleteMemberUserId = userId;
  }

  @override
  Future<List<Map<String, dynamic>>> searchProfiles({
    String? search,
    int limit = 50,
  }) async {
    if (throwOnSearchProfiles != null) throw throwOnSearchProfiles!;
    lastSearchProfilesSearch = search;
    lastSearchProfilesLimit = limit;
    return searchProfilesResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findExpenseSplitsForUser(
      String userId) async {
    if (throwOnFindExpenseSplits != null) throw throwOnFindExpenseSplits!;
    lastFindExpenseSplitsUserId = userId;
    return findExpenseSplitsForUserResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findCrewMemberIds(
      List<String> tripIds, String userId) async {
    if (throwOnFindCrewMemberIds != null) throw throwOnFindCrewMemberIds!;
    lastFindCrewMemberTripIds = tripIds;
    lastFindCrewMemberUserId = userId;
    return findCrewMemberIdsResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findPublicTrips({int limit = 100}) async {
    if (throwOnFindPublicTrips != null) throw throwOnFindPublicTrips!;
    lastFindPublicTripsLimit = limit;
    return findPublicTripsResponse;
  }

  @override
  Future<dynamic> rpcDeleteTrip(String tripId) async {
    if (throwOnRpcDeleteTrip != null) throw throwOnRpcDeleteTrip!;
    lastRpcDeleteTripId = tripId;
    return rpcDeleteTripResponse;
  }

  @override
  Future<String> rpcCopyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    required bool copyItinerary,
    required bool copyChecklists,
  }) async {
    if (throwOnRpcCopyTrip != null) throw throwOnRpcCopyTrip!;
    lastRpcCopyTripSourceId = sourceTripId;
    lastRpcCopyTripNewName = newName;
    lastRpcCopyTripStart = newStartDate;
    lastRpcCopyTripEnd = newEndDate;
    lastRpcCopyTripItinerary = copyItinerary;
    lastRpcCopyTripChecklists = copyChecklists;
    return rpcCopyTripResponse;
  }

  @override
  Future<bool> rpcToggleFavorite(String tripId) async {
    if (throwOnRpcToggleFavorite != null) throw throwOnRpcToggleFavorite!;
    lastRpcToggleFavoriteId = tripId;
    return rpcToggleFavoriteResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> rpcGetFavoriteTripIds() async {
    if (throwOnRpcGetFavoriteTripIds != null) {
      throw throwOnRpcGetFavoriteTripIds!;
    }
    return rpcGetFavoriteTripIdsResponse;
  }
}

void main() {
  late _FakeQueries queries;
  late TripRemoteDataSourceImpl ds;

  String? currentUserId = 'user-1';

  void buildDs({String? Function()? overrideUid}) {
    ds = TripRemoteDataSourceImpl(
      queries: queries,
      currentUserId: overrideUid ?? () => currentUserId,
    );
  }

  setUp(() {
    queries = _FakeQueries();
    currentUserId = 'user-1';
    buildDs();
  });

  // ---------------------------------------------------------------------------
  // createTrip
  // ---------------------------------------------------------------------------
  group('createTrip', () {
    Map<String, dynamic> tripRow({String id = 't-1'}) => {
          'id': id,
          'name': 'Bali',
          'description': 'Beach',
          'destination': 'Bali',
          'start_date': '2024-01-01T00:00:00.000Z',
          'end_date': '2024-01-08T00:00:00.000Z',
          'cover_image_url': 'http://x',
          'created_by': 'user-1',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'is_completed': false,
          'rating': 0.0,
          'cost': 100.0,
          'currency': 'INR',
          'is_public': true,
        };

    test('throws when no user', () async {
      buildDs(overrideUid: () => null);
      await expectLater(
        ds.createTrip(_buildTrip()),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('User not authenticated'))),
      );
    });

    test('inserts and returns parsed model', () async {
      queries.insertTripResponse = tripRow(id: 't-1');
      final created = await ds.createTrip(_buildTrip());
      expect(created.id, 't-1');
      expect(queries.lastInsertedTrip!['name'], 'Bali');
      expect(queries.lastInsertedTrip!['created_by'], 'user-1');
      expect(queries.lastInsertedTrip!['currency'], 'INR');
      expect(queries.lastInsertedTrip!['is_public'], true);
    });

    test('wraps query errors with "Failed to create trip"', () async {
      queries.throwOnInsertTrip = Exception('boom');
      await expectLater(
        ds.createTrip(_buildTrip()),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to create trip'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getUserTrips
  // ---------------------------------------------------------------------------
  group('getUserTrips', () {
    test('throws when no user', () async {
      buildDs(overrideUid: () => null);
      await expectLater(
        ds.getUserTrips(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get user trips'))),
      );
    });

    test('returns empty list when user has no trip memberships', () async {
      queries.findTripIdsForUserResponse = const [];
      final result = await ds.getUserTrips();
      expect(result, isEmpty);
      expect(queries.lastFindTripIdsForUser, 'user-1');
    });

    test('parses trips, members and applies favorite flag', () async {
      queries.findTripIdsForUserResponse = const [
        {'trip_id': 't-1'},
        {'trip_id': 't-2'},
      ];
      queries.rpcGetFavoriteTripIdsResponse = const [
        {'trip_id': 't-2'},
      ];
      queries.findTripsWithMembersByIdsResponse = [
        _tripJoinedRow(id: 't-1', name: 'Trip 1', members: [
          _memberRow(id: 'm-1', userId: 'user-1', email: 'u1@x.com'),
        ]),
        _tripJoinedRow(id: 't-2', name: 'Trip 2', members: const []),
      ];

      final trips = await ds.getUserTrips();

      expect(trips, hasLength(2));
      expect(trips[0].trip.id, 't-1');
      expect(trips[0].isFavorite, isFalse);
      expect(trips[0].members, hasLength(1));
      expect(trips[0].members.first.email, 'u1@x.com');
      expect(trips[1].trip.id, 't-2');
      expect(trips[1].isFavorite, isTrue);
      expect(queries.lastFindTripsByIdsArg, ['t-1', 't-2']);
    });

    test('wraps query errors', () async {
      queries.findTripIdsForUserResponse = const [
        {'trip_id': 't-1'},
      ];
      queries.throwOnFindTripsWithMembersByIds = Exception('boom');
      await expectLater(
        ds.getUserTrips(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get user trips'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getTripById
  // ---------------------------------------------------------------------------
  group('getTripById', () {
    test('returns null when query returns null', () async {
      queries.setFindTripWithMembersByIdReturnNull();
      final result = await ds.getTripById('t-x');
      expect(result, isNull);
      expect(queries.lastFindTripWithMembersById, 't-x');
    });

    test('returns parsed trip with isFavorite=true when favorite', () async {
      queries.findTripWithMembersByIdResponse =
          _tripJoinedRow(id: 't-1', name: 'Trip A', members: const []);
      queries.rpcGetFavoriteTripIdsResponse = const [
        {'trip_id': 't-1'},
      ];

      final result = await ds.getTripById('t-1');

      expect(result, isNotNull);
      expect(result!.trip.id, 't-1');
      expect(result.isFavorite, isTrue);
    });

    test('isFavorite=false when not in favorites list', () async {
      queries.findTripWithMembersByIdResponse =
          _tripJoinedRow(id: 't-1', name: 'Trip A', members: const []);
      queries.rpcGetFavoriteTripIdsResponse = const [];

      final result = await ds.getTripById('t-1');

      expect(result!.isFavorite, isFalse);
    });

    test('handles trip_members where profiles is a list', () async {
      // Supabase sometimes returns profiles as a 1-element list
      final row = _tripJoinedRow(id: 't-1', name: 'X', members: [
        {
          'id': 'm-1',
          'user_id': 'u-1',
          'role': 'admin',
          'joined_at': '2024-01-01T00:00:00.000Z',
          'profiles': [
            {'id': 'u-1', 'email': 'a@b.com', 'full_name': 'A B'}
          ],
        },
      ]);
      queries.findTripWithMembersByIdResponse = row;

      final result = await ds.getTripById('t-1');
      expect(result!.members.single.email, 'a@b.com');
      expect(result.members.single.fullName, 'A B');
    });

    test('handles trip_members where profiles list is empty', () async {
      final row = _tripJoinedRow(id: 't-1', name: 'X', members: [
        {
          'id': 'm-1',
          'user_id': 'u-1',
          'role': 'admin',
          'joined_at': '2024-01-01T00:00:00.000Z',
          'profiles': const <dynamic>[],
        },
      ]);
      queries.findTripWithMembersByIdResponse = row;

      final result = await ds.getTripById('t-1');
      expect(result!.members.single.email, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnFindTripWithMembersById = Exception('boom');
      await expectLater(
        ds.getTripById('t-x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get trip'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateTrip
  // ---------------------------------------------------------------------------
  group('updateTrip', () {
    test('drops null values, snake_cases keys, formats DateTime fields',
        () async {
      final start = DateTime.utc(2024, 7, 1);
      final end = DateTime.utc(2024, 7, 8);
      await ds.updateTrip('t-1', {
        'name': 'New',
        'description': null, // dropped
        'startDate': start,
        'endDate': end,
        'isCompleted': true,
      });

      expect(queries.lastUpdateTripId, 't-1');
      expect(queries.lastUpdateTripData, {
        'name': 'New',
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'is_completed': true,
      });
    });

    test('wraps errors', () async {
      queries.throwOnUpdateTripById = Exception('boom');
      await expectLater(
        ds.updateTrip('t-1', {'name': 'x'}),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to update trip'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteTrip
  // ---------------------------------------------------------------------------
  group('deleteTrip', () {
    test('calls admin_delete_trip RPC', () async {
      queries.rpcDeleteTripResponse = true;
      await ds.deleteTrip('t-1');
      expect(queries.lastRpcDeleteTripId, 't-1');
    });

    test('throws when RPC returns false (not found / no permission)',
        () async {
      queries.rpcDeleteTripResponse = false;
      await expectLater(
        ds.deleteTrip('t-1'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to delete trip'))),
      );
    });

    test('wraps errors', () async {
      queries.throwOnRpcDeleteTrip = Exception('boom');
      await expectLater(
        ds.deleteTrip('t-1'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to delete trip'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // addMember / removeMember
  // ---------------------------------------------------------------------------
  group('addMember', () {
    test('inserts a row with default member role', () async {
      queries.insertTripMemberResponse = const [
        {'id': 'r1'}
      ];
      await ds.addMember('t-1', 'u-9');
      expect(queries.lastInsertTripMember, {
        'trip_id': 't-1',
        'user_id': 'u-9',
        'role': 'member',
      });
    });

    test('honors a custom role', () async {
      queries.insertTripMemberResponse = const [
        {'id': 'r1'}
      ];
      await ds.addMember('t-1', 'u-9', role: 'admin');
      expect(queries.lastInsertTripMember!['role'], 'admin');
    });

    test('wraps errors', () async {
      queries.throwOnInsertTripMember = Exception('boom');
      await expectLater(
        ds.addMember('t-1', 'u-9'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to add member'))),
      );
    });
  });

  group('removeMember', () {
    test('issues a delete with both filters', () async {
      await ds.removeMember('t-1', 'u-9');
      expect(queries.lastDeleteMemberTripId, 't-1');
      expect(queries.lastDeleteMemberUserId, 'u-9');
    });

    test('wraps errors', () async {
      queries.throwOnDeleteTripMember = Exception('boom');
      await expectLater(
        ds.removeMember('t-1', 'u-9'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to remove member'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // searchSystemUsers
  // ---------------------------------------------------------------------------
  group('searchSystemUsers', () {
    test('passes through search and limit', () async {
      queries.searchProfilesResponse = const [];
      await ds.searchSystemUsers(search: 'alice', limit: 10);
      expect(queries.lastSearchProfilesSearch, 'alice');
      expect(queries.lastSearchProfilesLimit, 10);
    });

    test('returns mapped models', () async {
      queries.searchProfilesResponse = const [
        {
          'id': 'u-1',
          'email': 'a@x.com',
          'full_name': 'Alice',
          'avatar_url': null,
        },
        {
          'id': 'u-2',
          'email': 'b@x.com',
          'full_name': 'Bob',
          'avatar_url': null,
        },
      ];
      final result = await ds.searchSystemUsers();
      expect(result, hasLength(2));
      expect(result[0].email, 'a@x.com');
      expect(result[1].fullName, 'Bob');
    });

    test('filters out excluded user ids client-side', () async {
      queries.searchProfilesResponse = const [
        {'id': 'u-1', 'email': 'a@x.com', 'full_name': 'A'},
        {'id': 'u-2', 'email': 'b@x.com', 'full_name': 'B'},
        {'id': 'u-3', 'email': 'c@x.com', 'full_name': 'C'},
      ];
      final result = await ds.searchSystemUsers(excludeUserIds: ['u-2']);
      expect(result.map((u) => u.id), ['u-1', 'u-3']);
    });

    test('does not filter when excludeUserIds is null or empty', () async {
      queries.searchProfilesResponse = const [
        {'id': 'u-1', 'email': 'a@x.com', 'full_name': 'A'},
      ];
      final r1 = await ds.searchSystemUsers();
      expect(r1, hasLength(1));
      final r2 = await ds.searchSystemUsers(excludeUserIds: const []);
      expect(r2, hasLength(1));
    });

    test('wraps errors', () async {
      queries.throwOnSearchProfiles = Exception('boom');
      await expectLater(
        ds.searchSystemUsers(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to search users'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getUserStats
  // ---------------------------------------------------------------------------
  group('getUserStats', () {
    test('throws when no user', () async {
      buildDs(overrideUid: () => null);
      await expectLater(
        ds.getUserStats(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get user stats'))),
      );
    });

    test('aggregates trips, expenses, spent, unique crew', () async {
      queries.findTripIdsForUserResponse = const [
        {'trip_id': 't-1'},
        {'trip_id': 't-2'},
      ];
      queries.findExpenseSplitsForUserResponse = const [
        {'id': 'e-1', 'amount': 25.5},
        {'id': 'e-2', 'amount': 4.5},
        {'id': 'e-3', 'amount': null},
      ];
      queries.findCrewMemberIdsResponse = const [
        {'user_id': 'u-2'},
        {'user_id': 'u-3'},
        {'user_id': 'u-2'}, // dup → unique 2
      ];

      final stats = await ds.getUserStats();
      expect(stats.totalTrips, 2);
      expect(stats.totalExpenses, 3);
      expect(stats.totalSpent, 30.0);
      expect(stats.uniqueCrewMembers, 2);
      expect(queries.lastFindCrewMemberTripIds, ['t-1', 't-2']);
      expect(queries.lastFindCrewMemberUserId, 'user-1');
    });

    test('skips crew query when user has no trips', () async {
      queries.findTripIdsForUserResponse = const [];
      queries.findExpenseSplitsForUserResponse = const [];
      final stats = await ds.getUserStats();
      expect(stats.totalTrips, 0);
      expect(stats.uniqueCrewMembers, 0);
      expect(queries.lastFindCrewMemberTripIds, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnFindTripIdsForUser = Exception('boom');
      await expectLater(
        ds.getUserStats(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get user stats'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getDiscoverableTrips
  // ---------------------------------------------------------------------------
  group('getDiscoverableTrips', () {
    test('throws when no user', () async {
      buildDs(overrideUid: () => null);
      await expectLater(
        ds.getDiscoverableTrips(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('Failed to get discoverable trips'))),
      );
    });

    test('filters out trips the user is already a member of, caps at 50',
        () async {
      queries.findTripIdsForUserResponse = const [
        {'trip_id': 't-mine-1'},
        {'trip_id': 't-mine-2'},
      ];
      // 60 public trips, 2 of which the user is already in.
      queries.findPublicTripsResponse = [
        for (int i = 0; i < 60; i++)
          _tripJoinedRow(id: 't-$i', name: 'T$i', members: const []),
        _tripJoinedRow(id: 't-mine-1', name: 'Mine1', members: const []),
        _tripJoinedRow(id: 't-mine-2', name: 'Mine2', members: const []),
      ];

      final trips = await ds.getDiscoverableTrips();
      expect(trips.length, 50);
      expect(
        trips.every((t) =>
            !['t-mine-1', 't-mine-2'].contains(t.trip.id)),
        isTrue,
      );
      expect(queries.lastFindPublicTripsLimit, 100);
    });

    test('wraps errors', () async {
      queries.findTripIdsForUserResponse = const [];
      queries.throwOnFindPublicTrips = Exception('boom');
      await expectLater(
        ds.getDiscoverableTrips(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('Failed to get discoverable trips'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // copyTrip
  // ---------------------------------------------------------------------------
  group('copyTrip', () {
    test('forwards parameters to RPC and returns new id', () async {
      queries.rpcCopyTripResponse = 'new-id';
      final start = DateTime.utc(2024, 7, 1);
      final end = DateTime.utc(2024, 7, 8);

      final newId = await ds.copyTrip(
        sourceTripId: 'src',
        newName: 'Renamed',
        newStartDate: start,
        newEndDate: end,
        copyItinerary: false,
        copyChecklists: true,
      );

      expect(newId, 'new-id');
      expect(queries.lastRpcCopyTripSourceId, 'src');
      expect(queries.lastRpcCopyTripNewName, 'Renamed');
      expect(queries.lastRpcCopyTripStart, start);
      expect(queries.lastRpcCopyTripEnd, end);
      expect(queries.lastRpcCopyTripItinerary, false);
      expect(queries.lastRpcCopyTripChecklists, true);
    });

    test('uses default flags when not provided', () async {
      queries.rpcCopyTripResponse = 'x';
      await ds.copyTrip(
        sourceTripId: 's',
        newName: 'n',
        newStartDate: DateTime.utc(2024, 1, 1),
        newEndDate: DateTime.utc(2024, 1, 2),
      );
      expect(queries.lastRpcCopyTripItinerary, true);
      expect(queries.lastRpcCopyTripChecklists, true);
    });

    test('wraps errors', () async {
      queries.throwOnRpcCopyTrip = Exception('boom');
      await expectLater(
        ds.copyTrip(
          sourceTripId: 's',
          newName: 'n',
          newStartDate: DateTime.utc(2024, 1, 1),
          newEndDate: DateTime.utc(2024, 1, 2),
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to copy trip'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // toggleFavorite
  // ---------------------------------------------------------------------------
  group('toggleFavorite', () {
    test('forwards to RPC and returns bool', () async {
      queries.rpcToggleFavoriteResponse = true;
      final result = await ds.toggleFavorite('t-1');
      expect(result, isTrue);
      expect(queries.lastRpcToggleFavoriteId, 't-1');
    });

    test('returns false when RPC returns false', () async {
      queries.rpcToggleFavoriteResponse = false;
      final result = await ds.toggleFavorite('t-1');
      expect(result, isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnRpcToggleFavorite = Exception('boom');
      await expectLater(
        ds.toggleFavorite('t-1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('Failed to toggle favorite'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getFavoriteTripIds
  // ---------------------------------------------------------------------------
  group('getFavoriteTripIds', () {
    test('returns mapped trip ids', () async {
      queries.rpcGetFavoriteTripIdsResponse = const [
        {'trip_id': 't-1'},
        {'trip_id': 't-2'},
      ];
      final ids = await ds.getFavoriteTripIds();
      expect(ids, ['t-1', 't-2']);
    });

    test('returns empty list when no favorites', () async {
      queries.rpcGetFavoriteTripIdsResponse = const [];
      final ids = await ds.getFavoriteTripIds();
      expect(ids, isEmpty);
    });

    test('wraps errors', () async {
      queries.throwOnRpcGetFavoriteTripIds = Exception('boom');
      await expectLater(
        ds.getFavoriteTripIds(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('Failed to get favorite trip IDs'))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SystemUserModel
  // ---------------------------------------------------------------------------
  group('SystemUserModel', () {
    test('displayName prefers fullName, then email, then fallback', () {
      expect(
        const SystemUserModel(id: 'u', fullName: 'Alice').displayName,
        'Alice',
      );
      expect(
        const SystemUserModel(id: 'u', email: 'a@b.com').displayName,
        'a@b.com',
      );
      expect(const SystemUserModel(id: 'u').displayName, 'Unknown User');
    });

    test('fromJson maps fields', () {
      final u = SystemUserModel.fromJson(const {
        'id': 'u',
        'email': 'a@b.com',
        'full_name': 'Alice',
        'avatar_url': 'http://x',
      });
      expect(u.id, 'u');
      expect(u.email, 'a@b.com');
      expect(u.fullName, 'Alice');
      expect(u.avatarUrl, 'http://x');
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

Map<String, dynamic> _tripJoinedRow({
  required String id,
  required String name,
  required List<Map<String, dynamic>> members,
}) {
  return {
    'id': id,
    'name': name,
    'description': null,
    'destination': 'Earth',
    'start_date': '2024-01-01T00:00:00.000Z',
    'end_date': '2024-01-02T00:00:00.000Z',
    'cover_image_url': null,
    'created_by': 'user-1',
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
    'is_completed': false,
    'rating': 0.0,
    'cost': null,
    'currency': 'INR',
    'is_public': true,
    'trip_members': members,
  };
}

Map<String, dynamic> _memberRow({
  required String id,
  required String userId,
  String role = 'member',
  String email = 'x@y.com',
  String fullName = 'Member',
}) {
  return {
    'id': id,
    'user_id': userId,
    'role': role,
    'joined_at': '2024-01-01T00:00:00.000Z',
    'profiles': {
      'id': userId,
      'email': email,
      'full_name': fullName,
      'avatar_url': null,
    },
  };
}

TripModel _buildTrip() {
  return TripModel(
    id: 'placeholder',
    name: 'Bali',
    description: 'Beach',
    destination: 'Bali',
    startDate: DateTime.utc(2024, 1, 1),
    endDate: DateTime.utc(2024, 1, 8),
    coverImageUrl: 'http://x',
    createdBy: 'user-1',
    cost: 100.0,
    currency: 'INR',
    isPublic: true,
  );
}
