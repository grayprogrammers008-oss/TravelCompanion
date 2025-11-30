import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/itinerary/data/datasources/itinerary_remote_datasource.dart';
import 'package:travel_crew/features/itinerary/data/repositories/itinerary_repository_impl.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

import 'itinerary_repository_impl_test.mocks.dart';

@GenerateMocks([ItineraryRemoteDataSource])
void main() {
  late ItineraryRepositoryImpl repository;
  late MockItineraryRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockItineraryRemoteDataSource();
    repository = ItineraryRepositoryImpl(mockRemoteDataSource);
  });

  final now = DateTime.now();

  ItineraryItemModel createItineraryItem({
    required String id,
    required String tripId,
    required String title,
    int? dayNumber,
    int orderIndex = 0,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ItineraryItemModel(
      id: id,
      tripId: tripId,
      title: title,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      createdBy: 'user-123',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ItineraryRepositoryImpl', () {
    group('createItineraryItem', () {
      test('should create item successfully', () async {
        // Arrange
        final createdItem = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          dayNumber: 1,
        );
        when(mockRemoteDataSource.createItem(
          tripId: anyNamed('tripId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => createdItem);

        // Act
        final result = await repository.createItineraryItem(
          tripId: 'trip-1',
          title: 'Visit Museum',
          dayNumber: 1,
        );

        // Assert
        expect(result.title, 'Visit Museum');
        expect(result.tripId, 'trip-1');
        verify(mockRemoteDataSource.createItem(
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: null,
          location: null,
          startTime: null,
          endTime: null,
          dayNumber: 1,
          orderIndex: 0,
        )).called(1);
      });

      test('should create item with all fields', () async {
        // Arrange
        final startTime = DateTime(2024, 6, 15, 9, 0);
        final endTime = DateTime(2024, 6, 15, 12, 0);
        final createdItem = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'Art museum tour',
          location: '123 Art Street',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 2,
        );
        when(mockRemoteDataSource.createItem(
          tripId: anyNamed('tripId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => createdItem);

        // Act
        final result = await repository.createItineraryItem(
          tripId: 'trip-1',
          title: 'Visit Museum',
          description: 'Art museum tour',
          location: '123 Art Street',
          startTime: startTime,
          endTime: endTime,
          dayNumber: 1,
          orderIndex: 2,
        );

        // Assert
        expect(result.description, 'Art museum tour');
        expect(result.location, '123 Art Street');
        expect(result.orderIndex, 2);
      });
    });

    group('getTripItinerary', () {
      test('should return all items for trip', () async {
        // Arrange
        final items = [
          createItineraryItem(id: '1', tripId: 'trip-1', title: 'Day 1 Activity', dayNumber: 1),
          createItineraryItem(id: '2', tripId: 'trip-1', title: 'Day 2 Activity', dayNumber: 2),
        ];
        when(mockRemoteDataSource.getTripItinerary(any))
            .thenAnswer((_) async => items);

        // Act
        final result = await repository.getTripItinerary('trip-1');

        // Assert
        expect(result.length, 2);
        verify(mockRemoteDataSource.getTripItinerary('trip-1')).called(1);
      });

      test('should return empty list when no items', () async {
        // Arrange
        when(mockRemoteDataSource.getTripItinerary(any))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getTripItinerary('trip-1');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getDayItinerary', () {
      test('should return items for specific day', () async {
        // Arrange
        final items = [
          createItineraryItem(id: '1', tripId: 'trip-1', title: 'Morning Activity', dayNumber: 1, orderIndex: 0),
          createItineraryItem(id: '2', tripId: 'trip-1', title: 'Afternoon Activity', dayNumber: 1, orderIndex: 1),
        ];
        when(mockRemoteDataSource.getDayItinerary(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
        )).thenAnswer((_) async => items);

        // Act
        final result = await repository.getDayItinerary(
          tripId: 'trip-1',
          dayNumber: 1,
        );

        // Assert
        expect(result.length, 2);
        expect(result.every((item) => item.dayNumber == 1), true);
        verify(mockRemoteDataSource.getDayItinerary(
          tripId: 'trip-1',
          dayNumber: 1,
        )).called(1);
      });
    });

    group('getItineraryByDays', () {
      test('should return items grouped by days', () async {
        // Arrange
        final days = [
          ItineraryDay(dayNumber: 1, items: [
            createItineraryItem(id: '1', tripId: 'trip-1', title: 'Day 1 Activity', dayNumber: 1),
          ]),
          ItineraryDay(dayNumber: 2, items: [
            createItineraryItem(id: '2', tripId: 'trip-1', title: 'Day 2 Activity', dayNumber: 2),
          ]),
        ];
        when(mockRemoteDataSource.getItineraryByDays(any))
            .thenAnswer((_) async => days);

        // Act
        final result = await repository.getItineraryByDays('trip-1');

        // Assert
        expect(result.length, 2);
        expect(result[0].dayNumber, 1);
        expect(result[1].dayNumber, 2);
        verify(mockRemoteDataSource.getItineraryByDays('trip-1')).called(1);
      });
    });

    group('getItineraryItem', () {
      test('should return single item by id', () async {
        // Arrange
        final item = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Museum',
        );
        when(mockRemoteDataSource.getItem(any))
            .thenAnswer((_) async => item);

        // Act
        final result = await repository.getItineraryItem('item-1');

        // Assert
        expect(result.id, 'item-1');
        expect(result.title, 'Visit Museum');
        verify(mockRemoteDataSource.getItem('item-1')).called(1);
      });
    });

    group('updateItineraryItem', () {
      test('should update item title', () async {
        // Arrange
        final updatedItem = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Updated Title',
        );
        when(mockRemoteDataSource.updateItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await repository.updateItineraryItem(
          itemId: 'item-1',
          title: 'Updated Title',
        );

        // Assert
        expect(result.title, 'Updated Title');
        verify(mockRemoteDataSource.updateItem(
          itemId: 'item-1',
          title: 'Updated Title',
          description: null,
          location: null,
          startTime: null,
          endTime: null,
          dayNumber: null,
          orderIndex: null,
        )).called(1);
      });

      test('should update multiple fields', () async {
        // Arrange
        final newTime = DateTime(2024, 6, 15, 14, 0);
        final updatedItem = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Updated Title',
          location: 'New Location',
          startTime: newTime,
        );
        when(mockRemoteDataSource.updateItem(
          itemId: anyNamed('itemId'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          location: anyNamed('location'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          dayNumber: anyNamed('dayNumber'),
          orderIndex: anyNamed('orderIndex'),
        )).thenAnswer((_) async => updatedItem);

        // Act
        final result = await repository.updateItineraryItem(
          itemId: 'item-1',
          title: 'Updated Title',
          location: 'New Location',
          startTime: newTime,
        );

        // Assert
        expect(result.title, 'Updated Title');
        expect(result.location, 'New Location');
      });
    });

    group('deleteItineraryItem', () {
      test('should delete item successfully', () async {
        // Arrange
        when(mockRemoteDataSource.deleteItem(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteItineraryItem('item-1');

        // Assert
        verify(mockRemoteDataSource.deleteItem('item-1')).called(1);
      });
    });

    group('reorderItems', () {
      test('should reorder items within a day', () async {
        // Arrange
        when(mockRemoteDataSource.reorderItems(
          tripId: anyNamed('tripId'),
          dayNumber: anyNamed('dayNumber'),
          itemIds: anyNamed('itemIds'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.reorderItems(
          tripId: 'trip-1',
          dayNumber: 1,
          itemIds: ['item-2', 'item-1', 'item-3'],
        );

        // Assert
        verify(mockRemoteDataSource.reorderItems(
          tripId: 'trip-1',
          dayNumber: 1,
          itemIds: ['item-2', 'item-1', 'item-3'],
        )).called(1);
      });
    });

    group('moveItemToDay', () {
      test('should move item to different day', () async {
        // Arrange
        when(mockRemoteDataSource.moveItemToDay(
          itemId: anyNamed('itemId'),
          newDayNumber: anyNamed('newDayNumber'),
        )).thenAnswer((_) async => {});

        // Act
        await repository.moveItemToDay(
          itemId: 'item-1',
          newDayNumber: 3,
        );

        // Assert
        verify(mockRemoteDataSource.moveItemToDay(
          itemId: 'item-1',
          newDayNumber: 3,
        )).called(1);
      });
    });

    group('watchTripItinerary', () {
      test('should return stream from datasource', () {
        // Arrange
        final items = [
          createItineraryItem(id: '1', tripId: 'trip-1', title: 'Activity 1'),
        ];
        when(mockRemoteDataSource.watchTripItinerary(any))
            .thenAnswer((_) => Stream.value(items));

        // Act
        final stream = repository.watchTripItinerary('trip-1');

        // Assert
        expect(stream, isA<Stream<List<ItineraryItemModel>>>());
        verify(mockRemoteDataSource.watchTripItinerary('trip-1')).called(1);
      });

      test('should throw exception when watch fails', () {
        // Arrange
        when(mockRemoteDataSource.watchTripItinerary(any))
            .thenThrow(Exception('Stream error'));

        // Act & Assert
        expect(
          () => repository.watchTripItinerary('trip-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to watch trip itinerary'),
          )),
        );
      });
    });

    group('watchItineraryByDays', () {
      test('should return stream of days from datasource', () {
        // Arrange
        final days = [
          ItineraryDay(dayNumber: 1, items: []),
        ];
        when(mockRemoteDataSource.watchItineraryByDays(any))
            .thenAnswer((_) => Stream.value(days));

        // Act
        final stream = repository.watchItineraryByDays('trip-1');

        // Assert
        expect(stream, isA<Stream<List<ItineraryDay>>>());
        verify(mockRemoteDataSource.watchItineraryByDays('trip-1')).called(1);
      });

      test('should throw exception when watch by days fails', () {
        // Arrange
        when(mockRemoteDataSource.watchItineraryByDays(any))
            .thenThrow(Exception('Stream error'));

        // Act & Assert
        expect(
          () => repository.watchItineraryByDays('trip-1'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to watch itinerary by days'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle large number of itinerary items', () async {
        // Arrange
        final manyItems = List.generate(
          100,
          (i) => createItineraryItem(
            id: 'item-$i',
            tripId: 'trip-1',
            title: 'Activity $i',
            dayNumber: (i ~/ 10) + 1,
          ),
        );
        when(mockRemoteDataSource.getTripItinerary(any))
            .thenAnswer((_) async => manyItems);

        // Act
        final result = await repository.getTripItinerary('trip-1');

        // Assert
        expect(result.length, 100);
      });

      test('should handle items with no day number', () async {
        // Arrange
        final itemWithoutDay = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Unscheduled Activity',
          dayNumber: null,
        );
        when(mockRemoteDataSource.getTripItinerary(any))
            .thenAnswer((_) async => [itemWithoutDay]);

        // Act
        final result = await repository.getTripItinerary('trip-1');

        // Assert
        expect(result.first.dayNumber, null);
      });

      test('should handle special characters in item title', () async {
        // Arrange
        final item = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Visit Café "Le Petit" – Émojis 🏛️ & Unicode™',
        );
        when(mockRemoteDataSource.getItem(any))
            .thenAnswer((_) async => item);

        // Act
        final result = await repository.getItineraryItem('item-1');

        // Assert
        expect(result.title, 'Visit Café "Le Petit" – Émojis 🏛️ & Unicode™');
      });

      test('should handle very long description', () async {
        // Arrange
        final longDescription = 'A' * 5000;
        final item = createItineraryItem(
          id: 'item-1',
          tripId: 'trip-1',
          title: 'Activity',
          description: longDescription,
        );
        when(mockRemoteDataSource.getItem(any))
            .thenAnswer((_) async => item);

        // Act
        final result = await repository.getItineraryItem('item-1');

        // Assert
        expect(result.description?.length, 5000);
      });

      test('should handle multiple calls to same trip', () async {
        // Arrange
        final items = [
          createItineraryItem(id: '1', tripId: 'trip-1', title: 'Activity 1'),
        ];
        when(mockRemoteDataSource.getTripItinerary(any))
            .thenAnswer((_) async => items);

        // Act
        await repository.getTripItinerary('trip-1');
        await repository.getTripItinerary('trip-1');
        await repository.getTripItinerary('trip-1');

        // Assert
        verify(mockRemoteDataSource.getTripItinerary('trip-1')).called(3);
      });
    });
  });
}
