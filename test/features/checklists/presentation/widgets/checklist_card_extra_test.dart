import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/checklists/domain/entities/checklist_entity.dart';
import 'package:pathio/features/checklists/presentation/providers/checklist_providers.dart';
import 'package:pathio/features/checklists/presentation/widgets/checklist_card.dart';

import 'fake_checklist_repository.dart';

void main() {
  final theme = AppThemeData.getThemeData(AppThemeType.ocean);

  ChecklistEntity makeChecklist({
    String id = 'cl-1',
    String tripId = 'trip-1',
    String name = 'Packing List',
  }) =>
      ChecklistEntity(
        id: id,
        tripId: tripId,
        name: name,
        createdAt: DateTime(2024, 1, 1),
      );

  ChecklistItemEntity makeItem({
    required String id,
    required String checklistId,
    bool isCompleted = false,
  }) =>
      ChecklistItemEntity(
        id: id,
        checklistId: checklistId,
        title: 'Item $id',
        isCompleted: isCompleted,
      );

  Widget wrap(Widget child, {required FakeChecklistRepository repo}) {
    return ProviderScope(
      overrides: [
        checklistRepositoryProvider.overrideWithValue(repo),
      ],
      child: AppThemeProvider(
        themeData: theme,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Loading branch — visible on the very first frame before the
  // future provider resolves.
  // ---------------------------------------------------------------

  group('ChecklistCard — loading branch', () {
    testWidgets('shows "Loading items..." text on first frame',
        (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      // Do NOT settle — want the loading frame.
      expect(find.text('Loading items...'), findsOneWidget);
      // The checklist name is still visible on the loading branch.
      expect(find.text('Packing List'), findsOneWidget);
      // Drain.
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('renders the checklist icon during loading', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      expect(find.byIcon(Icons.checklist), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  // ---------------------------------------------------------------
  // Data branch — additional progress percentage scenarios.
  // ---------------------------------------------------------------

  group('ChecklistCard — progress display', () {
    testWidgets('renders 33% complete for 1/3 items', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: [
          makeItem(id: 'a', checklistId: 'cl-1', isCompleted: true),
          makeItem(id: 'b', checklistId: 'cl-1'),
          makeItem(id: 'c', checklistId: 'cl-1'),
        ],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 items'), findsOneWidget);
      expect(find.text('33% Complete'), findsOneWidget);
    });

    testWidgets('renders 25% complete for 1/4 items', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: [
          makeItem(id: 'a', checklistId: 'cl-1', isCompleted: true),
          makeItem(id: 'b', checklistId: 'cl-1'),
          makeItem(id: 'c', checklistId: 'cl-1'),
          makeItem(id: 'd', checklistId: 'cl-1'),
        ],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 of 4 items'), findsOneWidget);
      expect(find.text('25% Complete'), findsOneWidget);
    });

    testWidgets('LinearProgressIndicator value matches progress fraction',
        (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: [
          makeItem(id: 'a', checklistId: 'cl-1', isCompleted: true),
          makeItem(id: 'b', checklistId: 'cl-1'),
        ],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final lp = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(lp.value, closeTo(0.5, 0.001));
    });
  });

  // ---------------------------------------------------------------
  // Menu branches
  // ---------------------------------------------------------------

  group('ChecklistCard — popup menu', () {
    testWidgets('renders menu when only onEdit is provided', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      var edited = 0;
      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
            onEdit: () => edited++,
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Only Edit should be present — no Delete option.
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(edited, 1);
    });

    testWidgets('renders menu when only onDelete is provided', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      var deleted = 0;
      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
            onDelete: () => deleted++,
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('menu icons match production design', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
            onEdit: () {},
            onDelete: () {},
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Edit and Delete icons inside the menu.
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('does not invoke onEdit when only onDelete tapped',
        (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      var edited = 0;
      var deleted = 0;
      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
            onEdit: () => edited++,
            onDelete: () => deleted++,
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, 1);
      expect(edited, 0);
    });
  });

  // ---------------------------------------------------------------
  // Top-level structure
  // ---------------------------------------------------------------

  group('ChecklistCard — structural', () {
    testWidgets('renders Card + InkWell + checklist icon', (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets(
        'no popup menu when neither onEdit nor onDelete provided',
        (tester) async {
      final repo = FakeChecklistRepository();
      final checklist = makeChecklist();
      repo.checklistWithItemsResponse = ChecklistWithItemsEntity(
        checklist: checklist,
        items: const [],
      );

      await tester.pumpWidget(
        wrap(
          ChecklistCard(
            checklist: checklist,
            tripId: 'trip-1',
            onTap: () {},
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
