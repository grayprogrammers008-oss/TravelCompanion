# Android App Crash Diagnostic Script

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " TravelCompanion Crash Diagnostic" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Set paths
$adb = "C:\Users\bsent\AppData\Local\Android\sdk\platform-tools\adb.exe"
$package = "com.pathio.travel"

# Step 1: Check device connection
Write-Host "Step 1: Checking device connection..." -ForegroundColor Yellow
& $adb devices
Write-Host ""

# Step 2: Clear logcat
Write-Host "Step 2: Clearing logcat..." -ForegroundColor Yellow
& $adb logcat -c
Write-Host "Logcat cleared" -ForegroundColor Green
Write-Host ""

# Step 3: Force stop the app
Write-Host "Step 3: Force stopping app..." -ForegroundColor Yellow
& $adb shell am force-stop $package
Write-Host "App stopped" -ForegroundColor Green
Write-Host ""

# Step 4: Clear app data
Write-Host "Step 4: Clearing app data..." -ForegroundColor Yellow
& $adb shell pm clear $package
Write-Host ""

# Step 5: Start the app
Write-Host "Step 5: Starting app..." -ForegroundColor Yellow
& $adb shell am start -n "${package}/.MainActivity"
Write-Host ""

# Step 6: Wait for crash
Write-Host "Step 6: Waiting 5 seconds for app to start/crash..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Write-Host ""

# Step 7: Get crash logs
Write-Host "Step 7: Capturing crash logs..." -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Red
& $adb logcat -d | Select-String -Pattern "FATAL|AndroidRuntime|Exception|Error" | Select-Object -First 50
Write-Host "======================================" -ForegroundColor Red
Write-Host ""

# Step 8: Get app-specific logs
Write-Host "Step 8: Getting app-specific logs..." -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan
& $adb logcat -d | Select-String -Pattern $package | Select-Object -First 30
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Step 9: Check if app is running
Write-Host "Step 9: Checking if app process is running..." -ForegroundColor Yellow
$process = & $adb shell ps | Select-String -Pattern $package
if ($process) {
    Write-Host "✅ App is running!" -ForegroundColor Green
    Write-Host $process
} else {
    Write-Host "❌ App is NOT running (crashed)" -ForegroundColor Red
}
Write-Host ""

Write-Host "Diagnostic complete!" -ForegroundColor Cyan
Write-Host "If the app crashed, check the FATAL/Exception logs above" -ForegroundColor Yellow
