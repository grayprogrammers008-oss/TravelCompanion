import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';
import '../../data/services/sync_coordinator.dart';
import '../../data/services/priority_sync_queue.dart';

/// Sync Status Bottom Sheet
/// Displays comprehensive sync statistics, queue status, and manual controls
class SyncStatusSheet extends ConsumerStatefulWidget {
  const SyncStatusSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SyncStatusSheet(),
    );
  }

  @override
  ConsumerState<SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends ConsumerState<SyncStatusSheet> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);
    final syncStats = ref.watch(syncStatisticsProvider);
    final queueStats = ref.watch(queueStatisticsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.sync,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _getSyncStatusText(syncState.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getSyncStatusColor(syncState.status),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tab bar
          _buildTabBar(),

          // Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          const SizedBox(width: 8),
          _buildTab('Queue', 1),
          const SizedBox(width: 8),
          _buildTab('Statistics', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildQueueTab();
      case 2:
        return _buildStatisticsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    final syncState = ref.watch(syncNotifierProvider);
    final syncStats = ref.watch(syncStatisticsProvider);
    final queueStats = ref.watch(queueStatisticsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sync Controls
        _buildSectionTitle('Sync Controls'),
        const SizedBox(height: 8),
        _buildSyncControls(),
        const SizedBox(height: 24),

        // Status Summary
        _buildSectionTitle('Status Summary'),
        const SizedBox(height: 8),
        _buildStatusCard(
          'Sync Status',
          _getSyncStatusText(syncState.status),
          _getSyncStatusIcon(syncState.status),
          _getSyncStatusColor(syncState.status),
        ),
        const SizedBox(height: 8),
        _buildStatusCard(
          'Queue',
          '${queueStats.totalQueueSize} tasks',
          Icons.queue,
          queueStats.isProcessing ? Colors.blue : Colors.grey,
        ),
        const SizedBox(height: 8),
        _buildStatusCard(
          'Active Sources',
          '${syncState.activeSourcesCount} sources',
          Icons.router,
          syncState.activeSourcesCount > 0 ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 24),

        // Quick Stats
        _buildSectionTitle('Quick Stats'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'Messages Synced',
                syncStats.totalMessagesSynced.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStatCard(
                'Duplicates Skipped',
                syncStats.totalDuplicatesSkipped.toString(),
                Icons.block,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                'Conflicts Resolved',
                syncStats.totalConflictsResolved.toString(),
                Icons.merge_type,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStatCard(
                'Efficiency',
                '${(syncStats.overallEfficiency * 100).toStringAsFixed(1)}%',
                Icons.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),

        // Last Sync Time
        if (syncState.lastSyncTime != null) ...[
          const SizedBox(height: 16),
          Text(
            'Last sync: ${_formatDateTime(syncState.lastSyncTime!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildQueueTab() {
    final queueStats = ref.watch(queueStatisticsProvider);
    final currentTask = ref.watch(currentTaskProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Queue Status
        _buildSectionTitle('Queue Status'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQueueStatRow('High Priority', queueStats.highPriorityCount, Colors.red),
                const SizedBox(height: 8),
                _buildQueueStatRow('Medium Priority', queueStats.mediumPriorityCount, Colors.orange),
                const SizedBox(height: 8),
                _buildQueueStatRow('Low Priority', queueStats.lowPriorityCount, Colors.blue),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Queue Size',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${queueStats.totalQueueSize}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Current Task
        if (currentTask != null) ...[
          _buildSectionTitle('Current Task'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(currentTask.type),
              subtitle: Text('Trip: ${currentTask.tripId}'),
              trailing: Chip(
                label: Text(
                  currentTask.priority.name,
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: _getPriorityColor(currentTask.priority),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Queue Performance
        _buildSectionTitle('Queue Performance'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPerformanceRow('Total Queued', queueStats.totalTasksQueued),
                const SizedBox(height: 8),
                _buildPerformanceRow('Processed', queueStats.totalTasksProcessed),
                const SizedBox(height: 8),
                _buildPerformanceRow('Failed', queueStats.totalTasksFailed),
                const SizedBox(height: 8),
                _buildPerformanceRow('Retried', queueStats.totalTasksRetried),
                const Divider(height: 24),
                _buildPerformanceBar('Success Rate', queueStats.successRate, Colors.green),
                const SizedBox(height: 8),
                _buildPerformanceBar('Failure Rate', queueStats.failureRate, Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    final syncStats = ref.watch(syncStatisticsProvider);
    final dedupStats = ref.watch(deduplicationStatisticsProvider);
    final conflictStats = ref.watch(conflictStatisticsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Deduplication Stats
        _buildSectionTitle('Deduplication'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow('Total Checks', dedupStats.totalChecks),
                const SizedBox(height: 8),
                _buildStatRow('Duplicates Found', dedupStats.duplicatesFound),
                const SizedBox(height: 8),
                _buildStatRow('Unique Messages', dedupStats.uniqueMessages),
                const SizedBox(height: 8),
                _buildStatRow('Cache Size', dedupStats.cacheSize),
                const Divider(height: 24),
                _buildPerformanceBar('Duplicate Rate', dedupStats.duplicateRate, Colors.orange),
                const SizedBox(height: 8),
                _buildPerformanceBar('Cache Usage', dedupStats.cacheUsage, Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Conflict Resolution Stats
        _buildSectionTitle('Conflict Resolution'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow('Total Conflicts', conflictStats.totalConflicts),
                const SizedBox(height: 8),
                _buildStatRow('By Timestamp', conflictStats.resolvedByTimestamp),
                const SizedBox(height: 8),
                _buildStatRow('By Source', conflictStats.resolvedBySource),
                const SizedBox(height: 8),
                _buildStatRow('By Content', conflictStats.resolvedByContent),
                const SizedBox(height: 8),
                _buildStatRow('Manual', conflictStats.manualResolution),
                const Divider(height: 24),
                _buildPerformanceBar('Timestamp Rate', conflictStats.timestampRate, Colors.blue),
                const SizedBox(height: 8),
                _buildPerformanceBar('Source Rate', conflictStats.sourceRate, Colors.green),
                const SizedBox(height: 8),
                _buildPerformanceBar('Content Rate', conflictStats.contentRate, Colors.purple),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Reset button
        ElevatedButton.icon(
          onPressed: () {
            ref.read(syncNotifierProvider.notifier).resetStatistics();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Statistics reset')),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Statistics'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncControls() {
    final syncState = ref.watch(syncNotifierProvider);
    final queueIsPaused = ref.watch(queueIsPausedProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!syncState.isInitialized)
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(syncNotifierProvider.notifier).initialize();
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Initialize Sync'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: syncState.isSyncing
                          ? () => ref.read(syncNotifierProvider.notifier).stopAutoSync()
                          : () => ref.read(syncNotifierProvider.notifier).startAutoSync(),
                      icon: Icon(syncState.isSyncing ? Icons.stop : Icons.play_arrow),
                      label: Text(syncState.isSyncing ? 'Stop Auto Sync' : 'Start Auto Sync'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: syncState.isSyncing ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: queueIsPaused
                          ? () => ref.read(prioritySyncQueueProvider).resume()
                          : () => ref.read(prioritySyncQueueProvider).pause(),
                      icon: Icon(queueIsPaused ? Icons.play_circle : Icons.pause_circle),
                      label: Text(queueIsPaused ? 'Resume Queue' : 'Pause Queue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: queueIsPaused ? Colors.orange : Colors.grey[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatusCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStatRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Idle';
      case SyncStatus.initializing:
        return 'Initializing...';
      case SyncStatus.ready:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.paused:
        return 'Paused';
      case SyncStatus.error:
        return 'Error';
    }
  }

  IconData _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icons.sync_disabled;
      case SyncStatus.initializing:
        return Icons.sync;
      case SyncStatus.ready:
        return Icons.check_circle;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.paused:
        return Icons.pause_circle;
      case SyncStatus.error:
        return Icons.error;
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.initializing:
        return Colors.blue;
      case SyncStatus.ready:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.paused:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
    }
  }

  Color _getPriorityColor(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.high:
        return Colors.red[100]!;
      case SyncPriority.medium:
        return Colors.orange[100]!;
      case SyncPriority.low:
        return Colors.blue[100]!;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
