import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trip_invites/domain/entities/invite_entity.dart';
import 'package:travel_crew/features/trip_invites/domain/repositories/invite_repository.dart';
import 'package:travel_crew/features/trip_invites/domain/usecases/accept_invite_usecase.dart';

import 'accept_invite_usecase_test.mocks.dart';

@GenerateMocks([InviteRepository])
void main() {
  late AcceptInviteUseCase useCase;
  late MockInviteRepository mockRepository;

  setUp(() {
    mockRepository = MockInviteRepository();
    useCase = AcceptInviteUseCase(mockRepository);
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
    tripName: 'Test Trip',
    inviterName: 'John Doe',
  );

  group('AcceptInviteUseCase', () {
    group('Positive Cases', () {
      test('should accept invite successfully', () async {
        // Arrange
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => testInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => testInvite.copyWith(status: 'accepted'));

        // Act
        final result = await useCase(
          inviteCode: 'ABC123',
          userId: 'user-123',
        );

        // Assert
        expect(result.status, 'accepted');
        verify(mockRepository.getInviteByCode('ABC123')).called(1);
        verify(mockRepository.acceptInvite(
          inviteCode: 'ABC123',
          userId: 'user-123',
        )).called(1);
      });

      test('should convert invite code to uppercase', () async {
        // Arrange
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => testInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => testInvite.copyWith(status: 'accepted'));

        // Act
        await useCase(
          inviteCode: 'abc123',
          userId: 'user-123',
        );

        // Assert
        verify(mockRepository.getInviteByCode('ABC123')).called(1);
        verify(mockRepository.acceptInvite(
          inviteCode: 'ABC123',
          userId: anyNamed('userId'),
        )).called(1);
      });

      test('should accept invite with phone number', () async {
        // Arrange
        final inviteWithPhone = testInvite.copyWith(
          phoneNumber: '+1234567890',
        );
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => inviteWithPhone);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => inviteWithPhone.copyWith(status: 'accepted'));

        // Act
        final result = await useCase(
          inviteCode: 'ABC123',
          userId: 'user-123',
        );

        // Assert
        expect(result.phoneNumber, '+1234567890');
      });

      test('should accept invite with all extended fields', () async {
        // Arrange
        final fullInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris, France',
        );
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => fullInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => fullInvite.copyWith(status: 'accepted'));

        // Act
        final result = await useCase(
          inviteCode: 'ABC123',
          userId: 'user-123',
        );

        // Assert
        expect(result.tripName, 'Amazing Trip');
        expect(result.tripDestination, 'Paris, France');
        expect(result.inviterName, 'John Doe');
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw Exception for empty invite code', () async {
        // Act & Assert
        expect(
          () => useCase(
            inviteCode: '',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invite code cannot be empty'),
          )),
        );
        verifyNever(mockRepository.getInviteByCode(any));
      });

      test('should throw Exception for invalid invite code length', () async {
        // Act & Assert - too short
        expect(
          () => useCase(
            inviteCode: 'ABC',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid invite code format'),
          )),
        );

        // Too long
        expect(
          () => useCase(
            inviteCode: 'ABCDEFGH',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid invite code format'),
          )),
        );
      });

      test('should throw Exception for empty user ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID cannot be empty'),
          )),
        );
      });

      test('should throw Exception when invite not found', () async {
        // Arrange
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invite not found'),
          )),
        );
      });

      test('should throw Exception when invite is expired', () async {
        // Arrange
        final expiredInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now.subtract(const Duration(days: 14)),
          expiresAt: now.subtract(const Duration(days: 7)), // Expired
        );
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => expiredInvite);

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('expired'),
          )),
        );
      });

      test('should throw Exception when invite is already accepted', () async {
        // Arrange
        final acceptedInvite = testInvite.copyWith(status: 'accepted');
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => acceptedInvite);

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already been accepted'),
          )),
        );
      });

      test('should throw Exception when invite is rejected', () async {
        // Arrange
        final rejectedInvite = testInvite.copyWith(status: 'rejected');
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => rejectedInvite);

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('no longer valid'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.getInviteByCode(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
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
        when(mockRepository.getInviteByCode(any))
            .thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle accept failure after successful get', () async {
        // Arrange
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => testInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('User already a member'));

        // Act & Assert
        expect(
          () => useCase(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already a member'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle invite code with mixed case', () async {
        // Arrange
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => testInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => testInvite.copyWith(status: 'accepted'));

        // Act
        await useCase(
          inviteCode: 'AbC123',
          userId: 'user-123',
        );

        // Assert
        verify(mockRepository.getInviteByCode('ABC123')).called(1);
      });

      test('should handle invite expiring soon (within minutes)', () async {
        // Arrange
        final expiringSoonInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now.subtract(const Duration(days: 6, hours: 23, minutes: 55)),
          expiresAt: now.add(const Duration(minutes: 5)), // 5 minutes left
        );
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => expiringSoonInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => expiringSoonInvite.copyWith(status: 'accepted'));

        // Act
        final result = await useCase(
          inviteCode: 'ABC123',
          userId: 'user-123',
        );

        // Assert
        expect(result.status, 'accepted');
      });

      test('should handle numeric invite code', () async {
        // Arrange
        final numericInvite = testInvite.copyWith(inviteCode: '123456');
        when(mockRepository.getInviteByCode('123456'))
            .thenAnswer((_) async => numericInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => numericInvite.copyWith(status: 'accepted'));

        // Act
        final result = await useCase(
          inviteCode: '123456',
          userId: 'user-123',
        );

        // Assert
        expect(result.status, 'accepted');
      });

      test('should handle UUID format user ID', () async {
        // Arrange
        const uuidUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getInviteByCode(any))
            .thenAnswer((_) async => testInvite);
        when(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => testInvite.copyWith(status: 'accepted'));

        // Act
        final result = await useCase(
          inviteCode: 'ABC123',
          userId: uuidUserId,
        );

        // Assert
        expect(result.status, 'accepted');
        verify(mockRepository.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: uuidUserId,
        )).called(1);
      });
    });

    group('InviteEntity Properties', () {
      test('isExpired should return true for expired invite', () {
        final expiredInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now.subtract(const Duration(days: 14)),
          expiresAt: now.subtract(const Duration(days: 7)),
        );

        expect(expiredInvite.isExpired, true);
      });

      test('isExpired should return false for valid invite', () {
        expect(testInvite.isExpired, false);
      });

      test('isPending should return true for pending non-expired invite', () {
        expect(testInvite.isPending, true);
      });

      test('isPending should return false for expired pending invite', () {
        final expiredPending = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now.subtract(const Duration(days: 14)),
          expiresAt: now.subtract(const Duration(days: 7)),
        );

        expect(expiredPending.isPending, false);
      });

      test('statusMessage should return correct messages', () {
        expect(testInvite.statusMessage, 'Pending');
        expect(testInvite.copyWith(status: 'accepted').statusMessage, 'Accepted');
        expect(testInvite.copyWith(status: 'rejected').statusMessage, 'Rejected');
      });

      test('timeRemainingFormatted should format correctly', () {
        // Days remaining
        final daysInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 5)),
        );
        expect(daysInvite.timeRemainingFormatted, contains('day'));

        // Expired
        final expiredInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'test@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now.subtract(const Duration(days: 14)),
          expiresAt: now.subtract(const Duration(days: 1)),
        );
        expect(expiredInvite.timeRemainingFormatted, 'Expired');
      });
    });
  });
}
