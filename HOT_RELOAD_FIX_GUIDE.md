# Hot Reload Not Working - Fix Guide

## Problem
When running `flutter run`, changes to the code are not reflected in the app. Hot reload (pressing 'r' or clicking hot reload button) doesn't update the UI.

## Common Causes & Solutions

### Solution 1: Full Rebuild (Quick Fix)

**When to use:** First thing to try, works 90% of the time

```bash
# Stop the running app (Ctrl+C in terminal or stop button in IDE)

# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Full rebuild and run
flutter run
```

**Alternative - Hot Restart:**
While app is running, press **`R`** (capital R) for hot restart instead of `r` (hot reload).

---

### Solution 2: Stateful Widget Issues

**Cause:** Hot reload doesn't work well with changes to `initState()`, constructors, or global variables.

**Fix:** Use **Hot Restart** instead of Hot Reload

```bash
# While app is running:
# Press 'R' (capital R) - Hot Restart
# Or press 'r' (lowercase) - Hot Reload
```

**Changes that require Hot Restart (R):**
- Modifying `initState()`
- Changing constructors
- Adding/removing dependencies
- Modifying global variables
- Changing enum values
- Updating `main()` function

**Changes that work with Hot Reload (r):**
- UI changes (widgets, layouts)
- Text changes
- Colors, styles
- Widget properties
- Function implementations (not signatures)

---

### Solution 3: Clear Derived Data / Cache

**For persistent issues:**

```bash
# 1. Stop the app

# 2. Clean Flutter cache
flutter clean

# 3. Delete build folders manually (if needed)
# Windows PowerShell:
Remove-Item -Recurse -Force .\build
Remove-Item -Recurse -Force .\.dart_tool
Remove-Item -Recurse -Force .\android\.gradle
Remove-Item -Recurse -Force .\android\app\build
Remove-Item -Recurse -Force .\ios\Pods
Remove-Item -Recurse -Force .\ios\.symlinks

# 4. Re-fetch dependencies
flutter pub get

# 5. For iOS (if applicable)
cd ios
pod deintegrate
pod install
cd ..

# 6. Full rebuild
flutter run
```

---

### Solution 4: Check for Code Errors

**Cause:** Silent compilation errors prevent hot reload

**Check for errors:**

```bash
# Run static analysis
flutter analyze

# Check for any errors or warnings
# Fix all errors before hot reloading
```

**Common error locations:**
- Missing imports
- Typos in class/variable names
- Unclosed brackets or parentheses
- Missing return statements
- Type mismatches

---

### Solution 5: Riverpod Provider Issues

**Cause:** Changes to providers don't always hot reload properly

**Specific to this project (using Riverpod):**

```dart
// If you changed a provider, you may need to:

// 1. Run code generation (if using riverpod_generator)
flutter pub run build_runner build --delete-conflicting-outputs

// 2. Then hot restart (not just reload)
// Press 'R' in terminal
```

**For provider changes:**
- Adding new providers → Hot Restart
- Changing provider logic → Hot Reload usually works
- Changing provider dependencies → Hot Restart

---

### Solution 6: Check File Watcher

**Cause:** IDE or Flutter not detecting file changes

**VS Code:**
1. Check if file watcher limit is reached (Linux/Mac)
2. Increase file watcher limit:

```bash
# For Linux/Mac
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**For Windows:**
- Usually not an issue, but restart VS Code if needed

---

### Solution 7: Emulator/Device Issues

**Android Emulator:**
```bash
# 1. Stop the app
# 2. Close emulator
# 3. Wipe emulator data
# In Android Studio: AVD Manager → Actions → Wipe Data

# 4. Restart emulator
# 5. Run app again
flutter run
```

**Physical Device:**
```bash
# 1. Uninstall the app completely from device
# 2. Disconnect and reconnect device
# 3. Check device is detected
flutter devices

# 4. Install fresh
flutter run
```

---

### Solution 8: Check main.dart Entry Point

**Cause:** Issues with the main app entry point

**Verify main.dart structure:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Your initialization code

  runApp(
    ProviderScope(  // For Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... your app config
    );
  }
}
```

**If you're using ConsumerWidget or other Riverpod widgets at root level, hot reload may be limited.**

---

### Solution 9: Network/Firewall Issues

**Cause:** Flutter DevTools connection blocked

**Check:**
1. Firewall isn't blocking Flutter DevTools
2. Dart VM service is running (should see URL in console)
3. Try different port:

```bash
flutter run --dart-vm-service-port=8080
```

---

### Solution 10: Specific to This Project

**For Travel Companion app:**

```bash
# 1. Clean everything
flutter clean

# 2. Remove generated files (if any)
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete

# 3. Re-run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Get dependencies
flutter pub get

# 5. Rebuild
flutter run
```

---

## Best Practices for Reliable Hot Reload

### Do's ✅

1. **Save files** before hot reloading (Ctrl+S)
2. **Fix all errors** before attempting hot reload
3. **Use Hot Restart (R)** for structural changes
4. **Use Hot Reload (r)** for UI-only changes
5. **Keep terminal window visible** to see reload messages
6. **Check console output** for reload success/failure

### Don'ts ❌

1. **Don't modify** `initState()` and expect hot reload
2. **Don't change** constructor signatures without restart
3. **Don't add** new packages without stopping app
4. **Don't expect** global variable changes to hot reload
5. **Don't ignore** analyzer warnings/errors

---

## Debug Hot Reload

### Enable Verbose Output

```bash
# Run with verbose logging
flutter run -v
```

### Check Hot Reload Status

When you press 'r', you should see:
```
Performing hot reload...
Reloaded 1 of 523 libraries in 1,234ms.
```

If you see errors, they'll appear here.

### Common Error Messages

**"Cannot find VM service"**
- Solution: Stop and restart app

**"Hot reload not supported"**
- Solution: Some widgets don't support hot reload, use hot restart

**"Compilation error"**
- Solution: Fix the code error shown

---

## Quick Troubleshooting Flowchart

```
Hot Reload Not Working?
    ↓
Are there compilation errors? → YES → Fix errors first
    ↓ NO
Did you change initState/constructor? → YES → Use Hot Restart (R)
    ↓ NO
Is this the first run after code change? → YES → Try Hot Reload (r)
    ↓ NO
Did you add/remove packages? → YES → Stop app → flutter pub get → flutter run
    ↓ NO
Try: flutter clean → flutter pub get → flutter run
    ↓ STILL NOT WORKING?
Delete build folders → flutter pub get → flutter run
```

---

## For This Specific Project (Travel Companion)

### Common Scenarios

**1. Changed a Messaging Provider:**
```bash
# Stop app
# Press Ctrl+C

# Rebuild
flutter run

# Then use Hot Restart (R) instead of Hot Reload (r)
```

**2. Modified Sync Services:**
```bash
# Services are singletons, changes need full restart
flutter run
```

**3. Updated UI (Widgets only):**
```bash
# Hot Reload should work
# Press 'r'
```

**4. Added New Dependencies:**
```bash
# Stop app
# flutter pub get
# flutter run
```

**5. Changed Build Configuration:**
```bash
# Stop app
# flutter clean
# flutter pub get
# flutter run
```

---

## Performance Tips

### Faster Rebuilds

```bash
# Use debug mode for development
flutter run --debug

# Profile mode for testing performance
flutter run --profile

# Release mode for final testing
flutter run --release
```

### Incremental Builds

Once app is running:
- **Small UI change:** Press `r` (hot reload) - ~1-2 seconds
- **Logic change:** Press `R` (hot restart) - ~3-5 seconds
- **Full rebuild:** Stop + `flutter run` - ~30-60 seconds

---

## IDE-Specific Solutions

### VS Code

1. **Restart Dart/Flutter Extension:**
   - `Ctrl+Shift+P` → "Reload Window"

2. **Check Flutter extension is up to date:**
   - Extensions → Search "Flutter" → Update if available

3. **Enable auto-save:**
   - File → Auto Save (checkmark it)

4. **Verify Flutter path:**
   - `Ctrl+Shift+P` → "Flutter: Change SDK"

### Android Studio / IntelliJ

1. **Invalidate Caches:**
   - File → Invalidate Caches → Invalidate and Restart

2. **Rebuild Project:**
   - Build → Rebuild Project

3. **Sync Gradle Files:**
   - File → Sync Project with Gradle Files

---

## Still Not Working?

### Nuclear Option (Last Resort)

```bash
# 1. Delete all build artifacts
Remove-Item -Recurse -Force .\build, .\.dart_tool, .\android\build, .\android\.gradle, .\ios\Pods, .\ios\.symlinks

# 2. Delete pubspec.lock
Remove-Item pubspec.lock

# 3. Re-fetch everything
flutter pub get

# 4. For Android: Clean Gradle
cd android
.\gradlew clean
cd ..

# 5. Full rebuild
flutter run
```

### Check Flutter Installation

```bash
# Verify Flutter is working
flutter doctor -v

# Upgrade Flutter (if needed)
flutter upgrade

# Downgrade if latest is buggy
flutter downgrade
```

---

## Summary: Quick Reference

| Issue | Solution | Command |
|-------|----------|---------|
| First thing to try | Hot Restart | Press `R` |
| UI changes only | Hot Reload | Press `r` |
| Logic/provider changes | Hot Restart | Press `R` |
| Added package | Full rebuild | `flutter run` |
| Persistent issues | Clean rebuild | `flutter clean && flutter run` |
| Nothing works | Nuclear option | Delete all build folders → rebuild |

---

**Last Updated:** 2025-10-25
**Flutter Version:** 3.35.6
**Project:** Travel Companion
