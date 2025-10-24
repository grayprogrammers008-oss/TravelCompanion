import 'package:flutter/foundation.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Add Reaction
/// Adds an emoji reaction to a message
class AddReactionUseCase {
  final MessageRepository repository;

  AddReactionUseCase(this.repository);

  /// Execute the use case
  Future<Result<void>> execute({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      debugPrint('🔵 [AddReactionUseCase] execute START');
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
        debugPrint('❌ [AddReactionUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Add reaction through repository
      await repository.addReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );

      debugPrint('✅ [AddReactionUseCase] Reaction added');
      return Result.success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ [AddReactionUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to add reaction: $e');
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

    // Basic emoji validation (1-4 characters, most emojis are in this range)
    if (emoji.length > 4) {
      return 'Invalid emoji';
    }

    return null;
  }
}
