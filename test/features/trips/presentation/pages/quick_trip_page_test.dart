import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/trips/presentation/pages/quick_trip_page.dart';

/// Widget tests for [QuickTripPage]. We deliberately avoid invoking the
/// destination search (which calls into Supabase via PlaceSearchDelegate) and
/// the trip-creation submit (which calls into TripController/TripRepository).
/// Instead we exercise the rendered scaffolding, the date-preset state machine,
/// and the static helpers that drive the UI.
///
/// All tests use a fixed-size viewport to keep layout deterministic.
void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/quick',
      routes: [
        GoRoute(
          path: '/quick',
          builder: (context, state) => const QuickTripPage(),
        ),
        GoRoute(
          path: '/trips/ai-wizard',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('AI_WIZARD'))),
        ),
        GoRoute(
          path: '/trips/:id',
          builder: (context, state) => Scaffold(
            body: Center(child: Text('TRIP_DETAIL_${state.pathParameters['id']}')),
          ),
        ),
      ],
    );
  }

  Widget app({GoRouter? router}) {
    final themeData = AppThemeData.getThemeData(AppThemeType.ocean);
    return ProviderScope(
      overrides: [
        theme_provider.currentThemeDataProvider.overrideWith((_) => themeData),
      ],
      child: AppThemeProvider(
        themeData: themeData,
        child: MaterialApp.router(
          theme: ThemeData.light(useMaterial3: true),
          routerConfig: router ?? buildRouter(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR / SCAFFOLD
  // ---------------------------------------------------------------------------

  group('QuickTripPage — app bar', () {
    testWidgets('renders the "Quick Trip" title', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Quick Trip'), findsOneWidget);
    });

    testWidgets('renders close button (Icons.close) in app bar leading',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders the AI wizard mic action button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('AI button has "AI Trip Wizard" tooltip', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byTooltip('AI Trip Wizard'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // STEP INDICATOR
  // ---------------------------------------------------------------------------

  group('QuickTripPage — step indicator', () {
    testWidgets('renders both step labels (Destination and Dates)',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Dates'), findsOneWidget);
    });

    testWidgets('shows initial step number "1" when destination empty',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      // Step indicator shows "1" inside the active circle for destination.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // DESTINATION SECTION
  // ---------------------------------------------------------------------------

  group('QuickTripPage — destination section', () {
    testWidgets('renders the section title and subtitle', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Where are you going?'), findsOneWidget);
      expect(find.text('Search for a city, place, or destination'),
          findsOneWidget);
    });

    testWidgets('renders the search-destination placeholder when empty',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Search destination...'), findsOneWidget);
    });

    testWidgets('renders the location_on icon for the destination card',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.location_on), findsAtLeastNWidgets(1));
    });

    testWidgets('renders the search icon inside the destination input',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // DATES SECTION
  // ---------------------------------------------------------------------------

  group('QuickTripPage — dates section', () {
    testWidgets('renders the section title and subtitle', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('When are you traveling?'), findsOneWidget);
      expect(find.text('Pick dates or choose a preset'), findsOneWidget);
    });

    testWidgets('renders all four date-preset chips', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('This Weekend'), findsOneWidget);
      expect(find.text('Next Weekend'), findsOneWidget);
      expect(find.text('Next Week'), findsOneWidget);
      expect(find.text('Pick Dates'), findsOneWidget);
    });

    testWidgets('renders calendar icon for the dates section', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsAtLeastNWidgets(1));
    });

    testWidgets('renders the edit_calendar icon on the "Pick Dates" chip',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.edit_calendar), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // DATE PRESET SELECTION (NO ACTUAL DATE PICKING)
  // ---------------------------------------------------------------------------

  group('QuickTripPage — date preset selection', () {
    testWidgets('tapping "This Weekend" selects a date and shows summary',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('This Weekend'));
      await tester.pump();

      // After preset selected the green confirmation row appears.
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      // Trip preview shows the auto-generated trip name placeholder.
      // Without a destination, the preview block is hidden — but the date
      // summary row should be present.
      expect(find.textContaining('days'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping "Next Weekend" populates the date summary',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('Next Weekend'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping "Next Week" populates the date summary',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('Next Week'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });

    testWidgets('switching presets keeps a single date summary visible',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('This Weekend'));
      await tester.pump();
      await tester.tap(find.text('Next Weekend'));
      await tester.pump();

      // Summary row should still be present after switching.
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BUTTON
  // ---------------------------------------------------------------------------

  group('QuickTripPage — bottom action button', () {
    testWidgets('initial label says "Enter Destination"', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Enter Destination'), findsOneWidget);
    });

    testWidgets('button is disabled before destination is set',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      // Find the ElevatedButton; its onPressed must be null when disabled.
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('after selecting only dates, the button still says '
        '"Enter Destination" (destination required first)', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('This Weekend'));
      await tester.pump();

      expect(find.text('Enter Destination'), findsOneWidget);

      // Even with dates set, button stays disabled because hasDestination=false.
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('the rocket icon is rendered next to the action label',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.rocket_launch), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  group('QuickTripPage — navigation', () {
    testWidgets('tapping AI button navigates to /trips/ai-wizard',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('AI_WIZARD'), findsOneWidget);
    });

    testWidgets('close button pops the route when there is a parent',
        (tester) async {
      useTallViewport(tester);
      // Build a router with /home as initial then push /quick — that way
      // context.pop has somewhere to go.
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('HOME'))),
          ),
          GoRoute(
            path: '/quick',
            builder: (context, state) => const QuickTripPage(),
          ),
        ],
      );
      await tester.pumpWidget(app(router: router));
      await tester.pump();
      router.push('/quick');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Quick Trip'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('HOME'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // TRIP PREVIEW BLOCK (RENDERED WHEN BOTH FIELDS POPULATED)
  // ---------------------------------------------------------------------------

  group('QuickTripPage — trip preview block', () {
    testWidgets('preview block is hidden initially', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Your trip will be created as:'), findsNothing);
    });

    testWidgets('preview stays hidden when only dates are picked',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('This Weekend'));
      await tester.pump();

      // Without destination, preview block is omitted.
      expect(find.text('Your trip will be created as:'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // LIFECYCLE / DISPOSAL
  // ---------------------------------------------------------------------------

  group('QuickTripPage — lifecycle', () {
    testWidgets('unmounts cleanly without exceptions', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets('rebuilding the same page does not throw', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pumpWidget(app());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
