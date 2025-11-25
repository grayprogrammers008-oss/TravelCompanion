import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/network/supabase_client.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_trip.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientWrapper.client;
});

/// Admin data source provider
final adminDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AdminRemoteDataSource(supabase);
});

/// Admin trip repository provider (uses data source directly for simplicity)
final adminTripRepositoryProvider = Provider<AdminRemoteDataSource>((ref) {
  return ref.watch(adminDataSourceProvider);
});

/// Admin trips provider - fetches trips with filtering
final adminTripsProvider =
    FutureProvider.family<List<AdminTripModel>, TripListParams>(
  (ref, params) async {
    final dataSource = ref.watch(adminDataSourceProvider);

    return await dataSource.getAllTrips(
      limit: params.limit,
      offset: params.offset,
      search: params.search,
      status: params.status,
    );
  },
);

/// Trip statistics provider
final tripStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  try {
    final response = await supabase.rpc('get_admin_trip_stats');
    return response as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Failed to get trip stats: $e');
  }
});
