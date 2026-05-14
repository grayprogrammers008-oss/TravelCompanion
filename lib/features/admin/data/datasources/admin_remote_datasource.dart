import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathio/features/admin/data/datasources/admin_queries.dart';
import 'package:pathio/features/admin/data/models/admin_activity_log_model.dart';
import 'package:pathio/features/admin/data/models/admin_dashboard_stats_model.dart';
import 'package:pathio/features/admin/data/models/admin_user_model.dart';
import 'package:pathio/features/admin/domain/entities/admin_checklist.dart';
import 'package:pathio/features/admin/domain/entities/admin_expense.dart';
import 'package:pathio/features/admin/domain/entities/admin_trip.dart';
import 'package:pathio/features/admin/domain/entities/user_role.dart';
import 'package:pathio/features/admin/domain/entities/user_status.dart';

/// Admin Remote Data Source
///
/// All Supabase RPC and PostgREST chain calls live behind [AdminQueries] so
/// the datasource itself can be exercised by unit tests. The default
/// constructor wires up the production [AdminQueriesImpl]; tests inject a
/// fake.
class AdminRemoteDataSource {
  AdminRemoteDataSource(
    SupabaseClient supabase, {
    AdminQueries? queries,
    DateTime Function()? clock,
  })  : _queries = queries ?? AdminQueriesImpl(supabase),
        _clock = clock ?? DateTime.now;

  final AdminQueries _queries;
  final DateTime Function() _clock;

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final userId = _queries.currentUserId();
      if (userId == null) return false;

      final response = await _queries.rpcIsAdmin(userId);
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
      final response = await _queries.rpcGetAllUsersAdmin(
        limit: limit,
        offset: offset,
        search: search,
        role: role?.value,
        status: status?.value,
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => AdminUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get user by ID with statistics
  Future<AdminUserModel> getUserById(String userId) async {
    try {
      final response = await _queries.rpcGetAllUsersAdmin(
        limit: 1,
        offset: 0,
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
      final response = await _queries.rpcSuspendUser(userId, reason);
      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  /// Activate user account
  Future<bool> activateUser(String userId) async {
    try {
      final response = await _queries.rpcActivateUser(userId);
      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  /// Update user role
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      final response =
          await _queries.rpcUpdateUserRole(userId, newRole.value);
      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Get admin dashboard statistics
  Future<AdminDashboardStatsModel> getDashboardStats() async {
    try {
      final response = await _queries.rpcGetAdminDashboardStats();
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
      final rows = await _queries.findActivityLogs(
        adminId: adminId,
        targetUserId: targetUserId,
        offset: offset,
        limit: limit,
      );
      return rows.map(AdminActivityLogModel.fromJson).toList();
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

      updates['updated_at'] = _clock().toIso8601String();

      await _queries.updateProfileById(userId, updates);

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
      final response = await _queries.rpcGetAllTripsAdmin(
        limit: limit,
        offset: offset,
        search: search,
        status: status,
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => AdminTripModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get trips: $e');
    }
  }

  /// Delete trip (admin only)
  Future<bool> deleteTrip(String tripId) async {
    try {
      final response = await _queries.rpcAdminDeleteTrip(tripId);
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
      final response = await _queries.rpcAdminUpdateTrip(
        tripId: tripId,
        name: name,
        description: description,
        destination: destination,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        budget: budget,
        currency: currency,
        isCompleted: isCompleted,
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
      final response = await _queries.rpcGetAllChecklistsAdmin(
        limit: limit,
        offset: offset,
        search: search,
        status: status,
        tripId: tripId,
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              AdminChecklistModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get checklists: $e');
    }
  }

  /// Get checklist statistics (admin only)
  Future<AdminChecklistStatsModel> getChecklistStats() async {
    try {
      final response = await _queries.rpcGetAdminChecklistStats();
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
      final response = await _queries.rpcAdminDeleteChecklist(checklistId);
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
      final response = await _queries.rpcAdminUpdateChecklist(
        checklistId: checklistId,
        name: name,
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
      final response = await _queries.rpcAdminBulkUpdateChecklistItems(
        checklistId: checklistId,
        isCompleted: isCompleted,
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
      final response = await _queries.rpcGetAllExpensesAdmin(
        limit: limit,
        offset: offset,
        search: search,
        category: category,
        tripId: tripId,
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              AdminExpenseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  /// Get expense statistics (admin only)
  Future<AdminExpenseStatsModel> getExpenseStats() async {
    try {
      final response = await _queries.rpcGetAdminExpenseStats();
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
      final response = await _queries.rpcAdminDeleteExpense(expenseId);
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
      final response = await _queries.rpcAdminUpdateExpense(
        expenseId: expenseId,
        title: title,
        description: description,
        amount: amount,
        currency: currency,
        category: category,
      );
      return response as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Settle all splits for an expense (admin only)
  Future<int> settleExpenseSplits(String expenseId) async {
    try {
      final response = await _queries.rpcAdminSettleExpenseSplits(expenseId);
      return (response as num?)?.toInt() ?? 0;
    } catch (e) {
      throw Exception('Failed to settle expense splits: $e');
    }
  }

  /// Unsettle all splits for an expense (admin only)
  Future<int> unsettleExpenseSplits(String expenseId) async {
    try {
      final response = await _queries.rpcAdminUnsettleExpenseSplits(expenseId);
      return (response as num?)?.toInt() ?? 0;
    } catch (e) {
      throw Exception('Failed to unsettle expense splits: $e');
    }
  }
}
