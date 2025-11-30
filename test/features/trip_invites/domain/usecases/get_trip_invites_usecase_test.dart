import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trip_invites/domain/entities/invite_entity.dart';
import 'package:travel_crew/features/trip_invites/domain/repositories/invite_repository.dart';
import 'package:travel_crew/features/trip_invites/domain/usecases/get_trip_invites_usecase.dart';

import 'get_trip_invites_usecase_test.mocks.dart';

@GenerateMocks([InviteRepository])
void main() {
  late GetTripInvitesUseCase useCase;
  late MockInviteRepository mockRepository;

  setUp(() {
    mockRepository = MockInviteRepository();
    useCase = GetTripInvitesUseCase(mockRepository);
  });

  final now = DateTime.now();
  final future = now.add(const Duration(days: 7));
  final past = now.subtract(const Duration(days: 7));

  InviteEntity createInvite({
    required String id,
    required String email,
    String status = 'pending',
    DateTime? expiresAt,
  }) {
    return InviteEntity(
      id: id,
      tripId: 'trip-456',
      invitedBy: 'inviter-789',
      email: email,
      status: status,
      inviteCode: 'ABC$id',
      createdAt: now,
      expiresAt: expiresAt ?? future,
    );
  }

  group('GetTripInvitesUseCase', () {
    group('Positive Cases', () {
      test('should return list of invites for trip', () async {
        // Arrange
        final invites = [
          createInvite(id: '1', email: 'user1@example.com'),
          createInvite(id: '2', email: 'user2@example.com'),
          createInvite(id: '3', email: 'user3@example.com'),
        ];
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result.length, 3);
        verify(mockRepository.getTripInvites(
          tripId: 'trip-456',
          includeExpired: false,
        )).called(1);
      });

      test('should return empty list when no invites exist', () async {
        // Arrange
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result, isEmpty);
      });

      test('should include expired invites when requested', () async {
        // Arrange
        final invites = [
          createInvite(id: '1', email: 'user1@example.com'),
          createInvite(id: '2', email: 'user2@example.com', expiresAt: past),
        ];
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await useCase(
          tripId: 'trip-456',
          includeExpired: true,
        );

        // Assert
        expect(result.length, 2);
        verify(mockRepository.getTripInvites(
          tripId: 'trip-456',
          includeExpired: true,
        )).called(1);
      });

      test('should exclude expired invites by default', () async {
        // Arrange
        final validInvites = [
          createInvite(id: '1', email: 'user1@example.com'),
        ];
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => validInvites);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result.length, 1);
        verify(mockRepository.getTripInvites(
          tripId: 'trip-456',
          includeExpired: false,
        )).called(1);
      });

      test('should return invites with various statuses', () async {
        // Arrange
        final invites = [
          createInvite(id: '1', email: 'user1@example.com', status: 'pending'),
          createInvite(id: '2', email: 'user2@example.com', status: 'accepted'),
          createInvite(id: '3', email: 'user3@example.com', status: 'rejected'),
        ];
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result.where((i) => i.status == 'pending').length, 1);
        expect(result.where((i) => i.status == 'accepted').length, 1);
        expect(result.where((i) => i.status == 'rejected').length, 1);
      });

      test('should return single invite', () async {
        // Arrange
        final invites = [
          createInvite(id: '1', email: 'user1@example.com'),
        ];
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => invites);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result.length, 1);
        expect(result[0].email, 'user1@example.com');
      });

      test('should return invites with extended fields', () async {
        // Arrange
        final fullInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'user@example.com',
          phoneNumber: '+1234567890',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now,
          expiresAt: future,
          inviterName: 'John Doe',
          inviterEmail: 'john@example.com',
          tripName: 'Amazing Trip',
          tripDestination: 'Paris',
        );
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => [fullInvite]);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result[0].inviterName, 'John Doe');
        expect(result[0].tripName, 'Amazing Trip');
        expect(result[0].tripDestination, 'Paris');
      });
    });

    group('Negative Cases - Validation', () {
      test('should throw Exception for empty trip ID', () async {
        // Act & Assert
        expect(
          () => useCase(tripId: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID cannot be empty'),
          )),
        );
        verifyNever(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        ));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-456'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-456'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle trip not found error', () async {
        // Arrange
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenThrow(Exception('Trip not found'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'nonexistent-trip'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip not found'),
          )),
        );
      });

      test('should handle permission denied error', () async {
        // Arrange
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenThrow(Exception('Permission denied: Not a trip member'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-456'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await useCase(tripId: uuidTripId);

        // Assert
        expect(result, isEmpty);
        verify(mockRepository.getTripInvites(
          tripId: uuidTripId,
          includeExpired: anyNamed('includeExpired'),
        )).called(1);
      });

      test('should handle large number of invites', () async {
        // Arrange
        final manyInvites = List.generate(
          100,
          (i) => createInvite(id: 'id-$i', email: 'user$i@example.com'),
        );
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => manyInvites);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result.length, 100);
      });

      test('should be callable multiple times', () async {
        // Arrange
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => []);

        // Act
        await useCase(tripId: 'trip-456');
        await useCase(tripId: 'trip-456');
        await useCase(tripId: 'trip-789');

        // Assert
        verify(mockRepository.getTripInvites(
          tripId: 'trip-456',
          includeExpired: anyNamed('includeExpired'),
        )).called(2);
        verify(mockRepository.getTripInvites(
          tripId: 'trip-789',
          includeExpired: anyNamed('includeExpired'),
        )).called(1);
      });

      test('should handle invites about to expire', () async {
        // Arrange
        final expiringInvite = InviteEntity(
          id: 'invite-123',
          tripId: 'trip-456',
          invitedBy: 'inviter-789',
          email: 'user@example.com',
          status: 'pending',
          inviteCode: 'ABC123',
          createdAt: now.subtract(const Duration(days: 6, hours: 23)),
          expiresAt: now.add(const Duration(minutes: 30)),
        );
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => [expiringInvite]);

        // Act
        final result = await useCase(tripId: 'trip-456');

        // Assert
        expect(result.length, 1);
        expect(result[0].timeUntilExpiration.inMinutes, lessThanOrEqualTo(30));
      });

      test('should return fresh data on each call', () async {
        // Arrange
        final firstCallInvites = [
          createInvite(id: '1', email: 'user1@example.com'),
        ];
        final secondCallInvites = [
          createInvite(id: '1', email: 'user1@example.com'),
          createInvite(id: '2', email: 'user2@example.com'),
        ];

        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => firstCallInvites);

        // First call
        final result1 = await useCase(tripId: 'trip-456');
        expect(result1.length, 1);

        // Update mock for second call
        when(mockRepository.getTripInvites(
          tripId: anyNamed('tripId'),
          includeExpired: anyNamed('includeExpired'),
        )).thenAnswer((_) async => secondCallInvites);

        // Second call
        final result2 = await useCase(tripId: 'trip-456');
        expect(result2.length, 2);
      });
    });
  });
}
