@echo off
REM Flutter Debug Reset Script
REM Fixes "Error connecting to the service protocol" errors
REM Usage: Run this script when encountering Flutter debug connection issues

echo ============================================
echo Flutter Debug Reset Script
echo ============================================
echo.

echo [1/5] Killing all Flutter/Dart processes...
taskkill //F //IM dart.exe //T >nul 2>&1
taskkill //F //IM dartaotruntime.exe //T >nul 2>&1
taskkill //F //IM flutter_tools.exe //T >nul 2>&1
echo Done!
echo.

echo [2/5] Cleaning Flutter build cache...
cd /d "%~dp0.."
call flutter clean
echo Done!
echo.

echo [3/5] Removing .dart_tool directory...
if exist ".dart_tool" (
    rmdir /s /q .dart_tool
    echo Done!
) else (
    echo .dart_tool directory not found, skipping...
)
echo.

echo [4/5] Getting Flutter dependencies...
call flutter pub get
echo Done!
echo.

echo [5/5] Checking Flutter environment...
call flutter doctor
echo.

echo ============================================
echo Reset Complete!
echo ============================================
echo.
echo You can now:
echo   1. Restart your IDE/Editor (VS Code, Android Studio, etc.)
echo   2. Run: flutter run
echo   3. Or run with verbose logging: flutter run -v
echo.
echo If issues persist, check: FIX_SERVICE_PROTOCOL_ERROR.md
echo ============================================

pause
