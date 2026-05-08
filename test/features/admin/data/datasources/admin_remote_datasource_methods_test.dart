import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:travel_crew/features/admin/data/datasources/admin_queries.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

/// Comprehensive unit tests for [AdminRemoteDataSource].
///
/// All Supabase RPC + PostgREST calls go through [AdminQueries] which is
/// faked here. We exercise every public method on the happy path AND the
/// error path, asserting both the args passed to the queries layer and the
/// model returned.

class _FakeQueries implements AdminQueries {
  // ---- recorded args ----
  String? overrideCurrentUserId;
  bool overrideCurrentUserIsNull = false;

  String? lastIsAdminUserId;

  int? lastGetAllUsersLimit;
  int? lastGetAllUsersOffset;
  String? lastGetAllUsersSearch;
  String? lastGetAllUsersRole;
  String? lastGetAllUsersStatus;

  String? lastSuspendUserId;
  String? lastSuspendReason;

  String? lastActivateUserId;

  String? lastUpdateRoleUserId;
  String? lastUpdateRoleNewRole;

  bool dashboardStatsCalled = false;

  int? lastGetTripsLimit;
  int? lastGetTripsOffset;
  String? lastGetTripsSearch;
  String? lastGetTripsStatus;

  String? lastDeleteTripId;

  String? lastUpdateTripId;
  String? lastUpdateTripName;
  String? lastUpdateTripDescription;
  String? lastUpdateTripDestination;
  String? lastUpdateTripStartDate;
  String? lastUpdateTripEndDate;
  double? lastUpdateTripBudget;
  String? lastUpdateTripCurrency;
  bool? lastUpdateTripIsCompleted;

  int? lastGetChecklistsLimit;
  int? lastGetChecklistsOffset;
  String? lastGetChecklistsSearch;
  String? lastGetChecklistsStatus;
  String? lastGetChecklistsTripId;

  bool checklistStatsCalled = false;

  String? lastDeleteChecklistId;

  String? lastUpdateChecklistId;
  String? lastUpdateChecklistName;

  String? lastBulkUpdateChecklistId;
  bool? lastBulkUpdateChecklistIsCompleted;

  int? lastGetExpensesLimit;
  int? lastGetExpensesOffset;
  String? lastGetExpensesSearch;
  String? lastGetExpensesCategory;
  String? lastGetExpensesTripId;

  bool expenseStatsCalled = false;

  String? lastDeleteExpenseId;

  String? lastUpdateExpenseId;
  String? lastUpdateExpenseTitle;
  String? lastUpdateExpenseDescription;
  double? lastUpdateExpenseAmount;
  String? lastUpdateExpenseCurrency;
  String? lastUpdateExpenseCategory;

  String? lastSettleExpenseId;
  String? lastUnsettleExpenseId;

  String? lastFindLogsAdminId;
  String? lastFindLogsTargetUserId;
  int? lastFindLogsOffset;
  int? lastFindLogsLimit;

  String? lastUpdateProfileUserId;
  Map<String, dynamic>? lastUpdateProfileData;

  // ---- responses ----
  dynamic isAdminResponse;
  dynamic getAllUsersResponse;
  dynamic suspendUserResponse;
  dynamic activateUserResponse;
  dynamic updateUserRoleResponse;
  dynamic dashboardStatsResponse;
  dynamic getAllTripsResponse;
  dynamic deleteTripResponse;
  dynamic updateTripResponse;
  dynamic getAllChecklistsResponse;
  dynamic checklistStatsResponse;
  dynamic deleteChecklistResponse;
  dynamic updateChecklistResponse;
  dynamic bulkUpdateChecklistResponse;
  dynamic getAllExpensesResponse;
  dynamic expenseStatsResponse;
  dynamic deleteExpenseResponse;
  dynamic updateExpenseResponse;
  dynamic settleExpenseResponse;
  dynamic unsettleExpenseResponse;
  List<Map<String, dynamic>> findActivityLogsResponse = const [];

  // ---- error injectors ----
  Object? throwOnIsAdmin;
  Object? throwOnGetAllUsers;
  Object? throwOnSuspendUser;
  Object? throwOnActivateUser;
  Object? throwOnUpdateUserRole;
  Object? throwOnDashboardStats;
  Object? throwOnGetAllTrips;
  Object? throwOnDeleteTrip;
  Object? throwOnUpdateTrip;
  Object? throwOnGetAllChecklists;
  Object? throwOnChecklistStats;
  Object? throwOnDeleteChecklist;
  Object? throwOnUpdateChecklist;
  Object? throwOnBulkUpdateChecklist;
  Object? throwOnGetAllExpenses;
  Object? throwOnExpenseStats;
  Object? throwOnDeleteExpense;
  Object? throwOnUpdateExpense;
  Object? throwOnSettleExpense;
  Object? throwOnUnsettleExpense;
  Object? throwOnFindActivityLogs;
  Object? throwOnUpdateProfile;

  @override
  String? currentUserId() {
    if (overrideCurrentUserIsNull) return null;
    return overrideCurrentUserId ?? 'admin-1';
  }

  @override
  Future<dynamic> rpcIsAdmin(String userId) async {
    if (throwOnIsAdmin != null) throw throwOnIsAdmin!;
    lastIsAdminUserId = userId;
    return isAdminResponse;
  }

  @override
  Future<dynamic> rpcGetAllUsersAdmin({
    required int limit,
    required int offset,
    String? search,
    String? role,
    String? status,
  }) async {
    if (throwOnGetAllUsers != null) throw throwOnGetAllUsers!;
    lastGetAllUsersLimit = limit;
    lastGetAllUsersOffset = offset;
    lastGetAllUsersSearch = search;
    lastGetAllUsersRole = role;
    lastGetAllUsersStatus = status;
    return getAllUsersResponse;
  }

  @override
  Future<dynamic> rpcSuspendUser(String userId, String reason) async {
    if (throwOnSuspendUser != null) throw throwOnSuspendUser!;
    lastSuspendUserId = userId;
    lastSuspendReason = reason;
    return suspendUserResponse;
  }

  @override
  Future<dynamic> rpcActivateUser(String userId) async {
    if (throwOnActivateUser != null) throw throwOnActivateUser!;
    lastActivateUserId = userId;
    return activateUserResponse;
  }

  @override
  Future<dynamic> rpcUpdateUserRole(String userId, String newRole) async {
    if (throwOnUpdateUserRole != null) throw throwOnUpdateUserRole!;
    lastUpdateRoleUserId = userId;
    lastUpdateRoleNewRole = newRole;
    return updateUserRoleResponse;
  }

  @override
  Future<dynamic> rpcGetAdminDashboardStats() async {
    if (throwOnDashboardStats != null) throw throwOnDashboardStats!;
    dashboardStatsCalled = true;
    return dashboardStatsResponse;
  }

  @override
  Future<dynamic> rpcGetAllTripsAdmin({
    required int limit,
    required int offset,
    String? search,
    String? status,
  }) async {
    if (throwOnGetAllTrips != null) throw throwOnGetAllTrips!;
    lastGetTripsLimit = limit;
    lastGetTripsOffset = offset;
    lastGetTripsSearch = search;
    lastGetTripsStatus = status;
    return getAllTripsResponse;
  }

  @override
  Future<dynamic> rpcAdminDeleteTrip(String tripId) async {
    if (throwOnDeleteTrip != null) throw throwOnDeleteTrip!;
    lastDeleteTripId = tripId;
    return deleteTripResponse;
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
  }) async {
    if (throwOnUpdateTrip != null) throw throwOnUpdateTrip!;
    lastUpdateTripId = tripId;
    lastUpdateTripName = name;
    lastUpdateTripDescription = description;
    lastUpdateTripDestination = destination;
    lastUpdateTripStartDate = startDate;
    lastUpdateTripEndDate = endDate;
    lastUpdateTripBudget = budget;
    lastUpdateTripCurrency = currency;
    lastUpdateTripIsCompleted = isCompleted;
    return updateTripResponse;
  }

  @override
  Future<dynamic> rpcGetAllChecklistsAdmin({
    required int limit,
    required int offset,
    String? search,
    String? status,
    String? tripId,
  }) async {
    if (throwOnGetAllChecklists != null) throw throwOnGetAllChecklists!;
    lastGetChecklistsLimit = limit;
    lastGetChecklistsOffset = offset;
    lastGetChecklistsSearch = search;
    lastGetChecklistsStatus = status;
    lastGetChecklistsTripId = tripId;
    return getAllChecklistsResponse;
  }

  @override
  Future<dynamic> rpcGetAdminChecklistStats() async {
    if (throwOnChecklistStats != null) throw throwOnChecklistStats!;
    checklistStatsCalled = true;
    return checklistStatsResponse;
  }

  @override
  Future<dynamic> rpcAdminDeleteChecklist(String checklistId) async {
    if (throwOnDeleteChecklist != null) throw throwOnDeleteChecklist!;
    lastDeleteChecklistId = checklistId;
    return deleteChecklistResponse;
  }

  @override
  Future<dynamic> rpcAdminUpdateChecklist({
    required String checklistId,
    String? name,
  }) async {
    if (throwOnUpdateChecklist != null) throw throwOnUpdateChecklist!;
    lastUpdateChecklistId = checklistId;
    lastUpdateChecklistName = name;
    return updateChecklistResponse;
  }

  @override
  Future<dynamic> rpcAdminBulkUpdateChecklistItems({
    required String checklistId,
    required bool isCompleted,
  }) async {
    if (throwOnBulkUpdateChecklist != null) throw throwOnBulkUpdateChecklist!;
    lastBulkUpdateChecklistId = checklistId;
    lastBulkUpdateChecklistIsCompleted = isCompleted;
    return bulkUpdateChecklistResponse;
  }

  @override
  Future<dynamic> rpcGetAllExpensesAdmin({
    required int limit,
    required int offset,
    String? search,
    String? category,
    String? tripId,
  }) async {
    if (throwOnGetAllExpenses != null) throw throwOnGetAllExpenses!;
    lastGetExpensesLimit = limit;
    lastGetExpensesOffset = offset;
    lastGetExpensesSearch = search;
    lastGetExpensesCategory = category;
    lastGetExpensesTripId = tripId;
    return getAllExpensesResponse;
  }

  @override
  Future<dynamic> rpcGetAdminExpenseStats() async {
    if (throwOnExpenseStats != null) throw throwOnExpenseStats!;
    expenseStatsCalled = true;
    return expenseStatsResponse;
  }

  @override
  Future<dynamic> rpcAdminDeleteExpense(String expenseId) async {
    if (throwOnDeleteExpense != null) throw throwOnDeleteExpense!;
    lastDeleteExpenseId = expenseId;
    return deleteExpenseResponse;
  }

  @override
  Future<dynamic> rpcAdminUpdateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
  }) async {
    if (throwOnUpdateExpense != null) throw throwOnUpdateExpense!;
    lastUpdateExpenseId = expenseId;
    lastUpdateExpenseTitle = title;
    lastUpdateExpenseDescription = description;
    lastUpdateExpenseAmount = amount;
    lastUpdateExpenseCurrency = currency;
    lastUpdateExpenseCategory = category;
    return updateExpenseResponse;
  }

  @override
  Future<dynamic> rpcAdminSettleExpenseSplits(String expenseId) async {
    if (throwOnSettleExpense != null) throw throwOnSettleExpense!;
    lastSettleExpenseId = expenseId;
    return settleExpenseResponse;
  }

  @override
  Future<dynamic> rpcAdminUnsettleExpenseSplits(String expenseId) async {
    if (throwOnUnsettleExpense != null) throw throwOnUnsettleExpense!;
    lastUnsettleExpenseId = expenseId;
    return unsettleExpenseResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findActivityLogs({
    String? adminId,
    String? targetUserId,
    required int offset,
    required int limit,
  }) async {
    if (throwOnFindActivityLogs != null) throw throwOnFindActivityLogs!;
    lastFindLogsAdminId = adminId;
    lastFindLogsTargetUserId = targetUserId;
    lastFindLogsOffset = offset;
    lastFindLogsLimit = limit;
    return findActivityLogsResponse;
  }

  @override
  Future<void> updateProfileById(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (throwOnUpdateProfile != null) throw throwOnUpdateProfile!;
    lastUpdateProfileUserId = userId;
    lastUpdateProfileData = data;
  }
}

/// Bare-bones SupabaseClient stand-in. The datasource never calls into it
/// because [AdminQueries] is injected; we only need a non-null instance to
/// satisfy the constructor.
class _FakeSupabase extends Fake implements SupabaseClient {}

void main() {
  late _FakeQueries queries;
  late AdminRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  setUp(() {
    queries = _FakeQueries();
    ds = AdminRemoteDataSource(
      _FakeSupabase(),
      queries: queries,
      clock: () => fixedClock,
    );
  });

  // ============================================================
  // isAdmin
  // ============================================================
  group('isAdmin', () {
    test('returns false when not authenticated', () async {
      queries.overrideCurrentUserIsNull = true;
      expect(await ds.isAdmin(), isFalse);
    });

    test('returns true when RPC says true', () async {
      queries.isAdminResponse = true;
      expect(await ds.isAdmin(), isTrue);
      expect(queries.lastIsAdminUserId, 'admin-1');
    });

    test('returns false when RPC returns null', () async {
      queries.isAdminResponse = null;
      expect(await ds.isAdmin(), isFalse);
    });

    test('wraps RPC errors with "Failed to check admin status"', () async {
      queries.throwOnIsAdmin = Exception('boom');
      await expectLater(
        ds.isAdmin(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to check admin status'))),
      );
    });
  });

  // ============================================================
  // getAllUsers
  // ============================================================
  group('getAllUsers', () {
    Map<String, dynamic> userJson(String id) => {
          'id': id,
          'email': '$id@example.com',
          'full_name': 'User $id',
          'role': 'user',
          'status': 'active',
          'created_at': fixedClock.toIso8601String(),
          'updated_at': fixedClock.toIso8601String(),
          'login_count': 0,
          'trips_count': 0,
          'messages_count': 0,
          'expenses_count': 0,
          'total_expenses': 0.0,
        };

    test('passes through default args + maps response', () async {
      queries.getAllUsersResponse = [userJson('u-1'), userJson('u-2')];

      final result = await ds.getAllUsers();

      expect(result, hasLength(2));
      expect(result.first.id, 'u-1');
      expect(queries.lastGetAllUsersLimit, 50);
      expect(queries.lastGetAllUsersOffset, 0);
      expect(queries.lastGetAllUsersSearch, isNull);
      expect(queries.lastGetAllUsersRole, isNull);
      expect(queries.lastGetAllUsersStatus, isNull);
    });

    test('forwards search, role.value and status.value', () async {
      queries.getAllUsersResponse = const <dynamic>[];

      await ds.getAllUsers(
        limit: 10,
        offset: 20,
        search: 'alice',
        role: UserRole.admin,
        status: UserStatus.suspended,
      );

      expect(queries.lastGetAllUsersLimit, 10);
      expect(queries.lastGetAllUsersOffset, 20);
      expect(queries.lastGetAllUsersSearch, 'alice');
      expect(queries.lastGetAllUsersRole, 'admin');
      expect(queries.lastGetAllUsersStatus, 'suspended');
    });

    test('wraps RPC errors with "Failed to get users"', () async {
      queries.throwOnGetAllUsers = Exception('boom');
      await expectLater(
        ds.getAllUsers(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get users'))),
      );
    });
  });

  // ============================================================
  // getUserById
  // ============================================================
  group('getUserById', () {
    Map<String, dynamic> userJson(String id) => {
          'id': id,
          'email': '$id@example.com',
          'full_name': 'User $id',
          'role': 'user',
          'status': 'active',
          'created_at': fixedClock.toIso8601String(),
          'updated_at': fixedClock.toIso8601String(),
          'login_count': 0,
          'trips_count': 0,
          'messages_count': 0,
          'expenses_count': 0,
          'total_expenses': 0.0,
        };

    test('returns matching user from list', () async {
      queries.getAllUsersResponse = [userJson('a'), userJson('b'), userJson('c')];
      final result = await ds.getUserById('b');
      expect(result.id, 'b');
    });

    test('throws "User not found" when no match', () async {
      queries.getAllUsersResponse = [userJson('a')];
      await expectLater(
        ds.getUserById('zzz'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('User not found'))),
      );
    });

    test('wraps query errors', () async {
      queries.throwOnGetAllUsers = Exception('boom');
      await expectLater(
        ds.getUserById('a'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get user'))),
      );
    });
  });

  // ============================================================
  // suspendUser / activateUser / updateUserRole
  // ============================================================
  group('suspendUser', () {
    test('forwards id+reason and returns RPC bool', () async {
      queries.suspendUserResponse = true;
      final result = await ds.suspendUser('u-1', 'spam');
      expect(result, isTrue);
      expect(queries.lastSuspendUserId, 'u-1');
      expect(queries.lastSuspendReason, 'spam');
    });

    test('returns false on null response', () async {
      queries.suspendUserResponse = null;
      expect(await ds.suspendUser('u', 'r'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnSuspendUser = Exception('boom');
      await expectLater(
        ds.suspendUser('u', 'r'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to suspend user'))),
      );
    });
  });

  group('activateUser', () {
    test('forwards id and returns RPC bool', () async {
      queries.activateUserResponse = true;
      expect(await ds.activateUser('u-1'), isTrue);
      expect(queries.lastActivateUserId, 'u-1');
    });

    test('returns false on null response', () async {
      queries.activateUserResponse = null;
      expect(await ds.activateUser('u'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnActivateUser = Exception('boom');
      await expectLater(
        ds.activateUser('u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to activate user'))),
      );
    });
  });

  group('updateUserRole', () {
    test('forwards role.value', () async {
      queries.updateUserRoleResponse = true;
      expect(await ds.updateUserRole('u', UserRole.superAdmin), isTrue);
      expect(queries.lastUpdateRoleUserId, 'u');
      expect(queries.lastUpdateRoleNewRole, 'super_admin');
    });

    test('returns false on null response', () async {
      queries.updateUserRoleResponse = null;
      expect(await ds.updateUserRole('u', UserRole.user), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnUpdateUserRole = Exception('boom');
      await expectLater(
        ds.updateUserRole('u', UserRole.user),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to update user role'))),
      );
    });
  });

  // ============================================================
  // getDashboardStats
  // ============================================================
  group('getDashboardStats', () {
    test('returns parsed model', () async {
      queries.dashboardStatsResponse = {
        'total_users': 100,
        'active_users': 80,
        'suspended_users': 5,
        'admins_count': 3,
        'new_users_today': 2,
        'new_users_week': 10,
        'new_users_month': 50,
        'total_trips': 25,
        'total_messages': 500,
        'active_users_today': 30,
      };
      final result = await ds.getDashboardStats();
      expect(result.totalUsers, 100);
      expect(result.activeUsers, 80);
      expect(queries.dashboardStatsCalled, isTrue);
    });

    test('wraps errors', () async {
      queries.throwOnDashboardStats = Exception('boom');
      await expectLater(
        ds.getDashboardStats(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get dashboard stats'))),
      );
    });
  });

  // ============================================================
  // getActivityLogs
  // ============================================================
  group('getActivityLogs', () {
    Map<String, dynamic> logJson(String id) => {
          'id': id,
          'admin_id': 'admin-1',
          'action_type': 'user_suspended',
          'target_user_id': 'u-1',
          'description': 'desc',
          'metadata': {'k': 'v'},
          'created_at': fixedClock.toIso8601String(),
        };

    test('passes default range and no filters; returns mapped models',
        () async {
      queries.findActivityLogsResponse = [logJson('l-1'), logJson('l-2')];

      final result = await ds.getActivityLogs();

      expect(result, hasLength(2));
      expect(result.first.id, 'l-1');
      expect(queries.lastFindLogsAdminId, isNull);
      expect(queries.lastFindLogsTargetUserId, isNull);
      expect(queries.lastFindLogsOffset, 0);
      expect(queries.lastFindLogsLimit, 50);
    });

    test('forwards adminId and targetUserId filters + custom limit/offset',
        () async {
      queries.findActivityLogsResponse = const [];
      await ds.getActivityLogs(
        limit: 5,
        offset: 100,
        adminId: 'admin-1',
        targetUserId: 'u-9',
      );
      expect(queries.lastFindLogsAdminId, 'admin-1');
      expect(queries.lastFindLogsTargetUserId, 'u-9');
      expect(queries.lastFindLogsOffset, 100);
      expect(queries.lastFindLogsLimit, 5);
    });

    test('wraps errors', () async {
      queries.throwOnFindActivityLogs = Exception('boom');
      await expectLater(
        ds.getActivityLogs(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get activity logs'))),
      );
    });
  });

  // ============================================================
  // updateUserProfile
  // ============================================================
  group('updateUserProfile', () {
    Map<String, dynamic> userJson(String id) => {
          'id': id,
          'email': '$id@example.com',
          'full_name': 'User $id',
          'role': 'user',
          'status': 'active',
          'created_at': fixedClock.toIso8601String(),
          'updated_at': fixedClock.toIso8601String(),
          'login_count': 0,
          'trips_count': 0,
          'messages_count': 0,
          'expenses_count': 0,
          'total_expenses': 0.0,
        };

    test('skips update when no fields provided and refetches user', () async {
      queries.getAllUsersResponse = [userJson('u-1')];

      final result = await ds.updateUserProfile('u-1');

      expect(result.id, 'u-1');
      expect(queries.lastUpdateProfileData, isNull);
    });

    test('updates only provided fields and stamps updated_at from clock',
        () async {
      queries.getAllUsersResponse = [userJson('u-1')];

      await ds.updateUserProfile(
        'u-1',
        fullName: 'New Name',
        avatarUrl: 'http://x/y.png',
      );

      expect(queries.lastUpdateProfileUserId, 'u-1');
      expect(queries.lastUpdateProfileData, {
        'full_name': 'New Name',
        'avatar_url': 'http://x/y.png',
        'updated_at': fixedClock.toIso8601String(),
      });
    });

    test('updates only fullName when avatarUrl missing', () async {
      queries.getAllUsersResponse = [userJson('u-1')];

      await ds.updateUserProfile('u-1', fullName: 'Name Only');

      expect(queries.lastUpdateProfileData, {
        'full_name': 'Name Only',
        'updated_at': fixedClock.toIso8601String(),
      });
    });

    test('wraps update errors', () async {
      queries.throwOnUpdateProfile = Exception('boom');
      await expectLater(
        ds.updateUserProfile('u-1', fullName: 'X'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to update user profile'))),
      );
    });
  });

  // ============================================================
  // getAllTrips
  // ============================================================
  group('getAllTrips', () {
    Map<String, dynamic> tripJson(String id) => {
          'id': id,
          'name': 'Trip $id',
          'destination': 'Goa',
          'created_by': 'creator-1',
          'creator_name': 'Alice',
          'creator_email': 'alice@example.com',
          'is_completed': false,
          'rating': 0.0,
          'currency': 'INR',
          'member_count': 1,
          'total_expenses': 0.0,
          'created_at': fixedClock.toIso8601String(),
          'updated_at': fixedClock.toIso8601String(),
        };

    test('passes default args + maps response', () async {
      queries.getAllTripsResponse = [tripJson('t-1')];
      final result = await ds.getAllTrips();
      expect(result, hasLength(1));
      expect(result.first.id, 't-1');
      expect(queries.lastGetTripsLimit, 50);
      expect(queries.lastGetTripsOffset, 0);
      expect(queries.lastGetTripsSearch, isNull);
      expect(queries.lastGetTripsStatus, isNull);
    });

    test('forwards filters', () async {
      queries.getAllTripsResponse = const <dynamic>[];
      await ds.getAllTrips(
          limit: 11, offset: 22, search: 'goa', status: 'active');
      expect(queries.lastGetTripsLimit, 11);
      expect(queries.lastGetTripsOffset, 22);
      expect(queries.lastGetTripsSearch, 'goa');
      expect(queries.lastGetTripsStatus, 'active');
    });

    test('wraps errors', () async {
      queries.throwOnGetAllTrips = Exception('boom');
      await expectLater(
        ds.getAllTrips(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get trips'))),
      );
    });
  });

  // ============================================================
  // deleteTrip
  // ============================================================
  group('deleteTrip', () {
    test('forwards id and returns bool', () async {
      queries.deleteTripResponse = true;
      expect(await ds.deleteTrip('t-1'), isTrue);
      expect(queries.lastDeleteTripId, 't-1');
    });

    test('returns false on null response', () async {
      queries.deleteTripResponse = null;
      expect(await ds.deleteTrip('t'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnDeleteTrip = Exception('boom');
      await expectLater(
        ds.deleteTrip('t'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to delete trip'))),
      );
    });
  });

  // ============================================================
  // updateTrip
  // ============================================================
  group('updateTrip', () {
    test('forwards all provided fields, ISO-formats dates', () async {
      queries.updateTripResponse = true;
      final start = DateTime.utc(2024, 7, 1);
      final end = DateTime.utc(2024, 7, 8);

      final ok = await ds.updateTrip(
        't-1',
        name: 'New',
        description: 'D',
        destination: 'Bali',
        startDate: start,
        endDate: end,
        budget: 1234.5,
        currency: 'USD',
        isCompleted: true,
      );

      expect(ok, isTrue);
      expect(queries.lastUpdateTripId, 't-1');
      expect(queries.lastUpdateTripName, 'New');
      expect(queries.lastUpdateTripDescription, 'D');
      expect(queries.lastUpdateTripDestination, 'Bali');
      expect(queries.lastUpdateTripStartDate, start.toIso8601String());
      expect(queries.lastUpdateTripEndDate, end.toIso8601String());
      expect(queries.lastUpdateTripBudget, 1234.5);
      expect(queries.lastUpdateTripCurrency, 'USD');
      expect(queries.lastUpdateTripIsCompleted, isTrue);
    });

    test('omits null fields', () async {
      queries.updateTripResponse = true;
      await ds.updateTrip('t-1', name: 'Only Name');
      expect(queries.lastUpdateTripName, 'Only Name');
      expect(queries.lastUpdateTripDescription, isNull);
      expect(queries.lastUpdateTripStartDate, isNull);
      expect(queries.lastUpdateTripBudget, isNull);
    });

    test('returns false when RPC returns null', () async {
      queries.updateTripResponse = null;
      expect(await ds.updateTrip('t-1'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnUpdateTrip = Exception('boom');
      await expectLater(
        ds.updateTrip('t-1'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to update trip'))),
      );
    });
  });

  // ============================================================
  // getAllChecklists
  // ============================================================
  group('getAllChecklists', () {
    Map<String, dynamic> clJson(String id) => {
          'id': id,
          'trip_id': 't-1',
          'trip_name': 'Trip',
          'name': 'CL $id',
          'item_count': 0,
          'completed_count': 0,
          'pending_count': 0,
        };

    test('forwards default + filters and returns mapped list', () async {
      queries.getAllChecklistsResponse = [clJson('c-1')];

      final result = await ds.getAllChecklists(
        limit: 5,
        offset: 10,
        search: 'pack',
        status: 'pending',
        tripId: 't-1',
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'c-1');
      expect(queries.lastGetChecklistsLimit, 5);
      expect(queries.lastGetChecklistsOffset, 10);
      expect(queries.lastGetChecklistsSearch, 'pack');
      expect(queries.lastGetChecklistsStatus, 'pending');
      expect(queries.lastGetChecklistsTripId, 't-1');
    });

    test('omits optional filters when null', () async {
      queries.getAllChecklistsResponse = const <dynamic>[];
      await ds.getAllChecklists();
      expect(queries.lastGetChecklistsSearch, isNull);
      expect(queries.lastGetChecklistsStatus, isNull);
      expect(queries.lastGetChecklistsTripId, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnGetAllChecklists = Exception('boom');
      await expectLater(
        ds.getAllChecklists(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get checklists'))),
      );
    });
  });

  // ============================================================
  // getChecklistStats
  // ============================================================
  group('getChecklistStats', () {
    test('returns parsed model', () async {
      queries.checklistStatsResponse = {
        'total_checklists': 10,
        'total_items': 100,
        'completed_items': 60,
        'pending_items': 40,
        'completion_rate': 60.0,
        'checklists_with_all_completed': 3,
        'empty_checklists': 1,
      };
      final result = await ds.getChecklistStats();
      expect(result.totalChecklists, 10);
      expect(result.completionRate, 60.0);
      expect(queries.checklistStatsCalled, isTrue);
    });

    test('wraps errors', () async {
      queries.throwOnChecklistStats = Exception('boom');
      await expectLater(
        ds.getChecklistStats(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get checklist stats'))),
      );
    });
  });

  // ============================================================
  // deleteChecklist
  // ============================================================
  group('deleteChecklist', () {
    test('forwards id and returns bool', () async {
      queries.deleteChecklistResponse = true;
      expect(await ds.deleteChecklist('c-1'), isTrue);
      expect(queries.lastDeleteChecklistId, 'c-1');
    });

    test('returns false on null response', () async {
      queries.deleteChecklistResponse = null;
      expect(await ds.deleteChecklist('c'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnDeleteChecklist = Exception('boom');
      await expectLater(
        ds.deleteChecklist('c'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to delete checklist'))),
      );
    });
  });

  // ============================================================
  // updateChecklist
  // ============================================================
  group('updateChecklist', () {
    test('forwards id + name', () async {
      queries.updateChecklistResponse = true;
      expect(await ds.updateChecklist('c-1', name: 'New CL'), isTrue);
      expect(queries.lastUpdateChecklistId, 'c-1');
      expect(queries.lastUpdateChecklistName, 'New CL');
    });

    test('omits name when null', () async {
      queries.updateChecklistResponse = true;
      await ds.updateChecklist('c-1');
      expect(queries.lastUpdateChecklistName, isNull);
    });

    test('returns false on null response', () async {
      queries.updateChecklistResponse = null;
      expect(await ds.updateChecklist('c'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnUpdateChecklist = Exception('boom');
      await expectLater(
        ds.updateChecklist('c'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to update checklist'))),
      );
    });
  });

  // ============================================================
  // bulkUpdateChecklistItems
  // ============================================================
  group('bulkUpdateChecklistItems', () {
    test('forwards args and returns int from num response', () async {
      queries.bulkUpdateChecklistResponse = 7;
      final n = await ds.bulkUpdateChecklistItems('c-1', isCompleted: true);
      expect(n, 7);
      expect(queries.lastBulkUpdateChecklistId, 'c-1');
      expect(queries.lastBulkUpdateChecklistIsCompleted, isTrue);
    });

    test('returns 0 on null response', () async {
      queries.bulkUpdateChecklistResponse = null;
      expect(
        await ds.bulkUpdateChecklistItems('c', isCompleted: false),
        0,
      );
    });

    test('wraps errors', () async {
      queries.throwOnBulkUpdateChecklist = Exception('boom');
      await expectLater(
        ds.bulkUpdateChecklistItems('c', isCompleted: false),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to bulk update checklist items'))),
      );
    });
  });

  // ============================================================
  // getAllExpenses
  // ============================================================
  group('getAllExpenses', () {
    Map<String, dynamic> expenseJson(String id) => {
          'id': id,
          'title': 'Title $id',
          'amount': 100.0,
          'currency': 'INR',
          'paid_by': 'p-1',
          'split_type': 'equal',
          'created_at': fixedClock.toIso8601String(),
          'split_count': 0,
          'settled_count': 0,
          'pending_amount': 0.0,
        };

    test('forwards default + filters and returns mapped list', () async {
      queries.getAllExpensesResponse = [expenseJson('e-1')];

      final result = await ds.getAllExpenses(
        limit: 7,
        offset: 14,
        search: 'food',
        category: 'food',
        tripId: 't-1',
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'e-1');
      expect(queries.lastGetExpensesLimit, 7);
      expect(queries.lastGetExpensesOffset, 14);
      expect(queries.lastGetExpensesSearch, 'food');
      expect(queries.lastGetExpensesCategory, 'food');
      expect(queries.lastGetExpensesTripId, 't-1');
    });

    test('omits optional filters when null', () async {
      queries.getAllExpensesResponse = const <dynamic>[];
      await ds.getAllExpenses();
      expect(queries.lastGetExpensesSearch, isNull);
      expect(queries.lastGetExpensesCategory, isNull);
      expect(queries.lastGetExpensesTripId, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnGetAllExpenses = Exception('boom');
      await expectLater(
        ds.getAllExpenses(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get expenses'))),
      );
    });
  });

  // ============================================================
  // getExpenseStats
  // ============================================================
  group('getExpenseStats', () {
    test('returns parsed model', () async {
      queries.expenseStatsResponse = {
        'total_expenses': 5,
        'total_amount': 500.0,
        'total_settled': 200.0,
        'total_pending': 300.0,
        'settlement_rate': 40.0,
        'expenses_with_receipts': 2,
        'standalone_expenses': 1,
        'trip_expenses': 4,
        'category_breakdown': {'food': 3, 'transport': 2},
      };
      final result = await ds.getExpenseStats();
      expect(result.totalExpenses, 5);
      expect(result.categoryBreakdown, {'food': 3, 'transport': 2});
      expect(queries.expenseStatsCalled, isTrue);
    });

    test('wraps errors', () async {
      queries.throwOnExpenseStats = Exception('boom');
      await expectLater(
        ds.getExpenseStats(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to get expense stats'))),
      );
    });
  });

  // ============================================================
  // deleteExpense
  // ============================================================
  group('deleteExpense', () {
    test('forwards id and returns bool', () async {
      queries.deleteExpenseResponse = true;
      expect(await ds.deleteExpense('e-1'), isTrue);
      expect(queries.lastDeleteExpenseId, 'e-1');
    });

    test('returns false on null response', () async {
      queries.deleteExpenseResponse = null;
      expect(await ds.deleteExpense('e'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnDeleteExpense = Exception('boom');
      await expectLater(
        ds.deleteExpense('e'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to delete expense'))),
      );
    });
  });

  // ============================================================
  // updateExpense
  // ============================================================
  group('updateExpense', () {
    test('forwards all fields when provided', () async {
      queries.updateExpenseResponse = true;
      final ok = await ds.updateExpense(
        'e-1',
        title: 'T',
        description: 'D',
        amount: 99.5,
        currency: 'USD',
        category: 'food',
      );
      expect(ok, isTrue);
      expect(queries.lastUpdateExpenseId, 'e-1');
      expect(queries.lastUpdateExpenseTitle, 'T');
      expect(queries.lastUpdateExpenseDescription, 'D');
      expect(queries.lastUpdateExpenseAmount, 99.5);
      expect(queries.lastUpdateExpenseCurrency, 'USD');
      expect(queries.lastUpdateExpenseCategory, 'food');
    });

    test('omits null fields', () async {
      queries.updateExpenseResponse = true;
      await ds.updateExpense('e-1', title: 'Only');
      expect(queries.lastUpdateExpenseTitle, 'Only');
      expect(queries.lastUpdateExpenseAmount, isNull);
      expect(queries.lastUpdateExpenseCurrency, isNull);
    });

    test('returns false on null response', () async {
      queries.updateExpenseResponse = null;
      expect(await ds.updateExpense('e'), isFalse);
    });

    test('wraps errors', () async {
      queries.throwOnUpdateExpense = Exception('boom');
      await expectLater(
        ds.updateExpense('e'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to update expense'))),
      );
    });
  });

  // ============================================================
  // settleExpenseSplits / unsettleExpenseSplits
  // ============================================================
  group('settleExpenseSplits', () {
    test('forwards id and returns int', () async {
      queries.settleExpenseResponse = 4;
      expect(await ds.settleExpenseSplits('e-1'), 4);
      expect(queries.lastSettleExpenseId, 'e-1');
    });

    test('returns 0 on null response', () async {
      queries.settleExpenseResponse = null;
      expect(await ds.settleExpenseSplits('e'), 0);
    });

    test('wraps errors', () async {
      queries.throwOnSettleExpense = Exception('boom');
      await expectLater(
        ds.settleExpenseSplits('e'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to settle expense splits'))),
      );
    });
  });

  group('unsettleExpenseSplits', () {
    test('forwards id and returns int', () async {
      queries.unsettleExpenseResponse = 2;
      expect(await ds.unsettleExpenseSplits('e-1'), 2);
      expect(queries.lastUnsettleExpenseId, 'e-1');
    });

    test('returns 0 on null response', () async {
      queries.unsettleExpenseResponse = null;
      expect(await ds.unsettleExpenseSplits('e'), 0);
    });

    test('wraps errors', () async {
      queries.throwOnUnsettleExpense = Exception('boom');
      await expectLater(
        ds.unsettleExpenseSplits('e'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Failed to unsettle expense splits'))),
      );
    });
  });

  // ============================================================
  // Default constructor (no queries injected)
  // ============================================================
  group('Default constructor', () {
    test('uses AdminQueriesImpl when no queries argument given', () {
      // This proves the no-arg path doesn't throw at construction time;
      // production behaviour is verified via integration tests.
      final fallback = AdminRemoteDataSource(_FakeSupabase());
      expect(fallback, isA<AdminRemoteDataSource>());
    });
  });
}
