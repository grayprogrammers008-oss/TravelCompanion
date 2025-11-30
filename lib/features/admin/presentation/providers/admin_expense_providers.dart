import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_expense.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

export 'package:travel_crew/features/admin/domain/entities/admin_expense.dart';

/// Admin expenses provider - fetches expenses with filtering
final adminExpensesProvider =
    FutureProvider.family<List<AdminExpenseModel>, ExpenseListParams>(
  (ref, params) async {
    final dataSource = ref.watch(adminRemoteDataSourceProvider);

    return await dataSource.getAllExpenses(
      limit: params.limit,
      offset: params.offset,
      search: params.search,
      category: params.category,
      tripId: params.tripId,
    );
  },
);

/// Admin expense stats provider
final adminExpenseStatsProvider =
    FutureProvider<AdminExpenseStatsModel>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return await dataSource.getExpenseStats();
});

/// Admin expense repository provider (uses existing data source)
final adminExpenseRepositoryProvider = Provider((ref) {
  return ref.watch(adminRemoteDataSourceProvider);
});
