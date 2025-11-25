import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';

/// Use Case: Suspend User
/// Suspends a user account (admin only)
class SuspendUserUseCase {
  final AdminRepository _repository;

  SuspendUserUseCase(this._repository);

  Future<bool> call(String userId, String reason) async {
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    if (reason.isEmpty) {
      throw Exception('Reason for suspension cannot be empty');
    }

    return await _repository.suspendUser(userId, reason);
  }
}
