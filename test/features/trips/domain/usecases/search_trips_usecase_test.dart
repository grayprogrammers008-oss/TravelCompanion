import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/usecases/search_trips_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

void main() {
  group('SearchTripsUseCase', () {
    late SearchTripsUseCase useCase;
    late List<TripWithMembers> testTrips;

    setUp(() {
      useCase = SearchTripsUseCase();

      // Create test data with various scenarios
      testTrips = [
        TripWithMembers(
          trip: TripModel(
            id: 'trip1',
            name: 'Paris Adventure',
            description: 'Exploring the City of Light',
            destination: 'Paris, France',
            startDate: DateTime(2024, 7, 1),
            endDate: DateTime(2024, 7, 15),
            coverImageUrl: 'https://example.com/paris.jpg',
            createdBy: 'user1',
            createdAt: DateTime(2024, 6, 1),
            updatedAt: DateTime(2024, 6, 1),
          ),
          members: [
            TripMemberModel(
              id: 'member1',
              tripId: 'trip1',
              userId: 'user1',
              role: 'owner',
              joinedAt: DateTime(2024, 6, 1),
              fullName: 'John Doe',
              avatarUrl: 'https://example.com/john.jpg',
            ),
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: 'trip2',
            name: 'Tokyo Journey',
            description: 'Discovering Japanese culture',
            destination: 'Tokyo, Japan',
            startDate: DateTime(2024, 3, 1),
            endDate: DateTime(2024, 3, 10),
            coverImageUrl: 'https://example.com/tokyo.jpg',
            createdBy: 'user1',
            createdAt: DateTime(2024, 2, 1),
            updatedAt: DateTime(2024, 2, 1),
          ),
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
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: 'trip3',
            name: 'New York Weekend',
            description: 'Quick trip to the Big Apple',
            destination: 'New York, USA',
            startDate: DateTime(2024, 5, 1),
            endDate: DateTime(2024, 5, 3),
            coverImageUrl: 'https://example.com/ny.jpg',
            createdBy: 'user1',
            createdAt: DateTime(2024, 4, 1),
            updatedAt: DateTime(2024, 4, 1),
          ),
          members: [
            TripMemberModel(
              id: 'member3',
              tripId: 'trip3',
              userId: 'user1',
              role: 'owner',
              joinedAt: DateTime(2024, 4, 1),
              fullName: 'John Doe',
              avatarUrl: 'https://example.com/john.jpg',
            ),
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: 'trip4',
            name: 'London Business Trip',
            description: null, // No description
            destination: 'London, UK',
            startDate: DateTime(2024, 8, 1),
            endDate: DateTime(2024, 8, 5),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: DateTime(2024, 7, 1),
            updatedAt: DateTime(2024, 7, 1),
          ),
          members: [
            TripMemberModel(
              id: 'member4',
              tripId: 'trip4',
              userId: 'user1',
              role: 'owner',
              joinedAt: DateTime(2024, 7, 1),
              fullName: 'John Doe',
              avatarUrl: 'https://example.com/john.jpg',
            ),
          ],
        ),
      ];
    });

    group('Search by trip name', () {
      test('should find trip by exact name match', () {
        // Act
        final result = useCase(trips: testTrips, query: 'Paris Adventure');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip1');
        expect(result[0].trip.name, 'Paris Adventure');
      });

      test('should find trip by partial name match', () {
        // Act
        final result = useCase(trips: testTrips, query: 'Paris');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.name, 'Paris Adventure');
      });

      test('should be case-insensitive when searching by name', () {
        // Act
        final result = useCase(trips: testTrips, query: 'TOKYO');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.name, 'Tokyo Journey');
      });

      test('should find multiple trips with similar names', () {
        // Act
        final result = useCase(trips: testTrips, query: 'trip');

        // Assert
        expect(result.length, 2); // "Quick trip" and "Business Trip"
        expect(result.any((t) => t.trip.id == 'trip3'), true);
        expect(result.any((t) => t.trip.id == 'trip4'), true);
      });
    });

    group('Search by description', () {
      test('should find trip by description match', () {
        // Act
        final result = useCase(trips: testTrips, query: 'culture');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip2');
        expect(result[0].trip.description, 'Discovering Japanese culture');
      });

      test('should find trip by partial description match', () {
        // Act
        final result = useCase(trips: testTrips, query: 'City of Light');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip1');
      });

      test('should be case-insensitive when searching by description', () {
        // Act
        final result = useCase(trips: testTrips, query: 'BIG APPLE');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip3');
      });

      test('should handle trips with null description gracefully', () {
        // Act
        final result = useCase(trips: testTrips, query: 'London');

        // Assert - Should find by destination, not crash on null description
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip4');
      });
    });

    group('Search by destination', () {
      test('should find trip by destination match', () {
        // Act
        final result = useCase(trips: testTrips, query: 'France');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.destination, 'Paris, France');
      });

      test('should find trip by city in destination', () {
        // Act
        final result = useCase(trips: testTrips, query: 'Tokyo');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.destination, 'Tokyo, Japan');
      });

      test('should be case-insensitive when searching by destination', () {
        // Act
        final result = useCase(trips: testTrips, query: 'new york');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.destination, 'New York, USA');
      });

      test('should find trip by country in destination', () {
        // Act
        final result = useCase(trips: testTrips, query: 'USA');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.destination, 'New York, USA');
      });
    });

    group('Search across multiple fields', () {
      test('should find trip when query matches name or description', () {
        // Act - "Exploring" is in description
        final result = useCase(trips: testTrips, query: 'Exploring');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip1');
      });

      test('should find trip when query matches name or destination', () {
        // Act - "London" is in both name and destination
        final result = useCase(trips: testTrips, query: 'London');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip4');
      });
    });

    group('Edge cases', () {
      test('should return all trips when query is null', () {
        // Act
        final result = useCase(trips: testTrips, query: null);

        // Assert
        expect(result.length, testTrips.length);
        expect(result, testTrips);
      });

      test('should return all trips when query is empty string', () {
        // Act
        final result = useCase(trips: testTrips, query: '');

        // Assert
        expect(result.length, testTrips.length);
        expect(result, testTrips);
      });

      test('should return all trips when query is whitespace only', () {
        // Act
        final result = useCase(trips: testTrips, query: '   ');

        // Assert
        expect(result.length, testTrips.length);
        expect(result, testTrips);
      });

      test('should return empty list when no trips match', () {
        // Act
        final result = useCase(trips: testTrips, query: 'Antarctica');

        // Assert
        expect(result.length, 0);
        expect(result, []);
      });

      test('should return empty list when searching in empty trip list', () {
        // Act
        final result = useCase(trips: [], query: 'Paris');

        // Assert
        expect(result.length, 0);
        expect(result, []);
      });

      test('should trim whitespace from query', () {
        // Act
        final result = useCase(trips: testTrips, query: '  Paris  ');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.name, 'Paris Adventure');
      });

      test('should handle special characters in query', () {
        // Add trip with special characters
        final specialTrip = TripWithMembers(
          trip: TripModel(
            id: 'trip5',
            name: 'São Paulo Adventure',
            description: 'Exploring São Paulo',
            destination: 'São Paulo, Brazil',
            startDate: DateTime(2024, 9, 1),
            endDate: DateTime(2024, 9, 10),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: DateTime(2024, 8, 1),
            updatedAt: DateTime(2024, 8, 1),
          ),
          members: [
            TripMemberModel(
              id: 'member5',
              tripId: 'trip5',
              userId: 'user1',
              role: 'owner',
              joinedAt: DateTime(2024, 8, 1),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        );

        final tripsWithSpecial = [...testTrips, specialTrip];

        // Act
        final result = useCase(trips: tripsWithSpecial, query: 'São Paulo');

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip5');
      });
    });

    group('Performance and efficiency', () {
      test('should handle large number of trips efficiently', () {
        // Arrange
        final largeList = List.generate(
          1000,
          (index) => TripWithMembers(
            trip: TripModel(
              id: 'trip$index',
              name: 'Trip $index',
              description: 'Description $index',
              destination: 'Destination $index',
              startDate: DateTime(2024, 1, 1).add(Duration(days: index)),
              endDate: DateTime(2024, 1, 10).add(Duration(days: index)),
              coverImageUrl: null,
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
                fullName: 'User $index',
                avatarUrl: null,
              ),
            ],
          ),
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final result = useCase(trips: largeList, query: 'Trip 500');
        stopwatch.stop();

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip500');
        // Search should complete in reasonable time (< 100ms for 1000 items)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should not modify original trips list', () {
        // Arrange
        final originalLength = testTrips.length;
        final firstTripId = testTrips[0].trip.id;

        // Act
        useCase(trips: testTrips, query: 'Paris');

        // Assert
        expect(testTrips.length, originalLength);
        expect(testTrips[0].trip.id, firstTripId);
      });
    });
  });
}
