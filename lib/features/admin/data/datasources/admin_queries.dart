import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase RPC calls and PostgREST chain used by
/// [AdminRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).order(...)`) and
/// raw `rpc(name, params: ...)` invocations are not mockable through Mockito —
/// their generic types are fixed per method and `Mock` cannot intercept the
/// awaited `then()`. Wrapping them in this interface lets tests substitute a
/// fake while the production [AdminQueriesImpl] carries the (untestable)
/// Supabase code.
abstract class AdminQueries {
  // ---------- Auth helpers ----------

  /// Currently-authenticated user id (or null).
  String? currentUserId();

  // ---------- RPCs ----------

  /// `is_admin(user_id)` → bool
  Future<dynamic> rpcIsAdmin(String userId);

  /// `get_all_users_admin(...)` → `List<dynamic>`
  Future<dynamic> rpcGetAllUsersAdmin({
    required int limit,
    required int offset,
    String? search,
    String? role,
    String? status,
  });

  /// `suspend_user(user_id, reason)` → bool
  Future<dynamic> rpcSuspendUser(String userId, String reason);

  /// `activate_user(user_id)` → bool
  Future<dynamic> rpcActivateUser(String userId);

  /// `update_user_role(user_id, new_role)` → bool
  Future<dynamic> rpcUpdateUserRole(String userId, String newRole);

  /// `get_admin_dashboard_stats()` → Map
  Future<dynamic> rpcGetAdminDashboardStats();

  /// `get_all_trips_admin(...)` → `List<dynamic>`
  Future<dynamic> rpcGetAllTripsAdmin({
    required int limit,
    required int offset,
    String? search,
    String? status,
  });

  /// `admin_delete_trip(trip_id)` → bool
  Future<dynamic> rpcAdminDeleteTrip(String tripId);

  /// `admin_update_trip(...)` → bool
  Future<dynamic> rpcAdminUpdateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    String? startDate,
    String? endDate,
    double? budget,
    String? currency,
    bool? isCompleted,
  });

  /// `get_all_checklists_admin(...)` → `List<dynamic>`
  Future<dynamic> rpcGetAllChecklistsAdmin({
    required int limit,
    required int offset,
    String? search,
    String? status,
    String? tripId,
  });

  /// `get_admin_checklist_stats()` → Map
  Future<dynamic> rpcGetAdminChecklistStats();

  /// `admin_delete_checklist(checklist_id)` → bool
  Future<dynamic> rpcAdminDeleteChecklist(String checklistId);

  /// `admin_update_checklist(checklist_id, name?)` → bool
  Future<dynamic> rpcAdminUpdateChecklist({
    required String checklistId,
    String? name,
  });

  /// `admin_bulk_update_checklist_items(checklist_id, is_completed)` → num
  Future<dynamic> rpcAdminBulkUpdateChecklistItems({
    required String checklistId,
    required bool isCompleted,
  });

  /// `get_all_expenses_admin(...)` → `List<dynamic>`
  Future<dynamic> rpcGetAllExpensesAdmin({
    required int limit,
    required int offset,
    String? search,
    String? category,
    String? tripId,
  });

  /// `get_admin_expense_stats()` → Map
  Future<dynamic> rpcGetAdminExpenseStats();

  /// `admin_delete_expense(expense_id)` → bool
  Future<dynamic> rpcAdminDeleteExpense(String expenseId);

  /// `admin_update_expense(...)` → bool
  Future<dynamic> rpcAdminUpdateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
  });

  /// `admin_settle_expense_splits(expense_id)` → num
  Future<dynamic> rpcAdminSettleExpenseSplits(String expenseId);

  /// `admin_unsettle_expense_splits(expense_id)` → num
  Future<dynamic> rpcAdminUnsettleExpenseSplits(String expenseId);

  // ---------- PostgREST chains ----------

  /// Fetch admin activity log rows ordered desc with optional filters.
  Future<List<Map<String, dynamic>>> findActivityLogs({
    String? adminId,
    String? targetUserId,
    required int offset,
    required int limit,
  });

  /// Update profile fields for a user.
  Future<void> updateProfileById(String userId, Map<String, dynamic> data);
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through. Exercised end-to-end by integration / live tests,
/// not unit tests.
class AdminQueriesImpl implements AdminQueries {
  AdminQueriesImpl(this._client);
  final SupabaseClient _client;

  @override
  String? currentUserId() => _client.auth.currentUser?.id;

  @override
  Future<dynamic> rpcIsAdmin(String userId) {
    return _client.rpc('is_admin', params: {'user_id': userId});
  }

  @override
  Future<dynamic> rpcGetAllUsersAdmin({
    required int limit,
    required int offset,
    String? search,
    String? role,
    String? status,
  }) {
    return _client.rpc(
      'get_all_users_admin',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        if (search != null) 'p_search': search,
        if (role != null) 'p_role': role,
        if (status != null) 'p_status': status,
      },
    );
  }

  @override
  Future<dynamic> rpcSuspendUser(String userId, String reason) {
    return _client.rpc(
      'suspend_user',
      params: {'p_user_id': userId, 'p_reason': reason},
    );
  }

  @override
  Future<dynamic> rpcActivateUser(String userId) {
    return _client.rpc('activate_user', params: {'p_user_id': userId});
  }

  @override
  Future<dynamic> rpcUpdateUserRole(String userId, String newRole) {
    return _client.rpc(
      'update_user_role',
      params: {'p_user_id': userId, 'p_new_role': newRole},
    );
  }

  @override
  Future<dynamic> rpcGetAdminDashboardStats() {
    return _client.rpc('get_admin_dashboard_stats');
  }

  @override
  Future<dynamic> rpcGetAllTripsAdmin({
    required int limit,
    required int offset,
    String? search,
    String? status,
  }) {
    return _client.rpc(
      'get_all_trips_admin',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        if (search != null) 'p_search': search,
        if (status != null) 'p_status': status,
      },
    );
  }

  @override
  Future<dynamic> rpcAdminDeleteTrip(String tripId) {
    return _client.rpc('admin_delete_trip', params: {'p_trip_id': tripId});
  }

  @override
  Future<dynamic> rpcAdminUpdateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    String? startDate,
    String? endDate,
    double? budget,
    String? currency,
    bool? isCompleted,
  }) {
    return _client.rpc(
      'admin_update_trip',
      params: {
        'p_trip_id': tripId,
        if (name != null) 'p_name': name,
        if (description != null) 'p_description': description,
        if (destination != null) 'p_destination': destination,
        if (startDate != null) 'p_start_date': startDate,
        if (endDate != null) 'p_end_date': endDate,
        if (budget != null) 'p_budget': budget,
        if (currency != null) 'p_currency': currency,
        if (isCompleted != null) 'p_is_completed': isCompleted,
      },
    );
  }

  @override
  Future<dynamic> rpcGetAllChecklistsAdmin({
    required int limit,
    required int offset,
    String? search,
    String? status,
    String? tripId,
  }) {
    return _client.rpc(
      'get_all_checklists_admin',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        if (search != null) 'p_search': search,
        if (status != null) 'p_status': status,
        if (tripId != null) 'p_trip_id': tripId,
      },
    );
  }

  @override
  Future<dynamic> rpcGetAdminChecklistStats() {
    return _client.rpc('get_admin_checklist_stats');
  }

  @override
  Future<dynamic> rpcAdminDeleteChecklist(String checklistId) {
    return _client.rpc(
      'admin_delete_checklist',
      params: {'p_checklist_id': checklistId},
    );
  }

  @override
  Future<dynamic> rpcAdminUpdateChecklist({
    required String checklistId,
    String? name,
  }) {
    return _client.rpc(
      'admin_update_checklist',
      params: {
        'p_checklist_id': checklistId,
        if (name != null) 'p_name': name,
      },
    );
  }

  @override
  Future<dynamic> rpcAdminBulkUpdateChecklistItems({
    required String checklistId,
    required bool isCompleted,
  }) {
    return _client.rpc(
      'admin_bulk_update_checklist_items',
      params: {
        'p_checklist_id': checklistId,
        'p_is_completed': isCompleted,
      },
    );
  }

  @override
  Future<dynamic> rpcGetAllExpensesAdmin({
    required int limit,
    required int offset,
    String? search,
    String? category,
    String? tripId,
  }) {
    return _client.rpc(
      'get_all_expenses_admin',
      params: {
        'p_limit': limit,
        'p_offset': offset,
        if (search != null) 'p_search': search,
        if (category != null) 'p_category': category,
        if (tripId != null) 'p_trip_id': tripId,
      },
    );
  }

  @override
  Future<dynamic> rpcGetAdminExpenseStats() {
    return _client.rpc('get_admin_expense_stats');
  }

  @override
  Future<dynamic> rpcAdminDeleteExpense(String expenseId) {
    return _client.rpc(
      'admin_delete_expense',
      params: {'p_expense_id': expenseId},
    );
  }

  @override
  Future<dynamic> rpcAdminUpdateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
  }) {
    return _client.rpc(
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
  }

  @override
  Future<dynamic> rpcAdminSettleExpenseSplits(String expenseId) {
    return _client.rpc(
      'admin_settle_expense_splits',
      params: {'p_expense_id': expenseId},
    );
  }

  @override
  Future<dynamic> rpcAdminUnsettleExpenseSplits(String expenseId) {
    return _client.rpc(
      'admin_unsettle_expense_splits',
      params: {'p_expense_id': expenseId},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> findActivityLogs({
    String? adminId,
    String? targetUserId,
    required int offset,
    required int limit,
  }) async {
    var query = _client.from('admin_activity_log').select();

    if (adminId != null) {
      query = query.eq('admin_id', adminId);
    }
    if (targetUserId != null) {
      query = query.eq('target_user_id', targetUserId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  @override
  Future<void> updateProfileById(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }
}
