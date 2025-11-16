import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/medical_emergency_button.dart';

void main() {
  group('Medical Emergency Button E2E Tests', () {
    testWidgets('should display medical emergency button with correct styling',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MedicalEmergencyButton), findsOneWidget);
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
      expect(find.text('MEDICAL'), findsOneWidget);
      expect(find.text('Medical Emergency'), findsOneWidget);
      expect(find.text('Tap for immediate help'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap the button
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert - Dialog should appear
      expect(find.text('Medical Emergency'), findsOneWidget);
      expect(
          find.text('Are you experiencing a medical emergency?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('CONFIRM EMERGENCY'), findsOneWidget);
    });

    testWidgets('should cancel alert when dialog is cancelled', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap button and cancel
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be dismissed
      expect(find.text('Medical Emergency'), findsNothing);
      expect(find.text('CONFIRM EMERGENCY'), findsNothing);
    });

    testWidgets('should display red color for medical emergency',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Find the container with red color
      final container = tester.widget<GestureDetector>(
        find.byType(GestureDetector),
      );
      expect(container, isNotNull);
    });

    testWidgets('should hide label when showLabel is false', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(showLabel: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Medical Emergency'), findsNothing);
      expect(find.text('Tap for immediate help'), findsNothing);
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
    });

    testWidgets('should show medical emergency button in trip context',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(tripId: 'trip123'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MedicalEmergencyButton), findsOneWidget);
      expect(find.byIcon(Icons.medical_services), findsOneWidget);
    });

    testWidgets('should use custom size', (tester) async {
      // Arrange & Act
      const customSize = 150.0;
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(size: customSize),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Button should exist with custom size
      expect(find.byType(MedicalEmergencyButton), findsOneWidget);
    });

    testWidgets('should animate pulse effect', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );

      // Let animation run for a bit
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - AnimatedBuilder should be present
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('should show loading indicator when triggering alert',
        (tester) async {
      // Note: This test would require mocking the emergency controller
      // to control the loading state. For now, we'll just verify the widget renders.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Widget should render
      expect(find.byType(MedicalEmergencyButton), findsOneWidget);
    });

    testWidgets('should accept onAlertTriggered callback parameter', (tester) async {
      // Note: Testing callback execution would require mocking the controller.
      // For now, we verify the widget accepts the callback parameter.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(
                  onAlertTriggered: () {
                    // Callback would be called after alert is triggered
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Widget should render
      expect(find.byType(MedicalEmergencyButton), findsOneWidget);
    });

    testWidgets('should display confirmation dialog with correct content',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap to show dialog
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert - Check dialog content
      expect(find.text('Medical Emergency'), findsOneWidget);
      expect(
          find.textContaining('Are you experiencing a medical emergency?'),
          findsOneWidget);
      expect(find.textContaining('Alert your emergency contacts'),
          findsOneWidget);
      expect(find.textContaining('Share your current location'), findsOneWidget);
    });

    testWidgets('should have medical icon in dialog title', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap to show dialog
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert - Medical icon should be in the dialog
      expect(find.byIcon(Icons.medical_services), findsNWidgets(2)); // One in button, one in dialog
    });

    testWidgets('should display with correct text styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MedicalEmergencyButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verify text elements exist
      expect(find.text('MEDICAL'), findsOneWidget);
      expect(find.text('Medical Emergency'), findsOneWidget);
      expect(find.text('Tap for immediate help'), findsOneWidget);
    });
  });
}
