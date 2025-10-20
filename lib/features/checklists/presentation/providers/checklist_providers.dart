import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/checklist_entity.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../../domain/usecases/get_trip_checklists_usecase.dart';
import '../../domain/usecases/get_checklist_with_items_usecase.dart';
import '../../domain/usecases/create_checklist_usecase.dart';
import '../../domain/usecases/manage_checklist_items_usecase.dart';
import '../../data/datasources/checklist_remote_datasource.dart';
import '../../data/repositories/checklist_repository_impl.dart';

// Data Sources
final checklistRemoteDataSourceProvider = Provider<ChecklistRemoteDataSource>((ref) {
  return ChecklistRemoteDataSource();
});

// Repository - Online-only mode (Supabase)
final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final remoteDataSource = ref.watch(checklistRemoteDataSourceProvider);
  return ChecklistRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Cases
final getTripChecklistsUseCaseProvider = Provider<GetTripChecklistsUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return GetTripChecklistsUseCase(repository);
});

final watchTripChecklistsUseCaseProvider = Provider<WatchTripChecklistsUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return WatchTripChecklistsUseCase(repository);
});

final getChecklistWithItemsUseCaseProvider = Provider<GetChecklistWithItemsUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return GetChecklistWithItemsUseCase(repository);
});

final watchChecklistWithItemsUseCaseProvider = Provider<WatchChecklistWithItemsUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return WatchChecklistWithItemsUseCase(repository);
});

final createChecklistUseCaseProvider = Provider<CreateChecklistUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return CreateChecklistUseCase(repository);
});

final addChecklistItemUseCaseProvider = Provider<AddChecklistItemUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return AddChecklistItemUseCase(repository);
});

final updateChecklistItemUseCaseProvider = Provider<UpdateChecklistItemUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return UpdateChecklistItemUseCase(repository);
});

final toggleItemCompletionUseCaseProvider = Provider<ToggleItemCompletionUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return ToggleItemCompletionUseCase(repository);
});

final deleteChecklistItemUseCaseProvider = Provider<DeleteChecklistItemUseCase>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return DeleteChecklistItemUseCase(repository);
});

// State Providers

/// Provider to get checklists for a specific trip
final tripChecklistsProvider = FutureProvider.family<List<ChecklistEntity>, String>((ref, tripId) async {
  final useCase = ref.watch(getTripChecklistsUseCaseProvider);
  return await useCase(tripId);
});

/// Provider to watch checklists in real-time
final watchTripChecklistsProvider = StreamProvider.family<List<ChecklistEntity>, String>((ref, tripId) {
  final useCase = ref.watch(watchTripChecklistsUseCaseProvider);
  return useCase(tripId);
});

/// Provider to get a checklist with all its items
final checklistWithItemsProvider = FutureProvider.family<ChecklistWithItemsEntity, String>((ref, checklistId) async {
  final useCase = ref.watch(getChecklistWithItemsUseCaseProvider);
  return await useCase(checklistId);
});

/// Provider to watch a checklist with items in real-time
final watchChecklistWithItemsProvider = StreamProvider.family<ChecklistWithItemsEntity, String>((ref, checklistId) {
  final useCase = ref.watch(watchChecklistWithItemsUseCaseProvider);
  return useCase(checklistId);
});

/// Controller state for checklist operations
class ChecklistState {
  final bool isLoading;
  final String? error;

  ChecklistState({
    this.isLoading = false,
    this.error,
  });

  ChecklistState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ChecklistState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Checklist Controller - Riverpod 3.0
class ChecklistController extends Notifier<ChecklistState> {
  late final ChecklistRepository _repository;

  @override
  ChecklistState build() {
    _repository = ref.watch(checklistRepositoryProvider);
    return ChecklistState();
  }

  /// Create a new checklist
  Future<ChecklistEntity?> createChecklist({
    required String tripId,
    required String name,
    required String createdBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = CreateChecklistParams(
        tripId: tripId,
        name: name,
        createdBy: createdBy,
      );
      final useCase = CreateChecklistUseCase(_repository);
      final checklist = await useCase(params);
      state = state.copyWith(isLoading: false);
      return checklist;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update checklist name
  Future<bool> updateChecklist({
    required String checklistId,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateChecklist(
        checklistId: checklistId,
        name: name,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a checklist
  Future<bool> deleteChecklist(String checklistId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteChecklist(checklistId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Add item to checklist
  Future<ChecklistItemEntity?> addItem({
    required String checklistId,
    required String title,
    String? assignedTo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = AddChecklistItemParams(
        checklistId: checklistId,
        title: title,
        assignedTo: assignedTo,
      );
      final useCase = AddChecklistItemUseCase(_repository);
      final item = await useCase(params);
      state = state.copyWith(isLoading: false);
      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update checklist item
  Future<bool> updateItem({
    required String itemId,
    String? title,
    String? assignedTo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = UpdateChecklistItemParams(
        itemId: itemId,
        title: title,
        assignedTo: assignedTo,
      );
      final useCase = UpdateChecklistItemUseCase(_repository);
      await useCase(params);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Toggle item completion
  Future<bool> toggleItemCompletion({
    required String itemId,
    required bool isCompleted,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = ToggleItemCompletionParams(
        itemId: itemId,
        isCompleted: isCompleted,
        userId: userId,
      );
      final useCase = ToggleItemCompletionUseCase(_repository);
      await useCase(params);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete an item
  Future<bool> deleteItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteChecklistItem(itemId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Reorder items
  Future<bool> reorderItems({
    required String checklistId,
    required List<String> itemIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.reorderItems(
        checklistId: checklistId,
        itemIds: itemIds,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Provider for ChecklistController
final checklistControllerProvider = NotifierProvider<ChecklistController, ChecklistState>(() {
  return ChecklistController();
});
