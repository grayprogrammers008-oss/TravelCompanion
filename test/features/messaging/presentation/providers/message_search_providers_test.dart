import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/presentation/providers/message_search_providers.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';

void main() {
  group('MessageSearchParams', () {
    test('should create with required fields', () {
      const params = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
      );

      expect(params.conversationId, 'conv-123');
      expect(params.query, 'hello');
      expect(params.filterType, isNull);
    });

    test('should create with optional filterType', () {
      const params = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'text',
      );

      expect(params.conversationId, 'conv-123');
      expect(params.query, 'hello');
      expect(params.filterType, 'text');
    });

    test('should be equal when all properties match', () {
      const params1 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'text',
      );

      const params2 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'text',
      );

      expect(params1, equals(params2));
    });

    test('should not be equal when conversationId differs', () {
      const params1 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
      );

      const params2 = MessageSearchParams(
        conversationId: 'conv-456',
        query: 'hello',
      );

      expect(params1, isNot(equals(params2)));
    });

    test('should not be equal when query differs', () {
      const params1 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
      );

      const params2 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'goodbye',
      );

      expect(params1, isNot(equals(params2)));
    });

    test('should not be equal when filterType differs', () {
      const params1 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'text',
      );

      const params2 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'image',
      );

      expect(params1, isNot(equals(params2)));
    });

    test('should have consistent hashCode for equal objects', () {
      const params1 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'text',
      );

      const params2 = MessageSearchParams(
        conversationId: 'conv-123',
        query: 'hello',
        filterType: 'text',
      );

      expect(params1.hashCode, equals(params2.hashCode));
    });
  });

  group('MessageSearchState', () {
    test('should create with default values', () {
      const state = MessageSearchState();

      expect(state.query, '');
      expect(state.filterType, isNull);
      expect(state.isSearching, false);
      expect(state.results, isEmpty);
      expect(state.error, isNull);
    });

    test('should create with custom values', () {
      final testDate = DateTime(2025, 1, 24, 10, 30);
      final messages = [
        MessageEntity(
          id: 'msg-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello',
          messageType: MessageType.text,
          createdAt: testDate,
          updatedAt: testDate,
        ),
      ];

      final state = MessageSearchState(
        query: 'hello',
        filterType: 'text',
        isSearching: true,
        results: messages,
        error: 'Some error',
      );

      expect(state.query, 'hello');
      expect(state.filterType, 'text');
      expect(state.isSearching, true);
      expect(state.results.length, 1);
      expect(state.error, 'Some error');
    });

    group('copyWith', () {
      test('should copy with new query', () {
        const original = MessageSearchState(query: 'hello');
        final copied = original.copyWith(query: 'world');

        expect(copied.query, 'world');
        expect(original.query, 'hello');
      });

      test('should copy with new filterType', () {
        const original = MessageSearchState(filterType: 'text');
        final copied = original.copyWith(filterType: 'image');

        expect(copied.filterType, 'image');
        expect(original.filterType, 'text');
      });

      test('should copy with new isSearching', () {
        const original = MessageSearchState(isSearching: false);
        final copied = original.copyWith(isSearching: true);

        expect(copied.isSearching, true);
        expect(original.isSearching, false);
      });

      test('should copy with new results', () {
        final testDate = DateTime(2025, 1, 24, 10, 30);
        const original = MessageSearchState(results: []);
        final newResults = [
          MessageEntity(
            id: 'msg-1',
            tripId: 'trip-1',
            senderId: 'user-1',
            message: 'Test',
            messageType: MessageType.text,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        final copied = original.copyWith(results: newResults);

        expect(copied.results.length, 1);
        expect(original.results, isEmpty);
      });

      test('should copy with new error', () {
        const original = MessageSearchState(error: null);
        final copied = original.copyWith(error: 'New error');

        expect(copied.error, 'New error');
        expect(original.error, isNull);
      });

      test('should preserve other values when copying single field', () {
        const original = MessageSearchState(
          query: 'hello',
          filterType: 'text',
          isSearching: true,
        );

        final copied = original.copyWith(query: 'world');

        expect(copied.query, 'world');
        expect(copied.filterType, 'text');
        expect(copied.isSearching, true);
      });
    });
  });

  group('Message filtering logic', () {
    final testDate = DateTime(2025, 1, 24, 10, 30);

    final textMessage = MessageEntity(
      id: 'msg-1',
      tripId: 'trip-1',
      senderId: 'user-1',
      message: 'Hello world',
      messageType: MessageType.text,
      senderName: 'John Doe',
      createdAt: testDate,
      updatedAt: testDate,
    );

    final imageMessage = MessageEntity(
      id: 'msg-2',
      tripId: 'trip-1',
      senderId: 'user-2',
      message: 'Photo from beach',
      messageType: MessageType.image,
      senderName: 'Jane Smith',
      createdAt: testDate,
      updatedAt: testDate,
    );

    final deletedMessage = MessageEntity(
      id: 'msg-3',
      tripId: 'trip-1',
      senderId: 'user-1',
      message: 'Deleted message',
      messageType: MessageType.text,
      isDeleted: true,
      createdAt: testDate,
      updatedAt: testDate,
    );

    final allMessages = [textMessage, imageMessage, deletedMessage];

    test('should filter by message content', () {
      final query = 'hello'.toLowerCase();
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        return message.message?.toLowerCase().contains(query) ?? false;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'msg-1');
    });

    test('should filter by sender name', () {
      final query = 'jane'.toLowerCase();
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        return message.senderName?.toLowerCase().contains(query) ?? false;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'msg-2');
    });

    test('should exclude deleted messages', () {
      final query = 'deleted'.toLowerCase();
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        return message.message?.toLowerCase().contains(query) ?? false;
      }).toList();

      expect(filtered, isEmpty);
    });

    test('should filter by message type - text only', () {
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        return message.messageType == MessageType.text;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.messageType, MessageType.text);
    });

    test('should filter by message type - image only', () {
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        return message.messageType == MessageType.image;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.messageType, MessageType.image);
    });

    test('should combine content search with type filter', () {
      final query = 'photo'.toLowerCase();
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        if (message.messageType != MessageType.image) return false;
        return message.message?.toLowerCase().contains(query) ?? false;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'msg-2');
    });

    test('should return empty for non-matching query', () {
      final query = 'xyz123'.toLowerCase();
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        if (message.message?.toLowerCase().contains(query) ?? false) return true;
        if (message.senderName?.toLowerCase().contains(query) ?? false) return true;
        return false;
      }).toList();

      expect(filtered, isEmpty);
    });

    test('should be case insensitive', () {
      final query = 'HELLO'.toLowerCase();
      final filtered = allMessages.where((message) {
        if (message.isDeleted) return false;
        return message.message?.toLowerCase().contains(query) ?? false;
      }).toList();

      expect(filtered.length, 1);
      expect(filtered.first.message, 'Hello world');
    });
  });
}
