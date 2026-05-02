import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';

void main() {
  group('AppThemeProvider InheritedWidget', () {
    testWidgets('AppThemeProvider.of returns themeData from ancestor', (tester) async {
      final data = AppThemeData.getThemeData(AppThemeType.ocean);
      AppThemeData? captured;

      await tester.pumpWidget(
        AppThemeProvider(
          themeData: data,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                captured = AppThemeProvider.of(ctx);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.name, data.name);
      expect(captured!.primaryColor, data.primaryColor);
    });

    testWidgets('AppThemeProvider.maybeOf returns null without ancestor', (tester) async {
      AppThemeData? maybe;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              maybe = AppThemeProvider.maybeOf(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(maybe, isNull);
    });

    testWidgets('AppThemeProvider.maybeOf returns themeData with ancestor', (tester) async {
      final data = AppThemeData.getThemeData(AppThemeType.sunset);
      AppThemeData? maybe;

      await tester.pumpWidget(
        AppThemeProvider(
          themeData: data,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                maybe = AppThemeProvider.maybeOf(ctx);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(maybe, isNotNull);
      expect(maybe!.name, 'Sunset Coral');
    });

    testWidgets('updateShouldNotify returns true when themeData changes', (tester) async {
      final ocean = AppThemeData.getThemeData(AppThemeType.ocean);
      final sunset = AppThemeData.getThemeData(AppThemeType.sunset);

      final widgetA = AppThemeProvider(
        themeData: ocean,
        child: const SizedBox(),
      );
      final widgetB = AppThemeProvider(
        themeData: sunset,
        child: const SizedBox(),
      );
      final widgetC = AppThemeProvider(
        themeData: ocean,
        child: const SizedBox(),
      );

      expect(widgetB.updateShouldNotify(widgetA), true);
      expect(widgetC.updateShouldNotify(widgetA), false);
    });
  });

  group('AppThemeExtension on BuildContext', () {
    testWidgets('appThemeData returns provided theme data', (tester) async {
      final data = AppThemeData.getThemeData(AppThemeType.emerald);
      AppThemeData? captured;

      await tester.pumpWidget(
        AppThemeProvider(
          themeData: data,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                captured = ctx.appThemeData;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.name, 'Emerald Green');
    });

    testWidgets('appThemeDataOrNull returns null without ancestor', (tester) async {
      AppThemeData? maybe;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              maybe = ctx.appThemeDataOrNull;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(maybe, isNull);
    });
  });
}
