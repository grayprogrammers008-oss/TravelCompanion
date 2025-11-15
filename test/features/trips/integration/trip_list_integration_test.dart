import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:travel_crew/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_trips_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'trip_list_integration_test.mocks.dart';

@GenerateMocks([TripRemoteDataSource])
void main() {
  group('Trip List Integration Tests', () {
    late TripRepository repository;
    late GetUserTripsUseCase getUserTripsUseCase;
    late MockTripRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockTripRemoteDataSource();
      repository = TripRepositoryImpl(mockDataSource);
      getUserTripsUseCase = GetUserTripsUseCase(repository);
    });

    group('Complete Trip List Flow', () {
      final testTrip1 = TripModel(
        id: 'trip1',
        name: 'Paris Trip',
        description: 'Summer vacation in Paris',
        destination: 'Paris, France',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 7, 15),
        coverImageUrl: 'https://example.com/paris.jpg',
        createdBy: 'user1',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );

      final testMember1 = TripMemberModel(
        id: 'member1',
        tripId: 'trip1',
        userId: 'user1',
        role: 'owner',
        joinedAt: DateTime(2024, 6, 1),
        fullName: 'John Doe',
        avatarUrl: 'https://example.com/john.jpg',
      );

      final testTripWithMembers1 = TripWithMembers(
        trip: testTrip1,
        members: [testMember1],
      );

      test('should fetch and return trips from data source through repository',
          () async {
        // Arrange
        when(mockDataSource.getUserTrips())
            .thenAnswer((_) async => [testTripWithMembers1]);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip1');
        expect(result[0].trip.name, 'Paris Trip');
        expect(result[0].members.length, 1);
        expect(result[0].members[0].userId, 'user1');
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should handle multiple trips with different member counts',
          () async {
        // Arrange
        final testTrip2 = TripModel(
          id: 'trip2',
          name: 'Tokyo Trip',
          description: 'Spring in Tokyo',
          destination: 'Tokyo, Japan',
          startDate: DateTime(2024, 3, 1),
          endDate: DateTime(2024, 3, 10),
          coverImageUrl: 'https://example.com/tokyo.jpg',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
        );

        final testTripWithMembers2 = TripWithMembers(
          trip: testTrip2,
          members: [
            TripMemberModel(
              id: 'member2',
              tripId: 'trip2',
              userId: 'user1',
              role: 'owner',
              joinedAt: DateTime(2024, 2, 1),
              fullName: 'John Doe',
              avatarUrl: 'https://example.com/john.jpg',
            ),
            TripMemberModel(
              id: 'member3',
              tripId: 'trip2',
              userId: 'user2',
              role: 'member',
              joinedAt: DateTime(2024, 2, 2),
              fullName: 'Jane Smith',
              avatarUrl: 'https://example.com/jane.jpg',
            ),
            TripMemberModel(
              id: 'member4',
              tripId: 'trip2',
              userId: 'user3',
              role: 'member',
              joinedAt: DateTime(2024, 2, 3),
              fullName: 'Bob Wilson',
              avatarUrl: 'https://example.com/bob.jpg',
            ),
          ],
        );

        when(mockDataSource.getUserTrips()).thenAnswer(
            (_) async => [testTripWithMembers1, testTripWithMembers2]);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result.length, 2);
        expect(result[0].members.length, 1);
        expect(result[1].members.length, 3);
        expect(result[1].trip.name, 'Tokyo Trip');
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should return empty list when user has no trips', () async {
        // Arrange
        when(mockDataSource.getUserTrips()).thenAnswer((_) async => []);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result, isEmpty);
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should propagate exception from data source', () async {
        // Arrange
        when(mockDataSource.getUserTrips())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(() => getUserTripsUseCase(), throwsException);
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should handle trips with null optional fields', () async {
        // Arrange
        final tripWithMinimalData = TripModel(
          id: 'trip3',
          name: 'Minimal Trip',
          description: null,
          destination: null,
          startDate: null,
          endDate: null,
          coverImageUrl: null,
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: null,
        );

        final tripWithMembers = TripWithMembers(
          trip: tripWithMinimalData,
          members: [
            TripMemberModel(
              id: 'member5',
              tripId: 'trip3',
              userId: 'user1',
              role: 'owner',
              joinedAt: DateTime(2024, 1, 1),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        );

        when(mockDataSource.getUserTrips())
            .thenAnswer((_) async => [tripWithMembers]);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.name, 'Minimal Trip');
        expect(result[0].trip.description, isNull);
        expect(result[0].trip.destination, isNull);
        expect(result[0].trip.startDate, isNull);
        expect(result[0].trip.endDate, isNull);
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should handle large number of trips', () async {
        // Arrange
        final trips = List.generate(
          50,
          (index) => TripWithMembers(
            trip: TripModel(
              id: 'trip$index',
              name: 'Trip $index',
              description: 'Description $index',
              destination: 'Destination $index',
              startDate: DateTime(2024, 1, 1).add(Duration(days: index)),
              endDate: DateTime(2024, 1, 10).add(Duration(days: index)),
              coverImageUrl: 'https://example.com/trip$index.jpg',
              createdBy: 'user1',
              createdAt: DateTime(2024, 1, 1),
              updatedAt: DateTime(2024, 1, 1),
            ),
            members: [
              TripMemberModel(
                id: 'member$index',
                tripId: 'trip$index',
                userId: 'user1',
                role: 'owner',
                joinedAt: DateTime(2024, 1, 1),
                fullName: 'John Doe',
                avatarUrl: 'https://example.com/john.jpg',
              ),
            ],
          ),
        );

        when(mockDataSource.getUserTrips()).thenAnswer((_) async => trips);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result.length, 50);
        expect(result.first.trip.name, 'Trip 0');
        expect(result.last.trip.name, 'Trip 49');
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should handle trips with past and future dates', () async {
        // Arrange
        final pastTrip = TripWithMembers(
          trip: TripModel(
            id: 'past',
            name: 'Past Trip',
            description: 'Completed trip',
            destination: 'Past Destination',
            startDate: DateTime(2023, 1, 1),
            endDate: DateTime(2023, 1, 10),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: DateTime(2023, 1, 1),
            updatedAt: DateTime(2023, 1, 1),
          ),
          members: [testMember1],
        );

        final futureTrip = TripWithMembers(
          trip: TripModel(
            id: 'future',
            name: 'Future Trip',
            description: 'Upcoming trip',
            destination: 'Future Destination',
            startDate: DateTime.now().add(const Duration(days: 30)),
            endDate: DateTime.now().add(const Duration(days: 40)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
          members: [testMember1],
        );

        when(mockDataSource.getUserTrips())
            .thenAnswer((_) async => [pastTrip, futureTrip]);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result.length, 2);
        expect(result[0].trip.name, 'Past Trip');
        expect(result[1].trip.name, 'Future Trip');
        expect(result[0].trip.startDate!.isBefore(DateTime.now()), isTrue);
        expect(result[1].trip.startDate!.isAfter(DateTime.now()), isTrue);
        verify(mockDataSource.getUserTrips()).called(1);
      });

      test('should preserve trip order from data source', () async {
        // Arrange
        final trip1 = TripWithMembers(
          trip: testTrip1.copyWith(id: 'a', name: 'A Trip'),
          members: [testMember1],
        );
        final trip2 = TripWithMembers(
          trip: testTrip1.copyWith(id: 'z', name: 'Z Trip'),
          members: [testMember1],
        );
        final trip3 = TripWithMembers(
          trip: testTrip1.copyWith(id: 'm', name: 'M Trip'),
          members: [testMember1],
        );

        when(mockDataSource.getUserTrips())
            .thenAnswer((_) async => [trip2, trip1, trip3]);

        // Act
        final result = await getUserTripsUseCase();

        // Assert
        expect(result.length, 3);
        expect(result[0].trip.name, 'Z Trip');
        expect(result[1].trip.name, 'A Trip');
        expect(result[2].trip.name, 'M Trip');
        verify(mockDataSource.getUserTrips()).called(1);
      });
    });
  });
}
