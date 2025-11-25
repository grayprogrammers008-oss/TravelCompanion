import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';

/// Use Case: Activate User
/// Activates a suspended user account (admin only)
class ActivateUserUseCase {
  final AdminRepository _repository;

  ActivateUserUseCase(this._repository);

  Future<bool> call(String userId) async {
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    return await _repository.activateUser(userId);
  }
}
