import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/trips/presentation/pages/trip_filter_page.dart';

/// Build a router that hosts the TripFilterPage and a /home route to pop back to.
GoRouter _buildRouter({
  double? initialMinBudget,
  double? initialMaxBudget,
  DateTime? initialCreatedAfter,
  DateTime? initialCreatedBefore,
  void Function(Map<String, dynamic>?)? onPopResult,
}) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await context.push<Map<String, dynamic>>(
                    '/filter',
                  );
                  onPopResult?.call(result);
                },
                child: const Text('Open Filter'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/filter',
        builder: (_, _) => TripFilterPage(
          initialMinBudget: initialMinBudget,
          initialMaxBudget: initialMaxBudget,
          initialCreatedAfter: initialCreatedAfter,
          initialCreatedBefore: initialCreatedBefore,
        ),
      ),
    ],
  );
}

Future<void> _pumpFilterPage(
  WidgetTester tester, {
  double? initialMinBudget,
  double? initialMaxBudget,
  DateTime? initialCreatedAfter,
  DateTime? initialCreatedBefore,
  void Function(Map<String, dynamic>?)? onPopResult,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = _buildRouter(
    initialMinBudget: initialMinBudget,
    initialMaxBudget: initialMaxBudget,
    initialCreatedAfter: initialCreatedAfter,
    initialCreatedBefore: initialCreatedBefore,
    onPopResult: onPopResult,
  );

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();

  // Tap "Open Filter" button to navigate
  await tester.tap(find.text('Open Filter'));
  await tester.pumpAndSettle();
}

void main() {
  group('TripFilterPage Widget Tests', () {
    testWidgets('renders title "Filter Trips"', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('Filter Trips'), findsOneWidget);
    });

    testWidgets('shows Budget Range section', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('Budget Range'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('shows Date Created section', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('Date Created'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows Min Budget and Max Budget text fields', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('Min Budget'), findsOneWidget);
      expect(find.text('Max Budget'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows From Date and To Date placeholders by default',
        (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('From Date'), findsOneWidget);
      expect(find.text('To Date'), findsOneWidget);
    });

    testWidgets('shows Apply Filters button', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does NOT show Clear All button when no filters initially',
        (tester) async {
      await _pumpFilterPage(tester);
      expect(find.text('Clear All'), findsNothing);
    });

    testWidgets('shows Clear All button when initial budget is set',
        (tester) async {
      await _pumpFilterPage(tester, initialMinBudget: 1000);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('shows Clear All button when initial date is set',
        (tester) async {
      await _pumpFilterPage(tester, initialCreatedAfter: DateTime(2024, 1, 1));
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('initial min budget value is set on TextField', (tester) async {
      await _pumpFilterPage(tester, initialMinBudget: 5000);

      final tf = tester.widget<TextField>(find.byType(TextField).first);
      expect(tf.controller!.text, '5000');
    });

    testWidgets('initial max budget value is set on TextField', (tester) async {
      await _pumpFilterPage(tester, initialMaxBudget: 25000);

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[1].controller!.text, '25000');
    });

    testWidgets('initial dates display formatted text', (tester) async {
      await _pumpFilterPage(
        tester,
        initialCreatedAfter: DateTime(2024, 3, 15),
        initialCreatedBefore: DateTime(2024, 6, 30),
      );

      expect(find.text('15/03/2024'), findsOneWidget);
      expect(find.text('30/06/2024'), findsOneWidget);
    });

    testWidgets('typing in Min Budget field updates value', (tester) async {
      await _pumpFilterPage(tester);

      await tester.enterText(find.byType(TextField).first, '500');
      await tester.pump();

      final tf = tester.widget<TextField>(find.byType(TextField).first);
      expect(tf.controller!.text, '500');
    });

    testWidgets('typing in Max Budget field updates value', (tester) async {
      await _pumpFilterPage(tester);

      await tester.enterText(find.byType(TextField).at(1), '15000');
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[1].controller!.text, '15000');
    });

    testWidgets('Apply Filters button pops with budget filters when set',
        (tester) async {
      Map<String, dynamic>? popped;
      await _pumpFilterPage(
        tester,
        onPopResult: (r) => popped = r,
      );

      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.enterText(find.byType(TextField).at(1), '50000');
      await tester.pump();

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!['minBudget'], 1000.0);
      expect(popped!['maxBudget'], 50000.0);
    });

    testWidgets('Apply Filters returns null budgets when fields empty',
        (tester) async {
      Map<String, dynamic>? popped;
      await _pumpFilterPage(tester, onPopResult: (r) => popped = r);

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!['minBudget'], null);
      expect(popped!['maxBudget'], null);
      expect(popped!['createdAfter'], null);
      expect(popped!['createdBefore'], null);
    });

    testWidgets('Clear All pops with all-null filters', (tester) async {
      Map<String, dynamic>? popped;
      await _pumpFilterPage(
        tester,
        initialMinBudget: 1000,
        initialMaxBudget: 5000,
        onPopResult: (r) => popped = r,
      );

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!['minBudget'], null);
      expect(popped!['maxBudget'], null);
      expect(popped!['createdAfter'], null);
      expect(popped!['createdBefore'], null);
    });

    testWidgets('clear icon for createdAfter resets the date', (tester) async {
      await _pumpFilterPage(tester, initialCreatedAfter: DateTime(2024, 1, 5));

      // The X icon (Icons.clear) is rendered next to the formatted date
      expect(find.byIcon(Icons.clear), findsWidgets);

      // Tap the first clear icon (for createdAfter)
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pump();

      // Now placeholder should reappear
      expect(find.text('From Date'), findsOneWidget);
    });

    testWidgets('Apply preserves typed values and existing dates',
        (tester) async {
      Map<String, dynamic>? popped;
      await _pumpFilterPage(
        tester,
        initialCreatedAfter: DateTime(2024, 1, 1),
        initialCreatedBefore: DateTime(2024, 12, 31),
        onPopResult: (r) => popped = r,
      );

      await tester.enterText(find.byType(TextField).first, '2500');
      await tester.pump();

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(popped!['minBudget'], 2500.0);
      expect(popped!['createdAfter'], DateTime(2024, 1, 1));
      expect(popped!['createdBefore'], DateTime(2024, 12, 31));
    });

    testWidgets('shows calendar_month icons for date fields', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.byIcon(Icons.calendar_month), findsNWidgets(2));
    });

    testWidgets('Scaffold + AppBar present', (tester) async {
      await _pumpFilterPage(tester);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
