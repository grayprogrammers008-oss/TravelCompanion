import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/checklists/domain/entities/checklist_entity.dart';
import 'package:pathio/features/checklists/presentation/providers/checklist_providers.dart';
import 'package:pathio/features/checklists/presentation/widgets/edit_checklist_dialog.dart';

import 'fake_checklist_repository.dart';

void main() {
  final theme = AppThemeData.getThemeData(AppThemeType.ocean);

  ChecklistEntity makeChecklist({
    String id = 'cl-1',
    String name = 'Packing List',
  }) =>
      ChecklistEntity(
        id: id,
        tripId: 'trip-1',
        name: name,
        createdAt: DateTime(2024, 1, 1),
      );

  Future<void> showDialogFor(
    WidgetTester tester, {
    required FakeChecklistRepository repo,
    required ChecklistEntity checklist,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checklistRepositoryProvider.overrideWithValue(repo),
        ],
        child: AppThemeProvider(
          themeData: theme,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog<bool>(
                      context: context,
                      builder: (_) =>
                          EditChecklistDialog(checklist: checklist),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('EditChecklistDialog', () {
    testWidgets('renders pre-filled name and Save/Cancel buttons',
        (tester) async {
      final repo = FakeChecklistRepository();
      await showDialogFor(tester, repo: repo, checklist: makeChecklist());

      expect(find.text('Edit Checklist'), findsOneWidget);
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller!.text, 'Packing List');
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel pops without invoking controller', (tester) async {
      final repo = FakeChecklistRepository();
      await showDialogFor(tester, repo: repo, checklist: makeChecklist());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(EditChecklistDialog), findsNothing);
      expect(repo.lastUpdateChecklistArgs, isNull);
    });

    testWidgets('shows snackbar when name is empty', (tester) async {
      final repo = FakeChecklistRepository();
      await showDialogFor(tester, repo: repo, checklist: makeChecklist());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Checklist name cannot be empty'), findsOneWidget);
      expect(repo.lastUpdateChecklistArgs, isNull);
      expect(find.byType(EditChecklistDialog), findsOneWidget);
    });

    testWidgets('saving the same name pops without calling controller',
        (tester) async {
      final repo = FakeChecklistRepository();
      await showDialogFor(
          tester, repo: repo, checklist: makeChecklist(name: 'Same'));

      // Don't change text, just save
      await tester.enterText(find.byType(TextField), 'Same');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdateChecklistArgs, isNull);
      expect(find.byType(EditChecklistDialog), findsNothing);
    });

    testWidgets('successful save invokes updateChecklist with trimmed name',
        (tester) async {
      final repo = FakeChecklistRepository();
      await showDialogFor(tester, repo: repo, checklist: makeChecklist());

      await tester.enterText(find.byType(TextField), '  Beach Trip List  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdateChecklistArgs, isNotNull);
      expect(repo.lastUpdateChecklistArgs!['checklistId'], 'cl-1');
      expect(repo.lastUpdateChecklistArgs!['name'], 'Beach Trip List');
      expect(find.byType(EditChecklistDialog), findsNothing);
      // Success snackbar
      expect(find.text('Checklist updated'), findsOneWidget);
    });

    testWidgets('shows error snackbar when controller fails', (tester) async {
      final repo = FakeChecklistRepository();
      repo.throwOnUpdateChecklist = Exception('db down');
      await showDialogFor(tester, repo: repo, checklist: makeChecklist());

      await tester.enterText(find.byType(TextField), 'Different');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to update checklist'), findsOneWidget);
      expect(find.byType(EditChecklistDialog), findsOneWidget);
    });
  });
}
