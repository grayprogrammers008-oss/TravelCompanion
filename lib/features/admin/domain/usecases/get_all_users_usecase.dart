import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';

/// Use Case: Get All Users
/// Retrieves all users with statistics (admin only)
class GetAllUsersUseCase {
  final AdminRepository _repository;

  GetAllUsersUseCase(this._repository);

  Future<List<AdminUser>> call({
    int limit = 50,
    int offset = 0,
    String? search,
    UserRole? role,
    UserStatus? status,
  }) async {
    return await _repository.getAllUsers(
      limit: limit,
      offset: offset,
      search: search,
      role: role,
      status: status,
    );
  }
}
