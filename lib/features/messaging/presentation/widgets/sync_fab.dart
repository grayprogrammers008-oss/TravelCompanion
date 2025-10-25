import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../pages/message_queue_screen.dart';
import '../providers/messaging_providers.dart';

/// Sync Floating Action Button
/// Shows pending message count and opens queue management screen
class SyncFab extends ConsumerWidget {
  final String? tripId;

  const SyncFab({
    super.key,
    this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch pending messages count
    final pendingAsync = tripId != null
        ? ref.watch(pendingMessagesByTripProvider(tripId!))
        : ref.watch(pendingMessagesCountProvider);

    // Watch connectivity
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    final isOffline = connectivityAsync.whenOrNull(
          data: (connectivityList) => connectivityList.contains(ConnectivityResult.none) || connectivityList.isEmpty,
        ) ??
        false;

    return Builder(
      builder: (builderContext) {
        return pendingAsync.when(
          data: (messages) {
            final count = messages is int ? messages : (messages as List).length;

            if (count == 0) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageQueueScreen(tripId: tripId),
                  ),
                );
              },
              backgroundColor: isOffline ? AppTheme.warning : Theme.of(builderContext).colorScheme.primary,
              icon: Icon(
                isOffline ? Icons.cloud_off : Icons.cloud_upload,
              ),
              label: Row(
                children: [
                  Text(
                    '$count pending',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(builderContext).colorScheme.surface.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }
}
