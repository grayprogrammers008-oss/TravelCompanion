import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/presentation/widgets/image_viewer.dart';

void main() {
  void expandViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('ImageViewer Widget', () {
    testWidgets('renders with required imageUrl', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      expect(find.byType(ImageViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('shows download icon in app bar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('shows share icon in app bar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('tapping download shows snackbar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.download));
      await tester.pump();

      expect(find.text('Download feature coming soon'), findsOneWidget);
    });

    testWidgets('tapping share shows snackbar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();

      expect(find.text('Share feature coming soon'), findsOneWidget);
    });

    testWidgets('uses Hero widget when heroTag provided', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(
            imageUrl: 'https://example.com/img.jpg',
            heroTag: 'tag-1',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('does not include Hero when no heroTag', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('background is black for full immersion', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewer(imageUrl: 'https://example.com/img.jpg'),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('static show pushes a fullscreen route', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ImageViewer.show(
                  context,
                  imageUrl: 'https://example.com/img.jpg',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      // Don't pumpAndSettle - CachedNetworkImage placeholder spinner runs forever
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ImageViewer), findsOneWidget);
    });
  });
}
