import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/ai_orb_animation.dart';

import 'test_helpers.dart';

void main() {
  group('AiOrbAnimation', () {
    testWidgets('renders with default props', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AiOrbAnimation(),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(AiOrbAnimation), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AiOrbAnimation(size: 100),
        size: const Size(400, 400),
      ));
      await tester.pump();
      // The widget should size itself to ~100×100. Just confirm it's in the tree.
      expect(find.byType(AiOrbAnimation), findsOneWidget);
    });

    testWidgets('renders when isActive=false', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AiOrbAnimation(isActive: false),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(AiOrbAnimation), findsOneWidget);
    });

    testWidgets('renders with non-zero soundLevel', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AiOrbAnimation(soundLevel: 0.5, isActive: true),
        size: const Size(400, 400),
      ));
      await tester.pump();
      // Pump a couple of frames to exercise listeners.
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(AiOrbAnimation), findsOneWidget);
    });

    testWidgets('reacts to changing soundLevel via didUpdateWidget',
        (tester) async {
      var level = 0.1;
      await tester.pumpWidget(StatefulBuilder(
        builder: (context, setState) {
          return wrapWithTheme(
            Column(
              children: [
                AiOrbAnimation(soundLevel: level, isActive: true),
                ElevatedButton(
                  onPressed: () => setState(() => level = 0.9),
                  child: const Text('boost'),
                ),
              ],
            ),
            size: const Size(400, 600),
          );
        },
      ));
      await tester.pump();
      await tester.tap(find.text('boost'));
      await tester.pump();
      expect(find.byType(AiOrbAnimation), findsOneWidget);
    });
  });
}
