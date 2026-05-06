import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_crew/main.dart' as app;

/// On-device integration tests for the TravelCompanion app.
///
/// Run with:
///   flutter test integration_test/ -d <device-id>
///
/// These exercise the actual built app — Supabase, Firebase, plugins —
/// against a real device or emulator. Use them for cross-system smoke
/// signal that no widget-level test can give: cold-start time, plugin
/// initialization, navigation across the full router, etc.
///
/// Tests are intentionally lightweight: they verify the app boots and
/// reaches the first interactive screen. Deep flows (login, trip CRUD)
/// are better covered by widget tests with Supabase fakes — those don't
/// need a real backend or device.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke tests', () {
    testWidgets('cold start reaches a non-empty UI within 30 seconds',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // After cold start the app must have rendered SOMETHING. We don't
      // assume which screen — could be splash, onboarding, or login —
      // but the framework should have painted at least one widget.
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('first interactive screen has at least one tap target',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Every entry screen (splash, onboarding, login) has at least one
      // tappable affordance — button, text field, or gesture detector.
      final hasButton = find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(TextButton).evaluate().isNotEmpty ||
          find.byType(OutlinedButton).evaluate().isNotEmpty ||
          find.byType(IconButton).evaluate().isNotEmpty ||
          find.byType(GestureDetector).evaluate().isNotEmpty ||
          find.byType(InkWell).evaluate().isNotEmpty;

      expect(hasButton, isTrue,
          reason: 'Cold start must surface at least one tap target');
    });

    testWidgets('app does not crash on first frame', (tester) async {
      app.main();
      await tester.pump();

      // If main() threw or the framework couldn't lay out, the binding
      // would be in an error state. Just reaching this expect proves
      // boot didn't crash before the first frame was scheduled.
      expect(tester.binding, isNotNull);
    });
  });
}
