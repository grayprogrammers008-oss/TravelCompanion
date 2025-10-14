import '../repositories/auth_repository.dart';

/// Use case for user sign out
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Execute sign out
  Future<void> call() async {
    await _repository.signOut();
  }
}
