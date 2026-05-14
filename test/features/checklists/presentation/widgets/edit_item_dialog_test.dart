import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/checklists/domain/entities/checklist_entity.dart';
import 'package:pathio/features/checklists/presentation/providers/checklist_providers.dart';
import 'package:pathio/features/checklists/presentation/widgets/edit_item_dialog.dart';

import 'fake_checklist_repository.dart';

void main() {
  final theme = AppThemeData.getThemeData(AppThemeType.ocean);

  ChecklistItemEntity makeItem({
    String id = 'it-1',
    String title = 'Passport',
    String? assignedTo,
  }) =>
      ChecklistItemEntity(
        id: id,
        checklistId: 'cl-1',
        title: title,
        assignedTo: assignedTo,
      );

  Future<bool?> showAndCapture(
    WidgetTester tester, {
    required FakeChecklistRepository repo,
    required ChecklistItemEntity item,
  }) async {
    bool? result;
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
                    onPressed: () async {
                      result = await showDialog<bool>(
                        context: context,
                        builder: (_) => EditItemDialog(item: item),
                      );
                    },
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
    return result;
  }

  group('EditItemDialog', () {
    testWidgets('renders pre-filled title and Save/Cancel buttons',
        (tester) async {
      final repo = FakeChecklistRepository();
      await showAndCapture(tester, repo: repo, item: makeItem());

      expect(find.text('Edit Item'), findsOneWidget);
      // The TextField is initialized with the title text
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller!.text, 'Passport');
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel pops without invoking the controller', (tester) async {
      final repo = FakeChecklistRepository();
      await showAndCapture(tester, repo: repo, item: makeItem());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(EditItemDialog), findsNothing);
      expect(repo.lastUpdateItemArgs, isNull);
    });

    testWidgets('shows snackbar when title is empty on Save', (tester) async {
      final repo = FakeChecklistRepository();
      await showAndCapture(tester, repo: repo, item: makeItem());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Title cannot be empty'), findsOneWidget);
      expect(repo.lastUpdateItemArgs, isNull);
      // Dialog should still be open
      expect(find.byType(EditItemDialog), findsOneWidget);
    });

    testWidgets('successful save calls updateItem with trimmed title',
        (tester) async {
      final repo = FakeChecklistRepository();
      await showAndCapture(
          tester, repo: repo, item: makeItem(assignedTo: 'u-1'));

      await tester.enterText(find.byType(TextField), '  New Title  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdateItemArgs, isNotNull);
      expect(repo.lastUpdateItemArgs!['itemId'], 'it-1');
      expect(repo.lastUpdateItemArgs!['title'], 'New Title');
      expect(repo.lastUpdateItemArgs!['assignedTo'], 'u-1');
      // Dialog should close
      expect(find.byType(EditItemDialog), findsNothing);
    });

    testWidgets('shows error snackbar when controller fails', (tester) async {
      final repo = FakeChecklistRepository();
      repo.throwOnUpdateItem = Exception('boom');
      await showAndCapture(tester, repo: repo, item: makeItem());

      await tester.enterText(find.byType(TextField), 'Updated');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to update item'), findsOneWidget);
      // Dialog should remain open
      expect(find.byType(EditItemDialog), findsOneWidget);
    });
  });
}
