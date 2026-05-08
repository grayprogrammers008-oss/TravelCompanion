import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/presentation/widgets/checklist_item_tile.dart';

void main() {
  final theme = AppThemeData.getThemeData(AppThemeType.ocean);

  ChecklistItemEntity makeItem({
    String id = 'it-1',
    String title = 'Passport',
    bool isCompleted = false,
    String? assignedToName,
    String? completedByName,
  }) =>
      ChecklistItemEntity(
        id: id,
        checklistId: 'cl-1',
        title: title,
        isCompleted: isCompleted,
        assignedToName: assignedToName,
        completedByName: completedByName,
      );

  Widget wrap(Widget child) {
    return AppThemeProvider(
      themeData: theme,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SizedBox(width: 600, child: child)),
      ),
    );
  }

  group('ChecklistItemTile', () {
    testWidgets('shows item title and an unchecked checkbox by default',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('Passport'), findsOneWidget);
      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, isFalse);
    });

    testWidgets('renders strikethrough text and check icon when completed',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: true),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      // Check icon shown for completed items
      expect(find.byIcon(Icons.check), findsOneWidget);

      final titleWidget = tester.widget<Text>(find.text('Passport'));
      expect(titleWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('optimisticIsCompleted overrides item.isCompleted',
        (tester) async {
      // item.isCompleted=false but optimistic=true -> show as completed
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: false),
          optimisticIsCompleted: true,
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, isTrue);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tapping the row triggers onToggle', (tester) async {
      var toggled = 0;
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () => toggled++,
          onDelete: () {},
        )),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(toggled, 1);
    });

    testWidgets('tapping the checkbox triggers onToggle', (tester) async {
      var toggled = 0;
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () => toggled++,
          onDelete: () {},
        )),
      );

      await tester.tap(find.byType(Checkbox));
      expect(toggled, 1);
    });

    testWidgets('long press triggers onEdit when provided', (tester) async {
      var edited = 0;
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
          onEdit: () => edited++,
        )),
      );

      await tester.longPress(find.byType(InkWell).first);
      expect(edited, 1);
    });

    testWidgets('shows assigned-to badge when assignedToName provided',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(assignedToName: 'Alice'),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows completed-by badge when completedByName provided',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(completedByName: 'Bob', isCompleted: true),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('by Bob'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows both badges side by side when present',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(
            assignedToName: 'Alice',
            completedByName: 'Bob',
            isCompleted: true,
          ),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('by Bob'), findsOneWidget);
    });

    testWidgets('hides badges when no assignment data', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('Dismissible with confirm dialog accepts deletion',
        (tester) async {
      var deleted = 0;
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () => deleted++,
        )),
      );

      // Swipe end-to-start (left) on the dismissible
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Remove "Passport" from this checklist?'),
          findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, 1);
    });

    testWidgets('Dismissible cancels and does not call onDelete',
        (tester) async {
      var deleted = 0;
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () => deleted++,
        )),
      );

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, 0);
    });
  });
}
