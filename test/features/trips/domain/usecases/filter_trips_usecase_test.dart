import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/usecases/filter_trips_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

void main() {
  group('FilterTripsUseCase', () {
    late FilterTripsUseCase useCase;
    late List<TripWithMembers> testTrips;
    late DateTime now;

    setUp(() {
      useCase = FilterTripsUseCase();
      now = DateTime.now();

      // Create comprehensive test data
      testTrips = [
        // Past trip
        TripWithMembers(
          trip: TripModel(
            id: 'trip1',
            name: 'Barcelona Vacation',
            description: 'Past trip to Spain',
            destination: 'Barcelona, Spain',
            startDate: now.subtract(const Duration(days: 30)),
            endDate: now.subtract(const Duration(days: 20)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 60)),
            updatedAt: now.subtract(const Duration(days: 60)),
          ),
          members: [
            TripMemberModel(
              id: 'member1',
              tripId: 'trip1',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 60)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Ongoing trip
        TripWithMembers(
          trip: TripModel(
            id: 'trip2',
            name: 'Tokyo Adventure',
            description: 'Currently in Tokyo',
            destination: 'Tokyo, Japan',
            startDate: now.subtract(const Duration(days: 5)),
            endDate: now.add(const Duration(days: 5)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 40)),
            updatedAt: now.subtract(const Duration(days: 40)),
          ),
          members: [
            TripMemberModel(
              id: 'member2',
              tripId: 'trip2',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 40)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Upcoming trip
        TripWithMembers(
          trip: TripModel(
            id: 'trip3',
            name: 'Paris Trip',
            description: 'Future trip to France',
            destination: 'Paris, France',
            startDate: now.add(const Duration(days: 30)),
            endDate: now.add(const Duration(days: 40)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 20)),
            updatedAt: now.subtract(const Duration(days: 20)),
          ),
          members: [
            TripMemberModel(
              id: 'member3',
              tripId: 'trip3',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 20)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Trip without dates
        TripWithMembers(
          trip: TripModel(
            id: 'trip4',
            name: 'Undated Adventure',
            description: 'Trip without dates',
            destination: 'Somewhere',
            startDate: null,
            endDate: null,
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 10)),
            updatedAt: now.subtract(const Duration(days: 10)),
          ),
          members: [
            TripMemberModel(
              id: 'member4',
              tripId: 'trip4',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 10)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
        // Another upcoming trip (for sorting tests)
        TripWithMembers(
          trip: TripModel(
            id: 'trip5',
            name: 'London Weekend',
            description: 'Quick London trip',
            destination: 'London, UK',
            startDate: now.add(const Duration(days: 10)),
            endDate: now.add(const Duration(days: 12)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: now.subtract(const Duration(days: 5)),
            updatedAt: now.subtract(const Duration(days: 5)),
          ),
          members: [
            TripMemberModel(
              id: 'member5',
              tripId: 'trip5',
              userId: 'user1',
              role: 'owner',
              joinedAt: now.subtract(const Duration(days: 5)),
              fullName: 'John Doe',
              avatarUrl: null,
            ),
          ],
        ),
      ];
    });

    group('Filter by type - All', () {
      test('should return all trips when filterType is all', () {
        // Arrange
        final params = const TripFilterParams(filterType: TripFilterType.all);

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, testTrips.length);
      });
    });

    group('Filter by type - Upcoming', () {
      test('should return only upcoming trips', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.upcoming,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 2); // trip3 and trip5
        expect(result.every((t) => t.trip.startDate!.isAfter(now)), true);
        expect(result.any((t) => t.trip.id == 'trip3'), true);
        expect(result.any((t) => t.trip.id == 'trip5'), true);
      });

      test('should exclude trips without start date from upcoming', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.upcoming,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.any((t) => t.trip.id == 'trip4'), false);
      });
    });

    group('Filter by type - Ongoing', () {
      test('should return only ongoing trips', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.ongoing,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 1); // only trip2
        expect(result[0].trip.id, 'trip2');
        expect(result[0].trip.startDate!.isBefore(now), true);
        expect(result[0].trip.endDate!.isAfter(now), true);
      });

      test('should exclude trips without dates from ongoing', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.ongoing,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.any((t) => t.trip.id == 'trip4'), false);
      });
    });

    group('Filter by type - Past', () {
      test('should return only past trips', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.past,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 1); // only trip1
        expect(result[0].trip.id, 'trip1');
        expect(result[0].trip.endDate!.isBefore(now), true);
      });

      test('should exclude trips without end date from past', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.past,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.any((t) => t.trip.id == 'trip4'), false);
      });
    });

    group('Filter by type - With/Without Dates', () {
      test('should return only trips with dates', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.withDates,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 4); // all except trip4
        expect(result.every((t) => t.trip.startDate != null), true);
        expect(result.every((t) => t.trip.endDate != null), true);
        expect(result.any((t) => t.trip.id == 'trip4'), false);
      });

      test('should return only trips without dates', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.withoutDates,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 1); // only trip4
        expect(result[0].trip.id, 'trip4');
        expect(
          result[0].trip.startDate == null || result[0].trip.endDate == null,
          true,
        );
      });
    });

    group('Custom date range filter', () {
      test('should filter trips by custom start date', () {
        // Arrange
        final customStartDate = now.add(const Duration(days: 15));
        final params = TripFilterParams(
          filterType: TripFilterType.all,
          customStartDate: customStartDate,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert - should only include trips starting after day 15
        expect(result.length, 1); // only trip3
        expect(result[0].trip.id, 'trip3');
      });

      test('should filter trips by custom end date', () {
        // Arrange
        final customEndDate = now.add(const Duration(days: 15));
        final params = TripFilterParams(
          filterType: TripFilterType.all,
          customEndDate: customEndDate,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert - should include trips ending before day 15
        expect(result.length, 3); // trip1, trip2, trip5
        expect(result.any((t) => t.trip.id == 'trip1'), true);
        expect(result.any((t) => t.trip.id == 'trip2'), true);
        expect(result.any((t) => t.trip.id == 'trip5'), true);
      });

      test('should filter trips by both custom start and end dates', () {
        // Arrange
        final customStartDate = now.add(const Duration(days: 5));
        final customEndDate = now.add(const Duration(days: 25));
        final params = TripFilterParams(
          filterType: TripFilterType.all,
          customStartDate: customStartDate,
          customEndDate: customEndDate,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert - should include trips in the date range
        expect(result.length, 1); // only trip5
        expect(result[0].trip.id, 'trip5');
      });

      test('should handle trips without dates when using custom date range', () {
        // Arrange
        final customStartDate = now;
        final params = TripFilterParams(
          filterType: TripFilterType.all,
          customStartDate: customStartDate,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert - trip4 (without dates) should be excluded
        expect(result.any((t) => t.trip.id == 'trip4'), false);
      });
    });

    group('Sort by name', () {
      test('should sort trips by name ascending', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.nameAsc,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result[0].trip.name, 'Barcelona Vacation');
        expect(result[1].trip.name, 'London Weekend');
        expect(result[2].trip.name, 'Paris Trip');
        expect(result[3].trip.name, 'Tokyo Adventure');
        expect(result[4].trip.name, 'Undated Adventure');
      });

      test('should sort trips by name descending', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.nameDesc,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result[0].trip.name, 'Undated Adventure');
        expect(result[1].trip.name, 'Tokyo Adventure');
        expect(result[2].trip.name, 'Paris Trip');
        expect(result[3].trip.name, 'London Weekend');
        expect(result[4].trip.name, 'Barcelona Vacation');
      });
    });

    group('Sort by date', () {
      test('should sort trips by date newest first', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.dateNewest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result[0].trip.id, 'trip3'); // furthest in future
        expect(result[1].trip.id, 'trip5');
        expect(result[2].trip.id, 'trip2');
        expect(result[3].trip.id, 'trip1');
        expect(result[4].trip.id, 'trip4'); // no date, goes last
      });

      test('should sort trips by date oldest first', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.dateOldest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result[0].trip.id, 'trip1'); // oldest start date
        expect(result[1].trip.id, 'trip2');
        expect(result[2].trip.id, 'trip5');
        expect(result[3].trip.id, 'trip3');
        expect(result[4].trip.id, 'trip4'); // no date, goes last
      });

      test('should put trips without dates at end when sorting by date', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.dateNewest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert - trip4 (without dates) should be last
        expect(result.last.trip.id, 'trip4');
      });
    });

    group('Sort by created date', () {
      test('should sort trips by created date newest first', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.createdNewest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result[0].trip.id, 'trip5'); // created 5 days ago
        expect(result[1].trip.id, 'trip4'); // created 10 days ago
        expect(result[2].trip.id, 'trip3'); // created 20 days ago
        expect(result[3].trip.id, 'trip2'); // created 40 days ago
        expect(result[4].trip.id, 'trip1'); // created 60 days ago
      });

      test('should sort trips by created date oldest first', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.createdOldest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result[0].trip.id, 'trip1'); // created 60 days ago
        expect(result[1].trip.id, 'trip2'); // created 40 days ago
        expect(result[2].trip.id, 'trip3'); // created 20 days ago
        expect(result[3].trip.id, 'trip4'); // created 10 days ago
        expect(result[4].trip.id, 'trip5'); // created 5 days ago
      });
    });

    group('Combined filter and sort', () {
      test('should filter upcoming trips and sort by date', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.upcoming,
          sortBy: TripSortBy.dateOldest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 2);
        expect(result[0].trip.id, 'trip5'); // earlier upcoming trip
        expect(result[1].trip.id, 'trip3'); // later upcoming trip
      });

      test('should filter past trips and sort by name', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.past,
          sortBy: TripSortBy.nameAsc,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 1);
        expect(result[0].trip.id, 'trip1');
      });

      test('should filter trips with dates and sort by created date', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.withDates,
          sortBy: TripSortBy.createdNewest,
        );

        // Act
        final result = useCase(trips: testTrips, params: params);

        // Assert
        expect(result.length, 4);
        expect(result[0].trip.id, 'trip5');
        expect(result.any((t) => t.trip.id == 'trip4'), false); // excluded
      });
    });

    group('Edge cases', () {
      test('should handle empty trip list', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.all,
        );

        // Act
        final result = useCase(trips: [], params: params);

        // Assert
        expect(result, []);
      });

      test('should handle trip list with all trips matching filter', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.withDates,
        );

        final tripsWithDates = testTrips.where((t) =>
            t.trip.startDate != null && t.trip.endDate != null).toList();

        // Act
        final result = useCase(trips: tripsWithDates, params: params);

        // Assert
        expect(result.length, tripsWithDates.length);
      });

      test('should handle trip list with no trips matching filter', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.upcoming,
        );

        final pastTrips = testTrips.where((t) =>
            t.trip.endDate != null && t.trip.endDate!.isBefore(now)).toList();

        // Act
        final result = useCase(trips: pastTrips, params: params);

        // Assert
        expect(result, []);
      });

      test('should not modify original trips list', () {
        // Arrange
        final params = const TripFilterParams(
          filterType: TripFilterType.upcoming,
          sortBy: TripSortBy.nameDesc,
        );
        final originalLength = testTrips.length;
        final originalFirstId = testTrips.first.trip.id;

        // Act
        useCase(trips: testTrips, params: params);

        // Assert
        expect(testTrips.length, originalLength);
        expect(testTrips.first.trip.id, originalFirstId);
      });

      test('should handle trips with null createdAt when sorting', () {
        // Arrange
        final tripWithoutCreatedAt = TripWithMembers(
          trip: TripModel(
            id: 'trip6',
            name: 'No Created Date',
            description: null,
            destination: 'Unknown',
            startDate: now,
            endDate: now.add(const Duration(days: 1)),
            coverImageUrl: null,
            createdBy: 'user1',
            createdAt: null,
            updatedAt: null,
          ),
          members: [],
        );

        final tripsWithNull = [...testTrips, tripWithoutCreatedAt];

        final params = const TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.createdNewest,
        );

        // Act
        final result = useCase(trips: tripsWithNull, params: params);

        // Assert - trip without createdAt should be at the end
        expect(result.last.trip.id, 'trip6');
      });
    });

    group('TripFilterParams', () {
      test('should create default params', () {
        // Act
        const params = TripFilterParams();

        // Assert
        expect(params.filterType, TripFilterType.all);
        expect(params.sortBy, TripSortBy.dateNewest);
        expect(params.customStartDate, null);
        expect(params.customEndDate, null);
      });

      test('should copy with new values', () {
        // Arrange
        const original = TripFilterParams(
          filterType: TripFilterType.all,
          sortBy: TripSortBy.nameAsc,
        );

        // Act
        final copied = original.copyWith(
          filterType: TripFilterType.upcoming,
          sortBy: TripSortBy.dateNewest,
        );

        // Assert
        expect(copied.filterType, TripFilterType.upcoming);
        expect(copied.sortBy, TripSortBy.dateNewest);
        expect(original.filterType, TripFilterType.all);
        expect(original.sortBy, TripSortBy.nameAsc);
      });

      test('should preserve unchanged values when copying', () {
        // Arrange
        final customDate = DateTime(2024, 6, 1);
        final original = TripFilterParams(
          filterType: TripFilterType.past,
          sortBy: TripSortBy.nameDesc,
          customStartDate: customDate,
        );

        // Act
        final copied = original.copyWith(sortBy: TripSortBy.dateOldest);

        // Assert
        expect(copied.filterType, TripFilterType.past);
        expect(copied.sortBy, TripSortBy.dateOldest);
        expect(copied.customStartDate, customDate);
      });
    });
  });
}
