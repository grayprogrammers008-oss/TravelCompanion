import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/data/models/admin_activity_log_model.dart';
import 'package:travel_crew/features/admin/data/models/admin_dashboard_stats_model.dart';
import 'package:travel_crew/features/admin/data/models/admin_user_model.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_action_type.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

class _StubSupabaseClient extends Mock implements SupabaseClient {}

/// Hand-rolled fake datasource that records calls and returns canned responses.
class _FakeAdminDataSource extends AdminRemoteDataSource {
  _FakeAdminDataSource() : super(_StubSupabaseClient());

  bool isAdminResult = true;
  Object? isAdminError;

  List<AdminUserModel> usersToReturn = const [];
  Object? getAllUsersError;
  final List<Map<String, dynamic>> getAllUsersCalls = [];

  AdminDashboardStatsModel? statsToReturn;
  Object? statsError;
  int statsCalls = 0;

  List<AdminActivityLogModel> logsToReturn = const [];
  Object? logsError;
  final List<Map<String, dynamic>> logsCalls = [];

  bool suspendResult = true;
  bool activateResult = true;
  bool roleResult = true;
  final List<Map<String, dynamic>> suspendCalls = [];
  final List<String> activateCalls = [];
  final List<Map<String, dynamic>> roleCalls = [];

  @override
  Future<bool> isAdmin() async {
    if (isAdminError != null) throw isAdminError!;
    return isAdminResult;
  }

  @override
  Future<List<AdminUserModel>> getAllUsers({
    int limit = 50,
    int offset = 0,
    String? search,
    UserRole? role,
    UserStatus? status,
  }) async {
    getAllUsersCalls.add({
      'limit': limit,
      'offset': offset,
      'search': search,
      'role': role,
      'status': status,
    });
    if (getAllUsersError != null) throw getAllUsersError!;
    return usersToReturn;
  }

  @override
  Future<AdminDashboardStatsModel> getDashboardStats() async {
    statsCalls++;
    if (statsError != null) throw statsError!;
    return statsToReturn ??
        const AdminDashboardStatsModel(
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
  }

  @override
  Future<List<AdminActivityLogModel>> getActivityLogs({
    int limit = 50,
    int offset = 0,
    String? adminId,
    String? targetUserId,
  }) async {
    logsCalls.add({
      'limit': limit,
      'offset': offset,
      'adminId': adminId,
      'targetUserId': targetUserId,
    });
    if (logsError != null) throw logsError!;
    return logsToReturn;
  }

  @override
  Future<bool> suspendUser(String userId, String reason) async {
    suspendCalls.add({'userId': userId, 'reason': reason});
    return suspendResult;
  }

  @override
  Future<bool> activateUser(String userId) async {
    activateCalls.add(userId);
    return activateResult;
  }

  @override
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    roleCalls.add({'userId': userId, 'role': newRole});
    return roleResult;
  }
}

AdminUserModel _user(String id, {UserRole role = UserRole.user}) {
  final dt = DateTime(2024, 1, 1);
  return AdminUserModel(
    id: id,
    email: '$id@example.com',
    fullName: 'User $id',
    role: role,
    status: UserStatus.active,
    createdAt: dt,
    updatedAt: dt,
    loginCount: 0,
    tripsCount: 0,
    messagesCount: 0,
    expensesCount: 0,
    totalExpenses: 0,
  );
}

void main() {
  group('admin_providers', () {
    late _FakeAdminDataSource fake;
    late ProviderContainer container;

    setUp(() {
      fake = _FakeAdminDataSource();
      container = ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(_StubSupabaseClient()),
        adminRemoteDataSourceProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    group('isAdminProvider', () {
      test('returns true when datasource says user is admin', () async {
        fake.isAdminResult = true;
        final result = await container.read(isAdminProvider.future);
        expect(result, true);
      });

      test('returns false when datasource says user is not admin', () async {
        fake.isAdminResult = false;
        final result = await container.read(isAdminProvider.future);
        expect(result, false);
      });

      test('exposes error state from datasource', () async {
        fake.isAdminError = Exception('boom');
        // Trigger the read; await unhandled to allow capture without throwing.
        // ignore: unawaited_futures
        container.read(isAdminProvider.future).catchError((_) => false);
        // Pump microtasks so the future resolves.
        await Future<void>.delayed(Duration.zero);
        final state = container.read(isAdminProvider);
        expect(state.hasError, true);
      });
    });

    group('adminDashboardStatsProvider', () {
      test('returns stats from datasource', () async {
        fake.statsToReturn = const AdminDashboardStatsModel(
          totalUsers: 50,
          activeUsers: 40,
          suspendedUsers: 5,
          adminsCount: 2,
          newUsersToday: 1,
          newUsersWeek: 5,
          newUsersMonth: 15,
          totalTrips: 25,
          totalMessages: 200,
          activeUsersToday: 10,
        );
        final stats = await container.read(adminDashboardStatsProvider.future);
        expect(stats.totalUsers, 50);
        expect(stats.activeUsers, 40);
        expect(stats.activeUserPercentage, 80.0);
      });

      test('exposes error state on failure', () async {
        fake.statsError = Exception('stats failed');
        // ignore: unawaited_futures
        container.read(adminDashboardStatsProvider.future).catchError((_) =>
            const AdminDashboardStatsModel(
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
            ));
        await Future<void>.delayed(Duration.zero);
        final state = container.read(adminDashboardStatsProvider);
        expect(state.hasError, true);
      });
    });

    group('adminUsersProvider (family)', () {
      test('returns users for default params', () async {
        fake.usersToReturn = [_user('a'), _user('b')];
        final users =
            await container.read(adminUsersProvider(const UserListParams()).future);
        expect(users, hasLength(2));
        expect(users.first, isA<AdminUser>());
        expect(fake.getAllUsersCalls.single['limit'], 50);
        expect(fake.getAllUsersCalls.single['offset'], 0);
      });

      test('passes filter params through to datasource', () async {
        fake.usersToReturn = [_user('a', role: UserRole.admin)];
        const params = UserListParams(
          limit: 10,
          offset: 20,
          search: 'foo',
          role: UserRole.admin,
          status: UserStatus.suspended,
        );
        await container.read(adminUsersProvider(params).future);
        final call = fake.getAllUsersCalls.single;
        expect(call['limit'], 10);
        expect(call['offset'], 20);
        expect(call['search'], 'foo');
        expect(call['role'], UserRole.admin);
        expect(call['status'], UserStatus.suspended);
      });

      test('returns empty list when datasource returns empty', () async {
        fake.usersToReturn = [];
        final users = await container
            .read(adminUsersProvider(const UserListParams()).future);
        expect(users, isEmpty);
      });
    });

    group('adminActivityLogsProvider (family)', () {
      test('returns logs for default params', () async {
        fake.logsToReturn = [
          AdminActivityLogModel(
            id: 'l1',
            adminId: 'a1',
            actionType: AdminActionType.userCreated,
            description: 'Created',
            metadata: const {},
            createdAt: DateTime(2024, 1, 1),
          ),
        ];
        final logs = await container
            .read(adminActivityLogsProvider(const ActivityLogParams()).future);
        expect(logs, hasLength(1));
        expect(logs.first.id, 'l1');
      });

      test('passes filter params through', () async {
        fake.logsToReturn = const [];
        const params = ActivityLogParams(
          limit: 5,
          offset: 10,
          adminId: 'admin-1',
          targetUserId: 'user-2',
        );
        await container.read(adminActivityLogsProvider(params).future);
        final call = fake.logsCalls.single;
        expect(call['limit'], 5);
        expect(call['offset'], 10);
        expect(call['adminId'], 'admin-1');
        expect(call['targetUserId'], 'user-2');
      });
    });

    group('action providers', () {
      test('suspendUserActionProvider invokes datasource and invalidates lists',
          () async {
        fake.usersToReturn = [_user('a')];
        // Prime users provider
        await container.read(adminUsersProvider(const UserListParams()).future);
        final initialCallCount = fake.getAllUsersCalls.length;

        final action = container.read(suspendUserActionProvider);
        final result = await action('user-1', 'Violating ToS');

        expect(result, true);
        expect(fake.suspendCalls.single['userId'], 'user-1');
        expect(fake.suspendCalls.single['reason'], 'Violating ToS');

        // Re-read to confirm provider was invalidated and refetches.
        await container.read(adminUsersProvider(const UserListParams()).future);
        expect(fake.getAllUsersCalls.length, greaterThan(initialCallCount));
      });

      test('activateUserActionProvider calls datasource', () async {
        final action = container.read(activateUserActionProvider);
        final result = await action('user-2');
        expect(result, true);
        expect(fake.activateCalls.single, 'user-2');
      });

      test('updateUserRoleActionProvider calls datasource with role', () async {
        final action = container.read(updateUserRoleActionProvider);
        final result = await action('user-3', UserRole.admin);
        expect(result, true);
        expect(fake.roleCalls.single['userId'], 'user-3');
        expect(fake.roleCalls.single['role'], UserRole.admin);
      });

      test('suspendUserActionProvider returns false when datasource fails',
          () async {
        fake.suspendResult = false;
        final action = container.read(suspendUserActionProvider);
        final result = await action('user-1', 'reason');
        expect(result, false);
      });
    });
  });

  group('UserListParams', () {
    test('defaults', () {
      const params = UserListParams();
      expect(params.limit, 50);
      expect(params.offset, 0);
      expect(params.search, isNull);
      expect(params.role, isNull);
      expect(params.status, isNull);
    });

    test('equality with same fields', () {
      const a = UserListParams(limit: 10, search: 's', role: UserRole.admin);
      const b = UserListParams(limit: 10, search: 's', role: UserRole.admin);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on field change', () {
      const a = UserListParams(limit: 10);
      const b = UserListParams(limit: 20);
      expect(a, isNot(equals(b)));
    });

    test('identical operator', () {
      const a = UserListParams();
      // ignore: unrelated_type_equality_checks
      expect(a == a, true);
    });
  });

  group('ActivityLogParams', () {
    test('defaults', () {
      const params = ActivityLogParams();
      expect(params.limit, 50);
      expect(params.offset, 0);
      expect(params.adminId, isNull);
      expect(params.targetUserId, isNull);
    });

    test('equality', () {
      const a = ActivityLogParams(limit: 5, adminId: 'a');
      const b = ActivityLogParams(limit: 5, adminId: 'a');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on different adminId', () {
      const a = ActivityLogParams(adminId: 'x');
      const b = ActivityLogParams(adminId: 'y');
      expect(a, isNot(equals(b)));
    });
  });
}
