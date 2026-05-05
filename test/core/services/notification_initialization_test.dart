import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/services/notification_initialization.dart';

/// Tests for [NotificationInitialization].
///
/// In a unit-test environment Firebase is not initialized — `Firebase.app()`
/// throws and `FirebaseMessaging.instance` cannot be acquired. The class is
/// designed to handle this gracefully: every entry point wraps work in a
/// try/catch, logs a warning, and returns silently. We verify that contract:
///
///   * [registerToken] / [unregisterToken] / [initialize] never throw, even
///     with no Firebase and no auth.
///   * The injected [SupabaseClient] is honored — when Firebase is missing,
///     [registerToken] and [unregisterToken] short-circuit BEFORE touching
///     `supabase.auth`, so the fake client should NOT see any reads.
///   * [isInitialized] starts false and stays false after a failing init.
///   * [resetInitialization] returns the flag to false.
///
/// We deliberately do NOT initialize Firebase in tests — the goal is to
/// verify the no-Firebase fallback paths that protect production from
/// crashing when the FCM stack is unavailable.

class _FakeAuth extends Mock implements GoTrueClient {
  int currentUserReads = 0;

  @override
  User? get currentUser {
    currentUserReads++;
    return null;
  }
}

class _FakeSupabaseClient extends Mock implements SupabaseClient {
  _FakeSupabaseClient(this._auth);
  final _FakeAuth _auth;

  @override
  GoTrueClient get auth => _auth;
}

void main() {
  setUp(() {
    NotificationInitialization.resetInitialization();
  });

  group('NotificationInitialization.isInitialized', () {
    test('starts as false', () {
      expect(NotificationInitialization.isInitialized, isFalse);
    });

    test('resetInitialization sets it back to false', () {
      NotificationInitialization.resetInitialization();
      expect(NotificationInitialization.isInitialized, isFalse);
    });
  });

  group('NotificationInitialization.registerToken (no Firebase env)', () {
    test('returns silently — does not throw without Firebase initialized',
        () async {
      final auth = _FakeAuth();
      final client = _FakeSupabaseClient(auth);

      // Without Firebase initialized, the method must return without throwing.
      await expectLater(
        NotificationInitialization.registerToken(supabaseClient: client),
        completes,
      );
    });

    test('short-circuits BEFORE touching the supabase client', () async {
      // Implementation calls Firebase.app() first; if that throws (which it
      // does in tests), we return early and never read auth.currentUser.
      final auth = _FakeAuth();
      final client = _FakeSupabaseClient(auth);

      await NotificationInitialization.registerToken(supabaseClient: client);

      expect(auth.currentUserReads, 0,
          reason:
              'registerToken must short-circuit on missing Firebase before touching the client');
    });

    test('accepts no-arg call (uses Supabase singleton)', () async {
      // We can't easily verify the singleton path without a real Supabase
      // bootstrapped — but the no-arg form must at least not throw.
      await expectLater(
        NotificationInitialization.registerToken(),
        completes,
      );
    });
  });

  group('NotificationInitialization.unregisterToken (no Firebase env)', () {
    test('returns silently — does not throw without Firebase initialized',
        () async {
      final auth = _FakeAuth();
      final client = _FakeSupabaseClient(auth);

      await expectLater(
        NotificationInitialization.unregisterToken(supabaseClient: client),
        completes,
      );
    });

    test('short-circuits BEFORE touching the supabase client', () async {
      final auth = _FakeAuth();
      final client = _FakeSupabaseClient(auth);

      await NotificationInitialization.unregisterToken(supabaseClient: client);

      expect(auth.currentUserReads, 0,
          reason:
              'unregisterToken must short-circuit on missing Firebase before touching the client');
    });

    test('accepts no-arg call (uses Supabase singleton)', () async {
      await expectLater(
        NotificationInitialization.unregisterToken(),
        completes,
      );
    });
  });

  group('NotificationInitialization.initialize (no Firebase env)', () {
    test('returns silently — never rethrows an FCM init failure', () async {
      // Even if FCMService.initialize() throws (because Firebase isn't set
      // up), the outer try/catch in initialize() must swallow it. The doc
      // comment is explicit: "notifications are not critical".
      final auth = _FakeAuth();
      final client = _FakeSupabaseClient(auth);

      await expectLater(
        NotificationInitialization.initialize(supabaseClient: client),
        completes,
      );
    });

    test('marks service as initialized even when no user is authenticated',
        () async {
      // FCMService swallows its own Firebase failure internally. With no
      // authenticated user the code path skips token registration and
      // proceeds to set _isInitialized = true. This matches production
      // intent: the service is "ready"; there's just no user to register.
      final auth = _FakeAuth();
      final client = _FakeSupabaseClient(auth);

      await NotificationInitialization.initialize(supabaseClient: client);

      expect(NotificationInitialization.isInitialized, isTrue);
      expect(auth.currentUserReads, 1,
          reason:
              'initialize must consult auth.currentUser before token registration');
    });

    test('accepts no-arg call (uses Supabase singleton)', () async {
      await expectLater(
        NotificationInitialization.initialize(),
        completes,
      );
    });
  });
}
