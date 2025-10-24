import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/fcm_service.dart';
import '../../domain/entities/notification_payload.dart';

/// FCM Service Provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// FCM Token Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.read(fcmServiceProvider);
  return fcmService.fcmToken;
});

/// Notification Settings Provider
final notificationSettingsProvider =
    FutureProvider<NotificationSettings>((ref) async {
  final fcmService = ref.read(fcmServiceProvider);
  return fcmService.getNotificationSettings();
});

/// Notification State Notifier
class NotificationStateNotifier extends StateNotifier<NotificationState> {
  final FCMService _fcmService;

  NotificationStateNotifier(this._fcmService)
      : super(const NotificationState()) {
    _initialize();
  }

  /// Initialize FCM and set up listeners
  Future<void> _initialize() async {
    try {
      debugPrint('🔵 [NotificationProvider] Initializing...');

      await _fcmService.initialize();

      // Set up callbacks
      _fcmService.onMessageReceived = _handleMessageReceived;
      _fcmService.onNotificationTapped = _handleNotificationTapped;
      _fcmService.onTokenRefresh = _handleTokenRefresh;

      // Update state with token
      state = state.copyWith(
        fcmToken: _fcmService.fcmToken,
        isInitialized: true,
      );

      debugPrint('✅ [NotificationProvider] Initialized');
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Initialization failed: $e');
      state = state.copyWith(
        isInitialized: false,
        error: e.toString(),
      );
    }
  }

  /// Handle message received (foreground)
  void _handleMessageReceived(RemoteMessage message) {
    debugPrint('📬 [NotificationProvider] Message received');

    try {
      final payload = NotificationPayload.fromJson(message.data);

      state = state.copyWith(
        lastNotification: payload,
        unreadCount: state.unreadCount + 1,
      );
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Failed to parse notification: $e');
    }
  }

  /// Handle notification tapped
  void _handleNotificationTapped(Map<String, dynamic> data) {
    debugPrint('📬 [NotificationProvider] Notification tapped');

    try {
      final payload = NotificationPayload.fromJson(data);

      state = state.copyWith(
        tappedNotification: payload,
      );
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Failed to parse tapped notification: $e');
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    debugPrint('🔄 [NotificationProvider] Token refreshed');

    state = state.copyWith(fcmToken: token);
  }

  /// Subscribe to trip notifications
  Future<void> subscribeToTrip(String tripId) async {
    try {
      debugPrint('🔔 [NotificationProvider] Subscribing to trip: $tripId');

      await _fcmService.subscribeToTopic('trip_$tripId');

      final topics = [...state.subscribedTopics, 'trip_$tripId'];
      state = state.copyWith(subscribedTopics: topics);

      debugPrint('✅ [NotificationProvider] Subscribed to trip notifications');
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Failed to subscribe: $e');
    }
  }

  /// Unsubscribe from trip notifications
  Future<void> unsubscribeFromTrip(String tripId) async {
    try {
      debugPrint('🔕 [NotificationProvider] Unsubscribing from trip: $tripId');

      await _fcmService.unsubscribeFromTopic('trip_$tripId');

      final topics = state.subscribedTopics
          .where((topic) => topic != 'trip_$tripId')
          .toList();
      state = state.copyWith(subscribedTopics: topics);

      debugPrint('✅ [NotificationProvider] Unsubscribed from trip notifications');
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Failed to unsubscribe: $e');
    }
  }

  /// Clear tapped notification
  void clearTappedNotification() {
    state = state.copyWith(tappedNotification: null);
  }

  /// Clear last notification
  void clearLastNotification() {
    state = state.copyWith(lastNotification: null);
  }

  /// Reset unread count
  void resetUnreadCount() {
    state = state.copyWith(unreadCount: 0);
  }

  /// Increment unread count
  void incrementUnreadCount() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }

  /// Decrement unread count
  void decrementUnreadCount() {
    if (state.unreadCount > 0) {
      state = state.copyWith(unreadCount: state.unreadCount - 1);
    }
  }

  /// Set badge count
  Future<void> setBadgeCount(int count) async {
    try {
      await _fcmService.setBadgeCount(count);
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Failed to set badge: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _fcmService.clearAllNotifications();
      state = state.copyWith(
        unreadCount: 0,
        lastNotification: null,
      );
    } catch (e) {
      debugPrint('❌ [NotificationProvider] Failed to clear notifications: $e');
    }
  }
}

/// Notification State
class NotificationState {
  final String? fcmToken;
  final bool isInitialized;
  final String? error;
  final NotificationPayload? lastNotification;
  final NotificationPayload? tappedNotification;
  final int unreadCount;
  final List<String> subscribedTopics;

  const NotificationState({
    this.fcmToken,
    this.isInitialized = false,
    this.error,
    this.lastNotification,
    this.tappedNotification,
    this.unreadCount = 0,
    this.subscribedTopics = const [],
  });

  NotificationState copyWith({
    String? fcmToken,
    bool? isInitialized,
    String? error,
    NotificationPayload? lastNotification,
    NotificationPayload? tappedNotification,
    int? unreadCount,
    List<String>? subscribedTopics,
  }) {
    return NotificationState(
      fcmToken: fcmToken ?? this.fcmToken,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      lastNotification: lastNotification,
      tappedNotification: tappedNotification,
      unreadCount: unreadCount ?? this.unreadCount,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
    );
  }
}

/// Notification State Provider
final notificationStateProvider =
    StateNotifierProvider<NotificationStateNotifier, NotificationState>((ref) {
  final fcmService = ref.read(fcmServiceProvider);
  return NotificationStateNotifier(fcmService);
});
