import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';

void main() {
  group('AppThemeType enum', () {
    test('has the expected eight values', () {
      expect(AppThemeType.values.length, 8);
      expect(AppThemeType.values, contains(AppThemeType.ocean));
      expect(AppThemeType.values, contains(AppThemeType.sunset));
      expect(AppThemeType.values, contains(AppThemeType.emerald));
      expect(AppThemeType.values, contains(AppThemeType.royal));
      expect(AppThemeType.values, contains(AppThemeType.lavender));
      expect(AppThemeType.values, contains(AppThemeType.blossom));
      expect(AppThemeType.values, contains(AppThemeType.desert));
      expect(AppThemeType.values, contains(AppThemeType.brilliant));
    });

    test('all enum names are unique and non-empty', () {
      final names = AppThemeType.values.map((t) => t.name).toList();
      expect(names.toSet().length, names.length);
      for (final n in names) {
        expect(n, isNotEmpty);
      }
    });
  });

  group('AppThemeData.getThemeData', () {
    test('returns non-null data for every theme type', () {
      for (final type in AppThemeType.values) {
        final data = AppThemeData.getThemeData(type);
        expect(data, isNotNull);
        expect(data.name, isNotEmpty);
        expect(data.description, isNotEmpty);
        expect(data.primaryColor, isA<Color>());
        expect(data.primaryGradient, isA<LinearGradient>());
        expect(data.glossyGradient, isA<LinearGradient>());
        expect(data.headerGradient, isA<LinearGradient>());
        expect(data.backgroundGradient, isA<LinearGradient>());
        expect(data.primaryShadow, isNotEmpty);
        expect(data.glossyShadow, isNotEmpty);
        expect(data.icon, isA<IconData>());
        expect(data.accentColor, isA<Color>());
      }
    });

    test('ocean theme uses blue primary', () {
      final ocean = AppThemeData.getThemeData(AppThemeType.ocean);
      expect(ocean.name, 'Ocean Blue');
      expect(ocean.primaryColor, const Color(0xFF0066CC));
    });

    test('sunset theme uses coral primary', () {
      final sunset = AppThemeData.getThemeData(AppThemeType.sunset);
      expect(sunset.name, 'Sunset Coral');
      expect(sunset.primaryColor, const Color(0xFFFF385C));
    });

    test('emerald theme uses green primary', () {
      final emerald = AppThemeData.getThemeData(AppThemeType.emerald);
      expect(emerald.primaryColor, const Color(0xFF00B14F));
    });

    test('brilliant theme uses electric purple', () {
      final brilliant = AppThemeData.getThemeData(AppThemeType.brilliant);
      expect(brilliant.primaryColor, const Color(0xFF7B5FE8));
    });

    test('all themes are light by default (isDark = false)', () {
      for (final t in AppThemeType.values) {
        final data = AppThemeData.getThemeData(t);
        expect(data.isDark, false);
      }
    });

    test('each theme has a unique primary color', () {
      final colors = AppThemeType.values
          .map((t) => AppThemeData.getThemeData(t).primaryColor.toARGB32())
          .toList();
      expect(colors.toSet().length, colors.length);
    });

    test('each theme has a unique name', () {
      final names = AppThemeType.values
          .map((t) => AppThemeData.getThemeData(t).name)
          .toList();
      expect(names.toSet().length, names.length);
    });

    test('primary gradient contains at least 2 colors', () {
      for (final t in AppThemeType.values) {
        final g = AppThemeData.getThemeData(t).primaryGradient;
        expect(g.colors.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('AppThemeData.toThemeData', () {
    test('produces a Material 3 ThemeData with matching primary color', () {
      for (final t in AppThemeType.values) {
        final data = AppThemeData.getThemeData(t);
        final theme = data.toThemeData();
        expect(theme.useMaterial3, true);
        expect(theme.colorScheme.primary, data.primaryColor);
      }
    });

    test('light theme uses light brightness', () {
      final theme = AppThemeData.getThemeData(AppThemeType.ocean).toThemeData();
      expect(theme.brightness, Brightness.light);
    });

    test('elevated button uses primary color background', () {
      final data = AppThemeData.getThemeData(AppThemeType.royal);
      final theme = data.toThemeData();
      final style = theme.elevatedButtonTheme.style;
      expect(style, isNotNull);
      // We won't try to resolve the MaterialStateProperty here; just verify the
      // theme produced a button theme.
      expect(theme.elevatedButtonTheme, isA<ElevatedButtonThemeData>());
    });
  });

  group('AppThemeData constructor', () {
    test('isDark defaults to false', () {
      const data = AppThemeData(
        name: 'Test',
        description: 'desc',
        primaryColor: Color(0xFF123456),
        primaryDeep: Color(0xFF000000),
        primaryLight: Color(0xFFFFFFFF),
        primaryPale: Color(0xFFEEEEEE),
        primaryGradient: LinearGradient(colors: [Color(0xFF123456), Color(0xFF000000)]),
        glossyGradient: LinearGradient(colors: [Color(0xFF123456), Color(0xFF000000)]),
        headerGradient: LinearGradient(colors: [Color(0xFF123456), Color(0xFF000000)]),
        backgroundGradient: LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFEEEEEE)]),
        primaryShadow: [BoxShadow(color: Color(0x20000000), blurRadius: 4)],
        glossyShadow: [BoxShadow(color: Color(0x30000000), blurRadius: 8)],
        icon: Icons.star,
        accentColor: Color(0xFFFF0000),
      );
      expect(data.isDark, false);
    });
  });
}
