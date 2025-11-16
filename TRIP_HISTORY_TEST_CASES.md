# Trip History Feature - Test Cases and Steps

**Feature:** Trip History - View and analyze completed trips with ratings and statistics
**Created:** 2025-11-16
**Test Coverage:** Unit Tests, Integration Tests, E2E Tests

---

## Table of Contents
1. [Unit Test Cases](#unit-test-cases)
2. [Integration Test Cases](#integration-test-cases)
3. [End-to-End Test Cases](#end-to-end-test-cases)
4. [Manual Testing Guide](#manual-testing-guide)
5. [Test Execution Steps](#test-execution-steps)

---

## Unit Test Cases

### File: `test/features/trips/domain/usecases/get_trip_history_usecase_test.dart`

#### Test Suite 1: GetTripHistoryUseCase - call()

**TC-U001: Filter Completed Trips**
- **Objective:** Verify that only completed trips are returned
- **Steps:**
  1. Create mock data with 2 completed trips and 1 active trip
  2. Call `useCase.call()`
  3. Verify result contains exactly 2 trips
  4. Verify all returned trips have `isCompleted = true`
- **Expected Result:** Only completed trips returned
- **Priority:** High

**TC-U002: Sort by Completion Date Descending**
- **Objective:** Verify trips are sorted newest first
- **Steps:**
  1. Create 3 completed trips with different completion dates (March, June, May)
  2. Call `useCase.call()`
  3. Verify result[0] is June trip (newest)
  4. Verify result[1] is May trip (middle)
  5. Verify result[2] is March trip (oldest)
- **Expected Result:** Trips sorted by completion date descending
- **Priority:** High

**TC-U003: Handle Null Completion Dates**
- **Objective:** Verify trips without completion dates are handled gracefully
- **Steps:**
  1. Create 1 trip with completedAt date
  2. Create 1 trip with completedAt = null
  3. Call `useCase.call()`
  4. Verify trip with date comes first
  5. Verify trip without date comes last
- **Expected Result:** Trips with dates prioritized, nulls go to end
- **Priority:** Medium

**TC-U004: Empty List When No Completed Trips**
- **Objective:** Verify empty list returned when all trips are active
- **Steps:**
  1. Create 2 active trips (isCompleted = false)
  2. Call `useCase.call()`
  3. Verify result is empty list
- **Expected Result:** Empty list returned
- **Priority:** High

**TC-U005: Exception Handling**
- **Objective:** Verify exceptions from repository are propagated
- **Steps:**
  1. Mock repository to throw Exception('Network error')
  2. Call `useCase.call()`
  3. Verify exception is thrown
- **Expected Result:** Exception propagated to caller
- **Priority:** High

#### Test Suite 2: GetTripHistoryUseCase - watchHistory()

**TC-U006: Stream Emits Completed Trips Only**
- **Objective:** Verify real-time stream filters completed trips
- **Steps:**
  1. Mock repository to emit stream with 1 completed and 1 active trip
  2. Call `useCase.watchHistory()`
  3. Verify stream emits list with 1 trip
  4. Verify emitted trip is completed
- **Expected Result:** Stream filters to completed trips only
- **Priority:** High

**TC-U007: Stream Emits Sorted Trips**
- **Objective:** Verify stream emits trips in sorted order
- **Steps:**
  1. Mock repository to emit old trip and new trip
  2. Call `useCase.watchHistory()`
  3. Verify stream emits list with new trip first
- **Expected Result:** Trips sorted newest first in stream
- **Priority:** Medium

#### Test Suite 3: GetTripHistoryUseCase - getStatistics()

**TC-U008: Calculate Statistics Correctly**
- **Objective:** Verify statistics calculation is accurate
- **Steps:**
  1. Create 3 completed trips with ratings 4.0, 5.0, 3.0
  2. Call `useCase.getStatistics()`
  3. Verify totalCompletedTrips = 3
  4. Verify totalRatedTrips = 3
  5. Verify averageRating = 4.0
  6. Verify earliest and latest completion dates
- **Expected Result:** All statistics calculated correctly
- **Priority:** High

**TC-U009: Handle Trips Without Ratings**
- **Objective:** Verify statistics exclude unrated trips
- **Steps:**
  1. Create 1 trip with rating 4.5
  2. Create 1 trip with rating 0.0 (unrated)
  3. Call `useCase.getStatistics()`
  4. Verify totalCompletedTrips = 2
  5. Verify totalRatedTrips = 1
  6. Verify averageRating = 4.5 (excludes unrated)
- **Expected Result:** Unrated trips excluded from average calculation
- **Priority:** High

**TC-U010: Empty Statistics**
- **Objective:** Verify empty statistics when no trips
- **Steps:**
  1. Mock repository to return empty list
  2. Call `useCase.getStatistics()`
  3. Verify all counts are 0
  4. Verify dates are null
  5. Verify hasAnyTrips = false
- **Expected Result:** TripHistoryStatistics.empty() returned
- **Priority:** Medium

**TC-U011: Format Average Rating**
- **Objective:** Verify rating formatted to 1 decimal place
- **Steps:**
  1. Create trip with rating 4.666666
  2. Call `useCase.getStatistics()`
  3. Call `stats.formattedAverageRating`
  4. Verify result is '4.7'
- **Expected Result:** Rating rounded and formatted correctly
- **Priority:** Low

#### Test Suite 4: TripHistoryStatistics

**TC-U012: Empty Factory**
- **Objective:** Verify empty factory creates correct state
- **Steps:**
  1. Call `TripHistoryStatistics.empty()`
  2. Verify all numeric fields are 0
  3. Verify all date fields are null
  4. Verify hasAnyTrips = false
  5. Verify hasRatedTrips = false
- **Expected Result:** Correct empty state created
- **Priority:** Low

---

## Integration Test Cases

### File: `test/features/trips/integration/trip_history_integration_test.dart`

#### Test Suite 1: Trip History Integration

**TC-I001: Fetch and Filter from Data Source**
- **Objective:** Verify data flows correctly through repository layer
- **Steps:**
  1. Mock data source to return 3 trips (2 completed, 1 active)
  2. Call `useCase.call()` through repository
  3. Verify only 2 completed trips returned
  4. Verify data source was called once
- **Expected Result:** Data correctly flows through all layers
- **Priority:** High

**TC-I002: Statistics Across Data Layers**
- **Objective:** Verify statistics calculation through repository
- **Steps:**
  1. Mock data source with 3 trips (2 rated, 1 unrated)
  2. Call `useCase.getStatistics()`
  3. Verify statistics calculated from raw data source data
  4. Verify average excludes unrated trip
- **Expected Result:** Statistics accurate across layers
- **Priority:** High

**TC-I003: Real-time Stream Updates**
- **Objective:** Verify stream updates flow through repository
- **Steps:**
  1. Mock data source stream to emit initial data
  2. Emit updated data with new completed trip
  3. Verify stream emits both updates
  4. Verify second emission includes new trip
- **Expected Result:** Real-time updates propagated correctly
- **Priority:** High

**TC-I004: Data Source Error Handling**
- **Objective:** Verify errors propagate correctly
- **Steps:**
  1. Mock data source to throw Exception
  2. Call `useCase.call()`
  3. Verify exception reaches use case level
- **Expected Result:** Exceptions propagate through layers
- **Priority:** High

**TC-I005: Preserve Member Information**
- **Objective:** Verify trip member data is not lost
- **Steps:**
  1. Create trip with 2 members (John Doe, Jane Smith)
  2. Fetch through repository
  3. Verify member list preserved
  4. Verify member names correct
- **Expected Result:** All member data preserved through layers
- **Priority:** Medium

#### Test Suite 2: Error Scenarios

**TC-I006: Network Timeout**
- **Objective:** Verify timeout errors are handled
- **Steps:**
  1. Mock data source to throw timeout exception
  2. Call `useCase.call()`
  3. Verify exception thrown
- **Expected Result:** Timeout exception propagated
- **Priority:** Medium

**TC-I007: Invalid Data Format**
- **Objective:** Verify handling of malformed data
- **Steps:**
  1. Create trip with empty ID and name
  2. Process through use case
  3. Verify trip still processed
- **Expected Result:** Malformed data handled gracefully
- **Priority:** Low

**TC-I008: Concurrent Statistics Access**
- **Objective:** Verify thread-safe statistics calculation
- **Steps:**
  1. Mock data source with 10 trips
  2. Make 5 concurrent `getStatistics()` calls
  3. Await all futures
  4. Verify all return same statistics
- **Expected Result:** Concurrent access handled safely
- **Priority:** Low

---

## End-to-End Test Cases

### File: `test/features/trips/e2e/trip_history_e2e_test.dart`

#### Test Suite 1: UI Display

**TC-E001: Display Trip History Page**
- **Objective:** Verify page renders with all components
- **Steps:**
  1. Launch app to Trip History page
  2. Verify 'Trip History' title displayed
  3. Verify statistics header present
  4. Verify trip list visible
- **Expected Result:** All page components render correctly
- **User Action:** None (automatic on page load)
- **Priority:** High

**TC-E002: Display Statistics Header**
- **Objective:** Verify statistics section shows correct data
- **Steps:**
  1. Load page with 2 completed trips (4.5 and 5.0 rating)
  2. Verify 'Total Trips' shows '2'
  3. Verify 'Avg Rating' shows '4.8'
  4. Verify 'Rated' shows '2/2'
- **Expected Result:** Statistics calculated and displayed correctly
- **User Action:** View statistics section
- **Priority:** High

**TC-E003: Display Trip Cards**
- **Objective:** Verify each trip shows all information
- **Steps:**
  1. Load page with Paris and Tokyo trips
  2. Verify 'Paris Adventure' card displayed
  3. Verify destination 'Paris, France' shown
  4. Verify rating badge shows '4.5'
  5. Verify member count '2 members'
  6. Verify completion date 'May 15, 2024'
- **Expected Result:** All trip details displayed correctly
- **User Action:** Scroll through trip list
- **Priority:** High

**TC-E004: Empty State**
- **Objective:** Verify empty state when no trips
- **Steps:**
  1. Load page with no completed trips
  2. Verify 'No completed trips yet' message
  3. Verify history icon displayed
  4. Verify helper text about completing trips
- **Expected Result:** Friendly empty state displayed
- **User Action:** None (state visible immediately)
- **Priority:** High

**TC-E005: Loading State**
- **Objective:** Verify loading indicator during data fetch
- **Steps:**
  1. Load page (delay data fetch)
  2. Verify circular progress indicator shown
  3. Wait for data to load
  4. Verify indicator disappears
- **Expected Result:** Loading state provides feedback
- **User Action:** Wait for data to load
- **Priority:** Medium

**TC-E006: Error State**
- **Objective:** Verify error display when fetch fails
- **Steps:**
  1. Simulate network error
  2. Load page
  3. Verify 'Error loading trip history' message
  4. Verify error icon displayed
  5. Verify error details shown
- **Expected Result:** Clear error message displayed
- **User Action:** None (error shown automatically)
- **Priority:** High

#### Test Suite 2: User Interactions

**TC-E007: Navigate to Trip Detail**
- **Objective:** Verify tapping trip card navigates to detail
- **Steps:**
  1. Load page with trips
  2. Tap 'Paris Adventure' card
  3. Verify navigation initiated
- **Expected Result:** User taken to trip detail page
- **User Action:** Tap on trip card
- **Priority:** High

**TC-E008: Scroll Through Trips**
- **Objective:** Verify long lists are scrollable
- **Steps:**
  1. Load page with 20 trips
  2. Scroll down list
  3. Verify older trips appear
  4. Verify scrolling is smooth
- **Expected Result:** Can scroll through entire list
- **User Action:** Swipe up to scroll
- **Priority:** Medium

#### Test Suite 3: Data Validation

**TC-E009: Trips Sorted Correctly**
- **Objective:** Verify display order (newest first)
- **Steps:**
  1. Load trips with completion dates: March, June, May
  2. Verify first card is June trip
  3. Verify second card is May trip
  4. Verify third card is March trip
- **Expected Result:** Newest trip displayed first
- **User Action:** View trip order in list
- **Priority:** High

**TC-E010: Unrated Trips**
- **Objective:** Verify trips without ratings display correctly
- **Steps:**
  1. Load page with unrated trip (rating = 0.0)
  2. Verify trip card has no rating badge
  3. Verify trip still displayed in list
- **Expected Result:** Unrated trips shown without rating badge
- **User Action:** Look for rating badge
- **Priority:** Medium

**TC-E011: Date Ranges**
- **Objective:** Verify trip date range formatting
- **Steps:**
  1. Load trip with dates May 1-10, 2024
  2. Verify display shows 'May 01, 2024 - May 10, 2024'
  3. Load trip with only start date
  4. Verify shows 'From May 01, 2024'
- **Expected Result:** Date ranges formatted correctly
- **User Action:** Read trip dates
- **Priority:** Low

#### Test Suite 4: Accessibility

**TC-E012: Screen Reader Support**
- **Objective:** Verify semantic labels for accessibility
- **Steps:**
  1. Enable screen reader
  2. Navigate to Trip History page
  3. Verify 'Trip History' label announced
  4. Verify trip cards have descriptive labels
- **Expected Result:** All UI elements have proper semantics
- **User Action:** Use screen reader navigation
- **Priority:** Medium

**TC-E013: Large Text Support**
- **Objective:** Verify layout with increased text size
- **Steps:**
  1. Set device text size to 200%
  2. Load Trip History page
  3. Verify no text overflow
  4. Verify all content readable
- **Expected Result:** Layout adapts to large text
- **User Action:** Change system text size
- **Priority:** Low

#### Test Suite 5: Performance

**TC-E014: Render Many Trips Efficiently**
- **Objective:** Verify performance with 100 trips
- **Steps:**
  1. Load page with 100 completed trips
  2. Measure render time
  3. Verify renders in < 1 second
  4. Verify smooth scrolling
- **Expected Result:** Efficient rendering with large datasets
- **User Action:** Open page with many trips
- **Priority:** Medium

---

## Manual Testing Guide

### Prerequisites
1. Flutter development environment set up
2. Device/emulator running
3. At least 3 completed trips in database
4. At least 1 active (uncompleted) trip in database

### Manual Test Scenarios

#### Scenario 1: View Trip History
**Steps:**
1. Open TravelCompanion app
2. Navigate to Trips section
3. Tap on 'Trip History' option
4. Observe the Trip History page loads
5. Verify statistics header appears with correct counts
6. Scroll through list of completed trips
7. Verify each trip shows: name, destination, rating, member count, dates
8. Tap on a trip card
9. Verify navigation to trip detail page

**Expected Result:** All trip information displayed accurately, navigation works

#### Scenario 2: Empty History
**Steps:**
1. Create new user account (no trips)
2. Navigate to Trip History
3. Observe empty state message
4. Verify friendly message encouraging completing trips

**Expected Result:** Clear empty state with helpful guidance

#### Scenario 3: Statistics Accuracy
**Steps:**
1. Note down actual completed trips and ratings from database
2. Calculate expected average rating manually
3. Open Trip History page
4. Verify statistics match calculations:
   - Total trips count
   - Average rating
   - Rated trips ratio

**Expected Result:** Statistics match manual calculations

#### Scenario 4: Real-time Updates
**Steps:**
1. Open Trip History page
2. From another device/session, complete an active trip
3. Rate the completed trip
4. Observe Trip History page
5. Verify new trip appears automatically (if real-time enabled)
6. Or pull-to-refresh to see new trip

**Expected Result:** Page updates with new completed trip

#### Scenario 5: Error Handling
**Steps:**
1. Turn off device internet
2. Navigate to Trip History page
3. Observe error message displayed
4. Turn internet back on
5. Retry/refresh page
6. Verify trips load successfully

**Expected Result:** Clear error message, recovery works

---

## Test Execution Steps

### Running Unit Tests

```bash
# Run all unit tests for Trip History use case
flutter test test/features/trips/domain/usecases/get_trip_history_usecase_test.dart

# Run with coverage
flutter test --coverage test/features/trips/domain/usecases/get_trip_history_usecase_test.dart

# Run specific test
flutter test test/features/trips/domain/usecases/get_trip_history_usecase_test.dart --name "should return only completed trips"
```

### Running Integration Tests

```bash
# Run integration tests
flutter test test/features/trips/integration/trip_history_integration_test.dart

# Run with verbose output
flutter test --verbose test/features/trips/integration/trip_history_integration_test.dart
```

### Running E2E Tests

```bash
# Run E2E tests
flutter test test/features/trips/e2e/trip_history_e2e_test.dart

# Run all Trip History tests
flutter test test/features/trips/ --name "history"
```

### Generating Test Coverage Report

```bash
# Generate coverage for entire Trip History feature
flutter test --coverage test/features/trips/

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
# On Windows
start coverage/html/index.html

# On Mac
open coverage/html/index.html

# On Linux
xdg-open coverage/html/index.html
```

### Running Mocks Generation

```bash
# Generate mocks for all test files
dart run build_runner build --delete-conflicting-outputs

# Watch mode (regenerate on changes)
dart run build_runner watch --delete-conflicting-outputs
```

---

## Test Coverage Goals

| Layer | Target Coverage | Current |
|-------|----------------|---------|
| Domain (Use Cases) | 100% | - |
| Data (Repository) | 90% | - |
| Presentation (UI) | 80% | - |
| E2E (User Flows) | Key flows | - |

---

## Test Data Setup

### Sample Test Data

**Completed Trip 1:**
```json
{
  "id": "trip_001",
  "name": "Paris Adventure",
  "destination": "Paris, France",
  "startDate": "2024-05-01",
  "endDate": "2024-05-10",
  "isCompleted": true,
  "completedAt": "2024-05-15T10:00:00Z",
  "rating": 4.5,
  "members": [
    {"userId": "user1", "role": "admin", "userName": "John Doe"},
    {"userId": "user2", "role": "member", "userName": "Jane Smith"}
  ]
}
```

**Completed Trip 2:**
```json
{
  "id": "trip_002",
  "name": "Tokyo Experience",
  "destination": "Tokyo, Japan",
  "startDate": "2024-06-01",
  "endDate": "2024-06-15",
  "isCompleted": true,
  "completedAt": "2024-06-20T15:30:00Z",
  "rating": 5.0,
  "members": [
    {"userId": "user1", "role": "admin", "userName": "John Doe"}
  ]
}
```

**Active Trip (Not in history):**
```json
{
  "id": "trip_003",
  "name": "London Trip",
  "destination": "London, UK",
  "startDate": "2024-07-01",
  "endDate": "2024-07-10",
  "isCompleted": false,
  "members": [
    {"userId": "user1", "role": "admin", "userName": "John Doe"}
  ]
}
```

---

## Regression Testing Checklist

Before releasing Trip History feature:

- [ ] All unit tests passing (100%)
- [ ] All integration tests passing
- [ ] All E2E tests passing
- [ ] Manual testing completed on:
  - [ ] iOS device
  - [ ] Android device
  - [ ] iOS simulator
  - [ ] Android emulator
- [ ] Accessibility testing completed
- [ ] Performance testing completed (100+ trips)
- [ ] Error scenarios tested (network issues, timeouts)
- [ ] Real-time updates verified (if applicable)
- [ ] Statistics calculations verified manually
- [ ] UI matches design specifications
- [ ] Navigation flows work correctly
- [ ] Empty states handled gracefully
- [ ] Loading states provide feedback

---

## Known Issues / Edge Cases

1. **Trips without completion dates:** Currently handled by sorting nulls to end
2. **Concurrent trip completions:** Real-time stream should handle updates
3. **Very long trip names:** UI should truncate with ellipsis
4. **No internet connection:** Error state displayed, retry available
5. **Large number of trips:** ListView handles efficiently with lazy loading

---

## Test Maintenance Notes

- Run mock generation after changes to interfaces: `dart run build_runner build`
- Update test data when TripModel schema changes
- Review and update test cases when requirements change
- Keep this document in sync with actual test files
- Document any new edge cases discovered during testing

---

**Document Version:** 1.0
**Last Updated:** 2025-11-16
**Maintained By:** Development Team
