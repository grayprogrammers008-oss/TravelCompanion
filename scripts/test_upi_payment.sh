#!/bin/bash
# Quick test script for UPI payment module

echo "==================================="
echo "UPI Payment Module - Quick Test"
echo "==================================="

# Run unit tests
echo ""
echo "[1/4] Running unit tests..."
flutter test test/core/services/payment_service_test.dart --reporter=compact

# Check test coverage
echo ""
echo "[2/4] Generating coverage report..."
flutter test --coverage test/core/services/payment_service_test.dart
if command -v lcov &> /dev/null; then
    lcov --summary coverage/lcov.info
else
    echo "Note: lcov not installed. Skipping coverage summary."
    echo "Coverage file generated: coverage/lcov.info"
fi

# Analyze code
echo ""
echo "[3/4] Analyzing code..."
flutter analyze lib/core/services/payment_service.dart

# Build APK
echo ""
echo "[4/4] Building debug APK..."
flutter build apk --debug

echo ""
echo "==================================="
echo "✅ Tests Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo "  1. Install APK on device: build/app/outputs/flutter-apk/app-debug.apk"
echo "  2. Test with real UPI apps (GPay, PhonePe, Paytm)"
echo "  3. Verify all scenarios work"
echo "  4. Check docs/UPI_PAYMENT_TESTING_GUIDE.md for detailed test cases"
