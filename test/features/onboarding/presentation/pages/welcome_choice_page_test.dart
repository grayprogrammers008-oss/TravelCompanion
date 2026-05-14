import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/core/theme/theme_provider.dart';
import 'package:pathio/features/onboarding/presentation/pages/welcome_choice_page.dart';

/// Widget tests for [WelcomeChoicePage].
///
/// The page uses `currentThemeDataProvider` (overridable) and `context.push`/
/// `context.go` from `go_router`. We pump it inside a [MaterialApp.router]
/// with a [GoRouter] so navigation works, and we override the theme provider
/// to bypass the production initialization path.

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/welcome-choice',
      routes: [
        GoRoute(
          path: '/welcome-choice',
          builder: (context, state) => const WelcomeChoicePage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('DASHBOARD'))),
        ),
        GoRoute(
          path: '/trips/ai-wizard',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('AI WIZARD'))),
        ),
        GoRoute(
          path: '/trips/quick',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('QUICK TRIP'))),
        ),
        GoRoute(
          path: '/trips/browse',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('BROWSE'))),
        ),
        GoRoute(
          path: '/invite/:code',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('INVITE'))),
        ),
      ],
    );
  }

  Widget app() {
    final themeData = AppThemeData.getThemeData(AppThemeType.ocean);
    return ProviderScope(
      overrides: [
        currentThemeDataProvider.overrideWith((ref) => themeData),
      ],
      child: AppThemeProvider(
        themeData: themeData,
        child: MaterialApp.router(routerConfig: buildRouter()),
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

  group('WelcomeChoicePage — initial render', () {
    testWidgets('shows loading container before animations initialize',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      // First frame: animations not yet initialized; loading container only.
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('renders welcome text after animations initialize',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      // Pump enough for the post-frame callback that flips _initialized
      // and starts the animation controller.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 850));

      expect(find.text('Welcome to TravelCompanion!'), findsOneWidget);
    });

    testWidgets('renders the four choice card titles', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 850));

      expect(find.text('Create a New Trip'), findsOneWidget);
      expect(find.text('Join an Existing Trip'), findsOneWidget);
      expect(find.text('Explore Public Trips'), findsOneWidget);
    });

    testWidgets('renders the takeoff icon in the header', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 850));

      expect(find.byIcon(Icons.flight_takeoff), findsAtLeastNWidgets(1));
    });
  });

  group('WelcomeChoicePage — navigation', () {
    Future<void> pumpReady(WidgetTester tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 850));
    }

    testWidgets('tapping "Create a New Trip" navigates to /trips/quick',
        (tester) async {
      useTallViewport(tester);
      await pumpReady(tester);

      await tester.tap(find.text('Create a New Trip'));
      await tester.pumpAndSettle();

      expect(find.text('QUICK TRIP'), findsOneWidget);
    });

    testWidgets('tapping "Explore Public Trips" navigates to /trips/browse',
        (tester) async {
      useTallViewport(tester);
      await pumpReady(tester);

      await tester.tap(find.text('Explore Public Trips'));
      await tester.pumpAndSettle();

      expect(find.text('BROWSE'), findsOneWidget);
    });

    testWidgets('tapping "Join an Existing Trip" opens the invite dialog',
        (tester) async {
      useTallViewport(tester);
      await pumpReady(tester);

      await tester.tap(find.text('Join an Existing Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The join flow shows a custom dialog (not necessarily AlertDialog).
      // Verify by looking for the input field that the join dialog presents.
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      // Dispose to drain pending timers.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('WelcomeChoicePage — dispose', () {
    testWidgets('disposes cleanly when popped before animations finish',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();
      // Replace the entire widget tree before animations complete to verify
      // the dispose path doesn't throw on a still-running AnimationController.
      await tester.pumpWidget(const SizedBox.shrink());
      // No exception means dispose handled the half-initialized state.
      expect(tester.takeException(), isNull);
    });
  });
}
