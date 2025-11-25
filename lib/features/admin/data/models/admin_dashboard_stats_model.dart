import 'package:travel_crew/features/admin/domain/entities/admin_dashboard_stats.dart';

/// Admin Dashboard Stats Model
/// Maps database JSON to domain entity
class AdminDashboardStatsModel extends AdminDashboardStats {
  const AdminDashboardStatsModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.suspendedUsers,
    required super.adminsCount,
    required super.newUsersToday,
    required super.newUsersWeek,
    required super.newUsersMonth,
    required super.totalTrips,
    required super.totalMessages,
    required super.activeUsersToday,
  });

  /// Create from JSON (Supabase response)
  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      suspendedUsers: json['suspended_users'] as int? ?? 0,
      adminsCount: json['admins_count'] as int? ?? 0,
      newUsersToday: json['new_users_today'] as int? ?? 0,
      newUsersWeek: json['new_users_week'] as int? ?? 0,
      newUsersMonth: json['new_users_month'] as int? ?? 0,
      totalTrips: json['total_trips'] as int? ?? 0,
      totalMessages: json['total_messages'] as int? ?? 0,
      activeUsersToday: json['active_users_today'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'suspended_users': suspendedUsers,
      'admins_count': adminsCount,
      'new_users_today': newUsersToday,
      'new_users_week': newUsersWeek,
      'new_users_month': newUsersMonth,
      'total_trips': totalTrips,
      'total_messages': totalMessages,
      'active_users_today': activeUsersToday,
    };
  }

  /// Convert to domain entity
  AdminDashboardStats toEntity() {
    return AdminDashboardStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      suspendedUsers: suspendedUsers,
      adminsCount: adminsCount,
      newUsersToday: newUsersToday,
      newUsersWeek: newUsersWeek,
      newUsersMonth: newUsersMonth,
      totalTrips: totalTrips,
      totalMessages: totalMessages,
      activeUsersToday: activeUsersToday,
    );
  }

  /// Create from domain entity
  factory AdminDashboardStatsModel.fromEntity(AdminDashboardStats stats) {
    return AdminDashboardStatsModel(
      totalUsers: stats.totalUsers,
      activeUsers: stats.activeUsers,
      suspendedUsers: stats.suspendedUsers,
      adminsCount: stats.adminsCount,
      newUsersToday: stats.newUsersToday,
      newUsersWeek: stats.newUsersWeek,
      newUsersMonth: stats.newUsersMonth,
      totalTrips: stats.totalTrips,
      totalMessages: stats.totalMessages,
      activeUsersToday: stats.activeUsersToday,
    );
  }
}
