import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:travel_crew/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:travel_crew/core/services/location_service.dart';
import 'package:travel_crew/shared/models/emergency_contact_model.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

import 'emergency_repository_impl_test.mocks.dart';

@GenerateMocks([EmergencyRemoteDataSource, LocationService])
void main() {
  late EmergencyRepositoryImpl repository;
  late MockEmergencyRemoteDataSource mockRemoteDataSource;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRemoteDataSource = MockEmergencyRemoteDataSource();
    mockLocationService = MockLocationService();
    repository = EmergencyRepositoryImpl(mockRemoteDataSource, mockLocationService);
  });

  group('EmergencyRepositoryImpl', () {
    group('Emergency Contacts', () {
      test('should get emergency contacts from remote data source', () async {
        // Arrange
        final contacts = [
          EmergencyContactModel(
            id: 'contact1',
            userId: 'user1',
            name: 'John Doe',
            phoneNumber: '+1234567890',
            email: 'john@example.com',
            relationship: 'Spouse',
            isPrimary: true,
            createdAt: DateTime(2024, 1, 1),
          ),
        ];
        when(mockRemoteDataSource.getEmergencyContacts())
            .thenAnswer((_) async => contacts);

        // Act
        final result = await repository.getEmergencyContacts();

        // Assert
        expect(result, contacts);
        verify(mockRemoteDataSource.getEmergencyContacts()).called(1);
      });

      test('should add emergency contact through remote data source', () async {
        // Arrange
        final contact = EmergencyContactModel(
          id: 'contact1',
          userId: 'user1',
          name: 'Jane Smith',
          phoneNumber: '+1987654321',
          email: 'jane@example.com',
          relationship: 'Friend',
          isPrimary: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockRemoteDataSource.addEmergencyContact(
          name: anyNamed('name'),
          phoneNumber: anyNamed('phoneNumber'),
          email: anyNamed('email'),
          relationship: anyNamed('relationship'),
          isPrimary: anyNamed('isPrimary'),
        )).thenAnswer((_) async => contact);

        // Act
        final result = await repository.addEmergencyContact(
          name: 'Jane Smith',
          phoneNumber: '+1987654321',
          email: 'jane@example.com',
          relationship: 'Friend',
          isPrimary: false,
        );

        // Assert
        expect(result, contact);
        verify(mockRemoteDataSource.addEmergencyContact(
          name: 'Jane Smith',
          phoneNumber: '+1987654321',
          email: 'jane@example.com',
          relationship: 'Friend',
          isPrimary: false,
        )).called(1);
      });

      test('should delete emergency contact through remote data source',
          () async {
        // Arrange
        when(mockRemoteDataSource.deleteEmergencyContact(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteEmergencyContact('contact1');

        // Assert
        verify(mockRemoteDataSource.deleteEmergencyContact('contact1'))
            .called(1);
      });

      test('should throw exception when get contacts fails', () async {
        // Arrange
        when(mockRemoteDataSource.getEmergencyContacts())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.getEmergencyContacts(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Emergency Alerts/SOS', () {
      test('should trigger SOS alert through remote data source', () async {
        // Arrange
        final alert = EmergencyAlertModel(
          id: 'alert1',
          userId: 'user1',
          tripId: 'trip1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          message: 'Help needed!',
          latitude: 37.7749,
          longitude: -122.4194,
          createdAt: DateTime(2024, 1, 1),
          notifiedContactIds: ['contact1', 'contact2'],
        );
        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: anyNamed('type'),
          tripId: anyNamed('tripId'),
          message: anyNamed('message'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          contactIds: anyNamed('contactIds'),
        )).thenAnswer((_) async => alert);

        // Act
        final result = await repository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: 'trip1',
          message: 'Help needed!',
          latitude: 37.7749,
          longitude: -122.4194,
        );

        // Assert
        expect(result, alert);
        expect(result.type, EmergencyAlertType.sos);
        expect(result.status, EmergencyAlertStatus.active);
        verify(mockRemoteDataSource.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: 'trip1',
          message: 'Help needed!',
          latitude: 37.7749,
          longitude: -122.4194,
          contactIds: null,
        )).called(1);
      });

      test('should acknowledge alert through remote data source', () async {
        // Arrange
        final alert = EmergencyAlertModel(
          id: 'alert1',
          userId: 'user1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.acknowledged,
          createdAt: DateTime(2024, 1, 1),
          acknowledgedAt: DateTime(2024, 1, 1, 10, 5),
          acknowledgedBy: 'user2',
          notifiedContactIds: ['contact1'],
        );
        when(mockRemoteDataSource.acknowledgeAlert(any))
            .thenAnswer((_) async => alert);

        // Act
        final result = await repository.acknowledgeAlert('alert1');

        // Assert
        expect(result, alert);
        expect(result.status, EmergencyAlertStatus.acknowledged);
        verify(mockRemoteDataSource.acknowledgeAlert('alert1')).called(1);
      });

      test('should cancel alert through remote data source', () async {
        // Arrange
        final alert = EmergencyAlertModel(
          id: 'alert1',
          userId: 'user1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.cancelled,
          createdAt: DateTime(2024, 1, 1),
          resolvedAt: DateTime(2024, 1, 1, 10, 10),
          notifiedContactIds: ['contact1'],
        );
        when(mockRemoteDataSource.cancelAlert(any))
            .thenAnswer((_) async => alert);

        // Act
        final result = await repository.cancelAlert('alert1');

        // Assert
        expect(result, alert);
        expect(result.status, EmergencyAlertStatus.cancelled);
        verify(mockRemoteDataSource.cancelAlert('alert1')).called(1);
      });

      test('should resolve alert through remote data source', () async {
        // Arrange
        final alert = EmergencyAlertModel(
          id: 'alert1',
          userId: 'user1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.resolved,
          createdAt: DateTime(2024, 1, 1),
          resolvedAt: DateTime(2024, 1, 1, 11, 0),
          notifiedContactIds: ['contact1'],
        );
        when(mockRemoteDataSource.resolveAlert(
          alertId: anyNamed('alertId'),
          resolution: anyNamed('resolution'),
        )).thenAnswer((_) async => alert);

        // Act
        final result = await repository.resolveAlert(
          alertId: 'alert1',
          resolution: 'All safe now',
        );

        // Assert
        expect(result, alert);
        expect(result.status, EmergencyAlertStatus.resolved);
        verify(mockRemoteDataSource.resolveAlert(
          alertId: 'alert1',
          resolution: 'All safe now',
        )).called(1);
      });

      test('should get user alerts through remote data source', () async {
        // Arrange
        final alerts = [
          EmergencyAlertModel(
            id: 'alert1',
            userId: 'user1',
            type: EmergencyAlertType.sos,
            status: EmergencyAlertStatus.active,
            createdAt: DateTime(2024, 1, 1),
            notifiedContactIds: ['contact1'],
          ),
          EmergencyAlertModel(
            id: 'alert2',
            userId: 'user1',
            type: EmergencyAlertType.help,
            status: EmergencyAlertStatus.resolved,
            createdAt: DateTime(2024, 1, 2),
            resolvedAt: DateTime(2024, 1, 2, 15, 0),
            notifiedContactIds: ['contact1', 'contact2'],
          ),
        ];
        when(mockRemoteDataSource.getUserAlerts(
          status: anyNamed('status'),
          since: anyNamed('since'),
        )).thenAnswer((_) async => alerts);

        // Act
        final result = await repository.getUserAlerts();

        // Assert
        expect(result, alerts);
        expect(result.length, 2);
        verify(mockRemoteDataSource.getUserAlerts(
          status: null,
          since: null,
        )).called(1);
      });

      test('should watch active alerts through remote data source', () async {
        // Arrange
        final alerts = [
          EmergencyAlertModel(
            id: 'alert1',
            userId: 'user1',
            type: EmergencyAlertType.sos,
            status: EmergencyAlertStatus.active,
            createdAt: DateTime(2024, 1, 1),
            notifiedContactIds: ['contact1'],
          ),
        ];
        when(mockRemoteDataSource.watchActiveAlerts())
            .thenAnswer((_) => Stream.value(alerts));

        // Act
        final result = repository.watchActiveAlerts();

        // Assert
        expect(result, isA<Stream<List<EmergencyAlertModel>>>());
        final emitted = await result.first;
        expect(emitted, alerts);
        verify(mockRemoteDataSource.watchActiveAlerts()).called(1);
      });

      test('should throw exception when trigger alert fails', () async {
        // Arrange
        when(mockRemoteDataSource.triggerEmergencyAlert(
          type: anyNamed('type'),
          tripId: anyNamed('tripId'),
          message: anyNamed('message'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          contactIds: anyNamed('contactIds'),
        )).thenThrow(Exception('Failed to send alert'));

        // Act & Assert
        expect(
          () => repository.triggerEmergencyAlert(
            type: EmergencyAlertType.sos,
            message: 'Help!',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Location Sharing', () {
      test('should start location sharing through remote data source',
          () async {
        // Arrange
        final locationShare = LocationShareModel(
          id: 'session1',
          userId: 'user1',
          latitude: 37.7749,
          longitude: -122.4194,
          status: LocationShareStatus.active,
          startedAt: DateTime(2024, 1, 1),
          lastUpdatedAt: DateTime(2024, 1, 1),
          sharedWithContactIds: ['contact1', 'contact2'],
        );
        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => {
                  'latitude': 0.0,
                  'longitude': 0.0,
                });
        when(mockRemoteDataSource.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
        )).thenAnswer((_) async => locationShare);

        // Act
        final result = await repository.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
        );

        // Assert
        expect(result, isA<LocationShareModel>());
        expect(result.status, LocationShareStatus.active);
        verify(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
          tripId: null,
          duration: null,
          message: null,
          latitude: 0.0,
          longitude: 0.0,
        )).called(1);
      });

      test('should stop location sharing through remote data source', () async {
        // Arrange
        when(mockRemoteDataSource.stopLocationSharing(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.stopLocationSharing('session1');

        // Assert
        verify(mockRemoteDataSource.stopLocationSharing('session1')).called(1);
      });

      test('should get active location share through remote data source',
          () async {
        // Arrange
        final locationShare = LocationShareModel(
          id: 'session1',
          userId: 'user1',
          latitude: 37.7749,
          longitude: -122.4194,
          status: LocationShareStatus.active,
          startedAt: DateTime(2024, 1, 1),
          lastUpdatedAt: DateTime(2024, 1, 1),
          sharedWithContactIds: ['contact1'],
        );
        when(mockRemoteDataSource.getActiveLocationShare())
            .thenAnswer((_) async => locationShare);

        // Act
        final result = await repository.getActiveLocationShare();

        // Assert
        expect(result, locationShare);
        verify(mockRemoteDataSource.getActiveLocationShare()).called(1);
      });

      test('should watch location share through remote data source', () async {
        // Arrange
        final locationShare = LocationShareModel(
          id: 'session1',
          userId: 'user1',
          latitude: 37.7749,
          longitude: -122.4194,
          status: LocationShareStatus.active,
          startedAt: DateTime(2024, 1, 1),
          lastUpdatedAt: DateTime(2024, 1, 1),
          sharedWithContactIds: ['contact1'],
        );
        when(mockRemoteDataSource.watchLocationShare(any))
            .thenAnswer((_) => Stream.value(locationShare));

        // Act
        final result = repository.watchLocationShare('session1');

        // Assert
        expect(result, isA<Stream<LocationShareModel>>());
        final emitted = await result.first;
        expect(emitted, locationShare);
        verify(mockRemoteDataSource.watchLocationShare('session1')).called(1);
      });
    });
  });
}
