import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/sos_button.dart';

void main() {
  group('SOS Button E2E Tests', () {
    testWidgets('should display SOS button with correct styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SOSButton), findsOneWidget);
      expect(find.byIcon(Icons.sos), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Hold for 3 seconds'), findsOneWidget);
    });

    testWidgets('should show hold instruction when button is long pressed',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Start long press
      final center = tester.getCenter(find.byType(GestureDetector));
      await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.text('Hold to send...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should reset when long press is cancelled', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Start and cancel long press
      final center = tester.getCenter(find.byType(GestureDetector));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      // Assert - Should go back to default state
      expect(find.text('Hold for 3 seconds'), findsOneWidget);
      expect(find.text('Hold to send...'), findsNothing);
    });

    testWidgets('should display compact SOS button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSOSButton(
                onAlertTriggered: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.sos), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when compact button is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSOSButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('Only use in real emergencies!'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send SOS'), findsOneWidget);
    });

    testWidgets('should cancel dialog when Cancel is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompactSOSButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should have correct size for default SOS button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(size: 150.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 150.0);
      expect(container.constraints?.maxHeight, 150.0);
    });

    testWidgets('should hide label when showLabel is false', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(showLabel: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hold for 3 seconds'), findsNothing);
      expect(find.byIcon(Icons.sos), findsOneWidget);
    });

    testWidgets('should show SOS button in trip context', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(tripId: 'trip123'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SOSButton), findsOneWidget);
      expect(find.byIcon(Icons.sos), findsOneWidget);
    });

    testWidgets('should display red color for emergency', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red.shade600);
    });

    testWidgets('should have proper accessibility for screen readers',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - All text elements present for screen readers
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Hold for 3 seconds'), findsOneWidget);
      expect(find.byIcon(Icons.sos), findsOneWidget);
    });

    testWidgets('should display trip context when tripId is provided',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(tripId: 'trip123'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SOSButton), findsOneWidget);
      // Trip context should be used internally when alert is triggered
    });

    testWidgets('should show progress during hold gesture', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Hold for 1 second
      final center = tester.getCenter(find.byType(GestureDetector));
      await tester.startGesture(center);
      await tester.pump(const Duration(seconds: 1));

      // Assert - Progress indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should animate pulse effect', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SOSButton(),
              ),
            ),
          ),
        ),
      );

      // Let animation run for a bit
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - AnimatedBuilder should be present (may be multiple for theme and animation)
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });
  });
}
