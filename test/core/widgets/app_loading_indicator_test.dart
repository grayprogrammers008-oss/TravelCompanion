import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/app_loading_indicator.dart';

import 'test_helpers.dart';

void main() {
  group('AppLoadingIndicator', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AppLoadingIndicator(),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders an optional message', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AppLoadingIndicator(message: 'Loading trips...'),
        size: const Size(400, 400),
      ));
      await tester.pump();
      expect(find.text('Loading trips...'), findsOneWidget);
    });

    testWidgets('respects custom colors', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AppLoadingIndicator(
          color: Color(0xFFFF0000),
          secondaryColor: Color(0xFF00FF00),
          size: 60,
        ),
        size: const Size(400, 400),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('progresses across multiple frames without errors',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const AppLoadingIndicator(size: 80),
        size: const Size(400, 400),
      ));
      // Pump several frames to let morph/rotation/pulse tick.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });
  });
}
