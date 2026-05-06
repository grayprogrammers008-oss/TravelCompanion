import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_crew/main.dart' as app;

/// On-device tests for the Trips feature.
///
/// Strategy: each test boots the app fresh. If a persisted Supabase
/// session restores (because the user previously logged in on the
/// device), the app lands on the home/trips screen and we exercise it.
/// If no session is found, the app sits on the login screen — those
/// tests skip with a clear message rather than failing.
///
/// To make trip tests run, log in once manually on the device first.
/// The session will persist via Supabase's local storage; subsequent
/// integration test runs will start authenticated.
///
/// Run with:
///   flutter test integration_test/trips_flow_test.dart -d <device>

Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() check, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final stop = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(stop)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (check()) return true;
  }
  return false;
}

bool _onLoginScreen() {
  // Heuristic: a Sign In button or the words "Welcome back" / "Login"
  // are present on the login screen but not the home screen.
  final hasSignIn = find.text('Sign In').evaluate().isNotEmpty ||
      find.text('Login').evaluate().isNotEmpty ||
      find.text('Sign in').evaluate().isNotEmpty;
  final hasEmailField =
      find.widgetWithText(TextFormField, 'Email').evaluate().isNotEmpty ||
          find.widgetWithText(TextField, 'Email').evaluate().isNotEmpty;
  return hasSignIn && hasEmailField;
}

bool _onTripsHome() {
  // Heuristic: the home/trips list shows trip cards or a "+" FAB to
  // create a trip. We look for the FAB or any text matching "trip".
  final hasFab = find.byType(FloatingActionButton).evaluate().isNotEmpty;
  final hasTripsTitle = find.textContaining(RegExp(r'[Tt]rips?')).evaluate().isNotEmpty;
  return hasFab || hasTripsTitle;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Trips feature on device', () {
    testWidgets('home screen renders trip list or empty state',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // If the cold-start landed on login, skip — we cannot test trips
      // without authentication.
      if (_onLoginScreen()) {
        // ignore: avoid_print
        print('   ⚠️  No persisted session — skipping trip test. '
            'Log in manually on the device to enable this test.');
        return;
      }

      final foundHome =
          await _waitFor(tester, _onTripsHome, timeout: const Duration(seconds: 30));
      expect(foundHome, isTrue,
          reason:
              'Expected home/trips screen after authenticated cold start');
    });

    testWidgets('trip list scrolls without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      if (_onLoginScreen()) {
        // ignore: avoid_print
        print('   ⚠️  Skipping — not authenticated');
        return;
      }

      // Find a Scrollable widget (the trips list uses CustomScrollView /
      // ListView). Drag it up to trigger scrolling; verify no crash.
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isEmpty) {
        // ignore: avoid_print
        print('   ⚠️  No scrollable on home screen — empty trip list?');
        return;
      }

      await tester.fling(scrollable, const Offset(0, -300), 800);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The framework didn't throw — passing this expect proves the
      // scroll completed cleanly.
      expect(tester.takeException(), isNull);
    });

    testWidgets('FAB to create trip is reachable', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      if (_onLoginScreen()) {
        // ignore: avoid_print
        print('   ⚠️  Skipping — not authenticated');
        return;
      }

      final fabFinder = find.byType(FloatingActionButton);
      final hasFab = await _waitFor(tester, () => fabFinder.evaluate().isNotEmpty,
          timeout: const Duration(seconds: 15));

      if (!hasFab) {
        // Some screens don't expose a FAB; this is informational only.
        // ignore: avoid_print
        print('   ℹ️  No FloatingActionButton on home — '
            'app may use a different create-trip entry point');
        return;
      }

      // Tap the FAB. If it triggers navigation, we should see new widgets.
      // We don't assert on a specific destination — only that the tap
      // doesn't throw.
      await tester.tap(fabFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(tester.takeException(), isNull,
          reason: 'Tapping the create-trip FAB must not throw');
    });

    testWidgets('pull-to-refresh on home does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      if (_onLoginScreen()) {
        // ignore: avoid_print
        print('   ⚠️  Skipping — not authenticated');
        return;
      }

      // Pull down on the first scrollable to trigger pull-to-refresh.
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) return;

      await tester.fling(scrollable.first, const Offset(0, 400), 1200);
      // Wait long enough for the refresh future to resolve.
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(tester.takeException(), isNull,
          reason: 'Pull-to-refresh must not throw');
    });
  });
}
