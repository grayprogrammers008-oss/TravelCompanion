import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trip_invites/data/datasources/invite_remote_datasource.dart';
import 'package:travel_crew/features/trip_invites/data/models/invite_model.dart';
import 'package:travel_crew/features/trip_invites/data/repositories/invite_repository_impl.dart';

import 'invite_repository_impl_test.mocks.dart';

@GenerateMocks([InviteRemoteDataSource])
void main() {
  late InviteRepositoryImpl repository;
  late MockInviteRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockInviteRemoteDataSource();
    repository = InviteRepositoryImpl(mockRemoteDataSource);
  });

  final now = DateTime.now();
  final future = now.add(const Duration(days: 7));

  InviteModel createInviteModel({
    required String id,
    required String tripId,
    required String email,
    String status = 'pending',
    String inviteCode = 'ABC123',
    String? phoneNumber,
    DateTime? expiresAt,
    String? inviterName,
    String? tripName,
  }) {
    return InviteModel(
      id: id,
      tripId: tripId,
      invitedBy: 'inviter-123',
      email: email,
      phoneNumber: phoneNumber,
      status: status,
      inviteCode: inviteCode,
      createdAt: now,
      expiresAt: expiresAt ?? future,
      inviterName: inviterName,
      tripName: tripName,
    );
  }

  group('InviteRepositoryImpl', () {
    group('generateInvite', () {
      test('should create invite successfully', () async {
        // Arrange
        final createdInvite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
        );
        when(mockRemoteDataSource.createInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => createdInvite);

        // Act
        final result = await repository.generateInvite(
          tripId: 'trip-1',
          email: 'user@example.com',
        );

        // Assert
        expect(result.email, 'user@example.com');
        expect(result.tripId, 'trip-1');
        verify(mockRemoteDataSource.createInvite(
          tripId: 'trip-1',
          email: 'user@example.com',
          phoneNumber: null,
          expiresInDays: 7,
        )).called(1);
      });

      test('should create invite with phone number', () async {
        // Arrange
        final createdInvite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
          phoneNumber: '+1234567890',
        );
        when(mockRemoteDataSource.createInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => createdInvite);

        // Act
        final result = await repository.generateInvite(
          tripId: 'trip-1',
          email: 'user@example.com',
          phoneNumber: '+1234567890',
        );

        // Assert
        expect(result.phoneNumber, '+1234567890');
      });

      test('should create invite with custom expiration', () async {
        // Arrange
        final createdInvite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
          expiresAt: now.add(const Duration(days: 14)),
        );
        when(mockRemoteDataSource.createInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => createdInvite);

        // Act
        final result = await repository.generateInvite(
          tripId: 'trip-1',
          email: 'user@example.com',
          expiresInDays: 14,
        );

        // Assert
        expect(result, isNotNull);
        verify(mockRemoteDataSource.createInvite(
          tripId: 'trip-1',
          email: 'user@example.com',
          phoneNumber: null,
          expiresInDays: 14,
        )).called(1);
      });

      test('should throw exception when create fails', () async {
        // Arrange
        when(mockRemoteDataSource.createInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.generateInvite(
            tripId: 'trip-1',
            email: 'user@example.com',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to generate invite'),
          )),
        );
      });
    });

    group('acceptInvite', () {
      test('should accept invite successfully', () async {
        // Arrange
        final acceptedInvite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
          status: 'accepted',
        );
        when(mockRemoteDataSource.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => acceptedInvite);

        // Act
        final result = await repository.acceptInvite(
          inviteCode: 'ABC123',
          userId: 'user-123',
        );

        // Assert
        expect(result.status, 'accepted');
        verify(mockRemoteDataSource.acceptInvite(
          inviteCode: 'ABC123',
          userId: 'user-123',
        )).called(1);
      });

      test('should throw exception when accept fails', () async {
        // Arrange
        when(mockRemoteDataSource.acceptInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Invite expired'));

        // Act & Assert
        expect(
          () => repository.acceptInvite(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to accept invite'),
          )),
        );
      });
    });

    group('rejectInvite', () {
      test('should reject invite successfully', () async {
        // Arrange
        when(mockRemoteDataSource.rejectInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.rejectInvite(
          inviteCode: 'ABC123',
          userId: 'user-123',
        );

        // Assert
        verify(mockRemoteDataSource.rejectInvite(
          inviteCode: 'ABC123',
          userId: 'user-123',
        )).called(1);
      });

      test('should throw exception when reject fails', () async {
        // Arrange
        when(mockRemoteDataSource.rejectInvite(
          inviteCode: anyNamed('inviteCode'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.rejectInvite(
            inviteCode: 'ABC123',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to reject invite'),
          )),
        );
      });
    });

    group('revokeInvite', () {
      test('should revoke invite successfully', () async {
        // Arrange
        when(mockRemoteDataSource.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.revokeInvite(
          inviteId: 'invite-1',
          userId: 'user-123',
        );

        // Assert
        verify(mockRemoteDataSource.revokeInvite(
          inviteId: 'invite-1',
          userId: 'user-123',
        )).called(1);
      });

      test('should throw exception when revoke fails', () async {
        // Arrange
        when(mockRemoteDataSource.revokeInvite(
          inviteId: anyNamed('inviteId'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('Permission denied'));

        // Act & Assert
        expect(
          () => repository.revokeInvite(
            inviteId: 'invite-1',
            userId: 'user-123',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to revoke invite'),
          )),
        );
      });
    });

    group('getTripInvites', () {
      test('should return list of invites for trip', () async {
        // Arrange
        final invites = [
          createInviteModel(id: '1', tripId: 'trip-1', email: 'user1@example.com'),
          createInviteModel(id: '2', tripId: 'trip-1', email: 'user2@example.com'),
        ];
        when(mockRemoteDataSource.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await repository.getTripInvites(tripId: 'trip-1');

        // Assert
        expect(result.length, 2);
        verify(mockRemoteDataSource.getTripInvites(
          tripId: 'trip-1',
          includeExpired: false,
        )).called(1);
      });

      test('should return empty list when no invites', () async {
        // Arrange
        when(mockRemoteDataSource.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.getTripInvites(tripId: 'trip-1');

        // Assert
        expect(result, isEmpty);
      });

      test('should include expired invites when requested', () async {
        // Arrange
        final invites = [
          createInviteModel(id: '1', tripId: 'trip-1', email: 'user1@example.com'),
          createInviteModel(
            id: '2',
            tripId: 'trip-1',
            email: 'user2@example.com',
            expiresAt: now.subtract(const Duration(days: 1)),
          ),
        ];
        when(mockRemoteDataSource.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await repository.getTripInvites(
          tripId: 'trip-1',
          includeExpired: true,
        );

        // Assert
        expect(result.length, 2);
        verify(mockRemoteDataSource.getTripInvites(
          tripId: 'trip-1',
          includeExpired: true,
        )).called(1);
      });

      test('should throw exception when get fails', () async {
        // Arrange
        when(mockRemoteDataSource.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getTripInvites(tripId: 'trip-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get trip invites'),
          )),
        );
      });
    });

    group('getInviteByCode', () {
      test('should return invite when found', () async {
        // Arrange
        final invite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
          inviteCode: 'ABC123',
        );
        when(mockRemoteDataSource.getInviteByCode(any))
            .thenAnswer((_) async => invite);

        // Act
        final result = await repository.getInviteByCode('ABC123');

        // Assert
        expect(result, isNotNull);
        expect(result!.inviteCode, 'ABC123');
        verify(mockRemoteDataSource.getInviteByCode('ABC123')).called(1);
      });

      test('should return null when invite not found', () async {
        // Arrange
        when(mockRemoteDataSource.getInviteByCode(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getInviteByCode('NONEXISTENT');

        // Assert
        expect(result, isNull);
      });

      test('should throw exception when get fails', () async {
        // Arrange
        when(mockRemoteDataSource.getInviteByCode(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getInviteByCode('ABC123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get invite'),
          )),
        );
      });
    });

    group('getInvitesSentByUser', () {
      test('should return invites sent by user', () async {
        // Arrange
        final invites = [
          createInviteModel(id: '1', tripId: 'trip-1', email: 'user1@example.com'),
          createInviteModel(id: '2', tripId: 'trip-2', email: 'user2@example.com'),
        ];
        when(mockRemoteDataSource.getInvitesSentByUser(any))
            .thenAnswer((_) async => invites);

        // Act
        final result = await repository.getInvitesSentByUser('inviter-123');

        // Assert
        expect(result.length, 2);
        verify(mockRemoteDataSource.getInvitesSentByUser('inviter-123')).called(1);
      });

      test('should throw exception when get fails', () async {
        // Arrange
        when(mockRemoteDataSource.getInvitesSentByUser(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getInvitesSentByUser('user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get user invites'),
          )),
        );
      });
    });

    group('getPendingInvitesForEmail', () {
      test('should return pending invites for email', () async {
        // Arrange
        final invites = [
          createInviteModel(id: '1', tripId: 'trip-1', email: 'user@example.com'),
          createInviteModel(id: '2', tripId: 'trip-2', email: 'user@example.com'),
        ];
        when(mockRemoteDataSource.getPendingInvitesForEmail(any))
            .thenAnswer((_) async => invites);

        // Act
        final result = await repository.getPendingInvitesForEmail('user@example.com');

        // Assert
        expect(result.length, 2);
        verify(mockRemoteDataSource.getPendingInvitesForEmail('user@example.com')).called(1);
      });

      test('should return empty list when no pending invites', () async {
        // Arrange
        when(mockRemoteDataSource.getPendingInvitesForEmail(any))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getPendingInvitesForEmail('user@example.com');

        // Assert
        expect(result, isEmpty);
      });

      test('should throw exception when get fails', () async {
        // Arrange
        when(mockRemoteDataSource.getPendingInvitesForEmail(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getPendingInvitesForEmail('user@example.com'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get pending invites'),
          )),
        );
      });
    });

    group('resendInvite', () {
      test('should resend invite successfully', () async {
        // Arrange
        final updatedInvite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
          expiresAt: now.add(const Duration(days: 7)),
        );
        when(mockRemoteDataSource.resendInvite(any))
            .thenAnswer((_) async => updatedInvite);

        // Act
        final result = await repository.resendInvite('invite-1');

        // Assert
        expect(result, isNotNull);
        verify(mockRemoteDataSource.resendInvite('invite-1')).called(1);
      });

      test('should throw exception when resend fails', () async {
        // Arrange
        when(mockRemoteDataSource.resendInvite(any))
            .thenThrow(Exception('Email failed'));

        // Act & Assert
        expect(
          () => repository.resendInvite('invite-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to resend invite'),
          )),
        );
      });
    });

    group('deleteExpiredInvites', () {
      test('should delete all expired invites', () async {
        // Arrange
        when(mockRemoteDataSource.deleteExpiredInvites(tripId: anyNamed('tripId')))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteExpiredInvites();

        // Assert
        verify(mockRemoteDataSource.deleteExpiredInvites(tripId: null)).called(1);
      });

      test('should delete expired invites for specific trip', () async {
        // Arrange
        when(mockRemoteDataSource.deleteExpiredInvites(tripId: anyNamed('tripId')))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteExpiredInvites(tripId: 'trip-1');

        // Assert
        verify(mockRemoteDataSource.deleteExpiredInvites(tripId: 'trip-1')).called(1);
      });

      test('should throw exception when delete fails', () async {
        // Arrange
        when(mockRemoteDataSource.deleteExpiredInvites(tripId: anyNamed('tripId')))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.deleteExpiredInvites(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete expired invites'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle large number of invites', () async {
        // Arrange
        final manyInvites = List.generate(
          100,
          (i) => createInviteModel(
            id: 'invite-$i',
            tripId: 'trip-1',
            email: 'user$i@example.com',
          ),
        );
        when(mockRemoteDataSource.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => manyInvites);

        // Act
        final result = await repository.getTripInvites(tripId: 'trip-1');

        // Assert
        expect(result.length, 100);
      });

      test('should handle invites with various statuses', () async {
        // Arrange
        final invites = [
          createInviteModel(id: '1', tripId: 'trip-1', email: 'user1@example.com', status: 'pending'),
          createInviteModel(id: '2', tripId: 'trip-1', email: 'user2@example.com', status: 'accepted'),
          createInviteModel(id: '3', tripId: 'trip-1', email: 'user3@example.com', status: 'rejected'),
          createInviteModel(id: '4', tripId: 'trip-1', email: 'user4@example.com', status: 'revoked'),
        ];
        when(mockRemoteDataSource.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await repository.getTripInvites(tripId: 'trip-1');

        // Assert
        expect(result.length, 4);
        expect(result.map((i) => i.status).toSet(), {'pending', 'accepted', 'rejected', 'revoked'});
      });

      test('should handle special characters in email', () async {
        // Arrange
        final invite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user.name-test@sub.example.com',
        );
        when(mockRemoteDataSource.createInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => invite);

        // Act
        final result = await repository.generateInvite(
          tripId: 'trip-1',
          email: 'user.name-test@sub.example.com',
        );

        // Assert
        expect(result.email, 'user.name-test@sub.example.com');
      });

      test('should handle international phone numbers', () async {
        // Arrange
        final invite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
          phoneNumber: '+44 20 7123 4567',
        );
        when(mockRemoteDataSource.createInvite(
          tripId: anyNamed('tripId'),
          email: anyNamed('email'),
          phoneNumber: anyNamed('phoneNumber'),
          expiresInDays: anyNamed('expiresInDays'),
        )).thenAnswer((_) async => invite);

        // Act
        final result = await repository.generateInvite(
          tripId: 'trip-1',
          email: 'user@example.com',
          phoneNumber: '+44 20 7123 4567',
        );

        // Assert
        expect(result.phoneNumber, '+44 20 7123 4567');
      });

      test('should handle concurrent operations', () async {
        // Arrange
        final invite = createInviteModel(
          id: 'invite-1',
          tripId: 'trip-1',
          email: 'user@example.com',
        );
        when(mockRemoteDataSource.getInviteByCode(any))
            .thenAnswer((_) async => invite);

        // Act
        final futures = List.generate(
          5,
          (_) => repository.getInviteByCode('ABC123'),
        );
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, 5);
        expect(results.every((r) => r?.inviteCode == 'ABC123'), true);
      });
    });
  });
}
