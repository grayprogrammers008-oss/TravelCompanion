import '../repositories/auth_repository.dart';

/// Use case for changing user password
class ChangePasswordUseCase {
  final AuthRepository _repository;

  ChangePasswordUseCase(this._repository);

  /// Execute password change
  ///
  /// This use case validates both the current and new passwords before
  /// delegating to the repository. The repository will verify the current
  /// password through re-authentication.
  ///
  /// Parameters:
  /// - [currentPassword]: Current password to verify
  /// - [newPassword]: New password to set
  ///
  /// Validation Rules:
  /// - Current password: Required (not empty)
  /// - New password: Required (not empty)
  /// - New password: Minimum 6 characters
  /// - New password: Must be different from current password
  /// - New password: Must contain uppercase, lowercase, and number
  ///
  /// Throws [Exception] if validation fails or password change fails
  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Validate current password
    if (currentPassword.isEmpty) {
      throw Exception('Current password is required');
    }

    // Validate new password
    if (newPassword.isEmpty) {
      throw Exception('New password is required');
    }

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters');
    }

    // Ensure new password is different from current
    if (newPassword == currentPassword) {
      throw Exception('New password must be different from current password');
    }

    // Validate password strength
    if (!_isPasswordStrong(newPassword)) {
      throw Exception(
        'Password must contain at least one uppercase letter, one lowercase letter, and one number',
      );
    }

    // Delegate to repository which will verify current password
    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Check if password meets strength requirements
  ///
  /// Requirements:
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one digit (0-9)
  bool _isPasswordStrong(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return hasUppercase && hasLowercase && hasNumber;
  }
}
