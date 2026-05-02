import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/animations/animated_widgets.dart';

void main() {
  group('FadeInAnimation', () {
    testWidgets('renders child immediately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeInAnimation(
            child: Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      // Let animation complete safely
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('child remains after partial animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeInAnimation(
            duration: Duration(milliseconds: 300),
            child: Text('Hi'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hi'), findsOneWidget);
    });
  });

  group('SlideInAnimation', () {
    testWidgets('renders child via default constructor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInAnimation(
            child: Text('Slide'),
          ),
        ),
      );
      expect(find.text('Slide'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fromBottom factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInAnimation.fromBottom(
            child: Text('FromBottom'),
          ),
        ),
      );
      expect(find.text('FromBottom'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fromTop factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInAnimation.fromTop(
            child: Text('FromTop'),
          ),
        ),
      );
      expect(find.text('FromTop'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fromLeft factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInAnimation.fromLeft(
            child: Text('FromLeft'),
          ),
        ),
      );
      expect(find.text('FromLeft'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fromRight factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlideInAnimation.fromRight(
            child: Text('FromRight'),
          ),
        ),
      );
      expect(find.text('FromRight'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('ScaleAnimation', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScaleAnimation(
            child: Text('Scale'),
          ),
        ),
      );
      expect(find.text('Scale'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('FadeSlideAnimation', () {
    testWidgets('renders child and completes without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FadeSlideAnimation(
            child: Text('FadeSlide'),
          ),
        ),
      );
      expect(find.text('FadeSlide'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('FadeSlide'), findsOneWidget);
    });
  });

  group('StaggeredListAnimation', () {
    testWidgets('renders specified number of items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 600,
            child: StaggeredListAnimation(
              itemCount: 3,
              itemBuilder: (ctx, i) => SizedBox(
                height: 50,
                child: Text('Item $i'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Item 0'), findsOneWidget);
      // Allow stagger delays to elapse
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });

  group('AnimatedScaleButton', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AnimatedScaleButton(
              child: Text('Tap me'),
            ),
          ),
        ),
      );
      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('invokes onTap when pressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AnimatedScaleButton(
              onTap: () => taps++,
              child: const SizedBox(width: 100, height: 50, child: Text('X')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('X'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(taps, 1);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('renders child and animates without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerLoading(
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      );
      // Pump partially through repeating animation
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });

  group('PulseAnimation', () {
    testWidgets('renders child and pulses without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PulseAnimation(
            child: Text('Pulse'),
          ),
        ),
      );
      expect(find.text('Pulse'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Pulse'), findsOneWidget);
    });
  });
}
