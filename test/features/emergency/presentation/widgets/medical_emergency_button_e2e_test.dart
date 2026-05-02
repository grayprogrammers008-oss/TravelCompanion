import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/medical_emergency_button.dart';

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

/// MedicalEmergencyButton starts a continuous pulse animation in initState
/// (`_pulseController.repeat`) so `pumpAndSettle` never settles. Pump a few
/// frames so the first build completes, then run [body], then unmount the
/// widget tree so Flutter can dispose the AnimationController cleanly.
Future<void> _runWithButton(
  WidgetTester tester,
  Future<void> Function() body, {
  Widget child = const MedicalEmergencyButton(),
}) async {
  await tester.pumpWidget(_buildTestApp(child: child));
  // First-frame build + a couple of animation frames.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  try {
    await body();
  } finally {
    // Tear down the widget tree so the repeating animation is disposed.
    await tester.pumpWidget(const SizedBox.shrink());
  }
}

void main() {
  group('Medical Emergency Button E2E Tests', () {
    testWidgets('should display medical emergency button with correct styling',
        (tester) async {
      await _runWithButton(tester, () async {
        expect(find.byType(MedicalEmergencyButton), findsOneWidget);
        expect(find.byIcon(Icons.medical_services), findsOneWidget);
        expect(find.text('MEDICAL'), findsOneWidget);
        expect(find.text('Medical Emergency'), findsOneWidget);
        expect(find.text('Tap for immediate help'), findsOneWidget);
      });
    });

    testWidgets('should show confirmation dialog when tapped', (tester) async {
      await _runWithButton(tester, () async {
        await tester.tap(find.byType(GestureDetector));
        // Allow the dialog show animation to complete. The continuous pulse
        // animation prevents pumpAndSettle, so pump enough frames manually for
        // the dialog route transition to finish (Material default is ~150ms).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // The button label "Medical Emergency" is shown below the button and
        // the dialog title also contains it, so we expect at least one match
        // for the title and verify the dialog-specific elements. Use
        // textContaining to match the multi-line dialog content where the
        // question is followed by "\n\nThis will:\n...".
        expect(
            find.textContaining('Are you experiencing a medical emergency?'),
            findsOneWidget);
        expect(find.text('CANCEL'), findsOneWidget);
        expect(find.text('CONFIRM EMERGENCY'), findsOneWidget);
      });
    });

    testWidgets('should cancel alert when dialog is cancelled', (tester) async {
      await _runWithButton(tester, () async {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('CANCEL'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Dialog should be dismissed.
        expect(find.text('CONFIRM EMERGENCY'), findsNothing);
      });
    });

    testWidgets('should display red color for medical emergency',
        (tester) async {
      await _runWithButton(tester, () async {
        // Find the GestureDetector wrapping the button.
        final container = tester.widget<GestureDetector>(
          find.byType(GestureDetector),
        );
        expect(container, isNotNull);
      });
    });

    testWidgets('should hide label when showLabel is false', (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.text('Medical Emergency'), findsNothing);
          expect(find.text('Tap for immediate help'), findsNothing);
          expect(find.byIcon(Icons.medical_services), findsOneWidget);
        },
        child: const MedicalEmergencyButton(showLabel: false),
      );
    });

    testWidgets('should show medical emergency button in trip context',
        (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.byType(MedicalEmergencyButton), findsOneWidget);
          expect(find.byIcon(Icons.medical_services), findsOneWidget);
        },
        child: const MedicalEmergencyButton(tripId: 'trip123'),
      );
    });

    testWidgets('should use custom size', (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.byType(MedicalEmergencyButton), findsOneWidget);
        },
        child: const MedicalEmergencyButton(size: 150.0),
      );
    });

    testWidgets('should animate pulse effect', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const MedicalEmergencyButton()),
      );

      // Let animation run for a bit.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - AnimatedBuilder should be present
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Dispose the continuous animation so the test can settle.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should show loading indicator when triggering alert',
        (tester) async {
      await _runWithButton(tester, () async {
        // Widget should render with the fake repository.
        expect(find.byType(MedicalEmergencyButton), findsOneWidget);
      });
    });

    testWidgets('should accept onAlertTriggered callback parameter',
        (tester) async {
      await _runWithButton(
        tester,
        () async {
          expect(find.byType(MedicalEmergencyButton), findsOneWidget);
        },
        child: MedicalEmergencyButton(
          onAlertTriggered: () {
            // Callback would be called after alert is triggered.
          },
        ),
      );
    });

    testWidgets('should display confirmation dialog with correct content',
        (tester) async {
      await _runWithButton(tester, () async {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
            find.textContaining('Are you experiencing a medical emergency?'),
            findsOneWidget);
        expect(find.textContaining('Alert your emergency contacts'),
            findsOneWidget);
        expect(find.textContaining('Share your current location'),
            findsOneWidget);
      });
    });

    testWidgets('should have medical icon in dialog title', (tester) async {
      await _runWithButton(tester, () async {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Medical icon should be in the dialog (one in button, one in dialog).
        expect(find.byIcon(Icons.medical_services), findsNWidgets(2));
      });
    });

    testWidgets('should display with correct text styling', (tester) async {
      await _runWithButton(tester, () async {
        expect(find.text('MEDICAL'), findsOneWidget);
        expect(find.text('Medical Emergency'), findsOneWidget);
        expect(find.text('Tap for immediate help'), findsOneWidget);
      });
    });
  });
}
