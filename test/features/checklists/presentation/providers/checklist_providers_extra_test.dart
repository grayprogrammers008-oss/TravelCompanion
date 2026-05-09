import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/presentation/providers/checklist_providers.dart';

import '../widgets/fake_checklist_repository.dart';

/// Additional coverage for [checklist_providers.dart] focused on:
///   * use-case provider wiring
///   * stream providers (watch* family)
///   * controller `addItem` with default null `assignedTo`
///   * `ChecklistState` value class (constructor + copyWith semantics)
void main() {
  late FakeChecklistRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeChecklistRepository();
    container = ProviderContainer(overrides: [
      checklistRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  // ------------------------------------------------------------------
  // ChecklistState — value class
  // ------------------------------------------------------------------

  group('ChecklistState', () {
    test('default constructor produces non-loading and null error', () {
      final s = ChecklistState();
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
    });

    test('copyWith with isLoading replaces only that field', () {
      final s = ChecklistState();
      final s2 = s.copyWith(isLoading: true);
      expect(s2.isLoading, isTrue);
      expect(s2.error, isNull);
    });

    test('copyWith with error sets the error string', () {
      final s = ChecklistState();
      final s2 = s.copyWith(error: 'oops');
      expect(s2.error, 'oops');
      expect(s2.isLoading, isFalse);
    });

    test('copyWith without args keeps isLoading and clears error',
        () {
      // Note: copyWith does `error: error` (does not preserve previous error
      // unless explicitly passed) — capture current behaviour for regression.
      final s = ChecklistState(isLoading: true, error: 'old');
      final s2 = s.copyWith();
      expect(s2.isLoading, isTrue);
      expect(s2.error, isNull);
    });
  });

  // ------------------------------------------------------------------
  // Use-case providers
  // ------------------------------------------------------------------

  group('use-case providers', () {
    test('getTripChecklistsUseCaseProvider resolves a use case', () {
      final useCase = container.read(getTripChecklistsUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('watchTripChecklistsUseCaseProvider resolves a use case', () {
      expect(container.read(watchTripChecklistsUseCaseProvider), isNotNull);
    });

    test('getChecklistWithItemsUseCaseProvider resolves a use case', () {
      expect(container.read(getChecklistWithItemsUseCaseProvider), isNotNull);
    });

    test('watchChecklistWithItemsUseCaseProvider resolves a use case', () {
      expect(
        container.read(watchChecklistWithItemsUseCaseProvider),
        isNotNull,
      );
    });

    test('createChecklistUseCaseProvider resolves a use case', () {
      expect(container.read(createChecklistUseCaseProvider), isNotNull);
    });

    test('addChecklistItemUseCaseProvider resolves a use case', () {
      expect(container.read(addChecklistItemUseCaseProvider), isNotNull);
    });

    test('updateChecklistItemUseCaseProvider resolves a use case', () {
      expect(container.read(updateChecklistItemUseCaseProvider), isNotNull);
    });

    test('toggleItemCompletionUseCaseProvider resolves a use case', () {
      expect(container.read(toggleItemCompletionUseCaseProvider), isNotNull);
    });

    test('deleteChecklistItemUseCaseProvider resolves a use case', () {
      expect(container.read(deleteChecklistItemUseCaseProvider), isNotNull);
    });

    // Note: checklistRemoteDataSourceProvider would attempt to access
    // SupabaseClient.instance which is not initialised in tests, so we
    // intentionally do not exercise it here.
  });

  // ------------------------------------------------------------------
  // Stream providers (watch*)
  // ------------------------------------------------------------------

  group('watchTripChecklistsProvider', () {
    test('emits list from repository.watchTripChecklists', () async {
      repo.tripChecklistsResponse = [
        ChecklistEntity(
          id: 'cl-1',
          tripId: 'trip-1',
          name: 'A',
          createdAt: DateTime(2024, 1, 1),
        ),
      ];

      // Subscribe so the stream is materialised, then read via .future.
      final sub = container.listen(
        watchTripChecklistsProvider('trip-1'),
        (_, __) {},
      );
      addTearDown(sub.close);
      final first =
          await container.read(watchTripChecklistsProvider('trip-1').future);
      expect(first, hasLength(1));
      expect(first.first.id, 'cl-1');
    });

    test('emits empty list by default when no canned data', () async {
      final sub = container.listen(
        watchTripChecklistsProvider('trip-2'),
        (_, __) {},
      );
      addTearDown(sub.close);
      final first =
          await container.read(watchTripChecklistsProvider('trip-2').future);
      expect(first, isEmpty);
    });
  });

  group('watchChecklistWithItemsProvider', () {
    test('emits canned ChecklistWithItemsEntity from the repo', () async {
      final sub = container.listen(
        watchChecklistWithItemsProvider('cl-99'),
        (_, __) {},
      );
      addTearDown(sub.close);
      final first = await container
          .read(watchChecklistWithItemsProvider('cl-99').future);
      expect(first.checklist.id, 'cl-99');
    });
  });

  // ------------------------------------------------------------------
  // Controller — additional branches
  // ------------------------------------------------------------------

  group('ChecklistController.addItem (default assignedTo)', () {
    test('omits assignedTo (null) when not provided', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final item = await controller.addItem(
        checklistId: 'cl-1',
        title: 'Sunglasses',
      );
      expect(item, isNotNull);
      expect(repo.lastAddItemArgs!['title'], 'Sunglasses');
      expect(repo.lastAddItemArgs!['assignedTo'], isNull);
    });

    test('sets state.isLoading to false after success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      await controller.addItem(checklistId: 'cl-1', title: 'X');
      final state = container.read(checklistControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });

  group('ChecklistController.updateItem (assignedTo only)', () {
    test('forwards assignedTo without title', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.updateItem(
        itemId: 'it-1',
        assignedTo: 'u-7',
      );
      expect(ok, isTrue);
      expect(repo.lastUpdateItemArgs!['itemId'], 'it-1');
      expect(repo.lastUpdateItemArgs!['title'], isNull);
      expect(repo.lastUpdateItemArgs!['assignedTo'], 'u-7');
    });
  });

  group('ChecklistController.toggleItemCompletion (false branch)', () {
    test('forwards isCompleted=false correctly', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.toggleItemCompletion(
        itemId: 'it-1',
        isCompleted: false,
        userId: 'u-1',
      );
      expect(ok, isTrue);
      expect(repo.lastToggleArgs!['isCompleted'], isFalse);
    });
  });

  group('ChecklistController.reorderItems', () {
    test('forwards itemIds list to repository on success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.reorderItems(
        checklistId: 'cl-3',
        itemIds: const ['x', 'y', 'z'],
      );
      expect(ok, isTrue);
    });

    test('records the error message when reorder fails', () async {
      repo.throwOnReorderItems = Exception('order fail');
      final controller = container.read(checklistControllerProvider.notifier);
      await controller.reorderItems(
        checklistId: 'cl-3',
        itemIds: const ['x'],
      );
      final state = container.read(checklistControllerProvider);
      expect(state.error, contains('order fail'));
      expect(state.isLoading, isFalse);
    });
  });

  // ------------------------------------------------------------------
  // ChecklistOptimisticNotifier — additional behaviours
  // ------------------------------------------------------------------

  group('ChecklistOptimisticNotifier — multi-item', () {
    test('stores multiple items independently', () {
      final n = container.read(checklistItemOptimisticStateProvider.notifier);
      n.setOptimisticState('a', true);
      n.setOptimisticState('b', false);
      n.setOptimisticState('c', true);
      final state = container.read(checklistItemOptimisticStateProvider);
      expect(state['a'], isTrue);
      expect(state['b'], isFalse);
      expect(state['c'], isTrue);
      expect(state.length, 3);
    });

    test('clearOptimisticState removes only the target key', () {
      final n = container.read(checklistItemOptimisticStateProvider.notifier);
      n.setOptimisticState('a', true);
      n.setOptimisticState('b', false);
      n.clearOptimisticState('a');
      final state = container.read(checklistItemOptimisticStateProvider);
      expect(state.containsKey('a'), isFalse);
      expect(state['b'], isFalse);
      expect(state.length, 1);
    });

    test('clearAll wipes every key (including many)', () {
      final n = container.read(checklistItemOptimisticStateProvider.notifier);
      for (var i = 0; i < 10; i++) {
        n.setOptimisticState('item-$i', i.isEven);
      }
      expect(
        container.read(checklistItemOptimisticStateProvider).length,
        10,
      );
      n.clearAll();
      expect(
        container.read(checklistItemOptimisticStateProvider),
        isEmpty,
      );
    });
  });
}
