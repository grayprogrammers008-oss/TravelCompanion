import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/presentation/widgets/view_toggle.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ViewToggle', () {
    testWidgets('renders both Grid and Map labels with icons', (tester) async {
      await tester.pumpWidget(wrap(
        ViewToggle(
          currentMode: DiscoverViewMode.grid,
          onModeChanged: (_) {},
        ),
      ));

      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('does not invoke callback when tapping the already-selected option',
        (tester) async {
      var callCount = 0;
      DiscoverViewMode? lastMode;

      await tester.pumpWidget(wrap(
        ViewToggle(
          currentMode: DiscoverViewMode.grid,
          onModeChanged: (mode) {
            callCount++;
            lastMode = mode;
          },
        ),
      ));

      await tester.tap(find.text('Grid'));
      await tester.pump();

      expect(callCount, 0);
      expect(lastMode, isNull);
    });

    testWidgets('invokes callback when tapping a different option', (tester) async {
      DiscoverViewMode? selected;

      await tester.pumpWidget(wrap(
        ViewToggle(
          currentMode: DiscoverViewMode.grid,
          onModeChanged: (mode) => selected = mode,
        ),
      ));

      await tester.tap(find.text('Map'));
      await tester.pump();

      expect(selected, DiscoverViewMode.map);
    });

    testWidgets('switching between modes invokes the callback in both directions',
        (tester) async {
      DiscoverViewMode current = DiscoverViewMode.grid;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: ViewToggle(
                  currentMode: current,
                  onModeChanged: (mode) => setState(() => current = mode),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Map'));
      await tester.pump();
      expect(current, DiscoverViewMode.map);

      await tester.tap(find.text('Grid'));
      await tester.pump();
      expect(current, DiscoverViewMode.grid);
    });

    testWidgets('respects activeColor when provided', (tester) async {
      const customColor = Color(0xFF00FF00);

      await tester.pumpWidget(wrap(
        ViewToggle(
          currentMode: DiscoverViewMode.map,
          onModeChanged: (_) {},
          activeColor: customColor,
        ),
      ));

      // The selected (Map) icon should be tinted with the custom color
      final mapIcon = tester.widget<Icon>(find.byIcon(Icons.map_outlined));
      expect(mapIcon.color, customColor);
    });
  });

  group('CompactViewToggle', () {
    testWidgets('renders only icons (no labels)', (tester) async {
      await tester.pumpWidget(wrap(
        CompactViewToggle(
          currentMode: DiscoverViewMode.grid,
          onModeChanged: (_) {},
        ),
      ));

      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.text('Grid'), findsNothing);
      expect(find.text('Map'), findsNothing);
    });

    testWidgets('invokes callback when tapping a different option', (tester) async {
      DiscoverViewMode? selected;

      await tester.pumpWidget(wrap(
        CompactViewToggle(
          currentMode: DiscoverViewMode.grid,
          onModeChanged: (mode) => selected = mode,
        ),
      ));

      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump();

      expect(selected, DiscoverViewMode.map);
    });

    testWidgets('does not invoke callback when tapping the already-selected option',
        (tester) async {
      var callCount = 0;

      await tester.pumpWidget(wrap(
        CompactViewToggle(
          currentMode: DiscoverViewMode.map,
          onModeChanged: (_) => callCount++,
        ),
      ));

      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pump();

      expect(callCount, 0);
    });
  });
}
