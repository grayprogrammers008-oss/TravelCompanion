# Debug and Test Guide - Travel Crew App

**Created**: 2025-10-09
**Purpose**: Complete testing guide with debug steps to verify all features work

---

## 🔍 Current Status

### ✅ Build Status
```
flutter build apk --debug
✓ Built successfully in 7.0s
```

### ✅ Implemented Features
1. **Authentication** - Sign up, Sign in, Sign out
2. **Trip Management** - Create, View, Delete trips
3. **Expense Tracking** - Add, View, Delete expenses with auto-splits

### 🐛 Debug Logging Added
- CreateTripPage: Logs trip creation flow
- HomePage: Logs trip loading and display

---

## 📱 Step-by-Step Testing Guide

### Test 1: User Registration & Login ✅

#### Steps:
1. **Launch the app**
   ```bash
   flutter run
   ```

2. **Register a new user**
   - You should see Login Page
   - Tap "Don't have an account? Sign up"
   - Fill in:
     - Full Name: `Test User`
     - Email: `test@example.com`
     - Password: `Test123!`
     - Confirm Password: `Test123!`
   - Tap "Sign Up"

#### Expected Console Output:
```
No specific debug logs for registration yet
```

#### Expected UI:
- ✅ Loading spinner appears
- ✅ Success (no error message)
- ✅ Navigate to Home Page
- ✅ Empty state shown: "No trips yet"

#### If Registration Fails:
- **Error**: "Email already exists"
  - **Solution**: Use a different email or clear app data
- **Error**: Database error
  - **Solution**: Check database_helper.dart initialization

---

### Test 2: Trip Creation 🔍

#### Steps:
1. On Home Page (empty state), tap **"Create Trip"** button OR **"+ New Trip"** FAB
2. Fill in trip details:
   - **Trip Name**: `Goa Adventure` (required)
   - **Description**: `Beach vacation with friends`
   - **Destination**: `Goa, India`
   - **Start Date**: Select a future date
   - **End Date**: Select a date after start date
3. Tap **"Create Trip"**

#### Expected Console Output:
```
DEBUG: Creating trip with name: Goa Adventure
DEBUG: Trip created with ID: <uuid>
DEBUG: Invalidating userTripsProvider
DEBUG: Navigating back to home
DEBUG HomePage: Loading trips...
DEBUG HomePage: Received 1 trips
DEBUG HomePage: Showing trips list
```

#### Expected UI:
- ✅ Loading spinner on "Create Trip" button
- ✅ Navigate back to Home Page
- ✅ Green snackbar: "Trip created successfully!"
- ✅ Trip card appears in list with:
  - Title: "Goa Adventure"
  - Destination icon + "Goa, India"
  - Calendar icon + date range
  - Your avatar (first letter of email)

#### If Trip Doesn't Appear: 🚨
**Debug Steps**:

1. **Check Console Logs**
   - Look for "DEBUG: Trip created with ID"
   - If missing → Trip creation failed
   - If present → Trip created but not displaying

2. **Check Database**
   - Trip is saved to SQLite
   - Location: App documents directory
   - File: `travel_crew.db`

3. **Common Issues**:

   **Issue A: "User not authenticated" error**
   - **Cause**: currentUserId is null
   - **Fix**: Verify login sets currentUserId
   - **Check**: `auth_local_datasource.dart` line 62 & 120

   **Issue B: Trip created but not showing**
   - **Cause**: userTripsProvider not refreshing
   - **Fix**: Ensure `ref.invalidate(userTripsProvider)` is called
   - **Check**: `create_trip_page.dart` line 80

   **Issue C: Empty state still showing**
   - **Cause**: getUserTrips() returning empty array
   - **Check Console**: Should see "Received 0 trips"
   - **Fix**: Check trip_members table has entry with your user_id

4. **Manual Database Check** (Advanced):
   ```bash
   # Find the database file
   adb shell run-as com.example.travel_companion
   cd app_flutter
   ls -la travel_crew.db

   # Or use sqflite inspector in DevTools
   ```

---

### Test 3: View Trip Details ✅

#### Steps:
1. On Home Page, **tap on the trip card**
2. Should navigate to Trip Detail Page

#### Expected Console Output:
```
(No specific debug logs added yet)
```

#### Expected UI:
- ✅ Navigate to Trip Detail Page
- ✅ See gradient header (or cover image if set)
- ✅ App bar: "Trip Details"
- ✅ Trip name displayed
- ✅ Location, dates, duration shown
- ✅ Description section
- ✅ Members section with:
  - "Members (1)"
  - Your user card
  - "Organizer" blue chip
- ✅ Quick Actions section with 4 cards:
  - **Itinerary** (coming soon)
  - **Checklist** (coming soon)
  - **Expenses** (clickable!)
  - **Autopilot** (coming soon)

---

### Test 4: Expense Management 💰

#### Test 4A: Navigate to Expenses
**Steps**:
1. From Trip Detail Page
2. Tap **"Expenses"** quick action card

**Expected**:
- ✅ Navigate to Expense List Page
- ✅ Empty state: "No expenses yet"
- ✅ "+ Add Expense" FAB visible

#### Test 4B: Add Expense
**Steps**:
1. Tap **"+ Add Expense"** FAB
2. Fill in expense form:
   - **Title**: `Lunch at Beach Shack`
   - **Amount**: `2400`
   - **Category**: Select `Food`
   - **Date**: Select today's date
   - **Description**: `Amazing seafood lunch`
3. Tap **"Add Expense"**

**Expected Console Output**:
```
(No debug logs added for expenses yet)
```

**Expected UI**:
- ✅ Form validation works (try empty title)
- ✅ Amount accepts decimals (e.g., 2400.50)
- ✅ Category dropdown works
- ✅ Date picker works
- ✅ Info message: "This expense will be split equally among all trip members"
- ✅ Loading spinner on button
- ✅ Navigate back to Expense List
- ✅ Green snackbar: "Expense added successfully!"
- ✅ Expense card appears with:
  - Food icon (orange)
  - Title: "Lunch at Beach Shack"
  - Amount: ₹2,400.00
  - "Paid by: test@example.com"
  - "Split 1 ways" (only you in trip)
  - Date

#### Test 4C: View Expense Details
**Steps**:
1. On Expense List, **tap the expense card**
2. Bottom sheet should appear

**Expected UI**:
- ✅ Modal bottom sheet with:
  - Title: "Lunch at Beach Shack"
  - Total Amount: ₹2,400.00 (in colored box)
  - Description: "Amazing seafood lunch"
  - Split Details:
    - Your avatar + user ID
    - Amount: ₹2,400.00
    - "Not settled" (orange text)
  - Delete button (red, with icon)

#### Test 4D: View Balances
**Steps**:
1. On Expense List, tap **balance icon** (wallet) in app bar
2. Balance sheet appears

**Expected UI**:
- ✅ Modal bottom sheet "Balances"
- ✅ Your balance card showing:
  - Paid: ₹2,400.00
  - Owes: ₹2,400.00
  - Balance: ₹0.00 (grey - balanced)

#### Test 4E: Delete Expense
**Steps**:
1. Tap expense card → Details sheet appears
2. Tap **"Delete Expense"** button
3. Confirmation dialog appears
4. Tap **"Cancel"** first

**Expected**:
- ✅ Dialog closes, expense not deleted

5. Open details again, tap **"Delete Expense"**
6. Tap **"Delete"** (red button)

**Expected**:
- ✅ Expense deleted
- ✅ Navigate back to list
- ✅ Empty state appears
- ✅ Green snackbar: "Expense deleted successfully"

---

### Test 5: Multi-Member Expense Split 💡

**Setup**: This requires inviting another member (feature not implemented yet)

**Workaround for Testing**:
You can manually insert another user into the database for testing:

```sql
-- Insert test user
INSERT INTO profiles (id, email, full_name, created_at, updated_at)
VALUES ('test-user-2', 'friend@example.com', 'Friend User', datetime('now'), datetime('now'));

-- Add to trip (replace <trip_id> with your trip's ID from console logs)
INSERT INTO trip_members (id, trip_id, user_id, role, joined_at)
VALUES ('<uuid>', '<trip_id>', 'test-user-2', 'member', datetime('now'));
```

**Then test expense split**:
1. Add expense of ₹1200
2. Should split: ₹600 each (you + friend)
3. Balance:
   - You: Paid ₹1200, Owe ₹600 → **Gets back ₹600** (green)
   - Friend: Paid ₹0, Owe ₹600 → **Owes ₹600** (red)

---

### Test 6: Delete Trip 🗑️

#### Steps:
1. On Trip Detail Page
2. Tap **three-dot menu** (top right)
3. Tap **"Delete Trip"** (red text)
4. Confirmation dialog appears
5. Tap **"Cancel"** first

**Expected**:
- ✅ Dialog closes, trip not deleted

6. Open menu again, tap **"Delete Trip"**
7. Tap **"Delete"** (red button)

**Expected Console Output**:
```
(No debug logs for delete yet)
```

**Expected UI**:
- ✅ Trip deleted from database
- ✅ Navigate back to Home Page
- ✅ Empty state appears
- ✅ Snackbar: "Trip deleted successfully"

---

## 🐛 Common Issues & Fixes

### Issue 1: "No trips yet" after creating trip

**Symptoms**:
- Console shows: "Trip created with ID: <uuid>"
- Console shows: "Received 0 trips"
- Empty state still displayed

**Root Cause**:
- Trip created but not appearing in getUserTrips()
- Likely issue: trip_members table entry missing or user_id mismatch

**Debug Steps**:
1. Add debug logging to `trip_local_datasource.dart`:
   ```dart
   Future<List<TripWithMembers>> getUserTrips() async {
     print('DEBUG getUserTrips: currentUserId = $_currentUserId');

     final membershipRows = await db.query(...);
     print('DEBUG getUserTrips: Found ${membershipRows.length} memberships');

     final tripIds = membershipRows.map(...).toList();
     print('DEBUG getUserTrips: Trip IDs = $tripIds');

     // ... rest of code
   }
   ```

2. Check if:
   - `_currentUserId` is not null
   - Membership rows found
   - Trip IDs match

**Fix**:
- Ensure `setCurrentUserId()` is called in provider
- Verify trip_members insert in `createTrip()`

---

### Issue 2: Expenses not clickable

**Symptoms**:
- "Expenses" quick action shows "coming in Phase 2" message
- Navigation doesn't work

**Root Cause**:
- Old code not updated in trip_detail_page.dart

**Fix**:
Already fixed at line 281:
```dart
context.push('/trips/$tripId/expenses');
```

**Verify**:
- Rebuild app
- Clear app data if cached

---

### Issue 3: Balance calculations wrong

**Symptoms**:
- Balance shows incorrect amounts
- Splits not equal

**Debug**:
1. Check split calculation in `expense_local_datasource.dart`:
   ```dart
   final splitAmount = amount / splitWith.length;
   ```

2. Verify all members in `splitWith` array

**Common Mistake**:
- Not including all trip members
- Using wrong user IDs

---

### Issue 4: App crashes on expense add

**Symptoms**:
- Crash when tapping "Add Expense"
- Error in console

**Common Causes**:
1. **No members in trip**
   - Error: "No members found in trip"
   - Fix: Ensure trip has at least one member (you)

2. **User not authenticated**
   - Error: "User not logged in"
   - Fix: Check currentUserId is set

3. **Database constraint violation**
   - Error: Foreign key constraint failed
   - Fix: Ensure trip_id exists in trips table

---

## 🧪 Unit Testing Checklist

### Authentication
- [ ] Sign up with valid data succeeds
- [ ] Sign up with duplicate email fails
- [ ] Sign in with correct credentials succeeds
- [ ] Sign in with wrong password fails
- [ ] Sign out clears session
- [ ] currentUserId is set after login
- [ ] currentUserId is null after logout

### Trip Management
- [ ] Create trip with all fields succeeds
- [ ] Create trip with only name succeeds
- [ ] Created trip appears in list
- [ ] Trip has correct data
- [ ] Creator is added as organizer member
- [ ] View trip details shows correct info
- [ ] Delete trip removes from database
- [ ] Delete trip cascades to members

### Expense Management
- [ ] Add expense with all fields succeeds
- [ ] Add expense splits equally
- [ ] Expense appears in list
- [ ] Balance calculation is correct
- [ ] Delete expense works
- [ ] Empty state shows when no expenses
- [ ] View expense details works

---

## 📊 Expected Data Flow

### Trip Creation Flow:
```
User fills form
  ↓
CreateTripPage._handleCreateTrip()
  ↓
TripController.createTrip()
  ↓
CreateTripUseCase()
  ↓
TripRepository.createTrip()
  ↓
TripLocalDataSource.createTrip()
  ↓
SQLite: INSERT into trips + trip_members
  ↓
Return TripModel
  ↓
ref.invalidate(userTripsProvider)
  ↓
HomePage rebuilds
  ↓
getUserTrips() called
  ↓
Trips displayed
```

### Expense Addition Flow:
```
User fills form
  ↓
AddExpensePage._handleSubmit()
  ↓
ExpenseController.createExpense()
  ↓
ExpenseRepository.createExpense()
  ↓
ExpenseLocalDataSource.createExpense()
  ↓
SQLite: INSERT expense + expense_splits
  ↓
Return ExpenseModel
  ↓
ref.invalidate(tripExpensesProvider)
  ↓
ExpenseListPage rebuilds
  ↓
Expenses displayed
```

---

## 🔬 Manual Testing Script

Run this complete test to verify everything works:

```
1. FRESH START
   - Uninstall app
   - Reinstall/Run app

2. REGISTER
   - Email: testnew@test.com
   - Pass: Test123!
   - Verify: Navigates to Home
   - Verify: Empty state shown

3. CREATE TRIP #1
   - Name: "Goa Trip"
   - Destination: "Goa"
   - Dates: Future dates
   - Verify: Success message
   - Verify: Trip card appears
   - Verify: Console shows "Received 1 trips"

4. VIEW TRIP DETAILS
   - Tap trip card
   - Verify: All details shown
   - Verify: You are organizer
   - Verify: Expenses card visible

5. ADD EXPENSE #1
   - Tap Expenses card
   - Tap Add Expense FAB
   - Title: "Hotel"
   - Amount: "5000"
   - Category: "Accommodation"
   - Tap Add
   - Verify: Success
   - Verify: Expense card shown
   - Verify: Amount ₹5,000.00

6. ADD EXPENSE #2
   - Add another expense
   - Title: "Dinner"
   - Amount: "1200"
   - Category: "Food"
   - Verify: Total shows ₹6,200.00

7. CHECK BALANCES
   - Tap balance icon
   - Verify: Paid ₹6,200
   - Verify: Owes ₹6,200
   - Verify: Balance ₹0

8. DELETE EXPENSE
   - Tap "Dinner" expense
   - Tap Delete
   - Confirm
   - Verify: Only Hotel expense remains
   - Verify: Total shows ₹5,000.00

9. GO BACK TO HOME
   - Navigate back to trip detail
   - Navigate back to home
   - Verify: Trip still shown

10. CREATE TRIP #2
    - Add another trip
    - Verify: 2 trips shown

11. DELETE TRIP
    - Open first trip
    - Menu → Delete Trip
    - Confirm
    - Verify: Back to home
    - Verify: Only 1 trip shown

12. LOGOUT
    - Profile menu → Logout
    - Verify: At login page

13. LOGIN
    - Same credentials
    - Verify: Trip still there
    - Verify: Expenses still there
```

**Expected Result**: ALL steps pass ✅

---

## 🎯 Success Criteria

App is working correctly if:

- [x] Registration creates user
- [x] Login authenticates user
- [x] Trip creation saves to database
- [x] Trips appear in list
- [x] Trip details display correctly
- [x] Expenses can be added
- [x] Expenses appear in list
- [x] Balance calculations are correct
- [x] Delete operations work
- [x] Navigation flows correctly
- [x] Data persists after logout/login

---

## 📞 Reporting Results

After testing, please report:

**What Works** ✅:
- List features that work correctly

**What Doesn't Work** ❌:
- List features that fail
- Include error messages
- Include console output
- Include steps to reproduce

**Console Logs**:
- Copy relevant debug output
- Especially look for "DEBUG" prefixed logs

---

_Last Updated: 2025-10-09_
