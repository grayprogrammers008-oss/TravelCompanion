import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:travel_crew/core/providers/supabase_provider.dart';

/// Tests for the four exported providers in [supabase_provider.dart].
///
/// We override [supabaseClientProvider] with a fake [SupabaseClient] whose
/// auth stream we control. The downstream providers (authStateProvider,
/// currentUserProvider, userIdProvider) are then exercised through the
/// resulting AsyncValue states.

class _FakeAuth extends Mock implements GoTrueClient {
  _FakeAuth(this._stream);
  final Stream<AuthState> _stream;
  @override
  Stream<AuthState> get onAuthStateChange => _stream;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this._id);
  final String _id;
  @override
  String get id => _id;
}

class _FakeSession extends Fake implements Session {
  _FakeSession(this._user);
  final User _user;
  @override
  User get user => _user;
}

class _FakeAuthState extends Fake implements AuthState {
  _FakeAuthState(this._session);
  final Session? _session;
  @override
  Session? get session => _session;
}

class _FakeSupabase extends Fake implements SupabaseClient {
  _FakeSupabase(this._auth);
  final GoTrueClient _auth;
  @override
  GoTrueClient get auth => _auth;
}

void main() {
  group('supabaseClientProvider', () {
    test('can be overridden by tests', () {
      final fake = _FakeSupabase(_FakeAuth(const Stream.empty()));
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      expect(identical(container.read(supabaseClientProvider), fake), isTrue);
    });
  });

  group('authStateProvider', () {
    test('exposes the auth stream from the supabase client', () async {
      final user = _FakeUser('u-1');
      final session = _FakeSession(user);
      final stream = Stream<AuthState>.fromIterable([_FakeAuthState(session)]);
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      // Subscribe so the stream actually starts.
      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      // Wait for the first event.
      await container.read(authStateProvider.future);
      final state = container.read(authStateProvider);
      expect(state.value, isA<AuthState>());
      expect(state.value!.session?.user.id, 'u-1');
    });
  });

  group('currentUserProvider', () {
    test('returns null while authStateProvider is loading', () {
      // Use a stream that never emits — provider stays in loading.
      final stream = const Stream<AuthState>.empty();
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      // Pre-stream-completion: AsyncValue is loading, currentUser is null.
      expect(container.read(currentUserProvider), isNull);
    });

    test('returns the user when authState emits a non-null session',
        () async {
      final user = _FakeUser('u-1');
      final session = _FakeSession(user);
      final stream = Stream<AuthState>.fromIterable([_FakeAuthState(session)]);
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(authStateProvider.future);
      expect(container.read(currentUserProvider)?.id, 'u-1');
    });

    test('returns null when authState session is null (signed out)',
        () async {
      final stream = Stream<AuthState>.fromIterable([_FakeAuthState(null)]);
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(authStateProvider.future);
      expect(container.read(currentUserProvider), isNull);
    });

    test('returns null when authStateProvider errors', () async {
      final stream = Stream<AuthState>.error(Exception('auth blew up'));
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      // Drain the error so it doesn't propagate as an unhandled error.
      try {
        await container.read(authStateProvider.future);
      } catch (_) {
        // Expected.
      }

      expect(container.read(currentUserProvider), isNull);
    });
  });

  group('userIdProvider', () {
    test('returns the current user id when signed in', () async {
      final user = _FakeUser('u-2');
      final session = _FakeSession(user);
      final stream = Stream<AuthState>.fromIterable([_FakeAuthState(session)]);
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(authStateProvider.future);
      expect(container.read(userIdProvider), 'u-2');
    });

    test('returns null when signed out', () async {
      final stream = Stream<AuthState>.fromIterable([_FakeAuthState(null)]);
      final supabase = _FakeSupabase(_FakeAuth(stream));

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(supabase)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(authStateProvider.future);
      expect(container.read(userIdProvider), isNull);
    });
  });
}
