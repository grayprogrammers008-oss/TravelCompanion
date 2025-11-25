import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/admin/data/models/admin_activity_log_model.dart';
import 'package:travel_crew/features/admin/data/models/admin_dashboard_stats_model.dart';
import 'package:travel_crew/features/admin/data/models/admin_user_model.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

/// Admin Remote Data Source
/// Handles all Supabase interactions for admin functionality
class AdminRemoteDataSource {
  final SupabaseClient _supabase;

  AdminRemoteDataSource(this._supabase);

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc(
        'is_admin',
        params: {'user_id': userId},
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to check admin status: $e');
    }
  }

  /// Get all users with statistics (admin only)
  Future<List<AdminUserModel>> getAllUsers({
    int limit = 50,
    int offset = 0,
    String? search,
    UserRole? role,
    UserStatus? status,
  }) async {
    try {
      print('🔍 DEBUG: Calling get_all_users_admin with params:');
      print('  limit: $limit, offset: $offset, search: $search, role: $role, status: $status');

      final response = await _supabase.rpc(
        'get_all_users_admin',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          if (search != null) 'p_search': search,
          if (role != null) 'p_role': role.value,
          if (status != null) 'p_status': status.value,
        },
      );

      print('✅ DEBUG: Got response type: ${response.runtimeType}');
      print('✅ DEBUG: Response: $response');

      final List<dynamic> data = response as List<dynamic>;
      print('✅ DEBUG: Parsed ${data.length} users');

      return data
          .map((json) => AdminUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error getting users: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get user by ID with statistics
  Future<AdminUserModel> getUserById(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_all_users_admin',
        params: {
          'p_limit': 1,
          'p_offset': 0,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      final users = data
          .map((json) => AdminUserModel.fromJson(json as Map<String, dynamic>))
          .where((user) => user.id == userId)
          .toList();

      if (users.isEmpty) {
        throw Exception('User not found');
      }

      return users.first;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Suspend user account
  Future<bool> suspendUser(String userId, String reason) async {
    try {
      final response = await _supabase.rpc(
        'suspend_user',
        params: {
          'p_user_id': userId,
          'p_reason': reason,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Activate user account
  Future<bool> activateUser(String userId) async {
    try {
      final response = await _supabase.rpc(
        'activate_user',
        params: {
          'p_user_id': userId,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      final response = await _supabase.rpc(
        'update_user_role',
        params: {
          'p_user_id': userId,
          'p_new_role': newRole.value,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Get admin dashboard statistics
  Future<AdminDashboardStatsModel> getDashboardStats() async {
    try {
      final response = await _supabase.rpc('get_admin_dashboard_stats');

      return AdminDashboardStatsModel.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  /// Get admin activity logs
  Future<List<AdminActivityLogModel>> getActivityLogs({
    int limit = 50,
    int offset = 0,
    String? adminId,
    String? targetUserId,
  }) async {
    try {
      var query = _supabase.from('admin_activity_log').select();

      if (adminId != null) {
        query = query.eq('admin_id', adminId);
      }

      if (targetUserId != null) {
        query = query.eq('target_user_id', targetUserId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> data = response;

      return data
          .map((json) =>
              AdminActivityLogModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get activity logs: $e');
    }
  }

  /// Update user profile
  Future<AdminUserModel> updateUserProfile(
    String userId, {
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        return await getUserById(userId);
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('profiles').update(updates).eq('id', userId);

      return await getUserById(userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
