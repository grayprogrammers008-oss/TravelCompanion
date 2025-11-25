/// User role enumeration
/// Maps to the database enum: user_role
enum UserRole {
  user('user'),
  admin('admin'),
  superAdmin('super_admin');

  final String value;
  const UserRole(this.value);

  /// Parse from string value
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Check if role has admin privileges
  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;

  /// Check if role can manage other admins
  bool get canManageAdmins => this == UserRole.superAdmin;
}
