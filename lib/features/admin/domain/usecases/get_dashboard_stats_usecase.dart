import 'package:pathio/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:pathio/features/admin/domain/repositories/admin_repository.dart';

/// Use Case: Get Dashboard Statistics
/// Retrieves admin dashboard statistics (admin only)
class GetDashboardStatsUseCase {
  final AdminRepository _repository;

  GetDashboardStatsUseCase(this._repository);

  Future<AdminDashboardStats> call() async {
    return await _repository.getDashboardStats();
  }
}
