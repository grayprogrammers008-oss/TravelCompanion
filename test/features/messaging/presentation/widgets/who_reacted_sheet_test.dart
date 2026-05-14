import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/messaging/domain/entities/message_entity.dart';
import 'package:pathio/features/messaging/presentation/widgets/who_reacted_sheet.dart';

void main() {
  void expandViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  final now = DateTime.now();
  final reactions = [
    MessageReaction(
      emoji: '👍',
      userId: 'user-1',
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
    MessageReaction(
      emoji: '👍',
      userId: 'user-2',
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    MessageReaction(
      emoji: '❤️',
      userId: 'user-3',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    MessageReaction(
      emoji: '🎉',
      userId: 'user-4',
      createdAt: now.subtract(const Duration(days: 5)),
    ),
  ];

  final userNames = {
    'user-1': 'Alice',
    'user-2': 'Bob',
    'user-3': 'Charlie',
    'user-4': 'Diana',
  };

  Widget createTestWidget({
    List<MessageReaction>? reactionsOverride,
    Map<String, String>? userNamesOverride,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WhoReactedSheet(
          reactions: reactionsOverride ?? reactions,
          userNames: userNamesOverride ?? userNames,
        ),
      ),
    );
  }

  group('WhoReactedSheet Widget', () {
    testWidgets('renders header with title', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Reactions'), findsOneWidget);
    });

    testWidgets('renders close icon', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows All tab with total count', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('shows tab for each unique emoji', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // 👍, ❤️, 🎉 - 3 emoji tabs + All = 4 tabs
      expect(find.byType(Tab), findsNWidgets(4));
    });

    testWidgets('displays user names from userNames map', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('falls back to Unknown User when name missing',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(userNamesOverride: const {}));
      await tester.pump();

      expect(find.text('Unknown User'), findsWidgets);
    });

    testWidgets('shows time-ago text in subtitle', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // At least one time-ago label should be present
      final timeFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data != null &&
            (w.data!.contains('ago') || w.data!.contains('Just now')),
      );
      expect(timeFinder, findsWidgets);
    });

    testWidgets('renders avatar with first letter of user name',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Avatar shows 'A' for Alice
      expect(find.text('A'), findsWidgets);
    });

    testWidgets('switches to specific emoji tab when tapped', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on the heart emoji tab (use first which is the tab)
      await tester.tap(find.text('❤️').first);
      await tester.pumpAndSettle();

      // Charlie reacted with heart
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('handles single reaction', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(
        reactionsOverride: [
          MessageReaction(
            emoji: '🔥',
            userId: 'user-99',
            createdAt: now,
          ),
        ],
        userNamesOverride: {'user-99': 'Eve'},
      ));
      await tester.pump();

      expect(find.text('Eve'), findsOneWidget);
      expect(find.text('🔥'), findsWidgets);
    });

    testWidgets('groups reactions by emoji correctly', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // 👍 appears twice as reactions, plus in tab
      expect(find.text('👍'), findsWidgets);
    });

    testWidgets('static show method opens bottom sheet', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => WhoReactedSheet.show(
                  context,
                  reactions: reactions,
                  userNames: userNames,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(WhoReactedSheet), findsOneWidget);
      expect(find.text('Reactions'), findsOneWidget);
    });

    testWidgets('close button pops the dialog', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => WhoReactedSheet.show(
                  context,
                  reactions: reactions,
                  userNames: userNames,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(WhoReactedSheet), findsNothing);
    });

    testWidgets('handles empty userNames map gracefully', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(
        reactionsOverride: [
          MessageReaction(
            emoji: '👀',
            userId: 'unknown-id',
            createdAt: now,
          ),
        ],
        userNamesOverride: const {},
      ));
      await tester.pump();

      expect(find.text('Unknown User'), findsOneWidget);
      // Avatar fallback to '?' (initial of 'Unknown User' is 'U' actually so check 'U')
      expect(find.text('U'), findsWidgets);
    });
  });

  group('WhoReactedSheet TimeAgo formatting', () {
    testWidgets('shows Just now for recent reactions', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(
        reactionsOverride: [
          MessageReaction(
            emoji: '👍',
            userId: 'u1',
            createdAt: DateTime.now(),
          ),
        ],
        userNamesOverride: {'u1': 'Recent'},
      ));
      await tester.pump();

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('shows minutes ago for sub-hour reactions', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(
        reactionsOverride: [
          MessageReaction(
            emoji: '👍',
            userId: 'u1',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
        userNamesOverride: {'u1': 'Foo'},
      ));
      await tester.pump();

      expect(find.textContaining('minute'), findsOneWidget);
    });

    testWidgets('shows hours ago for sub-day reactions', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(
        reactionsOverride: [
          MessageReaction(
            emoji: '👍',
            userId: 'u1',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
        userNamesOverride: {'u1': 'Foo'},
      ));
      await tester.pump();

      expect(find.textContaining('hour'), findsOneWidget);
    });

    testWidgets('shows days ago for sub-week reactions', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(createTestWidget(
        reactionsOverride: [
          MessageReaction(
            emoji: '👍',
            userId: 'u1',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ],
        userNamesOverride: {'u1': 'Foo'},
      ));
      await tester.pump();

      expect(find.textContaining('day'), findsOneWidget);
    });
  });
}
