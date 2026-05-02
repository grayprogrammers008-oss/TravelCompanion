import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/gradient_backgrounds.dart';

import 'test_helpers.dart';

void main() {
  group('AnimatedGradientBackground', () {
    testWidgets('renders child (animated=true)', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AnimatedGradientBackground(child: Text('inner')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('inner'), findsOneWidget);
    });

    testWidgets('renders child (animate=false)', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AnimatedGradientBackground(
          animate: false,
          child: Text('still'),
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('still'), findsOneWidget);
    });
  });

  group('MeshGradientBackgroundSimple', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const MeshGradientBackgroundSimple(child: Text('mesh')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('mesh'), findsOneWidget);
    });
  });

  group('GlassmorphicBackground', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const GlassmorphicBackground(child: Text('glass-bg')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('glass-bg'), findsOneWidget);
    });
  });

  group('FloatingCirclesBackground', () {
    testWidgets('renders child on top of animated circles', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const FloatingCirclesBackground(
          circleCount: 3,
          child: Text('floaty'),
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('floaty'), findsOneWidget);
    });
  });

  group('WaveBackground', () {
    testWidgets('renders child and a CustomPaint', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const WaveBackground(child: Text('wavy')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('wavy'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('WavePainter', () {
    test('shouldRepaint when animation value changes', () {
      final p1 = WavePainter(animation: 0.0, waveColor: const Color(0xFFAA0000));
      final p2 = WavePainter(animation: 0.5, waveColor: const Color(0xFFAA0000));
      expect(p2.shouldRepaint(p1), isTrue);
    });
  });
}
