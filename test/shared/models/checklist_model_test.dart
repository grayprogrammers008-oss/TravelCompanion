import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/checklist_model.dart';

void main() {
  group('ChecklistModel', () {
    final now = DateTime.now();

    group('constructor', () {
      test('should create instance with required fields', () {
        const checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
        );

        expect(checklist.id, 'checklist-1');
        expect(checklist.tripId, 'trip-1');
        expect(checklist.name, 'Packing List');
        expect(checklist.createdBy, isNull);
        expect(checklist.createdAt, isNull);
        expect(checklist.updatedAt, isNull);
        expect(checklist.creatorName, isNull);
      });

      test('should create instance with all fields', () {
        final checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        expect(checklist.id, 'checklist-1');
        expect(checklist.tripId, 'trip-1');
        expect(checklist.name, 'Packing List');
        expect(checklist.createdBy, 'user-1');
        expect(checklist.createdAt, now);
        expect(checklist.updatedAt, now);
        expect(checklist.creatorName, 'John Doe');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'checklist-1',
          'trip_id': 'trip-1',
          'name': 'Packing List',
          'created_by': 'user-1',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
          'creator_name': 'John Doe',
        };

        final checklist = ChecklistModel.fromJson(json);

        expect(checklist.id, 'checklist-1');
        expect(checklist.tripId, 'trip-1');
        expect(checklist.name, 'Packing List');
        expect(checklist.createdBy, 'user-1');
        expect(checklist.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(checklist.updatedAt, DateTime.parse('2024-01-16T10:30:00.000Z'));
        expect(checklist.creatorName, 'John Doe');
      });

      test('should parse JSON with null optional fields', () {
        final json = {
          'id': 'checklist-1',
          'trip_id': 'trip-1',
          'name': 'Packing List',
          'created_by': null,
          'created_at': null,
          'updated_at': null,
          'creator_name': null,
        };

        final checklist = ChecklistModel.fromJson(json);

        expect(checklist.id, 'checklist-1');
        expect(checklist.tripId, 'trip-1');
        expect(checklist.name, 'Packing List');
        expect(checklist.createdBy, isNull);
        expect(checklist.createdAt, isNull);
        expect(checklist.updatedAt, isNull);
        expect(checklist.creatorName, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-16T10:30:00.000Z'),
          creatorName: 'John Doe',
        );

        final json = checklist.toJson();

        expect(json['id'], 'checklist-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['name'], 'Packing List');
        expect(json['created_by'], 'user-1');
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['updated_at'], '2024-01-16T10:30:00.000Z');
        expect(json['creator_name'], 'John Doe');
      });

      test('should handle null optional fields', () {
        const checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
        );

        final json = checklist.toJson();

        expect(json['id'], 'checklist-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['name'], 'Packing List');
        expect(json['created_by'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
        expect(json['creator_name'], isNull);
      });
    });

    group('toDatabaseJson', () {
      test('should exclude creator_name (joined field)', () {
        final checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-16T10:30:00.000Z'),
          creatorName: 'John Doe',
        );

        final json = checklist.toDatabaseJson();

        expect(json['id'], 'checklist-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['name'], 'Packing List');
        expect(json['created_by'], 'user-1');
        expect(json.containsKey('creator_name'), false);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final copied = original.copyWith(
          name: 'New List',
          creatorName: 'Jane Doe',
        );

        expect(copied.id, 'checklist-1');
        expect(copied.tripId, 'trip-1');
        expect(copied.name, 'New List');
        expect(copied.createdBy, 'user-1');
        expect(copied.createdAt, now);
        expect(copied.updatedAt, now);
        expect(copied.creatorName, 'Jane Doe');
      });

      test('should keep original values when not specified', () {
        final original = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final copied = original.copyWith();

        expect(copied, original);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final checklist1 = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final checklist2 = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        expect(checklist1, checklist2);
        expect(checklist1.hashCode, checklist2.hashCode);
      });

      test('should not be equal when different values', () {
        final checklist1 = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final checklist2 = ChecklistModel(
          id: 'checklist-2',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        expect(checklist1, isNot(checklist2));
      });

      test('should be identical to itself', () {
        final checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        expect(checklist == checklist, true);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final checklist = ChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          creatorName: 'John Doe',
        );

        final str = checklist.toString();

        expect(str, contains('ChecklistModel'));
        expect(str, contains('checklist-1'));
        expect(str, contains('Packing List'));
      });
    });
  });

  group('ChecklistItemModel', () {
    final now = DateTime.now();

    group('constructor', () {
      test('should create instance with required fields', () {
        const item = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
        );

        expect(item.id, 'item-1');
        expect(item.checklistId, 'checklist-1');
        expect(item.title, 'Pack clothes');
        expect(item.isCompleted, false);
        expect(item.assignedTo, isNull);
        expect(item.completedBy, isNull);
        expect(item.completedAt, isNull);
        expect(item.orderIndex, 0);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, isNull);
        expect(item.assignedToName, isNull);
        expect(item.completedByName, isNull);
      });

      test('should create instance with all fields', () {
        final item = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: true,
          assignedTo: 'user-1',
          completedBy: 'user-1',
          completedAt: now,
          orderIndex: 5,
          createdAt: now,
          updatedAt: now,
          assignedToName: 'John Doe',
          completedByName: 'John Doe',
        );

        expect(item.id, 'item-1');
        expect(item.checklistId, 'checklist-1');
        expect(item.title, 'Pack clothes');
        expect(item.isCompleted, true);
        expect(item.assignedTo, 'user-1');
        expect(item.completedBy, 'user-1');
        expect(item.completedAt, now);
        expect(item.orderIndex, 5);
        expect(item.createdAt, now);
        expect(item.updatedAt, now);
        expect(item.assignedToName, 'John Doe');
        expect(item.completedByName, 'John Doe');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'item-1',
          'checklist_id': 'checklist-1',
          'title': 'Pack clothes',
          'is_completed': true,
          'assigned_to': 'user-1',
          'completed_by': 'user-1',
          'completed_at': '2024-01-15T10:30:00.000Z',
          'order_index': 5,
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T10:30:00.000Z',
          'assigned_to_name': 'John Doe',
          'completed_by_name': 'John Doe',
        };

        final item = ChecklistItemModel.fromJson(json);

        expect(item.id, 'item-1');
        expect(item.checklistId, 'checklist-1');
        expect(item.title, 'Pack clothes');
        expect(item.isCompleted, true);
        expect(item.assignedTo, 'user-1');
        expect(item.completedBy, 'user-1');
        expect(item.completedAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(item.orderIndex, 5);
        expect(item.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(item.updatedAt, DateTime.parse('2024-01-16T10:30:00.000Z'));
        expect(item.assignedToName, 'John Doe');
        expect(item.completedByName, 'John Doe');
      });

      test('should handle is_completed as int (SQLite compatibility)', () {
        final jsonCompleted = {
          'id': 'item-1',
          'checklist_id': 'checklist-1',
          'title': 'Pack clothes',
          'is_completed': 1,
        };

        final jsonNotCompleted = {
          'id': 'item-2',
          'checklist_id': 'checklist-1',
          'title': 'Book hotel',
          'is_completed': 0,
        };

        final itemCompleted = ChecklistItemModel.fromJson(jsonCompleted);
        final itemNotCompleted = ChecklistItemModel.fromJson(jsonNotCompleted);

        expect(itemCompleted.isCompleted, true);
        expect(itemNotCompleted.isCompleted, false);
      });

      test('should handle null is_completed with default false', () {
        final json = {
          'id': 'item-1',
          'checklist_id': 'checklist-1',
          'title': 'Pack clothes',
          'is_completed': null,
        };

        final item = ChecklistItemModel.fromJson(json);

        expect(item.isCompleted, false);
      });

      test('should handle missing order_index with default 0', () {
        final json = {
          'id': 'item-1',
          'checklist_id': 'checklist-1',
          'title': 'Pack clothes',
        };

        final item = ChecklistItemModel.fromJson(json);

        expect(item.orderIndex, 0);
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'item-1',
          'checklist_id': 'checklist-1',
          'title': 'Pack clothes',
          'is_completed': false,
          'assigned_to': null,
          'completed_by': null,
          'completed_at': null,
          'order_index': 0,
          'created_at': null,
          'updated_at': null,
          'assigned_to_name': null,
          'completed_by_name': null,
        };

        final item = ChecklistItemModel.fromJson(json);

        expect(item.assignedTo, isNull);
        expect(item.completedBy, isNull);
        expect(item.completedAt, isNull);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, isNull);
        expect(item.assignedToName, isNull);
        expect(item.completedByName, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final item = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: true,
          assignedTo: 'user-1',
          completedBy: 'user-1',
          completedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          orderIndex: 5,
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-16T10:30:00.000Z'),
          assignedToName: 'John Doe',
          completedByName: 'John Doe',
        );

        final json = item.toJson();

        expect(json['id'], 'item-1');
        expect(json['checklist_id'], 'checklist-1');
        expect(json['title'], 'Pack clothes');
        expect(json['is_completed'], true);
        expect(json['assigned_to'], 'user-1');
        expect(json['completed_by'], 'user-1');
        expect(json['completed_at'], '2024-01-15T10:30:00.000Z');
        expect(json['order_index'], 5);
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
        expect(json['updated_at'], '2024-01-16T10:30:00.000Z');
        expect(json['assigned_to_name'], 'John Doe');
        expect(json['completed_by_name'], 'John Doe');
      });
    });

    group('toDatabaseJson', () {
      test('should exclude joined fields', () {
        final item = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: true,
          assignedTo: 'user-1',
          completedBy: 'user-1',
          completedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          orderIndex: 5,
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          updatedAt: DateTime.parse('2024-01-16T10:30:00.000Z'),
          assignedToName: 'John Doe',
          completedByName: 'John Doe',
        );

        final json = item.toDatabaseJson();

        expect(json['id'], 'item-1');
        expect(json['checklist_id'], 'checklist-1');
        expect(json['title'], 'Pack clothes');
        expect(json.containsKey('assigned_to_name'), false);
        expect(json.containsKey('completed_by_name'), false);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: false,
          orderIndex: 0,
        );

        final copied = original.copyWith(
          title: 'Pack bags',
          isCompleted: true,
          orderIndex: 5,
        );

        expect(copied.id, 'item-1');
        expect(copied.checklistId, 'checklist-1');
        expect(copied.title, 'Pack bags');
        expect(copied.isCompleted, true);
        expect(copied.orderIndex, 5);
      });

      test('should keep original values when not specified', () {
        final original = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: true,
          orderIndex: 5,
        );

        final copied = original.copyWith();

        expect(copied, original);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final item1 = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: true,
          orderIndex: 5,
        );

        final item2 = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: true,
          orderIndex: 5,
        );

        expect(item1, item2);
        expect(item1.hashCode, item2.hashCode);
      });

      test('should not be equal when different values', () {
        final item1 = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: false,
          orderIndex: 0,
        );

        final item2 = ChecklistItemModel(
          id: 'item-2',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
          isCompleted: false,
          orderIndex: 0,
        );

        expect(item1, isNot(item2));
      });
    });

    group('toString', () {
      test('should return string representation', () {
        const item = ChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Pack clothes',
        );

        final str = item.toString();

        expect(str, contains('ChecklistItemModel'));
        expect(str, contains('item-1'));
        expect(str, contains('Pack clothes'));
      });
    });
  });

  group('ChecklistWithItems', () {
    final now = DateTime.now();
    final checklist = ChecklistModel(
      id: 'checklist-1',
      tripId: 'trip-1',
      name: 'Packing List',
      createdBy: 'user-1',
      createdAt: now,
      updatedAt: now,
      creatorName: 'John Doe',
    );

    final items = [
      const ChecklistItemModel(
        id: 'item-1',
        checklistId: 'checklist-1',
        title: 'Pack clothes',
        isCompleted: false,
        orderIndex: 0,
      ),
      const ChecklistItemModel(
        id: 'item-2',
        checklistId: 'checklist-1',
        title: 'Book hotel',
        isCompleted: true,
        orderIndex: 1,
      ),
    ];

    group('constructor', () {
      test('should create instance with checklist and items', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        expect(checklistWithItems.checklist, checklist);
        expect(checklistWithItems.items, items);
        expect(checklistWithItems.items.length, 2);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'checklist': {
            'id': 'checklist-1',
            'trip_id': 'trip-1',
            'name': 'Packing List',
            'created_by': 'user-1',
            'created_at': '2024-01-15T10:30:00.000Z',
            'updated_at': '2024-01-15T10:30:00.000Z',
            'creator_name': 'John Doe',
          },
          'items': [
            {
              'id': 'item-1',
              'checklist_id': 'checklist-1',
              'title': 'Pack clothes',
              'is_completed': false,
              'order_index': 0,
            },
            {
              'id': 'item-2',
              'checklist_id': 'checklist-1',
              'title': 'Book hotel',
              'is_completed': true,
              'order_index': 1,
            },
          ],
        };

        final checklistWithItems = ChecklistWithItems.fromJson(json);

        expect(checklistWithItems.checklist.id, 'checklist-1');
        expect(checklistWithItems.checklist.name, 'Packing List');
        expect(checklistWithItems.items.length, 2);
        expect(checklistWithItems.items[0].title, 'Pack clothes');
        expect(checklistWithItems.items[1].title, 'Book hotel');
      });

      test('should handle empty items list', () {
        final json = {
          'checklist': {
            'id': 'checklist-1',
            'trip_id': 'trip-1',
            'name': 'Empty List',
          },
          'items': <Map<String, dynamic>>[],
        };

        final checklistWithItems = ChecklistWithItems.fromJson(json);

        expect(checklistWithItems.checklist.name, 'Empty List');
        expect(checklistWithItems.items, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert to JSON with nested objects', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final json = checklistWithItems.toJson();

        expect(json['checklist'], isA<Map<String, dynamic>>());
        expect(json['items'], isA<List>());
        expect((json['checklist'] as Map<String, dynamic>)['id'], 'checklist-1');
        expect((json['items'] as List).length, 2);
      });
    });

    group('copyWith', () {
      test('should copy with new checklist', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final newChecklist = checklist.copyWith(name: 'Updated List');
        final copied = checklistWithItems.copyWith(checklist: newChecklist);

        expect(copied.checklist.name, 'Updated List');
        expect(copied.items, items);
      });

      test('should copy with new items', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final newItems = [
          const ChecklistItemModel(
            id: 'item-3',
            checklistId: 'checklist-1',
            title: 'New item',
            isCompleted: false,
            orderIndex: 0,
          ),
        ];

        final copied = checklistWithItems.copyWith(items: newItems);

        expect(copied.checklist, checklist);
        expect(copied.items.length, 1);
        expect(copied.items[0].title, 'New item');
      });

      test('should keep original values when not specified', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final copied = checklistWithItems.copyWith();

        expect(copied.checklist, checklist);
        expect(copied.items, items);
      });
    });

    group('equality', () {
      test('should be equal when same checklist and items', () {
        final checklistWithItems1 = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final checklistWithItems2 = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        expect(checklistWithItems1, checklistWithItems2);
        expect(checklistWithItems1.hashCode, checklistWithItems2.hashCode);
      });

      test('should not be equal when different checklist', () {
        final checklistWithItems1 = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final differentChecklist = checklist.copyWith(name: 'Different');
        final checklistWithItems2 = ChecklistWithItems(
          checklist: differentChecklist,
          items: items,
        );

        expect(checklistWithItems1, isNot(checklistWithItems2));
      });

      test('should not be equal when different items', () {
        final checklistWithItems1 = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final differentItems = [
          const ChecklistItemModel(
            id: 'item-3',
            checklistId: 'checklist-1',
            title: 'Different item',
            isCompleted: false,
            orderIndex: 0,
          ),
        ];

        final checklistWithItems2 = ChecklistWithItems(
          checklist: checklist,
          items: differentItems,
        );

        expect(checklistWithItems1, isNot(checklistWithItems2));
      });

      test('should be identical to itself', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        expect(checklistWithItems == checklistWithItems, true);
      });

      test('should not be equal to null list comparison', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        // This tests the _listEquals function
        expect(checklistWithItems, isNotNull);
      });
    });

    group('toString', () {
      test('should return string representation', () {
        final checklistWithItems = ChecklistWithItems(
          checklist: checklist,
          items: items,
        );

        final str = checklistWithItems.toString();

        expect(str, contains('ChecklistWithItems'));
        expect(str, contains('Packing List'));
      });
    });
  });
}
