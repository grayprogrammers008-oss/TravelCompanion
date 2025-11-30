import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/get_dashboard_stats_usecase.dart';

import 'get_dashboard_stats_usecase_test.mocks.dart';

@GenerateMocks([AdminRepository])
void main() {
  late GetDashboardStatsUseCase useCase;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    useCase = GetDashboardStatsUseCase(mockRepository);
  });

  final testStats = const AdminDashboardStats(
    totalUsers: 1000,
    activeUsers: 850,
    suspendedUsers: 50,
    adminsCount: 5,
    newUsersToday: 10,
    newUsersWeek: 75,
    newUsersMonth: 300,
    totalTrips: 500,
    totalMessages: 10000,
    activeUsersToday: 200,
  );

  group('GetDashboardStatsUseCase', () {
    group('Positive Cases', () {
      test('should return dashboard stats successfully', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalUsers, 1000);
        expect(result.activeUsers, 850);
        expect(result.suspendedUsers, 50);
        expect(result.adminsCount, 5);
        verify(mockRepository.getDashboardStats()).called(1);
      });

      test('should return stats with all fields populated', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalUsers, 1000);
        expect(result.activeUsers, 850);
        expect(result.suspendedUsers, 50);
        expect(result.adminsCount, 5);
        expect(result.newUsersToday, 10);
        expect(result.newUsersWeek, 75);
        expect(result.newUsersMonth, 300);
        expect(result.totalTrips, 500);
        expect(result.totalMessages, 10000);
        expect(result.activeUsersToday, 200);
      });

      test('should calculate active user percentage correctly', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        // 850 / 1000 * 100 = 85%
        expect(result.activeUserPercentage, 85.0);
      });

      test('should calculate suspended user percentage correctly', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        // 50 / 1000 * 100 = 5%
        expect(result.suspendedUserPercentage, 5.0);
      });

      test('should calculate average trips per user correctly', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        // 500 / 1000 = 0.5
        expect(result.averageTripsPerUser, 0.5);
      });

      test('should calculate average messages per user correctly', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        // 10000 / 1000 = 10
        expect(result.averageMessagesPerUser, 10.0);
      });

      test('should calculate daily active percentage correctly', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        final result = await useCase();

        // Assert
        // 200 / 1000 * 100 = 20%
        expect(result.dailyActivePercentage, 20.0);
      });

      test('should handle stats with zero users', () async {
        // Arrange
        final emptyStats = const AdminDashboardStats(
          totalUsers: 0,
          activeUsers: 0,
          suspendedUsers: 0,
          adminsCount: 0,
          newUsersToday: 0,
          newUsersWeek: 0,
          newUsersMonth: 0,
          totalTrips: 0,
          totalMessages: 0,
          activeUsersToday: 0,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => emptyStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalUsers, 0);
        expect(result.activeUserPercentage, 0);
        expect(result.suspendedUserPercentage, 0);
        expect(result.averageTripsPerUser, 0);
        expect(result.averageMessagesPerUser, 0);
        expect(result.dailyActivePercentage, 0);
      });

      test('should handle stats with large numbers', () async {
        // Arrange
        final largeStats = const AdminDashboardStats(
          totalUsers: 1000000,
          activeUsers: 950000,
          suspendedUsers: 10000,
          adminsCount: 100,
          newUsersToday: 1000,
          newUsersWeek: 7000,
          newUsersMonth: 30000,
          totalTrips: 500000,
          totalMessages: 100000000,
          activeUsersToday: 50000,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => largeStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.totalUsers, 1000000);
        expect(result.activeUserPercentage, 95.0);
        expect(result.averageMessagesPerUser, 100.0);
      });

      test('should handle stats with all suspended users', () async {
        // Arrange
        final allSuspendedStats = const AdminDashboardStats(
          totalUsers: 100,
          activeUsers: 0,
          suspendedUsers: 100,
          adminsCount: 0,
          newUsersToday: 0,
          newUsersWeek: 0,
          newUsersMonth: 0,
          totalTrips: 0,
          totalMessages: 0,
          activeUsersToday: 0,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => allSuspendedStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.suspendedUserPercentage, 100.0);
        expect(result.activeUserPercentage, 0.0);
      });

      test('should handle stats with only admins', () async {
        // Arrange
        final onlyAdminsStats = const AdminDashboardStats(
          totalUsers: 10,
          activeUsers: 10,
          suspendedUsers: 0,
          adminsCount: 10,
          newUsersToday: 0,
          newUsersWeek: 0,
          newUsersMonth: 0,
          totalTrips: 50,
          totalMessages: 500,
          activeUsersToday: 10,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => onlyAdminsStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.adminsCount, 10);
        expect(result.totalUsers, 10);
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate repository exception', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should handle network error', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenThrow(Exception('Network unavailable'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network unavailable'),
          )),
        );
      });

      test('should handle permission denied error', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenThrow(Exception('Permission denied: Admin access required'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          )),
        );
      });

      test('should handle timeout error', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenThrow(Exception('Request timeout'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('timeout'),
          )),
        );
      });

      test('should handle authentication error', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenThrow(Exception('User not authenticated'));

        // Act & Assert
        expect(
          () => useCase(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle weekly growth rate calculation with zero month users', () async {
        // Arrange
        final noMonthlyUsersStats = const AdminDashboardStats(
          totalUsers: 100,
          activeUsers: 80,
          suspendedUsers: 5,
          adminsCount: 2,
          newUsersToday: 5,
          newUsersWeek: 10,
          newUsersMonth: 0,
          totalTrips: 50,
          totalMessages: 500,
          activeUsersToday: 20,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => noMonthlyUsersStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.weeklyGrowthRate, 0);
      });

      test('should handle fractional percentages', () async {
        // Arrange
        final fractionalStats = const AdminDashboardStats(
          totalUsers: 3,
          activeUsers: 1,
          suspendedUsers: 1,
          adminsCount: 1,
          newUsersToday: 0,
          newUsersWeek: 1,
          newUsersMonth: 2,
          totalTrips: 2,
          totalMessages: 7,
          activeUsersToday: 1,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => fractionalStats);

        // Act
        final result = await useCase();

        // Assert
        // 1 / 3 * 100 = 33.333...
        expect(result.activeUserPercentage, closeTo(33.33, 0.01));
        // 7 / 3 = 2.333...
        expect(result.averageMessagesPerUser, closeTo(2.33, 0.01));
      });

      test('should be callable multiple times', () async {
        // Arrange
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => testStats);

        // Act
        await useCase();
        await useCase();
        await useCase();

        // Assert
        verify(mockRepository.getDashboardStats()).called(3);
      });

      test('should return fresh stats on each call', () async {
        // Arrange
        final firstStats = const AdminDashboardStats(
          totalUsers: 100,
          activeUsers: 80,
          suspendedUsers: 5,
          adminsCount: 2,
          newUsersToday: 5,
          newUsersWeek: 10,
          newUsersMonth: 40,
          totalTrips: 50,
          totalMessages: 500,
          activeUsersToday: 20,
        );
        final secondStats = const AdminDashboardStats(
          totalUsers: 105,
          activeUsers: 85,
          suspendedUsers: 5,
          adminsCount: 2,
          newUsersToday: 8,
          newUsersWeek: 15,
          newUsersMonth: 45,
          totalTrips: 55,
          totalMessages: 550,
          activeUsersToday: 25,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => firstStats);

        // First call
        final result1 = await useCase();
        expect(result1.totalUsers, 100);

        // Update mock for second call
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => secondStats);

        // Second call
        final result2 = await useCase();
        expect(result2.totalUsers, 105);
      });

      test('should handle single user stats', () async {
        // Arrange
        final singleUserStats = const AdminDashboardStats(
          totalUsers: 1,
          activeUsers: 1,
          suspendedUsers: 0,
          adminsCount: 1,
          newUsersToday: 1,
          newUsersWeek: 1,
          newUsersMonth: 1,
          totalTrips: 1,
          totalMessages: 5,
          activeUsersToday: 1,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => singleUserStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.activeUserPercentage, 100.0);
        expect(result.dailyActivePercentage, 100.0);
        expect(result.averageTripsPerUser, 1.0);
        expect(result.averageMessagesPerUser, 5.0);
      });
    });

    group('Computed Properties', () {
      test('should calculate weekly growth rate correctly', () async {
        // Arrange
        // Weekly: 70/7 = 10 per day
        // Monthly: 200/30 = 6.67 per day
        // Growth = ((10 - 6.67) / 6.67) * 100 = ~50%
        final growthStats = const AdminDashboardStats(
          totalUsers: 1000,
          activeUsers: 800,
          suspendedUsers: 50,
          adminsCount: 5,
          newUsersToday: 10,
          newUsersWeek: 70,
          newUsersMonth: 200,
          totalTrips: 500,
          totalMessages: 5000,
          activeUsersToday: 100,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => growthStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.weeklyGrowthRate, closeTo(50.0, 1.0));
      });

      test('should handle negative weekly growth rate', () async {
        // Arrange
        // Weekly: 30/7 = 4.29 per day
        // Monthly: 200/30 = 6.67 per day
        // Growth = ((4.29 - 6.67) / 6.67) * 100 = ~-35.7%
        final negativeGrowthStats = const AdminDashboardStats(
          totalUsers: 1000,
          activeUsers: 800,
          suspendedUsers: 50,
          adminsCount: 5,
          newUsersToday: 2,
          newUsersWeek: 30,
          newUsersMonth: 200,
          totalTrips: 500,
          totalMessages: 5000,
          activeUsersToday: 100,
        );
        when(mockRepository.getDashboardStats())
            .thenAnswer((_) async => negativeGrowthStats);

        // Act
        final result = await useCase();

        // Assert
        expect(result.weeklyGrowthRate, lessThan(0));
      });
    });
  });
}
