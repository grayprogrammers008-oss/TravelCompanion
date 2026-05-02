import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/emergency_providers.dart';

/// SOS Button Widget - Emergency alert trigger button
///
/// Features:
/// - Hold-to-activate mechanism for accidental trigger prevention
/// - Visual feedback during activation
/// - Customizable size and appearance
/// - Automatic location capture
class SOSButton extends ConsumerStatefulWidget {
  final String? tripId;
  final VoidCallback? onAlertTriggered;
  final VoidCallback? onAlertCancelled;
  final double size;
  final bool showLabel;

  const SOSButton({
    super.key,
    this.tripId,
    this.onAlertTriggered,
    this.onAlertCancelled,
    this.size = 120.0,
    this.showLabel = true,
  });

  @override
  ConsumerState<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends ConsumerState<SOSButton>
    with SingleTickerProviderStateMixin {
  bool _isHolding = false;
  double _holdProgress = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _holdProgressTimer;

  static const Duration _holdDuration = Duration(seconds: 3);
  DateTime? _holdStartTime;

  @override
  void initState() {
    super.initState();

    // Pulse animation for visual feedback
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Stop the hold-progress recursive timer loop so it doesn't continue
    // scheduling itself after the widget is unmounted (which would leave
    // a pending timer and fail tests with the "pending Timer" error).
    _isHolding = false;
    _holdStartTime = null;
    _holdProgressTimer?.cancel();
    _holdProgressTimer = null;
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressStart() {
    setState(() {
      _isHolding = true;
      _holdStartTime = DateTime.now();
    });

    // Update progress every 50ms
    _updateHoldProgress();
  }

  void _updateHoldProgress() {
    if (!mounted || !_isHolding || _holdStartTime == null) return;

    final elapsed = DateTime.now().difference(_holdStartTime!);
    final progress = elapsed.inMilliseconds / _holdDuration.inMilliseconds;

    setState(() {
      _holdProgress = progress.clamp(0.0, 1.0);
    });

    if (progress >= 1.0) {
      _holdProgressTimer?.cancel();
      _holdProgressTimer = null;
      _triggerSOS();
    } else {
      // Use a cancellable Timer (rather than Future.delayed) so dispose() can
      // tear it down cleanly when the widget is unmounted mid-hold during
      // tests. Otherwise the recursive scheduling leaves a pending Timer.
      _holdProgressTimer?.cancel();
      _holdProgressTimer = Timer(
        const Duration(milliseconds: 50),
        _updateHoldProgress,
      );
    }
  }

  void _onPressEnd() {
    _holdProgressTimer?.cancel();
    _holdProgressTimer = null;
    setState(() {
      _isHolding = false;
      _holdStartTime = null;
      _holdProgress = 0.0;
    });
  }

  Future<void> _triggerSOS() async {
    try {
      final controller = ref.read(emergencyControllerProvider.notifier);

      // Get current location (placeholder - should integrate with location service)
      const double? latitude = null;
      const double? longitude = null;

      await controller.triggerSOS(
        tripId: widget.tripId,
        message: 'Emergency! Need immediate assistance.',
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
        widget.onAlertTriggered?.call();

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'SOS alert sent to your emergency contacts!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    'Failed to send SOS: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _holdProgressTimer?.cancel();
      _holdProgressTimer = null;
      if (mounted) {
        setState(() {
          _isHolding = false;
          _holdStartTime = null;
          _holdProgress = 0.0;
        });
      } else {
        _isHolding = false;
        _holdStartTime = null;
        _holdProgress = 0.0;
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
          onLongPressStart: (_) => _onPressStart(),
          onLongPressEnd: (_) => _onPressEnd(),
          onLongPressCancel: _onPressEnd,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5 * _pulseAnimation.value),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress indicator
                    if (_isHolding)
                      SizedBox(
                        width: widget.size - 10,
                        height: widget.size - 10,
                        child: CircularProgressIndicator(
                          value: _holdProgress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),

                    // SOS Icon and Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sos,
                          size: widget.size * 0.4,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.size * 0.15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    // Loading overlay
                    if (state.isTriggeringAlert)
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
            _isHolding ? 'Hold to send...' : 'Hold for 3 seconds',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),

          if (_isHolding) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '${((_holdDuration.inMilliseconds * (1 - _holdProgress)) / 1000).ceil()}s',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Compact SOS Button for navigation bars or floating action buttons
class CompactSOSButton extends ConsumerWidget {
  final String? tripId;
  final VoidCallback? onAlertTriggered;

  const CompactSOSButton({
    super.key,
    this.tripId,
    this.onAlertTriggered,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showSOSDialog(context, ref),
      backgroundColor: Colors.red.shade600,
      child: const Icon(
        Icons.sos,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showSOSDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: AppTheme.spacingMd),
            Text('Emergency SOS'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will send an emergency alert to all your emergency contacts.',
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Only use in real emergencies!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final controller =
                    ref.read(emergencyControllerProvider.notifier);
                await controller.triggerSOS(tripId: tripId);
                onAlertTriggered?.call();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SOS alert sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send SOS: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }
}
