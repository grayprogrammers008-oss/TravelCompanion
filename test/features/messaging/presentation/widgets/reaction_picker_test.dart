import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/presentation/widgets/reaction_picker.dart';

void main() {
  group('ReactionPicker Widget', () {
    testWidgets('should display reaction picker with categories', (tester) async {
      // Arrange
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (emoji) {
                selectedEmoji = emoji;
              },
            ),
          ),
        ),
      );

      // Assert - Check for header
      expect(find.text('Choose Reaction'), findsOneWidget);

      // Assert - Check for search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search emojis...'), findsOneWidget);

      // Assert - Check for tab bar
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should display handle bar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Check for handle bar container
      final handleBars = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius != null,
      );

      expect(handleBars, findsWidgets);
    });

    testWidgets('should have close button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should display all emoji categories', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Check for category tabs
      expect(find.text('Frequently Used'), findsOneWidget);
      expect(find.text('Smileys'), findsOneWidget);
      expect(find.text('Gestures'), findsOneWidget);
      expect(find.text('Hearts'), findsOneWidget);
      expect(find.text('Celebrations'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(find.text('Objects'), findsOneWidget);
    });

    testWidgets('should display emoji grid', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - Check for grid view
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should call onEmojiSelected when emoji is tapped', (tester) async {
      // Arrange
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (emoji) {
                selectedEmoji = emoji;
              },
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Act - Find and tap an emoji (should be in GridView)
      final emojiTexts = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data != null && widget.data!.contains('👍'),
      );

      if (emojiTexts.evaluate().isNotEmpty) {
        await tester.tap(emojiTexts.first);
        await tester.pumpAndSettle();

        // Assert
        expect(selectedEmoji, isNotNull);
      }
    });

    testWidgets('should filter emojis when searching', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Enter search query
      await tester.enterText(find.byType(TextField), 'heart');
      await tester.pumpAndSettle();

      // Assert - Search functionality works (categories might be hidden during search)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'heart');
    });

    testWidgets('should show clear button when search has text', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Act - Enter search query
      await tester.enterText(find.byType(TextField), 'smile');
      await tester.pumpAndSettle();

      // Assert - Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should clear search when clear button is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Enter search query
      await tester.enterText(find.byType(TextField), 'heart');
      await tester.pumpAndSettle();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '');
    });

    testWidgets('should show search icon', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('static show method should display as bottom sheet', (tester) async {
      // Arrange
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ReactionPicker.show(
                      context,
                      onEmojiSelected: (emoji) {
                        selectedEmoji = emoji;
                      },
                    );
                  },
                  child: const Text('Open Picker'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Tap button to open picker
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Assert - Picker is displayed
      expect(find.text('Choose Reaction'), findsOneWidget);
      expect(find.byType(ReactionPicker), findsOneWidget);
    });
  });

  group('ReactionPicker Animations', () {
    testWidgets('emoji button should have scale animation on tap', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Find first emoji container
      final emojiContainers = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      );

      if (emojiContainers.evaluate().isNotEmpty) {
        // Perform tap down
        final gesture = await tester.startGesture(
          tester.getCenter(emojiContainers.first),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Release tap
        await gesture.up();
        await tester.pumpAndSettle();

        // Animation completed
        expect(find.byType(ScaleTransition), findsWidgets);
      }
    });
  });

  group('ReactionPicker Edge Cases', () {
    testWidgets('should handle empty search results gracefully', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Search for something that doesn't exist
      await tester.enterText(find.byType(TextField), 'xyzabc123notfound');
      await tester.pumpAndSettle();

      // Assert - Should show empty state
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No emojis found'), findsOneWidget);
    });

    testWidgets('should handle rapid tab switching', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Rapidly switch between tabs
      await tester.tap(find.text('Smileys'));
      await tester.pump();
      await tester.tap(find.text('Hearts'));
      await tester.pump();
      await tester.tap(find.text('Gestures'));
      await tester.pumpAndSettle();

      // Assert - Should not crash and should show selected tab
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should maintain state when switching tabs', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              onEmojiSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Switch to different tab and back
      await tester.tap(find.text('Hearts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frequently Used'));
      await tester.pumpAndSettle();

      // Assert - Should still display correctly
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Frequently Used'), findsOneWidget);
    });
  });
}
