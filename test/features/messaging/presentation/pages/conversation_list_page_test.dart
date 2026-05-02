import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/conversation_entity.dart';
import 'package:travel_crew/features/messaging/presentation/pages/conversation_list_page.dart';
import 'package:travel_crew/features/messaging/presentation/providers/conversation_providers.dart';

/// Local filter enum used for tests since the production page doesn't expose one.
enum ConversationFilter { all, directMessages, groups }

void main() {
  final now = DateTime.now();

  final testMember1 = ConversationMemberEntity(
    id: 'member-1',
    conversationId: 'conv-1',
    userId: 'current-user',
    role: 'admin',
    joinedAt: now,
    userName: 'Current User',
  );

  final testMember2 = ConversationMemberEntity(
    id: 'member-2',
    conversationId: 'conv-1',
    userId: 'user-2',
    role: 'member',
    joinedAt: now,
    userName: 'Jane Smith',
  );

  final testGroupConversation = ConversationEntity(
    id: 'conv-1',
    tripId: 'trip-1',
    name: 'Trip Planning',
    createdBy: 'current-user',
    createdAt: now,
    updatedAt: now,
    isDirectMessage: false,
    members: [testMember1, testMember2],
    memberCount: 3,
    unreadCount: 2,
    lastMessageText: 'Last group message',
    lastMessageAt: now.subtract(const Duration(minutes: 5)),
    lastMessageSenderName: 'Jane Smith',
  );

  final testDMConversation = ConversationEntity(
    id: 'dm-1',
    tripId: 'trip-1',
    name: 'Direct Message',
    createdBy: 'current-user',
    createdAt: now,
    updatedAt: now,
    isDirectMessage: true,
    members: [testMember1, testMember2],
    memberCount: 2,
    unreadCount: 1,
    lastMessageText: 'Hey there!',
    lastMessageAt: now.subtract(const Duration(hours: 1)),
    lastMessageSenderName: 'Jane Smith',
  );

  Widget createTestWidget({
    required List<ConversationEntity> conversations,
  }) {
    // The production page reads tripConversationsStreamProvider (a Stream).
    return ProviderScope(
      overrides: [
        tripConversationsStreamProvider(const TripConversationsParams(
          tripId: 'trip-1',
          userId: 'current-user',
        )).overrideWith((ref) => Stream.value(conversations)),
      ],
      child: const MaterialApp(
        home: ConversationListPage(
          tripId: 'trip-1',
          tripName: 'Beach Vacation',
          currentUserId: 'current-user',
        ),
      ),
    );
  }

  group('ConversationListPage', () {
    testWidgets('displays Group Chats title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(conversations: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Group Chats'), findsOneWidget);
    });

    testWidgets('displays trip name in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(conversations: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Beach Vacation'), findsOneWidget);
    });

    testWidgets('displays empty-state message when no group chats exist',
        (tester) async {
      await tester.pumpWidget(createTestWidget(conversations: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No Group Chats Yet'), findsOneWidget);
    });

    testWidgets('displays groups icon in empty state', (tester) async {
      await tester.pumpWidget(createTestWidget(conversations: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    });

    testWidgets('displays search icon', (tester) async {
      await tester.pumpWidget(createTestWidget(conversations: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays group conversation name when groups exist',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        conversations: [testGroupConversation],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Trip Planning'), findsOneWidget);
    });

    testWidgets('hides direct-message conversations (groups only)',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        conversations: [testGroupConversation, testDMConversation],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Group conversation visible
      expect(find.text('Trip Planning'), findsOneWidget);
      // DM conversation hidden — page filters out DMs
      expect(find.text('Direct Message'), findsNothing);
    });
  });

  group('ConversationFilter', () {
    test('ConversationFilter has correct values', () {
      expect(ConversationFilter.values.length, 3);
      expect(ConversationFilter.all.name, 'all');
      expect(ConversationFilter.directMessages.name, 'directMessages');
      expect(ConversationFilter.groups.name, 'groups');
    });
  });

  group('ConversationEntity filtering logic', () {
    test('can identify direct messages', () {
      expect(testDMConversation.isDirectMessage, true);
      expect(testGroupConversation.isDirectMessage, false);
    });

    test('can filter only DMs', () {
      final conversations = [testGroupConversation, testDMConversation];
      final dms = conversations.where((c) => c.isDirectMessage).toList();

      expect(dms.length, 1);
      expect(dms.first.id, 'dm-1');
    });

    test('can filter only groups', () {
      final conversations = [testGroupConversation, testDMConversation];
      final groups = conversations.where((c) => !c.isDirectMessage).toList();

      expect(groups.length, 1);
      expect(groups.first.id, 'conv-1');
    });

    test('getDisplayName returns correct name for group', () {
      expect(
        testGroupConversation.getDisplayName('current-user'),
        'Trip Planning',
      );
    });

    test('getDisplayName returns other user name for DM', () {
      expect(
        testDMConversation.getDisplayName('current-user'),
        'Jane Smith',
      );
    });
  });
}
