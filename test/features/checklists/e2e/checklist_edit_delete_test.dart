import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/database/database_helper.dart';
import 'package:travel_crew/features/checklists/data/datasources/checklist_local_datasource.dart';
import 'package:travel_crew/features/checklists/data/repositories/checklist_repository_impl.dart';
import 'package:travel_crew/shared/models/checklist_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChecklistRepositoryImpl repository;
  late ChecklistLocalDataSource datasource;

  setUp(() async {
    // Initialize in-memory database
    await DatabaseHelper.instance.database;
    datasource = ChecklistLocalDataSource(DatabaseHelper.instance);
    repository = ChecklistRepositoryImpl(localDataSource: datasource);
  });

  tearDown(() async {
    // Clean up database
    await DatabaseHelper.instance.close();
  });

  group('Edit Checklist End-to-End Tests', () {
    test('Should update checklist name successfully', () async {
      // Create initial checklist
      final checklistId = 'checklist-edit-1';
      final originalName = 'Original Packing List';
      final updatedName = 'Updated Packing List';

      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: originalName,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Update checklist name
      await repository.updateChecklist(
        checklistId: checklistId,
        name: updatedName,
      );

      // Verify update
      final updated = await datasource.getChecklist(checklistId);
      expect(updated, isNotNull);
      expect(updated!.name, equals(updatedName));
      expect(updated.id, equals(checklistId));
    });

    test('Should handle concurrent updates correctly', () async {
      // Create checklist
      final checklistId = 'checklist-edit-2';
      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: 'Concurrent Test',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Simulate concurrent updates
      await Future.wait([
        repository.updateChecklist(checklistId: checklistId, name: 'Update 1'),
        repository.updateChecklist(checklistId: checklistId, name: 'Update 2'),
        repository.updateChecklist(checklistId: checklistId, name: 'Update 3'),
      ]);

      // Verify checklist still exists and has a valid name
      final result = await datasource.getChecklist(checklistId);
      expect(result, isNotNull);
      expect(result!.name, isNotEmpty);
    });

    test('Should validate empty name updates', () async {
      // Create checklist
      final checklistId = 'checklist-edit-3';
      final originalName = 'Valid Name';
      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: originalName,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Attempt to update with empty name (should be caught by UI validation)
      // This tests the repository behavior - UI should prevent this
      await repository.updateChecklist(
        checklistId: checklistId,
        name: '',
      );

      // Verify checklist has empty name (repository doesn't validate, UI should)
      final result = await datasource.getChecklist(checklistId);
      expect(result, isNotNull);
      expect(result!.name, equals('')); // Repository allows it, UI should prevent
    });
  });

  group('Delete Checklist End-to-End Tests', () {
    test('Should delete checklist successfully', () async {
      // Create checklist
      final checklistId = 'checklist-delete-1';
      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: 'To Be Deleted',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Verify it exists
      var result = await datasource.getChecklist(checklistId);
      expect(result, isNotNull);

      // Delete checklist
      await repository.deleteChecklist(checklistId);

      // Verify deletion
      result = await datasource.getChecklist(checklistId);
      expect(result, isNull);
    });

    test('Should delete checklist and all its items (cascade)', () async {
      // Create checklist
      final checklistId = 'checklist-delete-2';
      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: 'Delete With Items',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Add items to checklist
      final item1 = ChecklistItemModel(
        id: 'item-1',
        checklistId: checklistId,
        title: 'Item 1',
        isCompleted: false,
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final item2 = ChecklistItemModel(
        id: 'item-2',
        checklistId: checklistId,
        title: 'Item 2',
        isCompleted: false,
        orderIndex: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await datasource.upsertChecklistItem(item1);
      await datasource.upsertChecklistItem(item2);

      // Verify items exist
      var items = await datasource.getChecklistItems(checklistId);
      expect(items.length, equals(2));

      // Delete checklist (should cascade delete items)
      await repository.deleteChecklist(checklistId);

      // Verify checklist is deleted
      final checklistResult = await datasource.getChecklist(checklistId);
      expect(checklistResult, isNull);

      // Verify items are deleted (CASCADE)
      items = await datasource.getChecklistItems(checklistId);
      expect(items.length, equals(0));
    });

    test('Should handle deleting non-existent checklist gracefully', () async {
      final nonExistentId = 'does-not-exist';

      // Attempt to delete non-existent checklist
      // Should not throw an error
      await repository.deleteChecklist(nonExistentId);

      // Verify still doesn't exist
      final result = await datasource.getChecklist(nonExistentId);
      expect(result, isNull);
    });

    test('Should delete multiple checklists in sequence', () async {
      // Create multiple checklists
      final checklists = List.generate(
        5,
        (index) => ChecklistModel(
          id: 'checklist-multi-$index',
          tripId: 'trip-1',
          name: 'Checklist $index',
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          creatorName: 'Test User',
        ),
      );

      for (final checklist in checklists) {
        await datasource.upsertChecklist(checklist);
      }

      // Verify all exist
      var tripChecklists = await datasource.getTripChecklists('trip-1');
      expect(tripChecklists.length, greaterThanOrEqualTo(5));

      // Delete all checklists
      for (final checklist in checklists) {
        await repository.deleteChecklist(checklist.id);
      }

      // Verify all are deleted
      for (final checklist in checklists) {
        final result = await datasource.getChecklist(checklist.id);
        expect(result, isNull, reason: 'Checklist ${checklist.id} should be deleted');
      }
    });
  });

  group('Edit and Delete Integration Tests', () {
    test('Should edit checklist multiple times then delete', () async {
      // Create checklist
      final checklistId = 'checklist-edit-delete-1';
      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: 'Initial Name',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Edit multiple times
      await repository.updateChecklist(checklistId: checklistId, name: 'Edit 1');
      await repository.updateChecklist(checklistId: checklistId, name: 'Edit 2');
      await repository.updateChecklist(checklistId: checklistId, name: 'Final Edit');

      // Verify last edit
      var result = await datasource.getChecklist(checklistId);
      expect(result!.name, equals('Final Edit'));

      // Delete checklist
      await repository.deleteChecklist(checklistId);

      // Verify deletion
      result = await datasource.getChecklist(checklistId);
      expect(result, isNull);
    });

    test('Should maintain data integrity after edit operations', () async {
      // Create checklist with items
      final checklistId = 'checklist-integrity-1';
      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: 'Integrity Test',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Add items
      final item = ChecklistItemModel(
        id: 'item-integrity-1',
        checklistId: checklistId,
        title: 'Test Item',
        isCompleted: false,
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await datasource.upsertChecklistItem(item);

      // Edit checklist name
      await repository.updateChecklist(checklistId: checklistId, name: 'Updated Name');

      // Verify item still exists after name update
      final items = await datasource.getChecklistItems(checklistId);
      expect(items.length, equals(1));
      expect(items.first.title, equals('Test Item'));

      // Verify checklist name updated
      final updatedChecklist = await datasource.getChecklist(checklistId);
      expect(updatedChecklist!.name, equals('Updated Name'));
    });
  });

  group('Edge Cases', () {
    test('Should handle very long checklist names', () async {
      final checklistId = 'checklist-long-name';
      final longName = 'A' * 500; // 500 characters

      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: longName,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Update with another long name
      final anotherLongName = 'B' * 500;
      await repository.updateChecklist(checklistId: checklistId, name: anotherLongName);

      final result = await datasource.getChecklist(checklistId);
      expect(result!.name, equals(anotherLongName));
      expect(result.name.length, equals(500));
    });

    test('Should handle special characters in checklist names', () async {
      final checklistId = 'checklist-special-chars';
      final specialName = 'Test 🎉 Checklist with éñüö & symbols!@#\$%';

      final checklist = ChecklistModel(
        id: checklistId,
        tripId: 'trip-1',
        name: specialName,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        creatorName: 'Test User',
      );

      await datasource.upsertChecklist(checklist);

      // Update with more special characters
      final updatedName = '新しい チェックリスト 🚀🌟✨';
      await repository.updateChecklist(checklistId: checklistId, name: updatedName);

      final result = await datasource.getChecklist(checklistId);
      expect(result!.name, equals(updatedName));
    });
  });
}
