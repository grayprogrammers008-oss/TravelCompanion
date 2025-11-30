import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/update_shared_location_usecase.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

import 'update_shared_location_usecase_test.mocks.dart';

@GenerateMocks([EmergencyRepository])
void main() {
  late UpdateSharedLocationUseCase useCase;
  late MockEmergencyRepository mockRepository;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = UpdateSharedLocationUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testLocationShare = LocationShareModel(
    id: 'session-123',
    userId: 'user-123',
    latitude: 40.7128,
    longitude: -74.0060,
    accuracy: 10.0,
    altitude: 50.0,
    speed: 5.0,
    heading: 90.0,
    status: LocationShareStatus.active,
    startedAt: now,
    lastUpdatedAt: now,
    sharedWithContactIds: ['contact-1', 'contact-2'],
    message: 'Updated location',
  );

  group('UpdateSharedLocationUseCase', () {
    group('Positive Cases', () {
      test('should update location successfully', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        expect(result.latitude, 40.7128);
        expect(result.longitude, -74.0060);
        verify(mockRepository.updateSharedLocation(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: null,
          altitude: null,
          speed: null,
          heading: null,
          message: null,
        )).called(1);
      });

      test('should update location with accuracy', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 10.5,
        );

        // Assert
        expect(result.accuracy, 10.0);
      });

      test('should update location with all parameters', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 5.0,
          altitude: 100.0,
          speed: 10.0,
          heading: 180.0,
          message: 'Moving north',
        );

        // Assert
        verify(mockRepository.updateSharedLocation(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 5.0,
          altitude: 100.0,
          speed: 10.0,
          heading: 180.0,
          message: 'Moving north',
        )).called(1);
      });

      test('should trim message whitespace', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          message: '  Arrived safely  ',
        );

        // Assert
        verify(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: 'Arrived safely',
        )).called(1);
      });

      test('should accept boundary coordinates', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act - boundary values
        await useCase(sessionId: 'session-123', latitude: 90, longitude: 180);
        await useCase(sessionId: 'session-123', latitude: -90, longitude: -180);
        await useCase(sessionId: 'session-123', latitude: 0, longitude: 0);

        // Assert
        verify(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).called(3);
      });

      test('should accept heading boundary values', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act - heading 0 to 359.9 is valid
        await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          heading: 0,
        );
        await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          heading: 359.9,
        );

        // Assert
        verify(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).called(2);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty session ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: '',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Session ID cannot be empty'),
          )),
        );
      });

      test('should throw ArgumentError for whitespace-only session ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: '   ',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Session ID cannot be empty'),
          )),
        );
      });

      test('should throw ArgumentError for latitude below -90', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: -91,
            longitude: -74.0060,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Latitude must be between -90 and 90'),
          )),
        );
      });

      test('should throw ArgumentError for latitude above 90', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 91,
            longitude: -74.0060,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Latitude must be between -90 and 90'),
          )),
        );
      });

      test('should throw ArgumentError for longitude below -180', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -181,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Longitude must be between -180 and 180'),
          )),
        );
      });

      test('should throw ArgumentError for longitude above 180', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: 181,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Longitude must be between -180 and 180'),
          )),
        );
      });

      test('should throw ArgumentError for negative accuracy', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
            accuracy: -5,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Accuracy cannot be negative'),
          )),
        );
      });

      test('should throw ArgumentError for negative speed', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
            speed: -10,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Speed cannot be negative'),
          )),
        );
      });

      test('should throw ArgumentError for heading below 0', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
            heading: -1,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Heading must be between 0 and 360 degrees'),
          )),
        );
      });

      test('should throw ArgumentError for heading at or above 360', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
            heading: 360,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Heading must be between 0 and 360 degrees'),
          )),
        );
      });

      test('should throw ArgumentError for heading above 360', () async {
        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
            heading: 400,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle session not found error', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Session not found'));

        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'invalid-session',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Session not found'),
          )),
        );
      });

      test('should handle session expired error', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Location sharing session expired'));

        // Act & Assert
        expect(
          () => useCase(
            sessionId: 'session-123',
            latitude: 40.7128,
            longitude: -74.0060,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format session ID', () async {
        // Arrange
        const uuidSessionId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          sessionId: uuidSessionId,
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle zero accuracy', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 0,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle zero speed (stationary)', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          speed: 0,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle negative altitude (below sea level)', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act - Dead Sea is ~430m below sea level
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 31.5,
          longitude: 35.5,
          altitude: -430,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle high altitude', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act - Mount Everest
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 27.9881,
          longitude: 86.9250,
          altitude: 8848,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle high speed', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act - Airplane speed ~250 m/s
        final result = await useCase(
          sessionId: 'session-123',
          latitude: 40.7128,
          longitude: -74.0060,
          speed: 250,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle precise coordinates', () async {
        // Arrange
        when(mockRepository.updateSharedLocation(
          sessionId: anyNamed('sessionId'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          accuracy: anyNamed('accuracy'),
          altitude: anyNamed('altitude'),
          speed: anyNamed('speed'),
          heading: anyNamed('heading'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        await useCase(
          sessionId: 'session-123',
          latitude: 40.71280000001,
          longitude: -74.00600000001,
        );

        // Assert
        verify(mockRepository.updateSharedLocation(
          sessionId: 'session-123',
          latitude: 40.71280000001,
          longitude: -74.00600000001,
          accuracy: null,
          altitude: null,
          speed: null,
          heading: null,
          message: null,
        )).called(1);
      });
    });
  });
}
