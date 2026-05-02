import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/messaging/data/services/fcm_service.dart';
import '../services/fcm_token_manager.dart';

/// Notification Service Initialization
/// Handles FCM service initialization and token registration
class NotificationInitialization {
  static bool _isInitialized = false;

  /// Initialize notification services
  /// Call this after user authentication
  static Future<void> initialize({SupabaseClient? supabaseClient}) async {
    // Skip on web - Firebase not configured
    if (kIsWeb) {
      debugPrint('ℹ️ [NotificationInit] Skipped on web (Firebase not configured)');
      return;
    }

    // Always reset state first to handle app restarts in debug mode
    // This prevents stale singleton state from causing crashes
    final fcmService = FCMService();
    fcmService.reset();
    _isInitialized = false;

    try {
      debugPrint('🔵 [NotificationInit] Initializing notification services...');

      // Initialize FCM service
      await fcmService.initialize();
      debugPrint('   ✅ FCM service initialized');

      // Register FCM token with Supabase (if user is authenticated)
      final supabase = supabaseClient ?? Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Use FCMService's lazy-initialized FirebaseMessaging instance
        final tokenManager = FCMTokenManager(
          supabase,
          fcmService.firebaseMessaging,
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
  static Future<void> registerToken({SupabaseClient? supabaseClient}) async {
    // Skip on web
    if (kIsWeb) return;

    try {
      debugPrint('🔵 [NotificationInit] Registering FCM token...');

      // Check if Firebase is initialized before proceeding
      try {
        Firebase.app();
      } catch (e) {
        debugPrint('   ⚠️ Firebase not initialized, skipping token registration');
        return;
      }

      final supabase = supabaseClient ?? Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('   ⚠️ User not authenticated');
        return;
      }

      // Use FCMService's lazy-initialized FirebaseMessaging instance
      final fcmService = FCMService();
      final tokenManager = FCMTokenManager(
        supabase,
        fcmService.firebaseMessaging,
      );
      await tokenManager.registerToken();
      debugPrint('   ✅ FCM token registered for user: ${user.id}');
    } catch (e) {
      debugPrint('   ❌ Failed to register FCM token: $e');
    }
  }

  /// Unregister FCM token
  /// Call this on logout
  static Future<void> unregisterToken({SupabaseClient? supabaseClient}) async {
    // Skip on web
    if (kIsWeb) return;

    try {
      debugPrint('🔵 [NotificationInit] Unregistering FCM token...');

      // Check if Firebase is initialized before proceeding
      try {
        Firebase.app();
      } catch (e) {
        debugPrint('   ⚠️ Firebase not initialized, skipping token unregistration');
        return;
      }

      // Use FCMService's lazy-initialized FirebaseMessaging instance
      final fcmService = FCMService();
      final supabase = supabaseClient ?? Supabase.instance.client;
      final tokenManager = FCMTokenManager(
        supabase,
        fcmService.firebaseMessaging,
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
