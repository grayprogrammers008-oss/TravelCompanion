# Issue #5: Itinerary Builder - Handoff Document

**Date**: 2025-10-17
**Status**: 🟡 **READY FOR IMPLEMENTATION**
**Prepared For**: Vinoth
**Prepared By**: Claude Code

---

## 📋 Summary

I've prepared a complete implementation plan and initial file structure for **Issue #5: Itinerary Builder with Day-wise Organization**. This document provides everything you need to complete the implementation with full end-to-end testing.

---

## ✅ What Has Been Completed

### 1. **Documentation** ✅
- **ISSUE_5_ITINERARY_IMPLEMENTATION_PLAN.md** - Comprehensive 600+ line implementation guide
  - Complete architecture overview
  - Code examples for every component
  - 35+ files to create with specifications
  - 60+ unit tests planned
  - Step-by-step implementation order
  - Success criteria and verification checklist

### 2. **Foundation Files** ✅
Created initial structure (12 files committed to git):

**Domain Layer:**
- `lib/features/itinerary/domain/repositories/itinerary_repository.dart` ✅
- `lib/features/itinerary/domain/usecases/create_itinerary_item_usecase.dart` (placeholder)
- `lib/features/itinerary/domain/usecases/update_itinerary_item_usecase.dart` (placeholder)
- `lib/features/itinerary/domain/usecases/delete_itinerary_item_usecase.dart` (placeholder)
- `lib/features/itinerary/domain/usecases/get_trip_itinerary_usecase.dart` (placeholder)
- `lib/features/itinerary/domain/usecases/get_itinerary_by_days_usecase.dart` (placeholder)
- `lib/features/itinerary/domain/usecases/reorder_items_usecase.dart` (placeholder)

**Data Layer:**
- `lib/features/itinerary/data/datasources/itinerary_local_datasource.dart` (placeholder)
- `lib/features/itinerary/data/repositories/itinerary_repository_impl.dart` (placeholder)

**Presentation Layer:**
- `lib/features/itinerary/presentation/providers/itinerary_providers.dart` (placeholder)
- `lib/features/itinerary/presentation/pages/itinerary_list_page.dart` (placeholder)

### 3. **Database & Models** ✅ (Already Existing)
- Database table: `itinerary_items` ✅
- Models: `ItineraryItemModel`, `ItineraryDay` ✅
- Indexes and relationships ✅

---

## 📝 What Needs To Be Done

### **Phase 1: Complete Domain Layer** (2-3 hours)

Fill in the placeholder use case files with actual implementation. Each file needs:

#### Required Validations:
- **Title**: Required, not empty, min 3 characters
- **Times**: End time > start time (if both provided)
- **Day Number**: Positive integer (if provided)
- **Order Index**: Non-negative integer

#### Files to Complete:

1. **create_itinerary_item_usecase.dart** (~70 lines)
   - Validate all inputs
   - Call repository.createItineraryItem()
   - Wrap exceptions with context

2. **update_itinerary_item_usecase.dart** (~65 lines)
   - Similar validations as create
   - Handle partial updates
   - Wrap exceptions

3. **delete_itinerary_item_usecase.dart** (~30 lines)
   - Validate item ID exists
   - Call repository.deleteItineraryItem()

4. **get_trip_itinerary_usecase.dart** (~25 lines)
   - Validate trip ID
   - Return all items for trip

5. **get_itinerary_by_days_usecase.dart** (~40 lines)
   - Get items grouped by day
   - Return List<ItineraryDay>

6. **reorder_items_usecase.dart** (~35 lines)
   - Validate input
   - Call repository.reorderItems()

**Reference**: See detailed code examples in ISSUE_5_ITINERARY_IMPLEMENTATION_PLAN.md

---

### **Phase 2: Implement Data Layer** (2-3 hours)

#### 1. **itinerary_local_datasource.dart** (~500 lines)

Key methods needed:
```dart
- setCurrentUserId(String? userId)  // From auth
- createItineraryItem(...) -> ItineraryItemModel
- getTripItinerary(String tripId) -> List<ItineraryItemModel>
- getItineraryByDays(String tripId) -> List<ItineraryDay>
- getItineraryItem(String itemId) -> ItineraryItemModel
- updateItineraryItem(...) -> ItineraryItemModel
- deleteItineraryItem(String itemId)
- reorderItems(...)
- getDayItinerary(String tripId, int dayNumber) -> List<ItineraryItemModel>
```

**Important:**
- Use `DatabaseHelper.instance.database` for SQLite
- Set _currentUserId from auth (like TripLocalDataSource)
- Use UUID for IDs
- Handle ordering: `ORDER BY day_number ASC, order_index ASC, start_time ASC`
- Implement day grouping logic

#### 2. **itinerary_repository_impl.dart** (~200 lines)

Implement all methods from ItineraryRepository interface:
- Wrap datasource calls with try-catch
- Throw exceptions with context
- Pass through all parameters

---

### **Phase 3: Build Presentation Layer** (2-3 hours)

#### 1. **itinerary_providers.dart** (~280 lines)

Create these providers:
```dart
// Data source (with auth user ID)
final itineraryLocalDataSourceProvider = Provider<ItineraryLocalDataSource>((ref) {
  final dataSource = ItineraryLocalDataSource();
  final authDataSource = ref.watch(authLocalDataSourceProvider);
  dataSource.setCurrentUserId(authDataSource.currentUserId);
  return dataSource;
});

// Repository
final itineraryRepositoryProvider = Provider<ItineraryRepository>(...)

// Use cases (6 providers)
final createItineraryItemUseCaseProvider = Provider<CreateItineraryItemUseCase>(...)
// ... etc

// Data providers
final tripItineraryProvider = FutureProvider.family<List<ItineraryItemModel>, String>(...)
final itineraryByDaysProvider = FutureProvider.family<List<ItineraryDay>, String>(...)

// Controller
class ItineraryController extends Notifier<ItineraryState> {...}
final itineraryControllerProvider = NotifierProvider<ItineraryController, ItineraryState>(...)
```

#### 2. **itinerary_list_page.dart** (~600 lines)

Features needed:
- Display items grouped by days
- Day headers with gradient
- Item cards with time, location, description
- Swipe to delete
- Tap to edit
- FAB to add new item
- Empty state
- Error state
- Loading state
- Premium animations (StaggeredListAnimation)

#### 3. **add_edit_itinerary_item_page.dart** (~500 lines)

Form fields:
- Title (required, validated)
- Description (optional, multiline)
- Location (optional)
- Day number (picker)
- Start time (time picker)
- End time (time picker)
- Save button (with loading state)
- Cancel button

---

### **Phase 4: Testing** (1-2 hours)

Create test files in `test/features/itinerary/domain/usecases/`:

#### Required Tests (60+ total):

1. **create_itinerary_item_usecase_test.dart** (15 tests)
   - ✅ Create with all fields
   - ✅ Create with minimal fields
   - ✅ Trim whitespace
   - ❌ Empty title
   - ❌ Short title (< 3 chars)
   - ❌ End time before start time
   - ❌ Negative day number
   - ❌ Negative order index
   - ❌ Repository errors
   - And more...

2. **update_itinerary_item_usecase_test.dart** (18 tests)
   - Similar to create tests
   - Test partial updates
   - Test no-op updates

3. **get_itinerary_by_days_usecase_test.dart** (12 tests)
   - Empty itinerary
   - Single day
   - Multiple days
   - Proper grouping
   - Proper sorting

4. **delete_itinerary_item_usecase_test.dart** (8 tests)

5. **get_trip_itinerary_usecase_test.dart** (8 tests)

6. **reorder_items_usecase_test.dart** (10 tests)

**Test Pattern** (use manual mocks like trip tests):
```dart
class MockItineraryRepository implements ItineraryRepository {
  ItineraryItemModel? _itemToReturn;
  Exception? _exceptionToThrow;
  bool _createCalled = false;
  Map<String, dynamic>? _lastCallParams;

  // Setup methods
  void setupCreateItem(ItineraryItemModel item) {...}
  void setupCreateToThrow(Exception e) {...}

  // Verification
  bool get wasCreateCalled => _createCalled;
  Map<String, dynamic>? get lastCallParams => _lastCallParams;

  // Reset
  void reset() {...}

  // Implement interface methods
  @override
  Future<ItineraryItemModel> createItineraryItem(...) async {
    _createCalled = true;
    _lastCallParams = {...};
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _itemToReturn!;
  }

  // Other methods throw UnimplementedError
}
```

**Run Tests:**
```bash
flutter test test/features/itinerary/domain/usecases/

# Expected: 60+ passing tests
# Target: 100% pass rate
```

---

### **Phase 5: Integration** (30 mins)

#### 1. Update Router (`lib/core/router/app_router.dart`)

Add routes:
```dart
GoRoute(
  path: '/trips/:tripId/itinerary',
  name: 'itinerary',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return ItineraryListPage(tripId: tripId);
  },
),
GoRoute(
  path: '/trips/:tripId/itinerary/add',
  name: 'addItineraryItem',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return AddEditItineraryItemPage(tripId: tripId);
  },
),
GoRoute(
  path: '/trips/:tripId/itinerary/:itemId/edit',
  name: 'editItineraryItem',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    final itemId = state.pathParameters['itemId']!;
    return AddEditItineraryItemPage(tripId: tripId, itemId: itemId);
  },
),
```

#### 2. Update Trip Detail Page

Add "Itinerary" navigation button/tab in `trip_detail_page.dart`:
```dart
// In the trip detail page
ElevatedButton.icon(
  onPressed: () => context.push('/trips/${widget.tripId}/itinerary'),
  icon: Icon(Icons.event_note),
  label: Text('View Itinerary'),
)
```

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] CreateItineraryItemUseCase - 15 tests passing
- [ ] UpdateItineraryItemUseCase - 18 tests passing
- [ ] DeleteItineraryItemUseCase - 8 tests passing
- [ ] GetTripItineraryUseCase - 8 tests passing
- [ ] GetItineraryByDaysUseCase - 12 tests passing
- [ ] ReorderItemsUseCase - 10 tests passing
- [ ] **Total: 60+ tests, 100% passing**

### Manual Testing
- [ ] Create itinerary item
- [ ] View items grouped by days
- [ ] Edit existing item
- [ ] Delete item (swipe)
- [ ] Navigate between pages
- [ ] Form validation works
- [ ] Time pickers work
- [ ] Day grouping displays correctly
- [ ] Empty state shows
- [ ] Error handling works
- [ ] Loading states work
- [ ] Animations apply

### Code Quality
- [ ] No compilation errors
- [ ] No warnings (`flutter analyze`)
- [ ] Proper error handling throughout
- [ ] User feedback for all operations
- [ ] Loading states everywhere
- [ ] Clean architecture followed

---

## 📊 Progress Tracker

### Implementation Status

| Phase | Component | Status | Files | Lines |
|-------|-----------|--------|-------|-------|
| 1 | Domain - Repository | ✅ Done | 1 | 60 |
| 1 | Domain - Use Cases | 🟡 Placeholders | 6 | ~300 |
| 2 | Data - Datasource | 🟡 Placeholder | 1 | ~500 |
| 2 | Data - Repository Impl | 🟡 Placeholder | 1 | ~200 |
| 3 | Presentation - Providers | 🟡 Placeholder | 1 | ~280 |
| 3 | Presentation - List Page | 🟡 Placeholder | 1 | ~600 |
| 3 | Presentation - Add/Edit Page | ⚪ Not Started | 1 | ~500 |
| 4 | Tests - Use Cases | ⚪ Not Started | 6+ | ~1200 |
| 5 | Integration - Router | ⚪ Not Started | 0 | ~30 |
| 5 | Integration - Trip Detail | ⚪ Not Started | 0 | ~20 |

**Overall Progress**: 10% (Foundation laid)

---

## 🚀 Quick Start Guide

### Step 1: Complete Use Cases (Start Here)
```bash
# Open each use case file and implement following the plan
code lib/features/itinerary/domain/usecases/create_itinerary_item_usecase.dart

# Reference the implementation plan for code examples
# Validate inputs, call repository, handle errors
```

### Step 2: Implement Datasource
```bash
code lib/features/itinerary/data/datasources/itinerary_local_datasource.dart

# Copy pattern from TripLocalDataSource
# Implement CRUD + day grouping logic
# Use SQLite via DatabaseHelper
```

### Step 3: Build UI
```bash
code lib/features/itinerary/presentation/pages/itinerary_list_page.dart

# Display items grouped by days
# Apply animations
# Handle user interactions
```

### Step 4: Write Tests
```bash
# Create test files for each use case
mkdir -p test/features/itinerary/domain/usecases
code test/features/itinerary/domain/usecases/create_itinerary_item_usecase_test.dart

# Use manual mocks pattern
# Test success, validation errors, repository errors
```

### Step 5: Run & Verify
```bash
# Run tests
flutter test test/features/itinerary/

# Check compilation
flutter analyze lib/features/itinerary/

# Manual test
flutter run
```

---

## 📚 Reference Documents

1. **ISSUE_5_ITINERARY_IMPLEMENTATION_PLAN.md** - Complete implementation guide with code examples
2. **CLAUDE.md** - Project progress and design system
3. **lib/features/trips/** - Reference for clean architecture pattern
4. **lib/features/trip_invites/** - Reference for similar feature structure
5. **test/features/trips/domain/usecases/** - Reference for testing patterns

---

## ⚠️ Important Notes

### Authentication
- ItineraryLocalDataSource needs _currentUserId from auth
- Follow same pattern as TripLocalDataSource:
  ```dart
  final authDataSource = ref.watch(authLocalDataSourceProvider);
  dataSource.setCurrentUserId(authDataSource.currentUserId);
  ```

### Day Grouping Logic
- Items can have `day_number` (1, 2, 3, etc.) or null
- Group by day_number
- Sort by: day_number ASC, order_index ASC, start_time ASC
- Each ItineraryDay has: dayNumber, date (optional), List<items>

### Validation Rules
- Title: Required, min 3 chars, trim whitespace
- Times: end_time > start_time (if both provided)
- Day: Must be positive (if provided)
- Order: Must be >= 0

### Error Handling
- Always wrap repository calls in try-catch
- Provide user-friendly error messages
- Show errors in SnackBar
- Log errors for debugging

---

## ✅ Definition of Done

The feature is complete when:

1. ✅ All 35+ files created and implemented
2. ✅ 60+ unit tests written and passing (100%)
3. ✅ No compilation errors or warnings
4. ✅ All CRUD operations work
5. ✅ Day-wise grouping displays correctly
6. ✅ Forms validate properly
7. ✅ Premium animations applied
8. ✅ Integrated with trip detail page
9. ✅ Router configured
10. ✅ Manual testing completed
11. ✅ Documentation updated
12. ✅ Code committed and pushed to main

---

## 🎯 Success Criteria

### Functionality ✅
- Users can create daily activities for trips
- Activities are organized by day
- Users can set time slots for each activity
- Users can add locations and descriptions
- Users can edit and delete activities
- Day-wise view shows activities grouped properly
- Forms validate user input

### Technical ✅
- Clean architecture (Domain/Data/Presentation)
- Riverpod state management
- SQLite local storage
- 60+ comprehensive tests
- 100% test pass rate
- No errors or warnings
- Proper error handling

### UI/UX ✅
- Material Design 3 styling
- Premium animations
- Loading states
- Empty states
- Error states
- User feedback (SnackBars)
- Intuitive navigation

---

## 📞 Need Help?

If you encounter issues:

1. **Check the Implementation Plan**: ISSUE_5_ITINERARY_IMPLEMENTATION_PLAN.md has detailed code examples
2. **Reference Similar Features**: Look at trips or trip_invites modules
3. **Check Tests**: Trip tests show the manual mock pattern
4. **Run Analyze**: `flutter analyze` will catch most issues
5. **Check Logs**: Look for DEBUG prints in console

---

## 🎉 Next Steps After Completion

Once Issue #5 is done:

1. Create ISSUE_5_COMPLETE.md documentation
2. Update CLAUDE.md with progress
3. Commit all changes to git
4. Create pull request (if using PR workflow)
5. Move to next issue (Checklists, Payments, etc.)

---

**Ready to implement?** 🚀

Start with Phase 1 (Domain Layer), then work through Phases 2-5 systematically. Follow the implementation plan closely, and you'll have a production-ready Itinerary Builder with full test coverage!

---

**Status**: 📋 Ready for Implementation
**Est. Time**: 6-8 hours
**Files**: 35+
**Tests**: 60+
**Handoff Date**: 2025-10-17

---

_Prepared by Claude Code with ❤️_
