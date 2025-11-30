import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/admin/data/models/admin_activity_log_model.dart';
import 'package:travel_crew/features/admin/data/models/admin_dashboard_stats_model.dart';
import 'package:travel_crew/features/admin/data/models/admin_user_model.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_checklist.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_expense.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_trip.dart';
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

  // ============================================================
  // TRIP MANAGEMENT METHODS
  // ============================================================

  /// Get all trips with member counts and expenses (admin only)
  Future<List<AdminTripModel>> getAllTrips({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
  }) async {
    try {
      print('🔍 DEBUG: Calling get_all_trips_admin with params:');
      print('  limit: $limit, offset: $offset, search: $search, status: $status');

      final response = await _supabase.rpc(
        'get_all_trips_admin',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          if (search != null) 'p_search': search,
          if (status != null) 'p_status': status,
        },
      );

      print('✅ DEBUG: Got response type: ${response.runtimeType}');
      print('✅ DEBUG: Response: $response');

      final List<dynamic> data = response as List<dynamic>;
      print('✅ DEBUG: Parsed ${data.length} trips');

      return data
          .map((json) => AdminTripModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error getting trips: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      throw Exception('Failed to get trips: $e');
    }
  }

  /// Delete trip (admin only)
  Future<bool> deleteTrip(String tripId) async {
    try {
      final response = await _supabase.rpc(
        'admin_delete_trip',
        params: {
          'p_trip_id': tripId,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  /// Update trip (admin only)
  Future<bool> updateTrip(
    String tripId, {
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? currency,
    bool? isCompleted,
  }) async {
    try {
      final response = await _supabase.rpc(
        'admin_update_trip',
        params: {
          'p_trip_id': tripId,
          if (name != null) 'p_name': name,
          if (description != null) 'p_description': description,
          if (destination != null) 'p_destination': destination,
          if (startDate != null) 'p_start_date': startDate.toIso8601String(),
          if (endDate != null) 'p_end_date': endDate.toIso8601String(),
          if (budget != null) 'p_budget': budget,
          if (currency != null) 'p_currency': currency,
          if (isCompleted != null) 'p_is_completed': isCompleted,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  // ============================================================
  // CHECKLIST MANAGEMENT METHODS
  // ============================================================

  /// Get all checklists with trip info and statistics (admin only)
  Future<List<AdminChecklistModel>> getAllChecklists({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
    String? tripId,
  }) async {
    try {
      print('🔍 DEBUG: Calling get_all_checklists_admin with params:');
      print('  limit: $limit, offset: $offset, search: $search, status: $status, tripId: $tripId');

      final response = await _supabase.rpc(
        'get_all_checklists_admin',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          if (search != null) 'p_search': search,
          if (status != null) 'p_status': status,
          if (tripId != null) 'p_trip_id': tripId,
        },
      );

      print('✅ DEBUG: Got response type: ${response.runtimeType}');
      print('✅ DEBUG: Response: $response');

      final List<dynamic> data = response as List<dynamic>;
      print('✅ DEBUG: Parsed ${data.length} checklists');

      return data
          .map((json) => AdminChecklistModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error getting checklists: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      throw Exception('Failed to get checklists: $e');
    }
  }

  /// Get checklist statistics (admin only)
  Future<AdminChecklistStatsModel> getChecklistStats() async {
    try {
      final response = await _supabase.rpc('get_admin_checklist_stats');

      return AdminChecklistStatsModel.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get checklist stats: $e');
    }
  }

  /// Delete checklist (admin only)
  Future<bool> deleteChecklist(String checklistId) async {
    try {
      final response = await _supabase.rpc(
        'admin_delete_checklist',
        params: {
          'p_checklist_id': checklistId,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to delete checklist: $e');
    }
  }

  /// Update checklist (admin only)
  Future<bool> updateChecklist(
    String checklistId, {
    String? name,
  }) async {
    try {
      final response = await _supabase.rpc(
        'admin_update_checklist',
        params: {
          'p_checklist_id': checklistId,
          if (name != null) 'p_name': name,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to update checklist: $e');
    }
  }

  /// Bulk update checklist items (mark all as completed/pending)
  Future<int> bulkUpdateChecklistItems(
    String checklistId, {
    required bool isCompleted,
  }) async {
    try {
      final response = await _supabase.rpc(
        'admin_bulk_update_checklist_items',
        params: {
          'p_checklist_id': checklistId,
          'p_is_completed': isCompleted,
        },
      );

      return (response as num?)?.toInt() ?? 0;
    } catch (e) {
      throw Exception('Failed to bulk update checklist items: $e');
    }
  }

  // ============================================================
  // EXPENSE MANAGEMENT METHODS
  // ============================================================

  /// Get all expenses with trip info and statistics (admin only)
  Future<List<AdminExpenseModel>> getAllExpenses({
    int limit = 50,
    int offset = 0,
    String? search,
    String? category,
    String? tripId,
  }) async {
    try {
      print('🔍 DEBUG: Calling get_all_expenses_admin with params:');
      print('  limit: $limit, offset: $offset, search: $search, category: $category, tripId: $tripId');

      final response = await _supabase.rpc(
        'get_all_expenses_admin',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          if (search != null) 'p_search': search,
          if (category != null) 'p_category': category,
          if (tripId != null) 'p_trip_id': tripId,
        },
      );

      print('✅ DEBUG: Got response type: ${response.runtimeType}');
      print('✅ DEBUG: Response: $response');

      final List<dynamic> data = response as List<dynamic>;
      print('✅ DEBUG: Parsed ${data.length} expenses');

      return data
          .map((json) => AdminExpenseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error getting expenses: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      throw Exception('Failed to get expenses: $e');
    }
  }

  /// Get expense statistics (admin only)
  Future<AdminExpenseStatsModel> getExpenseStats() async {
    try {
      final response = await _supabase.rpc('get_admin_expense_stats');

      return AdminExpenseStatsModel.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get expense stats: $e');
    }
  }

  /// Delete expense (admin only)
  Future<bool> deleteExpense(String expenseId) async {
    try {
      final response = await _supabase.rpc(
        'admin_delete_expense',
        params: {
          'p_expense_id': expenseId,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Update expense (admin only)
  Future<bool> updateExpense(
    String expenseId, {
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
  }) async {
    try {
      final response = await _supabase.rpc(
        'admin_update_expense',
        params: {
          'p_expense_id': expenseId,
          if (title != null) 'p_title': title,
          if (description != null) 'p_description': description,
          if (amount != null) 'p_amount': amount,
          if (currency != null) 'p_currency': currency,
          if (category != null) 'p_category': category,
        },
      );

      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Settle all splits for an expense (admin only)
  Future<int> settleExpenseSplits(String expenseId) async {
    try {
      final response = await _supabase.rpc(
        'admin_settle_expense_splits',
        params: {
          'p_expense_id': expenseId,
        },
      );

      return (response as num?)?.toInt() ?? 0;
    } catch (e) {
      throw Exception('Failed to settle expense splits: $e');
    }
  }

  /// Unsettle all splits for an expense (admin only)
  Future<int> unsettleExpenseSplits(String expenseId) async {
    try {
      final response = await _supabase.rpc(
        'admin_unsettle_expense_splits',
        params: {
          'p_expense_id': expenseId,
        },
      );

      return (response as num?)?.toInt() ?? 0;
    } catch (e) {
      throw Exception('Failed to unsettle expense splits: $e');
    }
  }
}
