import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_activity_log.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';

/// Admin Repository Implementation
/// Implements admin functionality using Supabase as the data source
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl(this._remoteDataSource);

  @override
  Future<bool> isAdmin() async {
    try {
      return await _remoteDataSource.isAdmin();
    } catch (e) {
      throw Exception('Failed to check admin status: $e');
    }
  }

  @override
  Future<List<AdminUser>> getAllUsers({
    int limit = 50,
    int offset = 0,
    String? search,
    UserRole? role,
    UserStatus? status,
  }) async {
    try {
      final models = await _remoteDataSource.getAllUsers(
        limit: limit,
        offset: offset,
        search: search,
        role: role,
        status: status,
      );

      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  @override
  Future<AdminUser> getUserById(String userId) async {
    try {
      final model = await _remoteDataSource.getUserById(userId);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<bool> suspendUser(String userId, String reason) async {
    try {
      return await _remoteDataSource.suspendUser(userId, reason);
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  @override
  Future<bool> activateUser(String userId) async {
    try {
      return await _remoteDataSource.activateUser(userId);
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  @override
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      return await _remoteDataSource.updateUserRole(userId, newRole);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final model = await _remoteDataSource.getDashboardStats();
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  @override
  Future<List<AdminActivityLog>> getActivityLogs({
    int limit = 50,
    int offset = 0,
    String? adminId,
    String? targetUserId,
  }) async {
    try {
      final models = await _remoteDataSource.getActivityLogs(
        limit: limit,
        offset: offset,
        adminId: adminId,
        targetUserId: targetUserId,
      );

      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get activity logs: $e');
    }
  }

  @override
  Future<AdminUser> updateUserProfile(
    String userId, {
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final model = await _remoteDataSource.updateUserProfile(
        userId,
        fullName: fullName,
        avatarUrl: avatarUrl,
      );

      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
