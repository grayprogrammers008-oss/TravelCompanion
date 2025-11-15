import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/search_itinerary_usecase.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

/// Integration tests for itinerary search functionality
/// Tests realistic scenarios of searching through trip itineraries
void main() {
  group('Search Itinerary Integration Tests', () {
    late SearchItineraryUseCase searchUseCase;
    late List<ItineraryItemModel> testItems;

    setUp(() {
      searchUseCase = SearchItineraryUseCase();

      // Create comprehensive test data set representing a multi-day trip
      testItems = [
        // Day 1 - Arrival and Paris landmarks
        ItineraryItemModel(
          id: 'item1',
          tripId: 'trip1',
          title: 'Hotel Check-in',
          description: 'Arrive at Hotel Le Marais',
          location: 'Hotel Le Marais, 4th Arrondissement, Paris',
          startTime: DateTime(2024, 7, 1, 14, 0),
          endTime: DateTime(2024, 7, 1, 15, 0),
          dayNumber: 1,
          orderIndex: 0,
        ),
        ItineraryItemModel(
          id: 'item2',
          tripId: 'trip1',
          title: 'Visit Eiffel Tower',
          description: 'Iconic iron landmark with city views',
          location: 'Champ de Mars, 5 Avenue Anatole France, Paris',
          startTime: DateTime(2024, 7, 1, 16, 0),
          endTime: DateTime(2024, 7, 1, 18, 0),
          dayNumber: 1,
          orderIndex: 1,
        ),
        ItineraryItemModel(
          id: 'item3',
          tripId: 'trip1',
          title: 'Dinner at Le Jules Verne',
          description: 'Fine dining restaurant in Eiffel Tower',
          location: 'Eiffel Tower, Avenue Gustave Eiffel, Paris',
          startTime: DateTime(2024, 7, 1, 19, 30),
          endTime: DateTime(2024, 7, 1, 21, 30),
          dayNumber: 1,
          orderIndex: 2,
        ),
        // Day 2 - Museums and art
        ItineraryItemModel(
          id: 'item4',
          tripId: 'trip1',
          title: 'Louvre Museum',
          description: 'World\'s largest art museum and historic monument',
          location: 'Rue de Rivoli, 75001 Paris, France',
          startTime: DateTime(2024, 7, 2, 9, 0),
          endTime: DateTime(2024, 7, 2, 13, 0),
          dayNumber: 2,
          orderIndex: 0,
        ),
        ItineraryItemModel(
          id: 'item5',
          tripId: 'trip1',
          title: 'Lunch at Café Marly',
          description: 'Café with Louvre pyramid views',
          location: '93 Rue de Rivoli, 75001 Paris',
          startTime: DateTime(2024, 7, 2, 13, 0),
          endTime: DateTime(2024, 7, 2, 14, 30),
          dayNumber: 2,
          orderIndex: 1,
        ),
        ItineraryItemModel(
          id: 'item6',
          tripId: 'trip1',
          title: 'Musée d\'Orsay',
          description: 'Impressionist and post-impressionist masterpieces',
          location: '1 Rue de la Légion d\'Honneur, 75007 Paris',
          startTime: DateTime(2024, 7, 2, 15, 0),
          endTime: DateTime(2024, 7, 2, 18, 0),
          dayNumber: 2,
          orderIndex: 2,
        ),
        // Day 3 - Versailles day trip
        ItineraryItemModel(
          id: 'item7',
          tripId: 'trip1',
          title: 'Palace of Versailles',
          description: 'Former royal residence with stunning gardens',
          location: 'Place d\'Armes, 78000 Versailles, France',
          startTime: DateTime(2024, 7, 3, 9, 0),
          endTime: DateTime(2024, 7, 3, 17, 0),
          dayNumber: 3,
          orderIndex: 0,
        ),
        ItineraryItemModel(
          id: 'item8',
          tripId: 'trip1',
          title: 'Gardens of Versailles',
          description: 'Explore the magnificent palace gardens',
          location: 'Gardens of Versailles, France',
          startTime: DateTime(2024, 7, 3, 14, 0),
          endTime: DateTime(2024, 7, 3, 16, 0),
          dayNumber: 3,
          orderIndex: 1,
        ),
        // Day 4 - Shopping and culture
        ItineraryItemModel(
          id: 'item9',
          tripId: 'trip1',
          title: 'Shopping on Champs-Élysées',
          description: 'Luxury shopping on the famous avenue',
          location: 'Avenue des Champs-Élysées, Paris',
          startTime: DateTime(2024, 7, 4, 10, 0),
          endTime: DateTime(2024, 7, 4, 13, 0),
          dayNumber: 4,
          orderIndex: 0,
        ),
        ItineraryItemModel(
          id: 'item10',
          tripId: 'trip1',
          title: 'Arc de Triomphe',
          description: 'Iconic triumphal arch monument',
          location: 'Place Charles de Gaulle, Paris',
          startTime: DateTime(2024, 7, 4, 14, 0),
          endTime: DateTime(2024, 7, 4, 15, 30),
          dayNumber: 4,
          orderIndex: 1,
        ),
      ];
    });

    group('Search and Filter by Day', () {
      test('should search for "museum" and get results from specific days', () {
        // Arrange
        const query = 'museum';

        // Act
        final searchResults = searchUseCase(items: testItems, query: query);
        final day2Items = searchResults.where((item) => item.dayNumber == 2).toList();

        // Assert
        expect(searchResults.length, 1); // Only "Louvre Museum" has "museum" in title
        expect(day2Items.length, 1); // Louvre is on day 2
        expect(day2Items.any((i) => i.id == 'item4'), true);
      });

      test('should search for location "Paris" and filter by day', () {
        // Arrange
        const query = 'Paris';

        // Act
        final searchResults = searchUseCase(items: testItems, query: query);
        final day1Items = searchResults.where((item) => item.dayNumber == 1).toList();
        final day3Items = searchResults.where((item) => item.dayNumber == 3).toList();

        // Assert
        expect(searchResults.length, 8); // All Paris activities (items 1-6, 9-10)
        expect(day1Items.length, 3); // Day 1 Paris activities
        expect(day3Items.length, 0); // Day 3 is Versailles
      });
    });

    group('Search and Filter by Time', () {
      test('should find morning activities (before noon)', () {
        // Arrange
        const query = 'palace'; // Will find Palace of Versailles

        // Act
        final searchResults = searchUseCase(items: testItems, query: query);
        final morningActivities = searchResults.where((item) {
          if (item.startTime == null) return false;
          return item.startTime!.hour < 12;
        }).toList();

        // Assert
        expect(searchResults.length, 2); // Palace of Versailles + Gardens
        expect(morningActivities.length, 1); // Palace starts at 9 AM
        expect(morningActivities[0].id, 'item7');
      });

      test('should find evening activities (after 6 PM)', () {
        // Arrange
        final eveningItems = testItems.where((item) {
          if (item.startTime == null) return false;
          return item.startTime!.hour >= 18;
        }).toList();

        // Act
        final result = searchUseCase(items: eveningItems, query: 'Eiffel');

        // Assert
        expect(eveningItems.length, 1); // Only Dinner at Le Jules Verne starts after 6 PM
        expect(result.length, 1); // Dinner has "Eiffel" in location
      });
    });

    group('Complex Search Scenarios', () {
      test('should search for "Tower" and group by day', () {
        // Arrange
        const query = 'Tower';

        // Act
        final searchResults = searchUseCase(items: testItems, query: query);
        final byDay = <int, List<ItineraryItemModel>>{};
        for (var item in searchResults) {
          if (item.dayNumber != null) {
            byDay.putIfAbsent(item.dayNumber!, () => []).add(item);
          }
        }

        // Assert
        expect(searchResults.length, 2); // Eiffel Tower visit and dinner
        expect(byDay[1]?.length, 2); // Both on day 1
      });

      test('should search for dining/food activities', () {
        // Arrange
        const queries = ['dinner', 'lunch', 'café', 'restaurant'];
        final allResults = <ItineraryItemModel>{};

        // Act
        for (var query in queries) {
          final results = searchUseCase(items: testItems, query: query);
          allResults.addAll(results);
        }

        // Assert
        expect(allResults.length, 2); // Le Jules Verne and Café Marly (Set removes duplicates)
        expect(allResults.any((i) => i.id == 'item3'), true);
        expect(allResults.any((i) => i.id == 'item5'), true);
      });

      test('should search and exclude specific day', () {
        // Arrange
        const query = 'Paris';
        const excludeDay = 4;

        // Act
        final searchResults = searchUseCase(items: testItems, query: query);
        final filteredResults = searchResults
            .where((item) => item.dayNumber != excludeDay)
            .toList();

        // Assert
        expect(searchResults.length, 8); // All Paris activities (items 1-6, 9-10)
        expect(filteredResults.length, 6); // Excluding day 4 items (9, 10)
        expect(filteredResults.every((i) => i.dayNumber != excludeDay), true);
      });
    });

    group('Real-world User Scenarios', () {
      test('User wants to find all Versailles activities', () {
        // Arrange
        const query = 'Versailles';

        // Act
        final result = searchUseCase(items: testItems, query: query);

        // Assert
        expect(result.length, 2);
        expect(result.every((i) => i.dayNumber == 3), true);
        expect(result.any((i) => i.title.contains('Palace')), true);
        expect(result.any((i) => i.title.contains('Gardens')), true);
      });

      test('User searches for activities near Eiffel Tower', () {
        // Arrange
        const query = 'Eiffel';

        // Act
        final result = searchUseCase(items: testItems, query: query);

        // Assert
        expect(result.length, 2);
        expect(result.every((i) => i.dayNumber == 1), true);
        // Should find both the visit and dinner
        expect(result.any((i) => i.title == 'Visit Eiffel Tower'), true);
        expect(result.any((i) => i.title == 'Dinner at Le Jules Verne'), true);
      });

      test('User wants to find all shopping activities', () {
        // Arrange
        const query = 'Shopping';

        // Act
        final result = searchUseCase(items: testItems, query: query);

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item9');
        expect(result[0].dayNumber, 4);
      });

      test('User searches for art-related activities', () {
        // Arrange
        const query = 'art';

        // Act
        final result = searchUseCase(items: testItems, query: query);

        // Assert
        expect(result.length, 1); // Louvre description mentions "art museum"
        expect(result[0].id, 'item4');
      });

      test('User wants activities on a specific street (Rue de Rivoli)', () {
        // Arrange
        const query = 'Rue de Rivoli';

        // Act
        final result = searchUseCase(items: testItems, query: query);

        // Assert
        expect(result.length, 2); // Louvre and Café Marly
        expect(result.every((i) => i.dayNumber == 2), true);
      });
    });

    group('Empty and Edge Cases', () {
      test('should handle search with no results', () {
        // Arrange
        const query = 'Beach'; // No beach activities in Paris trip

        // Act
        final result = searchUseCase(items: testItems, query: query);

        // Assert
        expect(result, []);
      });

      test('should handle empty itinerary', () {
        // Arrange
        const query = 'Museum';

        // Act
        final result = searchUseCase(items: [], query: query);

        // Assert
        expect(result, []);
      });

      test('should return all items for empty query', () {
        // Act
        final result = searchUseCase(items: testItems, query: '');

        // Assert
        expect(result.length, testItems.length);
        expect(result, testItems);
      });
    });

    group('Performance Tests', () {
      test('should handle large itinerary efficiently', () {
        // Arrange - Create large dataset
        final largeItinerary = List.generate(
          500,
          (index) => ItineraryItemModel(
            id: 'item$index',
            tripId: 'trip1',
            title: 'Activity ${index % 10 == 0 ? "Museum" : "Tour"} $index',
            description: 'Description $index',
            location: index % 10 == 0 ? 'Paris, France' : 'Other Location',
            startTime: DateTime(2024, 7, 1).add(Duration(hours: index)),
            endTime: DateTime(2024, 7, 1).add(Duration(hours: index + 2)),
            dayNumber: (index ~/ 10) + 1,
            orderIndex: index,
          ),
        );

        const query = 'Museum';

        // Act
        final stopwatch = Stopwatch()..start();
        final result = searchUseCase(items: largeItinerary, query: query);
        stopwatch.stop();

        // Assert
        expect(result.length, greaterThan(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
