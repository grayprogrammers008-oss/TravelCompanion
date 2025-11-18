import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/trigger_emergency_alert_usecase.dart';
import 'package:travel_crew/features/emergency/domain/usecases/add_emergency_contact_usecase.dart';
import 'package:travel_crew/features/emergency/domain/usecases/start_location_sharing_usecase.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';

import 'emergency_controller_test.mocks.dart';

@GenerateMocks([
  EmergencyRepository,
  TriggerEmergencyAlertUseCase,
  AddEmergencyContactUseCase,
  StartLocationSharingUseCase,
])
void main() {
  late MockEmergencyRepository mockRepository;
  late MockTriggerEmergencyAlertUseCase mockTriggerAlertUseCase;
  late MockAddEmergencyContactUseCase mockAddContactUseCase;
  late MockStartLocationSharingUseCase mockStartLocationSharingUseCase;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    mockTriggerAlertUseCase = MockTriggerEmergencyAlertUseCase();
    mockAddContactUseCase = MockAddEmergencyContactUseCase();
    mockStartLocationSharingUseCase = MockStartLocationSharingUseCase();

    container = ProviderContainer(
      overrides: [
        emergencyRepositoryProvider.overrideWithValue(mockRepository),
        triggerEmergencyAlertUseCaseProvider
            .overrideWithValue(mockTriggerAlertUseCase),
        addEmergencyContactUseCaseProvider
            .overrideWithValue(mockAddContactUseCase),
        startLocationSharingUseCaseProvider
            .overrideWithValue(mockStartLocationSharingUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Emergency Controller - Medical Emergency Tests', () {
    test('should trigger medical emergency alert successfully', () async {
      // Arrange
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        message: 'Medical emergency assistance needed',
        latitude: 37.7749,
        longitude: -122.4194,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1', 'contact2'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: null,
        message: 'Medical emergency assistance needed',
        latitude: 37.7749,
        longitude: -122.4194,
      )).thenAnswer((_) async => expectedAlert);

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      final result = await controller.triggerMedicalAlert(
        message: 'Medical emergency assistance needed',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Assert
      expect(result.id, expectedAlert.id);
      expect(result.type, EmergencyAlertType.medical);
      expect(result.status, EmergencyAlertStatus.active);
      expect(result.message, 'Medical emergency assistance needed');

      verify(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: null,
        message: 'Medical emergency assistance needed',
        latitude: 37.7749,
        longitude: -122.4194,
      )).called(1);
    });

    test('should trigger medical alert with trip context', () async {
      // Arrange
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        tripId: 'trip123',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        message: 'Medical emergency during trip',
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: 'trip123',
        message: 'Medical emergency during trip',
        latitude: null,
        longitude: null,
      )).thenAnswer((_) async => expectedAlert);

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      final result = await controller.triggerMedicalAlert(
        tripId: 'trip123',
        message: 'Medical emergency during trip',
      );

      // Assert
      expect(result.tripId, 'trip123');
      expect(result.type, EmergencyAlertType.medical);
      verify(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: 'trip123',
        message: 'Medical emergency during trip',
        latitude: null,
        longitude: null,
      )).called(1);
    });

    test('should set isTriggeringAlert to true during medical alert', () async {
      // Arrange
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async {
        // Simulate delay
        await Future.delayed(const Duration(milliseconds: 100));
        return expectedAlert;
      });

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      final futureResult = controller.triggerMedicalAlert();

      // Assert - Check loading state
      await Future.delayed(const Duration(milliseconds: 50));
      final stateDuringLoading = container.read(emergencyControllerProvider);
      expect(stateDuringLoading.isTriggeringAlert, true);

      await futureResult;
    });

    test('should set activeAlert after triggering medical alert', () async {
      // Arrange
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => expectedAlert);

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      await controller.triggerMedicalAlert();

      // Assert
      final state = container.read(emergencyControllerProvider);
      expect(state.activeAlert, isNotNull);
      expect(state.activeAlert?.id, expectedAlert.id);
      expect(state.activeAlert?.type, EmergencyAlertType.medical);
      expect(state.isTriggeringAlert, false);
    });

    test('should handle error when triggering medical alert fails', () async {
      // Arrange
      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      final controller = container.read(emergencyControllerProvider.notifier);
      expect(
        () => controller.triggerMedicalAlert(),
        throwsA(isA<Exception>()),
      );
    });

    test('should set error state when medical alert fails', () async {
      // Arrange
      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenThrow(Exception('Network error'));

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      try {
        await controller.triggerMedicalAlert();
      } catch (e) {
        // Expected to throw
      }

      // Assert
      final state = container.read(emergencyControllerProvider);
      expect(state.error, isNotNull);
      expect(state.error, contains('Network error'));
      expect(state.isTriggeringAlert, false);
    });

    test('should differentiate between SOS and medical alerts', () async {
      // Arrange - Medical Alert
      final medicalAlert = EmergencyAlertModel(
        id: 'medical1',
        userId: 'user1',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      // Arrange - SOS Alert
      final sosAlert = EmergencyAlertModel(
        id: 'sos1',
        userId: 'user1',
        type: EmergencyAlertType.sos,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => medicalAlert);

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.sos,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => sosAlert);

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      final medicalResult = await controller.triggerMedicalAlert();
      final sosResult = await controller.triggerSOS();

      // Assert
      expect(medicalResult.type, EmergencyAlertType.medical);
      expect(sosResult.type, EmergencyAlertType.sos);
    });

    test('should trigger medical alert without GPS coordinates', () async {
      // Arrange
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: null,
        message: null,
        latitude: null,
        longitude: null,
      )).thenAnswer((_) async => expectedAlert);

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      final result = await controller.triggerMedicalAlert();

      // Assert
      expect(result, expectedAlert);
      verify(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: null,
        message: null,
        latitude: null,
        longitude: null,
      )).called(1);
    });

    test('should clear error state before triggering medical alert', () async {
      // Arrange - First trigger an error
      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenThrow(Exception('First error'));

      final controller = container.read(emergencyControllerProvider.notifier);

      try {
        await controller.triggerMedicalAlert();
      } catch (e) {
        // Expected to throw
      }

      // Verify error is set
      var state = container.read(emergencyControllerProvider);
      expect(state.error, isNotNull);

      // Arrange - Now set up success
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        type: EmergencyAlertType.medical,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.medical,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => expectedAlert);

      // Act - Trigger again
      await controller.triggerMedicalAlert();

      // Assert - Error should be cleared
      state = container.read(emergencyControllerProvider);
      expect(state.error, isNull);
    });
  });

  group('Emergency Controller - Help Alert Tests', () {
    test('should trigger help alert successfully', () async {
      // Arrange
      final expectedAlert = EmergencyAlertModel(
        id: 'alert1',
        userId: 'user1',
        type: EmergencyAlertType.help,
        status: EmergencyAlertStatus.active,
        createdAt: DateTime(2024, 1, 1),
        notifiedContactIds: ['contact1'],
      );

      when(mockTriggerAlertUseCase(
        type: EmergencyAlertType.help,
        tripId: anyNamed('tripId'),
        message: anyNamed('message'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => expectedAlert);

      // Act
      final controller = container.read(emergencyControllerProvider.notifier);
      final result = await controller.triggerHelpAlert();

      // Assert
      expect(result.type, EmergencyAlertType.help);
      verify(mockTriggerAlertUseCase(
        type: EmergencyAlertType.help,
        tripId: null,
        message: null,
        latitude: null,
        longitude: null,
      )).called(1);
    });
  });
}
