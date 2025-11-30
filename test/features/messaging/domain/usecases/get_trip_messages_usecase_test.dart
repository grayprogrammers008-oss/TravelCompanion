import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/get_trip_messages_usecase.dart';

import 'get_trip_messages_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late GetTripMessagesUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = GetTripMessagesUseCase(mockRepository);
  });

  final now = DateTime.now();

  final testMessage = MessageEntity(
    id: 'msg-123',
    tripId: 'trip-123',
    senderId: 'user-123',
    message: 'Hello, world!',
    messageType: MessageType.text,
    reactions: const [],
    readBy: const ['user-123'],
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
    senderName: 'John Doe',
  );

  group('GetTripMessagesUseCase', () {
    group('Positive Cases', () {
      test('should return list of messages for a trip', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage]);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.length, 1);
        expect(result.data!.first.id, 'msg-123');
        verify(mockRepository.getTripMessages(
          tripId: 'trip-123',
          limit: 50,
          offset: 0,
        )).called(1);
      });

      test('should return empty list when no messages exist', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('should return multiple messages', () async {
        // Arrange
        final message2 = MessageEntity(
          id: 'msg-456',
          tripId: 'trip-123',
          senderId: 'user-456',
          message: 'Hi there!',
          messageType: MessageType.text,
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now.add(const Duration(minutes: 1)),
          updatedAt: now.add(const Duration(minutes: 1)),
          senderName: 'Jane Doe',
        );

        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage, message2]);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.length, 2);
      });

      test('should handle pagination with custom limit', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage]);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: 25,
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getTripMessages(
          tripId: 'trip-123',
          limit: 25,
          offset: 0,
        )).called(1);
      });

      test('should handle pagination with offset', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage]);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: 50,
          offset: 100,
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getTripMessages(
          tripId: 'trip-123',
          limit: 50,
          offset: 100,
        )).called(1);
      });

      test('should return messages with various types', () async {
        // Arrange
        final imageMessage = MessageEntity(
          id: 'msg-image',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: null,
          messageType: MessageType.image,
          attachmentUrl: 'https://example.com/image.jpg',
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        final locationMessage = MessageEntity(
          id: 'msg-location',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: null,
          messageType: MessageType.location,
          attachmentUrl: 'lat:40.7128,lng:-74.0060',
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage, imageMessage, locationMessage]);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.length, 3);
        expect(result.data![0].messageType, MessageType.text);
        expect(result.data![1].messageType, MessageType.image);
        expect(result.data![2].messageType, MessageType.location);
      });
    });

    group('Negative Cases - Validation', () {
      test('should return failure for empty trip ID', () async {
        // Act
        final result = await useCase.execute(tripId: '');

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Trip ID cannot be empty'));
        verifyNever(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ));
      });

      test('should return failure for zero limit', () async {
        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: 0,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Limit must be greater than 0'));
        verifyNever(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ));
      });

      test('should return failure for negative limit', () async {
        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: -5,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Limit must be greater than 0'));
      });

      test('should return failure for limit exceeding 100', () async {
        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: 150,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Limit cannot exceed 100'));
      });

      test('should return failure for negative offset', () async {
        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          offset: -1,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Offset cannot be negative'));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should return failure when repository throws exception', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to get trip messages'));
      });

      test('should handle database error', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenThrow(Exception('Database unavailable'));

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Database unavailable'));
      });
    });

    group('Edge Cases', () {
      test('should handle boundary limit of 100', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage]);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: 100,
        );

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getTripMessages(
          tripId: 'trip-123',
          limit: 100,
          offset: 0,
        )).called(1);
      });

      test('should handle boundary limit of 1', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage]);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          limit: 1,
        );

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle UUID format trip ID', () async {
        // Arrange
        const uuidTripId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(tripId: uuidTripId);

        // Assert
        expect(result.isSuccess, true);
        verify(mockRepository.getTripMessages(
          tripId: uuidTripId,
          limit: 50,
          offset: 0,
        )).called(1);
      });

      test('should handle large offset value', () async {
        // Arrange
        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(
          tripId: 'trip-123',
          offset: 10000,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('should handle messages with reactions', () async {
        // Arrange
        final messageWithReactions = MessageEntity(
          id: 'msg-reactions',
          tripId: 'trip-123',
          senderId: 'user-123',
          message: 'Great!',
          messageType: MessageType.text,
          reactions: [
            MessageReaction(
              emoji: '👍',
              userId: 'user-456',
              createdAt: now,
            ),
            MessageReaction(
              emoji: '❤️',
              userId: 'user-789',
              createdAt: now,
            ),
          ],
          readBy: const ['user-123', 'user-456'],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [messageWithReactions]);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.first.reactions.length, 2);
        expect(result.data!.first.readBy.length, 2);
      });

      test('should handle deleted messages', () async {
        // Arrange
        final deletedMessage = testMessage.copyWith(isDeleted: true);

        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [deletedMessage]);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.first.isDeleted, true);
      });

      test('should handle reply messages', () async {
        // Arrange
        final replyMessage = MessageEntity(
          id: 'msg-reply',
          tripId: 'trip-123',
          senderId: 'user-456',
          message: 'Reply to your message',
          messageType: MessageType.text,
          replyToId: 'msg-123',
          reactions: const [],
          readBy: const [],
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getTripMessages(
          tripId: anyNamed('tripId'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        )).thenAnswer((_) async => [testMessage, replyMessage]);

        // Act
        final result = await useCase.execute(tripId: 'trip-123');

        // Assert
        expect(result.isSuccess, true);
        expect(result.data![1].replyToId, 'msg-123');
      });
    });
  });
}
