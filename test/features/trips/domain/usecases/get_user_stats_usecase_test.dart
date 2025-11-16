import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';

import 'get_user_stats_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late GetUserStatsUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = GetUserStatsUseCase(mockRepository);
  });

  group('GetUserStatsUseCase', () {
    final testStats = UserTravelStats(
      totalTrips: 5,
      totalExpenses: 25,
      totalSpent: 15000.0,
      uniqueCrewMembers: 8,
    );

    group('call() - Get user stats', () {
      test('should return user stats from repository', () async {
        // Arrange
        when(mockRepository.getUserStats()).thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result, testStats);
        expect(result.totalTrips, 5);
        expect(result.totalExpenses, 25);
        expect(result.totalSpent, 15000.0);
        expect(result.uniqueCrewMembers, 8);
        verify(mockRepository.getUserStats()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should return empty stats when user has no data', () async {
        // Arrange
        final emptyStats = UserTravelStats.empty();
        when(mockRepository.getUserStats()).thenAnswer((_) async => emptyStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result, emptyStats);
        expect(result.totalTrips, 0);
        expect(result.totalExpenses, 0);
        expect(result.totalSpent, 0.0);
        expect(result.uniqueCrewMembers, 0);
        verify(mockRepository.getUserStats()).called(1);
      });

      test('should return empty stats when repository fails', () async {
        // Arrange
        when(mockRepository.getUserStats())
            .thenThrow(Exception('Failed to fetch stats'));

        // Act
        final result = await useCase();

        // Assert
        expect(result, UserTravelStats.empty());
        expect(result.totalTrips, 0);
        expect(result.totalExpenses, 0);
        expect(result.totalSpent, 0.0);
        expect(result.uniqueCrewMembers, 0);
        verify(mockRepository.getUserStats()).called(1);
      });

      test('should handle stats with only trips', () async {
        // Arrange
        final statsWithOnlyTrips = const UserTravelStats(
          totalTrips: 3,
          totalExpenses: 0,
          totalSpent: 0.0,
          uniqueCrewMembers: 0,
        );
        when(mockRepository.getUserStats())
            .thenAnswer((_) async => statsWithOnlyTrips);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalTrips, 3);
        expect(result.totalExpenses, 0);
        expect(result.totalSpent, 0.0);
        expect(result.uniqueCrewMembers, 0);
        verify(mockRepository.getUserStats()).called(1);
      });

      test('should handle stats with large numbers', () async {
        // Arrange
        final largeStats = const UserTravelStats(
          totalTrips: 100,
          totalExpenses: 500,
          totalSpent: 1000000.50,
          uniqueCrewMembers: 50,
        );
        when(mockRepository.getUserStats()).thenAnswer((_) async => largeStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalTrips, 100);
        expect(result.totalExpenses, 500);
        expect(result.totalSpent, 1000000.50);
        expect(result.uniqueCrewMembers, 50);
        verify(mockRepository.getUserStats()).called(1);
      });

      test('should handle decimal amounts correctly', () async {
        // Arrange
        final decimalStats = const UserTravelStats(
          totalTrips: 2,
          totalExpenses: 5,
          totalSpent: 1234.56,
          uniqueCrewMembers: 3,
        );
        when(mockRepository.getUserStats())
            .thenAnswer((_) async => decimalStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalSpent, 1234.56);
        verify(mockRepository.getUserStats()).called(1);
      });
    });

    group('watch() - Watch user stats stream', () {
      test('should return stream of user stats from repository', () async {
        // Arrange
        final statsStream = Stream.value(testStats);
        when(mockRepository.watchUserStats()).thenAnswer((_) => statsStream);

        // Act
        final result = useCase.watch();

        // Assert
        expect(result, isA<Stream<UserTravelStats>>());

        final emitted = await result.first;
        expect(emitted, testStats);
        expect(emitted.totalTrips, 5);
        expect(emitted.totalExpenses, 25);
        expect(emitted.totalSpent, 15000.0);
        expect(emitted.uniqueCrewMembers, 8);
        verify(mockRepository.watchUserStats()).called(1);
      });

      test('should return stream with multiple stat updates', () async {
        // Arrange
        final stats1 = const UserTravelStats(
          totalTrips: 1,
          totalExpenses: 5,
          totalSpent: 1000.0,
          uniqueCrewMembers: 2,
        );
        final stats2 = const UserTravelStats(
          totalTrips: 2,
          totalExpenses: 10,
          totalSpent: 2500.0,
          uniqueCrewMembers: 3,
        );
        final stats3 = const UserTravelStats(
          totalTrips: 3,
          totalExpenses: 15,
          totalSpent: 4000.0,
          uniqueCrewMembers: 5,
        );

        final statsStream = Stream.fromIterable([stats1, stats2, stats3]);
        when(mockRepository.watchUserStats()).thenAnswer((_) => statsStream);

        // Act
        final result = useCase.watch();

        // Assert
        final emittedList = await result.toList();
        expect(emittedList.length, 3);
        expect(emittedList[0].totalTrips, 1);
        expect(emittedList[1].totalTrips, 2);
        expect(emittedList[2].totalTrips, 3);
        expect(emittedList[0].totalExpenses, 5);
        expect(emittedList[1].totalExpenses, 10);
        expect(emittedList[2].totalExpenses, 15);
        verify(mockRepository.watchUserStats()).called(1);
      });

      test('should handle empty stream', () async {
        // Arrange
        final emptyStream = const Stream<UserTravelStats>.empty();
        when(mockRepository.watchUserStats()).thenAnswer((_) => emptyStream);

        // Act
        final result = useCase.watch();

        // Assert
        final emittedList = await result.toList();
        expect(emittedList, isEmpty);
        verify(mockRepository.watchUserStats()).called(1);
      });

      test('should propagate stream errors', () async {
        // Arrange
        final errorStream = Stream<UserTravelStats>.error(
          Exception('Failed to watch stats'),
        );
        when(mockRepository.watchUserStats()).thenAnswer((_) => errorStream);

        // Act
        final result = useCase.watch();

        // Assert
        expect(
          result.first,
          throwsA(isA<Exception>()),
        );
        verify(mockRepository.watchUserStats()).called(1);
      });

      test('should emit stats when values change in real-time', () async {
        // Arrange
        final initialStats = UserTravelStats.empty();
        final updatedStats = const UserTravelStats(
          totalTrips: 1,
          totalExpenses: 3,
          totalSpent: 500.0,
          uniqueCrewMembers: 2,
        );

        final statsStream = Stream.fromIterable([initialStats, updatedStats]);
        when(mockRepository.watchUserStats()).thenAnswer((_) => statsStream);

        // Act
        final result = useCase.watch();

        // Assert
        final emittedList = await result.toList();
        expect(emittedList.length, 2);
        expect(emittedList[0], initialStats);
        expect(emittedList[1], updatedStats);
        expect(emittedList[1].totalTrips, 1);
        verify(mockRepository.watchUserStats()).called(1);
      });
    });

    group('UserTravelStats', () {
      test('should create stats with all fields', () {
        // Act
        final stats = const UserTravelStats(
          totalTrips: 10,
          totalExpenses: 50,
          totalSpent: 25000.0,
          uniqueCrewMembers: 15,
        );

        // Assert
        expect(stats.totalTrips, 10);
        expect(stats.totalExpenses, 50);
        expect(stats.totalSpent, 25000.0);
        expect(stats.uniqueCrewMembers, 15);
      });

      test('should create empty stats with factory', () {
        // Act
        final stats = UserTravelStats.empty();

        // Assert
        expect(stats.totalTrips, 0);
        expect(stats.totalExpenses, 0);
        expect(stats.totalSpent, 0.0);
        expect(stats.uniqueCrewMembers, 0);
      });

      test('should compare stats correctly with equality operator', () {
        // Arrange
        const stats1 = UserTravelStats(
          totalTrips: 5,
          totalExpenses: 20,
          totalSpent: 10000.0,
          uniqueCrewMembers: 8,
        );
        const stats2 = UserTravelStats(
          totalTrips: 5,
          totalExpenses: 20,
          totalSpent: 10000.0,
          uniqueCrewMembers: 8,
        );
        const stats3 = UserTravelStats(
          totalTrips: 3,
          totalExpenses: 15,
          totalSpent: 5000.0,
          uniqueCrewMembers: 5,
        );

        // Assert
        expect(stats1, equals(stats2));
        expect(stats1, isNot(equals(stats3)));
      });

      test('should have consistent hashCode for equal objects', () {
        // Arrange
        const stats1 = UserTravelStats(
          totalTrips: 5,
          totalExpenses: 20,
          totalSpent: 10000.0,
          uniqueCrewMembers: 8,
        );
        const stats2 = UserTravelStats(
          totalTrips: 5,
          totalExpenses: 20,
          totalSpent: 10000.0,
          uniqueCrewMembers: 8,
        );

        // Assert
        expect(stats1.hashCode, equals(stats2.hashCode));
      });
    });
  });
}
