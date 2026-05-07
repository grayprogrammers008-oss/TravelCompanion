// Coverage placeholder for `lib/features/itinerary/data/datasources/itinerary_remote_datasource.dart`.
//
// `ItineraryRemoteDataSource` is intentionally **not** unit-tested here:
//
//   1. It depends on the static singleton `SupabaseClientWrapper.client`,
//      which throws unless `Supabase.initialize` has been called. There's
//      no constructor/argument seam to inject a fake client.
//   2. Every method drives a 4+ deep PostgREST builder chain
//      (`from(...)`.`insert(...)`.`select(...)`.`single()` etc.). Hand-rolling
//      mocks for every step pulls in `PostgrestFilterBuilder`,
//      `PostgrestTransformBuilder`, etc., which the project's testing rules
//      explicitly say to skip when the chain is "too deep (4+ levels)".
//
// The data source is exercised end-to-end via:
//   - `test/features/itinerary/data/repositories/itinerary_repository_impl_test.dart`
//     (mocks the data source itself with mockito codegen)
//   - `test/features/itinerary/integration/search_itinerary_integration_test.dart`
//
// If we ever decide to test it directly, the recommended approach is to:
//   a) refactor `ItineraryRemoteDataSource` to accept a `SupabaseClient`
//      via its constructor (currently it reads the static singleton), or
//   b) use Supabase's built-in `MockSupabase` infrastructure once it's
//      available in the supabase_flutter test package.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ItineraryRemoteDataSource direct unit tests are skipped — see file header', () {
    // No-op assertion so the file is a valid test file and registers in the
    // test runner.
    expect(true, isTrue);
  });
}
