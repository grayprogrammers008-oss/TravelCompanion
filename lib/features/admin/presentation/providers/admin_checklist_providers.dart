import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_checklist.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

export 'package:travel_crew/features/admin/domain/entities/admin_checklist.dart';

/// Admin checklists provider - fetches checklists with filtering
final adminChecklistsProvider =
    FutureProvider.family<List<AdminChecklistModel>, ChecklistListParams>(
  (ref, params) async {
    final dataSource = ref.watch(adminRemoteDataSourceProvider);

    return await dataSource.getAllChecklists(
      limit: params.limit,
      offset: params.offset,
      search: params.search,
      status: params.status,
      tripId: params.tripId,
    );
  },
);

/// Admin checklist stats provider
final adminChecklistStatsProvider =
    FutureProvider<AdminChecklistStatsModel>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return await dataSource.getChecklistStats();
});

/// Admin checklist repository provider (uses existing data source)
final adminChecklistRepositoryProvider = Provider((ref) {
  return ref.watch(adminRemoteDataSourceProvider);
});
