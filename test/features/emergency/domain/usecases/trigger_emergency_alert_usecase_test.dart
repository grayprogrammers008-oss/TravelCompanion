import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/trigger_emergency_alert_usecase.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';

@GenerateMocks([EmergencyRepository])
import 'trigger_emergency_alert_usecase_test.mocks.dart';

void main() {
  late TriggerEmergencyAlertUseCase useCase;
  late MockEmergencyRepository mockRepository;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = TriggerEmergencyAlertUseCase(mockRepository);
  });

  group('TriggerEmergencyAlertUseCase', () {
    final testAlert = EmergencyAlertModel(
      id: 'alert1',
      userId: 'user1',
      type: EmergencyAlertType.sos,
      status: EmergencyAlertStatus.active,
      latitude: 40.7128,
      longitude: -74.0060,
      createdAt: DateTime(2024, 1, 1, 12, 0),
      notifiedContactIds: ['contact1', 'contact2'],
    );

    group('Successful alert triggering', () {
      test('should trigger SOS alert successfully', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).thenAnswer((_) async => testAlert);

        // Act
        final result = await useCase(
          type: EmergencyAlertType.sos,
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        expect(result, equals(testAlert));
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).called(1);
      });

      test('should trigger alert with trip ID', () async {
        // Arrange
        final alertWithTrip = testAlert.copyWith(tripId: 'trip1');
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          tripId: 'trip1',
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).thenAnswer((_) async => alertWithTrip);

        // Act
        final result = await useCase(
          type: EmergencyAlertType.help,
          tripId: 'trip1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        expect(result.tripId, equals('trip1'));
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          tripId: 'trip1',
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).called(1);
      });

      test('should trigger alert with custom message', () async {
        // Arrange
        final alertWithMessage = testAlert.copyWith(message: 'Need help!');
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          tripId: null,
          message: 'Need help!',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).thenAnswer((_) async => alertWithMessage);

        // Act
        final result = await useCase(
          type: EmergencyAlertType.help,
          message: 'Need help!',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        expect(result.message, equals('Need help!'));
      });

      test('should trim message whitespace', () async {
        // Arrange
        final alertWithMessage = testAlert.copyWith(message: 'Need help!');
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          tripId: null,
          message: 'Need help!',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).thenAnswer((_) async => alertWithMessage);

        // Act
        await useCase(
          type: EmergencyAlertType.help,
          message: '  Need help!  ',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.help,
          tripId: null,
          message: 'Need help!',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).called(1);
      });

      test('should trigger alert with specific contacts', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: ['contact1', 'contact2'],
        )).thenAnswer((_) async => testAlert);

        // Act
        await useCase(
          type: EmergencyAlertType.sos,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: ['contact1', 'contact2'],
        );

        // Assert
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: ['contact1', 'contact2'],
        )).called(1);
      });

      test('should trigger medical emergency alert', () async {
        // Arrange
        final medicalAlert = testAlert.copyWith(type: EmergencyAlertType.medical);
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.medical,
          tripId: null,
          message: 'Medical emergency',
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).thenAnswer((_) async => medicalAlert);

        // Act
        final result = await useCase(
          type: EmergencyAlertType.medical,
          message: 'Medical emergency',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        expect(result.type, equals(EmergencyAlertType.medical));
      });

      test('should trigger alert without location', () async {
        // Arrange
        final alertWithoutLocation = EmergencyAlertModel(
          id: 'alert1',
          userId: 'user1',
          type: EmergencyAlertType.safety,
          status: EmergencyAlertStatus.active,
          message: 'Safety check-in',
          createdAt: DateTime(2024, 1, 1, 12, 0),
          notifiedContactIds: ['contact1', 'contact2'],
        );
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.safety,
          tripId: null,
          message: 'Safety check-in',
          latitude: null,
          longitude: null,
          contactIds: null,
        )).thenAnswer((_) async => alertWithoutLocation);

        // Act
        final result = await useCase(
          type: EmergencyAlertType.safety,
          message: 'Safety check-in',
        );

        // Assert
        expect(result.latitude, isNull);
        expect(result.longitude, isNull);
      });
    });

    group('Validation', () {
      test('should throw error when only latitude is provided', () async {
        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            latitude: 40.7128,
          ),
          throwsArgumentError,
        );
      });

      test('should throw error when only longitude is provided', () async {
        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            longitude: -74.0060,
          ),
          throwsArgumentError,
        );
      });

      test('should throw error for invalid latitude (too low)', () async {
        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            latitude: -91.0,
            longitude: -74.0060,
          ),
          throwsArgumentError,
        );
      });

      test('should throw error for invalid latitude (too high)', () async {
        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            latitude: 91.0,
            longitude: -74.0060,
          ),
          throwsArgumentError,
        );
      });

      test('should throw error for invalid longitude (too low)', () async {
        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            latitude: 40.7128,
            longitude: -181.0,
          ),
          throwsArgumentError,
        );
      });

      test('should throw error for invalid longitude (too high)', () async {
        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            latitude: 40.7128,
            longitude: 181.0,
          ),
          throwsArgumentError,
        );
      });

      test('should accept valid latitude at boundary (-90)', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: -90.0,
          longitude: 0.0,
          contactIds: null,
        )).thenAnswer((_) async => testAlert);

        // Act
        await useCase(
          type: EmergencyAlertType.sos,
          latitude: -90.0,
          longitude: 0.0,
        );

        // Assert
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: -90.0,
          longitude: 0.0,
          contactIds: null,
        )).called(1);
      });

      test('should accept valid latitude at boundary (90)', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 90.0,
          longitude: 0.0,
          contactIds: null,
        )).thenAnswer((_) async => testAlert);

        // Act
        await useCase(
          type: EmergencyAlertType.sos,
          latitude: 90.0,
          longitude: 0.0,
        );

        // Assert
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 90.0,
          longitude: 0.0,
          contactIds: null,
        )).called(1);
      });

      test('should accept valid longitude at boundary (-180)', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 0.0,
          longitude: -180.0,
          contactIds: null,
        )).thenAnswer((_) async => testAlert);

        // Act
        await useCase(
          type: EmergencyAlertType.sos,
          latitude: 0.0,
          longitude: -180.0,
        );

        // Assert
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 0.0,
          longitude: -180.0,
          contactIds: null,
        )).called(1);
      });

      test('should accept valid longitude at boundary (180)', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 0.0,
          longitude: 180.0,
          contactIds: null,
        )).thenAnswer((_) async => testAlert);

        // Act
        await useCase(
          type: EmergencyAlertType.sos,
          latitude: 0.0,
          longitude: 180.0,
        );

        // Assert
        verify(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 0.0,
          longitude: 180.0,
          contactIds: null,
        )).called(1);
      });
    });

    group('Error handling', () {
      test('should propagate repository exceptions', () async {
        // Arrange
        when(mockRepository.triggerEmergencyAlert(
          type: EmergencyAlertType.sos,
          tripId: null,
          message: null,
          latitude: 40.7128,
          longitude: -74.0060,
          contactIds: null,
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase(
            type: EmergencyAlertType.sos,
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          throwsException,
        );
      });
    });
  });
}
