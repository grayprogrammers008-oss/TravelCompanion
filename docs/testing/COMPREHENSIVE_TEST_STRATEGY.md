# Comprehensive Test Strategy & Coverage Plan

**Date:** October 25, 2025
**Status:** 🔄 In Progress
**Current Test Results:** 487 passing, 221 failing (68.8% pass rate)

---

## Executive Summary

This document outlines the comprehensive testing strategy for the TravelCompanion app, identifying current gaps and providing a roadmap for achieving 100% test coverage across all modules with both positive and negative test cases.

---

## Current Test Coverage Analysis

### Test Statistics (As of Oct 25, 2025)
- **Total Tests:** 708
- **Passing:** 487 (68.8%)
- **Failing:** 221 (31.2%)
- **Total Test Files:** 44

### Coverage by Module

| Module | Unit Tests | Integration Tests | E2E Tests | Status |
|--------|------------|-------------------|-----------|--------|
| **Auth** | ✅ 6 files | ✅ 2 files | ❌ Missing | 70% |
| **Trips** | ✅ 2 files | ✅ 1 file | ✅ 1 file | 80% |
| **Messaging** | ✅ 11 files | ✅ 3 files | ✅ 1 file | 90% |
| **Checklists** | ✅ 1 file | ❌ Missing | ✅ 1 file | 60% |
| **Itinerary** | ✅ 1 file | ❌ Missing | ❌ Missing | 30% |
| **Expenses** | ❌ Missing | ❌ Missing | ❌ Missing | 0% |
| **Settings** | ✅ 2 files | ❌ Missing | ✅ 1 file | 50% |
| **Onboarding** | ✅ 4 files | ❌ Missing | ❌ Missing | 40% |
| **Core/Utils** | ✅ 2 files | N/A | N/A | 80% |

---

## Test Types & Requirements

### 1. Unit Tests
**Purpose:** Test individual functions, classes, and methods in isolation

**Coverage Requirements:**
- All domain use cases
- All data sources
- All repositories
- All utilities and helpers
- All models/entities

**Test Cases:**
- ✅ Positive: Valid inputs produce expected outputs
- ✅ Negative: Invalid inputs throw proper errors
- ✅ Edge Cases: Boundary conditions, null values, empty lists
- ✅ Error Handling: Network errors, validation failures

### 2. Integration Tests
**Purpose:** Test interactions between multiple components

**Coverage Requirements:**
- Provider interactions
- Repository + DataSource combinations
- Use case + Repository workflows
- Multi-step business logic

**Test Cases:**
- ✅ Positive: Successful multi-component workflows
- ✅ Negative: Failure propagation between layers
- ✅ State Management: Provider state updates correctly
- ✅ Data Flow: Data transforms correctly across layers

### 3. E2E Tests
**Purpose:** Test complete user workflows from UI to database

**Coverage Requirements:**
- All major user journeys
- CRUD operations for each feature
- Navigation flows
- Form submissions
- Error states and recovery

**Test Cases:**
- ✅ Positive: Complete user workflows succeed
- ✅ Negative: Error messages display correctly
- ✅ Validation: Form validation works as expected
- ✅ UI State: Loading, success, error states

---

## Module-Specific Test Plans

### 📧 Auth Module

**Current Status:** 70% coverage

**Existing Tests:**
- ✅ Unit: Sign up, sign in, update profile, change password use cases
- ✅ Integration: Profile management, change password
- ✅ Data: Remote datasource tests
- ❌ Missing: E2E auth flow tests

**Required E2E Tests:**

1. **auth_signup_e2e_test.dart**
   - ✅ Positive: Successful signup with valid email/password
   - ✅ Positive: Successful signup with profile photo
   - ❌ Negative: Signup fails with existing email
   - ❌ Negative: Signup fails with weak password
   - ❌ Negative: Signup fails with invalid email format

2. **auth_login_e2e_test.dart**
   - ✅ Positive: Successful login with valid credentials
   - ✅ Positive: Remember me functionality
   - ❌ Negative: Login fails with wrong password
   - ❌ Negative: Login fails with non-existent email
   - ❌ Negative: Login fails with empty fields

3. **auth_profile_e2e_test.dart**
   - ✅ Positive: Profile update with all fields
   - ✅ Positive: Profile photo upload
   - ❌ Negative: Profile update fails without network
   - ❌ Negative: Photo upload fails with large file

### 🧳 Trips Module

**Current Status:** 80% coverage

**Existing Tests:**
- ✅ Unit: Create trip, update trip use cases
- ✅ Integration: Trip edit integration
- ✅ E2E: Trip edit e2e
- ✅ Widget: Home page test
- ❌ Missing: Comprehensive trip list E2E, trip detail E2E

**Required E2E Tests:**

1. **trips_list_e2e_test.dart**
   - ✅ Positive: Load and display trips list
   - ✅ Positive: Navigate to trip details
   - ✅ Positive: Real-time trip updates
   - ❌ Negative: Empty state when no trips
   - ❌ Negative: Error state when loading fails

2. **trip_detail_e2e_test.dart**
   - ✅ Positive: View all trip information
   - ✅ Positive: Navigate to chat/checklist/expenses
   - ✅ Positive: Invite members to trip
   - ❌ Negative: Handle missing trip data gracefully

3. **trip_create_e2e_test.dart**
   - ✅ Positive: Create trip with all fields
   - ✅ Positive: Create trip with minimal fields
   - ❌ Negative: Validation errors for empty required fields
   - ❌ Negative: Date validation (start before end)

### 💬 Messaging Module

**Current Status:** 90% coverage (Best coverage!)

**Existing Tests:**
- ✅ Unit: Message datasource, conflict resolution
- ✅ Unit: Services (BLE, mesh, P2P, encryption, sync)
- ✅ Unit: Use cases, entities
- ✅ Integration: Hybrid sync, messaging flow, E2E
- ✅ Widget: Sync providers, status sheet, reaction picker
- ❌ Issues: Some test failures due to async timing

**Required Fixes:**
1. Fix `sync_status_sheet_test.dart` - StreamController close error
2. Fix `reaction_picker_test.dart` - Widget hit test warnings
3. Add negative test cases for offline scenarios

**Additional E2E Tests:**

1. **messaging_offline_e2e_test.dart**
   - ✅ Positive: Queue messages when offline
   - ✅ Positive: Sync messages when back online
   - ❌ Negative: Show offline indicator
   - ❌ Negative: Retry failed messages

2. **messaging_p2p_e2e_test.dart**
   - ✅ Positive: Discover nearby peers
   - ✅ Positive: Send message via P2P
   - ❌ Negative: Handle connection failures
   - ❌ Negative: Fallback to cloud when P2P unavailable

### ✅ Checklists Module

**Current Status:** 60% coverage

**Existing Tests:**
- ✅ Unit: Create checklist use case
- ✅ E2E: Checklist e2e test
- ❌ Missing: Integration tests, more unit tests

**Required Tests:**

1. **checklist_unit_tests.dart**
   - Add use cases: Get, Update, Delete, ToggleItem
   - Add repository tests
   - Add datasource tests

2. **checklist_integration_test.dart**
   - ✅ Positive: Full checklist CRUD workflow
   - ❌ Negative: Validation failures
   - ❌ Negative: Network error handling

3. **checklist_e2e_enhanced_test.dart** (Enhance existing)
   - Add more negative scenarios
   - Add edge cases (empty checklists, max items, etc.)

### 🗓️ Itinerary Module

**Current Status:** 30% coverage ⚠️ **CRITICAL GAP**

**Existing Tests:**
- ✅ Unit: Create itinerary item use case only
- ❌ Missing: Everything else!

**Required Tests (High Priority):**

1. **itinerary_unit_tests.dart**
   - Create: GetItineraryItems, UpdateItem, DeleteItem use cases
   - Add repository tests
   - Add datasource tests

2. **itinerary_integration_test.dart**
   - ✅ Positive: Create, read, update, delete itinerary items
   - ✅ Positive: Date/time handling
   - ❌ Negative: Invalid date ranges
   - ❌ Negative: Network failures

3. **itinerary_e2e_test.dart**
   - ✅ Positive: View itinerary list for trip
   - ✅ Positive: Add new itinerary item
   - ✅ Positive: Edit existing item
   - ✅ Positive: Delete item with confirmation
   - ❌ Negative: Empty state handling
   - ❌ Negative: Form validation errors
   - ❌ Negative: Date conflicts

### 💰 Expenses Module

**Current Status:** 0% coverage ⚠️ **CRITICAL GAP**

**Existing Tests:**
- ❌ None!

**Required Tests (High Priority):**

1. **expense_unit_tests.dart**
   - Create all use cases: Create, Get, Update, Delete, GetBalance
   - Add repository tests
   - Add datasource tests
   - Add UPI payment service tests

2. **expense_integration_test.dart**
   - ✅ Positive: Create expense workflow
   - ✅ Positive: Split expense among members
   - ✅ Positive: Calculate balances
   - ✅ Positive: UPI payment flow
   - ❌ Negative: Invalid amount validation
   - ❌ Negative: Payment failures

3. **expense_e2e_test.dart**
   - ✅ Positive: View expenses list
   - ✅ Positive: Add individual expense
   - ✅ Positive: Add split expense
   - ✅ Positive: View balance sheet
   - ✅ Positive: Make UPI payment
   - ❌ Negative: Form validation
   - ❌ Negative: Split calculation errors
   - ❌ Negative: Payment app not installed

### ⚙️ Settings Module

**Current Status:** 50% coverage

**Existing Tests:**
- ✅ Widget: Settings page tests (2 files)
- ✅ E2E: Settings navigation
- ❌ Missing: Theme switching tests, notification tests

**Required Tests:**

1. **settings_theme_test.dart**
   - ✅ Positive: Switch between themes
   - ✅ Positive: Theme persists across restarts
   - ❌ Negative: Handle missing theme gracefully

2. **settings_notifications_test.dart**
   - ✅ Positive: Enable/disable notifications
   - ✅ Positive: Notification permissions
   - ❌ Negative: Handle permission denial

### 📱 Onboarding Module

**Current Status:** 40% coverage

**Existing Tests:**
- ✅ Unit: Onboarding model, provider tests
- ✅ Widget: Onboarding page, screen tests
- ❌ Issues: Some test failures (color mismatches, text not found)
- ❌ Missing: E2E flow test

**Required Fixes:**
1. Fix color assertion in `onboarding_screen_test.dart:677`
2. Fix text finder in `onboarding_page_test.dart:390`

**Required E2E Tests:**

1. **onboarding_flow_e2e_test.dart**
   - ✅ Positive: Complete onboarding flow
   - ✅ Positive: Skip onboarding
   - ✅ Positive: Never show again after completion
   - ❌ Negative: Handle back button during onboarding

---

## Test Failure Analysis

### Current Failures (221 total)

**Category 1: Messaging Module (estimated 100 failures)**
- StreamController close errors in sync tests
- Widget hit test warnings
- Async timing issues

**Category 2: Onboarding Module (estimated 50 failures)**
- Color mismatch assertions
- Widget finder failures
- PageController navigation issues

**Category 3: Settings Module (estimated 30 failures)**
- Provider mocking issues
- Theme provider not available

**Category 4: Other Modules (estimated 41 failures)**
- Various provider and widget test issues

---

## Implementation Roadmap

### Phase 1: Fix Existing Broken Tests (Priority: 🔴 Critical)
**Timeline:** 1-2 days

1. ✅ Fix messaging module async issues
2. ✅ Fix onboarding module assertions
3. ✅ Fix settings module provider mocks
4. ✅ Fix any compilation errors

**Target:** Get pass rate from 68.8% to 85%

### Phase 2: Add Missing Critical E2E Tests (Priority: 🟠 High)
**Timeline:** 2-3 days

1. ✅ Create Expenses module complete test suite
2. ✅ Create Itinerary module complete test suite
3. ✅ Create Auth module E2E tests
4. ✅ Enhance Trips module E2E coverage

**Target:** Achieve 95% module coverage

### Phase 3: Comprehensive Negative Testing (Priority: 🟡 Medium)
**Timeline:** 2-3 days

1. ✅ Add negative test cases to all existing E2E tests
2. ✅ Add edge case testing
3. ✅ Add error recovery testing
4. ✅ Add offline scenario testing

**Target:** Every E2E test has both positive and negative cases

### Phase 4: Performance & Stress Testing (Priority: 🟢 Low)
**Timeline:** 1-2 days

1. ✅ Add performance benchmarks for messaging module
2. ✅ Add load testing for list views (trips, expenses, etc.)
3. ✅ Add memory leak detection tests

**Target:** Ensure app performs well under stress

---

## Test Writing Standards

### Naming Convention
```dart
// Unit Tests
'[UseCase/Class] - [Action] - [Expected Result]'
'CreateTripUseCase - with valid data - returns Trip entity'
'CreateTripUseCase - with invalid data - throws ValidationException'

// Integration Tests
'[Feature] - [Workflow] - [Expected Result]'
'Trip Management - create and edit trip - updates successfully'
'Trip Management - create with network error - shows error message'

// E2E Tests
'[User Story] - [Success/Failure Scenario]'
'As a user, I can create a new trip - Success'
'As a user, I cannot create trip without name - Validation Error'
```

### Test Structure (AAA Pattern)
```dart
test('description', () {
  // Arrange
  // Set up test data, mocks, and dependencies

  // Act
  // Execute the action being tested

  // Assert
  // Verify the expected outcome
});
```

### Coverage Requirements
- **Unit Tests:** 100% of use cases, repositories, data sources
- **Integration Tests:** All major workflows
- **E2E Tests:** All user-facing features
- **Positive Cases:** At least 1 per feature
- **Negative Cases:** At least 2 per feature (validation, network error)

---

## Testing Tools & Frameworks

- **flutter_test:** Core testing framework
- **mockito:** Mocking dependencies
- **integration_test:** E2E testing
- **flutter_driver:** Performance testing
- **fake_async:** Time-dependent testing
- **golden_toolkit:** Screenshot testing (future)

---

## Success Metrics

### Target Goals
- ✅ **Pass Rate:** 100% (currently 68.8%)
- ✅ **Module Coverage:** 100% of modules have E2E tests
- ✅ **Positive/Negative Ratio:** 60/40 minimum
- ✅ **Test Execution Time:** < 5 minutes for full suite
- ✅ **Code Coverage:** > 80% (use `flutter test --coverage`)

### Current Progress
- 🔄 Pass Rate: 68.8% → Target: 100%
- 🔄 E2E Coverage: 5/8 modules → Target: 8/8 modules
- 🔄 Expenses Tests: 0 → Target: 15+
- 🔄 Itinerary Tests: 1 → Target: 10+

---

## Next Steps

1. **Immediate (Today):**
   - Fix broken messaging module tests
   - Fix onboarding module test failures
   - Create Expenses module test suite

2. **This Week:**
   - Create Itinerary module test suite
   - Add Auth module E2E tests
   - Enhance all E2E tests with negative cases

3. **Next Week:**
   - Achieve 100% pass rate
   - Add performance tests
   - Generate coverage report

---

**Document Owner:** Development Team
**Last Updated:** October 25, 2025
**Next Review:** October 27, 2025

