# iOS Share Extension Setup

The files for the Share Extension have been created. Follow these steps in Xcode to complete the setup:

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

1. Delete the auto-generated `ShareViewController.swift` in the ShareExtension folder
2. Drag and drop `ios/ShareExtension/ShareViewController.swift` into the ShareExtension group in Xcode
3. When prompted, check "Copy items if needed" and ensure the ShareExtension target is selected

4. Replace the auto-generated `Info.plist`:
   - Delete the auto-generated one
   - Drag `ios/ShareExtension/Info.plist` into the ShareExtension group

5. Replace MainInterface.storyboard:
   - Delete the auto-generated one
   - Drag the entire `ios/ShareExtension/Base.lproj` folder into ShareExtension group

## Step 4: Configure App Groups

Both the main app and Share Extension need to be in the same App Group to share data:

1. Select the **Runner** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** and add: `group.com.pathio.travel`

6. Select the **ShareExtension** target
7. Go to **Signing & Capabilities** tab
8. Click **+ Capability**
9. Add **App Groups**
10. Click the **+** and add the same group: `group.com.pathio.travel`

## Step 5: Build Settings

1. Select the **ShareExtension** target
2. Go to **Build Settings**
3. Search for "iOS Deployment Target"
4. Set it to match the Runner target (likely iOS 12.0 or higher)

## Step 6: Verify

1. Build the project (Cmd+B)
2. Both Runner and ShareExtension should build successfully

## Testing

1. Run the app on a device or simulator
2. Open Google Maps, find a location
3. Tap the Share button
4. Look for "Share to Pathio" in the share sheet
5. Tap it - the app should open with the "Add to Itinerary" sheet

## Troubleshooting

- **Extension not appearing**: Make sure the app has been run at least once on the device
- **Data not passing**: Verify both targets have the same App Group configured
- **Build errors**: Ensure iOS deployment target matches between targets
