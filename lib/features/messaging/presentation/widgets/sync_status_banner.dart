import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/messaging_providers.dart';

/// Sync Status Banner
/// Shows offline status and pending message count
class SyncStatusBanner extends ConsumerWidget {
  final VoidCallback? onSyncTap;

  const SyncStatusBanner({
    super.key,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final pendingAsync = ref.watch(pendingMessagesCountProvider);

    return connectivityAsync.when(
      data: (connectivityList) {
        final isOffline = connectivityList.contains(ConnectivityResult.none) || connectivityList.isEmpty;

        if (!isOffline) {
          // Online - show pending count if any
          return pendingAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();

              return _buildBanner(
                context: context,
                icon: Icons.cloud_upload,
                color: AppTheme.warning,
                title: 'Syncing messages...',
                subtitle: '$count message${count > 1 ? 's' : ''} pending',
                actionLabel: 'Sync Now',
                onActionTap: onSyncTap,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
        } else {
          // Offline - show offline banner
          return pendingAsync.when(
            data: (count) {
              return _buildBanner(
                context: context,
                icon: Icons.cloud_off,
                color: AppTheme.error,
                title: 'You\'re offline',
                subtitle: count > 0
                    ? '$count message${count > 1 ? 's' : ''} will be sent when online'
                    : 'Messages will be sent when connection is restored',
                actionLabel: null,
                onActionTap: null,
              );
            },
            loading: () => _buildBanner(
              context: context,
              icon: Icons.cloud_off,
              color: AppTheme.error,
              title: 'You\'re offline',
              subtitle: 'Messages will be sent when connection is restored',
              actionLabel: null,
              onActionTap: null,
            ),
            error: (_, __) => const SizedBox.shrink(),
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral700,
                      ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}
