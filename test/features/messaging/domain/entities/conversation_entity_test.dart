import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/conversation_entity.dart';

void main() {
  group('ConversationEntity', () {
    final now = DateTime.now();

    final testMember1 = ConversationMemberEntity(
      id: 'member-1',
      conversationId: 'conv-1',
      userId: 'user-1',
      role: 'admin',
      joinedAt: now,
      userName: 'John Doe',
      userAvatarUrl: 'https://example.com/john.jpg',
      userEmail: 'john@example.com',
    );

    final testMember2 = ConversationMemberEntity(
      id: 'member-2',
      conversationId: 'conv-1',
      userId: 'user-2',
      role: 'member',
      joinedAt: now,
      userName: 'Jane Smith',
      userAvatarUrl: 'https://example.com/jane.jpg',
      userEmail: 'jane@example.com',
    );

    final testConversation = ConversationEntity(
      id: 'conv-1',
      tripId: 'trip-1',
      name: 'Trip Planning',
      description: 'Planning our trip',
      createdBy: 'user-1',
      isDirectMessage: false,
      createdAt: now,
      updatedAt: now,
      lastMessageText: 'Hello everyone!',
      lastMessageAt: now,
      lastMessageSenderName: 'John Doe',
      unreadCount: 5,
      memberCount: 2,
      members: [testMember1, testMember2],
    );

    group('Constructor', () {
      test('creates entity with required fields', () {
        final conversation = ConversationEntity(
          id: 'conv-1',
          tripId: 'trip-1',
          name: 'Test Chat',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(conversation.id, 'conv-1');
        expect(conversation.tripId, 'trip-1');
        expect(conversation.name, 'Test Chat');
        expect(conversation.createdBy, 'user-1');
        expect(conversation.isDirectMessage, false);
        expect(conversation.unreadCount, 0);
        expect(conversation.memberCount, 0);
        expect(conversation.members, isEmpty);
      });

      test('creates entity with all fields', () {
        expect(testConversation.id, 'conv-1');
        expect(testConversation.description, 'Planning our trip');
        expect(testConversation.lastMessageText, 'Hello everyone!');
        expect(testConversation.unreadCount, 5);
        expect(testConversation.memberCount, 2);
        expect(testConversation.members.length, 2);
      });

      test('creates direct message conversation', () {
        final dm = ConversationEntity(
          id: 'dm-1',
          tripId: 'trip-1',
          name: 'Direct Message',
          createdBy: 'user-1',
          isDirectMessage: true,
          createdAt: now,
          updatedAt: now,
          members: [testMember1, testMember2],
        );

        expect(dm.isDirectMessage, true);
      });
    });

    group('getDisplayName', () {
      test('returns conversation name for group chat', () {
        expect(testConversation.getDisplayName('user-1'), 'Trip Planning');
      });

      test('returns other member name for direct message', () {
        final dm = ConversationEntity(
          id: 'dm-1',
          tripId: 'trip-1',
          name: 'Direct Message',
          createdBy: 'user-1',
          isDirectMessage: true,
          createdAt: now,
          updatedAt: now,
          members: [testMember1, testMember2],
        );

        // When current user is user-1, should show Jane Smith
        expect(dm.getDisplayName('user-1'), 'Jane Smith');

        // When current user is user-2, should show John Doe
        expect(dm.getDisplayName('user-2'), 'John Doe');
      });

      test('returns conversation name when no members', () {
        final dm = ConversationEntity(
          id: 'dm-1',
          tripId: 'trip-1',
          name: 'Direct Message',
          createdBy: 'user-1',
          isDirectMessage: true,
          createdAt: now,
          updatedAt: now,
          members: [],
        );

        expect(dm.getDisplayName('user-1'), 'Direct Message');
      });
    });

    group('isUserAdmin', () {
      test('returns true when user is admin', () {
        expect(testConversation.isUserAdmin('user-1'), true);
      });

      test('returns false when user is member', () {
        expect(testConversation.isUserAdmin('user-2'), false);
      });

      test('returns false when user is not in conversation', () {
        expect(testConversation.isUserAdmin('user-3'), false);
      });
    });

    group('isMember', () {
      test('returns true when user is member', () {
        expect(testConversation.isMember('user-1'), true);
        expect(testConversation.isMember('user-2'), true);
      });

      test('returns false when user is not member', () {
        expect(testConversation.isMember('user-3'), false);
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final copied = testConversation.copyWith(name: 'New Name');

        expect(copied.name, 'New Name');
        expect(copied.id, testConversation.id);
        expect(copied.tripId, testConversation.tripId);
      });

      test('copies with new unread count', () {
        final copied = testConversation.copyWith(unreadCount: 10);

        expect(copied.unreadCount, 10);
        expect(copied.name, testConversation.name);
      });

      test('copies with new members', () {
        final newMember = ConversationMemberEntity(
          id: 'member-3',
          conversationId: 'conv-1',
          userId: 'user-3',
          role: 'member',
          joinedAt: now,
          userName: 'Bob',
        );

        final copied = testConversation.copyWith(members: [newMember]);

        expect(copied.members.length, 1);
        expect(copied.members.first.userName, 'Bob');
      });
    });

    group('Equatable', () {
      test('two entities with same data are equal', () {
        final conversation1 = ConversationEntity(
          id: 'conv-1',
          tripId: 'trip-1',
          name: 'Test',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final conversation2 = ConversationEntity(
          id: 'conv-1',
          tripId: 'trip-1',
          name: 'Test',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(conversation1, equals(conversation2));
      });

      test('two entities with different data are not equal', () {
        final conversation1 = ConversationEntity(
          id: 'conv-1',
          tripId: 'trip-1',
          name: 'Test',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        final conversation2 = ConversationEntity(
          id: 'conv-2',
          tripId: 'trip-1',
          name: 'Test',
          createdBy: 'user-1',
          createdAt: now,
          updatedAt: now,
        );

        expect(conversation1, isNot(equals(conversation2)));
      });
    });
  });

  group('ConversationMemberEntity', () {
    final now = DateTime.now();

    group('Constructor', () {
      test('creates entity with required fields', () {
        final member = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: now,
        );

        expect(member.id, 'member-1');
        expect(member.conversationId, 'conv-1');
        expect(member.userId, 'user-1');
        expect(member.role, 'admin');
        expect(member.isMuted, false);
        expect(member.lastReadAt, isNull);
      });

      test('creates entity with all fields', () {
        final member = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'member',
          joinedAt: now,
          isMuted: true,
          lastReadAt: now,
          userName: 'John Doe',
          userAvatarUrl: 'https://example.com/john.jpg',
          userEmail: 'john@example.com',
        );

        expect(member.isMuted, true);
        expect(member.lastReadAt, now);
        expect(member.userName, 'John Doe');
        expect(member.userAvatarUrl, 'https://example.com/john.jpg');
        expect(member.userEmail, 'john@example.com');
      });
    });

    group('Role checks', () {
      test('isAdmin returns true for admin role', () {
        final admin = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: now,
        );

        expect(admin.isAdmin, true);
        expect(admin.isMember, false);
      });

      test('isMember returns true for member role', () {
        final member = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'member',
          joinedAt: now,
        );

        expect(member.isAdmin, false);
        expect(member.isMember, true);
      });
    });

    group('copyWith', () {
      test('copies with new role', () {
        final member = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'member',
          joinedAt: now,
        );

        final copied = member.copyWith(role: 'admin');

        expect(copied.role, 'admin');
        expect(copied.isAdmin, true);
        expect(copied.id, member.id);
      });

      test('copies with muted status', () {
        final member = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'member',
          joinedAt: now,
          isMuted: false,
        );

        final copied = member.copyWith(isMuted: true);

        expect(copied.isMuted, true);
      });
    });

    group('Equatable', () {
      test('two members with same data are equal', () {
        final member1 = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: now,
        );

        final member2 = ConversationMemberEntity(
          id: 'member-1',
          conversationId: 'conv-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: now,
        );

        expect(member1, equals(member2));
      });
    });
  });
}
