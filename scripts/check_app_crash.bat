@echo off
echo ================================================
echo TravelCompanion App Crash Diagnostic Tool
echo ================================================
echo.

echo Step 1: Checking emulator status...
adb devices
echo.

echo Step 2: Clearing app data...
adb shell pm clear com.example.travel_crew
echo.

echo Step 3: Uninstalling old version...
adb uninstall com.example.travel_crew
echo.

echo Step 4: Installing fresh build...
cd /d "%~dp0.."
flutter install
echo.

echo Step 5: Checking logcat for crashes...
echo [Press Ctrl+C to stop watching logs]
adb logcat *:E | findstr /C:"FATAL" /C:"AndroidRuntime" /C:"travel_crew"
