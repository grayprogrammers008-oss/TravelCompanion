# 📱 iOS Simulator Issue - Complete Fix Guide

## 🐛 The Problem

You're getting this error:
```
Unable to find a destination matching the provided destination specifier
iOS 26.0 is not installed. Please download and install the platform from Xcode > Settings > Components.
Could not build the application for the simulator.
```

## 🔍 Root Cause

**Your System**:
- ✅ Xcode 26.0.1 installed
- ✅ iOS Simulator SDK 26.0 (comes with Xcode)
- ❌ iOS 26.0 Simulator Runtime NOT installed
- ✅ iOS 17.2 and 17.4 Simulator Runtimes installed

**The Issue**: Your Xcode version (26.0.1) has SDK 26.0, but you only have iOS 17.x simulator runtimes. The SDK and runtime are different things!

---

## ✅ Solution Options

### Option 1: Install iOS 26.0 Simulator Runtime (Recommended)

This will allow you to use the latest iOS simulator.

#### Step-by-Step:

1. **Open Xcode**

2. **Go to Settings/Preferences**:
   - Click **Xcode** in menu bar → **Settings** (or press `⌘,`)

3. **Navigate to Components**:
   - Click **Platforms** tab (or **Components** in older Xcode)

4. **Download iOS 26.0 Simulator**:
   - Find "iOS 26.0 Simulator" in the list
   - Click the **Download** button (⬇️)
   - Wait for download to complete (can take 10-30 minutes, ~8GB)

5. **Verify Installation**:
   ```bash
   xcrun simctl list runtimes | grep iOS
   ```

   You should see:
   ```
   iOS 26.0 (26.0 - xxxxx) - com.apple.CoreSimulator.SimRuntime.iOS-26-0
   ```

6. **Run Your App**:
   ```bash
   ./run_ios.sh
   ```

---

### Option 2: Use iOS 17 Simulator (Requires Xcode Downgrade)

If you don't want to download iOS 26.0 runtime, you'd need to use an older Xcode version that matches your iOS 17.x runtimes.

**Not recommended** because:
- Xcode 26.x is already installed
- You'd lose the latest features
- More complex to manage multiple Xcode versions

---

### Option 3: Test on Physical Device (Workaround)

If you have an iPhone/iPad, you can test on the real device while waiting for the simulator runtime to download.

#### Steps:

1. **Connect iPhone via USB**

2. **Trust Computer** on iPhone when prompted

3. **Check Device is Detected**:
   ```bash
   flutter devices
   ```

   You should see your iPhone listed.

4. **Run on Device**:
   ```bash
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8
   flutter run
   ```

5. **On iPhone**:
   - Go to: Settings → General → VPN & Device Management
   - Trust your developer certificate

---

### Option 4: Use Android Emulator (Alternative Platform)

While iOS simulator downloads, you can test on Android:

1. **Open Android Studio**

2. **Start Android Emulator**:
   - Tools → Device Manager
   - Click ▶️ on any emulator

3. **Run App**:
   ```bash
   flutter run
   ```

---

## 🚀 Quick Commands

### Check What Simulators You Have:
```bash
xcrun simctl list devices available
```

### Check What Runtimes Are Installed:
```bash
xcrun simctl list runtimes
```

### List All Flutter Devices:
```bash
flutter devices
```

### Boot a Specific Simulator:
```bash
# Boot iPhone 15 Pro Max (iOS 17.4)
xcrun simctl boot 79D3D6FF-63C5-4EDD-A438-B71B9DECB033
open -a Simulator
```

---

## 📊 Understanding the Versions

| Component | Your Version | What It Is |
|-----------|--------------|------------|
| Xcode | 26.0.1 | Development environment |
| iOS SDK | 26.0 | Compile-time SDK (for building) |
| iOS Simulator Runtime | 17.2, 17.4 | Actual iOS version to run on |
| Needed | 26.0 | Missing runtime to match SDK |

**Analogy**: You have a compiler (SDK 26.0) but not the operating system (Runtime 26.0) to run the compiled app on.

---

## ⏱️ Download Size & Time

**iOS 26.0 Simulator Runtime**:
- Size: ~7-10 GB
- Time: 10-30 minutes (depending on internet speed)
- Location: Downloads via Xcode Settings → Platforms

---

## 🔧 Troubleshooting

### Issue: Can't find "Platforms" or "Components" in Xcode Settings
**Xcode Version**: Depends on your Xcode version
- Xcode 14+: Settings → Platforms
- Xcode 12-13: Preferences → Components
- Try both locations

### Issue: Download fails or hangs
**Solutions**:
1. Check internet connection
2. Restart Xcode
3. Try downloading from command line:
   ```bash
   xcodebuild -downloadPlatform iOS
   ```

### Issue: Not enough disk space
**Solution**:
- Free up at least 15 GB of disk space
- Delete old Xcode simulators you don't need:
  ```bash
  xcrun simctl delete unavailable
  ```

### Issue: "iOS 26.0 not available in list"
**Possible reasons**:
- Your Xcode might need an update
- Check for Xcode updates in App Store
- Or the runtime might already be installed (check with `xcrun simctl list runtimes`)

---

## 📝 Step-by-Step Walkthrough

### Complete Process:

1. **Open Xcode**
   ```bash
   open -a Xcode
   ```

2. **Open Settings**
   - Menu Bar: Xcode → Settings (or press `⌘,`)

3. **Go to Platforms Tab**
   - Click "Platforms" in the settings window

4. **Find iOS 26.0**
   - Look for "iOS 26.0" or "Simulator - iOS 26.0"

5. **Click Download Icon**
   - Click the download button (⬇️ icon)
   - Enter your Apple ID password if prompted

6. **Wait for Download**
   - You'll see progress in the Platforms window
   - Keep Xcode open during download

7. **Verify Installation**
   ```bash
   xcrun simctl list runtimes | grep "iOS 26"
   ```

8. **Create/Boot Simulator**
   ```bash
   # Xcode will auto-create iPhone simulators for iOS 26
   # Or open: Xcode → Window → Devices and Simulators → Simulators tab
   ```

9. **Run Your App**
   ```bash
   cd /Users/vinothvs/Development/TravelCompanion
   ./run_ios.sh
   ```

---

## ✅ After Installation

Once iOS 26.0 runtime is installed:

```bash
# Check it's there
xcrun simctl list runtimes

# Boot a new iOS 26 simulator
open -a Simulator

# Run your app
./run_ios.sh
```

Your app should launch successfully! 🎉

---

## 🎯 Quick Fix Summary

**Fastest Solution**:
1. Open Xcode
2. Xcode → Settings → Platforms
3. Download "iOS 26.0 Simulator"
4. Wait for download
5. Run `./run_ios.sh`

**Time Required**: 15-45 minutes (mostly download time)

---

## 💡 Pro Tip

While the iOS 26.0 simulator downloads, you can:
1. Test on Android emulator
2. Test on physical iPhone (if you have one)
3. Review the code
4. Read the documentation I created

---

## 📱 Alternative: Test on Android Now

Don't want to wait? Test on Android:

```bash
# Open Android Studio, start any emulator, then:
flutter run
```

The app will run on Android while iOS simulator downloads in the background.

---

## 🎉 Once Working

After iOS 26.0 is installed, your workflow will be:

```bash
# Just run this:
./run_ios.sh

# Or manually:
flutter run
```

Simple as that!

---

**Status**: ⏳ Waiting for iOS 26.0 Simulator Runtime Download
**Action Required**: Download iOS 26.0 via Xcode Settings → Platforms
**ETA**: 15-45 minutes
**Alternative**: Use Android emulator or physical device

Good luck! 🚀
