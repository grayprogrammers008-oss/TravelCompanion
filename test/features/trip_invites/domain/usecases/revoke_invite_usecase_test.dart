import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trip_invites/domain/repositories/invite_repository.dart';
import 'package:travel_crew/features/trip_invites/domain/usecases/revoke_invite_usecase.dart';

import 'revoke_invite_usecase_test.mocks.dart';

@GenerateMocks([InviteRepository])
void main() {
  late RevokeInviteUseCase useCase;
  late MockInviteRepository mockRepository;

  setUp(() {
    mockRepository = MockInviteRepository();
    useCase = RevokeInviteUseCase(mockRepository);
  });

  group('RevokeInviteUseCase', () {
    group('Positive Cases', () {
      test('should revoke invite successfully', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: 'invite-123',
          userId: 'user-456',
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: 'invite-123',
          userId: 'user-456',
        )).called(1);
      });

      test('should allow inviter to revoke their invite', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act & Assert - should complete without throwing
        await expectLater(
          useCase(
            inviteId: 'invite-123',
            userId: 'original-inviter',
          ),
          completes,
        );
      });

      test('should allow trip admin to revoke invite', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          useCase(
            inviteId: 'invite-123',
            userId: 'trip-admin',
          ),
          completes,
        );
      });

      test('should handle UUID format invite ID', () async {
        // Arrange
        const uuidInviteId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: uuidInviteId,
          userId: 'user-456',
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: uuidInviteId,
          userId: anyNamed('userId'),
        )).called(1);
      });

      test('should handle UUID format user ID', () async {
        // Arrange
        const uuidUserId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: 'invite-123',
          userId: uuidUserId,
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: uuidUserId,
        )).called(1);
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw Exception for empty invite ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            inviteId: '',
            userId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invite ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should throw Exception for empty user ID', () async {
        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'invite-123',
            userId: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        ));
      });

      test('should throw Exception for both empty IDs', () async {
        // Act & Assert - should fail on first validation (invite ID)
        expect(
          () => useCase(
            inviteId: '',
            userId: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invite ID cannot be empty'),
          )),
        );
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'invite-123',
            userId: 'user-456',
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
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'invite-123',
            userId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle invite not found error', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Invite not found'));

        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'nonexistent-invite',
            userId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invite not found'),
          )),
        );
      });

      test('should handle permission denied error', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Permission denied: Only inviter or admin can revoke'));

        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'invite-123',
            userId: 'random-user',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          )),
        );
      });

      test('should handle invite already accepted error', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Cannot revoke accepted invite'));

        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'accepted-invite',
            userId: 'user-456',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot revoke accepted invite'),
          )),
        );
      });

      test('should handle invite already expired error', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Invite has already expired'));

        // Act & Assert
        expect(
          () => useCase(
            inviteId: 'expired-invite',
            userId: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle short invite ID', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: 'i1',
          userId: 'u1',
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: 'i1',
          userId: 'u1',
        )).called(1);
      });

      test('should handle very long invite ID', () async {
        // Arrange
        final longInviteId = 'invite-${'a' * 500}';
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: longInviteId,
          userId: 'user-456',
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: longInviteId,
          userId: anyNamed('userId'),
        )).called(1);
      });

      test('should handle ID with special characters', () async {
        // Arrange
        const specialId = 'invite_123-abc@test';
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: specialId,
          userId: 'user-456',
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: specialId,
          userId: anyNamed('userId'),
        )).called(1);
      });

      test('should handle rapid successive revocations', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await Future.wait([
          useCase(inviteId: 'invite-1', userId: 'user-456'),
          useCase(inviteId: 'invite-2', userId: 'user-456'),
          useCase(inviteId: 'invite-3', userId: 'user-456'),
        ]);

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: 'invite-1',
          userId: anyNamed('userId'),
        )).called(1);
        verify(mockRepository.revokeInvite(
          inviteId: 'invite-2',
          userId: anyNamed('userId'),
        )).called(1);
        verify(mockRepository.revokeInvite(
          inviteId: 'invite-3',
          userId: anyNamed('userId'),
        )).called(1);
      });

      test('should handle revoking same invite twice (first succeeds, second may fail)', () async {
        // Arrange
        var callCount = 0;
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount > 1) {
            throw Exception('Invite already revoked');
          }
        });

        // Act
        await useCase(inviteId: 'invite-123', userId: 'user-456');

        expect(
          () => useCase(inviteId: 'invite-123', userId: 'user-456'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle numeric IDs', () async {
        // Arrange
        when(mockRepository.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async {});

        // Act
        await useCase(
          inviteId: '12345',
          userId: '67890',
        );

        // Assert
        verify(mockRepository.revokeInvite(
          inviteId: '12345',
          userId: '67890',
        )).called(1);
      });
    });
  });
}
