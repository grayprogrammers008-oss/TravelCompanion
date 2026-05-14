import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/messaging/domain/entities/message_entity.dart';
import 'package:pathio/features/messaging/presentation/widgets/message_bubble.dart';

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
  const currentUserId = 'user-current';

  MessageEntity buildMessage({
    String id = 'msg-1',
    String senderId = currentUserId,
    String? message = 'Hello world',
    MessageType type = MessageType.text,
    String? attachmentUrl,
    List<MessageReaction> reactions = const [],
    List<String> readBy = const [],
    String? senderName,
    String? senderAvatarUrl,
    DateTime? createdAt,
  }) {
    return MessageEntity(
      id: id,
      tripId: 'trip-1',
      senderId: senderId,
      message: message,
      messageType: type,
      attachmentUrl: attachmentUrl,
      reactions: reactions,
      readBy: readBy,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      createdAt: createdAt ?? now,
      updatedAt: createdAt ?? now,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MessageBubble - Text messages', () {
    testWidgets('renders own text message', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(message: 'Hi there'),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('Hi there'), findsOneWidget);
    });

    testWidgets('renders received text message with sender name',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            senderId: 'other-user',
            message: 'Hey!',
            senderName: 'Alice',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('Hey!'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows avatar with first letter for received message',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            senderId: 'other-user',
            senderName: 'Bob',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows ? for received message without sender name',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(senderId: 'other-user'),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('does not show avatar for own messages', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('shows single check icon for own message not yet delivered',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(readBy: const [currentUserId]),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows double-check icon when read by others', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(readBy: const [currentUserId, 'other-user']),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });
  });

  group('MessageBubble - Long-press and callbacks', () {
    testWidgets('invokes onLongPress', (tester) async {
      expandViewport(tester);
      var calls = 0;
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(),
          currentUserId: currentUserId,
          onLongPress: () => calls++,
        ),
      ));
      await tester.pump();

      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      expect(calls, 1);
    });
  });

  group('MessageBubble - Reactions', () {
    testWidgets('does not render reactions row when empty', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('renders reactions when present', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            reactions: [
              MessageReaction(
                emoji: '👍',
                userId: 'user-2',
                createdAt: now,
              ),
            ],
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('👍'), findsOneWidget);
    });

    testWidgets('groups reactions and displays count', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            reactions: [
              MessageReaction(
                emoji: '🎉',
                userId: 'u1',
                createdAt: now,
              ),
              MessageReaction(
                emoji: '🎉',
                userId: 'u2',
                createdAt: now,
              ),
              MessageReaction(
                emoji: '🎉',
                userId: 'u3',
                createdAt: now,
              ),
            ],
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping reaction triggers onReactionTap', (tester) async {
      expandViewport(tester);
      var taps = 0;
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            reactions: [
              MessageReaction(
                emoji: '🔥',
                userId: 'u1',
                createdAt: now,
              ),
            ],
          ),
          currentUserId: currentUserId,
          onReactionTap: () => taps++,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('🔥'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('long-pressing reaction triggers onReactionLongPress',
        (tester) async {
      expandViewport(tester);
      String? captured;
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            reactions: [
              MessageReaction(
                emoji: '😂',
                userId: 'u1',
                createdAt: now,
              ),
            ],
          ),
          currentUserId: currentUserId,
          onReactionLongPress: (e) => captured = e,
        ),
      ));
      await tester.pump();

      await tester.longPress(find.text('😂'));
      await tester.pump();

      expect(captured, '😂');
    });
  });

  group('MessageBubble - Other message types', () {
    testWidgets('renders location message with icon', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: 'Sharing my location',
            type: MessageType.location,
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('Sharing my location'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('renders default location text when message null',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(message: null, type: MessageType.location),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('Location shared'), findsOneWidget);
    });

    testWidgets('renders expense link with money icon', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: 'Dinner — \$50',
            type: MessageType.expenseLink,
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.text('Dinner — \$50'), findsOneWidget);
    });

    testWidgets('renders default expense text when message null',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(message: null, type: MessageType.expenseLink),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('Expense shared'), findsOneWidget);
    });

    testWidgets('renders document message with download icon',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '📄 trip-plan.pdf',
            type: MessageType.document,
            attachmentUrl: 'https://example.com/trip-plan.pdf',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('uses Excel icon for xlsx documents', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '📊 budget.xlsx',
            type: MessageType.document,
            attachmentUrl: 'https://example.com/budget.xlsx',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    testWidgets('uses Word icon for docx documents', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '📝 notes.docx',
            type: MessageType.document,
            attachmentUrl: 'https://example.com/notes.docx',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('uses slideshow icon for pptx documents', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '🎯 deck.pptx',
            type: MessageType.document,
            attachmentUrl: 'https://example.com/deck.pptx',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.slideshow), findsOneWidget);
    });

    testWidgets('uses zip icon for archive documents', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '🗜️ files.zip',
            type: MessageType.document,
            attachmentUrl: 'https://example.com/files.zip',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.folder_zip), findsOneWidget);
    });

    testWidgets('uses generic file icon for unknown extension',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '📦 unknown.xyz',
            type: MessageType.document,
            attachmentUrl: 'https://example.com/unknown.xyz',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
    });

    testWidgets('image message with caption renders the caption text',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: 'Beautiful view',
            type: MessageType.image,
            attachmentUrl: 'https://example.com/img.jpg',
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.text('Beautiful view'), findsOneWidget);
    });

    testWidgets('image message without attachment shows nothing extra',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            message: '',
            type: MessageType.image,
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.byType(MessageBubble), findsOneWidget);
    });
  });

  // Skip: avatar-with-URL test requires HttpClient mocking for NetworkImage
  // which adds dependencies not worth chasing — the no-URL avatar branch
  // is already covered by other tests in this file.

  group('MessageBubble - Timestamp formatting', () {
    testWidgets('shows time-only format for today', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(createdAt: DateTime.now()),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      // Should not contain 'Yesterday' or weekday since it's today
      expect(find.textContaining('Yesterday'), findsNothing);
    });

    testWidgets('shows Yesterday prefix for yesterday', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(wrap(
        MessageBubble(
          message: buildMessage(
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          currentUserId: currentUserId,
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Yesterday'), findsOneWidget);
    });
  });
}
