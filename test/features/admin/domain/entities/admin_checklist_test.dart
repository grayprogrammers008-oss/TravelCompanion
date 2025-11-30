import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_checklist.dart';

void main() {
  group('AdminChecklistModel', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        const checklist = AdminChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          tripName: 'Beach Vacation',
          name: 'Packing List',
        );

        expect(checklist.id, 'checklist-1');
        expect(checklist.tripId, 'trip-1');
        expect(checklist.tripName, 'Beach Vacation');
        expect(checklist.name, 'Packing List');
        expect(checklist.itemCount, 0);
        expect(checklist.completedCount, 0);
        expect(checklist.pendingCount, 0);
      });

      test('should create instance with all fields', () {
        final now = DateTime.now();
        final checklist = AdminChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          tripName: 'Beach Vacation',
          tripDestination: 'Goa',
          name: 'Packing List',
          createdBy: 'user-1',
          creatorName: 'John Doe',
          creatorEmail: 'john@example.com',
          createdAt: now,
          updatedAt: now,
          itemCount: 10,
          completedCount: 5,
          pendingCount: 5,
        );

        expect(checklist.tripDestination, 'Goa');
        expect(checklist.createdBy, 'user-1');
        expect(checklist.creatorName, 'John Doe');
        expect(checklist.creatorEmail, 'john@example.com');
        expect(checklist.createdAt, now);
        expect(checklist.updatedAt, now);
        expect(checklist.itemCount, 10);
        expect(checklist.completedCount, 5);
        expect(checklist.pendingCount, 5);
      });
    });

    group('completionPercentage', () {
      test('should return 0 when itemCount is 0', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 0,
          completedCount: 0,
        );
        expect(checklist.completionPercentage, 0.0);
      });

      test('should return 50 when half completed', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 10,
          completedCount: 5,
        );
        expect(checklist.completionPercentage, 50.0);
      });

      test('should return 100 when all completed', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 10,
          completedCount: 10,
        );
        expect(checklist.completionPercentage, 100.0);
      });

      test('should handle fractional percentages', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 3,
          completedCount: 1,
        );
        expect(checklist.completionPercentage, closeTo(33.33, 0.01));
      });
    });

    group('isFullyCompleted', () {
      test('should return true when all items completed', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 5,
          completedCount: 5,
        );
        expect(checklist.isFullyCompleted, true);
      });

      test('should return false when not all completed', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 5,
          completedCount: 3,
        );
        expect(checklist.isFullyCompleted, false);
      });

      test('should return false when empty', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 0,
          completedCount: 0,
        );
        expect(checklist.isFullyCompleted, false);
      });
    });

    group('isEmpty', () {
      test('should return true when itemCount is 0', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 0,
        );
        expect(checklist.isEmpty, true);
      });

      test('should return false when itemCount > 0', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          itemCount: 5,
        );
        expect(checklist.isEmpty, false);
      });
    });

    group('hasPendingItems', () {
      test('should return true when pendingCount > 0', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          pendingCount: 3,
        );
        expect(checklist.hasPendingItems, true);
      });

      test('should return false when pendingCount is 0', () {
        const checklist = AdminChecklistModel(
          id: '1',
          tripId: '1',
          tripName: 'Trip',
          name: 'List',
          pendingCount: 0,
        );
        expect(checklist.hasPendingItems, false);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'checklist-1',
          'trip_id': 'trip-1',
          'trip_name': 'Beach Vacation',
          'trip_destination': 'Goa',
          'name': 'Packing List',
          'created_by': 'user-1',
          'creator_name': 'John Doe',
          'creator_email': 'john@example.com',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
          'item_count': 10,
          'completed_count': 5,
          'pending_count': 5,
        };

        final checklist = AdminChecklistModel.fromJson(json);

        expect(checklist.id, 'checklist-1');
        expect(checklist.tripId, 'trip-1');
        expect(checklist.tripName, 'Beach Vacation');
        expect(checklist.tripDestination, 'Goa');
        expect(checklist.name, 'Packing List');
        expect(checklist.createdBy, 'user-1');
        expect(checklist.creatorName, 'John Doe');
        expect(checklist.creatorEmail, 'john@example.com');
        expect(checklist.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(checklist.updatedAt, DateTime.parse('2024-01-16T10:30:00.000Z'));
        expect(checklist.itemCount, 10);
        expect(checklist.completedCount, 5);
        expect(checklist.pendingCount, 5);
      });

      test('should handle null id with empty string', () {
        final json = {
          'id': null,
          'trip_id': 'trip-1',
          'trip_name': 'Trip',
          'name': 'List',
        };

        final checklist = AdminChecklistModel.fromJson(json);
        expect(checklist.id, '');
      });

      test('should handle null trip_name with default', () {
        final json = {
          'id': '1',
          'trip_id': 'trip-1',
          'trip_name': null,
          'name': 'List',
        };

        final checklist = AdminChecklistModel.fromJson(json);
        expect(checklist.tripName, 'Unknown Trip');
      });

      test('should handle null name with default', () {
        final json = {
          'id': '1',
          'trip_id': 'trip-1',
          'trip_name': 'Trip',
          'name': null,
        };

        final checklist = AdminChecklistModel.fromJson(json);
        expect(checklist.name, 'Unnamed Checklist');
      });

      test('should handle missing counts with 0', () {
        final json = {
          'id': '1',
          'trip_id': 'trip-1',
          'trip_name': 'Trip',
          'name': 'List',
        };

        final checklist = AdminChecklistModel.fromJson(json);
        expect(checklist.itemCount, 0);
        expect(checklist.completedCount, 0);
        expect(checklist.pendingCount, 0);
      });

      test('should handle invalid date strings', () {
        final json = {
          'id': '1',
          'trip_id': 'trip-1',
          'trip_name': 'Trip',
          'name': 'List',
          'created_at': 'invalid-date',
          'updated_at': 'also-invalid',
        };

        final checklist = AdminChecklistModel.fromJson(json);
        expect(checklist.createdAt, isNull);
        expect(checklist.updatedAt, isNull);
      });

      test('should handle numeric counts as num', () {
        final json = {
          'id': '1',
          'trip_id': 'trip-1',
          'trip_name': 'Trip',
          'name': 'List',
          'item_count': 10.0,
          'completed_count': 5.0,
          'pending_count': 5.0,
        };

        final checklist = AdminChecklistModel.fromJson(json);
        expect(checklist.itemCount, 10);
        expect(checklist.completedCount, 5);
        expect(checklist.pendingCount, 5);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final checklist = AdminChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          tripName: 'Beach Vacation',
          tripDestination: 'Goa',
          name: 'Packing List',
          createdBy: 'user-1',
          creatorName: 'John Doe',
          creatorEmail: 'john@example.com',
          createdAt: DateTime(2024, 1, 15, 10, 30),
          updatedAt: DateTime(2024, 1, 16, 10, 30),
          itemCount: 10,
          completedCount: 5,
          pendingCount: 5,
        );

        final json = checklist.toJson();

        expect(json['id'], 'checklist-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['trip_name'], 'Beach Vacation');
        expect(json['trip_destination'], 'Goa');
        expect(json['name'], 'Packing List');
        expect(json['created_by'], 'user-1');
        expect(json['creator_name'], 'John Doe');
        expect(json['creator_email'], 'john@example.com');
        expect(json['item_count'], 10);
        expect(json['completed_count'], 5);
        expect(json['pending_count'], 5);
      });

      test('should handle null optional fields', () {
        const checklist = AdminChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          tripName: 'Trip',
          name: 'List',
        );

        final json = checklist.toJson();

        expect(json['trip_destination'], isNull);
        expect(json['created_by'], isNull);
        expect(json['creator_name'], isNull);
        expect(json['creator_email'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = AdminChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          tripName: 'Original Trip',
          name: 'Original List',
          itemCount: 5,
        );

        final copied = original.copyWith(
          tripName: 'Updated Trip',
          name: 'Updated List',
          itemCount: 10,
        );

        expect(copied.id, 'checklist-1');
        expect(copied.tripId, 'trip-1');
        expect(copied.tripName, 'Updated Trip');
        expect(copied.name, 'Updated List');
        expect(copied.itemCount, 10);
      });

      test('should keep original values when not specified', () {
        final original = AdminChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          tripName: 'Trip',
          tripDestination: 'Goa',
          name: 'List',
          createdBy: 'user-1',
          creatorName: 'John',
          creatorEmail: 'john@example.com',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 16),
          itemCount: 10,
          completedCount: 5,
          pendingCount: 5,
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.tripId, original.tripId);
        expect(copied.tripName, original.tripName);
        expect(copied.tripDestination, original.tripDestination);
        expect(copied.name, original.name);
        expect(copied.createdBy, original.createdBy);
        expect(copied.creatorName, original.creatorName);
        expect(copied.creatorEmail, original.creatorEmail);
        expect(copied.createdAt, original.createdAt);
        expect(copied.updatedAt, original.updatedAt);
        expect(copied.itemCount, original.itemCount);
        expect(copied.completedCount, original.completedCount);
        expect(copied.pendingCount, original.pendingCount);
      });
    });
  });

  group('ChecklistListParams', () {
    group('constructor', () {
      test('should create with default values', () {
        const params = ChecklistListParams();
        expect(params.limit, 50);
        expect(params.offset, 0);
        expect(params.search, isNull);
        expect(params.status, isNull);
        expect(params.tripId, isNull);
      });

      test('should create with specified values', () {
        const params = ChecklistListParams(
          limit: 20,
          offset: 10,
          search: 'packing',
          status: 'completed',
          tripId: 'trip-1',
        );
        expect(params.limit, 20);
        expect(params.offset, 10);
        expect(params.search, 'packing');
        expect(params.status, 'completed');
        expect(params.tripId, 'trip-1');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        const params1 = ChecklistListParams(limit: 20, search: 'test');
        const params2 = ChecklistListParams(limit: 20, search: 'test');
        expect(params1, equals(params2));
      });

      test('should not be equal when different values', () {
        const params1 = ChecklistListParams(limit: 20, search: 'test');
        const params2 = ChecklistListParams(limit: 30, search: 'test');
        expect(params1, isNot(equals(params2)));
      });

      test('should be identical to itself', () {
        const params = ChecklistListParams(limit: 20);
        expect(params == params, true);
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal objects', () {
        const params1 = ChecklistListParams(limit: 20, status: 'completed');
        const params2 = ChecklistListParams(limit: 20, status: 'completed');
        expect(params1.hashCode, equals(params2.hashCode));
      });
    });
  });

  group('AdminChecklistStatsModel', () {
    group('constructor', () {
      test('should create with default values', () {
        const stats = AdminChecklistStatsModel();
        expect(stats.totalChecklists, 0);
        expect(stats.totalItems, 0);
        expect(stats.completedItems, 0);
        expect(stats.pendingItems, 0);
        expect(stats.completionRate, 0.0);
        expect(stats.checklistsWithAllCompleted, 0);
        expect(stats.emptyChecklists, 0);
      });

      test('should create with specified values', () {
        const stats = AdminChecklistStatsModel(
          totalChecklists: 100,
          totalItems: 500,
          completedItems: 300,
          pendingItems: 200,
          completionRate: 60.0,
          checklistsWithAllCompleted: 40,
          emptyChecklists: 10,
        );
        expect(stats.totalChecklists, 100);
        expect(stats.totalItems, 500);
        expect(stats.completedItems, 300);
        expect(stats.pendingItems, 200);
        expect(stats.completionRate, 60.0);
        expect(stats.checklistsWithAllCompleted, 40);
        expect(stats.emptyChecklists, 10);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'total_checklists': 100,
          'total_items': 500,
          'completed_items': 300,
          'pending_items': 200,
          'completion_rate': 60.0,
          'checklists_with_all_completed': 40,
          'empty_checklists': 10,
        };

        final stats = AdminChecklistStatsModel.fromJson(json);

        expect(stats.totalChecklists, 100);
        expect(stats.totalItems, 500);
        expect(stats.completedItems, 300);
        expect(stats.pendingItems, 200);
        expect(stats.completionRate, 60.0);
        expect(stats.checklistsWithAllCompleted, 40);
        expect(stats.emptyChecklists, 10);
      });

      test('should handle null values with defaults', () {
        final json = <String, dynamic>{};

        final stats = AdminChecklistStatsModel.fromJson(json);

        expect(stats.totalChecklists, 0);
        expect(stats.totalItems, 0);
        expect(stats.completedItems, 0);
        expect(stats.pendingItems, 0);
        expect(stats.completionRate, 0.0);
        expect(stats.checklistsWithAllCompleted, 0);
        expect(stats.emptyChecklists, 0);
      });

      test('should handle numeric values as int', () {
        final json = {
          'total_checklists': 100.0,
          'total_items': 500.0,
          'completed_items': 300.0,
          'pending_items': 200.0,
          'completion_rate': 60.5,
          'checklists_with_all_completed': 40.0,
          'empty_checklists': 10.0,
        };

        final stats = AdminChecklistStatsModel.fromJson(json);

        expect(stats.totalChecklists, 100);
        expect(stats.totalItems, 500);
        expect(stats.completedItems, 300);
        expect(stats.pendingItems, 200);
        expect(stats.completionRate, 60.5);
        expect(stats.checklistsWithAllCompleted, 40);
        expect(stats.emptyChecklists, 10);
      });
    });
  });
}
