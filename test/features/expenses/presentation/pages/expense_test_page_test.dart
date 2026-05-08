// Test for `ExpenseTestPage`.
//
// SKIPPED RATIONALE: `ExpenseTestPage` (lib/features/expenses/presentation/
// pages/expense_test_page.dart) is a developer-only manual test page that
// runs CRUD operations against the live Supabase backend (it reads
// `SupabaseClientWrapper.currentUserId` and writes/reads/updates/deletes
// real database rows). It exists to verify expense flows interactively
// during development; the production user experience never reaches it
// outside of debug builds.
//
// All of its functional methods (`_testCreate`, `_testRead`, `_testUpdate`,
// `_testDelete`) are guarded behind a "Run All Tests" button that requires
// an authenticated Supabase session. Mocking that surface in widget tests
// would re-test what the underlying repository / use-case suites already
// cover (see test/features/expenses/domain/usecases/ and
// test/features/expenses/data/repositories/).
//
// We intentionally do NOT add render-only smoke tests here because the
// page reads `SupabaseClientWrapper.currentUserId` in its build path,
// which would throw "Supabase not initialized" without a bootstrap.
//
// Coverage of this file is therefore 0% by design — it is dev-only code
// and not part of the user-facing expense flow.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ExpenseTestPage is a dev-only manual test surface — see file '
    'comment for rationale',
    () {
      // No-op — this file documents the deliberate exclusion of
      // ExpenseTestPage from the unit/widget test surface.
      expect(1, 1);
    },
  );
}
