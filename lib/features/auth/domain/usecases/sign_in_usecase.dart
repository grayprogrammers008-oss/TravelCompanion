import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for user sign in
class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  /// Execute sign in
  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    // Validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    // Execute sign in
    return await _repository.signIn(email: email, password: password);
  }
}
