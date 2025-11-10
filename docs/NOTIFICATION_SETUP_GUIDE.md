# 🔔 Push Notifications - Quick Setup Guide

## Current Status: ⚠️ Requires Configuration

The push notification system is **implemented but NOT configured**. Follow this guide to activate it.

---

## 📋 Setup Checklist

- [ ] Step 1: Firebase Project Setup
- [ ] Step 2: Android Configuration
- [ ] Step 3: iOS Configuration
- [ ] Step 4: Supabase Database Setup
- [ ] Step 5: Supabase Edge Function Deployment
- [ ] Step 6: App Code Integration
- [ ] Step 7: Testing

**Estimated Time:** 30-45 minutes

---

## Step 1: Firebase Project Setup (15 min)

### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or use existing project
3. Enter project name: `TravelCompanion` (or your choice)
4. Enable/disable Google Analytics (optional)
5. Click "Create project"

### 1.2 Add Android App

1. In Firebase Console → Click "Add app" → Select Android (🤖)
2. **Android package name**: `com.example.travel_crew`
   - ⚠️ Find yours in `android/app/build.gradle` → `applicationId`
3. **App nickname**: `TravelCompanion Android` (optional)
4. Click "Register app"
5. **Download** `google-services.json`
6. **Place file** in: `android/app/google-services.json`
7. Click "Next" → "Next" → "Continue to console"

### 1.3 Add iOS App

1. In Firebase Console → Click "Add app" → Select iOS (🍎)
2. **iOS bundle ID**: `com.example.travelCrew`
   - ⚠️ Find yours in Xcode → Runner → General → Bundle Identifier
3. **App nickname**: `TravelCompanion iOS` (optional)
4. Click "Register app"
5. **Download** `GoogleService-Info.plist`
6. **Drag file into Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into Runner folder
   - ✅ Check "Copy items if needed"
   - ✅ Select Runner target
7. Click "Next" → "Next" → "Continue to console"

### 1.4 Get Firebase Server Key

1. Firebase Console → ⚙️ Settings → Project settings
2. Click **"Cloud Messaging"** tab
3. Scroll to **"Cloud Messaging API (Legacy)"**
4. Copy the **"Server key"**
   ```
   Example: AAAA1234567:APA91bF...xyz
   ```
5. **Save this key** - you'll need it for Supabase in Step 5

---

## Step 2: Android Configuration (5 min)

### 2.1 Update `android/build.gradle`

Open `android/build.gradle` and add Google Services:

```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"

        // ✨ ADD THIS LINE
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 2.2 Update `android/app/build.gradle`

Open `android/app/build.gradle` and add at the **BOTTOM** of the file:

```gradle
// ✨ ADD THIS LINE AT THE VERY BOTTOM
apply plugin: 'com.google.gms.google-services'
```

### 2.3 Verify `google-services.json` Location

Ensure file is at: `android/app/google-services.json`

```bash
ls -la android/app/google-services.json
# Should show the file exists
```

---

## Step 3: iOS Configuration (5 min)

### 3.1 Update `ios/Runner/Info.plist`

Add background modes for remote notifications:

```xml
<!-- Add this inside <dict> tag -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 3.2 Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode (NOT .xcodeproj)
2. Select **Runner** project in navigator
3. Select **Runner** target
4. Click **"Signing & Capabilities"** tab
5. Click **"+ Capability"** button
6. Search and add **"Push Notifications"**
7. Also add **"Background Modes"** if not present
   - ✅ Check "Remote notifications"

### 3.3 Verify GoogleService-Info.plist

Ensure file is added to Xcode project:
- Should appear in Xcode file navigator under Runner
- Should have Runner target membership checked

---

## Step 4: Supabase Database Setup (5 min)

### 4.1 Apply Database Migration

**Option A: Using Supabase CLI** (Recommended)
```bash
cd /Users/vinothvs/Development/TravelCompanion
supabase db push
```

**Option B: Manual SQL Execution**
```bash
# If you have direct database access
psql -U postgres -h your-supabase-host -d postgres \
  -f supabase/migrations/20250127_trip_notifications.sql
```

**Option C: Supabase Dashboard**
1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Go to **SQL Editor**
4. Click "New query"
5. Copy contents of `supabase/migrations/20250127_trip_notifications.sql`
6. Paste and click **"Run"**

### 4.2 Verify Tables Created

In Supabase Dashboard → Table Editor, you should see:
- ✅ `user_fcm_tokens` table

In Database → Functions, you should see:
- ✅ `register_fcm_token()`
- ✅ `unregister_fcm_token()`
- ✅ `notify_trip_updated()`
- ✅ `notify_member_added()`

---

## Step 5: Supabase Edge Function Deployment (5 min)

### 5.1 Deploy Edge Function

```bash
cd /Users/vinothvs/Development/TravelCompanion
supabase functions deploy send-trip-notification
```

### 5.2 Set Firebase Server Key Secret

Using the Server Key from Step 1.4:

```bash
supabase secrets set FCM_SERVER_KEY=AAAA1234567:APA91bF...xyz
```

Replace `AAAA1234567:APA91bF...xyz` with your actual server key.

### 5.3 Verify Deployment

```bash
supabase functions list
# Should show: send-trip-notification
```

---

## Step 6: App Code Integration (10 min)

### 6.1 Initialize FCM Token Manager on Login

Open the file where user login is handled and add:

**Example: In your auth success callback**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/services/fcm_token_manager.dart';

// After successful login
Future<void> _onLoginSuccess() async {
  final supabase = Supabase.instance.client;
  final fcm = FirebaseMessaging.instance;

  final tokenManager = FCMTokenManager(supabase, fcm);

  // Register FCM token
  await tokenManager.registerToken();

  // Listen for token refresh
  tokenManager.listenToTokenRefresh();
}
```

### 6.2 Unregister Token on Logout

```dart
// On logout
Future<void> _onLogout() async {
  final supabase = Supabase.instance.client;
  final fcm = FirebaseMessaging.instance;

  final tokenManager = FCMTokenManager(supabase, fcm);

  // Unregister token
  await tokenManager.unregisterToken();

  // Then proceed with logout
  await supabase.auth.signOut();
}
```

### 6.3 Alternative: Auto-Register in App Startup

Add to your main app initialization (e.g., in a SplashScreen or HomePage):

```dart
@override
void initState() {
  super.initState();
  _initializeFCM();
}

Future<void> _initializeFCM() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
    final supabase = Supabase.instance.client;
    final fcm = FirebaseMessaging.instance;
    final tokenManager = FCMTokenManager(supabase, fcm);

    await tokenManager.registerToken();
    tokenManager.listenToTokenRefresh();
  }
}
```

---

## Step 7: Testing (10 min)

### 7.1 Test FCM Token Registration

1. **Run the app** on a physical device (notifications don't work well on emulators)
2. **Login** with a test account
3. **Check Supabase Dashboard**:
   - Table Editor → `user_fcm_tokens`
   - Should see a new row with your `user_id` and `fcm_token`
   - `is_active` should be `true`

### 7.2 Test Trip Update Notification

#### Test Scenario: Update a Trip

1. **Device 1**: Login with User A
2. **Device 2**: Login with User B
3. Add both users to the same trip
4. **Device 1** (User A): Update the trip name
5. **Device 2** (User B): Should receive push notification!

Expected notification:
```
Title: Trip Updated
Body: [User A] updated [Trip Name] (name)
```

### 7.3 Manual Test with Firebase Console

**Easiest way to test without needing 2 devices:**

1. Go to Firebase Console → Cloud Messaging
2. Click **"Send your first message"**
3. **Notification title**: "Test Notification"
4. **Notification text**: "Testing push notifications"
5. Click **"Send test message"**
6. Paste your FCM token (from `user_fcm_tokens` table)
7. Click **"Test"**
8. Should receive notification on your device!

### 7.4 Test Edge Function

Test the edge function directly:

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/send-trip-notification \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "trip_id": "your-trip-id",
    "payload": {
      "type": "trip_updated",
      "trip_id": "your-trip-id",
      "trip_name": "Test Trip",
      "sender_id": "user-id",
      "sender_name": "Test User",
      "updated_field": "name"
    }
  }'
```

Check response and Supabase logs:
```bash
supabase functions logs send-trip-notification
```

---

## 🎯 Quick Verification Checklist

After setup, verify these:

- [ ] ✅ `google-services.json` in `android/app/`
- [ ] ✅ `GoogleService-Info.plist` in Xcode project
- [ ] ✅ `user_fcm_tokens` table exists in Supabase
- [ ] ✅ Edge function `send-trip-notification` deployed
- [ ] ✅ `FCM_SERVER_KEY` secret set in Supabase
- [ ] ✅ FCM token appears in database after login
- [ ] ✅ Test notification received from Firebase Console

---

## 🐛 Troubleshooting

### Issue: No FCM token in database

**Solution:**
1. Check app logs for FCM token
2. Verify user is logged in
3. Check `register_fcm_token()` function exists in Supabase
4. Check RLS policies on `user_fcm_tokens` table

### Issue: Notification not received

**Solution:**
1. Verify token is `is_active = true` in database
2. Check Firebase Console logs
3. Test with Firebase Console "Send test message"
4. Check device notification permissions
5. Verify app is in foreground/background (different behavior)

### Issue: Edge function fails

**Solution:**
1. Check Supabase logs: `supabase functions logs send-trip-notification`
2. Verify `FCM_SERVER_KEY` is set correctly
3. Check Firebase Server Key is valid
4. Verify trip members exist in `trip_members` table

### Issue: Android build fails

**Solution:**
1. Ensure `google-services.json` is in correct location
2. Check `google-services` plugin is applied LAST in `app/build.gradle`
3. Run `flutter clean && flutter pub get`
4. Rebuild: `flutter build apk`

### Issue: iOS build fails

**Solution:**
1. Run `cd ios && pod install`
2. Verify `GoogleService-Info.plist` is in Xcode with Runner target
3. Check Push Notifications capability is enabled
4. Clean build folder in Xcode: Product → Clean Build Folder

---

## 📱 Platform-Specific Notes

### Android
- ✅ Works on emulators with Google Play Services
- ✅ Works on physical devices
- ⚠️ Requires Google Play Services installed

### iOS
- ❌ Does NOT work on simulator
- ✅ Works on physical devices only
- ⚠️ Requires valid Apple Developer account for push notifications
- ⚠️ Requires proper provisioning profile

---

## 🚀 What Happens After Setup?

Once configured, notifications will be **automatically sent** when:

1. ✅ **Trip Created** - All future members get notified when invited
2. ✅ **Trip Updated** - All members notified (except the person who updated)
3. ✅ **Trip Deleted** - All members notified
4. ✅ **Member Added** - All existing members notified
5. ✅ **Member Removed** - All remaining members notified
6. ✅ **New Message** - All members notified (if messaging feature is active)

**No additional code needed** - it's all handled by database triggers! 🎉

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Full Implementation Docs](./FIREBASE_PUSH_NOTIFICATIONS.md)

---

## 💡 Tips

1. **Test on Real Devices**: Notifications work best on physical devices
2. **Check Permissions**: Users must grant notification permissions
3. **Background vs Foreground**: Different notification behaviors
4. **Battery Optimization**: Some Android devices kill background apps
5. **Token Refresh**: FCM tokens can change, our system handles this automatically

---

**Questions?** Check the [troubleshooting section](#-troubleshooting) or refer to the detailed [Firebase Push Notifications documentation](./FIREBASE_PUSH_NOTIFICATIONS.md).

---

**Last Updated:** January 29, 2025
**Status:** ⚠️ Setup Required - Follow this guide to activate
