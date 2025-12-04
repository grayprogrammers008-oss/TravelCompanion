import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/conversation_entity.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/create_conversation_usecase.dart';
import 'package:travel_crew/features/messaging/domain/usecases/get_trip_conversations_usecase.dart';
import 'package:travel_crew/features/messaging/domain/usecases/send_message_usecase.dart';

/// Manual mock for ConversationRepository
class MockConversationRepository implements ConversationRepository {
  Result<ConversationEntity>? createConversationResult;
  Result<List<ConversationEntity>>? getTripConversationsResult;
  Result<ConversationEntity>? getConversationResult;
  Result<void>? updateConversationResult;
  Result<void>? deleteConversationResult;
  Result<void>? addMembersResult;
  Result<void>? removeMemberResult;
  Result<void>? updateMemberRoleResult;
  Result<void>? leaveConversationResult;
  Result<void>? setMutedResult;
  Result<void>? markAsReadResult;
  Result<List<MessageEntity>>? getMessagesResult;
  Result<MessageEntity>? sendMessageResult;
  Result<List<ConversationMemberEntity>>? getMembersResult;
  Result<ConversationEntity>? findOrCreateDMResult;

  // Track calls
  int createConversationCallCount = 0;
  int leaveConversationCallCount = 0;
  int addMembersCallCount = 0;
  int markAsReadCallCount = 0;

  @override
  Future<Result<ConversationEntity>> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  }) async {
    createConversationCallCount++;
    return createConversationResult ?? Result.failure('Not configured');
  }

  @override
  Future<Result<List<ConversationEntity>>> getTripConversations({
    required String tripId,
    required String userId,
  }) async {
    return getTripConversationsResult ?? Result.success([]);
  }

  @override
  Future<Result<ConversationEntity>> getConversation({
    required String conversationId,
    required String userId,
  }) async {
    return getConversationResult ?? Result.failure('Not found');
  }

  @override
  Future<Result<void>> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    return updateConversationResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> deleteConversation(String conversationId) async {
    return deleteConversationResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> userIds,
  }) async {
    addMembersCallCount++;
    return addMembersResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    return removeMemberResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    return updateMemberRoleResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> leaveConversation({
    required String conversationId,
    required String userId,
  }) async {
    leaveConversationCallCount++;
    return leaveConversationResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> setMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    return setMutedResult ?? Result.success(null);
  }

  @override
  Future<Result<void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    markAsReadCallCount++;
    return markAsReadResult ?? Result.success(null);
  }

  @override
  Future<Result<List<MessageEntity>>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    return getMessagesResult ?? Result.success([]);
  }

  @override
  Future<Result<MessageEntity>> sendConversationMessage({
    required String conversationId,
    required String tripId,
    required String senderId,
    required String message,
    MessageType messageType = MessageType.text,
    String? replyToId,
    String? attachmentUrl,
  }) async {
    return sendMessageResult ?? Result.failure('Not configured');
  }

  @override
  Stream<List<ConversationEntity>> watchTripConversations({
    required String tripId,
    required String userId,
  }) {
    return Stream.value([]);
  }

  @override
  Stream<List<MessageEntity>> watchConversationMessages(String conversationId) {
    return Stream.value([]);
  }

  @override
  Stream<ConversationEntity> watchConversation({
    required String conversationId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<ConversationMemberEntity>>> getConversationMembers(
    String conversationId,
  ) async {
    return getMembersResult ?? Result.success([]);
  }

  @override
  Future<Result<ConversationEntity>> findOrCreateDirectMessage({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    return findOrCreateDMResult ?? Result.failure('Not configured');
  }
}

void main() {
  late MockConversationRepository mockRepository;

  setUp(() {
    mockRepository = MockConversationRepository();
  });

  final now = DateTime.now();

  final testMember1 = ConversationMemberEntity(
    id: 'member-1',
    conversationId: 'conv-1',
    userId: 'user-1',
    role: 'admin',
    joinedAt: now,
    userName: 'John Doe',
  );

  final testMember2 = ConversationMemberEntity(
    id: 'member-2',
    conversationId: 'conv-1',
    userId: 'user-2',
    role: 'member',
    joinedAt: now,
    userName: 'Jane Smith',
  );

  final testConversation = ConversationEntity(
    id: 'conv-1',
    tripId: 'trip-1',
    name: 'Trip Planning',
    createdBy: 'user-1',
    createdAt: now,
    updatedAt: now,
    members: [testMember1, testMember2],
    memberCount: 2,
  );

  final testDM = ConversationEntity(
    id: 'dm-1',
    tripId: 'trip-1',
    name: 'Direct Message',
    createdBy: 'user-1',
    isDirectMessage: true,
    createdAt: now,
    updatedAt: now,
    members: [testMember1, testMember2],
    memberCount: 2,
  );

  group('CreateConversationUseCase', () {
    late CreateConversationUseCase useCase;

    setUp(() {
      useCase = CreateConversationUseCase(mockRepository);
    });

    test('creates a group conversation successfully', () async {
      mockRepository.createConversationResult = Result.success(testConversation);

      final result = await useCase.execute(
        tripId: 'trip-1',
        name: 'Trip Planning',
        description: 'Plan our trip',
        memberUserIds: ['user-1', 'user-2', 'user-3'],
        createdBy: 'user-1',
        isDirectMessage: false,
      );

      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (conversation) {
          expect(conversation.id, 'conv-1');
          expect(conversation.name, 'Trip Planning');
          expect(conversation.isDirectMessage, false);
        },
        onFailure: (_) => fail('Should not fail'),
      );
      expect(mockRepository.createConversationCallCount, 1);
    });

    test('creates a direct message successfully', () async {
      mockRepository.createConversationResult = Result.success(testDM);

      final result = await useCase.execute(
        tripId: 'trip-1',
        name: 'Direct Message',
        memberUserIds: ['user-1', 'user-2'],
        createdBy: 'user-1',
        isDirectMessage: true,
      );

      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (conversation) {
          expect(conversation.isDirectMessage, true);
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('returns error when creation fails', () async {
      mockRepository.createConversationResult = Result.failure('At least 2 members required');

      final result = await useCase.execute(
        tripId: 'trip-1',
        name: 'Test',
        memberUserIds: ['user-1'],
        createdBy: 'user-1',
      );

      expect(result.isSuccess, false);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error, contains('2 members'));
        },
      );
    });
  });

  group('GetTripConversationsUseCase', () {
    late GetTripConversationsUseCase useCase;

    setUp(() {
      useCase = GetTripConversationsUseCase(mockRepository);
    });

    test('gets all conversations for a trip', () async {
      mockRepository.getTripConversationsResult = Result.success([testConversation, testDM]);

      final result = await useCase.execute(
        tripId: 'trip-1',
        userId: 'user-1',
      );

      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (conversations) {
          expect(conversations.length, 2);
          expect(conversations[0].id, 'conv-1');
          expect(conversations[1].id, 'dm-1');
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('returns empty list when no conversations', () async {
      mockRepository.getTripConversationsResult = Result.success([]);

      final result = await useCase.execute(
        tripId: 'trip-1',
        userId: 'user-1',
      );

      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (conversations) {
          expect(conversations, isEmpty);
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('returns error when fetching fails', () async {
      mockRepository.getTripConversationsResult = Result.failure('Network error');

      final result = await useCase.execute(
        tripId: 'trip-1',
        userId: 'user-1',
      );

      expect(result.isSuccess, false);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error, 'Network error');
        },
      );
    });
  });

  group('LeaveConversationUseCase', () {
    late LeaveConversationUseCase useCase;

    setUp(() {
      useCase = LeaveConversationUseCase(mockRepository);
    });

    test('leaves a conversation successfully', () async {
      mockRepository.leaveConversationResult = Result.success(null);

      final result = await useCase.execute(
        conversationId: 'conv-1',
        userId: 'user-2',
      );

      expect(result.isSuccess, true);
      expect(mockRepository.leaveConversationCallCount, 1);
    });

    test('returns error when leaving fails', () async {
      mockRepository.leaveConversationResult = Result.failure('Cannot leave: you are the only admin');

      final result = await useCase.execute(
        conversationId: 'conv-1',
        userId: 'user-1',
      );

      expect(result.isSuccess, false);
      result.fold(
        onSuccess: (_) => fail('Should fail'),
        onFailure: (error) {
          expect(error, contains('admin'));
        },
      );
    });
  });

  group('AddConversationMembersUseCase', () {
    late AddConversationMembersUseCase useCase;

    setUp(() {
      useCase = AddConversationMembersUseCase(mockRepository);
    });

    test('adds members successfully', () async {
      mockRepository.addMembersResult = Result.success(null);

      final result = await useCase.execute(
        conversationId: 'conv-1',
        userIds: ['user-3', 'user-4'],
      );

      expect(result.isSuccess, true);
      expect(mockRepository.addMembersCallCount, 1);
    });

    test('returns error when not authorized', () async {
      mockRepository.addMembersResult = Result.failure('Only admins can add members');

      final result = await useCase.execute(
        conversationId: 'conv-1',
        userIds: ['user-3'],
      );

      expect(result.isSuccess, false);
    });
  });

  group('MarkConversationAsReadUseCase', () {
    late MarkConversationAsReadUseCase useCase;

    setUp(() {
      useCase = MarkConversationAsReadUseCase(mockRepository);
    });

    test('marks conversation as read successfully', () async {
      mockRepository.markAsReadResult = Result.success(null);

      final result = await useCase.execute(
        conversationId: 'conv-1',
        userId: 'user-1',
      );

      expect(result.isSuccess, true);
      expect(mockRepository.markAsReadCallCount, 1);
    });
  });

  group('FindOrCreateDirectMessage', () {
    test('finds existing DM successfully', () async {
      mockRepository.findOrCreateDMResult = Result.success(testDM);

      final result = await mockRepository.findOrCreateDirectMessage(
        tripId: 'trip-1',
        currentUserId: 'user-1',
        otherUserId: 'user-2',
      );

      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (dm) {
          expect(dm.isDirectMessage, true);
          expect(dm.id, 'dm-1');
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });

    test('creates new DM when none exists', () async {
      final newDM = ConversationEntity(
        id: 'new-dm-1',
        tripId: 'trip-1',
        name: 'Direct Message',
        createdBy: 'user-1',
        isDirectMessage: true,
        createdAt: now,
        updatedAt: now,
      );

      mockRepository.findOrCreateDMResult = Result.success(newDM);

      final result = await mockRepository.findOrCreateDirectMessage(
        tripId: 'trip-1',
        currentUserId: 'user-1',
        otherUserId: 'user-3',
      );

      expect(result.isSuccess, true);
      result.fold(
        onSuccess: (dm) {
          expect(dm.id, 'new-dm-1');
        },
        onFailure: (_) => fail('Should not fail'),
      );
    });
  });
}
