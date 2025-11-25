# Test Notification Button - Quick Guide

## Overview
A test notification button has been added to the login screen for easy testing of Firebase push notifications during development.

## Location
**File:** [lib/features/auth/presentation/pages/login_page.dart](../lib/features/auth/presentation/pages/login_page.dart:543)

The button appears on the login screen below the "Sign In" button.

## Usage

### 1. Run the App
```bash
flutter run
```

### 2. Navigate to Login Screen
- Open the app on your simulator/device
- Navigate to the login screen

### 3. Press Test Notification Button
- Click the "Test Notification" button
- A local notification will appear on your device

### 4. Expected Result
- ✅ A snackbar appears: "✅ Test notification sent!"
- ✅ A notification appears in the notification tray:
  - **Title:** 🎉 Test Notification
  - **Body:** Firebase notifications are working! This is a test message from TravelCrew.

## What It Does

The button sends a **local notification** (not a remote push notification) to verify that:
1. ✅ Firebase Local Notifications plugin is working
2. ✅ Notification permissions are granted
3. ✅ Notifications can be displayed on the device

## Features

- 🔔 Sends immediate local notification
- 📱 Works on both Android and iOS
- 🎨 Matches app theme styling
- ⚡ Instant feedback with snackbar
- 🔊 Includes sound and vibration
- 🎯 High priority notification

## Code Implementation

### Button UI
```dart
OutlinedButton.icon(
  onPressed: _sendTestNotification,
  icon: const Icon(Icons.notifications_active, size: 18),
  label: const Text('Test Notification'),
  style: OutlinedButton.styleFrom(
    foregroundColor: themeData.primaryColor,
    side: BorderSide(color: themeData.primaryColor.withValues(alpha: 0.3)),
    padding: const EdgeInsets.symmetric(
      vertical: AppTheme.spacingMd,
      horizontal: AppTheme.spacingLg,
    ),
  ),
)
```

### Notification Logic
```dart
Future<void> _sendTestNotification() async {
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const androidDetails = AndroidNotificationDetails(
    'test_channel',
    'Test Notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    enableVibration: true,
    playSound: true,
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    '🎉 Test Notification',
    'Firebase notifications are working! This is a test message from TravelCrew.',
    NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}
```

## Testing Scenarios

### ✅ Successful Test
**Console Output:**
```
🧪 Sending test notification...
✅ Test notification sent successfully
```

**User Experience:**
- Snackbar: "✅ Test notification sent!"
- Notification appears in tray
- Sound plays (if enabled)
- Device vibrates (if enabled)

### ❌ Failed Test
**Console Output:**
```
🧪 Sending test notification...
❌ Failed to send test notification: [error message]
```

**User Experience:**
- Snackbar: "❌ Failed: [error message]"
- Check notification permissions

## Troubleshooting

### Issue: Notification Not Appearing

**Android:**
1. Check notification permissions in device settings
2. Ensure app has notification permission granted
3. Check "Do Not Disturb" mode is off

**iOS:**
1. Check Settings > Notifications > TravelCrew
2. Ensure "Allow Notifications" is enabled
3. Check notification preview settings

### Issue: Button Does Nothing

1. Check console logs for errors
2. Verify Firebase is initialized:
   ```dart
   await Firebase.initializeApp();
   ```
3. Check local notifications plugin is initialized

### Issue: Permission Denied

**Solution:**
```dart
// Request permissions first
final messaging = FirebaseMessaging.instance;
await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

## Next Steps for Real Push Notifications

Once local notifications work, test remote push notifications:

1. **Login to the app**
2. **Use NotificationTestHelper:**
   ```dart
   import 'package:supabase_flutter/supabase_flutter.dart';
   import '../test/utils/notification_test_helper.dart';

   final helper = NotificationTestHelper(Supabase.instance.client);
   await helper.sendTestTripUpdateNotification(
     tripId: 'your-trip-id',
     tripName: 'Test Trip',
   );
   ```

3. **Deploy Supabase Edge Function:**
   ```bash
   supabase functions deploy send-trip-notification
   ```

## Removal for Production

**To remove the test button for production:**

1. Delete the button code (lines 540-558):
   ```dart
   // Remove these lines
   const SizedBox(height: AppTheme.spacingMd),
   OutlinedButton.icon(...), // Test notification button
   ```

2. Or wrap it in a debug flag:
   ```dart
   if (kDebugMode) ...[
     const SizedBox(height: AppTheme.spacingMd),
     OutlinedButton.icon(...),
   ]
   ```

## Related Documentation

- [Firebase Push Notifications Implementation](./FIREBASE_PUSH_NOTIFICATIONS.md)
- [Implementation Complete Summary](./FIREBASE_NOTIFICATIONS_IMPLEMENTATION_COMPLETE.md)
- [Notification Test Helper](../test/utils/notification_test_helper.dart)
- [Manual Test Script](../test/manual/firebase_notification_manual_test.dart)

---

**Added:** November 23, 2025
**Status:** ✅ Working
**Purpose:** Development testing

