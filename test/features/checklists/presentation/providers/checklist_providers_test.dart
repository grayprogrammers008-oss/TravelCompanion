import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/features/checklists/presentation/providers/checklist_providers.dart';

import '../widgets/fake_checklist_repository.dart';

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

  group('ChecklistController.createChecklist', () {
    test('returns the created entity and ends with isLoading=false',
        () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final result = await controller.createChecklist(
        tripId: 't',
        name: 'Trip Things',
        createdBy: 'u-1',
      );
      expect(result, isNotNull);
      expect(result!.name, 'Trip Things');
      expect(repo.lastCreateChecklistArgs, {
        'tripId': 't',
        'name': 'Trip Things',
        'createdBy': 'u-1',
      });
      final state = container.read(checklistControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('returns null and stores error message when use case throws',
        () async {
      repo.throwOnCreateChecklist = Exception('rls fail');
      final controller = container.read(checklistControllerProvider.notifier);
      final result = await controller.createChecklist(
        tripId: 't',
        name: 'X',
        createdBy: 'u',
      );
      expect(result, isNull);
      final state = container.read(checklistControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('rls fail'));
    });
  });

  group('ChecklistController.updateChecklist', () {
    test('returns true on success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.updateChecklist(
        checklistId: 'cl-1',
        name: 'New Name',
      );
      expect(ok, isTrue);
      expect(repo.lastUpdateChecklistArgs, {
        'checklistId': 'cl-1',
        'name': 'New Name',
      });
    });

    test('returns false and captures error on failure', () async {
      repo.throwOnUpdateChecklist = Exception('boom');
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.updateChecklist(
        checklistId: 'cl-1',
        name: 'X',
      );
      expect(ok, isFalse);
      expect(container.read(checklistControllerProvider).error,
          contains('boom'));
    });
  });

  group('ChecklistController.deleteChecklist', () {
    test('returns true on success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.deleteChecklist('cl-1');
      expect(ok, isTrue);
      expect(repo.lastDeleteChecklistId, 'cl-1');
    });

    test('returns false on failure', () async {
      repo.throwOnDeleteChecklist = Exception('boom');
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.deleteChecklist('cl-1');
      expect(ok, isFalse);
      expect(container.read(checklistControllerProvider).error,
          contains('boom'));
    });
  });

  group('ChecklistController.addItem', () {
    test('returns the created item on success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final item = await controller.addItem(
        checklistId: 'cl-1',
        title: 'Sunscreen',
        assignedTo: 'u-2',
      );
      expect(item, isNotNull);
      expect(item!.title, 'Sunscreen');
      expect(repo.lastAddItemArgs!['title'], 'Sunscreen');
      expect(repo.lastAddItemArgs!['assignedTo'], 'u-2');
    });

    test('returns null on failure', () async {
      repo.throwOnAddItem = Exception('add fail');
      final controller = container.read(checklistControllerProvider.notifier);
      final item =
          await controller.addItem(checklistId: 'cl-1', title: 'X');
      expect(item, isNull);
      expect(container.read(checklistControllerProvider).error,
          contains('add fail'));
    });
  });

  group('ChecklistController.updateItem', () {
    test('returns true on success and forwards args', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.updateItem(
        itemId: 'it-1',
        title: 'New title',
        assignedTo: 'u-9',
      );
      expect(ok, isTrue);
      expect(repo.lastUpdateItemArgs!['itemId'], 'it-1');
      expect(repo.lastUpdateItemArgs!['title'], 'New title');
      expect(repo.lastUpdateItemArgs!['assignedTo'], 'u-9');
    });

    test('returns false on failure', () async {
      repo.throwOnUpdateItem = Exception('upd fail');
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.updateItem(itemId: 'it-1', title: 'X');
      expect(ok, isFalse);
    });
  });

  group('ChecklistController.toggleItemCompletion', () {
    test('returns true and forwards args to repository', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.toggleItemCompletion(
        itemId: 'it-1',
        isCompleted: true,
        userId: 'u-1',
      );
      expect(ok, isTrue);
      expect(repo.lastToggleArgs, {
        'itemId': 'it-1',
        'isCompleted': true,
        'userId': 'u-1',
      });
    });

    test('returns false on failure', () async {
      repo.throwOnToggleItem = Exception('toggle fail');
      final controller = container.read(checklistControllerProvider.notifier);
      final ok = await controller.toggleItemCompletion(
        itemId: 'it-1',
        isCompleted: false,
        userId: 'u-1',
      );
      expect(ok, isFalse);
    });
  });

  group('ChecklistController.deleteItem', () {
    test('returns true on success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      expect(await controller.deleteItem('it-1'), isTrue);
      expect(repo.lastDeleteItemId, 'it-1');
    });

    test('returns false on failure', () async {
      repo.throwOnDeleteItem = Exception('boom');
      final controller = container.read(checklistControllerProvider.notifier);
      expect(await controller.deleteItem('it-1'), isFalse);
    });
  });

  group('ChecklistController.reorderItems', () {
    test('returns true on success', () async {
      final controller = container.read(checklistControllerProvider.notifier);
      expect(
        await controller.reorderItems(
          checklistId: 'cl-1',
          itemIds: ['a', 'b'],
        ),
        isTrue,
      );
    });

    test('returns false on failure', () async {
      repo.throwOnReorderItems = Exception('boom');
      final controller = container.read(checklistControllerProvider.notifier);
      expect(
        await controller.reorderItems(
          checklistId: 'cl-1',
          itemIds: ['a', 'b'],
        ),
        isFalse,
      );
    });
  });

  group('ChecklistOptimisticNotifier', () {
    test('starts empty', () {
      expect(
        container.read(checklistItemOptimisticStateProvider),
        isEmpty,
      );
    });

    test('setOptimisticState writes a value, then clearOptimisticState removes it',
        () {
      final notifier =
          container.read(checklistItemOptimisticStateProvider.notifier);
      notifier.setOptimisticState('it-1', true);
      expect(
        container.read(checklistItemOptimisticStateProvider)['it-1'],
        isTrue,
      );

      notifier.clearOptimisticState('it-1');
      expect(
        container
            .read(checklistItemOptimisticStateProvider)
            .containsKey('it-1'),
        isFalse,
      );
    });

    test('setOptimisticState supports overwriting an existing key', () {
      final notifier =
          container.read(checklistItemOptimisticStateProvider.notifier);
      notifier.setOptimisticState('it-1', true);
      notifier.setOptimisticState('it-1', false);
      expect(
        container.read(checklistItemOptimisticStateProvider)['it-1'],
        isFalse,
      );
    });

    test('clearAll wipes all keys', () {
      final notifier =
          container.read(checklistItemOptimisticStateProvider.notifier);
      notifier.setOptimisticState('a', true);
      notifier.setOptimisticState('b', false);
      notifier.setOptimisticState('c', true);
      notifier.clearAll();
      expect(container.read(checklistItemOptimisticStateProvider), isEmpty);
    });

    test('clearOptimisticState on a missing key is a no-op', () {
      final notifier =
          container.read(checklistItemOptimisticStateProvider.notifier);
      notifier.clearOptimisticState('non-existent');
      expect(container.read(checklistItemOptimisticStateProvider), isEmpty);
    });
  });

  group('tripChecklistsProvider', () {
    test('returns repository.getTripChecklists result', () async {
      final tripId = 't-1';
      final result =
          await container.read(tripChecklistsProvider(tripId).future);
      expect(result, isEmpty);
      expect(repo.lastTripIdRequested, tripId);
    });
  });

  group('checklistWithItemsProvider', () {
    test('returns repository.getChecklistWithItems result', () async {
      final result = await container
          .read(checklistWithItemsProvider('cl-1').future);
      expect(result.checklist.id, 'cl-1');
      expect(repo.lastChecklistIdForItems, 'cl-1');
    });
  });
}
