import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_activity_log.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';
import 'package:travel_crew/features/admin/domain/usecases/activate_user_usecase.dart';
import 'package:travel_crew/features/admin/domain/usecases/get_all_users_usecase.dart';
import 'package:travel_crew/features/admin/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:travel_crew/features/admin/domain/usecases/is_admin_usecase.dart';
import 'package:travel_crew/features/admin/domain/usecases/suspend_user_usecase.dart';
import 'package:travel_crew/features/admin/domain/usecases/update_user_role_usecase.dart';

// ============================================================================
// DATA SOURCE PROVIDERS
// ============================================================================

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return AdminRepositoryImpl(dataSource);
});

// ============================================================================
// USE CASE PROVIDERS
// ============================================================================

final isAdminUseCaseProvider = Provider<IsAdminUseCase>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return IsAdminUseCase(repository);
});

final getAllUsersUseCaseProvider = Provider<GetAllUsersUseCase>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetAllUsersUseCase(repository);
});

final getDashboardStatsUseCaseProvider = Provider<GetDashboardStatsUseCase>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return GetDashboardStatsUseCase(repository);
});

final suspendUserUseCaseProvider = Provider<SuspendUserUseCase>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return SuspendUserUseCase(repository);
});

final activateUserUseCaseProvider = Provider<ActivateUserUseCase>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return ActivateUserUseCase(repository);
});

final updateUserRoleUseCaseProvider = Provider<UpdateUserRoleUseCase>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return UpdateUserRoleUseCase(repository);
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final useCase = ref.watch(isAdminUseCaseProvider);
  return await useCase();
});

/// Get admin dashboard statistics
final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final useCase = ref.watch(getDashboardStatsUseCaseProvider);
  return await useCase();
});

/// Parameters for user list query
class UserListParams {
  final int limit;
  final int offset;
  final String? search;
  final UserRole? role;
  final UserStatus? status;

  const UserListParams({
    this.limit = 50,
    this.offset = 0,
    this.search,
    this.role,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserListParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset &&
          search == other.search &&
          role == other.role &&
          status == other.status;

  @override
  int get hashCode =>
      limit.hashCode ^
      offset.hashCode ^
      (search?.hashCode ?? 0) ^
      (role?.hashCode ?? 0) ^
      (status?.hashCode ?? 0);
}

/// Get all users with filters
final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, UserListParams>((ref, params) async {
  final useCase = ref.watch(getAllUsersUseCaseProvider);

  return await useCase(
    limit: params.limit,
    offset: params.offset,
    search: params.search,
    role: params.role,
    status: params.status,
  );
});

/// Parameters for activity log query
class ActivityLogParams {
  final int limit;
  final int offset;
  final String? adminId;
  final String? targetUserId;

  const ActivityLogParams({
    this.limit = 50,
    this.offset = 0,
    this.adminId,
    this.targetUserId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset &&
          adminId == other.adminId &&
          targetUserId == other.targetUserId;

  @override
  int get hashCode =>
      limit.hashCode ^
      offset.hashCode ^
      (adminId?.hashCode ?? 0) ^
      (targetUserId?.hashCode ?? 0);
}

/// Get admin activity logs with filters
final adminActivityLogsProvider =
    FutureProvider.family<List<AdminActivityLog>, ActivityLogParams>(
        (ref, params) async {
  final repository = ref.watch(adminRepositoryProvider);

  return await repository.getActivityLogs(
    limit: params.limit,
    offset: params.offset,
    adminId: params.adminId,
    targetUserId: params.targetUserId,
  );
});

// ============================================================================
// ACTIONS
// ============================================================================

/// Suspend user action
final suspendUserActionProvider = Provider<Future<bool> Function(String, String)>((ref) {
  return (userId, reason) async {
    final useCase = ref.read(suspendUserUseCaseProvider);
    final result = await useCase(userId, reason);

    // Invalidate user list to refresh
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminDashboardStatsProvider);

    return result;
  };
});

/// Activate user action
final activateUserActionProvider = Provider<Future<bool> Function(String)>((ref) {
  return (userId) async {
    final useCase = ref.read(activateUserUseCaseProvider);
    final result = await useCase(userId);

    // Invalidate user list to refresh
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminDashboardStatsProvider);

    return result;
  };
});

/// Update user role action
final updateUserRoleActionProvider = Provider<Future<bool> Function(String, UserRole)>((ref) {
  return (userId, newRole) async {
    final useCase = ref.read(updateUserRoleUseCaseProvider);
    final result = await useCase(userId, newRole);

    // Invalidate user list to refresh
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminDashboardStatsProvider);

    return result;
  };
});
