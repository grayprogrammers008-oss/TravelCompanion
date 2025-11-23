# Firebase Push Notifications Setup Guide

This guide will walk you through setting up Firebase Cloud Messaging (FCM) for TravelCompanion push notifications.

## Part 1: Create Firebase Project (15 minutes)

### Step 1: Go to Firebase Console
1. Visit https://console.firebase.google.com/
2. Sign in with your Google account
3. Click **"Add project"**

### Step 2: Configure Project
1. **Project name:** `TravelCompanion` (or `travel-companion`)
2. **Project ID:** Will be auto-generated (e.g., `travel-companion-abc123`)
   - **⚠️ SAVE THIS PROJECT ID** - You'll need it later
3. Click **Continue**

### Step 3: Google Analytics (Optional)
1. Toggle **"Enable Google Analytics"** - Your choice (recommended: OFF for simplicity)
2. Click **Create project**
3. Wait for project creation (30-60 seconds)
4. Click **Continue**

---

## Part 2: Add Android App to Firebase (10 minutes)

### Step 1: Register Android App
1. In Firebase Console, click the **Android icon** (robot)
2. **Android package name:** `com.travelcrew.app`
   - ⚠️ This must match your app's package name exactly
   - Check: `android/app/build.gradle` → look for `applicationId`
3. **App nickname (optional):** `TravelCompanion Android`
4. **Debug signing certificate SHA-1 (optional):** Leave blank for now
5. Click **Register app**

### Step 2: Download Configuration File
1. Click **Download google-services.json**
2. **⚠️ IMPORTANT:** Save this file - you'll place it in `android/app/` directory
3. Click **Next**

### Step 3: Skip Gradle Configuration
1. Click **Next** (we'll do this manually)
2. Click **Continue to console**

---

## Part 3: Add iOS App to Firebase (15 minutes)

### Step 1: Register iOS App
1. In Firebase Console, click **Add app** → Select **iOS icon** (Apple)
2. **iOS bundle ID:** `com.travelcrew.app`
   - ⚠️ Must match your iOS bundle identifier exactly
   - Check: Open `ios/Runner.xcodeproj` in Xcode → General tab → Bundle Identifier
3. **App nickname (optional):** `TravelCompanion iOS`
4. **App Store ID (optional):** Leave blank
5. Click **Register app**

### Step 2: Download Configuration File
1. Click **Download GoogleService-Info.plist**
2. **⚠️ IMPORTANT:** Save this file - you'll place it in `ios/Runner/` directory
3. Click **Next**
4. Click **Next** again (skip SDK setup)
5. Click **Continue to console**

---

## Part 4: Enable Cloud Messaging

### Step 1: Enable FCM API
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **Cloud Messaging** tab
3. Scroll down to **Cloud Messaging API (Legacy)**
4. If you see **"Enable"** button, click it
5. **Copy the Server Key** - You'll need this for Supabase Edge Functions

---

## Part 5: Apple Push Notification Setup (iOS Only) (20 minutes)

⚠️ **Prerequisites:** You need an Apple Developer Account ($99/year)

### Step 1: Create APNs Authentication Key
1. Go to https://developer.apple.com/account/
2. Sign in with your Apple Developer account
3. Go to **Certificates, Identifiers & Profiles**
4. Click **Keys** (left sidebar)
5. Click the **+** button to create a new key
6. **Key Name:** `TravelCompanion Push Notifications`
7. Check **Apple Push Notifications service (APNs)**
8. Click **Continue**
9. Click **Register**
10. Click **Download** - Save the `.p8` file
11. **⚠️ IMPORTANT:** Copy the **Key ID** (shows after download)
12. **⚠️ IMPORTANT:** Copy your **Team ID** (top right of page)

### Step 2: Upload APNs Key to Firebase
1. Back in Firebase Console → **Project Settings**
2. Click **Cloud Messaging** tab
3. Scroll to **Apple app configuration**
4. Under **APNs Authentication Key**, click **Upload**
5. Upload the `.p8` file you downloaded
6. Enter **Key ID** (from step 11 above)
7. Enter **Team ID** (from step 12 above)
8. Click **Upload**

---

## Part 6: Place Configuration Files in Project

### For Android:
1. Copy `google-services.json` to: `/Users/vinothvs/Development/TravelCompanion/android/app/`
2. Verify the file is in the correct location

### For iOS:
1. **Method 1: Via Xcode (Recommended)**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Right-click on `Runner` folder (in left sidebar)
   - Select **Add Files to "Runner"...**
   - Select `GoogleService-Info.plist`
   - ✅ Check **"Copy items if needed"**
   - ✅ Check **"Runner" target**
   - Click **Add**

2. **Method 2: Manual Copy**
   - Copy `GoogleService-Info.plist` to: `/Users/vinothvs/Development/TravelCompanion/ios/Runner/`
   - Then open Xcode and verify it appears in the project

---

## Part 7: Tell Claude You're Ready

Once you've completed the steps above, tell me:

**"I've completed Firebase setup. Here's my info:"**
```
Project ID: [paste your Firebase project ID]
FCM Server Key: [paste from Cloud Messaging settings]
iOS Team ID: [paste your Apple Team ID]
iOS APNs Key ID: [paste the APNs Key ID]
```

Then I'll:
1. ✅ Add the configuration files to the Flutter project
2. ✅ Add Firebase dependencies to `pubspec.yaml`
3. ✅ Configure Android and iOS native projects
4. ✅ Implement the notification service
5. ✅ Create the notification center UI
6. ✅ Set up Supabase integration

---

## Troubleshooting

### Can't find bundle ID?
```bash
cd ios
grep -r "PRODUCT_BUNDLE_IDENTIFIER" Runner.xcodeproj/project.pbxproj
```

### Can't find package name?
```bash
grep "applicationId" android/app/build.gradle
```

### Firebase Console Issues?
- Make sure you're using a Google account (not Apple ID)
- Try a different browser if you see errors
- Clear cache and cookies

---

## Estimated Time
- **Total:** 60-70 minutes
- **Firebase setup:** 15 min
- **Android config:** 10 min
- **iOS config:** 15 min
- **APNs setup:** 20 min
- **File placement:** 10 min

---

## What Happens Next?

After you provide the Firebase credentials, I'll automatically:
1. Configure the Flutter app for FCM
2. Implement notification permissions
3. Create notification service
4. Handle foreground/background notifications
5. Implement deep linking for notification taps
6. Create in-app notification center
7. Set up Supabase Edge Functions for sending notifications
8. Add database triggers for automatic notifications

**Ready to get started? Follow Part 1 and let me know when you're ready to proceed!** 🚀
