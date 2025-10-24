import 'package:flutter/foundation.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Get Trip Messages
/// Retrieves messages for a specific trip with pagination
class GetTripMessagesUseCase {
  final MessageRepository repository;

  GetTripMessagesUseCase(this.repository);

  /// Execute the use case
  /// Returns a list of message entities
  Future<Result<List<MessageEntity>>> execute({
    required String tripId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔵 [GetTripMessagesUseCase] execute START');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Limit: $limit, Offset: $offset');

      // Validate inputs
      final validationError = _validate(
        tripId: tripId,
        limit: limit,
        offset: offset,
      );

      if (validationError != null) {
        debugPrint('❌ [GetTripMessagesUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Get messages from repository
      final messages = await repository.getTripMessages(
        tripId: tripId,
        limit: limit,
        offset: offset,
      );

      debugPrint('✅ [GetTripMessagesUseCase] Retrieved ${messages.length} messages');
      return Result.success(messages);
    } catch (e, stackTrace) {
      debugPrint('❌ [GetTripMessagesUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to get trip messages: $e');
    }
  }

  /// Validate input parameters
  String? _validate({
    required String tripId,
    required int limit,
    required int offset,
  }) {
    if (tripId.isEmpty) {
      return 'Trip ID cannot be empty';
    }

    if (limit <= 0) {
      return 'Limit must be greater than 0';
    }

    if (limit > 100) {
      return 'Limit cannot exceed 100';
    }

    if (offset < 0) {
      return 'Offset cannot be negative';
    }

    return null;
  }
}
