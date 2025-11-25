import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';

/// Use Case: Update User Role
/// Updates a user's role (super_admin only)
class UpdateUserRoleUseCase {
  final AdminRepository _repository;

  UpdateUserRoleUseCase(this._repository);

  Future<bool> call(String userId, UserRole newRole) async {
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    return await _repository.updateUserRole(userId, newRole);
  }
}
