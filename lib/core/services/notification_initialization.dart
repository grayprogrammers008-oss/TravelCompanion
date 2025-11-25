import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/messaging/data/services/fcm_service.dart';
import '../services/fcm_token_manager.dart';

/// Notification Service Initialization
/// Handles FCM service initialization and token registration
class NotificationInitialization {
  static bool _isInitialized = false;

  /// Initialize notification services
  /// Call this after user authentication
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ [NotificationInit] Already initialized');
      return;
    }

    try {
      debugPrint('🔵 [NotificationInit] Initializing notification services...');

      // Initialize FCM service
      final fcmService = FCMService();
      await fcmService.initialize();
      debugPrint('   ✅ FCM service initialized');

      // Register FCM token with Supabase (if user is authenticated)
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final tokenManager = FCMTokenManager(
          supabase,
          FirebaseMessaging.instance,
        );
        await tokenManager.registerToken();
        debugPrint('   ✅ FCM token registered');

        // Listen to token refresh
        tokenManager.listenToTokenRefresh();
        debugPrint('   ✅ Token refresh listener activated');
      } else {
        debugPrint('   ⚠️ User not authenticated, skipping token registration');
      }

      _isInitialized = true;
      debugPrint('✅ [NotificationInit] Notification services initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ [NotificationInit] Initialization failed');
      debugPrint('   Exception: $e');
      debugPrint('   Stack Trace: $stackTrace');
      // Don't rethrow - notifications are not critical
    }
  }

  /// Register FCM token for authenticated user
  /// Call this after successful login
  static Future<void> registerToken() async {
    try {
      debugPrint('🔵 [NotificationInit] Registering FCM token...');

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('   ⚠️ User not authenticated');
        return;
      }

      final tokenManager = FCMTokenManager(
        supabase,
        FirebaseMessaging.instance,
      );
      await tokenManager.registerToken();
      debugPrint('   ✅ FCM token registered for user: ${user.id}');
    } catch (e) {
      debugPrint('   ❌ Failed to register FCM token: $e');
    }
  }

  /// Unregister FCM token
  /// Call this on logout
  static Future<void> unregisterToken() async {
    try {
      debugPrint('🔵 [NotificationInit] Unregistering FCM token...');

      final supabase = Supabase.instance.client;
      final tokenManager = FCMTokenManager(
        supabase,
        FirebaseMessaging.instance,
      );
      await tokenManager.unregisterToken();
      debugPrint('   ✅ FCM token unregistered');

      _isInitialized = false;
    } catch (e) {
      debugPrint('   ❌ Failed to unregister FCM token: $e');
    }
  }

  /// Check if notification services are initialized
  static bool get isInitialized => _isInitialized;

  /// Reset initialization state (for testing)
  @visibleForTesting
  static void resetInitialization() {
    _isInitialized = false;
  }
}
