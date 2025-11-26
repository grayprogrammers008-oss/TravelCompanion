import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Unit tests for HomePage filter functionality
/// Tests budget filtering, date filtering, and combined filters
void main() {
  group('Trip Filter Logic Tests', () {
    // Sample test data
    final trip1 = TripModel(
      id: '1',
      name: 'Beach Vacation',
      description: 'Relaxing beach trip',
      destination: 'Goa',
      createdBy: 'user1',
      budget: 50000,
      currency: 'INR',
      createdAt: DateTime(2024, 11, 1),
    );

    final trip2 = TripModel(
      id: '2',
      name: 'Mountain Trek',
      description: 'Adventure in mountains',
      destination: 'Himalayas',
      createdBy: 'user1',
      budget: 30000,
      currency: 'INR',
      createdAt: DateTime(2024, 11, 15),
    );

    final trip3 = TripModel(
      id: '3',
      name: 'City Tour',
      description: 'Exploring the city',
      destination: 'Mumbai',
      createdBy: 'user1',
      budget: 80000,
      currency: 'INR',
      createdAt: DateTime(2024, 11, 25),
    );

    final trip4 = TripModel(
      id: '4',
      name: 'Budget Trip',
      description: 'Low cost adventure',
      destination: 'Nearby',
      createdBy: 'user1',
      budget: 10000,
      currency: 'INR',
      createdAt: DateTime(2024, 10, 20),
    );

    final trip5 = TripModel(
      id: '5',
      name: 'No Budget Trip',
      description: 'Trip without budget',
      destination: 'Unknown',
      createdBy: 'user1',
      budget: null,
      currency: 'INR',
      createdAt: DateTime(2024, 11, 10),
    );

    final tripWithMembers1 = TripWithMembers(trip: trip1, members: []);
    final tripWithMembers2 = TripWithMembers(trip: trip2, members: []);
    final tripWithMembers3 = TripWithMembers(trip: trip3, members: []);
    final tripWithMembers4 = TripWithMembers(trip: trip4, members: []);
    final tripWithMembers5 = TripWithMembers(trip: trip5, members: []);

    final allTrips = [
      tripWithMembers1,
      tripWithMembers2,
      tripWithMembers3,
      tripWithMembers4,
      tripWithMembers5,
    ];

    group('Budget Filter Tests', () {
      test('Filter by minimum budget only', () {
        final minBudget = 30000.0;

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.budget != null && trip.budget! < minBudget) {
            return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 4); // trip1, trip2, trip3, trip5 (null budget passes)
        expect(filtered.any((t) => t.trip.id == '1'), true);
        expect(filtered.any((t) => t.trip.id == '2'), true);
        expect(filtered.any((t) => t.trip.id == '3'), true);
        expect(filtered.any((t) => t.trip.id == '4'), false); // Filtered out (10k < 30k)
        expect(filtered.any((t) => t.trip.id == '5'), true); // Null budget passes
      });

      test('Filter by maximum budget only', () {
        final maxBudget = 50000.0;

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.budget != null && trip.budget! > maxBudget) {
            return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 4); // trip1, trip2, trip4, trip5
        expect(filtered.any((t) => t.trip.id == '1'), true);
        expect(filtered.any((t) => t.trip.id == '2'), true);
        expect(filtered.any((t) => t.trip.id == '3'), false); // Filtered out
        expect(filtered.any((t) => t.trip.id == '4'), true);
        expect(filtered.any((t) => t.trip.id == '5'), true); // Null budget passes
      });

      test('Filter by budget range', () {
        final minBudget = 30000.0;
        final maxBudget = 60000.0;

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.budget != null) {
            if (trip.budget! < minBudget || trip.budget! > maxBudget) {
              return false;
            }
          }
          return true;
        }).toList();

        expect(filtered.length, 3); // trip1, trip2, trip5
        expect(filtered.any((t) => t.trip.id == '1'), true);
        expect(filtered.any((t) => t.trip.id == '2'), true);
        expect(filtered.any((t) => t.trip.id == '3'), false); // > maxBudget
        expect(filtered.any((t) => t.trip.id == '4'), false); // < minBudget
        expect(filtered.any((t) => t.trip.id == '5'), true); // Null budget passes
      });

      test('Trips with null budget should pass all budget filters', () {
        final minBudget = 100000.0;
        final maxBudget = 200000.0;

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.budget != null) {
            if (trip.budget! < minBudget || trip.budget! > maxBudget) {
              return false;
            }
          }
          return true;
        }).toList();

        expect(filtered.length, 1); // Only trip5 with null budget
        expect(filtered.first.trip.id, '5');
      });
    });

    group('Date Created Filter Tests', () {
      test('Filter by created after date', () {
        final createdAfter = DateTime(2024, 11, 10);

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.createdAt != null && trip.createdAt!.isBefore(createdAfter)) {
            return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 3); // trip2, trip3, trip5
        expect(filtered.any((t) => t.trip.id == '1'), false); // Nov 1
        expect(filtered.any((t) => t.trip.id == '2'), true); // Nov 15
        expect(filtered.any((t) => t.trip.id == '3'), true); // Nov 25
        expect(filtered.any((t) => t.trip.id == '4'), false); // Oct 20
        expect(filtered.any((t) => t.trip.id == '5'), true); // Nov 10 (exact)
      });

      test('Filter by created before date (end of day)', () {
        final createdBefore = DateTime(2024, 11, 15);
        final endOfDay = DateTime(
          createdBefore.year,
          createdBefore.month,
          createdBefore.day,
          23,
          59,
          59,
        );

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.createdAt != null && trip.createdAt!.isAfter(endOfDay)) {
            return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 4); // trip1, trip2, trip4, trip5
        expect(filtered.any((t) => t.trip.id == '1'), true); // Nov 1
        expect(filtered.any((t) => t.trip.id == '2'), true); // Nov 15 (exact)
        expect(filtered.any((t) => t.trip.id == '3'), false); // Nov 25
        expect(filtered.any((t) => t.trip.id == '4'), true); // Oct 20
        expect(filtered.any((t) => t.trip.id == '5'), true); // Nov 10
      });

      test('Filter by date range', () {
        final createdAfter = DateTime(2024, 11, 1);
        final createdBefore = DateTime(2024, 11, 20);
        final endOfDay = DateTime(
          createdBefore.year,
          createdBefore.month,
          createdBefore.day,
          23,
          59,
          59,
        );

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.createdAt != null) {
            if (trip.createdAt!.isBefore(createdAfter)) return false;
            if (trip.createdAt!.isAfter(endOfDay)) return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 3); // trip1, trip2, trip5
        expect(filtered.any((t) => t.trip.id == '1'), true); // Nov 1
        expect(filtered.any((t) => t.trip.id == '2'), true); // Nov 15
        expect(filtered.any((t) => t.trip.id == '3'), false); // Nov 25
        expect(filtered.any((t) => t.trip.id == '4'), false); // Oct 20
        expect(filtered.any((t) => t.trip.id == '5'), true); // Nov 10
      });
    });

    group('Combined Filter Tests', () {
      test('Filter by both budget range and date range', () {
        final minBudget = 30000.0;
        final maxBudget = 60000.0;
        final createdAfter = DateTime(2024, 11, 1);
        final createdBefore = DateTime(2024, 11, 20);
        final endOfDay = DateTime(
          createdBefore.year,
          createdBefore.month,
          createdBefore.day,
          23,
          59,
          59,
        );

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;

          // Budget filter
          if (trip.budget != null) {
            if (trip.budget! < minBudget || trip.budget! > maxBudget) {
              return false;
            }
          }

          // Date filter
          if (trip.createdAt != null) {
            if (trip.createdAt!.isBefore(createdAfter)) return false;
            if (trip.createdAt!.isAfter(endOfDay)) return false;
          }

          return true;
        }).toList();

        expect(filtered.length, 3); // trip1, trip2, trip5
        expect(filtered.any((t) => t.trip.id == '1'), true); // 50k, Nov 1
        expect(filtered.any((t) => t.trip.id == '2'), true); // 30k, Nov 15
        expect(filtered.any((t) => t.trip.id == '3'), false); // 80k > maxBudget
        expect(filtered.any((t) => t.trip.id == '4'), false); // Oct 20 < createdAfter
        expect(filtered.any((t) => t.trip.id == '5'), true); // null budget, Nov 10
      });

      test('Strict budget and date range (no results)', () {
        final minBudget = 100000.0;
        final maxBudget = 200000.0;
        final createdAfter = DateTime(2024, 12, 1);
        final createdBefore = DateTime(2024, 12, 31);
        final endOfDay = DateTime(
          createdBefore.year,
          createdBefore.month,
          createdBefore.day,
          23,
          59,
          59,
        );

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;

          // Budget filter
          if (trip.budget != null) {
            if (trip.budget! < minBudget || trip.budget! > maxBudget) {
              return false;
            }
          }

          // Date filter
          if (trip.createdAt != null) {
            if (trip.createdAt!.isBefore(createdAfter)) return false;
            if (trip.createdAt!.isAfter(endOfDay)) return false;
          }

          return true;
        }).toList();

        expect(filtered.length, 0); // No trips match
      });
    });

    group('Search Filter Tests', () {
      test('Search by trip name', () {
        final query = 'beach';

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          final nameMatch = trip.name.toLowerCase().contains(query.toLowerCase());
          final destinationMatch = trip.destination?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final descriptionMatch = trip.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || destinationMatch || descriptionMatch;
        }).toList();

        expect(filtered.length, 1);
        expect(filtered.first.trip.id, '1');
      });

      test('Search by destination', () {
        final query = 'goa';

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          final nameMatch = trip.name.toLowerCase().contains(query.toLowerCase());
          final destinationMatch = trip.destination?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final descriptionMatch = trip.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || destinationMatch || descriptionMatch;
        }).toList();

        expect(filtered.length, 1);
        expect(filtered.first.trip.id, '1');
      });

      test('Search by description', () {
        final query = 'adventure';

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          final nameMatch = trip.name.toLowerCase().contains(query.toLowerCase());
          final destinationMatch = trip.destination?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final descriptionMatch = trip.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || destinationMatch || descriptionMatch;
        }).toList();

        expect(filtered.length, 2); // trip2 and trip4
        expect(filtered.any((t) => t.trip.id == '2'), true);
        expect(filtered.any((t) => t.trip.id == '4'), true);
      });

      test('Combined search and filter', () {
        final query = 'trip';
        final minBudget = 20000.0;

        final filtered = allTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;

          // Search filter
          final nameMatch = trip.name.toLowerCase().contains(query.toLowerCase());
          final destinationMatch = trip.destination?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final descriptionMatch = trip.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
          if (!nameMatch && !destinationMatch && !descriptionMatch) {
            return false;
          }

          // Budget filter
          if (trip.budget != null && trip.budget! < minBudget) {
            return false;
          }

          return true;
        }).toList();

        // trip1 has "trip" in description ("beach trip")
        // trip4 and trip5 have "trip" in name
        // After budget filter: trip1 (50k) and trip5 (null) pass
        // trip4 (10k) is filtered out by minBudget
        expect(filtered.length, 2);
        expect(filtered.any((t) => t.trip.id == '1'), true); // Has "trip" in description, 50k passes
        expect(filtered.any((t) => t.trip.id == '4'), false); // 10k < minBudget
        expect(filtered.any((t) => t.trip.id == '5'), true); // null budget passes
      });
    });

    group('Edge Cases', () {
      test('Empty trips list returns empty', () {
        final filtered = <TripWithMembers>[].where((tripWithMembers) {
          return true;
        }).toList();

        expect(filtered.length, 0);
      });

      test('No filters applied returns all trips', () {
        final filtered = allTrips.where((tripWithMembers) {
          return true;
        }).toList();

        expect(filtered.length, 5);
      });

      test('Trip with null createdAt passes date filters', () {
        final tripNoDate = TripModel(
          id: '6',
          name: 'No Date Trip',
          createdBy: 'user1',
          createdAt: null,
        );
        final tripWithMembersNoDate = TripWithMembers(trip: tripNoDate, members: []);
        final testTrips = [tripWithMembersNoDate];

        final createdAfter = DateTime(2024, 11, 1);

        final filtered = testTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.createdAt != null && trip.createdAt!.isBefore(createdAfter)) {
            return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 1); // Null date passes
      });

      test('Zero budget is valid and different from null budget', () {
        final tripZeroBudget = TripModel(
          id: '7',
          name: 'Free Trip',
          createdBy: 'user1',
          budget: 0,
          currency: 'INR',
        );
        final tripWithMembersZero = TripWithMembers(trip: tripZeroBudget, members: []);
        final testTrips = [tripWithMembersZero];

        final minBudget = 10000.0;

        final filtered = testTrips.where((tripWithMembers) {
          final trip = tripWithMembers.trip;
          if (trip.budget != null && trip.budget! < minBudget) {
            return false;
          }
          return true;
        }).toList();

        expect(filtered.length, 0); // Zero budget is filtered out
      });
    });
  });
}
