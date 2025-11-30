import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/domain/repositories/checklist_repository.dart';
import 'package:travel_crew/features/checklists/domain/usecases/get_checklist_with_items_usecase.dart';

import 'get_checklist_with_items_usecase_test.mocks.dart';

@GenerateMocks([ChecklistRepository])
void main() {
  late GetChecklistWithItemsUseCase useCase;
  late WatchChecklistWithItemsUseCase watchUseCase;
  late MockChecklistRepository mockRepository;

  setUp(() {
    mockRepository = MockChecklistRepository();
    useCase = GetChecklistWithItemsUseCase(mockRepository);
    watchUseCase = WatchChecklistWithItemsUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testChecklist = ChecklistEntity(
    id: 'checklist-123',
    tripId: 'trip-123',
    name: 'Packing List',
    createdBy: 'user-123',
    createdAt: now,
    updatedAt: now,
    creatorName: 'John Doe',
  );

  final testItem1 = ChecklistItemEntity(
    id: 'item-1',
    checklistId: 'checklist-123',
    title: 'Pack clothes',
    isCompleted: false,
    orderIndex: 0,
    createdAt: now,
  );

  final testItem2 = ChecklistItemEntity(
    id: 'item-2',
    checklistId: 'checklist-123',
    title: 'Pack toiletries',
    isCompleted: true,
    completedBy: 'user-123',
    completedAt: now,
    orderIndex: 1,
    createdAt: now,
  );

  final testChecklistWithItems = ChecklistWithItemsEntity(
    checklist: testChecklist,
    items: [testItem1, testItem2],
  );

  final emptyChecklistWithItems = ChecklistWithItemsEntity(
    checklist: testChecklist,
    items: [],
  );

  group('GetChecklistWithItemsUseCase', () {
    group('Positive Cases', () {
      test('should return checklist with items', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => testChecklistWithItems,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.checklist.id, 'checklist-123');
        expect(result.items.length, 2);
        verify(mockRepository.getChecklistWithItems('checklist-123')).called(1);
      });

      test('should return checklist with empty items list', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => emptyChecklistWithItems,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.checklist.id, 'checklist-123');
        expect(result.items, isEmpty);
      });

      test('should return checklist with correct progress (0/0)', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => emptyChecklistWithItems,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.progress, 0.0);
        expect(result.completedCount, 0);
        expect(result.pendingCount, 0);
      });

      test('should return checklist with correct progress (1/2)', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => testChecklistWithItems,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.progress, 0.5);
        expect(result.completedCount, 1);
        expect(result.pendingCount, 1);
      });

      test('should return checklist with correct progress (2/2)', () async {
        // Arrange
        final allCompletedItems = [
          testItem1.copyWith(isCompleted: true),
          testItem2,
        ];
        final allCompletedChecklist = ChecklistWithItemsEntity(
          checklist: testChecklist,
          items: [
            ChecklistItemEntity(
              id: 'item-1',
              checklistId: 'checklist-123',
              title: 'Pack clothes',
              isCompleted: true,
              orderIndex: 0,
              createdAt: now,
            ),
            testItem2,
          ],
        );
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => allCompletedChecklist,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.progress, 1.0);
        expect(result.completedCount, 2);
        expect(result.pendingCount, 0);
      });

      test('should return items with assignment info', () async {
        // Arrange
        final itemWithAssignment = ChecklistItemEntity(
          id: 'item-1',
          checklistId: 'checklist-123',
          title: 'Pack clothes',
          isCompleted: false,
          assignedTo: 'user-456',
          assignedToName: 'Jane Doe',
          orderIndex: 0,
          createdAt: now,
        );
        final checklistWithAssignment = ChecklistWithItemsEntity(
          checklist: testChecklist,
          items: [itemWithAssignment],
        );
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => checklistWithAssignment,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.items.first.assignedTo, 'user-456');
        expect(result.items.first.assignedToName, 'Jane Doe');
      });

      test('should return items with completion info', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => testChecklistWithItems,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        final completedItem = result.items.where((i) => i.isCompleted).first;
        expect(completedItem.completedBy, 'user-123');
        expect(completedItem.completedAt, isNotNull);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty checklist ID', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Checklist ID cannot be empty',
          )),
        );
        verifyNever(mockRepository.getChecklistWithItems(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('checklist-123')).thenThrow(
          Exception('Database error'),
        );

        // Act & Assert
        expect(
          () => useCase('checklist-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should propagate not found error', () async {
        // Arrange
        when(mockRepository.getChecklistWithItems('non-existent')).thenThrow(
          Exception('Checklist not found'),
        );

        // Act & Assert
        expect(
          () => useCase('non-existent'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format checklist ID', () async {
        // Arrange
        const uuidChecklistId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getChecklistWithItems(uuidChecklistId)).thenAnswer(
          (_) async => testChecklistWithItems,
        );

        // Act
        final result = await useCase(uuidChecklistId);

        // Assert
        expect(result, isNotNull);
      });

      test('should handle checklist with many items', () async {
        // Arrange
        final manyItems = List.generate(
          100,
          (i) => ChecklistItemEntity(
            id: 'item-$i',
            checklistId: 'checklist-123',
            title: 'Item $i',
            isCompleted: i % 2 == 0,
            orderIndex: i,
            createdAt: now,
          ),
        );
        final checklistWithManyItems = ChecklistWithItemsEntity(
          checklist: testChecklist,
          items: manyItems,
        );
        when(mockRepository.getChecklistWithItems('checklist-123')).thenAnswer(
          (_) async => checklistWithManyItems,
        );

        // Act
        final result = await useCase('checklist-123');

        // Assert
        expect(result.items.length, 100);
        expect(result.completedCount, 50);
        expect(result.pendingCount, 50);
        expect(result.progress, 0.5);
      });
    });
  });

  group('WatchChecklistWithItemsUseCase', () {
    group('Positive Cases', () {
      test('should return stream of checklist with items', () {
        // Arrange
        when(mockRepository.watchChecklistWithItems('checklist-123')).thenAnswer(
          (_) => Stream.value(testChecklistWithItems),
        );

        // Act
        final result = watchUseCase('checklist-123');

        // Assert
        expect(result, isA<Stream<ChecklistWithItemsEntity>>());
        verify(mockRepository.watchChecklistWithItems('checklist-123')).called(1);
      });

      test('should emit checklist with items from stream', () async {
        // Arrange
        when(mockRepository.watchChecklistWithItems('checklist-123')).thenAnswer(
          (_) => Stream.value(testChecklistWithItems),
        );

        // Act
        final stream = watchUseCase('checklist-123');
        final result = await stream.first;

        // Assert
        expect(result.checklist.id, 'checklist-123');
        expect(result.items.length, 2);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty checklist ID', () {
        // Act & Assert
        expect(
          () => watchUseCase(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Checklist ID cannot be empty',
          )),
        );
        verifyNever(mockRepository.watchChecklistWithItems(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should throw when repository throws', () {
        // Arrange
        when(mockRepository.watchChecklistWithItems('checklist-123')).thenThrow(
          Exception('Stream error'),
        );

        // Act & Assert
        expect(
          () => watchUseCase('checklist-123'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}

// Extension to help with tests (copyWith for ChecklistItemEntity)
extension ChecklistItemEntityCopyWith on ChecklistItemEntity {
  ChecklistItemEntity copyWith({
    String? id,
    String? checklistId,
    String? title,
    bool? isCompleted,
    String? assignedTo,
    String? completedBy,
    DateTime? completedAt,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedToName,
    String? completedByName,
  }) {
    return ChecklistItemEntity(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedToName: assignedToName ?? this.assignedToName,
      completedByName: completedByName ?? this.completedByName,
    );
  }
}
