/// Manual Test Script for Firebase Push Notifications
///
/// This script demonstrates how to manually test Firebase push notifications.
/// Run this script after logging in to test the notification system.
///
/// Usage:
/// 1. Deploy the Supabase edge function: `supabase functions deploy send-trip-notification`
/// 2. Run the migration: `supabase db push`
/// 3. Set the FCM_SERVER_KEY: `supabase secrets set FCM_SERVER_KEY=your_key`
/// 4. Run this test in the app after authentication
///
/// Example:
/// ```dart
/// // In your app, after login:
/// final helper = NotificationTestHelper(Supabase.instance.client);
/// await helper.printNotificationDebugInfo();
/// await helper.sendTestTripUpdateNotification(
///   tripId: 'your-trip-id',
///   tripName: 'Test Trip',
/// );
/// ```
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/notification_test_helper.dart';

class FirebaseNotificationManualTest {
  static Future<void> runComprehensiveTest() async {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║  Firebase Push Notifications - Manual Test Suite      ║');
    debugPrint('╚════════════════════════════════════════════════════════╝');
    debugPrint('');

    final supabase = Supabase.instance.client;
    final helper = NotificationTestHelper(supabase);

    // Step 1: Print debug info
    debugPrint('📋 Step 1: System Diagnostic');
    debugPrint('─────────────────────────────────────────────────────────');
    await helper.printNotificationDebugInfo();

    // Step 2: Verify FCM token
    debugPrint('📋 Step 2: Verify FCM Token Registration');
    debugPrint('─────────────────────────────────────────────────────────');
    final hasToken = await helper.verifyFCMTokenRegistered();
    if (!hasToken) {
      debugPrint('❌ FAILED: FCM token not registered');
      debugPrint('   Please ensure:');
      debugPrint('   1. You are logged in');
      debugPrint('   2. Firebase is properly configured');
      debugPrint('   3. The app has notification permissions');
      return;
    }

    // Step 3: Check edge function
    debugPrint('📋 Step 3: Test Edge Function Connection');
    debugPrint('─────────────────────────────────────────────────────────');
    final isDeployed = await helper.isEdgeFunctionDeployed();
    if (!isDeployed) {
      debugPrint('❌ FAILED: Edge function not deployed or not accessible');
      debugPrint('   Please run: supabase functions deploy send-trip-notification');
      return;
    }

    // Step 4: Test with actual trip (if available)
    debugPrint('📋 Step 4: Send Test Notifications');
    debugPrint('─────────────────────────────────────────────────────────');
    debugPrint('⚠️  To send actual notifications, you need a real trip ID');
    debugPrint('   Use the following methods in your app:');
    debugPrint('');
    debugPrint('   // Example 1: Trip Update Notification');
    debugPrint('   await helper.sendTestTripUpdateNotification(');
    debugPrint('     tripId: "your-actual-trip-id",');
    debugPrint('     tripName: "My Awesome Trip",');
    debugPrint('   );');
    debugPrint('');
    debugPrint('   // Example 2: Member Added Notification');
    debugPrint('   await helper.sendTestMemberAddedNotification(');
    debugPrint('     tripId: "your-actual-trip-id",');
    debugPrint('     tripName: "My Awesome Trip",');
    debugPrint('     memberName: "John Doe",');
    debugPrint('   );');
    debugPrint('');
    debugPrint('   // Example 3: New Message Notification');
    debugPrint('   await helper.sendTestNewMessageNotification(');
    debugPrint('     tripId: "your-actual-trip-id",');
    debugPrint('     tripName: "My Awesome Trip",');
    debugPrint('     messageText: "Hello from the test!",');
    debugPrint('   );');
    debugPrint('');

    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║  Test Suite Complete                                   ║');
    debugPrint('╚════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Quick test with a specific trip ID
  static Future<void> quickTest({
    required String tripId,
    required String tripName,
  }) async {
    debugPrint('🚀 Running quick notification test...');
    debugPrint('   Trip ID: $tripId');
    debugPrint('   Trip Name: $tripName');
    debugPrint('');

    final supabase = Supabase.instance.client;
    final helper = NotificationTestHelper(supabase);

    try {
      // Send test notification
      final result = await helper.sendTestTripUpdateNotification(
        tripId: tripId,
        tripName: tripName,
      );

      debugPrint('✅ SUCCESS: Notification sent');
      debugPrint('   Sent: ${result['sent'] ?? 0}');
      debugPrint('   Failed: ${result['failed'] ?? 0}');
      debugPrint('   Total: ${result['total'] ?? 0}');
    } catch (e) {
      debugPrint('❌ FAILED: $e');
    }
  }
}

/// Widget to add to your app for manual testing
class NotificationTestButton extends StatelessWidget {
  final String? tripId;
  final String? tripName;

  const NotificationTestButton({
    super.key,
    this.tripId,
    this.tripName,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        if (tripId != null && tripName != null) {
          await FirebaseNotificationManualTest.quickTest(
            tripId: tripId!,
            tripName: tripName!,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Test notification sent! Check console logs.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await FirebaseNotificationManualTest.runComprehensiveTest();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Diagnostic complete! Check console logs.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.notifications_active),
      label: const Text('Test Notifications'),
    );
  }
}

/// Instructions for testing
class TestInstructions {
  static const String setup = '''
Firebase Push Notifications - Setup Checklist

✅ Prerequisites:
  1. Firebase project created
  2. google-services.json added to android/app/
  3. GoogleService-Info.plist added to ios/Runner/
  4. Firebase dependencies in pubspec.yaml
  5. Google Services plugin in build.gradle

✅ Supabase Setup:
  1. Run migration: supabase db push
  2. Deploy edge function: supabase functions deploy send-trip-notification
  3. Set FCM server key: supabase secrets set FCM_SERVER_KEY=your_key

✅ Testing Steps:
  1. Login to the app
  2. FCM token should auto-register
  3. Use NotificationTestHelper to send test notifications
  4. Check device for notifications

✅ Troubleshooting:
  - Check console logs for errors
  - Verify FCM token in Supabase: user_fcm_tokens table
  - Test edge function in Supabase dashboard
  - Check notification permissions in device settings
  - View edge function logs: supabase functions logs send-trip-notification
''';

  static const String quickGuide = '''
Quick Test Guide

// 1. Add test button to your trip details page
NotificationTestButton(
  tripId: widget.tripId,
  tripName: trip.name,
)

// 2. Or run diagnostic
final helper = NotificationTestHelper(Supabase.instance.client);
await helper.printNotificationDebugInfo();

// 3. Send test notification
await helper.sendTestTripUpdateNotification(
  tripId: "your-trip-id",
  tripName: "My Trip",
);

// 4. Check device for notification
// 5. Check console for debug output
''';
}
