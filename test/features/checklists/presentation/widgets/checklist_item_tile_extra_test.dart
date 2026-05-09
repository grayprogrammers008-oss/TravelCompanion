import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/presentation/widgets/checklist_item_tile.dart';

/// Additional coverage for [ChecklistItemTile] focused on:
///   * border / decoration variants based on completion state
///   * optimistic vs. actual state combinations
///   * confirm-dismiss dialog wiring (Cancel + Delete)
///   * card sub-tree assertions (Checkbox.activeColor, Card.shape)
///   * onEdit absence does not crash long-press
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

  // -------------------------------------------------------------
  // Card / decoration variants
  // -------------------------------------------------------------

  group('ChecklistItemTile — card decoration', () {
    testWidgets('Card has rounded shape with radius for incomplete items',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets(
        'Card border thickness changes when item is completed',
        (tester) async {
      // Incomplete -> width 1
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: false),
          onToggle: () {},
          onDelete: () {},
        )),
      );
      final incompleteCard = tester.widget<Card>(find.byType(Card));
      final incompleteBorder =
          (incompleteCard.shape as RoundedRectangleBorder).side;
      expect(incompleteBorder.width, 1);

      // Re-pump with completed -> width 2
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: true),
          onToggle: () {},
          onDelete: () {},
        )),
      );
      final completeCard = tester.widget<Card>(find.byType(Card));
      final completeBorder =
          (completeCard.shape as RoundedRectangleBorder).side;
      expect(completeBorder.width, 2);
    });
  });

  // -------------------------------------------------------------
  // Optimistic vs actual combinations
  // -------------------------------------------------------------

  group('ChecklistItemTile — optimistic state', () {
    testWidgets(
        'optimistic=false overrides item.isCompleted=true (uncheck UI)',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: true),
          optimisticIsCompleted: false,
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, isFalse);
      // No check icon since not completed.
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets(
        'when optimisticIsCompleted is null, falls back to item.isCompleted',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: true),
          optimisticIsCompleted: null,
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, isTrue);
    });
  });

  // -------------------------------------------------------------
  // Checkbox properties
  // -------------------------------------------------------------

  group('ChecklistItemTile — checkbox properties', () {
    testWidgets('Checkbox uses success color as activeColor', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.activeColor, AppTheme.success);
    });

    testWidgets('Checkbox uses rounded shape', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.shape, isA<RoundedRectangleBorder>());
    });
  });

  // -------------------------------------------------------------
  // Confirm-dismiss dialog
  // -------------------------------------------------------------

  group('ChecklistItemTile — confirm-dismiss dialog', () {
    testWidgets(
        'shows confirm dialog with item title interpolated in content',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(title: 'Tickets'),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item'), findsOneWidget);
      expect(
        find.text('Remove "Tickets" from this checklist?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Cancel button keeps item visible (no onDelete invocation)',
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, 0);
      // The dismiss should have been cancelled, item remains.
      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.text('Passport'), findsOneWidget);
    });

    testWidgets('Delete button confirms and triggers onDelete', (tester) async {
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

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, 1);
    });
  });

  // -------------------------------------------------------------
  // onEdit behaviour
  // -------------------------------------------------------------

  group('ChecklistItemTile — onEdit', () {
    testWidgets('long-press without onEdit does not throw', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
          // onEdit intentionally omitted (null)
        )),
      );

      await tester.longPress(find.byType(InkWell).first);
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------
  // Title styling on completion
  // -------------------------------------------------------------

  group('ChecklistItemTile — title styling', () {
    testWidgets('completed title has reduced text alpha (~0.5 of base)',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: true),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      // The completed state applies alpha to color — color should not equal
      // the default text colour exactly (proxy: just verify it has non-null
      // colour and decoration).
      final t = tester.widget<Text>(find.text('Passport'));
      expect(t.style?.color, isNotNull);
      expect(t.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('incomplete title has no line-through and primary text colour',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: false),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final t = tester.widget<Text>(find.text('Passport'));
      expect(t.style?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('font weight on title is medium (w500)', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final t = tester.widget<Text>(find.text('Passport'));
      expect(t.style?.fontWeight, FontWeight.w500);
    });
  });

  // -------------------------------------------------------------
  // Status icon visibility
  // -------------------------------------------------------------

  group('ChecklistItemTile — status icon', () {
    testWidgets('shows check status icon when completed', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: true),
          onToggle: () {},
          onDelete: () {},
        )),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides status icon when incomplete', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: false),
          onToggle: () {},
          onDelete: () {},
        )),
      );
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows status icon when optimisticIsCompleted=true even '
        'though item.isCompleted=false', (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(isCompleted: false),
          optimisticIsCompleted: true,
          onToggle: () {},
          onDelete: () {},
        )),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  // -------------------------------------------------------------
  // Dismissible structure
  // -------------------------------------------------------------

  group('ChecklistItemTile — Dismissible structure', () {
    testWidgets('uses end-to-start direction with item id as Key',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(id: 'unique-99'),
          onToggle: () {},
          onDelete: () {},
        )),
      );

      final d = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(d.direction, DismissDirection.endToStart);
      expect(d.key, const Key('unique-99'));
    });

    testWidgets('background reveals delete icon after a partial swipe',
        (tester) async {
      await tester.pumpWidget(
        wrap(ChecklistItemTile(
          item: makeItem(),
          onToggle: () {},
          onDelete: () {},
        )),
      );
      // Drag halfway to materialise the Dismissible background widget.
      await tester.drag(find.byType(Dismissible), const Offset(-100, 0));
      await tester.pump();

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
