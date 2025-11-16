import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/core/services/location_service.dart';
import 'package:travel_crew/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:travel_crew/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';

import 'medical_emergency_integration_test.mocks.dart';

@GenerateMocks([EmergencyRemoteDataSource, LocationService])
void main() {
  late EmergencyRepositoryImpl repository;
  late MockEmergencyRemoteDataSource mockRemoteDataSource;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRemoteDataSource = MockEmergencyRemoteDataSource();
    mockLocationService = MockLocationService();
    repository = EmergencyRepositoryImpl(
      mockRemoteDataSource,
      mockLocationService,
    );
  });

  group('Medical Emergency Integration Tests', () {
    group('Medical Emergency with Location', () {
      test('should trigger medical emergency with real GPS coordinates',
          () async {
        // Arrange - Mock hospital location
        final hospitalCoords = {
          'latitude': 37.7749,
          'longitude': -122.4194,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => hospitalCoords);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Medical emergency assistance needed',
          latitude: 37.7749,
          longitude: -122.4194,
          contactIds: null,
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-1',
              userId: 'user1',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Medical emergency assistance needed',
              latitude: 37.7749,
              longitude: -122.4194,
              createdAt: DateTime(2024, 1, 1),
              notifiedContactIds: ['contact1', 'contact2'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Medical emergency assistance needed',
          latitude: 37.7749,
          longitude: -122.4194,
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.status, EmergencyAlertStatus.active);
        expect(result.latitude, 37.7749);
        expect(result.longitude, -122.4194);
        expect(result.message, 'Medical emergency assistance needed');
        expect(result.notifiedContactIds, ['contact1', 'contact2']);

        verify(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Medical emergency assistance needed',
          latitude: 37.7749,
          longitude: -122.4194,
          contactIds: null,
        )).called(1);
      });

      test('should trigger medical emergency during trip', () async {
        // Arrange - Mock vacation location
        final vacationCoords = {
          'latitude': 36.7783,
          'longitude': -119.4179,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => vacationCoords);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: 'vacation-trip-123',
          message: 'Medical emergency during vacation',
          latitude: 36.7783,
          longitude: -119.4179,
          contactIds: null,
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-2',
              userId: 'user1',
              tripId: 'vacation-trip-123',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Medical emergency during vacation',
              latitude: 36.7783,
              longitude: -119.4179,
              createdAt: DateTime(2024, 1, 1),
              notifiedContactIds: ['contact1', 'contact2', 'contact3'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: 'vacation-trip-123',
          message: 'Medical emergency during vacation',
          latitude: 36.7783,
          longitude: -119.4179,
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.tripId, 'vacation-trip-123');
        expect(result.latitude, 36.7783);
        expect(result.longitude, -119.4179);
        expect(result.message, 'Medical emergency during vacation');
        expect(result.notifiedContactIds.length, 3);

        verify(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: 'vacation-trip-123',
          message: 'Medical emergency during vacation',
          latitude: 36.7783,
          longitude: -119.4179,
          contactIds: null,
        )).called(1);
      });

      test('should handle medical emergency with specific contacts', () async {
        // Arrange
        final coords = {'latitude': 40.7128, 'longitude': -74.0060};

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => coords);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Heart attack - need immediate help',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: ['doctor-contact-1', 'family-contact-1'],
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-3',
              userId: 'user1',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Heart attack - need immediate help',
              latitude: 40.7128,
              longitude: -74.0060,
              createdAt: DateTime(2024, 1, 1),
              notifiedContactIds: ['doctor-contact-1', 'family-contact-1'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Heart attack - need immediate help',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: ['doctor-contact-1', 'family-contact-1'],
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.message, 'Heart attack - need immediate help');
        expect(result.notifiedContactIds, [
          'doctor-contact-1',
          'family-contact-1',
        ]);

        verify(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Heart attack - need immediate help',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: ['doctor-contact-1', 'family-contact-1'],
        )).called(1);
      });
    });

    group('Medical Emergency without Location', () {
      test('should trigger medical emergency without GPS coordinates',
          () async {
        // Arrange - No location available (permission denied)
        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => null);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Medical emergency - location unavailable',
          latitude: null,
          longitude: null,
          contactIds: null,
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-4',
              userId: 'user1',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Medical emergency - location unavailable',
              createdAt: DateTime(2024, 1, 1),
              notifiedContactIds: ['contact1'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Medical emergency - location unavailable',
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.latitude, isNull);
        expect(result.longitude, isNull);
        expect(result.message, 'Medical emergency - location unavailable');

        verify(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Medical emergency - location unavailable',
          latitude: null,
          longitude: null,
          contactIds: null,
        )).called(1);
      });

      test('should trigger medical emergency with minimal information',
          () async {
        // Arrange
        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: null,
          latitude: null,
          longitude: null,
          contactIds: null,
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-5',
              userId: 'user1',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              createdAt: DateTime(2024, 1, 1),
              notifiedContactIds: ['contact1', 'contact2'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.status, EmergencyAlertStatus.active);
        expect(result.message, isNull);
        expect(result.latitude, isNull);
        expect(result.longitude, isNull);
        expect(result.notifiedContactIds.isNotEmpty, true);

        verify(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: null,
          latitude: null,
          longitude: null,
          contactIds: null,
        )).called(1);
      });
    });

    group('Medical Emergency Alert Lifecycle', () {
      test('should acknowledge medical emergency alert', () async {
        // Arrange
        final alert = EmergencyAlertModel(
          id: 'medical-alert-6',
          userId: 'user1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.active,
          message: 'Medical emergency',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          notifiedContactIds: ['contact1', 'contact2'],
        );

        final acknowledgedAlert = EmergencyAlertModel(
          id: 'medical-alert-6',
          userId: 'user1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.acknowledged,
          message: 'Medical emergency',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          acknowledgedAt: DateTime(2024, 1, 1, 10, 5),
          acknowledgedBy: 'contact1',
          notifiedContactIds: ['contact1', 'contact2'],
        );

        when(mockRemoteDataSource.acknowledgeAlert('medical-alert-6'))
            .thenAnswer((_) async => acknowledgedAlert);

        // Act
        final result = await repository.acknowledgeAlert('medical-alert-6');

        // Assert
        expect(result.status, EmergencyAlertStatus.acknowledged);
        expect(result.acknowledgedBy, 'contact1');
        expect(result.acknowledgedAt, isNotNull);

        verify(mockRemoteDataSource.acknowledgeAlert('medical-alert-6'))
            .called(1);
      });

      test('should resolve medical emergency alert', () async {
        // Arrange
        final resolvedAlert = EmergencyAlertModel(
          id: 'medical-alert-7',
          userId: 'user1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.resolved,
          message: 'Medical emergency',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          resolvedAt: DateTime(2024, 1, 1, 11, 0),
          notifiedContactIds: ['contact1'],
        );

        when(mockRemoteDataSource.resolveAlert(
          alertId: 'medical-alert-7',
          resolution: 'Patient stabilized and transported to hospital',
        )).thenAnswer((_) async => resolvedAlert);

        // Act
        final result = await repository.resolveAlert(
          alertId: 'medical-alert-7',
          resolution: 'Patient stabilized and transported to hospital',
        );

        // Assert
        expect(result.status, EmergencyAlertStatus.resolved);
        expect(result.resolvedAt, isNotNull);

        verify(mockRemoteDataSource.resolveAlert(
          alertId: 'medical-alert-7',
          resolution: 'Patient stabilized and transported to hospital',
        )).called(1);
      });

      test('should cancel medical emergency alert', () async {
        // Arrange
        final cancelledAlert = EmergencyAlertModel(
          id: 'medical-alert-8',
          userId: 'user1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.cancelled,
          message: 'False alarm',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          resolvedAt: DateTime(2024, 1, 1, 10, 2),
          notifiedContactIds: ['contact1'],
        );

        when(mockRemoteDataSource.cancelAlert('medical-alert-8'))
            .thenAnswer((_) async => cancelledAlert);

        // Act
        final result = await repository.cancelAlert('medical-alert-8');

        // Assert
        expect(result.status, EmergencyAlertStatus.cancelled);

        verify(mockRemoteDataSource.cancelAlert('medical-alert-8')).called(1);
      });
    });

    group('Medical Emergency Type Differentiation', () {
      test('should differentiate between SOS and Medical emergencies',
          () async {
        // Arrange - SOS Alert
        final sosAlert = EmergencyAlertModel(
          id: 'sos-alert-1',
          userId: 'user1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          message: 'Critical danger - immediate help needed',
          latitude: 37.7749,
          longitude: -122.4194,
          createdAt: DateTime(2024, 1, 1),
          notifiedContactIds: ['contact1'],
        );

        // Arrange - Medical Alert
        final medicalAlert = EmergencyAlertModel(
          id: 'medical-alert-9',
          userId: 'user1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.active,
          message: 'Medical assistance required',
          latitude: 37.7749,
          longitude: -122.4194,
          createdAt: DateTime(2024, 1, 1),
          notifiedContactIds: ['contact1'],
        );

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: 'Critical danger - immediate help needed',
          latitude: 37.7749,
          longitude: -122.4194,
          contactIds: null,
        )).thenAnswer((_) async => sosAlert);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Medical assistance required',
          latitude: 37.7749,
          longitude: -122.4194,
          contactIds: null,
        )).thenAnswer((_) async => medicalAlert);

        // Act
        final sosResult = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          message: 'Critical danger - immediate help needed',
          latitude: 37.7749,
          longitude: -122.4194,
        );

        final medicalResult = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Medical assistance required',
          latitude: 37.7749,
          longitude: -122.4194,
        );

        // Assert
        expect(sosResult.type, EmergencyAlertType.sos);
        expect(medicalResult.type, EmergencyAlertType.medical);
        expect(sosResult.message, 'Critical danger - immediate help needed');
        expect(medicalResult.message, 'Medical assistance required');
      });

      test('should differentiate between Help and Medical emergencies',
          () async {
        // Arrange - Help Alert
        final helpAlert = EmergencyAlertModel(
          id: 'help-alert-1',
          userId: 'user1',
          type: EmergencyAlertType.help,
          status: EmergencyAlertStatus.active,
          message: 'Need assistance with navigation',
          createdAt: DateTime(2024, 1, 1),
          notifiedContactIds: ['contact1'],
        );

        // Arrange - Medical Alert
        final medicalAlert = EmergencyAlertModel(
          id: 'medical-alert-10',
          userId: 'user1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.active,
          message: 'Feeling dizzy and nauseous',
          createdAt: DateTime(2024, 1, 1),
          notifiedContactIds: ['contact1'],
        );

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          tripId: null,
          message: 'Need assistance with navigation',
          latitude: null,
          longitude: null,
          contactIds: null,
        )).thenAnswer((_) async => helpAlert);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Feeling dizzy and nauseous',
          latitude: null,
          longitude: null,
          contactIds: null,
        )).thenAnswer((_) async => medicalAlert);

        // Act
        final helpResult = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          message: 'Need assistance with navigation',
        );

        final medicalResult = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Feeling dizzy and nauseous',
        );

        // Assert
        expect(helpResult.type, EmergencyAlertType.help);
        expect(medicalResult.type, EmergencyAlertType.medical);
        expect(helpResult.message, 'Need assistance with navigation');
        expect(medicalResult.message, 'Feeling dizzy and nauseous');
      });
    });

    group('Error Handling', () {
      test('should handle network error when triggering medical alert',
          () async {
        // Arrange
        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: anyNamed('message'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          contactIds: anyNamed('contactIds'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.triggerEmergencyAlert(
            type: EmergencyAlertType.medical,
            message: 'Medical emergency',
          ),
          throwsException,
        );
      });

      test('should handle timeout when triggering medical alert', () async {
        // Arrange
        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: anyNamed('message'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          contactIds: anyNamed('contactIds'),
        )).thenThrow(Exception('Request timeout'));

        // Act & Assert
        expect(
          () => repository.triggerEmergencyAlert(
            type: EmergencyAlertType.medical,
            message: 'Medical emergency',
          ),
          throwsException,
        );
      });

      test('should handle error when acknowledging medical alert fails',
          () async {
        // Arrange
        when(mockRemoteDataSource.acknowledgeAlert(any))
            .thenThrow(Exception('Failed to acknowledge alert'));

        // Act & Assert
        expect(
          () => repository.acknowledgeAlert('medical-alert-1'),
          throwsException,
        );
      });
    });

    group('Real-world Medical Emergency Scenarios', () {
      test('should handle heart attack scenario with precise location',
          () async {
        // Arrange - Patient at home
        final homeCoords = {
          'latitude': 34.0522,
          'longitude': -118.2437,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => homeCoords);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Severe chest pain - possible heart attack',
          latitude: 34.0522,
          longitude: -118.2437,
          contactIds: ['spouse', 'doctor', 'emergency-contact'],
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-11',
              userId: 'user1',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Severe chest pain - possible heart attack',
              latitude: 34.0522,
              longitude: -118.2437,
              createdAt: DateTime(2024, 1, 1, 14, 30),
              notifiedContactIds: ['spouse', 'doctor', 'emergency-contact'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Severe chest pain - possible heart attack',
          latitude: 34.0522,
          longitude: -118.2437,
          contactIds: ['spouse', 'doctor', 'emergency-contact'],
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.message, 'Severe chest pain - possible heart attack');
        expect(result.latitude, 34.0522);
        expect(result.longitude, -118.2437);
        expect(result.notifiedContactIds.length, 3);
        expect(result.status, EmergencyAlertStatus.active);
      });

      test('should handle diabetic emergency during hiking trip', () async {
        // Arrange - Hiking trail location
        final trailCoords = {
          'latitude': 36.5781,
          'longitude': -118.2926,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => trailCoords);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: 'hiking-trip-456',
          message: 'Diabetic emergency - blood sugar critically low',
          latitude: 36.5781,
          longitude: -118.2926,
          contactIds: null,
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-12',
              userId: 'user1',
              tripId: 'hiking-trip-456',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Diabetic emergency - blood sugar critically low',
              latitude: 36.5781,
              longitude: -118.2926,
              createdAt: DateTime(2024, 1, 1, 16, 45),
              notifiedContactIds: ['hiking-buddy', 'family-member'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: 'hiking-trip-456',
          message: 'Diabetic emergency - blood sugar critically low',
          latitude: 36.5781,
          longitude: -118.2926,
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.tripId, 'hiking-trip-456');
        expect(
            result.message, 'Diabetic emergency - blood sugar critically low');
        expect(result.latitude, 36.5781);
        expect(result.longitude, -118.2926);
      });

      test('should handle allergic reaction with immediate notification',
          () async {
        // Arrange - Restaurant location
        final restaurantCoords = {
          'latitude': 40.7580,
          'longitude': -73.9855,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => restaurantCoords);

        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Severe allergic reaction - difficulty breathing',
          latitude: 40.7580,
          longitude: -73.9855,
          contactIds: ['emergency-contact-1'],
        )).thenAnswer((_) async => EmergencyAlertModel(
              id: 'medical-alert-13',
              userId: 'user1',
              type: EmergencyAlertType.medical,
              status: EmergencyAlertStatus.active,
              message: 'Severe allergic reaction - difficulty breathing',
              latitude: 40.7580,
              longitude: -73.9855,
              createdAt: DateTime(2024, 1, 1, 19, 15),
              notifiedContactIds: ['emergency-contact-1'],
            ));

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          message: 'Severe allergic reaction - difficulty breathing',
          latitude: 40.7580,
          longitude: -73.9855,
          contactIds: ['emergency-contact-1'],
        );

        // Assert
        expect(result.type, EmergencyAlertType.medical);
        expect(result.message,
            'Severe allergic reaction - difficulty breathing');
        expect(result.status, EmergencyAlertStatus.active);
        expect(result.latitude, 40.7580);
        expect(result.longitude, -73.9855);
      });
    });
  });
}
