import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user sign up
class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  /// Execute sign up
  Future<UserEntity> call({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    // Validation
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      throw Exception('Email, password, and full name are required');
    }

    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }

    // Execute sign up
    return await _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}
