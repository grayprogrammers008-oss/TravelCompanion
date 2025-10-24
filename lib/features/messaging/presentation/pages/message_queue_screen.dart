import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/messaging_providers.dart';

/// Message Queue Screen
/// Displays pending and failed messages in the offline queue
class MessageQueueScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const MessageQueueScreen({
    super.key,
    this.tripId,
  });

  @override
  ConsumerState<MessageQueueScreen> createState() => _MessageQueueScreenState();
}

class _MessageQueueScreenState extends ConsumerState<MessageQueueScreen> {
  bool _isSyncing = false;

  /// Handle sync all pending messages
  Future<void> _handleSyncAll() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncUseCase = ref.read(syncPendingMessagesUseCaseProvider);
      final result = await syncUseCase.execute();

      if (!mounted) return;

      result.fold(
        onSuccess: (syncResult) {
          if (syncResult.allSynced) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ All messages synced successfully!'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (syncResult.someFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ ${syncResult.syncedMessages} synced, '
                  '${syncResult.failedMessages} failed',
                ),
                backgroundColor: AppTheme.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (syncResult.allFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Failed to sync messages. Check connection.'),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Refresh the list
          ref.invalidate(pendingMessagesCountProvider);
          if (widget.tripId != null) {
            ref.invalidate(pendingMessagesByTripProvider(widget.tripId!));
          }
        },
        onFailure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// Handle retry single message
  Future<void> _handleRetryMessage(String queueId) async {
    try {
      final repository = ref.read(messageRepositoryProvider);
      await repository.retryMessage(queueId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Message synced successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the list
      ref.invalidate(pendingMessagesCountProvider);
      if (widget.tripId != null) {
        ref.invalidate(pendingMessagesByTripProvider(widget.tripId!));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handle remove from queue
  Future<void> _handleRemoveFromQueue(String queueId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Message?'),
        content: const Text(
          'This will remove the message from the queue. '
          'It will not be sent to the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(messageRepositoryProvider);
      await repository.removeFromQueue(queueId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message removed from queue'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh the list
      ref.invalidate(pendingMessagesCountProvider);
      if (widget.tripId != null) {
        ref.invalidate(pendingMessagesByTripProvider(widget.tripId!));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch pending messages
    final pendingAsync = widget.tripId != null
        ? ref.watch(pendingMessagesByTripProvider(widget.tripId!))
        : ref.watch(pendingMessagesCountProvider).whenData(
              (count) => ref.watch(messageRepositoryProvider).getPendingMessages(),
            );

    // Watch connectivity
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    final isOffline = connectivityAsync.whenOrNull(
          data: (connectivity) => connectivity.name == 'none',
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Queue'),
        actions: [
          // Connectivity indicator
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingMd),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOffline
                      ? AppTheme.error.withValues(alpha: 0.1)
                      : AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: isOffline ? AppTheme.error : AppTheme.success,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOffline ? Icons.cloud_off : Icons.cloud_done,
                      size: 16,
                      color: isOffline ? AppTheme.error : AppTheme.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOffline ? 'Offline' : 'Online',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOffline ? AppTheme.error : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: pendingAsync is AsyncData
          ? FutureBuilder<List<QueuedMessageEntity>>(
              future: pendingAsync.value as Future<List<QueuedMessageEntity>>,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildMessageList(messages, isOffline);
              },
            )
          : pendingAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildMessageList(messages, isOffline);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
      bottomNavigationBar: pendingAsync is AsyncData
          ? FutureBuilder<List<QueuedMessageEntity>>(
              future: pendingAsync.value as Future<List<QueuedMessageEntity>>,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return const SizedBox.shrink();
                return _buildSyncAllButton(messages.length, isOffline);
              },
            )
          : pendingAsync.whenOrNull(
                data: (messages) {
                  if (messages.isEmpty) return const SizedBox.shrink();
                  return _buildSyncAllButton(messages.length, isOffline);
                },
              ) ??
              const SizedBox.shrink(),
    );
  }

  /// Build message list
  Widget _buildMessageList(List<QueuedMessageEntity> messages, bool isOffline) {
    // Group by status
    final pending = messages.where((m) => m.syncStatus == 'pending').toList();
    final failed = messages.where((m) => m.syncStatus == 'failed').toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Statistics card
        _buildStatisticsCard(pending.length, failed.length),

        const SizedBox(height: AppTheme.spacingLg),

        // Failed messages section
        if (failed.isNotEmpty) ...[
          _buildSectionHeader('Failed Messages', failed.length),
          const SizedBox(height: AppTheme.spacingMd),
          ...failed.map((message) => _buildQueuedMessageCard(message, true)),
          const SizedBox(height: AppTheme.spacingLg),
        ],

        // Pending messages section
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('Pending Messages', pending.length),
          const SizedBox(height: AppTheme.spacingMd),
          ...pending.map((message) => _buildQueuedMessageCard(message, false)),
        ],
      ],
    );
  }

  /// Build statistics card
  Widget _buildStatisticsCard(int pendingCount, int failedCount) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowTeal,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.schedule,
              label: 'Pending',
              value: '$pendingCount',
              color: Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.error_outline,
              label: 'Failed',
              value: '$failedCount',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: AppTheme.spacingXs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.neutral200,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.neutral700,
            ),
          ),
        ),
      ],
    );
  }

  /// Build queued message card
  Widget _buildQueuedMessageCard(QueuedMessageEntity message, bool isFailed) {
    final messageData = message.messageData;
    final messageText = messageData['message'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isFailed
              ? AppTheme.error.withValues(alpha: 0.3)
              : AppTheme.neutral200,
          width: 1.5,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: isFailed
                  ? AppTheme.error.withValues(alpha: 0.05)
                  : AppTheme.neutral50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isFailed ? Icons.error_outline : Icons.schedule,
                  color: isFailed ? AppTheme.error : AppTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFailed ? 'Failed to send' : 'Waiting to send',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFailed ? AppTheme.error : AppTheme.warning,
                        ),
                      ),
                      if (message.retryCount > 0)
                        Text(
                          'Retry attempts: ${message.retryCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatTimestamp(message.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),

          // Message content
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.neutral900,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isFailed && message.errorMessage != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: Text(
                            message.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.error,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _handleRemoveFromQueue(message.id),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXs),
                TextButton.icon(
                  onPressed: () => _handleRetryMessage(message.id),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build sync all button
  Widget _buildSyncAllButton(int messageCount, bool isOffline) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: !isOffline && !_isSyncing ? _handleSyncAll : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: _isSyncing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      'Sync All Messages ($messageCount)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowTeal,
            ),
            child: const Icon(
              Icons.cloud_done,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.neutral900,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'No pending messages to sync',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.error,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Failed to load queue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(pendingMessagesCountProvider);
              if (widget.tripId != null) {
                ref.invalidate(pendingMessagesByTripProvider(widget.tripId!));
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
