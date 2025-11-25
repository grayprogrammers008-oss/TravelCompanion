import 'package:equatable/equatable.dart';

/// Admin Dashboard Statistics Entity
/// Aggregated statistics for admin dashboard
class AdminDashboardStats extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;
  final int adminsCount;
  final int newUsersToday;
  final int newUsersWeek;
  final int newUsersMonth;
  final int totalTrips;
  final int totalMessages;
  final int activeUsersToday;

  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.suspendedUsers,
    required this.adminsCount,
    required this.newUsersToday,
    required this.newUsersWeek,
    required this.newUsersMonth,
    required this.totalTrips,
    required this.totalMessages,
    required this.activeUsersToday,
  });

  /// Get user growth percentage (week over month)
  double get weeklyGrowthRate {
    if (newUsersMonth == 0) return 0;
    final weeklyRate = (newUsersWeek / 7).toDouble();
    final monthlyRate = (newUsersMonth / 30).toDouble();
    if (monthlyRate == 0) return 0;
    return ((weeklyRate - monthlyRate) / monthlyRate) * 100;
  }

  /// Get active user percentage
  double get activeUserPercentage {
    if (totalUsers == 0) return 0;
    return (activeUsers / totalUsers) * 100;
  }

  /// Get suspended user percentage
  double get suspendedUserPercentage {
    if (totalUsers == 0) return 0;
    return (suspendedUsers / totalUsers) * 100;
  }

  /// Get average trips per user
  double get averageTripsPerUser {
    if (totalUsers == 0) return 0;
    return totalTrips / totalUsers;
  }

  /// Get average messages per user
  double get averageMessagesPerUser {
    if (totalUsers == 0) return 0;
    return totalMessages / totalUsers;
  }

  /// Get daily active user percentage
  double get dailyActivePercentage {
    if (totalUsers == 0) return 0;
    return (activeUsersToday / totalUsers) * 100;
  }

  /// Copy with method
  AdminDashboardStats copyWith({
    int? totalUsers,
    int? activeUsers,
    int? suspendedUsers,
    int? adminsCount,
    int? newUsersToday,
    int? newUsersWeek,
    int? newUsersMonth,
    int? totalTrips,
    int? totalMessages,
    int? activeUsersToday,
  }) {
    return AdminDashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      suspendedUsers: suspendedUsers ?? this.suspendedUsers,
      adminsCount: adminsCount ?? this.adminsCount,
      newUsersToday: newUsersToday ?? this.newUsersToday,
      newUsersWeek: newUsersWeek ?? this.newUsersWeek,
      newUsersMonth: newUsersMonth ?? this.newUsersMonth,
      totalTrips: totalTrips ?? this.totalTrips,
      totalMessages: totalMessages ?? this.totalMessages,
      activeUsersToday: activeUsersToday ?? this.activeUsersToday,
    );
  }

  @override
  List<Object?> get props => [
        totalUsers,
        activeUsers,
        suspendedUsers,
        adminsCount,
        newUsersToday,
        newUsersWeek,
        newUsersMonth,
        totalTrips,
        totalMessages,
        activeUsersToday,
      ];
}
