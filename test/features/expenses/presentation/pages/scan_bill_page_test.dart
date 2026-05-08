// Widget tests for `ScanBillPage`.
//
// SCOPE: ScanBillPage uses the `image_picker` plugin for camera/gallery
// access AND `BillScannerService` for ML Kit text recognition. Both
// require platform channels that aren't available in widget tests.
// We render the page in its idle ("no image picked yet") state to
// exercise the empty-state UI surface, then stop.
//
// SKIPPED test paths (documented):
//   - Picking an image from camera/gallery (uses ImagePicker channel)
//   - Bill scanning workflow (uses ML Kit text recognition)
//   - Submitting the parsed expense (uses Supabase singleton currentUserId)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/easy_mode_provider.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/expenses/presentation/pages/scan_bill_page.dart';

final _theme = AppThemeData.getThemeData(AppThemeType.ocean);

Widget _buildPage({String? tripId}) {
  return ProviderScope(
    overrides: [
      theme_provider.currentThemeDataProvider.overrideWith((_) => _theme),
      easyModeConfigProvider.overrideWith((_) => const EasyModeConfig()),
    ],
    child: AppThemeProvider(
      themeData: _theme,
      child: MaterialApp(
        home: ScanBillPage(tripId: tripId),
      ),
    ),
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> drainAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('ScanBillPage — idle/empty state render', () {
    testWidgets('renders without throwing in standalone (tripId == null)',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage(tripId: null));
      await drainAnimations(tester);

      // The page builds — Scaffold is rendered. Specific content may vary
      // by ML kit / camera readiness, but the page should not crash.
      expect(find.byType(Scaffold), findsOneWidget);
    });

    // SKIPPED: pre-selected tripId variant — the page reads `tripProvider`
    // via Riverpod which would attempt to construct a SupabaseClient.

    testWidgets('shows back button icon', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_buildPage());
      await drainAnimations(tester);

      expect(find.byIcon(Icons.arrow_back), findsAtLeastNWidgets(1));
    });
  });
}
