import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/messaging/domain/entities/notification_payload.dart';

/// Test utility for sending sample notifications
/// Use this to manually test push notifications during development
class NotificationTestHelper {
  final SupabaseClient _supabase;

  NotificationTestHelper(this._supabase);

  /// Send a test trip update notification
  Future<Map<String, dynamic>> sendTestTripUpdateNotification({
    required String tripId,
    required String tripName,
    String? userId,
    String? userName,
  }) async {
    try {
      debugPrint('📤 Sending test trip update notification...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final payload = NotificationPayload(
        type: 'trip_updated',
        tripId: tripId,
        tripName: tripName,
        senderId: userId ?? currentUser.id,
        senderName: userName ?? 'Test User',
        updatedField: 'name',
      );

      final response = await _supabase.functions.invoke(
        'send-trip-notification',
        body: {
          'trip_id': tripId,
          'payload': payload.toJson(),
          'exclude_user_id': currentUser.id, // Don't send to self
        },
      );

      debugPrint('✅ Test notification sent: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send test notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send a test member added notification
  Future<Map<String, dynamic>> sendTestMemberAddedNotification({
    required String tripId,
    required String tripName,
    required String memberName,
  }) async {
    try {
      debugPrint('📤 Sending test member added notification...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final payload = NotificationPayload(
        type: 'member_added',
        tripId: tripId,
        tripName: tripName,
        senderId: currentUser.id,
        memberName: memberName,
      );

      final response = await _supabase.functions.invoke(
        'send-trip-notification',
        body: {
          'trip_id': tripId,
          'payload': payload.toJson(),
          'exclude_user_id': currentUser.id,
        },
      );

      debugPrint('✅ Test notification sent: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send test notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Send a test new message notification
  Future<Map<String, dynamic>> sendTestNewMessageNotification({
    required String tripId,
    required String tripName,
    required String messageText,
  }) async {
    try {
      debugPrint('📤 Sending test new message notification...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final payload = NotificationPayload(
        type: 'new_message',
        tripId: tripId,
        tripName: tripName,
        senderId: currentUser.id,
        senderName: 'Test User',
        messageText: messageText,
      );

      final response = await _supabase.functions.invoke(
        'send-trip-notification',
        body: {
          'trip_id': tripId,
          'payload': payload.toJson(),
          'exclude_user_id': currentUser.id,
        },
      );

      debugPrint('✅ Test notification sent: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send test notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Verify FCM token is registered for current user
  Future<bool> verifyFCMTokenRegistered() async {
    try {
      debugPrint('🔍 Checking FCM token registration...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('   ⚠️ User not authenticated');
        return false;
      }

      final response = await _supabase
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_active', true);

      if (response.isEmpty) {
        debugPrint('   ⚠️ No active FCM tokens found');
        return false;
      }

      debugPrint('   ✅ Found ${response.length} active FCM token(s)');
      for (var token in response) {
        debugPrint('   - Device: ${token['device_type']} (${token['device_id']})');
        debugPrint('   - Token: ${token['fcm_token'].substring(0, 20)}...');
        debugPrint('   - Last used: ${token['last_used_at']}');
      }

      return true;
    } catch (e) {
      debugPrint('   ❌ Failed to verify FCM token: $e');
      return false;
    }
  }

  /// Get all trip members for a trip (useful for testing notifications)
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    try {
      debugPrint('🔍 Fetching trip members for trip: $tripId');

      final response = await _supabase
          .from('trip_members')
          .select('user_id, profiles:user_id(full_name, email)')
          .eq('trip_id', tripId);

      debugPrint('   ✅ Found ${response.length} member(s)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('   ❌ Failed to fetch trip members: $e');
      rethrow;
    }
  }

  /// Test the Supabase edge function directly
  Future<Map<String, dynamic>> testEdgeFunctionConnection() async {
    try {
      debugPrint('🧪 Testing Supabase edge function connection...');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Send a minimal test payload
      final testPayload = {
        'type': 'test',
        'trip_id': 'test-trip-id',
        'trip_name': 'Test Trip',
        'sender_id': currentUser.id,
        'sender_name': 'Test User',
      };

      final response = await _supabase.functions.invoke(
        'send-trip-notification',
        body: {
          'trip_id': 'test-trip-id',
          'payload': testPayload,
          'exclude_user_id': currentUser.id,
        },
      );

      debugPrint('✅ Edge function responded: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('❌ Edge function test failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if edge function is deployed
  Future<bool> isEdgeFunctionDeployed() async {
    try {
      debugPrint('🔍 Checking if edge function is deployed...');

      await testEdgeFunctionConnection();
      debugPrint('   ✅ Edge function is deployed and accessible');
      return true;
    } catch (e) {
      debugPrint('   ⚠️ Edge function is not deployed or not accessible');
      debugPrint('   Error: $e');
      return false;
    }
  }

  /// Print debugging information for notification setup
  Future<void> printNotificationDebugInfo() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════');
    debugPrint('📋 Notification System Debug Info');
    debugPrint('═══════════════════════════════════════');

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('⚠️  User not authenticated');
      return;
    }

    debugPrint('👤 User ID: ${currentUser.id}');
    debugPrint('📧 Email: ${currentUser.email}');
    debugPrint('');

    // Check FCM token
    final hasToken = await verifyFCMTokenRegistered();
    debugPrint('🔔 FCM Token Registered: ${hasToken ? "✅ Yes" : "❌ No"}');
    debugPrint('');

    // Check edge function
    final isDeployed = await isEdgeFunctionDeployed();
    debugPrint('⚙️  Edge Function Deployed: ${isDeployed ? "✅ Yes" : "❌ No"}');
    debugPrint('');

    debugPrint('═══════════════════════════════════════');
    debugPrint('');
  }
}
