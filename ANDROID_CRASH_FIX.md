# Android App Crash - Diagnostic & Fix Guide

## Problem
The app installs but crashes immediately when opened on Android emulator.

## Most Common Causes & Solutions

### 1. **Supabase Initialization Failure** (Most Likely)
The app requires internet connection and Supabase to initialize. If Supabase fails, the app might crash.

**Quick Fix:**
```bash
# Check if emulator has internet
adb shell ping -c 3 google.com

# If no internet, restart emulator with internet enabled
```

### 2. **Clear App Data and Reinstall**
Old cached data might be causing conflicts.

**Steps:**
```bash
# Step 1: Clear app data
adb shell pm clear com.pathio.travel

# Step 2: Uninstall completely
adb uninstall com.pathio.travel

# Step 3: Reinstall fresh
cd "d:\Nithya\Travel Companion\TravelCompanion"
flutter install

# Step 4: Watch logs
flutter logs
```

### 3. **Check Crash Logs**
View the actual crash details:

```bash
# Option 1: Use flutter logs
flutter logs | findstr /C:"FATAL" /C:"Exception"

# Option 2: Use adb logcat
adb logcat *:E | findstr /C:"pathio" /C:"FATAL"

# Option 3: Get full crash report
adb logcat -d > crash_log.txt
```

### 4. **Common Runtime Errors**

#### A. Missing Hive Boxes
**Error**: `HiveError: Box not found`

**Fix**: The app initializes Hive in main.dart. If this fails:
```dart
// In lib/main.dart
await Hive.initFlutter();
await MessagingInitialization.initialize();
```

Ensure these complete without errors.

#### B. Supabase Connection Timeout
**Error**: `SocketException` or `TimeoutException`

**Fix**:
1. Check emulator has internet
2. Verify Supabase URL is correct in `lib/core/config/supabase_config.dart`
3. Try with a longer timeout

#### C. Permission Errors
**Error**: `SecurityException` or permission denied

**Fix**: Grant runtime permissions:
```bash
# Grant camera permission
adb shell pm grant com.pathio.travel android.permission.CAMERA

# Grant location permission
adb shell pm grant com.pathio.travel android.permission.ACCESS_FINE_LOCATION

# Grant storage permission
adb shell pm grant com.pathio.travel android.permission.READ_EXTERNAL_STORAGE
```

### 5. **Debug Build Steps**

Try running in debug mode with verbose logging:

```bash
# Clean build
flutter clean
flutter pub get

# Build and run with verbose output
flutter run -v

# Or build APK manually
flutter build apk --debug

# Install manually
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Launch app
adb shell am start -n com.pathio.travel/com.pathio.travel.MainActivity

# Watch logs immediately
adb logcat -c && adb logcat *:E
```

### 6. **Add Error Handling to main.dart**

Wrap initialization in try-catch to prevent crashes:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized');

    // Initialize messaging
    await MessagingInitialization.initialize();
    debugPrint('✅ Messaging initialized');

    // Initialize Supabase
    await SupabaseClientWrapper.initialize();
    debugPrint('✅ Supabase initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - show error screen in app
  }

  runApp(const ProviderScope(child: TravelCrewApp()));
}
```

## Quick Diagnostic Commands

```bash
# 1. Check if app is installed
adb shell pm list packages | findstr pathio

# 2. Check app info
adb shell dumpsys package com.pathio.travel | findstr version

# 3. Check if app process is running
adb shell ps | findstr pathio

# 4. Force stop app
adb shell am force-stop com.pathio.travel

# 5. Clear cache
adb shell pm clear com.pathio.travel

# 6. Get app logs only
adb logcat --pid=$(adb shell pidof -s com.pathio.travel)
```

## Expected Behavior

When app starts successfully, you should see in logs:
```
✅ Hive initialized successfully
✅ Messaging initialized successfully
✅ Supabase initialized successfully (online-only mode)
```

If any of these fail, the app might crash or show error screen.

## Next Steps

1. Run `flutter logs` before opening the app
2. Open the app
3. Check the logs for the exact error message
4. Share the error message for specific fix

## Test on Physical Device

Sometimes emulator-specific issues occur. Test on physical device:

```bash
# Enable USB debugging on phone
# Connect via USB
flutter run
```
