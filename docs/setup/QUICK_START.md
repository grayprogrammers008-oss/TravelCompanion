# Quick Start Guide

## ✅ What's Been Done

### 1. Expense Testing Page Created
A complete interactive testing page for expense CRUD operations:
- **Route**: `/expenses/test`
- **Location**: [lib/features/expenses/presentation/pages/expense_test_page.dart](lib/features/expenses/presentation/pages/expense_test_page.dart)

### 2. App is Running
The app is currently running on iPhone 17 Pro Max simulator.

---

## 🚀 How to Access the Test Page

### Option 1: Add a Test Button (Recommended)

Add this to your expenses home page temporarily:

```dart
// In lib/features/expenses/presentation/pages/expenses_home_page.dart
// Add to the AppBar actions:

actions: [
  IconButton(
    icon: const Icon(Icons.bug_report),
    onPressed: () => context.go('/expenses/test'),
    tooltip: 'Run Tests',
  ),
],
```

### Option 2: Modify HomePage

Add a temporary button to [lib/features/trips/presentation/pages/home_page.dart](lib/features/trips/presentation/pages/home_page.dart):

```dart
// In the AppBar or somewhere visible:
ElevatedButton.icon(
  icon: const Icon(Icons.science),
  label: const Text('Test Expenses'),
  onPressed: () => context.go('/expenses/test'),
),
```

### Option 3: Use Flutter DevTools

1. Open Flutter DevTools (link shown in console)
2. Navigate to the widget inspector
3. Manually trigger navigation to `/expenses/test`

---

## 📋 Test Workflow

1. **Launch App** ✅ (Already running)
2. **Login** - Enter your credentials and tap "Login"
3. **Navigate** to test page using one of the options above
4. **Click "Run All Tests"**
5. **Watch the console** for results

---

## 🎯 What the Tests Do

### CREATE Test
- Creates a standalone expense
- Amount: ₹1000
- Category: Food
- Verifies expense ID is generated

### READ Test
- Fetches all user expenses
- Verifies created expense exists
- Fetches single expense by ID
- Shows split information

### UPDATE Test
- Updates expense to:
  - Title: "Updated Test Expense"
  - Amount: ₹1500
  - Category: Transport
- Verifies changes persist

### DELETE Test
- Deletes the test expense
- Verifies removal from database
- Confirms cascade deletion of splits

---

## ✅ Expected Results

When all tests pass, you'll see:

```
🚀 Starting expense CRUD tests...

📝 TEST 1: CREATE Expense
✅ Expense created!

📖 TEST 2: READ Expenses
✅ Found N expenses
✅ Verified: Created expense found in list
✅ Fetched single expense: ...

📝 TEST 3: UPDATE Expense
✅ Expense updated!
✅ Verified: Update persisted in database

🗑️ TEST 4: DELETE Expense
✅ Expense deleted!
✅ Verified: Expense removed from database

✅ All tests completed successfully!
```

---

## 🐛 If You See Errors

The test console will show:
- ❌ Red text for errors
- ✅ Green text for success
- ⚠️ Orange for warnings

Share the error message and we can fix it immediately!

---

## 📚 Additional Resources

- **Full Testing Guide**: [EXPENSE_TESTING_GUIDE.md](EXPENSE_TESTING_GUIDE.md)
- **Test Page Code**: [lib/features/expenses/presentation/pages/expense_test_page.dart](lib/features/expenses/presentation/pages/expense_test_page.dart)
- **Router Config**: [lib/core/router/app_router.dart](lib/core/router/app_router.dart)

---

## 🔧 Quick Commands

```bash
# Restart the app
flutter run -d A575062E-AA31-4169-A915-A3D7091FB914

# Hot reload (if app is running)
# Press 'r' in the terminal

# Hot restart (if app is running)
# Press 'R' in the terminal

# Kill all dart processes
killall dart
```

---

## 🎉 Next Steps

1. Access the test page
2. Run the tests
3. Verify all operations work
4. Report any issues with the error logs

The expense module is ready for testing!
