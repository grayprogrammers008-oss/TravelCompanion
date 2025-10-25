import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/itinerary_model.dart';
import '../../data/datasources/itinerary_remote_datasource.dart';
import '../../data/repositories/itinerary_repository_impl.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../domain/usecases/create_itinerary_item_usecase.dart';
import '../../domain/usecases/update_itinerary_item_usecase.dart';
import '../../domain/usecases/delete_itinerary_item_usecase.dart';
import '../../domain/usecases/get_trip_itinerary_usecase.dart';
import '../../domain/usecases/get_itinerary_by_days_usecase.dart';
import '../../domain/usecases/reorder_items_usecase.dart';

// Data Source Provider - Using Remote Supabase DataSource
final itineraryRemoteDataSourceProvider = Provider<ItineraryRemoteDataSource>((ref) {
  return ItineraryRemoteDataSource();
});

// Repository Provider - Using Remote DataSource
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final remoteDataSource = ref.watch(itineraryRemoteDataSourceProvider);
  return ItineraryRepositoryImpl(remoteDataSource);
});

// Use Cases Providers
final createItineraryItemUseCaseProvider = Provider<CreateItineraryItemUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return CreateItineraryItemUseCase(repository);
});

final updateItineraryItemUseCaseProvider = Provider<UpdateItineraryItemUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return UpdateItineraryItemUseCase(repository);
});

final deleteItineraryItemUseCaseProvider = Provider<DeleteItineraryItemUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return DeleteItineraryItemUseCase(repository);
});

final getTripItineraryUseCaseProvider = Provider<GetTripItineraryUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return GetTripItineraryUseCase(repository);
});

final getItineraryByDaysUseCaseProvider = Provider<GetItineraryByDaysUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return GetItineraryByDaysUseCase(repository);
});

final reorderItemsUseCaseProvider = Provider<ReorderItemsUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return ReorderItemsUseCase(repository);
});

// Trip Itinerary Provider - REAL-TIME stream of all items for a trip
final tripItineraryProvider = StreamProvider.family<List<ItineraryItemModel>, String>(
  (ref, tripId) {
    final repository = ref.watch(itineraryRepositoryProvider);
    return repository.watchTripItinerary(tripId);
  },
);

// Itinerary By Days Provider - REAL-TIME stream of items grouped by days
final itineraryByDaysProvider = StreamProvider.family<List<ItineraryDay>, String>(
  (ref, tripId) {
    final repository = ref.watch(itineraryRepositoryProvider);
    return repository.watchItineraryByDays(tripId);
  },
);

// Itinerary Controller State
class ItineraryState {
  final bool isLoading;
  final ItineraryItemModel? currentItem;
  final List<ItineraryDay>? days;
  final String? error;
  final String? successMessage;

  ItineraryState({
    this.isLoading = false,
    this.currentItem,
    this.days,
    this.error,
    this.successMessage,
  });

  ItineraryState copyWith({
    bool? isLoading,
    ItineraryItemModel? currentItem,
    List<ItineraryDay>? days,
    String? error,
    String? successMessage,
  }) {
    return ItineraryState(
      isLoading: isLoading ?? this.isLoading,
      currentItem: currentItem ?? this.currentItem,
      days: days ?? this.days,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Itinerary Controller
class ItineraryController extends Notifier<ItineraryState> {
  late final CreateItineraryItemUseCase _createItemUseCase;
  late final UpdateItineraryItemUseCase _updateItemUseCase;
  late final DeleteItineraryItemUseCase _deleteItemUseCase;
  late final ReorderItemsUseCase _reorderItemsUseCase;
  late final ItineraryRepository _repository;

  @override
  ItineraryState build() {
    // Initialize dependencies from ref
    _createItemUseCase = ref.read(createItineraryItemUseCaseProvider);
    _updateItemUseCase = ref.read(updateItineraryItemUseCaseProvider);
    _deleteItemUseCase = ref.read(deleteItineraryItemUseCaseProvider);
    _reorderItemsUseCase = ref.read(reorderItemsUseCaseProvider);
    _repository = ref.read(itineraryRepositoryProvider);

    return ItineraryState();
  }

  /// Create a new itinerary item
  Future<ItineraryItemModel> createItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final item = await _createItemUseCase(
        tripId: tripId,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        dayNumber: dayNumber,
        orderIndex: orderIndex,
      );
      state = state.copyWith(
        isLoading: false,
        currentItem: item,
        successMessage: 'Activity added successfully',
      );

      // Invalidate the itinerary providers to refresh the list
      ref.invalidate(itineraryByDaysProvider);
      ref.invalidate(tripItineraryProvider);

      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update an itinerary item
  Future<ItineraryItemModel> updateItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final item = await _updateItemUseCase(
        itemId: itemId,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        dayNumber: dayNumber,
        orderIndex: orderIndex,
      );
      state = state.copyWith(
        isLoading: false,
        currentItem: item,
        successMessage: 'Activity updated successfully',
      );

      // Invalidate the itinerary providers to refresh the list
      ref.invalidate(itineraryByDaysProvider);
      ref.invalidate(tripItineraryProvider);

      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete an itinerary item
  Future<void> deleteItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _deleteItemUseCase(itemId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Activity deleted successfully',
      );

      // Invalidate the itinerary providers to refresh the list
      ref.invalidate(itineraryByDaysProvider);
      ref.invalidate(tripItineraryProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Reorder items within a day
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _reorderItemsUseCase(
        tripId: tripId,
        dayNumber: dayNumber,
        itemIds: itemIds,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Items reordered successfully',
      );

      // Invalidate the itinerary providers to refresh the list
      ref.invalidate(itineraryByDaysProvider);
      ref.invalidate(tripItineraryProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Move item to different day
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _repository.moveItemToDay(
        itemId: itemId,
        newDayNumber: newDayNumber,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Activity moved successfully',
      );

      // Invalidate the itinerary providers to refresh the list
      ref.invalidate(itineraryByDaysProvider);
      ref.invalidate(tripItineraryProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Itinerary Controller Provider
final itineraryControllerProvider = NotifierProvider<ItineraryController, ItineraryState>(() {
  return ItineraryController();
});
