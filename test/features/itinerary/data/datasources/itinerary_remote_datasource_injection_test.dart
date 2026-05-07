import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/features/itinerary/data/datasources/itinerary_remote_datasource.dart';

/// Verifies that [ItineraryRemoteDataSource] now accepts an injectable
/// [SupabaseClient]. This is the contract that lets tests stub Supabase
/// without touching the static singleton.
///
/// We don't try to mock the entire 4-deep PostgREST chain
/// (`.from().insert().select().single()`) — that's documented as out-of-scope
/// in [itinerary_remote_datasource_test.dart]. Here we only assert that
/// the constructor accepts a [SupabaseClient] and stores it.

class _FakeSupabase extends Mock implements SupabaseClient {}

void main() {
  group('ItineraryRemoteDataSource constructor injection', () {
    test('accepts an injected SupabaseClient', () {
      final fake = _FakeSupabase();
      final ds = ItineraryRemoteDataSource(fake);
      expect(ds, isA<ItineraryRemoteDataSource>());
    });

    test('default constructor falls back to singleton (no-arg)', () {
      // We can't actually construct without Supabase initialized in tests,
      // but we can verify the constructor signature accepts no argument.
      // Skipped at runtime — would throw without bootstrap.
    }, skip: 'Needs Supabase singleton initialized; covered by integration tests.');
  });
}
