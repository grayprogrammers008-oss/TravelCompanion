# Pathio - App Store Assets

This folder contains all assets and documentation needed for Apple App Store submission.

## Folder Structure

```
Assets/
└── AppStore/
    ├── AppIcon/                    # App icon assets
    │   ├── generate_icon.py        # Python script to generate icon
    │   └── README.md               # Icon creation guide
    ├── Screenshots/                # App screenshots
    │   ├── iPhone_6.7/             # 1290x2796 screenshots (required)
    │   │   └── README.md
    │   ├── iPhone_6.5/             # 1242x2688 screenshots (optional)
    │   └── SCREENSHOT_GUIDE.md     # How to capture screenshots
    ├── Privacy/                    # Privacy policy
    │   └── PRIVACY_POLICY.md       # Privacy policy document
    ├── APP_METADATA.md             # All app store metadata
    └── SUBMISSION_CHECKLIST.md     # Step-by-step submission guide
```

## Quick Start for Testing Submission

### 1. Create App Icon
**Required**: 1024x1024 PNG file

**Quick options**:
- Use [AppIcon.co](https://appicon.co) to generate from any image
- Create simple design in Figma/Canva (1024x1024, blue background, white "P")
- Run the Python script (requires `pip3 install Pillow`)

Place final icon at: `AppStore/AppIcon/AppIcon-1024x1024.png`

### 2. Capture Screenshots
**Required**: Minimum 3 screenshots at 1290 x 2796 pixels

**Easiest method - Use your physical iPhone**:
1. Open Pathio on your iPhone
2. Press Volume Up + Side Button to screenshot
3. AirDrop to Mac
4. Place in `AppStore/Screenshots/iPhone_6.7/`

**Alternative - Use Simulator**:
- Run app on iPhone 17 Pro Max simulator
- Press Cmd + S to capture
- Move from Desktop to `AppStore/Screenshots/iPhone_6.7/`

### 3. Host Privacy Policy
**Required**: Public URL

**Quick options**:
- GitHub Pages (free, easy)
- Netlify (free, drag & drop)
- Your own website

Content available at: `AppStore/Privacy/PRIVACY_POLICY.md`

### 4. Review App Metadata
Open `AppStore/APP_METADATA.md` and review:
- App description
- Keywords
- Support contact info
- Privacy policy URL
- What's New text

## Files Ready for Submission

### ✅ Created and Ready
- [x] Privacy Policy document
- [x] App description and metadata
- [x] Screenshot guidelines
- [x] Submission checklist
- [x] App icon generator script

### ⏳ You Need to Complete
- [ ] Create/upload 1024x1024 app icon PNG
- [ ] Capture 3-10 screenshots (1290 x 2796)
- [ ] Host privacy policy at public URL
- [ ] Update contact information in metadata
- [ ] Archive app in Xcode
- [ ] Upload build to App Store Connect
- [ ] Submit for review

## Important Documents

### For Submission Process
- **SUBMISSION_CHECKLIST.md** - Complete step-by-step guide
- **APP_METADATA.md** - All text and information for App Store Connect

### For Assets Creation
- **AppIcon/README.md** - Icon creation guide
- **Screenshots/SCREENSHOT_GUIDE.md** - How to capture screenshots
- **Privacy/PRIVACY_POLICY.md** - Privacy policy template

## App Information Quick Reference

- **App Name**: Pathio
- **Bundle ID**: com.pathio.travel
- **Category**: Travel / Social Networking
- **Version**: 1.0.0
- **Tagline**: Plan trips with friends
- **Description**: Group travel planning with collaborative checklists, real-time messaging, and offline capabilities

## Next Steps

1. **Right now**:
   - Open Pathio on your iPhone
   - Take 3 screenshots of different screens
   - Save to `AppStore/Screenshots/iPhone_6.7/`

2. **Create app icon**:
   - Use AppIcon.co or similar tool
   - Save 1024x1024 PNG to `AppStore/AppIcon/`

3. **Host privacy policy**:
   - Copy `Privacy/PRIVACY_POLICY.md` content
   - Host on GitHub Pages or Netlify
   - Note the URL for App Store Connect

4. **Build for App Store**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Product → Archive
   - Distribute → App Store Connect
   - Upload

5. **Submit in App Store Connect**:
   - Fill in metadata from `APP_METADATA.md`
   - Upload screenshots
   - Upload app icon (done automatically from build)
   - Submit for review

## Support

For detailed instructions, see:
- `/docs/APP_STORE_QUICK_GUIDE.md` - Fast-track guide (2 hours)
- `/docs/APPLE_APP_STORE_DEPLOYMENT.md` - Comprehensive guide

## Testing vs Production

### For Testing (Current Goal)
- Simple app icon is fine
- Basic screenshots from simulator OK
- Privacy policy can be basic
- Use test metadata

### For Production Release
- Professional app icon design
- Polished screenshots with overlays
- Comprehensive privacy policy (legal review)
- Final metadata and descriptions
- Thorough testing on multiple devices
- Marketing materials prepared

---

**Current Status**: Assets folder structure created, documentation ready, waiting for screenshots and icon files.

**Estimated time to complete**: 30-60 minutes (icon + screenshots + hosting privacy policy)
