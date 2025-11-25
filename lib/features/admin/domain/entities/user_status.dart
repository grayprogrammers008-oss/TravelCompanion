/// User account status enumeration
/// Maps to the database enum: user_status
enum UserStatus {
  active('active'),
  suspended('suspended'),
  deleted('deleted');

  final String value;
  const UserStatus(this.value);

  /// Parse from string value
  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.active,
    );
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }

  /// Get color for status indicator
  String get colorHex {
    switch (this) {
      case UserStatus.active:
        return '#22C55E'; // Green
      case UserStatus.suspended:
        return '#F59E0B'; // Amber
      case UserStatus.deleted:
        return '#EF4444'; // Red
    }
  }

  /// Check if user can perform actions
  bool get canPerformActions => this == UserStatus.active;
}
