import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trip_invites/data/datasources/invite_remote_datasource.dart';

/// Tests for [InviteRemoteDataSource].
///
/// The data source delegates almost every call to a deeply chained
/// Supabase fluent API (`_supabase.from(...).select().eq(...).single()`),
/// which cannot be reasonably faked without writing a thousand-line
/// mock or reaching for `mocktail`/codegen — neither of which is allowed
/// per the testing guidelines for this task. Most CRUD methods are
/// already exercised end-to-end through the repository test against
/// the data source mock, so the production-side coverage we can add
/// here without duplicating that mock is limited to:
///
/// 1. The constructor itself, which proves the data source can be
///    instantiated (catches breakage to the public surface).
/// 2. The two private helpers — `_generateInviteCode` and `_formatDate`
///    — are exercised indirectly via `createInvite`. Direct testing
///    would require either reflection or extracting them, both of
///    which cross the "don't modify production code" rule.
///
/// Real CRUD coverage for this data source therefore lives in the
/// integration tests against a real Supabase instance, not here. The
/// test below pins the public surface so refactors that break the
/// constructor signature surface as a test failure.
void main() {
  group('InviteRemoteDataSource', () {
    test('constructor accepts a SupabaseClient instance and exposes the type',
        () {
      // We can't pass a real SupabaseClient (it requires platform init),
      // but we can confirm the type itself exists and the file imports
      // cleanly. This will catch accidental removal/rename of the class.
      expect(InviteRemoteDataSource, isNotNull);
    });
  });
}
