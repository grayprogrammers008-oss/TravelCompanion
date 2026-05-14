import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:pathio/features/itinerary/domain/usecases/create_itinerary_item_usecase.dart';
import 'package:pathio/features/itinerary/domain/usecases/delete_itinerary_item_usecase.dart';
import 'package:pathio/features/itinerary/domain/usecases/get_itinerary_by_days_usecase.dart';
import 'package:pathio/features/itinerary/domain/usecases/get_trip_itinerary_usecase.dart';
import 'package:pathio/features/itinerary/domain/usecases/reorder_items_usecase.dart';
import 'package:pathio/features/itinerary/domain/usecases/update_itinerary_item_usecase.dart';
import 'package:pathio/features/itinerary/presentation/providers/itinerary_providers.dart';
import 'package:pathio/shared/models/itinerary_model.dart';

/// Hand-rolled fake repository allowing fine control over each method's
/// behaviour so we can drive ItineraryController through its happy and
/// error paths.
class _FakeItineraryRepository implements ItineraryRepository {
  // Canned outputs / errors
  ItineraryItemModel? createReturn;
  Object? createError;

  ItineraryItemModel? updateReturn;
  Object? updateError;

  Object? deleteError;

  Object? reorderError;

  Object? moveError;

  // Recorded inputs
  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;
  String? lastDeletedId;
  Map<String, dynamic>? lastReorderArgs;
  Map<String, dynamic>? lastMoveArgs;

  @override
  Future<ItineraryItemModel> createItineraryItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    lastCreateArgs = {
      'tripId': tripId,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'dayNumber': dayNumber,
      'orderIndex': orderIndex,
    };
    if (createError != null) throw createError!;
    return createReturn!;
  }

  @override
  Future<ItineraryItemModel> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) async {
    lastUpdateArgs = {
      'itemId': itemId,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'dayNumber': dayNumber,
      'orderIndex': orderIndex,
    };
    if (updateError != null) throw updateError!;
    return updateReturn!;
  }

  @override
  Future<void> deleteItineraryItem(String itemId) async {
    lastDeletedId = itemId;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    lastReorderArgs = {
      'tripId': tripId,
      'dayNumber': dayNumber,
      'itemIds': itemIds,
    };
    if (reorderError != null) throw reorderError!;
  }

  @override
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  }) async {
    lastMoveArgs = {
      'itemId': itemId,
      'newDayNumber': newDayNumber,
    };
    if (moveError != null) throw moveError!;
  }

  // Below methods are not exercised by the controller so we throw to fail
  // loudly if the implementation accidentally calls them.

  @override
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) {
    throw UnimplementedError();
  }

  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ItineraryItemModel>> watchTripItinerary(String tripId) {
    return const Stream.empty();
  }

  @override
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) {
    return const Stream.empty();
  }
}

ItineraryItemModel _sampleItem({String id = 'item-1', int orderIndex = 0}) {
  return ItineraryItemModel(
    id: id,
    tripId: 'trip-1',
    title: 'Visit Eiffel Tower',
    description: 'Skip the line tour',
    location: 'Paris',
    startTime: DateTime(2024, 6, 1, 10),
    endTime: DateTime(2024, 6, 1, 12),
    dayNumber: 1,
    orderIndex: orderIndex,
  );
}

ProviderContainer _makeContainer(_FakeItineraryRepository repo) {
  return ProviderContainer(
    overrides: [
      itineraryRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  group('ItineraryState', () {
    test('default state is empty / non-loading', () {
      final state = ItineraryState();
      expect(state.isLoading, isFalse);
      expect(state.currentItem, isNull);
      expect(state.days, isNull);
      expect(state.error, isNull);
      expect(state.successMessage, isNull);
    });

    test('copyWith updates supplied fields and preserves currentItem/days', () {
      final item = _sampleItem();
      final initial = ItineraryState();
      final updated = initial.copyWith(
        isLoading: true,
        currentItem: item,
        days: [ItineraryDay(dayNumber: 1, items: [item])],
      );
      expect(updated.isLoading, isTrue);
      expect(updated.currentItem, item);
      expect(updated.days, hasLength(1));
      // error/successMessage are reset via direct assignment in copyWith.
      expect(updated.error, isNull);
      expect(updated.successMessage, isNull);
    });

    test('copyWith without args resets error / successMessage and preserves other fields', () {
      // Note: ItineraryState.copyWith assigns error / successMessage directly
      // (no `??`), so they are intentionally cleared when omitted - this lets
      // the controller drop messages when transitioning state.
      final state = ItineraryState(
        isLoading: true,
        successMessage: 'ok',
        error: 'previous error',
      );
      final copy = state.copyWith();
      expect(copy.isLoading, isTrue);
      expect(copy.successMessage, isNull);
      expect(copy.error, isNull);
      // copyWith returns a new instance.
      expect(identical(state, copy), isFalse);
    });
  });

  group('Default providers wire repository / use cases together', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('createItineraryItemUseCaseProvider exposes a CreateItineraryItemUseCase', () {
      final useCase = container.read(createItineraryItemUseCaseProvider);
      expect(useCase, isA<CreateItineraryItemUseCase>());
    });

    test('updateItineraryItemUseCaseProvider exposes an UpdateItineraryItemUseCase', () {
      final useCase = container.read(updateItineraryItemUseCaseProvider);
      expect(useCase, isA<UpdateItineraryItemUseCase>());
    });

    test('deleteItineraryItemUseCaseProvider exposes a DeleteItineraryItemUseCase', () {
      final useCase = container.read(deleteItineraryItemUseCaseProvider);
      expect(useCase, isA<DeleteItineraryItemUseCase>());
    });

    test('getTripItineraryUseCaseProvider exposes a GetTripItineraryUseCase', () {
      final useCase = container.read(getTripItineraryUseCaseProvider);
      expect(useCase, isA<GetTripItineraryUseCase>());
    });

    test('getItineraryByDaysUseCaseProvider exposes a GetItineraryByDaysUseCase', () {
      final useCase = container.read(getItineraryByDaysUseCaseProvider);
      expect(useCase, isA<GetItineraryByDaysUseCase>());
    });

    test('reorderItemsUseCaseProvider exposes a ReorderItemsUseCase', () {
      final useCase = container.read(reorderItemsUseCaseProvider);
      expect(useCase, isA<ReorderItemsUseCase>());
    });

    test('itineraryRepositoryProvider returns the overridden repository', () {
      final fromContainer = container.read(itineraryRepositoryProvider);
      expect(identical(fromContainer, repo), isTrue);
    });

    test('tripItineraryProvider returns an empty stream from the fake repo', () async {
      // The fake returns Stream.empty(), which completes without values; the
      // family provider should expose AsyncValue states without crashing.
      final sub = container.listen(
        tripItineraryProvider('trip-1'),
        (_, __) {},
      );
      // First read is loading.
      expect(sub.read().isLoading, isTrue);
    });

    test('itineraryByDaysProvider returns AsyncLoading initially', () {
      final value = container.read(itineraryByDaysProvider('trip-1'));
      expect(value.isLoading, isTrue);
    });
  });

  group('ItineraryController.createItem', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('successful create updates state with currentItem and success message', () async {
      final item = _sampleItem();
      repo.createReturn = item;

      final controller = container.read(itineraryControllerProvider.notifier);
      final result = await controller.createItem(
        tripId: 'trip-1',
        title: 'Visit Eiffel Tower',
        description: 'Skip the line tour',
        location: 'Paris',
        startTime: DateTime(2024, 6, 1, 10),
        endTime: DateTime(2024, 6, 1, 12),
        dayNumber: 1,
        orderIndex: 0,
      );

      expect(result, item);
      final state = container.read(itineraryControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.currentItem, item);
      expect(state.successMessage, 'Activity added successfully');
      expect(state.error, isNull);
      expect(repo.lastCreateArgs?['tripId'], 'trip-1');
    });

    test('successful create with showSuccessMessage=false omits success message', () async {
      final item = _sampleItem();
      repo.createReturn = item;

      final controller = container.read(itineraryControllerProvider.notifier);
      await controller.createItem(
        tripId: 'trip-1',
        title: 'Visit Eiffel Tower',
        showSuccessMessage: false,
      );

      final state = container.read(itineraryControllerProvider);
      expect(state.successMessage, isNull);
      expect(state.currentItem, item);
    });

    test('failure stores error and rethrows', () async {
      // Use a non-validation title (>= 3 chars, trimmed) so the repo is reached
      // and we can assert that its exception bubbles up through the use case.
      repo.createError = Exception('db down');

      final controller = container.read(itineraryControllerProvider.notifier);
      await expectLater(
        () => controller.createItem(
          tripId: 'trip-1',
          title: 'Visit',
        ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(itineraryControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.successMessage, isNull);
    });
  });

  group('ItineraryController.updateItem', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('successful update sets currentItem and success message', () async {
      final updated = _sampleItem(id: 'item-1').copyWith(title: 'Updated');
      repo.updateReturn = updated;

      final controller = container.read(itineraryControllerProvider.notifier);
      final result = await controller.updateItem(
        itemId: 'item-1',
        title: 'Updated',
      );

      expect(result, updated);
      final state = container.read(itineraryControllerProvider);
      expect(state.successMessage, 'Activity updated successfully');
      expect(state.currentItem, updated);
      expect(state.isLoading, isFalse);
    });

    test('failure stores error message and rethrows', () async {
      repo.updateError = Exception('boom');

      final controller = container.read(itineraryControllerProvider.notifier);
      await expectLater(
        () => controller.updateItem(itemId: 'item-1', title: 'Updated'),
        throwsA(isA<Exception>()),
      );

      final state = container.read(itineraryControllerProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.successMessage, isNull);
    });
  });

  group('ItineraryController.deleteItem', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('successful delete sets success message', () async {
      final controller = container.read(itineraryControllerProvider.notifier);
      await controller.deleteItem('item-1');

      expect(repo.lastDeletedId, 'item-1');
      final state = container.read(itineraryControllerProvider);
      expect(state.successMessage, 'Activity deleted successfully');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('failure stores error message and rethrows', () async {
      repo.deleteError = Exception('cannot delete');

      final controller = container.read(itineraryControllerProvider.notifier);
      await expectLater(
        () => controller.deleteItem('item-1'),
        throwsA(isA<Exception>()),
      );

      final state = container.read(itineraryControllerProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });
  });

  group('ItineraryController.reorderItems', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('successful reorder sets success message and forwards args', () async {
      final controller = container.read(itineraryControllerProvider.notifier);
      await controller.reorderItems(
        tripId: 'trip-1',
        dayNumber: 1,
        itemIds: const ['a', 'b', 'c'],
      );

      expect(repo.lastReorderArgs?['tripId'], 'trip-1');
      expect(repo.lastReorderArgs?['dayNumber'], 1);
      expect(repo.lastReorderArgs?['itemIds'], ['a', 'b', 'c']);
      final state = container.read(itineraryControllerProvider);
      expect(state.successMessage, 'Items reordered successfully');
      expect(state.isLoading, isFalse);
    });

    test('failure stores error and rethrows', () async {
      repo.reorderError = Exception('fail');

      final controller = container.read(itineraryControllerProvider.notifier);
      await expectLater(
        () => controller.reorderItems(
          tripId: 'trip-1',
          dayNumber: 1,
          itemIds: const ['a'],
        ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(itineraryControllerProvider);
      expect(state.error, isNotNull);
    });
  });

  group('ItineraryController.moveItemToDay', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('successful move sets success message and forwards args', () async {
      final controller = container.read(itineraryControllerProvider.notifier);
      await controller.moveItemToDay(itemId: 'item-1', newDayNumber: 3);

      expect(repo.lastMoveArgs?['itemId'], 'item-1');
      expect(repo.lastMoveArgs?['newDayNumber'], 3);
      final state = container.read(itineraryControllerProvider);
      expect(state.successMessage, 'Activity moved successfully');
      expect(state.isLoading, isFalse);
    });

    test('failure stores error and rethrows', () async {
      repo.moveError = Exception('cannot move');

      final controller = container.read(itineraryControllerProvider.notifier);
      await expectLater(
        () => controller.moveItemToDay(itemId: 'item-1', newDayNumber: 2),
        throwsA(isA<Exception>()),
      );

      final state = container.read(itineraryControllerProvider);
      expect(state.error, isNotNull);
    });
  });

  group('ItineraryController.clear* helpers', () {
    late _FakeItineraryRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeItineraryRepository();
      container = _makeContainer(repo);
    });

    tearDown(() => container.dispose());

    test('clearSuccessMessage nulls out successMessage', () async {
      repo.createReturn = _sampleItem();
      final controller = container.read(itineraryControllerProvider.notifier);
      await controller.createItem(tripId: 'trip-1', title: 'Visit Eiffel Tower');
      expect(container.read(itineraryControllerProvider).successMessage, isNotNull);

      controller.clearSuccessMessage();
      expect(container.read(itineraryControllerProvider).successMessage, isNull);
    });

    test('clearError nulls out error', () async {
      repo.createError = Exception('boom');
      final controller = container.read(itineraryControllerProvider.notifier);
      await expectLater(
        () => controller.createItem(tripId: 'trip-1', title: 'Visit'),
        throwsA(anything),
      );
      expect(container.read(itineraryControllerProvider).error, isNotNull);

      controller.clearError();
      expect(container.read(itineraryControllerProvider).error, isNull);
    });
  });
}
