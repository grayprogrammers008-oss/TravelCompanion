# Apple App Store Deployment Guide

Complete guide to deploying TravelCompanion to the Apple App Store.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Apple Developer Account Setup](#apple-developer-account-setup)
3. [App Store Connect Setup](#app-store-connect-setup)
4. [Code Signing & Certificates](#code-signing--certificates)
5. [App Icon & Assets](#app-icon--assets)
6. [Build Configuration](#build-configuration)
7. [Create Archive & Upload](#create-archive--upload)
8. [App Store Listing](#app-store-listing)
9. [TestFlight Beta Testing](#testflight-beta-testing)
10. [Submit for Review](#submit-for-review)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Items

- ✅ **Apple Developer Account** ($99/year)
  - Individual or Organization account
  - [Sign up here](https://developer.apple.com/programs/)

- ✅ **Mac with Xcode 26.1** (You already have this)
  - Command Line Tools installed
  - Valid Apple ID signed in

- ✅ **App Requirements**
  - Unique Bundle ID
  - App Icon (1024x1024 PNG)
  - Screenshots for all device sizes
  - Privacy Policy URL
  - App Description & Metadata

---

## Apple Developer Account Setup

### Step 1: Enroll in Apple Developer Program

1. **Go to** [Apple Developer](https://developer.apple.com/programs/)
2. **Click** "Enroll"
3. **Choose** account type:
   - **Individual**: Personal apps under your name
   - **Organization**: Company/business apps
4. **Complete** enrollment process
5. **Pay** $99 USD annual fee
6. **Wait** for approval (usually 24-48 hours)

### Step 2: Sign in to Xcode

```bash
# Open Xcode
open -a Xcode

# Go to: Xcode → Settings → Accounts
# Click "+" → Add Apple ID
# Sign in with your developer account
```

---

## App Store Connect Setup

### Step 1: Create App ID

1. **Go to** [App Store Connect](https://appstoreconnect.apple.com)
2. **Navigate to** "My Apps"
3. **Click** "+" → "New App"
4. **Fill in**:
   - **Platform**: iOS
   - **Name**: TravelCompanion (or your desired name)
   - **Primary Language**: English
   - **Bundle ID**: Create new → `com.travelcrew.travelCrew`
   - **SKU**: `travelcompanion-ios` (unique identifier)
   - **User Access**: Full Access

> **Note**: The Bundle ID must match your app's Bundle Identifier in Xcode.

### Step 2: Verify Bundle ID

Check your current Bundle ID:

```bash
# Check Info.plist
cat /Users/vinothvs/Development/TravelCompanion/ios/Runner/Info.plist | grep -A 1 "CFBundleIdentifier"

# Current Bundle ID: com.travelcrew.travelCrew
```

---

## Code Signing & Certificates

### Step 1: Create App Store Certificate

#### Option A: Automatic Signing (Recommended)

1. **Open** your project in Xcode:
   ```bash
   open /Users/vinothvs/Development/TravelCompanion/ios/Runner.xcworkspace
   ```

2. **Select** Runner target
3. **Go to** "Signing & Capabilities"
4. **Check** "Automatically manage signing"
5. **Select** your Team
6. **Xcode will**:
   - Create certificates
   - Create provisioning profiles
   - Register App ID

#### Option B: Manual Signing

1. **Go to** [Apple Developer - Certificates](https://developer.apple.com/account/resources/certificates)
2. **Click** "+" to create new certificate
3. **Select** "iOS Distribution (App Store and Ad Hoc)"
4. **Follow** Certificate Signing Request (CSR) instructions:
   ```bash
   # Open Keychain Access
   # Keychain Access → Certificate Assistant → Request Certificate from CA
   # Email: your@email.com
   # Common Name: Your Name
   # Save to disk
   ```
5. **Upload** CSR file
6. **Download** certificate
7. **Double-click** to install in Keychain

### Step 2: Create Provisioning Profile

1. **Go to** [Provisioning Profiles](https://developer.apple.com/account/resources/profiles)
2. **Click** "+" to create new
3. **Select** "App Store"
4. **Choose** your App ID: `com.travelcrew.travelCrew`
5. **Select** your distribution certificate
6. **Name** it: `TravelCompanion App Store`
7. **Download** and double-click to install

---

## App Icon & Assets

### Step 1: Create App Icon

**Requirements**:
- 1024x1024 PNG
- No transparency
- No rounded corners (iOS adds them)

**Create Icon**:
```bash
# You can use online tools:
# - https://appicon.co
# - https://makeappicon.com

# Or create manually with:
# - Sketch
# - Figma
# - Photoshop
```

### Step 2: Add Icon to Xcode

1. **Open** `ios/Runner/Assets.xcassets/AppIcon.appiconset`
2. **Drag** your app icon images
3. **Required sizes**:
   - 20pt (2x, 3x)
   - 29pt (2x, 3x)
   - 40pt (2x, 3x)
   - 60pt (2x, 3x)
   - 76pt (1x, 2x) - iPad
   - 83.5pt (2x) - iPad Pro
   - 1024pt (1x) - App Store

### Step 3: Create Screenshots

**Required Screenshots**:
- **6.7" Display** (iPhone 14 Pro Max, 15 Pro Max, 16 Pro Max)
  - 1290 x 2796 pixels
- **6.5" Display** (iPhone 11 Pro Max, XS Max)
  - 1242 x 2688 pixels
- **5.5" Display** (iPhone 8 Plus)
  - 1242 x 2208 pixels
- **iPad Pro 12.9"**
  - 2048 x 2732 pixels

**Capture Screenshots**:
```bash
# Run on simulator
flutter run -d <simulator-id>

# Take screenshots:
# - Press Cmd + S in Simulator
# - Screenshots saved to Desktop
```

---

## Build Configuration

### Step 1: Update App Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: major.minor.patch+buildNumber
```

### Step 2: Update iOS Deployment Target

Current deployment target is iOS 15.0 (already configured).

Verify in [ios/Podfile](../ios/Podfile:2):
```ruby
platform :ios, '15.0'
```

### Step 3: Configure Info.plist

Edit [ios/Runner/Info.plist](../ios/Runner/Info.plist):

```xml
<!-- Already configured, verify these keys exist: -->
<key>CFBundleDisplayName</key>
<string>TravelCrew</string>

<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>

<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>

<!-- Add Privacy Descriptions -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture photos for your trips</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images for your trips</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby points of interest</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>We use Bluetooth to enable offline messaging with nearby travelers</string>

<key>NSLocalNetworkUsageDescription</key>
<string>We use local network to enable offline messaging with nearby travelers</string>
```

### Step 4: Firebase Configuration

**Important**: Ensure Firebase is properly configured for production.

1. **Download** production GoogleService-Info.plist from Firebase Console
2. **Replace** existing file:
   ```bash
   # Backup current file
   cp ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info-dev.plist

   # Add production file
   # Download from: Firebase Console → Project Settings → iOS App → Download
   # Place at: ios/Runner/GoogleService-Info.plist
   ```

---

## Create Archive & Upload

### Step 1: Clean Build

```bash
cd /Users/vinothvs/Development/TravelCompanion

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
export LANG=en_US.UTF-8
pod install
cd ..
```

### Step 2: Build Release IPA

#### Option A: Using Flutter (Recommended)

```bash
# Build iOS release
flutter build ios --release

# This creates a release build but doesn't archive
# You'll need to use Xcode for archiving
```

#### Option B: Using Xcode (Required for App Store)

1. **Open workspace**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select** "Any iOS Device (arm64)" as destination

3. **Product** → **Scheme** → Select "Runner"

4. **Product** → **Archive**

5. **Wait** for archive to complete (5-10 minutes)

6. **Organizer** window opens automatically

### Step 3: Validate Archive

In Xcode Organizer:

1. **Select** your archive
2. **Click** "Validate App"
3. **Select** your App Store Connect account
4. **Choose** options:
   - ✅ Upload your app's symbols
   - ✅ Include bitcode (if applicable)
5. **Click** "Validate"
6. **Wait** for validation to complete

### Step 4: Upload to App Store Connect

1. **Click** "Distribute App"
2. **Select** "App Store Connect"
3. **Choose** "Upload"
4. **Select** options:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number (automatic)
5. **Sign** with your distribution certificate
6. **Click** "Upload"
7. **Wait** for upload to complete (10-30 minutes)

> **Note**: You'll receive an email when processing is complete.

---

## App Store Listing

### Step 1: Complete App Information

Go to [App Store Connect](https://appstoreconnect.apple.com):

1. **Navigate to** your app
2. **Complete** App Information:

#### Basic Information

```yaml
Name: TravelCompanion
Subtitle: Plan trips with friends
Privacy Policy URL: https://yourwebsite.com/privacy
Category:
  Primary: Travel
  Secondary: Social Networking
Content Rights: Yes, contains third-party content
```

#### Age Rating

Complete questionnaire (typical for travel app):
- No violence, gambling, mature content
- Likely rating: 4+

#### Pricing

- **Price**: Free (or select paid tier)
- **Availability**: All countries or select specific

### Step 2: Version Information

For version 1.0.0:

#### What's New

```
Welcome to TravelCompanion!

Plan amazing trips with friends:
• Create and manage group trips
• Collaborate on checklists
• Real-time messaging (online & offline)
• Share photos and memories
• Get notified about trip updates

Start planning your next adventure today!
```

#### Description

```
TravelCompanion is the ultimate app for planning group trips with friends and family.

FEATURES:

✈️ GROUP TRIP PLANNING
• Create trips and invite friends
• Set destinations, dates, and budgets
• Track trip progress together

✅ COLLABORATIVE CHECKLISTS
• Build packing lists as a group
• Assign items to trip members
• Mark items complete in real-time

💬 SMART MESSAGING
• Chat with your travel crew
• Offline messaging with nearby friends
• Stay connected anywhere

📸 PHOTO SHARING
• Share trip memories instantly
• Create group albums
• Relive your adventures

🔔 PUSH NOTIFICATIONS
• Get notified about trip updates
• Know when friends join
• Stay in sync with your crew

🎨 BEAUTIFUL THEMES
• Choose from 7 gorgeous themes
• Customize your experience
• Light and dark modes

🔒 PRIVACY FIRST
• End-to-end encryption
• Your data stays private
• Secure cloud sync with Supabase

Whether you're planning a weekend getaway or a month-long adventure, TravelCompanion makes group travel planning effortless and fun!
```

#### Keywords

```
travel, trip planner, group travel, vacation, checklist, itinerary, travel planning, group trips, travel buddies, trip organizer
```

#### Support URL

```
https://yourwebsite.com/support
```

#### Marketing URL (optional)

```
https://yourwebsite.com
```

### Step 3: Upload Screenshots

1. **Upload** screenshots for each device size
2. **Minimum required**:
   - 3 screenshots per device size
   - Maximum: 10 screenshots
3. **Order matters** - first screenshot is featured

### Step 4: App Preview Video (Optional)

- 15-30 seconds
- Shows app features
- Required sizes match screenshot sizes
- Upload in App Store Connect

---

## TestFlight Beta Testing

Before releasing to App Store, test with TestFlight:

### Step 1: Enable TestFlight

1. **Go to** App Store Connect → TestFlight
2. **Select** your uploaded build
3. **Wait** for "Processing" to complete

### Step 2: Add Internal Testers

1. **Click** "Internal Testing"
2. **Add** testers (up to 100)
3. **Testers** receive email invitation
4. **Install** TestFlight app
5. **Test** your app

### Step 3: Add External Testers (Optional)

1. **Click** "External Testing"
2. **Create** test group
3. **Add** testers (up to 10,000)
4. **Submit** for Beta App Review
5. **Wait** for approval (1-2 days)

### Step 4: Collect Feedback

- Monitor crash reports
- Read tester feedback
- Fix critical issues
- Upload new builds as needed

---

## Submit for Review

### Step 1: Final Checklist

Before submitting:

- ✅ All app information complete
- ✅ Screenshots uploaded
- ✅ Privacy Policy accessible
- ✅ App tested on TestFlight
- ✅ No crashes or critical bugs
- ✅ Complies with App Store Guidelines
- ✅ Build uploaded and processed

### Step 2: Submit for Review

1. **Go to** App Store Connect → Your App → Version 1.0.0
2. **Select** build number
3. **Complete** Export Compliance:
   - Does your app use encryption? **Yes**
   - Is it exempt? **Yes** (HTTPS only)
4. **Complete** Advertising Identifier:
   - Does your app use IDFA? **No** (unless you added analytics)
5. **Review** all information
6. **Click** "Submit for Review"

### Step 3: Review Process

**Timeline**: 1-3 days (sometimes longer)

**Statuses**:
1. **Waiting for Review** - In queue
2. **In Review** - Apple is testing
3. **Pending Developer Release** - Approved!
4. **Ready for Sale** - Live on App Store

**If Rejected**:
- Read rejection reason carefully
- Fix issues
- Respond in Resolution Center
- Resubmit

---

## Troubleshooting

### Common Issues

#### 1. Missing Compliance

**Error**: "Missing Compliance"

**Solution**:
```bash
# Add to Info.plist
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

#### 2. Invalid Icon

**Error**: "Icon must not contain alpha channel"

**Solution**:
```bash
# Remove transparency from icon
# Use ImageMagick:
convert icon.png -alpha off icon_fixed.png
```

#### 3. Build Upload Fails

**Error**: Various upload errors

**Solution**:
```bash
# Use Application Loader (legacy) or Transporter app
# Download from Mac App Store: "Transporter"
```

#### 4. Provisioning Profile Issues

**Error**: "No matching provisioning profile"

**Solution**:
1. Delete provisioning profiles
2. Re-create in Developer Portal
3. Download and install
4. Clean Xcode derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

#### 5. Firebase Configuration

**Error**: GoogleService-Info.plist missing

**Solution**:
```bash
# Ensure file exists
ls -la ios/Runner/GoogleService-Info.plist

# If missing, download from Firebase Console
```

---

## Post-Release

### Monitor Performance

1. **App Store Connect Analytics**
   - Downloads
   - Sales
   - Crashes
   - Ratings

2. **Firebase Analytics**
   - User engagement
   - Feature usage
   - Retention

3. **Crash Reporting**
   - Firebase Crashlytics
   - Xcode Organizer crashes

### Update Strategy

**Regular Updates**:
- Bug fixes: Submit immediately
- Minor features: Every 2-4 weeks
- Major versions: Every 2-3 months

**Version Numbering**:
- Bug fix: 1.0.0 → 1.0.1
- Minor feature: 1.0.0 → 1.1.0
- Major feature: 1.0.0 → 2.0.0
- Build number: Always increment (+1, +2, etc.)

---

## Quick Reference Commands

### Build & Archive

```bash
# Clean everything
flutter clean && cd ios && rm -rf Pods Podfile.lock && pod install && cd ..

# Build release
flutter build ios --release

# Archive in Xcode
open ios/Runner.xcworkspace
# Then: Product → Archive
```

### Version Management

```yaml
# pubspec.yaml
version: 1.0.0+1  # version+buildNumber

# Increment for updates:
version: 1.0.1+2  # Bug fix
version: 1.1.0+3  # Minor update
version: 2.0.0+4  # Major update
```

### Check Bundle ID

```bash
cat ios/Runner/Info.plist | grep -A 1 "CFBundleIdentifier"
# Current: com.travelcrew.travelCrew
```

---

## Resources

### Official Documentation

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Tools

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com/account)
- [Transporter App](https://apps.apple.com/app/transporter/id1450874784) - Upload builds
- [TestFlight](https://testflight.apple.com) - Beta testing

### Design Resources

- [App Icon Template](https://developer.apple.com/design/resources/)
- [Screenshot Templates](https://www.screely.com)
- [Asset Generator](https://appicon.co)

---

## Next Steps

1. ✅ **Enroll** in Apple Developer Program
2. ✅ **Create** App Store Connect listing
3. ✅ **Prepare** app icon and screenshots
4. ✅ **Configure** code signing
5. ✅ **Build** and archive
6. ✅ **Upload** to App Store Connect
7. ✅ **Test** with TestFlight
8. ✅ **Submit** for review
9. ✅ **Launch** 🚀

---

**Good luck with your App Store deployment!**

*Last updated: November 9, 2025*
