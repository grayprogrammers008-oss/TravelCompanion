import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:travel_crew/features/emergency/domain/usecases/start_location_sharing_usecase.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

import 'start_location_sharing_usecase_test.mocks.dart';

@GenerateMocks([EmergencyRepository])
void main() {
  late StartLocationSharingUseCase useCase;
  late MockEmergencyRepository mockRepository;

  setUp(() {
    mockRepository = MockEmergencyRepository();
    useCase = StartLocationSharingUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testLocationShare = LocationShareModel(
    id: 'session-123',
    userId: 'user-123',
    latitude: 40.7128,
    longitude: -74.0060,
    status: LocationShareStatus.active,
    startedAt: now,
    lastUpdatedAt: now,
    sharedWithContactIds: ['contact-1', 'contact-2'],
  );

  group('StartLocationSharingUseCase', () {
    group('Positive Cases', () {
      test('should start location sharing successfully', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          contactIds: ['contact-1', 'contact-2'],
        );

        // Assert
        expect(result.id, 'session-123');
        expect(result.status, LocationShareStatus.active);
        verify(mockRepository.startLocationSharing(
          contactIds: ['contact-1', 'contact-2'],
          tripId: null,
          duration: null,
          message: null,
        )).called(1);
      });

      test('should start sharing with single contact', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should start sharing with trip ID', () async {
        // Arrange
        final shareWithTrip = testLocationShare.copyWith(tripId: 'trip-123');
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => shareWithTrip);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
          tripId: 'trip-123',
        );

        // Assert
        expect(result.tripId, 'trip-123');
        verify(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: 'trip-123',
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).called(1);
      });

      test('should start sharing with duration', () async {
        // Arrange
        final shareWithExpiry = testLocationShare.copyWith(
          expiresAt: now.add(const Duration(hours: 2)),
        );
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => shareWithExpiry);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
          duration: const Duration(hours: 2),
        );

        // Assert
        expect(result.expiresAt, isNotNull);
      });

      test('should start sharing with message', () async {
        // Arrange
        final shareWithMessage = testLocationShare.copyWith(
          message: 'I am safe',
        );
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => shareWithMessage);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
          message: 'I am safe',
        );

        // Assert
        expect(result.message, 'I am safe');
      });

      test('should trim message whitespace', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        await useCase(
          contactIds: ['contact-1'],
          message: '  Help needed  ',
        );

        // Assert
        verify(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: 'Help needed',
        )).called(1);
      });

      test('should start sharing with minimum duration (1 minute)', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
          duration: const Duration(minutes: 1),
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should start sharing with maximum duration (24 hours)', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
          duration: const Duration(hours: 24),
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should share with many contacts', () async {
        // Arrange
        final contactIds = List.generate(10, (i) => 'contact-$i');
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          contactIds: contactIds,
        );

        // Assert
        expect(result, isNotNull);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw ArgumentError for empty contact list', () async {
        // Act & Assert
        expect(
          () => useCase(contactIds: []),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Must share location with at least one contact'),
          )),
        );
        verifyNever(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        ));
      });

      test('should throw ArgumentError for duration less than 1 minute', () async {
        // Act & Assert
        expect(
          () => useCase(
            contactIds: ['contact-1'],
            duration: const Duration(seconds: 30),
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Duration must be at least 1 minute'),
          )),
        );
      });

      test('should throw ArgumentError for zero duration', () async {
        // Act & Assert
        expect(
          () => useCase(
            contactIds: ['contact-1'],
            duration: Duration.zero,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Duration must be at least 1 minute'),
          )),
        );
      });

      test('should throw ArgumentError for duration exceeding 24 hours', () async {
        // Act & Assert
        expect(
          () => useCase(
            contactIds: ['contact-1'],
            duration: const Duration(hours: 25),
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Duration cannot exceed 24 hours'),
          )),
        );
      });

      test('should throw ArgumentError for duration of 48 hours', () async {
        // Act & Assert
        expect(
          () => useCase(
            contactIds: ['contact-1'],
            duration: const Duration(hours: 48),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(contactIds: ['contact-1']),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(contactIds: ['contact-1']),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle location permission denied', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Location permission denied'));

        // Act & Assert
        expect(
          () => useCase(contactIds: ['contact-1']),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle contact not found error', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenThrow(Exception('Contact not found'));

        // Act & Assert
        expect(
          () => useCase(contactIds: ['invalid-contact']),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format contact IDs', () async {
        // Arrange
        final uuidContacts = [
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'b2c3d4e5-f6a7-8901-bcde-f12345678901',
        ];
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(contactIds: uuidContacts);

        // Assert
        expect(result, isNotNull);
      });

      test('should handle null message', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        final result = await useCase(
          contactIds: ['contact-1'],
          message: null,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle duration just under 24 hours', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act - 23 hours 59 minutes should work
        final result = await useCase(
          contactIds: ['contact-1'],
          duration: const Duration(hours: 23, minutes: 59),
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle long message', () async {
        // Arrange
        final longMessage = 'A' * 500;
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        await useCase(
          contactIds: ['contact-1'],
          message: longMessage,
        );

        // Assert
        verify(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: longMessage,
        )).called(1);
      });

      test('should handle all parameters provided', () async {
        // Arrange
        when(mockRepository.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
        )).thenAnswer((_) async => testLocationShare);

        // Act
        await useCase(
          contactIds: ['contact-1', 'contact-2'],
          tripId: 'trip-123',
          duration: const Duration(hours: 6),
          message: 'Sharing my location',
        );

        // Assert
        verify(mockRepository.startLocationSharing(
          contactIds: ['contact-1', 'contact-2'],
          tripId: 'trip-123',
          duration: const Duration(hours: 6),
          message: 'Sharing my location',
        )).called(1);
      });
    });
  });
}
