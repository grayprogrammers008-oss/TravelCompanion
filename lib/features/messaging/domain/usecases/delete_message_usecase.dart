import 'package:flutter/foundation.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Delete Message
/// Deletes a message (soft delete)
/// Only the sender can delete their own messages
class DeleteMessageUseCase {
  final MessageRepository repository;

  DeleteMessageUseCase(this.repository);

  /// Execute the use case
  /// Note: Permission check (is sender) should be done in the UI layer
  /// This use case assumes the caller has already verified permissions
  Future<Result<void>> execute({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [DeleteMessageUseCase] execute START');
      debugPrint('   Message ID: $messageId');
      debugPrint('   User ID: $userId');

      // Validate inputs
      final validationError = _validate(
        messageId: messageId,
        userId: userId,
      );

      if (validationError != null) {
        debugPrint('❌ [DeleteMessageUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Verify user is the sender
      final message = await repository.getMessageById(messageId);
      if (message == null) {
        debugPrint('❌ [DeleteMessageUseCase] Message not found');
        return Result.failure('Message not found');
      }

      if (message.senderId != userId) {
        debugPrint('❌ [DeleteMessageUseCase] User is not the sender');
        return Result.failure('You can only delete your own messages');
      }

      // Delete message through repository
      await repository.deleteMessage(messageId);

      debugPrint('✅ [DeleteMessageUseCase] Message deleted');
      return Result.success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ [DeleteMessageUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to delete message: $e');
    }
  }

  /// Validate input parameters
  String? _validate({
    required String messageId,
    required String userId,
  }) {
    if (messageId.isEmpty) {
      return 'Message ID cannot be empty';
    }

    if (userId.isEmpty) {
      return 'User ID cannot be empty';
    }

    return null;
  }
}
