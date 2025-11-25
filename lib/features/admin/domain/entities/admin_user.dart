import 'package:equatable/equatable.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

/// Admin User Entity
/// Extended user information for admin management
class AdminUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final DateTime? accountLockedAt;
  final String? accountLockedReason;
  final int loginCount;
  final int tripsCount;
  final int messagesCount;
  final int expensesCount;
  final double totalExpenses;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.lastActiveAt,
    this.accountLockedAt,
    this.accountLockedReason,
    required this.loginCount,
    required this.tripsCount,
    required this.messagesCount,
    required this.expensesCount,
    required this.totalExpenses,
  });

  /// Check if user is admin
  bool get isAdmin => role.isAdmin;

  /// Check if user can manage other admins
  bool get canManageAdmins => role.canManageAdmins;

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Check if user is suspended
  bool get isSuspended => status == UserStatus.suspended;

  /// Check if user account is locked
  bool get isLocked => accountLockedAt != null;

  /// Get initials from full name
  String get initials {
    final names = fullName.trim().split(' ').where((name) => name.isNotEmpty).toList();
    if (names.isEmpty) return '?';
    if (names.length == 1) {
      return names[0].isEmpty ? '?' : names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  /// Get display name (full name or email)
  String get displayName {
    return fullName.isNotEmpty ? fullName : email.split('@')[0];
  }

  /// Get activity level based on login/active timestamps
  String get activityLevel {
    if (lastActiveAt == null) return 'Never Active';

    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);

    if (difference.inDays == 0) return 'Active Today';
    if (difference.inDays == 1) return 'Active Yesterday';
    if (difference.inDays <= 7) return 'Active This Week';
    if (difference.inDays <= 30) return 'Active This Month';

    return 'Inactive';
  }

  /// Copy with method
  AdminUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    DateTime? accountLockedAt,
    String? accountLockedReason,
    int? loginCount,
    int? tripsCount,
    int? messagesCount,
    int? expensesCount,
    double? totalExpenses,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      accountLockedAt: accountLockedAt ?? this.accountLockedAt,
      accountLockedReason: accountLockedReason ?? this.accountLockedReason,
      loginCount: loginCount ?? this.loginCount,
      tripsCount: tripsCount ?? this.tripsCount,
      messagesCount: messagesCount ?? this.messagesCount,
      expensesCount: expensesCount ?? this.expensesCount,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        role,
        status,
        createdAt,
        updatedAt,
        lastLoginAt,
        lastActiveAt,
        accountLockedAt,
        accountLockedReason,
        loginCount,
        tripsCount,
        messagesCount,
        expensesCount,
        totalExpenses,
      ];
}
