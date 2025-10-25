# Test Implementation Plan - Quick Reference

**Status:** Ready to Execute
**Estimated Time:** 6-8 hours
**Priority Order:** Critical → High → Medium

---

## Quick Summary

**Current State:**
- 487 passing / 221 failing (68.8% pass rate)
- 44 test files
- 2 modules with 0% test coverage (Expenses, Itinerary - partial)

**Target State:**
- 100% pass rate
- All 8 modules with comprehensive E2E tests
- Every feature has positive + negative test cases

---

## Execution Plan

### 🔴 PHASE 1: Fix Broken Tests (2-3 hours)

**Priority 1: Messaging Module Fixes**
```bash
# Files to fix:
test/features/messaging/presentation/widgets/sync_status_sheet_test.dart
test/features/messaging/presentation/widgets/reaction_picker_test.dart

# Issues:
- StreamController close after dispose
- Widget hit test warnings
- Async timing issues

# Solution:
- Add proper tearDown() for stream controllers
- Use pump() and pumpAndSettle() correctly
- Add warnIfMissed: false to tap() calls where appropriate
```

**Priority 2: Onboarding Module Fixes**
```bash
# Files to fix:
test/features/onboarding/presentation/widgets/onboarding_screen_test.dart:677
test/features/onboarding/presentation/pages/onboarding_page_test.dart:390

# Issues:
- Color assertion mismatch (expected vs actual)
- Text finder not finding "Welcome to Travel Crew"

# Solution:
- Update color expectations to match current theme
- Check actual text content in onboarding pages
- Use pumpAndSettle() before assertions
```

**Priority 3: Settings Module Fixes**
```bash
# Files to fix:
test/features/settings/e2e/settings_navigation_e2e_test.dart
test/features/settings/presentation/pages/settings_page_test.dart

# Issues:
- Missing AppThemeProvider in widget tree
- Provider overrides not complete

# Solution:
- Wrap test widgets with all required providers
- Add AppThemeProvider to test setup
```

**Expected Outcome:** Pass rate increases from 68.8% to 85%+

---

### 🟠 PHASE 2: Add Critical Missing Tests (3-4 hours)

**Priority 1: Expenses Module (0% → 80%)**

Create these files:
1. `test/features/expenses/unit/expense_usecases_test.dart`
2. `test/features/expenses/integration/expense_management_integration_test.dart`
3. `test/features/expenses/e2e/expense_flow_e2e_test.dart`

Test Cases:
```dart
// E2E Positive Cases:
✅ User can view expenses list
✅ User can add individual expense
✅ User can add split expense
✅ User can view balance sheet
✅ User can make UPI payment

// E2E Negative Cases:
❌ Empty fields show validation errors
❌ Invalid amount shows error
❌ Payment fails without UPI app
❌ Network error shows retry option
```

**Priority 2: Itinerary Module (30% → 80%)**

Create these files:
1. `test/features/itinerary/unit/itinerary_usecases_test.dart`
2. `test/features/itinerary/integration/itinerary_management_integration_test.dart`
3. `test/features/itinerary/e2e/itinerary_flow_e2e_test.dart`

Test Cases:
```dart
// E2E Positive Cases:
✅ User can view itinerary list
✅ User can add new itinerary item
✅ User can edit existing item
✅ User can delete item

// E2E Negative Cases:
❌ Start date after end date shows error
❌ Empty title shows validation error
❌ Delete requires confirmation
❌ Network error shows message
```

**Priority 3: Auth Module E2E (70% → 90%)**

Create these files:
1. `test/features/auth/e2e/auth_signup_e2e_test.dart`
2. `test/features/auth/e2e/auth_login_e2e_test.dart`
3. `test/features/auth/e2e/auth_profile_e2e_test.dart`

**Expected Outcome:** All modules have E2E coverage

---

### 🟡 PHASE 3: Enhance with Negative Cases (1-2 hours)

For each existing E2E test, add:
- At least 2 negative test cases
- At least 1 edge case
- Error recovery scenarios

**Template:**
```dart
group('Negative Test Cases', () {
  testWidgets('shows validation error for empty field', (tester) async {
    // Arrange: Navigate to form
    // Act: Submit without filling required field
    // Assert: Error message is displayed
  });

  testWidgets('shows network error message', (tester) async {
    // Arrange: Mock network failure
    // Act: Perform action requiring network
    // Assert: Error message with retry option
  });

  testWidgets('handles offline scenario', (tester) async {
    // Arrange: Set offline mode
    // Act: Try to perform online action
    // Assert: Offline message + queue option
  });
});
```

**Expected Outcome:** Every E2E test has 60% positive, 40% negative ratio

---

## Test File Templates

### E2E Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('[Feature] E2E Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Add provider overrides here
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Positive Test Cases', () {
      testWidgets('✅ [Happy path description]', (tester) async {
        // Arrange
        await tester.pumpWidget(/* Widget tree */);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byKey(/* key */));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(/* expected */), findsOneWidget);
      });
    });

    group('Negative Test Cases', () {
      testWidgets('❌ [Error scenario description]', (tester) async {
        // Test implementation
      });
    });

    group('Edge Cases', () {
      testWidgets('🔸 [Edge case description]', (tester) async {
        // Test implementation
      });
    });
  });
}
```

### Integration Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([Repository, DataSource])
void main() {
  group('[Feature] Integration Tests', () {
    late MockRepository mockRepository;

    setUp(() {
      mockRepository = MockRepository();
    });

    test('✅ successful workflow', () async {
      // Arrange
      when(mockRepository.method()).thenAnswer((_) async => result);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, expectedResult);
      verify(mockRepository.method()).called(1);
    });

    test('❌ error handling', () async {
      // Arrange
      when(mockRepository.method()).thenThrow(Exception());

      // Act & Assert
      expect(() => useCase.execute(), throwsException);
    });
  });
}
```

---

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Module
```bash
flutter test test/features/expenses/
flutter test test/features/itinerary/
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Only E2E Tests
```bash
flutter test test/features/*/e2e/
```

### Run Only Integration Tests
```bash
flutter test test/features/*/integration/
```

---

## Success Checklist

### Phase 1: Fixes
- [ ] Messaging sync_status_sheet_test.dart passes
- [ ] Messaging reaction_picker_test.dart passes
- [ ] Onboarding color assertions fixed
- [ ] Onboarding text finders fixed
- [ ] Settings provider issues resolved
- [ ] Pass rate > 85%

### Phase 2: New Tests
- [ ] Expenses module has 3 test files
- [ ] Expenses E2E has 5+ positive + 4+ negative cases
- [ ] Itinerary module has 3 test files
- [ ] Itinerary E2E has 4+ positive + 4+ negative cases
- [ ] Auth module has 3 E2E test files
- [ ] All 8 modules have E2E coverage

### Phase 3: Enhancement
- [ ] Every E2E test has negative cases
- [ ] Edge cases added to all modules
- [ ] Error recovery scenarios tested
- [ ] Offline scenarios tested

### Final Validation
- [ ] Pass rate = 100%
- [ ] No skipped tests
- [ ] Code coverage > 80%
- [ ] All modules green
- [ ] Documentation updated

---

## Quick Commands Reference

```bash
# Fix tests
flutter test test/features/messaging/presentation/widgets/

# Add new test file
touch test/features/expenses/e2e/expense_flow_e2e_test.dart

# Generate mocks
flutter pub run build_runner build

# Run single test file
flutter test test/features/expenses/e2e/expense_flow_e2e_test.dart

# Watch mode (auto-run on changes)
flutter test --watch

# Verbose output
flutter test --verbose

# Stop on first failure
flutter test --fail-fast
```

---

**Next Action:** Start with Phase 1 - Fix broken tests
**Time Estimate:** 2-3 hours
**Files to Edit:** 5 test files

Ready to begin! 🚀

