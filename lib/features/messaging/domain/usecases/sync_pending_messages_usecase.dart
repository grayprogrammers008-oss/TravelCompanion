import 'package:flutter/foundation.dart';
import '../repositories/message_repository.dart';
import 'send_message_usecase.dart';

/// Use Case: Sync Pending Messages
/// Syncs all pending messages in the offline queue
/// Called when connectivity is restored or manually by user
class SyncPendingMessagesUseCase {
  final MessageRepository repository;

  SyncPendingMessagesUseCase(this.repository);

  /// Execute the use case
  /// Returns success even if some messages fail to sync
  Future<Result<SyncResult>> execute() async {
    try {
      debugPrint('🔵 [SyncPendingMessagesUseCase] execute START');

      // Get pending messages before sync
      final pendingMessages = await repository.getPendingMessages();
      final totalCount = pendingMessages.length;

      debugPrint('   ℹ️ Found $totalCount pending messages');

      if (totalCount == 0) {
        debugPrint('✅ [SyncPendingMessagesUseCase] No messages to sync');
        return Result.success(SyncResult(
          totalMessages: 0,
          syncedMessages: 0,
          failedMessages: 0,
        ));
      }

      // Sync pending messages
      await repository.syncPendingMessages();

      // Get remaining pending messages after sync
      final remainingMessages = await repository.getPendingMessages();
      final remainingCount = remainingMessages.length;

      final syncedCount = totalCount - remainingCount;
      final failedCount = remainingCount;

      debugPrint('   ✅ Synced: $syncedCount');
      debugPrint('   ❌ Failed: $failedCount');

      debugPrint('✅ [SyncPendingMessagesUseCase] Sync complete');
      return Result.success(SyncResult(
        totalMessages: totalCount,
        syncedMessages: syncedCount,
        failedMessages: failedCount,
      ));
    } catch (e, stackTrace) {
      debugPrint('❌ [SyncPendingMessagesUseCase] execute FAILED');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return Result.failure('Failed to sync pending messages: $e');
    }
  }
}

/// Result of sync operation
class SyncResult {
  final int totalMessages;
  final int syncedMessages;
  final int failedMessages;

  SyncResult({
    required this.totalMessages,
    required this.syncedMessages,
    required this.failedMessages,
  });

  bool get allSynced => failedMessages == 0;
  bool get someFailed => failedMessages > 0;
  bool get allFailed => syncedMessages == 0 && totalMessages > 0;

  @override
  String toString() {
    return 'SyncResult(total: $totalMessages, synced: $syncedMessages, failed: $failedMessages)';
  }
}
