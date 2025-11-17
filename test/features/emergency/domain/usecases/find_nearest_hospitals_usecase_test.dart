import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/find_nearest_hospitals_usecase.dart';
import 'package:travel_crew/shared/models/hospital_model.dart';

import 'find_nearest_hospitals_usecase_test.mocks.dart';

@GenerateMocks([EmergencyRepository])
void main() {
  late MockEmergencyRepository mockRepository;
  late FindNearestHospitalsUseCase useCase;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = FindNearestHospitalsUseCase(mockRepository);
  });

  group('FindNearestHospitalsUseCase', () {
    final testHospitals = [
      HospitalModel(
        id: 'hospital1',
        name: 'UCSF Medical Center',
        address: '505 Parnassus Ave',
        city: 'San Francisco',
        state: 'CA',
        latitude: 37.7625,
        longitude: -122.4589,
        type: HospitalType.traumaCenter,
        hasEmergencyRoom: true,
        hasTraumaCenter: true,
        traumaLevel: TraumaLevel.levelOne,
        is24_7: true,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 2.5,
        rating: 4.5,
      ),
      HospitalModel(
        id: 'hospital2',
        name: 'SF General Hospital',
        address: '1001 Potrero Ave',
        city: 'San Francisco',
        state: 'CA',
        latitude: 37.7571,
        longitude: -122.4045,
        type: HospitalType.traumaCenter,
        hasEmergencyRoom: true,
        hasTraumaCenter: true,
        traumaLevel: TraumaLevel.levelOne,
        is24_7: true,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 3.1,
        rating: 4.3,
      ),
      HospitalModel(
        id: 'hospital3',
        name: 'Kaiser Permanente',
        address: '2425 Geary Blvd',
        city: 'San Francisco',
        state: 'CA',
        latitude: 37.7829,
        longitude: -122.4364,
        type: HospitalType.general,
        hasEmergencyRoom: true,
        hasTraumaCenter: false,
        is24_7: true,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 1.8,
        rating: 4.2,
      ),
    ];

    test('should find nearest hospitals successfully', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).thenAnswer((_) async => testHospitals);

      // Act
      final result = await useCase(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Assert
      expect(result, isA<List<HospitalModel>>());
      expect(result.length, 3);
      verify(mockRepository.findNearestHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).called(1);
    });

    test('should throw ArgumentError for invalid latitude (too low)', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: -91.0,
          longitude: -122.4194,
        ),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      ));
    });

    test('should throw ArgumentError for invalid latitude (too high)', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 91.0,
          longitude: -122.4194,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for invalid longitude (too low)', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -181.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for invalid longitude (too high)', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: 181.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for negative maxDistanceKm', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -122.4194,
          maxDistanceKm: -10.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for zero maxDistanceKm', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -122.4194,
          maxDistanceKm: 0.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for negative limit', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -122.4194,
          limit: -5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for zero limit', () async {
      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -122.4194,
          limit: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should accept valid parameters with custom values', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 25.0,
        limit: 5,
        onlyEmergency: false,
        only24_7: true,
      )).thenAnswer((_) async => testHospitals.take(1).toList());

      // Act
      final result = await useCase(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 25.0,
        limit: 5,
        onlyEmergency: false,
        only24_7: true,
      );

      // Assert
      expect(result, isA<List<HospitalModel>>());
      verify(mockRepository.findNearestHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 25.0,
        limit: 5,
        onlyEmergency: false,
        only24_7: true,
      )).called(1);
    });

    test('should return empty list when no hospitals found', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => []);

      // Act
      final result = await useCase(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Assert
      expect(result, isEmpty);
    });

    test('should sort hospitals by emergency priority score', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => testHospitals);

      // Act
      final result = await useCase(
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Assert
      // Verify hospitals are sorted by priority score (descending)
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].emergencyPriorityScore,
          greaterThanOrEqualTo(result[i + 1].emergencyPriorityScore),
        );
      }
    });

    test('should handle repository errors by rethrowing', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should accept boundary latitude values', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => []);

      // Act - Test minimum latitude
      await useCase(latitude: -90.0, longitude: 0.0);

      // Act - Test maximum latitude
      await useCase(latitude: 90.0, longitude: 0.0);

      // Assert
      verify(mockRepository.findNearestHospitals(
        latitude: -90.0,
        longitude: 0.0,
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).called(1);

      verify(mockRepository.findNearestHospitals(
        latitude: 90.0,
        longitude: 0.0,
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).called(1);
    });

    test('should accept boundary longitude values', () async {
      // Arrange
      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => []);

      // Act - Test minimum longitude
      await useCase(latitude: 0.0, longitude: -180.0);

      // Act - Test maximum longitude
      await useCase(latitude: 0.0, longitude: 180.0);

      // Assert
      verify(mockRepository.findNearestHospitals(
        latitude: 0.0,
        longitude: -180.0,
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).called(1);

      verify(mockRepository.findNearestHospitals(
        latitude: 0.0,
        longitude: 180.0,
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).called(1);
    });
  });
}
