import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/messaging/domain/entities/notification_payload.dart';

void main() {
  NotificationPayload base({
    String type = 'new_message',
    String tripId = 't-1',
    String tripName = 'Bali Trip',
    String? messageId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? messageText,
    String? reactionEmoji,
    String? updatedField,
    String? memberName,
  }) =>
      NotificationPayload(
        type: type,
        tripId: tripId,
        tripName: tripName,
        messageId: messageId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        messageText: messageText,
        reactionEmoji: reactionEmoji,
        updatedField: updatedField,
        memberName: memberName,
      );

  group('NotificationPayload constructor', () {
    test('stores required fields', () {
      const p = NotificationPayload(
        type: 'new_message',
        tripId: 't1',
        tripName: 'Bali',
      );
      expect(p.type, 'new_message');
      expect(p.tripId, 't1');
      expect(p.tripName, 'Bali');
      expect(p.messageId, isNull);
      expect(p.senderId, isNull);
      expect(p.senderName, isNull);
    });

    test('stores all optional fields', () {
      const p = NotificationPayload(
        type: 'new_message',
        tripId: 't',
        tripName: 'Trip',
        messageId: 'm-1',
        senderId: 'u-1',
        senderName: 'Alice',
        senderAvatarUrl: 'https://example.com/a.png',
        messageText: 'hello',
        reactionEmoji: '🎉',
        updatedField: 'destination',
        memberName: 'Bob',
      );
      expect(p.messageId, 'm-1');
      expect(p.senderId, 'u-1');
      expect(p.senderName, 'Alice');
      expect(p.senderAvatarUrl, 'https://example.com/a.png');
      expect(p.messageText, 'hello');
      expect(p.reactionEmoji, '🎉');
      expect(p.updatedField, 'destination');
      expect(p.memberName, 'Bob');
    });
  });

  group('NotificationPayload.fromJson — snake_case', () {
    test('parses minimum required fields', () {
      final p = NotificationPayload.fromJson({
        'type': 'new_message',
        'trip_id': 't-1',
        'trip_name': 'Trip',
      });
      expect(p.type, 'new_message');
      expect(p.tripId, 't-1');
      expect(p.tripName, 'Trip');
      expect(p.messageId, isNull);
    });

    test('parses every optional field from snake_case', () {
      final p = NotificationPayload.fromJson({
        'type': 'message_reply',
        'trip_id': 't-1',
        'trip_name': 'Trip',
        'message_id': 'm-1',
        'sender_id': 'u-1',
        'sender_name': 'Alice',
        'sender_avatar_url': 'a.png',
        'message_text': 'hi',
        'reaction_emoji': '🎉',
        'updated_field': 'name',
        'member_name': 'Bob',
      });
      expect(p.messageId, 'm-1');
      expect(p.senderId, 'u-1');
      expect(p.senderName, 'Alice');
      expect(p.senderAvatarUrl, 'a.png');
      expect(p.messageText, 'hi');
      expect(p.reactionEmoji, '🎉');
      expect(p.updatedField, 'name');
      expect(p.memberName, 'Bob');
    });
  });

  group('NotificationPayload.fromJson — camelCase fallback', () {
    test('parses camelCase keys when snake_case is absent', () {
      final p = NotificationPayload.fromJson({
        'type': 'new_message',
        'tripId': 't-1',
        'tripName': 'Trip',
        'messageId': 'm-1',
        'senderId': 'u-1',
        'senderName': 'Alice',
        'senderAvatarUrl': 'a.png',
        'messageText': 'hi',
        'reactionEmoji': '🎉',
        'updatedField': 'name',
        'memberName': 'Bob',
      });
      expect(p.tripId, 't-1');
      expect(p.tripName, 'Trip');
      expect(p.messageId, 'm-1');
      expect(p.senderId, 'u-1');
      expect(p.senderName, 'Alice');
      expect(p.senderAvatarUrl, 'a.png');
      expect(p.messageText, 'hi');
      expect(p.reactionEmoji, '🎉');
      expect(p.updatedField, 'name');
      expect(p.memberName, 'Bob');
    });

    test('defaults type to "new_message" when missing', () {
      final p = NotificationPayload.fromJson({
        'trip_id': 't',
        'trip_name': 'X',
      });
      expect(p.type, 'new_message');
    });
  });

  group('NotificationPayload.toJson', () {
    test('emits required fields with snake_case keys', () {
      final p = base();
      final json = p.toJson();
      expect(json['type'], 'new_message');
      expect(json['trip_id'], 't-1');
      expect(json['trip_name'], 'Bali Trip');
    });

    test('omits null optional fields', () {
      final p = base();
      final json = p.toJson();
      expect(json.containsKey('message_id'), isFalse);
      expect(json.containsKey('sender_id'), isFalse);
      expect(json.containsKey('sender_avatar_url'), isFalse);
      expect(json.containsKey('member_name'), isFalse);
    });

    test('emits every set optional field', () {
      final p = base(
        messageId: 'm',
        senderId: 'u',
        senderName: 'A',
        senderAvatarUrl: 'a.png',
        messageText: 'hi',
        reactionEmoji: '🎉',
        updatedField: 'name',
        memberName: 'B',
      );
      final json = p.toJson();
      expect(json['message_id'], 'm');
      expect(json['sender_id'], 'u');
      expect(json['sender_name'], 'A');
      expect(json['sender_avatar_url'], 'a.png');
      expect(json['message_text'], 'hi');
      expect(json['reaction_emoji'], '🎉');
      expect(json['updated_field'], 'name');
      expect(json['member_name'], 'B');
    });
  });

  group('NotificationPayload.getTitle', () {
    test('new_message → senderName', () {
      expect(base(senderName: 'Alice').getTitle(), 'Alice');
    });

    test('new_message → "New Message" when senderName is null', () {
      expect(base().getTitle(), 'New Message');
    });

    test('message_reaction → "{senderName} reacted to your message"', () {
      expect(
        base(type: 'message_reaction', senderName: 'Alice').getTitle(),
        'Alice reacted to your message',
      );
    });

    test('message_reply → "{senderName} replied to your message"', () {
      expect(
        base(type: 'message_reply', senderName: 'Alice').getTitle(),
        'Alice replied to your message',
      );
    });

    test('trip_created → "New Trip Created"', () {
      expect(base(type: 'trip_created').getTitle(), 'New Trip Created');
    });

    test('trip_updated → "Trip Updated"', () {
      expect(base(type: 'trip_updated').getTitle(), 'Trip Updated');
    });

    test('trip_deleted → "Trip Deleted"', () {
      expect(base(type: 'trip_deleted').getTitle(), 'Trip Deleted');
    });

    test('member_added → "Member Added"', () {
      expect(base(type: 'member_added').getTitle(), 'Member Added');
    });

    test('member_removed → "Member Removed"', () {
      expect(base(type: 'member_removed').getTitle(), 'Member Removed');
    });

    test('unknown type → tripName', () {
      expect(base(type: 'something_else').getTitle(), 'Bali Trip');
    });
  });

  group('NotificationPayload.getBody', () {
    test('new_message → messageText when set', () {
      expect(base(messageText: 'hello').getBody(), 'hello');
    });

    test('new_message → fallback referencing tripName when messageText null',
        () {
      expect(
          base().getBody(), 'You have a new message in Bali Trip');
    });

    test('message_reaction → reactionEmoji when set', () {
      expect(
        base(type: 'message_reaction', reactionEmoji: '🔥').getBody(),
        '🔥',
      );
    });

    test('message_reaction → ❤️ default when emoji missing', () {
      expect(base(type: 'message_reaction').getBody(), '❤️');
    });

    test('message_reply → messageText when set', () {
      expect(
        base(type: 'message_reply', messageText: 'reply').getBody(),
        'reply',
      );
    });

    test('message_reply → "Replied to your message" default', () {
      expect(
        base(type: 'message_reply').getBody(),
        'Replied to your message',
      );
    });

    test('trip_created → references senderName and tripName', () {
      expect(
        base(type: 'trip_created', senderName: 'Alice').getBody(),
        'Alice created a new trip: Bali Trip',
      );
    });

    test('trip_created → uses "Someone" when senderName missing', () {
      expect(
        base(type: 'trip_created').getBody(),
        'Someone created a new trip: Bali Trip',
      );
    });

    test('trip_updated → includes updatedField parenthetical when set', () {
      expect(
        base(type: 'trip_updated', senderName: 'Alice', updatedField: 'name')
            .getBody(),
        'Alice updated Bali Trip (name)',
      );
    });

    test('trip_updated → omits parenthetical when updatedField is null', () {
      expect(
        base(type: 'trip_updated', senderName: 'Alice').getBody(),
        'Alice updated Bali Trip',
      );
    });

    test('trip_deleted → references senderName + tripName', () {
      expect(
        base(type: 'trip_deleted', senderName: 'Alice').getBody(),
        'Alice deleted the trip: Bali Trip',
      );
    });

    test('member_added → "{memberName} joined {tripName}"', () {
      expect(
        base(type: 'member_added', memberName: 'Bob').getBody(),
        'Bob joined Bali Trip',
      );
    });

    test('member_added → "Someone joined ..." when memberName null', () {
      expect(
        base(type: 'member_added').getBody(),
        'Someone joined Bali Trip',
      );
    });

    test('member_removed → "{memberName} left {tripName}"', () {
      expect(
        base(type: 'member_removed', memberName: 'Bob').getBody(),
        'Bob left Bali Trip',
      );
    });

    test('unknown type → messageText', () {
      expect(
        base(type: 'unknown', messageText: 'hi').getBody(),
        'hi',
      );
    });

    test('unknown type → empty string when messageText null', () {
      expect(base(type: 'unknown').getBody(), '');
    });
  });

  group('NotificationPayload equality', () {
    test('equal when all fields match', () {
      final a = base(senderName: 'Alice', messageText: 'hi');
      final b = base(senderName: 'Alice', messageText: 'hi');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when type differs', () {
      expect(base(type: 'new_message') == base(type: 'trip_updated'), isFalse);
    });

    test('not equal when tripId differs', () {
      expect(base(tripId: 'a') == base(tripId: 'b'), isFalse);
    });

    test('not equal when senderName differs', () {
      expect(base(senderName: 'A') == base(senderName: 'B'), isFalse);
    });
  });
}
