import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';
import '../usecases/send_message_usecase.dart';

/// Repository interface for conversation operations
abstract class ConversationRepository {
  // ============================================================================
  // CONVERSATION CRUD
  // ============================================================================

  /// Create a new conversation in a trip
  Future<Result<ConversationEntity>> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  });

  /// Get all conversations for a trip that the user is a member of
  Future<Result<List<ConversationEntity>>> getTripConversations({
    required String tripId,
    required String userId,
  });

  /// Get a single conversation by ID
  Future<Result<ConversationEntity>> getConversation({
    required String conversationId,
    required String userId,
  });

  /// Update conversation details (name, description, avatar)
  Future<Result<void>> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
  });

  /// Delete a conversation (admin only)
  Future<Result<void>> deleteConversation(String conversationId);

  // ============================================================================
  // MEMBER MANAGEMENT
  // ============================================================================

  /// Add members to a conversation
  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> userIds,
  });

  /// Remove a member from a conversation
  Future<Result<void>> removeMember({
    required String conversationId,
    required String userId,
  });

  /// Update a member's role (admin/member)
  Future<Result<void>> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  });

  /// Leave a conversation (remove self)
  Future<Result<void>> leaveConversation({
    required String conversationId,
    required String userId,
  });

  /// Mute/unmute notifications for a conversation
  Future<Result<void>> setMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  });

  /// Update last read timestamp for unread count
  Future<Result<void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  });

  // ============================================================================
  // MESSAGES
  // ============================================================================

  /// Get messages for a conversation
  Future<Result<List<MessageEntity>>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  });

  /// Send a message to a conversation
  Future<Result<MessageEntity>> sendConversationMessage({
    required String conversationId,
    required String tripId,
    required String senderId,
    required String message,
    MessageType messageType = MessageType.text,
    String? replyToId,
    String? attachmentUrl,
  });

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// Watch conversations for a trip (real-time updates)
  Stream<List<ConversationEntity>> watchTripConversations({
    required String tripId,
    required String userId,
  });

  /// Watch messages for a conversation (real-time updates)
  Stream<List<MessageEntity>> watchConversationMessages(String conversationId);

  /// Watch a single conversation for updates
  Stream<ConversationEntity> watchConversation({
    required String conversationId,
    required String userId,
  });

  // ============================================================================
  // UTILITY
  // ============================================================================

  /// Get conversation members with profile info
  Future<Result<List<ConversationMemberEntity>>> getConversationMembers(
    String conversationId,
  );

  /// Find or create a direct message conversation with a user
  Future<Result<ConversationEntity>> findOrCreateDirectMessage({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  });
}
