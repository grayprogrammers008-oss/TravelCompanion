import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trip_invites/domain/entities/invite_entity.dart';
import 'package:travel_crew/features/trip_invites/domain/repositories/invite_repository.dart';
import 'package:travel_crew/features/trip_invites/domain/usecases/generate_invite_usecase.dart';

import 'generate_invite_usecase_test.mocks.dart';

@GenerateMocks([InviteRepository])
void main() {
  late GenerateInviteUseCase useCase;
  late MockInviteRepository mockRepository;

  setUp(() {
    mockRepository = MockInviteRepository();
    useCase = GenerateInviteUseCase(mockRepository);
  });

  final now = DateTime.now();
  final future = now.add(const Duration(days: 7));

  final testInvite = InviteEntity(
    id: 'invite-123',
    tripId: 'trip-456',
    invitedBy: 'inviter-789',
    email: 'test@example.com',
    status: 'pending',
    inviteCode: 'ABC123',
    createdAt: now,
    expiresAt: future,
  );

  group('GenerateInviteUseCase', () {
    group('Positive Cases', () {
      test('should generate invite successfully', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'test@example.com',
        );

        // Assert
        expect(result.id, 'invite-123');
        expect(result.status, 'pending');
        verify(mockRepository.generateInvite(
          tripId: 'trip-456',
          email: 'test@example.com',
          phoneNumber: null,
          expiresInDays: 7,
        )).called(1);
      });

      test('should generate invite with phone number', () async {
        // Arrange
        final inviteWithPhone = testInvite.copyWith(phoneNumber: '+1234567890');
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => inviteWithPhone);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
        );

        // Assert
        expect(result.phoneNumber, '+1234567890');
        verify(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: '+1234567890',
          expiresInDays: anyNamed('expiresInDays'),
        )).called(1);
      });

      test('should generate invite with custom expiration', () async {
        // Arrange
        final customExpiryInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 14)),
        );
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => customExpiryInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'test@example.com',
          expiresInDays: 14,
        );

        // Assert
        expect(result.expiresAt.difference(now).inDays, 14);
        verify(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: 14,
        )).called(1);
      });

      test('should generate invite with 1 day expiration (minimum)', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'test@example.com',
          expiresInDays: 1,
        );

        // Assert
        expect(result, isNotNull);
        verify(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: 1,
        )).called(1);
      });

      test('should generate invite with 365 day expiration (maximum)', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'test@example.com',
          expiresInDays: 365,
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should generate invite with various valid email formats', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Note: The usecase uses regex ^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$
        // which matches word chars, hyphens, and dots
        final validEmails = [
          'user@example.com',
          'user.name@example.com',
          'user-name@example.co.uk',
          'user_name@subdomain.example.com',
          'test123@domain.org',
        ];

        // Act & Assert
        for (final email in validEmails) {
          final result = await useCase(
            tripId: 'trip-456',
            email: email,
          );
          expect(result, isNotNull);
        }
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw Exception for empty trip ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: '',
            email: 'test@example.com',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        ));
      });

      test('should throw Exception for empty email', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Email cannot be empty'),
          )),
        );
      });

      test('should throw Exception for invalid email format', () async {
        final invalidEmails = [
          'invalid',
          'invalid@',
          '@example.com',
          'invalid@.com',
          'invalid@example',
          'invalid email@example.com',
        ];

        for (final email in invalidEmails) {
          expect(
            () => useCase(
              tripId: 'trip-456',
              email: email,
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid email format'),
            )),
            reason: 'Should reject: $email',
          );
        }
      });

      test('should throw Exception for expiration less than 1 day', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
            expiresInDays: 0,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Expiration must be at least 1 day'),
          )),
        );
      });

      test('should throw Exception for negative expiration', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
            expiresInDays: -5,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Expiration must be at least 1 day'),
          )),
        );
      });

      test('should throw Exception for expiration exceeding 365 days', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
            expiresInDays: 366,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Expiration cannot exceed 365 days'),
          )),
        );
      });

      test('should throw Exception for expiration of 1000 days', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
            expiresInDays: 1000,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle trip not found error', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenThrow(Exception('Trip not found'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'nonexistent-trip',
            email: 'test@example.com',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip not found'),
          )),
        );
      });

      test('should handle user already invited error', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenThrow(Exception('User already invited to this trip'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already invited'),
          )),
        );
      });

      test('should handle user already a member error', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenThrow(Exception('User is already a member of this trip'));

        // Act & Assert
        expect(
          () => useCase(
            tripId: 'trip-456',
            email: 'test@example.com',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: uuidTripId,
          email: 'test@example.com',
        );

        // Assert
        expect(result, isNotNull);
        verify(mockRepository.generateInvite(
          tripId: uuidTripId,
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).called(1);
      });

      test('should handle international phone number', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'test@example.com',
          phoneNumber: '+44 7911 123456',
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should generate multiple invites for different emails', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        await useCase(tripId: 'trip-456', email: 'user1@example.com');
        await useCase(tripId: 'trip-456', email: 'user2@example.com');
        await useCase(tripId: 'trip-456', email: 'user3@example.com');

        // Assert
        verify(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).called(3);
      });

      test('should handle email with numbers and underscores', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'user_invite123@example.com',
        );

        // Assert
        expect(result, isNotNull);
      });

      test('should handle long subdomain email', () async {
        // Arrange
        when(mockRepository.generateInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => testInvite);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          email: 'user@subdomain.another.example.co.uk',
        );

        // Assert
        expect(result, isNotNull);
      });
    });
  });
}
