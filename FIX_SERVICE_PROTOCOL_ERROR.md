# Fix: Service Protocol Connection Error

**Error Message:**
```
Error connecting to the service protocol: failed to connect to
http://127.0.0.1:51001/f8p12WVgwTA=/ HttpException: Connection closed before full
header was received, uri = http://127.0.0.1:51001/f8p12WVgwTA=/ws
```

---

## Root Causes

This error occurs when:
1. **Multiple Flutter/Dart processes** are running and causing port conflicts
2. **Stale debug sessions** are holding onto service protocol connections
3. **Build cache corruption** preventing proper service initialization
4. **Firewall/Antivirus** blocking local connections
5. **Port already in use** by another application

---

## Quick Fix (Recommended)

Run these commands in sequence:

### 1. Kill All Flutter/Dart Processes
```bash
# Windows
taskkill //F //IM dart.exe //T
taskkill //F //IM dartaotruntime.exe //T
taskkill //F //IM flutter_tools.exe //T

# Linux/Mac
killall -9 dart
killall -9 dartaotruntime
killall -9 flutter_tools
```

### 2. Clean Flutter Build Cache
```bash
cd "d:\Nithya\Travel Companion\TravelCompanion"
flutter clean
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Restart Your IDE/Editor
- **VS Code**: Close and reopen VS Code
- **Android Studio**: File → Invalidate Caches → Restart

### 5. Run Flutter App in Fresh Session
```bash
# For Android Emulator
flutter run

# For specific device
flutter devices
flutter run -d <device-id>

# For hot restart
flutter run --hot
```

---

## Detailed Solutions

### Solution 1: Clean Restart (Most Effective)

```bash
# Step 1: Kill all Flutter processes
taskkill //F //IM dart.exe //T
taskkill //F //IM dartaotruntime.exe //T

# Step 2: Clean project
flutter clean

# Step 3: Delete .dart_tool directory
rm -rf .dart_tool/

# Step 4: Get dependencies
flutter pub get

# Step 5: Run with verbose logging to see connection details
flutter run -v
```

---

### Solution 2: Check Port Availability

The service protocol uses dynamic ports (usually 50000-60000 range). Check if ports are blocked:

```bash
# Windows: Check what's using ports
netstat -ano | findstr "51001"

# If something is using the port, kill it
taskkill //F //PID <PID>
```

---

### Solution 3: Disable Hot Reload Temporarily

If hot reload is causing issues, disable it:

```bash
flutter run --no-hot
```

Or in your IDE:
- VS Code: Set `"flutter.hotReloadOnSave": false` in settings
- Android Studio: Disable "Hot Reload on Save"

---

### Solution 4: Use Different Observatory Port

Force Flutter to use a specific port:

```bash
flutter run --observatory-port=8181
```

---

### Solution 5: Check Firewall/Antivirus

1. **Windows Defender Firewall:**
   - Go to: Control Panel → Windows Defender Firewall → Allow an app
   - Add `dart.exe` and `dartaotruntime.exe` from:
     - `D:\Nithya\Travel Companion\TravelCompanion\flutter\bin\cache\dart-sdk\bin\`
   - Allow both Private and Public networks

2. **Third-party Antivirus:**
   - Add exceptions for Flutter SDK directory
   - Temporarily disable to test if it's the cause

---

### Solution 6: Reset Flutter Configuration

```bash
# Remove Flutter settings
rm -rf ~/.flutter
rm -rf %LOCALAPPDATA%\Pub\Cache

# Reconfigure Flutter
flutter doctor -v
flutter config --clear-features
flutter doctor --android-licenses
```

---

### Solution 7: Update Flutter

Sometimes this is caused by Flutter version bugs:

```bash
flutter upgrade
flutter doctor -v
```

---

## Prevention Tips

### 1. Always Stop Debug Sessions Properly
- Don't force-close the IDE while debugging
- Use "Stop" button instead of closing terminal
- Exit debug mode before closing IDE

### 2. Regular Cleanup
```bash
# Weekly maintenance
flutter clean
flutter pub get
```

### 3. Use Flutter DevTools Properly
```bash
# Launch DevTools separately if needed
flutter pub global activate devtools
flutter pub global run devtools
```

### 4. Monitor Running Processes
```bash
# Before starting new debug session
tasklist | findstr "dart"
# If processes are hanging, kill them
```

---

## VS Code Specific Fixes

### 1. Update Extensions
- Update Flutter extension to latest
- Update Dart extension to latest

### 2. Clear VS Code Cache
```bash
# Windows
rmdir /s /q %APPDATA%\Code\Cache
rmdir /s /q %APPDATA%\Code\CachedData

# Then restart VS Code
```

### 3. VS Code Settings
Add to `.vscode/settings.json`:
```json
{
  "dart.flutterRunAdditionalArgs": [
    "--no-sound-null-safety"
  ],
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false
}
```

---

## Android Studio Specific Fixes

### 1. Invalidate Caches
- File → Invalidate Caches → Invalidate and Restart

### 2. Rebuild Project
- Build → Clean Project
- Build → Rebuild Project

### 3. Reset ADB
```bash
adb kill-server
adb start-server
```

---

## Verification Steps

After applying fixes, verify the connection works:

```bash
# 1. Check Flutter doctor
flutter doctor -v

# 2. Run with verbose logging
flutter run -v

# 3. Watch for successful service protocol connection
# You should see: "Successfully connected to service protocol"
```

---

## Still Having Issues?

### Check Logs
```bash
# Flutter logs
flutter logs

# VS Code logs
# View → Output → Select "Flutter" or "Dart"

# Check dart-sdk logs
type "%LOCALAPPDATA%\Temp\dart_*.log"
```

### Report Issue
If problem persists, gather information and report:
```bash
flutter doctor -v > flutter_info.txt
flutter run -v > flutter_run.txt 2>&1
```

---

## Summary Checklist

- [ ] Kill all Dart/Flutter processes
- [ ] Run `flutter clean`
- [ ] Delete `.dart_tool` directory
- [ ] Run `flutter pub get`
- [ ] Restart IDE/Editor
- [ ] Check firewall/antivirus settings
- [ ] Verify no port conflicts
- [ ] Run `flutter run -v` to see detailed logs
- [ ] If still failing, try different port with `--observatory-port`
- [ ] Update Flutter if using old version

---

## Quick Reference Commands

```bash
# Full reset sequence (copy-paste friendly)
taskkill //F //IM dart.exe //T
taskkill //F //IM dartaotruntime.exe //T
cd "d:\Nithya\Travel Companion\TravelCompanion"
flutter clean
rmdir /s /q .dart_tool
flutter pub get
flutter run -v
```

---

**Last Updated:** 2025-10-25
**Status:** ✅ Processes killed, cache cleaned, ready for fresh start
