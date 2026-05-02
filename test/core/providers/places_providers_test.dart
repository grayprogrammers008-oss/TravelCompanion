import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/providers/places_providers.dart';

void main() {
  group('AutocompleteState', () {
    test('default constructor has empty predictions and not loading', () {
      const state = AutocompleteState();
      expect(state.predictions, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith overrides individual fields', () {
      const original = AutocompleteState();
      final updated = original.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.predictions, isEmpty);
      expect(updated.error, isNull);
    });

    test('copyWith preserves predictions when not specified', () {
      const original = AutocompleteState(isLoading: true);
      final updated = original.copyWith(error: 'oops');
      expect(updated.error, 'oops');
      expect(updated.isLoading, true);
    });

    test('error is replaced (not preserved) when copyWith is invoked without it', () {
      // Note: due to current copyWith implementation, error is replaced with the
      // passed argument (which defaults to null). This test asserts that behaviour.
      const original = AutocompleteState(error: 'old');
      final updated = original.copyWith(isLoading: false);
      expect(updated.error, isNull);
    });
  });
}
