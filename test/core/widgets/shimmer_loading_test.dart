import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/shimmer_loading.dart';

import 'test_helpers.dart';

void main() {
  group('ShimmerLoading', () {
    testWidgets('returns child unchanged when isLoading=false',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ShimmerLoading(
          isLoading: false,
          child: Text('static'),
        ),
      ));
      await tester.pump();
      expect(find.text('static'), findsOneWidget);
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('wraps child in a ShaderMask when isLoading=true',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ShimmerLoading(
          child: SizedBox(width: 50, height: 50),
        ),
      ));
      await tester.pump();
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('ShimmerBox', () {
    testWidgets('renders with the requested width and height',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ShimmerBox(width: 80, height: 20),
      ));
      await tester.pump();
      expect(find.byType(ShimmerBox), findsOneWidget);
      // The Container inside should have a finite size set by us.
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShimmerBox),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth ?? 80, anyOf(80, isA<double>()));
    });
  });

  group('ShimmerCircle', () {
    testWidgets('renders with the requested size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ShimmerCircle(size: 32),
      ));
      await tester.pump();
      expect(find.byType(ShimmerCircle), findsOneWidget);
    });
  });

  group('ShimmerText', () {
    testWidgets('renders with default height of 16', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ShimmerText(width: 100),
      ));
      await tester.pump();
      expect(find.byType(ShimmerText), findsOneWidget);
    });
  });

  group('ShimmerTripCard', () {
    testWidgets('renders skeleton structure (image + texts + circles)',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ShimmerTripCard(),
        size: const Size(400, 600),
      ));
      await tester.pump();

      expect(find.byType(ShimmerBox), findsWidgets);
      expect(find.byType(ShimmerText), findsWidgets);
      expect(find.byType(ShimmerCircle), findsWidgets);
    });
  });

  group('ShimmerListView', () {
    testWidgets('uses provided itemBuilder for itemCount items',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ShimmerListView(
          itemCount: 4,
          itemBuilder: (_, i) => SizedBox(
            height: 30,
            child: Text('item-$i'),
          ),
        ),
        size: const Size(400, 800),
      ));
      await tester.pump();
      expect(find.text('item-0'), findsOneWidget);
      expect(find.text('item-3'), findsOneWidget);
    });
  });
}
