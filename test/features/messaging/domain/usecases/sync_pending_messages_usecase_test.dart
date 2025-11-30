import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/domain/usecases/sync_pending_messages_usecase.dart';

import 'sync_pending_messages_usecase_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late SyncPendingMessagesUseCase useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = SyncPendingMessagesUseCase(mockRepository);
  });

  final now = DateTime.now();

  QueuedMessageEntity createQueuedMessage({
    required String id,
    MessageSyncStatus syncStatus = MessageSyncStatus.pending,
  }) {
    return QueuedMessageEntity(
      id: id,
      tripId: 'trip-123',
      senderId: 'user-123',
      messageData: {'message': 'Test message'},
      transmissionMethod: TransmissionMethod.internet,
      syncStatus: syncStatus,
      createdAt: now,
    );
  }

  group('SyncPendingMessagesUseCase', () {
    group('Positive Cases', () {
      test('should return success with zero counts when no pending messages', () async {
        // Arrange
        when(mockRepository.getPendingMessages())
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.totalMessages, 0);
        expect(result.data!.syncedMessages, 0);
        expect(result.data!.failedMessages, 0);
        expect(result.data!.allSynced, true);
        verifyNever(mockRepository.syncPendingMessages());
      });

      test('should sync all pending messages successfully', () async {
        // Arrange
        final pendingMessages = [
          createQueuedMessage(id: 'q-1'),
          createQueuedMessage(id: 'q-2'),
          createQueuedMessage(id: 'q-3'),
        ];

        when(mockRepository.getPendingMessages())
            .thenAnswer((_) async => pendingMessages);
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // After sync, return empty list (all synced)
        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return []; // After sync
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 3);
        expect(result.data!.syncedMessages, 3);
        expect(result.data!.failedMessages, 0);
        expect(result.data!.allSynced, true);
        expect(result.data!.someFailed, false);
        verify(mockRepository.syncPendingMessages()).called(1);
      });

      test('should handle partial sync (some messages failed)', () async {
        // Arrange
        final pendingMessages = [
          createQueuedMessage(id: 'q-1'),
          createQueuedMessage(id: 'q-2'),
          createQueuedMessage(id: 'q-3'),
        ];
        final remainingMessages = [
          createQueuedMessage(id: 'q-3', syncStatus: MessageSyncStatus.failed),
        ];

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return remainingMessages; // One failed
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 3);
        expect(result.data!.syncedMessages, 2);
        expect(result.data!.failedMessages, 1);
        expect(result.data!.allSynced, false);
        expect(result.data!.someFailed, true);
        expect(result.data!.allFailed, false);
      });

      test('should handle all messages failed to sync', () async {
        // Arrange
        final pendingMessages = [
          createQueuedMessage(id: 'q-1'),
          createQueuedMessage(id: 'q-2'),
        ];

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return pendingMessages; // All still pending
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 2);
        expect(result.data!.syncedMessages, 0);
        expect(result.data!.failedMessages, 2);
        expect(result.data!.allSynced, false);
        expect(result.data!.allFailed, true);
      });

      test('should sync single pending message', () async {
        // Arrange
        final pendingMessages = [createQueuedMessage(id: 'q-1')];

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return [];
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 1);
        expect(result.data!.syncedMessages, 1);
      });

      test('should sync many pending messages', () async {
        // Arrange
        final pendingMessages = List.generate(
          100,
          (i) => createQueuedMessage(id: 'q-$i'),
        );

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return [];
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 100);
        expect(result.data!.syncedMessages, 100);
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should return failure when getPendingMessages throws', () async {
        // Arrange
        when(mockRepository.getPendingMessages())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to sync pending messages'));
      });

      test('should return failure when syncPendingMessages throws', () async {
        // Arrange
        final pendingMessages = [createQueuedMessage(id: 'q-1')];
        when(mockRepository.getPendingMessages())
            .thenAnswer((_) async => pendingMessages);
        when(mockRepository.syncPendingMessages())
            .thenThrow(Exception('Network error'));

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Failed to sync pending messages'));
      });

      test('should handle timeout error', () async {
        // Arrange
        final pendingMessages = [createQueuedMessage(id: 'q-1')];
        when(mockRepository.getPendingMessages())
            .thenAnswer((_) async => pendingMessages);
        when(mockRepository.syncPendingMessages())
            .thenThrow(Exception('Request timeout'));

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('timeout'));
      });

      test('should handle authentication error during sync', () async {
        // Arrange
        final pendingMessages = [createQueuedMessage(id: 'q-1')];
        when(mockRepository.getPendingMessages())
            .thenAnswer((_) async => pendingMessages);
        when(mockRepository.syncPendingMessages())
            .thenThrow(Exception('User not authenticated'));

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('User not authenticated'));
      });
    });

    group('Edge Cases', () {
      test('should handle messages with different transmission methods', () async {
        // Arrange
        final pendingMessages = [
          QueuedMessageEntity(
            id: 'q-internet',
            tripId: 'trip-123',
            senderId: 'user-123',
            messageData: {'message': 'Internet message'},
            transmissionMethod: TransmissionMethod.internet,
            syncStatus: MessageSyncStatus.pending,
            createdAt: now,
          ),
          QueuedMessageEntity(
            id: 'q-bluetooth',
            tripId: 'trip-123',
            senderId: 'user-123',
            messageData: {'message': 'Bluetooth message'},
            transmissionMethod: TransmissionMethod.bluetooth,
            syncStatus: MessageSyncStatus.pending,
            createdAt: now,
          ),
          QueuedMessageEntity(
            id: 'q-wifi',
            tripId: 'trip-123',
            senderId: 'user-123',
            messageData: {'message': 'WiFi Direct message'},
            transmissionMethod: TransmissionMethod.wifiDirect,
            syncStatus: MessageSyncStatus.pending,
            createdAt: now,
          ),
        ];

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return [];
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 3);
      });

      test('should handle messages with relay path', () async {
        // Arrange
        final messageWithRelay = QueuedMessageEntity(
          id: 'q-relay',
          tripId: 'trip-123',
          senderId: 'user-123',
          messageData: {'message': 'Relay message'},
          transmissionMethod: TransmissionMethod.relay,
          relayPath: ['device-1', 'device-2', 'device-3'],
          syncStatus: MessageSyncStatus.pending,
          createdAt: now,
        );

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [messageWithRelay];
          return [];
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.totalMessages, 1);
      });

      test('should handle messages with retry count', () async {
        // Arrange
        final messageWithRetries = QueuedMessageEntity(
          id: 'q-retry',
          tripId: 'trip-123',
          senderId: 'user-123',
          messageData: {'message': 'Retried message'},
          transmissionMethod: TransmissionMethod.internet,
          syncStatus: MessageSyncStatus.pending,
          retryCount: 3,
          lastAttemptAt: now.subtract(const Duration(minutes: 5)),
          createdAt: now.subtract(const Duration(hours: 1)),
        );

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [messageWithRetries];
          return [];
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle messages with error messages', () async {
        // Arrange
        final failedMessage = QueuedMessageEntity(
          id: 'q-failed',
          tripId: 'trip-123',
          senderId: 'user-123',
          messageData: {'message': 'Failed message'},
          transmissionMethod: TransmissionMethod.internet,
          syncStatus: MessageSyncStatus.failed,
          retryCount: 5,
          lastAttemptAt: now,
          errorMessage: 'Server unavailable',
          createdAt: now.subtract(const Duration(hours: 2)),
        );

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [failedMessage];
          return [failedMessage]; // Still failed
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.failedMessages, 1);
      });

      test('SyncResult toString should return readable format', () async {
        // Arrange
        final pendingMessages = [
          createQueuedMessage(id: 'q-1'),
          createQueuedMessage(id: 'q-2'),
        ];

        var callCount = 0;
        when(mockRepository.getPendingMessages()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return pendingMessages;
          return [createQueuedMessage(id: 'q-2')]; // One remaining
        });
        when(mockRepository.syncPendingMessages()).thenAnswer((_) async {
          return;
        });

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.data!.toString(),
            contains('SyncResult(total: 2, synced: 1, failed: 1)'));
      });
    });

    group('SyncResult Properties', () {
      test('allSynced should be true when failedMessages is 0', () {
        final syncResult = SyncResult(
          totalMessages: 5,
          syncedMessages: 5,
          failedMessages: 0,
        );
        expect(syncResult.allSynced, true);
      });

      test('allSynced should be false when failedMessages > 0', () {
        final syncResult = SyncResult(
          totalMessages: 5,
          syncedMessages: 4,
          failedMessages: 1,
        );
        expect(syncResult.allSynced, false);
      });

      test('someFailed should be true when failedMessages > 0', () {
        final syncResult = SyncResult(
          totalMessages: 5,
          syncedMessages: 3,
          failedMessages: 2,
        );
        expect(syncResult.someFailed, true);
      });

      test('someFailed should be false when failedMessages is 0', () {
        final syncResult = SyncResult(
          totalMessages: 5,
          syncedMessages: 5,
          failedMessages: 0,
        );
        expect(syncResult.someFailed, false);
      });

      test('allFailed should be true when syncedMessages is 0 and totalMessages > 0', () {
        final syncResult = SyncResult(
          totalMessages: 5,
          syncedMessages: 0,
          failedMessages: 5,
        );
        expect(syncResult.allFailed, true);
      });

      test('allFailed should be false when syncedMessages > 0', () {
        final syncResult = SyncResult(
          totalMessages: 5,
          syncedMessages: 1,
          failedMessages: 4,
        );
        expect(syncResult.allFailed, false);
      });

      test('allFailed should be false when totalMessages is 0', () {
        final syncResult = SyncResult(
          totalMessages: 0,
          syncedMessages: 0,
          failedMessages: 0,
        );
        expect(syncResult.allFailed, false);
      });
    });
  });
}
