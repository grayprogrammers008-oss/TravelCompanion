import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/domain/repositories/checklist_repository.dart';
import 'package:travel_crew/features/checklists/domain/usecases/create_checklist_usecase.dart';

import 'create_checklist_usecase_test.mocks.dart';

@GenerateMocks([ChecklistRepository])
void main() {
  late CreateChecklistUseCase useCase;
  late MockChecklistRepository mockRepository;

  setUp(() {
    mockRepository = MockChecklistRepository();
    useCase = CreateChecklistUseCase(mockRepository);
  });

  group('CreateChecklistUseCase', () {
    const testTripId = 'trip-123';
    const testName = 'Packing List';
    const testCreatedBy = 'user-456';

    final testChecklist = ChecklistEntity(
      id: 'checklist-789',
      tripId: testTripId,
      name: testName,
      createdBy: testCreatedBy,
      createdAt: DateTime(2025, 1, 1),
    );

    test('should create checklist successfully with valid parameters', () async {
      // Arrange
      when(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      )).thenAnswer((_) async => testChecklist);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(testChecklist));
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should trim whitespace from checklist name', () async {
      // Arrange
      const nameWithWhitespace = '  Packing List  ';
      when(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName, // Should be trimmed
        createdBy: testCreatedBy,
      )).thenAnswer((_) async => testChecklist);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: nameWithWhitespace,
        createdBy: testCreatedBy,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(testChecklist));
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName, // Verify trimmed name was used
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should throw ArgumentError when tripId is empty', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: '', // Empty trip ID
        name: testName,
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () async => await useCase(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Trip ID cannot be empty',
        )),
      );

      verifyNever(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      ));
    });

    test('should throw ArgumentError when name is empty', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: '', // Empty name
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () async => await useCase(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Checklist name cannot be empty',
        )),
      );

      verifyNever(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      ));
    });

    test('should throw ArgumentError when name is only whitespace', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: '   ', // Only whitespace
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () async => await useCase(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Checklist name cannot be empty',
        )),
      );

      verifyNever(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      ));
    });

    test('should throw ArgumentError when name exceeds 100 characters', () async {
      // Arrange
      final longName = 'A' * 101; // 101 characters
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: longName,
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () async => await useCase(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Checklist name cannot exceed 100 characters',
        )),
      );

      verifyNever(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      ));
    });

    test('should accept name with exactly 100 characters', () async {
      // Arrange
      final maxLengthName = 'A' * 100; // Exactly 100 characters
      final checklistWithMaxName = ChecklistEntity(
        id: 'checklist-789',
        tripId: testTripId,
        name: maxLengthName,
        createdBy: testCreatedBy,
        createdAt: DateTime(2025, 1, 1),
      );

      when(mockRepository.createChecklist(
        tripId: testTripId,
        name: maxLengthName,
        createdBy: testCreatedBy,
      )).thenAnswer((_) async => checklistWithMaxName);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: maxLengthName,
        createdBy: testCreatedBy,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(checklistWithMaxName));
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: maxLengthName,
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should throw ArgumentError when createdBy is empty', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: testName,
        createdBy: '', // Empty creator ID
      );

      // Act & Assert
      expect(
        () async => await useCase(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Creator ID cannot be empty',
        )),
      );

      verifyNever(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      ));
    });

    test('should propagate repository exceptions', () async {
      // Arrange
      final exception = Exception('Database connection failed');
      when(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      )).thenThrow(exception);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () async => await useCase(params),
        throwsA(equals(exception)),
      );

      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should handle special characters in checklist name', () async {
      // Arrange
      const specialName = 'Pack! @Home #Items \$100';
      final checklistWithSpecialName = ChecklistEntity(
        id: 'checklist-789',
        tripId: testTripId,
        name: specialName,
        createdBy: testCreatedBy,
        createdAt: DateTime(2025, 1, 1),
      );

      when(mockRepository.createChecklist(
        tripId: testTripId,
        name: specialName,
        createdBy: testCreatedBy,
      )).thenAnswer((_) async => checklistWithSpecialName);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: specialName,
        createdBy: testCreatedBy,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(checklistWithSpecialName));
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: specialName,
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should handle unicode characters in checklist name', () async {
      // Arrange
      const unicodeName = '打包清单 🎒';
      final checklistWithUnicodeName = ChecklistEntity(
        id: 'checklist-789',
        tripId: testTripId,
        name: unicodeName,
        createdBy: testCreatedBy,
        createdAt: DateTime(2025, 1, 1),
      );

      when(mockRepository.createChecklist(
        tripId: testTripId,
        name: unicodeName,
        createdBy: testCreatedBy,
      )).thenAnswer((_) async => checklistWithUnicodeName);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: unicodeName,
        createdBy: testCreatedBy,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(checklistWithUnicodeName));
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: unicodeName,
        createdBy: testCreatedBy,
      )).called(1);
    });
  });
}
