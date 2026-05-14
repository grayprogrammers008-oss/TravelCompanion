import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/features/checklists/data/mappers/checklist_mapper.dart';
import 'package:pathio/features/checklists/domain/entities/checklist_entity.dart';
import 'package:pathio/shared/models/checklist_model.dart';

void main() {
  group('ChecklistMapper.toEntity', () {
    test('maps all required fields correctly', () {
      final model = ChecklistModel(
        id: 'cl-1',
        tripId: 'trip-1',
        name: 'Packing',
      );

      final entity = model.toEntity();

      expect(entity.id, 'cl-1');
      expect(entity.tripId, 'trip-1');
      expect(entity.name, 'Packing');
      expect(entity.createdBy, isNull);
      expect(entity.createdAt, isNull);
      expect(entity.updatedAt, isNull);
      expect(entity.creatorName, isNull);
    });

    test('maps optional fields when present', () {
      final ts = DateTime(2024, 1, 15);
      final model = ChecklistModel(
        id: 'cl-2',
        tripId: 'trip-2',
        name: 'Errands',
        createdBy: 'user-99',
        createdAt: ts,
        updatedAt: ts.add(const Duration(hours: 1)),
        creatorName: 'Alice',
      );

      final entity = model.toEntity();

      expect(entity.createdBy, 'user-99');
      expect(entity.createdAt, ts);
      expect(entity.updatedAt, ts.add(const Duration(hours: 1)));
      expect(entity.creatorName, 'Alice');
    });
  });

  group('ChecklistEntityMapper.toModel', () {
    test('maps required fields correctly', () {
      final entity = ChecklistEntity(
        id: 'cl-1',
        tripId: 'trip-1',
        name: 'Packing',
      );

      final model = entity.toModel();

      expect(model.id, 'cl-1');
      expect(model.tripId, 'trip-1');
      expect(model.name, 'Packing');
    });

    test('round-trip preserves equality', () {
      final ts = DateTime(2024, 1, 15);
      final original = ChecklistModel(
        id: 'cl-1',
        tripId: 'trip-1',
        name: 'My List',
        createdBy: 'u',
        createdAt: ts,
        updatedAt: ts,
        creatorName: 'Bob',
      );

      final roundTrip = original.toEntity().toModel();

      expect(roundTrip, equals(original));
    });
  });

  group('ChecklistItemMapper.toEntity', () {
    test('maps all required fields', () {
      const model = ChecklistItemModel(
        id: 'it-1',
        checklistId: 'cl-1',
        title: 'Sunscreen',
      );

      final entity = model.toEntity();

      expect(entity.id, 'it-1');
      expect(entity.checklistId, 'cl-1');
      expect(entity.title, 'Sunscreen');
      expect(entity.isCompleted, isFalse);
      expect(entity.orderIndex, 0);
    });

    test('maps assignment / completion / timestamps', () {
      final created = DateTime(2024, 1, 1);
      final completed = DateTime(2024, 1, 2);
      final model = ChecklistItemModel(
        id: 'it-2',
        checklistId: 'cl-1',
        title: 'Charger',
        isCompleted: true,
        assignedTo: 'u-1',
        completedBy: 'u-2',
        completedAt: completed,
        orderIndex: 5,
        createdAt: created,
        updatedAt: created,
        assignedToName: 'Alice',
        completedByName: 'Bob',
      );

      final entity = model.toEntity();

      expect(entity.isCompleted, isTrue);
      expect(entity.assignedTo, 'u-1');
      expect(entity.completedBy, 'u-2');
      expect(entity.completedAt, completed);
      expect(entity.orderIndex, 5);
      expect(entity.createdAt, created);
      expect(entity.updatedAt, created);
      expect(entity.assignedToName, 'Alice');
      expect(entity.completedByName, 'Bob');
    });

    test('default isCompleted=false propagates', () {
      const model = ChecklistItemModel(
        id: 'it-3',
        checklistId: 'cl-1',
        title: 'Default',
      );

      expect(model.toEntity().isCompleted, isFalse);
    });
  });

  group('ChecklistItemEntityMapper.toModel', () {
    test('maps required fields back to model', () {
      const entity = ChecklistItemEntity(
        id: 'it-1',
        checklistId: 'cl-1',
        title: 'Hat',
      );

      final model = entity.toModel();

      expect(model.id, 'it-1');
      expect(model.checklistId, 'cl-1');
      expect(model.title, 'Hat');
      expect(model.isCompleted, isFalse);
    });

    test('round-trip entity↔model preserves equality', () {
      final created = DateTime(2024, 6, 1, 9, 0);
      final entity = ChecklistItemEntity(
        id: 'it-9',
        checklistId: 'cl-9',
        title: 'Camera',
        isCompleted: true,
        assignedTo: 'a',
        completedBy: 'b',
        completedAt: created,
        orderIndex: 3,
        createdAt: created,
        updatedAt: created,
        assignedToName: 'A',
        completedByName: 'B',
      );

      final roundTrip = entity.toModel().toEntity();
      // Equatable equality
      expect(roundTrip.id, entity.id);
      expect(roundTrip.checklistId, entity.checklistId);
      expect(roundTrip.title, entity.title);
      expect(roundTrip.isCompleted, entity.isCompleted);
      expect(roundTrip.assignedTo, entity.assignedTo);
      expect(roundTrip.completedBy, entity.completedBy);
      expect(roundTrip.completedAt, entity.completedAt);
      expect(roundTrip.orderIndex, entity.orderIndex);
      expect(roundTrip.createdAt, entity.createdAt);
      expect(roundTrip.updatedAt, entity.updatedAt);
      expect(roundTrip.assignedToName, entity.assignedToName);
      expect(roundTrip.completedByName, entity.completedByName);
    });
  });

  group('ChecklistWithItemsMapper.toEntity', () {
    test('maps a checklist with multiple items into the entity', () {
      final model = ChecklistWithItems(
        checklist: ChecklistModel(
          id: 'cl-1',
          tripId: 'trip-1',
          name: 'List',
        ),
        items: const [
          ChecklistItemModel(id: '1', checklistId: 'cl-1', title: 'A'),
          ChecklistItemModel(
            id: '2',
            checklistId: 'cl-1',
            title: 'B',
            isCompleted: true,
          ),
        ],
      );

      final entity = model.toEntity();

      expect(entity.checklist.id, 'cl-1');
      expect(entity.items, hasLength(2));
      expect(entity.items[0].title, 'A');
      expect(entity.items[1].isCompleted, isTrue);
    });

    test('maps an empty item list cleanly', () {
      final model = ChecklistWithItems(
        checklist: ChecklistModel(
          id: 'cl-empty',
          tripId: 't',
          name: 'Empty',
        ),
        items: const [],
      );

      final entity = model.toEntity();
      expect(entity.items, isEmpty);
      expect(entity.checklist.name, 'Empty');
    });

    test('progress and completedCount on round-trip entity is correct', () {
      final model = ChecklistWithItems(
        checklist: ChecklistModel(
          id: 'cl-1',
          tripId: 't',
          name: 'L',
        ),
        items: const [
          ChecklistItemModel(
              id: '1', checklistId: 'cl-1', title: 'A', isCompleted: true),
          ChecklistItemModel(id: '2', checklistId: 'cl-1', title: 'B'),
          ChecklistItemModel(
              id: '3', checklistId: 'cl-1', title: 'C', isCompleted: true),
          ChecklistItemModel(id: '4', checklistId: 'cl-1', title: 'D'),
        ],
      );

      final entity = model.toEntity();
      expect(entity.progress, 0.5);
      expect(entity.completedCount, 2);
      expect(entity.pendingCount, 2);
    });
  });

  group('ChecklistWithItemsEntityMapper.toModel', () {
    test('maps a populated entity to a model', () {
      final entity = ChecklistWithItemsEntity(
        checklist: ChecklistEntity(
          id: 'cl-1',
          tripId: 't',
          name: 'L',
        ),
        items: const [
          ChecklistItemEntity(id: '1', checklistId: 'cl-1', title: 'A'),
        ],
      );

      final model = entity.toModel();

      expect(model.checklist.id, 'cl-1');
      expect(model.items, hasLength(1));
      expect(model.items.first.title, 'A');
    });

    test('round-trip preserves length and titles', () {
      final entity = ChecklistWithItemsEntity(
        checklist: ChecklistEntity(
          id: 'cl-1',
          tripId: 't',
          name: 'L',
        ),
        items: const [
          ChecklistItemEntity(id: '1', checklistId: 'cl-1', title: 'a'),
          ChecklistItemEntity(id: '2', checklistId: 'cl-1', title: 'b'),
          ChecklistItemEntity(id: '3', checklistId: 'cl-1', title: 'c'),
        ],
      );

      final round = entity.toModel().toEntity();
      expect(round.items.map((i) => i.title), ['a', 'b', 'c']);
    });
  });
}
