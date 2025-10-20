import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/presentation/widgets/checklist_item_tile.dart';

void main() {
  group('ChecklistItemTile Widget Tests', () {
    late ChecklistItemEntity testItem;

    setUp(() {
      testItem = ChecklistItemEntity(
        id: 'item-1',
        checklistId: 'checklist-1',
        title: 'Test Item',
        isCompleted: false,
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('Should display item title and checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Test Item'), findsOneWidget);

      // Verify checkbox is displayed
      expect(find.byType(Checkbox), findsOneWidget);

      // Verify checkbox is not checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('Should call onToggle when checkbox is tapped', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () => toggled = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      // Tap the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify onToggle was called
      expect(toggled, isTrue);
    });

    testWidgets('Should show delete confirmation dialog ONCE when swiped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Perform swipe gesture from right to left
      await tester.drag(find.byType(ChecklistItemTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify delete confirmation dialog appears
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Remove "Test Item" from this checklist?'), findsOneWidget);

      // Verify only ONE dialog is shown (not two)
      expect(find.byType(AlertDialog), findsOneWidget);

      // Verify dialog has Cancel and Delete buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Should cancel delete when Cancel is tapped', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Swipe to show delete
      await tester.drag(find.byType(ChecklistItemTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify onDelete was NOT called
      expect(deleted, isFalse);

      // Verify item is still visible
      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('Should delete item when Delete is confirmed', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Swipe to show delete
      await tester.drag(find.byType(ChecklistItemTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify onDelete was called
      expect(deleted, isTrue);
    });

    testWidgets('Should show strikethrough text when item is completed', (tester) async {
      final completedItem = ChecklistItemEntity(
        id: 'item-2',
        checklistId: 'checklist-1',
        title: 'Completed Item',
        isCompleted: true,
        orderIndex: 0,
        completedBy: 'user-1',
        completedByName: 'Test User',
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: completedItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Find the text widget
      final textWidget = tester.widget<Text>(find.text('Completed Item'));

      // Verify it has strikethrough decoration
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));

      // Verify checkbox is checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      // Verify completed badge is shown
      expect(find.text('by Test User'), findsOneWidget);
    });

    testWidgets('Should show assigned badge when item has assignedTo', (tester) async {
      final assignedItem = ChecklistItemEntity(
        id: 'item-3',
        checklistId: 'checklist-1',
        title: 'Assigned Item',
        isCompleted: false,
        orderIndex: 0,
        assignedTo: 'user-2',
        assignedToName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: assignedItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify assigned badge is shown
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('Should call onEdit when long-pressed', (tester) async {
      bool edited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () {},
              onEdit: () => edited = true,
            ),
          ),
        ),
      );

      // Long press on the tile
      await tester.longPress(find.text('Test Item'));
      await tester.pumpAndSettle();

      // Verify onEdit was called
      expect(edited, isTrue);
    });

    testWidgets('Should show red delete background when swiping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Start swiping (but don't complete the swipe)
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChecklistItemTile)));
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();

      // Verify delete icon is visible
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Cancel the gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Should not show onEdit callback if not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () {},
              // onEdit not provided
            ),
          ),
        ),
      );

      // Try long press (should not crash)
      await tester.longPress(find.text('Test Item'));
      await tester.pumpAndSettle();

      // Should not crash and item should still be visible
      expect(find.text('Test Item'), findsOneWidget);
    });
  });

  group('ChecklistItemTile Delete Confirmation Tests', () {
    testWidgets('Should show only ONE dialog on swipe delete', (tester) async {
      final testItem = ChecklistItemEntity(
        id: 'item-test',
        checklistId: 'checklist-test',
        title: 'Test2',
        isCompleted: false,
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChecklistItemTile(
              item: testItem,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Swipe to trigger delete
      await tester.drag(find.byType(ChecklistItemTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Count number of "Delete Item" dialogs
      final deleteDialogTitles = find.text('Delete Item');
      expect(deleteDialogTitles, findsOneWidget, reason: 'Should show exactly ONE delete confirmation dialog');

      // Count number of AlertDialog widgets
      final alertDialogs = find.byType(AlertDialog);
      expect(alertDialogs, findsOneWidget, reason: 'Should show exactly ONE AlertDialog');

      // Verify the dialog content
      expect(find.text('Remove "Test2" from this checklist?'), findsOneWidget);
    });
  });
}
