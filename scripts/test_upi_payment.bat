@echo off
REM Quick test script for UPI payment module

echo ===================================
echo UPI Payment Module - Quick Test
echo ===================================
echo.

REM Run unit tests
echo [1/4] Running unit tests...
call flutter test test\core\services\payment_service_test.dart --reporter=compact
echo.

REM Check test coverage
echo [2/4] Generating coverage report...
call flutter test --coverage test\core\services\payment_service_test.dart
if exist coverage\lcov.info (
    echo Coverage file generated: coverage\lcov.info
) else (
    echo Warning: Coverage file not generated
)
echo.

REM Analyze code
echo [3/4] Analyzing code...
call flutter analyze lib\core\services\payment_service.dart
echo.

REM Build APK
echo [4/4] Building debug APK...
call flutter build apk --debug
echo.

echo ===================================
echo Done! Tests Complete
echo ===================================
echo.
echo Next steps:
echo   1. Install APK on device: build\app\outputs\flutter-apk\app-debug.apk
echo   2. Test with real UPI apps (GPay, PhonePe, Paytm)
echo   3. Verify all scenarios work
echo   4. Check docs\UPI_PAYMENT_TESTING_GUIDE.md for detailed test cases
echo.

pause
