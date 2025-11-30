import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/domain/repositories/checklist_repository.dart';
import 'package:travel_crew/features/checklists/domain/usecases/manage_checklist_items_usecase.dart';

import 'manage_checklist_items_usecase_test.mocks.dart';

@GenerateMocks([ChecklistRepository])
void main() {
  late AddChecklistItemUseCase addItemUseCase;
  late UpdateChecklistItemUseCase updateItemUseCase;
  late ToggleItemCompletionUseCase toggleCompletionUseCase;
  late DeleteChecklistItemUseCase deleteItemUseCase;
  late MockChecklistRepository mockRepository;

  setUp(() {
    mockRepository = MockChecklistRepository();
    addItemUseCase = AddChecklistItemUseCase(mockRepository);
    updateItemUseCase = UpdateChecklistItemUseCase(mockRepository);
    toggleCompletionUseCase = ToggleItemCompletionUseCase(mockRepository);
    deleteItemUseCase = DeleteChecklistItemUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testItem = ChecklistItemEntity(
    id: 'item-123',
    checklistId: 'checklist-123',
    title: 'Pack clothes',
    isCompleted: false,
    orderIndex: 0,
    createdAt: now,
    updatedAt: now,
  );

  final completedItem = ChecklistItemEntity(
    id: 'item-123',
    checklistId: 'checklist-123',
    title: 'Pack clothes',
    isCompleted: true,
    completedBy: 'user-123',
    completedAt: now,
    orderIndex: 0,
    createdAt: now,
    updatedAt: now,
  );

  group('AddChecklistItemUseCase', () {
    group('Positive Cases', () {
      test('should add item with required fields', () async {
        // Arrange
        when(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act
        final result = await addItemUseCase(AddChecklistItemParams(
          checklistId: 'checklist-123',
          title: 'Pack clothes',
        ));

        // Assert
        expect(result.id, 'item-123');
        expect(result.title, 'Pack clothes');
        verify(mockRepository.addChecklistItem(
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          assignedTo: null,
          orderIndex: null,
        )).called(1);
      });

      test('should add item with assignment', () async {
        // Arrange
        final assignedItem = ChecklistItemEntity(
          id: 'item-123',
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          isCompleted: false,
          assignedTo: 'user-456',
          orderIndex: 0,
          createdAt: now,
        );
        when(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => assignedItem);

        // Act
        final result = await addItemUseCase(AddChecklistItemParams(
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          assignedTo: 'user-456',
        ));

        // Assert
        expect(result.assignedTo, 'user-456');
        verify(mockRepository.addChecklistItem(
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          assignedTo: 'user-456',
          orderIndex: null,
        )).called(1);
      });

      test('should add item with specific order index', () async {
        // Arrange
        final orderedItem = ChecklistItemEntity(
          id: 'item-123',
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          isCompleted: false,
          orderIndex: 5,
          createdAt: now,
        );
        when(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => orderedItem);

        // Act
        final result = await addItemUseCase(AddChecklistItemParams(
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          orderIndex: 5,
        ));

        // Assert
        expect(result.orderIndex, 5);
      });

      test('should trim title whitespace', () async {
        // Arrange
        when(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act
        await addItemUseCase(AddChecklistItemParams(
          checklistId: 'checklist-123',
          title: '  Pack clothes  ',
        ));

        // Assert
        verify(mockRepository.addChecklistItem(
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          assignedTo: null,
          orderIndex: null,
        )).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty checklist ID', () async {
        // Act & Assert
        expect(
          () => addItemUseCase(AddChecklistItemParams(
            checklistId: '',
            title: 'Pack clothes',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Checklist ID cannot be empty',
          )),
        );
        verifyNever(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        ));
      });

      test('should throw ArgumentError for empty title', () async {
        // Act & Assert
        expect(
          () => addItemUseCase(AddChecklistItemParams(
            checklistId: 'checklist-123',
            title: '',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item title cannot be empty',
          )),
        );
      });

      test('should throw ArgumentError for whitespace-only title', () async {
        // Act & Assert
        expect(
          () => addItemUseCase(AddChecklistItemParams(
            checklistId: 'checklist-123',
            title: '   ',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item title cannot be empty',
          )),
        );
      });

      test('should throw ArgumentError for title exceeding 200 characters', () async {
        // Arrange
        final longTitle = 'a' * 201;

        // Act & Assert
        expect(
          () => addItemUseCase(AddChecklistItemParams(
            checklistId: 'checklist-123',
            title: longTitle,
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item title cannot exceed 200 characters',
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => addItemUseCase(AddChecklistItemParams(
            checklistId: 'checklist-123',
            title: 'Pack clothes',
          )),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should accept title with exactly 200 characters', () async {
        // Arrange
        final maxTitle = 'a' * 200;
        when(mockRepository.addChecklistItem(
          checklistId: anyNamed('checklistId'),
          title: anyNamed('title'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act & Assert - should not throw
        await addItemUseCase(AddChecklistItemParams(
          checklistId: 'checklist-123',
          title: maxTitle,
        ));

        verify(mockRepository.addChecklistItem(
          checklistId: 'checklist-123',
          title: maxTitle,
          assignedTo: null,
          orderIndex: null,
        )).called(1);
      });
    });
  });

  group('UpdateChecklistItemUseCase', () {
    group('Positive Cases', () {
      test('should update item title', () async {
        // Arrange
        final updatedItem = ChecklistItemEntity(
          id: 'item-123',
          checklistId: 'checklist-123',
          title: 'Updated title',
          isCompleted: false,
          orderIndex: 0,
          createdAt: now,
          updatedAt: now,
        );
        when(mockRepository.updateChecklistItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          isCompleted: anyNamed('isCompleted'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await updateItemUseCase(UpdateChecklistItemParams(
          itemId: 'item-123',
          title: 'Updated title',
        ));

        // Assert
        expect(result.title, 'Updated title');
      });

      test('should update item completion status', () async {
        // Arrange
        when(mockRepository.updateChecklistItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          isCompleted: anyNamed('isCompleted'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => completedItem);

        // Act
        final result = await updateItemUseCase(UpdateChecklistItemParams(
          itemId: 'item-123',
          isCompleted: true,
        ));

        // Assert
        expect(result.isCompleted, true);
      });

      test('should update item assignment', () async {
        // Arrange
        final assignedItem = ChecklistItemEntity(
          id: 'item-123',
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          isCompleted: false,
          assignedTo: 'user-789',
          orderIndex: 0,
          createdAt: now,
        );
        when(mockRepository.updateChecklistItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          isCompleted: anyNamed('isCompleted'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => assignedItem);

        // Act
        final result = await updateItemUseCase(UpdateChecklistItemParams(
          itemId: 'item-123',
          assignedTo: 'user-789',
        ));

        // Assert
        expect(result.assignedTo, 'user-789');
      });

      test('should trim title whitespace on update', () async {
        // Arrange
        when(mockRepository.updateChecklistItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          isCompleted: anyNamed('isCompleted'),
          assignedTo: anyNamed('assignedTo'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => testItem);

        // Act
        await updateItemUseCase(UpdateChecklistItemParams(
          itemId: 'item-123',
          title: '  Updated title  ',
        ));

        // Assert
        verify(mockRepository.updateChecklistItem(
          itemId: 'item-123',
          title: 'Updated title',
          isCompleted: null,
          assignedTo: null,
          orderIndex: null,
        )).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty item ID', () async {
        // Act & Assert
        expect(
          () => updateItemUseCase(UpdateChecklistItemParams(
            itemId: '',
            title: 'Updated',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item ID cannot be empty',
          )),
        );
      });

      test('should throw ArgumentError for empty title update', () async {
        // Act & Assert
        expect(
          () => updateItemUseCase(UpdateChecklistItemParams(
            itemId: 'item-123',
            title: '',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item title cannot be empty',
          )),
        );
      });

      test('should throw ArgumentError for whitespace-only title update', () async {
        // Act & Assert
        expect(
          () => updateItemUseCase(UpdateChecklistItemParams(
            itemId: 'item-123',
            title: '   ',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item title cannot be empty',
          )),
        );
      });

      test('should throw ArgumentError for title exceeding 200 characters', () async {
        // Arrange
        final longTitle = 'a' * 201;

        // Act & Assert
        expect(
          () => updateItemUseCase(UpdateChecklistItemParams(
            itemId: 'item-123',
            title: longTitle,
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item title cannot exceed 200 characters',
          )),
        );
      });
    });
  });

  group('ToggleItemCompletionUseCase', () {
    group('Positive Cases', () {
      test('should toggle item to completed', () async {
        // Arrange
        when(mockRepository.toggleItemCompletion(
          itemId: anyNamed('itemId'),
          isCompleted: anyNamed('isCompleted'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => completedItem);

        // Act
        final result = await toggleCompletionUseCase(ToggleItemCompletionParams(
          itemId: 'item-123',
          isCompleted: true,
          userId: 'user-123',
        ));

        // Assert
        expect(result.isCompleted, true);
        expect(result.completedBy, 'user-123');
        verify(mockRepository.toggleItemCompletion(
          itemId: 'item-123',
          isCompleted: true,
          userId: 'user-123',
        )).called(1);
      });

      test('should toggle item to incomplete', () async {
        // Arrange
        when(mockRepository.toggleItemCompletion(
          itemId: anyNamed('itemId'),
          isCompleted: anyNamed('isCompleted'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => testItem);

        // Act
        final result = await toggleCompletionUseCase(ToggleItemCompletionParams(
          itemId: 'item-123',
          isCompleted: false,
          userId: 'user-123',
        ));

        // Assert
        expect(result.isCompleted, false);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty item ID', () async {
        // Act & Assert
        expect(
          () => toggleCompletionUseCase(ToggleItemCompletionParams(
            itemId: '',
            isCompleted: true,
            userId: 'user-123',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item ID cannot be empty',
          )),
        );
      });

      test('should throw ArgumentError for empty user ID', () async {
        // Act & Assert
        expect(
          () => toggleCompletionUseCase(ToggleItemCompletionParams(
            itemId: 'item-123',
            isCompleted: true,
            userId: '',
          )),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'User ID cannot be empty',
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.toggleItemCompletion(
          itemId: anyNamed('itemId'),
          isCompleted: anyNamed('isCompleted'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => toggleCompletionUseCase(ToggleItemCompletionParams(
            itemId: 'item-123',
            isCompleted: true,
            userId: 'user-123',
          )),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('DeleteChecklistItemUseCase', () {
    group('Positive Cases', () {
      test('should delete item successfully', () async {
        // Arrange
        when(mockRepository.deleteChecklistItem('item-123')).thenAnswer(
          (_) async {
            return;
          },
        );

        // Act
        await deleteItemUseCase('item-123');

        // Assert
        verify(mockRepository.deleteChecklistItem('item-123')).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty item ID', () async {
        // Act & Assert
        expect(
          () => deleteItemUseCase(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Item ID cannot be empty',
          )),
        );
        verifyNever(mockRepository.deleteChecklistItem(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.deleteChecklistItem('item-123')).thenThrow(
          Exception('Item not found'),
        );

        // Act & Assert
        expect(
          () => deleteItemUseCase('item-123'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
