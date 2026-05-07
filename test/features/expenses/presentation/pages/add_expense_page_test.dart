// Widget tests for `AddExpensePage` (standalone mode).
//
// Strategy: render the page in standalone mode (tripId: null) — this skips
// `_buildMemberPicker` and `_buildWhoPaidPicker`, both of which would
// otherwise hit `SupabaseClientWrapper.currentUserId` (a static singleton
// that throws without Supabase initialization). The test mode mocks no
// trip data because the build-tree never reads `tripProvider` when tripId
// is null.
//
// We DO NOT submit the form because `_handleSubmit` reads
// `SupabaseClientWrapper.currentUserId` and would throw "Supabase not
// initialized". Submitting the form is therefore covered indirectly by
// the ExpenseController tests in
// `test/features/expenses/presentation/providers/`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/easy_mode_provider.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/expenses/presentation/pages/add_expense_page.dart';

final _theme = AppThemeData.getThemeData(AppThemeType.ocean);

Widget _buildPage({String? tripId}) {
  return ProviderScope(
    overrides: [
      theme_provider.currentThemeDataProvider.overrideWith((_) => _theme),
      easyModeConfigProvider.overrideWith((_) => const EasyModeConfig()),
    ],
    child: AppThemeProvider(
      themeData: _theme,
      child: MaterialApp(
        home: AddExpensePage(tripId: tripId),
      ),
    ),
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

  Future<void> drainAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('AddExpensePage — standalone mode (tripId == null)', () {
    testWidgets('renders "Track Your Spending" header', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      expect(find.text('Track Your Spending'), findsOneWidget);
    });

    testWidgets('renders the standalone subtitle', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      expect(
        find.text('Add a personal expense to track your spending'),
        findsOneWidget,
      );
    });

    testWidgets('renders back button with "Back" tooltip', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsAtLeastNWidgets(1));
    });

    testWidgets('renders the receipt_long header icon', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      expect(find.byIcon(Icons.receipt_long), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Expense Title input field', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      expect(find.text('Expense Title *'), findsOneWidget);
    });

    testWidgets('renders Amount input field with required marker',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      expect(find.text('Amount *'), findsOneWidget);
    });

    testWidgets('does not render member picker labels in standalone mode',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      // "Split With *" appears only in trip mode
      expect(find.text('Split With *'), findsNothing);
      // "Paid By *" appears only in trip mode
      expect(find.text('Paid By *'), findsNothing);
    });

    testWidgets('user can type into the Expense Title field', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      // Find the TextFormField for title (first one)
      final titleFields = find.byType(TextFormField);
      expect(titleFields, findsAtLeastNWidgets(1));

      await tester.enterText(titleFields.first, 'Lunch at cafe');
      await tester.pump();

      expect(find.text('Lunch at cafe'), findsOneWidget);
    });

    testWidgets('user can type into the Amount field', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      // Amount is the second TextFormField (after title)
      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeastNWidgets(2));

      await tester.enterText(fields.at(1), '123.45');
      await tester.pump();

      expect(find.text('123.45'), findsOneWidget);
    });

    testWidgets('renders Description input field (optional)', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      // 'Description' label or "(Optional)" appears in the form
      expect(
        find.textContaining('Description'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
