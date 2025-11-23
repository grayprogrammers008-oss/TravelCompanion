import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/sos_button.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/nearest_hospitals_widget.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/medical_emergency_button.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';

/// Emergency Service Page - Centralized emergency features
///
/// Features:
/// - SOS Alert Button (hold for 3 seconds)
/// - Find Nearest Hospitals
/// - Medical Emergency Quick Action
/// - Emergency Contacts Management (future)
/// - Location Sharing (future)
class EmergencyPage extends ConsumerWidget {
  final String? tripId;

  const EmergencyPage({
    super.key,
    this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = context.appThemeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Emergency Service Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Emergency Alert Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emergency,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Emergency Assistance',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Quick access to emergency services and help',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // SOS Alert Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Alert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: themeData.primaryShadow,
                    ),
                    child: Column(
                      children: [
                        SOSButton(
                          tripId: tripId,
                          onAlertTriggered: () {
                            // Alert triggered successfully
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: Text(
                                  'Hold the SOS button for 3 seconds to send an emergency alert to your emergency contacts.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.local_hospital,
                          title: 'Medical',
                          subtitle: 'Emergency',
                          color: Colors.red,
                          onTap: () {
                            // Medical emergency action is handled by the button itself
                          },
                          child: const MedicalEmergencyButton(
                            size: 60,
                            showLabel: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.local_police,
                          title: 'Police',
                          subtitle: 'Call 911',
                          color: Colors.blue,
                          onTap: () => _callEmergencyNumber(context, '911'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.fire_truck,
                          title: 'Fire',
                          subtitle: 'Call 911',
                          color: Colors.orange,
                          onTap: () => _callEmergencyNumber(context, '911'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.location_on,
                          title: 'Share',
                          subtitle: 'Location',
                          color: Colors.green,
                          onTap: () => _shareLocation(context, ref),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Nearest Hospitals Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearest Hospitals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Icon(
                        Icons.location_searching,
                        color: themeData.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const NearestHospitalsWidget(),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppTheme.info),
            SizedBox(width: AppTheme.spacingMd),
            Text('Emergency Services'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoItem(
                icon: Icons.sos,
                title: 'SOS Alert',
                description:
                    'Hold the SOS button for 3 seconds to send an emergency alert with your location to all your emergency contacts.',
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _InfoItem(
                icon: Icons.local_hospital,
                title: 'Medical Emergency',
                description:
                    'Quick access to medical emergency services. Tap to call emergency services or find nearest hospital.',
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _InfoItem(
                icon: Icons.location_on,
                title: 'Hospital Finder',
                description:
                    'Find nearest hospitals with emergency rooms, sorted by distance from your current location.',
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _InfoItem(
                icon: Icons.phone,
                title: 'Emergency Numbers',
                description:
                    'Quick dial buttons for police (911), fire (911), and medical emergencies.',
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        'Only use in real emergencies. Misuse may result in penalties.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _callEmergencyNumber(BuildContext context, String number) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.phone, color: AppTheme.error),
            SizedBox(width: AppTheme.spacingMd),
            Text('Call Emergency Services'),
          ],
        ),
        content: Text('Call $number for emergency assistance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final uri = Uri.parse('tel:$number');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot make phone call to $number'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error making call: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareLocation(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.info),
            SizedBox(width: AppTheme.spacingMd),
            Text('Share Live Location'),
          ],
        ),
        content: const Text(
          'Share your live location with emergency contacts?\n\n'
          'This will:\n'
          '• Share your current GPS location\n'
          '• Update location in real-time\n'
          '• Notify your emergency contacts',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.success,
            ),
            child: const Text('Share Location'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Get all emergency contacts
        final contactsAsync = await ref.read(emergencyContactsProvider.future);

        if (contactsAsync.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please add emergency contacts first'),
                backgroundColor: AppTheme.warning,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // Start location sharing with all emergency contacts
        final controller = ref.read(emergencyControllerProvider.notifier);
        final contactIds = contactsAsync.map((c) => c.id).toList();
        await controller.startLocationSharing(
          contactIds: contactIds,
          tripId: tripId,
          message: 'Emergency location sharing activated',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sharing location with ${contactsAsync.length} contacts'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share location: $e'),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}

/// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final Widget? child;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: themeData.primaryShadow,
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: child ??
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
      ),
    );
  }
}

/// Info Item Widget for dialog
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            color: AppTheme.info,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing2xs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
