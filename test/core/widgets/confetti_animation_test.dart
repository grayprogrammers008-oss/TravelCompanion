import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/confetti_animation.dart';

import 'test_helpers.dart';

void main() {
  group('ConfettiAnimation', () {
    testWidgets('renders nothing when show=false', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ConfettiAnimation(show: false),
      ));
      await tester.pump();
      expect(find.byType(CustomPaint), findsNothing);
      expect(find.byType(SizedBox), findsWidgets); // shrink
    });

    testWidgets('renders a CustomPaint with particles when show=true',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ConfettiAnimation(
          show: true,
          particleCount: 5,
          duration: Duration(milliseconds: 50),
        ),
        size: const Size(400, 600),
      ));
      // First pump triggers _generateParticles + forward(), need second to render painter.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is ConfettiPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('invokes onComplete when animation finishes', (tester) async {
      var completed = false;
      await tester.pumpWidget(wrapWithTheme(
        ConfettiAnimation(
          show: true,
          particleCount: 3,
          duration: const Duration(milliseconds: 30),
          onComplete: () => completed = true,
        ),
        size: const Size(400, 600),
      ));
      await tester.pump();
      // Drive past the animation duration.
      await tester.pump(const Duration(milliseconds: 50));
      expect(completed, isTrue);
    });
  });

  group('ConfettiPainter', () {
    test('shouldRepaint when progress changes', () {
      final p1 = ConfettiPainter(particles: const [], progress: 0.0);
      final p2 = ConfettiPainter(particles: const [], progress: 0.5);
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('does not repaint when progress is identical', () {
      final p1 = ConfettiPainter(particles: const [], progress: 0.3);
      final p2 = ConfettiPainter(particles: const [], progress: 0.3);
      expect(p2.shouldRepaint(p1), isFalse);
    });
  });
}
