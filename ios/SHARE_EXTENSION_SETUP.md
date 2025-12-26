# iOS Share Extension Setup

This guide will help you set up the Share Extension so users can share locations from Google Maps directly to Pathio.

## What This Enables

When a user finds a place in Google Maps, they can:
1. Tap the **Share** button in Google Maps
2. Select **"Share to Pathio"** from the share sheet
3. Pathio opens with a bottom sheet to:
   - Select which trip to add the location to
   - Choose which day of the trip
   - Set an optional time
4. The location is added to their trip itinerary!

## Pre-Configured Files

The following files are already set up:
- `ios/ShareExtension/ShareViewController.swift` - Share handling logic
- `ios/ShareExtension/Info.plist` - Extension configuration
- `ios/ShareExtension/Base.lproj/MainInterface.storyboard` - UI storyboard
- `ios/ShareExtension/ShareExtension.entitlements` - App Groups entitlement
- `ios/Runner/Runner.entitlements` - Main app entitlements (includes App Groups)
- `ios/Runner/RunnerRelease.entitlements` - Release entitlements (includes App Groups)

Flutter side is also ready:
- `lib/core/services/shared_location_handler.dart` - Receives shared content
- `lib/core/services/google_maps_url_parser.dart` - Parses Google Maps URLs
- `lib/features/itinerary/presentation/widgets/add_location_to_trip_sheet.dart` - UI for adding to trip

## Step 1: Open Xcode Project

```bash
open ios/Runner.xcworkspace
```

## Step 2: Add Share Extension Target

1. In Xcode, go to **File → New → Target**
2. Select **iOS → Share Extension**
3. Click **Next**
4. Set:
   - **Product Name**: `ShareExtension`
   - **Bundle Identifier**: `com.pathio.travel.ShareExtension`
   - **Language**: Swift
5. Click **Finish**
6. When prompted "Activate ShareExtension scheme?", click **Cancel** (we want to stay on Runner)

## Step 3: Replace Generated Files

The Share Extension creates default files. Replace them with the ones we created:

1. Delete the auto-generated `ShareViewController.swift` in the ShareExtension folder (in Xcode sidebar)
2. Drag and drop `ios/ShareExtension/ShareViewController.swift` into the ShareExtension group in Xcode
3. When prompted, check "Copy items if needed" and ensure the ShareExtension target is selected

4. Replace the auto-generated `Info.plist`:
   - Delete the auto-generated one
   - Drag `ios/ShareExtension/Info.plist` into the ShareExtension group

5. Replace MainInterface.storyboard:
   - Delete the auto-generated one
   - Drag the entire `ios/ShareExtension/Base.lproj` folder into ShareExtension group

6. Add entitlements file:
   - Drag `ios/ShareExtension/ShareExtension.entitlements` into the ShareExtension group

## Step 4: Configure App Groups in Xcode

The entitlements files are pre-configured, but you need to enable App Groups in Xcode:

### For Runner (Main App):
1. Select the **Runner** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** and add: `group.com.pathio.travel`

### For ShareExtension:
1. Select the **ShareExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** and add the same group: `group.com.pathio.travel`

## Step 5: Set Entitlements File Path

For the ShareExtension target:
1. Select **ShareExtension** target
2. Go to **Build Settings**
3. Search for "Code Signing Entitlements"
4. Set the value to: `ShareExtension/ShareExtension.entitlements`

## Step 6: Build Settings

1. Select the **ShareExtension** target
2. Go to **Build Settings**
3. Search for "iOS Deployment Target"
4. Set it to match the Runner target (iOS 12.0 or higher)

## Step 7: Verify & Build

1. Build the project (Cmd+B)
2. Both Runner and ShareExtension should build successfully

## Testing

1. Run the app on a device or simulator
2. Open Google Maps, find a location (e.g., "Taj Mahal")
3. Tap the **Share** button in Google Maps
4. Look for **"Share to Pathio"** in the share sheet
5. Tap it - Pathio opens with the "Add to Trip" sheet showing:
   - The place name extracted from the URL
   - Coordinates (if available)
   - List of your trips to choose from
   - Day selector
   - Optional time picker

## Supported Google Maps URL Formats

The parser handles these URL formats:
- `https://www.google.com/maps/place/Taj+Mahal/@27.1751,78.0421,17z`
- `https://maps.google.com/maps?q=27.1751,78.0421`
- `https://goo.gl/maps/xxxxx` (short URLs)
- `https://maps.app.goo.gl/xxxxx` (new short URLs)

## Troubleshooting

- **Extension not appearing in share sheet**:
  - Make sure the app has been run at least once on the device
  - Check that both targets have matching App Groups

- **Data not passing to Flutter**:
  - Verify both targets have the same App Group: `group.com.pathio.travel`
  - Check the URL scheme `com.pathio.travel://` is registered in Runner's Info.plist

- **Build errors**:
  - Ensure iOS deployment target matches between targets
  - Verify the entitlements file path is correct in Build Settings

- **"Add to Trip" sheet not showing**:
  - Check the debug console for `SharedLocationHandler` logs
  - Verify `receive_sharing_intent` package is properly installed

## How It Works

1. **ShareViewController.swift** receives the shared URL from Google Maps
2. It saves the URL to a shared UserDefaults via App Groups
3. It opens the main app using the URL scheme `com.pathio.travel://share`
4. **SharedLocationHandler** in Flutter detects the share via `receive_sharing_intent`
5. **GoogleMapsUrlParser** extracts place name and coordinates from the URL
6. **AddLocationToTripSheet** shows UI to select trip, day, and time
7. Location is saved to the itinerary via Supabase
