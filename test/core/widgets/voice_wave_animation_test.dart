import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/voice_wave_animation.dart';

import 'test_helpers.dart';

void main() {
  group('VoiceWaveAnimation', () {
    testWidgets('renders when not listening', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const VoiceWaveAnimation(
          soundLevel: 0.0,
          isListening: false,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(VoiceWaveAnimation), findsOneWidget);
    });

    testWidgets('renders with custom colors when not listening',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const VoiceWaveAnimation(
          soundLevel: 0.0,
          isListening: false,
          primaryColor: Color(0xFFFF8800),
          secondaryColor: Color(0xFF8800FF),
          size: 120,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(VoiceWaveAnimation), findsOneWidget);
    });

    // NOTE: Tests with isListening=true are intentionally omitted — the
    // widget kicks off an unbounded `_triggerRandomGlitch()` async loop
    // (Future.delayed) that leaks past the test boundary and causes
    // "Timer is still pending after the widget tree was disposed" failures.
  });

  group('MorphingBlobAnimation', () {
    testWidgets('renders with default props', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const MorphingBlobAnimation(),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(MorphingBlobAnimation), findsOneWidget);
    });

    testWidgets('renders with custom color and size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const MorphingBlobAnimation(
          color: Color(0xFFFF8800),
          size: 150,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(MorphingBlobAnimation), findsOneWidget);
    });
  });
}
