# iPhone 6.7" Screenshots

## Required Specifications
- **Resolution**: 1290 x 2796 pixels
- **Format**: PNG or JPEG
- **Quantity**: 3-10 screenshots

## How to Capture

### Option 1: Physical iPhone (Easiest)
1. Open Pathio on your iPhone 15 Pro Max, 16 Pro Max, or 17 Pro Max
2. Navigate to the screens you want to capture
3. Press **Volume Up + Side Button** simultaneously
4. AirDrop screenshots to your Mac
5. Place them in this folder

### Option 2: Simulator
1. Run: `flutter run -d <simulator-id>`
2. Navigate to desired screen in simulator
3. Press **Cmd + S** to save screenshot to Desktop
4. Move screenshots to this folder

### Option 3: Using Command Line
```bash
# Boot simulator
xcrun simctl boot "iPhone 17 Pro Max"

# Open simulator
open -a Simulator

# Run app
flutter run -d <device-id>

# Capture screenshot
xcrun simctl io booted screenshot ~/Desktop/screenshot-1.png

# Move to this folder
mv ~/Desktop/screenshot-*.png ./
```

## Screenshot Ideas

1. **Welcome/Onboarding** - First screen users see
2. **Trips Dashboard** - List of trips with preview cards
3. **Trip Details** - Single trip with members and checklists
4. **Messaging** - Chat interface showing conversations
5. **Checklist Creation** - Creating or editing a checklist
6. **Profile/Settings** - User profile and theme options

## For Testing Submission

Since you're just testing the submission process, you can:
- Use any screenshots from the running app
- Don't worry about perfect composition
- Ensure screenshots are the correct resolution (1290 x 2796)
- Have at least 3 screenshots

## For Production Release

When releasing to the world:
- Use high-quality, polished screenshots
- Add text overlays highlighting features
- Use consistent theme/styling
- Show real, meaningful content (not test data)
- Consider using screenshot design tools like Screely or Rotato

## Current Status

Place your captured screenshots here and rename them:
- `01-welcome.png`
- `02-dashboard.png`
- `03-trip-details.png`
- `04-messaging.png` (optional)
- `05-checklist.png` (optional)
