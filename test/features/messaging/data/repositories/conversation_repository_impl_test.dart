import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/conversation_model.dart';
import 'package:travel_crew/shared/models/message_model.dart';
import 'package:travel_crew/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:travel_crew/features/messaging/data/repositories/conversation_repository_impl.dart';

/// Manual mock for ConversationRemoteDataSource
class MockConversationRemoteDataSource implements ConversationRemoteDataSource {
  // Result holders
  ConversationModel? createConversationResult;
  List<ConversationModel>? getTripConversationsResult;
  ConversationModel? getConversationResult;
  List<ConversationMemberModel>? getConversationMembersResult;
  List<MessageModel>? getConversationMessagesResult;
  MessageModel? sendMessageResult;
  ConversationModel? findOrCreateDMResult;

  // Error flags
  bool shouldThrow = false;
  String errorMessage = 'Mock error';

  // Call tracking
  int createConversationCallCount = 0;
  int getTripConversationsCallCount = 0;
  int addMembersCallCount = 0;
  int removeMemberCallCount = 0;
  int updateMemberRoleCallCount = 0;
  int setMutedCallCount = 0;
  int markAsReadCallCount = 0;
  int deleteConversationCallCount = 0;
  int updateConversationCallCount = 0;

  // Captured parameters
  String? capturedConversationId;
  String? capturedUserId;
  List<String>? capturedUserIds;
  String? capturedRole;
  bool? capturedMuted;

  @override
  Future<ConversationModel> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  }) async {
    createConversationCallCount++;
    if (shouldThrow) throw Exception(errorMessage);
    return createConversationResult!;
  }

  @override
  Future<List<ConversationModel>> getTripConversations(
    String tripId,
    String userId,
  ) async {
    getTripConversationsCallCount++;
    if (shouldThrow) throw Exception(errorMessage);
    return getTripConversationsResult ?? [];
  }

  @override
  Future<ConversationModel> getConversation(
    String conversationId,
    String userId,
  ) async {
    if (shouldThrow) throw Exception(errorMessage);
    return getConversationResult!;
  }

  @override
  Future<void> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    updateConversationCallCount++;
    capturedConversationId = conversationId;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    deleteConversationCallCount++;
    capturedConversationId = conversationId;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> addMembers({
    required String conversationId,
    required List<String> userIds,
  }) async {
    addMembersCallCount++;
    capturedConversationId = conversationId;
    capturedUserIds = userIds;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    removeMemberCallCount++;
    capturedConversationId = conversationId;
    capturedUserId = userId;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    updateMemberRoleCallCount++;
    capturedConversationId = conversationId;
    capturedUserId = userId;
    capturedRole = role;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> setMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    setMutedCallCount++;
    capturedConversationId = conversationId;
    capturedUserId = userId;
    capturedMuted = muted;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    markAsReadCallCount++;
    capturedConversationId = conversationId;
    capturedUserId = userId;
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<List<ConversationMemberModel>> getConversationMembers(
    String conversationId,
  ) async {
    if (shouldThrow) throw Exception(errorMessage);
    return getConversationMembersResult ?? [];
  }

  @override
  Future<List<MessageModel>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return getConversationMessagesResult ?? [];
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String tripId,
    required String senderId,
    required String message,
    String messageType = 'text',
    String? replyToId,
    String? attachmentUrl,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return sendMessageResult!;
  }

  @override
  Future<ConversationModel> findOrCreateDirectMessage({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return findOrCreateDMResult!;
  }

  @override
  Stream<List<MessageModel>> subscribeToConversationMessages(
    String conversationId,
  ) {
    return Stream.value(getConversationMessagesResult ?? []);
  }

  @override
  Stream<ConversationModel> subscribeToConversation(
    String conversationId,
    String userId,
  ) {
    return Stream.value(getConversationResult!);
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
    required String senderId,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> deleteMessages({
    required List<String> messageIds,
    required String senderId,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<String?> ensureUserInDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return null;
  }

  @override
  Future<ConversationModel> getDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return getConversationResult!;
  }

  @override
  Future<String?> getDefaultGroupId({
    required String tripId,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return null;
  }

  @override
  Stream<void> subscribeToConversationMemberChanges(String tripId) {
    return const Stream.empty();
  }

  @override
  Stream<void> subscribeToTripActivityChanges(String tripId) {
    return const Stream.empty();
  }

  @override
  Stream<void> subscribeToTripMessages(String tripId) {
    return const Stream.empty();
  }
}

void main() {
  late MockConversationRemoteDataSource mockDataSource;
  late ConversationRepositoryImpl repository;

  final now = DateTime.now();

  final testMemberModel = ConversationMemberModel(
    id: 'member-1',
    conversationId: 'conv-1',
    userId: 'user-1',
    role: 'admin',
    joinedAt: now,
    userName: 'John Doe',
  );

  final testConversationModel = ConversationModel(
    id: 'conv-1',
    tripId: 'trip-1',
    name: 'Trip Planning',
    createdBy: 'user-1',
    createdAt: now,
    updatedAt: now,
    memberCount: 2,
    members: [testMemberModel],
  );

  final testMessageModel = MessageModel(
    id: 'msg-1',
    tripId: 'trip-1',
    senderId: 'user-1',
    message: 'Hello everyone!',
    messageType: 'text',
    createdAt: now,
    updatedAt: now,
    senderName: 'John Doe',
  );

  setUp(() {
    mockDataSource = MockConversationRemoteDataSource();
    repository = ConversationRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('ConversationRepositoryImpl', () {
    group('createConversation', () {
      test('creates conversation successfully', () async {
        mockDataSource.createConversationResult = testConversationModel;

        final result = await repository.createConversation(
          tripId: 'trip-1',
          name: 'Trip Planning',
          memberUserIds: ['user-1', 'user-2'],
          createdBy: 'user-1',
        );

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (entity) {
            expect(entity.id, 'conv-1');
            expect(entity.name, 'Trip Planning');
          },
          onFailure: (_) => fail('Should not fail'),
        );
        expect(mockDataSource.createConversationCallCount, 1);
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;
        mockDataSource.errorMessage = 'Network error';

        final result = await repository.createConversation(
          tripId: 'trip-1',
          name: 'Trip Planning',
          memberUserIds: ['user-1', 'user-2'],
          createdBy: 'user-1',
        );

        expect(result.isSuccess, false);
        result.fold(
          onSuccess: (_) => fail('Should fail'),
          onFailure: (error) {
            expect(error, contains('Network error'));
          },
        );
      });
    });

    group('getTripConversations', () {
      test('gets conversations successfully', () async {
        mockDataSource.getTripConversationsResult = [testConversationModel];

        final result = await repository.getTripConversations(
          tripId: 'trip-1',
          userId: 'user-1',
        );

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (conversations) {
            expect(conversations.length, 1);
            expect(conversations[0].id, 'conv-1');
          },
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.getTripConversations(
          tripId: 'trip-1',
          userId: 'user-1',
        );

        expect(result.isSuccess, false);
      });
    });

    group('getConversation', () {
      test('gets single conversation successfully', () async {
        mockDataSource.getConversationResult = testConversationModel;

        final result = await repository.getConversation(
          conversationId: 'conv-1',
          userId: 'user-1',
        );

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (entity) {
            expect(entity.id, 'conv-1');
            expect(entity.name, 'Trip Planning');
          },
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.getConversation(
          conversationId: 'conv-1',
          userId: 'user-1',
        );

        expect(result.isSuccess, false);
      });
    });

    group('updateConversation', () {
      test('updates conversation successfully', () async {
        final result = await repository.updateConversation(
          conversationId: 'conv-1',
          name: 'Updated Name',
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.updateConversationCallCount, 1);
        expect(mockDataSource.capturedConversationId, 'conv-1');
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.updateConversation(
          conversationId: 'conv-1',
          name: 'Updated Name',
        );

        expect(result.isSuccess, false);
      });
    });

    group('deleteConversation', () {
      test('deletes conversation successfully', () async {
        final result = await repository.deleteConversation('conv-1');

        expect(result.isSuccess, true);
        expect(mockDataSource.deleteConversationCallCount, 1);
        expect(mockDataSource.capturedConversationId, 'conv-1');
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.deleteConversation('conv-1');

        expect(result.isSuccess, false);
      });
    });

    group('addMembers', () {
      test('adds members successfully', () async {
        final result = await repository.addMembers(
          conversationId: 'conv-1',
          userIds: ['user-3', 'user-4'],
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.addMembersCallCount, 1);
        expect(mockDataSource.capturedUserIds, ['user-3', 'user-4']);
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.addMembers(
          conversationId: 'conv-1',
          userIds: ['user-3'],
        );

        expect(result.isSuccess, false);
      });
    });

    group('removeMember', () {
      test('removes member successfully', () async {
        final result = await repository.removeMember(
          conversationId: 'conv-1',
          userId: 'user-2',
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.removeMemberCallCount, 1);
        expect(mockDataSource.capturedUserId, 'user-2');
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.removeMember(
          conversationId: 'conv-1',
          userId: 'user-2',
        );

        expect(result.isSuccess, false);
      });
    });

    group('updateMemberRole', () {
      test('updates member role successfully', () async {
        final result = await repository.updateMemberRole(
          conversationId: 'conv-1',
          userId: 'user-2',
          role: 'admin',
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.updateMemberRoleCallCount, 1);
        expect(mockDataSource.capturedRole, 'admin');
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.updateMemberRole(
          conversationId: 'conv-1',
          userId: 'user-2',
          role: 'admin',
        );

        expect(result.isSuccess, false);
      });
    });

    group('leaveConversation', () {
      test('leaves conversation successfully', () async {
        final result = await repository.leaveConversation(
          conversationId: 'conv-1',
          userId: 'user-2',
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.removeMemberCallCount, 1);
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.leaveConversation(
          conversationId: 'conv-1',
          userId: 'user-2',
        );

        expect(result.isSuccess, false);
      });
    });

    group('setMuted', () {
      test('sets muted status successfully', () async {
        final result = await repository.setMuted(
          conversationId: 'conv-1',
          userId: 'user-1',
          muted: true,
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.setMutedCallCount, 1);
        expect(mockDataSource.capturedMuted, true);
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.setMuted(
          conversationId: 'conv-1',
          userId: 'user-1',
          muted: true,
        );

        expect(result.isSuccess, false);
      });
    });

    group('markConversationAsRead', () {
      test('marks conversation as read successfully', () async {
        final result = await repository.markConversationAsRead(
          conversationId: 'conv-1',
          userId: 'user-1',
        );

        expect(result.isSuccess, true);
        expect(mockDataSource.markAsReadCallCount, 1);
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.markConversationAsRead(
          conversationId: 'conv-1',
          userId: 'user-1',
        );

        expect(result.isSuccess, false);
      });
    });

    group('getConversationMessages', () {
      test('gets messages successfully', () async {
        mockDataSource.getConversationMessagesResult = [testMessageModel];

        final result = await repository.getConversationMessages(
          conversationId: 'conv-1',
        );

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (messages) {
            expect(messages.length, 1);
            expect(messages[0].message, 'Hello everyone!');
          },
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.getConversationMessages(
          conversationId: 'conv-1',
        );

        expect(result.isSuccess, false);
      });
    });

    group('sendConversationMessage', () {
      test('sends message successfully', () async {
        mockDataSource.sendMessageResult = testMessageModel;

        final result = await repository.sendConversationMessage(
          conversationId: 'conv-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello everyone!',
        );

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (message) {
            expect(message.message, 'Hello everyone!');
            expect(message.senderId, 'user-1');
          },
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.sendConversationMessage(
          conversationId: 'conv-1',
          tripId: 'trip-1',
          senderId: 'user-1',
          message: 'Hello!',
        );

        expect(result.isSuccess, false);
      });
    });

    group('getConversationMembers', () {
      test('gets members successfully', () async {
        mockDataSource.getConversationMembersResult = [testMemberModel];

        final result = await repository.getConversationMembers('conv-1');

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (members) {
            expect(members.length, 1);
            expect(members[0].userName, 'John Doe');
            expect(members[0].role, 'admin');
          },
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.getConversationMembers('conv-1');

        expect(result.isSuccess, false);
      });
    });

    group('findOrCreateDirectMessage', () {
      test('finds/creates DM successfully', () async {
        final dmModel = testConversationModel.copyWith(
          isDirectMessage: true,
          name: 'Direct Message',
        );
        mockDataSource.findOrCreateDMResult = dmModel;

        final result = await repository.findOrCreateDirectMessage(
          tripId: 'trip-1',
          currentUserId: 'user-1',
          otherUserId: 'user-2',
        );

        expect(result.isSuccess, true);
        result.fold(
          onSuccess: (dm) {
            expect(dm.isDirectMessage, true);
          },
          onFailure: (_) => fail('Should not fail'),
        );
      });

      test('returns error when datasource throws', () async {
        mockDataSource.shouldThrow = true;

        final result = await repository.findOrCreateDirectMessage(
          tripId: 'trip-1',
          currentUserId: 'user-1',
          otherUserId: 'user-2',
        );

        expect(result.isSuccess, false);
      });
    });

    group('watchConversationMessages', () {
      test('returns stream of messages', () async {
        mockDataSource.getConversationMessagesResult = [testMessageModel];

        final stream = repository.watchConversationMessages('conv-1');

        final messages = await stream.first;
        expect(messages.length, 1);
        expect(messages[0].message, 'Hello everyone!');
      });
    });

    group('watchConversation', () {
      test('returns stream of conversation updates', () async {
        mockDataSource.getConversationResult = testConversationModel;

        final stream = repository.watchConversation(
          conversationId: 'conv-1',
          userId: 'user-1',
        );

        final conversation = await stream.first;
        expect(conversation.id, 'conv-1');
        expect(conversation.name, 'Trip Planning');
      });
    });
  });
}
