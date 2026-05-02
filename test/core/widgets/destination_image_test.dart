import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/destination_image.dart';

import 'test_helpers.dart';

void main() {
  group('UserAvatarWidget', () {
    testWidgets('renders single-letter initial for one-word name',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const UserAvatarWidget(userName: 'Alice', size: 48),
      ));
      await tester.pump();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders two-letter initials for multi-word names',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const UserAvatarWidget(userName: 'Alice Wonderland', size: 48),
      ));
      await tester.pump();
      expect(find.text('AW'), findsOneWidget);
    });

    testWidgets('falls back to "?" when no name provided', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const UserAvatarWidget(size: 48),
      ));
      await tester.pump();
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('falls back to "?" for empty string', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const UserAvatarWidget(userName: '', size: 48),
      ));
      await tester.pump();
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const UserAvatarWidget(userName: 'Bob', size: 80),
      ));
      await tester.pump();
      // The outermost Container should be 80×80.
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSized = containers.any((c) {
        final box = c.constraints;
        if (box == null) return false;
        return box.maxWidth == 80 && box.maxHeight == 80;
      });
      expect(hasSized, isTrue);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('renders title, description and icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyStateWidget(
          title: 'No trips yet',
          description: 'Create your first trip',
          icon: Icons.luggage,
        ),
        size: const Size(800, 1200),
      ));
      await tester.pump();
      expect(find.text('No trips yet'), findsOneWidget);
      expect(find.text('Create your first trip'), findsOneWidget);
      expect(find.byIcon(Icons.luggage), findsOneWidget);
    });

    testWidgets('renders no action button when only title/description given',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyStateWidget(
          title: 't',
          description: 'd',
          icon: Icons.inbox,
        ),
        size: const Size(800, 1200),
      ));
      await tester.pump();
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders the action button and triggers onAction',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapWithTheme(
        EmptyStateWidget(
          title: 'No trips',
          description: 'Add one',
          icon: Icons.inbox,
          actionLabel: 'Create',
          onAction: () => pressed = true,
        ),
        size: const Size(800, 1200),
      ));
      await tester.pump();
      expect(find.text('Create'), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(pressed, isTrue);
    });
  });

  // NOTE: DestinationImage is intentionally not exercised here: it calls
  // ImageService → Google Places (network), which we don't want to hit from
  // tests. The companion UserAvatarWidget / EmptyStateWidget cover the
  // pure-UI surface area of this file.
}
