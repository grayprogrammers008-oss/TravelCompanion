import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_crew/core/database/database_helper.dart';
import 'package:travel_crew/features/checklists/data/datasources/checklist_local_datasource.dart';
import 'package:travel_crew/features/checklists/data/repositories/checklist_repository_impl.dart';
import 'package:travel_crew/features/checklists/domain/repositories/checklist_repository.dart';
import 'package:travel_crew/features/checklists/domain/usecases/create_checklist_usecase.dart';
import 'package:travel_crew/features/checklists/domain/usecases/get_trip_checklists_usecase.dart';
import 'package:travel_crew/features/checklists/domain/usecases/get_checklist_with_items_usecase.dart';
import 'package:travel_crew/features/checklists/domain/usecases/manage_checklist_items_usecase.dart';

/// End-to-End Integration Tests for Collaborative Checklists Feature
///
/// These tests verify the complete workflow of the checklist feature:
/// 1. Creating checklists for a trip
/// 2. Adding items to checklists
/// 3. Assigning items to team members
/// 4. Marking items as complete
/// 5. Tracking completion (who completed what and when)
/// 6. Deleting items and checklists
///
/// Tests use a real in-memory SQLite database to ensure
/// data persistence and integrity.
void main() {
  // Initialize FFI for SQLite testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late ChecklistRepository repository;
  late CreateChecklistUseCase createChecklistUseCase;
  late GetTripChecklistsUseCase getTripChecklistsUseCase;
  late GetChecklistWithItemsUseCase getChecklistWithItemsUseCase;
  late AddChecklistItemUseCase addItemUseCase;
  late UpdateChecklistItemUseCase updateItemUseCase;
  late ToggleItemCompletionUseCase toggleCompletionUseCase;
  late DeleteChecklistItemUseCase deleteItemUseCase;
  late Database database;

  setUp(() async {
    // Create in-memory database for testing
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await ChecklistLocalDataSource.createTables(db);
      },
    );

    // Create test database helper
    final testDatabaseHelper = _TestDatabaseHelper(database);

    // Set up repository and use cases
    final dataSource = ChecklistLocalDataSource(testDatabaseHelper);
    repository = ChecklistRepositoryImpl(localDataSource: dataSource);

    createChecklistUseCase = CreateChecklistUseCase(repository);
    getTripChecklistsUseCase = GetTripChecklistsUseCase(repository);
    getChecklistWithItemsUseCase = GetChecklistWithItemsUseCase(repository);
    addItemUseCase = AddChecklistItemUseCase(repository);
    updateItemUseCase = UpdateChecklistItemUseCase(repository);
    toggleCompletionUseCase = ToggleItemCompletionUseCase(repository);
    deleteItemUseCase = DeleteChecklistItemUseCase(repository);
  });

  group('End-to-End Checklist Feature Tests', () {
    const tripId = 'trip-hawaii-2024';
    const userId1 = 'user-alice';
    const userId2 = 'user-bob';

    test('Complete workflow: Create checklist → Add items → Assign → Complete', () async {
      // STEP 1: Create a packing checklist
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Packing List',
          createdBy: userId1,
        ),
      );

      expect(checklist, isNotNull);
      expect(checklist!.name, 'Packing List');
      expect(checklist.tripId, tripId);

      // STEP 2: Add items to the checklist
      final item1 = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist.id,
          title: 'Passport',
          assignedTo: userId1,
        ),
      );

      final item2 = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist.id,
          title: 'Sunscreen',
          assignedTo: userId2,
        ),
      );

      final item3 = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist.id,
          title: 'Camera',
          assignedTo: userId1,
        ),
      );

      expect(item1, isNotNull);
      expect(item2, isNotNull);
      expect(item3, isNotNull);
      expect(item1!.title, 'Passport');
      expect(item1.assignedTo, userId1);
      expect(item2!.assignedTo, userId2);

      // STEP 3: Get checklist with items to verify
      final checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);

      expect(checklistWithItems, isNotNull);
      expect(checklistWithItems!.items.length, 3);
      expect(checklistWithItems.completedCount, 0);
      expect(checklistWithItems.pendingCount, 3);
      expect(checklistWithItems.progress, 0.0);

      // STEP 4: Mark item 1 as complete
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item1.id,
          isCompleted: true,
          userId: userId1,
        ),
      );

      // STEP 5: Verify completion tracking
      final updatedChecklistWithItems = await getChecklistWithItemsUseCase(checklist.id);

      expect(updatedChecklistWithItems!.completedCount, 1);
      expect(updatedChecklistWithItems.pendingCount, 2);
      expect(updatedChecklistWithItems.progress, closeTo(0.33, 0.01));

      final completedItem = updatedChecklistWithItems.items.firstWhere((i) => i.id == item1.id);
      expect(completedItem.isCompleted, true);
      expect(completedItem.completedBy, userId1);
      expect(completedItem.completedAt, isNotNull);

      // STEP 6: Mark item 2 as complete by different user
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item2.id,
          isCompleted: true,
          userId: userId2,
        ),
      );

      // STEP 7: Verify progress calculation
      final progressChecklistWithItems = await getChecklistWithItemsUseCase(checklist.id);

      expect(progressChecklistWithItems!.completedCount, 2);
      expect(progressChecklistWithItems.pendingCount, 1);
      expect(progressChecklistWithItems.progress, closeTo(0.67, 0.01));

      // STEP 8: Complete all items
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item3.id,
          isCompleted: true,
          userId: userId1,
        ),
      );

      final finalChecklistWithItems = await getChecklistWithItemsUseCase(checklist.id);

      expect(finalChecklistWithItems!.completedCount, 3);
      expect(finalChecklistWithItems.pendingCount, 0);
      expect(finalChecklistWithItems.progress, 1.0);
    });

    test('Multiple checklists for same trip', () async {
      // Create multiple checklists
      final packingList = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Packing List',
          createdBy: userId1,
        ),
      );

      final todoList = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Pre-Trip TODO',
          createdBy: userId1,
        ),
      );

      final shoppingList = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Shopping List',
          createdBy: userId2,
        ),
      );

      expect(packingList, isNotNull);
      expect(todoList, isNotNull);
      expect(shoppingList, isNotNull);

      // Get all checklists for trip
      final checklists = await getTripChecklistsUseCase(tripId);

      expect(checklists.length, 3);
      expect(checklists.map((c) => c.name), containsAll([
        'Packing List',
        'Pre-Trip TODO',
        'Shopping List',
      ]));
    });

    test('Assignment and reassignment of items', () async {
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Tasks',
          createdBy: userId1,
        ),
      );

      // Add item assigned to user 1
      final item = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist!.id,
          title: 'Book flights',
          assignedTo: userId1,
        ),
      );

      expect(item!.assignedTo, userId1);

      // Reassign to user 2
      await updateItemUseCase(
        UpdateChecklistItemParams(
          itemId: item.id,
          title: 'Book flights',
          assignedTo: userId2,
        ),
      );

      final updated = await getChecklistWithItemsUseCase(checklist.id);
      final updatedItem = updated!.items.firstWhere((i) => i.id == item.id);

      expect(updatedItem.assignedTo, userId2);
    });

    test('Toggle completion on and off', () async {
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Test List',
          createdBy: userId1,
        ),
      );

      final item = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist!.id,
          title: 'Test item',
        ),
      );

      // Mark as complete
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item!.id,
          isCompleted: true,
          userId: userId1,
        ),
      );

      var checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);
      var completedItem = checklistWithItems!.items.first;

      expect(completedItem.isCompleted, true);
      expect(completedItem.completedBy, userId1);
      expect(completedItem.completedAt, isNotNull);

      // Mark as incomplete
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item.id,
          isCompleted: false,
          userId: userId1,
        ),
      );

      checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);
      completedItem = checklistWithItems!.items.first;

      expect(completedItem.isCompleted, false);
      expect(completedItem.completedBy, isNull);
      expect(completedItem.completedAt, isNull);
    });

    test('Delete items from checklist', () async {
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Delete Test',
          createdBy: userId1,
        ),
      );

      // Add 3 items
      final item1 = await addItemUseCase(
        AddChecklistItemParams(checklistId: checklist!.id, title: 'Item 1'),
      );
      final item2 = await addItemUseCase(
        AddChecklistItemParams(checklistId: checklist.id, title: 'Item 2'),
      );
      final item3 = await addItemUseCase(
        AddChecklistItemParams(checklistId: checklist.id, title: 'Item 3'),
      );

      var checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);
      expect(checklistWithItems!.items.length, 3);

      // Delete item 2
      await deleteItemUseCase(item2!.id);

      checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);
      expect(checklistWithItems!.items.length, 2);
      expect(checklistWithItems.items.map((i) => i.id), containsAll([item1!.id, item3!.id]));
      expect(checklistWithItems.items.map((i) => i.id), isNot(contains(item2.id)));
    });

    test('Empty checklist progress should be 0%', () async {
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Empty List',
          createdBy: userId1,
        ),
      );

      final checklistWithItems = await getChecklistWithItemsUseCase(checklist!.id);

      expect(checklistWithItems!.items.length, 0);
      expect(checklistWithItems.completedCount, 0);
      expect(checklistWithItems.pendingCount, 0);
      expect(checklistWithItems.progress, 0.0);
    });

    test('Items maintain order', () async {
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Ordered List',
          createdBy: userId1,
        ),
      );

      // Add items with specific order
      await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist!.id,
          title: 'First',
          orderIndex: 0,
        ),
      );
      await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist.id,
          title: 'Second',
          orderIndex: 1,
        ),
      );
      await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist.id,
          title: 'Third',
          orderIndex: 2,
        ),
      );

      final checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);

      expect(checklistWithItems!.items.length, 3);
      expect(checklistWithItems.items[0].title, 'First');
      expect(checklistWithItems.items[1].title, 'Second');
      expect(checklistWithItems.items[2].title, 'Third');
    });

    test('Collaborative completion tracking - multiple users', () async {
      final checklist = await createChecklistUseCase(
        CreateChecklistParams(
          tripId: tripId,
          name: 'Team Tasks',
          createdBy: userId1,
        ),
      );

      final item1 = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist!.id,
          title: 'Task 1',
          assignedTo: userId1,
        ),
      );

      final item2 = await addItemUseCase(
        AddChecklistItemParams(
          checklistId: checklist.id,
          title: 'Task 2',
          assignedTo: userId2,
        ),
      );

      // User 1 completes their task
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item1!.id,
          isCompleted: true,
          userId: userId1,
        ),
      );

      // User 2 completes their task
      await toggleCompletionUseCase(
        ToggleItemCompletionParams(
          itemId: item2!.id,
          isCompleted: true,
          userId: userId2,
        ),
      );

      final checklistWithItems = await getChecklistWithItemsUseCase(checklist.id);

      // Verify each user completed their own task
      final completedItem1 = checklistWithItems!.items.firstWhere((i) => i.id == item1.id);
      final completedItem2 = checklistWithItems.items.firstWhere((i) => i.id == item2.id);

      expect(completedItem1.completedBy, userId1);
      expect(completedItem2.completedBy, userId2);
      expect(checklistWithItems.progress, 1.0);
    });
  });
}

/// Test implementation of DatabaseHelper for integration testing
class _TestDatabaseHelper implements DatabaseHelper {
  final Database _testDatabase;

  _TestDatabaseHelper(this._testDatabase);

  @override
  Future<Database> get database async => _testDatabase;

  @override
  Future<void> close() async {
    await _testDatabase.close();
  }

  @override
  Future<void> clearAllData() async {
    // Not needed for tests
  }

  @override
  Future<void> deleteDatabase() async {
    // Not needed for tests
  }
}
