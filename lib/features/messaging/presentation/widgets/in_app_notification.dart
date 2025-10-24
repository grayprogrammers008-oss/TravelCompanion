import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/notification_payload.dart';
import '../pages/chat_screen.dart';
import '../providers/notification_provider.dart';

/// In-App Notification Banner
/// Shows a banner at the top when a notification is received while app is active
class InAppNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const InAppNotificationListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<InAppNotificationListener> createState() =>
      _InAppNotificationListenerState();
}

class _InAppNotificationListenerState
    extends ConsumerState<InAppNotificationListener> {
  OverlayEntry? _overlayEntry;
  NotificationPayload? _currentNotification;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to notification state
    ref.listen<NotificationState>(notificationStateProvider, (previous, next) {
      // Show banner for new notification
      if (next.lastNotification != null &&
          next.lastNotification != previous?.lastNotification) {
        _showNotificationBanner(next.lastNotification!);
      }

      // Handle notification tap
      if (next.tappedNotification != null &&
          next.tappedNotification != previous?.tappedNotification) {
        _handleNotificationTap(next.tappedNotification!);
      }
    });

    return widget.child;
  }

  /// Show notification banner
  void _showNotificationBanner(NotificationPayload payload) {
    // Remove existing overlay
    _removeOverlay();

    _currentNotification = payload;

    // Create overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: _NotificationBanner(
            payload: payload,
            onTap: () {
              _removeOverlay();
              _handleNotificationTap(payload);
            },
            onDismiss: _removeOverlay,
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_overlayEntry!);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentNotification == payload) {
        _removeOverlay();
      }
    });
  }

  /// Remove overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentNotification = null;

    // Clear last notification from state
    ref.read(notificationStateProvider.notifier).clearLastNotification();
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationPayload payload) {
    // Navigate to chat screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          tripId: payload.tripId,
          tripName: payload.tripName,
          currentUserId: '', // TODO: Get from auth provider
        ),
      ),
    );

    // Clear tapped notification
    ref.read(notificationStateProvider.notifier).clearTappedNotification();
  }
}

/// Notification Banner Widget
class _NotificationBanner extends StatefulWidget {
  final NotificationPayload payload;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.payload,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy < -500) {
              _dismiss();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.shadowLg,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryPale,
                  backgroundImage: widget.payload.senderAvatarUrl != null
                      ? NetworkImage(widget.payload.senderAvatarUrl!)
                      : null,
                  child: widget.payload.senderAvatarUrl == null
                      ? Text(
                          widget.payload.senderName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryTeal,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: AppTheme.spacingSm),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payload.getTitle(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.payload.getBody(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.neutral600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacingSm),

                // Dismiss button
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: AppTheme.neutral400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
