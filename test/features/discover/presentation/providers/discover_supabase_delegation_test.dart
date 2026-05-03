import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';

/// Sentinel SupabaseClient — never accessed, just used as an identity check.
class _SentinelClient extends Mock implements SupabaseClient {}

void main() {
  group('discoverSupabaseProvider', () {
    test('delegates to the global supabaseClientProvider', () {
      // Arrange — override the global Supabase provider with a sentinel.
      final sentinel = _SentinelClient();
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(sentinel),
        ],
      );
      addTearDown(container.dispose);

      // Act — read the discover-feature-local provider.
      final actual = container.read(discoverSupabaseProvider);

      // Assert — they must be the same instance, proving the test seam.
      expect(identical(actual, sentinel), isTrue);
    });

    test('returns a different client when the override changes', () {
      // First container with sentinel A.
      final a = _SentinelClient();
      final containerA = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(a)],
      );
      addTearDown(containerA.dispose);
      expect(identical(containerA.read(discoverSupabaseProvider), a), isTrue);

      // Second container with sentinel B — different identity.
      final b = _SentinelClient();
      final containerB = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(b)],
      );
      addTearDown(containerB.dispose);
      expect(identical(containerB.read(discoverSupabaseProvider), b), isTrue);
      expect(identical(a, b), isFalse);
    });
  });
}
