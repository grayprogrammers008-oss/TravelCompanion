import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/gradient_page_backgrounds.dart';

import 'test_helpers.dart';

void main() {
  group('MeshGradientBackground', () {
    testWidgets('renders child (animated=false default)', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const MeshGradientBackground(child: Text('mesh')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('mesh'), findsOneWidget);
    });

    testWidgets('renders child (animated=true)', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const MeshGradientBackground(animated: true, child: Text('alive')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('alive'), findsOneWidget);
    });
  });

  group('DiagonalGradientBackground', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const DiagonalGradientBackground(child: Text('diag')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('diag'), findsOneWidget);
    });
  });

  group('WaveGradientBackground', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const WaveGradientBackground(child: Text('waves')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('waves'), findsOneWidget);
    });
  });

  group('RadialBurstBackground', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const RadialBurstBackground(child: Text('burst')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('burst'), findsOneWidget);
    });
  });

  group('ParticleGradientBackground', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ParticleGradientBackground(child: Text('particles')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('particles'), findsOneWidget);
    });
  });
}
