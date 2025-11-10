# Pathio App Store Submission Checklist

## Pre-Submission Requirements

### ✅ Assets Created
- [ ] App Icon (1024x1024 PNG) - Located in `Assets/AppStore/AppIcon/`
- [ ] Screenshots (iPhone 6.7") - Located in `Assets/AppStore/Screenshots/iPhone_6.7/`
  - [ ] Minimum 3 screenshots captured
  - [ ] Screenshots show actual app content (not placeholders)
- [ ] Privacy Policy - Located in `Assets/AppStore/Privacy/PRIVACY_POLICY.md`
  - [ ] Contact email added
  - [ ] Hosted at public URL
- [ ] App Metadata - Review `Assets/AppStore/APP_METADATA.md`

### 📱 App Configuration
- [x] Bundle ID registered: com.pathio.travel
- [x] iPhone registered in Apple Developer Portal
- [x] Signing & Capabilities configured in Xcode
- [x] Info.plist updated with:
  - [x] App name: Pathio
  - [x] Privacy descriptions (Camera, Photos, Bluetooth, etc.)
  - [x] Export compliance (ITSAppUsesNonExemptEncryption = false)
- [x] Deep links configured:
  - [x] pathio.travel domain
  - [x] pathio:// custom scheme

### 🏗️ Build & Testing
- [ ] Clean build successful
- [ ] App runs on physical iPhone
- [ ] App runs on iOS Simulator
- [ ] TestFlight build uploaded (optional for initial testing)
- [ ] Basic feature testing:
  - [ ] User registration works
  - [ ] Trip creation works
  - [ ] Checklist creation works
  - [ ] Messaging works
  - [ ] Photo upload works
  - [ ] Push notifications work (if enabled)

## Apple Developer Portal Setup

### App Store Connect
- [ ] Navigate to: https://appstoreconnect.apple.com
- [ ] App created with name "Pathio"
- [ ] Bundle ID linked: com.pathio.travel

### App Information
- [ ] App Name: Pathio
- [ ] Subtitle: Plan trips with friends
- [ ] Primary Category: Travel
- [ ] Secondary Category: Social Networking
- [ ] Privacy Policy URL: [INSERT YOUR URL]
- [ ] Support URL: [INSERT YOUR URL]

### Pricing & Availability
- [ ] Price: Free
- [ ] Availability: All countries (or selected countries)
- [ ] Pre-order: No (for initial release)

## Build Process

### Step 1: Clean & Prepare
```bash
cd /Users/vinothvs/Development/TravelCompanion
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Step 2: Open in Xcode
```bash
open ios/Runner.xcworkspace
```

### Step 3: Configure Xcode
- [ ] Select Runner target
- [ ] Set destination: "Any iOS Device (arm64)"
- [ ] Verify signing is green (no errors)
- [ ] Check version/build number in General tab

### Step 4: Archive
- [ ] Product → Archive
- [ ] Wait 5-10 minutes for archive to complete
- [ ] Archive appears in Organizer window

### Step 5: Distribute
- [ ] In Organizer, click "Distribute App"
- [ ] Select: "App Store Connect"
- [ ] Select: "Upload"
- [ ] Click through options (keep defaults)
- [ ] Click "Upload"
- [ ] Wait 10-30 minutes for processing

## App Store Connect Submission

### Version Information
- [ ] Version: 1.0.0
- [ ] Build: Select uploaded build
- [ ] What's New: Copy from APP_METADATA.md

### App Review Information
- [ ] First Name: [Your Name]
- [ ] Last Name: [Your Name]
- [ ] Phone: [Your Phone]
- [ ] Email: [Your Email]
- [ ] Sign-in required: Yes (if auth is required)
- [ ] Demo account (if needed):
  - [ ] Username: [test account]
  - [ ] Password: [test password]
- [ ] Notes: Optional testing instructions

### Screenshots & Media
- [ ] iPhone 6.7" - Upload 3-10 screenshots from `Assets/AppStore/Screenshots/iPhone_6.7/`
- [ ] App Icon automatically pulled from build

### Export Compliance
- [ ] Uses encryption: Yes
- [ ] Exempt from export compliance: Yes
- [ ] Uses standard encryption: Yes (HTTPS only)

### Advertising
- [ ] Uses IDFA: No
- [ ] Contains ads: No
- [ ] Third-party advertising: No

### Content Rights
- [ ] I certify that I have the rights to use all content in my app: Yes

### Submit
- [ ] Review all information
- [ ] Click "Add for Review"
- [ ] Click "Submit for Review"
- [ ] Confirmation email received

## Post-Submission

### Monitoring
- [ ] Check App Store Connect daily for status updates
- [ ] Check email for App Review messages
- [ ] Status progression:
  - "Waiting for Review" (few hours to 1 day)
  - "In Review" (few hours)
  - "Pending Developer Release" or "Ready for Sale"

### If Rejected
- [ ] Read rejection reason carefully
- [ ] Fix the specific issues mentioned
- [ ] Respond to App Review team if clarification needed
- [ ] Upload new build if code changes required
- [ ] Resubmit for review

### If Approved
- [ ] App appears in App Store within 24 hours
- [ ] Verify app listing looks correct
- [ ] Test download and installation
- [ ] Share App Store link!
- [ ] Announce on social media
- [ ] Monitor user feedback and ratings

## Important Notes

### For Testing Submission
Since you mentioned this is just for testing:
- You can use placeholder screenshots (app running on simulator)
- Privacy policy can be basic (but must exist and be hosted)
- App icon can be simple (but must be 1024x1024 PNG)
- Description can be draft version

### For Production Release
Before releasing to the world:
- Create professional app icon
- Capture polished screenshots with real data
- Have a legal professional review privacy policy
- Complete thorough testing on multiple devices
- Set up support infrastructure (email, website)
- Create marketing materials
- Plan launch strategy

## Quick Command Reference

### Capture Screenshot from Simulator
```bash
xcrun simctl io booted screenshot ~/Desktop/pathio-screenshot.png
```

### Check Build Status
```bash
# List archives
ls ~/Library/Developer/Xcode/Archives/
```

### Flutter Build (Alternative to Xcode)
```bash
flutter build ipa --release
# Output: build/ios/archive/Runner.xcarchive
```

## Estimated Timeline

| Stage | Time | Action Required |
|-------|------|-----------------|
| Prepare assets | 1-2 hours | Create icons, screenshots, privacy policy |
| Configure Xcode | 15 minutes | Set up signing, verify settings |
| Build & Archive | 10-15 minutes | Wait for Xcode to compile |
| Upload to App Store | 20-30 minutes | Wait for processing |
| Complete metadata | 30 minutes | Fill in App Store Connect |
| Submit for review | 5 minutes | Final submission |
| **Waiting for Review** | **1-3 days** | **Monitor App Store Connect** |
| In Review | Few hours | Wait |
| **TOTAL ACTIVE TIME** | **~3 hours** | |
| **TOTAL WAIT TIME** | **1-3 days** | |

## Support Resources

- **App Store Connect**: https://appstoreconnect.apple.com
- **Developer Portal**: https://developer.apple.com/account
- **Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **App Store Quick Guide**: `/docs/APP_STORE_QUICK_GUIDE.md`
- **Full Deployment Guide**: `/docs/APPLE_APP_STORE_DEPLOYMENT.md`

## Current Status

- [x] App rebranded to "Pathio"
- [x] Bundle ID changed to com.pathio.travel
- [x] iPhone registered in Developer Portal
- [x] Signing configured in Xcode
- [x] Assets folder created
- [ ] App icon created (placeholder ready, needs final design)
- [ ] Screenshots captured (simulator running, ready to capture)
- [ ] Privacy policy hosted publicly
- [ ] Build archived and uploaded
- [ ] Metadata submitted in App Store Connect

## Next Immediate Steps

1. **Capture 3 screenshots** from running simulator
2. **Create simple app icon** (or use placeholder for testing)
3. **Host privacy policy** (GitHub Pages, Netlify, or simple web hosting)
4. **Archive app in Xcode**
5. **Upload to App Store Connect**
6. **Fill in metadata**
7. **Submit for review**

---

**You're almost there! 🚀**

The hard part (development) is done. Now it's just about packaging and submission.
