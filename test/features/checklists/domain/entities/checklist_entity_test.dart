import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';

void main() {
  group('ChecklistEntity', () {
    test('constructor stores required + optional fields', () {
      final c = ChecklistEntity(
        id: 'c1',
        tripId: 't1',
        name: 'Packing',
        createdBy: 'user-1',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
        creatorName: 'Alice',
      );
      expect(c.id, 'c1');
      expect(c.tripId, 't1');
      expect(c.name, 'Packing');
      expect(c.createdBy, 'user-1');
      expect(c.createdAt, DateTime.utc(2024, 1, 1));
      expect(c.updatedAt, DateTime.utc(2024, 1, 2));
      expect(c.creatorName, 'Alice');
    });

    test('optional fields default to null', () {
      const c = ChecklistEntity(id: 'c1', tripId: 't1', name: 'X');
      expect(c.createdBy, isNull);
      expect(c.createdAt, isNull);
      expect(c.updatedAt, isNull);
      expect(c.creatorName, isNull);
    });

    test('equality is value-based via Equatable', () {
      const a = ChecklistEntity(id: 'c', tripId: 't', name: 'X');
      const b = ChecklistEntity(id: 'c', tripId: 't', name: 'X');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different id breaks equality', () {
      const a = ChecklistEntity(id: 'a', tripId: 't', name: 'X');
      const b = ChecklistEntity(id: 'b', tripId: 't', name: 'X');
      expect(a, isNot(b));
    });

    test('different tripId breaks equality', () {
      const a = ChecklistEntity(id: 'c', tripId: '1', name: 'X');
      const b = ChecklistEntity(id: 'c', tripId: '2', name: 'X');
      expect(a, isNot(b));
    });

    test('different name breaks equality', () {
      const a = ChecklistEntity(id: 'c', tripId: 't', name: 'A');
      const b = ChecklistEntity(id: 'c', tripId: 't', name: 'B');
      expect(a, isNot(b));
    });

    test('props contains all fields in declared order', () {
      final c = ChecklistEntity(
        id: 'c1',
        tripId: 't1',
        name: 'X',
        createdBy: 'u',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
        creatorName: 'Alice',
      );
      expect(c.props, [
        'c1',
        't1',
        'X',
        'u',
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 2),
        'Alice',
      ]);
    });
  });

  group('ChecklistItemEntity', () {
    test('constructor stores all fields', () {
      final i = ChecklistItemEntity(
        id: 'i1',
        checklistId: 'c1',
        title: 'Pack socks',
        isCompleted: true,
        assignedTo: 'u-1',
        completedBy: 'u-2',
        completedAt: DateTime.utc(2024, 1, 5),
        orderIndex: 3,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 5),
        assignedToName: 'Bob',
        completedByName: 'Alice',
      );
      expect(i.id, 'i1');
      expect(i.checklistId, 'c1');
      expect(i.title, 'Pack socks');
      expect(i.isCompleted, isTrue);
      expect(i.assignedTo, 'u-1');
      expect(i.completedBy, 'u-2');
      expect(i.completedAt, DateTime.utc(2024, 1, 5));
      expect(i.orderIndex, 3);
      expect(i.assignedToName, 'Bob');
      expect(i.completedByName, 'Alice');
    });

    test('isCompleted defaults to false; orderIndex to 0', () {
      const i = ChecklistItemEntity(id: 'i', checklistId: 'c', title: 'X');
      expect(i.isCompleted, isFalse);
      expect(i.orderIndex, 0);
    });

    test('optional fields default to null', () {
      const i = ChecklistItemEntity(id: 'i', checklistId: 'c', title: 'X');
      expect(i.assignedTo, isNull);
      expect(i.completedBy, isNull);
      expect(i.completedAt, isNull);
      expect(i.createdAt, isNull);
      expect(i.updatedAt, isNull);
      expect(i.assignedToName, isNull);
      expect(i.completedByName, isNull);
    });

    test('equality is value-based via Equatable', () {
      const a = ChecklistItemEntity(
        id: 'i',
        checklistId: 'c',
        title: 'X',
        isCompleted: true,
        orderIndex: 2,
      );
      const b = ChecklistItemEntity(
        id: 'i',
        checklistId: 'c',
        title: 'X',
        isCompleted: true,
        orderIndex: 2,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different isCompleted breaks equality', () {
      const a = ChecklistItemEntity(
          id: 'i', checklistId: 'c', title: 'X', isCompleted: true);
      const b = ChecklistItemEntity(
          id: 'i', checklistId: 'c', title: 'X', isCompleted: false);
      expect(a, isNot(b));
    });

    test('different orderIndex breaks equality', () {
      const a = ChecklistItemEntity(
          id: 'i', checklistId: 'c', title: 'X', orderIndex: 1);
      const b = ChecklistItemEntity(
          id: 'i', checklistId: 'c', title: 'X', orderIndex: 2);
      expect(a, isNot(b));
    });
  });

  group('ChecklistWithItemsEntity', () {
    ChecklistEntity buildChecklist({String id = 'c1'}) =>
        ChecklistEntity(id: id, tripId: 't1', name: 'X');

    ChecklistItemEntity item({
      String id = 'i',
      bool isCompleted = false,
    }) =>
        ChecklistItemEntity(
          id: id,
          checklistId: 'c1',
          title: 'task',
          isCompleted: isCompleted,
        );

    test('progress is 0.0 when items list is empty', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: const [],
      );
      expect(e.progress, 0.0);
    });

    test('progress is 1.0 when all items completed', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [
          item(id: 'a', isCompleted: true),
          item(id: 'b', isCompleted: true),
        ],
      );
      expect(e.progress, 1.0);
    });

    test('progress is 0.0 when no items completed', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [item(id: 'a'), item(id: 'b')],
      );
      expect(e.progress, 0.0);
    });

    test('progress is 0.5 when half items completed', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [
          item(id: 'a', isCompleted: true),
          item(id: 'b'),
          item(id: 'c', isCompleted: true),
          item(id: 'd'),
        ],
      );
      expect(e.progress, 0.5);
    });

    test('completedCount counts isCompleted=true items', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [
          item(id: 'a', isCompleted: true),
          item(id: 'b'),
          item(id: 'c', isCompleted: true),
        ],
      );
      expect(e.completedCount, 2);
    });

    test('pendingCount counts isCompleted=false items', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [
          item(id: 'a', isCompleted: true),
          item(id: 'b'),
          item(id: 'c'),
        ],
      );
      expect(e.pendingCount, 2);
    });

    test('completedCount and pendingCount are zero when items empty', () {
      final e = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: const [],
      );
      expect(e.completedCount, 0);
      expect(e.pendingCount, 0);
    });

    test('equality compares checklist and items together', () {
      final a = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [item(id: 'a')],
      );
      final b = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [item(id: 'a')],
      );
      expect(a, b);
    });

    test('different items breaks equality', () {
      final a = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [item(id: 'a')],
      );
      final b = ChecklistWithItemsEntity(
        checklist: buildChecklist(),
        items: [item(id: 'b')],
      );
      expect(a, isNot(b));
    });
  });
}
