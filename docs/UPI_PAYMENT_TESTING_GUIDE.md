# UPI Payment Module - Complete Testing Guide

**Version:** 1.0
**Last Updated:** 2025-10-25
**Module:** Payment Service (UPI Integration)

---

## Table of Contents

1. [Overview](#overview)
2. [Testing Environment Setup](#testing-environment-setup)
3. [Unit Testing](#unit-testing)
4. [Manual Testing on Android](#manual-testing-on-android)
5. [Manual Testing on iOS](#manual-testing-on-ios)
6. [Integration Testing](#integration-testing)
7. [User Acceptance Testing (UAT)](#user-acceptance-testing-uat)
8. [Test Cases](#test-cases)
9. [Common Issues & Troubleshooting](#common-issues--troubleshooting)
10. [Testing Checklist](#testing-checklist)

---

## Overview

The UPI Payment module enables users to make payments through various UPI apps like:
- **Google Pay** (GPay)
- **PhonePe**
- **Paytm**
- **BHIM**
- **Generic UPI** (Any UPI app)

### Key Features
✅ Generate UPI deep links
✅ Launch specific UPI apps
✅ Auto-detect installed apps
✅ Fallback to alternative apps
✅ Validate UPI IDs
✅ Format payment amounts
✅ Track payment transactions

---

## Testing Environment Setup

### Prerequisites

#### 1. Flutter Environment
```bash
flutter doctor -v
# Ensure all checks pass
```

#### 2. Test Dependencies
All dependencies are already included in `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.5.0
```

#### 3. Physical Devices (Recommended)
- **Android**: Physical device with UPI apps installed
- **iOS**: Physical device (UPI deep links work best on real devices)
- **Emulator**: Can test basic functionality but can't launch actual UPI apps

#### 4. Install UPI Apps on Test Device
Download and install at least 2-3 of these:
- Google Pay
- PhonePe
- Paytm
- BHIM

---

## Unit Testing

### Running Unit Tests

#### Run All Payment Service Tests
```bash
cd "d:\Nithya\Travel Companion\TravelCompanion"
flutter test test/core/services/payment_service_test.dart
```

#### Run Specific Test Group
```bash
# Test UPI link generation only
flutter test test/core/services/payment_service_test.dart --name "UPI Link Generation"

# Test validation only
flutter test test/core/services/payment_service_test.dart --name "Input Validation"

# Test UPI ID validation
flutter test test/core/services/payment_service_test.dart --name "UPI ID Validation"
```

#### Run with Coverage
```bash
flutter test --coverage test/core/services/payment_service_test.dart
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html in browser
```

### Expected Results

✅ **All 50+ unit tests should pass**

```
✓ should generate valid generic UPI link
✓ should generate Google Pay specific link
✓ should generate PhonePe specific link
✓ should generate Paytm specific link
✓ should generate BHIM specific link
✓ should properly URL encode recipient name with spaces
✓ should properly URL encode note with special characters
✓ should format amount to 2 decimal places
✓ should throw error when UPI ID is empty
✓ should throw error when recipient name is empty
✓ should throw error when amount is zero
✓ should throw error when amount is negative
✓ should validate correct UPI ID formats
✓ should reject invalid UPI ID formats
... (50+ more tests)

All tests passed!
```

---

## Manual Testing on Android

### Test Setup

1. **Build and Install App**
```bash
flutter clean
flutter pub get
flutter run --release
# Or
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

2. **Enable Debug Logging**
   - The app logs UPI links in debug mode
   - Check Android Studio Logcat or use:
   ```bash
   adb logcat | grep "UPI"
   ```

### Test Scenarios

#### Scenario 1: Basic Payment Flow

**Steps:**
1. Open app → Navigate to Expenses or Trip Settlement
2. Tap on a user who owes money
3. Tap "Pay Now" or "Request Payment"
4. **Payment sheet appears** with:
   - ✅ Amount displayed clearly
   - ✅ Recipient name shown
   - ✅ UPI ID visible (with copy button)
   - ✅ List of installed UPI apps

5. Select **Google Pay**
6. **Expected:**
   - ✅ GPay opens automatically
   - ✅ Pre-filled amount: ₹[amount]
   - ✅ Pre-filled UPI ID
   - ✅ Pre-filled note/description
   - ✅ Can complete payment

**Success Criteria:**
- App launches within 2 seconds
- All details pre-filled correctly
- User can complete payment

---

#### Scenario 2: Multiple UPI Apps

**Steps:**
1. Install GPay, PhonePe, and Paytm on device
2. Open payment sheet
3. **Verify all 3 apps shown** with:
   - ✅ App icon/name
   - ✅ "Tap to pay" status
   - ✅ Green checkmark or indicator

4. Try each app one by one:
   - Tap **GPay** → Should open GPay
   - Back to app → Tap **PhonePe** → Should open PhonePe
   - Back to app → Tap **Paytm** → Should open Paytm

**Success Criteria:**
- All installed apps detected
- Each app launches correctly
- No errors or crashes

---

#### Scenario 3: No UPI Apps Installed

**Steps:**
1. Test on device **without any UPI apps** (or uninstall all)
2. Open payment sheet
3. **Expected UI:**
   - ⚠️ Warning icon displayed
   - ⚠️ Message: "No UPI Apps Found"
   - ℹ️ Help text: "Please install GPay, PhonePe, or Paytm"
   - 🔘 "Try Anyway" button

4. Tap **"Try Anyway"**
5. **Expected:**
   - Android shows app chooser
   - Or error: "No app found to handle UPI link"

**Success Criteria:**
- Clear error message
- Helpful guidance
- Graceful fallback

---

#### Scenario 4: Invalid UPI ID

**Steps:**
1. Manually modify UPI ID in code (or use test endpoint)
2. Test these invalid UPI IDs:
   - ❌ `invalid` (no @)
   - ❌ `user@` (no provider)
   - ❌ `@paytm` (no user)
   - ❌ `ab@xy` (too short)
   - ❌ `user paytm` (no @, has space)

3. **Expected:**
   - ✅ Validation error shown before launch
   - ✅ User cannot proceed
   - ✅ Clear error message

**Success Criteria:**
- Invalid IDs rejected
- User-friendly error messages
- App doesn't crash

---

#### Scenario 5: Edge Cases - Amounts

**Test Cases:**

| Amount | Expected Behavior |
|--------|-------------------|
| ₹0.01 | ✅ Accepts (minimum valid) |
| ₹0.00 | ❌ Rejects (error shown) |
| -₹100 | ❌ Rejects (error shown) |
| ₹999,999.99 | ✅ Accepts (large amount) |
| ₹500.5 | ✅ Formats to ₹500.50 |

**Steps:**
1. Try each amount above
2. Check amount formatting
3. Verify UPI link contains correct value

**Success Criteria:**
- Proper validation
- Correct formatting (2 decimals)
- Clear error messages

---

#### Scenario 6: Special Characters

**Test Data:**
```
Recipient Name: "John O'Brien-Smith Jr."
Note: "Goa Trip 2024 - Food & Travel!"
UPI ID: "user.name-123@bank_provider"
```

**Steps:**
1. Enter data with special characters
2. Launch payment
3. **Verify in UPI app:**
   - ✅ Name displays correctly
   - ✅ Note displays correctly
   - ✅ Special chars properly encoded

**Success Criteria:**
- All special characters handled
- URL encoding works
- No garbled text in UPI app

---

## Manual Testing on iOS

### iOS-Specific Setup

1. **Build for iOS**
```bash
flutter build ios --release
# Open in Xcode and deploy to device
```

2. **Install UPI Apps:**
   - Google Pay (if available)
   - PhonePe
   - Paytm (if available)
   - BHIM

### iOS-Specific Tests

#### Test 1: Deep Link Handling
- iOS handles deep links differently than Android
- Verify app switching works smoothly
- Test background/foreground transitions

#### Test 2: URL Scheme Registration
- Check if custom URL schemes work
- Verify app returns to TravelCrew after payment

#### Test 3: Universal Links
- Some UPI apps use universal links on iOS
- Verify fallback to web if app not installed

---

## Integration Testing

### Setup Integration Tests

Create `test/integration/payment_integration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_crew/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Flow Integration Tests', () {
    testWidgets('Complete payment flow from expense to UPI app', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to expenses
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      // Find settlement button
      await tester.tap(find.text('Settle Up'));
      await tester.pumpAndSettle();

      // Verify payment sheet appears
      expect(find.text('Choose Payment Method'), findsOneWidget);

      // Verify amount shown
      expect(find.textContaining('₹'), findsWidgets);

      // Take screenshot
      await tester.takeScreenshot('payment_sheet');
    });
  });
}
```

### Run Integration Tests

```bash
flutter test integration_test/payment_integration_test.dart
```

---

## User Acceptance Testing (UAT)

### UAT Checklist

#### For Testers (Non-Technical)

**Scenario A: Make a Payment**
1. ☐ Open app, go to "Expenses"
2. ☐ Find someone you owe money to
3. ☐ Tap "Pay Now"
4. ☐ **Check:** Payment sheet shows correct amount
5. ☐ **Check:** Recipient name is correct
6. ☐ Tap your preferred UPI app (GPay/PhonePe/Paytm)
7. ☐ **Check:** UPI app opens
8. ☐ **Check:** Amount is pre-filled
9. ☐ Complete payment
10. ☐ Return to app
11. ☐ **Check:** Payment status updates

**Scenario B: Request Payment**
1. ☐ Find someone who owes you money
2. ☐ Tap "Request Payment"
3. ☐ **Check:** Your UPI ID is shown
4. ☐ **Check:** Copy button works
5. ☐ Share UPI ID with friend
6. ☐ Verify they can pay you

**Scenario C: Error Handling**
1. ☐ Try payment without UPI apps installed
2. ☐ **Check:** Clear error message shown
3. ☐ **Check:** Helpful instructions provided
4. ☐ **Check:** App doesn't crash

---

## Test Cases

### Critical Path Tests

| Test ID | Description | Priority | Expected Result |
|---------|-------------|----------|-----------------|
| TC001 | Launch Google Pay with ₹500 | 🔴 High | GPay opens, amount pre-filled |
| TC002 | Launch PhonePe with ₹1000 | 🔴 High | PhonePe opens, details correct |
| TC003 | Launch Paytm with ₹250.50 | 🔴 High | Paytm opens, amount formatted |
| TC004 | No UPI apps installed | 🟡 Medium | Error shown, fallback offered |
| TC005 | Invalid UPI ID validation | 🟡 Medium | Error before launch |
| TC006 | Copy UPI ID to clipboard | 🟢 Low | ID copied successfully |
| TC007 | Long recipient names | 🟢 Low | Name displayed correctly |
| TC008 | Special characters in note | 🟢 Low | Characters encoded properly |
| TC009 | Very large amount (₹99,999) | 🟡 Medium | Amount handled correctly |
| TC010 | Very small amount (₹0.01) | 🟡 Medium | Amount formatted to 2 decimals |

### Regression Tests

| Test ID | Description | Frequency |
|---------|-------------|-----------|
| RT001 | All supported UPI apps launch | Every release |
| RT002 | UPI ID validation rules | Every release |
| RT003 | Amount formatting edge cases | Weekly |
| RT004 | Deep link generation accuracy | Every release |
| RT005 | Error handling scenarios | Every release |

---

## Common Issues & Troubleshooting

### Issue 1: UPI App Doesn't Open

**Symptoms:**
- Tap on payment app → nothing happens
- Error: "Cannot launch app"

**Possible Causes:**
1. App not installed
2. Deep link scheme changed
3. Permissions not granted

**Solutions:**
```bash
# Check if app is installed
adb shell pm list packages | grep -i "google.android.apps.nbu.paisa.user"  # GPay
adb shell pm list packages | grep -i "phonepe"  # PhonePe
adb shell pm list packages | grep -i "paytm"    # Paytm

# Check deep link handling
adb shell am start -a android.intent.action.VIEW -d "upi://pay?pa=test@upi&pn=Test&am=1&cu=INR"
```

**Fix in Code:**
- Update deep link schemes in `PaymentService.generateUPILink()`
- Add fallback to generic UPI

---

### Issue 2: Amount Not Pre-filled

**Symptoms:**
- UPI app opens but amount is empty
- Amount shows as ₹0.00

**Possible Causes:**
1. UPI link malformed
2. Amount parameter missing
3. URL encoding issue

**Debug:**
```dart
// Enable debug mode to see generated links
if (kDebugMode) {
  print('Generated UPI Link: $upiLink');
}
```

**Check:**
- UPI link must contain: `am=500.00` (2 decimals)
- Currency must be: `cu=INR`
- No spaces or special characters (should be URL encoded)

---

### Issue 3: Special Characters Break Payment

**Symptoms:**
- UPI app shows garbled text
- Payment fails with invalid characters

**Solution:**
```dart
// Ensure proper URL encoding
final encodedName = Uri.encodeComponent(recipientName);
final encodedNote = Uri.encodeComponent(note);
```

**Test:**
```dart
test('should handle special characters', () {
  final link = paymentService.generateUPILink(
    recipientName: "John O'Brien & Smith",
    note: "Goa Trip - 50%",
    // ...
  );

  expect(link, contains('%20'));  // Space encoded
  expect(link, contains('%26'));  // & encoded
});
```

---

### Issue 4: iOS Deep Links Not Working

**Symptoms:**
- Payment works on Android but not iOS
- App doesn't switch to UPI app on iOS

**Solutions:**
1. **Check URL Schemes in Info.plist:**
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>gpay</string>
    <string>phonepe</string>
    <string>paytm</string>
    <string>upi</string>
</array>
```

2. **Test with Safari:**
   - Open UPI link in Safari
   - Should prompt to open app

3. **Use Universal Links:**
   - Some apps use HTTPS links on iOS
   - Fallback to web payment if needed

---

## Testing Checklist

### Pre-Release Checklist

#### Unit Tests
- [ ] All 50+ unit tests passing
- [ ] Code coverage > 90%
- [ ] No skipped tests

#### Manual Testing - Android
- [ ] Tested on at least 3 different Android devices
- [ ] Tested with GPay, PhonePe, and Paytm
- [ ] Tested with no UPI apps installed
- [ ] Tested all edge cases (amounts, special characters)
- [ ] Tested error scenarios

#### Manual Testing - iOS
- [ ] Tested on iPhone (physical device)
- [ ] Tested with available UPI apps
- [ ] Tested deep link handling
- [ ] Tested app switching

#### Integration Testing
- [ ] End-to-end flow works
- [ ] Payment integrates with expense module
- [ ] Transaction tracking works
- [ ] Screenshots taken for documentation

#### Performance
- [ ] Payment sheet opens in < 1 second
- [ ] UPI app launches in < 2 seconds
- [ ] No memory leaks
- [ ] No crashes or freezes

#### Security
- [ ] UPI IDs validated before use
- [ ] No sensitive data logged in production
- [ ] Proper error messages (no internal errors exposed)

#### Accessibility
- [ ] Screen reader compatible
- [ ] Touch targets >= 44x44 points
- [ ] Color contrast meets WCAG guidelines
- [ ] Error messages announced

---

## Testing Scripts

### Quick Test Script (Bash)

```bash
#!/bin/bash
# Quick test script for UPI payment module

echo "==================================="
echo "UPI Payment Module - Quick Test"
echo "==================================="

# Run unit tests
echo "\n[1/4] Running unit tests..."
flutter test test/core/services/payment_service_test.dart --reporter=compact

# Check test coverage
echo "\n[2/4] Generating coverage report..."
flutter test --coverage test/core/services/payment_service_test.dart
lcov --summary coverage/lcov.info

# Analyze code
echo "\n[3/4] Analyzing code..."
flutter analyze lib/core/services/payment_service.dart

# Build APK
echo "\n[4/4] Building debug APK..."
flutter build apk --debug

echo "\n==================================="
echo "✅ Tests Complete!"
echo "==================================="
echo "\nNext steps:"
echo "  1. Install APK on device"
echo "  2. Test with real UPI apps"
echo "  3. Verify all scenarios work"
```

### Save as: `scripts/test_upi_payment.sh`

**Run:**
```bash
chmod +x scripts/test_upi_payment.sh
./scripts/test_upi_payment.sh
```

---

## Test Data

### Valid Test UPI IDs
```
user@paytm
john.doe@ybl
9876543210@paytm
merchant-123@upi
test_user@bank
```

### Invalid Test UPI IDs
```
invalid          # No @
user@            # No provider
@paytm           # No user
ab@xy            # Too short
user paytm       # No @, has space
user@@paytm      # Double @
```

### Test Amounts
```
Valid:
- ₹0.01  (minimum)
- ₹500.00
- ₹1234.56
- ₹999,999.99 (maximum reasonable)

Invalid:
- ₹0.00  (zero)
- -₹100  (negative)
```

---

## Automated Testing CI/CD

### GitHub Actions Workflow

Create `.github/workflows/test_payment.yml`:

```yaml
name: Test UPI Payment Module

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'lib/core/services/payment_service.dart'
      - 'test/core/services/payment_service_test.dart'
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.35.6'

    - name: Install dependencies
      run: flutter pub get

    - name: Run tests
      run: flutter test test/core/services/payment_service_test.dart

    - name: Generate coverage
      run: flutter test --coverage test/core/services/payment_service_test.dart

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/lcov.info
```

---

## Documentation & Reporting

### Test Report Template

```markdown
# UPI Payment Testing Report

**Date:** [Date]
**Tester:** [Name]
**Build:** [Version]
**Device:** [Model]

## Summary
- Total Tests: XX
- Passed: XX ✅
- Failed: XX ❌
- Blocked: XX ⚠️

## Test Results

### Critical Tests
| Test ID | Status | Notes |
|---------|--------|-------|
| TC001   | ✅     | -     |
| TC002   | ❌     | GPay not launching |
| ...     |        |       |

### Issues Found
1. **Issue #1:** GPay doesn't open
   - **Severity:** High
   - **Steps to Reproduce:** ...
   - **Expected:** ...
   - **Actual:** ...

## Recommendations
- [ ] Fix GPay deep link
- [ ] Add more error handling
- [ ] Improve user feedback
```

---

## Resources

### Useful Links
- [UPI Deep Linking Guide](https://www.npci.org.in/what-we-do/upi/product-overview)
- [Flutter URL Launcher](https://pub.dev/packages/url_launcher)
- [Android Deep Links](https://developer.android.com/training/app-links/deep-linking)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)

### Support Contacts
- **Developer:** [Your Name]
- **QA Lead:** [QA Name]
- **Product Owner:** [PO Name]

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-25 | Initial testing guide created |

---

**Document Owner:** Travel Crew QA Team
**Last Review:** 2025-10-25
**Next Review:** 2025-11-25
