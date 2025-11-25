import 'package:travel_crew/features/admin/domain/repositories/admin_repository.dart';

/// Use Case: Check if User is Admin
/// Verifies if the current user has admin privileges
class IsAdminUseCase {
  final AdminRepository _repository;

  IsAdminUseCase(this._repository);

  Future<bool> call() async {
    return await _repository.isAdmin();
  }
}
