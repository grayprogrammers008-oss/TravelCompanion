import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/mark_trip_as_completed_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'mark_trip_as_completed_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late MarkTripAsCompletedUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = MarkTripAsCompletedUseCase(mockRepository);
  });

  final now = DateTime.now();
  final testTrip = TripModel(
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

  final tripWithMembers = TripWithMembers(
    trip: testTrip,
    members: [creatorMember, regularMember, adminMember],
  );

  final completedTrip = testTrip.copyWith(
    isCompleted: true,
    completedAt: now,
  );

  group('MarkTripAsCompletedUseCase', () {
    group('Positive Cases', () {
      test('should mark trip as completed when user is creator', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
        )).thenAnswer((_) async => completedTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, true);
        verify(mockRepository.getTripById('trip-123')).called(1);
        verify(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
        )).called(1);
      });

      test('should mark trip as completed when user is admin', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
        )).thenAnswer((_) async => completedTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-789');

        // Assert
        expect(result.isCompleted, true);
      });

      test('should return updated trip model with completion date', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
        )).thenAnswer((_) async => completedTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, true);
        expect(result.completedAt, isNotNull);
      });
    });

    group('Negative Cases - Authorization Errors', () {
      test('should throw UnauthorizedException when user is regular member', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripWithMembers);

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
            .thenAnswer((_) async => tripWithMembers);

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-not-member'),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('Negative Cases - Trip State Errors', () {
      test('should throw TripAlreadyCompletedException when trip is already completed', () async {
        // Arrange
        final alreadyCompletedTrip = TripWithMembers(
          trip: completedTrip,
          members: [creatorMember],
        );
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => alreadyCompletedTrip);

        // Act & Assert
        expect(
          () => useCase(tripId: 'trip-123', userId: 'user-123'),
          throwsA(isA<TripAlreadyCompletedException>().having(
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
            .thenAnswer((_) async => tripWithMembers);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
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
    });

    group('Edge Cases', () {
      test('should work when trip has only creator as member', () async {
        // Arrange
        final tripOnlyCreator = TripWithMembers(
          trip: testTrip,
          members: [creatorMember],
        );
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripOnlyCreator);
        when(mockRepository.updateTrip(
          tripId: 'trip-123',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
        )).thenAnswer((_) async => completedTrip);

        // Act
        final result = await useCase(tripId: 'trip-123', userId: 'user-123');

        // Assert
        expect(result.isCompleted, true);
      });

      test('should work when trip has no end date', () async {
        // Arrange
        final tripNoEndDate = TripModel(
          id: 'trip-no-end',
          name: 'No End Date Trip',
          createdBy: 'user-123',
          isCompleted: false,
        );
        final tripWithNoEndDate = TripWithMembers(
          trip: tripNoEndDate,
          members: [creatorMember],
        );
        when(mockRepository.getTripById('trip-no-end'))
            .thenAnswer((_) async => tripWithNoEndDate);
        when(mockRepository.updateTrip(
          tripId: 'trip-no-end',
          isCompleted: true,
          completedAt: anyNamed('completedAt'),
        )).thenAnswer((_) async => tripNoEndDate.copyWith(isCompleted: true, completedAt: now));

        // Act
        final result = await useCase(tripId: 'trip-no-end', userId: 'user-123');

        // Assert
        expect(result.isCompleted, true);
      });
    });
  });

  group('Exception Classes', () {
    test('UnauthorizedException toString returns correct message', () {
      final exception = UnauthorizedException('Test message');
      expect(exception.toString(), 'UnauthorizedException: Test message');
    });

    test('TripNotFoundException toString returns correct message', () {
      final exception = TripNotFoundException('trip-123');
      expect(exception.toString(), contains('trip-123'));
    });

    test('TripAlreadyCompletedException toString returns correct message', () {
      final exception = TripAlreadyCompletedException('trip-123');
      expect(exception.toString(), contains('trip-123'));
      expect(exception.toString(), contains('already completed'));
    });
  });
}
