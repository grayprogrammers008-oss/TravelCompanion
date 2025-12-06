import 'package:flutter/foundation.dart';
import '../../../../shared/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../datasources/conversation_remote_datasource.dart';

/// Implementation of ConversationRepository
class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource _remoteDataSource;

  ConversationRepositoryImpl({
    required ConversationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  // ============================================================================
  // CONVERSATION CRUD
  // ============================================================================

  @override
  Future<Result<ConversationEntity>> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  }) async {
    try {
      final model = await _remoteDataSource.createConversation(
        tripId: tripId,
        name: name,
        description: description,
        memberUserIds: memberUserIds,
        createdBy: createdBy,
        isDirectMessage: isDirectMessage,
      );
      return Result.success(_mapModelToEntity(model));
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<ConversationEntity>>> getTripConversations({
    required String tripId,
    required String userId,
  }) async {
    try {
      final models = await _remoteDataSource.getTripConversations(tripId, userId);
      return Result.success(models.map(_mapModelToEntity).toList());
    } catch (e) {
      debugPrint('Error getting trip conversations: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<ConversationEntity>> getConversation({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final model = await _remoteDataSource.getConversation(conversationId, userId);
      return Result.success(_mapModelToEntity(model));
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      await _remoteDataSource.updateConversation(
        conversationId: conversationId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error updating conversation: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteConversation(String conversationId) async {
    try {
      await _remoteDataSource.deleteConversation(conversationId);
      return Result.success(null);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      return Result.failure(e.toString());
    }
  }

  // ============================================================================
  // MEMBER MANAGEMENT
  // ============================================================================

  @override
  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> userIds,
  }) async {
    try {
      await _remoteDataSource.addMembers(
        conversationId: conversationId,
        userIds: userIds,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error adding members: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.removeMember(
        conversationId: conversationId,
        userId: userId,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error removing member: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async {
    try {
      await _remoteDataSource.updateMemberRole(
        conversationId: conversationId,
        userId: userId,
        role: role,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error updating member role: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> leaveConversation({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.removeMember(
        conversationId: conversationId,
        userId: userId,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error leaving conversation: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> setMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async {
    try {
      await _remoteDataSource.setMuted(
        conversationId: conversationId,
        userId: userId,
        muted: muted,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error setting muted: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.markAsRead(
        conversationId: conversationId,
        userId: userId,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error marking as read: $e');
      return Result.failure(e.toString());
    }
  }

  // ============================================================================
  // MESSAGES
  // ============================================================================

  @override
  Future<Result<List<MessageEntity>>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final models = await _remoteDataSource.getConversationMessages(
        conversationId: conversationId,
        limit: limit,
        offset: offset,
      );
      return Result.success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      debugPrint('Error getting conversation messages: $e');
      return Result.failure(e.toString());
    }
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
    try {
      final model = await _remoteDataSource.sendMessage(
        conversationId: conversationId,
        tripId: tripId,
        senderId: senderId,
        message: message,
        messageType: messageType.name,
        replyToId: replyToId,
        attachmentUrl: attachmentUrl,
      );
      return Result.success(model.toEntity());
    } catch (e) {
      debugPrint('Error sending message: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteMessage({
    required String messageId,
    required String senderId,
  }) async {
    try {
      await _remoteDataSource.deleteMessage(
        messageId: messageId,
        senderId: senderId,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteMessages({
    required List<String> messageIds,
    required String senderId,
  }) async {
    try {
      await _remoteDataSource.deleteMessages(
        messageIds: messageIds,
        senderId: senderId,
      );
      return Result.success(null);
    } catch (e) {
      debugPrint('Error deleting messages: $e');
      return Result.failure(e.toString());
    }
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  @override
  Stream<List<ConversationEntity>> watchTripConversations({
    required String tripId,
    required String userId,
  }) {
    // For now, return a stream that fetches data periodically
    // In production, use Supabase realtime properly
    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => getTripConversations(tripId: tripId, userId: userId))
        .where((result) => result.isSuccess)
        .map((result) => result.data!);
  }

  @override
  Stream<List<MessageEntity>> watchConversationMessages(String conversationId) {
    return _remoteDataSource
        .subscribeToConversationMessages(conversationId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<ConversationEntity> watchConversation({
    required String conversationId,
    required String userId,
  }) {
    return _remoteDataSource
        .subscribeToConversation(conversationId, userId)
        .map(_mapModelToEntity);
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  @override
  Future<Result<List<ConversationMemberEntity>>> getConversationMembers(
    String conversationId,
  ) async {
    try {
      final models = await _remoteDataSource.getConversationMembers(conversationId);
      return Result.success(models.map(_mapMemberModelToEntity).toList());
    } catch (e) {
      debugPrint('Error getting conversation members: $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<ConversationEntity>> findOrCreateDirectMessage({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final model = await _remoteDataSource.findOrCreateDirectMessage(
        tripId: tripId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      return Result.success(_mapModelToEntity(model));
    } catch (e) {
      debugPrint('Error finding/creating DM: $e');
      return Result.failure(e.toString());
    }
  }

  // ============================================================================
  // MAPPERS
  // ============================================================================

  ConversationEntity _mapModelToEntity(ConversationModel model) {
    return ConversationEntity(
      id: model.id,
      tripId: model.tripId,
      name: model.name,
      description: model.description,
      avatarUrl: model.avatarUrl,
      createdBy: model.createdBy,
      isDirectMessage: model.isDirectMessage,
      isDefaultGroup: model.isDefaultGroup,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      lastMessageText: model.lastMessageText,
      lastMessageAt: model.lastMessageAt,
      lastMessageSenderName: model.lastMessageSenderName,
      unreadCount: model.unreadCount,
      memberCount: model.memberCount,
      dmOtherMemberName: model.dmOtherMemberName,
      dmOtherMemberAvatar: model.dmOtherMemberAvatar,
      members: model.members.map(_mapMemberModelToEntity).toList(),
    );
  }

  @override
  Future<Result<ConversationEntity>> getDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    try {
      final model = await _remoteDataSource.getDefaultGroup(
        tripId: tripId,
        userId: userId,
      );
      return Result.success(_mapModelToEntity(model));
    } catch (e) {
      return Result.failure('Failed to get default group: $e');
    }
  }

  @override
  Future<Result<String?>> getDefaultGroupId({
    required String tripId,
  }) async {
    try {
      final id = await _remoteDataSource.getDefaultGroupId(tripId: tripId);
      return Result.success(id);
    } catch (e) {
      debugPrint('Error getting default group ID: $e');
      return Result.failure('Failed to get default group ID: $e');
    }
  }

  ConversationMemberEntity _mapMemberModelToEntity(ConversationMemberModel model) {
    return ConversationMemberEntity(
      id: model.id,
      conversationId: model.conversationId,
      userId: model.userId,
      role: model.role,
      joinedAt: model.joinedAt,
      isMuted: model.isMuted,
      lastReadAt: model.lastReadAt,
      userName: model.userName,
      userAvatarUrl: model.userAvatarUrl,
      userEmail: model.userEmail,
    );
  }
}
