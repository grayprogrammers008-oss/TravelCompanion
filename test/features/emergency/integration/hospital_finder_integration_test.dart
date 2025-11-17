import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:travel_crew/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:travel_crew/features/emergency/domain/usecases/find_nearest_hospitals_usecase.dart';
import 'package:travel_crew/core/services/location_service.dart';
import 'package:travel_crew/shared/models/hospital_model.dart';

import 'hospital_finder_integration_test.mocks.dart';

@GenerateMocks([EmergencyRemoteDataSource, LocationService])
void main() {
  late MockEmergencyRemoteDataSource mockDataSource;
  late MockLocationService mockLocationService;
  late EmergencyRepositoryImpl repository;
  late FindNearestHospitalsUseCase useCase;

  setUp(() {
    mockDataSource = MockEmergencyRemoteDataSource();
    mockLocationService = MockLocationService();
    repository = EmergencyRepositoryImpl(mockDataSource, mockLocationService);
    useCase = FindNearestHospitalsUseCase(repository);
  });

  group('Hospital Finder Integration Tests', () {
    final sanFranciscoHospitals = [
      HospitalModel(
        id: 'ucsf-1',
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
        services: ['emergency', 'surgery', 'cardiology', 'neurology', 'oncology'],
        specialties: ['trauma', 'cardiac', 'neuro', 'pediatric'],
        rating: 4.5,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 2.5,
      ),
      HospitalModel(
        id: 'sfgh-1',
        name: 'San Francisco General Hospital',
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
        services: ['emergency', 'surgery', 'trauma', 'burn_unit'],
        specialties: ['trauma', 'burn', 'psychiatric'],
        rating: 4.3,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 3.1,
      ),
      HospitalModel(
        id: 'cpmc-1',
        name: 'California Pacific Medical Center',
        address: '2333 Buchanan St',
        city: 'San Francisco',
        state: 'CA',
        latitude: 37.7917,
        longitude: -122.4314,
        type: HospitalType.general,
        hasEmergencyRoom: true,
        hasTraumaCenter: false,
        is24_7: true,
        services: ['emergency', 'surgery', 'maternity', 'orthopedics'],
        specialties: ['orthopedic', 'maternity', 'cardiac'],
        rating: 4.4,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 1.8,
      ),
      HospitalModel(
        id: 'kaiser-sf-1',
        name: 'Kaiser Permanente San Francisco',
        address: '2425 Geary Blvd',
        city: 'San Francisco',
        state: 'CA',
        latitude: 37.7829,
        longitude: -122.4364,
        type: HospitalType.general,
        hasEmergencyRoom: true,
        hasTraumaCenter: false,
        is24_7: true,
        services: ['emergency', 'primary_care', 'urgent_care', 'lab'],
        specialties: ['family_medicine', 'internal_medicine'],
        rating: 4.2,
        createdAt: DateTime(2024, 1, 1),
        distanceKm: 2.0,
      ),
    ];

    test('should find nearest hospitals in San Francisco', () async {
      // Arrange - User at Golden Gate Park
      const userLat = 37.7694;
      const userLng = -122.4862;

      when(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).thenAnswer((_) async => sanFranciscoHospitals);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
      );

      // Assert
      expect(hospitals, isNotEmpty);
      expect(hospitals.length, 4);

      // Verify all returned hospitals have emergency rooms
      expect(
        hospitals.every((h) => h.hasEmergencyRoom),
        true,
        reason: 'All hospitals should have emergency rooms',
      );

      // Verify hospitals are in San Francisco
      expect(
        hospitals.every((h) => h.city == 'San Francisco'),
        true,
        reason: 'All hospitals should be in San Francisco',
      );

      // Verify repository was called with correct parameters
      verify(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).called(1);
    });

    test('should filter only trauma centers', () async {
      // Arrange
      const userLat = 37.7749;
      const userLng = -122.4194;

      final traumaCenters = sanFranciscoHospitals
          .where((h) => h.hasTraumaCenter)
          .toList();

      when(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).thenAnswer((_) async => traumaCenters);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
      );

      // Assert
      expect(hospitals.length, 2);
      expect(
        hospitals.every((h) => h.hasTraumaCenter),
        true,
        reason: 'All hospitals should be trauma centers',
      );
      expect(
        hospitals.any((h) => h.traumaLevel == TraumaLevel.levelOne),
        true,
        reason: 'Should include Level I trauma centers',
      );
    });

    test('should prioritize closer hospitals in emergency', () async {
      // Arrange
      const userLat = 37.7829;
      const userLng = -122.4364;

      when(mockDataSource.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => sanFranciscoHospitals);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
      );

      // Assert
      expect(hospitals.isNotEmpty, true);

      // Verify hospitals are sorted by priority score
      for (int i = 0; i < hospitals.length - 1; i++) {
        expect(
          hospitals[i].emergencyPriorityScore,
          greaterThanOrEqualTo(hospitals[i + 1].emergencyPriorityScore),
          reason: 'Hospitals should be sorted by emergency priority score (highest first)',
        );
      }
    });

    test('should handle search with custom distance radius', () async {
      // Arrange
      const userLat = 37.7749;
      const userLng = -122.4194;
      const maxDistance = 10.0;

      final nearbyHospitals = sanFranciscoHospitals
          .where((h) => (h.distanceKm ?? 0) <= maxDistance)
          .toList();

      when(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: maxDistance,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).thenAnswer((_) async => nearbyHospitals);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: maxDistance,
      );

      // Assert
      expect(hospitals.isNotEmpty, true);
      expect(
        hospitals.every((h) => (h.distanceKm ?? 0) <= maxDistance),
        true,
        reason: 'All hospitals should be within $maxDistance km',
      );
    });

    test('should find only 24/7 hospitals when requested', () async {
      // Arrange
      const userLat = 37.7749;
      const userLng = -122.4194;

      when(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: true,
      )).thenAnswer((_) async => sanFranciscoHospitals);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
        only24_7: true,
      );

      // Assert
      expect(
        hospitals.every((h) => h.is24_7),
        true,
        reason: 'All hospitals should be open 24/7',
      );
    });

    test('should handle empty results gracefully', () async {
      // Arrange - Remote area with no nearby hospitals
      const userLat = 40.7128;
      const userLng = -74.0060;

      when(mockDataSource.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => []);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
      );

      // Assert
      expect(hospitals, isEmpty);
    });

    test('should handle data source errors appropriately', () async {
      // Arrange
      when(mockDataSource.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenThrow(Exception('Database connection failed'));

      // Act & Assert
      expect(
        () => useCase(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should limit results to specified count', () async {
      // Arrange
      const userLat = 37.7749;
      const userLng = -122.4194;
      const limit = 2;

      when(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: 50.0,
        limit: limit,
        onlyEmergency: true,
        only24_7: false,
      )).thenAnswer((_) async => sanFranciscoHospitals.take(limit).toList());

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
        limit: limit,
      );

      // Assert
      expect(hospitals.length, lessThanOrEqualTo(limit));
      verify(mockDataSource.findNearestHospitals(
        latitude: userLat,
        longitude: userLng,
        maxDistanceKm: 50.0,
        limit: limit,
        onlyEmergency: true,
        only24_7: false,
      )).called(1);
    });

    test('should include hospital details and ratings', () async {
      // Arrange
      const userLat = 37.7749;
      const userLng = -122.4194;

      when(mockDataSource.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => sanFranciscoHospitals);

      // Act
      final hospitals = await useCase(
        latitude: userLat,
        longitude: userLng,
      );

      // Assert
      for (final hospital in hospitals) {
        expect(hospital.id, isNotEmpty);
        expect(hospital.name, isNotEmpty);
        expect(hospital.address, isNotEmpty);
        expect(hospital.city, isNotEmpty);
        expect(hospital.state, isNotEmpty);
        expect(hospital.latitude, isNotNull);
        expect(hospital.longitude, isNotNull);
        expect(hospital.distanceKm, isNotNull);

        // Verify ratings are in valid range
        if (hospital.rating != null) {
          expect(hospital.rating, greaterThanOrEqualTo(0.0));
          expect(hospital.rating, lessThanOrEqualTo(5.0));
        }
      }
    });
  });
}
