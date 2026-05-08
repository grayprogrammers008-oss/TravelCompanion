import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/features/messaging/data/datasources/conversation_queries.dart';
import 'package:travel_crew/features/messaging/data/datasources/conversation_remote_datasource.dart';

/// Comprehensive unit tests for [ConversationRemoteDataSource].
///
/// All Supabase chain calls go through [ConversationQueries] which is
/// faked here. We exercise every public non-stream method on the happy
/// path AND the error path, asserting both the args passed to the queries
/// layer and the model returned.
///
/// Realtime stream methods (subscribeToConversation,
/// subscribeToConversationMessages, subscribeToTripMessages,
/// subscribeToConversationMemberChanges, subscribeToTripActivityChanges)
/// are intentionally not exercised — they need a live Supabase realtime
/// channel and are kept as direct subscriptions.

class _FakeConversationQueries implements ConversationQueries {
  // ---- Conversations ----
  Map<String, dynamic>? lastInsertedConversation;
  String? lastUpdatedConvId;
  Map<String, dynamic>? lastUpdatedConvData;
  String? lastDeletedConvId;
  String? lastFindDefaultGroupTripId;
  String? lastFindDmsTripId;

  Map<String, dynamic>? insertConversationResponse;
  String? findDefaultGroupResponse; // null = not found
  bool _findDefaultGroupReturnNull = false;
  List<Map<String, dynamic>> findDmsResponse = const [];

  // ---- RPCs ----
  String? lastRpcGetTripConvsTripId;
  String? lastRpcGetTripConvsUserId;
  String? lastRpcGetConvDetailsConvId;
  String? lastRpcGetConvDetailsUserId;
  String? lastRpcMarkReadConvId;
  String? lastRpcMarkReadUserId;
  String? lastRpcFindDmTripId;
  String? lastRpcFindDmUser1;
  String? lastRpcFindDmUser2;
  String? lastRpcEnsureUserTripId;
  String? lastRpcEnsureUserUserId;
  String? lastRpcEnsureGroupTripId;

  List<dynamic> rpcGetTripConvsResponse = const [];
  List<dynamic> rpcGetConvDetailsResponse = const [];
  String? rpcFindDmResponse;
  bool _rpcFindDmReturnNull = false;
  String? rpcEnsureUserResponse;
  bool _rpcEnsureUserReturnNull = false;
  String? rpcEnsureGroupResponse;
  bool _rpcEnsureGroupReturnNull = false;

  // ---- Members ----
  List<List<Map<String, dynamic>>> insertedMemberBatches = [];
  String? lastDeletedMemberConvId;
  String? lastDeletedMemberUserId;
  String? lastUpdatedMemberConvId;
  String? lastUpdatedMemberUserId;
  Map<String, dynamic>? lastUpdatedMemberData;
  String? lastFindMembersConvId;
  bool? lastFindMembersOrdered;

  List<Map<String, dynamic>> findMembersResponse = const [];

  // ---- Messages ----
  String? lastFindConvMessagesConvId;
  int? lastFindConvMessagesLimit;
  int? lastFindConvMessagesOffset;
  Map<String, dynamic>? lastInsertedMessage;
  String? lastSoftDeleteMsgId;
  String? lastSoftDeleteSenderId;
  List<String> softDeleteCallLog = [];

  List<Map<String, dynamic>> findConvMessagesResponse = const [];
  Map<String, dynamic>? insertMessageResponse;

  // ---- Throw triggers ----
  Object? throwOnInsertConv;
  Object? throwOnUpdateConv;
  Object? throwOnDeleteConv;
  Object? throwOnFindDefaultGroup;
  Object? throwOnFindDms;
  Object? throwOnRpcGetTripConvs;
  Object? throwOnRpcGetConvDetails;
  Object? throwOnRpcMarkRead;
  Object? throwOnRpcFindDm;
  Object? throwOnRpcEnsureUser;
  Object? throwOnRpcEnsureGroup;
  Object? throwOnInsertMembers;
  Object? throwOnDeleteMember;
  Object? throwOnUpdateMember;
  Object? throwOnFindMembers;
  Object? throwOnFindConvMessages;
  Object? throwOnInsertMessage;
  Object? throwOnSoftDeleteBySender;

  // toggles
  void setFindDefaultGroupReturnsNull() => _findDefaultGroupReturnNull = true;
  void setRpcFindDmReturnsNull() => _rpcFindDmReturnNull = true;
  void setRpcEnsureUserReturnsNull() => _rpcEnsureUserReturnNull = true;
  void setRpcEnsureGroupReturnsNull() => _rpcEnsureGroupReturnNull = true;

  // ---- impls ----

  @override
  Future<Map<String, dynamic>> insertConversation(
      Map<String, dynamic> data) async {
    if (throwOnInsertConv != null) throw throwOnInsertConv!;
    lastInsertedConversation = data;
    return insertConversationResponse ?? {'id': 'conv-1', ...data};
  }

  @override
  Future<void> updateConversationById(
      String conversationId, Map<String, dynamic> data) async {
    if (throwOnUpdateConv != null) throw throwOnUpdateConv!;
    lastUpdatedConvId = conversationId;
    lastUpdatedConvData = data;
  }

  @override
  Future<void> deleteConversationById(String conversationId) async {
    if (throwOnDeleteConv != null) throw throwOnDeleteConv!;
    lastDeletedConvId = conversationId;
  }

  @override
  Future<String?> findDefaultGroupIdForTrip(String tripId) async {
    if (throwOnFindDefaultGroup != null) throw throwOnFindDefaultGroup!;
    lastFindDefaultGroupTripId = tripId;
    if (_findDefaultGroupReturnNull) return null;
    return findDefaultGroupResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findDirectMessagesForTrip(
      String tripId) async {
    if (throwOnFindDms != null) throw throwOnFindDms!;
    lastFindDmsTripId = tripId;
    return findDmsResponse;
  }

  @override
  Future<List<dynamic>> rpcGetTripConversations({
    required String tripId,
    required String userId,
  }) async {
    if (throwOnRpcGetTripConvs != null) throw throwOnRpcGetTripConvs!;
    lastRpcGetTripConvsTripId = tripId;
    lastRpcGetTripConvsUserId = userId;
    return rpcGetTripConvsResponse;
  }

  @override
  Future<List<dynamic>> rpcGetConversationWithDetails({
    required String conversationId,
    required String userId,
  }) async {
    if (throwOnRpcGetConvDetails != null) throw throwOnRpcGetConvDetails!;
    lastRpcGetConvDetailsConvId = conversationId;
    lastRpcGetConvDetailsUserId = userId;
    return rpcGetConvDetailsResponse;
  }

  @override
  Future<void> rpcMarkConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    if (throwOnRpcMarkRead != null) throw throwOnRpcMarkRead!;
    lastRpcMarkReadConvId = conversationId;
    lastRpcMarkReadUserId = userId;
  }

  @override
  Future<String?> rpcFindExistingDm({
    required String tripId,
    required String user1Id,
    required String user2Id,
  }) async {
    if (throwOnRpcFindDm != null) throw throwOnRpcFindDm!;
    lastRpcFindDmTripId = tripId;
    lastRpcFindDmUser1 = user1Id;
    lastRpcFindDmUser2 = user2Id;
    if (_rpcFindDmReturnNull) return null;
    return rpcFindDmResponse;
  }

  @override
  Future<String?> rpcEnsureUserInDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    if (throwOnRpcEnsureUser != null) throw throwOnRpcEnsureUser!;
    lastRpcEnsureUserTripId = tripId;
    lastRpcEnsureUserUserId = userId;
    if (_rpcEnsureUserReturnNull) return null;
    return rpcEnsureUserResponse;
  }

  @override
  Future<String?> rpcEnsureTripDefaultGroup(String tripId) async {
    if (throwOnRpcEnsureGroup != null) throw throwOnRpcEnsureGroup!;
    lastRpcEnsureGroupTripId = tripId;
    if (_rpcEnsureGroupReturnNull) return null;
    return rpcEnsureGroupResponse;
  }

  @override
  Future<void> insertConversationMembers(
      List<Map<String, dynamic>> rows) async {
    if (throwOnInsertMembers != null) throw throwOnInsertMembers!;
    insertedMemberBatches.add(rows);
  }

  @override
  Future<void> deleteConversationMember({
    required String conversationId,
    required String userId,
  }) async {
    if (throwOnDeleteMember != null) throw throwOnDeleteMember!;
    lastDeletedMemberConvId = conversationId;
    lastDeletedMemberUserId = userId;
  }

  @override
  Future<void> updateConversationMember({
    required String conversationId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (throwOnUpdateMember != null) throw throwOnUpdateMember!;
    lastUpdatedMemberConvId = conversationId;
    lastUpdatedMemberUserId = userId;
    lastUpdatedMemberData = data;
  }

  @override
  Future<List<Map<String, dynamic>>> findConversationMembers(
    String conversationId, {
    bool ordered = false,
  }) async {
    if (throwOnFindMembers != null) throw throwOnFindMembers!;
    lastFindMembersConvId = conversationId;
    lastFindMembersOrdered = ordered;
    return findMembersResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> findConversationMessages({
    required String conversationId,
    required int limit,
    required int offset,
  }) async {
    if (throwOnFindConvMessages != null) throw throwOnFindConvMessages!;
    lastFindConvMessagesConvId = conversationId;
    lastFindConvMessagesLimit = limit;
    lastFindConvMessagesOffset = offset;
    return findConvMessagesResponse;
  }

  @override
  Future<Map<String, dynamic>> insertMessage(Map<String, dynamic> data) async {
    if (throwOnInsertMessage != null) throw throwOnInsertMessage!;
    lastInsertedMessage = data;
    return insertMessageResponse ?? const {};
  }

  @override
  Future<void> softDeleteMessageBySender({
    required String messageId,
    required String senderId,
  }) async {
    if (throwOnSoftDeleteBySender != null) throw throwOnSoftDeleteBySender!;
    lastSoftDeleteMsgId = messageId;
    lastSoftDeleteSenderId = senderId;
    softDeleteCallLog.add(messageId);
  }
}

void main() {
  late _FakeConversationQueries queries;
  late ConversationRemoteDataSource ds;
  final fixedClock = DateTime.utc(2024, 6, 1, 12, 0, 0);

  Map<String, dynamic> convRow({
    String id = 'conv-1',
    String tripId = 't-1',
    String name = 'Group',
    String createdBy = 'u-1',
  }) {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'created_by': createdBy,
      'is_direct_message': false,
      'is_default_group': false,
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
    };
  }

  Map<String, dynamic> memberRow({
    String id = 'mem-1',
    String userId = 'u-1',
    String role = 'member',
    String? fullName,
  }) {
    return {
      'id': id,
      'conversation_id': 'conv-1',
      'user_id': userId,
      'role': role,
      'joined_at': fixedClock.toIso8601String(),
      'is_muted': false,
      'profiles': fullName == null
          ? null
          : {
              'id': userId,
              'full_name': fullName,
              'avatar_url': 'http://a',
              'email': '$userId@x.com',
            },
    };
  }

  Map<String, dynamic> messageRow({
    String id = 'msg-1',
    String? senderName,
  }) {
    return {
      'id': id,
      'trip_id': 't-1',
      'sender_id': 'u-1',
      'message': 'hi',
      'message_type': 'text',
      'is_deleted': false,
      'reactions': const <Map<String, dynamic>>[],
      'read_by': const <String>[],
      'created_at': fixedClock.toIso8601String(),
      'updated_at': fixedClock.toIso8601String(),
      if (senderName != null)
        'sender': {
          'id': 'u-1',
          'full_name': senderName,
          'avatar_url': 'http://a',
        },
    };
  }

  setUp(() {
    queries = _FakeConversationQueries();
    ds = ConversationRemoteDataSource(
      queries: queries,
      clock: () => fixedClock,
    );
  });

  group('createConversation', () {
    test('inserts conversation, then admin member, then other members, then fetches details',
        () async {
      queries.insertConversationResponse = {'id': 'conv-1'};
      queries.rpcGetConvDetailsResponse = [convRow()];
      queries.findMembersResponse = [memberRow(fullName: 'A')];

      final result = await ds.createConversation(
        tripId: 't-1',
        name: 'Group',
        memberUserIds: ['u-creator', 'u-1', 'u-2'],
        createdBy: 'u-creator',
      );

      expect(queries.lastInsertedConversation, {
        'trip_id': 't-1',
        'name': 'Group',
        'description': null,
        'created_by': 'u-creator',
        'is_direct_message': false,
      });

      // First batch: creator alone (admin)
      expect(queries.insertedMemberBatches.first, [
        {
          'conversation_id': 'conv-1',
          'user_id': 'u-creator',
          'role': 'admin',
        }
      ]);
      // Second batch: the other members (filtered to exclude creator)
      expect(queries.insertedMemberBatches[1], [
        {
          'conversation_id': 'conv-1',
          'user_id': 'u-1',
          'role': 'member',
        },
        {
          'conversation_id': 'conv-1',
          'user_id': 'u-2',
          'role': 'member',
        },
      ]);

      // getConversation invoked
      expect(queries.lastRpcGetConvDetailsConvId, 'conv-1');
      expect(queries.lastRpcGetConvDetailsUserId, 'u-creator');
      expect(result.id, 'conv-1');
    });

    test('does not insert second batch when only creator is provided', () async {
      queries.insertConversationResponse = {'id': 'conv-1'};
      queries.rpcGetConvDetailsResponse = [convRow()];

      await ds.createConversation(
        tripId: 't-1',
        name: 'Group',
        memberUserIds: ['u-creator'],
        createdBy: 'u-creator',
      );

      expect(queries.insertedMemberBatches, hasLength(1));
    });

    test('rethrows insertion errors', () async {
      queries.throwOnInsertConv = Exception('boom');
      await expectLater(
        ds.createConversation(
          tripId: 't',
          name: 'g',
          memberUserIds: const [],
          createdBy: 'u',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getTripConversations', () {
    test('forwards args and parses RPC rows', () async {
      queries.rpcGetTripConvsResponse = [convRow()];
      final result = await ds.getTripConversations('t-1', 'u-1');
      expect(queries.lastRpcGetTripConvsTripId, 't-1');
      expect(queries.lastRpcGetTripConvsUserId, 'u-1');
      expect(result.single.id, 'conv-1');
    });

    test('rethrows errors', () async {
      queries.throwOnRpcGetTripConvs = Exception('boom');
      await expectLater(
        ds.getTripConversations('t', 'u'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getConversation', () {
    test('throws when conversationId or userId is empty', () async {
      await expectLater(
        ds.getConversation('', 'u'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Invalid'))),
      );
      await expectLater(
        ds.getConversation('c', ''),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('Invalid'))),
      );
    });

    test('throws when RPC returns empty list', () async {
      queries.rpcGetConvDetailsResponse = const [];
      await expectLater(
        ds.getConversation('c', 'u'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns parsed conversation with merged members', () async {
      queries.rpcGetConvDetailsResponse = [convRow()];
      queries.findMembersResponse = [
        memberRow(fullName: 'Alice', userId: 'u-1'),
      ];
      final result = await ds.getConversation('conv-1', 'u-1');
      expect(result.id, 'conv-1');
      expect(result.members, hasLength(1));
      expect(result.members.first.userName, 'Alice');
      expect(result.members.first.userAvatarUrl, 'http://a');
      expect(queries.lastFindMembersConvId, 'conv-1');
      expect(queries.lastFindMembersOrdered, isFalse);
    });
  });

  group('updateConversation', () {
    test('issues update only with non-null fields', () async {
      await ds.updateConversation(
        conversationId: 'c-1',
        name: 'new',
        avatarUrl: 'avatar',
      );
      expect(queries.lastUpdatedConvId, 'c-1');
      expect(queries.lastUpdatedConvData, {
        'name': 'new',
        'avatar_url': 'avatar',
      });
    });

    test('skips call when no fields are provided', () async {
      await ds.updateConversation(conversationId: 'c-1');
      expect(queries.lastUpdatedConvId, isNull);
    });

    test('rethrows errors', () async {
      queries.throwOnUpdateConv = Exception('boom');
      await expectLater(
        ds.updateConversation(conversationId: 'c', name: 'x'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteConversation', () {
    test('forwards id', () async {
      await ds.deleteConversation('c-1');
      expect(queries.lastDeletedConvId, 'c-1');
    });

    test('rethrows errors', () async {
      queries.throwOnDeleteConv = Exception('boom');
      await expectLater(
        ds.deleteConversation('c'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('member operations', () {
    test('addMembers builds rows with role=member', () async {
      await ds.addMembers(conversationId: 'c-1', userIds: ['u-1', 'u-2']);
      expect(queries.insertedMemberBatches.single, [
        {'conversation_id': 'c-1', 'user_id': 'u-1', 'role': 'member'},
        {'conversation_id': 'c-1', 'user_id': 'u-2', 'role': 'member'},
      ]);
    });

    test('addMembers rethrows errors', () async {
      queries.throwOnInsertMembers = Exception('boom');
      await expectLater(
        ds.addMembers(conversationId: 'c', userIds: ['u']),
        throwsA(isA<Exception>()),
      );
    });

    test('removeMember forwards composite key', () async {
      await ds.removeMember(conversationId: 'c-1', userId: 'u-1');
      expect(queries.lastDeletedMemberConvId, 'c-1');
      expect(queries.lastDeletedMemberUserId, 'u-1');
    });

    test('removeMember rethrows errors', () async {
      queries.throwOnDeleteMember = Exception('boom');
      await expectLater(
        ds.removeMember(conversationId: 'c', userId: 'u'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateMemberRole sends role payload', () async {
      await ds.updateMemberRole(
          conversationId: 'c-1', userId: 'u-1', role: 'admin');
      expect(queries.lastUpdatedMemberConvId, 'c-1');
      expect(queries.lastUpdatedMemberUserId, 'u-1');
      expect(queries.lastUpdatedMemberData, {'role': 'admin'});
    });

    test('updateMemberRole rethrows errors', () async {
      queries.throwOnUpdateMember = Exception('boom');
      await expectLater(
        ds.updateMemberRole(conversationId: 'c', userId: 'u', role: 'admin'),
        throwsA(isA<Exception>()),
      );
    });

    test('setMuted sends is_muted payload', () async {
      await ds.setMuted(conversationId: 'c-1', userId: 'u-1', muted: true);
      expect(queries.lastUpdatedMemberData, {'is_muted': true});
    });

    test('setMuted rethrows errors', () async {
      queries.throwOnUpdateMember = Exception('boom');
      await expectLater(
        ds.setMuted(conversationId: 'c', userId: 'u', muted: false),
        throwsA(isA<Exception>()),
      );
    });

    test('getConversationMembers passes ordered=true and parses profiles',
        () async {
      queries.findMembersResponse = [memberRow(fullName: 'Alice')];
      final result = await ds.getConversationMembers('c-1');
      expect(queries.lastFindMembersOrdered, isTrue);
      expect(result.single.userName, 'Alice');
    });

    test('getConversationMembers rethrows errors', () async {
      queries.throwOnFindMembers = Exception('boom');
      await expectLater(
        ds.getConversationMembers('c'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('markAsRead', () {
    test('uses RPC happy path', () async {
      await ds.markAsRead(conversationId: 'c-1', userId: 'u-1');
      expect(queries.lastRpcMarkReadConvId, 'c-1');
      expect(queries.lastRpcMarkReadUserId, 'u-1');
      expect(queries.lastUpdatedMemberConvId, isNull);
    });

    test('falls back to client-side update when RPC throws', () async {
      queries.throwOnRpcMarkRead = Exception('no rpc');
      await ds.markAsRead(conversationId: 'c-1', userId: 'u-1');
      expect(queries.lastUpdatedMemberConvId, 'c-1');
      expect(queries.lastUpdatedMemberUserId, 'u-1');
      expect(
        queries.lastUpdatedMemberData!['last_read_at'],
        fixedClock.toUtc().toIso8601String(),
      );
    });

    test('rethrows when fallback also fails', () async {
      queries.throwOnRpcMarkRead = Exception('rpc fail');
      queries.throwOnUpdateMember = Exception('update fail');
      await expectLater(
        ds.markAsRead(conversationId: 'c', userId: 'u'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getConversationMessages', () {
    test('forwards args and parses joined sender', () async {
      queries.findConvMessagesResponse = [messageRow(senderName: 'Alice')];
      final result =
          await ds.getConversationMessages(conversationId: 'c-1');
      expect(queries.lastFindConvMessagesConvId, 'c-1');
      expect(queries.lastFindConvMessagesLimit, 50);
      expect(queries.lastFindConvMessagesOffset, 0);
      expect(result.single.senderName, 'Alice');
      expect(result.single.senderAvatarUrl, 'http://a');
    });

    test('passes through custom limit/offset', () async {
      queries.findConvMessagesResponse = [];
      await ds.getConversationMessages(
          conversationId: 'c', limit: 10, offset: 30);
      expect(queries.lastFindConvMessagesLimit, 10);
      expect(queries.lastFindConvMessagesOffset, 30);
    });

    test('rethrows errors', () async {
      queries.throwOnFindConvMessages = Exception('boom');
      await expectLater(
        ds.getConversationMessages(conversationId: 'c'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteMessage / deleteMessages', () {
    test('deleteMessage forwards composite key', () async {
      await ds.deleteMessage(messageId: 'm-1', senderId: 'u-1');
      expect(queries.lastSoftDeleteMsgId, 'm-1');
      expect(queries.lastSoftDeleteSenderId, 'u-1');
    });

    test('deleteMessage rethrows errors', () async {
      queries.throwOnSoftDeleteBySender = Exception('boom');
      await expectLater(
        ds.deleteMessage(messageId: 'm', senderId: 'u'),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteMessages calls per-message in order', () async {
      await ds.deleteMessages(
          messageIds: ['m-1', 'm-2', 'm-3'], senderId: 'u-1');
      expect(queries.softDeleteCallLog, ['m-1', 'm-2', 'm-3']);
    });

    test('deleteMessages aborts on first failure and rethrows', () async {
      queries.throwOnSoftDeleteBySender = Exception('boom');
      await expectLater(
        ds.deleteMessages(messageIds: ['m'], senderId: 'u'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('sendMessage', () {
    test('inserts payload and parses joined sender', () async {
      queries.insertMessageResponse = messageRow(senderName: 'Alice');
      final result = await ds.sendMessage(
        conversationId: 'c-1',
        tripId: 't-1',
        senderId: 'u-1',
        message: 'hi',
        replyToId: 'r-1',
        attachmentUrl: 'http://x',
      );
      expect(queries.lastInsertedMessage, {
        'conversation_id': 'c-1',
        'trip_id': 't-1',
        'sender_id': 'u-1',
        'message': 'hi',
        'message_type': 'text',
        'reply_to_id': 'r-1',
        'attachment_url': 'http://x',
      });
      expect(result.senderName, 'Alice');
    });

    test('uses default messageType when not provided', () async {
      queries.insertMessageResponse = messageRow();
      await ds.sendMessage(
        conversationId: 'c',
        tripId: 't',
        senderId: 'u',
        message: 'hi',
      );
      expect(queries.lastInsertedMessage!['message_type'], 'text');
      expect(queries.lastInsertedMessage!['reply_to_id'], isNull);
      expect(queries.lastInsertedMessage!['attachment_url'], isNull);
    });

    test('rethrows errors', () async {
      queries.throwOnInsertMessage = Exception('boom');
      await expectLater(
        ds.sendMessage(
          conversationId: 'c',
          tripId: 't',
          senderId: 'u',
          message: 'hi',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('findOrCreateDirectMessage', () {
    test('returns existing DM via RPC when RPC succeeds and id is non-empty',
        () async {
      queries.rpcFindDmResponse = 'dm-1';
      queries.rpcGetConvDetailsResponse = [convRow(id: 'dm-1')];
      queries.findMembersResponse = [];
      final result = await ds.findOrCreateDirectMessage(
          tripId: 't-1', currentUserId: 'a', otherUserId: 'b');
      expect(queries.lastRpcFindDmTripId, 't-1');
      expect(queries.lastRpcFindDmUser1, 'a');
      expect(queries.lastRpcFindDmUser2, 'b');
      expect(result.id, 'dm-1');
    });

    test('falls back to manual search when RPC throws and finds match', () async {
      queries.throwOnRpcFindDm = Exception('rpc absent');
      queries.findDmsResponse = [
        {
          'id': 'dm-2',
          'conversation_members': [
            {'user_id': 'a'},
            {'user_id': 'b'},
          ],
        },
      ];
      queries.rpcGetConvDetailsResponse = [convRow(id: 'dm-2')];
      queries.findMembersResponse = [];
      final result = await ds.findOrCreateDirectMessage(
          tripId: 't-1', currentUserId: 'a', otherUserId: 'b');
      expect(result.id, 'dm-2');
      expect(queries.lastFindDmsTripId, 't-1');
    });

    test(
        'creates a new DM when neither RPC nor manual search finds existing match',
        () async {
      queries.setRpcFindDmReturnsNull();
      // Creation path
      queries.insertConversationResponse = {'id': 'new-dm'};
      queries.rpcGetConvDetailsResponse = [
        convRow(id: 'new-dm', name: 'Direct Message')
      ];
      queries.findMembersResponse = [];

      final result = await ds.findOrCreateDirectMessage(
          tripId: 't-1', currentUserId: 'a', otherUserId: 'b');
      expect(result.id, 'new-dm');
      expect(queries.lastInsertedConversation!['name'], 'Direct Message');
      expect(queries.lastInsertedConversation!['is_direct_message'], true);
    });

    test('manual fallback returns null when no DM matches both users', () async {
      queries.throwOnRpcFindDm = Exception('rpc absent');
      queries.findDmsResponse = [
        {
          'id': 'dm-x',
          'conversation_members': [
            {'user_id': 'a'},
            {'user_id': 'someone-else'},
          ],
        },
      ];
      // After manual returns null, creation path engages
      queries.insertConversationResponse = {'id': 'new-dm'};
      queries.rpcGetConvDetailsResponse = [convRow(id: 'new-dm')];
      queries.findMembersResponse = [];

      final result = await ds.findOrCreateDirectMessage(
          tripId: 't-1', currentUserId: 'a', otherUserId: 'b');
      expect(result.id, 'new-dm');
    });
  });

  group('ensureUserInDefaultGroup', () {
    test('returns id from RPC happy path', () async {
      queries.rpcEnsureUserResponse = 'group-1';
      final result = await ds.ensureUserInDefaultGroup(
          tripId: 't-1', userId: 'u-1');
      expect(result, 'group-1');
      expect(queries.lastRpcEnsureUserTripId, 't-1');
      expect(queries.lastRpcEnsureUserUserId, 'u-1');
    });

    test('returns null when RPC returns null/empty', () async {
      queries.setRpcEnsureUserReturnsNull();
      // RPC path returns null -> getDefaultGroupId is called, also returns null
      queries.setFindDefaultGroupReturnsNull();
      queries.setRpcEnsureGroupReturnsNull();
      final result = await ds.ensureUserInDefaultGroup(
          tripId: 't-1', userId: 'u-1');
      expect(result, isNull);
    });

    test('falls back to getDefaultGroupId when RPC throws', () async {
      queries.throwOnRpcEnsureUser = Exception('boom');
      queries.findDefaultGroupResponse = 'fallback-group';
      final result = await ds.ensureUserInDefaultGroup(
          tripId: 't-1', userId: 'u-1');
      expect(result, 'fallback-group');
    });
  });

  group('getDefaultGroupId', () {
    test('returns id from direct query when present', () async {
      queries.findDefaultGroupResponse = 'g-1';
      expect(await ds.getDefaultGroupId(tripId: 't-1'), 'g-1');
      expect(queries.lastFindDefaultGroupTripId, 't-1');
    });

    test('falls back to ensure RPC when direct query returns null', () async {
      queries.setFindDefaultGroupReturnsNull();
      queries.rpcEnsureGroupResponse = 'created-1';
      expect(await ds.getDefaultGroupId(tripId: 't-1'), 'created-1');
      expect(queries.lastRpcEnsureGroupTripId, 't-1');
    });

    test('returns null when both lookups yield null', () async {
      queries.setFindDefaultGroupReturnsNull();
      queries.setRpcEnsureGroupReturnsNull();
      expect(await ds.getDefaultGroupId(tripId: 't-1'), isNull);
    });

    test('returns null when ensure RPC throws (caught internally)', () async {
      queries.setFindDefaultGroupReturnsNull();
      queries.throwOnRpcEnsureGroup = Exception('rpc fail');
      expect(await ds.getDefaultGroupId(tripId: 't-1'), isNull);
    });

    test('rethrows when initial direct query throws', () async {
      queries.throwOnFindDefaultGroup = Exception('boom');
      await expectLater(
        ds.getDefaultGroupId(tripId: 't'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getDefaultGroup', () {
    test('returns model when default group id is found', () async {
      queries.findDefaultGroupResponse = 'g-1';
      queries.rpcGetConvDetailsResponse = [convRow(id: 'g-1')];
      queries.findMembersResponse = [];
      final result =
          await ds.getDefaultGroup(tripId: 't-1', userId: 'u-1');
      expect(result.id, 'g-1');
    });

    test('throws when no default group found', () async {
      queries.setFindDefaultGroupReturnsNull();
      queries.setRpcEnsureGroupReturnsNull();
      await expectLater(
        ds.getDefaultGroup(tripId: 't', userId: 'u'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('No default group found'))),
      );
    });
  });
}
