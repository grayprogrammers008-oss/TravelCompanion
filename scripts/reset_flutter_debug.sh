#!/bin/bash
# Flutter Debug Reset Script
# Fixes "Error connecting to the service protocol" errors
# Usage: Run this script when encountering Flutter debug connection issues

echo "============================================"
echo "Flutter Debug Reset Script"
echo "============================================"
echo ""

echo "[1/5] Killing all Flutter/Dart processes..."
killall -9 dart 2>/dev/null || true
killall -9 dartaotruntime 2>/dev/null || true
killall -9 flutter_tools 2>/dev/null || true
echo "Done!"
echo ""

echo "[2/5] Cleaning Flutter build cache..."
cd "$(dirname "$0")/.."
flutter clean
echo "Done!"
echo ""

echo "[3/5] Removing .dart_tool directory..."
if [ -d ".dart_tool" ]; then
    rm -rf .dart_tool
    echo "Done!"
else
    echo ".dart_tool directory not found, skipping..."
fi
echo ""

echo "[4/5] Getting Flutter dependencies..."
flutter pub get
echo "Done!"
echo ""

echo "[5/5] Checking Flutter environment..."
flutter doctor
echo ""

echo "============================================"
echo "Reset Complete!"
echo "============================================"
echo ""
echo "You can now:"
echo "  1. Restart your IDE/Editor (VS Code, Android Studio, etc.)"
echo "  2. Run: flutter run"
echo "  3. Or run with verbose logging: flutter run -v"
echo ""
echo "If issues persist, check: FIX_SERVICE_PROTOCOL_ERROR.md"
echo "============================================"
