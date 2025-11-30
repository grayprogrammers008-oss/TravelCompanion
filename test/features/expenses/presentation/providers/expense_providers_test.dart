import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/expenses/presentation/providers/expense_providers.dart';

void main() {
  group('ExpenseState', () {
    test('should create ExpenseState with default values', () {
      final state = ExpenseState();

      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should create ExpenseState with loading true', () {
      final state = ExpenseState(isLoading: true);

      expect(state.isLoading, true);
      expect(state.error, isNull);
    });

    test('should create ExpenseState with error', () {
      final state = ExpenseState(error: 'Something went wrong');

      expect(state.isLoading, false);
      expect(state.error, 'Something went wrong');
    });

    test('should create ExpenseState with both isLoading and error', () {
      final state = ExpenseState(isLoading: true, error: 'Error occurred');

      expect(state.isLoading, true);
      expect(state.error, 'Error occurred');
    });

    group('copyWith', () {
      test('should return new ExpenseState with updated isLoading', () {
        final original = ExpenseState();
        final updated = original.copyWith(isLoading: true);

        expect(updated.isLoading, true);
        expect(updated.error, isNull);
        // Original should be unchanged
        expect(original.isLoading, false);
      });

      test('should return new ExpenseState with updated error', () {
        final original = ExpenseState();
        final updated = original.copyWith(error: 'New error');

        expect(updated.isLoading, false);
        expect(updated.error, 'New error');
      });

      test('should return new ExpenseState with both updated values', () {
        final original = ExpenseState();
        final updated = original.copyWith(isLoading: true, error: 'Error');

        expect(updated.isLoading, true);
        expect(updated.error, 'Error');
      });

      test('should preserve isLoading when not updating but clear error', () {
        // Note: The copyWith implementation clears error when not explicitly passed
        final original = ExpenseState(isLoading: true, error: 'Existing error');
        final updated = original.copyWith();

        expect(updated.isLoading, true);
        // Error is cleared because copyWith uses `error: error` not `error: error ?? this.error`
        expect(updated.error, isNull);
      });

      test('should clear error when not explicitly passing it', () {
        final original = ExpenseState(error: 'Some error');
        // The copyWith implementation uses `error: error` directly
        // so not passing error means it becomes null
        final updated = original.copyWith();

        // Error is null because the implementation doesn't preserve error
        expect(updated.error, isNull);
      });

      test('should clear error when only updating isLoading', () {
        // Note: The copyWith implementation clears error when not explicitly passed
        final original = ExpenseState(error: 'Error');
        final updated = original.copyWith(isLoading: true);

        expect(updated.isLoading, true);
        // Error is cleared because copyWith uses `error: error` not `error: error ?? this.error`
        expect(updated.error, isNull);
      });

      test('should update error while preserving isLoading', () {
        final original = ExpenseState(isLoading: true);
        final updated = original.copyWith(error: 'New error');

        expect(updated.isLoading, true);
        expect(updated.error, 'New error');
      });
    });

    group('state transitions', () {
      test('should represent loading state correctly', () {
        final loadingState = ExpenseState(isLoading: true, error: null);

        expect(loadingState.isLoading, true);
        expect(loadingState.error, isNull);
      });

      test('should represent success state correctly', () {
        final successState = ExpenseState(isLoading: false, error: null);

        expect(successState.isLoading, false);
        expect(successState.error, isNull);
      });

      test('should represent error state correctly', () {
        final errorState = ExpenseState(isLoading: false, error: 'Failed to load expenses');

        expect(errorState.isLoading, false);
        expect(errorState.error, 'Failed to load expenses');
      });

      test('should simulate typical loading flow', () {
        // Initial state
        var state = ExpenseState();
        expect(state.isLoading, false);
        expect(state.error, isNull);

        // Start loading
        state = state.copyWith(isLoading: true, error: null);
        expect(state.isLoading, true);
        expect(state.error, isNull);

        // Success
        state = state.copyWith(isLoading: false);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('should simulate typical error flow', () {
        // Initial state
        var state = ExpenseState();

        // Start loading
        state = state.copyWith(isLoading: true, error: null);
        expect(state.isLoading, true);

        // Error occurred
        state = state.copyWith(isLoading: false, error: 'Network error');
        expect(state.isLoading, false);
        expect(state.error, 'Network error');
      });
    });
  });
}
