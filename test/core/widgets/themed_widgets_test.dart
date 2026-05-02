import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/themed_widgets.dart';

import 'test_helpers.dart';

void main() {
  group('ThemedCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedCard(child: Text('card body')),
      ));
      await tester.pump();
      expect(find.text('card body'), findsOneWidget);
    });
  });

  group('ThemedButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ThemedButton(label: 'Save', onPressed: () {}),
      ));
      await tester.pump();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        ThemedButton(label: 'Press me', onPressed: () => taps++),
      ));
      await tester.pump();

      await tester.tap(find.text('Press me'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('shows progress indicator when isLoading=true',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ThemedButton(label: 'Loading', onPressed: () {}, isLoading: true),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label is replaced with spinner.
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('renders an icon alongside the label when icon is provided',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ThemedButton(
          label: 'Add',
          icon: Icons.add,
          onPressed: () {},
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('uses OutlinedButton when isOutlined=true', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ThemedButton(label: 'Out', onPressed: () {}, isOutlined: true),
      ));
      await tester.pump();
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ThemedIcon', () {
    testWidgets('renders the requested icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedIcon(icon: Icons.location_on),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('respects explicit color override', (tester) async {
      const c = Color(0xFF112233);
      await tester.pumpWidget(wrapWithTheme(
        const ThemedIcon(icon: Icons.flag, color: c),
      ));
      await tester.pump();
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.flag));
      expect(iconWidget.color, c);
    });
  });

  group('ThemedChip', () {
    testWidgets('renders label and (optional) icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedChip(label: '5 days', icon: Icons.calendar_today),
      ));
      await tester.pump();
      expect(find.text('5 days'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        ThemedChip(label: 'tap', onTap: () => taps++),
      ));
      await tester.pump();

      await tester.tap(find.text('tap'));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('ThemedSectionHeader', () {
    testWidgets('renders title and action', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ThemedSectionHeader(
          title: 'Recent Trips',
          action: TextButton(onPressed: () {}, child: const Text('See All')),
        ),
      ));
      await tester.pump();
      expect(find.text('Recent Trips'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
    });
  });

  group('ThemedDivider', () {
    testWidgets('renders a Divider widget', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedDivider(),
      ));
      await tester.pump();
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('ThemedLoadingIndicator', () {
    testWidgets('renders a CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedLoadingIndicator(),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ThemedEmptyState', () {
    testWidgets('renders icon, title, message and (optional) action',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrapWithTheme(
        ThemedEmptyState(
          icon: Icons.inbox,
          title: 'Nothing yet',
          message: 'Create your first item',
          action: ThemedButton(label: 'Create', onPressed: () => taps++),
        ),
        size: const Size(800, 1200),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Create your first item'), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('renders without an action when none is provided',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedEmptyState(
          icon: Icons.inbox,
          title: 't',
          message: 'm',
        ),
        size: const Size(800, 1200),
      ));
      await tester.pump();
      expect(find.byType(ThemedButton), findsNothing);
    });
  });

  group('ThemedGradientCard', () {
    testWidgets('renders child via gradient container', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ThemedGradientCard(child: Text('premium')),
      ));
      await tester.pump();
      expect(find.text('premium'), findsOneWidget);
    });
  });
}
