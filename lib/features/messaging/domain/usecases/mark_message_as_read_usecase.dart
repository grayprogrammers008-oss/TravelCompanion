import 'package:flutter/foundation.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Mark Message as Read
/// Marks a message as read by a specific user
class MarkMessageAsReadUseCase {
  final MessageRepository repository;

  MarkMessageAsReadUseCase(this.repository);

  /// Execute the use case
  Future<Result<void>> execute({
    required String messageId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [MarkMessageAsReadUseCase] execute START');
      debugPrint('   Message ID: $messageId');
      debugPrint('   User ID: $userId');

      // Validate inputs
      final validationError = _validate(
        messageId: messageId,
        userId: userId,
      );

      if (validationError != null) {
        debugPrint('❌ [MarkMessageAsReadUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Mark message as read through repository
      await repository.markMessageAsRead(
        messageId: messageId,
        userId: userId,
      );

      debugPrint('✅ [MarkMessageAsReadUseCase] Message marked as read');
      return Result.success(null);
    } catch (e, stackTrace) {
      debugPrint('❌ [MarkMessageAsReadUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to mark message as read: $e');
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
