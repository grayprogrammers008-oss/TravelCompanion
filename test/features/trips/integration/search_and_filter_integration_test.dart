import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/usecases/search_trips_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/filter_trips_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Integration tests for combining search and filter functionality
/// Tests realistic scenarios of searching and filtering trips together
void main() {
  group('Search and Filter Integration Tests', () {
    late SearchTripsUseCase searchUseCase;
    late FilterTripsUseCase filterUseCase;
    late List<TripWithMembers> testTrips;
    late DateTime now;

    setUp(() {
      searchUseCase = SearchTripsUseCase();
      filterUseCase = FilterTripsUseCase();
      now = DateTime.now();

      // Create comprehensive test data set
      testTrips = [
        // Past trip to Paris
        TripWithMembers(
          trip: TripModel(
            id: 'trip1',
            name: 'Paris Summer Vacation',
            description: 'Exploring the Eiffel Tower and Louvre',
            destination: 'Paris, France',
            startDate: now.subtract(const Duration(days: 90)),
            endDate: now.subtract(const Duration(days: 80)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 120)),
            updatedAt: now.subtract(const Duration(days: 120)),
          ),
          members: [
            TripMemberModel(
              id: 'member1',
              tripId: 'trip1',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 120)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Ongoing trip to Tokyo
        TripWithMembers(
          trip: TripModel(
            id: 'trip2',
            name: 'Tokyo Business Trip',
            description: 'Conference and client meetings',
            destination: 'Tokyo, Japan',
            startDate: now.subtract(const Duration(days: 3)),
            endDate: now.add(const Duration(days: 4)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 30)),
            updatedAt: now.subtract(const Duration(days: 30)),
          ),
          members: [
            TripMemberModel(
              id: 'member2',
              tripId: 'trip2',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 30)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Upcoming trip to London
        TripWithMembers(
          trip: TripModel(
            id: 'trip3',
            name: 'London Weekend',
            description: 'Quick getaway to see Big Ben',
            destination: 'London, UK',
            startDate: now.add(const Duration(days: 10)),
            endDate: now.add(const Duration(days: 13)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 5)),
            updatedAt: now.subtract(const Duration(days: 5)),
          ),
          members: [
            TripMemberModel(
              id: 'member3',
              tripId: 'trip3',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 5)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Upcoming trip to Paris
        TripWithMembers(
          trip: TripModel(
            id: 'trip4',
            name: 'Paris Romantic Getaway',
            description: 'Anniversary trip with my partner',
            destination: 'Paris, France',
            startDate: now.add(const Duration(days: 60)),
            endDate: now.add(const Duration(days: 67)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(days: 2)),
          ),
          members: [
            TripMemberModel(
              id: 'member4',
              tripId: 'trip4',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 2)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Past trip to New York
        TripWithMembers(
          trip: TripModel(
            id: 'trip5',
            name: 'New York Business Conference',
            description: 'Tech conference in Manhattan',
            destination: 'New York, USA',
            startDate: now.subtract(const Duration(days: 45)),
            endDate: now.subtract(const Duration(days: 42)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 60)),
            updatedAt: now.subtract(const Duration(days: 60)),
          ),
          members: [
            TripMemberModel(
              id: 'member5',
              tripId: 'trip5',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 60)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Trip without dates
        TripWithMembers(
          trip: TripModel(
            id: 'trip6',
            name: 'Someday Barcelona Trip',
            description: 'Dream trip to Spain',
            destination: 'Barcelona, Spain',
            startDate: null,
            endDate: null,
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          members: [
            TripMemberModel(
              id: 'member6',
              tripId: 'trip6',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 10)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
      ];
    });

    group('Search then Filter scenarios', () {
      test('should search for "Paris" then filter for upcoming trips', () {
        // Arrange
        const query = 'Paris';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.upcoming,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final filteredResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(searchResults.length, 2); // trip1 and trip4
        expect(filteredResults.length, 1); // only trip4 is upcoming
        expect(filteredResults[0].trip.id, 'trip4');
      });

      test('should search for "Business" then filter for past trips', () {
        // Arrange
        const query = 'Business';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.past,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final filteredResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(searchResults.length, 2); // trip2 and trip5
        expect(filteredResults.length, 1); // only trip5 is past
        expect(filteredResults[0].trip.id, 'trip5');
      });

      test('should search for "Conference" then sort by date', () {
        // Arrange
        const query = 'Conference';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.dateOldest,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final sortedResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(searchResults.length, 2); // trip2 and trip5
        expect(sortedResults[0].trip.id, 'trip5'); // older trip first
        expect(sortedResults[1].trip.id, 'trip2');
      });

      test('should search then filter and sort', () {
        // Arrange
        const query = 'trip'; // matches all trips with "trip" in description
        const filterParams = TripFilterParams(
          filterType: TripFilterType.withDates,
          sortBy: TripSortBy.nameAsc,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final finalResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(searchResults.length, 3); // trips with "trip" in description
        expect(finalResults.every((t) => t.trip.startDate != null), true);
        // Verify alphabetical order
        for (var i = 0; i < finalResults.length - 1; i++) {
          expect(
            finalResults[i].trip.name.compareTo(finalResults[i + 1].trip.name),
            lessThanOrEqualTo(0),
          );
        }
      });
    });

    group('Filter then Search scenarios', () {
      test('should filter for upcoming trips then search for "Paris"', () {
        // Arrange
        const filterParams = TripFilterParams(
          filterType: TripFilterType.upcoming,
        );
        const query = 'Paris';

        // Act
        final filteredResults = filterUseCase(
          trips: testTrips,
          params: filterParams,
        );
        final searchResults = searchUseCase(
          trips: filteredResults,
          query: query,
        );

        // Assert
        expect(filteredResults.length, 2); // trip3 and trip4
        expect(searchResults.length, 1); // only trip4 matches "Paris"
        expect(searchResults[0].trip.id, 'trip4');
      });

      test('should filter for past trips then search for "conference"', () {
        // Arrange
        const filterParams = TripFilterParams(
          filterType: TripFilterType.past,
        );
        const query = 'conference';

        // Act
        final filteredResults = filterUseCase(
          trips: testTrips,
          params: filterParams,
        );
        final searchResults = searchUseCase(
          trips: filteredResults,
          query: query,
        );

        // Assert
        expect(filteredResults.length, 2); // trip1 and trip5
        expect(searchResults.length, 1); // only trip5 has "conference"
        expect(searchResults[0].trip.id, 'trip5');
      });

      test('should sort by name then search', () {
        // Arrange
        const filterParams = TripFilterParams(
          sortBy: TripSortBy.nameAsc,
        );
        const query = 'London';

        // Act
        final sortedResults = filterUseCase(
          trips: testTrips,
          params: filterParams,
        );
        final searchResults = searchUseCase(
          trips: sortedResults,
          query: query,
        );

        // Assert
        expect(sortedResults.length, testTrips.length);
        expect(searchResults.length, 1);
        expect(searchResults[0].trip.id, 'trip3');
      });
    });

    group('Complex scenarios', () {
      test('should handle empty results from search before filter', () {
        // Arrange
        const query = 'Antarctica'; // no trips match
        const filterParams = TripFilterParams(
          filterType: TripFilterType.upcoming,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final filteredResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(searchResults, []);
        expect(filteredResults, []);
      });

      test('should handle empty results from filter before search', () {
        // Arrange
        const filterParams = TripFilterParams(
          filterType: TripFilterType.ongoing,
        );
        const query = 'Paris'; // no ongoing trips to Paris

        // Act
        final filteredResults = filterUseCase(
          trips: testTrips,
          params: filterParams,
        );
        final searchResults = searchUseCase(
          trips: filteredResults,
          query: query,
        );

        // Assert
        expect(filteredResults.length, 1); // only trip2 is ongoing
        expect(searchResults, []); // trip2 is not to Paris
      });

      test('should handle search with custom date range filter', () {
        // Arrange
        const query = 'Paris';
        final filterParams = TripFilterParams(
          filterType: TripFilterType.all,
          customStartDate: now.add(const Duration(days: 50)),
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final filteredResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(searchResults.length, 2); // trip1 and trip4
        expect(filteredResults.length, 1); // only trip4 starts after day 50
        expect(filteredResults[0].trip.id, 'trip4');
      });

      test('should chain multiple operations maintaining order', () {
        // Arrange
        const query1 = 'Business';
        const query2 = 'conference';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.dateNewest,
        );

        // Act - Search for "Business"
        var results = searchUseCase(trips: testTrips, query: query1);

        // Then filter and sort
        results = filterUseCase(trips: results, params: filterParams);

        // Then search within results for "conference"
        results = searchUseCase(trips: results, query: query2);

        // Assert - Both trip2 and trip5 have "Business" and "conference"
        expect(results.length, 2);
        expect(results[0].trip.id, 'trip2'); // newest (ongoing)
        expect(results[1].trip.id, 'trip5'); // older (past)
      });
    });

    group('Real-world user scenarios', () {
      test('User wants to find all upcoming Paris trips sorted by date', () {
        // Arrange
        const query = 'Paris';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.upcoming,
          sortBy: TripSortBy.dateOldest,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final finalResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(finalResults.length, 1);
        expect(finalResults[0].trip.id, 'trip4');
        expect(finalResults[0].trip.name, 'Paris Romantic Getaway');
      });

      test('User wants past conference trips sorted by most recent', () {
        // Arrange
        const query = 'conference';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.past,
          sortBy: TripSortBy.dateNewest,
        );

        // Act
        final searchResults = searchUseCase(trips: testTrips, query: query);
        final finalResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );

        // Assert
        expect(finalResults.length, 1);
        expect(finalResults[0].trip.id, 'trip5');
        expect(finalResults[0].trip.name, 'New York Business Conference');
      });

      test('User wants all trips to Europe sorted alphabetically', () {
        // Arrange
        // European destinations: Paris, London, Barcelona
        const filterParams = TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.nameAsc,
        );

        // Act
        var results = testTrips.where((trip) {
          final dest = trip.trip.destination?.toLowerCase() ?? '';
          return dest.contains('paris') ||
              dest.contains('london') ||
              dest.contains('barcelona');
        }).toList();
        results = filterUseCase(trips: results, params: filterParams);

        // Assert
        expect(results.length, 4); // 2 Paris, 1 London, 1 Barcelona
        expect(results[0].trip.name, 'London Weekend');
        expect(results[1].trip.name, 'Paris Romantic Getaway');
        expect(results[2].trip.name, 'Paris Summer Vacation');
        expect(results[3].trip.name, 'Someday Barcelona Trip');
      });

      test('User wants trips created in last 7 days sorted by newest', () {
        // Arrange
        const filterParams = TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.createdNewest,
        );

        // Act
        final recentTrips = testTrips.where((trip) {
          if (trip.trip.createdAt == null) return false;
          final daysSinceCreated = now.difference(trip.trip.createdAt!).inDays;
          return daysSinceCreated <= 7;
        }).toList();
        final results = filterUseCase(trips: recentTrips, params: filterParams);

        // Assert
        expect(results.length, 2); // trip3 (5 days ago) and trip4 (2 days ago)
        expect(results[0].trip.id, 'trip4'); // most recent
        expect(results[1].trip.id, 'trip3');
      });
    });

    group('Performance tests', () {
      test('should handle large dataset with search and filter', () {
        // Arrange
        final largeDataset = List.generate(500, (index) {
          final isUpcoming = index % 2 == 0;
          return TripWithMembers(
            trip: TripModel(
              id: 'trip$index',
              name: 'Trip ${index % 10 == 0 ? "Paris" : "Other"} $index',
              description: 'Description $index',
              destination: index % 10 == 0 ? 'Paris, France' : 'Other, Place',
              startDate: isUpcoming
                  ? now.add(Duration(days: index))
                  : now.subtract(Duration(days: index)),
              endDate: isUpcoming
                  ? now.add(Duration(days: index + 5))
                  : now.subtract(Duration(days: index - 5)),
              coverImageUrl: null,
              createdBy: 'user1',
              createdAt: now.subtract(Duration(days: 1000 - index)),
              updatedAt: now.subtract(Duration(days: 1000 - index)),
            ),
            members: [],
          );
        });

        const query = 'Paris';
        const filterParams = TripFilterParams(
          filterType: TripFilterType.upcoming,
          sortBy: TripSortBy.dateOldest,
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final searchResults = searchUseCase(trips: largeDataset, query: query);
        final finalResults = filterUseCase(
          trips: searchResults,
          params: filterParams,
        );
        stopwatch.stop();

        // Assert
        expect(finalResults.length, greaterThan(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
