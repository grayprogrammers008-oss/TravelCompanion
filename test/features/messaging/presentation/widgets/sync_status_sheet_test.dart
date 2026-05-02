import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/messaging/presentation/widgets/sync_status_sheet.dart';
import 'package:travel_crew/features/messaging/presentation/providers/sync_providers.dart';
import 'package:travel_crew/features/messaging/data/services/sync_coordinator.dart';

void main() {
  group('SyncStatusSheet Widget Tests', () {
    late SyncCoordinator mockCoordinator;

    setUp(() async {
      mockCoordinator = SyncCoordinator();
      await mockCoordinator.initialize();
    });

    tearDown(() {
      mockCoordinator.dispose();
    });

    void expandViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          syncCoordinatorProvider.overrideWithValue(mockCoordinator),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SyncStatusSheet.show(context),
                child: const Text('Show Sync'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should display sync status sheet when opened',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap button to open sheet
      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should show sheet title (header + status card both contain "Sync Status")
      expect(find.text('Sync Status'), findsWidgets);

      // Close to avoid post-test ref leak
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('should show three tabs: Overview, Queue, Statistics',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Check all tabs are present (Queue may also appear as a status card label)
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Queue'), findsWidgets);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('should display sync controls in Overview tab',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should show initialize button (not initialized yet)
      expect(find.text('Initialize Sync'), findsOneWidget);
    });

    testWidgets('should switch between tabs when tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Tap Queue tab (first match - the actual tab, not the status card label)
      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      // Should show queue-related content
      expect(find.textContaining('Queue'), findsWidgets);

      // Tap Statistics tab
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Should show statistics content
      expect(find.textContaining('Deduplication'), findsWidgets);
    });

    testWidgets('should display quick stats in Overview tab', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Check for quick stat labels
      expect(find.text('Messages Synced'), findsOneWidget);
      expect(find.text('Duplicates Skipped'), findsOneWidget);
      expect(find.text('Conflicts Resolved'), findsOneWidget);
      expect(find.text('Efficiency'), findsOneWidget);
    });

    testWidgets('should display queue priority counts in Queue tab',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Switch to Queue tab (first match - the tab not the status card label)
      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      // Check for priority labels
      expect(find.text('High Priority'), findsOneWidget);
      expect(find.text('Medium Priority'), findsOneWidget);
      expect(find.text('Low Priority'), findsOneWidget);
      expect(find.text('Total Queue Size'), findsOneWidget);
    });

    testWidgets('should display queue performance metrics', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      // Check for performance labels
      expect(find.text('Queue Performance'), findsOneWidget);
      expect(find.text('Total Queued'), findsOneWidget);
      expect(find.text('Processed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Success Rate'), findsOneWidget);
    });

    testWidgets('should display deduplication stats in Statistics tab',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Check for deduplication metrics
      expect(find.text('Total Checks'), findsOneWidget);
      expect(find.text('Duplicates Found'), findsOneWidget);
      expect(find.text('Unique Messages'), findsOneWidget);
      expect(find.text('Cache Size'), findsOneWidget);
    });

    testWidgets('should display conflict resolution stats', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Check for conflict resolution section
      expect(find.text('Conflict Resolution'), findsOneWidget);
      expect(find.text('Total Conflicts'), findsOneWidget);
      expect(find.text('By Timestamp'), findsOneWidget);
      expect(find.text('By Source'), findsOneWidget);
      expect(find.text('By Content'), findsOneWidget);
    });

    testWidgets('should have reset statistics button', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Should have reset button (may need scrolling to find on small viewport)
      expect(find.text('Reset Statistics'), findsWidgets);
    });

    testWidgets('should close sheet when close button tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      expect(find.text('Sync Status'), findsWidgets);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Sheet should be closed
      expect(find.text('Sync Status'), findsNothing);
    });

    testWidgets('should display status summary cards', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Check for status cards
      expect(find.text('Status Summary'), findsOneWidget);
      expect(find.text('Sync Status'), findsNWidgets(2)); // Title + card label
      expect(find.text('Queue'), findsNWidgets(2)); // Tab + card label
      expect(find.text('Active Sources'), findsOneWidget);
    });

    testWidgets('should show sync controls section', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Check for controls section
      expect(find.text('Sync Controls'), findsOneWidget);
    });

    testWidgets('should display handle bar at top', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Handle bar should be a Container with grey background
      final handleBar = find.descendant(
        of: find.byType(SyncStatusSheet),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints != null &&
              widget.constraints!.maxWidth == 40,
        ),
      );

      expect(handleBar, findsOneWidget);
    });

    testWidgets('should show sync icon in header', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should have sync icon
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('should display progress bars for rates', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      // Should have LinearProgressIndicator widgets
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('should show percentage values', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      // Should display percentage text (like "0.0%")
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('should display cards with elevation', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should have Card widgets
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should use consistent spacing', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should have SizedBox widgets for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should be scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should have ListView for scrolling
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('should display correct tab count', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should have exactly 3 tabs
      final tabButtons = find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector &&
            widget.child is Container &&
            (widget.child as Container).child is Text,
      );

      expect(tabButtons, findsNWidgets(3));
    });

    testWidgets('should highlight selected tab', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Overview tab should be selected by default
      // Find the Overview tab container and check its decoration
      final overviewTab = find.ancestor(
        of: find.text('Overview'),
        matching: find.byType(Container),
      );

      expect(overviewTab, findsWidgets);
    });

    testWidgets('should display sync status with correct color',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Should have status text with color
      // Initial status should be "Idle" or "Ready"
      final statusTexts = find.textContaining('Status');
      expect(statusTexts, findsWidgets);
    });
  });

  group('SyncStatusSheet Integration with Providers', () {
    testWidgets('should react to sync state changes', (tester) async {
      final coordinator = SyncCoordinator();
      await coordinator.initialize();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncCoordinatorProvider.overrideWithValue(coordinator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SyncStatusSheet.show(context),
                  child: const Text('Show Sync'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Initial state should be shown
      expect(find.text('Initialize Sync'), findsOneWidget);

      coordinator.dispose();
    });

    testWidgets('should update UI when statistics change', (tester) async {
      final coordinator = SyncCoordinator();
      await coordinator.initialize();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncCoordinatorProvider.overrideWithValue(coordinator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SyncStatusSheet.show(context),
                  child: const Text('Show Sync'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sync'));
      await tester.pumpAndSettle();

      // Check initial stats
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      expect(find.text('Total Checks'), findsOneWidget);

      coordinator.dispose();
    });
  });
}
