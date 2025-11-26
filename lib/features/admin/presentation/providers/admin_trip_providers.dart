import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_trip.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

export 'package:travel_crew/features/admin/domain/entities/admin_trip.dart';

/// Admin trips provider - fetches trips with filtering
final adminTripsProvider =
    FutureProvider.family<List<AdminTripModel>, TripListParams>(
  (ref, params) async {
    final dataSource = ref.watch(adminRemoteDataSourceProvider);

    return await dataSource.getAllTrips(
      limit: params.limit,
      offset: params.offset,
      search: params.search,
      status: params.status,
    );
  },
);

/// Admin trip repository provider (uses existing data source)
final adminTripRepositoryProvider = Provider((ref) {
  return ref.watch(adminRemoteDataSourceProvider);
});
