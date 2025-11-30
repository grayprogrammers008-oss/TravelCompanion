import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/mark_trip_as_completed_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/unmark_trip_as_completed_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'unmark_trip_as_completed_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late UnmarkTripAsCompletedUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = UnmarkTripAsCompletedUseCase(mockRepository);
  });

  final now = DateTime.now();
  final completedTrip = TripModel(
    id: 'trip-123',
    name: 'Test Trip',
    destination: 'Paris',
    createdBy: 'user-123',
    createdAt: now,
    isCompleted: true,
    completedAt: now,
    rating: 4.5,
  );

  final activeTrip = TripModel(
    id: 'trip-123',
    name: 'Test Trip',
    destination: 'Paris',
    createdBy: 'user-123',
    createdAt: now,
    isCompleted: false,
  );

  final creatorMember = TripMemberModel(
    id: 'member-1',
    tripId: 'trip-123',
    userId: 'user-123',
    role: 'admin',
    joinedAt: now,
  );

  final regularMember = TripMemberModel(
    id: 'member-2',
    tripId: 'trip-123',
    userId: 'user-456',
    role: 'member',
    joinedAt: now,
  );

  final adminMember = TripMemberModel(
    id: 'member-3',
    tripId: 'trip-123',
    userId: 'user-789',
    role: 'admin',
    joinedAt: now,
  );

  final completedTripWithMembers = TripWithMembers(
    trip: completedTrip,
    members: [creatorMember, regularMember, adminMember],
  );

  final activeTripWithMembers = TripWithMembers(
    trip: activeTrip,
    members: [creatorMember, regularMember, adminMember],
  );

  group('UnmarkTripAsCompletedUseCase', () {
    group('Positive Cases', () {
      test('should reopen trip when user is creator', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).thenAnswer((_) async => activeTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, false);
        verify(mockRepository.getTripById('trip-123')).called(1);
        verify(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).called(1);
      });

      test('should reopen trip when user is admin', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).thenAnswer((_) async => activeTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-789');

        // Assert
        expect(result.isCompleted, false);
      });

      test('should return updated trip without completion date', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).thenAnswer((_) async => activeTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, false);
        expect(result.completedAt, isNull);
      });
    });

    group('Negative Cases - Authorization Errors', () {
      test('should throw UnauthorizedException when user is regular member', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-456'),
          throwsA(isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            contains('Only trip creator or admins'),
          )),
        );
      });

      test('should throw UnauthorizedException when user is not a member', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-not-member'),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('Negative Cases - Trip State Errors', () {
      test('should throw TripNotCompletedException when trip is not completed', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => activeTripWithMembers);

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-123'),
          throwsA(isA<TripNotCompletedException>().having(
            (e) => e.tripId,
            'tripId',
            'trip-123',
          )),
        );
        verifyNever(mockRepository.updateTrip(
          tripId: anyNamed('tripId'),
          isCompleted: anyNamed('isCompleted'),
          completedAt: anyNamed('completedAt'),
        ));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate exception when trip not found', () async {
        // Arrange
        when(mockRepository.getTripById('non-existent'))
            .thenThrow(Exception('Trip not found'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'non-existent', userId: 'user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip not found'),
          )),
        );
      });

      test('should propagate exception when update fails', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Update failed'),
          )),
        );
      });

      test('should propagate exception for network error', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should work when trip has only creator as member', () async {
        // Arrange
        final tripOnlyCreator = TripWithMembers(
          trip: completedTrip,
          members: [creatorMember],
        );
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripOnlyCreator);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).thenAnswer((_) async => activeTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, false);
      });

      test('should work when trip has rating', () async {
        // Arrange
        final ratedTrip = completedTrip.copyWith(rating: 5.0);
        final ratedTripWithMembers = TripWithMembers(
          trip: ratedTrip,
          members: [creatorMember],
        );
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => ratedTripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: false,
          completedAt: null,
        )).thenAnswer((_) async => activeTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, false);
      });
    });
  });

  group('TripNotCompletedException', () {
    test('toString returns correct message', () {
      final exception = TripNotCompletedException('trip-123');
      expect(exception.toString(), contains('trip-123'));
      expect(exception.toString(), contains('not completed'));
    });

    test('tripId is stored correctly', () {
      final exception = TripNotCompletedException('trip-abc');
      expect(exception.tripId, 'trip-abc');
    });
  });
}
