import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/emergency_providers.dart';

/// Medical Emergency Button Widget - Triggers medical emergency alert
///
/// Features:
/// - Tap-to-activate for quick medical emergency response
/// - Visual feedback during activation
/// - Customizable size and appearance
/// - Integrates with emergency controller
/// - Captures GPS location automatically
class MedicalEmergencyButton extends ConsumerStatefulWidget {
  final String? tripId;
  final double size;
  final bool showLabel;
  final VoidCallback? onAlertTriggered;

  const MedicalEmergencyButton({
    super.key,
    this.tripId,
    this.size = 120,
    this.showLabel = true,
    this.onAlertTriggered,
  });

  @override
  ConsumerState<MedicalEmergencyButton> createState() =>
      _MedicalEmergencyButtonState();
}

class _MedicalEmergencyButtonState
    extends ConsumerState<MedicalEmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red.shade700),
            const SizedBox(width: AppTheme.spacingSm),
            const Text('Medical Emergency'),
          ],
        ),
        content: const Text(
          'Are you experiencing a medical emergency?\n\n'
          'This will:\n'
          '• Alert your emergency contacts\n'
          '• Share your current location\n'
          '• Notify local emergency services if configured',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM EMERGENCY'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isConfirming = true);

      try {
        final controller = ref.read(emergencyControllerProvider.notifier);
        await controller.triggerMedicalAlert(
          tripId: widget.tripId,
          message: 'Medical emergency assistance needed',
        );

        if (mounted) {
          setState(() => _isConfirming = false);
          widget.onAlertTriggered?.call();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical emergency alert sent to your contacts'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isConfirming = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send alert: $e'),
              backgroundColor: Colors.red.shade900,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emergencyControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: (state.isTriggeringAlert || _isConfirming) ? null : _handleTap,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade700,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4 * _pulseAnimation.value),
                      blurRadius: 15 * _pulseAnimation.value,
                      spreadRadius: 4 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Medical Icon and Text
                    if (!_isConfirming && !state.isTriggeringAlert)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: widget.size * 0.4,
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            'MEDICAL',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ],
                      ),

                    // Loading overlay
                    if (_isConfirming || state.isTriggeringAlert)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        if (widget.showLabel) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Medical Emergency',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Tap for immediate help',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
          ),
        ],
      ],
    );
  }
}
