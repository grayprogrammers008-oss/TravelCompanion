import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/features/messaging/data/datasources/message_queries.dart';
import 'package:travel_crew/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:travel_crew/shared/models/message_model.dart';

/// Comprehensive unit tests for [MessageRemoteDataSource].
///
/// All Supabase chain calls go through [MessageQueries] which is faked here.
/// We exercise every public non-stream method on the happy path AND the
/// error path, asserting both the args passed to the queries layer and the
/// model returned.
///
/// Realtime stream methods (subscribeToTripMessages,
/// subscribeToMessageUpdates) are intentionally not exercised — they need
/// a live Supabase realtime channel and are kept as direct subscriptions.

class _FakeMessageQueries implements MessageQueries {
  // ---- Recorded calls ----
  Map<String, dynamic>? lastInsertedMessage;
  String? lastFindTripMessagesTripId;
  int? lastFindTripMessagesLimit;
  int? lastFindTripMessagesOffset;
  String? lastFindMessageById;
  String? lastFindMessagesAfterTripId;
  String? lastFindMessagesAfterCreatedAtGt;
  String? lastFindThreadedRepliesId;
  String? lastSoftDeleteId;
  String? lastUpdateById;
  Map<String, dynamic>? lastUpdateData;
  String? lastRpcMarkReadMessageId;
  String? lastRpcMarkReadUserId;
  Map<String, dynamic>? lastInsertedQueueRow;
  String? lastUpdatedQueueId;
  Map<String, dynamic>? lastUpdatedQueueData;
  String? lastDeletedQueueId;

  // ---- Stubbed responses ----
  Map<String, dynamic>? insertMessageResponse;
  List<Map<String, dynamic>> findTripMessagesResponse = const [];
  Map<String, dynamic>? findMessageByIdResponse;
  bool _findByIdReturnNull = false;
  List<Map<String, dynamic>> findMessagesAfterResponse = const [];
  List<Map<String, dynamic>> findThreadedRepliesResponse = const [];
  List<Map<String, dynamic>> findPendingResponse = const [];

  // ---- Throw triggers ----
  Object? throwOnInsert;
  Object? throwOnFindTrip;
  Object? throwOnFindById;
  Object? throwOnFindAfter;
  Object? throwOnFindReplies;
  Object? throwOnSoftDelete;
  Object? throwOnUpdateById;
  Object? throwOnRpcMarkRead;
  Object? throwOnInsertQueue;
  Object? throwOnFindPending;
  Object? throwOnUpdateQueue;
  Object? throwOnDeleteQueue;

  void setFindByIdReturnsNull() => _findByIdReturnNull = true;

  @override
  Future<Map<String, dynamic>> insertMessage(Map<String, dynamic> data) async {
    if (throwOnInsert != null) throw throwOnInsert!;
    lastInsertedMessage = data;
    return insertMessageResponse ?? data;
  }

  @override
  Future<List<Map<String, dynamic>>> findTripMessages({
    required String tripId,
    required int limit,
    required int offset,
  }) async {
    if (throwOnFindTrip != null) throw throwOnFindTrip!;
    lastFindTripMessagesTripId = tripId;
    lastFindTripMessagesLimit = limit;
    lastFindTripMessagesOffset = offset;
    return findTripMessagesResponse;
  }

  @override
  Future<Map<String, dynamic>?> findMessageById(String messageId) async {
    if (throwOnFindById != null) throw throwOnFindById!;
    lastFindMessageById = messageId;
    if (_findByIdReturnNull) return null;
    return findMessageByIdResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findMessagesAfter({
    required String tripId,
    required String createdAtGt,
  }) async {
    if (throwOnFindAfter != null) throw throwOnFindAfter!;
    lastFindMessagesAfterTripId = tripId;
    lastFindMessagesAfterCreatedAtGt = createdAtGt;
    return findMessagesAfterResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findThreadedReplies(
      String messageId) async {
    if (throwOnFindReplies != null) throw throwOnFindReplies!;
    lastFindThreadedRepliesId = messageId;
    return findThreadedRepliesResponse;
  }

  @override
  Future<void> softDeleteMessage(String messageId) async {
    if (throwOnSoftDelete != null) throw throwOnSoftDelete!;
    lastSoftDeleteId = messageId;
  }

  @override
  Future<void> updateMessageById(
      String messageId, Map<String, dynamic> data) async {
    if (throwOnUpdateById != null) throw throwOnUpdateById!;
    lastUpdateById = messageId;
    lastUpdateData = data;
  }

  @override
  Future<void> rpcMarkMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    if (throwOnRpcMarkRead != null) throw throwOnRpcMarkRead!;
    lastRpcMarkReadMessageId = messageId;
    lastRpcMarkReadUserId = userId;
  }

  @override
  Future<void> insertQueuedMessage(Map<String, dynamic> data) async {
    if (throwOnInsertQueue != null) throw throwOnInsertQueue!;
    lastInsertedQueueRow = data;
  }

  @override
  Future<List<Map<String, dynamic>>> findPendingQueuedMessages() async {
    if (throwOnFindPending != null) throw throwOnFindPending!;
    return findPendingResponse;
  }

  @override
  Future<void> updateQueuedMessageById(
      String queueId, Map<String, dynamic> data) async {
    if (throwOnUpdateQueue != null) throw throwOnUpdateQueue!;
    lastUpdatedQueueId = queueId;
    lastUpdatedQueueData = data;
  }

  @override
  Future<void> deleteQueuedMessageById(String queueId) async {
    if (throwOnDeleteQueue != null) throw throwOnDeleteQueue!;
    lastDeletedQueueId = queueId;
  }
}

void main() {
  late _FakeMessageQueries queries;
  late MessageRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  MessageModel buildMsg({
    String id = 'msg-1',
    String tripId = 'trip-1',
    String senderId = 'user-1',
    List<Map<String, dynamic>> reactions = const [],
    List<String> readBy = const [],
  }) {
    return MessageModel(
      id: id,
      tripId: tripId,
      senderId: senderId,
      message: 'hi',
      messageType: 'text',
      reactions: reactions,
      readBy: readBy,
      isDeleted: false,
      createdAt: fixedClock,
      updatedAt: fixedClock,
    );
  }

  Map<String, dynamic> dbRow({
    String id = 'msg-1',
    String tripId = 'trip-1',
    String senderId = 'user-1',
    List<Map<String, dynamic>>? reactions,
    List<String>? readBy,
    Map<String, dynamic>? profiles,
  }) {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_id': senderId,
      'message': 'hi',
      'message_type': 'text',
      'is_deleted': false,
      'reactions': reactions ?? const <Map<String, dynamic>>[],
      'read_by': readBy ?? const <String>[],
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
      if (profiles != null) 'profiles': profiles,
    };
  }

  setUp(() {
    queries = _FakeMessageQueries();
    ds = MessageRemoteDataSource(
      queries: queries,
      clock: () => fixedClock,
    );
  });

  group('sendMessage', () {
    test('inserts the database JSON and returns parsed model', () async {
      queries.insertMessageResponse = dbRow();
      final result = await ds.sendMessage(buildMsg());
      expect(queries.lastInsertedMessage!['id'], 'msg-1');
      expect(queries.lastInsertedMessage!['trip_id'], 'trip-1');
      expect(queries.lastInsertedMessage!['sender_id'], 'user-1');
      expect(result.id, 'msg-1');
    });

    test('wraps query errors with a helpful message', () async {
      queries.throwOnInsert = Exception('boom');
      await expectLater(
        ds.sendMessage(buildMsg()),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to send message'))),
      );
    });
  });

  group('getTripMessages', () {
    test('forwards default limit/offset and parses joined profile', () async {
      queries.findTripMessagesResponse = [
        dbRow(profiles: {'full_name': 'Alice', 'avatar_url': 'http://a'}),
      ];
      final result = await ds.getTripMessages(tripId: 't');
      expect(queries.lastFindTripMessagesTripId, 't');
      expect(queries.lastFindTripMessagesLimit, 50);
      expect(queries.lastFindTripMessagesOffset, 0);
      expect(result, hasLength(1));
      expect(result.single.senderName, 'Alice');
      expect(result.single.senderAvatarUrl, 'http://a');
    });

    test('passes through custom limit/offset', () async {
      queries.findTripMessagesResponse = [];
      await ds.getTripMessages(tripId: 't', limit: 10, offset: 30);
      expect(queries.lastFindTripMessagesLimit, 10);
      expect(queries.lastFindTripMessagesOffset, 30);
    });

    test('returns empty list when query returns empty', () async {
      queries.findTripMessagesResponse = [];
      expect(await ds.getTripMessages(tripId: 't'), isEmpty);
    });

    test('handles row without profiles gracefully', () async {
      queries.findTripMessagesResponse = [dbRow()];
      final result = await ds.getTripMessages(tripId: 't');
      expect(result.single.senderName, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnFindTrip = Exception('boom');
      await expectLater(
        ds.getTripMessages(tripId: 't'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('Failed to get trip messages'))),
      );
    });
  });

  group('getMessageById', () {
    test('returns null when not found', () async {
      queries.setFindByIdReturnsNull();
      expect(await ds.getMessageById('x'), isNull);
      expect(queries.lastFindMessageById, 'x');
    });

    test('returns parsed model with joined profile', () async {
      queries.findMessageByIdResponse =
          dbRow(profiles: {'full_name': 'Bob', 'avatar_url': 'b'});
      final result = await ds.getMessageById('msg-1');
      expect(result, isNotNull);
      expect(result!.senderName, 'Bob');
      expect(result.senderAvatarUrl, 'b');
    });

    test('returns parsed model when profiles missing', () async {
      queries.findMessageByIdResponse = dbRow();
      final result = await ds.getMessageById('msg-1');
      expect(result!.senderName, isNull);
    });

    test('wraps errors', () async {
      queries.throwOnFindById = Exception('boom');
      await expectLater(
        ds.getMessageById('m'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('Failed to get message by ID'))),
      );
    });
  });

  group('getMessagesAfter', () {
    test('passes ISO timestamp and trip id, returns parsed models', () async {
      final after = DateTime.utc(2024, 5, 20);
      queries.findMessagesAfterResponse = [
        dbRow(profiles: {'full_name': 'Z'}),
      ];
      final result =
          await ds.getMessagesAfter(tripId: 't', timestamp: after);
      expect(queries.lastFindMessagesAfterTripId, 't');
      expect(queries.lastFindMessagesAfterCreatedAtGt,
          after.toIso8601String());
      expect(result.single.senderName, 'Z');
    });

    test('wraps errors', () async {
      queries.throwOnFindAfter = Exception('boom');
      await expectLater(
        ds.getMessagesAfter(tripId: 't', timestamp: fixedClock),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get messages after'))),
      );
    });
  });

  group('getThreadedReplies', () {
    test('passes message id and parses results', () async {
      queries.findThreadedRepliesResponse = [dbRow(id: 'r-1')];
      final result = await ds.getThreadedReplies('parent');
      expect(queries.lastFindThreadedRepliesId, 'parent');
      expect(result.single.id, 'r-1');
    });

    test('wraps errors', () async {
      queries.throwOnFindReplies = Exception('boom');
      await expectLater(
        ds.getThreadedReplies('p'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get threaded replies'))),
      );
    });
  });

  group('deleteMessage', () {
    test('soft deletes by id', () async {
      await ds.deleteMessage('msg-1');
      expect(queries.lastSoftDeleteId, 'msg-1');
    });

    test('wraps errors', () async {
      queries.throwOnSoftDelete = Exception('boom');
      await expectLater(
        ds.deleteMessage('m'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to delete message'))),
      );
    });
  });

  group('markMessageAsRead', () {
    test('uses RPC happy path and records args', () async {
      await ds.markMessageAsRead(messageId: 'm', userId: 'u');
      expect(queries.lastRpcMarkReadMessageId, 'm');
      expect(queries.lastRpcMarkReadUserId, 'u');
      // No fallback used
      expect(queries.lastUpdateById, isNull);
    });

    test('falls back to direct update when RPC throws and user not in readBy',
        () async {
      queries.throwOnRpcMarkRead = Exception('no rpc');
      queries.findMessageByIdResponse =
          dbRow(readBy: ['u-other']);
      await ds.markMessageAsRead(messageId: 'msg-1', userId: 'u-new');
      expect(queries.lastUpdateById, 'msg-1');
      expect(queries.lastUpdateData, {
        'read_by': ['u-other', 'u-new']
      });
    });

    test('fallback no-ops when message already has user in readBy', () async {
      queries.throwOnRpcMarkRead = Exception('no rpc');
      queries.findMessageByIdResponse = dbRow(readBy: ['u-here']);
      await ds.markMessageAsRead(messageId: 'msg-1', userId: 'u-here');
      expect(queries.lastUpdateById, isNull); // no update issued
    });

    test('fallback returns silently when message lookup yields null', () async {
      queries.throwOnRpcMarkRead = Exception('no rpc');
      queries.setFindByIdReturnsNull();
      await ds.markMessageAsRead(messageId: 'm', userId: 'u');
      expect(queries.lastUpdateById, isNull);
    });

    test('fallback wraps errors when getMessageById throws', () async {
      queries.throwOnRpcMarkRead = Exception('rpc fail');
      queries.throwOnFindById = Exception('lookup fail');
      await expectLater(
        ds.markMessageAsRead(messageId: 'm', userId: 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to mark message as read'))),
      );
    });
  });

  group('addReaction', () {
    test('throws when message not found', () async {
      queries.setFindByIdReturnsNull();
      await expectLater(
        ds.addReaction(messageId: 'm', userId: 'u', emoji: '🔥'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('Failed to add reaction'))),
      );
    });

    test('appends reaction when not already present', () async {
      queries.findMessageByIdResponse = dbRow();
      await ds.addReaction(messageId: 'msg-1', userId: 'u', emoji: '🔥');
      expect(queries.lastUpdateById, 'msg-1');
      final reactions =
          queries.lastUpdateData!['reactions'] as List<dynamic>;
      expect(reactions.single['emoji'], '🔥');
      expect(reactions.single['user_id'], 'u');
      expect(reactions.single['created_at'], fixedClock.toIso8601String());
    });

    test('does not update when same user/emoji reaction already exists',
        () async {
      queries.findMessageByIdResponse = dbRow(reactions: [
        {'emoji': '🔥', 'user_id': 'u', 'created_at': 'whenever'},
      ]);
      await ds.addReaction(messageId: 'msg-1', userId: 'u', emoji: '🔥');
      expect(queries.lastUpdateById, isNull);
    });

    test('wraps query errors', () async {
      queries.findMessageByIdResponse = dbRow();
      queries.throwOnUpdateById = Exception('boom');
      await expectLater(
        ds.addReaction(messageId: 'm', userId: 'u', emoji: '🔥'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('Failed to add reaction'))),
      );
    });
  });

  group('removeReaction', () {
    test('throws when message not found', () async {
      queries.setFindByIdReturnsNull();
      await expectLater(
        ds.removeReaction(messageId: 'm', userId: 'u', emoji: '🔥'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to remove reaction'))),
      );
    });

    test('removes only the matching user/emoji reaction', () async {
      queries.findMessageByIdResponse = dbRow(reactions: [
        {'emoji': '🔥', 'user_id': 'u'},
        {'emoji': '🔥', 'user_id': 'other'},
        {'emoji': '👍', 'user_id': 'u'},
      ]);
      await ds.removeReaction(messageId: 'msg-1', userId: 'u', emoji: '🔥');
      final reactions =
          queries.lastUpdateData!['reactions'] as List<dynamic>;
      expect(reactions, hasLength(2));
      expect(reactions.any((r) => r['user_id'] == 'u' && r['emoji'] == '🔥'),
          isFalse);
    });

    test('wraps query errors', () async {
      queries.findMessageByIdResponse = dbRow();
      queries.throwOnUpdateById = Exception('boom');
      await expectLater(
        ds.removeReaction(messageId: 'm', userId: 'u', emoji: '🔥'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to remove reaction'))),
      );
    });
  });

  group('queueMessage / getPendingMessages / updateQueueStatus / removeFromQueue',
      () {
    QueuedMessageModel buildQ({String id = 'q-1'}) => QueuedMessageModel(
          id: id,
          tripId: 't',
          senderId: 's',
          messageData: const {'k': 'v'},
          transmissionMethod: 'internet',
          syncStatus: 'pending',
          createdAt: fixedClock,
        );

    test('queueMessage forwards JSON', () async {
      await ds.queueMessage(buildQ());
      expect(queries.lastInsertedQueueRow!['id'], 'q-1');
      expect(queries.lastInsertedQueueRow!['trip_id'], 't');
    });

    test('queueMessage wraps errors', () async {
      queries.throwOnInsertQueue = Exception('boom');
      await expectLater(
        ds.queueMessage(buildQ()),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('Failed to queue message'))),
      );
    });

    test('getPendingMessages parses rows', () async {
      queries.findPendingResponse = [buildQ().toJson()];
      final result = await ds.getPendingMessages();
      expect(result.single.id, 'q-1');
    });

    test('getPendingMessages wraps errors', () async {
      queries.throwOnFindPending = Exception('boom');
      await expectLater(
        ds.getPendingMessages(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to get pending messages'))),
      );
    });

    test('updateQueueStatus sets status, last_attempt_at, error_message',
        () async {
      await ds.updateQueueStatus(
          queueId: 'q-1', status: 'failed', errorMessage: 'oops');
      expect(queries.lastUpdatedQueueId, 'q-1');
      expect(queries.lastUpdatedQueueData, {
        'sync_status': 'failed',
        'last_attempt_at': fixedClock.toIso8601String(),
        'error_message': 'oops',
      });
    });

    test('updateQueueStatus accepts null errorMessage', () async {
      await ds.updateQueueStatus(queueId: 'q-1', status: 'synced');
      expect(queries.lastUpdatedQueueData!['error_message'], isNull);
    });

    test('updateQueueStatus wraps errors', () async {
      queries.throwOnUpdateQueue = Exception('boom');
      await expectLater(
        ds.updateQueueStatus(queueId: 'q', status: 's'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Failed to update queue status'))),
      );
    });

    test('removeFromQueue forwards id', () async {
      await ds.removeFromQueue('q-1');
      expect(queries.lastDeletedQueueId, 'q-1');
    });

    test('removeFromQueue wraps errors', () async {
      queries.throwOnDeleteQueue = Exception('boom');
      await expectLater(
        ds.removeFromQueue('q'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('Failed to remove from queue'))),
      );
    });
  });
}
