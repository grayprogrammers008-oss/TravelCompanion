import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_history_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'get_trip_history_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late GetTripHistoryUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = GetTripHistoryUseCase(mockRepository);
  });

  group('GetTripHistoryUseCase - call()', () {
    test('should return only completed trips', () async {
      // Arrange
      final completedTrip1 = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Paris Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.5,
        ),
        members: [],
      );

      final activeTrip = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'London Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: false,
        ),
        members: [],
      );

      final completedTrip2 = TripWithMembers(
        trip: TripModel(
          id: '3',
          name: 'Tokyo Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 3, 1),
          updatedAt: DateTime(2024, 3, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 6, 20),
          rating: 5.0,
        ),
        members: [],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [completedTrip1, activeTrip, completedTrip2]);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.length, 2);
      expect(result.every((t) => t.trip.isCompleted), true);
      verify(mockRepository.getUserTrips()).called(1);
    });

    test('should sort completed trips by completion date descending', () async {
      // Arrange - Create trips with different completion dates
      final tripMarch = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'March Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 3, 15), // Oldest
          rating: 3.0,
        ),
        members: [],
      );

      final tripJune = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'June Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 6, 20), // Newest
          rating: 4.0,
        ),
        members: [],
      );

      final tripMay = TripWithMembers(
        trip: TripModel(
          id: '3',
          name: 'May Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 3, 1),
          updatedAt: DateTime(2024, 3, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 10), // Middle
          rating: 4.5,
        ),
        members: [],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [tripMarch, tripJune, tripMay]);

      // Act
      final result = await useCase.call();

      // Assert - Should be sorted newest first
      expect(result.length, 3);
      expect(result[0].trip.name, 'June Trip'); // Newest
      expect(result[1].trip.name, 'May Trip');   // Middle
      expect(result[2].trip.name, 'March Trip'); // Oldest
    });

    test('should handle trips with null completion dates', () async {
      // Arrange
      final tripWithDate = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Completed Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.0,
        ),
        members: [],
      );

      final tripWithoutDate = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'Completed But No Date',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: true,
          completedAt: null, // Edge case
          rating: 3.5,
        ),
        members: [],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [tripWithDate, tripWithoutDate]);

      // Act
      final result = await useCase.call();

      // Assert - Trips with dates should come first
      expect(result.length, 2);
      expect(result[0].trip.id, '1'); // Has date, so comes first
      expect(result[1].trip.id, '2'); // No date, goes to end
    });

    test('should return empty list when no completed trips exist', () async {
      // Arrange
      final activeTrip1 = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Active Trip 1',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: false,
        ),
        members: [],
      );

      final activeTrip2 = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'Active Trip 2',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: false,
        ),
        members: [],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [activeTrip1, activeTrip2]);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, isEmpty);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.getUserTrips())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => useCase.call(),
        throwsException,
      );
    });
  });

  group('GetTripHistoryUseCase - watchHistory()', () {
    test('should return stream of completed trips only', () async {
      // Arrange
      final completedTrip = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Completed Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.5,
        ),
        members: [],
      );

      final activeTrip = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'Active Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: false,
        ),
        members: [],
      );

      when(mockRepository.watchUserTrips())
          .thenAnswer((_) => Stream.value([completedTrip, activeTrip]));

      // Act
      final stream = useCase.watchHistory();

      // Assert
      await expectLater(
        stream,
        emits(predicate<List<TripWithMembers>>((trips) {
          return trips.length == 1 && trips[0].trip.isCompleted;
        })),
      );
    });

    test('should emit sorted trips newest first', () async {
      // Arrange
      final oldTrip = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Old Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 3, 1),
          rating: 3.0,
        ),
        members: [],
      );

      final newTrip = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'New Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 6, 1),
          rating: 4.5,
        ),
        members: [],
      );

      when(mockRepository.watchUserTrips())
          .thenAnswer((_) => Stream.value([oldTrip, newTrip]));

      // Act
      final stream = useCase.watchHistory();

      // Assert
      await expectLater(
        stream,
        emits(predicate<List<TripWithMembers>>((trips) {
          return trips.length == 2 &&
              trips[0].trip.name == 'New Trip' &&
              trips[1].trip.name == 'Old Trip';
        })),
      );
    });
  });

  group('GetTripHistoryUseCase - getStatistics()', () {
    test('should calculate correct statistics for completed trips', () async {
      // Arrange
      final trip1 = TripWithMembers(
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
      );

      final trip2 = TripWithMembers(
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
      );

      final trip3 = TripWithMembers(
        trip: TripModel(
          id: '3',
          name: 'Trip 3',
          createdBy: 'user1',
          createdAt: DateTime(2024, 3, 1),
          updatedAt: DateTime(2024, 3, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 6, 10),
          rating: 3.0,
        ),
        members: [],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [trip1, trip2, trip3]);

      // Act
      final stats = await useCase.getStatistics();

      // Assert
      expect(stats.totalCompletedTrips, 3);
      expect(stats.totalRatedTrips, 3);
      expect(stats.averageRating, 4.0); // (4.0 + 5.0 + 3.0) / 3 = 4.0
      expect(stats.earliestCompletionDate, DateTime(2024, 3, 15));
      expect(stats.latestCompletionDate, DateTime(2024, 6, 10));
    });

    test('should handle trips without ratings', () async {
      // Arrange
      final ratedTrip = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Rated Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.5,
        ),
        members: [],
      );

      final unratedTrip = TripWithMembers(
        trip: TripModel(
          id: '2',
          name: 'Unrated Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 6, 20),
          rating: 0.0, // Not rated
        ),
        members: [],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [ratedTrip, unratedTrip]);

      // Act
      final stats = await useCase.getStatistics();

      // Assert
      expect(stats.totalCompletedTrips, 2);
      expect(stats.totalRatedTrips, 1); // Only one with rating > 0
      expect(stats.averageRating, 4.5);
      expect(stats.hasAnyTrips, true);
      expect(stats.hasRatedTrips, true);
    });

    test('should return empty statistics when no completed trips', () async {
      // Arrange
      when(mockRepository.getUserTrips()).thenAnswer((_) async => []);

      // Act
      final stats = await useCase.getStatistics();

      // Assert
      expect(stats.totalCompletedTrips, 0);
      expect(stats.totalRatedTrips, 0);
      expect(stats.averageRating, 0.0);
      expect(stats.earliestCompletionDate, null);
      expect(stats.latestCompletionDate, null);
      expect(stats.hasAnyTrips, false);
      expect(stats.hasRatedTrips, false);
    });

    test('should format average rating correctly', () async {
      // Arrange
      final trip = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Trip',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.666666,
        ),
        members: [],
      );

      when(mockRepository.getUserTrips()).thenAnswer((_) async => [trip]);

      // Act
      final stats = await useCase.getStatistics();

      // Assert
      expect(stats.formattedAverageRating, '4.7'); // Should round to 1 decimal
    });
  });

  group('TripHistoryStatistics', () {
    test('empty factory should create correct empty state', () {
      // Act
      final stats = TripHistoryStatistics.empty();

      // Assert
      expect(stats.totalCompletedTrips, 0);
      expect(stats.averageRating, 0.0);
      expect(stats.totalRatedTrips, 0);
      expect(stats.earliestCompletionDate, null);
      expect(stats.latestCompletionDate, null);
      expect(stats.hasAnyTrips, false);
      expect(stats.hasRatedTrips, false);
      expect(stats.formattedAverageRating, '0.0');
    });

    test('hasAnyTrips should return true when trips exist', () {
      // Act
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 1,
        averageRating: 4.0,
        totalRatedTrips: 1,
      );

      // Assert
      expect(stats.hasAnyTrips, true);
    });

    test('hasRatedTrips should return true when rated trips exist', () {
      // Act
      final stats = TripHistoryStatistics(
        totalCompletedTrips: 2,
        averageRating: 4.0,
        totalRatedTrips: 1,
      );

      // Assert
      expect(stats.hasRatedTrips, true);
    });
  });
}
