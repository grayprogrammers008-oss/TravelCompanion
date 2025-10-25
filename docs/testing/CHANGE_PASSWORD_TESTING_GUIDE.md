# Change Password Testing Guide

This guide provides step-by-step instructions for testing the change password functionality after the security fix.

---

## 🧪 Automated Testing

### 1. Unit Tests

```bash
# Navigate to project directory
cd "d:\Nithya\Travel Companion\TravelCompanion"

# Run change password use case tests
flutter test test/features/auth/domain/usecases/change_password_usecase_test.dart --reporter expanded
```

**Expected Results** (8 tests):
- ✅ should change password successfully with valid inputs
- ✅ should throw exception when current password is empty
- ✅ should throw exception when new password is empty
- ✅ should throw exception when new password is too short
- ✅ should throw exception when new password same as current
- ✅ should throw exception when password lacks uppercase
- ✅ should throw exception when password lacks lowercase
- ✅ should throw exception when password lacks number
- ✅ should accept password with uppercase, lowercase, and number
- ✅ should propagate repository exceptions

### 2. Integration Tests

```bash
# Generate mocks (if not already done)
flutter pub run build_runner build --delete-conflicting-outputs

# Run integration tests
flutter test test/features/auth/integration/change_password_integration_test.dart --reporter expanded
```

**Expected Results** (15+ tests):
- ✅ Use Case → Repository Integration tests
- ✅ Password Strength Validation tests
- ✅ Error Handling tests

### 3. Run All Auth Tests

```bash
# Run all authentication tests
flutter test test/features/auth/ --reporter expanded
```

---

## 📱 Manual Testing

### Prerequisites
1. Have the app running (debug mode recommended)
2. Be logged in with a test account
3. Know your current password

---

### Test Case 1: Successful Password Change ✅

**Steps**:
1. Launch the app and ensure you're logged in
2. Navigate to **Profile** page (bottom nav or hamburger menu)
3. Scroll to **Account Security** section
4. Tap **"Change Password"** button
5. In the dialog:
   - **Current Password**: Enter your ACTUAL current password
   - **New Password**: Enter `TestPass123` (or any strong password)
   - **Confirm New Password**: Re-enter `TestPass123`
6. Tap **"Change Password"** button

**Expected Result**:
- ✅ Dialog closes
- ✅ Success message appears: "Password changed successfully"
- ✅ Green success snackbar at bottom
- ✅ No errors

**Verification**:
- Log out
- Try logging in with OLD password → Should FAIL
- Try logging in with NEW password (`TestPass123`) → Should SUCCEED

---

### Test Case 2: Incorrect Current Password ❌→✅

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter `WrongPassword999` (intentionally wrong!)
   - **New Password**: Enter `NewPass456`
   - **Confirm New Password**: Re-enter `NewPass456`
3. Tap **"Change Password"** button

**Expected Result**:
- ✅ Dialog closes
- ✅ Error message appears: **"Current password is incorrect"**
- ✅ Red error snackbar at bottom
- ✅ Password NOT changed

**Verification**:
- Try logging in with `NewPass456` → Should FAIL
- Your old password still works

---

### Test Case 3: Weak New Password (Too Short) ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter correct password
   - **New Password**: Enter `Ab1` (only 3 characters)
   - **Confirm New Password**: Enter `Ab1`
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Inline validation error appears under "New Password" field
- ✅ Error text: **"Password must be at least 6 characters"**
- ✅ Form does NOT submit
- ✅ Dialog stays open

---

### Test Case 4: Weak New Password (No Uppercase) ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter correct password
   - **New Password**: Enter `password123` (no uppercase!)
   - **Confirm New Password**: Enter `password123`
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Inline validation error appears
- ✅ Error text: **"Must have uppercase, lowercase, and number"**
- ✅ Form does NOT submit

---

### Test Case 5: Weak New Password (No Lowercase) ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter correct password
   - **New Password**: Enter `PASSWORD123` (no lowercase!)
   - **Confirm New Password**: Enter `PASSWORD123`
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Inline validation error appears
- ✅ Error text: **"Must have uppercase, lowercase, and number"**
- ✅ Form does NOT submit

---

### Test Case 6: Weak New Password (No Number) ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter correct password
   - **New Password**: Enter `PasswordABC` (no numbers!)
   - **Confirm New Password**: Enter `PasswordABC`
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Inline validation error appears
- ✅ Error text: **"Must have uppercase, lowercase, and number"**
- ✅ Form does NOT submit

---

### Test Case 7: New Password Same as Current ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter your current password (e.g., `CurrentPass123`)
   - **New Password**: Enter THE SAME password (`CurrentPass123`)
   - **Confirm New Password**: Re-enter the same password
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Inline validation error appears
- ✅ Error text: **"New password must be different from current"**
- ✅ Form does NOT submit

---

### Test Case 8: Password Mismatch (Confirm) ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. In the dialog:
   - **Current Password**: Enter correct password
   - **New Password**: Enter `NewPass123`
   - **Confirm New Password**: Enter `DifferentPass456` (different!)
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Inline validation error appears under "Confirm New Password" field
- ✅ Error text: **"Passwords do not match"**
- ✅ Form does NOT submit

---

### Test Case 9: Empty Fields ❌

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. Leave all fields EMPTY
3. Try to tap **"Change Password"** button

**Expected Result**:
- ✅ Validation errors appear for all required fields:
  - Current Password: "Please enter your current password"
  - New Password: "Please enter a new password"
  - Confirm New Password: "Please confirm your new password"
- ✅ Form does NOT submit

---

### Test Case 10: Password Visibility Toggle 👁️

**Steps**:
1. Navigate to **Profile** → **Change Password**
2. Enter any password in "Current Password" field
3. Click the eye icon (👁️) on the right
4. Observe password visibility
5. Click eye icon again
6. Observe password is hidden
7. Repeat for "New Password" and "Confirm New Password" fields

**Expected Result**:
- ✅ Eye icon toggles between open and closed
- ✅ Password toggles between visible and hidden (dots)
- ✅ All three password fields work independently

---

## 🔒 Security Verification

### Before Fix Vulnerability Test

**This should NOW FAIL (which is correct!)**:

1. Note your current password
2. Try to change password with:
   - Current Password: `RandomWrongPassword123`
   - New Password: `NewPass456`
   - Confirm: `NewPass456`
3. Submit

**Expected Result**:
- ✅ **"Current password is incorrect"** error appears
- ✅ Password NOT changed
- ✅ Can still log in with your ACTUAL current password

**If you get success message** → 🚨 BUG NOT FIXED!

---

## 📊 Test Results Template

Use this template to record your test results:

```
[ ] Test Case 1: Successful Password Change
[ ] Test Case 2: Incorrect Current Password
[ ] Test Case 3: Weak Password - Too Short
[ ] Test Case 4: Weak Password - No Uppercase
[ ] Test Case 5: Weak Password - No Lowercase
[ ] Test Case 6: Weak Password - No Number
[ ] Test Case 7: New Password Same as Current
[ ] Test Case 8: Password Mismatch
[ ] Test Case 9: Empty Fields
[ ] Test Case 10: Password Visibility Toggle

Security Tests:
[ ] Incorrect current password rejected
[ ] Can only change with correct current password
[ ] Re-authentication works correctly
```

---

## 🐛 If Tests Fail

### Common Issues

1. **"Current password is incorrect" on correct password**
   - Check Supabase connection
   - Verify you're using the correct test credentials
   - Check network connectivity

2. **Tests not running**
   - Run `flutter pub get`
   - Run `flutter pub run build_runner build --delete-conflicting-outputs`
   - Clean build: `flutter clean && flutter pub get`

3. **Build directory permission error**
   - Close IDE/editor
   - Delete `build` folder manually
   - Run `flutter clean`
   - Restart IDE

---

## 📝 Reporting Issues

If you find bugs during testing, please report with:

1. **Test Case Number** (e.g., "Test Case 2")
2. **Steps Taken** (copy from test case)
3. **Expected Result** (from test case)
4. **Actual Result** (what actually happened)
5. **Screenshots** (if applicable)
6. **Error Messages** (exact text)
7. **Device/Platform** (Android/iOS/Web)

---

## ✅ Success Criteria

All tests should pass with these criteria:

1. ✅ Correct current password allows password change
2. ✅ Incorrect current password is REJECTED
3. ✅ Weak passwords are REJECTED with clear messages
4. ✅ New password cannot be same as current
5. ✅ All validation messages are clear and helpful
6. ✅ UI feedback is immediate (inline validation)
7. ✅ Success/error snackbars appear correctly
8. ✅ Password visibility toggles work

---

_Last Updated: 2025-10-23_
_For: Travel Crew App - Change Password Security Fix_
