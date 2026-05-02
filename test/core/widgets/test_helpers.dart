import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;

/// Default theme used across widget tests.
final AppThemeData testTheme = AppThemeData.getThemeData(AppThemeType.ocean);

/// Wraps a child in [ProviderScope], [AppThemeProvider] and [MaterialApp].
///
/// Use this when a widget reads from `context.appThemeData`, `context.primaryColor`,
/// or other theme-extension getters that ultimately go through `Theme.of(context)`
/// or our InheritedWidget.
Widget wrapWithTheme(
  Widget child, {
  List<dynamic> overrides = const <dynamic>[],
  Size? size,
}) {
  return ProviderScope(
    overrides: [
      theme_provider.currentThemeDataProvider.overrideWith((_) => testTheme),
      ...overrides.cast(),
    ],
    child: AppThemeProvider(
      themeData: testTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SizedBox(
            width: size?.width,
            height: size?.height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Lightweight wrapper without AppThemeProvider — for widgets that only use
/// MaterialApp/ThemeData (e.g. SearchDelegate, ThemedDivider).
Widget wrapMaterial(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: child),
  );
}
