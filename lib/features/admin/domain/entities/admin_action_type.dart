/// Admin action type enumeration
/// Maps to the database enum: admin_action_type
enum AdminActionType {
  userCreated('user_created'),
  userUpdated('user_updated'),
  userSuspended('user_suspended'),
  userActivated('user_activated'),
  userDeleted('user_deleted'),
  roleChanged('role_changed'),
  passwordReset('password_reset'),
  profileUpdated('profile_updated');

  final String value;
  const AdminActionType(this.value);

  /// Parse from string value
  static AdminActionType fromString(String value) {
    return AdminActionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdminActionType.userUpdated,
    );
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case AdminActionType.userCreated:
        return 'User Created';
      case AdminActionType.userUpdated:
        return 'User Updated';
      case AdminActionType.userSuspended:
        return 'User Suspended';
      case AdminActionType.userActivated:
        return 'User Activated';
      case AdminActionType.userDeleted:
        return 'User Deleted';
      case AdminActionType.roleChanged:
        return 'Role Changed';
      case AdminActionType.passwordReset:
        return 'Password Reset';
      case AdminActionType.profileUpdated:
        return 'Profile Updated';
    }
  }

  /// Get icon for action type
  String get icon {
    switch (this) {
      case AdminActionType.userCreated:
        return '➕';
      case AdminActionType.userUpdated:
        return '✏️';
      case AdminActionType.userSuspended:
        return '⏸️';
      case AdminActionType.userActivated:
        return '▶️';
      case AdminActionType.userDeleted:
        return '🗑️';
      case AdminActionType.roleChanged:
        return '👤';
      case AdminActionType.passwordReset:
        return '🔑';
      case AdminActionType.profileUpdated:
        return '📝';
    }
  }
}
