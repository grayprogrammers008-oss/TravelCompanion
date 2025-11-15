import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/search_itinerary_usecase.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

void main() {
  group('SearchItineraryUseCase', () {
    late SearchItineraryUseCase useCase;
    late List<ItineraryItemModel> testItems;

    setUp(() {
      useCase = SearchItineraryUseCase();

      // Create test data with various scenarios
      testItems = [
        ItineraryItemModel(
          id: 'item1',
          tripId: 'trip1',
          title: 'Visit Eiffel Tower',
          description: 'Iconic landmark in Paris',
          location: 'Champ de Mars, Paris, France',
          startTime: DateTime(2024, 7, 1, 10, 0),
          endTime: DateTime(2024, 7, 1, 12, 0),
          dayNumber: 1,
          orderIndex: 0,
          createdBy: 'user1',
          createdAt: DateTime(2024, 6, 1),
        ),
        ItineraryItemModel(
          id: 'item2',
          tripId: 'trip1',
          title: 'Louvre Museum Tour',
          description: 'Explore the world-famous art museum',
          location: 'Rue de Rivoli, Paris, France',
          startTime: DateTime(2024, 7, 1, 14, 0),
          endTime: DateTime(2024, 7, 1, 17, 0),
          dayNumber: 1,
          orderIndex: 1,
          createdBy: 'user1',
          createdAt: DateTime(2024, 6, 1),
        ),
        ItineraryItemModel(
          id: 'item3',
          tripId: 'trip1',
          title: 'Seine River Cruise',
          description: 'Romantic evening cruise',
          location: 'Port de la Bourdonnais, Paris',
          startTime: DateTime(2024, 7, 1, 19, 0),
          endTime: DateTime(2024, 7, 1, 21, 0),
          dayNumber: 1,
          orderIndex: 2,
          createdBy: 'user1',
          createdAt: DateTime(2024, 6, 1),
        ),
        ItineraryItemModel(
          id: 'item4',
          tripId: 'trip1',
          title: 'Shopping at Champs-Élysées',
          description: null, // No description
          location: 'Avenue des Champs-Élysées, Paris',
          startTime: DateTime(2024, 7, 2, 10, 0),
          endTime: DateTime(2024, 7, 2, 12, 0),
          dayNumber: 2,
          orderIndex: 0,
          createdBy: 'user1',
          createdAt: DateTime(2024, 6, 1),
        ),
        ItineraryItemModel(
          id: 'item5',
          tripId: 'trip1',
          title: 'Versailles Palace',
          description: 'Day trip to the Palace of Versailles',
          location: 'Place d\'Armes, Versailles, France',
          startTime: DateTime(2024, 7, 2, 9, 0),
          endTime: DateTime(2024, 7, 2, 16, 0),
          dayNumber: 2,
          orderIndex: 1,
          createdBy: 'user1',
          createdAt: DateTime(2024, 6, 1),
        ),
      ];
    });

    group('Search by title', () {
      test('should find item by exact title match', () {
        // Act
        final result = useCase(items: testItems, query: 'Visit Eiffel Tower');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item1');
        expect(result[0].title, 'Visit Eiffel Tower');
      });

      test('should find item by partial title match', () {
        // Act
        final result = useCase(items: testItems, query: 'Eiffel');

        // Assert
        expect(result.length, 1);
        expect(result[0].title, 'Visit Eiffel Tower');
      });

      test('should be case-insensitive when searching by title', () {
        // Act
        final result = useCase(items: testItems, query: 'LOUVRE');

        // Assert
        expect(result.length, 1);
        expect(result[0].title, 'Louvre Museum Tour');
      });

      test('should find multiple items with similar titles', () {
        // Act
        final result = useCase(items: testItems, query: 'Palace');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item5');
      });
    });

    group('Search by description', () {
      test('should find item by description match', () {
        // Act
        final result = useCase(items: testItems, query: 'Romantic');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item3');
        expect(result[0].description, 'Romantic evening cruise');
      });

      test('should find item by partial description match', () {
        // Act
        final result = useCase(items: testItems, query: 'art museum');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item2');
      });

      test('should be case-insensitive when searching by description', () {
        // Act
        final result = useCase(items: testItems, query: 'ICONIC LANDMARK');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item1');
      });

      test('should handle items with null description gracefully', () {
        // Act
        final result = useCase(items: testItems, query: 'Shopping');

        // Assert - Should find by title, not crash on null description
        expect(result.length, 1);
        expect(result[0].id, 'item4');
      });
    });

    group('Search by location', () {
      test('should find item by location match', () {
        // Act
        final result = useCase(items: testItems, query: 'Versailles');

        // Assert
        expect(result.length, 1);
        expect(result[0].location, 'Place d\'Armes, Versailles, France');
      });

      test('should find items by city in location', () {
        // Act
        final result = useCase(items: testItems, query: 'Paris');

        // Assert
        expect(result.length, 4); // All items with Paris in location
        expect(result.any((i) => i.id == 'item1'), true);
        expect(result.any((i) => i.id == 'item2'), true);
        expect(result.any((i) => i.id == 'item3'), true);
        expect(result.any((i) => i.id == 'item4'), true);
      });

      test('should be case-insensitive when searching by location', () {
        // Act
        final result = useCase(items: testItems, query: 'champ de mars');

        // Assert
        expect(result.length, 1);
        expect(result[0].location, 'Champ de Mars, Paris, France');
      });

      test('should find item by country in location', () {
        // Act
        final result = useCase(items: testItems, query: 'France');

        // Assert
        expect(result.length, 3); // Items with France in location
      });
    });

    group('Search across multiple fields', () {
      test('should find item when query matches title or description', () {
        // Act - "cruise" is in both title and description
        final result = useCase(items: testItems, query: 'cruise');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item3');
      });

      test('should find item when query matches title or location', () {
        // Act - "Tower" is in title, "Eiffel" is in both
        final result = useCase(items: testItems, query: 'Tower');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item1');
      });

      test('should find items when query matches any field', () {
        // Act - "Rivoli" only in location
        final result = useCase(items: testItems, query: 'Rivoli');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item2');
      });
    });

    group('Edge cases', () {
      test('should return all items when query is null', () {
        // Act
        final result = useCase(items: testItems, query: null);

        // Assert
        expect(result.length, testItems.length);
        expect(result, testItems);
      });

      test('should return all items when query is empty string', () {
        // Act
        final result = useCase(items: testItems, query: '');

        // Assert
        expect(result.length, testItems.length);
        expect(result, testItems);
      });

      test('should return all items when query is whitespace only', () {
        // Act
        final result = useCase(items: testItems, query: '   ');

        // Assert
        expect(result.length, testItems.length);
        expect(result, testItems);
      });

      test('should return empty list when no items match', () {
        // Act
        final result = useCase(items: testItems, query: 'Tokyo');

        // Assert
        expect(result.length, 0);
        expect(result, []);
      });

      test('should return empty list when searching in empty item list', () {
        // Act
        final result = useCase(items: [], query: 'Eiffel');

        // Assert
        expect(result.length, 0);
        expect(result, []);
      });

      test('should trim whitespace from query', () {
        // Act
        final result = useCase(items: testItems, query: '  Seine  ');

        // Assert
        expect(result.length, 1);
        expect(result[0].title, 'Seine River Cruise');
      });

      test('should handle special characters in query', () {
        // Add item with special characters
        final specialItem = ItineraryItemModel(
          id: 'item6',
          tripId: 'trip1',
          title: 'Café de Flore',
          description: 'Historic café in Saint-Germain-des-Prés',
          location: 'Boulevard Saint-Germain, Paris',
          startTime: DateTime(2024, 7, 3, 9, 0),
          endTime: DateTime(2024, 7, 3, 11, 0),
          dayNumber: 3,
          orderIndex: 0,
          createdBy: 'user1',
          createdAt: DateTime(2024, 6, 1),
        );

        final itemsWithSpecial = [...testItems, specialItem];

        // Act
        final result = useCase(items: itemsWithSpecial, query: 'Café');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item6');
      });

      test('should handle accented characters correctly', () {
        // Act - Test with Champs-Élysées
        final result = useCase(items: testItems, query: 'Élysées');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item4');
      });
    });

    group('Performance and efficiency', () {
      test('should handle large number of items efficiently', () {
        // Arrange
        final largeList = List.generate(
          1000,
          (index) => ItineraryItemModel(
            id: 'item$index',
            tripId: 'trip1',
            title: 'Activity $index',
            description: 'Description $index',
            location: 'Location $index',
            startTime: DateTime(2024, 1, 1, 10, 0),
            endTime: DateTime(2024, 1, 1, 12, 0),
            dayNumber: 1,
            orderIndex: index,
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
          ),
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final result = useCase(items: largeList, query: 'Activity 500');
        stopwatch.stop();

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item500');
        // Search should complete in reasonable time (< 100ms for 1000 items)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should not modify original items list', () {
        // Arrange
        final originalLength = testItems.length;
        final firstItemId = testItems[0].id;

        // Act
        useCase(items: testItems, query: 'Eiffel');

        // Assert
        expect(testItems.length, originalLength);
        expect(testItems[0].id, firstItemId);
      });
    });

    group('Real-world scenarios', () {
      test('should find museum activities', () {
        // Act
        final result = useCase(items: testItems, query: 'Museum');

        // Assert
        expect(result.length, 1);
        expect(result[0].title, 'Louvre Museum Tour');
      });

      test('should find activities by day location (Paris)', () {
        // Act
        final result = useCase(items: testItems, query: 'Paris');

        // Assert
        expect(result.length, 4);
        // Verify all are Paris activities
        for (var item in result) {
          expect(
            item.location?.toLowerCase().contains('paris') ?? false,
            true,
          );
        }
      });

      test('should search for specific landmark', () {
        // Act
        final result = useCase(items: testItems, query: 'Eiffel Tower');

        // Assert
        expect(result.length, 1);
        expect(result[0].title, 'Visit Eiffel Tower');
        expect(result[0].location, 'Champ de Mars, Paris, France');
      });

      test('should find activities by type (shopping)', () {
        // Act
        final result = useCase(items: testItems, query: 'Shopping');

        // Assert
        expect(result.length, 1);
        expect(result[0].title, 'Shopping at Champs-Élysées');
      });

      test('should search for day trips', () {
        // Act
        final result = useCase(items: testItems, query: 'Day trip');

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'item5');
        expect(result[0].description, 'Day trip to the Palace of Versailles');
      });
    });
  });
}
