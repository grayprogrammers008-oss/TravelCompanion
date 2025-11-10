import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// FCM Token Manager
/// Handles registration and management of FCM tokens in Supabase
class FCMTokenManager {
  final SupabaseClient _supabase;
  final FirebaseMessaging _firebaseMessaging;

  FCMTokenManager(this._supabase, this._firebaseMessaging);

  /// Register FCM token for current user
  Future<void> registerToken() async {
    try {
      debugPrint('🔔 [FCMTokenManager] Registering FCM token...');

      // Get FCM token
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null) {
        debugPrint('⚠️ [FCMTokenManager] No FCM token available');
        return;
      }

      debugPrint('   Token: ${fcmToken.substring(0, 20)}...');

      // Get device info
      final deviceId = await _getDeviceId();
      final deviceType = _getDeviceType();

      debugPrint('   Device ID: $deviceId');
      debugPrint('   Device Type: $deviceType');

      // Register token in Supabase
      final response = await _supabase.rpc(
        'register_fcm_token',
        params: {
          'p_fcm_token': fcmToken,
          'p_device_id': deviceId,
          'p_device_type': deviceType,
        },
      );

      debugPrint('✅ [FCMTokenManager] Token registered: $response');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCMTokenManager] Failed to register token: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  /// Unregister FCM token for current device
  Future<void> unregisterToken() async {
    try {
      debugPrint('🔕 [FCMTokenManager] Unregistering FCM token...');

      final deviceId = await _getDeviceId();

      await _supabase.rpc(
        'unregister_fcm_token',
        params: {
          'p_device_id': deviceId,
        },
      );

      debugPrint('✅ [FCMTokenManager] Token unregistered');
    } catch (e) {
      debugPrint('❌ [FCMTokenManager] Failed to unregister token: $e');
    }
  }

  /// Get unique device ID
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique Android ID
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else {
      return 'web_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get device type
  String _getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'web';
    }
  }

  /// Listen to token refresh and update in Supabase
  void listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 [FCMTokenManager] Token refreshed');
      registerToken();
    });
  }
}
