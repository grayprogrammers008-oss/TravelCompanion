import 'package:flutter/foundation.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Remove Reaction
/// Removes an emoji reaction from a message
class RemoveReactionUseCase {
  final MessageRepository repository;

  RemoveReactionUseCase(this.repository);

  /// Execute the use case
  Future<Result<void>> execute({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [RemoveReactionUseCase] execute START');
      debugPrint('   Message ID: $messageId');
      debugPrint('   User ID: $userId');
      debugPrint('   Emoji: $emoji');

      // Validate inputs
      final validationError = _validate(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );

      if (validationError != null) {
        debugPrint('❌ [RemoveReactionUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Remove reaction through repository
      await repository.removeReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );

      debugPrint('✅ [RemoveReactionUseCase] Reaction removed');
      return Result.success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ [RemoveReactionUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to remove reaction: $e');
    }
  }

  /// Validate input parameters
  String? _validate({
    required String messageId,
    required String userId,
    required String emoji,
  }) {
    if (messageId.isEmpty) {
      return 'Message ID cannot be empty';
    }

    if (userId.isEmpty) {
      return 'User ID cannot be empty';
    }

    if (emoji.isEmpty) {
      return 'Emoji cannot be empty';
    }

    return null;
  }
}
