# Deep Linking Setup for Travel Companion

This guide explains how to configure deep linking for the Trip Invite feature.

## Overview

Deep links allow users to open the app directly from invite links like:
- `https://travelcrew.app/invite/ABC123`
- `travelcrew://invite/ABC123`

## Android Configuration

### 1. Update `android/app/src/main/AndroidManifest.xml`

Add the following intent filter inside the `<activity>` tag (the MainActivity):

```xml
<activity
    android:name=".MainActivity"
    ...>

    <!-- Existing intent filters -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Deep Link Intent Filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <!-- HTTP/HTTPS links -->
        <data
            android:scheme="https"
            android:host="travelcrew.app"
            android:pathPrefix="/invite" />

        <!-- Custom scheme -->
        <data
            android:scheme="travelcrew"
            android:host="invite" />
    </intent-filter>
</activity>
```

### 2. App Links Verification (Optional - Production Only)

For verified app links (auto-open without prompt), host a `.well-known/assetlinks.json` file at:
`https://travelcrew.app/.well-known/assetlinks.json`

Example content:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.travelcrew.app",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_FINGERPRINT_HERE"
    ]
  }
}]
```

Get your SHA256 fingerprint:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## iOS Configuration

### 1. Update `ios/Runner/Info.plist`

Add the following inside the `<dict>` tag:

```xml
<!-- Deep Link URL Types -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.travelcrew.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>travelcrew</string>
        </array>
    </dict>
</array>

<!-- Universal Links -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:travelcrew.app</string>
</array>
```

### 2. Universal Links Setup (Optional - Production Only)

Host an `apple-app-site-association` file at:
`https://travelcrew.app/.well-known/apple-app-site-association`

Example content:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.travelcrew.app",
        "paths": [
          "/invite/*"
        ]
      }
    ]
  }
}
```

**Important:** This file must:
- Be served with `Content-Type: application/json`
- Be accessible via HTTPS
- Not have a `.json` extension

### 3. Enable Associated Domains in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner project
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Associated Domains"
6. Add: `applinks:travelcrew.app`

## Testing Deep Links

### Android

Test using ADB:

```bash
# Test HTTPS link
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://travelcrew.app/invite/ABC123" \
  com.travelcrew.app

# Test custom scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "travelcrew://invite/ABC123" \
  com.travelcrew.app
```

### iOS

Test using Simulator:

```bash
# Open Simulator
xcrun simctl openurl booted "travelcrew://invite/ABC123"

# Or test HTTPS
xcrun simctl openurl booted "https://travelcrew.app/invite/ABC123"
```

Test on physical device:
- Send the link via Messages/Email
- Tap the link
- Or use Safari and type the URL

## App Implementation

The app is already configured to handle invite links via GoRouter:

```dart
// Route definition
GoRoute(
  path: '/invite/:inviteCode',
  name: 'acceptInvite',
  builder: (context, state) {
    final inviteCode = state.pathParameters['inviteCode']!;
    return AcceptInvitePage(inviteCode: inviteCode);
  },
)
```

GoRouter automatically handles deep link routing when configured correctly.

## Troubleshooting

### Android

1. **Link opens in browser instead of app:**
   - Verify `android:autoVerify="true"` is set
   - Check if assetlinks.json is accessible
   - Reinstall the app after changes

2. **Custom scheme not working:**
   - Make sure the scheme matches exactly
   - Check for typos in AndroidManifest.xml

### iOS

1. **Universal links not working:**
   - Verify apple-app-site-association file is accessible
   - Check that file has correct content-type
   - Associated domain must match exactly
   - Try deleting and reinstalling the app

2. **Custom scheme not working:**
   - Verify Info.plist has correct scheme
   - Make sure CFBundleURLTypes is properly formatted

## Production Checklist

Before releasing to production:

- [ ] Replace `travelcrew.app` with your actual domain
- [ ] Update package name/bundle identifier
- [ ] Host assetlinks.json (Android)
- [ ] Host apple-app-site-association (iOS)
- [ ] Get production SHA256 fingerprint (Android)
- [ ] Add production Team ID (iOS)
- [ ] Test on real devices
- [ ] Test with production domain
- [ ] Verify both HTTP/HTTPS and custom schemes work

## Current Status

✅ **Completed:**
- Route configuration in app
- Accept invite page with animations
- Invite generation bottom sheet
- Share functionality

🚧 **Pending:**
- AndroidManifest.xml configuration (manual step required)
- Info.plist configuration (manual step required)
- Production domain setup (when ready)

## Share Link Format

When sharing invites, the app generates links in this format:

```
https://travelcrew.app/invite/{INVITE_CODE}

Example: https://travelcrew.app/invite/ABC123
```

This ensures:
- **Web fallback**: If app isn't installed, link can redirect to app store
- **Universal links**: Auto-opens app if installed (with proper setup)
- **Custom scheme**: Fallback option (`travelcrew://invite/ABC123`)

## Next Steps

1. **Development Testing:**
   - Configure AndroidManifest.xml and Info.plist locally
   - Test with custom scheme (`travelcrew://`)
   - Test invite flow end-to-end

2. **Production Deployment:**
   - Register domain (e.g., travelcrew.app)
   - Set up web hosting for verification files
   - Configure production certificates
   - Test with production domain

---

**Note:** Deep linking requires physical testing on devices. Emulators/Simulators have limitations with universal links.
