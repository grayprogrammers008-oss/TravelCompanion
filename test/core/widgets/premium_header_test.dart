import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/premium_header.dart';

import 'test_helpers.dart';

void main() {
  group('PremiumHeader', () {
    testWidgets('renders title (and optional subtitle / icon)',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumHeader(
          title: 'My Trips',
          subtitle: 'You have 3 upcoming',
          icon: Icons.flight_takeoff,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();

      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('You have 3 upcoming'), findsOneWidget);
      expect(find.byIcon(Icons.flight_takeoff), findsOneWidget);
    });

    testWidgets('shows back button when showBackButton=true', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumHeader(
          title: 'Detail',
          showBackButton: true,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('omits back button by default', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumHeader(title: 'Plain'),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('invokes onBack callback when back button is tapped',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapWithTheme(
        PremiumHeader(
          title: 'Detail',
          showBackButton: true,
          onBack: () => pressed = true,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('renders the trailing widget', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumHeader(
          title: 'With Trailing',
          trailing: Icon(Icons.settings, key: Key('trailing-settings')),
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byKey(const Key('trailing-settings')), findsOneWidget);
    });
  });

  group('GlossyCard (premium_header)', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const GlossyCard(child: Text('inside')),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('inside'), findsOneWidget);
    });
  });

  group('GradientBackground', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const GradientBackground(child: Text('bg child')),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('bg child'), findsOneWidget);
    });
  });

  group('GlossyButton', () {
    testWidgets('renders label and (optional) icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        GlossyButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onPressed: () {},
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('shows progress indicator when isLoading=true',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        GlossyButton(label: 'Hidden', isLoading: true, onPressed: () {}),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        GlossyButton(label: 'Tap', onPressed: () => taps++),
        size: const Size(400, 200),
      ));
      await tester.pump();

      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('does not invoke onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        GlossyButton(
          label: 'Tap',
          isLoading: true,
          onPressed: () => taps++,
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();

      // The label is not rendered while loading; tap on the spinner.
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(taps, 0);
    });
  });
}
