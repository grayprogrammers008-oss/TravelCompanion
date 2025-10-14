# Travel Crew App - Testing Guide

**Phase 1 - Trip Management Testing**
**Last Updated**: 2025-10-09

---

## 🧪 Pre-Testing Checklist

### 1. Build Verification
```bash
# Ensure no errors
flutter analyze

# Build the app
flutter build apk --debug

# Or run directly on device/emulator
flutter run
```

**Expected Results**:
- ✅ `flutter analyze` shows 0 errors
- ✅ Build completes successfully
- ✅ App launches without crashes

---

## 🔐 Test 1: User Registration

### Steps
1. Launch the app
2. You should see the **Login Page**
3. Tap **"Don't have an account? Sign up"**
4. Fill in the registration form:
   - **Full Name**: John Doe
   - **Email**: john@example.com
   - **Password**: Test@123
   - **Confirm Password**: Test@123
5. Tap **"Sign Up"**

### Expected Results
- ✅ Loading indicator appears
- ✅ Registration succeeds
- ✅ User is automatically logged in
- ✅ Navigated to **Home Page** (trip list)
- ✅ Home page shows empty state with "No trips yet" message

### Troubleshooting
- ❌ **Error**: "Email already exists" → Use a different email
- ❌ **Error**: "Password too weak" → Use stronger password with numbers/symbols
- ❌ **Stuck on loading** → Check console for errors

---

## 🔑 Test 2: User Login & Session

### Steps
1. From the Home Page, tap the **profile icon** (top-right)
2. Tap **"Logout"**
3. You should see the **Login Page** again
4. Fill in credentials:
   - **Email**: john@example.com
   - **Password**: Test@123
5. Tap **"Login"**

### Expected Results
- ✅ Loading indicator appears
- ✅ Login succeeds
- ✅ Navigated to **Home Page**
- ✅ Session persists (closing and reopening app keeps you logged in)

### Session Persistence Test
1. **Without logging out**, close the app completely
2. Reopen the app
3. Should automatically navigate to **Home Page** (already logged in)

---

## ✈️ Test 3: Create Trip - Full Details

### Steps
1. From the Home Page, tap the **"+ New Trip"** FAB (bottom-right)
2. Fill in **all fields**:
   - **Trip Name**: Bali Adventure
   - **Description**: A relaxing beach vacation with friends
   - **Destination**: Bali, Indonesia
   - **Start Date**: Tap field → Select a future date (e.g., 2025-12-15)
   - **End Date**: Tap field → Select a date after start date (e.g., 2025-12-20)
3. Tap **"Create Trip"**

### Expected Results
- ✅ Loading indicator appears on button
- ✅ Success message: "Trip created successfully!"
- ✅ Navigated back to **Home Page**
- ✅ New trip appears in the list as a **card** with:
  - Cover image (gradient fallback)
  - Trip name: "Bali Adventure"
  - Destination icon + "Bali, Indonesia"
  - Calendar icon + date range
  - Member avatars (just you)

---

## 📝 Test 4: Create Trip - Minimal Details

### Steps
1. Tap **"+ New Trip"** again
2. Fill in **only required fields**:
   - **Trip Name**: Weekend Getaway
   - Leave description, destination, and dates **empty**
3. Tap **"Create Trip"**

### Expected Results
- ✅ Trip created successfully
- ✅ Trip appears in list with:
  - Trip name: "Weekend Getaway"
  - No destination shown
  - No dates shown
  - Just your member avatar

---

## 👁️ Test 5: View Trip Details

### Steps
1. From the Home Page trip list
2. **Tap on the "Bali Adventure" card**

### Expected Results
- ✅ Navigated to **Trip Detail Page**
- ✅ Top shows:
  - Cover image (gradient fallback)
  - App bar with "Trip Details" title
  - Edit button (top-right)
  - Three-dot menu (top-right)
- ✅ Details section shows:
  - **Trip name**: "Bali Adventure"
  - **Location icon** + "Bali, Indonesia"
  - **Calendar icon** + "Dec 15, 2025 - Dec 20, 2025"
  - **Clock icon** + "6 days" (calculated duration)
  - **Description section**: "A relaxing beach vacation with friends"
- ✅ Members section shows:
  - "Members (1)"
  - Your user card with:
    - Circle avatar with first letter of email
    - "Member [user_id]"
    - "Role: Organizer" (you're the creator)
    - Blue "Organizer" chip
- ✅ Quick Actions section shows 4 cards:
  - Itinerary (placeholder)
  - Checklist (placeholder)
  - Expenses (placeholder)
  - Autopilot (placeholder)

---

## 🗑️ Test 6: Delete Trip

### Steps
1. From the **Trip Detail Page**
2. Tap the **three-dot menu** (top-right)
3. Tap **"Delete Trip"** (red text with trash icon)
4. A dialog appears: "Are you sure you want to delete this trip?"
5. Tap **"Cancel"** first

### Expected Results (Cancel)
- ✅ Dialog closes
- ✅ Still on Trip Detail Page
- ✅ Trip NOT deleted

### Steps (Actual Delete)
1. Tap **three-dot menu** again
2. Tap **"Delete Trip"**
3. This time tap **"Delete"** (red button)

### Expected Results (Delete)
- ✅ Dialog closes
- ✅ Loading/processing occurs
- ✅ Success message: "Trip deleted successfully"
- ✅ Navigated back to **Home Page**
- ✅ Trip **no longer appears** in the list
- ✅ If it was the only trip, shows empty state again

---

## 🔄 Test 7: Pull to Refresh

### Steps
1. On the Home Page with trip list
2. **Pull down** from the top of the list
3. Release

### Expected Results
- ✅ Refresh indicator appears
- ✅ Trip list reloads
- ✅ All trips still display correctly

---

## 📱 Test 8: Navigation Flow

### Steps
1. **Home Page** → Tap "New Trip" → **Create Trip Page**
2. Fill form → Tap "Create Trip"
3. → **Home Page** (with success message)
4. Tap a trip card → **Trip Detail Page**
5. Tap **back button** → **Home Page**
6. Tap profile icon → Bottom sheet appears
7. Tap **outside** bottom sheet → Closes
8. Tap profile icon → Tap **"Logout"** → **Login Page**

### Expected Results
- ✅ All navigation transitions smooth
- ✅ Back button works correctly
- ✅ No crashes during navigation
- ✅ Context maintained (no data loss)

---

## ⚠️ Test 9: Error Handling

### Form Validation (Create Trip Page)
1. Leave **Trip Name** empty
2. Tap "Create Trip"

**Expected**: ✅ Error message: "Please enter a trip name"

3. Enter trip name: "X" (1 character)
4. Tap "Create Trip"

**Expected**: ✅ Error message: "Name must be at least 3 characters"

5. Enter name: "Test Trip"
6. Select **End Date before Start Date**
7. Tap "Create Trip"

**Expected**: ✅ Error message or end date picker adjusts

---

## 🎨 Test 10: UI/UX Validation

### Empty States
- ✅ Home Page with no trips shows:
  - Large flight icon
  - "No trips yet" heading
  - Helpful message
  - "Create Trip" button

### Loading States
- ✅ Login shows loading spinner on button
- ✅ Sign up shows loading spinner
- ✅ Create trip shows loading spinner
- ✅ Trip list shows center loading spinner
- ✅ Trip detail shows loading spinner

### Error States
- ✅ Trip detail with error shows:
  - Error icon
  - "Error loading trip" message
  - Error details
  - "Go Back" button

---

## 📊 Test Results Template

Copy this to track your testing:

```markdown
## My Test Results - [Date]

### ✅ Passing Tests
- [ ] Test 1: User Registration
- [ ] Test 2: User Login & Session
- [ ] Test 3: Create Trip - Full Details
- [ ] Test 4: Create Trip - Minimal Details
- [ ] Test 5: View Trip Details
- [ ] Test 6: Delete Trip
- [ ] Test 7: Pull to Refresh
- [ ] Test 8: Navigation Flow
- [ ] Test 9: Error Handling
- [ ] Test 10: UI/UX Validation

### ❌ Failing Tests
(List any tests that failed with details)

### 🐛 Bugs Found
1.
2.

### 💡 Suggestions
1.
2.
```

---

## 🔍 Additional Checks

### Database Persistence
1. Create 2-3 trips
2. Close the app **completely** (swipe away from recents)
3. Reopen the app
4. Login if needed

**Expected**: ✅ All trips still appear in the list

### Multiple Trips
1. Create **5+ trips** with different data
2. Scroll through the list

**Expected**:
- ✅ All trips display correctly
- ✅ Scrolling is smooth
- ✅ Each card shows correct data
- ✅ No duplicate trips

### Date Formatting
Check that dates display correctly:
- ✅ Format: "Dec 15, 2025" (not "2025-12-15")
- ✅ Date range: "Dec 15, 2025 - Dec 20, 2025"
- ✅ Duration: "6 days" (not "5 days")

---

## 🚨 Known Limitations (Phase 1)

These are **expected** and will be implemented in Phase 2:

1. **Edit Trip** - Shows "coming soon" message
2. **Invite Members** - Shows "coming soon" message
3. **Quick Actions** - All show "coming in Phase 2" message:
   - Itinerary
   - Checklist
   - Expenses
   - Autopilot
4. **Trip Images** - No image upload yet (gradient fallback only)
5. **Real Members** - Only shows trip creator
6. **Trip Sharing** - No invite system yet

---

## 📞 Reporting Issues

If you find bugs, please report with:

1. **What you did** (steps to reproduce)
2. **What you expected** (expected behavior)
3. **What happened** (actual behavior)
4. **Screenshots** (if applicable)
5. **Device info** (Android/iOS version, device model)

### Example Bug Report
```markdown
## Bug: Trip not saving description

**Steps**:
1. Create new trip
2. Fill name: "Test"
3. Fill description: "Long description here..."
4. Tap Create Trip

**Expected**: Trip saves with description

**Actual**: Trip saves but description is empty

**Device**: Android 13, Pixel 6
**Screenshot**: [attach]
```

---

## ✅ Success Criteria

Phase 1 is considered **successful** if:

- [x] All 10 test cases pass
- [x] No crashes during normal use
- [x] Data persists across app restarts
- [x] Navigation works correctly
- [x] UI is responsive and looks good
- [x] Forms validate properly
- [x] Error messages are clear
- [x] Loading states show appropriately

---

## 🎉 Phase 1 Complete!

If all tests pass, Phase 1 is **ready for production** and you can move on to implementing Phase 2 features:
- Trip invites & member management
- Itinerary builder
- Checklists
- Expense tracking
- Real-time sync
- Claude AI integration

---

_Last Updated: 2025-10-09_
