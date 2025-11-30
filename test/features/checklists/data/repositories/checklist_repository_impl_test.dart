import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/checklists/data/datasources/checklist_remote_datasource.dart';
import 'package:travel_crew/features/checklists/data/repositories/checklist_repository_impl.dart';
import 'package:travel_crew/shared/models/checklist_model.dart';

import 'checklist_repository_impl_test.mocks.dart';

@GenerateMocks([ChecklistRemoteDataSource])
void main() {
  late ChecklistRepositoryImpl repository;
  late MockChecklistRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockChecklistRemoteDataSource();
    repository = ChecklistRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  final now = DateTime.now();

  ChecklistModel createChecklistModel({
    required String id,
    required String tripId,
    required String name,
    String? createdBy,
  }) {
    return ChecklistModel(
      id: id,
      tripId: tripId,
      name: name,
      createdBy: createdBy ?? 'user-123',
      createdAt: now,
      updatedAt: now,
    );
  }

  ChecklistItemModel createChecklistItemModel({
    required String id,
    required String checklistId,
    required String title,
    int orderIndex = 0,
    bool isCompleted = false,
    String? assignedTo,
  }) {
    return ChecklistItemModel(
      id: id,
      checklistId: checklistId,
      title: title,
      orderIndex: orderIndex,
      isCompleted: isCompleted,
      assignedTo: assignedTo,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ChecklistRepositoryImpl', () {
    group('getTripChecklists', () {
      test('should return list of checklists from remote datasource', () async {
        // Arrange
        final checklists = [
          createChecklistModel(id: '1', tripId: 'trip-1', name: 'Packing'),
          createChecklistModel(id: '2', tripId: 'trip-1', name: 'Documents'),
        ];
        when(mockRemoteDataSource.getTripChecklists(any))
            .thenAnswer((_) async => checklists);

        // Act
        final result = await repository.getTripChecklists('trip-1');

        // Assert
        expect(result.length, 2);
        expect(result[0].name, 'Packing');
        expect(result[1].name, 'Documents');
        verify(mockRemoteDataSource.getTripChecklists('trip-1')).called(1);
      });

      test('should return empty list when no checklists exist', () async {
        // Arrange
        when(mockRemoteDataSource.getTripChecklists(any))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getTripChecklists('trip-1');

        // Assert
        expect(result, isEmpty);
      });

      test('should throw exception when remote datasource fails', () async {
        // Arrange
        when(mockRemoteDataSource.getTripChecklists(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getTripChecklists('trip-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get trip checklists'),
          )),
        );
      });
    });

    group('getChecklistWithItems', () {
      test('should return checklist with items', () async {
        // Arrange
        final checklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing',
        );
        final items = [
          createChecklistItemModel(
            id: 'item-1',
            checklistId: 'checklist-1',
            title: 'Passport',
          ),
          createChecklistItemModel(
            id: 'item-2',
            checklistId: 'checklist-1',
            title: 'Tickets',
          ),
        ];
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => checklist);
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.getChecklistWithItems('checklist-1');

        // Assert
        expect(result.checklist.name, 'Packing');
        expect(result.items.length, 2);
        verify(mockRemoteDataSource.getChecklist('checklist-1')).called(1);
        verify(mockRemoteDataSource.getChecklistItems('checklist-1')).called(1);
      });

      test('should throw exception when checklist not found', () async {
        // Arrange
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.getChecklistWithItems('nonexistent'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Checklist not found'),
          )),
        );
      });

      test('should handle checklist with no items', () async {
        // Arrange
        final checklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Empty List',
        );
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => checklist);
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getChecklistWithItems('checklist-1');

        // Assert
        expect(result.checklist.name, 'Empty List');
        expect(result.items, isEmpty);
      });
    });

    group('createChecklist', () {
      test('should create checklist successfully', () async {
        // Arrange
        final createdChecklist = createChecklistModel(
          id: 'new-id',
          tripId: 'trip-1',
          name: 'My Checklist',
          createdBy: 'user-123',
        );
        when(mockRemoteDataSource.upsertChecklist(any))
            .thenAnswer((_) async => createdChecklist);

        // Act
        final result = await repository.createChecklist(
          tripId: 'trip-1',
          name: 'My Checklist',
          createdBy: 'user-123',
        );

        // Assert
        expect(result.name, 'My Checklist');
        expect(result.tripId, 'trip-1');
        verify(mockRemoteDataSource.upsertChecklist(any)).called(1);
      });

      test('should throw exception on create failure', () async {
        // Arrange
        when(mockRemoteDataSource.upsertChecklist(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.createChecklist(
            tripId: 'trip-1',
            name: 'My Checklist',
            createdBy: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to create checklist'),
          )),
        );
      });
    });

    group('updateChecklist', () {
      test('should update checklist name successfully', () async {
        // Arrange
        final existingChecklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Old Name',
        );
        final updatedChecklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'New Name',
        );
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => existingChecklist);
        when(mockRemoteDataSource.upsertChecklist(any))
            .thenAnswer((_) async => updatedChecklist);

        // Act
        final result = await repository.updateChecklist(
          checklistId: 'checklist-1',
          name: 'New Name',
        );

        // Assert
        expect(result.name, 'New Name');
        verify(mockRemoteDataSource.getChecklist('checklist-1')).called(1);
        verify(mockRemoteDataSource.upsertChecklist(any)).called(1);
      });

      test('should throw exception when checklist not found', () async {
        // Arrange
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.updateChecklist(
            checklistId: 'nonexistent',
            name: 'New Name',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Checklist not found'),
          )),
        );
      });
    });

    group('deleteChecklist', () {
      test('should delete checklist successfully', () async {
        // Arrange
        when(mockRemoteDataSource.deleteChecklist(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteChecklist('checklist-1');

        // Assert
        verify(mockRemoteDataSource.deleteChecklist('checklist-1')).called(1);
      });

      test('should throw exception on delete failure', () async {
        // Arrange
        when(mockRemoteDataSource.deleteChecklist(any))
            .thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => repository.deleteChecklist('checklist-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete checklist'),
          )),
        );
      });
    });

    group('addChecklistItem', () {
      test('should add item with auto-generated order index', () async {
        // Arrange
        final existingItems = [
          createChecklistItemModel(
            id: 'item-1',
            checklistId: 'checklist-1',
            title: 'Item 1',
            orderIndex: 0,
          ),
        ];
        final newItem = createChecklistItemModel(
          id: 'item-2',
          checklistId: 'checklist-1',
          title: 'New Item',
          orderIndex: 1,
        );
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => existingItems);
        when(mockRemoteDataSource.upsertChecklistItem(any))
            .thenAnswer((_) async => newItem);

        // Act
        final result = await repository.addChecklistItem(
          checklistId: 'checklist-1',
          title: 'New Item',
        );

        // Assert
        expect(result.title, 'New Item');
        verify(mockRemoteDataSource.getChecklistItems('checklist-1')).called(1);
        verify(mockRemoteDataSource.upsertChecklistItem(any)).called(1);
      });

      test('should add item with custom order index', () async {
        // Arrange
        final newItem = createChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'First Item',
          orderIndex: 5,
        );
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => []);
        when(mockRemoteDataSource.upsertChecklistItem(any))
            .thenAnswer((_) async => newItem);

        // Act
        final result = await repository.addChecklistItem(
          checklistId: 'checklist-1',
          title: 'First Item',
          orderIndex: 5,
        );

        // Assert
        expect(result.orderIndex, 5);
      });

      test('should add item with assignee', () async {
        // Arrange
        final newItem = createChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Assigned Item',
          assignedTo: 'user-456',
        );
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => []);
        when(mockRemoteDataSource.upsertChecklistItem(any))
            .thenAnswer((_) async => newItem);

        // Act
        final result = await repository.addChecklistItem(
          checklistId: 'checklist-1',
          title: 'Assigned Item',
          assignedTo: 'user-456',
        );

        // Assert
        expect(result.assignedTo, 'user-456');
      });

      test('should throw exception on add failure', () async {
        // Arrange
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => []);
        when(mockRemoteDataSource.upsertChecklistItem(any))
            .thenThrow(Exception('Insert failed'));

        // Act & Assert
        expect(
          () => repository.addChecklistItem(
            checklistId: 'checklist-1',
            title: 'New Item',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to add checklist item'),
          )),
        );
      });
    });

    group('toggleItemCompletion', () {
      test('should toggle item to completed', () async {
        // Arrange
        final completedItem = createChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Task',
          isCompleted: true,
        );
        when(mockRemoteDataSource.toggleItemCompletion(
          itemId: anyNamed('itemId'),
          isCompleted: anyNamed('isCompleted'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => completedItem);

        // Act
        final result = await repository.toggleItemCompletion(
          itemId: 'item-1',
          isCompleted: true,
          userId: 'user-123',
        );

        // Assert
        expect(result.isCompleted, true);
        verify(mockRemoteDataSource.toggleItemCompletion(
          itemId: 'item-1',
          isCompleted: true,
          userId: 'user-123',
        )).called(1);
      });

      test('should toggle item to not completed', () async {
        // Arrange
        final uncompletedItem = createChecklistItemModel(
          id: 'item-1',
          checklistId: 'checklist-1',
          title: 'Task',
          isCompleted: false,
        );
        when(mockRemoteDataSource.toggleItemCompletion(
          itemId: anyNamed('itemId'),
          isCompleted: anyNamed('isCompleted'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => uncompletedItem);

        // Act
        final result = await repository.toggleItemCompletion(
          itemId: 'item-1',
          isCompleted: false,
          userId: 'user-123',
        );

        // Assert
        expect(result.isCompleted, false);
      });

      test('should throw exception on toggle failure', () async {
        // Arrange
        when(mockRemoteDataSource.toggleItemCompletion(
          itemId: anyNamed('itemId'),
          isCompleted: anyNamed('isCompleted'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => repository.toggleItemCompletion(
            itemId: 'item-1',
            isCompleted: true,
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to toggle item completion'),
          )),
        );
      });
    });

    group('deleteChecklistItem', () {
      test('should delete item successfully', () async {
        // Arrange
        when(mockRemoteDataSource.deleteChecklistItem(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteChecklistItem('item-1');

        // Assert
        verify(mockRemoteDataSource.deleteChecklistItem('item-1')).called(1);
      });

      test('should throw exception on delete failure', () async {
        // Arrange
        when(mockRemoteDataSource.deleteChecklistItem(any))
            .thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => repository.deleteChecklistItem('item-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete checklist item'),
          )),
        );
      });
    });

    group('reorderItems', () {
      test('should reorder items successfully', () async {
        // Arrange
        final items = [
          createChecklistItemModel(
            id: 'item-1',
            checklistId: 'checklist-1',
            title: 'Item 1',
            orderIndex: 0,
          ),
          createChecklistItemModel(
            id: 'item-2',
            checklistId: 'checklist-1',
            title: 'Item 2',
            orderIndex: 1,
          ),
        ];
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => items);
        when(mockRemoteDataSource.upsertChecklistItem(any))
            .thenAnswer((invocation) async {
          final model = invocation.positionalArguments[0] as ChecklistItemModel;
          return model;
        });

        // Act
        await repository.reorderItems(
          checklistId: 'checklist-1',
          itemIds: ['item-2', 'item-1'],
        );

        // Assert
        verify(mockRemoteDataSource.getChecklistItems('checklist-1')).called(1);
        verify(mockRemoteDataSource.upsertChecklistItem(any)).called(2);
      });

      test('should throw exception on reorder failure', () async {
        // Arrange
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenThrow(Exception('Fetch failed'));

        // Act & Assert
        expect(
          () => repository.reorderItems(
            checklistId: 'checklist-1',
            itemIds: ['item-1', 'item-2'],
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to reorder items'),
          )),
        );
      });
    });

    group('watchTripChecklists', () {
      test('should return stream of checklists', () async {
        // Arrange
        final checklists = [
          createChecklistModel(id: '1', tripId: 'trip-1', name: 'Packing'),
        ];
        when(mockRemoteDataSource.getTripChecklists(any))
            .thenAnswer((_) async => checklists);

        // Act
        final stream = repository.watchTripChecklists('trip-1');

        // Assert - just verify stream creation works
        expect(stream, isA<Stream>());
      });
    });

    group('watchChecklistWithItems', () {
      test('should return stream of checklist with items', () async {
        // Arrange
        final checklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Packing',
        );
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => checklist);
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => []);

        // Act
        final stream = repository.watchChecklistWithItems('checklist-1');

        // Assert - just verify stream creation works
        expect(stream, isA<Stream>());
      });
    });

    group('Edge Cases', () {
      test('should handle large number of checklists', () async {
        // Arrange
        final manyChecklists = List.generate(
          100,
          (i) => createChecklistModel(
            id: 'checklist-$i',
            tripId: 'trip-1',
            name: 'Checklist $i',
          ),
        );
        when(mockRemoteDataSource.getTripChecklists(any))
            .thenAnswer((_) async => manyChecklists);

        // Act
        final result = await repository.getTripChecklists('trip-1');

        // Assert
        expect(result.length, 100);
      });

      test('should handle checklist with many items', () async {
        // Arrange
        final checklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'Big List',
        );
        final manyItems = List.generate(
          50,
          (i) => createChecklistItemModel(
            id: 'item-$i',
            checklistId: 'checklist-1',
            title: 'Item $i',
            orderIndex: i,
          ),
        );
        when(mockRemoteDataSource.getChecklist(any))
            .thenAnswer((_) async => checklist);
        when(mockRemoteDataSource.getChecklistItems(any))
            .thenAnswer((_) async => manyItems);

        // Act
        final result = await repository.getChecklistWithItems('checklist-1');

        // Assert
        expect(result.items.length, 50);
      });

      test('should handle special characters in checklist name', () async {
        // Arrange
        final checklist = createChecklistModel(
          id: 'checklist-1',
          tripId: 'trip-1',
          name: 'My "Special" List™ – With Émojis 🎒',
        );
        when(mockRemoteDataSource.upsertChecklist(any))
            .thenAnswer((_) async => checklist);

        // Act
        final result = await repository.createChecklist(
          tripId: 'trip-1',
          name: 'My "Special" List™ – With Émojis 🎒',
          createdBy: 'user-123',
        );

        // Assert
        expect(result.name, 'My "Special" List™ – With Émojis 🎒');
      });
    });
  });
}
