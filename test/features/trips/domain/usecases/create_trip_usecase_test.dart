import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/create_trip_usecase.dart';

import 'create_trip_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late CreateTripUseCase useCase;
  late MockTripRepository mockTripRepository;

  setUp(() {
    mockTripRepository = MockTripRepository();
    useCase = CreateTripUseCase(mockTripRepository);
  });

  const testUserId = 'user123';
  const testName = 'Trip to Paris';
  const testDestination = 'Paris, France';
  final testStartDate = DateTime(2025, 10, 1);
  final testEndDate = DateTime(2025, 10, 10);
  const testDescription = 'Amazing trip to Paris';

  final testTrip = TripModel(
    id: 'trip123',
    name: testName,
    destination: testDestination,
    startDate: testStartDate,
    endDate: testEndDate,
    description: testDescription,
    createdBy: testUserId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('CreateTripUseCase', () {
    test('should create trip with valid data', () async {
      // Arrange
      when(mockTripRepository.createTrip(
        userId: testUserId,
        name: testName,
        destination: testDestination,
        startDate: testStartDate,
        endDate: testEndDate,
        description: testDescription,
        coverImageUrl: null,
      )).thenAnswer((_) async => testTrip);

      // Act
      final result = await useCase(
        userId: testUserId,
        name: testName,
        destination: testDestination,
        startDate: testStartDate,
        endDate: testEndDate,
        description: testDescription,
      );

      // Assert
      expect(result, equals(testTrip));
      verify(mockTripRepository.createTrip(
        userId: testUserId,
        name: testName,
        destination: testDestination,
        startDate: testStartDate,
        endDate: testEndDate,
        description: testDescription,
        coverImageUrl: null,
      )).called(1);
    });

    test('should throw exception when name is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          userId: testUserId,
          name: '',
          destination: testDestination,
          startDate: testStartDate,
          endDate: testEndDate,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when destination is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          userId: testUserId,
          name: testName,
          destination: '',
          startDate: testStartDate,
          endDate: testEndDate,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when end date is before start date', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          userId: testUserId,
          name: testName,
          destination: testDestination,
          startDate: testEndDate,
          endDate: testStartDate,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when userId is empty', () async {
      // Arrange & Act & Assert
      expect(
        () => useCase(
          userId: '',
          name: testName,
          destination: testDestination,
          startDate: testStartDate,
          endDate: testEndDate,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
