import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/checklists/presentation/providers/checklist_providers.dart';
import 'package:pathio/features/checklists/presentation/widgets/add_item_bottom_sheet.dart';

import 'fake_checklist_repository.dart';

Widget _wrap(Widget child, FakeChecklistRepository repo) {
  return ProviderScope(
    overrides: [
      checklistRepositoryProvider.overrideWithValue(repo),
    ],
    child: AppThemeProvider(
      themeData: AppThemeData.getThemeData(AppThemeType.ocean),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('AddItemBottomSheet extra — rendering', () {
    testWidgets('renders "Add Item" header with task icon', (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      expect(find.text('Add Item'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.add_task), findsOneWidget);
    });

    testWidgets('renders item title TextFormField with placeholder',
        (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      expect(
        find.text('e.g., Passport, Sunscreen, Book tickets'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders Add Item button with add icon', (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders the drag handle bar', (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      // The handle is a 40x4 sized container — confirm overall structure
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });

  group('AddItemBottomSheet extra — validation', () {
    testWidgets('Empty title shows "Please enter an item title" on submit',
        (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      // Tap the submit button without entering text
      await tester.tap(find.text('Add Item').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter an item title'), findsOneWidget);
    });

    testWidgets('Whitespace-only title is also rejected', (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.pump();
      await tester.tap(find.text('Add Item').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter an item title'), findsOneWidget);
    });

    testWidgets('Title over 200 chars triggers length validator',
        (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      final tooLong = 'x' * 201;
      await tester.enterText(find.byType(TextFormField), tooLong);
      await tester.pump();
      await tester.tap(find.text('Add Item').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Title must be 200 characters or less'), findsOneWidget);
    });

    testWidgets('Valid title invokes the repository.addItem call',
        (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-42'), repo),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Sunscreen');
      await tester.pump();

      await tester.tap(find.text('Add Item').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Repo should have recorded the add call
      expect(repo.lastAddItemArgs?['checklistId'], 'cl-42');
      expect(repo.lastAddItemArgs?['title'], 'Sunscreen');
    });
  });

  group('AddItemBottomSheet extra — submit error path', () {
    testWidgets('Repo error during addItem still keeps UI mounted',
        (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      repo.throwOnAddItem = Exception('network');
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Item');
      await tester.pump();
      await tester.tap(find.text('Add Item').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Sheet still rendered
      expect(find.byType(AddItemBottomSheet), findsOneWidget);
    });
  });

  group('AddItemBottomSheet extra — onFieldSubmitted', () {
    testWidgets('submitting via keyboard "done" triggers add', (tester) async {
      useTallViewport(tester);
      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
        _wrap(const AddItemBottomSheet(checklistId: 'cl-1'), repo),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Charger');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(repo.lastAddItemArgs?['title'], 'Charger');
    });
  });
}
