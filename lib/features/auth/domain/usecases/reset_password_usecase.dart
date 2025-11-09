import '../repositories/auth_repository.dart';

/// Use case for resetting user password via email
class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  /// Sends a password reset email to the specified email address
  ///
  /// Throws [Exception] if:
  /// - Email format is invalid
  /// - Email is not registered
  /// - Network error occurs
  Future<void> call(String email) async {
    // Validate email format
    if (email.trim().isEmpty) {
      throw Exception('Email cannot be empty');
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw Exception('Invalid email format');
    }

    // Call repository to send reset email
    await _repository.resetPassword(email.trim());
  }
}
