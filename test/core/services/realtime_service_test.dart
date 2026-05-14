// Tests for RealtimeService.
//
// We focus on the parts that don't require talking to a real Supabase
// realtime channel: the [RealtimeEventType] mapping and the lifecycle
// surface (`activeChannelCount`, `isChannelActive`, `unsubscribe`,
// `unsubscribeAll`, `dispose`) on a service constructed with no active
// channels.
//
// Mocking SupabaseClient.channel(...) -> RealtimeChannel transitively
// requires also mocking the underlying RealtimeClient WebSocket layer,
// which is out of scope; full subscribe* coverage is gated behind
// integration tests against a live Supabase instance.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathio/core/services/realtime_service.dart';

class _StubAuthClient implements GoTrueClient {
  final _ctrl = StreamController<AuthState>.broadcast();
  @override
  Stream<AuthState> get onAuthStateChange => _ctrl.stream;

  void emit(AuthChangeEvent ev) {
    _ctrl.add(AuthState(ev, null));
  }

  void close() => _ctrl.close();

  // The rest of GoTrueClient is unused; we throw to surface unexpected calls.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('GoTrueClient.${invocation.memberName} not stubbed');
}

class _StubSupabaseClient implements SupabaseClient {
  _StubSupabaseClient();

  final _StubAuthClient _auth = _StubAuthClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          'SupabaseClient.${invocation.memberName} not stubbed');
}

void main() {
  group('RealtimeEventTypeExtension', () {
    test('maps insert -> RealtimeEventType.insert', () {
      expect(
        PostgresChangeEvent.insert.eventType,
        RealtimeEventType.insert,
      );
    });

    test('maps update -> RealtimeEventType.update', () {
      expect(
        PostgresChangeEvent.update.eventType,
        RealtimeEventType.update,
      );
    });

    test('maps delete -> RealtimeEventType.delete', () {
      expect(
        PostgresChangeEvent.delete.eventType,
        RealtimeEventType.delete,
      );
    });

    test('maps "all" event to update fallback', () {
      // The .all enum value falls into the default branch.
      expect(
        PostgresChangeEvent.all.eventType,
        RealtimeEventType.update,
      );
    });
  });

  group('RealtimeEventType enum', () {
    test('has three distinct values', () {
      expect(RealtimeEventType.values, hasLength(3));
      expect(RealtimeEventType.values.toSet(), hasLength(3));
    });
  });

  group('RealtimeService lifecycle (no live channels)', () {
    late _StubSupabaseClient stub;

    setUp(() {
      stub = _StubSupabaseClient();
    });

    tearDown(() {
      stub._auth.close();
    });

    test('activeChannelCount is 0 on a fresh instance', () {
      final svc = RealtimeService.withClient(stub);
      expect(svc.activeChannelCount, 0);
    });

    test('isChannelActive returns false for unknown channel', () {
      final svc = RealtimeService.withClient(stub);
      expect(svc.isChannelActive('nope'), isFalse);
    });

    test('unsubscribe on missing channel is a no-op', () {
      final svc = RealtimeService.withClient(stub);
      // Should not throw
      svc.unsubscribe('does-not-exist');
      expect(svc.activeChannelCount, 0);
    });

    test('unsubscribeAll on empty service is a no-op', () {
      final svc = RealtimeService.withClient(stub);
      svc.unsubscribeAll();
      expect(svc.activeChannelCount, 0);
    });

    test('dispose with no channels is safe', () {
      final svc = RealtimeService.withClient(stub);
      svc.dispose();
      expect(svc.activeChannelCount, 0);
    });

    test('dispose can be called multiple times', () {
      final svc = RealtimeService.withClient(stub);
      svc.dispose();
      svc.dispose();
      expect(svc.activeChannelCount, 0);
    });

    test('with auth listener wired, signOut event triggers cleanup',
        () async {
      final svc =
          RealtimeService.withClient(stub, wireAuthListener: true);
      stub._auth.emit(AuthChangeEvent.signedOut);
      // Allow microtask queue to drain.
      await Future<void>.delayed(Duration.zero);
      expect(svc.activeChannelCount, 0);
      svc.dispose();
    });

    test(
        'with auth listener wired, tokenRefreshed event triggers '
        'reconnect path safely with no active channels', () async {
      final svc =
          RealtimeService.withClient(stub, wireAuthListener: true);
      stub._auth.emit(AuthChangeEvent.tokenRefreshed);
      // Wait long enough for the 500ms internal cleanup pause.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(svc.activeChannelCount, 0);
      svc.dispose();
    });
  });
}
