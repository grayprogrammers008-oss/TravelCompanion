# Screenshot Capture Guide for Pathio

## Required Screenshot Sizes

### For App Store Submission

You need screenshots for these device sizes:

#### 1. iPhone 6.7" Display (Required)
- **Resolution**: 1290 x 2796 pixels
- **Devices**: iPhone 15 Pro Max, 15 Plus, 16 Pro Max, 17 Pro Max
- **Quantity**: Minimum 3, Maximum 10
- **Folder**: `iPhone_6.7/`

#### 2. iPhone 6.5" Display (Optional but Recommended)
- **Resolution**: 1242 x 2688 pixels
- **Devices**: iPhone 11 Pro Max, XS Max
- **Quantity**: Minimum 3, Maximum 10
- **Folder**: `iPhone_6.5/`

## How to Capture Screenshots

### Method 1: Using iOS Simulator (Current Setup)

The app is now running on iPhone 17 Pro Max simulator (6.7" display).

**Steps:**
1. Interact with the app to reach desired screens
2. Press **Cmd + S** in the simulator window
3. Screenshots save to your Desktop
4. Move screenshots to `Assets/AppStore/Screenshots/iPhone_6.7/`

### Method 2: Using Physical iPhone

1. Open app on your iPhone (15 Pro Max or similar)
2. Navigate to the screen you want to capture
3. Press **Volume Up + Side Button** simultaneously
4. Find screenshots in Photos app
5. AirDrop to Mac
6. Move to `Assets/AppStore/Screenshots/iPhone_6.7/`

## Recommended Screenshots (in order)

### Screenshot 1: Welcome/Splash Screen
- Shows Pathio logo and tagline
- First impression for users

### Screenshot 2: Trip List/Dashboard
- Shows multiple trips
- Demonstrates main interface
- Highlights trip organization

### Screenshot 3: Trip Details
- Show trip with members
- Display checklists and tasks
- Highlight collaboration features

### Screenshot 4: Messaging
- Group chat interface
- Show real-time messaging
- Highlight online/offline capabilities

### Screenshot 5: Checklist Creation
- Creating or editing checklist
- Shows collaborative features
- Task management

### Screenshot 6: Profile/Settings (Optional)
- Theme options
- User profile
- Settings interface

## Screenshot Best Practices

### Do:
- ✅ Use realistic data (not "Test User" or "Sample Trip")
- ✅ Show app in use with content
- ✅ Ensure good contrast and readability
- ✅ Use consistent theme across all screenshots
- ✅ Show key features prominently

### Don't:
- ❌ Include placeholder text or Lorem Ipsum
- ❌ Show empty states (unless intentional)
- ❌ Include personal/sensitive information
- ❌ Show error messages or bugs
- ❌ Include status bars with low battery or no signal

## Quick Screenshot Capture (For Testing)

Since you just want to test submission, here's the minimal approach:

1. **Launch app on simulator** (currently running)
2. **Capture 3 screens**:
   - Login/Welcome screen (Cmd + S)
   - Main dashboard/trips list (Cmd + S)
   - Any trip detail screen (Cmd + S)
3. **Move to folder**: `mv ~/Desktop/Simulator*.png Assets/AppStore/Screenshots/iPhone_6.7/`
4. **Rename for clarity**:
   - `01-welcome.png`
   - `02-trips-dashboard.png`
   - `03-trip-details.png`

## For Production Release

For the actual world release, consider:
- Professional screenshot design with text overlays
- Highlight key features with callouts
- Use tools like [Screely](https://screely.com) or [Rotato](https://rotato.app) for frames
- Create marketing screenshots with descriptions
- Add translations for international markets

## Current Status

Run these commands to capture screenshots from the running simulator:

```bash
# Wait for app to load
sleep 5

# Capture current screen
xcrun simctl io booted screenshot ~/Desktop/pathio-screenshot-1.png

# Then manually navigate in simulator and repeat for each screen
```

After capturing, organize them:

```bash
# Move to proper folder
mv ~/Desktop/pathio-screenshot-*.png Assets/AppStore/Screenshots/iPhone_6.7/

# Rename for submission
cd Assets/AppStore/Screenshots/iPhone_6.7/
mv pathio-screenshot-1.png 01-welcome.png
mv pathio-screenshot-2.png 02-dashboard.png
mv pathio-screenshot-3.png 03-details.png
```
