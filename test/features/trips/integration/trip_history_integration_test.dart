import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:travel_crew/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_history_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'trip_history_integration_test.mocks.dart';

@GenerateMocks([TripRemoteDataSource])
void main() {
  late TripRepositoryImpl repository;
  late GetTripHistoryUseCase useCase;
  late MockTripRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockTripRemoteDataSource();
    repository = TripRepositoryImpl(mockDataSource);
    useCase = GetTripHistoryUseCase(repository);
  });

  group('Trip History Integration Tests', () {
    test('should fetch and filter completed trips from data source', () async {
      // Arrange - Mock data from Supabase
      final allTrips = [
        TripWithMembers(
          trip: TripModel(
            id: '1',
            name: 'Completed Paris Trip',
            destination: 'Paris, France',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
            isCompleted: true,
            completedAt: DateTime(2024, 5, 15),
            rating: 4.5,
          ),
          members: [
            TripMemberModel(
              id: 'member1',
              tripId: '1',
              userId: 'user1',
              role: 'admin',
              joinedAt: DateTime(2024, 1, 1),
              fullName: 'John Doe',
              email: 'john@example.com',
            ),
            TripMemberModel(
              id: 'member2',
              tripId: '1',
              userId: 'user2',
              role: 'member',
              joinedAt: DateTime(2024, 1, 2),
              fullName: 'Jane Smith',
              email: 'jane@example.com',
            ),
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: '2',
            name: 'Active London Trip',
            destination: 'London, UK',
            createdBy: 'user1',
            createdAt: DateTime(2024, 2, 1),
            updatedAt: DateTime(2024, 2, 1),
            isCompleted: false,
          ),
          members: [
            TripMemberModel(
              id: 'member3',
              tripId: '2',
              userId: 'user1',
              role: 'admin',
              joinedAt: DateTime(2024, 2, 1),
              fullName: 'John Doe',
              email: 'john@example.com',
            ),
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: '3',
            name: 'Completed Tokyo Trip',
            destination: 'Tokyo, Japan',
            createdBy: 'user1',
            createdAt: DateTime(2024, 3, 1),
            updatedAt: DateTime(2024, 3, 1),
            isCompleted: true,
            completedAt: DateTime(2024, 6, 20),
            rating: 5.0,
          ),
          members: [
            TripMemberModel(
              id: 'member4',
              tripId: '3',
              userId: 'user1',
              role: 'admin',
              joinedAt: DateTime(2024, 3, 1),
              fullName: 'John Doe',
              email: 'john@example.com',
            ),
          ],
        ),
      ];

      when(mockDataSource.getUserTrips()).thenAnswer((_) async => allTrips);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.length, 2);
      expect(result[0].trip.name, 'Completed Tokyo Trip'); // Newest first
      expect(result[1].trip.name, 'Completed Paris Trip');
      verify(mockDataSource.getUserTrips()).called(1);
    });

    test('should calculate statistics across data layers', () async {
      // Arrange
      final trips = [
        TripWithMembers(
          trip: TripModel(
            id: '1',
            name: 'Trip 1',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
            isCompleted: true,
            completedAt: DateTime(2024, 3, 15),
            rating: 4.0,
          ),
          members: [],
        ),
        TripWithMembers(
          trip: TripModel(
            id: '2',
            name: 'Trip 2',
            createdBy: 'user1',
            createdAt: DateTime(2024, 2, 1),
            updatedAt: DateTime(2024, 2, 1),
            isCompleted: true,
            completedAt: DateTime(2024, 5, 20),
            rating: 5.0,
          ),
          members: [],
        ),
        TripWithMembers(
          trip: TripModel(
            id: '3',
            name: 'Trip 3',
            createdBy: 'user1',
            createdAt: DateTime(2024, 3, 1),
            updatedAt: DateTime(2024, 3, 1),
            isCompleted: true,
            completedAt: DateTime(2024, 6, 10),
            rating: 0.0, // Not rated
          ),
          members: [],
        ),
      ];

      when(mockDataSource.getUserTrips()).thenAnswer((_) async => trips);

      // Act
      final stats = await useCase.getStatistics();

      // Assert - Verify data flows correctly through layers
      expect(stats.totalCompletedTrips, 3);
      expect(stats.totalRatedTrips, 2); // Only 2 with rating > 0
      expect(stats.averageRating, 4.5); // (4.0 + 5.0) / 2
      expect(stats.earliestCompletionDate, DateTime(2024, 3, 15));
      expect(stats.latestCompletionDate, DateTime(2024, 6, 10));
    });

    test('should handle real-time stream updates', () async {
      // Arrange - Simulate real-time updates from Supabase
      final trip1 = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Initial Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.0,
        ),
        members: [],
      );

      final trip2 = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'New Completed Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 6, 20),
          rating: 5.0,
        ),
        members: [],
      );

      // Emit initial data, then update
      when(mockDataSource.watchUserTrips()).thenAnswer((_) {
        return Stream.fromIterable([
          [trip1],           // Initial state
          [trip1, trip2],    // After new trip completed
        ]);
      });

      // Act
      final stream = useCase.watchHistory();

      // Assert
      expect(
        stream,
        emitsInOrder([
          predicate<List<TripWithMembers>>((trips) => trips.length == 1),
          predicate<List<TripWithMembers>>((trips) => trips.length == 2),
        ]),
      );
    });

    test('should handle data source errors gracefully', () async {
      // Arrange
      when(mockDataSource.getUserTrips())
          .thenThrow(Exception('Supabase connection failed'));

      // Act & Assert
      expect(
        () => useCase.call(),
        throwsException,
      );
    });

    test('should preserve member information in completed trips', () async {
      // Arrange
      final members = [
        TripMemberModel(
          id: 'member5',
          tripId: '1',
          userId: 'user1',
          role: 'admin',
          joinedAt: DateTime(2024, 1, 1),
          fullName: 'John Doe',
          email: 'john@example.com',
        ),
        TripMemberModel(
          id: 'member6',
          tripId: '1',
          userId: 'user2',
          role: 'member',
          joinedAt: DateTime(2024, 1, 5),
          fullName: 'Jane Smith',
          email: 'jane@example.com',
        ),
      ];

      final trip = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Team Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.5,
        ),
        members: members,
      );

      when(mockDataSource.getUserTrips()).thenAnswer((_) async => [trip]);

      // Act
      final result = await useCase.call();

      // Assert - Verify member data is preserved
      expect(result.length, 1);
      expect(result[0].members.length, 2);
      expect(result[0].members[0].fullName, 'John Doe');
      expect(result[0].members[1].fullName, 'Jane Smith');
    });
  });

  group('Trip History Error Scenarios', () {
    test('should handle network timeout', () async {
      // Arrange
      when(mockDataSource.getUserTrips())
          .thenThrow(Exception('Connection timeout'));

      // Act & Assert
      expect(
        () => useCase.call(),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle invalid data format', () async {
      // Arrange - Test with trips that have inconsistent data
      final invalidTrip = TripWithMembers(
        trip: TripModel(
          id: '',  // Invalid empty ID
          name: '',  // Invalid empty name
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
        ),
        members: [],
      );

      when(mockDataSource.getUserTrips())
          .thenAnswer((_) async => [invalidTrip]);

      // Act
      final result = await useCase.call();

      // Assert - Should still process but filter properly
      expect(result.length, 1);
      expect(result[0].trip.isCompleted, true);
    });

    test('should handle concurrent access to statistics', () async {
      // Arrange
      final trips = List.generate(
        10,
        (i) => TripWithMembers(
          trip: TripModel(
            id: 'trip_$i',
            name: 'Trip $i',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, i + 1),
            updatedAt: DateTime(2024, 1, i + 1),
            isCompleted: true,
            completedAt: DateTime(2024, i + 1, 15),
            rating: 3.0 + (i % 3),
          ),
          members: [],
        ),
      );

      when(mockDataSource.getUserTrips()).thenAnswer((_) async => trips);

      // Act - Make multiple concurrent requests
      final futures = List.generate(5, (_) => useCase.getStatistics());
      final results = await Future.wait(futures);

      // Assert - All requests should return same statistics
      for (final stats in results) {
        expect(stats.totalCompletedTrips, 10);
        expect(stats.hasAnyTrips, true);
      }
    });
  });
}
