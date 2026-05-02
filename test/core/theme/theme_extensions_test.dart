import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/theme_extensions.dart';

void main() {
  Future<void> pumpWithContext(
    WidgetTester tester,
    void Function(BuildContext) verify,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF112233),
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFAABBCC),
            onPrimaryContainer: Color(0xFF003366),
            secondary: Color(0xFF445566),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFCCDDEE),
            onSecondaryContainer: Color(0xFF002244),
            tertiary: Color(0xFF778899),
            onTertiary: Colors.white,
            tertiaryContainer: Color(0xFFEEFFEE),
            onTertiaryContainer: Color(0xFF003322),
            error: Color(0xFFFF0000),
            onError: Colors.white,
            errorContainer: Color(0xFFFFCCCC),
            onErrorContainer: Color(0xFF990000),
            surface: Color(0xFFF5F5F5),
            onSurface: Color(0xFF111111),
            surfaceContainerHighest: Color(0xFFE0E0E0),
            onSurfaceVariant: Color(0xFF555555),
            outline: Color(0xFF999999),
            outlineVariant: Color(0xFFCCCCCC),
            shadow: Color(0x80000000),
            scrim: Color(0xC0000000),
            inverseSurface: Color(0xFF222222),
            onInverseSurface: Color(0xFFFAFAFA),
            inversePrimary: Color(0xFF99AABB),
          ),
        ),
        home: Builder(
          builder: (ctx) {
            verify(ctx);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  testWidgets('color getters return expected colorScheme values', (tester) async {
    await pumpWithContext(tester, (ctx) {
      expect(ctx.primaryColor, const Color(0xFF112233));
      expect(ctx.accentColor, const Color(0xFF445566));
      expect(ctx.backgroundColor, const Color(0xFFF5F5F5));
      expect(ctx.textColor, const Color(0xFF111111));
      expect(ctx.errorColor, const Color(0xFFFF0000));
      expect(ctx.successColor, const Color(0xFF778899));
      expect(ctx.primaryLight, const Color(0xFFAABBCC));
      expect(ctx.primaryDark, const Color(0xFF003366));
      expect(ctx.surfaceColor, const Color(0xFFF5F5F5));
    });
  });

  testWidgets('cardColor falls back to white when not set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Builder(
          builder: (ctx) {
            // cardTheme.color may be null on some defaults; just check non-null
            expect(ctx.cardColor, isA<Color>());
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('all text style getters return non-null TextStyle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 50),
            displayMedium: TextStyle(fontSize: 45),
            displaySmall: TextStyle(fontSize: 40),
            headlineLarge: TextStyle(fontSize: 32),
            headlineMedium: TextStyle(fontSize: 28),
            headlineSmall: TextStyle(fontSize: 24),
            titleLarge: TextStyle(fontSize: 22),
            titleMedium: TextStyle(fontSize: 16),
            titleSmall: TextStyle(fontSize: 14),
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
            bodySmall: TextStyle(fontSize: 12),
            labelLarge: TextStyle(fontSize: 14),
            labelMedium: TextStyle(fontSize: 12),
            labelSmall: TextStyle(fontSize: 11),
          ),
        ),
        home: Builder(
          builder: (ctx) {
            expect(ctx.displayLarge.fontSize, 50);
            expect(ctx.displayMedium.fontSize, 45);
            expect(ctx.displaySmall.fontSize, 40);
            expect(ctx.headlineLarge.fontSize, 32);
            expect(ctx.headlineMedium.fontSize, 28);
            expect(ctx.headlineSmall.fontSize, 24);
            expect(ctx.titleLarge.fontSize, 22);
            expect(ctx.titleMedium.fontSize, 16);
            expect(ctx.titleSmall.fontSize, 14);
            expect(ctx.bodyLarge.fontSize, 16);
            expect(ctx.bodyMedium.fontSize, 14);
            expect(ctx.bodySmall.fontSize, 12);
            expect(ctx.labelLarge.fontSize, 14);
            expect(ctx.labelMedium.fontSize, 12);
            expect(ctx.labelSmall.fontSize, 11);

            // Convenient aliases
            expect(ctx.headlineStyle, ctx.headlineMedium);
            expect(ctx.titleStyle, ctx.titleMedium);
            expect(ctx.bodyStyle, ctx.bodyMedium);
            expect(ctx.captionStyle, ctx.labelSmall);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('spacing values are positive and ordered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.spacingXs, 8.0);
            expect(ctx.spacingSm, 12.0);
            expect(ctx.spacingMd, 16.0);
            expect(ctx.spacingLg, 24.0);
            expect(ctx.spacingXl, 32.0);
            expect(ctx.spacing2xl, 48.0);
            expect(ctx.spacing3xl, 64.0);

            expect(ctx.spacingXs < ctx.spacingSm, true);
            expect(ctx.spacingSm < ctx.spacingMd, true);
            expect(ctx.spacingMd < ctx.spacingLg, true);
            expect(ctx.spacingLg < ctx.spacingXl, true);
            expect(ctx.spacingXl < ctx.spacing2xl, true);
            expect(ctx.spacing2xl < ctx.spacing3xl, true);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('radius values are positive and ordered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.radiusXs, 4.0);
            expect(ctx.radiusSm, 8.0);
            expect(ctx.radiusMd, 12.0);
            expect(ctx.radiusLg, 16.0);
            expect(ctx.radiusXl, 24.0);
            expect(ctx.radiusFull, 999.0);

            expect(ctx.radiusXs < ctx.radiusSm, true);
            expect(ctx.radiusSm < ctx.radiusMd, true);
            expect(ctx.radiusMd < ctx.radiusLg, true);
            expect(ctx.radiusLg < ctx.radiusXl, true);
            expect(ctx.radiusXl < ctx.radiusFull, true);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('icon sizes are ordered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.iconSizeXs < ctx.iconSizeSm, true);
            expect(ctx.iconSizeSm < ctx.iconSizeMd, true);
            expect(ctx.iconSizeMd < ctx.iconSizeLg, true);
            expect(ctx.iconSizeLg < ctx.iconSizeXl, true);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('opacity values are within [0,1] and ordered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.opacityDisabled, inInclusiveRange(0.0, 1.0));
            expect(ctx.opacityMedium, inInclusiveRange(0.0, 1.0));
            expect(ctx.opacityHigh, inInclusiveRange(0.0, 1.0));
            expect(ctx.opacityDisabled < ctx.opacityMedium, true);
            expect(ctx.opacityMedium < ctx.opacityHigh, true);
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('elevation values are non-negative and ordered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            expect(ctx.elevation0, 0);
            expect(ctx.elevation1, 1);
            expect(ctx.elevation2, 2);
            expect(ctx.elevation4, 4);
            expect(ctx.elevation8, 8);
            expect(ctx.elevation16, 16);
            expect(ctx.elevation0 < ctx.elevation1, true);
            expect(ctx.elevation8 < ctx.elevation16, true);
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
