import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/features/checklists/data/datasources/checklist_queries.dart';
import 'package:pathio/features/checklists/data/datasources/checklist_remote_datasource.dart';
import 'package:pathio/shared/models/checklist_model.dart';

/// Comprehensive unit tests for [ChecklistRemoteDataSource].
///
/// All Supabase chain calls go through [ChecklistQueries] which is faked
/// here. We exercise every public method on both the happy path AND the
/// error path, asserting both the args passed and the model returned.

class _FakeQueries implements ChecklistQueries {
  // Last-call recordings
  String? lastFindChecklistsTripId;
  String? lastFindChecklistByIdMaybeId;
  String? lastFindItemsChecklistId;
  Map<String, dynamic>? lastUpsertChecklistData;
  Map<String, dynamic>? lastUpsertItemData;
  String? lastDeleteChecklistId;
  String? lastDeleteItemId;
  String? lastUpdateItemId;
  Map<String, dynamic>? lastUpdateItemData;

  // Canned responses
  List<Map<String, dynamic>> findChecklistsForTripResponse = const [];
  Map<String, dynamic>? findChecklistByIdMaybeResponse;
  bool _returnNullForChecklistMaybe = false;
  List<Map<String, dynamic>> findItemsForChecklistResponse = const [];
  Map<String, dynamic>? upsertChecklistResponse;
  Map<String, dynamic>? upsertItemResponse;
  Map<String, dynamic>? updateItemResponse;

  // Throw-on-call configurators
  Object? throwOnFindChecklistsForTrip;
  Object? throwOnFindChecklistByIdMaybe;
  Object? throwOnFindItemsForChecklist;
  Object? throwOnUpsertChecklist;
  Object? throwOnUpsertItem;
  Object? throwOnDeleteChecklist;
  Object? throwOnDeleteItem;
  Object? throwOnUpdateItem;

  void setChecklistMaybeReturnNull() => _returnNullForChecklistMaybe = true;

  @override
  Future<List<Map<String, dynamic>>> findChecklistsForTrip(
      String tripId) async {
    if (throwOnFindChecklistsForTrip != null) {
      throw throwOnFindChecklistsForTrip!;
    }
    lastFindChecklistsTripId = tripId;
    return findChecklistsForTripResponse;
  }

  @override
  Future<Map<String, dynamic>?> findChecklistByIdMaybe(
      String checklistId) async {
    if (throwOnFindChecklistByIdMaybe != null) {
      throw throwOnFindChecklistByIdMaybe!;
    }
    lastFindChecklistByIdMaybeId = checklistId;
    if (_returnNullForChecklistMaybe) return null;
    return findChecklistByIdMaybeResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findItemsForChecklist(
      String checklistId) async {
    if (throwOnFindItemsForChecklist != null) {
      throw throwOnFindItemsForChecklist!;
    }
    lastFindItemsChecklistId = checklistId;
    return findItemsForChecklistResponse;
  }

  @override
  Future<Map<String, dynamic>> upsertChecklist(
      Map<String, dynamic> data) async {
    if (throwOnUpsertChecklist != null) throw throwOnUpsertChecklist!;
    lastUpsertChecklistData = data;
    return upsertChecklistResponse ?? data;
  }

  @override
  Future<Map<String, dynamic>> upsertChecklistItem(
      Map<String, dynamic> data) async {
    if (throwOnUpsertItem != null) throw throwOnUpsertItem!;
    lastUpsertItemData = data;
    return upsertItemResponse ?? data;
  }

  @override
  Future<void> deleteChecklistById(String checklistId) async {
    if (throwOnDeleteChecklist != null) throw throwOnDeleteChecklist!;
    lastDeleteChecklistId = checklistId;
  }

  @override
  Future<void> deleteChecklistItemById(String itemId) async {
    if (throwOnDeleteItem != null) throw throwOnDeleteItem!;
    lastDeleteItemId = itemId;
  }

  @override
  Future<Map<String, dynamic>> updateChecklistItemById(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    if (throwOnUpdateItem != null) throw throwOnUpdateItem!;
    lastUpdateItemId = itemId;
    lastUpdateItemData = updates;
    return updateItemResponse ?? updates;
  }
}

void main() {
  late _FakeQueries queries;
  late ChecklistRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  setUp(() {
    queries = _FakeQueries();
    ds = ChecklistRemoteDataSource(
      queries: queries,
      clock: () => fixedClock,
    );
  });

  Map<String, dynamic> sampleChecklistJson({
    String id = 'cl-1',
    String tripId = 't-1',
    String name = 'Packing List',
  }) {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'created_by': 'u-1',
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
    };
  }

  Map<String, dynamic> sampleItemJson({
    String id = 'it-1',
    String checklistId = 'cl-1',
    String title = 'Passport',
    bool isCompleted = false,
  }) {
    return {
      'id': id,
      'checklist_id': checklistId,
      'title': title,
      'is_completed': isCompleted,
      'order_index': 0,
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
    };
  }

  group('getTripChecklists', () {
    test('returns mapped models from queries', () async {
      queries.findChecklistsForTripResponse = [
        sampleChecklistJson(id: 'cl-1'),
        sampleChecklistJson(id: 'cl-2', name: 'Things to do'),
      ];

      final result = await ds.getTripChecklists('t-1');
      expect(queries.lastFindChecklistsTripId, 't-1');
      expect(result, hasLength(2));
      expect(result[0].id, 'cl-1');
      expect(result[1].name, 'Things to do');
    });

    test('returns empty list when query returns empty', () async {
      queries.findChecklistsForTripResponse = const [];
      final result = await ds.getTripChecklists('t-9');
      expect(result, isEmpty);
    });

    test('wraps query errors with "Failed to fetch trip checklists"',
        () async {
      queries.throwOnFindChecklistsForTrip = Exception('boom');
      await expectLater(
        ds.getTripChecklists('t'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch trip checklists'),
        )),
      );
    });
  });

  group('getChecklist', () {
    test('returns null when query returns null', () async {
      queries.setChecklistMaybeReturnNull();
      final result = await ds.getChecklist('cl-1');
      expect(result, isNull);
      expect(queries.lastFindChecklistByIdMaybeId, 'cl-1');
    });

    test('returns parsed model when found', () async {
      queries.findChecklistByIdMaybeResponse = sampleChecklistJson();
      final result = await ds.getChecklist('cl-1');
      expect(result, isNotNull);
      expect(result!.id, 'cl-1');
      expect(result.name, 'Packing List');
    });

    test('wraps query errors', () async {
      queries.throwOnFindChecklistByIdMaybe = Exception('boom');
      await expectLater(
        ds.getChecklist('cl-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch checklist'),
        )),
      );
    });
  });

  group('getChecklistItems', () {
    test('returns mapped models from queries', () async {
      queries.findItemsForChecklistResponse = [
        sampleItemJson(id: 'it-1', title: 'Passport'),
        sampleItemJson(id: 'it-2', title: 'Sunscreen'),
      ];
      final result = await ds.getChecklistItems('cl-1');
      expect(queries.lastFindItemsChecklistId, 'cl-1');
      expect(result, hasLength(2));
      expect(result[0].title, 'Passport');
      expect(result[1].title, 'Sunscreen');
    });

    test('returns empty list', () async {
      queries.findItemsForChecklistResponse = const [];
      final result = await ds.getChecklistItems('cl-1');
      expect(result, isEmpty);
    });

    test('wraps query errors', () async {
      queries.throwOnFindItemsForChecklist = Exception('boom');
      await expectLater(
        ds.getChecklistItems('cl-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to fetch checklist items'),
        )),
      );
    });
  });

  group('upsertChecklist', () {
    test('uses toDatabaseJson (excludes creator_name) and returns parsed model',
        () async {
      final input = ChecklistModel(
        id: 'cl-1',
        tripId: 't-1',
        name: 'Packing',
        createdBy: 'u-1',
        createdAt: fixedClock,
        updatedAt: fixedClock,
        creatorName: 'Should NOT be sent',
      );
      queries.upsertChecklistResponse = sampleChecklistJson();

      final result = await ds.upsertChecklist(input);

      expect(queries.lastUpsertChecklistData, isNotNull);
      expect(queries.lastUpsertChecklistData!['id'], 'cl-1');
      expect(queries.lastUpsertChecklistData!['name'], 'Packing');
      expect(queries.lastUpsertChecklistData!['trip_id'], 't-1');
      expect(queries.lastUpsertChecklistData!.containsKey('creator_name'),
          isFalse);
      expect(result.id, 'cl-1');
    });

    test('wraps query errors', () async {
      queries.throwOnUpsertChecklist = Exception('boom');
      final input = ChecklistModel(
        id: 'cl-1',
        tripId: 't-1',
        name: 'X',
        createdAt: fixedClock,
      );
      await expectLater(
        ds.upsertChecklist(input),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to upsert checklist'),
        )),
      );
    });
  });

  group('upsertChecklistItem', () {
    test('uses toDatabaseJson (excludes joined fields) and returns model',
        () async {
      final input = ChecklistItemModel(
        id: 'it-1',
        checklistId: 'cl-1',
        title: 'Passport',
        isCompleted: false,
        assignedToName: 'Should NOT be sent',
        completedByName: 'Also NOT sent',
        createdAt: fixedClock,
        updatedAt: fixedClock,
      );
      queries.upsertItemResponse = sampleItemJson();

      final result = await ds.upsertChecklistItem(input);

      expect(queries.lastUpsertItemData, isNotNull);
      expect(queries.lastUpsertItemData!['id'], 'it-1');
      expect(queries.lastUpsertItemData!['title'], 'Passport');
      expect(queries.lastUpsertItemData!.containsKey('assigned_to_name'),
          isFalse);
      expect(queries.lastUpsertItemData!.containsKey('completed_by_name'),
          isFalse);
      expect(result.id, 'it-1');
    });

    test('wraps query errors', () async {
      queries.throwOnUpsertItem = Exception('boom');
      final input = ChecklistItemModel(
        id: 'it-1',
        checklistId: 'cl-1',
        title: 'X',
      );
      await expectLater(
        ds.upsertChecklistItem(input),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to upsert checklist item'),
        )),
      );
    });
  });

  group('deleteChecklist', () {
    test('forwards id to queries', () async {
      await ds.deleteChecklist('cl-1');
      expect(queries.lastDeleteChecklistId, 'cl-1');
    });

    test('wraps query errors', () async {
      queries.throwOnDeleteChecklist = Exception('boom');
      await expectLater(
        ds.deleteChecklist('cl-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to delete checklist'),
        )),
      );
    });
  });

  group('deleteChecklistItem', () {
    test('forwards id to queries', () async {
      await ds.deleteChecklistItem('it-1');
      expect(queries.lastDeleteItemId, 'it-1');
    });

    test('wraps query errors', () async {
      queries.throwOnDeleteItem = Exception('boom');
      await expectLater(
        ds.deleteChecklistItem('it-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to delete checklist item'),
        )),
      );
    });
  });

  group('toggleItemCompletion', () {
    test('marks completed: sets is_completed, completed_by, completed_at',
        () async {
      queries.updateItemResponse = sampleItemJson(isCompleted: true);

      final result = await ds.toggleItemCompletion(
        itemId: 'it-1',
        isCompleted: true,
        userId: 'u-9',
      );

      expect(queries.lastUpdateItemId, 'it-1');
      expect(queries.lastUpdateItemData!['is_completed'], isTrue);
      expect(queries.lastUpdateItemData!['completed_by'], 'u-9');
      expect(queries.lastUpdateItemData!['completed_at'],
          fixedClock.toIso8601String());
      expect(queries.lastUpdateItemData!['updated_at'],
          fixedClock.toIso8601String());
      expect(result.id, 'it-1');
    });

    test('marks uncompleted: completed_by and completed_at are null',
        () async {
      queries.updateItemResponse = sampleItemJson(isCompleted: false);

      await ds.toggleItemCompletion(
        itemId: 'it-1',
        isCompleted: false,
        userId: 'u-9',
      );

      expect(queries.lastUpdateItemData!['is_completed'], isFalse);
      expect(queries.lastUpdateItemData!['completed_by'], isNull);
      expect(queries.lastUpdateItemData!['completed_at'], isNull);
      // updated_at is always set
      expect(queries.lastUpdateItemData!['updated_at'],
          fixedClock.toIso8601String());
    });

    test('wraps query errors', () async {
      queries.throwOnUpdateItem = Exception('boom');
      await expectLater(
        ds.toggleItemCompletion(
          itemId: 'it-1',
          isCompleted: true,
          userId: 'u',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to toggle item completion'),
        )),
      );
    });
  });
}
