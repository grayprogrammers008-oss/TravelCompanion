import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/animated_button.dart';

import 'test_helpers.dart';

void main() {
  group('AnimatedButton', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        AnimatedButton(
          onPressed: () {},
          child: const Text('Press'),
        ),
      ));
      await tester.pump();
      expect(find.text('Press'), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        AnimatedButton(
          onPressed: () => taps++,
          child: const Text('Tap'),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('shows progress indicator when isLoading=true',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        AnimatedButton(
          onPressed: () {},
          isLoading: true,
          child: const Text('label'),
        ),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not invoke onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        AnimatedButton(
          onPressed: () => taps++,
          isLoading: true,
          child: const Text('label'),
        ),
      ));
      await tester.pump();
      await tester.tap(find.byType(AnimatedButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('does not invoke when onPressed is null', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AnimatedButton(child: Text('disabled')),
      ));
      await tester.pump();
      // Just ensure no errors when tapping a disabled button.
      await tester.tap(find.text('disabled'));
      await tester.pump();
    });
  });

  group('RippleButton', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        RippleButton(
          onPressed: () {},
          child: const SizedBox(
            width: 100,
            height: 40,
            child: Center(child: Text('ripple')),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('ripple'), findsOneWidget);
    });

    testWidgets('invokes onPressed on tap-down', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        RippleButton(
          onPressed: () => taps++,
          child: const SizedBox(
            width: 100,
            height: 40,
            child: Center(child: Text('ripple')),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('ripple'));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('PulseFAB', () {
    testWidgets('renders the inner child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        PulseFAB(
          onPressed: () {},
          child: const Icon(Icons.add, key: Key('fab-icon')),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('fab-icon')), findsOneWidget);
    });

    testWidgets('does not crash when showPulse=false', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PulseFAB(
          showPulse: false,
          child: Icon(Icons.bolt),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });

  group('GlossyButtonAnimated', () {
    testWidgets('renders child and propagates tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        GlossyButtonAnimated(
          onPressed: () => taps++,
          child: const SizedBox(
            width: 120,
            height: 40,
            child: Center(child: Text('shine')),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('shine'), findsOneWidget);

      await tester.tap(find.text('shine'), warnIfMissed: false);
      await tester.pump();
      expect(taps, 1);
    });
  });
}
