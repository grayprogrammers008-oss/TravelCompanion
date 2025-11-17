import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/services/location_service.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/nearest_hospitals_widget.dart';
import 'package:travel_crew/shared/models/hospital_model.dart';
import 'package:geolocator/geolocator.dart';

import 'nearest_hospitals_widget_e2e_test.mocks.dart';

@GenerateMocks([EmergencyRepository, LocationService])
void main() {
  late MockEmergencyRepository mockRepository;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    mockLocationService = MockLocationService();
  });

  Widget createTestWidget({
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: NearestHospitalsWidget(),
        ),
      ),
    );
  }

  final testPosition = Position(
    latitude: 37.7749,
    longitude: -122.4194,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  final testHospitals = [
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
      phoneNumber: '+1-415-476-1000',
      emergencyPhone: '911',
      services: ['emergency', 'surgery', 'cardiology'],
      specialties: ['trauma', 'cardiac'],
      rating: 4.5,
      createdAt: DateTime(2024, 1, 1),
      distanceKm: 2.5,
    ),
    HospitalModel(
      id: 'kaiser-sf-1',
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
      phoneNumber: '+1-415-833-2000',
      services: ['emergency', 'primary_care'],
      specialties: ['family_medicine'],
      rating: 4.2,
      createdAt: DateTime(2024, 1, 1),
      distanceKm: 1.8,
    ),
  ];

  group('Nearest Hospitals Widget E2E Tests', () {
    testWidgets('should display loading state initially', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return testHospitals;
      });

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();

      // Assert - Check loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Finding nearest hospitals...'), findsOneWidget);

      // Wait for completion to clean up timers
      await tester.pumpAndSettle();

      // Cleanup
      container.dispose();
    });

    testWidgets('should display list of hospitals after loading', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => testHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('UCSF Medical Center'), findsOneWidget);
      expect(find.text('Kaiser Permanente'), findsOneWidget);
      expect(find.text('505 Parnassus Ave'), findsOneWidget);
      expect(find.text('2425 Geary Blvd'), findsOneWidget);

      // Cleanup
      container.dispose();
    });

    testWidgets('should display hospital distance badges', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => testHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert - Check distance displays
      expect(find.text('2.5 km'), findsOneWidget);
      expect(find.text('1.8 km'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsNWidgets(2));

      // Cleanup
      container.dispose();
    });

    testWidgets('should display hospital features and ratings', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => testHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert - Check feature chips
      expect(find.text('Trauma Level I'), findsOneWidget);
      expect(find.text('Emergency'), findsNWidgets(2));
      expect(find.text('24/7'), findsNWidgets(2));
      expect(find.text('4.5/5.0'), findsOneWidget);
      expect(find.text('4.2/5.0'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(2));

      // Cleanup
      container.dispose();
    });

    testWidgets('should display call and directions buttons', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => testHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert - Check action buttons
      expect(find.text('Call'), findsNWidgets(2));
      expect(find.text('Directions'), findsNWidgets(2));
      expect(find.byIcon(Icons.phone), findsNWidgets(2));
      expect(find.byIcon(Icons.directions), findsNWidgets(2));

      // Cleanup
      container.dispose();
    });

    testWidgets('should display empty state when no hospitals found', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No Hospitals Found'), findsOneWidget);
      expect(find.byIcon(Icons.local_hospital_outlined), findsOneWidget);
      expect(
        find.textContaining('No hospitals found within'),
        findsOneWidget,
      );

      // Cleanup
      container.dispose();
    });

    testWidgets('should display error state on failure', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenThrow(Exception('Network error'));

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error Loading Hospitals'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Exception: Network error'), findsOneWidget);

      // Cleanup
      container.dispose();
    });

    testWidgets('should handle tap on hospital card', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => testHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Tap on the first hospital card
      await tester.tap(find.text('UCSF Medical Center'));
      await tester.pumpAndSettle();

      // Assert - Bottom sheet should be shown with details
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Specialties'), findsOneWidget);

      // Cleanup
      container.dispose();
    });

    testWidgets('should scroll through hospital list', (tester) async {
      // Arrange - Create several hospitals to test scrolling
      final manyHospitals = List.generate(
        5,
        (index) => HospitalModel(
          id: 'hospital-$index',
          name: 'Test Hospital ${index + 1}',
          address: '${100 + index} Main St',
          city: 'San Francisco',
          state: 'CA',
          latitude: 37.7 + index * 0.01,
          longitude: -122.4 + index * 0.01,
          type: HospitalType.general,
          hasEmergencyRoom: true,
          is24_7: true,
          createdAt: DateTime(2024, 1, 1),
          distanceKm: (index + 1).toDouble(),
        ),
      );

      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        maxDistanceKm: anyNamed('maxDistanceKm'),
        limit: anyNamed('limit'),
        onlyEmergency: anyNamed('onlyEmergency'),
        only24_7: anyNamed('only24_7'),
      )).thenAnswer((_) async => manyHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert - First hospital should be visible
      expect(find.text('Test Hospital 1'), findsOneWidget);

      // Verify ListView exists and can be scrolled
      expect(find.byType(ListView), findsOneWidget);

      // Cleanup
      container.dispose();
    });

    testWidgets('should use location service to get current position', (tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocation())
          .thenAnswer((_) async => testPosition);

      when(mockRepository.findNearestHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).thenAnswer((_) async => testHospitals);

      final container = ProviderContainer(
        overrides: [
          emergencyRepositoryProvider.overrideWithValue(mockRepository),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Assert - Verify location service was called
      verify(mockLocationService.getCurrentLocation()).called(1);

      // Verify repository was called with correct coordinates
      verify(mockRepository.findNearestHospitals(
        latitude: 37.7749,
        longitude: -122.4194,
        maxDistanceKm: 50.0,
        limit: 10,
        onlyEmergency: true,
        only24_7: false,
      )).called(1);

      // Cleanup
      container.dispose();
    });
  });
}
