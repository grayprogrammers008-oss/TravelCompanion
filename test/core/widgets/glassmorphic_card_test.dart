import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/glassmorphic_card.dart';

import 'test_helpers.dart';

void main() {
  group('GlassmorphicCard', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const GlassmorphicCard(child: Text('hello glass')),
      ));
      await tester.pump();
      expect(find.text('hello glass'), findsOneWidget);
    });

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.all(42);
      await tester.pumpWidget(wrapWithTheme(
        const GlassmorphicCard(
          padding: customPadding,
          child: SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      // Find a Container that has our exact padding.
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.any((c) => c.padding == customPadding), isTrue);
    });
  });

  group('GlossyCard (animated)', () {
    testWidgets('renders child and supports tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        GlossyCard(
          showShine: false,
          onTap: () => taps++,
          child: const Text('content'),
        ),
      ));
      await tester.pump();
      expect(find.text('content'), findsOneWidget);

      await tester.tap(find.text('content'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('renders without an onTap (purely decorative)', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const GlossyCard(
          showShine: false,
          child: Text('decoration'),
        ),
      ));
      await tester.pump();
      expect(find.text('decoration'), findsOneWidget);
    });
  });

  group('FloatingCard', () {
    testWidgets('renders child and propagates onTap', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapWithTheme(
        FloatingCard(
          onTap: () => pressed = true,
          child: const Text('floating'),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('floating'));
      await tester.pump();
      expect(pressed, isTrue);
    });
  });

  group('NeumorphicCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const NeumorphicCard(child: Text('neumorphic')),
      ));
      await tester.pump();
      expect(find.text('neumorphic'), findsOneWidget);
    });

    testWidgets('switches shadow set when isPressed=true', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const NeumorphicCard(
          isPressed: true,
          child: Text('pressed'),
        ),
      ));
      await tester.pump();

      // Pressed state has only one BoxShadow; raised state has two.
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final hasSingleShadow = containers.any((c) {
        final dec = c.decoration;
        if (dec is! BoxDecoration) return false;
        return (dec.boxShadow ?? const []).length == 1;
      });
      expect(hasSingleShadow, isTrue);
    });
  });

  group('GradientBorderCard', () {
    testWidgets('renders child wrapped in two containers', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const GradientBorderCard(child: Text('inner')),
      ));
      await tester.pump();
      expect(find.text('inner'), findsOneWidget);
    });
  });
}
