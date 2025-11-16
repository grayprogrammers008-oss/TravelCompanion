import 'dart:async';
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

// User Trips Provider - REAL-TIME stream of all trips for current user
final userTripsProvider = StreamProvider<List<TripWithMembers>>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchUserTrips();
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
final tripHistoryProvider = StreamProvider<List<TripWithMembers>>((ref) {
  final useCase = ref.watch(getTripHistoryUseCaseProvider);
  return useCase.watchHistory();
});

// Trip History Statistics Provider
final tripHistoryStatisticsProvider = FutureProvider<TripHistoryStatistics>((ref) async {
  final useCase = ref.watch(getTripHistoryUseCaseProvider);
  return await useCase.getStatistics();
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
  late final TripRepository _repository;

  @override
  TripState build() {
    // Initialize dependencies from ref
    _createTripUseCase = ref.read(createTripUseCaseProvider);
    _updateTripUseCase = ref.read(updateTripUseCaseProvider);
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
}

// Trip Controller Provider - Updated for Riverpod 3.0
final tripControllerProvider = NotifierProvider<TripController, TripState>(() {
  return TripController();
});
