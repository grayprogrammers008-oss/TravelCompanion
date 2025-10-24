import 'package:flutter/foundation.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

/// Use Case: Send Message
/// Validates input and sends a message through the repository
class SendMessageUseCase {
  final MessageRepository repository;

  SendMessageUseCase(this.repository);

  /// Execute the use case
  /// Returns the sent message entity
  Future<Result<MessageEntity>> execute({
    required String tripId,
    required String senderId,
    required String message,
    required MessageType messageType,
    String? replyToId,
    String? attachmentUrl,
  }) async {
    try {
      debugPrint('🔵 [SendMessageUseCase] execute START');
      debugPrint('   Trip ID: $tripId');
      debugPrint('   Sender ID: $senderId');
      debugPrint('   Message Type: $messageType');

      // Validate inputs
      final validationError = _validate(
        tripId: tripId,
        senderId: senderId,
        message: message,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
      );

      if (validationError != null) {
        debugPrint('❌ [SendMessageUseCase] Validation failed: $validationError');
        return Result.failure(validationError);
      }

      // Send message through repository
      final messageEntity = await repository.sendMessage(
        tripId: tripId,
        senderId: senderId,
        message: message,
        messageType: messageType,
        replyToId: replyToId,
        attachmentUrl: attachmentUrl,
      );

      debugPrint('✅ [SendMessageUseCase] Message sent successfully');
      return Result.success(messageEntity);
    } catch (e, stackTrace) {
      debugPrint('❌ [SendMessageUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to send message: $e');
    }
  }

  /// Validate input parameters
  String? _validate({
    required String tripId,
    required String senderId,
    required String message,
    required MessageType messageType,
    String? attachmentUrl,
  }) {
    // Validate trip ID
    if (tripId.isEmpty) {
      return 'Trip ID cannot be empty';
    }

    // Validate sender ID
    if (senderId.isEmpty) {
      return 'Sender ID cannot be empty';
    }

    // Validate message content based on type
    if (messageType == MessageType.text) {
      if (message.isEmpty) {
        return 'Message text cannot be empty';
      }
      if (message.length > 2000) {
        return 'Message text cannot exceed 2000 characters';
      }
    }

    // Validate attachment URL for image type
    if (messageType == MessageType.image) {
      if (attachmentUrl == null || attachmentUrl.isEmpty) {
        return 'Image message must have an attachment URL';
      }
    }

    // Validate location data
    if (messageType == MessageType.location) {
      if (attachmentUrl == null || attachmentUrl.isEmpty) {
        return 'Location message must have location data';
      }
    }

    return null; // All validations passed
  }
}

/// Result wrapper for use case responses
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  factory Result.failure(String error) {
    return Result._(error: error, isSuccess: false);
  }

  /// Execute a function if result is success
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return Result.success(mapper(data as T));
      } catch (e) {
        return Result.failure('Mapping failed: $e');
      }
    }
    return Result.failure(error ?? 'Unknown error');
  }

  /// Execute a function if result is failure
  Result<T> mapError(String Function(String error) mapper) {
    if (!isSuccess && error != null) {
      return Result.failure(mapper(error!));
    }
    return this;
  }

  /// Fold the result into a single value
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String error) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    }
    return onFailure(error ?? 'Unknown error');
  }
}
