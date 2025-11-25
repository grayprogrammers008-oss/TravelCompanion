# Notification Troubleshooting Guide

## Issue: Test Notification Not Appearing

If you press the test notification button but don't see a notification, follow these steps:

### 1. Check Console Logs

Look for these messages in your console:

**✅ Success:**
```
🧪 Sending test notification...
   ✅ Local notifications initialized
   ✅ Notification channel created
✅ Test notification sent successfully
```

**❌ Common Errors:**
```
❌ Failed to send test notification: [error message]
```

### 2. Verify Notification Permissions

#### iOS Simulator/Device:
1. After pressing the button, you should see a permission dialog
2. **Tap "Allow"** when prompted
3. Press the test button again

**Check Settings:**
- Go to **Settings → Notifications → TravelCrew**
- Ensure "Allow Notifications" is **ON**
- Check "Lock Screen", "Notification Center", and "Banners" are enabled

#### Android Emulator/Device:
1. The app should auto-request permissions on first use
2. If not, manually grant permissions:
   - **Settings → Apps → TravelCrew → Notifications**
   - Enable all notification categories

### 3. Check Simulator/Emulator Setup

#### iOS Simulator:
- ⚠️ **Local notifications work in iOS Simulator**
- You should see notifications in the notification center
- Pull down from the top of the screen to see notifications

#### Android Emulator:
- ✅ Local notifications work in Android Emulator
- Swipe down from the top to see notification tray
- Ensure emulator is **not in "Do Not Disturb" mode**

### 4. Rebuild the App

Sometimes notification channels need a clean reinstall:

```bash
# Clean the build
flutter clean

# Reinstall the app
flutter run
```

### 5. Check for Errors

**Common Error 1: Permission Denied**
```
Failed to send test notification: Notification permissions not granted
```

**Solution:**
- Grant notification permissions in device/simulator settings
- Restart the app
- Try again

**Common Error 2: Channel Not Created**
```
Failed to send test notification: Invalid channel ID
```

**Solution:**
- This is now fixed with the updated code
- The channel is created before sending notification

**Common Error 3: Plugin Not Initialized**
```
Failed to send test notification: MissingPluginException
```

**Solution:**
- Stop the app completely
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild: `flutter run`

### 6. Verify Updated Code

Make sure you have the latest changes in [login_page.dart](../lib/features/auth/presentation/pages/login_page.dart:148):

The `_sendTestNotification()` method should:
1. ✅ Initialize local notifications
2. ✅ Create notification channel (Android)
3. ✅ Show notification
4. ✅ Display snackbar confirmation

### 7. Test with Hot Restart

If hot reload doesn't work:

```bash
# In the Flutter console, press:
R  # (capital R for hot restart)

# Or stop and re-run:
flutter run
```

### 8. Platform-Specific Checks

#### iOS Specific:
```dart
// The iOS settings request permissions:
const iosSettings = DarwinInitializationSettings(
  requestAlertPermission: true,  // ← Must be true
  requestBadgePermission: true,
  requestSoundPermission: true,
);
```

#### Android Specific:
```dart
// Android needs notification channel:
const androidChannel = AndroidNotificationChannel(
  'test_channel',
  'Test Notifications',
  importance: Importance.high,  // ← Must be high
  enableVibration: true,
  playSound: true,
);
```

### 9. Debug Steps

Add this before pressing the button:

1. **Check if running on simulator:**
   ```
   Look at the top of your Flutter app/IDE
   Should show: "iPhone 15 Simulator" or "Android Emulator"
   ```

2. **Check notification settings in app:**
   - iOS: Settings → Notifications → TravelCrew
   - Android: Settings → Apps → TravelCrew → Notifications

3. **Test with a simpler notification first:**
   ```dart
   // Just title, no body
   await localNotifications.show(
     0,
     'Simple Test',
     null,
     details,
   );
   ```

### 10. Expected Behavior

**When It Works:**

1. Press "Test Notification" button
2. **iOS:** Permission dialog appears (first time only)
3. **Snackbar appears:** "✅ Test notification sent! Check your notification tray."
4. **Notification appears** in notification tray/center:
   - Title: 🎉 Test Notification
   - Body: Firebase notifications are working! This is a test message from TravelCrew.
5. **Sound plays** (if enabled)
6. **Device vibrates** (Android, if enabled)

### 11. Still Not Working?

If notifications still don't appear:

**Option 1: Check the actual error message**
- Look in the console for the exact error
- The snackbar will show the error message

**Option 2: Test on a real device**
```bash
# Connect your device via USB
flutter devices  # Verify device is connected
flutter run      # Deploy to device
```

**Option 3: Verify Firebase is initialized**
Check console on app start for:
```
✅ Firebase initialized successfully
✅ Notification services initialized successfully
```

**Option 4: Test FCM Service directly**
After login, the FCM service is initialized. This means:
- ✅ Permissions are granted
- ✅ Notification channels are created
- ✅ Local notifications should work

### 12. Quick Test Checklist

- [ ] App is running on simulator/device
- [ ] Pressed "Test Notification" button
- [ ] Saw snackbar: "✅ Test notification sent!"
- [ ] Checked notification tray (swipe down from top)
- [ ] Granted notification permissions when prompted
- [ ] Console shows success messages
- [ ] No errors in console

### 13. Alternative: Test After Login

If the test button on login screen doesn't work, try testing after logging in:

```dart
// After successful login, FCM is initialized
// Notifications should work better after login
```

The FCM service initialization after login sets up everything properly, including:
- ✅ Notification permissions
- ✅ Notification channels
- ✅ FCM token registration

---

## Summary

**Most Common Issues:**
1. **Permissions not granted** → Grant in Settings
2. **Need to restart app** → Hot restart (R) or full restart
3. **Simulator restrictions** → Use real device
4. **Channel not created** → Fixed in updated code

**Quick Fix:**
```bash
flutter clean
flutter run
# Press test button
# Grant permissions
# Check notification tray
```

If you still have issues, share the console output and I can help debug further!

