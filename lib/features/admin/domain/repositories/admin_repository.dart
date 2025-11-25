import 'package:travel_crew/features/admin/domain/entities/admin_activity_log.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

/// Admin Repository Interface
/// Defines contract for admin user management operations
abstract class AdminRepository {
  /// Check if current user is admin
  Future<bool> isAdmin();

  /// Get all users with statistics (admin only)
  ///
  /// [limit] - Maximum number of users to return (default: 50)
  /// [offset] - Number of users to skip (for pagination)
  /// [search] - Search term to filter by email or name
  /// [role] - Filter by user role
  /// [status] - Filter by user status
  ///
  /// Throws an exception if user is not admin or on error
  Future<List<AdminUser>> getAllUsers({
    int limit = 50,
    int offset = 0,
    String? search,
    UserRole? role,
    UserStatus? status,
  });

  /// Get user by ID with statistics
  ///
  /// Throws an exception if user is not found or on error
  Future<AdminUser> getUserById(String userId);

  /// Suspend user account
  ///
  /// [userId] - User ID to suspend
  /// [reason] - Reason for suspension (will be logged)
  ///
  /// Returns true if successful
  /// Throws an exception if user is not admin or on error
  Future<bool> suspendUser(String userId, String reason);

  /// Activate suspended user account
  ///
  /// [userId] - User ID to activate
  ///
  /// Returns true if successful
  /// Throws an exception if user is not admin or on error
  Future<bool> activateUser(String userId);

  /// Update user role (super_admin only)
  ///
  /// [userId] - User ID to update
  /// [newRole] - New role to assign
  ///
  /// Returns true if successful
  /// Throws an exception if user is not super_admin or on error
  Future<bool> updateUserRole(String userId, UserRole newRole);

  /// Get admin dashboard statistics
  ///
  /// Throws an exception if user is not admin or on error
  Future<AdminDashboardStats> getDashboardStats();

  /// Get admin activity logs
  ///
  /// [limit] - Maximum number of logs to return
  /// [offset] - Number of logs to skip (for pagination)
  /// [adminId] - Filter by admin user ID
  /// [targetUserId] - Filter by target user ID
  ///
  /// Throws an exception if user is not admin or on error
  Future<List<AdminActivityLog>> getActivityLogs({
    int limit = 50,
    int offset = 0,
    String? adminId,
    String? targetUserId,
  });

  /// Update user profile (admin can update any user)
  ///
  /// [userId] - User ID to update
  /// [fullName] - New full name
  /// [avatarUrl] - New avatar URL
  ///
  /// Returns updated user
  /// Throws an exception if user is not admin or on error
  Future<AdminUser> updateUserProfile(
    String userId, {
    String? fullName,
    String? avatarUrl,
  });
}
