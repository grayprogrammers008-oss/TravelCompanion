import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:travel_crew/features/itinerary/data/datasources/itinerary_queries.dart';
import 'package:travel_crew/features/itinerary/data/datasources/itinerary_remote_datasource.dart';

/// Comprehensive unit tests for [ItineraryRemoteDataSource].
///
/// All Supabase chain calls go through [ItineraryQueries] which is faked
/// here. We exercise every public method on the happy path AND the error
/// path, asserting both the args passed to the queries layer and the
/// model returned. Realtime stream methods (`watchTripItinerary`,
/// `watchItineraryByDays`) hit Supabase channels directly and are not
/// covered by these unit tests.

class _FakeQueries implements ItineraryQueries {
  // Last-call recorders.
  Map<String, dynamic>? lastInserted;
  String? lastFindForTripId;
  String? lastFindForDayTripId;
  int? lastFindForDayDayNumber;
  String? lastFindByIdItemId;
  String? lastUpdateReturningItemId;
  Map<String, dynamic>? lastUpdateReturningData;
  String? lastDeleteItemId;
  Map<String, dynamic>? lastScopedUpdateData;
  String? lastScopedUpdateItemId;
  String? lastScopedUpdateTripId;
  int? lastScopedUpdateDayNumber;
  String? lastFindMaxOrderTripId;
  int? lastFindMaxOrderDayNumber;
  String? lastUpdateByIdItemId;
  Map<String, dynamic>? lastUpdateByIdData;

  // Tracking for sequential calls (used by reorderItems).
  final List<Map<String, dynamic>> scopedUpdateCalls = [];

  // Programmable responses.
  Map<String, dynamic>? insertItemResponse;
  List<Map<String, dynamic>> findItemsForTripResponse = const [];
  List<Map<String, dynamic>> findItemsForDayResponse = const [];
  Map<String, dynamic>? findItemByIdResponse;
  Map<String, dynamic>? updateItemReturningResponse;
  List<Map<String, dynamic>> findMaxOrderResponse = const [];

  // Error injection.
  Object? throwOnInsert;
  Object? throwOnFindForTrip;
  Object? throwOnFindForDay;
  Object? throwOnFindById;
  Object? throwOnUpdateReturning;
  Object? throwOnDelete;
  Object? throwOnScopedUpdate;
  Object? throwOnFindMaxOrder;
  Object? throwOnUpdateById;

  @override
  Future<Map<String, dynamic>> insertItem(Map<String, dynamic> data) async {
    if (throwOnInsert != null) throw throwOnInsert!;
    lastInserted = data;
    return insertItemResponse ?? data;
  }

  @override
  Future<List<Map<String, dynamic>>> findItemsForTrip(String tripId) async {
    if (throwOnFindForTrip != null) throw throwOnFindForTrip!;
    lastFindForTripId = tripId;
    return findItemsForTripResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findItemsForDay(
    String tripId,
    int dayNumber,
  ) async {
    if (throwOnFindForDay != null) throw throwOnFindForDay!;
    lastFindForDayTripId = tripId;
    lastFindForDayDayNumber = dayNumber;
    return findItemsForDayResponse;
  }

  @override
  Future<Map<String, dynamic>> findItemById(String itemId) async {
    if (throwOnFindById != null) throw throwOnFindById!;
    lastFindByIdItemId = itemId;
    return findItemByIdResponse ?? const {};
  }

  @override
  Future<Map<String, dynamic>> updateItemByIdReturning(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    if (throwOnUpdateReturning != null) throw throwOnUpdateReturning!;
    lastUpdateReturningItemId = itemId;
    lastUpdateReturningData = data;
    return updateItemReturningResponse ?? const {};
  }

  @override
  Future<void> deleteItemById(String itemId) async {
    if (throwOnDelete != null) throw throwOnDelete!;
    lastDeleteItemId = itemId;
  }

  @override
  Future<void> updateItemScopedToDay({
    required String itemId,
    required String tripId,
    required int dayNumber,
    required Map<String, dynamic> data,
  }) async {
    if (throwOnScopedUpdate != null) throw throwOnScopedUpdate!;
    lastScopedUpdateItemId = itemId;
    lastScopedUpdateTripId = tripId;
    lastScopedUpdateDayNumber = dayNumber;
    lastScopedUpdateData = data;
    scopedUpdateCalls.add({
      'itemId': itemId,
      'tripId': tripId,
      'dayNumber': dayNumber,
      'data': data,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> findMaxOrderIndexForDay(
    String tripId,
    int dayNumber,
  ) async {
    if (throwOnFindMaxOrder != null) throw throwOnFindMaxOrder!;
    lastFindMaxOrderTripId = tripId;
    lastFindMaxOrderDayNumber = dayNumber;
    return findMaxOrderResponse;
  }

  @override
  Future<void> updateItemById(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    if (throwOnUpdateById != null) throw throwOnUpdateById!;
    lastUpdateByIdItemId = itemId;
    lastUpdateByIdData = data;
  }
}

class _FakeAuth extends Mock implements GoTrueClient {
  _FakeAuth([this._user]);
  final User? _user;
  @override
  User? get currentUser => _user;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._id);
  final String _id;
  @override
  String get id => _id;
}

class _FakeSupabase extends Fake implements SupabaseClient {
  _FakeSupabase(this._auth);
  final GoTrueClient _auth;
  @override
  GoTrueClient get auth => _auth;
}

void main() {
  late _FakeQueries queries;
  late _FakeSupabase supabase;
  late ItineraryRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  Map<String, dynamic> fullRow({
    String id = 'item-1',
    String tripId = 'trip-1',
    String title = 'Visit beach',
    int? dayNumber = 1,
    int orderIndex = 0,
    String? creatorFullName = 'Alice',
  }) {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'description': 'desc',
      'location': 'loc',
      'latitude': 1.0,
      'longitude': 2.0,
      'place_id': 'p1',
      'start_time': fixedClock.toIso8601String(),
      'end_time': fixedClock.add(const Duration(hours: 1)).toIso8601String(),
      'day_number': dayNumber,
      'order_index': orderIndex,
      'created_by': 'user-1',
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
      'profiles': creatorFullName == null ? null : {'full_name': creatorFullName},
    };
  }

  void setUpDs({User? user}) {
    supabase = _FakeSupabase(_FakeAuth(user ?? _FakeUser('user-1')));
    ds = ItineraryRemoteDataSource(
      supabase,
      queries: queries,
      uuid: const Uuid(),
      clock: () => fixedClock,
    );
  }

  setUp(() {
    queries = _FakeQueries();
    setUpDs();
  });

  group('createItem', () {
    test('throws when no user authenticated', () async {
      supabase = _FakeSupabase(_FakeAuth(null));
      ds = ItineraryRemoteDataSource(
        supabase,
        queries: queries,
        clock: () => fixedClock,
      );
      await expectLater(
        ds.createItem(tripId: 't', title: 'X'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('User not authenticated'))),
      );
    });

    test('inserts item with all expected fields and returns parsed model',
        () async {
      queries.insertItemResponse = fullRow();

      final result = await ds.createItem(
        tripId: 'trip-1',
        title: 'Visit beach',
        description: 'desc',
        location: 'loc',
        latitude: 1.0,
        longitude: 2.0,
        placeId: 'p1',
        startTime: fixedClock,
        endTime: fixedClock.add(const Duration(hours: 1)),
        dayNumber: 1,
        orderIndex: 3,
      );

      expect(queries.lastInserted!['trip_id'], 'trip-1');
      expect(queries.lastInserted!['title'], 'Visit beach');
      expect(queries.lastInserted!['description'], 'desc');
      expect(queries.lastInserted!['location'], 'loc');
      expect(queries.lastInserted!['latitude'], 1.0);
      expect(queries.lastInserted!['longitude'], 2.0);
      expect(queries.lastInserted!['place_id'], 'p1');
      expect(queries.lastInserted!['start_time'], fixedClock.toIso8601String());
      expect(queries.lastInserted!['end_time'],
          fixedClock.add(const Duration(hours: 1)).toIso8601String());
      expect(queries.lastInserted!['day_number'], 1);
      expect(queries.lastInserted!['order_index'], 3);
      expect(queries.lastInserted!['created_by'], 'user-1');
      expect(queries.lastInserted!['created_at'], fixedClock.toIso8601String());
      expect(queries.lastInserted!['updated_at'], fixedClock.toIso8601String());
      // Generated UUID is non-empty.
      expect(queries.lastInserted!['id'], isA<String>());
      expect((queries.lastInserted!['id'] as String).length, greaterThan(0));

      expect(result.id, 'item-1');
      expect(result.title, 'Visit beach');
      expect(result.creatorName, 'Alice');
    });

    test('uses sensible defaults for optional fields', () async {
      queries.insertItemResponse = fullRow();

      await ds.createItem(tripId: 't', title: 'Title');

      expect(queries.lastInserted!['description'], isNull);
      expect(queries.lastInserted!['location'], isNull);
      expect(queries.lastInserted!['latitude'], isNull);
      expect(queries.lastInserted!['longitude'], isNull);
      expect(queries.lastInserted!['place_id'], isNull);
      expect(queries.lastInserted!['start_time'], isNull);
      expect(queries.lastInserted!['end_time'], isNull);
      expect(queries.lastInserted!['day_number'], isNull);
      expect(queries.lastInserted!['order_index'], 0);
    });

    test('handles null profiles join (no creator_name)', () async {
      queries.insertItemResponse = fullRow(creatorFullName: null);
      final result = await ds.createItem(tripId: 't', title: 'X');
      expect(result.creatorName, isNull);
    });

    test('wraps query errors with "Failed to create itinerary item"',
        () async {
      queries.throwOnInsert = Exception('boom');
      await expectLater(
        ds.createItem(tripId: 't', title: 'X'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to create itinerary item'))),
      );
    });
  });

  group('getTripItinerary', () {
    test('passes trip id and returns mapped models with creator_name',
        () async {
      queries.findItemsForTripResponse = [
        fullRow(id: 'a', creatorFullName: 'Alice'),
        fullRow(id: 'b', creatorFullName: null),
      ];
      final result = await ds.getTripItinerary('t-1');
      expect(queries.lastFindForTripId, 't-1');
      expect(result, hasLength(2));
      expect(result[0].id, 'a');
      expect(result[0].creatorName, 'Alice');
      expect(result[1].id, 'b');
      expect(result[1].creatorName, isNull);
    });

    test('returns empty list when none found', () async {
      queries.findItemsForTripResponse = const [];
      final result = await ds.getTripItinerary('t');
      expect(result, isEmpty);
    });

    test('wraps errors', () async {
      queries.throwOnFindForTrip = Exception('boom');
      await expectLater(
        ds.getTripItinerary('t'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get trip itinerary'))),
      );
    });
  });

  group('getDayItinerary', () {
    test('passes trip id and day number, returns mapped models', () async {
      queries.findItemsForDayResponse = [
        fullRow(id: 'a', dayNumber: 2),
      ];
      final result = await ds.getDayItinerary(tripId: 't-1', dayNumber: 2);
      expect(queries.lastFindForDayTripId, 't-1');
      expect(queries.lastFindForDayDayNumber, 2);
      expect(result, hasLength(1));
      expect(result.single.id, 'a');
    });

    test('wraps errors', () async {
      queries.throwOnFindForDay = Exception('boom');
      await expectLater(
        ds.getDayItinerary(tripId: 't', dayNumber: 1),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get day itinerary'))),
      );
    });
  });

  group('getItineraryByDays', () {
    test('groups items by day_number, sorts ascending', () async {
      queries.findItemsForTripResponse = [
        fullRow(id: 'a', dayNumber: 2),
        fullRow(id: 'b', dayNumber: 1),
        fullRow(id: 'c', dayNumber: 1),
        fullRow(id: 'd', dayNumber: 3),
      ];
      final days = await ds.getItineraryByDays('t');
      expect(days.map((d) => d.dayNumber).toList(), [1, 2, 3]);
      expect(days[0].items.map((i) => i.id).toList(), ['b', 'c']);
      expect(days[1].items.map((i) => i.id).toList(), ['a']);
      expect(days[2].items.map((i) => i.id).toList(), ['d']);
    });

    test('null day_number is grouped under day 0', () async {
      queries.findItemsForTripResponse = [
        fullRow(id: 'a', dayNumber: null),
        fullRow(id: 'b', dayNumber: 1),
      ];
      final days = await ds.getItineraryByDays('t');
      expect(days.map((d) => d.dayNumber).toList(), [0, 1]);
      expect(days[0].items.single.id, 'a');
    });

    test('returns empty list when no items', () async {
      queries.findItemsForTripResponse = const [];
      final days = await ds.getItineraryByDays('t');
      expect(days, isEmpty);
    });

    test('wraps errors (rewrapping inner error from getTripItinerary)',
        () async {
      queries.throwOnFindForTrip = Exception('boom');
      await expectLater(
        ds.getItineraryByDays('t'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get itinerary by days'))),
      );
    });
  });

  group('getItem', () {
    test('passes id, returns parsed model with creator_name', () async {
      queries.findItemByIdResponse = fullRow(id: 'item-7', creatorFullName: 'Bob');
      final result = await ds.getItem('item-7');
      expect(queries.lastFindByIdItemId, 'item-7');
      expect(result.id, 'item-7');
      expect(result.creatorName, 'Bob');
    });

    test('handles null profiles join', () async {
      queries.findItemByIdResponse = fullRow(creatorFullName: null);
      final result = await ds.getItem('x');
      expect(result.creatorName, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnFindById = Exception('boom');
      await expectLater(
        ds.getItem('x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get itinerary item'))),
      );
    });
  });

  group('updateItem', () {
    test('only sends provided fields plus updated_at', () async {
      queries.updateItemReturningResponse = fullRow(id: 'item-1');

      await ds.updateItem(
        itemId: 'item-1',
        title: 'New title',
        description: 'New desc',
      );

      expect(queries.lastUpdateReturningItemId, 'item-1');
      final data = queries.lastUpdateReturningData!;
      expect(data['title'], 'New title');
      expect(data['description'], 'New desc');
      expect(data['updated_at'], fixedClock.toIso8601String());
      expect(data.containsKey('location'), isFalse);
      expect(data.containsKey('latitude'), isFalse);
      expect(data.containsKey('longitude'), isFalse);
      expect(data.containsKey('place_id'), isFalse);
      expect(data.containsKey('start_time'), isFalse);
      expect(data.containsKey('end_time'), isFalse);
      expect(data.containsKey('day_number'), isFalse);
      expect(data.containsKey('order_index'), isFalse);
    });

    test('formats DateTime fields as ISO 8601 strings', () async {
      queries.updateItemReturningResponse = fullRow();
      final start = DateTime.utc(2024, 7, 1, 9);
      final end = DateTime.utc(2024, 7, 1, 11);

      await ds.updateItem(
        itemId: 'item-1',
        startTime: start,
        endTime: end,
      );

      final data = queries.lastUpdateReturningData!;
      expect(data['start_time'], start.toIso8601String());
      expect(data['end_time'], end.toIso8601String());
    });

    test('passes through all numeric/string fields when provided', () async {
      queries.updateItemReturningResponse = fullRow();

      await ds.updateItem(
        itemId: 'item-1',
        location: 'Beach',
        latitude: 12.5,
        longitude: -3.7,
        placeId: 'place-x',
        dayNumber: 4,
        orderIndex: 9,
      );

      final data = queries.lastUpdateReturningData!;
      expect(data['location'], 'Beach');
      expect(data['latitude'], 12.5);
      expect(data['longitude'], -3.7);
      expect(data['place_id'], 'place-x');
      expect(data['day_number'], 4);
      expect(data['order_index'], 9);
    });

    test('returns parsed model with creator_name', () async {
      queries.updateItemReturningResponse =
          fullRow(id: 'item-1', creatorFullName: 'Carol');
      final result = await ds.updateItem(itemId: 'item-1', title: 'T');
      expect(result.id, 'item-1');
      expect(result.creatorName, 'Carol');
    });

    test('returns parsed model with null creator_name when no profile join',
        () async {
      queries.updateItemReturningResponse =
          fullRow(id: 'item-1', creatorFullName: null);
      final result = await ds.updateItem(itemId: 'item-1', title: 'T');
      expect(result.creatorName, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnUpdateReturning = Exception('boom');
      await expectLater(
        ds.updateItem(itemId: 'x', title: 't'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to update itinerary item'))),
      );
    });
  });

  group('deleteItem', () {
    test('forwards id to queries', () async {
      await ds.deleteItem('item-9');
      expect(queries.lastDeleteItemId, 'item-9');
    });

    test('wraps errors', () async {
      queries.throwOnDelete = Exception('boom');
      await expectLater(
        ds.deleteItem('x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to delete itinerary item'))),
      );
    });
  });

  group('reorderItems', () {
    test('issues one scoped update per id with sequential order_index',
        () async {
      await ds.reorderItems(
        tripId: 'trip-1',
        dayNumber: 2,
        itemIds: ['a', 'b', 'c'],
      );

      expect(queries.scopedUpdateCalls, hasLength(3));

      for (var i = 0; i < 3; i++) {
        final call = queries.scopedUpdateCalls[i];
        expect(call['itemId'], ['a', 'b', 'c'][i]);
        expect(call['tripId'], 'trip-1');
        expect(call['dayNumber'], 2);
        final data = call['data'] as Map<String, dynamic>;
        expect(data['order_index'], i);
        expect(data['updated_at'], fixedClock.toIso8601String());
      }
    });

    test('does nothing on empty list', () async {
      await ds.reorderItems(tripId: 't', dayNumber: 1, itemIds: const []);
      expect(queries.scopedUpdateCalls, isEmpty);
    });

    test('wraps errors', () async {
      queries.throwOnScopedUpdate = Exception('boom');
      await expectLater(
        ds.reorderItems(tripId: 't', dayNumber: 1, itemIds: ['a']),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to reorder items'))),
      );
    });
  });

  group('moveItemToDay', () {
    test(
        'looks up item, queries max order on target day, sets new day + maxOrder+1',
        () async {
      queries.findItemByIdResponse = fullRow(id: 'item-1', tripId: 'trip-1');
      queries.findMaxOrderResponse = [
        {'order_index': 5},
      ];

      await ds.moveItemToDay(itemId: 'item-1', newDayNumber: 4);

      expect(queries.lastFindByIdItemId, 'item-1');
      expect(queries.lastFindMaxOrderTripId, 'trip-1');
      expect(queries.lastFindMaxOrderDayNumber, 4);
      expect(queries.lastUpdateByIdItemId, 'item-1');
      expect(queries.lastUpdateByIdData, {
        'day_number': 4,
        'order_index': 6,
        'updated_at': fixedClock.toIso8601String(),
      });
    });

    test('uses 0 as max when target day is empty', () async {
      queries.findItemByIdResponse = fullRow(id: 'item-1', tripId: 'trip-1');
      queries.findMaxOrderResponse = const [];

      await ds.moveItemToDay(itemId: 'item-1', newDayNumber: 7);

      expect(queries.lastUpdateByIdData!['order_index'], 1);
      expect(queries.lastUpdateByIdData!['day_number'], 7);
    });

    test('treats null order_index in returned row as 0', () async {
      queries.findItemByIdResponse = fullRow(id: 'item-1', tripId: 'trip-1');
      queries.findMaxOrderResponse = [
        {'order_index': null},
      ];

      await ds.moveItemToDay(itemId: 'item-1', newDayNumber: 3);

      expect(queries.lastUpdateByIdData!['order_index'], 1);
    });

    test('wraps errors raised by getItem', () async {
      queries.throwOnFindById = Exception('boom');
      await expectLater(
        ds.moveItemToDay(itemId: 'x', newDayNumber: 1),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to move item to day'))),
      );
    });

    test('wraps errors raised by max-order lookup', () async {
      queries.findItemByIdResponse = fullRow(id: 'item-1', tripId: 'trip-1');
      queries.throwOnFindMaxOrder = Exception('boom');
      await expectLater(
        ds.moveItemToDay(itemId: 'item-1', newDayNumber: 1),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to move item to day'))),
      );
    });

    test('wraps errors raised by final update', () async {
      queries.findItemByIdResponse = fullRow(id: 'item-1', tripId: 'trip-1');
      queries.findMaxOrderResponse = const [];
      queries.throwOnUpdateById = Exception('boom');
      await expectLater(
        ds.moveItemToDay(itemId: 'item-1', newDayNumber: 1),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to move item to day'))),
      );
    });
  });
}
