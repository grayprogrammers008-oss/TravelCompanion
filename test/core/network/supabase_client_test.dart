import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/network/supabase_client.dart';

/// Tests for the static [SupabaseClientWrapper] facade.
///
/// We can only test the not-initialized contract — bootstrapping a real
/// Supabase instance from a unit test would require network access and
/// is covered by integration tests. Here we verify that every getter
/// throws a descriptive error before initialize() has been called.
///
/// Note: each Dart test isolate starts fresh, so [SupabaseClientWrapper]
/// is uninitialized at the start of this file. We intentionally do NOT
/// call initialize() in any of these tests.

void main() {
  group('SupabaseClientWrapper.client', () {
    test('throws Exception when not initialized', () {
      expect(
        () => SupabaseClientWrapper.client,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Supabase not initialized'),
        )),
      );
    });

    test('error message points the caller at initialize()', () {
      try {
        SupabaseClientWrapper.client;
        fail('expected an Exception');
      } catch (e) {
        expect(e.toString(), contains('SupabaseClientWrapper.initialize()'));
      }
    });
  });

  group('SupabaseClientWrapper.currentUser', () {
    test('throws (delegates to client which throws)', () {
      expect(() => SupabaseClientWrapper.currentUser, throwsA(isA<Exception>()));
    });
  });

  group('SupabaseClientWrapper.currentUserId', () {
    test('throws (delegates to currentUser which throws)', () {
      expect(
        () => SupabaseClientWrapper.currentUserId,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SupabaseClientWrapper.isAuthenticated', () {
    test('throws (delegates to currentUser which throws)', () {
      expect(
        () => SupabaseClientWrapper.isAuthenticated,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SupabaseClientWrapper.authStateChanges', () {
    test('throws (delegates to client which throws)', () {
      expect(
        () => SupabaseClientWrapper.authStateChanges,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SupabaseClientWrapper.storage', () {
    test('throws (delegates to client which throws)', () {
      expect(() => SupabaseClientWrapper.storage, throwsA(isA<Exception>()));
    });
  });

  group('SupabaseClientWrapper.realtime', () {
    test('throws (delegates to client which throws)', () {
      expect(() => SupabaseClientWrapper.realtime, throwsA(isA<Exception>()));
    });
  });

  group('SupabaseClientWrapper.signOut', () {
    test('throws (delegates to client which throws)', () {
      expect(
        () => SupabaseClientWrapper.signOut(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
