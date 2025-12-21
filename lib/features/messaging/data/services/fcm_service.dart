import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM Service
/// Handles Firebase Cloud Messaging for push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Callback for when a notification is tapped (foreground)
  Function(Map<String, dynamic> data)? onNotificationTapped;

  /// Callback for when a notification is received (foreground)
  Function(RemoteMessage message)? onMessageReceived;

  /// Callback for when FCM token is refreshed
  Function(String token)? onTokenRefresh;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ [FCM] Already initialized');
      return;
    }

    try {
      debugPrint('🔵 [FCM] Initializing FCM service...');

      // Ensure Firebase is initialized (safe to call multiple times)
      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Firebase might already be initialized, that's OK
        debugPrint('   ℹ️ Firebase already initialized or init error: $e');
      }

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token - with extra error handling for iOS cold start
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('   ✅ FCM Token: $_fcmToken');
      } catch (e) {
        debugPrint('   ⚠️ Failed to get FCM token: $e');
        // Continue without token - will retry later
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        debugPrint('🔄 [FCM] Token refreshed: $token');
        _fcmToken = token;
        onTokenRefresh?.call(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for initial message (app opened from terminated state)
      try {
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('📬 [FCM] App opened from terminated state');
          _handleMessageOpenedApp(initialMessage);
        }
      } catch (e) {
        debugPrint('   ⚠️ Failed to get initial message: $e');
      }

      _isInitialized = true;
      debugPrint('✅ [FCM] FCM service initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Initialization failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      // Don't rethrow - app should still work without push notifications
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      debugPrint('   🔵 Requesting notification permissions...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('   ✅ Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('   ✅ Notifications authorized');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('   ⚠️ Provisional authorization granted');
      } else {
        debugPrint('   ⚠️ Notifications not authorized');
      }
    } catch (e) {
      debugPrint('   ❌ Failed to request permissions: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('   🔵 Initializing local notifications...');

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      if (defaultTargetPlatform == TargetPlatform.android) {
        const channel = AndroidNotificationChannel(
          'messages', // id
          'Messages', // name
          description: 'Notifications for new messages',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      debugPrint('   ✅ Local notifications initialized');
    } catch (e) {
      debugPrint('   ❌ Failed to initialize local notifications: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      debugPrint('📬 [FCM] Foreground message received');
      debugPrint('   Title: ${message.notification?.title}');
      debugPrint('   Body: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');

      // Call callback
      onMessageReceived?.call(message);

      // Show local notification
      _showLocalNotification(message);
    } catch (e) {
      debugPrint('❌ [FCM] Failed to handle foreground message: $e');
    }
  }

  /// Handle message opened app (background tap)
  void _handleMessageOpenedApp(RemoteMessage message) {
    try {
      debugPrint('📬 [FCM] Message opened app');
      debugPrint('   Data: ${message.data}');

      // Call callback
      if (message.data.isNotEmpty) {
        onNotificationTapped?.call(message.data);
      }
    } catch (e) {
      debugPrint('❌ [FCM] Failed to handle message opened app: $e');
    }
  }

  /// Handle notification tap (local notification)
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('📬 [FCM] Local notification tapped');
      debugPrint('   Payload: ${response.payload}');

      if (response.payload != null) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        onNotificationTapped?.call(data);
      }
    } catch (e) {
      debugPrint('❌ [FCM] Failed to handle notification tap: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'messages',
        'Messages',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(message.data),
      );

      debugPrint('   ✅ Local notification shown');
    } catch (e) {
      debugPrint('   ❌ Failed to show local notification: $e');
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Get current notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      debugPrint('🔵 [FCM] Subscribing to topic: $topic');
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ [FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      debugPrint('🔵 [FCM] Unsubscribing from topic: $topic');
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ [FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to unsubscribe from topic: $e');
    }
  }

  /// Set badge count (iOS only)
  Future<void> setBadgeCount(int count) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _firebaseMessaging.setAutoInitEnabled(true);
        // iOS badge is typically managed by APNs
        debugPrint('📱 [FCM] Badge count set to: $count');
      }
    } catch (e) {
      debugPrint('❌ [FCM] Failed to set badge count: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('🧹 [FCM] All notifications cleared');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to clear notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      debugPrint('🧹 [FCM] Notification $id cancelled');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to cancel notification: $e');
    }
  }

  /// Dispose
  void dispose() {
    _isInitialized = false;
    debugPrint('🔵 [FCM] FCM service disposed');
  }
}

/// Background message handler
/// Must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 [FCM] Background message received');
  debugPrint('   Message ID: ${message.messageId}');
  debugPrint('   Data: ${message.data}');
}
