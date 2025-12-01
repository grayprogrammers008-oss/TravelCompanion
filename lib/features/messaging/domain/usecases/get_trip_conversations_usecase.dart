import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';
import 'send_message_usecase.dart';

/// Use case for getting all conversations in a trip
class GetTripConversationsUseCase {
  final ConversationRepository _repository;

  GetTripConversationsUseCase(this._repository);

  /// Execute the use case to get conversations
  ///
  /// [tripId] - The trip ID to get conversations for
  /// [userId] - The current user's ID (to filter by membership)
  Future<Result<List<ConversationEntity>>> execute({
    required String tripId,
    required String userId,
  }) {
    return _repository.getTripConversations(
      tripId: tripId,
      userId: userId,
    );
  }
}

/// Use case for leaving a conversation
class LeaveConversationUseCase {
  final ConversationRepository _repository;

  LeaveConversationUseCase(this._repository);

  /// Execute the use case to leave a conversation
  ///
  /// [conversationId] - The conversation to leave
  /// [userId] - The user's ID who is leaving
  Future<Result<void>> execute({
    required String conversationId,
    required String userId,
  }) {
    return _repository.leaveConversation(
      conversationId: conversationId,
      userId: userId,
    );
  }
}

/// Use case for adding members to a conversation
class AddConversationMembersUseCase {
  final ConversationRepository _repository;

  AddConversationMembersUseCase(this._repository);

  /// Execute the use case to add members
  ///
  /// [conversationId] - The conversation to add members to
  /// [userIds] - List of user IDs to add
  Future<Result<void>> execute({
    required String conversationId,
    required List<String> userIds,
  }) {
    return _repository.addMembers(
      conversationId: conversationId,
      userIds: userIds,
    );
  }
}

/// Use case for marking a conversation as read
class MarkConversationAsReadUseCase {
  final ConversationRepository _repository;

  MarkConversationAsReadUseCase(this._repository);

  /// Execute the use case to mark conversation as read
  ///
  /// [conversationId] - The conversation to mark as read
  /// [userId] - The user's ID
  Future<Result<void>> execute({
    required String conversationId,
    required String userId,
  }) {
    return _repository.markConversationAsRead(
      conversationId: conversationId,
      userId: userId,
    );
  }
}
