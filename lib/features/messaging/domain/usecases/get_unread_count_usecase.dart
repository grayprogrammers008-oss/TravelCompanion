import 'package:flutter/foundation.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Get Unread Count
/// Gets the count of unread messages for a specific trip and user
class GetUnreadCountUseCase {
  final MessageRepository repository;

  GetUnreadCountUseCase(this.repository);

  /// Execute the use case
  Future<Result<int>> execute({
    required String tripId,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [GetUnreadCountUseCase] execute START');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   User ID: $userId');

      // Validate inputs
      final validationError = _validate(
        tripId: tripId,
        userId: userId,
      );

      if (validationError != null) {
        debugPrint('❌ [GetUnreadCountUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Get unread count from repository
      final count = await repository.getUnreadCount(
        tripId: tripId,
        userId: userId,
      );

      debugPrint('✅ [GetUnreadCountUseCase] Unread count: $count');
      return Result.success(count);
    } catch (e, stackTrace) {
      debugPrint('❌ [GetUnreadCountUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to get unread count: $e');
    }
  }

  /// Validate input parameters
  String? _validate({
    required String tripId,
    required String userId,
  }) {
    if (tripId.isEmpty) {
      return 'Trip ID cannot be empty';
    }

    if (userId.isEmpty) {
      return 'User ID cannot be empty';
    }

    return null;
  }
}
