import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/ai_sphere_animation.dart';

import 'test_helpers.dart';

void main() {
  group('AISphereAnimation', () {
    testWidgets('renders with default props', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AISphereAnimation(),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(AISphereAnimation), findsOneWidget);
    });

    testWidgets('renders when isActive=true', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AISphereAnimation(isActive: true, soundLevel: 0.6),
        size: const Size(400, 400),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(AISphereAnimation), findsOneWidget);
    });

    testWidgets('respects custom primary/glow colors', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AISphereAnimation(
          primaryColor: Color(0xFFFF00FF),
          glowColor: Color(0xFF00FF00),
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(AISphereAnimation), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AISphereAnimation(size: 120),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(AISphereAnimation), findsOneWidget);
    });
  });
}
