import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

/// Admin Activity Log List Widget
/// Displays list of admin actions and activities
class AdminActivityLogList extends ConsumerStatefulWidget {
  const AdminActivityLogList({super.key});

  @override
  ConsumerState<AdminActivityLogList> createState() =>
      _AdminActivityLogListState();
}

class _AdminActivityLogListState extends ConsumerState<AdminActivityLogList> {
  int _currentPage = 0;

  ActivityLogParams get _currentParams => ActivityLogParams(
        limit: 50,
        offset: _currentPage * 50,
      );

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminActivityLogsProvider(_currentParams));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  'No activity logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Activity will appear here when admins take actions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminActivityLogsProvider(_currentParams));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: logs.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppTheme.spacingMd),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildActivityCard(context, log);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Failed to load activity logs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(adminActivityLogsProvider(_currentParams));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, log) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: _getActionColor(log.actionType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                log.actionType.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.actionType.displayName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Text(
                        log.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    log.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (log.metadata.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildMetadata(context, log.metadata),
                  ],
                  if (log.ipAddress != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.ipAddress!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getActionColor(actionType) {
    switch (actionType.toString()) {
      case 'AdminActionType.userCreated':
        return Colors.green;
      case 'AdminActionType.userUpdated':
        return Colors.blue;
      case 'AdminActionType.userSuspended':
        return Colors.orange;
      case 'AdminActionType.userActivated':
        return Colors.teal;
      case 'AdminActionType.userDeleted':
        return Colors.red;
      case 'AdminActionType.roleChanged':
        return Colors.purple;
      case 'AdminActionType.passwordReset':
        return Colors.amber;
      case 'AdminActionType.profileUpdated':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
