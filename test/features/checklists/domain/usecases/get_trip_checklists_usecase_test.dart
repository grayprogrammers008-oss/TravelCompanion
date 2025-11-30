import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/domain/repositories/checklist_repository.dart';
import 'package:travel_crew/features/checklists/domain/usecases/get_trip_checklists_usecase.dart';

import 'get_trip_checklists_usecase_test.mocks.dart';

@GenerateMocks([ChecklistRepository])
void main() {
  late GetTripChecklistsUseCase useCase;
  late WatchTripChecklistsUseCase watchUseCase;
  late MockChecklistRepository mockRepository;

  setUp(() {
    mockRepository = MockChecklistRepository();
    useCase = GetTripChecklistsUseCase(mockRepository);
    watchUseCase = WatchTripChecklistsUseCase(mockRepository);
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

  final testChecklist2 = ChecklistEntity(
    id: 'checklist-456',
    tripId: 'trip-123',
    name: 'Shopping List',
    createdBy: 'user-456',
    createdAt: now,
    updatedAt: now,
    creatorName: 'Jane Doe',
  );

  group('GetTripChecklistsUseCase', () {
    group('Positive Cases', () {
      test('should return list of checklists for trip', () async {
        // Arrange
        when(mockRepository.getTripChecklists('trip-123')).thenAnswer(
          (_) async => [testChecklist],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 1);
        expect(result.first.id, 'checklist-123');
        expect(result.first.name, 'Packing List');
        verify(mockRepository.getTripChecklists('trip-123')).called(1);
      });

      test('should return empty list when trip has no checklists', () async {
        // Arrange
        when(mockRepository.getTripChecklists('trip-456')).thenAnswer(
          (_) async => [],
        );

        // Act
        final result = await useCase('trip-456');

        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getTripChecklists('trip-456')).called(1);
      });

      test('should return multiple checklists for trip', () async {
        // Arrange
        when(mockRepository.getTripChecklists('trip-123')).thenAnswer(
          (_) async => [testChecklist, testChecklist2],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 2);
        expect(result[0].name, 'Packing List');
        expect(result[1].name, 'Shopping List');
      });

      test('should return checklists with all properties', () async {
        // Arrange
        when(mockRepository.getTripChecklists('trip-123')).thenAnswer(
          (_) async => [testChecklist],
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        final checklist = result.first;
        expect(checklist.id, 'checklist-123');
        expect(checklist.tripId, 'trip-123');
        expect(checklist.name, 'Packing List');
        expect(checklist.createdBy, 'user-123');
        expect(checklist.creatorName, 'John Doe');
        expect(checklist.createdAt, isNotNull);
        expect(checklist.updatedAt, isNotNull);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty trip ID', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Trip ID cannot be empty',
          )),
        );
        verifyNever(mockRepository.getTripChecklists(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.getTripChecklists('trip-123')).thenThrow(
          Exception('Database error'),
        );

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should propagate network error', () async {
        // Arrange
        when(mockRepository.getTripChecklists('trip-123')).thenThrow(
          Exception('Network unavailable'),
        );

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getTripChecklists(uuidTripId)).thenAnswer(
          (_) async => [testChecklist],
        );

        // Act
        final result = await useCase(uuidTripId);

        // Assert
        expect(result.length, 1);
      });

      test('should handle large number of checklists', () async {
        // Arrange
        final manyChecklists = List.generate(
          50,
          (i) => ChecklistEntity(
            id: 'checklist-$i',
            tripId: 'trip-123',
            name: 'Checklist $i',
            createdBy: 'user-123',
            createdAt: now,
          ),
        );
        when(mockRepository.getTripChecklists('trip-123')).thenAnswer(
          (_) async => manyChecklists,
        );

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.length, 50);
      });
    });
  });

  group('WatchTripChecklistsUseCase', () {
    group('Positive Cases', () {
      test('should return stream of checklists', () {
        // Arrange
        when(mockRepository.watchTripChecklists('trip-123')).thenAnswer(
          (_) => Stream.value([testChecklist]),
        );

        // Act
        final result = watchUseCase('trip-123');

        // Assert
        expect(result, isA<Stream<List<ChecklistEntity>>>());
        verify(mockRepository.watchTripChecklists('trip-123')).called(1);
      });

      test('should emit checklists from stream', () async {
        // Arrange
        when(mockRepository.watchTripChecklists('trip-123')).thenAnswer(
          (_) => Stream.value([testChecklist, testChecklist2]),
        );

        // Act
        final stream = watchUseCase('trip-123');
        final result = await stream.first;

        // Assert
        expect(result.length, 2);
      });

      test('should emit empty list when no checklists', () async {
        // Arrange
        when(mockRepository.watchTripChecklists('trip-123')).thenAnswer(
          (_) => Stream.value([]),
        );

        // Act
        final stream = watchUseCase('trip-123');
        final result = await stream.first;

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty trip ID', () {
        // Act & Assert
        expect(
          () => watchUseCase(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Trip ID cannot be empty',
          )),
        );
        verifyNever(mockRepository.watchTripChecklists(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should throw when repository throws', () {
        // Arrange
        when(mockRepository.watchTripChecklists('trip-123')).thenThrow(
          Exception('Stream error'),
        );

        // Act & Assert
        expect(
          () => watchUseCase('trip-123'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
