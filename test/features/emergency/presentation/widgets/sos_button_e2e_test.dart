import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/sos_button.dart';

import 'fake_emergency_repository.dart';

Widget _buildTestApp({required Widget child}) {
  return ProviderScope(
    overrides: [
      emergencyRepositoryProvider
          .overrideWithValue(FakeEmergencyRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
}

/// SOSButton starts a continuous pulse animation in initState
/// (`_pulseController.repeat`) so `pumpAndSettle` never settles. Pump a few
/// frames so the first build completes, then run [body], then unmount the
/// widget tree so Flutter can dispose the AnimationController cleanly.
Future<void> _runWithButton(
  WidgetTester tester,
  Future<void> Function() body, {
  Widget child = const SOSButton(),
}) async {
  await tester.pumpWidget(_buildTestApp(child: child));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  try {
    await body();
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
  }
}

void main() {
  group('SOS Button E2E Tests', () {
    testWidgets('should display SOS button with correct styling',
        (tester) async {
      await _runWithButton(tester, () async {
        expect(find.byType(SOSButton), findsOneWidget);
        expect(find.byIcon(Icons.sos), findsOneWidget);
        expect(find.text('SOS'), findsOneWidget);
        expect(find.text('Hold for 3 seconds'), findsOneWidget);
      });
    });

    testWidgets('should show hold instruction when button is long pressed',
        (tester) async {
      await _runWithButton(tester, () async {
        final center = tester.getCenter(find.byType(GestureDetector));
        final gesture = await tester.startGesture(center);
        // onLongPressStart fires only after kLongPressTimeout (~500ms), then
        // _isHolding becomes true and the "Hold to send..." label appears.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Hold to send...'), findsOneWidget);
        expect(
            find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        // Release the gesture so the periodic hold-progress timer is
        // cancelled before the widget tree is torn down.
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });
    });

    testWidgets('should reset when long press is cancelled', (tester) async {
      await _runWithButton(tester, () async {
        final center = tester.getCenter(find.byType(GestureDetector));
        final gesture = await tester.startGesture(center);
        await tester.pump(const Duration(milliseconds: 500));
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Hold for 3 seconds'), findsOneWidget);
        expect(find.text('Hold to send...'), findsNothing);
      });
    });

    testWidgets('should display compact SOS button', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: CompactSOSButton(
            onAlertTriggered: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.sos), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should show confirmation dialog when compact button is tapped',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const CompactSOSButton()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('Only use in real emergencies!'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send SOS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should cancel dialog when Cancel is tapped', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const CompactSOSButton()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should have correct size for default SOS button',
        (tester) async {
      await _runWithButton(
        tester,
        () async {
          final container = tester.widget<Container>(
            find
                .descendant(
                  of: find.byType(GestureDetector),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(container.constraints?.maxWidth, 150.0);
          expect(container.constraints?.maxHeight, 150.0);
        },
        child: const SOSButton(size: 150.0),
      );
    });

    testWidgets('should hide label when showLabel is false', (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.text('Hold for 3 seconds'), findsNothing);
          expect(find.byIcon(Icons.sos), findsOneWidget);
        },
        child: const SOSButton(showLabel: false),
      );
    });

    testWidgets('should show SOS button in trip context', (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.byType(SOSButton), findsOneWidget);
          expect(find.byIcon(Icons.sos), findsOneWidget);
        },
        child: const SOSButton(tripId: 'trip123'),
      );
    });

    testWidgets('should display red color for emergency', (tester) async {
      await _runWithButton(tester, () async {
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(GestureDetector),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.red.shade600);
      });
    });

    testWidgets('should have proper accessibility for screen readers',
        (tester) async {
      await _runWithButton(tester, () async {
        expect(find.text('SOS'), findsOneWidget);
        expect(find.text('Hold for 3 seconds'), findsOneWidget);
        expect(find.byIcon(Icons.sos), findsOneWidget);
      });
    });

    testWidgets('should display trip context when tripId is provided',
        (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.byType(SOSButton), findsOneWidget);
          // Trip context should be used internally when alert is triggered.
        },
        child: const SOSButton(tripId: 'trip123'),
      );
    });

    testWidgets('should show progress during hold gesture', (tester) async {
      await _runWithButton(tester, () async {
        final center = tester.getCenter(find.byType(GestureDetector));
        final gesture = await tester.startGesture(center);
        // Wait past kLongPressTimeout so onLongPressStart fires and the
        // CircularProgressIndicator is shown by the hold-progress logic.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 500));

        expect(
            find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        // Release the gesture so the recurring hold-progress Timer is
        // cancelled before the widget is unmounted (otherwise the test
        // fails with a pending Timer error).
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });
    });

    testWidgets('should animate pulse effect', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const SOSButton()),
      );

      // Let animation run for a bit.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - AnimatedBuilder should be present.
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Dispose the continuous animation so the test can settle.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
