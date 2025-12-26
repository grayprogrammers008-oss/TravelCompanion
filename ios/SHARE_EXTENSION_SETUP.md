# iOS Share Extension Setup

## ✅ Status: READY TO USE

The Share Extension is **fully configured and ready to test**! Both the iOS native side and Flutter side are complete.

## What This Enables

When a user finds a place in Google Maps, they can:
1. Tap the **Share** button in Google Maps
2. Select **"Share to Pathio"** from the share sheet
3. Pathio opens with a bottom sheet to:
   - Select which trip to add the location to
   - Choose which day of the trip
   - Set an optional time
4. The location is added to their trip itinerary!

## ✅ Complete Setup

### iOS Native (Complete)
- ✅ ShareExtension Xcode target created
- ✅ `ios/ShareExtension/ShareViewController.swift` - Share handling logic
- ✅ `ios/ShareExtension/Info.plist` - Extension configuration
- ✅ `ios/ShareExtension/Base.lproj/MainInterface.storyboard` - UI storyboard
- ✅ `ios/ShareExtension/ShareExtension.entitlements` - App Groups entitlement
- ✅ `ios/Runner/Runner.entitlements` - Main app entitlements (includes App Groups)
- ✅ `ios/Runner/RunnerRelease.entitlements` - Release entitlements (includes App Groups)
- ✅ App Groups capability: `group.com.pathio.travel`

### Flutter Side (Complete)
- ✅ `lib/core/services/shared_location_handler.dart` - Receives shared content
- ✅ `lib/core/services/google_maps_url_parser.dart` - Parses Google Maps URLs
- ✅ `lib/features/itinerary/presentation/widgets/add_location_to_trip_sheet.dart` - UI for adding to trip
- ✅ Initialized in `main.dart`

## How to Test (Ready Now!)

The Share Extension is already built and bundled with the app. Just run and test:

```bash
# Build and run on iOS device/simulator
flutter run
```

### Testing Steps:

1. **Launch the app** on a device or simulator (Share Extensions work best on physical devices)
2. **Open Google Maps** and find a location (e.g., "Taj Mahal", "Eiffel Tower", "Times Square")
3. **Tap the Share button** in Google Maps
4. **Look for "Share to Pathio"** in the share sheet (may need to scroll)
5. **Tap "Share to Pathio"** - The app will:
   - Open Pathio automatically
   - Show "Add to Trip" bottom sheet with:
     - Place name extracted from the Google Maps URL
     - Coordinates (latitude, longitude)
     - List of your trips to select from
     - Day selector for the trip
     - Optional time picker
6. **Select a trip, day, and optional time**, then tap "Add to Day X"
7. **Success!** The location is added to your trip's itinerary

## Supported Google Maps URL Formats

The parser handles these URL formats:
- `https://www.google.com/maps/place/Taj+Mahal/@27.1751,78.0421,17z`
- `https://maps.google.com/maps?q=27.1751,78.0421`
- `https://goo.gl/maps/xxxxx` (short URLs)
- `https://maps.app.goo.gl/xxxxx` (new short URLs)

## Troubleshooting

### Extension not appearing in share sheet
- **Make sure the app has been run at least once** on the device/simulator
- Share Extensions need to be "registered" by running the app first
- On physical devices, uninstall and reinstall if the extension doesn't appear

### "Share to Pathio" appears but nothing happens
- Check the debug console for `SharedLocationHandler` logs:
  ```
  🔗 SharedLocationHandler: Initializing...
  🔗 SharedLocationHandler: Received shared items
  ✅ SharedLocationHandler: Parsed location: Taj Mahal (27.1751, 78.0421)
  ```
- Verify the URL scheme `com.pathio.travel://` is in `Runner/Info.plist` (already configured)

### "Add to Trip" sheet not showing
- Make sure you have at least one trip created in the app
- Check console logs for parsing errors
- Verify the shared URL is a valid Google Maps URL

### App doesn't open after sharing
- Verify both targets have the same App Group: `group.com.pathio.travel` (already configured)
- Check that the URL scheme is registered in Info.plist (already configured)

### Build errors
- Run `flutter clean && flutter pub get`
- Rebuild: `flutter build ios --no-codesign`

## How It Works

1. **ShareViewController.swift** receives the shared URL from Google Maps
2. It saves the URL to a shared UserDefaults via App Groups (`group.com.pathio.travel`)
3. It opens the main app using the URL scheme `com.pathio.travel://share`
4. **SharedLocationHandler** in Flutter detects the share via `receive_sharing_intent`
5. **GoogleMapsUrlParser** extracts place name and coordinates from the URL
6. **AddLocationToTripSheet** shows UI to select trip, day, and time
7. Location is saved to the itinerary via Supabase

---

## Quick Reference

### Files Modified (Recent Commit)
- `ios/Runner/Runner.entitlements` - Added App Groups
- `ios/Runner/RunnerRelease.entitlements` - Added App Groups
- `ios/ShareExtension/ShareExtension.entitlements` - Created with App Groups
- `ios/SHARE_EXTENSION_SETUP.md` - This documentation

### Key Configuration
- **App Groups ID**: `group.com.pathio.travel`
- **URL Scheme**: `com.pathio.travel://`
- **Bundle ID**: `com.pathio.travel`
- **Extension Bundle ID**: `com.pathio.travel.ShareExtension`
- **Share Extension Display Name**: "Share to Pathio"

### Build Commands
```bash
# Clean build
flutter clean && flutter pub get

# Build for iOS (no code signing)
flutter build ios --no-codesign

# Run on device/simulator
flutter run

# Build and install release on device
flutter build ios --release
open ios/Runner.xcworkspace  # Then run from Xcode
```

### Debug Logs to Watch
```
✅ Shared location handler initialized
🔗 SharedLocationHandler: Initializing...
🔗 SharedLocationHandler: Checking for initial share...
🔗 SharedLocationHandler: Received X shared items
🔗 SharedLocationHandler: Processing text: <URL>
🔗 SharedLocationHandler: Found URL: <Google Maps URL>
✅ SharedLocationHandler: Parsed location: <Place Name> (lat, lng)
🔗 SharedLocationHandler: Showing add sheet...
```

---

**Last Updated**: December 26, 2024
**Status**: ✅ Production Ready
