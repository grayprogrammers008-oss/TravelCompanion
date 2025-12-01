import '../entities/conversation_entity.dart';
import '../repositories/conversation_repository.dart';
import 'send_message_usecase.dart';

/// Use case for creating a new conversation
class CreateConversationUseCase {
  final ConversationRepository _repository;

  CreateConversationUseCase(this._repository);

  /// Execute the use case to create a conversation
  ///
  /// [tripId] - The trip this conversation belongs to
  /// [name] - Name of the conversation
  /// [memberUserIds] - List of user IDs to add as members (including creator)
  /// [createdBy] - User ID of the creator
  /// [description] - Optional description
  /// [isDirectMessage] - Whether this is a 1:1 DM
  Future<Result<ConversationEntity>> execute({
    required String tripId,
    required String name,
    required List<String> memberUserIds,
    required String createdBy,
    String? description,
    bool isDirectMessage = false,
  }) {
    return _repository.createConversation(
      tripId: tripId,
      name: name,
      description: description,
      memberUserIds: memberUserIds,
      createdBy: createdBy,
      isDirectMessage: isDirectMessage,
    );
  }
}
