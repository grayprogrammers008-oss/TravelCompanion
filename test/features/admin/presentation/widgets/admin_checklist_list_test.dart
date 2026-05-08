import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_checklist.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_checklist_providers.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';
import 'package:travel_crew/features/admin/presentation/widgets/admin_checklist_list.dart';

class _StubSupabaseClient extends Mock implements SupabaseClient {}

class _FakeChecklistDataSource extends AdminRemoteDataSource {
  _FakeChecklistDataSource() : super(_StubSupabaseClient());

  bool throwOnDelete = false;
  bool throwOnUpdate = false;
  bool deleteResult = true;
  bool updateResult = true;

  final List<String> deleteCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<bool> deleteChecklist(String checklistId) async {
    deleteCalls.add(checklistId);
    if (throwOnDelete) throw Exception('delete failed');
    return deleteResult;
  }

  @override
  Future<bool> updateChecklist(String checklistId, {String? name}) async {
    updateCalls.add({'id': checklistId, 'name': name});
    if (throwOnUpdate) throw Exception('update failed');
    return updateResult;
  }
}

AdminChecklistModel _checklist({
  String id = 'c1',
  String tripId = 't1',
  String tripName = 'Bali Trip',
  String? tripDestination = 'Bali',
  String name = 'Packing List',
  DateTime? createdAt,
  int itemCount = 5,
  int completedCount = 2,
  int pendingCount = 3,
}) {
  return AdminChecklistModel(
    id: id,
    tripId: tripId,
    tripName: tripName,
    tripDestination: tripDestination,
    name: name,
    createdAt: createdAt ?? DateTime(2024, 5, 1),
    itemCount: itemCount,
    completedCount: completedCount,
    pendingCount: pendingCount,
  );
}

GoRouter _router({Widget? body}) {
  return GoRouter(
    initialLocation: '/admin',
    routes: [
      GoRoute(
        path: '/admin',
        builder: (_, _) =>
            Scaffold(body: body ?? const AdminChecklistList()),
      ),
      GoRoute(
        path: '/trips/:id/checklists',
        builder: (_, state) =>
            Scaffold(body: Text('CHECKLIST_${state.pathParameters['id']}')),
      ),
    ],
  );
}

Widget _wrap({
  required Future<List<AdminChecklistModel>> Function() future,
  AdminRemoteDataSource? dataSource,
}) {
  return ProviderScope(
    overrides: [
      adminChecklistsProvider.overrideWith((ref, params) => future()),
      if (dataSource != null)
        adminRemoteDataSourceProvider.overrideWithValue(dataSource),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AdminChecklistList - rendering', () {
    testWidgets('renders loading state', (tester) async {
      useTallViewport(tester);
      final completer = Completer<List<AdminChecklistModel>>();
      await tester.pumpWidget(_wrap(future: () => completer.future));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(const <AdminChecklistModel>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();
      expect(find.text('No checklists found'), findsOneWidget);
      expect(find.text('Checklists will appear here'), findsOneWidget);
      expect(find.byIcon(Icons.checklist_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('renders error state with retry button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async {
          throw Exception('network');
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Error loading checklists'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders search input and filter chips', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search by checklist or trip name...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('renders checklist card with name and trip', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(name: 'Beach Packing', tripName: 'Goa Holiday'),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Beach Packing'), findsOneWidget);
      expect(find.text('Goa Holiday'), findsOneWidget);
    });

    testWidgets('renders progress bar and percentage when items > 0',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(itemCount: 10, completedCount: 4, pendingCount: 6),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('renders Complete badge when fully completed', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(itemCount: 3, completedCount: 3, pendingCount: 0),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('renders Empty badge when itemCount is 0', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(itemCount: 0, completedCount: 0, pendingCount: 0),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Empty'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders In Progress badge when partially completed',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(itemCount: 5, completedCount: 2, pendingCount: 3),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('renders Items count chip', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(itemCount: 7)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('7 Items'), findsOneWidget);
    });

    testWidgets('renders Done count chip when completedCount > 0',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(itemCount: 5, completedCount: 3, pendingCount: 2),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('3 Done'), findsOneWidget);
    });

    testWidgets('renders Pending count chip when pendingCount > 0',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(itemCount: 5, completedCount: 1, pendingCount: 4),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('4 Pending'), findsOneWidget);
    });

    testWidgets('renders trip destination in footer', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(tripDestination: 'Paris')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Paris'), findsOneWidget);
    });

    testWidgets('renders Created date when destination is null',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _checklist(
            tripDestination: null,
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Created'), findsOneWidget);
    });

    testWidgets('renders edit and delete buttons', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist()],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('AdminChecklistList - search and filter', () {
    testWidgets('typing in search shows clear icon', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'pack');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear search resets', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'foo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('search empty state shows adjusted message', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'nothing');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Try adjusting your search'), findsOneWidget);
    });

    testWidgets('tapping Completed filter selects it', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      // No exception => pass
    });

    testWidgets('tapping Pending filter selects it', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Empty filter selects it', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        _wrap(future: () async => const <AdminChecklistModel>[]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empty'));
      await tester.pumpAndSettle();
    });
  });

  group('AdminChecklistList - actions', () {
    testWidgets('tapping card navigates to checklist detail route',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(tripId: 'tripXYZ')],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Packing List'));
      await tester.pumpAndSettle();
      expect(find.text('CHECKLIST_tripXYZ'), findsOneWidget);
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(name: 'My List', itemCount: 4)],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete Checklist'), findsOneWidget);
      expect(find.textContaining('My List'), findsAtLeastNWidgets(1));
      expect(find.textContaining('4 items'), findsOneWidget);
    });

    testWidgets('cancel from delete dialog does not delete', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist()],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(ds.deleteCalls, isEmpty);
    });

    testWidgets('confirm delete calls deleteChecklist', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(id: 'c-99')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(ds.deleteCalls, contains('c-99'));
    });

    testWidgets('delete error shows snackbar', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource()..throwOnDelete = true;
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist()],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Failed to delete checklist'), findsOneWidget);
    });

    testWidgets('tapping edit opens dialog', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(name: 'Old Name')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Edit Checklist'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('edit dialog cancel button dismisses', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist()],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Checklist'), findsNothing);
      expect(ds.updateCalls, isEmpty);
    });

    testWidgets('edit save with same name closes dialog without update',
        (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(name: 'Same')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      // Don't change the name; just tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(ds.updateCalls, isEmpty);
    });

    testWidgets('edit save with empty name does nothing', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(name: 'Existing')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      // Scope to dialog to avoid the page search TextField.
      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, '');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(ds.updateCalls, isEmpty);
    });

    testWidgets('edit save with new name calls updateChecklist',
        (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource();
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(id: 'c-1', name: 'Old')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'New Name');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(ds.updateCalls, hasLength(1));
      expect(ds.updateCalls.first['id'], 'c-1');
      expect(ds.updateCalls.first['name'], 'New Name');
    });

    testWidgets('edit save error shows snackbar', (tester) async {
      useTallViewport(tester);
      final ds = _FakeChecklistDataSource()..throwOnUpdate = true;
      await tester.pumpWidget(_wrap(
        future: () async => [_checklist(name: 'Old')],
        dataSource: ds,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'New');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Failed to update checklist'), findsOneWidget);
    });
  });
}
