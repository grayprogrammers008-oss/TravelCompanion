// Tests for AiItineraryState (pure-state copyWith semantics) and the
// availableInterests / travelStyles constants exposed by ai_itinerary_providers.
//
// We do NOT exercise AiItineraryController.generateItinerary here because it
// requires Supabase auth and a live AI provider (Groq/Gemini), neither of
// which are available in unit tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/ai_itinerary/domain/entities/ai_itinerary.dart';
import 'package:travel_crew/features/ai_itinerary/presentation/providers/ai_itinerary_providers.dart';

void main() {
  AiGeneratedItinerary buildItinerary({String destination = 'Goa'}) {
    return AiGeneratedItinerary(
      destination: destination,
      durationDays: 3,
      days: const [],
      generatedAt: DateTime(2024, 1, 1),
    );
  }

  group('AiItineraryState defaults', () {
    test('default constructor produces an idle empty state', () {
      const state = AiItineraryState();
      expect(state.isLoading, false);
      expect(state.itinerary, isNull);
      expect(state.error, isNull);
      expect(state.remainingGenerations, isNull);
    });
  });

  group('AiItineraryState.copyWith', () {
    test('returns new instance with merged fields', () {
      const initial = AiItineraryState();
      final updated = initial.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(initial.isLoading, false); // immutable
    });

    test('copyWith without overrides preserves itinerary', () {
      final itinerary = buildItinerary();
      final state = AiItineraryState(itinerary: itinerary);
      final copied = state.copyWith();
      expect(copied.itinerary, same(itinerary));
    });

    test('copyWith with new itinerary replaces previous', () {
      final first = buildItinerary(destination: 'A');
      final second = buildItinerary(destination: 'B');
      final state = AiItineraryState(itinerary: first);
      final updated = state.copyWith(itinerary: second);
      expect(updated.itinerary?.destination, 'B');
    });

    test('clearItinerary=true sets itinerary back to null', () {
      final state = AiItineraryState(itinerary: buildItinerary());
      final cleared = state.copyWith(clearItinerary: true);
      expect(cleared.itinerary, isNull);
    });

    test('clearItinerary=true takes precedence over passed itinerary', () {
      final state = AiItineraryState(itinerary: buildItinerary());
      final cleared = state.copyWith(
        itinerary: buildItinerary(destination: 'New'),
        clearItinerary: true,
      );
      expect(cleared.itinerary, isNull);
    });

    test('error is replaced (not merged) on each copyWith call', () {
      // The implementation assigns `error: error` directly, so passing no
      // value clears the error to null. This test documents that behavior.
      const state = AiItineraryState(error: 'previous');
      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });

    test('error can be set explicitly', () {
      const state = AiItineraryState();
      final updated = state.copyWith(error: 'Network failure');
      expect(updated.error, 'Network failure');
    });

    test('remainingGenerations updates', () {
      const state = AiItineraryState(remainingGenerations: 5);
      final updated = state.copyWith(remainingGenerations: 2);
      expect(updated.remainingGenerations, 2);
    });

    test('remainingGenerations preserved when not provided', () {
      const state = AiItineraryState(remainingGenerations: 7);
      final updated = state.copyWith(isLoading: true);
      expect(updated.remainingGenerations, 7);
    });

    test('isLoading defaults to existing value when not provided', () {
      const state = AiItineraryState(isLoading: true);
      final updated = state.copyWith(error: 'oops');
      expect(updated.isLoading, true);
    });
  });

  group('Constant lists', () {
    test('availableInterests is non-empty and contains expected entries', () {
      expect(availableInterests, isNotEmpty);
      expect(availableInterests, contains('Adventure'));
      expect(availableInterests, contains('Food & Cuisine'));
      expect(availableInterests, contains('Mountains'));
    });

    test('availableInterests has no duplicates', () {
      expect(availableInterests.toSet().length, availableInterests.length);
    });

    test('travelStyles contains exactly Budget/Moderate/Luxury', () {
      expect(travelStyles, ['Budget', 'Moderate', 'Luxury']);
    });
  });
}
