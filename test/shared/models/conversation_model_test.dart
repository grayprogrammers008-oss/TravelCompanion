import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/conversation_model.dart';

void main() {
  group('ConversationModel', () {
    final createdAt = DateTime(2024, 1, 15, 10, 0);
    final updatedAt = DateTime(2024, 1, 15, 11, 0);
    final lastMessageAt = DateTime(2024, 1, 15, 10, 45);

    ConversationModel buildSample() {
      return ConversationModel(
        id: 'conv-1',
        tripId: 't-1',
        name: 'All Members',
        description: 'Trip group',
        avatarUrl: 'https://example.com/a.jpg',
        createdBy: 'u-1',
        isDirectMessage: false,
        isDefaultGroup: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastMessageText: 'Hi',
        lastMessageAt: lastMessageAt,
        lastMessageSenderName: 'John',
        unreadCount: 3,
        memberCount: 5,
      );
    }

    group('constructor', () {
      test('should create with required fields and apply defaults', () {
        final conv = ConversationModel(
          id: 'conv-1',
          tripId: 't-1',
          name: 'Group',
          createdBy: 'u-1',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        expect(conv.id, 'conv-1');
        expect(conv.isDirectMessage, false);
        expect(conv.isDefaultGroup, false);
        expect(conv.unreadCount, 0);
        expect(conv.memberCount, 0);
        expect(conv.members, isEmpty);
      });

      test('should create with all fields', () {
        final conv = buildSample();
        expect(conv.lastMessageText, 'Hi');
        expect(conv.unreadCount, 3);
        expect(conv.memberCount, 5);
        expect(conv.isDefaultGroup, true);
      });
    });

    group('fromJson', () {
      test('should parse JSON with all fields and members', () {
        final json = {
          'id': 'conv-1',
          'trip_id': 't-1',
          'name': 'Group',
          'description': 'desc',
          'avatar_url': 'http://x',
          'created_by': 'u-1',
          'is_direct_message': false,
          'is_default_group': true,
          'created_at': createdAt.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
          'last_message_text': 'Hi',
          'last_message_at': lastMessageAt.toIso8601String(),
          'last_message_sender_name': 'John',
          'unread_count': 3,
          'member_count': 5,
          'members': [
            {
              'id': 'm-1',
              'conversation_id': 'conv-1',
              'user_id': 'u-1',
              'role': 'admin',
              'joined_at': createdAt.toIso8601String(),
            }
          ],
        };

        final conv = ConversationModel.fromJson(json);

        expect(conv.id, 'conv-1');
        expect(conv.unreadCount, 3);
        expect(conv.members.length, 1);
        expect(conv.members.first.role, 'admin');
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'conv-1',
          'trip_id': 't-1',
          'name': 'Group',
          'created_by': 'u-1',
          'created_at': createdAt.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
        };

        final conv = ConversationModel.fromJson(json);

        expect(conv.description, isNull);
        expect(conv.avatarUrl, isNull);
        expect(conv.lastMessageText, isNull);
        expect(conv.lastMessageAt, isNull);
        expect(conv.unreadCount, 0);
        expect(conv.memberCount, 0);
        expect(conv.members, isEmpty);
      });

      test('should parse numeric counts as int', () {
        final json = {
          'id': 'conv-1',
          'trip_id': 't-1',
          'name': 'Group',
          'created_by': 'u-1',
          'created_at': createdAt.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
          'unread_count': 7.0,
          'member_count': 12.0,
        };

        final conv = ConversationModel.fromJson(json);
        expect(conv.unreadCount, 7);
        expect(conv.memberCount, 12);
      });
    });

    group('toJson', () {
      test('should convert to full JSON', () {
        final conv = buildSample();
        final json = conv.toJson();

        expect(json['id'], 'conv-1');
        expect(json['trip_id'], 't-1');
        expect(json['name'], 'All Members');
        expect(json['unread_count'], 3);
        expect(json['member_count'], 5);
        expect(json['is_direct_message'], false);
        expect(json['is_default_group'], true);
      });

      test('toInsertJson excludes computed fields', () {
        final conv = buildSample();
        final json = conv.toInsertJson();

        expect(json['trip_id'], 't-1');
        expect(json['name'], 'All Members');
        expect(json.containsKey('id'), false);
        expect(json.containsKey('unread_count'), false);
        expect(json.containsKey('member_count'), false);
      });
    });

    group('copyWith', () {
      test('should override specified fields', () {
        final original = buildSample();
        final copied = original.copyWith(
          name: 'Renamed',
          unreadCount: 0,
        );

        expect(copied.name, 'Renamed');
        expect(copied.unreadCount, 0);
        expect(copied.id, 'conv-1');
        expect(copied.tripId, 't-1');
      });

      test('should preserve values when nothing overridden', () {
        final original = buildSample();
        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.unreadCount, original.unreadCount);
      });
    });

    group('equality', () {
      test('should be equal when ids match', () {
        final c1 = buildSample();
        final c2 = buildSample().copyWith(name: 'different');
        expect(c1 == c2, true);
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('should not be equal when ids differ', () {
        final c1 = buildSample();
        final c2 = buildSample().copyWith(id: 'conv-2');
        expect(c1 == c2, false);
      });
    });

    group('toString', () {
      test('should contain id and name', () {
        final conv = buildSample();
        final str = conv.toString();
        expect(str, contains('ConversationModel'));
        expect(str, contains('conv-1'));
        expect(str, contains('All Members'));
      });
    });
  });

  group('ConversationMemberModel', () {
    final joinedAt = DateTime(2024, 1, 15, 10, 0);
    final lastReadAt = DateTime(2024, 1, 15, 11, 0);

    ConversationMemberModel buildSample({String role = 'admin'}) {
      return ConversationMemberModel(
        id: 'm-1',
        conversationId: 'conv-1',
        userId: 'u-1',
        role: role,
        joinedAt: joinedAt,
        isMuted: true,
        lastReadAt: lastReadAt,
        userName: 'John',
        userAvatarUrl: 'http://avatar',
        userEmail: 'john@example.com',
      );
    }

    test('constructor stores fields correctly', () {
      final m = buildSample();
      expect(m.id, 'm-1');
      expect(m.role, 'admin');
      expect(m.isMuted, true);
      expect(m.userName, 'John');
    });

    test('isAdmin returns true when role is admin', () {
      expect(buildSample().isAdmin, true);
      expect(buildSample(role: 'member').isAdmin, false);
    });

    test('fromJson parses with full fields', () {
      final json = {
        'id': 'm-1',
        'conversation_id': 'conv-1',
        'user_id': 'u-1',
        'role': 'admin',
        'joined_at': joinedAt.toIso8601String(),
        'is_muted': true,
        'last_read_at': lastReadAt.toIso8601String(),
        'user_name': 'John',
        'user_avatar_url': 'http://avatar',
        'user_email': 'john@example.com',
      };

      final m = ConversationMemberModel.fromJson(json);

      expect(m.id, 'm-1');
      expect(m.role, 'admin');
      expect(m.isMuted, true);
      expect(m.userName, 'John');
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {
        'id': 'm-1',
        'conversation_id': 'conv-1',
        'user_id': 'u-1',
        'joined_at': joinedAt.toIso8601String(),
      };

      final m = ConversationMemberModel.fromJson(json);

      expect(m.role, 'member');
      expect(m.isMuted, false);
      expect(m.lastReadAt, isNull);
      expect(m.userName, isNull);
    });

    test('fromJson reads from nested profiles object', () {
      final json = {
        'id': 'm-1',
        'conversation_id': 'conv-1',
        'user_id': 'u-1',
        'role': 'member',
        'joined_at': joinedAt.toIso8601String(),
        'profiles': {
          'full_name': 'Nested Name',
          'avatar_url': 'http://nested',
          'email': 'nested@example.com',
        },
      };

      final m = ConversationMemberModel.fromJson(json);

      expect(m.userName, 'Nested Name');
      expect(m.userAvatarUrl, 'http://nested');
      expect(m.userEmail, 'nested@example.com');
    });

    test('toJson produces full payload', () {
      final m = buildSample();
      final json = m.toJson();

      expect(json['id'], 'm-1');
      expect(json['conversation_id'], 'conv-1');
      expect(json['role'], 'admin');
      expect(json['is_muted'], true);
      expect(json['user_name'], 'John');
    });

    test('toInsertJson contains only insert fields', () {
      final m = buildSample();
      final json = m.toInsertJson();

      expect(json['conversation_id'], 'conv-1');
      expect(json['user_id'], 'u-1');
      expect(json['role'], 'admin');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('joined_at'), false);
    });

    test('copyWith overrides specified fields', () {
      final original = buildSample();
      final copied = original.copyWith(role: 'member', isMuted: false);

      expect(copied.role, 'member');
      expect(copied.isMuted, false);
      expect(copied.id, 'm-1');
    });

    test('equality based on id', () {
      final m1 = buildSample();
      final m2 = buildSample().copyWith(role: 'member');
      final m3 = buildSample().copyWith(id: 'm-2');

      expect(m1 == m2, true);
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1 == m3, false);
    });

    test('toString contains identifiers', () {
      final m = buildSample();
      final str = m.toString();
      expect(str, contains('ConversationMemberModel'));
      expect(str, contains('m-1'));
      expect(str, contains('admin'));
    });
  });

  group('CreateConversationParams', () {
    test('constructor stores fields correctly', () {
      const params = CreateConversationParams(
        tripId: 't-1',
        name: 'Group',
        description: 'desc',
        memberUserIds: ['u-1', 'u-2'],
      );

      expect(params.tripId, 't-1');
      expect(params.name, 'Group');
      expect(params.description, 'desc');
      expect(params.memberUserIds, ['u-1', 'u-2']);
      expect(params.isDirectMessage, false);
    });

    test('isDirectMessage defaults to false', () {
      const params = CreateConversationParams(
        tripId: 't-1',
        name: 'G',
        memberUserIds: [],
      );
      expect(params.isDirectMessage, false);
    });
  });
}
