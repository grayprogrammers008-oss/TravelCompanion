import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_dashboard_stats.dart';

void main() {
  group('AdminDashboardStats', () {
    group('constructor', () {
      test('should create instance with all required fields', () {
        const stats = AdminDashboardStats(
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

        expect(stats.totalUsers, 1000);
        expect(stats.activeUsers, 850);
        expect(stats.suspendedUsers, 50);
        expect(stats.adminsCount, 5);
        expect(stats.newUsersToday, 10);
        expect(stats.newUsersWeek, 75);
        expect(stats.newUsersMonth, 300);
        expect(stats.totalTrips, 500);
        expect(stats.totalMessages, 10000);
        expect(stats.activeUsersToday, 200);
      });
    });

    group('computed properties', () {
      group('weeklyGrowthRate', () {
        test('should calculate positive growth rate', () {
          // Weekly: 70/7 = 10 per day
          // Monthly: 200/30 = 6.67 per day
          // Growth = ((10 - 6.67) / 6.67) * 100 = ~50%
          const stats = AdminDashboardStats(
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

          expect(stats.weeklyGrowthRate, closeTo(50.0, 1.0));
        });

        test('should calculate negative growth rate', () {
          // Weekly: 30/7 = 4.29 per day
          // Monthly: 200/30 = 6.67 per day
          // Growth = ((4.29 - 6.67) / 6.67) * 100 = ~-35.7%
          const stats = AdminDashboardStats(
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

          expect(stats.weeklyGrowthRate, lessThan(0));
        });

        test('should return 0 when newUsersMonth is 0', () {
          const stats = AdminDashboardStats(
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

          expect(stats.weeklyGrowthRate, 0);
        });

        test('should return 0 when both weekly and monthly rates are 0', () {
          const stats = AdminDashboardStats(
            totalUsers: 100,
            activeUsers: 80,
            suspendedUsers: 5,
            adminsCount: 2,
            newUsersToday: 0,
            newUsersWeek: 0,
            newUsersMonth: 0,
            totalTrips: 50,
            totalMessages: 500,
            activeUsersToday: 20,
          );

          expect(stats.weeklyGrowthRate, 0);
        });
      });

      group('activeUserPercentage', () {
        test('should calculate correct percentage', () {
          const stats = AdminDashboardStats(
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

          // 850 / 1000 * 100 = 85%
          expect(stats.activeUserPercentage, 85.0);
        });

        test('should return 100% when all users are active', () {
          const stats = AdminDashboardStats(
            totalUsers: 100,
            activeUsers: 100,
            suspendedUsers: 0,
            adminsCount: 5,
            newUsersToday: 10,
            newUsersWeek: 75,
            newUsersMonth: 100,
            totalTrips: 50,
            totalMessages: 1000,
            activeUsersToday: 100,
          );

          expect(stats.activeUserPercentage, 100.0);
        });

        test('should return 0 when no users are active', () {
          const stats = AdminDashboardStats(
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

          expect(stats.activeUserPercentage, 0.0);
        });

        test('should return 0 when totalUsers is 0', () {
          const stats = AdminDashboardStats(
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

          expect(stats.activeUserPercentage, 0);
        });
      });

      group('suspendedUserPercentage', () {
        test('should calculate correct percentage', () {
          const stats = AdminDashboardStats(
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

          // 50 / 1000 * 100 = 5%
          expect(stats.suspendedUserPercentage, 5.0);
        });

        test('should return 100% when all users are suspended', () {
          const stats = AdminDashboardStats(
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

          expect(stats.suspendedUserPercentage, 100.0);
        });

        test('should return 0 when no users are suspended', () {
          const stats = AdminDashboardStats(
            totalUsers: 100,
            activeUsers: 100,
            suspendedUsers: 0,
            adminsCount: 5,
            newUsersToday: 10,
            newUsersWeek: 50,
            newUsersMonth: 100,
            totalTrips: 50,
            totalMessages: 1000,
            activeUsersToday: 100,
          );

          expect(stats.suspendedUserPercentage, 0.0);
        });

        test('should return 0 when totalUsers is 0', () {
          const stats = AdminDashboardStats(
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

          expect(stats.suspendedUserPercentage, 0);
        });
      });

      group('averageTripsPerUser', () {
        test('should calculate correct average', () {
          const stats = AdminDashboardStats(
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

          // 500 / 1000 = 0.5
          expect(stats.averageTripsPerUser, 0.5);
        });

        test('should return 0 when totalUsers is 0', () {
          const stats = AdminDashboardStats(
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

          expect(stats.averageTripsPerUser, 0);
        });

        test('should handle high trip ratio', () {
          const stats = AdminDashboardStats(
            totalUsers: 100,
            activeUsers: 80,
            suspendedUsers: 5,
            adminsCount: 2,
            newUsersToday: 5,
            newUsersWeek: 20,
            newUsersMonth: 50,
            totalTrips: 500,
            totalMessages: 1000,
            activeUsersToday: 50,
          );

          // 500 / 100 = 5
          expect(stats.averageTripsPerUser, 5.0);
        });
      });

      group('averageMessagesPerUser', () {
        test('should calculate correct average', () {
          const stats = AdminDashboardStats(
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

          // 10000 / 1000 = 10
          expect(stats.averageMessagesPerUser, 10.0);
        });

        test('should return 0 when totalUsers is 0', () {
          const stats = AdminDashboardStats(
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

          expect(stats.averageMessagesPerUser, 0);
        });

        test('should handle large message counts', () {
          const stats = AdminDashboardStats(
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

          // 100000000 / 1000000 = 100
          expect(stats.averageMessagesPerUser, 100.0);
        });
      });

      group('dailyActivePercentage', () {
        test('should calculate correct percentage', () {
          const stats = AdminDashboardStats(
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

          // 200 / 1000 * 100 = 20%
          expect(stats.dailyActivePercentage, 20.0);
        });

        test('should return 0 when totalUsers is 0', () {
          const stats = AdminDashboardStats(
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

          expect(stats.dailyActivePercentage, 0);
        });

        test('should return 100% when all users are active today', () {
          const stats = AdminDashboardStats(
            totalUsers: 100,
            activeUsers: 100,
            suspendedUsers: 0,
            adminsCount: 5,
            newUsersToday: 5,
            newUsersWeek: 20,
            newUsersMonth: 50,
            totalTrips: 50,
            totalMessages: 500,
            activeUsersToday: 100,
          );

          expect(stats.dailyActivePercentage, 100.0);
        });
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = AdminDashboardStats(
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

        final copied = original.copyWith(
          totalUsers: 1100,
          activeUsers: 950,
        );

        expect(copied.totalUsers, 1100);
        expect(copied.activeUsers, 950);
        // Original values preserved
        expect(copied.suspendedUsers, 50);
        expect(copied.adminsCount, 5);
        expect(copied.newUsersToday, 10);
      });

      test('should keep original values when not specified', () {
        const original = AdminDashboardStats(
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

        final copied = original.copyWith();

        expect(copied.totalUsers, original.totalUsers);
        expect(copied.activeUsers, original.activeUsers);
        expect(copied.suspendedUsers, original.suspendedUsers);
        expect(copied.adminsCount, original.adminsCount);
        expect(copied.newUsersToday, original.newUsersToday);
        expect(copied.newUsersWeek, original.newUsersWeek);
        expect(copied.newUsersMonth, original.newUsersMonth);
        expect(copied.totalTrips, original.totalTrips);
        expect(copied.totalMessages, original.totalMessages);
        expect(copied.activeUsersToday, original.activeUsersToday);
      });

      test('should allow copying all fields', () {
        const original = AdminDashboardStats(
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

        final copied = original.copyWith(
          totalUsers: 2000,
          activeUsers: 1700,
          suspendedUsers: 100,
          adminsCount: 10,
          newUsersToday: 20,
          newUsersWeek: 150,
          newUsersMonth: 600,
          totalTrips: 1000,
          totalMessages: 20000,
          activeUsersToday: 400,
        );

        expect(copied.totalUsers, 2000);
        expect(copied.activeUsers, 1700);
        expect(copied.suspendedUsers, 100);
        expect(copied.adminsCount, 10);
        expect(copied.newUsersToday, 20);
        expect(copied.newUsersWeek, 150);
        expect(copied.newUsersMonth, 600);
        expect(copied.totalTrips, 1000);
        expect(copied.totalMessages, 20000);
        expect(copied.activeUsersToday, 400);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        const stats1 = AdminDashboardStats(
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

        const stats2 = AdminDashboardStats(
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

        expect(stats1, equals(stats2));
      });

      test('should not be equal when different values', () {
        const stats1 = AdminDashboardStats(
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

        const stats2 = AdminDashboardStats(
          totalUsers: 1001,
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

        expect(stats1, isNot(equals(stats2)));
      });

      test('should have same hashCode for equal objects', () {
        const stats1 = AdminDashboardStats(
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

        const stats2 = AdminDashboardStats(
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

        expect(stats1.hashCode, equals(stats2.hashCode));
      });
    });

    group('edge cases', () {
      test('should handle zero values', () {
        const stats = AdminDashboardStats(
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

        expect(stats.activeUserPercentage, 0);
        expect(stats.suspendedUserPercentage, 0);
        expect(stats.averageTripsPerUser, 0);
        expect(stats.averageMessagesPerUser, 0);
        expect(stats.dailyActivePercentage, 0);
        expect(stats.weeklyGrowthRate, 0);
      });

      test('should handle very large numbers', () {
        const stats = AdminDashboardStats(
          totalUsers: 1000000000,
          activeUsers: 950000000,
          suspendedUsers: 10000000,
          adminsCount: 1000,
          newUsersToday: 100000,
          newUsersWeek: 700000,
          newUsersMonth: 3000000,
          totalTrips: 500000000,
          totalMessages: 10000000000,
          activeUsersToday: 50000000,
        );

        expect(stats.activeUserPercentage, 95.0);
        expect(stats.suspendedUserPercentage, 1.0);
        expect(stats.averageTripsPerUser, 0.5);
        expect(stats.averageMessagesPerUser, 10.0);
        expect(stats.dailyActivePercentage, 5.0);
      });

      test('should handle fractional percentages correctly', () {
        const stats = AdminDashboardStats(
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

        // 1 / 3 * 100 = 33.333...
        expect(stats.activeUserPercentage, closeTo(33.33, 0.01));
        // 7 / 3 = 2.333...
        expect(stats.averageMessagesPerUser, closeTo(2.33, 0.01));
      });

      test('should handle single user stats', () {
        const stats = AdminDashboardStats(
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

        expect(stats.activeUserPercentage, 100.0);
        expect(stats.dailyActivePercentage, 100.0);
        expect(stats.averageTripsPerUser, 1.0);
        expect(stats.averageMessagesPerUser, 5.0);
      });

      test('should handle only admins stats', () {
        const stats = AdminDashboardStats(
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

        expect(stats.adminsCount, 10);
        expect(stats.totalUsers, 10);
        expect(stats.activeUserPercentage, 100.0);
      });

      test('should handle all suspended users', () {
        const stats = AdminDashboardStats(
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

        expect(stats.suspendedUserPercentage, 100.0);
        expect(stats.activeUserPercentage, 0.0);
      });
    });

    group('props', () {
      test('should include all fields in props', () {
        const stats = AdminDashboardStats(
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

        expect(stats.props, [
          1000,
          850,
          50,
          5,
          10,
          75,
          300,
          500,
          10000,
          200,
        ]);
      });
    });
  });
}
