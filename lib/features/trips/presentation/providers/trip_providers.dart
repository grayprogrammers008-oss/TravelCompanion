import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import '../../data/datasources/trip_remote_datasource.dart';
export '../../data/datasources/trip_remote_datasource.dart' show SystemUserModel;
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/usecases/create_trip_usecase.dart';
import '../../domain/usecases/update_trip_usecase.dart';
import '../../domain/usecases/get_trip_usecase.dart';
import '../../domain/usecases/get_user_trips_usecase.dart';
import '../../domain/usecases/get_trip_history_usecase.dart';
import '../../domain/usecases/get_user_stats_usecase.dart';
import '../../domain/usecases/mark_trip_as_completed_usecase.dart';
import '../../domain/usecases/unmark_trip_as_completed_usecase.dart';
import '../../domain/usecases/filter_trips_usecase.dart';
import '../../domain/usecases/get_trip_cost_usecase.dart';
import '../../domain/usecases/get_discoverable_trips_usecase.dart';
import '../../domain/usecases/join_trip_usecase.dart';
import '../../domain/usecases/copy_trip_usecase.dart';
import '../../domain/models/trip_cost_summary.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Remote Data Source Provider - Supabase (online-only mode)
final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  return TripRemoteDataSourceImpl();
});

// Repository Provider - Supabase only
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final remoteDataSource = ref.watch(tripRemoteDataSourceProvider);
  return TripRepositoryImpl(remoteDataSource);
});

// Use Cases Providers
final createTripUseCaseProvider = Provider<CreateTripUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return CreateTripUseCase(repository);
});

final getUserTripsUseCaseProvider = Provider<GetUserTripsUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetUserTripsUseCase(repository);
});

final getTripUseCaseProvider = Provider<GetTripUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetTripUseCase(repository);
});

final updateTripUseCaseProvider = Provider<UpdateTripUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return UpdateTripUseCase(repository);
});

final getTripHistoryUseCaseProvider = Provider<GetTripHistoryUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetTripHistoryUseCase(repository);
});

final getUserStatsUseCaseProvider = Provider<GetUserStatsUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetUserStatsUseCase(repository);
});

final markTripAsCompletedUseCaseProvider = Provider<MarkTripAsCompletedUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return MarkTripAsCompletedUseCase(repository);
});

final unmarkTripAsCompletedUseCaseProvider = Provider<UnmarkTripAsCompletedUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return UnmarkTripAsCompletedUseCase(repository);
});

// Get Trip Cost Use Case Provider
final getTripCostUseCaseProvider = Provider<GetTripCostUseCase>((ref) {
  final expenseRepository = ref.watch(expenseRepositoryProvider);
  return GetTripCostUseCase(expenseRepository);
});

// Get Discoverable Trips Use Case Provider
final getDiscoverableTripsUseCaseProvider = Provider<GetDiscoverableTripsUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetDiscoverableTripsUseCase(repository);
});

// Join Trip Use Case Provider
final joinTripUseCaseProvider = Provider<JoinTripUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return JoinTripUseCase(repository);
});

// Copy Trip Use Case Provider
final copyTripUseCaseProvider = Provider<CopyTripUseCase>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return CopyTripUseCase(repository);
});

// Trip Cost Summary Provider - FutureProvider for trip cost
final tripCostSummaryProvider = FutureProvider.family<TripCostSummary, String>((
  ref,
  tripId,
) async {
  final useCase = ref.watch(getTripCostUseCaseProvider);
  return await useCase(tripId);
});

// User Trips Provider - REAL-TIME stream of all trips for current user
// This provider automatically disposes and recreates when user changes (auth state changes)
// This prevents showing cached data from previous user (security issue)
final userTripsProvider = StreamProvider.autoDispose<List<TripWithMembers>>((ref) async* {
  // Watch auth state to ensure provider recreates when user changes
  final authState = ref.watch(authStateProvider);

  // Return empty list if not authenticated
  if (authState.value == null) {
    yield [];
    return;
  }

  final repository = ref.watch(tripRepositoryProvider);

  // Stream real-time updates
  await for (final trips in repository.watchUserTrips()) {
    yield trips;
  }
});

// Has Trips Provider - Quick check if user has any trips (for routing)
// Returns true if user has at least one trip, false otherwise
// Used to decide whether to show Welcome Choice page or Dashboard
final hasTripsProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);

  // Not authenticated = no trips
  if (authState.value == null) {
    return false;
  }

  final repository = ref.watch(tripRepositoryProvider);
  final trips = await repository.getUserTrips();
  return trips.isNotEmpty;
});

// Discoverable Trips Provider - Public trips that user can join
final discoverableTripsProvider = FutureProvider.autoDispose<List<TripWithMembers>>((ref) async {
  final useCase = ref.watch(getDiscoverableTripsUseCaseProvider);
  return await useCase();
});

// Single Trip Provider - REAL-TIME stream for specific trip
final tripProvider = StreamProvider.family<TripWithMembers, String>((
  ref,
  tripId,
) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchTrip(tripId);
});

// Trip History Provider - REAL-TIME stream of completed trips only
// This provider automatically disposes and recreates when user changes (auth state changes)
// This prevents showing cached data from previous user (security issue)
final tripHistoryProvider = StreamProvider.autoDispose<List<TripWithMembers>>((ref) {
  // Watch auth state to ensure provider recreates when user changes
  final authState = ref.watch(authStateProvider);

  // Return empty list if not authenticated
  if (authState.value == null) {
    return Stream.value([]);
  }

  final useCase = ref.watch(getTripHistoryUseCaseProvider);
  return useCase.watchHistory();
});

// Trip History Statistics Provider - Automatically updates when filtered trip history changes
final tripHistoryStatisticsProvider = Provider<TripHistoryStatistics>((ref) {
  // Watch the FILTERED trip history to show statistics for visible trips only
  final filteredTrips = ref.watch(filteredTripHistoryProvider);

  if (filteredTrips.isEmpty) {
    if (kDebugMode) {
      debugPrint('📊 Statistics: No trips matching current filters');
    }
    return TripHistoryStatistics.empty();
  }

  // Calculate statistics from filtered trips
  final totalTrips = filteredTrips.length;

  final tripsWithRatings = filteredTrips.where((t) => t.trip.rating > 0).toList();
  final totalRatings = tripsWithRatings.length;

  final averageRating = tripsWithRatings.isEmpty
      ? 0.0
      : tripsWithRatings
          .map((t) => t.trip.rating)
          .reduce((a, b) => a + b) / totalRatings;

  // Get earliest and latest completion dates
  final completionDates = filteredTrips
      .where((t) => t.trip.completedAt != null)
      .map((t) => t.trip.completedAt!)
      .toList();

  final earliestCompletion = completionDates.isEmpty
      ? null
      : completionDates.reduce((a, b) => a.isBefore(b) ? a : b);

  final latestCompletion = completionDates.isEmpty
      ? null
      : completionDates.reduce((a, b) => a.isAfter(b) ? a : b);

  if (kDebugMode) {
    debugPrint('📊 Statistics Updated: $totalTrips filtered trips, $totalRatings rated, avg rating: ${averageRating.toStringAsFixed(1)}');
  }

  return TripHistoryStatistics(
    totalCompletedTrips: totalTrips,
    averageRating: averageRating,
    totalRatedTrips: totalRatings,
    earliestCompletionDate: earliestCompletion,
    latestCompletionDate: latestCompletion,
  );
});

// Trip History Filter Controller
class TripHistoryFilterController extends Notifier<TripFilterParams> {
  @override
  TripFilterParams build() {
    return const TripFilterParams(
      filterType: TripFilterType.all,
      sortBy: TripSortBy.dateNewest,
    );
  }

  void updateFilter(TripFilterParams params) {
    state = params;
  }

  void updateSortBy(TripSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void updateFilterType(TripFilterType filterType) {
    state = state.copyWith(filterType: filterType);
  }

  void updateRatingRange(double? minRating, double? maxRating) {
    state = state.copyWith(minRating: minRating, maxRating: maxRating);
  }

  void updateSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      customStartDate: startDate,
      customEndDate: endDate,
    );
  }

  void reset() {
    state = const TripFilterParams(
      filterType: TripFilterType.all,
      sortBy: TripSortBy.dateNewest,
    );
  }
}

final tripHistoryFilterProvider = NotifierProvider<TripHistoryFilterController, TripFilterParams>(() {
  return TripHistoryFilterController();
});

// Filtered Trip History Provider - applies filters and sorting
final filteredTripHistoryProvider = Provider<List<TripWithMembers>>((ref) {
  final tripHistoryAsync = ref.watch(tripHistoryProvider);
  final filterParams = ref.watch(tripHistoryFilterProvider);

  return tripHistoryAsync.when(
    data: (trips) {
      final filterUseCase = FilterTripsUseCase();
      return filterUseCase(trips: trips, params: filterParams);
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// User Travel Statistics Provider - REAL-TIME stream of user stats
final userStatsProvider = StreamProvider<UserTravelStats>((ref) {
  final useCase = ref.watch(getUserStatsUseCaseProvider);
  return useCase.watch();
});

// Trip Controller State
class TripState {
  final bool isLoading;
  final TripModel? currentTrip;
  final List<TripWithMembers>? trips;
  final String? error;

  TripState({this.isLoading = false, this.currentTrip, this.trips, this.error});

  TripState copyWith({
    bool? isLoading,
    TripModel? currentTrip,
    List<TripWithMembers>? trips,
    String? error,
  }) {
    return TripState(
      isLoading: isLoading ?? this.isLoading,
      currentTrip: currentTrip ?? this.currentTrip,
      trips: trips ?? this.trips,
      error: error,
    );
  }
}

// Trip Controller - Updated for Riverpod 3.0
class TripController extends Notifier<TripState> {
  late final CreateTripUseCase _createTripUseCase;
  late final UpdateTripUseCase _updateTripUseCase;
  late final MarkTripAsCompletedUseCase _markTripAsCompletedUseCase;
  late final UnmarkTripAsCompletedUseCase _unmarkTripAsCompletedUseCase;
  late final TripRepository _repository;

  @override
  TripState build() {
    // Initialize dependencies from ref
    _createTripUseCase = ref.read(createTripUseCaseProvider);
    _updateTripUseCase = ref.read(updateTripUseCaseProvider);
    _markTripAsCompletedUseCase = ref.read(markTripAsCompletedUseCaseProvider);
    _unmarkTripAsCompletedUseCase = ref.read(unmarkTripAsCompletedUseCaseProvider);
    _repository = ref.read(tripRepositoryProvider);

    return TripState();
  }

  /// Create a new trip
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? cost,
    String? currency,
    bool isPublic = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final trip = await _createTripUseCase(
        name: name,
        description: description,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        coverImageUrl: coverImageUrl,
        cost: cost,
        currency: currency,
        isPublic: isPublic,
      );

      // Invalidate providers to trigger refresh
      ref.invalidate(userTripsProvider);

      state = state.copyWith(isLoading: false, currentTrip: trip);
      return trip;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update trip (with validation via use case)
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? cost,
    String? currency,
    bool? isPublic,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final trip = await _updateTripUseCase(
        tripId: tripId,
        name: name,
        description: description,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        coverImageUrl: coverImageUrl,
        cost: cost,
        currency: currency,
        isPublic: isPublic,
      );

      // Invalidate providers to trigger refresh
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripHistoryProvider);

      state = state.copyWith(isLoading: false, currentTrip: trip);
      return trip;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteTrip(tripId);

      // Invalidate providers to trigger refresh
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripHistoryProvider);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Add member to trip
  Future<void> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.addMember(tripId: tripId, userId: userId, role: role);

      // Invalidate trip provider to refresh the member list
      ref.invalidate(tripProvider(tripId));
      ref.invalidate(userTripsProvider);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Remove member from trip
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.removeMember(tripId: tripId, userId: userId);

      // Invalidate trip provider to refresh the member list
      ref.invalidate(tripProvider(tripId));
      ref.invalidate(userTripsProvider);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Mark trip as completed
  ///
  /// This marks the trip as completed, optionally with a rating.
  /// Only the trip creator or admins can mark a trip as completed.
  Future<TripModel> markTripAsCompleted({
    required String tripId,
    required String userId,
    double? rating,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kDebugMode) {
        debugPrint('🏁 Marking trip as completed: $tripId${rating != null ? " with rating: $rating" : ""}');
      }

      // Mark trip as completed
      var trip = await _markTripAsCompletedUseCase(
        tripId: tripId,
        userId: userId,
      );

      // If rating is provided, update the trip with the rating
      if (rating != null) {
        trip = await _repository.updateTrip(
          tripId: tripId,
          rating: rating,
        );
        if (kDebugMode) {
          debugPrint('⭐ Rating applied: $rating');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Trip completed in database: ${trip.name} (isCompleted: ${trip.isCompleted}, rating: ${trip.rating})');
      }

      // Wait briefly for Supabase real-time to propagate the change
      // This ensures the stream emits updated data before we invalidate providers
      if (kDebugMode) {
        debugPrint('⏳ Waiting 500ms for real-time propagation...');
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate providers to trigger refresh
      if (kDebugMode) {
        debugPrint('🔄 Invalidating providers to refresh UI...');
      }
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripHistoryProvider);
      ref.invalidate(tripHistoryStatisticsProvider);
      ref.invalidate(filteredTripHistoryProvider);

      state = state.copyWith(isLoading: false, currentTrip: trip);
      if (kDebugMode) {
        debugPrint('✅ Trip completion saved, providers invalidated');
      }
      return trip;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error completing trip: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Unmark trip as completed (reopen trip)
  ///
  /// This reopens a completed trip.
  /// Only the trip creator or admins can unmark a trip as completed.
  Future<TripModel> unmarkTripAsCompleted({
    required String tripId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kDebugMode) {
        debugPrint('🔄 Reopening trip: $tripId');
      }

      final trip = await _unmarkTripAsCompletedUseCase(
        tripId: tripId,
        userId: userId,
      );

      if (kDebugMode) {
        debugPrint('✅ Trip reopened in database: ${trip.name} (isCompleted: ${trip.isCompleted})');
      }

      // Wait briefly for Supabase real-time to propagate the change
      // This ensures the stream emits updated data before we invalidate providers
      if (kDebugMode) {
        debugPrint('⏳ Waiting 500ms for real-time propagation...');
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // Invalidate providers to trigger refresh
      if (kDebugMode) {
        debugPrint('🔄 Invalidating providers to refresh UI...');
      }
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripHistoryProvider);
      ref.invalidate(tripHistoryStatisticsProvider);
      ref.invalidate(filteredTripHistoryProvider);

      state = state.copyWith(isLoading: false, currentTrip: trip);
      if (kDebugMode) {
        debugPrint('✅ Trip reopen complete, providers invalidated');
      }
      return trip;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error reopening trip: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Trip Controller Provider - Updated for Riverpod 3.0
final tripControllerProvider = NotifierProvider<TripController, TripState>(() {
  return TripController();
});

/// Provider to search for system users to add to a trip
/// Parameters: (searchQuery, tripId) - tripId is used to exclude existing members
final systemUsersSearchProvider = FutureProvider.family<List<SystemUserModel>, ({String? search, String tripId})>((
  ref,
  params,
) async {
  final dataSource = ref.watch(tripRemoteDataSourceProvider);

  // Get existing member IDs from the trip
  final tripAsync = await ref.watch(tripProvider(params.tripId).future);
  final existingMemberIds = tripAsync.members.map((m) => m.userId).toList();

  return await dataSource.searchSystemUsers(
    search: params.search,
    excludeUserIds: existingMemberIds,
  );
});

/// Provider to get all system users (without excluding any)
/// Used for the manage members screen where we show all users with checkboxes
final allSystemUsersProvider = FutureProvider.family<List<SystemUserModel>, String?>((
  ref,
  search,
) async {
  final dataSource = ref.watch(tripRemoteDataSourceProvider);

  return await dataSource.searchSystemUsers(
    search: search,
    excludeUserIds: null, // Don't exclude anyone
  );
});

// ============ TRIP FAVORITES PROVIDERS ============

/// Provider to get list of favorite trip IDs for the current user
final favoriteTripIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final authState = ref.watch(authStateProvider);

  // Not authenticated = no favorites
  if (authState.value == null) {
    return [];
  }

  final repository = ref.watch(tripRepositoryProvider);
  return await repository.getFavoriteTripIds();
});

/// Provider that combines user trips with their favorite status
/// This is the main provider to use when displaying trips with favorite indicators
final userTripsWithFavoritesProvider = StreamProvider.autoDispose<List<TripWithMembers>>((ref) async* {
  // Watch auth state
  final authState = ref.watch(authStateProvider);
  if (authState.value == null) {
    yield [];
    return;
  }

  final repository = ref.watch(tripRepositoryProvider);

  // Get the favorite trip IDs
  List<String> favoriteIds = [];
  try {
    favoriteIds = await repository.getFavoriteTripIds();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Error fetching favorite trip IDs: $e');
    }
  }

  // Stream trips and merge with favorite status
  await for (final trips in repository.watchUserTrips()) {
    // Update each trip with its favorite status
    final tripsWithFavorites = trips.map((trip) {
      final isFavorite = favoriteIds.contains(trip.trip.id);
      return trip.copyWith(isFavorite: isFavorite);
    }).toList();

    yield tripsWithFavorites;
  }
});

/// Check if a specific trip is a favorite
final isTripFavoriteProvider = Provider.family<bool, String>((ref, tripId) {
  final favoritesAsync = ref.watch(favoriteTripIdsProvider);
  return favoritesAsync.when(
    data: (favoriteIds) => favoriteIds.contains(tripId),
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Controller for managing trip favorites
class TripFavoritesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Toggle favorite status for a trip
  /// Returns the new favorite status (true if now favorited, false if unfavorited)
  Future<bool> toggleFavorite(String tripId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tripRepositoryProvider);
      final isFavorite = await repository.toggleFavorite(tripId);

      if (kDebugMode) {
        debugPrint('⭐ Trip $tripId is now ${isFavorite ? 'favorited' : 'unfavorited'}');
      }

      // Invalidate providers to refresh the state
      ref.invalidate(favoriteTripIdsProvider);
      ref.invalidate(userTripsWithFavoritesProvider);
      ref.invalidate(userTripsProvider);
      // Also invalidate the specific trip provider to update trip detail page
      ref.invalidate(tripProvider(tripId));

      state = const AsyncValue.data(null);
      return isFavorite;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling favorite: $e');
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final tripFavoritesControllerProvider = NotifierProvider<TripFavoritesController, AsyncValue<void>>(() {
  return TripFavoritesController();
});
