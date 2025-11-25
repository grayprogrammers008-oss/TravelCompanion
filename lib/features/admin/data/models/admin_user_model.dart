import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

/// Admin User Model
/// Maps database JSON to domain entity
class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.avatarUrl,
    required super.role,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.lastLoginAt,
    super.lastActiveAt,
    super.accountLockedAt,
    super.accountLockedReason,
    required super.loginCount,
    required super.tripsCount,
    required super.messagesCount,
    required super.expensesCount,
    required super.totalExpenses,
  });

  /// Create from JSON (Supabase response)
  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'user'),
      status: UserStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      accountLockedAt: json['account_locked_at'] != null
          ? DateTime.parse(json['account_locked_at'] as String)
          : null,
      accountLockedReason: json['account_locked_reason'] as String?,
      loginCount: json['login_count'] as int? ?? 0,
      tripsCount: (json['trips_count'] as num?)?.toInt() ?? 0,
      messagesCount: (json['messages_count'] as num?)?.toInt() ?? 0,
      expensesCount: (json['expenses_count'] as num?)?.toInt() ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'account_locked_at': accountLockedAt?.toIso8601String(),
      'account_locked_reason': accountLockedReason,
      'login_count': loginCount,
      'trips_count': tripsCount,
      'messages_count': messagesCount,
      'expenses_count': expensesCount,
      'total_expenses': totalExpenses,
    };
  }

  /// Convert to domain entity
  AdminUser toEntity() {
    return AdminUser(
      id: id,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      role: role,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      lastActiveAt: lastActiveAt,
      accountLockedAt: accountLockedAt,
      accountLockedReason: accountLockedReason,
      loginCount: loginCount,
      tripsCount: tripsCount,
      messagesCount: messagesCount,
      expensesCount: expensesCount,
      totalExpenses: totalExpenses,
    );
  }

  /// Create from domain entity
  factory AdminUserModel.fromEntity(AdminUser user) {
    return AdminUserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      avatarUrl: user.avatarUrl,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      lastLoginAt: user.lastLoginAt,
      lastActiveAt: user.lastActiveAt,
      accountLockedAt: user.accountLockedAt,
      accountLockedReason: user.accountLockedReason,
      loginCount: user.loginCount,
      tripsCount: user.tripsCount,
      messagesCount: user.messagesCount,
      expensesCount: user.expensesCount,
      totalExpenses: user.totalExpenses,
    );
  }
}
