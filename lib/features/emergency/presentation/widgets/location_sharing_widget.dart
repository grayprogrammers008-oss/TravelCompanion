import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/location_share_model.dart';
import '../providers/emergency_providers.dart';

/// Location Sharing Management Widget
///
/// Features:
/// - View active location sharing sessions
/// - Stop location sharing
/// - View who you're sharing with
/// - Real-time updates
/// - Shows duration and last update time
class LocationSharingWidget extends ConsumerWidget {
  const LocationSharingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShareAsync = ref.watch(activeLocationShareProvider);

    return activeShareAsync.when(
      data: (locationShare) {
        if (locationShare == null) {
          return _buildNoActiveShare(context, ref);
        }
        return _buildActiveShare(context, ref, locationShare);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spacingMd),
            Text('Loading location sharing status...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Error Loading Location Share',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveShare(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Not Sharing Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'You are not currently sharing your location with anyone.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveShare(
    BuildContext context,
    WidgetRef ref,
    LocationShareModel locationShare,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Sharing Location',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Your real-time location is being shared',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Location Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInfoRow(
                    context,
                    Icons.gps_fixed,
                    'Coordinates',
                    '${locationShare.latitude.toStringAsFixed(6)}, ${locationShare.longitude.toStringAsFixed(6)}',
                  ),
                  if (locationShare.accuracy != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildInfoRow(
                      context,
                      Icons.adjust,
                      'Accuracy',
                      '±${locationShare.accuracy!.toStringAsFixed(1)}m',
                    ),
                  ],
                  if (locationShare.speed != null && locationShare.speed! > 0) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildInfoRow(
                      context,
                      Icons.speed,
                      'Speed',
                      '${(locationShare.speed! * 3.6).toStringAsFixed(1)} km/h',
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingSm),
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    'Last Updated',
                    _formatTimeSince(locationShare.timeSinceLastUpdate),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Sharing Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sharing With',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInfoRow(
                    context,
                    Icons.people,
                    'Contacts',
                    '${locationShare.sharedWithContactIds.length} people',
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    'Started',
                    dateFormat.format(locationShare.startedAt),
                  ),
                  if (locationShare.expiresAt != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildInfoRow(
                      context,
                      Icons.timer_off,
                      'Expires',
                      dateFormat.format(locationShare.expiresAt!),
                    ),
                  ],
                  if (locationShare.message != null) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.message,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Text(
                              locationShare.message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Stop Sharing Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showStopSharingDialog(context, ref, locationShare.id),
              icon: const Icon(Icons.stop),
              label: const Text('Stop Sharing Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} seconds ago';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minute${duration.inMinutes != 1 ? 's' : ''} ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours != 1 ? 's' : ''} ago';
    } else {
      return '${duration.inDays} day${duration.inDays != 1 ? 's' : ''} ago';
    }
  }

  Future<void> _showStopSharingDialog(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.stop_circle, color: AppTheme.error),
            SizedBox(width: AppTheme.spacingMd),
            Text('Stop Sharing Location'),
          ],
        ),
        content: const Text(
          'Are you sure you want to stop sharing your location?\n\n'
          'Your emergency contacts will no longer be able to see your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final controller = ref.read(emergencyControllerProvider.notifier);
        await controller.stopLocationSharing(sessionId);

        // Invalidate the provider to refresh
        ref.invalidate(activeLocationShareProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location sharing stopped successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to stop sharing: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}
