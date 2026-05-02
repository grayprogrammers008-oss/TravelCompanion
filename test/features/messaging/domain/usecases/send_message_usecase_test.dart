import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/send_message_usecase.dart';

import 'send_message_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late SendMessageUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = SendMessageUseCase(mockRepository);
  });

  final testDate = DateTime(2025, 1, 24, 10, 30);
  const testTripId = 'trip-123';
  const testSenderId = 'user-456';
  const testMessage = 'Hello World';

  final testMessageEntity = MessageEntity(
    id: 'msg-789',
    tripId: testTripId,
    senderId: testSenderId,
    message: testMessage,
    messageType: MessageType.text,
    reactions: const [],
    readBy: const [testSenderId],
    createdAt: testDate,
    updatedAt: testDate,
  );

  group('SendMessageUseCase - Text Messages', () {
    test('should send text message successfully', () async {
      // Arrange
      when(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
        replyToId: anyNamed('replyToId'),
        attachmentUrl: anyNamed('attachmentUrl'),
      )).thenAnswer((_) async => testMessageEntity);

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, testMessageEntity);
      expect(result.error, isNull);
      verify(mockRepository.sendMessage(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
        replyToId: null,
        attachmentUrl: null,
      )).called(1);
    });

    test('should fail when tripId is empty', () async {
      // Act
      final result = await useCase.execute(
        tripId: '',
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Trip ID cannot be empty');
      expect(result.data, isNull);
      verifyNever(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
      ));
    });

    test('should fail when senderId is empty', () async {
      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: '',
        message: testMessage,
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Sender ID cannot be empty');
      expect(result.data, isNull);
    });

    test('should fail when message text is empty for text type', () async {
      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: '',
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Message text cannot be empty');
      expect(result.data, isNull);
    });

    test('should fail when message text exceeds 2000 characters', () async {
      // Arrange
      final longMessage = 'A' * 2001;

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: longMessage,
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Message text cannot exceed 2000 characters');
    });

    test('should send reply to message', () async {
      // Arrange
      const replyToId = 'msg-original';
      final replyMessage = testMessageEntity.copyWith(replyToId: replyToId);

      when(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
        replyToId: anyNamed('replyToId'),
        attachmentUrl: anyNamed('attachmentUrl'),
      )).thenAnswer((_) async => replyMessage);

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
        replyToId: replyToId,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.replyToId, replyToId);
      verify(mockRepository.sendMessage(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
        replyToId: replyToId,
        attachmentUrl: null,
      )).called(1);
    });
  });

  group('SendMessageUseCase - Image Messages', () {
    const testImageUrl = 'https://example.com/image.jpg';

    test('should send image message successfully', () async {
      // Arrange
      final imageMessage = testMessageEntity.copyWith(
        messageType: MessageType.image,
        attachmentUrl: testImageUrl,
      );

      when(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
        replyToId: anyNamed('replyToId'),
        attachmentUrl: anyNamed('attachmentUrl'),
      )).thenAnswer((_) async => imageMessage);

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.image,
        attachmentUrl: testImageUrl,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.messageType, MessageType.image);
      expect(result.data?.attachmentUrl, testImageUrl);
    });

    test('should fail when image message has no attachment URL', () async {
      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: '',
        messageType: MessageType.image,
        attachmentUrl: null,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Image message must have an attachment URL');
    });

    test('should fail when image message has empty attachment URL', () async {
      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: '',
        messageType: MessageType.image,
        attachmentUrl: '',
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Image message must have an attachment URL');
    });
  });

  group('SendMessageUseCase - Location Messages', () {
    const testLocationData = 'lat:40.7128,lng:-74.0060';

    test('should send location message successfully', () async {
      // Arrange
      final locationMessage = testMessageEntity.copyWith(
        messageType: MessageType.location,
        attachmentUrl: testLocationData,
      );

      when(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
        replyToId: anyNamed('replyToId'),
        attachmentUrl: anyNamed('attachmentUrl'),
      )).thenAnswer((_) async => locationMessage);

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.location,
        attachmentUrl: testLocationData,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.messageType, MessageType.location);
    });

    test('should fail when location message has no location data', () async {
      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.location,
        attachmentUrl: null,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, 'Location message must have location data');
    });
  });

  group('SendMessageUseCase - Error Handling', () {
    test('should handle repository exceptions', () async {
      // Arrange
      when(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
        replyToId: anyNamed('replyToId'),
        attachmentUrl: anyNamed('attachmentUrl'),
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, contains('Failed to send message'));
      expect(result.error, contains('Network error'));
    });

    test('should handle unknown errors gracefully', () async {
      // Arrange
      when(mockRepository.sendMessage(
        tripId: anyNamed('tripId'),
        senderId: anyNamed('senderId'),
        message: anyNamed('message'),
        messageType: anyNamed('messageType'),
      )).thenThrow('Unexpected error');

      // Act
      final result = await useCase.execute(
        tripId: testTripId,
        senderId: testSenderId,
        message: testMessage,
        messageType: MessageType.text,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.error, isNotNull);
    });
  });

  group('Result Type', () {
    test('fold should return success value', () {
      final result = Result.success(42);
      final value = result.fold(
        onSuccess: (data) => 'Success: $data',
        onFailure: (error) => 'Failure: $error',
      );
      expect(value, 'Success: 42');
    });

    test('fold should return failure value', () {
      final result = Result<int>.failure('Error occurred');
      final value = result.fold(
        onSuccess: (data) => 'Success: $data',
        onFailure: (error) => 'Failure: $error',
      );
      expect(value, 'Failure: Error occurred');
    });

    test('map should transform success data', () {
      final result = Result.success(10);
      final mapped = result.map((data) => data * 2);
      expect(mapped.isSuccess, true);
      expect(mapped.data, 20);
    });

    test('map should preserve failure', () {
      final result = Result<int>.failure('Error');
      final mapped = result.map((data) => data * 2);
      expect(mapped.isSuccess, false);
      expect(mapped.error, 'Error');
    });

    test('mapError should transform error message', () {
      final result = Result<int>.failure('Network error');
      final mapped = result.mapError((error) => 'Transformed: $error');
      expect(mapped.isSuccess, false);
      expect(mapped.error, 'Transformed: Network error');
    });

    test('mapError should preserve success', () {
      final result = Result.success(42);
      final mapped = result.mapError((error) => 'Should not see this');
      expect(mapped.isSuccess, true);
      expect(mapped.data, 42);
    });
  });
}
