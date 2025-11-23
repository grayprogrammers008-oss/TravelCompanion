import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/trip_model.dart';
import '../../data/datasources/trip_remote_datasource.dart';
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

  // Add a 5-second delay to show the packing animation
  await Future.delayed(const Duration(seconds: 5));

  // Then stream real-time updates
  await for (final trips in repository.watchUserTrips()) {
    yield trips;
  }
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
