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

    final testChecklistEntity = ChecklistEntity(
      id: 'checklist-789',
      tripId: testTripId,
      name: testName,
      createdBy: testCreatedBy,
      createdAt: DateTime(2025, 10, 20),
      updatedAt: DateTime(2025, 10, 20),
    );

    test('should create checklist when all parameters are valid', () async {
      // Arrange
      when(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      )).thenAnswer((_) async => testChecklistEntity);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, equals(testChecklistEntity));
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should trim whitespace from checklist name', () async {
      // Arrange
      const nameWithWhitespace = '  Packing List  ';
      when(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      )).thenAnswer((_) async => testChecklistEntity);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: nameWithWhitespace,
        createdBy: testCreatedBy,
      );

      // Act
      await useCase(params);

      // Assert
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: 'Packing List', // Trimmed
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should throw ArgumentError when trip ID is empty', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: '',
        name: testName,
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () => useCase(params),
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

    test('should throw ArgumentError when checklist name is empty', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: '',
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () => useCase(params),
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

    test('should throw ArgumentError when checklist name is only whitespace', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: '   ',
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () => useCase(params),
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

    test('should throw ArgumentError when checklist name exceeds 100 characters', () async {
      // Arrange
      final longName = 'A' * 101; // 101 characters
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: longName,
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () => useCase(params),
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

    test('should accept checklist name with exactly 100 characters', () async {
      // Arrange
      final maxLengthName = 'A' * 100; // Exactly 100 characters
      when(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      )).thenAnswer((_) async => testChecklistEntity);

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: maxLengthName,
        createdBy: testCreatedBy,
      );

      // Act
      await useCase(params);

      // Assert
      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: maxLengthName,
        createdBy: testCreatedBy,
      )).called(1);
    });

    test('should throw ArgumentError when creator ID is empty', () async {
      // Arrange
      final params = CreateChecklistParams(
        tripId: testTripId,
        name: testName,
        createdBy: '',
      );

      // Act & Assert
      expect(
        () => useCase(params),
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
      const errorMessage = 'Database connection failed';
      when(mockRepository.createChecklist(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
      )).thenThrow(Exception(errorMessage));

      final params = CreateChecklistParams(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      );

      // Act & Assert
      expect(
        () => useCase(params),
        throwsA(isA<Exception>()),
      );

      verify(mockRepository.createChecklist(
        tripId: testTripId,
        name: testName,
        createdBy: testCreatedBy,
      )).called(1);
    });
  });
}
